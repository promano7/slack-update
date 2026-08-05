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

assert_file_missing() {
    local path=$1
    local message=$2

    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
        pass
    else
        fail "$message"
    fi
}

assert_no_transaction_files() {
    local directory=$1
    local message=$2
    local found

    found=$(find "$directory" -maxdepth 1 -name '.grub.cfg.slack-update.*' -print -quit)
    if [ -z "$found" ]; then
        pass
    else
        fail "$message ($found)"
    fi
}

assert_mode() {
    local expected=$1
    local path=$2
    local message=$3
    local actual

    actual=$(stat -c '%a' -- "$path")
    assert_equal "$expected" "$actual" "$message"
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
GRUB_GENERATOR_LOG="$TEST_TMP/grub-generator.log"
GRUB_VALIDATOR_LOG="$TEST_TMP/grub-validator.log"
GRUB_MOVE_LOG="$TEST_TMP/grub-move.log"
mkdir -p "$GRUB_DIRECTORY"

GRUB_MOCK_STATUS=0
GRUB_CHECK_STATUS=0
GRUB_MOVE_STATUS=0
GRUB_GENERATED_CONTENT='menuentry "Slackware" { linux /vmlinuz }'
GRUB_MUTATE_ACTIVE_DURING_CHECK=0

grub-mkconfig() {
    local output=

    printf '%s\n' "$@" >> "$GRUB_GENERATOR_LOG"
    while [ "$#" -gt 0 ]; do
        if [ "$1" = -o ] && [ "$#" -gt 1 ]; then
            output=$2
            break
        fi
        shift
    done

    if [ "$GRUB_MOCK_STATUS" -eq 0 ] && [ -n "$output" ]; then
        printf '%s' "$GRUB_GENERATED_CONTENT" > "$output"
    fi
    return "$GRUB_MOCK_STATUS"
}

grub-script-check() {
    printf '%s\n' "$@" >> "$GRUB_VALIDATOR_LOG"
    if [ "$GRUB_MUTATE_ACTIVE_DURING_CHECK" -eq 1 ]; then
        printf 'external concurrent update\n' > "$GRUB_CONFIG"
    fi
    return "$GRUB_CHECK_STATUS"
}

mv() {
    printf '%s\n' "$@" >> "$GRUB_MOVE_LOG"
    if [ "$GRUB_MOVE_STATUS" -ne 0 ]; then
        return "$GRUB_MOVE_STATUS"
    fi
    command mv "$@"
}

reset_transaction() {
    rm -rf "$GRUB_DIRECTORY"
    mkdir -p "$GRUB_DIRECTORY"
    printf 'original grub configuration\n' > "$GRUB_CONFIG"
    chmod 0640 "$GRUB_CONFIG"
    rm -f "$GRUB_GENERATOR_LOG" "$GRUB_VALIDATOR_LOG" "$GRUB_MOVE_LOG"

    BOOT_MODE=auto
    BOOT_MODULE_REASON=
    INITRD_REQUIRED=1
    INITRD_UPDATE=1
    INITRD_OK=1
    INITRD_VALIDATION_ERROR=
    GRUB_REQUIRED=1
    GRUB_UPDATE=1
    GRUB_OK=0
    GRUB_COMMAND_ATTEMPTED=0
    GRUB_BLOCKED_BY_INITRD=0
    GRUB_BLOCK_REASON=
    GRUB_MOCK_STATUS=0
    GRUB_CHECK_STATUS=0
    GRUB_MOVE_STATUS=0
    GRUB_GENERATED_CONTENT='menuentry "Slackware" { linux /vmlinuz }'
    GRUB_MUTATE_ACTIVE_DURING_CHECK=0
}

# Successful generation must target a temporary file, validate it, and replace atomically.
reset_transaction
assert_status 0 'valid GRUB output should complete the transaction' update_grub_configuration
assert_equal 1 "$GRUB_OK" 'successful transaction should set GRUB_OK'
assert_equal 1 "$GRUB_COMMAND_ATTEMPTED" 'successful transaction should invoke the generator'
assert_equal 0 "$GRUB_GENERATION_STATUS" 'successful generation should report status zero'
assert_equal 0 "$GRUB_VALIDATION_STATUS" 'successful validation should report status zero'
assert_equal 0 "$GRUB_INSTALL_STATUS" 'successful installation should report status zero'
assert_equal 1 "$GRUB_REPLACEMENT_ATTEMPTED" 'successful transaction should attempt replacement'
assert_equal 1 "$GRUB_CONFIG_REPLACED" 'successful transaction should report active replacement'
assert_file_contains 'menuentry "Slackware"' "$GRUB_CONFIG" \
    'the validated configuration should become active'
assert_file_not_contains 'original grub configuration' "$GRUB_CONFIG" \
    'the original content should be replaced only after validation'
assert_file_contains "$GRUB_DIRECTORY/.grub.cfg.slack-update." "$GRUB_GENERATOR_LOG" \
    'grub-mkconfig should receive a temporary path in the active directory'
assert_file_not_contains "$GRUB_CONFIG" "$GRUB_GENERATOR_LOG" \
    'grub-mkconfig must never write directly to the active path'
assert_file_contains "$GRUB_DIRECTORY/.grub.cfg.slack-update." "$GRUB_VALIDATOR_LOG" \
    'grub-script-check should validate the generated temporary path'
assert_file_contains "$GRUB_CONFIG" "$GRUB_MOVE_LOG" \
    'the final move should target the active configuration'
assert_mode 640 "$GRUB_CONFIG" \
    'atomic replacement should preserve the active configuration mode'
assert_no_transaction_files "$GRUB_DIRECTORY" \
    'successful replacement should leave no temporary transaction files'

# Generator failure must leave the active file byte-for-byte unchanged.
reset_transaction
original_fingerprint=$(cksum "$GRUB_CONFIG")
GRUB_MOCK_STATUS=9
assert_status 9 'generator failure should preserve the external status' update_grub_configuration
assert_equal "$original_fingerprint" "$(cksum "$GRUB_CONFIG")" \
    'generator failure should preserve the active configuration'
assert_equal 9 "$GRUB_GENERATION_STATUS" 'generator failure should be recorded'
assert_equal -1 "$GRUB_VALIDATION_STATUS" 'validation should not run after generator failure'
assert_equal 0 "$GRUB_REPLACEMENT_ATTEMPTED" 'generator failure must not attempt replacement'
assert_equal 0 "$GRUB_CONFIG_REPLACED" 'generator failure must not report replacement'
assert_file_missing "$GRUB_VALIDATOR_LOG" \
    'validator should not run after generator failure'
assert_no_transaction_files "$GRUB_DIRECTORY" \
    'generator failure should remove its temporary output'

# Empty generated output must fail before the validator or replacement.
reset_transaction
original_fingerprint=$(cksum "$GRUB_CONFIG")
GRUB_GENERATED_CONTENT=
assert_status 1 'empty generated output should fail closed' update_grub_configuration
assert_equal "$original_fingerprint" "$(cksum "$GRUB_CONFIG")" \
    'empty output should preserve the active configuration'
assert_equal 1 "$GRUB_VALIDATION_STATUS" 'empty output should fail validation'
assert_equal 'generated GRUB configuration is empty' "$GRUB_VALIDATION_ERROR" \
    'empty output should expose a stable diagnostic'
assert_file_missing "$GRUB_VALIDATOR_LOG" \
    'syntax validator should not receive an empty output'
assert_equal 0 "$GRUB_REPLACEMENT_ATTEMPTED" \
    'empty output must not reach replacement'
assert_no_transaction_files "$GRUB_DIRECTORY" \
    'empty output failure should remove the temporary file'

# Syntax rejection must preserve the active file and the validator status.
reset_transaction
original_fingerprint=$(cksum "$GRUB_CONFIG")
GRUB_CHECK_STATUS=4
assert_status 4 'validator failure should preserve its external status' update_grub_configuration
assert_equal "$original_fingerprint" "$(cksum "$GRUB_CONFIG")" \
    'validator failure should preserve the active configuration'
assert_equal 0 "$GRUB_GENERATION_STATUS" 'validation failure should retain successful generation state'
assert_equal 4 "$GRUB_VALIDATION_STATUS" 'validator failure should be recorded'
assert_equal 'grub-script-check rejected the generated configuration' "$GRUB_VALIDATION_ERROR" \
    'syntax rejection should expose a stable diagnostic'
assert_equal 0 "$GRUB_REPLACEMENT_ATTEMPTED" \
    'syntax rejection must not attempt replacement'
assert_no_transaction_files "$GRUB_DIRECTORY" \
    'syntax rejection should remove the temporary file'

# A missing validator must block before generating any output, even when the
# host running the harness has a real grub-script-check binary installed.
reset_transaction
unset -f grub-script-check
saved_path=$PATH
PATH="$TEST_TMP/missing-validator-path"
assert_status 1 'missing grub-script-check should fail closed' update_grub_configuration
PATH=$saved_path
assert_equal 0 "$GRUB_COMMAND_ATTEMPTED" \
    'missing validator should block before grub-mkconfig'
assert_equal 'grub-script-check is unavailable' "$GRUB_VALIDATION_ERROR" \
    'missing validator should expose a stable diagnostic'
assert_file_missing "$GRUB_GENERATOR_LOG" \
    'generator must not run without a validator'
assert_file_contains 'original grub configuration' "$GRUB_CONFIG" \
    'missing validator should preserve the active configuration'
grub-script-check() {
    printf '%s\n' "$@" >> "$GRUB_VALIDATOR_LOG"
    if [ "$GRUB_MUTATE_ACTIVE_DURING_CHECK" -eq 1 ]; then
        printf 'external concurrent update\n' > "$GRUB_CONFIG"
    fi
    return "$GRUB_CHECK_STATUS"
}

# Active symlinks and paths outside the configured directory must be rejected.
reset_transaction
printf 'symlink target\n' > "$TEST_TMP/symlink-target"
rm -f "$GRUB_CONFIG"
ln -s "$TEST_TMP/symlink-target" "$GRUB_CONFIG"
assert_status 1 'an active GRUB symlink should be rejected' update_grub_configuration
assert_equal "active GRUB configuration must not be a symbolic link: $GRUB_CONFIG" \
    "$GRUB_VALIDATION_ERROR" \
    'active symlink rejection should expose a stable diagnostic'
assert_file_contains 'symlink target' "$TEST_TMP/symlink-target" \
    'symlink rejection must not alter the target'
assert_file_missing "$GRUB_GENERATOR_LOG" \
    'generator must not run for an active symlink'

reset_transaction
outside_directory="$TEST_TMP/outside"
mkdir -p "$outside_directory"
GRUB_CONFIG="$outside_directory/grub.cfg"
printf 'outside original\n' > "$GRUB_CONFIG"
assert_status 1 'a configuration outside GRUB_DIRECTORY should be rejected' update_grub_configuration
assert_file_contains 'outside original' "$GRUB_CONFIG" \
    'outside-path rejection should preserve the active file'
assert_file_missing "$GRUB_GENERATOR_LOG" \
    'generator must not run for an outside active path'
GRUB_CONFIG="$GRUB_DIRECTORY/grub.cfg"

# A concurrent modification of the active file must prevent stale replacement.
reset_transaction
GRUB_MUTATE_ACTIVE_DURING_CHECK=1
assert_status 1 'concurrent active-file changes should block replacement' update_grub_configuration
assert_file_contains 'external concurrent update' "$GRUB_CONFIG" \
    'concurrent content should remain active'
assert_file_not_contains 'menuentry "Slackware"' "$GRUB_CONFIG" \
    'generated stale content must not replace a concurrent update'
assert_equal 0 "$GRUB_REPLACEMENT_ATTEMPTED" \
    'concurrent change should be detected before mv'
assert_equal 0 "$GRUB_CONFIG_REPLACED" \
    'concurrent change must not report replacement'
assert_equal 'active GRUB configuration changed during generation; replacement refused' \
    "$GRUB_VALIDATION_ERROR" \
    'concurrent change should expose a stable diagnostic'
assert_no_transaction_files "$GRUB_DIRECTORY" \
    'concurrent-change failure should remove the temporary file'

# An atomic move failure must preserve the active file.
reset_transaction
original_fingerprint=$(cksum "$GRUB_CONFIG")
GRUB_MOVE_STATUS=6
assert_status 6 'move failure should preserve its external status' update_grub_configuration
assert_equal "$original_fingerprint" "$(cksum "$GRUB_CONFIG")" \
    'move failure should preserve the active configuration'
assert_equal 1 "$GRUB_REPLACEMENT_ATTEMPTED" \
    'move failure should record the attempted replacement'
assert_equal 0 "$GRUB_CONFIG_REPLACED" \
    'move failure must not report replacement'
assert_equal 6 "$GRUB_INSTALL_STATUS" 'move failure should be recorded'
assert_equal 'atomic GRUB configuration replacement failed' "$GRUB_VALIDATION_ERROR" \
    'move failure should expose a stable diagnostic'
assert_no_transaction_files "$GRUB_DIRECTORY" \
    'move failure should remove the temporary file'

# A previously absent active configuration may be installed with secure permissions.
reset_transaction
rm -f "$GRUB_CONFIG"
assert_status 0 'an absent active configuration should be created after validation' update_grub_configuration
assert_file_contains 'menuentry "Slackware"' "$GRUB_CONFIG" \
    'validated output should create the missing active configuration'
assert_mode 600 "$GRUB_CONFIG" \
    'a newly created active configuration should use secure permissions'
assert_equal 0 "$GRUB_ACTIVE_CONFIG_EXISTED" \
    'transaction metadata should record the absent original'

# Cleanup must never follow a replacement symlink at the temporary path.
reset_transaction
assert_status 0 'transaction preparation should create an owned temporary file' prepare_grub_transaction
temporary_path=$GRUB_TEMP_CONFIG
printf 'cleanup target\n' > "$TEST_TMP/cleanup-target"
rm -f "$temporary_path"
ln -s "$TEST_TMP/cleanup-target" "$temporary_path"
assert_status 0 'cleanup should refuse to follow a temporary-path symlink' \
    discard_owned_grub_temporary_config
assert_file_contains 'cleanup target' "$TEST_TMP/cleanup-target" \
    'cleanup must not modify the symlink target'
if [ -L "$temporary_path" ]; then
    pass
else
    fail 'cleanup should leave a replaced temporary-path symlink untouched'
fi
rm -f "$temporary_path"
GRUB_TEMP_CONFIG_OWNED=0

# Provisional JSON must expose generation, validation, and atomic replacement state.
reset_transaction
assert_status 0 'successful transaction should provide JSON state' update_grub_configuration
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
INITRD_REQUIRED=0
INITRD_UPDATE=0
GRUB_REQUIRED=1
GRUB_UPDATE=1
GRUB_OK=1
GRUB_COMMAND_ATTEMPTED=1
GRUB_GENERATION_STATUS=0
GRUB_VALIDATION_STATUS=0
GRUB_VALIDATION_ERROR=
GRUB_INSTALL_STATUS=0
GRUB_REPLACEMENT_ATTEMPTED=1
GRUB_CONFIG_REPLACED=1
GRUB_TEMP_CONFIG="$GRUB_DIRECTORY/.grub.cfg.slack-update.example"
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
    fail 'provisional GRUB transaction JSON should be valid'
fi
assert_jq_equal success '.modules.boot.grub_state' "$JSON_OUTPUT_FILE" \
    'JSON should report successful GRUB state'
assert_jq_equal 0 '.modules.boot.grub_generation_exit_code' "$JSON_OUTPUT_FILE" \
    'JSON should expose successful generation'
assert_jq_equal 0 '.modules.boot.grub_validation_exit_code' "$JSON_OUTPUT_FILE" \
    'JSON should expose successful validation'
assert_jq_equal 0 '.modules.boot.grub_install_exit_code' "$JSON_OUTPUT_FILE" \
    'JSON should expose successful installation'
assert_jq_equal true '.modules.boot.grub_replacement_attempted' "$JSON_OUTPUT_FILE" \
    'JSON should expose replacement attempt state'
assert_jq_equal true '.modules.boot.grub_config_replaced' "$JSON_OUTPUT_FILE" \
    'JSON should expose atomic replacement success'
assert_jq_equal grub-script-check '.modules.boot.grub_validator' "$JSON_OUTPUT_FILE" \
    'JSON should identify the validator'
assert_jq_equal true '.modules.boot.grub_atomic_replacement' "$JSON_OUTPUT_FILE" \
    'JSON should declare atomic replacement semantics'

# Source audit: the active path must never be passed directly to grub-mkconfig.
SOURCE_AUDIT="$TEST_TMP/source-audit.txt"
declare -f update_grub_configuration > "$SOURCE_AUDIT"
assert_file_contains 'grub-mkconfig -o "$GRUB_TEMP_CONFIG"' "$SOURCE_AUDIT" \
    'source should direct generation to the temporary path'
assert_file_not_contains 'grub-mkconfig -o "$GRUB_CONFIG"' "$SOURCE_AUDIT" \
    'source must not direct generation to the active path'
assert_file_contains 'grub-script-check "$GRUB_TEMP_CONFIG"' "$REFERENCE_SCRIPT" \
    'source should validate the temporary configuration'
assert_file_contains 'mv -fT -- "$GRUB_TEMP_CONFIG" "$GRUB_CONFIG"' "$REFERENCE_SCRIPT" \
    'source should atomically replace the active configuration'
assert_file_contains 'grub_config_fingerprint "$GRUB_CONFIG"' "$REFERENCE_SCRIPT" \
    'source should detect concurrent active-file changes'

printf 'GRUB atomic replacement tests: %d checks, %d failures\n' \
    "$TEST_COUNT" "$FAILURE_COUNT"

[ "$FAILURE_COUNT" -eq 0 ]
