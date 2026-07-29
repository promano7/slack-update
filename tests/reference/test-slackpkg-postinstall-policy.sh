#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
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

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT
COMMAND_LOG="$TEST_TMP/slackpkg.commands"
PENDING_NEW_CONFIG_FILES="$TEST_TMP/pending-new-config-files.txt"

initialize_runtime_state
OPERATION=apply
FLATPAK_MODE=disabled
SBO_MODE=disabled
ELF_MODE=disabled
CINNAMON_MODE=disabled
BOOT_MODE=disabled
SLACKWARE_INSTALL_NEW=true
SLACKWARE_UPGRADE_ALL=true
PENDING_NEW_CONFIG_FILES="$TEST_TMP/pending-new-config-files.txt"
BROKEN="$TEST_TMP/broken.txt"
QUEUE_CORE="$TEST_TMP/queue-core.sqf"
QUEUE_EXTRA="$TEST_TMP/queue-extra.sqf"
SBO_OPTION_RECORDS="$TEST_TMP/sbo-options.normalized"
: > "$BROKEN"
: > "$QUEUE_CORE"
: > "$QUEUE_EXTRA"
: > "$SBO_OPTION_RECORDS"

slackpkg() {
    local first=1
    local argument

    for argument in "$@"; do
        if [ "$first" -eq 0 ]; then
            printf ' ' >> "$COMMAND_LOG"
        fi
        printf '%s' "$argument" >> "$COMMAND_LOG"
        first=0
    done
    printf '\n' >> "$COMMAND_LOG"

    case "${*: -1}" in
        update|install-new|upgrade-all) return 0 ;;
    esac
    return 1
}

find() {
    printf '%s\n' \
        /etc/rc.d/rc.M.new \
        /etc/ssh/sshd_config.new
}

update_slackware_system > "$TEST_TMP/update.log" 2>&1
assert_equal 0 "$SLACKPKG_UPDATE_STATUS" \
    'metadata refresh should preserve status zero'
assert_equal 0 "$SLACKPKG_INSTALL_NEW_STATUS" \
    'install-new should preserve status zero'
assert_equal 0 "$SLACKPKG_UPGRADE_ALL_STATUS" \
    'upgrade-all should preserve status zero'
assert_file_contains '-batch=on -default_answer=y update' "$COMMAND_LOG" \
    'metadata refresh should keep the affirmative batch answer'
assert_file_contains '-batch=on -default_answer=y -postinst=off install-new' "$COMMAND_LOG" \
    'install-new should disable slackpkg post-install processing'
assert_file_contains '-batch=on -default_answer=y -postinst=off upgrade-all' "$COMMAND_LOG" \
    'upgrade-all should disable slackpkg post-install processing'
assert_file_not_contains '-postinst=off update' "$COMMAND_LOG" \
    'metadata refresh should not receive the post-install option'
assert_equal 1 "$PENDING_NEW_CONFIG_FILES_VALID" \
    'the pending .new file scan should be valid'
assert_equal 2 "$PENDING_NEW_CONFIG_FILES_COUNT" \
    'the pending .new file scan should count every file'
assert_file_contains '/etc/rc.d/rc.M.new' "$PENDING_NEW_CONFIG_FILES" \
    'the pending list should preserve the first configuration path'
assert_file_contains '/etc/ssh/sshd_config.new' "$PENDING_NEW_CONFIG_FILES" \
    'the pending list should preserve the second configuration path'
assert_file_contains '2 pending .new configuration file(s) require manual review' "$TEST_TMP/update.log" \
    'the human log should warn about deferred configuration review'

PACKAGE_SNAPSHOT_BEFORE_VALID=1
PACKAGE_SNAPSHOT_AFTER_VALID=1
PACKAGE_SNAPSHOT_BEFORE_COUNT=10
PACKAGE_SNAPSHOT_AFTER_COUNT=10
FLATPAK_MODULE_STATE=disabled
SBO_MODULE_STATE=disabled
ELF_MODULE_STATE=disabled
CINNAMON_MODULE_STATE=disabled
BOOT_MODULE_STATE=disabled
JSON_OUTPUT="$TEST_TMP/modules.json"
print_apply_json_modules > "$JSON_OUTPUT"
assert_file_contains '"postinstall_policy": "defer"' "$JSON_OUTPUT" \
    'JSON should expose the explicit deferred configuration policy'
assert_file_contains '"postinstall_processing_enabled": false' "$JSON_OUTPUT" \
    'JSON should expose disabled interactive post-install processing'
assert_file_contains '"pending_new_config_files_valid": true' "$JSON_OUTPUT" \
    'JSON should expose a valid pending-file scan'
assert_file_contains '"pending_new_config_files_count": 2' "$JSON_OUTPUT" \
    'JSON should expose the pending-file count'
assert_file_contains '"/etc/rc.d/rc.M.new"' "$JSON_OUTPUT" \
    'JSON should expose pending configuration paths'

prepare_json_messages
assert_equal 0 "${#RESULT_ERRORS[@]}" \
    'pending .new files should not turn a successful update into an error'
assert_equal 1 "${#RESULT_WARNINGS[@]}" \
    'pending .new files should produce one structured warning'
assert_equal '2 pending Slackware .new configuration file(s) require manual review' \
    "${RESULT_WARNINGS[0]}" \
    'the structured warning should describe the deferred review'

find() {
    return 1
}
PENDING_NEW_CONFIG_FILES="$TEST_TMP/failed-pending-new-config-files.txt"
if capture_pending_new_config_files; then
    fail 'a failed /etc enumeration should not be reported as valid'
else
    pass
fi
assert_equal 0 "$PENDING_NEW_CONFIG_FILES_VALID" \
    'a failed scan should clear the validity flag'
assert_equal 'cannot enumerate pending .new configuration files under /etc' \
    "$PENDING_NEW_CONFIG_FILES_ERROR" \
    'a failed scan should expose a stable diagnostic'

printf 'Slackpkg post-install policy tests: %d checks, %d failures\n' \
    "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
