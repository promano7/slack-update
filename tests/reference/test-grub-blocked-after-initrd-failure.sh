#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPOSITORY_ROOT=$(cd "$TEST_DIR/../.." && pwd)
REFERENCE_SCRIPT="$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"

# Source the reference implementation without invoking main().
# shellcheck source=../../tools/reference/slack-update-reference.sh
source "$REFERENCE_SCRIPT"

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

assert_equal() {
    local expected=$1
    local actual=$2
    local message=$3

    if [ "$actual" = "$expected" ]; then
        pass
    else
        fail "$message (expected '$expected', got '$actual')"
    fi
}

assert_status() {
    local expected=$1
    local message=$2
    shift 2
    local status

    "$@" >/dev/null 2>&1
    status=$?
    assert_equal "$expected" "$status" "$message"
}

assert_file_exists() {
    local path=$1
    local message=$2

    if [ -e "$path" ]; then
        pass
    else
        fail "$message"
    fi
}

assert_file_missing() {
    local path=$1
    local message=$2

    if [ ! -e "$path" ]; then
        pass
    else
        fail "$message"
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

assert_jq_equal() {
    local expected=$1
    local filter=$2
    local path=$3
    local message=$4
    local actual

    if ! actual=$(jq -r "$filter" "$path" 2>/dev/null); then
        fail "$message (jq failed)"
        return
    fi
    assert_equal "$expected" "$actual" "$message"
}

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

GRUB_DIRECTORY="$TEST_TMP/grub"
GRUB_CONFIG="$GRUB_DIRECTORY/grub.cfg"
GRUB_CALLS="$TEST_TMP/grub-calls.txt"
mkdir -p "$GRUB_DIRECTORY"

GRUB_MOCK_STATUS=0
grub-mkconfig() {
    local output=

    printf '%s\n' "$@" >> "$GRUB_CALLS"
    while [ "$#" -gt 0 ]; do
        if [ "$1" = -o ] && [ "$#" -gt 1 ]; then
            output=$2
            break
        fi
        shift
    done
    if [ "$GRUB_MOCK_STATUS" -eq 0 ] && [ -n "$output" ]; then
        printf 'generated grub configuration\n' > "$output"
    fi
    return "$GRUB_MOCK_STATUS"
}

grub-script-check() {
    [ "$#" -eq 1 ] && [ -s "$1" ]
}

reset_guard_state() {
    BOOT_MODE=auto
    BOOT_MODULE_REASON=
    INITRD_REQUIRED=1
    INITRD_UPDATE=1
    INITRD_OK=0
    INITRD_VALIDATION_ERROR=
    GRUB_REQUIRED=1
    GRUB_UPDATE=1
    GRUB_OK=0
    GRUB_COMMAND_ATTEMPTED=0
    GRUB_BLOCKED_BY_INITRD=0
    GRUB_BLOCK_REASON=
    GRUB_MOCK_STATUS=0
    rm -f "$GRUB_CALLS" "$GRUB_CONFIG"
}

# The direct GRUB function must fail closed after initrd validation failure.
reset_guard_state
INITRD_VALIDATION_ERROR='configured KERNEL_VERSION is stale'
assert_status 2 'GRUB should return the blocked status after initrd validation failure' \
    update_grub_configuration
assert_equal 1 "$GRUB_BLOCKED_BY_INITRD" \
    'initrd validation failure should set the GRUB block guard'
assert_equal 0 "$GRUB_COMMAND_ATTEMPTED" \
    'blocked GRUB processing must not report a command attempt'
assert_equal 0 "$GRUB_OK" \
    'blocked GRUB processing must not report success'
assert_equal 'required initrd preparation failed validation: configured KERNEL_VERSION is stale' \
    "$GRUB_BLOCK_REASON" \
    'validation failure should expose a stable blocking reason'
assert_file_missing "$GRUB_CALLS" \
    'grub-mkconfig must not run after initrd validation failure'

# A failed mkinitrd command or missing output must block GRUB even without a validation diagnostic.
reset_guard_state
assert_status 2 'GRUB should be blocked after unsuccessful initrd regeneration' \
    update_grub_configuration
assert_equal 'required initrd regeneration did not complete successfully' \
    "$GRUB_BLOCK_REASON" \
    'regeneration failure should expose a stable blocking reason'
assert_file_missing "$GRUB_CALLS" \
    'grub-mkconfig must not run after initrd regeneration failure'

# Auto mode must not update GRUB when required initrd preparation was unavailable.
reset_guard_state
INITRD_UPDATE=0
BOOT_MODULE_REASON='initrd preparation requirements are missing'
assert_status 2 'required but unavailable initrd preparation should block GRUB' \
    update_grub_configuration
assert_equal 'required initrd preparation was not applicable: mode=auto, initrd preparation requirements are missing' \
    "$GRUB_BLOCK_REASON" \
    'unavailable initrd preparation should identify the module state'
assert_file_missing "$GRUB_CALLS" \
    'grub-mkconfig must not run when required initrd preparation is unavailable'

# A successful required initrd permits GRUB generation.
reset_guard_state
INITRD_OK=1
assert_status 0 'successful initrd preparation should permit GRUB generation' \
    update_grub_configuration
assert_equal 0 "$GRUB_BLOCKED_BY_INITRD" \
    'successful initrd preparation should clear the GRUB block guard'
assert_equal 1 "$GRUB_COMMAND_ATTEMPTED" \
    'permitted GRUB processing should report the command attempt'
assert_equal 1 "$GRUB_OK" \
    'successful grub-mkconfig should set GRUB_OK'
assert_file_contains '-o' "$GRUB_CALLS" \
    'GRUB should receive the output selector after initrd success'
assert_file_contains "$GRUB_DIRECTORY/.grub.cfg.slack-update." "$GRUB_CALLS" \
    'GRUB should receive a temporary output path beside the active configuration'
assert_file_not_contains "$GRUB_CONFIG" "$GRUB_CALLS" \
    'GRUB generation must not target the active configuration directly'
assert_file_exists "$GRUB_CONFIG" \
    'permitted GRUB processing should generate the configured file'

# GRUB-only work remains valid when no initrd action was required.
reset_guard_state
INITRD_REQUIRED=0
INITRD_UPDATE=0
assert_status 0 'GRUB-only processing should not require an unrelated initrd action' \
    update_grub_configuration
assert_equal 0 "$GRUB_BLOCKED_BY_INITRD" \
    'GRUB-only processing should not be marked as blocked by initrd'
assert_equal 1 "$GRUB_COMMAND_ATTEMPTED" \
    'GRUB-only processing should invoke grub-mkconfig'
assert_equal 1 "$GRUB_OK" \
    'GRUB-only processing should report success'

# A real grub-mkconfig failure remains distinct from an initrd safety block.
reset_guard_state
INITRD_OK=1
GRUB_MOCK_STATUS=7
assert_status 7 'grub-mkconfig failures should preserve their command status' \
    update_grub_configuration
assert_equal 0 "$GRUB_BLOCKED_BY_INITRD" \
    'a direct GRUB failure must not be mislabeled as an initrd block'
assert_equal 1 "$GRUB_COMMAND_ATTEMPTED" \
    'a failed GRUB command should still be reported as attempted'
assert_equal 0 "$GRUB_OK" \
    'a failed GRUB command must not report success'

# The boot coordinator must not emit action_started or call GRUB after initrd failure.
EVENT_LOG="$TEST_TMP/events.txt"
: > "$EVENT_LOG"
emit_module_started_event() {
    printf 'module_started:%s\n' "$1" >> "$EVENT_LOG"
}
emit_module_completed_event() {
    printf 'module_completed:%s:%s:%s\n' "$1" "$2" "${4-}" >> "$EVENT_LOG"
}
emit_action_started_event() {
    printf 'action_started:%s:%s\n' "$1" "$2" >> "$EVENT_LOG"
}
emit_action_completed_event() {
    printf 'action_completed:%s:%s:%s:%s\n' "$1" "$2" "$3" "${5-}" >> "$EVENT_LOG"
}
regenerate_initrd() {
    INITRD_OK=0
    INITRD_VALIDATION_ERROR='installed kernel modules directory is missing'
    return 1
}

reset_guard_state
BOOT_MODULE_RUN=1
BOOT_MODULE_STATE=available
if run_boot_preparation_module >/dev/null 2>&1; then
    fail 'the boot module should fail when initrd preparation fails'
else
    pass
fi
assert_file_contains 'action_completed:boot:regenerate_initrd:failed:1' "$EVENT_LOG" \
    'the failed initrd action should be reported'
assert_file_contains 'action_completed:boot:update_grub:blocked:1' "$EVENT_LOG" \
    'the GRUB action should complete as blocked'
assert_file_not_contains 'action_started:boot:update_grub' "$EVENT_LOG" \
    'the coordinator must not announce GRUB start after initrd failure'
assert_file_contains 'module_completed:boot:failed:1' "$EVENT_LOG" \
    'the boot module should complete as failed'
assert_equal 1 "$GRUB_BLOCKED_BY_INITRD" \
    'the coordinator should preserve the initrd safety block'
assert_equal 0 "$GRUB_COMMAND_ATTEMPTED" \
    'the coordinator must not attempt the GRUB command after initrd failure'
assert_file_missing "$GRUB_CALLS" \
    'the coordinator must not invoke grub-mkconfig after initrd failure'

# The same coordinator must start and complete GRUB after initrd succeeds.
: > "$EVENT_LOG"
regenerate_initrd() {
    INITRD_OK=1
    INITRD_VALIDATION_ERROR=
    return 0
}
reset_guard_state
BOOT_MODULE_RUN=1
BOOT_MODULE_STATE=available
if run_boot_preparation_module >/dev/null 2>&1; then
    pass
else
    fail 'the boot module should succeed when initrd and GRUB both succeed'
fi
assert_file_contains 'action_started:boot:update_grub' "$EVENT_LOG" \
    'the coordinator should announce GRUB only after initrd success'
assert_file_contains 'action_completed:boot:update_grub:success:0' "$EVENT_LOG" \
    'the permitted GRUB action should complete successfully'
assert_file_contains 'module_completed:boot:success:0' "$EVENT_LOG" \
    'the boot module should complete successfully'
assert_equal 1 "$GRUB_COMMAND_ATTEMPTED" \
    'successful coordinated processing should attempt GRUB'
assert_equal 1 "$GRUB_OK" \
    'successful coordinated processing should report GRUB success'

# Provisional JSON must distinguish blocked GRUB from a failed command.
initialize_runtime_state
PACKAGE_SNAPSHOT_BEFORE_VALID=1
PACKAGE_SNAPSHOT_AFTER_VALID=1
SLACKPKG_UPDATE_STATUS=0
SLACKPKG_INSTALL_NEW_STATUS=0
SLACKPKG_UPGRADE_ALL_STATUS=0
FLATPAK_MODE=auto
FLATPAK_MODULE_RUN=0
FLATPAK_MODULE_STATE=unavailable
SBO_MODE=auto
SBO_MODULE_RUN=0
SBO_MODULE_STATE=unavailable
ELF_MODE=auto
ELF_MODULE_RUN=0
ELF_MODULE_STATE=unavailable
CINNAMON_MODE=auto
CINNAMON_MODULE_RUN=0
CINNAMON_MODULE_STATE=unavailable
BOOT_MODE=auto
BOOT_MODULE_RUN=1
BOOT_MODULE_STATE=available
INITRD_REQUIRED=1
INITRD_UPDATE=1
INITRD_OK=0
INITRD_VALIDATION_STATUS=1
INITRD_VALIDATION_ERROR='configured KERNEL_VERSION is stale'
GRUB_REQUIRED=1
GRUB_UPDATE=1
GRUB_OK=0
GRUB_COMMAND_ATTEMPTED=0
GRUB_BLOCKED_BY_INITRD=1
GRUB_BLOCK_REASON='required initrd preparation failed validation: configured KERNEL_VERSION is stale'
BROKEN="$TEST_TMP/json-broken"
SBO_OPTION_RECORDS="$TEST_TMP/json-options"
: > "$BROKEN"
: > "$SBO_OPTION_RECORDS"
JSON_OUTPUT_FILE="$TEST_TMP/modules.json"
{
    printf '{"modules":{\n'
    print_apply_json_modules
    printf '}}\n'
} > "$JSON_OUTPUT_FILE"
if jq -e . "$JSON_OUTPUT_FILE" >/dev/null; then
    pass
else
    fail 'provisional boot JSON should be valid'
fi
assert_jq_equal failed '.modules.boot.state' "$JSON_OUTPUT_FILE" \
    'blocked GRUB after initrd failure should make boot state failed'
assert_jq_equal failed '.modules.boot.initrd_state' "$JSON_OUTPUT_FILE" \
    'JSON should report the initrd failure'
assert_jq_equal blocked '.modules.boot.grub_state' "$JSON_OUTPUT_FILE" \
    'JSON should report GRUB as blocked rather than executed and failed'
assert_jq_equal false '.modules.boot.grub_command_attempted' "$JSON_OUTPUT_FILE" \
    'JSON should prove grub-mkconfig was not attempted'
assert_jq_equal true '.modules.boot.grub_blocked_by_initrd' "$JSON_OUTPUT_FILE" \
    'JSON should expose the initrd prerequisite guard'
assert_jq_equal 'required initrd preparation failed validation: configured KERNEL_VERSION is stale' \
    '.modules.boot.grub_block_reason' "$JSON_OUTPUT_FILE" \
    'JSON should expose the stable GRUB block reason'

# Result diagnostics must not claim that an unexecuted GRUB command failed.
OPERATION=apply
FLATPAK_STATUS=-1
SBOPKG_SYNC_STATUS=-1
SQG_SYNC_STATUS=-1
SBO_TARGET_SELECTION_STATUS=-1
SBO_BUILD_STATUS=-1
CINNAMON_TRIGGER=0
CRITICAL_UPDATED=()
prepare_json_messages
RESULT_ERRORS_FILE="$TEST_TMP/result-errors.txt"
printf '%s\n' "${RESULT_ERRORS[@]}" > "$RESULT_ERRORS_FILE"
assert_file_contains 'GRUB configuration generation was blocked to protect boot safety:' \
    "$RESULT_ERRORS_FILE" \
    'result errors should identify the deliberate GRUB safety block'
assert_file_not_contains 'GRUB configuration generation was required but did not complete successfully' \
    "$RESULT_ERRORS_FILE" \
    'result errors must not misreport a blocked command as an attempted failure'

# Source audit: both the coordinator and the command function retain independent guards.
GUARD_SOURCE="$TEST_TMP/guard-source.txt"
{
    declare -f grub_initrd_prerequisite_is_satisfied
    declare -f update_grub_configuration
    declare -f run_boot_preparation_module
} > "$GUARD_SOURCE"
assert_file_contains 'if ! grub_initrd_prerequisite_is_satisfied' "$GUARD_SOURCE" \
    'the direct GRUB function should retain its defensive prerequisite check'
assert_file_contains 'elif ! grub_initrd_prerequisite_is_satisfied' "$REFERENCE_SCRIPT" \
    'the boot coordinator should block GRUB before action start'
assert_file_contains 'GRUB_COMMAND_ATTEMPTED=1' "$GUARD_SOURCE" \
    'command-attempt state should be set only at the grub-mkconfig boundary'
assert_file_contains 'run_boot_preparation_module || true' "$REFERENCE_SCRIPT" \
    'the apply workflow should use the guarded boot coordinator'

printf 'GRUB-after-initrd safety tests: %d checks, %d failures\n' \
    "$TEST_COUNT" "$FAILURE_COUNT"

[ "$FAILURE_COUNT" -eq 0 ]
