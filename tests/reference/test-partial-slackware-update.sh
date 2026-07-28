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

TEST_TMP=$(mktemp -d)
trap 'rm -rf "$TEST_TMP"' EXIT

prepare_workflow_state() {
    local scenario=$1

    initialize_runtime_state
    FLATPAK_MODE=auto
    SBO_MODE=auto
    ELF_MODE=auto
    CINNAMON_MODE=auto
    BOOT_MODE=auto
    SBO_QUEUE_DIR_FALLBACK="$TEST_TMP/queues"
    BROKEN="$TEST_TMP/$scenario.broken"
    QUEUE_CORE="$TEST_TMP/$scenario.queue-core"
    QUEUE_EXTRA="$TEST_TMP/$scenario.queue-extra"
    BEFORE_PKGS="$TEST_TMP/$scenario.before"
    AFTER_PKGS="$TEST_TMP/$scenario.after"
    : > "$BROKEN"
    : > "$QUEUE_CORE"
    : > "$QUEUE_EXTRA"
}

run_partial_scenario() {
    local failed_action=$1
    local failed_status=$2
    local scenario="partial-$failed_action"
    local after_marker="$TEST_TMP/$scenario-after"
    local secondary_marker="$TEST_TMP/$scenario-secondary"
    local event_log="$TEST_TMP/$scenario-events"
    local json_output="$TEST_TMP/$scenario-modules.json"

    prepare_workflow_state "$scenario"

    capture_package_snapshot_before() {
        PACKAGE_SNAPSHOT_BEFORE_VALID=1
        PACKAGE_SNAPSHOT_BEFORE_COUNT=3
        return 0
    }

    update_slackware_system() {
        SLACKPKG_UPDATE_STATUS=0
        SLACKPKG_INSTALL_NEW_STATUS=0
        SLACKPKG_UPGRADE_ALL_STATUS=0

        case "$failed_action" in
            update) SLACKPKG_UPDATE_STATUS=$failed_status ;;
            install-new) SLACKPKG_INSTALL_NEW_STATUS=$failed_status ;;
            upgrade-all) SLACKPKG_UPGRADE_ALL_STATUS=$failed_status ;;
        esac
    }

    capture_package_snapshot_after() {
        PACKAGE_SNAPSHOT_AFTER_VALID=1
        PACKAGE_SNAPSHOT_AFTER_COUNT=4
        : > "$after_marker"
        return 0
    }

    mark_secondary_call() {
        printf '%s\n' "$1" >> "$secondary_marker"
    }

    probe_optional_modules() { mark_secondary_call probe_optional_modules; }
    print_optional_module_activation() { mark_secondary_call print_optional_module_activation; }
    update_flatpak() { mark_secondary_call update_flatpak; }
    detect_abi_changes() { mark_secondary_call detect_abi_changes; }
    detect_kernel_changes() { mark_secondary_call detect_kernel_changes; }
    synchronize_sbo_repository() { mark_secondary_call synchronize_sbo_repository; }
    build_sbo_core_queue() { mark_secondary_call build_sbo_core_queue; }
    add_abi_rebuild_targets() { mark_secondary_call add_abi_rebuild_targets; }
    detect_broken_elf_objects() { mark_secondary_call detect_broken_elf_objects; }
    map_broken_objects_to_sbo_packages() { mark_secondary_call map_broken_objects_to_sbo_packages; }
    build_and_apply_sbo_queue() { mark_secondary_call build_and_apply_sbo_queue; }
    rebuild_cinnamon() { mark_secondary_call rebuild_cinnamon; }
    regenerate_initrd() { mark_secondary_call regenerate_initrd; }
    update_grub_configuration() { mark_secondary_call update_grub_configuration; }

    emit_module_started_event() {
        printf 'module_started:%s\n' "$1" >> "$event_log"
    }
    emit_action_started_event() {
        printf 'action_started:%s:%s\n' "$1" "$2" >> "$event_log"
    }
    emit_action_completed_event() {
        printf 'action_completed:%s:%s:%s\n' "$1" "$2" "$3" >> "$event_log"
    }
    emit_module_completed_event() {
        printf 'module_completed:%s:%s\n' "$1" "$2" >> "$event_log"
    }
    print_summary() { :; }

    if run_apply_workflow >/dev/null 2>&1; then
        fail "$failed_action failure should make apply workflow fail"
    else
        pass
    fi

    assert_file_exists "$after_marker" \
        "$failed_action failure should still capture the post-update snapshot"
    assert_file_missing "$secondary_marker" \
        "$failed_action failure should prevent every secondary module call"
    assert_equal 1 "$SECONDARY_MODULES_BLOCKED" \
        "$failed_action failure should set the secondary-module guard"
    assert_equal 'Slackware package operations did not complete successfully' \
        "$SECONDARY_MODULES_BLOCK_REASON" \
        "$failed_action failure should expose a stable blocking reason"
    assert_equal blocked "$FLATPAK_MODULE_STATE" \
        "$failed_action failure should mark Flatpak as blocked"
    assert_equal blocked "$SBO_MODULE_STATE" \
        "$failed_action failure should mark SBo as blocked"
    assert_equal blocked "$ELF_MODULE_STATE" \
        "$failed_action failure should mark ELF as blocked"
    assert_equal blocked "$CINNAMON_MODULE_STATE" \
        "$failed_action failure should mark Cinnamon as blocked"
    assert_equal blocked "$BOOT_MODULE_STATE" \
        "$failed_action failure should mark boot preparation as blocked"
    assert_file_contains 'module_started:slackware' "$event_log" \
        "$failed_action failure should emit the Slackware module start"
    assert_file_contains 'module_completed:slackware:failed' "$event_log" \
        "$failed_action failure should complete the Slackware module as failed"
    assert_file_not_contains 'module_started:flatpak' "$event_log" \
        "$failed_action failure should not emit a Flatpak module start"
    assert_file_not_contains 'module_started:sbo' "$event_log" \
        "$failed_action failure should not emit an SBo module start"
    assert_file_not_contains 'module_started:elf' "$event_log" \
        "$failed_action failure should not emit an ELF module start"
    assert_file_not_contains 'module_started:cinnamon' "$event_log" \
        "$failed_action failure should not emit a Cinnamon module start"
    assert_file_not_contains 'module_started:boot' "$event_log" \
        "$failed_action failure should not emit a boot module start"

    print_apply_json_modules > "$json_output"
    assert_file_contains '"secondary_modules_blocked": true' "$json_output" \
        "$failed_action failure should be represented in JSON"
    assert_file_contains '"state": "blocked"' "$json_output" \
        "$failed_action failure should expose blocked secondary module states in JSON"
    assert_file_contains '"initrd_state": "blocked"' "$json_output" \
        "$failed_action failure should expose blocked initrd state in JSON"
    assert_file_contains '"grub_state": "blocked"' "$json_output" \
        "$failed_action failure should expose blocked GRUB state in JSON"
}

run_partial_scenario update 10
run_partial_scenario install-new 20
run_partial_scenario upgrade-all 30

prepare_workflow_state success
SUCCESS_PROBE_MARKER="$TEST_TMP/success-probe"

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
    PACKAGE_SNAPSHOT_AFTER_VALID=1
    PACKAGE_SNAPSHOT_AFTER_COUNT=4
    return 0
}
probe_optional_modules() {
    : > "$SUCCESS_PROBE_MARKER"
    FLATPAK_MODULE_STATE=disabled
    SBO_MODULE_STATE=disabled
    ELF_MODULE_STATE=disabled
    CINNAMON_MODULE_STATE=disabled
    BOOT_MODULE_STATE=disabled
}
print_optional_module_activation() { :; }
detect_abi_changes() { :; }
detect_kernel_changes() { :; }
regenerate_initrd() { :; }
update_grub_configuration() { :; }
emit_module_started_event() { :; }
emit_action_started_event() { :; }
emit_action_completed_event() { :; }
emit_module_completed_event() { :; }
print_summary() { :; }

if run_apply_workflow >/dev/null 2>&1; then
    pass
else
    fail "successful Slackware operations should allow the apply workflow to continue"
fi
assert_file_exists "$SUCCESS_PROBE_MARKER" \
    "successful Slackware operations should reach secondary module probing"
assert_equal 0 "$SECONDARY_MODULES_BLOCKED" \
    "successful Slackware operations should not set the secondary-module guard"

printf 'Partial Slackware update tests: %d checks, %d failures\n' "$TEST_COUNT" "$FAILURE_COUNT"
[ "$FAILURE_COUNT" -eq 0 ]
