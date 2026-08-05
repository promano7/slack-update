#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
ACCEPTANCE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-normal-update.sh"
DEFAULT_CONFIG="$REPOSITORY_ROOT/data/config/slack-update.conf"
INSTALL_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/install-new-probe.log"
UPGRADE_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/upgrade-all-probe.log"
ACCEPTED_CURRENT_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-accepted.json"
REVIEWED_CURRENT_APPLY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-apply-reviewed.json"
CURRENT_PARSER_DIAGNOSTIC="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260803-parser-diagnostic.json"
ACCEPTED_SLACKWARE15_PREFLIGHT="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-15.0-preflight-accepted.json"
ACCEPTED_SLACKWARE15_APPLY="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/slackware-15.0-apply-accepted.json"

# Source helpers without executing the real-system scenario.
# shellcheck source=../acceptance/reference/test-normal-update.sh
source "$ACCEPTANCE_SCRIPT"

TEST_COUNT=0
TEST_FAILURE_COUNT=0

pass() {
    TEST_COUNT=$((TEST_COUNT + 1))
}

fail() {
    local message=$1

    TEST_COUNT=$((TEST_COUNT + 1))
    TEST_FAILURE_COUNT=$((TEST_FAILURE_COUNT + 1))
    printf 'FAIL: %s\n' "$message" >&2
}

assert_equal_value() {
    local expected=$1
    local actual=$2
    local message=$3

    if [ "$actual" = "$expected" ]; then
        pass
    else
        fail "$message (expected '$expected', got '$actual')"
    fi
}

assert_file_contains() {
    local pattern=$1
    local path=$2
    local message=$3

    if grep -Fq -- "$pattern" "$path"; then
        pass
    else
        fail "$message"
    fi
}

assert_file_not_contains() {
    local pattern=$1
    local path=$2
    local message=$3

    if grep -Fq -- "$pattern" "$path"; then
        fail "$message"
    else
        pass
    fi
}

assert_success() {
    local message=$1
    shift

    if "$@"; then
        pass
    else
        fail "$message"
    fi
}

assert_failure() {
    local message=$1
    shift

    if "$@" >/dev/null 2>&1; then
        fail "$message"
    else
        pass
    fi
}

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

assert_file_contains 'Always run --preflight first.' "$ACCEPTANCE_SCRIPT" \
    'the usage text should require preflight before a real update'
assert_file_contains '--confirm-hostname is required with --execute-apply' "$ACCEPTANCE_SCRIPT" \
    'real apply should require an exact hostname confirmation'
assert_file_contains '--allow-kernel-update' "$ACCEPTANCE_SCRIPT" \
    'kernel candidates should require an additional explicit option'
assert_file_contains '--allow-critical-update' "$ACCEPTANCE_SCRIPT" \
    'critical candidates should require an independent explicit option'
assert_file_contains '--confirm-candidates-sha256' "$ACCEPTANCE_SCRIPT" \
    'real apply should require the exact reviewed candidate-set digest'
assert_file_contains 'the refreshed candidate set does not match the explicitly reviewed SHA-256' "$ACCEPTANCE_SCRIPT" \
    'candidate-set changes should fail closed before real apply'
assert_file_contains 'critical candidates require the explicit --allow-critical-update option' "$ACCEPTANCE_SCRIPT" \
    'critical candidates should fail closed before real apply'
assert_file_contains 'slackpkg -dialog=off -batch=on -default_answer=n' "$ACCEPTANCE_SCRIPT" \
    'candidate probing should use a non-interactive negative answer'
assert_file_contains 'slackpkg -dialog=off -batch=on -default_answer=y update' "$ACCEPTANCE_SCRIPT" \
    'candidate classification should follow a non-interactive metadata refresh'
assert_file_contains 'metadata.update.exit' "$ACCEPTANCE_SCRIPT" \
    'the evidence should preserve the metadata refresh status'
assert_file_contains 'candidate probing did not modify the installed package database' "$ACCEPTANCE_SCRIPT" \
    'preflight should prove that package state is unchanged'
assert_file_contains 'candidate probing did not modify initrd or GRUB state' "$ACCEPTANCE_SCRIPT" \
    'preflight should prove that boot state is unchanged'
assert_file_contains 'the failed real apply left the installed package database unchanged' "$ACCEPTANCE_SCRIPT" \
    'an early failed apply should record unchanged package state without claiming a partial transaction'
assert_file_contains 'the failed real apply partially changed the installed package database' "$ACCEPTANCE_SCRIPT" \
    'a failed apply with package drift should be classified as a partial transaction'
assert_file_contains 'BOOT_CMDLINE_FILE=/proc/cmdline' "$ACCEPTANCE_SCRIPT" \
    'the real apply boundary should initialize the direct-generic command-line source'
assert_file_contains 'run_reference_apply' "$ACCEPTANCE_SCRIPT" \
    'the scenario should exercise the real reference apply workflow'
assert_file_contains 'mode=disabled' "$ACCEPTANCE_SCRIPT" \
    'non-Slackware optional modules should be isolated'
assert_file_contains 'boot mode is not auto' "$ACCEPTANCE_SCRIPT" \
    'apply validation should require automatic boot preparation'
assert_file_contains 'Copy evidence command:' "$ACCEPTANCE_SCRIPT" \
    'the scenario should print a one-line evidence copy command'
assert_file_contains 'Verify evidence command:' "$ACCEPTANCE_SCRIPT" \
    'the scenario should print a destination-side verification command'
assert_file_contains 'owner=${SUDO_USER:-promano}' "$ACCEPTANCE_SCRIPT" \
    'the evidence copy fallback should default to the promano account'
assert_file_contains 'postinstall_policy' "$ACCEPTANCE_SCRIPT" \
    'apply validation should require the explicit deferred post-install policy'
assert_file_contains 'postinstall_processing_enabled' "$ACCEPTANCE_SCRIPT" \
    'apply validation should reject interactive slackpkg post-install processing'
assert_file_contains 'pending_new_config_files_count' "$ACCEPTANCE_SCRIPT" \
    'apply validation should preserve the pending .new configuration-file count'
assert_file_contains 'kernel_changes is intentionally broader than boot-kernel replacement' "$ACCEPTANCE_SCRIPT" \
    'apply validation should distinguish broad kernel package changes from boot preparation'
assert_file_not_contains 'rm -rf /var/log/packages' "$ACCEPTANCE_SCRIPT" \
    'the scenario must never remove the package database'

assert_success 'Slackware 15.0 should be a valid target' \
    validate_target_name slackware-15.0
assert_success 'Slackware-current should be a valid target' \
    validate_target_name slackware-current
assert_failure 'unknown Slackware targets should be rejected' \
    validate_target_name slackware-14.2
assert_success 'Slackware 15.0 should match the stable target' \
    validate_slackware_target_version slackware-15.0 'Slackware 15.0'
assert_success 'Slackware 15.0+ should match current' \
    validate_slackware_target_version slackware-current 'Slackware 15.0+'
assert_failure 'Slackware 15.0 should not match current' \
    validate_slackware_target_version slackware-current 'Slackware 15.0'

TARGET=
MODE=
OUTPUT_DIR=
REFERENCE_SCRIPT=$DEFAULT_REFERENCE_SCRIPT
CONFIG_TEMPLATE=$DEFAULT_CONFIG
CONFIRM_HOSTNAME=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256=
ALLOW_KERNEL_UPDATE=0
ALLOW_CRITICAL_UPDATE=0
assert_success 'preflight arguments should parse without apply confirmation' \
    parse_arguments --target slackware-current --preflight
assert_equal_value preflight "$MODE" 'preflight should select preflight mode'

TARGET=
MODE=
OUTPUT_DIR=
REFERENCE_SCRIPT=$DEFAULT_REFERENCE_SCRIPT
CONFIG_TEMPLATE=$DEFAULT_CONFIG
CONFIRM_HOSTNAME=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256=
ALLOW_KERNEL_UPDATE=0
ALLOW_CRITICAL_UPDATE=0
assert_failure 'apply should fail without hostname confirmation' \
    parse_arguments --target slackware-current --execute-apply

TARGET=
MODE=
OUTPUT_DIR=
REFERENCE_SCRIPT=$DEFAULT_REFERENCE_SCRIPT
CONFIG_TEMPLATE=$DEFAULT_CONFIG
CONFIRM_HOSTNAME=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256=
ALLOW_KERNEL_UPDATE=0
ALLOW_CRITICAL_UPDATE=0
assert_failure 'apply should fail when hostname is present but candidate digest is missing' \
    parse_arguments --target slackware-current --execute-apply --confirm-hostname testhost

TARGET=
MODE=
OUTPUT_DIR=
REFERENCE_SCRIPT=$DEFAULT_REFERENCE_SCRIPT
CONFIG_TEMPLATE=$DEFAULT_CONFIG
CONFIRM_HOSTNAME=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256=
ALLOW_KERNEL_UPDATE=0
ALLOW_CRITICAL_UPDATE=0
assert_failure 'apply should reject a malformed candidate digest' \
    parse_arguments --target slackware-current --execute-apply \
        --confirm-hostname testhost --confirm-candidates-sha256 invalid

TARGET=
MODE=
OUTPUT_DIR=
REFERENCE_SCRIPT=$DEFAULT_REFERENCE_SCRIPT
CONFIG_TEMPLATE=$DEFAULT_CONFIG
CONFIRM_HOSTNAME=
CONFIRM_CANDIDATES_SHA256=
CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256=
ALLOW_KERNEL_UPDATE=0
ALLOW_CRITICAL_UPDATE=0
assert_success 'apply should parse with hostname and kernel confirmation' \
    parse_arguments --target slackware-current --execute-apply \
        --confirm-hostname testhost \
        --confirm-candidates-sha256 a8a608d8aac53c0d9f027622c01df4f794e94e8dd4586764b8d2503f9b94e45d \
        --confirm-kernel-boot-preflight-sha256 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef \
        --allow-kernel-update --allow-critical-update
assert_equal_value apply "$MODE" 'execute-apply should select apply mode'
assert_equal_value testhost "$CONFIRM_HOSTNAME" 'the hostname confirmation should be preserved'
assert_equal_value a8a608d8aac53c0d9f027622c01df4f794e94e8dd4586764b8d2503f9b94e45d "$CONFIRM_CANDIDATES_SHA256" \
    'the candidate-set confirmation should be preserved'
assert_equal_value 1 "$ALLOW_KERNEL_UPDATE" 'the kernel confirmation should be preserved'
assert_equal_value 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef "$CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256" \
    'the kernel boot preflight digest should be preserved'
assert_equal_value 1 "$ALLOW_CRITICAL_UPDATE" 'the critical confirmation should be preserved'

CANDIDATE_SET_SHA256=d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1
CONFIRM_KERNEL_BOOT_PREFLIGHT_SHA256=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
DEFAULT_CURRENT_KERNEL_BOOT_ACCEPTANCE="$TEST_TMP/current-kernel-accepted.json"
cat > "$DEFAULT_CURRENT_KERNEL_BOOT_ACCEPTANCE" <<'EOF_CURRENT_KERNEL_ACCEPTED'
{
  "scenario": "current-kernel-boot-preflight",
  "target": "slackware-current",
  "accepted": true,
  "archive_sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
  "normal_update_candidate_set_sha256": "d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1",
  "apply_ready": true,
  "apply_authorized": false
}
EOF_CURRENT_KERNEL_ACCEPTED
assert_success 'a matching apply-ready current-kernel preflight should validate' \
    validate_current_kernel_boot_acceptance
python3 - "$DEFAULT_CURRENT_KERNEL_BOOT_ACCEPTANCE" <<'PY_CURRENT_KERNEL_NOT_READY'
import json, sys
p=sys.argv[1]
d=json.load(open(p))
d['apply_ready']=False
open(p,'w').write(json.dumps(d))
PY_CURRENT_KERNEL_NOT_READY
assert_failure 'a non-ready current-kernel preflight should be rejected' \
    validate_current_kernel_boot_acceptance

DEFAULT_CURRENT_KERNEL_BOOT_ACCEPTANCE="$TEST_TMP/missing-current-kernel-boot.json"
DEFAULT_CURRENT_KERNEL_TRANSACTION_READINESS_ACCEPTANCE="$TEST_TMP/current-kernel-readiness-accepted.json"
cat > "$DEFAULT_CURRENT_KERNEL_TRANSACTION_READINESS_ACCEPTANCE" <<'EOF_CURRENT_KERNEL_READINESS'
{
  "scenario": "current-kernel-transaction-readiness-preflight",
  "target": "slackware-current",
  "accepted": true,
  "archive_sha256": "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef",
  "candidate_set_sha256": "d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1",
  "fresh_candidate_set_sha256": "d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1",
  "readiness_status": "apply-ready",
  "apply_ready": true,
  "apply_authorized": false,
  "pause_safe": false,
  "next_stage": "normal-update-apply-authorization-review"
}
EOF_CURRENT_KERNEL_READINESS
assert_success 'a matching final transaction-readiness record should validate for current apply' \
    validate_current_kernel_boot_acceptance
python3 - "$DEFAULT_CURRENT_KERNEL_TRANSACTION_READINESS_ACCEPTANCE" <<'PY_CURRENT_READINESS_PAUSE'
import json, sys
p=sys.argv[1]
d=json.load(open(p))
d['pause_safe']=True
open(p,'w').write(json.dumps(d))
PY_CURRENT_READINESS_PAUSE
assert_failure 'a readiness record with an unexpected pause-safe state should be rejected' \
    validate_current_kernel_boot_acceptance

GENERATED_CONFIG="$TEST_TMP/slack-update.conf"
write_acceptance_config "$DEFAULT_CONFIG" "$GENERATED_CONFIG" "$TEST_TMP/runtime"
assert_equal_value 0 "$?" 'the isolated configuration should be generated'
assert_equal_value 4 "$(grep -c '^mode=disabled$' "$GENERATED_CONFIG")" \
    'Flatpak, SBo, ELF, and Cinnamon should be disabled'
assert_equal_value 1 "$(grep -c '^mode=auto$' "$GENERATED_CONFIG")" \
    'only the boot module should remain in auto mode'
assert_file_contains 'work_dir='"$TEST_TMP/runtime/work" "$GENERATED_CONFIG" \
    'the work directory should remain inside evidence storage'
assert_file_contains 'log_dir='"$TEST_TMP/runtime/log" "$GENERATED_CONFIG" \
    'the log directory should remain inside evidence storage'
assert_file_contains 'lock_file='"$TEST_TMP/runtime/slack-update.lock" "$GENERATED_CONFIG" \
    'the lock should remain inside evidence storage'

SLACKPKG_REFRESH_STATUS=0
SLACKPKG_REFRESH_ARGUMENTS="$TEST_TMP/metadata-refresh-arguments.txt"
slackpkg() {
    printf '%s' "$1" > "$SLACKPKG_REFRESH_ARGUMENTS"
    shift
    printf ' %s' "$@" >> "$SLACKPKG_REFRESH_ARGUMENTS"
    printf '\n' >> "$SLACKPKG_REFRESH_ARGUMENTS"
    printf '%s\n' 'mock metadata refresh output'
    return "$SLACKPKG_REFRESH_STATUS"
}
run_metadata_refresh "$TEST_TMP/metadata.update.log" "$TEST_TMP/metadata.update.exit"
assert_equal_value 0 "$?" 'a successful metadata refresh should return zero'
assert_equal_value 0 "$(cat "$TEST_TMP/metadata.update.exit")" \
    'a successful metadata refresh should preserve status zero'
assert_file_contains '-dialog=off -batch=on -default_answer=y update' \
    "$SLACKPKG_REFRESH_ARGUMENTS" \
    'metadata refresh should use deterministic non-interactive arguments'
assert_file_contains 'mock metadata refresh output' "$TEST_TMP/metadata.update.log" \
    'metadata refresh output should be retained as evidence'
SLACKPKG_REFRESH_STATUS=30
assert_failure 'a failed metadata refresh should fail closed' \
    run_metadata_refresh "$TEST_TMP/metadata-failure.log" "$TEST_TMP/metadata-failure.exit"
assert_equal_value 30 "$(cat "$TEST_TMP/metadata-failure.exit")" \
    'a failed metadata refresh should preserve its raw status'
unset -f slackpkg

extract_slackpkg_candidates "$INSTALL_FIXTURE" "$TEST_TMP/install.txt"
assert_equal_value 0 "$?" 'install-new candidates should be parsed'
assert_equal_value 1 "$(wc -l < "$TEST_TMP/install.txt")" \
    'one install-new candidate should be extracted'
assert_file_contains 'new-runtime-1.2.3-x86_64-1.txz' "$TEST_TMP/install.txt" \
    'the install-new filename should be preserved'

extract_slackpkg_candidates "$UPGRADE_FIXTURE" "$TEST_TMP/upgrade.txt"
assert_equal_value 0 "$?" 'upgrade-all candidates should be parsed'
assert_equal_value 5 "$(wc -l < "$TEST_TMP/upgrade.txt")" \
    'five upgrade candidates should be extracted'
assert_file_contains 'kernel-generic-6.18.40-x86_64-1.txz' "$TEST_TMP/upgrade.txt" \
    'the generic-kernel candidate should be extracted'
assert_file_contains 'kernel-headers-6.18.40-x86-1.txz' "$TEST_TMP/upgrade.txt" \
    'the Slackware x86 kernel-headers candidate should be extracted'
assert_file_contains 'openssl-3.5.6-x86_64-2.txz' "$TEST_TMP/upgrade.txt" \
    'the critical OpenSSL candidate should be extracted'

cat "$TEST_TMP/install.txt" "$TEST_TMP/upgrade.txt" | LC_ALL=C sort -u > "$TEST_TMP/all.txt"
classify_candidates "$TEST_TMP/all.txt" "$TEST_TMP/names.txt" \
    "$TEST_TMP/kernel.txt" "$TEST_TMP/critical.txt"
assert_equal_value 0 "$?" 'candidate filenames should be classified'
assert_equal_value 6 "$(wc -l < "$TEST_TMP/names.txt")" \
    'six distinct package names should be classified'
assert_equal_value 2 "$(wc -l < "$TEST_TMP/kernel.txt")" \
    'both generic and headers kernel candidates should be classified'
assert_equal_value 1 "$(wc -l < "$TEST_TMP/critical.txt")" \
    'one critical candidate should be classified'
assert_file_contains 'kernel-generic' "$TEST_TMP/names.txt" \
    'the parsed package-name list should include kernel-generic'
assert_file_contains 'kernel-headers' "$TEST_TMP/names.txt" \
    'the parsed package-name list should include kernel-headers'
assert_file_contains 'openssl' "$TEST_TMP/names.txt" \
    'the parsed package-name list should include openssl'
assert_file_not_contains 'pipewire-1.6.8' "$TEST_TMP/names.txt" \
    'package names should not retain versions'

printf 'invalid-name.txz\n' > "$TEST_TMP/invalid.txt"
assert_failure 'invalid package filenames should fail closed' \
    classify_candidates "$TEST_TMP/invalid.txt" "$TEST_TMP/invalid-names.txt" \
        "$TEST_TMP/invalid-kernel.txt" "$TEST_TMP/invalid-critical.txt"

OUTPUT_DIR="$TEST_TMP/portable-evidence"
mkdir -p "$OUTPUT_DIR"
printf 'portable evidence fixture\n' > "$OUTPUT_DIR/payload.txt"
PORTABLE_ARCHIVE=$(create_evidence_archive)
assert_equal_value 0 "$?" 'the evidence archive should be created with a portable sidecar'
assert_equal_value "${PORTABLE_ARCHIVE##*/}" "$(awk '{print $2}' "$PORTABLE_ARCHIVE.sha256")" \
    'the SHA-256 sidecar should contain only the archive basename'
(
    cd "$(dirname -- "$PORTABLE_ARCHIVE")" || exit 1
    sha256sum -c "${PORTABLE_ARCHIVE##*/}.sha256" >/dev/null
)
assert_equal_value 0 "$?" 'the portable SHA-256 sidecar should verify from the archive directory'

OUTPUT_DIR="$TEST_TMP/evidence"
mkdir -p "$OUTPUT_DIR"
PASS_COUNT=7
FAILURE_COUNT=0
MODE=preflight
TARGET=slackware-current
HOSTNAME_VALUE=testhost
INSTALL_NEW_CANDIDATE_COUNT=1
UPGRADE_CANDIDATE_COUNT=4
TOTAL_CANDIDATE_COUNT=5
KERNEL_CANDIDATE_COUNT=1
CRITICAL_CANDIDATE_COUNT=1
CANDIDATE_SET_SHA256=a8a608d8aac53c0d9f027622c01df4f794e94e8dd4586764b8d2503f9b94e45d
write_summary "$OUTPUT_DIR/summary.txt"
assert_file_contains 'scenario=normal-update' "$OUTPUT_DIR/summary.txt" \
    'the summary should identify the normal-update scenario'
assert_file_contains 'mode=preflight' "$OUTPUT_DIR/summary.txt" \
    'the summary should identify preflight mode'
assert_file_contains 'total_candidates=5' "$OUTPUT_DIR/summary.txt" \
    'the summary should record total candidates'
assert_file_contains 'kernel_candidates=1' "$OUTPUT_DIR/summary.txt" \
    'the summary should record kernel candidates'
assert_file_contains 'critical_candidates=1' "$OUTPUT_DIR/summary.txt" \
    'the summary should record critical candidates'
assert_file_contains 'metadata_update_exit_code=not-run' "$OUTPUT_DIR/summary.txt" \
    'the summary should expose metadata refresh status when it was not run in the fixture'
assert_file_contains 'candidate_set_sha256=a8a608d8aac53c0d9f027622c01df4f794e94e8dd4586764b8d2503f9b94e45d' "$OUTPUT_DIR/summary.txt" \
    'the summary should preserve the reviewed candidate-set digest'

python3 - "$TEST_TMP/kernel-source-only.json" "$TEST_TMP/critical-userspace.json" \
    "$TEST_TMP/invalid-required.json" "$TEST_TMP/boot-kernel.json" \
    "$TEST_TMP/invalid-critical.json" "$GENERATED_CONFIG" <<'PYTHON_EOF'
import json
import pathlib
import sys

kernel_source_path, critical_path, invalid_required_path, boot_kernel_path, invalid_critical_path, config_path = sys.argv[1:]

def result(exit_code, reboot, kernel_changes, critical_packages, boot):
    return {
        "schema_version": 0,
        "operation": "apply",
        "success": True,
        "partial": False,
        "boot_safe": True,
        "exit_code": exit_code,
        "reboot": reboot,
        "config_path": config_path,
        "errors": [],
        "modules": {
            "slackware": {
                "state": "success",
                "update_exit_code": 0,
                "install_new_exit_code": 0,
                "upgrade_all_exit_code": 0,
                "postinstall_policy": "defer",
                "postinstall_processing_enabled": False,
                "pending_new_config_files_valid": True,
                "pending_new_config_files_count": 0,
                "pending_new_config_files": [],
                "snapshot_before_valid": True,
                "snapshot_after_valid": True,
                "secondary_modules_blocked": False,
                "kernel_changes": kernel_changes,
                "critical_packages": critical_packages,
            },
            "flatpak": {"mode": "disabled"},
            "sbo": {"mode": "disabled"},
            "elf": {"mode": "disabled"},
            "cinnamon": {"mode": "disabled"},
            "boot": {"mode": "auto", **boot},
        },
    }

not_required = {
    "state": "not-required",
    "initrd_required": False,
    "initrd_state": "not-required",
    "grub_required": False,
    "grub_state": "not-required",
}
required = {
    "state": "success",
    "initrd_required": True,
    "initrd_state": "success",
    "grub_required": True,
    "grub_state": "success",
}

pathlib.Path(kernel_source_path).write_text(
    json.dumps(result(0, "none", True, [], not_required)), encoding="utf-8"
)
pathlib.Path(critical_path).write_text(
    json.dumps(result(4, "recommended", True, ["glibc"], not_required)), encoding="utf-8"
)
pathlib.Path(invalid_required_path).write_text(
    json.dumps(result(5, "required", True, [], not_required)), encoding="utf-8"
)
pathlib.Path(boot_kernel_path).write_text(
    json.dumps(result(5, "required", True, [], required)), encoding="utf-8"
)
pathlib.Path(invalid_critical_path).write_text(
    json.dumps(result(0, "none", False, ["glibc"], not_required)), encoding="utf-8"
)
PYTHON_EOF
assert_success 'non-boot kernel package changes should permit successful code zero' \
    validate_apply_json "$TEST_TMP/kernel-source-only.json" "$GENERATED_CONFIG" 0
assert_success 'critical userspace updates should permit reboot-recommended code four' \
    validate_apply_json "$TEST_TMP/critical-userspace.json" "$GENERATED_CONFIG" 4
assert_failure 'code five should require explicit boot preparation' \
    validate_apply_json "$TEST_TMP/invalid-required.json" "$GENERATED_CONFIG" 5
assert_success 'boot-kernel changes should require successful boot preparation and code five' \
    validate_apply_json "$TEST_TMP/boot-kernel.json" "$GENERATED_CONFIG" 5
assert_failure 'critical userspace changes should not permit code zero' \
    validate_apply_json "$TEST_TMP/invalid-critical.json" "$GENERATED_CONFIG" 0

python3 - "$ACCEPTED_CURRENT_PREFLIGHT" <<'PYTHON_EOF'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
expected = {
    "cmake-4.4.1-x86_64-1.txz",
    "libarchive-3.8.9-x86_64-1.txz",
    "libcec-8.1.1-x86_64-1.txz",
    "libfprint-1.94.100-x86_64-1.txz",
    "libopusenc-0.3-x86_64-2.txz",
    "libssh-0.12.2-x86_64-1.txz",
    "pipewire-1.6.8-x86_64-3.txz",
    "samba-4.24.5-x86_64-1.txz",
    "seamonkey-2.53.24-x86_64-1.txz",
    "suitesparse-7.12.3-x86_64-1.txz",
}
assert data["scenario"] == "normal-update"
assert data["mode"] == "preflight"
assert data["target"] == "slackware-current"
assert data["accepted"] is True
assert data["archive_sha256"] == "ab5601a1c4a103dae1ac603ebb7c60d96ff8b90513176d92646dc4082450c14b"
assert set(data["candidates"]["upgrade_all"]) == expected
assert data["candidates"]["install_new"] == []
assert data["candidates"]["total"] == 10
assert data["candidates"]["kernel"] == []
assert data["candidates"]["critical"] == []
assert data["candidates"]["candidate_set_sha256"] == "a8a608d8aac53c0d9f027622c01df4f794e94e8dd4586764b8d2503f9b94e45d"
assert data["package_database"]["records_before"] == 2039
assert data["package_database"]["records_after_preflight"] == 2039
assert data["package_database"]["unchanged"] is True
assert data["boot_state"]["observed_initrd_and_grub_unchanged"] is True
assert data["assertions"] == {"passes": 5, "failures": 0}
assert data["apply_authorized"] is False
PYTHON_EOF
assert_equal_value 0 "$?" 'the accepted Slackware-current preflight record should satisfy its contract'
assert_file_contains '"total": 10' "$ACCEPTED_CURRENT_PREFLIGHT" \
    'the accepted preflight record should preserve the candidate count'
assert_file_contains '"kernel": []' "$ACCEPTED_CURRENT_PREFLIGHT" \
    'the accepted preflight record should preserve the empty kernel set'
assert_file_contains '"critical": []' "$ACCEPTED_CURRENT_PREFLIGHT" \
    'the accepted preflight record should preserve the empty critical set'
assert_file_contains '"apply_authorized": false' "$ACCEPTED_CURRENT_PREFLIGHT" \
    'the accepted preflight record should state that apply was not yet authorized'
assert_file_contains '"candidate_set_sha256": "a8a608d8aac53c0d9f027622c01df4f794e94e8dd4586764b8d2503f9b94e45d"' "$ACCEPTED_CURRENT_PREFLIGHT" \
    'the accepted preflight record should preserve the exact candidate-set digest'

python3 - "$CURRENT_PARSER_DIAGNOSTIC" <<'PYTHON_EOF'
import json
import pathlib
import sys

data = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
assert data["scenario"] == "normal-update"
assert data["mode"] == "preflight"
assert data["target"] == "slackware-current"
assert data["accepted"] is False
assert data["diagnostic_only"] is True
assert data["retry_required"] is True
assert data["archive_sha256"] == "9641b78a092945d50a80b29b4caa612d79bca82aec3331bbd463f432ef1ef7db"
assert data["observed_summary"]["upgrade_all_candidates"] == 55
assert data["raw_probe_review"]["upgrade_all_package_count"] == 56
assert data["raw_probe_review"]["omitted_candidate"] == "kernel-headers-6.18.41-x86-1.txz"
assert data["raw_probe_review"]["reconstructed_total_candidates"] == 57
assert data["raw_probe_review"]["reconstructed_candidate_set_sha256"] == "d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1"
assert data["state_observation"]["package_database_unchanged"] is True
assert data["state_observation"]["initrd_and_grub_unchanged"] is True
assert data["evidence_sidecar"]["portable"] is False
assert data["apply_authorized"] is False
PYTHON_EOF
assert_equal_value 0 "$?" 'the rejected 2026-08-03 parser diagnostic should satisfy its sanitized contract'
assert_file_contains '"omitted_candidate": "kernel-headers-6.18.41-x86-1.txz"' "$CURRENT_PARSER_DIAGNOSTIC" \
    'the diagnostic should preserve the omitted x86 kernel-headers candidate'
assert_file_contains '"reconstructed_total_candidates": 57' "$CURRENT_PARSER_DIAGNOSTIC" \
    'the diagnostic should preserve the corrected total candidate count'
assert_file_contains '"apply_authorized": false' "$CURRENT_PARSER_DIAGNOSTIC" \
    'the diagnostic should deny apply authorization'

python3 - "$REVIEWED_CURRENT_APPLY" <<'PYTHON_EOF'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
assert data["scenario"] == "normal-update"
assert data["mode"] == "apply"
assert data["target"] == "slackware-current"
assert data["accepted"] is False
assert data["package_transaction_accepted"] is True
assert data["reference_revalidation_required"] is True
assert data["archive_sha256"] == "00679a69d9c40033db74b4a73525651a42d0d72b293ec536d1181e87e2ab7e66"
assert data["executed_reference_sha256"] == "69030355c0c9de65af4bedbb11ac7537e3a63d1e6ad79d6a96e806adb61662a5"
assert data["result"]["exit_code"] == 0
assert data["result"]["success"] is True
assert data["result"]["partial"] is False
assert data["result"]["slackpkg_install_new_exit_code"] == 20
assert data["result"]["slackpkg_upgrade_all_exit_code"] == 0
assert data["package_database"]["records_before"] == 2039
assert data["package_database"]["records_after"] == 2039
assert data["package_database"]["changed"] is True
assert data["package_database"]["upgraded_package_count"] == 10
assert data["postinstall_observation"]["reported_new_config_files"] == 27
assert data["postinstall_observation"]["batch_answer_supplied"] == "y"
assert data["postinstall_observation"]["hardened_policy"] == "defer"
assert data["assertions"] == {"passes": 9, "failures": 0}
PYTHON_EOF
assert_equal_value 0 "$?" 'the reviewed Slackware-current apply record should preserve the accepted transaction and revalidation gate'
assert_file_contains '"package_transaction_accepted": true' "$REVIEWED_CURRENT_APPLY" \
    'the reviewed apply record should accept the real package transaction'
assert_file_contains '"reference_revalidation_required": true' "$REVIEWED_CURRENT_APPLY" \
    'the reviewed apply record should keep the hardened reference pending'
assert_file_contains '"reported_new_config_files": 27' "$REVIEWED_CURRENT_APPLY" \
    'the reviewed apply record should preserve the observed post-install prompt count'

python3 - "$ACCEPTED_SLACKWARE15_PREFLIGHT" "$ACCEPTED_SLACKWARE15_APPLY" <<'PYTHON_EOF'
import json
import pathlib
import sys

preflight = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
apply = json.loads(pathlib.Path(sys.argv[2]).read_text(encoding="utf-8"))

assert preflight["scenario"] == "normal-update"
assert preflight["mode"] == "preflight"
assert preflight["target"] == "slackware-15.0"
assert preflight["accepted"] is True
assert preflight["archive_sha256"] == "4774070e7a9173f6486d560e54d7efce8580b76a92449e1698e7449d8557e73c"
assert preflight["candidates"]["total"] == 196
assert len(preflight["candidates"]["install_new"]) == 12
assert len(preflight["candidates"]["upgrade_all"]) == 184
assert preflight["candidates"]["kernel"] == []
assert len(preflight["candidates"]["critical"]) == 5
assert preflight["candidates"]["candidate_set_sha256"] == "baaf89bb3e61662d7bbb10223e2c26b9adc98c443eacdf8273319a6818951410"
assert preflight["package_database"]["unchanged"] is True
assert preflight["assertions"] == {"passes": 6, "failures": 0}

assert apply["scenario"] == "normal-update"
assert apply["mode"] == "apply"
assert apply["target"] == "slackware-15.0"
assert apply["accepted"] is True
assert apply["accepted_after_validator_correction"] is True
assert apply["archive_sha256"] == "c670a5077f9efb5d64470b46b537754634913c0f1deccd4fcef707c9385339ed"
assert apply["result"]["exit_code"] == 4
assert apply["result"]["success"] is True
assert apply["result"]["partial"] is False
assert apply["result"]["reboot"] == "recommended"
assert apply["result"]["boot_preparation_required"] is False
assert apply["result"]["critical_packages"] == ["glibc", "openssl", "openssl-solibs"]
assert apply["package_database"]["records_before"] == 1554
assert apply["package_database"]["records_after"] == 1566
assert apply["package_database"]["installed_new_package_count"] == 12
assert apply["package_database"]["upgraded_package_count"] == 184
assert apply["package_database"]["candidate_coverage_complete"] is True
assert apply["boot_state"]["observed_initrd_and_grub_unchanged"] is True
assert apply["postinstall_policy"]["policy"] == "defer"
assert apply["postinstall_policy"]["postinstall_processing_enabled"] is False
assert apply["postinstall_policy"]["pending_new_config_files_count"] == 45
assert len(apply["postinstall_policy"]["pending_new_config_files"]) == 45
assert apply["postinstall_policy"]["real_system_policy_revalidated"] is True
assert apply["assertions"]["observed"] == {"passes": 8, "failures": 1}
assert apply["assertions"]["reviewed_after_validator_correction"] == {"passes": 9, "failures": 0}
PYTHON_EOF
assert_equal_value 0 "$?" 'the accepted Slackware 15.0 preflight and apply records should satisfy their reviewed contracts'
assert_file_contains '"accepted_after_validator_correction": true' "$ACCEPTED_SLACKWARE15_APPLY" \
    'the Slackware 15.0 apply record should preserve the validator correction'
assert_file_contains '"pending_new_config_files_count": 45' "$ACCEPTED_SLACKWARE15_APPLY" \
    'the Slackware 15.0 apply record should preserve the deferred .new count'
assert_file_contains '"upgraded_package_count": 184' "$ACCEPTED_SLACKWARE15_APPLY" \
    'the Slackware 15.0 apply record should preserve the upgraded package count'
assert_file_contains '"installed_new_package_count": 12' "$ACCEPTED_SLACKWARE15_APPLY" \
    'the Slackware 15.0 apply record should preserve the install-new package count'

printf 'Normal-update acceptance harness: %d checks, %d failures\n' \
    "$TEST_COUNT" "$TEST_FAILURE_COUNT"
[ "$TEST_FAILURE_COUNT" -eq 0 ]
