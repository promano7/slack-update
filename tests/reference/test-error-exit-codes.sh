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

assert_nonzero() {
    local actual=$1
    local message=$2

    if [ "$actual" -ne 0 ]; then
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

assert_failure() {
    local message=$1
    shift
    local status

    "$@"
    status=$?
    if [ "$status" -ne 0 ]; then
        pass
    else
        fail "$message"
    fi
}

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

assert_equal 0 "$EXIT_SUCCESS" 'success exit code should remain stable'
assert_equal 1 "$EXIT_GENERAL_FAILURE" 'general-failure exit code should remain stable'
assert_equal 2 "$EXIT_PARTIAL" 'partial-result exit code should remain stable'
assert_equal 3 "$EXIT_BOOT_UNSAFE" 'boot-unsafe exit code should remain stable'
assert_equal 4 "$EXIT_REBOOT_RECOMMENDED" 'reboot-recommended exit code should remain stable'
assert_equal 5 "$EXIT_REBOOT_REQUIRED" 'reboot-required exit code should remain stable'
assert_equal 6 "$EXIT_ALREADY_RUNNING" 'already-running exit code should remain stable'
assert_equal 7 "$EXIT_INVALID_INPUT" 'invalid-input exit code should remain stable'
assert_equal 8 "$EXIT_PRIVILEGE_UNAVAILABLE" 'privilege-unavailable exit code should remain stable'

prepare_result_state() {
    local operation=$1

    initialize_runtime_state >/dev/null
    OPERATION=$operation
    FLATPAK_MODE=disabled
    SBO_MODE=disabled
    ELF_MODE=disabled
    CINNAMON_MODE=disabled
    BOOT_MODE=disabled
    FLATPAK_MODULE_STATE=disabled
    FLATPAK_MODULE_REASON=
    SBO_MODULE_STATE=disabled
    SBO_MODULE_REASON=
    ELF_MODULE_STATE=disabled
    ELF_MODULE_REASON=
    CINNAMON_MODULE_STATE=disabled
    CINNAMON_MODULE_REASON=
    BOOT_MODULE_STATE=disabled
    BOOT_MODULE_REASON=
    PACKAGE_SNAPSHOT_BEFORE_VALID=1
    PACKAGE_SNAPSHOT_AFTER_VALID=1
    SLACKPKG_UPDATE_STATUS=0
    SLACKPKG_INSTALL_NEW_STATUS=0
    SLACKPKG_UPGRADE_ALL_STATUS=0
    CHECK_STATUS=0
    BROKEN="$TEST_TMP/result-broken"
    : > "$BROKEN"
}

run_result_case() {
    local scenario=$1
    local expected=$2
    local operation=apply
    local workflow_result=0

    case "$scenario" in
        check_success|check_failure) operation=check ;;
        dry_run_*) operation=dry-run ;;
    esac

    prepare_result_state "$operation"

    case "$scenario" in
        check_success|apply_success)
            ;;
        apply_no_packages)
            SLACKPKG_INSTALL_NEW_STATUS=20
            SLACKPKG_UPGRADE_ALL_STATUS=20
            ;;
        check_failure|dry_run_check_failure)
            CHECK_STATUS=42
            workflow_result=1
            ;;
        dry_run_workflow_failure|apply_workflow_failure)
            workflow_result=1
            ;;
        dry_run_enabled_module_unavailable|apply_enabled_flatpak_unavailable)
            FLATPAK_MODE=enabled
            FLATPAK_MODULE_STATE=unavailable
            FLATPAK_MODULE_REASON='required command is unavailable'
            ;;
        dry_run_target_selection_failure|apply_target_selection_failure)
            SBO_TARGET_SELECTION_STATUS=1
            SBO_TARGET_SELECTION_ERROR='invalid queue target'
            ;;
        apply_snapshot_before_failure)
            PACKAGE_SNAPSHOT_BEFORE_VALID=0
            PACKAGE_SNAPSHOT_BEFORE_ERROR='invalid baseline snapshot'
            ;;
        apply_snapshot_after_failure)
            PACKAGE_SNAPSHOT_AFTER_VALID=0
            PACKAGE_SNAPSHOT_AFTER_ERROR='invalid final snapshot'
            ;;
        apply_update_failure)
            SLACKPKG_UPDATE_STATUS=10
            ;;
        apply_install_new_failure)
            SLACKPKG_INSTALL_NEW_STATUS=11
            ;;
        apply_upgrade_all_failure)
            SLACKPKG_UPGRADE_ALL_STATUS=12
            ;;
        apply_flatpak_failure)
            FLATPAK_STATUS=13
            ;;
        apply_sbopkg_sync_failure)
            SBOPKG_SYNC_STATUS=14
            ;;
        apply_sqg_failure)
            SQG_SYNC_STATUS=15
            ;;
        apply_sbo_build_failure)
            SBO_BUILD_STATUS=16
            ;;
        apply_cinnamon_failure)
            CINNAMON_TRIGGER=3
            ;;
        apply_enabled_sbo_unavailable)
            SBO_MODE=enabled
            SBO_MODULE_STATE=unavailable
            SBO_MODULE_REASON='sbopkg is unavailable'
            ;;
        apply_enabled_elf_unavailable)
            ELF_MODE=enabled
            ELF_MODULE_STATE=unavailable
            ELF_MODULE_REASON='readelf is unavailable'
            ;;
        apply_enabled_cinnamon_unavailable)
            CINNAMON_MODE=enabled
            CINNAMON_MODULE_STATE=unavailable
            CINNAMON_MODULE_REASON='Cinnamon builder is unavailable'
            ;;
        apply_enabled_boot_unavailable)
            BOOT_MODE=enabled
            BOOT_MODULE_STATE=unavailable
            BOOT_MODULE_REASON='boot tools are unavailable'
            ;;
        apply_initrd_failure)
            INITRD_REQUIRED=1
            INITRD_UPDATE=1
            INITRD_OK=0
            INITRD_VALIDATION_ERROR='installed kernel validation failed'
            workflow_result=1
            ;;
        apply_grub_blocked)
            GRUB_REQUIRED=1
            GRUB_UPDATE=1
            GRUB_OK=0
            GRUB_BLOCKED_BY_INITRD=1
            GRUB_BLOCK_REASON='initrd preparation failed'
            workflow_result=1
            ;;
        apply_grub_failure)
            GRUB_REQUIRED=1
            GRUB_UPDATE=1
            GRUB_OK=0
            GRUB_VALIDATION_ERROR='staged configuration is invalid'
            workflow_result=1
            ;;
        apply_broken_elf)
            ELF_MODULE_RUN=1
            printf '/usr/bin/broken\n' > "$BROKEN"
            ;;
        apply_reboot_recommended)
            CRITICAL_UPDATED=(glibc)
            ;;
        apply_reboot_required)
            INITRD_REQUIRED=1
            INITRD_UPDATE=1
            INITRD_OK=1
            ;;
        *)
            fail "unknown result scenario: $scenario"
            return
            ;;
    esac

    determine_stable_exit_code "$workflow_result"
    assert_equal "$expected" "$STABLE_EXIT_CODE" \
        "$scenario should map to the expected stable exit code"

    case "$scenario" in
        check_success|apply_success|apply_no_packages)
            assert_equal 1 "$RESULT_SUCCESS" "$scenario should remain successful"
            ;;
        apply_reboot_recommended|apply_reboot_required)
            assert_equal 1 "$RESULT_SUCCESS" \
                "$scenario should be a successful non-zero result"
            assert_nonzero "$STABLE_EXIT_CODE" \
                "$scenario should preserve its successful non-zero reboot status"
            ;;
        *)
            assert_equal 0 "$RESULT_SUCCESS" "$scenario should be marked unsuccessful"
            assert_nonzero "$STABLE_EXIT_CODE" \
                "$scenario should never collapse an error to exit code zero"
            ;;
    esac
}

run_result_case check_success 0
run_result_case apply_success 0
run_result_case apply_no_packages 0
run_result_case check_failure 1
run_result_case dry_run_check_failure 1
run_result_case dry_run_workflow_failure 1
run_result_case dry_run_enabled_module_unavailable 1
run_result_case dry_run_target_selection_failure 1
run_result_case apply_workflow_failure 2
run_result_case apply_snapshot_before_failure 2
run_result_case apply_snapshot_after_failure 2
run_result_case apply_update_failure 2
run_result_case apply_install_new_failure 2
run_result_case apply_upgrade_all_failure 2
run_result_case apply_flatpak_failure 2
run_result_case apply_sbopkg_sync_failure 2
run_result_case apply_sqg_failure 2
run_result_case apply_target_selection_failure 2
run_result_case apply_sbo_build_failure 2
run_result_case apply_cinnamon_failure 2
run_result_case apply_enabled_flatpak_unavailable 2
run_result_case apply_enabled_sbo_unavailable 2
run_result_case apply_enabled_elf_unavailable 2
run_result_case apply_enabled_cinnamon_unavailable 2
run_result_case apply_enabled_boot_unavailable 2
run_result_case apply_initrd_failure 3
run_result_case apply_grub_blocked 3
run_result_case apply_grub_failure 3
run_result_case apply_broken_elf 2
run_result_case apply_reboot_recommended 4
run_result_case apply_reboot_required 5

# Runtime setup failures must be observable before an operation starts.
date() { return 1; }
assert_failure 'runtime timestamp failure should return non-zero' \
    initialize_runtime_state 2> "$TEST_TMP/runtime-time.stderr"
unset -f date
assert_file_contains 'cannot record the runtime start time' \
    "$TEST_TMP/runtime-time.stderr" \
    'runtime timestamp failure should produce a diagnostic'

RUNTIME_FAILURE_ROOT="$TEST_TMP/runtime-parent"
printf 'not a directory\n' > "$RUNTIME_FAILURE_ROOT"
WORKDIR_CONFIG="$RUNTIME_FAILURE_ROOT/work"
LOGDIR_CONFIG="$TEST_TMP/logs"
CSB_DIR_CONFIG="$TEST_TMP/csb"
assert_failure 'runtime directory creation failure should return non-zero' \
    initialize_runtime 2> "$TEST_TMP/runtime-directory.stderr"
assert_file_contains 'cannot create runtime directories' \
    "$TEST_TMP/runtime-directory.stderr" \
    'runtime directory failure should produce a diagnostic'

WORKDIR_CONFIG="$TEST_TMP/work"
LOGDIR_CONFIG="$TEST_TMP/logs"
mkdir -p "$WORKDIR_CONFIG" "$LOGDIR_CONFIG"
mktemp() { return 1; }
assert_failure 'runtime temporary-file creation failure should return non-zero' \
    initialize_runtime 2> "$TEST_TMP/runtime-temporary.stderr"
assert_failure 'dry-run workspace creation failure should return non-zero' \
    initialize_dry_run_runtime 2> "$TEST_TMP/dry-run-workspace.stderr"
unset -f mktemp
assert_file_contains 'cannot create the final queue temporary file' \
    "$TEST_TMP/runtime-temporary.stderr" \
    'runtime temporary-file failure should produce a diagnostic'
assert_file_contains 'cannot create the private dry-run workspace' \
    "$TEST_TMP/dry-run-workspace.stderr" \
    'dry-run workspace failure should produce a diagnostic'

LOG="$RUNTIME_FAILURE_ROOT/run.log"
JSON_OUTPUT=0
EVENTS_OUTPUT=0
assert_failure 'unwritable logging path should return non-zero' \
    configure_logging 2> "$TEST_TMP/logging.stderr"
assert_file_contains 'cannot open the runtime log for writing' \
    "$TEST_TMP/logging.stderr" \
    'logging setup failure should produce a diagnostic'

MAIN_HARNESS="$TEST_TMP/main-harness.sh"
cat > "$MAIN_HARNESS" <<'HARNESS_EOF'
#!/bin/bash

set -uo pipefail
IFS=$'\n\t'

REFERENCE_SCRIPT=$1
SCENARIO=$2
CASE_DIR=$3
shift 3

# shellcheck source=/dev/null
source "$REFERENCE_SCRIPT"

date() {
    case "$SCENARIO" in
        *completion_time_failure)
            if [ -e "$CASE_DIR/date-called" ]; then
                return 1
            fi
            mkdir -p "$CASE_DIR"
            : > "$CASE_DIR/date-called"
            ;;
    esac
    command date "$@"
}

load_configuration() {
    if [ "$SCENARIO" = config_failure ]; then
        return 1
    fi

    CONFIG_FILE="$CASE_DIR/config"
    WORKDIR_CONFIG="$CASE_DIR/work"
    LOGDIR_CONFIG="$CASE_DIR/log"
    LOCKFILE="$CASE_DIR/lock"
    LOG_RETENTION_DAYS=30
    CSB_DIR_CONFIG="$CASE_DIR/csb"
    FLATPAK_MODE=disabled
    SBO_MODE=disabled
    ELF_MODE=disabled
    CINNAMON_MODE=disabled
    BOOT_MODE=disabled
    return 0
}

require_root() {
    [ "$SCENARIO" != privilege_failure ] || return "$EXIT_PRIVILEGE_UNAVAILABLE"
}

acquire_instance_lock() {
    case "$SCENARIO" in
        lock_failure) return "$EXIT_GENERAL_FAILURE" ;;
        already_running) return "$EXIT_ALREADY_RUNNING" ;;
    esac
    INSTANCE_LOCK_HELD=0
    return 0
}

install_runtime_traps() { :; }
rotate_logs() { :; }
cleanup() { :; }

initialize_harness_state() {
    initialize_runtime_state || return 1
    mkdir -p "$CASE_DIR"
    BROKEN="$CASE_DIR/broken"
    : > "$BROKEN"
    FLATPAK_MODULE_STATE=disabled
    FLATPAK_MODULE_REASON=
    SBO_MODULE_STATE=disabled
    SBO_MODULE_REASON=
    ELF_MODULE_STATE=disabled
    ELF_MODULE_REASON=
    CINNAMON_MODULE_STATE=disabled
    CINNAMON_MODULE_REASON=
    BOOT_MODULE_STATE=disabled
    BOOT_MODULE_REASON=
    PACKAGE_SNAPSHOT_BEFORE_VALID=1
    PACKAGE_SNAPSHOT_AFTER_VALID=1
    SLACKPKG_UPDATE_STATUS=0
    SLACKPKG_INSTALL_NEW_STATUS=0
    SLACKPKG_UPGRADE_ALL_STATUS=0
}

initialize_runtime() {
    [ "$SCENARIO" != runtime_failure ] || return 1
    initialize_harness_state
}

initialize_dry_run_runtime() {
    [ "$SCENARIO" != runtime_failure ] || return 1
    initialize_harness_state
}

configure_logging() {
    [ "$SCENARIO" != logging_failure ] || return 1
    if [ "$JSON_OUTPUT" -eq 1 ] || [ "$EVENTS_OUTPUT" -eq 1 ]; then
        exec 3>&1
    fi
}

print_start_banner() { :; }
print_stable_exit_code_summary() { :; }
emit_operation_started_event() { :; }
emit_module_started_event() { :; }
emit_module_completed_event() { :; }
emit_action_started_event() { :; }
emit_action_completed_event() { :; }

print_json_result() {
    local exit_code=$1
    printf '{"exit_code":%d,"success":%s}\n' \
        "$exit_code" "$([ "$RESULT_SUCCESS" -eq 1 ] && printf true || printf false)"
}

run_check_workflow() {
    if [ "$SCENARIO" = check_failure ]; then
        CHECK_STATUS=42
        return 1
    fi
    CHECK_STATUS=0
    return 0
}

run_dry_run_workflow() {
    if [ "$SCENARIO" = dry_run_failure ]; then
        CHECK_STATUS=42
        return 1
    fi
    CHECK_STATUS=0
    return 0
}

run_apply_workflow() {
    case "$SCENARIO" in
        apply_partial)
            SLACKPKG_UPDATE_STATUS=42
            return 1
            ;;
        boot_unsafe)
            INITRD_REQUIRED=1
            INITRD_UPDATE=1
            INITRD_OK=0
            INITRD_VALIDATION_ERROR='mock initrd failure'
            return 1
            ;;
        reboot_recommended)
            CRITICAL_UPDATED=(glibc)
            ;;
        reboot_required)
            INITRD_REQUIRED=1
            INITRD_UPDATE=1
            INITRD_OK=1
            ;;
    esac
    return 0
}

main "$@"
HARNESS_EOF
chmod 0755 "$MAIN_HARNESS"

run_main_case() {
    local scenario=$1
    local expected=$2
    local output=$3
    shift 3
    local status

    bash "$MAIN_HARNESS" "$REFERENCE_SCRIPT" "$scenario" "$TEST_TMP/main-$scenario" \
        "$@" > "$output" 2>&1
    status=$?
    assert_equal "$expected" "$status" \
        "$scenario should leave main with the expected process status"
}

run_main_case success 0 "$TEST_TMP/main-success.out" --check
run_main_case check_failure 1 "$TEST_TMP/main-check-failure.out" --check
run_main_case apply_partial 2 "$TEST_TMP/main-partial.out" --apply
run_main_case boot_unsafe 3 "$TEST_TMP/main-boot-unsafe.out" --apply
run_main_case reboot_recommended 4 "$TEST_TMP/main-reboot-recommended.out" --apply
run_main_case reboot_required 5 "$TEST_TMP/main-reboot-required.out" --apply
run_main_case already_running 6 "$TEST_TMP/main-already-running.out" --check
run_main_case success 7 "$TEST_TMP/main-invalid-argument.out" --unknown
run_main_case config_failure 7 "$TEST_TMP/main-config-failure.out" --check
run_main_case privilege_failure 8 "$TEST_TMP/main-privilege-failure.out" --check
run_main_case lock_failure 1 "$TEST_TMP/main-lock-failure.out" --check
run_main_case runtime_failure 1 "$TEST_TMP/main-runtime-failure.out" --check
run_main_case runtime_failure 1 "$TEST_TMP/main-dry-runtime-failure.out" --dry-run
run_main_case logging_failure 1 "$TEST_TMP/main-logging-failure.out" --check
run_main_case completion_time_failure 1 \
    "$TEST_TMP/main-completion-time-failure.out" --check
run_main_case apply_completion_time_failure 2 \
    "$TEST_TMP/main-apply-completion-time-failure.out" --apply
run_main_case apply_partial 2 "$TEST_TMP/main-partial-json.out" --apply --json
run_main_case check_failure 1 "$TEST_TMP/main-check-events.out" --check --events

assert_file_contains '"exit_code":2' "$TEST_TMP/main-partial-json.out" \
    'JSON output should expose the same non-zero process result'
assert_file_contains '"success":false' "$TEST_TMP/main-partial-json.out" \
    'JSON output should mark the partial apply as unsuccessful'
assert_file_contains '"type":"operation_completed"' "$TEST_TMP/main-check-events.out" \
    'event output should end with an operation-completed record'
assert_file_contains '"exit_code":1' "$TEST_TMP/main-check-events.out" \
    'the final event should expose the same non-zero process result'
assert_file_contains 'cannot record the runtime completion time' \
    "$TEST_TMP/main-completion-time-failure.out" \
    'completion timestamp failure should produce a diagnostic'
assert_file_contains 'cannot record the runtime completion time' \
    "$TEST_TMP/main-apply-completion-time-failure.out" \
    'apply completion timestamp failure should produce a diagnostic'

main_start=$(grep -n '^main() {' "$REFERENCE_SCRIPT" | cut -d: -f1)
main_end=$(grep -n '^if \[ "${BASH_SOURCE\[0\]}" = "\$0" \]; then' "$REFERENCE_SCRIPT" | cut -d: -f1)
main_source=$(sed -n "${main_start},${main_end}p" "$REFERENCE_SCRIPT")

if printf '%s\n' "$main_source" | grep -Fq 'if ! initialize_dry_run_runtime; then'; then
    pass
else
    fail 'main should reject dry-run initialization failures'
fi
if printf '%s\n' "$main_source" | grep -Fq 'elif ! initialize_runtime; then'; then
    pass
else
    fail 'main should reject apply and check initialization failures'
fi
if printf '%s\n' "$main_source" | grep -Fq 'if ! configure_logging; then'; then
    pass
else
    fail 'main should reject logging initialization failures'
fi
assert_file_contains 'return "$EXIT_GENERAL_FAILURE"' "$REFERENCE_SCRIPT" \
    'runtime and logging setup failures should use the stable general-failure code'

if [ "$FAILURE_COUNT" -ne 0 ]; then
    printf 'FAILED: %d of %d error-exit checks failed\n' \
        "$FAILURE_COUNT" "$TEST_COUNT" >&2
    exit 1
fi

printf 'PASS: %d error-exit checks\n' "$TEST_COUNT"
