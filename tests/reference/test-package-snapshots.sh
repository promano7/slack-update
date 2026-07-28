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

assert_file_content() {
    local expected=$1
    local path=$2
    local message=$3
    local actual=

    if [ -f "$path" ]; then
        actual=$(cat "$path")
    fi
    assert_equal "$expected" "$actual" "$message"
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

    if "$@"; then
        fail "$message"
    else
        pass
    fi
}

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

PACKAGE_DATABASE="$TEST_TMP/packages"
mkdir -p "$PACKAGE_DATABASE"
: > "$PACKAGE_DATABASE/zlib-1.3.1-x86_64-1"
: > "$PACKAGE_DATABASE/aaa_libraries-15.0-x86_64-19"
: > "$PACKAGE_DATABASE/gtk+3-3.24.49-x86_64-1.txz"

SNAPSHOT="$TEST_TMP/packages.snapshot"
assert_success "valid package database should produce a snapshot" \
    capture_validated_package_snapshot "$SNAPSHOT"
assert_file_content \
    $'aaa_libraries-15.0-x86_64-19\ngtk+3-3.24.49-x86_64-1\nzlib-1.3.1-x86_64-1' \
    "$SNAPSHOT" \
    "captured snapshot should be normalized and sorted"
assert_equal 3 "$PACKAGE_SNAPSHOT_RECORD_COUNT" \
    "captured snapshot should report its record count"
assert_success "captured snapshot should pass standalone validation" \
    validate_package_snapshot "$SNAPSHOT"
assert_equal 3 "$PACKAGE_SNAPSHOT_RECORD_COUNT" \
    "standalone validation should report its record count"

REAL_PACKAGE_DATABASE=$PACKAGE_DATABASE
PACKAGE_DATABASE_LINK="$TEST_TMP/packages-link"
ln -s "$REAL_PACKAGE_DATABASE" "$PACKAGE_DATABASE_LINK"
PACKAGE_DATABASE=$PACKAGE_DATABASE_LINK
SYMLINK_SNAPSHOT="$TEST_TMP/packages-symlink.snapshot"
assert_success "a symlinked package database should produce a snapshot" \
    capture_validated_package_snapshot "$SYMLINK_SNAPSHOT"
assert_file_content \
    $'aaa_libraries-15.0-x86_64-19\ngtk+3-3.24.49-x86_64-1\nzlib-1.3.1-x86_64-1' \
    "$SYMLINK_SNAPSHOT" \
    "a command-line package database symlink should be followed"
assert_equal 3 "$PACKAGE_SNAPSHOT_RECORD_COUNT" \
    "a symlinked package database should report its record count"

EXTERNAL_RECORD="$TEST_TMP/external-package-1.0-x86_64-1"
: > "$EXTERNAL_RECORD"
ln -s "$EXTERNAL_RECORD" "$REAL_PACKAGE_DATABASE/internal-symlink-1.0-x86_64-1"
assert_success "package-record symlinks inside the database should be ignored" \
    capture_validated_package_snapshot "$SYMLINK_SNAPSHOT"
assert_equal 3 "$PACKAGE_SNAPSHOT_RECORD_COUNT" \
    "internal package-record symlinks should not enter the snapshot"
rm -f "$REAL_PACKAGE_DATABASE/internal-symlink-1.0-x86_64-1"
PACKAGE_DATABASE=$REAL_PACKAGE_DATABASE

printf 'preserve-existing-snapshot\n' > "$SNAPSHOT"
: > "$PACKAGE_DATABASE/not-a-package"
assert_failure "malformed package database entry should reject capture" \
    capture_validated_package_snapshot "$SNAPSHOT"
assert_file_content 'preserve-existing-snapshot' "$SNAPSHOT" \
    "failed atomic capture should preserve the previous destination"
case "$PACKAGE_SNAPSHOT_ERROR" in
    *'invalid package record: not-a-package') pass ;;
    *) fail "malformed package record should produce a specific validation error" ;;
esac
rm -f "$PACKAGE_DATABASE/not-a-package"

EMPTY_DATABASE="$TEST_TMP/empty-packages"
mkdir "$EMPTY_DATABASE"
PACKAGE_DATABASE="$EMPTY_DATABASE"
assert_failure "empty package database should reject capture" \
    capture_validated_package_snapshot "$TEST_TMP/empty.snapshot"
case "$PACKAGE_SNAPSHOT_ERROR" in
    *'contains no package records'*) pass ;;
    *) fail "empty package database should report that it contains no records" ;;
esac

PACKAGE_DATABASE="$TEST_TMP/missing-packages"
assert_failure "missing package database should reject capture" \
    capture_validated_package_snapshot "$TEST_TMP/missing.snapshot"
case "$PACKAGE_SNAPSHOT_ERROR" in
    *'directory does not exist'*) pass ;;
    *) fail "missing package database should report the missing directory" ;;
esac

assert_failure "missing snapshot should fail validation" \
    validate_package_snapshot "$TEST_TMP/does-not-exist.snapshot"

EMPTY_SNAPSHOT="$TEST_TMP/empty.snapshot"
: > "$EMPTY_SNAPSHOT"
assert_failure "empty snapshot should fail validation" \
    validate_package_snapshot "$EMPTY_SNAPSHOT"

UNSORTED_SNAPSHOT="$TEST_TMP/unsorted.snapshot"
cat > "$UNSORTED_SNAPSHOT" <<'EOF_UNSORTED'
zlib-1.3.1-x86_64-1
aaa_libraries-15.0-x86_64-19
EOF_UNSORTED
assert_failure "unsorted snapshot should fail validation" \
    validate_package_snapshot "$UNSORTED_SNAPSHOT"

DUPLICATE_SNAPSHOT="$TEST_TMP/duplicate.snapshot"
cat > "$DUPLICATE_SNAPSHOT" <<'EOF_DUPLICATE'
aaa_libraries-15.0-x86_64-19
aaa_libraries-15.0-x86_64-19
EOF_DUPLICATE
assert_failure "duplicate snapshot records should fail validation" \
    validate_package_snapshot "$DUPLICATE_SNAPSHOT"

NONCANONICAL_SNAPSHOT="$TEST_TMP/noncanonical.snapshot"
printf 'aaa_libraries-15.0-x86_64-19.txz\n' > "$NONCANONICAL_SNAPSHOT"
assert_failure "archive extension should make a stored snapshot non-canonical" \
    validate_package_snapshot "$NONCANONICAL_SNAPSHOT"
case "$PACKAGE_SNAPSHOT_ERROR" in
    *'non-canonical package record'*) pass ;;
    *) fail "non-canonical snapshot should report its canonicality failure" ;;
esac

MALFORMED_SNAPSHOT="$TEST_TMP/malformed.snapshot"
printf 'invalid-record\n' > "$MALFORMED_SNAPSHOT"
assert_failure "malformed snapshot record should fail validation" \
    validate_package_snapshot "$MALFORMED_SNAPSHOT"
case "$PACKAGE_SNAPSHOT_ERROR" in
    *'invalid package record'*) pass ;;
    *) fail "malformed snapshot should report its invalid record" ;;
esac

PACKAGE_DATABASE="$TEST_TMP/packages"
BEFORE_PKGS="$TEST_TMP/packages.before"
AFTER_PKGS="$TEST_TMP/packages.after"
printf 'stale-before\n' > "$BEFORE_PKGS"
printf 'stale-after\n' > "$AFTER_PKGS"
PACKAGE_SNAPSHOT_BEFORE_VALID=0
PACKAGE_SNAPSHOT_AFTER_VALID=0
PACKAGE_SNAPSHOT_BEFORE_COUNT=0
PACKAGE_SNAPSHOT_AFTER_COUNT=0
PACKAGE_SNAPSHOT_BEFORE_ERROR=
PACKAGE_SNAPSHOT_AFTER_ERROR=
assert_success "before wrapper should capture a validated baseline" \
    capture_package_snapshot_before
assert_equal 1 "$PACKAGE_SNAPSHOT_BEFORE_VALID" \
    "before wrapper should set its validity flag"
assert_equal 3 "$PACKAGE_SNAPSHOT_BEFORE_COUNT" \
    "before wrapper should expose its record count"
if [ ! -e "$AFTER_PKGS" ]; then
    pass
else
    fail "before wrapper should remove a stale post-update snapshot"
fi
assert_success "before wrapper output should pass validation" \
    validate_package_snapshot "$BEFORE_PKGS"

: > "$PACKAGE_DATABASE/bash-5.2.037-x86_64-1"
assert_success "after wrapper should capture a validated final state" \
    capture_package_snapshot_after
assert_equal 1 "$PACKAGE_SNAPSHOT_AFTER_VALID" \
    "after wrapper should set its validity flag"
assert_equal 4 "$PACKAGE_SNAPSHOT_AFTER_COUNT" \
    "after wrapper should expose its record count"
assert_success "after wrapper output should pass validation" \
    validate_package_snapshot "$AFTER_PKGS"

BEFORE_GUARD_MARKER="$TEST_TMP/update-called-before"
if (
    initialize_runtime_state
    BROKEN="$TEST_TMP/broken-before"
    BEFORE_PKGS="$TEST_TMP/guard.before"
    AFTER_PKGS="$TEST_TMP/guard.after"
    PACKAGE_SNAPSHOT_BEFORE_ERROR='forced baseline failure'
    capture_package_snapshot_before() {
        PACKAGE_SNAPSHOT_BEFORE_ERROR='forced baseline failure'
        return 1
    }
    update_slackware_system() {
        : > "$BEFORE_GUARD_MARKER"
    }
    emit_module_started_event() { :; }
    emit_action_started_event() { :; }
    emit_action_completed_event() { :; }
    emit_module_completed_event() { :; }
    print_summary() { :; }
    run_apply_workflow >/dev/null 2>&1
); then
    fail "apply workflow should fail when the baseline snapshot is invalid"
else
    pass
fi
if [ ! -e "$BEFORE_GUARD_MARKER" ]; then
    pass
else
    fail "slackpkg operations should not start after baseline snapshot failure"
fi

AFTER_GUARD_MARKER="$TEST_TMP/optional-probe-called"
if (
    initialize_runtime_state
    BROKEN="$TEST_TMP/broken-after"
    PACKAGE_SNAPSHOT_BEFORE_VALID=1
    PACKAGE_SNAPSHOT_BEFORE_COUNT=3
    capture_package_snapshot_before() {
        PACKAGE_SNAPSHOT_BEFORE_VALID=1
        PACKAGE_SNAPSHOT_BEFORE_COUNT=3
        return 0
    }
    update_slackware_system() {
        SLACKPKG_UPDATE_STATUS=0
        SLACKPKG_INSTALL_NEW_STATUS=0
        SLACKPKG_UPGRADE_ALL_STATUS=0
    }
    capture_package_snapshot_after() {
        PACKAGE_SNAPSHOT_AFTER_VALID=0
        PACKAGE_SNAPSHOT_AFTER_ERROR='forced final-state failure'
        return 1
    }
    probe_optional_modules() {
        : > "$AFTER_GUARD_MARKER"
    }
    emit_module_started_event() { :; }
    emit_action_started_event() { :; }
    emit_action_completed_event() { :; }
    emit_module_completed_event() { :; }
    print_summary() { :; }
    run_apply_workflow >/dev/null 2>&1
); then
    fail "apply workflow should fail when the final snapshot is invalid"
else
    pass
fi
if [ ! -e "$AFTER_GUARD_MARKER" ]; then
    pass
else
    fail "snapshot-dependent optional work should not start after final snapshot failure"
fi

printf 'Package snapshot tests: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
