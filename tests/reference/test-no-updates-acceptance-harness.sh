#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

TEST_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPOSITORY_ROOT=$(CDPATH= cd -- "$TEST_DIR/../.." && pwd -P)
ACCEPTANCE_SCRIPT="$REPOSITORY_ROOT/tests/acceptance/reference/test-no-updates.sh"
DEFAULT_CONFIG="$REPOSITORY_ROOT/data/config/slack-update.conf"
CHECK_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/no-updates/check-result.json"
APPLY_FIXTURE="$REPOSITORY_ROOT/tests/fixtures/reference/acceptance/no-updates/apply-result.json"
FIXTURE_CONFIG=/var/tmp/slack-update-acceptance/no-updates/example/slack-update.conf

# Source the acceptance helpers without executing the real-system scenario.
# shellcheck source=../acceptance/reference/test-no-updates.sh
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

assert_failure_status() {
    local message=$1
    shift
    local status

    "$@" >/dev/null 2>&1
    status=$?
    if [ "$status" -ne 0 ]; then
        pass
    else
        fail "$message"
    fi
}

json_is_valid() {
    python3 -m json.tool "$1" >/dev/null
}

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

assert_file_contains 'Run it only on a disposable VM snapshot' "$ACCEPTANCE_SCRIPT" \
    'the real apply scenario should warn that a recoverable test host is required'
assert_file_contains '--execute-apply is required' "$ACCEPTANCE_SCRIPT" \
    'the harness should require explicit confirmation before real package operations'
assert_file_contains 'run_reference_operation check' "$ACCEPTANCE_SCRIPT" \
    'the harness should run a no-updates precondition check'
assert_file_contains 'run_reference_operation apply' "$ACCEPTANCE_SCRIPT" \
    'the harness should exercise the real apply workflow'
assert_file_contains 'mode=disabled' "$ACCEPTANCE_SCRIPT" \
    'the scenario configuration should isolate optional modules'
assert_file_contains 'packages.before.sha256' "$ACCEPTANCE_SCRIPT" \
    'the baseline package database should be preserved as evidence'
assert_file_contains 'packages.after.sha256' "$ACCEPTANCE_SCRIPT" \
    'the final package database should be preserved as evidence'
assert_file_contains 'boot.before.txt' "$ACCEPTANCE_SCRIPT" \
    'the baseline boot state should be preserved as evidence'
assert_file_contains 'boot.after.txt' "$ACCEPTANCE_SCRIPT" \
    'the final boot state should be preserved as evidence'
assert_file_contains 'create_evidence_archive' "$ACCEPTANCE_SCRIPT" \
    'the scenario should create a portable evidence archive'
assert_file_contains 'sha256sum -- "$archive"' "$ACCEPTANCE_SCRIPT" \
    'the evidence archive should have a SHA-256 sidecar'
assert_file_not_contains 'rm -rf /var/log/packages' "$ACCEPTANCE_SCRIPT" \
    'the acceptance harness must never remove the package database'

check_line=$(grep -n 'run_reference_operation check' "$ACCEPTANCE_SCRIPT" | tail -n 1 | cut -d: -f1)
apply_line=$(grep -n 'run_reference_operation apply' "$ACCEPTANCE_SCRIPT" | tail -n 1 | cut -d: -f1)
if [ -n "$check_line" ] && [ -n "$apply_line" ] && [ "$check_line" -lt "$apply_line" ]; then
    pass
else
    fail 'the no-updates check must complete before the real apply workflow starts'
fi

assert_success 'Slackware 15.0 should be an accepted target name' \
    validate_target_name slackware-15.0
assert_success 'Slackware-current should be an accepted target name' \
    validate_target_name slackware-current
assert_failure_status 'unknown target names should be rejected' \
    validate_target_name slackware-14.2
assert_success 'the exact Slackware 15.0 version should match the stable target' \
    validate_slackware_target_version slackware-15.0 'Slackware 15.0'
assert_failure_status 'Slackware-current should not match the stable 15.0 version' \
    validate_slackware_target_version slackware-current 'Slackware 15.0'
assert_success 'a plus-suffixed Slackware version should match current' \
    validate_slackware_target_version slackware-current 'Slackware 15.0+'
assert_success 'an explicit current version label should match current' \
    validate_slackware_target_version slackware-current 'Slackware current'

GENERATED_CONFIG="$TEST_TMP/slack-update.conf"
RUNTIME_ROOT="$TEST_TMP/runtime"
write_acceptance_config "$DEFAULT_CONFIG" "$GENERATED_CONFIG" "$RUNTIME_ROOT"
assert_equal_value 0 "$?" 'the isolated acceptance configuration should be generated'
assert_file_contains "work_dir=$RUNTIME_ROOT/work" "$GENERATED_CONFIG" \
    'the generated work directory should stay inside the evidence tree'
assert_file_contains "log_dir=$RUNTIME_ROOT/log" "$GENERATED_CONFIG" \
    'the generated log directory should stay inside the evidence tree'
assert_file_contains "lock_file=$RUNTIME_ROOT/slack-update.lock" "$GENERATED_CONFIG" \
    'the generated lock should stay inside the evidence tree'
assert_file_contains 'schema_version=1' "$GENERATED_CONFIG" \
    'the generated configuration should preserve schema version 1'
assert_equal_value 5 "$(grep -c '^mode=disabled$' "$GENERATED_CONFIG")" \
    'all five optional modules should be disabled for this isolated scenario'
assert_file_not_contains 'mode=auto' "$GENERATED_CONFIG" \
    'no optional module should remain in auto mode'
if SLACK_UPDATE_CONFIG="$GENERATED_CONFIG" bash -c     'source "$1"; initialize_execution_environment; load_configuration'     _ "$REPOSITORY_ROOT/tools/reference/slack-update-reference.sh"; then
    pass
else
    fail 'the generated scenario configuration should pass the reference parser'
fi

assert_success 'the expected no-updates check fixture should satisfy the validator' \
    validate_json_result check "$CHECK_FIXTURE" "$FIXTURE_CONFIG"
assert_success 'the expected no-updates apply fixture should satisfy the validator' \
    validate_json_result apply "$APPLY_FIXTURE" "$FIXTURE_CONFIG"
assert_success 'the expected check fixture should be valid JSON' \
    json_is_valid "$CHECK_FIXTURE"
assert_success 'the expected apply fixture should be valid JSON' \
    json_is_valid "$APPLY_FIXTURE"

python3 - "$CHECK_FIXTURE" "$TEST_TMP/check-updates.json" <<'PYTHON_EOF'
import json
import pathlib
import sys

source, output = map(pathlib.Path, sys.argv[1:])
data = json.loads(source.read_text(encoding="utf-8"))
data["modules"]["slackware"]["updates_available"] = True
output.write_text(json.dumps(data), encoding="utf-8")
PYTHON_EOF
assert_failure_status 'a check result with available updates should fail validation' \
    validate_json_result check "$TEST_TMP/check-updates.json" "$FIXTURE_CONFIG"

python3 - "$APPLY_FIXTURE" "$TEST_TMP/apply-exit.json" <<'PYTHON_EOF'
import json
import pathlib
import sys

source, output = map(pathlib.Path, sys.argv[1:])
data = json.loads(source.read_text(encoding="utf-8"))
data["exit_code"] = 2
output.write_text(json.dumps(data), encoding="utf-8")
PYTHON_EOF
assert_failure_status 'a non-zero apply result should fail validation' \
    validate_json_result apply "$TEST_TMP/apply-exit.json" "$FIXTURE_CONFIG"

python3 - "$APPLY_FIXTURE" "$TEST_TMP/apply-count.json" <<'PYTHON_EOF'
import json
import pathlib
import sys

source, output = map(pathlib.Path, sys.argv[1:])
data = json.loads(source.read_text(encoding="utf-8"))
data["modules"]["slackware"]["snapshot_after_records"] += 1
output.write_text(json.dumps(data), encoding="utf-8")
PYTHON_EOF
assert_failure_status 'a changed package-record count should fail validation' \
    validate_json_result apply "$TEST_TMP/apply-count.json" "$FIXTURE_CONFIG"

python3 - "$APPLY_FIXTURE" "$TEST_TMP/apply-module.json" <<'PYTHON_EOF'
import json
import pathlib
import sys

source, output = map(pathlib.Path, sys.argv[1:])
data = json.loads(source.read_text(encoding="utf-8"))
data["modules"]["sbo"]["mode"] = "auto"
output.write_text(json.dumps(data), encoding="utf-8")
PYTHON_EOF
assert_failure_status 'an optional module outside disabled mode should fail validation' \
    validate_json_result apply "$TEST_TMP/apply-module.json" "$FIXTURE_CONFIG"

PACKAGE_DB="$TEST_TMP/packages"
mkdir -p "$PACKAGE_DB"
printf 'beta\n' > "$PACKAGE_DB/z-package-1.0-x86_64-1"
printf 'alpha\n' > "$PACKAGE_DB/a-package-1.0-x86_64-1"
capture_package_database "$PACKAGE_DB" "$TEST_TMP/packages.first"
assert_equal_value 0 "$?" 'a package database fixture should be captured'
assert_equal_value 2 "$(wc -l < "$TEST_TMP/packages.first")" \
    'the package database capture should include every regular record'
assert_equal_value 'a-package-1.0-x86_64-1' \
    "$(awk 'NR == 1 { print $2 }' "$TEST_TMP/packages.first")" \
    'package database evidence should use deterministic lexical order'
capture_package_database "$PACKAGE_DB" "$TEST_TMP/packages.second"
if cmp -s "$TEST_TMP/packages.first" "$TEST_TMP/packages.second"; then
    pass
else
    fail 'unchanged package databases should produce identical evidence'
fi
printf 'changed\n' > "$PACKAGE_DB/a-package-1.0-x86_64-1"
capture_package_database "$PACKAGE_DB" "$TEST_TMP/packages.changed"
if cmp -s "$TEST_TMP/packages.first" "$TEST_TMP/packages.changed"; then
    fail 'package record content changes should alter the evidence digest'
else
    pass
fi

"$ACCEPTANCE_SCRIPT" --help > "$TEST_TMP/help.out" 2> "$TEST_TMP/help.err"
assert_equal_value 0 "$?" '--help should exit successfully without running the scenario'
assert_file_contains '--execute-apply' "$TEST_TMP/help.out" \
    'the help text should disclose the explicit apply confirmation'

"$ACCEPTANCE_SCRIPT" --target slackware-15.0 > "$TEST_TMP/no-confirm.out" 2> "$TEST_TMP/no-confirm.err"
assert_equal_value 2 "$?" 'omitting --execute-apply should fail before host inspection'
assert_file_contains '--execute-apply is required' "$TEST_TMP/no-confirm.err" \
    'the missing confirmation diagnostic should be explicit'

OUTPUT_DIR="$TEST_TMP/evidence"
mkdir -p "$OUTPUT_DIR"
printf 'sample evidence\n' > "$OUTPUT_DIR/sample.txt"
archive_path=$(create_evidence_archive)
assert_equal_value "$OUTPUT_DIR.tar.gz" "$archive_path" \
    'the evidence archive should use the documented path'
if tar -tzf "$archive_path" | grep -Fq 'evidence/sample.txt'; then
    pass
else
    fail 'the evidence archive should contain the complete evidence directory'
fi
if sha256sum -c "$archive_path.sha256" >/dev/null 2>&1; then
    pass
else
    fail 'the evidence archive SHA-256 sidecar should verify successfully'
fi

printf 'No-updates acceptance harness tests: %d checks, %d failures\n' \
    "$TEST_COUNT" "$FAILURE_COUNT"

[ "$FAILURE_COUNT" -eq 0 ]
