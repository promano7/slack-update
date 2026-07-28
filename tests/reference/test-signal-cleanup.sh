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

assert_file_exists() {
    local path=$1
    local message=$2

    if [ -e "$path" ] || [ -L "$path" ]; then
        pass
    else
        fail "$message"
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

assert_lock_available() {
    local path=$1
    local message=$2

    if flock -n "$path" -c true; then
        pass
    else
        fail "$message"
    fi
}

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

HARNESS="$TEST_TMP/signal-harness.sh"
cat > "$HARNESS" <<'HARNESS_EOF'
#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

REFERENCE_SCRIPT=$1
CASE_DIR=$2

# shellcheck source=/dev/null
source "$REFERENCE_SCRIPT"

LOCKFILE="$CASE_DIR/slack-update.lock"
QUEUE_FINAL="$CASE_DIR/queue-final.tmp"
BROKEN_NEW="$CASE_DIR/broken-new.tmp"
STILL_BROKEN="$CASE_DIR/still-broken.tmp"
BROKEN_ERRORS="$CASE_DIR/broken-errors.tmp"
ELF_LIBRARY_CACHE="$CASE_DIR/elf-cache.tmp"
RUNTIME_TMPDIR="$CASE_DIR/runtime"
GRUB_DIRECTORY="$CASE_DIR/grub"
GRUB_TEMP_CONFIG="$GRUB_DIRECTORY/.grub.cfg.slack-update.test"
GRUB_TEMP_DIRECTORY_CANONICAL="$GRUB_DIRECTORY"
GRUB_TEMP_CONFIG_OWNED=1
SBO_GENERATED_QUEUE_OWNED_PATH="$CASE_DIR/sbo-workspace"
SBO_GENERATED_QUEUE_OWNED_CANONICAL="$SBO_GENERATED_QUEUE_OWNED_PATH"

mkdir -p "$RUNTIME_TMPDIR" "$GRUB_DIRECTORY" "$SBO_GENERATED_QUEUE_OWNED_PATH"
printf 'temporary\n' > "$QUEUE_FINAL"
printf 'temporary\n' > "$BROKEN_NEW"
printf 'temporary\n' > "$STILL_BROKEN"
printf 'temporary\n' > "$BROKEN_ERRORS"
printf 'temporary\n' > "$ELF_LIBRARY_CACHE"
printf 'temporary\n' > "$GRUB_TEMP_CONFIG"
printf 'temporary\n' > "$SBO_GENERATED_QUEUE_OWNED_PATH/generated.sqf"
printf 'preserve\n' > "$CASE_DIR/unrelated-file"

acquire_instance_lock || exit $?
install_runtime_traps
printf 'ready\n' > "$CASE_DIR/ready"

while :; do
    :
done

printf 'continued\n' > "$CASE_DIR/continued"
HARNESS_EOF
chmod 0755 "$HARNESS"

run_signal_case() {
    local signal_name=$1
    local expected_status=$2
    local case_dir="$TEST_TMP/$signal_name"
    local observed_lock="$case_dir/lock-observed"
    local stderr_file="$case_dir/stderr"
    local checker_pid
    local status

    mkdir -p "$case_dir"

    (
        local attempt
        for attempt in $(seq 1 200); do
            if [ -f "$case_dir/ready" ]; then
                if flock -n "$case_dir/slack-update.lock" -c true; then
                    printf 'available\n' > "$observed_lock"
                else
                    printf 'held\n' > "$observed_lock"
                fi
                exit 0
            fi
            sleep 0.01
        done
        printf 'not-ready\n' > "$observed_lock"
    ) &
    checker_pid=$!

    timeout --preserve-status --signal="$signal_name" 0.4 \
        bash "$HARNESS" "$REFERENCE_SCRIPT" "$case_dir" \
        > "$case_dir/stdout" 2> "$stderr_file"
    status=$?
    wait "$checker_pid"

    assert_equal "$expected_status" "$status" \
        "SIG$signal_name should terminate with the conventional signal status"
    assert_equal held "$(cat "$observed_lock")" \
        "SIG$signal_name test should observe the instance lock while the process runs"
    assert_lock_available "$case_dir/slack-update.lock" \
        "SIG$signal_name should release the instance lock"
    assert_file_missing "$case_dir/queue-final.tmp" \
        "SIG$signal_name should remove the final queue temporary file"
    assert_file_missing "$case_dir/broken-new.tmp" \
        "SIG$signal_name should remove the new broken-object temporary file"
    assert_file_missing "$case_dir/still-broken.tmp" \
        "SIG$signal_name should remove the verification temporary file"
    assert_file_missing "$case_dir/broken-errors.tmp" \
        "SIG$signal_name should remove the broken-object diagnostics file"
    assert_file_missing "$case_dir/elf-cache.tmp" \
        "SIG$signal_name should remove the ELF cache temporary file"
    assert_file_missing "$case_dir/runtime" \
        "SIG$signal_name should remove the owned runtime directory"
    assert_file_missing "$case_dir/grub/.grub.cfg.slack-update.test" \
        "SIG$signal_name should discard the owned GRUB transaction file"
    assert_file_missing "$case_dir/sbo-workspace" \
        "SIG$signal_name should remove the owned SBo workspace"
    assert_file_exists "$case_dir/unrelated-file" \
        "SIG$signal_name cleanup should preserve unrelated files"
    assert_file_missing "$case_dir/continued" \
        "SIG$signal_name must not resume the interrupted workflow"
    assert_file_contains "Interrupted by SIG$signal_name" "$stderr_file" \
        "SIG$signal_name should produce an interruption diagnostic"
    assert_file_contains "status $expected_status" "$stderr_file" \
        "SIG$signal_name should report its terminating status"
}

run_signal_case HUP 129
run_signal_case INT 130
run_signal_case TERM 143

# Cleanup must remain safe when a signal arrives immediately after lock acquisition,
# before runtime paths have been initialized.
EARLY_HARNESS="$TEST_TMP/early-signal-harness.sh"
cat > "$EARLY_HARNESS" <<'EARLY_EOF'
#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

REFERENCE_SCRIPT=$1
CASE_DIR=$2

# shellcheck source=/dev/null
source "$REFERENCE_SCRIPT"
LOCKFILE="$CASE_DIR/slack-update.lock"
acquire_instance_lock || exit $?
install_runtime_traps
printf 'ready\n' > "$CASE_DIR/ready"
while :; do
    :
done
EARLY_EOF
chmod 0755 "$EARLY_HARNESS"

EARLY_CASE="$TEST_TMP/early"
mkdir -p "$EARLY_CASE"
timeout --preserve-status --signal=TERM 0.3 \
    bash "$EARLY_HARNESS" "$REFERENCE_SCRIPT" "$EARLY_CASE" \
    > "$EARLY_CASE/stdout" 2> "$EARLY_CASE/stderr"
early_status=$?
assert_equal 143 "$early_status" \
    'SIGTERM before runtime initialization should terminate with status 143'
assert_lock_available "$EARLY_CASE/slack-update.lock" \
    'early SIGTERM should release the instance lock'
assert_file_contains 'Interrupted by SIGTERM' "$EARLY_CASE/stderr" \
    'early SIGTERM should still produce an interruption diagnostic'

# Source-level guards keep trap installation between lock acquisition and runtime setup.
main_start=$(grep -n '^main() {' "$REFERENCE_SCRIPT" | cut -d: -f1)
main_end=$(grep -n '^if \[ "${BASH_SOURCE\[0\]}" = "\$0" \]; then' "$REFERENCE_SCRIPT" | cut -d: -f1)
main_source=$(sed -n "${main_start},${main_end}p" "$REFERENCE_SCRIPT")
acquire_line=$(printf '%s\n' "$main_source" | grep -n 'acquire_instance_lock' | head -n1 | cut -d: -f1)
trap_line=$(printf '%s\n' "$main_source" | grep -n 'install_runtime_traps' | head -n1 | cut -d: -f1)
runtime_line=$(printf '%s\n' "$main_source" | grep -n 'initialize_dry_run_runtime' | head -n1 | cut -d: -f1)

if [ "$acquire_line" -lt "$trap_line" ] && [ "$trap_line" -lt "$runtime_line" ]; then
    pass
else
    fail 'main should install runtime traps immediately after lock acquisition and before runtime setup'
fi

assert_file_contains "trap 'handle_interruption_signal HUP 1' HUP" "$REFERENCE_SCRIPT" \
    'SIGHUP should use the terminating interruption handler'
assert_file_contains "trap 'handle_interruption_signal INT 2' INT" "$REFERENCE_SCRIPT" \
    'SIGINT should use the terminating interruption handler'
assert_file_contains "trap 'handle_interruption_signal TERM 15' TERM" "$REFERENCE_SCRIPT" \
    'SIGTERM should use the terminating interruption handler'
assert_file_contains 'trap - EXIT HUP INT TERM' "$REFERENCE_SCRIPT" \
    'the signal handler should disable traps before cleanup and exit'
assert_file_not_contains 'trap cleanup EXIT INT TERM HUP' "$REFERENCE_SCRIPT" \
    'signals must not share a non-terminating cleanup-only trap'
assert_file_contains 'release_instance_lock' "$REFERENCE_SCRIPT" \
    'cleanup should use the explicit lock-release helper'
assert_file_contains 'exec 9>&-' "$REFERENCE_SCRIPT" \
    'lock release should close the lock descriptor'

if [ "$FAILURE_COUNT" -ne 0 ]; then
    printf 'FAILED: %d of %d signal-cleanup checks failed\n' \
        "$FAILURE_COUNT" "$TEST_COUNT" >&2
    exit 1
fi

printf 'PASS: %d signal-cleanup checks\n' "$TEST_COUNT"
