#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_OUTPUT_ROOT=/var/tmp/slack-update-acceptance/current-normal-update-authorized-apply
READINESS_RECORD="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-kernel-transaction-readiness-20260805-accepted.json"
AUTHORIZATION_POLICY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-normal-update-authorized-apply-policy.json"
NORMAL_UPDATE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-normal-update.sh"
REFERENCE_SCRIPT="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"

TARGET=
OUTPUT_DIR=
CONFIRM_HOSTNAME=
CONFIRM_HOSTNAME_FQDN=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_TARGET_KERNEL=
CONFIRM_READINESS_SHA256=
CONFIRM_AUTHORIZATION_SHA256=
EXECUTE_AUTHORIZED_APPLY=0
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
HOSTNAME_SHORT=
HOSTNAME_FQDN=
RUNNING_KERNEL_BEFORE=
RUNNING_KERNEL_AFTER=
CHILD_STATUS=-1
TRANSACTION_STATUS=not-started
PAUSE_SAFE=false
PAUSE_SAFETY_REASON=authorized-package-transaction-pending
APPLY_READY=true
APPLY_AUTHORIZED=false
NEXT_STAGE=normal-update-apply-authorization-review
PACKAGE_DATABASE=

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current --execute-authorized-apply \
                     --confirm-hostname SHORT_HOSTNAME \
                     --confirm-hostname-fqdn FQDN \
                     --confirm-candidates-sha256 SHA256 \
                     --confirm-target-kernel VERSION \
                     --confirm-readiness-sha256 SHA256 \
                     --confirm-authorization-sha256 SHA256 [options]

Execute the explicitly reviewed Slackware-current 137-package transaction. This
wrapper binds the accepted final readiness record, validates the exact short
hostname, FQDN, and live 6.18.40 boot state, and invokes the normal-update
acceptance workflow. The child workflow refreshes metadata and revalidates the
complete candidate digest again immediately before it authorizes package
installation.

A successful result requires the package database to change, the GenInitrd
policy to be restored, the 6.18.42 kernel and versioned initrd to exist, GRUB to
reference the target kernel and initrd, and the 6.18.40 rollback artifacts to
remain present. Only then may the result report pause_safe=true.

Required options:
      --target slackware-current
      --execute-authorized-apply
      --confirm-hostname SHORT_HOSTNAME
      --confirm-hostname-fqdn FQDN
      --confirm-candidates-sha256 SHA256
      --confirm-target-kernel VERSION
      --confirm-readiness-sha256 SHA256
      --confirm-authorization-sha256 SHA256

Optional arguments:
      --output-dir PATH        Store evidence under an absolute, new directory
  -h, --help                   Show this help and exit
EOF_USAGE
}

error() { printf 'ERROR: %s\n' "$*" >&2; }
record_pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$1" | tee -a "$ASSERTION_LOG"; }
record_failure() { FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" | tee -a "$ASSERTION_LOG" >&2; }

is_sha256() {
    [ "${#1}" -eq 64 ] || return 1
    case "$1" in *[!0-9A-Fa-f]*) return 1 ;; esac
}

is_safe_kernel_version() {
    [ -n "$1" ] || return 1
    case "$1" in *[!0-9A-Za-z._+-]*) return 1 ;; esac
}

parse_arguments() {
    while [ "$#" -gt 0 ]; do
        case "$1" in
            --target) [ "$#" -ge 2 ] || return 1; TARGET=$2; shift 2 ;;
            --execute-authorized-apply) EXECUTE_AUTHORIZED_APPLY=$((EXECUTE_AUTHORIZED_APPLY + 1)); shift ;;
            --confirm-hostname) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME=$2; shift 2 ;;
            --confirm-hostname-fqdn) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
            --confirm-candidates-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_CANDIDATES_SHA256=${2,,}; shift 2 ;;
            --confirm-target-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_TARGET_KERNEL=$2; shift 2 ;;
            --confirm-readiness-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_READINESS_SHA256=${2,,}; shift 2 ;;
            --confirm-authorization-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_AUTHORIZATION_SHA256=${2,,}; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done

    [ "$TARGET" = slackware-current ] || return 1
    [ "$EXECUTE_AUTHORIZED_APPLY" -eq 1 ] || return 1
    [ -n "$CONFIRM_HOSTNAME" ] || return 1
    [ -n "$CONFIRM_HOSTNAME_FQDN" ] || return 1
    case "$CONFIRM_HOSTNAME$CONFIRM_HOSTNAME_FQDN" in *[[:space:]]*) return 1 ;; esac
    is_sha256 "$CONFIRM_CANDIDATES_SHA256" || return 1
    is_safe_kernel_version "$CONFIRM_TARGET_KERNEL" || return 1
    is_sha256 "$CONFIRM_READINESS_SHA256" || return 1
    is_sha256 "$CONFIRM_AUTHORIZATION_SHA256" || return 1
    if [ -n "$OUTPUT_DIR" ]; then
        case "$OUTPUT_DIR" in /*) ;; *) return 1 ;; esac
    fi
    case "$OUTPUT_DIR$REPOSITORY_ROOT" in *[[:space:]]*) return 1 ;; esac
}

require_regular_file() {
    [ -f "$1" ] && [ ! -L "$1" ] && [ -r "$1" ]
}

validate_reviewed_authorization() {
    python3 - "$READINESS_RECORD" "$AUTHORIZATION_POLICY" "$NORMAL_UPDATE_SCRIPT" "$REFERENCE_SCRIPT" \
        "$CONFIRM_HOSTNAME" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" \
        "$CONFIRM_READINESS_SHA256" "$CONFIRM_AUTHORIZATION_SHA256" <<'PY'
import hashlib
import json
import pathlib
import sys

(readiness_path, policy_path, normal_path, reference_path, hostname_short, hostname_fqdn,
 candidate_sha, target_kernel, readiness_sha, authorization_sha) = sys.argv[1:]


def load_regular(path):
    p = pathlib.Path(path)
    if not p.is_file() or p.is_symlink():
        raise SystemExit(1)
    return json.loads(p.read_text(encoding='utf-8'))


def digest(path):
    return hashlib.sha256(pathlib.Path(path).read_bytes()).hexdigest()

readiness = load_regular(readiness_path)
policy = load_regular(policy_path)
scope = (
    'operation=current-normal-update-authorized-apply\n'
    'target=slackware-current\n'
    f'hostname_short={hostname_short}\n'
    f'hostname_fqdn={hostname_fqdn}\n'
    f'candidate_set_sha256={candidate_sha}\n'
    f'target_kernel={target_kernel}\n'
    f'readiness_archive_sha256={readiness_sha}\n'
).encode()
calculated_scope = hashlib.sha256(scope).hexdigest()

checks = [
    readiness.get('scenario') == 'current-kernel-transaction-readiness-preflight',
    readiness.get('target') == 'slackware-current',
    readiness.get('accepted') is True,
    readiness.get('archive_sha256') == readiness_sha,
    readiness.get('candidate_set_sha256') == candidate_sha,
    readiness.get('fresh_candidate_set_sha256') == candidate_sha,
    readiness.get('target_kernel') == target_kernel,
    readiness.get('readiness_status') == 'apply-ready',
    readiness.get('apply_ready') is True,
    readiness.get('apply_authorized') is False,
    readiness.get('pause_safe') is False,
    readiness.get('next_stage') == 'normal-update-apply-authorization-review',
    policy.get('scenario') == 'current-normal-update-authorized-apply',
    policy.get('target') == 'slackware-current',
    policy.get('reviewed') is True,
    policy.get('authorization_reviewed') is True,
    policy.get('required_hostname_short') == hostname_short,
    policy.get('required_hostname_fqdn') == hostname_fqdn,
    policy.get('candidate_set_sha256') == candidate_sha,
    policy.get('target_kernel') == target_kernel,
    policy.get('accepted_readiness_archive_sha256') == readiness_sha,
    policy.get('authorization_scope_sha256') == authorization_sha == calculated_scope,
    policy.get('reference_engine_sha256') == digest(reference_path),
    policy.get('normal_update_acceptance_sha256') == digest(normal_path),
    policy.get('expected_candidate_count') == 137,
    policy.get('expected_install_new_count') == 1,
    policy.get('expected_upgrade_all_count') == 136,
    policy.get('expected_kernel_candidate_count') == 2,
    policy.get('expected_critical_candidate_count') == 0,
    policy.get('critical_update_authorized') is False,
    policy.get('postinstall_policy') == 'defer',
    policy.get('postinstall_processing_enabled') is False,
    policy.get('expected_exit_code') == 5,
    policy.get('expected_reboot') == 'required',
    policy.get('pause_safe_after_successful_apply') is True,
    policy.get('apply_authorized_only_with_explicit_scope_confirmation') is True,
]
raise SystemExit(0 if all(checks) else 1)
PY
}

capture_package_database() {
    local output=$1
    (
        cd "$PACKAGE_DATABASE" || exit 1
        find . -maxdepth 1 -type f -printf '%P\0' | LC_ALL=C sort -z |
            while IFS= read -r -d '' record; do sha256sum -- "$record"; done
    ) > "$output"
}

capture_path_state() {
    local path=$1 output=$2 type metadata digest target
    if [ -L "$path" ]; then
        type=symlink
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        target=$(readlink -- "$path") || return 1
        digest=
        [ -e "$path" ] && digest=$(sha256sum -- "$path" | awk '{print $1}')
        printf '%s|%s|%s|%s|%s\n' "$path" "$type" "$target" "$metadata" "$digest" >> "$output"
    elif [ -f "$path" ]; then
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        digest=$(sha256sum -- "$path" | awk '{print $1}') || return 1
        printf '%s|regular||%s|%s\n' "$path" "$metadata" "$digest" >> "$output"
    elif [ -d "$path" ]; then
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        printf '%s|directory||%s|\n' "$path" "$metadata" >> "$output"
    elif [ -e "$path" ]; then
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        printf '%s|other||%s|\n' "$path" "$metadata" >> "$output"
    else
        printf '%s|missing|||\n' "$path" >> "$output"
    fi
}

capture_sensitive_state() {
    local output=$1 path
    : > "$output"
    for path in \
        /boot/vmlinuz-generic "/boot/vmlinuz-$CONFIRM_TARGET_KERNEL" /boot/vmlinuz-6.18.40 \
        /boot/initrd-generic.img "/boot/initrd-$CONFIRM_TARGET_KERNEL.img" /boot/initrd-6.18.40.img \
        /boot/initrd.gz /boot/grub/grub.cfg /etc/default/geninitrd \
        /usr/sbin/geninitrd /usr/share/mkinitrd/mkinitrd_command_generator.sh \
        /var/lib/pkgtools/setup/setup.01.mkinitrd "/lib/modules/$CONFIRM_TARGET_KERNEL" /lib/modules/6.18.40; do
        capture_path_state "$path" "$output" || return 1
    done
}

validate_live_host_identity() {
    [ "$HOSTNAME_SHORT" = "$CONFIRM_HOSTNAME" ] || return 1
    [ "$HOSTNAME_FQDN" = "$CONFIRM_HOSTNAME_FQDN" ] || return 1
}

validate_live_pre_state() {
    [ "$RUNNING_KERNEL_BEFORE" = 6.18.40 ] || return 1
    [ -L /boot/vmlinuz-generic ] && [ "$(readlink -- /boot/vmlinuz-generic)" = vmlinuz-6.18.40 ] || return 1
    [ "$(sha256sum /boot/vmlinuz-6.18.40 | awk '{print $1}')" = 8899359f0c1f6fc018f8079ba0c76e886b12b8087ff7dccc695c459b40fb9aae ] || return 1
    [ -L /boot/initrd-generic.img ] && [ "$(readlink -- /boot/initrd-generic.img)" = initrd-6.18.40.img ] || return 1
    [ "$(sha256sum /boot/initrd-6.18.40.img | awk '{print $1}')" = 0da0e0289d93cdf2d3b78288bfa23db4c9437b576563f92889399b2c98294442 ] || return 1
    [ "$(sha256sum /boot/grub/grub.cfg | awk '{print $1}')" = 5fdff76d42ddec26b0c212668c4981a9ea2853a98b3260f33850c91ccf8ac247 ] || return 1
    [ "$(sha256sum /etc/default/geninitrd | awk '{print $1}')" = b779a2b578515a9e2059047311bf817723183b90707f1e31ce67bd96fd19b283 ] || return 1
    [ ! -e "/boot/vmlinuz-$CONFIRM_TARGET_KERNEL" ] && [ ! -L "/boot/vmlinuz-$CONFIRM_TARGET_KERNEL" ] || return 1
    [ ! -e "/boot/initrd-$CONFIRM_TARGET_KERNEL.img" ] && [ ! -L "/boot/initrd-$CONFIRM_TARGET_KERNEL.img" ] || return 1
    [ ! -e "/lib/modules/$CONFIRM_TARGET_KERNEL" ] && [ ! -L "/lib/modules/$CONFIRM_TARGET_KERNEL" ] || return 1
}

verify_nested_archive() {
    local archive=$1
    [ -f "$archive" ] && [ ! -L "$archive" ] && [ -f "$archive.sha256" ] && [ ! -L "$archive.sha256" ] || return 1
    (cd "$(dirname -- "$archive")" && sha256sum -c "${archive##*/}.sha256" >/dev/null)
}

validate_child_apply() {
    local child=$1
    python3 - "$child/summary.txt" "$child/apply.json" "$AUTHORIZATION_POLICY" \
        "$CONFIRM_CANDIDATES_SHA256" "$CONFIRM_TARGET_KERNEL" <<'PY'
import json
import pathlib
import sys

summary_path, apply_path, policy_path, candidate_sha, target_kernel = sys.argv[1:]
summary = {}
for line in pathlib.Path(summary_path).read_text(encoding='utf-8').splitlines():
    if '=' in line:
        key, value = line.split('=', 1)
        summary[key] = value
apply = json.loads(pathlib.Path(apply_path).read_text(encoding='utf-8'))
policy = json.loads(pathlib.Path(policy_path).read_text(encoding='utf-8'))
modules = apply.get('modules', {})
slackware = modules.get('slackware', {})
boot = modules.get('boot', {})
checks = [
    summary.get('scenario') == 'normal-update',
    summary.get('mode') == 'apply',
    summary.get('target') == 'slackware-current',
    summary.get('result') == 'PASS',
    summary.get('candidate_set_sha256') == candidate_sha,
    summary.get('total_candidates') == '137',
    summary.get('install_new_candidates') == '1',
    summary.get('upgrade_candidates') == '136',
    summary.get('kernel_candidates') == '2',
    summary.get('critical_candidates') == '0',
    summary.get('apply_exit_code') == '5',
    apply.get('operation') == 'apply',
    apply.get('success') is True,
    apply.get('partial') is False,
    apply.get('boot_safe') is True,
    apply.get('exit_code') == 5,
    apply.get('reboot') == 'required',
    apply.get('errors') == [],
    slackware.get('state') == 'success',
    slackware.get('update_exit_code') == 0,
    slackware.get('install_new_exit_code') in (0, 20),
    slackware.get('upgrade_all_exit_code') in (0, 20),
    slackware.get('postinstall_policy') == 'defer',
    slackware.get('postinstall_processing_enabled') is False,
    slackware.get('pending_new_config_files_valid') is True,
    slackware.get('snapshot_before_valid') is True,
    slackware.get('snapshot_after_valid') is True,
    slackware.get('secondary_modules_blocked') is False,
    slackware.get('kernel_changes') is True,
    boot.get('mode') == policy.get('expected_boot_mode'),
    boot.get('state') == policy.get('expected_boot_state'),
    boot.get('initrd_required') is True,
    boot.get('initrd_state') == policy.get('expected_initrd_state'),
    boot.get('grub_required') is True,
    boot.get('grub_state') == policy.get('expected_grub_state'),
    boot.get('geninitrd_policy_override_required') is True,
    boot.get('geninitrd_policy_override_applied') is True,
    boot.get('geninitrd_policy_override_restored') is True,
    boot.get('geninitrd_policy_override_active') is False,
    boot.get('geninitrd_policy_override_status') == policy.get('expected_geninitrd_policy_override_status'),
    boot.get('geninitrd_post_state') == policy.get('expected_geninitrd_post_state'),
    boot.get('geninitrd_post_kernel_version') == target_kernel,
    boot.get('geninitrd_post_kernel_path') == policy.get('expected_post_kernel_path'),
    boot.get('geninitrd_post_modules_path') == policy.get('expected_post_modules_path'),
    boot.get('geninitrd_post_initrd_path') == policy.get('expected_post_initrd_path'),
    boot.get('geninitrd_post_named_link') == policy.get('expected_post_named_link'),
    boot.get('grub_command_attempted') is True,
    boot.get('grub_config_replaced') is True,
    boot.get('grub_blocked_by_initrd') is False,
]
raise SystemExit(0 if all(checks) else 1)
PY
}

grub_config_references_path() {
    local kind=$1 path=$2 alternate=
    case "$path" in /boot/*) alternate=${path#/boot} ;; esac
    case "$kind" in
        kernel)
            awk -v expected="$path" -v alternate="$alternate" '
                ($1 == "linux" || $1 == "linuxefi") &&
                ($2 == expected || (alternate != "" && $2 == alternate)) { found=1 }
                END { exit !found }
            ' /boot/grub/grub.cfg
            ;;
        initrd)
            awk -v expected="$path" -v alternate="$alternate" '
                ($1 == "initrd" || $1 == "initrdefi") {
                    for (i=2; i<=NF; i++) {
                        if ($i == expected || (alternate != "" && $i == alternate)) found=1
                    }
                }
                END { exit !found }
            ' /boot/grub/grub.cfg
            ;;
        *) return 1 ;;
    esac
}

validate_post_apply_files() {
    [ -f "/boot/vmlinuz-$CONFIRM_TARGET_KERNEL" ] && [ ! -L "/boot/vmlinuz-$CONFIRM_TARGET_KERNEL" ] || return 1
    [ -d "/lib/modules/$CONFIRM_TARGET_KERNEL" ] && [ ! -L "/lib/modules/$CONFIRM_TARGET_KERNEL" ] || return 1
    [ -f "/boot/initrd-$CONFIRM_TARGET_KERNEL.img" ] && [ ! -L "/boot/initrd-$CONFIRM_TARGET_KERNEL.img" ] || return 1
    [ -L /boot/vmlinuz-generic ] && [ "$(readlink -- /boot/vmlinuz-generic)" = "vmlinuz-$CONFIRM_TARGET_KERNEL" ] || return 1
    [ -L /boot/initrd-generic.img ] && [ "$(readlink -- /boot/initrd-generic.img)" = "initrd-$CONFIRM_TARGET_KERNEL.img" ] || return 1
    [ -f /boot/vmlinuz-6.18.40 ] && [ -f /boot/initrd-6.18.40.img ] && [ -d /lib/modules/6.18.40 ] || return 1
    [ "$(sha256sum /etc/default/geninitrd | awk '{print $1}')" = b779a2b578515a9e2059047311bf817723183b90707f1e31ce67bd96fd19b283 ] || return 1
    grub_config_references_path kernel "/boot/vmlinuz-$CONFIRM_TARGET_KERNEL" || return 1
    grub_config_references_path initrd "/boot/initrd-$CONFIRM_TARGET_KERNEL.img" || return 1
}

write_analysis() {
    python3 - "$OUTPUT_DIR/authorization-analysis.json" <<PY
import json, pathlib
record = {
  'scenario': 'current-normal-update-authorized-apply',
  'target': '$TARGET',
  'hostname_short': '$HOSTNAME_SHORT',
  'hostname_fqdn': '$HOSTNAME_FQDN',
  'running_kernel_before': '$RUNNING_KERNEL_BEFORE',
  'running_kernel_after': '$RUNNING_KERNEL_AFTER',
  'target_kernel': '$CONFIRM_TARGET_KERNEL',
  'candidate_set_sha256': '$CONFIRM_CANDIDATES_SHA256',
  'readiness_archive_sha256': '$CONFIRM_READINESS_SHA256',
  'authorization_scope_sha256': '$CONFIRM_AUTHORIZATION_SHA256',
  'transaction_status': '$TRANSACTION_STATUS',
  'child_status': int('$CHILD_STATUS'),
  'package_transaction_executed': '$TRANSACTION_STATUS' == 'applied-and-boot-prepared',
  'apply_ready': '$APPLY_READY' == 'true',
  'apply_authorized': '$APPLY_AUTHORIZED' == 'true',
  'pause_safe': '$PAUSE_SAFE' == 'true',
  'pause_safety_reason': '$PAUSE_SAFETY_REASON',
  'next_stage': '$NEXT_STAGE',
  'assertions': {'passes': $PASS_COUNT, 'failures': $FAILURE_COUNT}
}
pathlib.Path('$OUTPUT_DIR/authorization-analysis.json').write_text(json.dumps(record, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

write_summary() {
    local result=PASS
    [ "$FAILURE_COUNT" -eq 0 ] || result=FAIL
    {
        printf 'scenario=current-normal-update-authorized-apply\n'
        printf 'target=%s\n' "$TARGET"
        printf 'hostname_short=%s\n' "$HOSTNAME_SHORT"
        printf 'hostname_fqdn=%s\n' "$HOSTNAME_FQDN"
        printf 'result=%s\n' "$result"
        printf 'passes=%d\n' "$PASS_COUNT"
        printf 'failures=%d\n' "$FAILURE_COUNT"
        printf 'running_kernel_before=%s\n' "$RUNNING_KERNEL_BEFORE"
        printf 'running_kernel_after=%s\n' "$RUNNING_KERNEL_AFTER"
        printf 'target_kernel=%s\n' "$CONFIRM_TARGET_KERNEL"
        printf 'candidate_set_sha256=%s\n' "$CONFIRM_CANDIDATES_SHA256"
        printf 'readiness_archive_sha256=%s\n' "$CONFIRM_READINESS_SHA256"
        printf 'authorization_scope_sha256=%s\n' "$CONFIRM_AUTHORIZATION_SHA256"
        printf 'transaction_status=%s\n' "$TRANSACTION_STATUS"
        printf 'child_status=%s\n' "$CHILD_STATUS"
        printf 'apply_ready=%s\n' "$APPLY_READY"
        printf 'apply_authorized=%s\n' "$APPLY_AUTHORIZED"
        printf 'pause_safe=%s\n' "$PAUSE_SAFE"
        printf 'pause_safety_reason=%s\n' "$PAUSE_SAFETY_REASON"
        printf 'next_stage=%s\n' "$NEXT_STAGE"
    } > "$OUTPUT_DIR/summary.txt"
}

create_evidence_archive() {
    local parent base archive
    parent=$(dirname -- "$OUTPUT_DIR")
    base=$(basename -- "$OUTPUT_DIR")
    archive="$OUTPUT_DIR.tar.gz"
    tar -C "$parent" -czf "$archive" "$base" || return 1
    chmod 0600 "$archive"
    (cd "$parent" && sha256sum -- "${archive##*/}") > "$archive.sha256" || return 1
    chmod 0600 "$archive.sha256"
    printf '%s\n' "$archive"
}

print_evidence_commands() {
    local archive=$1 owner=${SUDO_USER:-promano} group home
    [ -n "$owner" ] && [ "$owner" != root ] || owner=promano
    group=$(id -gn "$owner" 2>/dev/null || printf users)
    home=$(awk -F: -v owner="$owner" '$1 == owner {print $6; exit}' /etc/passwd)
    [ -n "$home" ] || home="/home/$owner"
    printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
        "$owner" "$group" "$archive" "$home/${archive##*/}" \
        "$owner" "$group" "$archive.sha256" "$home/${archive##*/}.sha256"
    printf 'Verify evidence command: cd %q && sha256sum -c %q\n' "$home" "${archive##*/}.sha256"
}

finish() {
    local archive
    RUNNING_KERNEL_AFTER=$(uname -r 2>/dev/null || true)
    capture_package_database "$OUTPUT_DIR/packages.after.txt" || true
    capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" || true
    write_analysis
    write_summary
    archive=$(create_evidence_archive) || { error 'failed to create evidence archive'; return 1; }
    printf 'Slackware-current authorized apply result: candidates=%s, running=%s, target=%s, transaction=%s, pause-safe=%s, apply-authorized=%s, next-stage=%s\n' \
        "$CONFIRM_CANDIDATES_SHA256" "$RUNNING_KERNEL_AFTER" "$CONFIRM_TARGET_KERNEL" "$TRANSACTION_STATUS" "$PAUSE_SAFE" "$APPLY_AUTHORIZED" "$NEXT_STAGE"
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$archive.sha256")"
    print_evidence_commands "$archive"
    [ "$FAILURE_COUNT" -eq 0 ]
}

main() {
    local timestamp child_dir child_archive

    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this authorized apply requires root'; return 2; }
    for command_name in awk cmp date find grep hostname python3 readlink sha256sum sort stat tar uname; do
        command -v "$command_name" >/dev/null 2>&1 || { error "required command is unavailable: $command_name"; return 2; }
    done
    for path in "$READINESS_RECORD" "$AUTHORIZATION_POLICY" "$NORMAL_UPDATE_SCRIPT" "$REFERENCE_SCRIPT"; do
        require_regular_file "$path" || { error "reviewed file is missing or unsafe: $path"; return 2; }
    done
    bash -n "$NORMAL_UPDATE_SCRIPT" || { error 'normal-update acceptance script has invalid shell syntax'; return 2; }
    bash -n "$REFERENCE_SCRIPT" || { error 'reference engine has invalid shell syntax'; return 2; }

    HOSTNAME_SHORT=$(hostname -s)
    HOSTNAME_FQDN=$(hostname -f)
    RUNNING_KERNEL_BEFORE=$(uname -r)
    PACKAGE_DATABASE=/var/lib/pkgtools/packages
    [ -d "$PACKAGE_DATABASE" ] || PACKAGE_DATABASE=/var/log/packages
    [ -d "$PACKAGE_DATABASE" ] || { error 'Slackware package database is unavailable'; return 2; }

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/slackware-current-$timestamp"
    [ ! -e "$OUTPUT_DIR" ] || { error "output directory already exists: $OUTPUT_DIR"; return 2; }
    mkdir -m 0700 -p "$OUTPUT_DIR/nested"
    ASSERTION_LOG="$OUTPUT_DIR/assertions.log"
    : > "$ASSERTION_LOG"

    if validate_reviewed_authorization; then
        record_pass 'the accepted readiness and authorization policy bind the exact 137-package apply scope'
    else
        record_failure 'the accepted readiness or explicit authorization scope is missing, changed, or mismatched'
    fi
    if validate_live_host_identity && [ "$CONFIRM_TARGET_KERNEL" = 6.18.42 ]; then
        record_pass 'the explicit short hostname, FQDN, candidate, kernel, readiness, and authorization confirmations match the reviewed boundary'
    else
        record_failure 'the explicit host identity or target confirmation does not match the reviewed boundary'
    fi
    capture_package_database "$OUTPUT_DIR/packages.before.txt" && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt" \
        && record_pass 'the package database and apply-sensitive state were captured before authorization' \
        || record_failure 'the package database or apply-sensitive state could not be captured before authorization'
    validate_live_pre_state \
        && record_pass 'the live 6.18.40 boot state exactly matches the accepted readiness evidence' \
        || record_failure 'the live boot state changed after readiness; real apply is blocked'

    if [ "$FAILURE_COUNT" -ne 0 ]; then
        TRANSACTION_STATUS=precondition-failed
        APPLY_READY=false
        NEXT_STAGE=manual-review-required
        finish
        return $?
    fi

    APPLY_AUTHORIZED=true
    TRANSACTION_STATUS=final-revalidation-and-apply-running
    child_dir="$OUTPUT_DIR/nested/normal-update-apply"
    printf 'Running final candidate revalidation and the explicitly authorized package transaction...\n'
    CHILD_STATUS=0
    bash "$NORMAL_UPDATE_SCRIPT" \
        --target slackware-current \
        --execute-apply \
        --confirm-hostname "$HOSTNAME_FQDN" \
        --confirm-candidates-sha256 "$CONFIRM_CANDIDATES_SHA256" \
        --allow-kernel-update \
        --confirm-kernel-boot-preflight-sha256 "$CONFIRM_READINESS_SHA256" \
        --output-dir "$child_dir" \
        > "$OUTPUT_DIR/normal-update-apply.stdout.log" \
        2> "$OUTPUT_DIR/normal-update-apply.stderr.log" || CHILD_STATUS=$?
    printf '%d\n' "$CHILD_STATUS" > "$OUTPUT_DIR/normal-update-apply.exit"

    if [ "$CHILD_STATUS" -eq 0 ]; then
        record_pass 'the embedded normal-update apply completed after its own final candidate revalidation'
    else
        record_failure "the embedded normal-update apply failed with status $CHILD_STATUS"
    fi
    child_archive="$child_dir.tar.gz"
    verify_nested_archive "$child_archive" \
        && record_pass 'the nested normal-update apply archive and portable sidecar verify inside the authorization evidence' \
        || record_failure 'the nested normal-update apply evidence failed verification'
    validate_child_apply "$child_dir" \
        && record_pass 'the child result satisfies the exact 137-package, deferred-postinstall, boot-safe apply contract' \
        || record_failure 'the child result does not satisfy the reviewed authorized-apply contract'

    capture_package_database "$OUTPUT_DIR/packages.after-apply.txt" || record_failure 'the package database could not be captured after apply'
    if [ -s "$OUTPUT_DIR/packages.after-apply.txt" ] && ! cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after-apply.txt"; then
        record_pass 'the authorized transaction changed the installed package database'
    else
        record_failure 'the authorized transaction did not produce the required package database change'
    fi
    if [ -f "/boot/vmlinuz-$CONFIRM_TARGET_KERNEL" ] && [ -d "/lib/modules/$CONFIRM_TARGET_KERNEL" ]; then
        record_pass 'the reviewed target kernel and module tree are installed'
    else
        record_failure 'the reviewed target kernel or module tree is missing after apply'
    fi
    if [ -f "/boot/initrd-$CONFIRM_TARGET_KERNEL.img" ] \
        && [ -L /boot/initrd-generic.img ] \
        && [ "$(readlink -- /boot/initrd-generic.img)" = "initrd-$CONFIRM_TARGET_KERNEL.img" ]; then
        record_pass 'the target versioned initrd and named link are installed'
    else
        record_failure 'the target versioned initrd or named link is incomplete'
    fi
    if grub_config_references_path kernel "/boot/vmlinuz-$CONFIRM_TARGET_KERNEL" \
        && grub_config_references_path initrd "/boot/initrd-$CONFIRM_TARGET_KERNEL.img"; then
        record_pass 'the active GRUB configuration references both target kernel and target initrd'
    else
        record_failure 'the active GRUB configuration does not contain the reviewed target pair'
    fi
    if [ "$(sha256sum /etc/default/geninitrd | awk '{print $1}')" = b779a2b578515a9e2059047311bf817723183b90707f1e31ce67bd96fd19b283 ]; then
        record_pass 'the temporary GenInitrd GRUB policy override was restored byte-for-byte'
    else
        record_failure 'the GenInitrd policy was not restored to the accepted digest'
    fi
    if [ -f /boot/vmlinuz-6.18.40 ] && [ -f /boot/initrd-6.18.40.img ] && [ -d /lib/modules/6.18.40 ]; then
        record_pass 'the running 6.18.40 kernel, initrd, and modules remain available for rollback'
    else
        record_failure 'the pre-transaction kernel rollback artifacts are incomplete'
    fi
    RUNNING_KERNEL_AFTER=$(uname -r)
    if [ "$RUNNING_KERNEL_AFTER" = 6.18.40 ]; then
        record_pass 'the current session remains on 6.18.40 pending an explicit reboot verification'
    else
        record_failure 'the running kernel changed unexpectedly during the package transaction'
    fi
    validate_post_apply_files \
        && record_pass 'all target and rollback boot artifacts satisfy the reviewed post-apply boundary' \
        || record_failure 'the final target or rollback boot-artifact boundary is incomplete'

    if [ "$FAILURE_COUNT" -eq 0 ]; then
        TRANSACTION_STATUS=applied-and-boot-prepared
        PAUSE_SAFE=true
        PAUSE_SAFETY_REASON=reviewed-package-transaction-complete-and-boot-artifacts-validated
        NEXT_STAGE=current-kernel-post-apply-verification
        record_pass 'the reviewed transaction is complete and later Slackware-current publications no longer invalidate it'
    else
        TRANSACTION_STATUS=failed-or-partial
        PAUSE_SAFE=false
        PAUSE_SAFETY_REASON=authorized-apply-did-not-reach-the-reviewed-complete-state
        NEXT_STAGE=manual-recovery-review-required
    fi

    finish
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
