#!/bin/bash

set -uo pipefail
IFS=$'\n\t'
umask 077
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
LC_ALL=C
export PATH LC_ALL

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../../.." && pwd -P)
DEFAULT_OUTPUT_ROOT=${ROLLBACK_PLAN_OUTPUT_ROOT:-/var/tmp/slack-update-acceptance/current-rollback-source-and-plan-preflight}
DEFAULT_SOURCE_STAGING_ROOT=${ROLLBACK_PLAN_SOURCE_STAGING_ROOT:-/var/tmp/slack-update-rollback-source}
DIAGNOSTIC_RECORD=${ROLLBACK_PLAN_DIAGNOSTIC_RECORD:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-reconstruction-inventory-20260806-corrected-diagnostic.json}
FAILED_PREFLIGHT_RECORD=${ROLLBACK_PLAN_FAILED_PREFLIGHT_RECORD:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-source-and-plan-preflight-20260806-failed-diagnostic.json}
REVISION_1_FAILED_PREFLIGHT_RECORD=${ROLLBACK_PLAN_REVISION_1_FAILED_PREFLIGHT_RECORD:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-source-and-plan-preflight-revision-1-20260806-failed-diagnostic.json}
REVISION_2_FAILED_PREFLIGHT_RECORD=${ROLLBACK_PLAN_REVISION_2_FAILED_PREFLIGHT_RECORD:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-source-and-plan-preflight-revision-2-20260806-failed-diagnostic.json}
REVISION_3_FAILED_PREFLIGHT_RECORD=${ROLLBACK_PLAN_REVISION_3_FAILED_PREFLIGHT_RECORD:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-source-and-plan-preflight-revision-3-20260806-failed-diagnostic.json}
REVISION_4_REJECTED_PLAN_RECORD=${ROLLBACK_PLAN_REVISION_4_REJECTED_PLAN_RECORD:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-source-and-plan-preflight-revision-4-20260806-rejected-plan-diagnostic.json}
GENINITRD_RECORD=${ROLLBACK_PLAN_GENINITRD_RECORD:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-command-preflight-20260805-accepted.json}
SIGNING_KEY=${ROLLBACK_PLAN_SIGNING_KEY:-$REPOSITORY_ROOT/tests/fixtures/reference/keys/slackware-security.gpg.asc}
PLAN_POLICY=${ROLLBACK_PLAN_POLICY:-$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-source-and-plan-preflight-policy.json}
PLAN_SCRIPT=$REPOSITORY_ROOT/tests/acceptance/reference/test-current-rollback-source-and-plan-preflight.sh

TARGET=
OUTPUT_DIR=
SOURCE_STAGING_DIR=
SOURCE_PACKAGE=
SOURCE_SIGNATURE=
CONFIRM_HOSTNAME=
CONFIRM_HOSTNAME_FQDN=
CONFIRM_INVENTORY_EVIDENCE_SHA256=
CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256=
CONFIRM_REVISION_1_FAILED_PREFLIGHT_EVIDENCE_SHA256=
CONFIRM_REVISION_2_FAILED_PREFLIGHT_EVIDENCE_SHA256=
CONFIRM_REVISION_3_FAILED_PREFLIGHT_EVIDENCE_SHA256=
CONFIRM_REVISION_4_REJECTED_PLAN_EVIDENCE_SHA256=
CONFIRM_ACTIVE_KERNEL=
CONFIRM_ROLLBACK_KERNEL=
CONFIRM_SOURCE_PLAN_SHA256=
PASS_COUNT=0
FAILURE_COUNT=0
SKIP_COUNT=0
ASSERTION_LOG=
ROOT_PREFIX=
PACKAGE_DATABASE=
HOSTNAME_SHORT=
HOSTNAME_FQDN=
RUNNING_KERNEL=
ARCHITECTURE=
ROOT_UUID=
ROOT_SOURCE=
SOURCE_ACQUISITION=unchecked
SOURCE_ACQUISITION_CHECKS=
SOURCE_PACKAGE_SHA256=
SOURCE_SIGNATURE_SHA256=
SOURCE_PACKAGE_SIZE=0
SOURCE_SIGNATURE_SIZE=0
SIGNATURE_FINGERPRINT=
SIGNATURE_PRIMARY_FINGERPRINT=
KERNEL_MEMBER=
KERNEL_SHA256=
KERNEL_SIZE=0
MODULE_FILE_COUNT=0
MODULE_PAYLOAD_BYTES=0
MODULE_MANIFEST_SHA256=
SPACE_STATE=unchecked
SPACE_RESERVE_BYTES=0
ESTIMATED_INITRD_BYTES=0
SPACE_REQUIRED_BYTES=0
SPACE_AVAILABLE_BYTES=0
APPLY_READY=false
NEXT_STAGE=current-rollback-source-and-plan-manual-review
REVIEWED_BOUNDARY_VALID=false
LIVE_BOUNDARY_VALID=false
SOURCE_ACQUIRED=false
SOURCE_SIGNATURE_VALID=false
SOURCE_PACKAGE_VALID=false
SPACE_BUDGET_VALID=false
INITRD_PROJECTION_VALID=false
GRUB_PROJECTION_VALID=false
APPLY_PLAN_VALID=false
TEST_MODE=${SLACK_UPDATE_TEST_MODE:-0}

print_usage() {
    cat <<EOF_USAGE
Usage: ${0##*/} --target slackware-current \\
                     --confirm-hostname SHORT_HOSTNAME \\
                     --confirm-hostname-fqdn FQDN \\
                     --confirm-inventory-evidence-sha256 SHA256 \\
                     --confirm-failed-preflight-evidence-sha256 SHA256 \\
                     --confirm-revision-1-failed-preflight-evidence-sha256 SHA256 \\
                     --confirm-revision-2-failed-preflight-evidence-sha256 SHA256 \\
                     --confirm-revision-3-failed-preflight-evidence-sha256 SHA256 \\
                     --confirm-revision-4-rejected-plan-evidence-sha256 SHA256 \\
                     --confirm-active-kernel VERSION \\
                     --confirm-rollback-kernel VERSION \\
                     --confirm-source-plan-sha256 SHA256 [options]

Acquire or reuse the exact historical Slackware package and detached signature,
verify them with the reviewed Slackware signing key, inspect the package without
extracting it into the installed system, and project the complete rollback
reconstruction plan. This preflight does not install packages, restore files,
run depmod or mkinitrd, modify GRUB, change the default boot entry, or reboot.

Required options:
      --target slackware-current
      --confirm-hostname SHORT_HOSTNAME
      --confirm-hostname-fqdn FQDN
      --confirm-inventory-evidence-sha256 SHA256
      --confirm-failed-preflight-evidence-sha256 SHA256
      --confirm-revision-1-failed-preflight-evidence-sha256 SHA256
      --confirm-revision-2-failed-preflight-evidence-sha256 SHA256
      --confirm-revision-3-failed-preflight-evidence-sha256 SHA256
      --confirm-revision-4-rejected-plan-evidence-sha256 SHA256
      --confirm-active-kernel VERSION
      --confirm-rollback-kernel VERSION
      --confirm-source-plan-sha256 SHA256

Optional arguments:
      --source-package PATH     Reuse one pre-staged exact package
      --source-signature PATH   Reuse its detached signature; requires package
      --source-staging-dir PATH Download/reuse source files under this directory
      --output-dir PATH         Store evidence under an absolute, new directory
  -h, --help                    Show this help and exit
EOF_USAGE
}

error() { printf 'ERROR: %s\n' "$*" >&2; }
record_pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$1" | tee -a "$ASSERTION_LOG"; }
record_failure() { FAILURE_COUNT=$((FAILURE_COUNT + 1)); printf 'FAIL: %s\n' "$1" | tee -a "$ASSERTION_LOG" >&2; }
record_skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); printf 'SKIP: %s\n' "$1" | tee -a "$ASSERTION_LOG"; }

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
            --confirm-inventory-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_INVENTORY_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-failed-preflight-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-revision-1-failed-preflight-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_REVISION_1_FAILED_PREFLIGHT_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-revision-2-failed-preflight-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_REVISION_2_FAILED_PREFLIGHT_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-revision-3-failed-preflight-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_REVISION_3_FAILED_PREFLIGHT_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-revision-4-rejected-plan-evidence-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_REVISION_4_REJECTED_PLAN_EVIDENCE_SHA256=${2,,}; shift 2 ;;
            --confirm-active-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_ACTIVE_KERNEL=$2; shift 2 ;;
            --confirm-rollback-kernel) [ "$#" -ge 2 ] || return 1; CONFIRM_ROLLBACK_KERNEL=$2; shift 2 ;;
            --confirm-source-plan-sha256) [ "$#" -ge 2 ] || return 1; CONFIRM_SOURCE_PLAN_SHA256=${2,,}; shift 2 ;;
            --source-package) [ "$#" -ge 2 ] || return 1; SOURCE_PACKAGE=$2; shift 2 ;;
            --source-signature) [ "$#" -ge 2 ] || return 1; SOURCE_SIGNATURE=$2; shift 2 ;;
            --source-staging-dir) [ "$#" -ge 2 ] || return 1; SOURCE_STAGING_DIR=$2; shift 2 ;;
            --output-dir) [ "$#" -ge 2 ] || return 1; OUTPUT_DIR=$2; shift 2 ;;
            -h|--help) print_usage; exit 0 ;;
            *) error "unknown argument: $1"; return 1 ;;
        esac
    done
    [ "$TARGET" = slackware-current ] || return 1
    [ -n "$CONFIRM_HOSTNAME" ] && [ -n "$CONFIRM_HOSTNAME_FQDN" ] || return 1
    case "$CONFIRM_HOSTNAME$CONFIRM_HOSTNAME_FQDN" in *[[:space:]]*) return 1 ;; esac
    is_sha256 "$CONFIRM_INVENTORY_EVIDENCE_SHA256" || return 1
    is_sha256 "$CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256" || return 1
    is_sha256 "$CONFIRM_REVISION_1_FAILED_PREFLIGHT_EVIDENCE_SHA256" || return 1
    is_sha256 "$CONFIRM_REVISION_2_FAILED_PREFLIGHT_EVIDENCE_SHA256" || return 1
    is_sha256 "$CONFIRM_REVISION_3_FAILED_PREFLIGHT_EVIDENCE_SHA256" || return 1
    is_sha256 "$CONFIRM_REVISION_4_REJECTED_PLAN_EVIDENCE_SHA256" || return 1
    is_sha256 "$CONFIRM_SOURCE_PLAN_SHA256" || return 1
    is_safe_kernel_version "$CONFIRM_ACTIVE_KERNEL" || return 1
    is_safe_kernel_version "$CONFIRM_ROLLBACK_KERNEL" || return 1
    [ "$CONFIRM_ACTIVE_KERNEL" != "$CONFIRM_ROLLBACK_KERNEL" ] || return 1
    if [ -n "$SOURCE_PACKAGE" ] || [ -n "$SOURCE_SIGNATURE" ]; then
        [ -n "$SOURCE_PACKAGE" ] && [ -n "$SOURCE_SIGNATURE" ] || return 1
        case "$SOURCE_PACKAGE" in /*) ;; *) return 1 ;; esac
        case "$SOURCE_SIGNATURE" in /*) ;; *) return 1 ;; esac
    fi
    if [ -n "$SOURCE_STAGING_DIR" ]; then case "$SOURCE_STAGING_DIR" in /*) ;; *) return 1 ;; esac; fi
    if [ -n "$OUTPUT_DIR" ]; then case "$OUTPUT_DIR" in /*) ;; *) return 1 ;; esac; fi
}

rooted() { printf '%s%s\n' "$ROOT_PREFIX" "$1"; }
require_regular_file() { [ -f "$1" ] && [ ! -L "$1" ] && [ -r "$1" ]; }
file_sha256() { sha256sum -- "$1" | awk '{print $1}'; }
file_size() { stat -Lc '%s' -- "$1"; }
policy_value() {
    python3 - "$PLAN_POLICY" "$1" <<'PY'
import json, sys
value=json.load(open(sys.argv[1], encoding='utf-8'))
for part in sys.argv[2].split('.'):
    value=value[part]
if isinstance(value, bool): print(str(value).lower())
else: print(value)
PY
}

validate_reviewed_boundary() {
    python3 - "$PLAN_POLICY" "$PLAN_SCRIPT" "$DIAGNOSTIC_RECORD" "$FAILED_PREFLIGHT_RECORD" \
        "$REVISION_1_FAILED_PREFLIGHT_RECORD" "$REVISION_2_FAILED_PREFLIGHT_RECORD" "$REVISION_3_FAILED_PREFLIGHT_RECORD" "$REVISION_4_REJECTED_PLAN_RECORD" "$GENINITRD_RECORD" "$SIGNING_KEY" \
        "$CONFIRM_HOSTNAME" "$CONFIRM_HOSTNAME_FQDN" "$CONFIRM_INVENTORY_EVIDENCE_SHA256" \
        "$CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256" "$CONFIRM_REVISION_1_FAILED_PREFLIGHT_EVIDENCE_SHA256" \
        "$CONFIRM_REVISION_2_FAILED_PREFLIGHT_EVIDENCE_SHA256" "$CONFIRM_REVISION_3_FAILED_PREFLIGHT_EVIDENCE_SHA256" "$CONFIRM_REVISION_4_REJECTED_PLAN_EVIDENCE_SHA256" \
        "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$CONFIRM_SOURCE_PLAN_SHA256" <<'PY'
import hashlib, json, pathlib, sys
(policy_path, script_path, diagnostic_path, failed_path, revision1_failed_path, revision2_failed_path, revision3_failed_path, revision4_rejected_path,
 geninitrd_path, key_path, host, fqdn, inventory_archive, failed_archive, revision1_failed_archive,
 revision2_failed_archive, revision3_failed_archive, revision4_rejected_archive, active, rollback, confirmed_scope) = sys.argv[1:]
def regular(path):
    p=pathlib.Path(path)
    if not p.is_file() or p.is_symlink(): raise SystemExit(1)
    return p
def sha(path): return hashlib.sha256(regular(path).read_bytes()).hexdigest()
policy=json.loads(regular(policy_path).read_text(encoding='utf-8'))
diagnostic=json.loads(regular(diagnostic_path).read_text(encoding='utf-8'))
failed=json.loads(regular(failed_path).read_text(encoding='utf-8'))
revision1_failed=json.loads(regular(revision1_failed_path).read_text(encoding='utf-8'))
revision2_failed=json.loads(regular(revision2_failed_path).read_text(encoding='utf-8'))
revision3_failed=json.loads(regular(revision3_failed_path).read_text(encoding='utf-8'))
revision4_rejected=json.loads(regular(revision4_rejected_path).read_text(encoding='utf-8'))
geninitrd=json.loads(regular(geninitrd_path).read_text(encoding='utf-8'))
script_sha=sha(script_path)
diagnostic_sha=sha(diagnostic_path)
failed_sha=sha(failed_path)
revision1_failed_sha=sha(revision1_failed_path)
revision2_failed_sha=sha(revision2_failed_path)
revision3_failed_sha=sha(revision3_failed_path)
revision4_rejected_sha=sha(revision4_rejected_path)
geninitrd_sha=sha(geninitrd_path)
key_sha=sha(key_path)
scope=(
 'operation=current-rollback-source-and-plan-preflight-revision-5\n'
 'target=slackware-current\n'
 f'hostname_short={host}\n'
 f'hostname_fqdn={fqdn}\n'
 f'active_kernel={active}\n'
 f'rollback_kernel={rollback}\n'
 f'root_uuid={policy.get("required_root_uuid", "")}\n'
 f'inventory_archive_sha256={inventory_archive}\n'
 f'failed_preflight_archive_sha256={failed_archive}\n'
 f'revision_1_failed_preflight_archive_sha256={revision1_failed_archive}\n'
 f'revision_2_failed_preflight_archive_sha256={revision2_failed_archive}\n'
 f'revision_3_failed_preflight_archive_sha256={revision3_failed_archive}\n'
 f'revision_4_rejected_plan_archive_sha256={revision4_rejected_archive}\n'
 f'diagnostic_record_sha256={diagnostic_sha}\n'
 f'failed_preflight_record_sha256={failed_sha}\n'
 f'revision_1_failed_preflight_record_sha256={revision1_failed_sha}\n'
 f'revision_2_failed_preflight_record_sha256={revision2_failed_sha}\n'
 f'revision_3_failed_preflight_record_sha256={revision3_failed_sha}\n'
 f'revision_4_rejected_plan_record_sha256={revision4_rejected_sha}\n'
 f'geninitrd_record_sha256={geninitrd_sha}\n'
 f'signing_key_sha256={key_sha}\n'
 f'plan_script_sha256={script_sha}\n'
).encode()
calculated=hashlib.sha256(scope).hexdigest()
vector=geninitrd.get('current_command_vector', [])
checks=[
 policy.get('scenario') == 'current-rollback-source-and-plan-preflight-revision-5',
 policy.get('target') == 'slackware-current',
 policy.get('reviewed') is True,
 policy.get('required_hostname_short') == host,
 policy.get('required_hostname_fqdn') == fqdn,
 policy.get('active_kernel') == active,
 policy.get('rollback_kernel') == rollback,
 policy.get('inventory_archive_sha256') == inventory_archive,
 policy.get('failed_preflight_archive_sha256') == failed_archive,
 policy.get('revision_1_failed_preflight_archive_sha256') == revision1_failed_archive,
 policy.get('revision_2_failed_preflight_archive_sha256') == revision2_failed_archive,
 policy.get('revision_3_failed_preflight_archive_sha256') == revision3_failed_archive,
 policy.get('revision_4_rejected_plan_archive_sha256') == revision4_rejected_archive,
 policy.get('diagnostic_record_sha256') == diagnostic_sha,
 policy.get('failed_preflight_record_sha256') == failed_sha,
 policy.get('revision_1_failed_preflight_record_sha256') == revision1_failed_sha,
 policy.get('revision_2_failed_preflight_record_sha256') == revision2_failed_sha,
 policy.get('revision_3_failed_preflight_record_sha256') == revision3_failed_sha,
 policy.get('revision_4_rejected_plan_record_sha256') == revision4_rejected_sha,
 policy.get('geninitrd_record_sha256') == geninitrd_sha,
 policy.get('signing_key_sha256') == key_sha,
 policy.get('plan_script_sha256') == script_sha,
 policy.get('source_plan_scope_sha256') == calculated == confirmed_scope,
 policy.get('repository_metadata_refresh_allowed') is False,
 policy.get('package_installation_allowed') is False,
 policy.get('initrd_generation_allowed') is False,
 policy.get('grub_mutation_allowed') is False,
 policy.get('reboot_execution_allowed') is False,
 diagnostic.get('archive_sha256') == inventory_archive,
 diagnostic.get('active_kernel') == active,
 diagnostic.get('rollback_kernel') == rollback,
 diagnostic.get('rollback_modules', {}).get('corrected_state') == 'depmod-metadata-only-placeholder',
 diagnostic.get('rollback_modules', {}).get('module_file_count') == 0,
 diagnostic.get('system_state_unchanged') is True,
 failed.get('archive_sha256') == failed_archive,
 failed.get('executed_script_sha256') == '37756428b0fbb9e106ce1853414f8032d803fdc6bb9ec9fef642ed82bd4c8a74',
 failed.get('system_state_mutated') is False,
 revision1_failed.get('archive_sha256') == revision1_failed_archive,
 revision1_failed.get('executed_script_sha256') == '8dc3eceb45c6c531aaf8e3f74e907cf4eb2b45a3aa113f43876b57405def47bd',
 revision1_failed.get('assertions') == {'failures':1,'passes':41,'skips':5},
 revision1_failed.get('source_acquisition') == 'unchecked',
 revision1_failed.get('system_state_mutated') is False,
 revision2_failed.get('archive_sha256') == revision2_failed_archive,
 revision2_failed.get('executed_script_sha256') == '516397c136ab9dd75d90eba7a5e1f969ef36c30e1725e05a2e3fbf3060b09c93',
 revision2_failed.get('assertions') == {'failures':1,'passes':57,'skips':3},
 revision2_failed.get('source_acquisition') == 'pre-staged',
 revision2_failed.get('source_signature_valid') is True,
 revision2_failed.get('failure_cause') == 'safe-root-directory-entry-rejected',
 revision2_failed.get('system_state_mutated') is False,
 revision3_failed.get('archive_sha256') == revision3_failed_archive,
 revision3_failed.get('scenario') == 'current-rollback-source-and-plan-preflight-revision-3-failed-diagnostic',
 revision3_failed.get('executed_script_sha256') == '409a4558a4bb92712ad192158962267159a3dd037c3f0159056ad969f7e63291',
 revision3_failed.get('assertions') == {'failures':1,'passes':58,'skips':2},
 revision3_failed.get('source_signature_valid') is True,
 revision3_failed.get('source_package_valid') is True,
 revision3_failed.get('failure_cause') == 'df-posix-output-option-conflict',
 revision3_failed.get('system_state_mutated') is False,
 revision4_rejected.get('archive_sha256') == revision4_rejected_archive,
 revision4_rejected.get('scenario') == 'current-rollback-source-and-plan-preflight-revision-4-rejected-plan-diagnostic',
 revision4_rejected.get('executed_script_sha256') == '2a0e98ed08e138385ca2983d1f7047c1ef5a54613b50d0305fd5f9414ad47099',
 revision4_rejected.get('assertions') == {'failures':0,'passes':61,'skips':0},
 revision4_rejected.get('apply_ready_reported') is True,
 revision4_rejected.get('apply_authorized') is False,
 revision4_rejected.get('failure_cause') == 'rollback-grub-entry-retained-active-initrd-and-reordered-microcode',
 revision4_rejected.get('system_state_mutated') is False,
 geninitrd.get('accepted') is True,
 geninitrd.get('current_command_vector') == vector,
 len(vector) >= 12 and vector[0] == 'mkinitrd' and '-k' in vector and vector[vector.index('-k')+1] == rollback,
]
if not all(checks): raise SystemExit(1)
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

capture_package_names() {
    local output=$1
    (cd "$PACKAGE_DATABASE" && find . -maxdepth 1 -type f -printf '%P\n' | LC_ALL=C sort) > "$output"
}

capture_path_state() {
    local path=$1 output=$2 metadata digest target type
    if [ -L "$path" ]; then
        target=$(readlink -- "$path") || return 1
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        printf '%s|symlink|%s|%s|\n' "${path#$ROOT_PREFIX}" "$target" "$metadata" >> "$output"
    elif [ -f "$path" ]; then
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        digest=$(file_sha256 "$path") || return 1
        printf '%s|regular||%s|%s\n' "${path#$ROOT_PREFIX}" "$metadata" "$digest" >> "$output"
    elif [ -d "$path" ]; then
        metadata=$(stat -c '%a:%u:%g:%s:%Y' -- "$path") || return 1
        printf '%s|directory||%s|\n' "${path#$ROOT_PREFIX}" "$metadata" >> "$output"
        find "$path" -mindepth 1 -printf '%P|%y|%m|%u|%g|%s|%T@\n' | LC_ALL=C sort >> "$output" || return 1
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
        /proc/cmdline /proc/sys/kernel/osrelease \
        /boot/vmlinuz-generic "/boot/vmlinuz-$CONFIRM_ACTIVE_KERNEL" "/boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL" \
        /boot/initrd-generic.img "/boot/initrd-$CONFIRM_ACTIVE_KERNEL.img" "/boot/initrd-$CONFIRM_ROLLBACK_KERNEL.img" \
        /boot/grub/grub.cfg /boot/grub/grubenv \
        /etc/default/geninitrd /usr/sbin/geninitrd \
        /usr/share/mkinitrd/mkinitrd_command_generator.sh /var/lib/pkgtools/setup/setup.01.mkinitrd \
        "/lib/modules/$CONFIRM_ACTIVE_KERNEL" "/lib/modules/$CONFIRM_ROLLBACK_KERNEL" \
        "/etc/grub.d/41_slackware_rollback_${CONFIRM_ROLLBACK_KERNEL//./_}"; do
        capture_path_state "$(rooted "$path")" "$output" || return 1
    done
}

validate_live_boundary() {
    local grubenv_list=$OUTPUT_DIR/grubenv.list
    local grubenv_path
    grubenv_path=$(rooted /boot/grub/grubenv)
    if [ -e "$grubenv_path" ] || [ -L "$grubenv_path" ]; then
        [ -f "$grubenv_path" ] && [ ! -L "$grubenv_path" ] || return 1
        grub-editenv "$grubenv_path" list > "$grubenv_list" 2>/dev/null || return 1
    else
        : > "$grubenv_list"
    fi
    python3 - "$PLAN_POLICY" "$ROOT_PREFIX" "$PACKAGE_DATABASE" "$OUTPUT_DIR/packages.before.txt" \
        "$OUTPUT_DIR/package-names.before.txt" "$HOSTNAME_SHORT" "$HOSTNAME_FQDN" "$RUNNING_KERNEL" \
        "$ARCHITECTURE" "$ROOT_UUID" "$ROOT_SOURCE" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" \
        "$grubenv_list" "$OUTPUT_DIR/live-boundary.json" "$OUTPUT_DIR/live-boundary-checks.tsv" <<'PY'
import hashlib, json, pathlib, shlex, sys
(policy_path, prefix, package_db, package_snapshot, names_snapshot, host, fqdn, running,
 arch, root_uuid, root_source, active, rollback, grubenv_path, output, checks_output) = sys.argv[1:]
policy=json.load(open(policy_path, encoding='utf-8'))
root=pathlib.Path(prefix) if prefix else pathlib.Path('/')
def path(value): return root / value.lstrip('/')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def exact_regular(p, expected_sha, expected_size):
    return p.is_file() and not p.is_symlink() and p.stat().st_uid == 0 and p.stat().st_gid == 0 and p.stat().st_size == expected_size and sha(p) == expected_sha
checks=[]
def add(key, ok, detail): checks.append({'key':key,'ok':bool(ok),'detail':detail})
add('hostname-short', host == policy['required_hostname_short'], f'hostname short name is {host}')
add('hostname-fqdn', fqdn == policy['required_hostname_fqdn'], f'hostname FQDN is {fqdn}')
add('running-kernel', running == active == policy['active_kernel'], f'running kernel is {running}')
add('architecture', arch == 'x86_64', f'architecture is {arch}')
add('root-uuid', root_uuid == policy['required_root_uuid'], f'root UUID is {root_uuid}')
add('root-source', bool(root_source), f'root source is {root_source or "missing"}')
osrelease=path('/proc/sys/kernel/osrelease'); cmdline=path('/proc/cmdline')
add('osrelease', osrelease.is_file() and osrelease.read_text().strip() == active, 'kernel osrelease matches the active kernel')
add('cmdline-readable', cmdline.is_file(), 'kernel command line is readable')
try: tokens=shlex.split(cmdline.read_text().strip()) if cmdline.is_file() else []
except Exception: tokens=[]
add('cmdline-boot-image', 'BOOT_IMAGE=/boot/vmlinuz-generic' in tokens, 'BOOT_IMAGE uses /boot/vmlinuz-generic')
add('cmdline-root-uuid', f'root=UUID={root_uuid}' in tokens, 'kernel command line uses the reviewed root UUID')
active_art=policy['active_artifacts']
add('active-kernel-file', exact_regular(path(f'/boot/vmlinuz-{active}'), active_art['kernel_sha256'], active_art['kernel_size']), 'active versioned kernel matches reviewed size and SHA-256')
add('active-initrd-file', exact_regular(path(f'/boot/initrd-{active}.img'), active_art['initrd_sha256'], active_art['initrd_size']), 'active versioned initrd matches reviewed size and SHA-256')
add('generic-kernel-link', path('/boot/vmlinuz-generic').is_symlink() and path('/boot/vmlinuz-generic').readlink().as_posix() == f'vmlinuz-{active}', 'generic kernel link targets the active version')
add('generic-initrd-link', path('/boot/initrd-generic.img').is_symlink() and path('/boot/initrd-generic.img').readlink().as_posix() == f'initrd-{active}.img', 'generic initrd link targets the active version')
active_modules=path(f'/lib/modules/{active}')
add('active-modules', active_modules.is_dir() and not active_modules.is_symlink() and any(active_modules.rglob('*')), 'active module tree is populated')
add('rollback-kernel-absent', not path(f'/boot/vmlinuz-{rollback}').exists() and not path(f'/boot/vmlinuz-{rollback}').is_symlink(), 'rollback kernel is absent before reconstruction')
add('rollback-initrd-absent', not path(f'/boot/initrd-{rollback}.img').exists() and not path(f'/boot/initrd-{rollback}.img').is_symlink(), 'rollback initrd is absent before reconstruction')
rollback_modules=path(f'/lib/modules/{rollback}')
add('rollback-placeholder-directory', rollback_modules.is_dir() and not rollback_modules.is_symlink(), 'rollback placeholder is a real directory')
expected=policy['rollback_placeholder_entries']
observed={}
if rollback_modules.is_dir() and not rollback_modules.is_symlink():
    for item in rollback_modules.iterdir():
        if item.is_symlink(): kind='symlink'
        elif item.is_dir(): kind='directory'
        elif item.is_file(): kind='regular'
        else: kind='other'
        st=item.lstat()
        observed[item.name]={'kind':kind,'mode':st.st_mode & 0o777,'uid':st.st_uid,'gid':st.st_gid,'size':st.st_size}
add('rollback-placeholder-entry-set', set(observed) == set(expected), 'rollback placeholder contains only the reviewed depmod metadata names')
metadata_ok=set(observed) == set(expected)
if metadata_ok:
    for name, spec in expected.items():
        item=observed[name]
        metadata_ok = metadata_ok and item['kind'] == spec['kind'] and item['mode'] == int(spec['mode'],8) and item['uid'] == 0 and item['gid'] == 0
        if spec['kind'] == 'regular': metadata_ok = metadata_ok and item['size'] == spec['size']
add('rollback-placeholder-metadata', metadata_ok, 'rollback placeholder types, modes, owners, and regular-file sizes match the reviewed metadata-only state')
module_suffixes=('.ko','.ko.gz','.ko.xz','.ko.zst')
module_objects=[]
if rollback_modules.is_dir() and not rollback_modules.is_symlink():
    module_objects=[p for p in rollback_modules.rglob('*') if p.is_file() and p.name.endswith(module_suffixes)]
add('rollback-module-objects-absent', not module_objects, 'rollback placeholder contains no kernel module objects')
for policy_key, check_key, live in [
 ('geninitrd_policy','geninitrd-policy','/etc/default/geninitrd'), ('geninitrd','geninitrd','/usr/sbin/geninitrd'),
 ('generator','generator','/usr/share/mkinitrd/mkinitrd_command_generator.sh'),
 ('setup','setup','/var/lib/pkgtools/setup/setup.01.mkinitrd'), ('active_grub','active-grub','/boot/grub/grub.cfg')]:
    item=policy[policy_key]
    add(check_key, exact_regular(path(live), item['sha256'], item['size']), f'{live} matches reviewed size and SHA-256')
fragment=path(f'/etc/grub.d/41_slackware_rollback_{rollback.replace(".", "_")}')
add('rollback-grub-fragment-absent', not fragment.exists() and not fragment.is_symlink(), 'rollback GRUB fragment is absent before reconstruction')
package_snapshot_path=pathlib.Path(package_snapshot); names_snapshot_path=pathlib.Path(names_snapshot)
add('installed-package-count', len(names_snapshot_path.read_text().splitlines()) == policy['installed_package_count'], 'installed package count matches the reviewed boundary')
add('package-database-snapshot', sha(package_snapshot_path) == policy['package_database_snapshot_sha256'], 'package database snapshot SHA-256 matches')
add('package-name-snapshot', sha(names_snapshot_path) == policy['package_name_snapshot_sha256'], 'package-name snapshot SHA-256 matches')
for forbidden in policy['forbidden_package_records']:
    candidate=pathlib.Path(package_db)/forbidden
    add(f'forbidden-package-{forbidden}', not candidate.exists() and not candidate.is_symlink(), f'forbidden rollback package record {forbidden} is absent')
grubenv=pathlib.Path(grubenv_path).read_text(encoding='utf-8',errors='replace').splitlines()
add('grub-next-entry-clear', not any(line.startswith('next_entry=') and line != 'next_entry=' for line in grubenv), 'GRUB has no pending one-time next_entry')
all_ok=all(item['ok'] for item in checks)
data={
 'active_kernel':active,'rollback_kernel':rollback,'root_uuid':root_uuid,'root_source':root_source,
 'rollback_module_state':'depmod-metadata-only-placeholder','rollback_kernel_present':False,
 'rollback_initrd_present':False,'rollback_grub_fragment_present':False,
 'installed_package_count':policy['installed_package_count'],'validated':all_ok,'checks':checks,
}
pathlib.Path(output).write_text(json.dumps(data, indent=2, sort_keys=True)+'\n', encoding='utf-8')
with pathlib.Path(checks_output).open('w', encoding='utf-8') as stream:
    for item in checks:
        detail=item['detail'].replace('\t',' ').replace('\n',' ')
        stream.write(f"{item['key']}\t{'PASS' if item['ok'] else 'FAIL'}\t{detail}\n")
raise SystemExit(0 if all_ok else 1)
PY
}

record_live_boundary_results() {
    local status=0 key result detail
    validate_live_boundary || status=$?
    if [ ! -s "$OUTPUT_DIR/live-boundary-checks.tsv" ]; then
        record_failure 'the live-boundary validator failed before producing individual checks'
        return 1
    fi
    while IFS=$'\t' read -r key result detail; do
        if [ "$result" = PASS ]; then
            record_pass "live boundary [$key]: $detail"
        else
            record_failure "live boundary [$key]: $detail"
        fi
    done < "$OUTPUT_DIR/live-boundary-checks.tsv"
    return "$status"
}

source_acquisition_check() {
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >> "$SOURCE_ACQUISITION_CHECKS"
}

inspect_source_pair() {
    local result=0
    python3 - "$SOURCE_PACKAGE" "$SOURCE_SIGNATURE" \
        "$(policy_value expected_package_filename)" \
        "$(policy_value expected_package_sha256)" \
        "$(policy_value expected_signature_sha256)" \
        "$SOURCE_ACQUISITION" "$SOURCE_ACQUISITION_CHECKS" \
        "$OUTPUT_DIR/source-acquisition.json" <<'PY' || result=$?
import hashlib, json, os, pathlib, stat, sys
(package_path, signature_path, expected_package_name, expected_package_sha,
 expected_signature_sha, acquisition, checks_path, output_path)=sys.argv[1:]
checks=[]
def add(key,status,detail):
    checks.append((key,status,detail.replace('\t',' ').replace('\n',' ')))
def inspect(role, raw_path, expected_name, expected_sha):
    path=pathlib.Path(raw_path)
    data={'path':raw_path,'expected_filename':expected_name,'expected_sha256':expected_sha,
          'exists':False,'is_symlink':False,'is_regular':False,'opened_nofollow':False,
          'mode':'','uid':None,'gid':None,'size':0,'sha256':''}
    add(f'{role}-basename','PASS' if path.name==expected_name else 'FAIL',
        f'{role} basename is {path.name!r}; expected {expected_name!r}')
    try:
        lst=os.lstat(path)
    except OSError as exc:
        add(f'{role}-lstat','FAIL',f'{role} cannot be inspected with lstat: {exc}')
        for suffix,detail in (
            ('no-symbolic-link',f'{role} link status requires successful lstat'),
            ('regular-file',f'{role} type requires successful lstat'),
            ('open-nofollow',f'{role} safe open requires a regular non-link file'),
            ('positive-size',f'{role} size requires successful safe open'),
            ('sha256',f'{role} digest requires successful safe open'),
        ): add(f'{role}-{suffix}','SKIP',detail)
        return data
    data.update(exists=True,is_symlink=stat.S_ISLNK(lst.st_mode),
                is_regular=stat.S_ISREG(lst.st_mode),mode=f'{stat.S_IMODE(lst.st_mode):04o}',
                uid=lst.st_uid,gid=lst.st_gid,size=lst.st_size)
    add(f'{role}-lstat','PASS',
        f'{role} lstat succeeded: mode={data["mode"]} uid={lst.st_uid} gid={lst.st_gid} size={lst.st_size}')
    if data['is_symlink']:
        add(f'{role}-no-symbolic-link','FAIL',f'{role} is a symbolic link and is rejected')
    else:
        add(f'{role}-no-symbolic-link','PASS',f'{role} is not a symbolic link')
    if not data['is_regular']:
        add(f'{role}-regular-file','FAIL' if not data['is_symlink'] else 'SKIP',
            f'{role} must be a regular file')
        add(f'{role}-open-nofollow','SKIP',f'{role} safe open requires a regular non-link file')
        add(f'{role}-positive-size','SKIP',f'{role} size requires successful safe open')
        add(f'{role}-sha256','SKIP',f'{role} digest requires successful safe open')
        return data
    add(f'{role}-regular-file','PASS',f'{role} is a regular file')
    flags=os.O_RDONLY | getattr(os,'O_CLOEXEC',0) | getattr(os,'O_NOFOLLOW',0)
    try:
        fd=os.open(path,flags)
    except OSError as exc:
        add(f'{role}-open-nofollow','FAIL',f'{role} cannot be opened safely without following links: {exc}')
        add(f'{role}-positive-size','SKIP',f'{role} size requires successful safe open')
        add(f'{role}-sha256','SKIP',f'{role} digest requires successful safe open')
        return data
    try:
        fst=os.fstat(fd)
        if not stat.S_ISREG(fst.st_mode):
            add(f'{role}-open-nofollow','FAIL',f'{role} changed type during safe open')
            add(f'{role}-positive-size','SKIP',f'{role} size requires a stable regular file')
            add(f'{role}-sha256','SKIP',f'{role} digest requires a stable regular file')
            return data
        data.update(opened_nofollow=True,mode=f'{stat.S_IMODE(fst.st_mode):04o}',
                    uid=fst.st_uid,gid=fst.st_gid,size=fst.st_size)
        add(f'{role}-open-nofollow','PASS',
            f'{role} opened with O_NOFOLLOW and remained regular')
        digest=hashlib.sha256()
        while True:
            chunk=os.read(fd,1024*1024)
            if not chunk: break
            digest.update(chunk)
        data['sha256']=digest.hexdigest()
    finally:
        os.close(fd)
    add(f'{role}-positive-size','PASS' if data['size']>0 else 'FAIL',
        f'{role} size is {data["size"]} byte(s)')
    add(f'{role}-sha256','PASS' if data['sha256']==expected_sha else 'FAIL',
        f'{role} SHA-256 is {data["sha256"] or "unavailable"}; expected {expected_sha}')
    return data
package=inspect('source-package',package_path,expected_package_name,expected_package_sha)
signature=inspect('source-signature',signature_path,expected_package_name+'.asc',expected_signature_sha)
with open(checks_path,'a',encoding='utf-8') as stream:
    for key,status,detail in checks:
        stream.write(f'{key}\t{status}\t{detail}\n')
payload={'acquisition':acquisition,'package':package,'signature':signature,
         'valid':not any(status=='FAIL' for _,status,_ in checks)}
pathlib.Path(output_path).write_text(json.dumps(payload,indent=2,sort_keys=True)+'\n',encoding='utf-8')
raise SystemExit(0 if payload['valid'] else 1)
PY
    if [ -s "$OUTPUT_DIR/source-acquisition.json" ]; then
        IFS=$'\t' read -r SOURCE_PACKAGE_SHA256 SOURCE_PACKAGE_SIZE SOURCE_SIGNATURE_SHA256 SOURCE_SIGNATURE_SIZE < <(
            python3 - "$OUTPUT_DIR/source-acquisition.json" <<'PY'
import json,sys
data=json.load(open(sys.argv[1],encoding='utf-8'))
print(data['package'].get('sha256',''),data['package'].get('size',0),
      data['signature'].get('sha256',''),data['signature'].get('size',0),sep='\t')
PY
        )
    fi
    return "$result"
}

acquire_source() {
    local expected expected_sig package_url signature_url tmp_package tmp_signature
    SOURCE_ACQUISITION_CHECKS="$OUTPUT_DIR/source-acquisition-checks.tsv"
    : > "$SOURCE_ACQUISITION_CHECKS"
    expected=$(policy_value expected_package_filename) || {
        source_acquisition_check source-policy FAIL 'the expected package filename is unavailable from policy'
        return 1
    }
    expected_sig="$expected.asc"
    if [ -n "$SOURCE_PACKAGE" ]; then
        SOURCE_ACQUISITION=pre-staged
        source_acquisition_check source-mode PASS 'an explicit pre-staged package and signature pair was requested'
        inspect_source_pair
        return $?
    fi
    [ -n "$SOURCE_STAGING_DIR" ] || SOURCE_STAGING_DIR="$DEFAULT_SOURCE_STAGING_ROOT/$CONFIRM_ROLLBACK_KERNEL"
    if [ -L "$SOURCE_STAGING_DIR" ]; then
        source_acquisition_check source-staging-directory FAIL 'the source staging directory is a symbolic link'
        return 1
    fi
    if mkdir -m 0700 -p -- "$SOURCE_STAGING_DIR"; then
        source_acquisition_check source-staging-directory PASS "private source staging is available at $SOURCE_STAGING_DIR"
    else
        source_acquisition_check source-staging-directory FAIL "private source staging could not be created at $SOURCE_STAGING_DIR"
        return 1
    fi
    SOURCE_PACKAGE="$SOURCE_STAGING_DIR/$expected"
    SOURCE_SIGNATURE="$SOURCE_STAGING_DIR/$expected_sig"
    if [ -e "$SOURCE_PACKAGE" ] || [ -L "$SOURCE_PACKAGE" ] || [ -e "$SOURCE_SIGNATURE" ] || [ -L "$SOURCE_SIGNATURE" ]; then
        SOURCE_ACQUISITION=reused-staging
        source_acquisition_check source-mode PASS 'an existing staged package/signature pair will be validated'
        inspect_source_pair
        return $?
    fi
    package_url=$(policy_value package_url) || {
        source_acquisition_check source-package-url FAIL 'the package URL is unavailable from policy'
        return 1
    }
    signature_url=$(policy_value signature_url) || {
        source_acquisition_check source-signature-url FAIL 'the signature URL is unavailable from policy'
        return 1
    }
    case "$package_url:$signature_url" in
        https://*:https://*)
            source_acquisition_check source-https-policy PASS 'both historical source URLs require HTTPS'
            ;;
        *)
            source_acquisition_check source-https-policy FAIL 'one or both historical source URLs are not HTTPS'
            return 1
            ;;
    esac
    tmp_package="$SOURCE_PACKAGE.partial.$$"
    tmp_signature="$SOURCE_SIGNATURE.partial.$$"
    if curl --proto '=https' --proto-redir '=https' --tlsv1.2 --fail --location --show-error \
        --output "$tmp_package" "$package_url"; then
        source_acquisition_check source-package-download PASS 'the historical package download completed'
    else
        source_acquisition_check source-package-download FAIL 'the historical package download failed'
        rm -f -- "$tmp_package" "$tmp_signature"
        return 1
    fi
    if curl --proto '=https' --proto-redir '=https' --tlsv1.2 --fail --location --show-error \
        --output "$tmp_signature" "$signature_url"; then
        source_acquisition_check source-signature-download PASS 'the detached-signature download completed'
    else
        source_acquisition_check source-signature-download FAIL 'the detached-signature download failed'
        rm -f -- "$tmp_package" "$tmp_signature"
        return 1
    fi
    chmod 0600 "$tmp_package" "$tmp_signature" || {
        source_acquisition_check source-download-mode FAIL 'downloaded source permissions could not be restricted'
        rm -f -- "$tmp_package" "$tmp_signature"
        return 1
    }
    mv -- "$tmp_package" "$SOURCE_PACKAGE" && mv -- "$tmp_signature" "$SOURCE_SIGNATURE" || {
        source_acquisition_check source-download-publish FAIL 'downloaded source files could not be published atomically'
        rm -f -- "$tmp_package" "$tmp_signature"
        return 1
    }
    source_acquisition_check source-download-publish PASS 'downloaded source files were published into private staging'
    SOURCE_ACQUISITION=downloaded-https
    inspect_source_pair
}

record_source_acquisition_results() {
    local status=0 key result detail
    acquire_source || status=$?
    if [ ! -s "$SOURCE_ACQUISITION_CHECKS" ]; then
        record_failure 'source acquisition failed before producing individual diagnostic checks'
        return 1
    fi
    while IFS=$'\t' read -r key result detail; do
        case "$result" in
            PASS) record_pass "source acquisition [$key]: $detail" ;;
            FAIL) record_failure "source acquisition [$key]: $detail" ;;
            SKIP) record_skip "source acquisition [$key]: $detail" ;;
            *) record_failure "source acquisition [$key]: invalid diagnostic result $result" ;;
        esac
    done < "$SOURCE_ACQUISITION_CHECKS"
    return "$status"
}

verify_source_signature() {
    local keyring_dir keyring status=$OUTPUT_DIR/gpg-status.txt expected result=0
    if [ "$TEST_MODE" = 1 ] && [ -n "${SLACK_UPDATE_TEST_SIGNATURE_MODE:-}" ]; then
        [ "$SLACK_UPDATE_TEST_SIGNATURE_MODE" = valid ] || return 1
        expected=$(policy_value signing_key_fingerprint) || return 1
        SIGNATURE_FINGERPRINT=${SLACK_UPDATE_TEST_SIGNING_FINGERPRINT:-}
        SIGNATURE_PRIMARY_FINGERPRINT=${SLACK_UPDATE_TEST_PRIMARY_FINGERPRINT:-}
        [ -n "$SIGNATURE_FINGERPRINT" ] && [ "$SIGNATURE_PRIMARY_FINGERPRINT" = "$expected" ] || return 1
        SOURCE_PACKAGE_SHA256=$(file_sha256 "$SOURCE_PACKAGE") || return 1
        SOURCE_SIGNATURE_SHA256=$(file_sha256 "$SOURCE_SIGNATURE") || return 1
        SOURCE_PACKAGE_SIZE=$(file_size "$SOURCE_PACKAGE") || return 1
        SOURCE_SIGNATURE_SIZE=$(file_size "$SOURCE_SIGNATURE") || return 1
        [ "$SOURCE_PACKAGE_SIZE" -gt 0 ] && [ "$SOURCE_SIGNATURE_SIZE" -gt 0 ] || return 1
        [ "$SOURCE_PACKAGE_SHA256" = "$(policy_value expected_package_sha256)" ] || return 1
        [ "$SOURCE_SIGNATURE_SHA256" = "$(policy_value expected_signature_sha256)" ] || return 1
        printf 'test-mode detached-signature verification bypass\n' > "$OUTPUT_DIR/gpg-keyring-build.log"
        printf '[GNUPG:] VALIDSIG %s 0 0 0 0 0 0 0 0 %s\n' \
            "$SIGNATURE_FINGERPRINT" "$SIGNATURE_PRIMARY_FINGERPRINT" > "$status"
        : > "$OUTPUT_DIR/gpg-verify.log"
        return 0
    fi
    keyring_dir=$(mktemp -d /tmp/slack-update-gpgv.XXXXXX) || return 1
    chmod 0700 "$keyring_dir" || { rm -rf -- "$keyring_dir"; return 1; }
    keyring="$keyring_dir/slackware.gpg"
    printf '%s\n' "$keyring_dir" > "$OUTPUT_DIR/gpg-keyring-directory.txt"
    gpg --batch --yes --dearmor --output "$keyring" "$SIGNING_KEY" \
        > "$OUTPUT_DIR/gpg-keyring-build.log" 2>&1 || result=1
    if [ "$result" -eq 0 ]; then
        gpgv --homedir "$keyring_dir" --keyring "$keyring" --status-fd 1 \
            "$SOURCE_SIGNATURE" "$SOURCE_PACKAGE" \
            > "$status" 2> "$OUTPUT_DIR/gpg-verify.log" || result=1
    fi
    if [ "$result" -eq 0 ]; then
        expected=$(policy_value signing_key_fingerprint) || result=1
    fi
    if [ "$result" -eq 0 ]; then
        local signature_identities identity_count
        signature_identities=$(awk '$1=="[GNUPG:]" && $2=="VALIDSIG" {primary=($12=="" ? $3 : $12); print $3 "\t" primary}' "$status" | LC_ALL=C sort -u)
        identity_count=$(printf '%s\n' "$signature_identities" | awk 'NF {count++} END {print count+0}')
        [ "$identity_count" -eq 1 ] || result=1
        if [ "$result" -eq 0 ]; then
            IFS=$'\t' read -r SIGNATURE_FINGERPRINT SIGNATURE_PRIMARY_FINGERPRINT <<< "$signature_identities"
            [ "$SIGNATURE_PRIMARY_FINGERPRINT" = "$expected" ] || result=1
        fi
    fi
    if [ "$result" -eq 0 ]; then
        SOURCE_PACKAGE_SHA256=$(file_sha256 "$SOURCE_PACKAGE") || result=1
        SOURCE_SIGNATURE_SHA256=$(file_sha256 "$SOURCE_SIGNATURE") || result=1
        SOURCE_PACKAGE_SIZE=$(file_size "$SOURCE_PACKAGE") || result=1
        SOURCE_SIGNATURE_SIZE=$(file_size "$SOURCE_SIGNATURE") || result=1
        [ "$SOURCE_PACKAGE_SIZE" -gt 0 ] && [ "$SOURCE_SIGNATURE_SIZE" -gt 0 ] || result=1
        [ "$SOURCE_PACKAGE_SHA256" = "$(policy_value expected_package_sha256)" ] || result=1
        [ "$SOURCE_SIGNATURE_SHA256" = "$(policy_value expected_signature_sha256)" ] || result=1
    fi
    rm -rf -- "$keyring_dir"
    return "$result"
}

inspect_source_package() {
    local summary=$OUTPUT_DIR/source-package.json
    local manifest=$OUTPUT_DIR/source-module-manifest.txt
    local inspection_log=$OUTPUT_DIR/source-package-inspection.log
    local payload_fields
    rm -f -- "$summary" "$manifest" "$inspection_log"
    python3 - "$SOURCE_PACKAGE" "$CONFIRM_ROLLBACK_KERNEL" "$summary" "$manifest" "$inspection_log" <<'PY'
import hashlib, json, os, pathlib, posixpath, stat, tarfile, sys, tempfile
package=pathlib.Path(sys.argv[1]); version=sys.argv[2]; summary=pathlib.Path(sys.argv[3])
modules_out=pathlib.Path(sys.argv[4]); log=pathlib.Path(sys.argv[5])
def reject(reason):
    log.write_text(reason.rstrip()+'\n',encoding='utf-8')
    raise SystemExit(1)
expected=f'kernel-generic-{version}-x86_64-1.txz'
if package.name != expected: reject(f'unexpected package basename: {package.name}')
if not package.is_file() or package.is_symlink(): reject('package is not a non-symlink regular file')
def normalize(name):
    original=name
    while name.startswith('./'): name=name[2:]
    if name in ('','.'): return None
    if name.startswith('/'): reject(f'absolute archive path: {original}')
    value=posixpath.normpath(name)
    if value in ('','..') or value.startswith('../'): reject(f'unsafe archive path: {original}')
    return value
def safe_link(name,target):
    if not target or target.startswith('/'): return False
    value=posixpath.normpath(posixpath.join(posixpath.dirname(name),target))
    return value not in ('','.','..') and not value.startswith('../')
def stream_hash(archive, member):
    stream=archive.extractfile(member)
    if stream is None: reject(f'cannot read regular archive member: {member.name}')
    h=hashlib.sha256(); size=0
    for chunk in iter(lambda: stream.read(1024*1024), b''): h.update(chunk); size += len(chunk)
    if size <= 0: reject(f'empty regular archive member is not accepted: {member.name}')
    return h.hexdigest(), size
seen=set(); kernels=[]; modules=[]; module_bytes=0; member_count=0; doinst=None; root_directory_count=0
try:
    with tarfile.open(package, 'r:*') as archive:
        for member in archive:
            member_count += 1
            name=normalize(member.name)
            if name is None:
                root_directory_count += 1
                if root_directory_count != 1: reject('duplicate archive root directory entry')
                if not member.isdir(): reject('archive root entry is not a directory')
                if member.uid != 0 or member.gid != 0: reject('archive root directory is not root-owned')
                if member.mode & (stat.S_ISUID | stat.S_ISGID | stat.S_IWOTH):
                    reject('archive root directory mode is unsafe')
                continue
            if name in seen: reject(f'duplicate normalized archive path: {name}')
            seen.add(name)
            if member.ischr() or member.isblk() or member.isfifo(): reject(f'unsafe special archive member: {name}')
            if member.issym() or member.islnk():
                if not safe_link(name, member.linkname): reject(f'unsafe archive link: {name} -> {member.linkname}')
                continue
            if not (member.isfile() or member.isdir()): reject(f'unsupported archive member type: {name}')
            if member.isfile() and (member.mode & (stat.S_ISUID | stat.S_ISGID | stat.S_IWOTH)):
                reject(f'unsafe regular-file mode: {name}')
            if member.isfile() and (member.uid != 0 or member.gid != 0):
                reject(f'non-root-owned regular file: {name}')
            if member.isfile() and name in (f'boot/vmlinuz-{version}', f'boot/vmlinuz-generic-{version}'):
                digest,size=stream_hash(archive,member)
                kernels.append({'member':name,'sha256':digest,'size':size,'mode':oct(member.mode & 0o777)})
            prefix=f'lib/modules/{version}/'
            if member.isfile() and name.startswith(prefix):
                digest,size=stream_hash(archive,member)
                rel=name[len(prefix):]
                modules.append({'path':rel,'sha256':digest,'size':size,'mode':oct(member.mode & 0o777)})
                module_bytes += size
            if member.isfile() and name == 'install/doinst.sh':
                digest,size=stream_hash(archive,member)
                doinst={'sha256':digest,'size':size,'mode':oct(member.mode & 0o777)}
except (tarfile.TarError, OSError) as exc:
    reject(f'archive read failure: {exc}')
if len(kernels) != 1: reject(f'expected one versioned kernel member, found {len(kernels)}')
if not modules: reject('module tree contains no regular payload files')
module_objects=[m for m in modules if m['path'].startswith('kernel/') and m['path'].endswith(('.ko','.ko.gz','.ko.xz','.ko.zst'))]
if not module_objects: reject('module tree contains no kernel module objects')
modules=sorted(modules,key=lambda x:x['path'])
manifest_text=''.join(f"{m['sha256']}  {m['size']}  {m['mode']}  {m['path']}\n" for m in modules)
package_hash=hashlib.sha256()
with package.open('rb') as stream:
    for chunk in iter(lambda: stream.read(1024*1024),b''): package_hash.update(chunk)
data={
 'filename':package.name,'package_sha256':package_hash.hexdigest(),'package_size':package.stat().st_size,
 'member_count':member_count,'archive_root_directory_count':root_directory_count,
 'kernel':kernels[0],'module_member_count':len(modules),
 'module_object_count':len(module_objects),'module_payload_bytes':module_bytes,'doinst':doinst,
 'paths_safe':True,'ownership_safe':True,'modes_safe':True,
}
summary_tmp=summary.with_name(summary.name+'.tmp')
manifest_tmp=modules_out.with_name(modules_out.name+'.tmp')
try:
    manifest_tmp.write_text(manifest_text,encoding='utf-8')
    summary_tmp.write_text(json.dumps(data,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    os.replace(manifest_tmp,modules_out)
    os.replace(summary_tmp,summary)
    log.write_text('package inspection completed successfully\n',encoding='utf-8')
except OSError as exc:
    for path in (summary_tmp,manifest_tmp):
        try: path.unlink()
        except FileNotFoundError: pass
    reject(f'cannot publish package inspection outputs: {exc}')
PY
    [ -f "$summary" ] && [ ! -L "$summary" ] && [ -f "$manifest" ] && [ ! -L "$manifest" ] || return 1
    payload_fields=$(python3 - "$summary" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
print(d['kernel']['member'],d['kernel']['sha256'],d['kernel']['size'],d['module_member_count'],d['module_payload_bytes'],sep='\t')
PY
    ) || return 1
    IFS=$'\t' read -r KERNEL_MEMBER KERNEL_SHA256 KERNEL_SIZE MODULE_FILE_COUNT MODULE_PAYLOAD_BYTES <<< "$payload_fields" || return 1
    MODULE_MANIFEST_SHA256=$(file_sha256 "$manifest") || return 1
    [ -n "$KERNEL_MEMBER" ] && [ "$KERNEL_SIZE" -gt 0 ] && [ "$MODULE_FILE_COUNT" -gt 0 ] \
        && is_sha256 "$MODULE_MANIFEST_SHA256"
}

space_sample() {
    local path=$1 available device
    if [ "$TEST_MODE" = 1 ]; then
        available=${SLACK_UPDATE_TEST_SPACE_AVAILABLE_BYTES:-10737418240}
        device=${SLACK_UPDATE_TEST_SPACE_DEVICE:-test-root}
    else
        [ -d "$path" ] && [ ! -L "$path" ] || return 1
        device=$(stat -c '%d' -- "$path") || return 1
        available=$(df -B1 --output=avail -- "$path" 2>> "$OUTPUT_DIR/space-budget-df.log" | awk 'NR == 2 { print $1 }') || return 1
    fi
    case "$available" in ''|*[!0-9]*) return 1 ;; esac
    printf '%s\t%s\n' "$device" "$available"
}

evaluate_space_budget() {
    : > "$OUTPUT_DIR/space-budget-df.log" || return 1
    local boot_device boot_available modules_device modules_available staging_device staging_available
    local backup_device backup_available grub_size boot_component modules_component staging_component backup_component
    SPACE_RESERVE_BYTES=$(policy_value minimum_free_space_reserve_bytes) || return 1
    ESTIMATED_INITRD_BYTES=$(policy_value estimated_initrd_bytes) || return 1
    grub_size=$(policy_value active_grub.size) || return 1
    case "$SPACE_RESERVE_BYTES:$ESTIMATED_INITRD_BYTES:$grub_size" in *[!0-9:]*) return 1 ;; esac
    IFS=$'\t' read -r boot_device boot_available < <(space_sample "$(rooted /boot)") || return 1
    IFS=$'\t' read -r modules_device modules_available < <(space_sample "$(rooted /lib/modules)") || return 1
    IFS=$'\t' read -r staging_device staging_available < <(space_sample "$(rooted /var/tmp)") || return 1
    IFS=$'\t' read -r backup_device backup_available < <(space_sample "$(rooted /var/lib)") || return 1
    boot_component=$((KERNEL_SIZE + ESTIMATED_INITRD_BYTES + (grub_size * 2)))
    modules_component=$MODULE_PAYLOAD_BYTES
    staging_component=$((KERNEL_SIZE + MODULE_PAYLOAD_BYTES + (grub_size * 2)))
    backup_component=$((grub_size + 4096))
    python3 - "$OUTPUT_DIR/space-budget.json" "$SPACE_RESERVE_BYTES" \
        "$boot_device" "$boot_available" "$boot_component" \
        "$modules_device" "$modules_available" "$modules_component" \
        "$staging_device" "$staging_available" "$staging_component" \
        "$backup_device" "$backup_available" "$backup_component" <<'PY'
import json, pathlib, sys
out=pathlib.Path(sys.argv[1]); reserve=int(sys.argv[2]); values=sys.argv[3:]
labels=('boot-final-artifacts','module-destination','private-apply-staging','rollback-backup')
groups={}
for label, offset in zip(labels, range(0, len(values), 3)):
    device, available, component = values[offset:offset+3]
    item=groups.setdefault(device, {'available_bytes':int(available),'component_bytes':0,'components':[]})
    item['available_bytes']=min(item['available_bytes'], int(available))
    item['component_bytes'] += int(component)
    item['components'].append({'name':label,'bytes':int(component)})
for item in groups.values():
    item['required_bytes']=item['component_bytes'] + reserve
    item['sufficient']=item['available_bytes'] >= item['required_bytes']
state='sufficient' if all(item['sufficient'] for item in groups.values()) else 'insufficient'
data={
    'state':state,'reserve_bytes_per_filesystem':reserve,
    'aggregate_required_bytes':sum(item['required_bytes'] for item in groups.values()),
    'minimum_available_bytes':min(item['available_bytes'] for item in groups.values()),
    'filesystems':groups,
}
out.write_text(json.dumps(data,indent=2,sort_keys=True)+'\n',encoding='utf-8')
print(state, data['aggregate_required_bytes'], data['minimum_available_bytes'], sep='\t')
PY
    IFS=$'\t' read -r SPACE_STATE SPACE_REQUIRED_BYTES SPACE_AVAILABLE_BYTES < <(
        python3 - "$OUTPUT_DIR/space-budget.json" <<'PY'
import json,sys
d=json.load(open(sys.argv[1],encoding='utf-8'))
print(d['state'],d['aggregate_required_bytes'],d['minimum_available_bytes'],sep='\t')
PY
    )
    [ "$SPACE_STATE" = sufficient ]
}

project_initrd_command() {
    python3 - "$GENINITRD_RECORD" "$CONFIRM_ROLLBACK_KERNEL" "$OUTPUT_DIR/projected-mkinitrd-command.json" \
        "$OUTPUT_DIR/projected-mkinitrd-command.sh" <<'PY'
import json, pathlib, shlex, sys
record=json.load(open(sys.argv[1],encoding='utf-8')); version=sys.argv[2]
vector=list(record['current_command_vector'])
if vector[0] != 'mkinitrd' or '-k' not in vector or vector[vector.index('-k')+1] != version or '-o' not in vector: raise SystemExit(1)
vector[vector.index('-o')+1]=f'/boot/initrd-{version}.img'
pathlib.Path(sys.argv[3]).write_text(json.dumps({'command_vector':vector,'executed':False,'output':f'/boot/initrd-{version}.img'},indent=2,sort_keys=True)+'\n',encoding='utf-8')
pathlib.Path(sys.argv[4]).write_text('# Projected only; do not execute before explicit authorization.\n'+shlex.join(vector)+'\n',encoding='utf-8')
PY
}

project_grub_entry() {
    local grub fragment_name
    grub=$(rooted /boot/grub/grub.cfg)
    fragment_name="41_slackware_rollback_${CONFIRM_ROLLBACK_KERNEL//./_}"
    python3 - "$grub" "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$OUTPUT_DIR/projected-grub-menuentry.cfg" \
        "$OUTPUT_DIR/projected-$fragment_name" "$OUTPUT_DIR/projected-grub-entry.json" <<'PY'
import json,pathlib,re,shlex,sys
source=pathlib.Path(sys.argv[1]).read_text(encoding='utf-8').splitlines()
active=sys.argv[2]
version=sys.argv[3]
entry_output=pathlib.Path(sys.argv[4])
fragment_output=pathlib.Path(sys.argv[5])
metadata_output=pathlib.Path(sys.argv[6])
started=False
depth=0
entry=[]
for raw in source:
    stripped=raw.strip()
    if not started and stripped.startswith('menuentry '):
        started=True
    if started:
        entry.append(raw)
        depth += raw.count('{') - raw.count('}')
        if depth == 0 and len(entry) > 1:
            break
if not entry or depth != 0:
    raise SystemExit('unable to resolve the first active GRUB menuentry')
header=entry[0]
indent=header[:len(header)-len(header.lstrip())]
entry[0]=f"{indent}menuentry 'Slackware GNU/Linux (rollback {version})' --id 'slackware-rollback-{version}' {{"
linux_count=0
initrd_count=0
microcode=[]
source_initrd_vector=[]
projected_initrd_vector=[]
for i,line in enumerate(entry):
    stripped=line.strip()
    if re.match(r'^linux(?:efi)?\s+', stripped):
        parts=shlex.split(stripped)
        if len(parts) < 2 or parts[1] != '/boot/vmlinuz-generic':
            raise SystemExit('the active Linux command does not use the reviewed generic kernel path')
        parts[1]=f'/boot/vmlinuz-{version}'
        entry[i]=line[:len(line)-len(line.lstrip())]+shlex.join(parts)
        linux_count += 1
    elif re.match(r'^initrd(?:efi)?\s+', stripped):
        parts=shlex.split(stripped)
        if len(parts) < 2:
            raise SystemExit('the active initrd command has no payload')
        command=parts[0]
        payload=parts[1:]
        source_initrd_vector=list(payload)
        active_tokens=[x for x in payload if x in ('/boot/initrd-generic.img',f'/boot/initrd-{active}.img')]
        foreign_initrd=[
            x for x in payload
            if re.search(r'(?:^|/)initrd(?:-[^/]*)?\.img$',x) and x not in active_tokens
        ]
        microcode=[x for x in payload if re.fullmatch(r'/boot/(?:amd|intel)-ucode\.img',x)]
        unknown=[x for x in payload if x not in active_tokens and x not in microcode]
        if (
            len(active_tokens) != 1
            or foreign_initrd
            or unknown
            or len(microcode) != len(set(microcode))
            or len(microcode) > 1
        ):
            raise SystemExit(
                'the active initrd vector is not exactly one reviewed initrd plus at most one microcode image'
            )
        projected_initrd_vector=microcode+[f'/boot/initrd-{version}.img']
        entry[i]=line[:len(line)-len(line.lstrip())]+shlex.join([command]+projected_initrd_vector)
        initrd_count += 1
if linux_count != 1 or initrd_count != 1:
    raise SystemExit('the active entry must contain exactly one Linux and one initrd command')
body='\n'.join(entry)+'\n'
for forbidden in ('/boot/initrd-generic.img',f'/boot/initrd-{active}.img'):
    if forbidden in body:
        raise SystemExit('the rollback entry retained an active-kernel initrd')
if f'/boot/vmlinuz-{version}' not in body or f'/boot/initrd-{version}.img' not in body:
    raise SystemExit('the rollback entry is missing its versioned kernel or initrd')
entry_output.write_text(body,encoding='utf-8')
fragment='#!/bin/sh\n\ncat <<\'EOF_SLACK_UPDATE_ROLLBACK\'\n'+body+'EOF_SLACK_UPDATE_ROLLBACK\n'
fragment_output.write_text(fragment,encoding='utf-8')
metadata_output.write_text(json.dumps({
  'active_kernel':active,
  'rollback_kernel':version,
  'source_initrd_vector':source_initrd_vector,
  'microcode_images':microcode,
  'projected_initrd_vector':projected_initrd_vector,
  'active_initrd_retained':False,
  'microcode_precedes_rollback_initrd':projected_initrd_vector == microcode+[f'/boot/initrd-{version}.img'],
  'executed':False,
},indent=2,sort_keys=True)+'\n',encoding='utf-8')
PY
    chmod 0755 "$OUTPUT_DIR/projected-$fragment_name" || return 1
    bash -n "$OUTPUT_DIR/projected-$fragment_name" || return 1
    grub-script-check "$OUTPUT_DIR/projected-grub-menuentry.cfg" >/dev/null 2>&1 || return 1
}

write_apply_plan() {
    local fragment_name="41_slackware_rollback_${CONFIRM_ROLLBACK_KERNEL//./_}"
    python3 - "$OUTPUT_DIR/reconstruction-plan.json" "$SOURCE_PACKAGE" "$SOURCE_SIGNATURE" \
        "$SOURCE_PACKAGE_SHA256" "$SOURCE_SIGNATURE_SHA256" "$SIGNATURE_FINGERPRINT" "$SIGNATURE_PRIMARY_FINGERPRINT" "$KERNEL_MEMBER" \
        "$KERNEL_SHA256" "$KERNEL_SIZE" "$MODULE_FILE_COUNT" "$MODULE_PAYLOAD_BYTES" "$MODULE_MANIFEST_SHA256" \
        "$SPACE_STATE" "$SPACE_RESERVE_BYTES" "$ESTIMATED_INITRD_BYTES" "$SPACE_REQUIRED_BYTES" "$SPACE_AVAILABLE_BYTES" \
        "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$ROOT_UUID" "$ROOT_SOURCE" \
        "$OUTPUT_DIR/projected-mkinitrd-command.json" "$OUTPUT_DIR/projected-$fragment_name" "$OUTPUT_DIR/projected-grub-entry.json" \
        "$CONFIRM_INVENTORY_EVIDENCE_SHA256" "$CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256" \
        "$CONFIRM_REVISION_1_FAILED_PREFLIGHT_EVIDENCE_SHA256" "$CONFIRM_REVISION_2_FAILED_PREFLIGHT_EVIDENCE_SHA256" \
        "$CONFIRM_REVISION_3_FAILED_PREFLIGHT_EVIDENCE_SHA256" "$CONFIRM_REVISION_4_REJECTED_PLAN_EVIDENCE_SHA256" "$CONFIRM_SOURCE_PLAN_SHA256" <<'PY'
import json,pathlib,sys
(out,pkg,sig,pkgsha,sigsha,signing_fingerprint,primary_fingerprint,kernel_member,kernel_sha,kernel_size,module_count,module_bytes,module_manifest_sha,
 space_state,space_reserve,estimated_initrd,space_required,space_available,active,rollback,root_uuid,root_source,mkinitrd_path,fragment_path,grub_entry_path,inventory_sha,failed_sha,revision1_failed_sha,revision2_failed_sha,revision3_failed_sha,revision4_rejected_sha,scope_sha)=sys.argv[1:]
mkinitrd=json.load(open(mkinitrd_path,encoding='utf-8'))['command_vector']
grub_entry=json.load(open(grub_entry_path,encoding='utf-8'))
fragment_name=f'41_slackware_rollback_{rollback.replace(".","_")}'
data={
 'scenario':'current-rollback-source-and-plan-preflight-revision-5','target':'slackware-current',
 'active_kernel':active,'rollback_kernel':rollback,'root_uuid':root_uuid,'root_source':root_source,
 'inventory_archive_sha256':inventory_sha,'failed_preflight_archive_sha256':failed_sha,
 'revision_1_failed_preflight_archive_sha256':revision1_failed_sha,'revision_2_failed_preflight_archive_sha256':revision2_failed_sha,'revision_3_failed_preflight_archive_sha256':revision3_failed_sha,'revision_4_rejected_plan_archive_sha256':revision4_rejected_sha,'source_plan_scope_sha256':scope_sha,
 'source':{'package_path':pkg,'signature_path':sig,'package_sha256':pkgsha,'signature_sha256':sigsha,'signing_fingerprint':signing_fingerprint,'valid_primary_fingerprint':primary_fingerprint},
 'payload':{'kernel_member':kernel_member,'kernel_destination':f'/boot/vmlinuz-{rollback}','kernel_sha256':kernel_sha,'kernel_size':int(kernel_size),'module_destination':f'/lib/modules/{rollback}','module_member_count':int(module_count),'module_payload_bytes':int(module_bytes),'module_manifest_sha256':module_manifest_sha},
 'space_budget':{'state':space_state,'reserve_bytes_per_filesystem':int(space_reserve),'estimated_initrd_bytes':int(estimated_initrd),'aggregate_required_bytes':int(space_required),'minimum_available_bytes':int(space_available)},
 'initrd':{'destination':f'/boot/initrd-{rollback}.img','command_vector':mkinitrd},
 'grub':{'fragment_destination':f'/etc/grub.d/{fragment_name}','fragment_mode':'0755','entry_id':f'slackware-rollback-{rollback}','default_must_remain':'0','active_default_kernel':'/boot/vmlinuz-generic','source_initrd_vector':grub_entry['source_initrd_vector'],'microcode_images':grub_entry['microcode_images'],'projected_initrd_vector':grub_entry['projected_initrd_vector'],'active_initrd_retained':False,'microcode_precedes_rollback_initrd':True},
 'ordered_actions':[
  {'order':1,'id':'revalidate-boundary-and-source-hashes'},
  {'order':2,'id':'create-owner-only-backup-and-extraction-directories'},
  {'order':3,'id':'back-up-depmod-metadata-placeholder-and-active-grub-config'},
  {'order':4,'id':'extract-only-reviewed-kernel-and-module-tree-to-private-staging'},
  {'order':5,'id':'verify-staged-kernel-and-complete-module-manifest'},
  {'order':6,'id':'install-versioned-rollback-kernel-and-module-tree'},
  {'order':7,'id':'run-depmod-for-rollback-kernel'},
  {'order':8,'id':'run-reviewed-versioned-mkinitrd-command'},
  {'order':9,'id':'install-explicit-rollback-grub-fragment'},
  {'order':10,'id':'generate-and-validate-temporary-grub-config'},
  {'order':11,'id':'prove-default-remains-active-6.18.42-entry'},
  {'order':12,'id':'atomically-replace-grub-config-and-verify-final-state'},
 ],
 'rollback_limits':['do-not-change-generic-kernel-link','do-not-change-generic-initrd-link','do-not-change-grub-default','retain-source-package-signature-and-backups'],
 'repository_metadata_refreshed':False,'package_installation_performed':False,'package_database_mutated':False,
 'depmod_executed':False,'initrd_generated':False,'grub_mutated':False,'reboot_performed':False,
 'apply_ready':True,'apply_authorized':False,'next_stage':'current-rollback-reconstruction-authorized-apply-review',
}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n',encoding='utf-8')
PY
    cat > "$OUTPUT_DIR/projected-apply-commands.txt" <<EOF_COMMANDS
# Projected only. These commands are not authorized by this preflight.
# The authorized apply wrapper must revalidate every hash and state invariant.
ROLLBACK_VERSION='$CONFIRM_ROLLBACK_KERNEL'
SOURCE_PACKAGE='$SOURCE_PACKAGE'
SOURCE_SIGNATURE='$SOURCE_SIGNATURE'
EXPECTED_PACKAGE_SHA256='$SOURCE_PACKAGE_SHA256'
EXPECTED_SIGNATURE_SHA256='$SOURCE_SIGNATURE_SHA256'
EXPECTED_KERNEL_SHA256='$KERNEL_SHA256'
EXPECTED_MODULE_MANIFEST_SHA256='$MODULE_MANIFEST_SHA256'
KERNEL_MEMBER='$KERNEL_MEMBER'
BACKUP_ROOT='/var/lib/slack-update/rollback-backups/$CONFIRM_ROLLBACK_KERNEL'
STAGE_ROOT='/var/tmp/slack-update-rollback-apply/$CONFIRM_ROLLBACK_KERNEL'
sha256sum -- "\$SOURCE_PACKAGE" "\$SOURCE_SIGNATURE"
install -d -o root -g root -m 0700 "\$BACKUP_ROOT" "\$STAGE_ROOT"
cp -a -- /lib/modules/$CONFIRM_ROLLBACK_KERNEL "\$BACKUP_ROOT/modules.metadata-placeholder.before"
cp -a -- /boot/grub/grub.cfg "\$BACKUP_ROOT/grub.cfg.before"
tar -xJf "\$SOURCE_PACKAGE" -C "\$STAGE_ROOT" -- "$KERNEL_MEMBER" "lib/modules/$CONFIRM_ROLLBACK_KERNEL"
sha256sum -- "\$STAGE_ROOT/$KERNEL_MEMBER"
install -o root -g root -m 0644 "\$STAGE_ROOT/$KERNEL_MEMBER" /boot/vmlinuz-$CONFIRM_ROLLBACK_KERNEL
mv -- /lib/modules/$CONFIRM_ROLLBACK_KERNEL "\$BACKUP_ROOT/modules.metadata-placeholder.original"
mv -- "\$STAGE_ROOT/lib/modules/$CONFIRM_ROLLBACK_KERNEL" /lib/modules/$CONFIRM_ROLLBACK_KERNEL
chown -R root:root /lib/modules/$CONFIRM_ROLLBACK_KERNEL
depmod -a $CONFIRM_ROLLBACK_KERNEL
$(tail -n 1 "$OUTPUT_DIR/projected-mkinitrd-command.sh")
install -o root -g root -m 0755 '$OUTPUT_DIR/projected-$fragment_name' /etc/grub.d/$fragment_name
grub-mkconfig -o "\$STAGE_ROOT/grub.cfg.new"
grub-script-check "\$STAGE_ROOT/grub.cfg.new"
# Verify that selector 0 still resolves to /boot/vmlinuz-generic and /boot/initrd-generic.img.
install -o root -g root -m 0600 "\$STAGE_ROOT/grub.cfg.new" /boot/grub/grub.cfg.new
mv -f -- /boot/grub/grub.cfg.new /boot/grub/grub.cfg
EOF_COMMANDS
}

write_analysis() {
    python3 - "$OUTPUT_DIR/source-and-plan-analysis.json" "$HOSTNAME_SHORT" "$HOSTNAME_FQDN" "$RUNNING_KERNEL" \
        "$CONFIRM_ACTIVE_KERNEL" "$CONFIRM_ROLLBACK_KERNEL" "$ROOT_UUID" "$ROOT_SOURCE" "$SOURCE_ACQUISITION" \
        "$SOURCE_PACKAGE" "$SOURCE_SIGNATURE" "$SOURCE_PACKAGE_SHA256" "$SOURCE_SIGNATURE_SHA256" \
        "$SOURCE_PACKAGE_SIZE" "$SOURCE_SIGNATURE_SIZE" "$SIGNATURE_FINGERPRINT" "$SIGNATURE_PRIMARY_FINGERPRINT" "$KERNEL_MEMBER" \
        "$KERNEL_SHA256" "$KERNEL_SIZE" "$MODULE_FILE_COUNT" "$MODULE_PAYLOAD_BYTES" "$MODULE_MANIFEST_SHA256" \
        "$SPACE_STATE" "$SPACE_RESERVE_BYTES" "$ESTIMATED_INITRD_BYTES" "$SPACE_REQUIRED_BYTES" "$SPACE_AVAILABLE_BYTES" "$APPLY_READY" \
        "$NEXT_STAGE" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$CONFIRM_INVENTORY_EVIDENCE_SHA256" \
        "$CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256" "$CONFIRM_REVISION_1_FAILED_PREFLIGHT_EVIDENCE_SHA256" \
        "$CONFIRM_REVISION_2_FAILED_PREFLIGHT_EVIDENCE_SHA256" "$CONFIRM_REVISION_3_FAILED_PREFLIGHT_EVIDENCE_SHA256" "$CONFIRM_REVISION_4_REJECTED_PLAN_EVIDENCE_SHA256" "$CONFIRM_SOURCE_PLAN_SHA256" <<'PY'
import json,pathlib,sys
(out,host,fqdn,running,active,rollback,root_uuid,root_source,acquisition,pkg,sig,pkgsha,sigsha,
 pkgsize,sigsize,signing_fingerprint,primary_fingerprint,kernel_member,kernel_sha,kernel_size,module_count,module_bytes,module_manifest_sha,
 space_state,space_reserve,estimated_initrd,space_required,space_available,ready,next_stage,
 passes,failures,skips,inventory_sha,failed_sha,revision1_failed_sha,revision2_failed_sha,revision3_failed_sha,revision4_rejected_sha,scope_sha)=sys.argv[1:]
data={
 'scenario':'current-rollback-source-and-plan-preflight-revision-5','target':'slackware-current','hostname_short':host,
 'hostname_fqdn':fqdn,'running_kernel':running,'active_kernel':active,'rollback_kernel':rollback,
 'root_uuid':root_uuid,'root_source':root_source,'inventory_archive_sha256':inventory_sha,
 'failed_preflight_archive_sha256':failed_sha,
 'revision_1_failed_preflight_archive_sha256':revision1_failed_sha,
 'revision_2_failed_preflight_archive_sha256':revision2_failed_sha,
 'revision_3_failed_preflight_archive_sha256':revision3_failed_sha,
 'revision_4_rejected_plan_archive_sha256':revision4_rejected_sha,
 'source_plan_scope_sha256':scope_sha,'rollback_module_state':'depmod-metadata-only-placeholder',
 'source_acquisition':acquisition,'source_package':{'path':pkg,'sha256':pkgsha,'size':int(pkgsize or 0)},
 'source_signature':{'path':sig,'sha256':sigsha,'size':int(sigsize or 0),'signing_fingerprint':signing_fingerprint,'valid_fingerprint':primary_fingerprint},
 'payload':{'kernel_member':kernel_member,'kernel_sha256':kernel_sha,'kernel_size':int(kernel_size or 0),'module_member_count':int(module_count or 0),'module_payload_bytes':int(module_bytes or 0),'module_manifest_sha256':module_manifest_sha},
 'space_budget':{'state':space_state,'reserve_bytes_per_filesystem':int(space_reserve or 0),'estimated_initrd_bytes':int(estimated_initrd or 0),'aggregate_required_bytes':int(space_required or 0),'minimum_available_bytes':int(space_available or 0)},
 'repository_metadata_refreshed':False,'package_installation_performed':False,'package_database_mutated':False,
 'depmod_executed':False,'initrd_generated':False,'grub_mutated':False,'reboot_performed':False,
 'system_state_mutated':False,'source_staging_created':acquisition in ('downloaded-https','reused-staging'),
 'apply_ready':ready=='true','apply_authorized':False,'next_stage':next_stage,
 'assertions':{'passes':int(passes),'failures':int(failures),'skips':int(skips)},
}
pathlib.Path(out).write_text(json.dumps(data,indent=2,sort_keys=True)+'\n',encoding='utf-8')
PY
}

write_summary() {
    cat > "$OUTPUT_DIR/summary.txt" <<EOF_SUMMARY
scenario=current-rollback-source-and-plan-preflight-revision-5
target=$TARGET
result=$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)
passes=$PASS_COUNT
failures=$FAILURE_COUNT
skips=$SKIP_COUNT
hostname_short=$HOSTNAME_SHORT
hostname_fqdn=$HOSTNAME_FQDN
running_kernel=$RUNNING_KERNEL
active_kernel=$CONFIRM_ACTIVE_KERNEL
rollback_kernel=$CONFIRM_ROLLBACK_KERNEL
rollback_module_state=depmod-metadata-only-placeholder
inventory_evidence_sha256=$CONFIRM_INVENTORY_EVIDENCE_SHA256
failed_preflight_evidence_sha256=$CONFIRM_FAILED_PREFLIGHT_EVIDENCE_SHA256
revision_1_failed_preflight_evidence_sha256=$CONFIRM_REVISION_1_FAILED_PREFLIGHT_EVIDENCE_SHA256
revision_2_failed_preflight_evidence_sha256=$CONFIRM_REVISION_2_FAILED_PREFLIGHT_EVIDENCE_SHA256
revision_3_failed_preflight_evidence_sha256=$CONFIRM_REVISION_3_FAILED_PREFLIGHT_EVIDENCE_SHA256
revision_4_rejected_plan_evidence_sha256=$CONFIRM_REVISION_4_REJECTED_PLAN_EVIDENCE_SHA256
source_plan_scope_sha256=$CONFIRM_SOURCE_PLAN_SHA256
source_acquisition=$SOURCE_ACQUISITION
source_package=$SOURCE_PACKAGE
source_package_sha256=$SOURCE_PACKAGE_SHA256
source_package_size=$SOURCE_PACKAGE_SIZE
source_signature=$SOURCE_SIGNATURE
source_signature_sha256=$SOURCE_SIGNATURE_SHA256
signature_fingerprint=$SIGNATURE_FINGERPRINT
signature_primary_fingerprint=$SIGNATURE_PRIMARY_FINGERPRINT
kernel_member=$KERNEL_MEMBER
kernel_sha256=$KERNEL_SHA256
kernel_size=$KERNEL_SIZE
module_member_count=$MODULE_FILE_COUNT
module_payload_bytes=$MODULE_PAYLOAD_BYTES
module_manifest_sha256=$MODULE_MANIFEST_SHA256
space_state=$SPACE_STATE
space_reserve_bytes=$SPACE_RESERVE_BYTES
estimated_initrd_bytes=$ESTIMATED_INITRD_BYTES
space_required_bytes=$SPACE_REQUIRED_BYTES
space_available_bytes=$SPACE_AVAILABLE_BYTES
repository_metadata_refreshed=false
package_installation_performed=false
package_database_mutated=false
depmod_executed=false
initrd_generated=false
grub_mutated=false
reboot_performed=false
apply_ready=$APPLY_READY
apply_authorized=false
next_stage=$NEXT_STAGE
EOF_SUMMARY
}

publish_evidence() {
    local parent base archive owner group
    parent=$(dirname -- "$OUTPUT_DIR")
    base=$(basename -- "$OUTPUT_DIR")
    archive="$parent/$base.tar.gz"
    tar -C "$parent" -czf "$archive" "$base" || return 1
    (cd "$parent" && sha256sum -- "$base.tar.gz" > "$base.tar.gz.sha256") || return 1
    owner=${SUDO_USER:-}
    if [ -z "$owner" ] || [ "$owner" = root ]; then owner=${ROLLBACK_PLAN_EVIDENCE_OWNER:-promano}; fi
    group=$(id -gn "$owner" 2>/dev/null || printf users)
    chmod 0600 "$archive" "$archive.sha256" || return 1
    printf 'Evidence archive: %s\n' "$archive"
    printf 'Evidence SHA-256: %s\n' "$(file_sha256 "$archive")"
    printf 'Copy evidence command: sudo install -o %s -g %s -m 0600 %q /home/%s/%q\n' "$owner" "$group" "$archive" "$owner" "$(basename -- "$archive")"
    printf 'Copy sidecar command: sudo install -o %s -g %s -m 0600 %q /home/%s/%q\n' "$owner" "$group" "$archive.sha256" "$owner" "$(basename -- "$archive.sha256")"
    printf 'Copy evidence pair command: sudo install -o %s -g %s -m 0600 %q /home/%s/%q && sudo install -o %s -g %s -m 0600 %q /home/%s/%q\n'         "$owner" "$group" "$archive" "$owner" "$(basename -- "$archive")"         "$owner" "$group" "$archive.sha256" "$owner" "$(basename -- "$archive.sha256")"
    if [ "$SOURCE_ACQUISITION" = pre-staged ]; then
        printf 'Source package retained: %s\n' "$SOURCE_PACKAGE"
        printf 'Source signature retained: %s\n' "$SOURCE_SIGNATURE"
    else
        printf 'Copy package command: sudo install -o %s -g %s -m 0600 %q /home/%s/%q\n' "$owner" "$group" "$SOURCE_PACKAGE" "$owner" "$(basename -- "$SOURCE_PACKAGE")"
        printf 'Copy signature command: sudo install -o %s -g %s -m 0600 %q /home/%s/%q\n' "$owner" "$group" "$SOURCE_SIGNATURE" "$owner" "$(basename -- "$SOURCE_SIGNATURE")"
    fi
    printf 'Verify evidence command: cd /home/%s && sha256sum -c %q\n' "$owner" "$(basename -- "$archive.sha256")"
}

main() {
    local timestamp slackware_version
    parse_arguments "$@" || { print_usage >&2; return 2; }
    [ "$(id -u)" -eq 0 ] || { error 'this preflight must run as root'; return 2; }
    if [ "$TEST_MODE" = 1 ]; then
        ROOT_PREFIX=${SLACK_UPDATE_TEST_ROOT:-}
        PATH=${SLACK_UPDATE_TEST_PATH:-$PATH}; export PATH
        HOSTNAME_SHORT=${SLACK_UPDATE_TEST_HOSTNAME_SHORT:-}
        HOSTNAME_FQDN=${SLACK_UPDATE_TEST_HOSTNAME_FQDN:-}
        RUNNING_KERNEL=${SLACK_UPDATE_TEST_RUNNING_KERNEL:-}
        ARCHITECTURE=${SLACK_UPDATE_TEST_ARCHITECTURE:-}
        ROOT_UUID=${SLACK_UPDATE_TEST_ROOT_UUID:-}
        ROOT_SOURCE=${SLACK_UPDATE_TEST_ROOT_SOURCE:-}
    else
        ROOT_PREFIX=
        HOSTNAME_SHORT=$(hostname -s) || return 2
        HOSTNAME_FQDN=$(hostname -f) || return 2
        RUNNING_KERNEL=$(uname -r) || return 2
        ARCHITECTURE=$(uname -m) || return 2
        ROOT_UUID=$(findmnt -n -o UUID /) || return 2
        ROOT_SOURCE=$(findmnt -n -o SOURCE /) || return 2
    fi
    slackware_version=$(cat "$(rooted /etc/slackware-version)" 2>/dev/null || true)
    [ "$slackware_version" = 'Slackware 15.0+' ] || { error 'Slackware-current target mismatch'; return 2; }
    for command_name in awk bash chmod cmp curl date df find findmnt gpg gpgv grep grub-editenv grub-script-check hostname id mkdir mktemp mv python3 readlink rm sha256sum sort stat tar tee uname wc; do
        if [ "$TEST_MODE" = 1 ] && { [ "$command_name" = findmnt ] || [ "$command_name" = hostname ] || [ "$command_name" = uname ]; }; then continue; fi
        command -v "$command_name" >/dev/null 2>&1 || { error "required command missing: $command_name"; return 2; }
    done
    for reviewed_file in "$DIAGNOSTIC_RECORD" "$FAILED_PREFLIGHT_RECORD" "$REVISION_1_FAILED_PREFLIGHT_RECORD" "$REVISION_2_FAILED_PREFLIGHT_RECORD" "$REVISION_3_FAILED_PREFLIGHT_RECORD" "$GENINITRD_RECORD" "$SIGNING_KEY" "$PLAN_POLICY" "$PLAN_SCRIPT"; do
        require_regular_file "$reviewed_file" || { error "reviewed file is missing or unsafe: $reviewed_file"; return 2; }
    done
    bash -n "$PLAN_SCRIPT" || { error 'source and plan preflight has invalid shell syntax'; return 2; }
    if [ -d "$(rooted /var/lib/pkgtools/packages)" ] && [ ! -L "$(rooted /var/lib/pkgtools/packages)" ]; then
        PACKAGE_DATABASE=$(rooted /var/lib/pkgtools/packages)
    elif [ -d "$(rooted /var/log/packages)" ] && [ ! -L "$(rooted /var/log/packages)" ]; then
        PACKAGE_DATABASE=$(rooted /var/log/packages)
    else
        error 'installed package database is unavailable'; return 2
    fi
    timestamp=$(date -u +%Y%m%dT%H%M%SZ)
    [ -n "$OUTPUT_DIR" ] || OUTPUT_DIR="$DEFAULT_OUTPUT_ROOT/${TARGET}-${timestamp}"
    [ ! -e "$OUTPUT_DIR" ] && [ ! -L "$OUTPUT_DIR" ] || { error "output exists: $OUTPUT_DIR"; return 2; }
    mkdir -m 0700 -p -- "$OUTPUT_DIR" || return 2
    ASSERTION_LOG=$OUTPUT_DIR/assertions.log
    : > "$ASSERTION_LOG"

    if validate_reviewed_boundary; then
        REVIEWED_BOUNDARY_VALID=true
        record_pass 'the corrected inventory, four failed diagnostics, rejected revision-4 plan, reviewed signing key, historical initrd command, exact code, and revision-5 scope are bound'
    else
        record_failure 'the corrected diagnostic boundary, a failed step-87 evidence record, or explicit revision scope is missing, changed, or mismatched'
    fi

    capture_package_database "$OUTPUT_DIR/packages.before.txt" \
        && capture_package_names "$OUTPUT_DIR/package-names.before.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.before.txt" \
        && record_pass 'the package database and rollback-sensitive state were captured before source verification' \
        || record_failure 'the package database or rollback-sensitive state could not be captured before source verification'

    if record_live_boundary_results; then
        LIVE_BOUNDARY_VALID=true
    fi

    if record_source_acquisition_results; then
        SOURCE_ACQUIRED=true
    fi

    if [ "$SOURCE_ACQUIRED" = true ]; then
        if require_regular_file "$SOURCE_PACKAGE" && require_regular_file "$SOURCE_SIGNATURE" && verify_source_signature; then
            SOURCE_SIGNATURE_VALID=true
            record_pass 'the detached signature is valid under the exact reviewed Slackware primary-key fingerprint'
        else
            record_failure 'the historical package signature is invalid, untrusted, missing, or ambiguous'
        fi
    else
        record_skip 'signature verification requires a safely acquired package and detached signature'
    fi

    if [ "$SOURCE_SIGNATURE_VALID" = true ]; then
        if inspect_source_package; then
            SOURCE_PACKAGE_VALID=true
            record_pass 'the signed package safely supplies one versioned kernel image and a complete non-empty 6.18.40 module payload'
        else
            record_failure 'the signed package layout, kernel identity, module payload, ownership, modes, or archive paths are unsafe'
        fi
    else
        record_skip 'package payload inspection requires a valid detached signature'
    fi

    if [ "$SOURCE_PACKAGE_VALID" = true ]; then
        if evaluate_space_budget; then
            SPACE_BUDGET_VALID=true
            record_pass 'the conservative per-filesystem reconstruction space budget is sufficient'
        else
            record_failure 'the kernel, module, initrd, staging, backup, and reserve space budget is insufficient or unavailable'
        fi
    else
        record_skip 'space-budget evaluation requires the inspected kernel and module payload sizes'
    fi

    if [ "$REVIEWED_BOUNDARY_VALID" = true ]; then
        if project_initrd_command; then
            INITRD_PROJECTION_VALID=true
            record_pass 'the accepted 6.18.40 mkinitrd vector was projected to the versioned rollback initrd without execution'
        else
            record_failure 'the historical accepted initrd command cannot be projected exactly for the rollback'
        fi
    else
        record_skip 'initrd projection requires the reviewed revision boundary'
    fi

    if [ "$LIVE_BOUNDARY_VALID" = true ]; then
        if project_grub_entry; then
            GRUB_PROJECTION_VALID=true
            record_pass 'a syntax-valid explicit rollback GRUB entry was projected without changing the active default'
        else
            record_failure 'the explicit rollback GRUB entry cannot be projected safely from the accepted active entry'
        fi
    else
        record_skip 'GRUB projection requires a fully valid live boot boundary'
    fi

    if [ "$REVIEWED_BOUNDARY_VALID" = true ] && [ "$LIVE_BOUNDARY_VALID" = true ] \
        && [ "$SOURCE_PACKAGE_VALID" = true ] && [ "$SPACE_BUDGET_VALID" = true ] \
        && [ "$INITRD_PROJECTION_VALID" = true ] && [ "$GRUB_PROJECTION_VALID" = true ]; then
        if write_apply_plan; then
            APPLY_PLAN_VALID=true
            record_pass 'the exact ordered reconstruction, verification, placeholder backup, and recovery plan was recorded without execution'
        else
            record_failure 'the reconstruction plan could not be recorded completely'
        fi
    else
        record_skip 'the complete reconstruction plan requires all independent source, live-boundary, space, initrd, and GRUB prerequisites'
    fi

    capture_package_database "$OUTPUT_DIR/packages.after.txt" \
        && capture_package_names "$OUTPUT_DIR/package-names.after.txt" \
        && capture_sensitive_state "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the package database and rollback-sensitive state were captured after planning' \
        || record_failure 'the final package database or rollback-sensitive state could not be captured'

    cmp -s "$OUTPUT_DIR/packages.before.txt" "$OUTPUT_DIR/packages.after.txt" \
        && cmp -s "$OUTPUT_DIR/package-names.before.txt" "$OUTPUT_DIR/package-names.after.txt" \
        && record_pass 'the installed package database remained unchanged throughout source verification and planning' \
        || record_failure 'the installed package database changed during the non-installing preflight'

    cmp -s "$OUTPUT_DIR/sensitive.before.txt" "$OUTPUT_DIR/sensitive.after.txt" \
        && record_pass 'the active kernel, rollback placeholder, initrd, GenInitrd, and GRUB state remained unchanged' \
        || record_failure 'rollback-sensitive installed-system state changed during the non-mutating preflight'

    if [ "$FAILURE_COUNT" -eq 0 ] && [ "$APPLY_PLAN_VALID" = true ]; then
        APPLY_READY=true
        NEXT_STAGE=current-rollback-reconstruction-authorized-apply-review
        record_pass 'the signed source and exact reconstruction plan are ready for separate explicit apply authorization'
    else
        APPLY_READY=false
        NEXT_STAGE=current-rollback-source-and-plan-manual-review
        record_skip 'apply readiness is unavailable because one or more independent prerequisites failed'
    fi

    write_analysis || return 2
    write_summary || return 2
    chmod -R go-rwx "$OUTPUT_DIR" || return 2
    publish_evidence || return 2
    printf 'Result: %s (%d passes, %d failures, %d skips); apply_ready=%s; apply_authorized=false; next_stage=%s\n' \
        "$([ "$FAILURE_COUNT" -eq 0 ] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAILURE_COUNT" "$SKIP_COUNT" "$APPLY_READY" "$NEXT_STAGE"
    [ "$FAILURE_COUNT" -eq 0 ]
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
