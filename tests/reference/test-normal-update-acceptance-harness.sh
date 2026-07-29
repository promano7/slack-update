#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
ACCEPTANCE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-normal-update.sh"
DEFAULT_CONFIG="$REPOSITORY_ROOT/data/config/slack-update.conf"
INSTALL_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/install-new-probe.log"
UPGRADE_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/normal-update/upgrade-all-probe.log"

# Source helpers without executing the real-system scenario.
# shellcheck source=../acceptance/reference/test-normal-update.sh
source "$ACCEPTANCE_SCRIPT"

TEST_COUNT=0
FAILURE_COUNT=0

pass() {
    TEST_COUNT=$((TEST_COUNT + 1))
}

fail() {
    local message=$1

    TEST_COUNT=$((TEST_COUNT + 1))
    FAILURE_COUNT=$((FAILURE_COUNT + 1))
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
assert_file_contains 'slackpkg -dialog=off -batch=on -default_answer=n' "$ACCEPTANCE_SCRIPT" \
    'candidate probing should use a non-interactive negative answer'
assert_file_contains 'candidate probing did not modify the installed package database' "$ACCEPTANCE_SCRIPT" \
    'preflight should prove that package state is unchanged'
assert_file_contains 'candidate probing did not modify initrd or GRUB state' "$ACCEPTANCE_SCRIPT" \
    'preflight should prove that boot state is unchanged'
assert_file_contains 'run_reference_apply' "$ACCEPTANCE_SCRIPT" \
    'the scenario should exercise the real reference apply workflow'
assert_file_contains 'mode=disabled' "$ACCEPTANCE_SCRIPT" \
    'non-Slackware optional modules should be isolated'
assert_file_contains 'boot mode is not auto' "$ACCEPTANCE_SCRIPT" \
    'apply validation should require automatic boot preparation'
assert_file_contains 'Copy evidence command:' "$ACCEPTANCE_SCRIPT" \
    'the scenario should print a one-line evidence copy command'
assert_file_contains 'owner=${SUDO_USER:-promano}' "$ACCEPTANCE_SCRIPT" \
    'the evidence copy fallback should default to the promano account'
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
ALLOW_KERNEL_UPDATE=0
assert_success 'preflight arguments should parse without apply confirmation' \
    parse_arguments --target slackware-current --preflight
assert_equal_value preflight "$MODE" 'preflight should select preflight mode'

TARGET=
MODE=
OUTPUT_DIR=
REFERENCE_SCRIPT=$DEFAULT_REFERENCE_SCRIPT
CONFIG_TEMPLATE=$DEFAULT_CONFIG
CONFIRM_HOSTNAME=
ALLOW_KERNEL_UPDATE=0
assert_failure 'apply should fail without hostname confirmation' \
    parse_arguments --target slackware-current --execute-apply

TARGET=
MODE=
OUTPUT_DIR=
REFERENCE_SCRIPT=$DEFAULT_REFERENCE_SCRIPT
CONFIG_TEMPLATE=$DEFAULT_CONFIG
CONFIRM_HOSTNAME=
ALLOW_KERNEL_UPDATE=0
assert_success 'apply should parse with hostname and kernel confirmation' \
    parse_arguments --target slackware-current --execute-apply \
        --confirm-hostname testhost --allow-kernel-update
assert_equal_value apply "$MODE" 'execute-apply should select apply mode'
assert_equal_value testhost "$CONFIRM_HOSTNAME" 'the hostname confirmation should be preserved'
assert_equal_value 1 "$ALLOW_KERNEL_UPDATE" 'the kernel confirmation should be preserved'

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

extract_slackpkg_candidates "$INSTALL_FIXTURE" "$TEST_TMP/install.txt"
assert_equal_value 0 "$?" 'install-new candidates should be parsed'
assert_equal_value 1 "$(wc -l < "$TEST_TMP/install.txt")" \
    'one install-new candidate should be extracted'
assert_file_contains 'new-runtime-1.2.3-x86_64-1.txz' "$TEST_TMP/install.txt" \
    'the install-new filename should be preserved'

extract_slackpkg_candidates "$UPGRADE_FIXTURE" "$TEST_TMP/upgrade.txt"
assert_equal_value 0 "$?" 'upgrade-all candidates should be parsed'
assert_equal_value 4 "$(wc -l < "$TEST_TMP/upgrade.txt")" \
    'four upgrade candidates should be extracted'
assert_file_contains 'kernel-generic-6.18.40-x86_64-1.txz' "$TEST_TMP/upgrade.txt" \
    'the kernel candidate should be extracted'
assert_file_contains 'openssl-3.5.6-x86_64-2.txz' "$TEST_TMP/upgrade.txt" \
    'the critical OpenSSL candidate should be extracted'

cat "$TEST_TMP/install.txt" "$TEST_TMP/upgrade.txt" | LC_ALL=C sort -u > "$TEST_TMP/all.txt"
classify_candidates "$TEST_TMP/all.txt" "$TEST_TMP/names.txt" \
    "$TEST_TMP/kernel.txt" "$TEST_TMP/critical.txt"
assert_equal_value 0 "$?" 'candidate filenames should be classified'
assert_equal_value 5 "$(wc -l < "$TEST_TMP/names.txt")" \
    'five distinct package names should be classified'
assert_equal_value 1 "$(wc -l < "$TEST_TMP/kernel.txt")" \
    'one kernel candidate should be classified'
assert_equal_value 1 "$(wc -l < "$TEST_TMP/critical.txt")" \
    'one critical candidate should be classified'
assert_file_contains 'kernel-generic' "$TEST_TMP/names.txt" \
    'the parsed package-name list should include kernel-generic'
assert_file_contains 'openssl' "$TEST_TMP/names.txt" \
    'the parsed package-name list should include openssl'
assert_file_not_contains 'pipewire-1.6.8' "$TEST_TMP/names.txt" \
    'package names should not retain versions'

printf 'invalid-name.txz\n' > "$TEST_TMP/invalid.txt"
assert_failure 'invalid package filenames should fail closed' \
    classify_candidates "$TEST_TMP/invalid.txt" "$TEST_TMP/invalid-names.txt" \
        "$TEST_TMP/invalid-kernel.txt" "$TEST_TMP/invalid-critical.txt"

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

printf 'Normal-update acceptance harness: %d checks, %d failures\n' \
    "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
