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

assert_file_equal() {
    local expected=$1
    local actual=$2
    local message=$3

    if cmp -s "$expected" "$actual"; then
        pass
    else
        fail "$message"
        diff -u "$expected" "$actual" >&2 || true
    fi
}

assert_record_selected() {
    local line=$1
    local expected_target=$2
    local expected_options=$3
    local expected_record=$4

    if sbo_queue_record_from_line "$line"; then
        assert_equal "$expected_target" "$SBO_QUEUE_LINE_TARGET" \
            "queue target mismatch for line: $line"
        assert_equal "$expected_options" "$SBO_QUEUE_LINE_OPTIONS" \
            "queue options mismatch for line: $line"
        assert_equal "$expected_record" "$SBO_QUEUE_LINE_RECORD" \
            "canonical queue record mismatch for line: $line"
    else
        fail "valid queue record was rejected: $line"
    fi
}

assert_record_rejected() {
    local line=$1
    local status

    if sbo_queue_record_from_line "$line"; then
        fail "unsafe queue record was accepted: $line"
    else
        status=$?
        assert_equal 2 "$status" "unsafe queue record should be rejected: $line"
    fi
}

assert_record_selected \
    'OpenCASCADE | FFMPEG=yes FREEIMAGE=yes' \
    OpenCASCADE \
    'FFMPEG=yes FREEIMAGE=yes' \
    'OpenCASCADE | FFMPEG=yes FREEIMAGE=yes'
assert_record_selected \
    $'  ffmpeg\t|  CHROMAPRINT=yes   CODECS=all  # local options' \
    ffmpeg \
    'CHROMAPRINT=yes CODECS=all' \
    'ffmpeg | CHROMAPRINT=yes CODECS=all'
assert_record_selected \
    'package | CFLAGS="-O2 -fPIC" TESTS=no' \
    package \
    'CFLAGS="-O2 -fPIC" TESTS=no' \
    'package | CFLAGS="-O2 -fPIC" TESTS=no'
assert_record_selected alpha alpha '' alpha
assert_record_rejected 'package |'
assert_record_rejected 'package | TESTS'
assert_record_rejected 'package | TESTS=yes;id'
assert_record_rejected 'package | TESTS=$(id)'
assert_record_rejected 'package | CFLAGS="-O2 -pipe'
assert_record_rejected $'package | CFLAGS="-O2\t-fPIC"'
assert_record_rejected 'package | TESTS=yes | DEBUG=no'

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

QUEUE_DIR="$TEST_TMP/queues"
mkdir -p "$QUEUE_DIR/nested"
cat > "$QUEUE_DIR/main.sqf" <<'EOF_QUEUE_MAIN'
dependency | FEATURE=yes
application | CFLAGS="-O2 -fPIC"
shared | TESTS=no
plain
EOF_QUEUE_MAIN
cat > "$QUEUE_DIR/nested/secondary.sqf" <<'EOF_QUEUE_SECONDARY'
shared | TESTS=no
another
EOF_QUEUE_SECONDARY

OPTIONS_FILE="$TEST_TMP/sbo-options.sqf"
cat > "$OPTIONS_FILE" <<'EOF_OPTIONS'
# Persistent overrides survive sqg regeneration.
application | CFLAGS="-O3 -pipe"
extra-target | MODE=full
EOF_OPTIONS

OPTION_MAP="$TEST_TMP/options.normalized"
EXPECTED_MAP="$TEST_TMP/options.expected"
cat > "$EXPECTED_MAP" <<'EOF_EXPECTED_MAP'
application	CFLAGS="-O3 -pipe"
dependency	FEATURE=yes
extra-target	MODE=full
shared	TESTS=no
EOF_EXPECTED_MAP

if collect_sbo_option_records_from_sources \
    "$QUEUE_DIR" "$OPTIONS_FILE" "$OPTION_MAP"; then
    pass
else
    fail "valid SBo options were not collected: $SBO_TARGET_SELECTION_ERROR"
fi
assert_file_equal "$EXPECTED_MAP" "$OPTION_MAP" \
    'persistent options should override generated queue options deterministically'
assert_equal 4 "$SBO_OPTION_RECORD_COUNT" \
    'the normalized option count should include queue and persistent records'

QUEUE_ONLY_MAP="$TEST_TMP/options-queue-only"
if collect_sbo_option_records_from_sources \
    "$QUEUE_DIR" "$TEST_TMP/missing-options.sqf" "$QUEUE_ONLY_MAP"; then
    pass
else
    fail 'a missing optional SBo options file should produce the queue option map'
fi
assert_equal $'application\tCFLAGS="-O2 -fPIC"\ndependency\tFEATURE=yes\nshared\tTESTS=no' \
    "$(cat "$QUEUE_ONLY_MAP")" \
    'queue options should remain available when no persistent file exists'

CONFLICT_DIR="$TEST_TMP/conflict-queues"
mkdir -p "$CONFLICT_DIR"
printf '%s\n' 'package | MODE=one' > "$CONFLICT_DIR/one.sqf"
printf '%s\n' 'package | MODE=two' > "$CONFLICT_DIR/two.sqf"
ATOMIC_MAP="$TEST_TMP/atomic-map"
printf '%s\n' preserved > "$ATOMIC_MAP"
if collect_sbo_option_records_from_sources \
    "$CONFLICT_DIR" "$TEST_TMP/no-options" "$ATOMIC_MAP"; then
    fail 'conflicting queue options should fail normalization'
else
    pass
fi
assert_equal preserved "$(cat "$ATOMIC_MAP")" \
    'conflicting queue options must preserve the previous normalized map'
assert_equal 'conflicting SBo build options for target: package' \
    "$SBO_TARGET_SELECTION_ERROR" \
    'conflicting queue options should expose the affected package'

INVALID_QUEUE_DIR="$TEST_TMP/invalid-queue-options"
mkdir -p "$INVALID_QUEUE_DIR"
printf '%s\n' 'package | TESTS=yes;id' > "$INVALID_QUEUE_DIR/invalid.sqf"
if collect_sbo_option_records_from_sources \
    "$INVALID_QUEUE_DIR" "$TEST_TMP/no-options" "$ATOMIC_MAP"; then
    fail 'unsafe queue options should fail collection'
else
    pass
fi
assert_equal "queue contains invalid SBo build options: $INVALID_QUEUE_DIR/invalid.sqf" \
    "$SBO_TARGET_SELECTION_ERROR" \
    'unsafe queue options should identify their source queue'

DUPLICATE_OPTIONS="$TEST_TMP/duplicate-options.sqf"
cat > "$DUPLICATE_OPTIONS" <<'EOF_DUPLICATE_OPTIONS'
package | MODE=one
package | MODE=one
EOF_DUPLICATE_OPTIONS
if collect_sbo_option_records_from_sources \
    "$TEST_TMP/no-queues" "$DUPLICATE_OPTIONS" "$ATOMIC_MAP"; then
    fail 'duplicate persistent option records should be rejected'
else
    pass
fi
assert_equal 'duplicate SBo build-option record for target: package' \
    "$SBO_TARGET_SELECTION_ERROR" \
    'duplicate persistent records should expose the affected package'
assert_equal preserved "$(cat "$ATOMIC_MAP")" \
    'duplicate persistent records must preserve the previous normalized map'

NO_OPTION_OVERRIDE="$TEST_TMP/no-option-override.sqf"
printf '%s\n' package > "$NO_OPTION_OVERRIDE"
if collect_sbo_option_records_from_sources \
    "$TEST_TMP/no-queues" "$NO_OPTION_OVERRIDE" "$ATOMIC_MAP"; then
    fail 'persistent option records without assignments should be rejected'
else
    pass
fi
assert_equal "SBo options file contains an invalid record: $NO_OPTION_OVERRIDE" \
    "$SBO_TARGET_SELECTION_ERROR" \
    'a persistent record without options should expose a stable diagnostic'

CONTROL_OVERRIDE="$TEST_TMP/control-override.sqf"
printf '%s\n' '@personal-queue' > "$CONTROL_OVERRIDE"
if collect_sbo_option_records_from_sources \
    "$TEST_TMP/no-queues" "$CONTROL_OVERRIDE" "$ATOMIC_MAP"; then
    fail 'queue references should not be accepted in the persistent options file'
else
    pass
fi

DIRECTORY_OVERRIDE="$TEST_TMP/options-directory"
mkdir -p "$DIRECTORY_OVERRIDE"
if collect_sbo_option_records_from_sources \
    "$TEST_TMP/no-queues" "$DIRECTORY_OVERRIDE" "$ATOMIC_MAP"; then
    fail 'a directory should not be accepted as the persistent options file'
else
    pass
fi
assert_equal "SBo options file is not a readable regular file: $DIRECTORY_OVERRIDE" \
    "$SBO_TARGET_SELECTION_ERROR" \
    'a non-regular options path should expose a stable diagnostic'

BROKEN_LINK_OVERRIDE="$TEST_TMP/broken-options-link.sqf"
ln -s "$TEST_TMP/missing-options-target" "$BROKEN_LINK_OVERRIDE"
if collect_sbo_option_records_from_sources \
    "$TEST_TMP/no-queues" "$BROKEN_LINK_OVERRIDE" "$ATOMIC_MAP"; then
    fail 'a broken options-file symlink should not be treated as an absent optional file'
else
    pass
fi
assert_equal "SBo options file is not a readable regular file: $BROKEN_LINK_OVERRIDE" \
    "$SBO_TARGET_SELECTION_ERROR" \
    'a broken options-file symlink should fail closed'

CORE_QUEUE="$TEST_TMP/core-queue"
EXTRA_TARGETS="$TEST_TMP/extra-targets"
FINAL_QUEUE="$TEST_TMP/final-queue"
printf '%s\n' dependency application plain > "$CORE_QUEUE"
printf '%s\n' extra-target application > "$EXTRA_TARGETS"
if merge_ordered_sbo_queue_with_target_sets \
    "$FINAL_QUEUE" "$CORE_QUEUE" "$OPTION_MAP" "$EXTRA_TARGETS"; then
    pass
else
    fail 'the final queue should accept normalized build options'
fi
assert_equal $'dependency | FEATURE=yes\napplication | CFLAGS="-O3 -pipe"\nplain\nextra-target | MODE=full' \
    "$(cat "$FINAL_QUEUE")" \
    'the final queue should preserve dependency order and apply options to core and extra targets'
assert_equal 0 "$(grep -c '^shared' "$FINAL_QUEUE" || true)" \
    'options for unselected packages should not add new queue targets'

NO_EXTRA_QUEUE="$TEST_TMP/no-extra-queue"
if merge_ordered_sbo_queue_with_target_sets \
    "$NO_EXTRA_QUEUE" "$CORE_QUEUE" "$OPTION_MAP"; then
    pass
else
    fail 'final queue rendering should not require an extra target set'
fi
assert_equal $'dependency | FEATURE=yes\napplication | CFLAGS="-O3 -pipe"\nplain' \
    "$(cat "$NO_EXTRA_QUEUE")" \
    'a queue without extra targets should preserve core options without reading standard input'

INVALID_MAP="$TEST_TMP/invalid-map"
printf '%s\n' $'package\tTESTS=yes;id' > "$INVALID_MAP"
printf '%s\n' preserved > "$FINAL_QUEUE"
if merge_ordered_sbo_queue_with_target_sets \
    "$FINAL_QUEUE" "$CORE_QUEUE" "$INVALID_MAP" "$EXTRA_TARGETS"; then
    fail 'an unsafe normalized option map should block final queue creation'
else
    pass
fi
assert_equal preserved "$(cat "$FINAL_QUEUE")" \
    'failed option application must preserve the previous final queue'

QUEUE_CORE="$CORE_QUEUE"
QUEUE_EXTRA="$EXTRA_TARGETS"
QUEUE_FINAL="$TEST_TMP/submitted-queue"
SBO_OPTION_RECORDS="$OPTION_MAP"
BROKEN="$TEST_TMP/broken"
STILL_BROKEN="$TEST_TMP/still-broken"
LOG="$TEST_TMP/test.log"
SBO_CALL="$TEST_TMP/sbopkg-call"
: > "$BROKEN"

sbopkg() {
    printf '%s\n' "$*" > "$SBO_CALL"
    return 0
}

if build_and_apply_sbo_queue >/dev/null; then
    pass
else
    fail 'a queue with preserved custom options should be submitted successfully'
fi
assert_equal $'-b\n-B\n'"$QUEUE_FINAL" "$(cat "$SBO_CALL")" \
    'sbopkg should receive the option-preserving queue through -B'
assert_equal $'dependency | FEATURE=yes\napplication | CFLAGS="-O3 -pipe"\nplain\nextra-target | MODE=full' \
    "$(cat "$QUEUE_FINAL")" \
    'the submitted queue should retain all selected custom build options'
assert_equal 0 "$SBO_BUILD_STATUS" \
    'successful option-preserving submission should record status zero'

initialize_runtime_state
FLATPAK_MODE=auto
SBO_MODE=auto
ELF_MODE=auto
CINNAMON_MODE=auto
BOOT_MODE=auto
FLATPAK_MODULE_STATE=disabled
SBO_MODULE_STATE=disabled
ELF_MODULE_STATE=disabled
CINNAMON_MODULE_STATE=disabled
BOOT_MODULE_STATE=disabled
FLATPAK_MODULE_REASON='disabled for test'
SBO_MODULE_REASON='disabled for test'
ELF_MODULE_REASON='disabled for test'
CINNAMON_MODULE_REASON='disabled for test'
BOOT_MODULE_REASON='disabled for test'
PACKAGE_SNAPSHOT_BEFORE_VALID=1
PACKAGE_SNAPSHOT_AFTER_VALID=1
PACKAGE_SNAPSHOT_BEFORE_COUNT=1
PACKAGE_SNAPSHOT_AFTER_COUNT=1
SLACKPKG_UPDATE_STATUS=0
SLACKPKG_INSTALL_NEW_STATUS=0
SLACKPKG_UPGRADE_ALL_STATUS=0
SBO_OPTIONS_FILE="$OPTIONS_FILE"
SBO_OPTION_RECORDS="$OPTION_MAP"
SBO_OPTION_RECORD_COUNT=4
BROKEN="$TEST_TMP/json-broken"
: > "$BROKEN"
JSON_MODULES="$TEST_TMP/options-modules.json"
{
    printf '{"modules":{\n'
    print_apply_json_modules
    printf '}}\n'
} > "$JSON_MODULES"
if jq -e . "$JSON_MODULES" >/dev/null; then
    pass
else
    fail 'provisional module JSON with SBo build options should be valid'
fi
assert_equal "$OPTIONS_FILE" "$(jq -r '.modules.sbo.options_file' "$JSON_MODULES")" \
    'provisional JSON should expose the persistent SBo options path'
assert_equal 4 "$(jq -r '.modules.sbo.build_option_record_count' "$JSON_MODULES")" \
    'provisional JSON should expose the normalized option count'
assert_equal 'CFLAGS="-O3 -pipe"' \
    "$(jq -r '.modules.sbo.build_options[] | select(.target == "application") | .options' "$JSON_MODULES")" \
    'provisional JSON should expose per-package build options structurally'

initialize_configuration_state
assert_equal /etc/slack-update/sbo-options.sqf "$CONFIG_SBO_OPTIONS_FILE" \
    'schema-1 configurations should receive the persistent options-file default'
CONFIG_FILE="$TEST_TMP/config.conf"
if assign_configuration_value sbo options_file /custom/sbo-options.sqf 1; then
    pass
else
    fail 'the configuration parser should accept sbo.options_file'
fi
assert_equal /custom/sbo-options.sqf "$CONFIG_SBO_OPTIONS_FILE" \
    'an explicit sbo.options_file should replace the schema default'

printf 'SBo build-option tests: %d checks, %d failures\n' \
    "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
