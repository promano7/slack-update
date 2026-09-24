#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-controller-artifact-acquisition-probe.sh \
  --acquire-binding-evidence --output-dir DIR

Acquire the exact kernel-headers predecessor/target package artifacts and
signatures on the controller, verify the Slackware signing-key fingerprint,
verify both detached package signatures, and emit SHA-256 binding evidence.

This probe must run unprivileged on the controller. It performs HTTPS network
access only to the frozen Slackware/Slackware UK URLs. It does not access or
modify the target VM, packages, boot configuration, or repository checkout.
USAGE
}

mode=
output_dir=
while (($#)); do
    case "$1" in
        --acquire-binding-evidence)
            [[ -z $mode ]] || { printf 'ERROR: duplicate mode\n' >&2; exit 2; }
            mode=acquire
            shift
            ;;
        --output-dir)
            [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }
            output_dir=$2
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            printf 'ERROR: unknown option: %s\n' "$1" >&2
            exit 2
            ;;
    esac
done

[[ $mode == acquire ]] || { usage >&2; exit 2; }
[[ -n $output_dir ]] || { printf 'ERROR: --output-dir is required\n' >&2; exit 2; }
(( EUID != 0 )) || { printf 'ERROR: run this controller acquisition probe without sudo/root\n' >&2; exit 3; }

for cmd in curl gpg sha256sum awk grep mkdir chmod rm date; do
    command -v "$cmd" >/dev/null 2>&1 || { printf 'ERROR: required command not found: %s\n' "$cmd" >&2; exit 4; }
done

[[ ! -e $output_dir ]] || { printf 'ERROR: output path must not already exist: %s\n' "$output_dir" >&2; exit 5; }
mkdir -m 700 -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: unsafe output directory\n' >&2; exit 5; }
output_dir=$(CDPATH= cd -- "$output_dir" && pwd -P)

key_url='https://mirrors.slackware.com/slackware/slackware-current/GPG-KEY'
archive_base='https://slackware.uk/cumulative/slackware64-current/slackware64/d'
pre_pkg='kernel-headers-6.18.44-x86-1.txz'
pre_sig='kernel-headers-6.18.44-x86-1.txz.asc'
tgt_pkg='kernel-headers-6.18.45-x86-1.txz'
tgt_sig='kernel-headers-6.18.45-x86-1.txz.asc'
expected_fpr='EC5649DA401E22ABFA6736EF6A4463C040102233'
expected_keyid='6A4463C040102233'
expected_uid='Slackware Linux Project <security@slackware.com>'

fetch() {
    local url=$1 dest=$2
    curl --fail --silent --show-error --location \
        --proto '=https' --tlsv1.2 --retry 2 --connect-timeout 20 \
        --output "$dest" -- "$url"
    [[ -s $dest && ! -L $dest ]] || { printf 'ERROR: acquired file is missing, empty, or unsafe: %s\n' "$dest" >&2; exit 6; }
}

key_file="$output_dir/GPG-KEY"
fetch "$key_url" "$key_file"
fetch "$archive_base/$pre_pkg" "$output_dir/$pre_pkg"
fetch "$archive_base/$pre_sig" "$output_dir/$pre_sig"
fetch "$archive_base/$tgt_pkg" "$output_dir/$tgt_pkg"
fetch "$archive_base/$tgt_sig" "$output_dir/$tgt_sig"

key_listing="$output_dir/GPG-KEY.colons"
inspect_home="$output_dir/.gnupg-inspect"
mkdir -m 700 -- "$inspect_home"
gpg --homedir "$inspect_home" --batch --no-options --with-colons --import-options show-only --import "$key_file" >"$key_listing" 2>"$output_dir/GPG-KEY.inspect.stderr"
rm -rf -- "$inspect_home"
actual_fpr=$(awk -F: '$1=="fpr" {print $10; exit}' "$key_listing")
actual_keyid=$(awk -F: '$1=="pub" {print $5; exit}' "$key_listing")
actual_uid=$(awk -F: '$1=="uid" {print $10; exit}' "$key_listing")
[[ $actual_fpr == "$expected_fpr" ]] || { printf 'ERROR: Slackware signing-key fingerprint mismatch\nexpected: %s\nactual:   %s\n' "$expected_fpr" "$actual_fpr" >&2; exit 7; }
[[ $actual_keyid == "$expected_keyid" ]] || { printf 'ERROR: Slackware signing-key ID mismatch\n' >&2; exit 7; }
[[ $actual_uid == "$expected_uid" ]] || { printf 'ERROR: Slackware signing-key UID mismatch\nexpected: %s\nactual:   %s\n' "$expected_uid" "$actual_uid" >&2; exit 7; }

gnupg_home="$output_dir/.gnupg-verification"
mkdir -m 700 -- "$gnupg_home"
gpg --homedir "$gnupg_home" --batch --no-options --import "$key_file" >"$output_dir/gpg-import.stdout" 2>"$output_dir/gpg-import.stderr"

verify_one() {
    local sig=$1 pkg=$2 status=$3 stderr=$4
    gpg --homedir "$gnupg_home" --batch --no-options --no-auto-key-retrieve \
        --status-fd 1 --verify "$sig" "$pkg" >"$status" 2>"$stderr"
    grep -Fq "[GNUPG:] VALIDSIG $expected_fpr " "$status" || {
        printf 'ERROR: detached signature did not validate with frozen Slackware fingerprint: %s\n' "$pkg" >&2
        exit 8
    }
}

verify_one "$output_dir/$pre_sig" "$output_dir/$pre_pkg" \
    "$output_dir/predecessor-signature.status" "$output_dir/predecessor-signature.stderr"
verify_one "$output_dir/$tgt_sig" "$output_dir/$tgt_pkg" \
    "$output_dir/target-signature.status" "$output_dir/target-signature.stderr"

rm -rf -- "$gnupg_home"

sha() { sha256sum -- "$1" | awk '{print $1}'; }
key_sha=$(sha "$key_file")
pre_pkg_sha=$(sha "$output_dir/$pre_pkg")
pre_sig_sha=$(sha "$output_dir/$pre_sig")
tgt_pkg_sha=$(sha "$output_dir/$tgt_pkg")
tgt_sig_sha=$(sha "$output_dir/$tgt_sig")

record="$output_dir/binding-evidence.tsv"
{
    printf 'acquisition_status\tPASS\n'
    printf 'controller_privilege\tunprivileged\n'
    printf 'signing_key_url\t%s\n' "$key_url"
    printf 'signing_key_fingerprint\t%s\n' "$actual_fpr"
    printf 'signing_key_long_id\t%s\n' "$actual_keyid"
    printf 'signing_key_uid\t%s\n' "$actual_uid"
    printf 'signing_key_sha256\t%s\n' "$key_sha"
    printf 'predecessor_package_url\t%s/%s\n' "$archive_base" "$pre_pkg"
    printf 'predecessor_package_filename\t%s\n' "$pre_pkg"
    printf 'predecessor_package_sha256\t%s\n' "$pre_pkg_sha"
    printf 'predecessor_signature_url\t%s/%s\n' "$archive_base" "$pre_sig"
    printf 'predecessor_signature_filename\t%s\n' "$pre_sig"
    printf 'predecessor_signature_sha256\t%s\n' "$pre_sig_sha"
    printf 'predecessor_signature_valid\tyes\n'
    printf 'target_package_url\t%s/%s\n' "$archive_base" "$tgt_pkg"
    printf 'target_package_filename\t%s\n' "$tgt_pkg"
    printf 'target_package_sha256\t%s\n' "$tgt_pkg_sha"
    printf 'target_signature_url\t%s/%s\n' "$archive_base" "$tgt_sig"
    printf 'target_signature_filename\t%s\n' "$tgt_sig"
    printf 'target_signature_sha256\t%s\n' "$tgt_sig_sha"
    printf 'target_signature_valid\tyes\n'
    printf 'target_vm_network_access_performed\tno\n'
    printf 'target_vm_action_performed\tno\n'
    printf 'package_action_performed\tno\n'
    printf 'boot_action_performed\tno\n'
    printf 'reboot_performed\tno\n'
} >"$record"

manifest="$output_dir/acquired-files.sha256"
(
    cd -- "$output_dir"
    sha256sum -- GPG-KEY "$pre_pkg" "$pre_sig" "$tgt_pkg" "$tgt_sig" binding-evidence.tsv
) >"$manifest"
manifest_sha=$(sha "$manifest")
record_sha=$(sha "$record")

printf 'acquisition_status\tPASS\n'
printf 'evidence_root\t%s\n' "$output_dir"
printf 'binding_evidence_sha256\t%s\n' "$record_sha"
printf 'acquired_files_manifest_sha256\t%s\n' "$manifest_sha"
printf 'signing_key_fingerprint\t%s\n' "$actual_fpr"
printf 'signing_key_sha256\t%s\n' "$key_sha"
printf 'predecessor_package_sha256\t%s\n' "$pre_pkg_sha"
printf 'predecessor_signature_sha256\t%s\n' "$pre_sig_sha"
printf 'target_package_sha256\t%s\n' "$tgt_pkg_sha"
printf 'target_signature_sha256\t%s\n' "$tgt_sig_sha"
printf 'predecessor_signature_valid\tyes\n'
printf 'target_signature_valid\tyes\n'
printf 'target_vm_network_access_performed\tno\n'
printf 'target_vm_action_performed\tno\n'
printf 'package_action_performed\tno\n'
printf 'boot_action_performed\tno\n'
printf 'reboot_performed\tno\n'
printf 'preserve_evidence_root_for_next_gate\tyes\n'
