#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_OUTPUT_ROOT=${RECOVERY_OUTPUT_ROOT:-/var/tmp/slack-update-acceptance/current-post-package-boot-recovery-verification}
POLICY=${RECOVERY_POLICY_PATH:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-post-package-boot-recovery-policy.json}

TARGET=
OUTPUT_DIR=
CONFIRM_HOSTNAME=
CONFIRM_HOSTNAME_FQDN=
CONFIRM_POST_APPLY_EVIDENCE_SHA256=
CONFIRM_TARGET_KERNEL=
PASS_COUNT=0
FAILURE_COUNT=0
ASSERTION_LOG=
PACKAGE_DATABASE=
HOSTNAME_SHORT=
HOSTNAME_FQDN=
RUNNING_KERNEL=
PAUSE_SAFE=false
REBOOT_READY=false
REBOOT_AUTHORIZED=false
ROLLBACK_STATE=unknown
NEXT_STAGE=manual-review-required
ROOT_PREFIX=
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-hostname SHORT_HOSTNAME \\
                     --confirm-hostname-fqdn FQDN \\
                     --confirm-post-apply-evidence-sha256 SHA256 \\
                     --confirm-target-kernel VERSION [options]

Verify the exact post-package state left by the reviewed Slackware-current
transaction. This command does not refresh metadata, install packages, execute
maintainer scripts, generate an initrd, or modify GRUB. It proves that the
completed package transaction installed the reviewed 6.18.42 kernel and initrd,
that the unchanged accepted GRUB configuration still pairs the generic kernel
and initrd links in one menuentry, and that both links now resolve to the exact
target artifacts.

A successful result reports pause_safe=true because later Slackware-current
publications no longer invalidate the completed installed transaction. The old
6.18.40 image and initrd are expected to be absent, so reboot remains subject to
a separate explicit review.

Required options:
      --target slackware-current
      --confirm-hostname SHORT_HOSTNAME
      --confirm-hostname-fqdn FQDN
      --confirm-post-apply-evidence-sha256 SHA256
      --confirm-target-kernel VERSION

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
            --confirm-hostname) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME=$2; shift 2 ;;
            --confirm-hostname-fqdn) [ "$#" -ge 2 ] || return 1; CONFIRM_HOSTNAME_FQDN=$2; shift 2 ;;
            --confirm-post-apply-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_POST_APPLY_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-target-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_TARGET_KERNEL=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done

    [ "$TARGET" = slackware-current ] || return 1
    [ -n "$CONFIRM_HOSTNAME" ] && [ -n "$CONFIRM_HOSTNAME_FQDN" ] || return 1
    case "$CONFIRM_HOSTNAME$CONFIRM_HOSTNAME_FQDN" in *[[:space:]]*) return 1 ;; esac
    is_sha256 "$CONFIRM_POST_APPLY_EVIDENCE_SHA256" || return 1
    is_safe_kernel_version "$CONFIRM_TARGET_KERNEL" || return 1
    if [ -n "$OUTPUT_DIR" ]; then
        case "$OUTPUT_DIR" in /*) ;; *) return 1 ;; esac
    fi
}

rooted() {
    printf '%s%s\n' "$ROOT_PREFIX" "$1"
}

require_regular_file() {
    [ -f "$1" ] && [ ! -L "$1" ] && [ -r "$1" ]
}

file_sha256() {
    sha256sum -- "$1" | awk '{print $1}'
}

file_size() {
    stat -Lc '%s' -- "$1"
}

capture_package_database() {
    local output=$1
    (
        cd "$PACKAGE_DATABASE" || exit 1
        find . -maxdepth 1 -type f -printf '%P\0' | LC_ALL=C sort -z |
            while IFS= read -r -d '' record; do sha256sum -- "$record"; done
    ) > "$output"
}

capture_package_names() {
    local output=$1
    (
        cd "$PACKAGE_DATABASE" || exit 1
        find . -maxdepth 1 -type f -printf '%P\n' | LC_ALL=C sort
    ) > "$output"
}

capture_path_state() {
    local path=$1 output=$2 type metadata digest target
    if [ -L "$path" ]; then
        target=$(readlink -- "$path") || return 1
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        digest=$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}') || digest=
        printf '%s|symlink|%s|%s|%s\n' "${path#$ROOT_PREFIX}" "$target" "$metadata" "$digest" >> "$output"
    elif [ -f "$path" ]; then
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        digest=$(file_sha256 "$path") || return 1
        printf '%s|regular||%s|%s\n' "${path#$ROOT_PREFIX}" "$metadata" "$digest" >> "$output"
    elif [ -d "$path" ]; then
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        printf '%s|directory||%s|\n' "${path#$ROOT_PREFIX}" "$metadata" >> "$output"
    elif [ -e "$path" ]; then
        type=$(stat -c '%F' -- "$path" 2>/dev/null || printf unknown)
        printf '%s|unsafe-%s|||\n' "${path#$ROOT_PREFIX}" "$type" >> "$output"
    else
        printf '%s|missing|||\n' "${path#$ROOT_PREFIX}" >> "$output"
    fi
}

capture_sensitive_state() {
    local output=$1 path
    : > "$output"
    for path in \
        /boot/vmlinuz-generic \
        "/boot/vmlinuz-$CONFIRM_TARGET_KERNEL" \
        /boot/vmlinuz-6.18.40 \
        /boot/initrd-generic.img \
        "/boot/initrd-$CONFIRM_TARGET_KERNEL.img" \
        /boot/initrd-6.18.40.img \
        /boot/initrd.gz \
        /boot/grub/grub.cfg \
        /etc/default/geninitrd \
        "/lib/modules/$CONFIRM_TARGET_KERNEL" \
        /lib/modules/6.18.40; do
        capture_path_state "$(rooted "$path")" "$output" || return 1
    done
}

validate_policy_binding() {
    python3 - "$POLICY" "$CONFIRM_HOSTNAME" "$CONFIRM_HOSTNAME_FQDN" \
        "$CONFIRM_POST_APPLY_EVIDENCE_SHA256" "$CONFIRM_TARGET_KERNEL" <<'PY'
import json
import pathlib
import sys

policy_path, hostname_short, hostname_fqdn, evidence_sha, target_kernel = sys.argv[1:]
p = pathlib.Path(policy_path)
if not p.is_file() or p.is_symlink():
    raise SystemExit(1)
d = json.loads(p.read_text(encoding='utf-8'))
checks = [
    d.get('scenario') == 'current-post-package-boot-recovery-verification',
    d.get('target') == 'slackware-current',
    d.get('reviewed') is True,
    d.get('accepted_failed_apply_archive_sha256') == evidence_sha,
    d.get('required_hostname_short') == hostname_short,
    d.get('required_hostname_fqdn') == hostname_fqdn,
    d.get('running_kernel') == '6.18.40',
    d.get('target_kernel') == target_kernel,
    d.get('package_transaction_executed') is True,
    d.get('package_transaction_completed') is True,
    d.get('expected_pause_safe') is True,
    d.get('reboot_authorized') is False,
    d.get('active_grub_mutation_required') is False,
    d.get('next_stage') == 'current-kernel-post-apply-reboot-review',
]
raise SystemExit(0 if all(checks) else 1)
PY
}

policy_value() {
    python3 - "$POLICY" "$1" <<'PY'
import json, sys
value = json.load(open(sys.argv[1], encoding='utf-8'))
for part in sys.argv[2].split('.'):
    value = value[part]
if isinstance(value, bool):
    print(str(value).lower())
else:
    print(value)
PY
}

validate_package_state() {
    local snapshot=$1 names=$2 expected_count expected_snapshot expected_names count
    expected_count=$(policy_value installed_package_count) || return 1
    expected_snapshot=$(policy_value installed_package_database_snapshot_sha256) || return 1
    expected_names=$(policy_value installed_package_name_snapshot_sha256) || return 1
    count=$(wc -l < "$names") || return 1
    [ "$count" -eq "$expected_count" ] || return 1
    [ "$(file_sha256 "$snapshot")" = "$expected_snapshot" ] || return 1
    [ "$(file_sha256 "$names")" = "$expected_names" ] || return 1
}

validate_package_records() {
    python3 - "$POLICY" "$PACKAGE_DATABASE" <<'PY'
import hashlib
import json
import pathlib
import sys

policy_path, package_database = sys.argv[1:]
d = json.load(open(policy_path, encoding='utf-8'))
root = pathlib.Path(package_database)
for record in d['required_package_records']:
    path = root / record['name']
    if not path.is_file() or path.is_symlink():
        raise SystemExit(1)
    if hashlib.sha256(path.read_bytes()).hexdigest() != record['record_sha256']:
        raise SystemExit(1)
for name in d['forbidden_package_records']:
    if (root / name).exists() or (root / name).is_symlink():
        raise SystemExit(1)
raise SystemExit(0)
PY
}

validate_exact_regular() {
    local path=$1 expected_sha=$2 expected_size=$3 mode uid gid metadata
    [ -f "$path" ] && [ ! -L "$path" ] || return 1
    metadata=$(stat -Lc '%a %u %g' -- "$path") || return 1
    IFS=" " read -r mode uid gid <<< "$metadata"
    [ "$uid" -eq 0 ] && [ "$gid" -eq 0 ] || return 1
    case "$mode" in 600|644|700|755) ;; *) return 1 ;; esac
    [ "$(file_size "$path")" -eq "$expected_size" ] || return 1
    [ "$(file_sha256 "$path")" = "$expected_sha" ]
}

validate_target_artifacts() {
    local kernel initrd modules generic_link named_link
    kernel=$(rooted "/boot/vmlinuz-$CONFIRM_TARGET_KERNEL")
    initrd=$(rooted "/boot/initrd-$CONFIRM_TARGET_KERNEL.img")
    modules=$(rooted "/lib/modules/$CONFIRM_TARGET_KERNEL")
    generic_link=$(rooted /boot/vmlinuz-generic)
    named_link=$(rooted /boot/initrd-generic.img)

    validate_exact_regular "$kernel" "$(policy_value target_artifacts.kernel_sha256)" "$(policy_value target_artifacts.kernel_size)" || return 1
    validate_exact_regular "$initrd" "$(policy_value target_artifacts.initrd_sha256)" "$(policy_value target_artifacts.initrd_size)" || return 1
    [ -d "$modules" ] && [ ! -L "$modules" ] || return 1
    find "$modules" -mindepth 1 -print -quit | grep -q . || return 1
    [ -L "$generic_link" ] && [ "$(readlink -- "$generic_link")" = "vmlinuz-$CONFIRM_TARGET_KERNEL" ] || return 1
    [ -L "$named_link" ] && [ "$(readlink -- "$named_link")" = "initrd-$CONFIRM_TARGET_KERNEL.img" ] || return 1
}

validate_geninitrd_boundary() {
    local policy_path geninitrd generator setup
    policy_path=$(rooted /etc/default/geninitrd)
    geninitrd=$(rooted /usr/sbin/geninitrd)
    generator=$(rooted /usr/share/mkinitrd/mkinitrd_command_generator.sh)
    setup=$(rooted /var/lib/pkgtools/setup/setup.01.mkinitrd)
    validate_exact_regular "$policy_path" "$(policy_value geninitrd.policy_sha256)" "$(policy_value geninitrd.policy_size)" || return 1
    validate_exact_regular "$geninitrd" "$(policy_value geninitrd.geninitrd_sha256)" "$(policy_value geninitrd.geninitrd_size)" || return 1
    validate_exact_regular "$generator" "$(policy_value geninitrd.generator_sha256)" "$(policy_value geninitrd.generator_size)" || return 1
    validate_exact_regular "$setup" "$(policy_value geninitrd.setup_sha256)" "$(policy_value geninitrd.setup_size)" || return 1
}

validate_grub_kernel_initrd_pair() {
    local grub=$1 kernel=$2 initrd=$3
    python3 - "$grub" "$kernel" "$initrd" <<'PY'
import pathlib, re, sys
path, kernel, initrd = sys.argv[1:]
try:
    lines = pathlib.Path(path).read_text(encoding='utf-8', errors='strict').splitlines()
except Exception:
    raise SystemExit(1)
blocks=[]
active=None
depth=0
for line in lines:
    stripped=line.strip()
    if active is None and stripped.startswith('menuentry '):
        active=[]
        depth=0
    if active is not None:
        active.append(stripped)
        depth += stripped.count('{') - stripped.count('}')
        if depth <= 0 and len(active) > 1:
            blocks.append(active)
            active=None
for block in blocks:
    linux_ok=any(re.match(r'^linux(?:efi)?\s+', line) and kernel in line.split() for line in block)
    initrd_ok=any(re.match(r'^initrd(?:efi)?\s+', line) and initrd in line.split() for line in block)
    if linux_ok and initrd_ok:
        raise SystemExit(0)
raise SystemExit(1)
PY
}

validate_active_grub() {
    local grub
    grub=$(rooted /boot/grub/grub.cfg)
    validate_exact_regular "$grub" "$(policy_value active_grub.sha256)" "$(policy_value active_grub.size)" || return 1
    grub-script-check "$grub" >/dev/null 2>&1 || return 1
    validate_grub_kernel_initrd_pair "$grub" /boot/vmlinuz-generic /boot/initrd-generic.img
}

validate_degraded_rollback() {
    [ ! -e "$(rooted /boot/vmlinuz-6.18.40)" ] && [ ! -L "$(rooted /boot/vmlinuz-6.18.40)" ] || return 1
    [ ! -e "$(rooted /boot/initrd-6.18.40.img)" ] && [ ! -L "$(rooted /boot/initrd-6.18.40.img)" ] || return 1
    [ -d "$(rooted /lib/modules/6.18.40)" ] && [ ! -L "$(rooted /lib/modules/6.18.40)" ] || return 1
    ROLLBACK_STATE=degraded-running-session-and-modules-only
}

write_analysis() {
    python3 - "$OUTPUT_DIR/recovery-analysis.json" "$HOSTNAME_SHORT" "$HOSTNAME_FQDN" \
        "$RUNNING_KERNEL" "$CONFIRM_TARGET_KERNEL" "$PASS_COUNT" "$FAILURE_COUNT" \
        "$ROLLBACK_STATE" "$PAUSE_SAFE" "$REBOOT_READY" "$REBOOT_AUTHORIZED" "$NEXT_STAGE" <<'PY'
import json, pathlib, sys
(output, hostname_short, hostname_fqdn, running, target, passes, failures,
 rollback, pause_safe, reboot_ready, reboot_authorized, next_stage) = sys.argv[1:]
data = {
    'scenario': 'current-post-package-boot-recovery-verification',
    'target': 'slackware-current',
    'hostname_short': hostname_short,
    'hostname_fqdn': hostname_fqdn,
    'running_kernel': running,
    'target_kernel': target,
    'package_transaction_completed': True,
    'active_grub_mutated': False,
    'target_boot_pair_verified': failures == '0',
    'rollback_state': rollback,
    'pause_safe': pause_safe == 'true',
    'pause_safety_reason': 'installed-transaction-complete-and-existing-generic-grub-pair-resolves-to-reviewed-target' if pause_safe == 'true' else 'post-package-boot-boundary-not-verified',
    'reboot_ready': reboot_ready == 'true',
    'reboot_authorized': reboot_authorized == 'true',
    'next_stage': next_stage,
    'assertions': {'passes': int(passes), 'failures': int(failures)},
}
pathlib.Path(output).write_text(json.dumps(data, indent=2, sort_keys=True) + '\n', encoding='utf-8')
PY
}

write_summary() {
    cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=current-post-package-boot-recovery-verification
target=$TARGET
hostname_short=$HOSTNAME_SHORT
hostname_fqdn=$HOSTNAME_FQDN
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
passes=$PASS_COUNT
failures=$FAILURE_COUNT
running_kernel=$RUNNING_KERNEL
target_kernel=$CONFIRM_TARGET_KERNEL
post_apply_evidence_sha256=$CONFIRM_POST_APPLY_EVIDENCE_SHA256
package_transaction_completed=true
target_boot_pair_verified=$([ "$FAILURE_COUNT" -eq 0 ] && printf true || printf false)
active_grub_mutated=false
rollback_state=$ROLLBACK_STATE
pause_safe=$PAUSE_SAFE
reboot_ready=$REBOOT_READY
reboot_authorized=$REBOOT_AUTHORIZED
next_stage=$NEXT_STAGE
EOF_SUMMARY
}

publish_evidence() {
    local timestamp archive sidecar owner group
    if [ "$TEST_MODE" = 1 ]; then
        printf 'Evidence directory (test mode): %s\n' "$OUTPUT_DIR"
        return 0
    fi
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    archive="$DEFAULT_OUTPUT_ROOT/${TARGET}-current-post-package-boot-recovery-verification-${timestamp}.tar.gz"
    sidecar="$archive.sha256"
    mkdir -p -- "$DEFAULT_OUTPUT_ROOT" || return 1
    tar -C "$(dirname -- "$OUTPUT_DIR")" -czf "$archive" "$(basename -- "$OUTPUT_DIR")" || return 1
    chmod 0600 -- "$archive"
    (cd "$(dirname -- "$archive")" && sha256sum -- "$(basename -- "$archive")" > "$(basename -- "$sidecar")") || return 1
    chmod 0600 -- "$sidecar"
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(awk '{print $1}' "$sidecar")"
    owner=${SUDO_USER:-promano}
    if id "$owner" >/dev/null 2>&1; then
        group=$(id -gn "$owner")
        printf 'Copy evidence command: sudo install -o %q -g %q -m 0600 %q %q && sudo install -o %q -g %q -m 0600 %q %q\n' \
            "$owner" "$group" "$archive" "/home/$owner/${archive##*/}" \
            "$owner" "$group" "$sidecar" "/home/$owner/${sidecar##*/}"
        printf 'Verify evidence command: cd %q && sha256sum -c %q\n' "/home/$owner" "${sidecar##*/}"
    fi
}

finish() {
    write_analysis || return 2
    write_summary
    printf 'Slackware-current post-package boot recovery result: running=%s, target=%s, transaction=installed, grub=existing-generic-pair-verified, rollback=%s, pause-safe=%s, reboot-ready=%s, reboot-authorized=%s, next-stage=%s\n' \
        "$RUNNING_KERNEL" "$CONFIRM_TARGET_KERNEL" "$ROLLBACK_STATE" "$PAUSE_SAFE" "$REBOOT_READY" "$REBOOT_AUTHORIZED" "$NEXT_STAGE"
    publish_evidence || return 2
    [ "$FAILURE_COUNT" -eq 0 ]
}

main() {
    local timestamp slackware_version grub package_record
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this verification must run as root'; return 2; }

    if [ "$TEST_MODE" = 1 ]; then
        ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
        [ -n "$ROOT_PREFIX" ] || { error 'test root is missing'; return 2; }
        PATH=${SLACK_UPDATE_TEST_PATH:-$PATH}
        HOSTNAME_SHORT=${SLACK_UPDATE_TEST_HOSTNAME_SHORT:-pcold-slack}
        HOSTNAME_FQDN=${SLACK_UPDATE_TEST_HOSTNAME_FQDN:-pcold-slack.pcold-slack.org}
        RUNNING_KERNEL=${SLACK_UPDATE_TEST_RUNNING_KERNEL:-6.18.40}
    else
        ROOT_PREFIX=
        HOSTNAME_SHORT=$(hostname -s) || return 2
        HOSTNAME_FQDN=$(hostname -f) || return 2
        RUNNING_KERNEL=$(uname -r) || return 2
    fi

    slackware_version=$(cat "$(rooted /etc/slackware-version)" 2>/dev/null || true)
    [ "$slackware_version" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command in python3 sha256sum tar find stat readlink grep cmp install grub-script-check; do
        command -v "$command" >/dev/null 2>&1 || { error "required command missing: $command"; return 2; }
    done

    if [ -d "$(rooted /var/lib/pkgtools/packages)" ] && [ ! -L "$(rooted /var/lib/pkgtools/packages)" ]; then
        PACKAGE_DATABASE=$(rooted /var/lib/pkgtools/packages)
    elif [ -d "$(rooted /var/log/packages)" ]; then
        PACKAGE_DATABASE=$(rooted /var/log/packages)
    else
        error 'installed package database is unavailable'
        return 2
    fi

    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || { error "output exists: $OUTPUT_DIR"; return 2; }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"

    validate_policy_binding \
        && record_pass 'the reviewed failed-apply evidence and recovery policy bind the exact installed post-package state' \
        || record_failure 'the failed-apply evidence or recovery policy does not match this verification boundary'
    [ "$HOSTNAME_SHORT" = "$CONFIRM_HOSTNAME" ] && [ "$HOSTNAME_FQDN" = "$CONFIRM_HOSTNAME_FQDN" ] \
        && [ "$RUNNING_KERNEL" = "$(policy_value running_kernel 2>/dev/null)" ] \
        && record_pass 'the explicit short hostname, FQDN, running kernel, and target confirmation match the reviewed host' \
        || record_failure 'the live host identity or running kernel no longer matches the reviewed post-package state'

    capture_package_database "$OUTPUT_DIR/packages.before.txt" \
        && capture_package_names "$OUTPUT_DIR/package-names.before.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt" \
        && record_pass 'the package database and boot-sensitive post-package state were captured before verification' \
        || record_failure 'the initial package or boot-sensitive state could not be captured'

    validate_package_state "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/package-names.before.txt" \
        && record_pass 'the installed package database exactly matches the completed 2040-record transaction snapshot' \
        || record_failure 'the installed package database has drifted from the completed reviewed transaction'
    validate_package_records \
        && record_pass 'the exact target kernel, headers, source, GRUB, and Breeze records are installed and the replaced kernel records are absent' \
        || record_failure 'the installed package records do not match the reviewed post-package boundary'
    validate_target_artifacts \
        && record_pass 'the target kernel, module tree, versioned initrd, and both generic links match the reviewed 6.18.42 artifacts' \
        || record_failure 'the target kernel, initrd, modules, or generic links are incomplete or changed'
    validate_geninitrd_boundary \
        && record_pass 'the restored GenInitrd policy and installed generator control files retain their accepted identities' \
        || record_failure 'the GenInitrd policy or installed generator control files changed after package application'
    validate_active_grub \
        && install -m 0600 -- "$(rooted /boot/grub/grub.cfg)" "$OUTPUT_DIR/grub.cfg.verified" \
        && record_pass 'the unchanged syntax-valid GRUB configuration pairs the generic kernel and initrd links in one menuentry' \
        || record_failure 'the active GRUB configuration no longer exposes the accepted generic kernel/initrd pair'
    validate_degraded_rollback \
        && record_pass 'the missing 6.18.40 disk images and retained running-session module tree are recorded as a degraded rollback state' \
        || record_failure 'the observed 6.18.40 rollback state differs from the reviewed post-package evidence'

    for package_record in \
        kernel-generic-6.18.42-x86_64-1 \
        kernel-headers-6.18.42-x86-1 \
        kernel-source-6.18.42-noarch-1 \
        grub-2.14-x86_64-3 \
        breeze-grub-6.7.4-x86_64-1; do
        if require_regular_file "$PACKAGE_DATABASE/$package_record"; then
            install -m 0600 -- "$PACKAGE_DATABASE/$package_record" "$OUTPUT_DIR/package-record.$package_record"
        fi
    done

    capture_package_database "$OUTPUT_DIR/packages.after.txt" \
        && capture_package_names "$OUTPUT_DIR/package-names.after.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the package database and boot-sensitive state were captured after verification' \
        || record_failure 'the final package or boot-sensitive state could not be captured'
    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && cmp -s "$OUTPUT_DIR/package-names.before.txt" "$OUTPUT_DIR/package-names.after.txt" \
        && record_pass 'the installed package database remained unchanged during post-package recovery verification' \
        || record_failure 'the installed package database changed during post-package recovery verification'
    cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the kernel, initrd, GenInitrd, module, and GRUB state remained unchanged during verification' \
        || record_failure 'the boot-sensitive state changed during post-package recovery verification'

    if [ "$FAILURE_COUNT" -eq 0 ]; then
        PAUSE_SAFE=true
        REBOOT_READY=true
        REBOOT_AUTHORIZED=false
        NEXT_STAGE=current-kernel-post-apply-reboot-review
        record_pass 'the installed transaction is complete and later Slackware-current publications no longer invalidate this safe pause'
    else
        PAUSE_SAFE=false
        REBOOT_READY=false
        REBOOT_AUTHORIZED=false
        NEXT_STAGE=manual-recovery-review-required
    fi

    finish
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
