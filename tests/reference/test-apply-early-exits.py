#!/usr/bin/env python3
"""Check real apply-prefix ordering with supplied operations and an early checkpoint."""

from pathlib import Path
import itertools
import shlex
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
MODULES = ("FLATPAK", "SBO", "ELF", "CINNAMON", "BOOT")
BLOCK_REASON = "Slackware package operations did not complete successfully"
PREFIX = r'''
source "$1"
TRACE=$2
trace() { printf '%s\0' "$@" >> "$TRACE"; printf '\n' >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
capture_package_snapshot_before() {
    [[ $# == 0 ]] || forbidden before-arguments
    trace before
    PACKAGE_SNAPSHOT_BEFORE_VALID=1; PACKAGE_SNAPSHOT_BEFORE_COUNT=3; PACKAGE_SNAPSHOT_BEFORE_ERROR=
    if [[ $BEFORE_RETURN != 0 ]]; then
        PACKAGE_SNAPSHOT_BEFORE_VALID=0; PACKAGE_SNAPSHOT_BEFORE_COUNT=0
        PACKAGE_SNAPSHOT_BEFORE_ERROR='supplied baseline failure'
    fi
    return "$BEFORE_RETURN"
}
probe_boot_module() { trace boot-probe "$@"; return "$AUX_RETURN"; }
prepare_geninitrd_grub_policy_override() {
    [[ $# == 0 ]] || forbidden ownership-arguments
    trace ownership
    GENINITRD_POLICY_OVERRIDE_STATUS=supplied-prepared; GENINITRD_POLICY_OVERRIDE_ERROR=
    if [[ $PREPARE_RETURN != 0 ]]; then
        GENINITRD_POLICY_OVERRIDE_STATUS=failed; GENINITRD_POLICY_OVERRIDE_ERROR='supplied ownership failure'
    fi
    return "$PREPARE_RETURN"
}
update_slackware_system() {
    [[ $# == 0 ]] || forbidden packages-arguments
    trace packages
    SLACKPKG_UPDATE_STATUS=$RAW_UPDATE
    SLACKPKG_INSTALL_NEW_STATUS=$RAW_INSTALL
    SLACKPKG_UPGRADE_ALL_STATUS=$RAW_UPGRADE
    return "$AUX_RETURN"
}
restore_geninitrd_grub_policy_override() {
    [[ $# == 0 ]] || forbidden restore-arguments
    trace restore
    GENINITRD_POLICY_OVERRIDE_STATUS=supplied-restored; GENINITRD_POLICY_OVERRIDE_ERROR=
    if [[ $RESTORE_RETURN != 0 ]]; then
        GENINITRD_POLICY_OVERRIDE_STATUS=failed; GENINITRD_POLICY_OVERRIDE_ERROR='supplied restoration failure'
    fi
    return "$RESTORE_RETURN"
}
capture_package_snapshot_after() {
    [[ $# == 0 ]] || forbidden after-arguments
    trace after
    PACKAGE_SNAPSHOT_AFTER_VALID=1; PACKAGE_SNAPSHOT_AFTER_COUNT=4; PACKAGE_SNAPSHOT_AFTER_ERROR=
    if [[ $AFTER_RETURN != 0 ]]; then
        PACKAGE_SNAPSHOT_AFTER_VALID=0; PACKAGE_SNAPSHOT_AFTER_COUNT=0
        PACKAGE_SNAPSHOT_AFTER_ERROR='supplied final snapshot failure'
    fi
    return "$AFTER_RETURN"
}
emit_module_started_event() { trace module-started "$@"; return "$AUX_RETURN"; }
emit_action_started_event() { trace action-started "$@"; return "$AUX_RETURN"; }
emit_action_completed_event() { trace action-completed "$@"; return "$AUX_RETURN"; }
emit_module_completed_event() { trace module-completed "$@"; return "$AUX_RETURN"; }
print_summary() {
    [[ $# == 0 ]] || forbidden summary-arguments
    trace summary "$slackware_state" "$action_exit" "$SECONDARY_MODULES_BLOCKED"
    return "$AUX_RETURN"
}
probe_optional_modules() {
    [[ $# == 0 ]] || forbidden continuation-arguments
    trace continuation "$slackware_state" "$action_exit"
    print_state checkpoint
    exit 86
}
'''
FORBIDDEN = (
    "main", "initialize_runtime", "initialize_runtime_state", "initialize_execution_environment",
    "load_configuration", "run_check_workflow", "run_dry_run_workflow", "capture_validated_package_snapshot",
    "stage_geninitrd_grub_policy_override", "read_geninitrd_policy_boolean", "geninitrd_policy_fingerprint",
    "print_optional_module_activation", "update_flatpak", "detect_abi_changes", "detect_kernel_changes",
    "synchronize_sbo_repository", "build_sbo_target_queues_after_synchronization", "detect_broken_elf_objects",
    "map_broken_objects_to_sbo_packages", "build_and_apply_sbo_queue", "rebuild_cinnamon", "run_boot_preparation_module",
    "slackpkg", "flatpak", "sbopkg", "sqg", "readelf", "mkinitrd", "grub-mkconfig", "git", "curl", "wget",
    "date", "find", "sort", "rm", "mv", "mktemp", "print_json_result", "emit_final_events",
)
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)


def cases():
    defaults = dict(BEFORE_RETURN=0, PREPARE_RETURN=0, RESTORE_RETURN=0, AFTER_RETURN=0,
                    RAW_UPDATE=0, RAW_INSTALL=0, RAW_UPGRADE=0)
    for gate in ("BEFORE_RETURN", "PREPARE_RETURN"):
        for raw in (1, 23, 255):
            yield defaults | {gate: raw}
    for update, install, upgrade, restore, after in itertools.product(
            (-1, 0, 20, 21, 42, 255), (-1, 0, 20, 21, 42, 255), (-1, 0, 20, 21, 42, 255), (0, 23), (0, 255)):
        yield defaults | dict(RAW_UPDATE=update, RAW_INSTALL=install, RAW_UPGRADE=upgrade,
                              RESTORE_RETURN=restore, AFTER_RETURN=after)


def initial_state():
    values = dict(PACKAGE_SNAPSHOT_BEFORE_VALID="7", PACKAGE_SNAPSHOT_BEFORE_COUNT="97",
                  PACKAGE_SNAPSHOT_BEFORE_ERROR="stale-before", PACKAGE_SNAPSHOT_AFTER_VALID="9",
                  PACKAGE_SNAPSHOT_AFTER_COUNT="98", PACKAGE_SNAPSHOT_AFTER_ERROR="stale-after",
                  GENINITRD_POLICY_OVERRIDE_STATUS="stale-policy", GENINITRD_POLICY_OVERRIDE_ERROR="stale-policy-error",
                  SLACKPKG_UPDATE_STATUS="91", SLACKPKG_INSTALL_NEW_STATUS="92", SLACKPKG_UPGRADE_ALL_STATUS="93",
                  SECONDARY_MODULES_BLOCKED="0", SECONDARY_MODULES_BLOCK_REASON="")
    for index, module in enumerate(MODULES):
        values.update({module + "_MODE": ("disabled", "enabled", "auto")[index % 3],
                       module + "_MODULE_STATE": "available", module + "_MODULE_REASON": "old " + module + " reason",
                       module + "_MODULE_RUN": "1"})
    return values


def expected(case):
    values = initial_state()
    rows = [("module-started", "slackware", "Slackware update module started"),
            ("action-started", "slackware", "snapshot_before", "Capturing package snapshot before update"), ("before",)]
    output = ""

    def end(state, raw, blocked=0):
        rows.append(("summary", state, raw, blocked))
        return output.encode(), rows, values, False

    if case["BEFORE_RETURN"]:
        values.update(PACKAGE_SNAPSHOT_BEFORE_VALID="0", PACKAGE_SNAPSHOT_BEFORE_COUNT="0",
                      PACKAGE_SNAPSHOT_BEFORE_ERROR="supplied baseline failure")
        output += "[ERROR] Cannot capture package snapshot before update: supplied baseline failure\n"
        rows += [("action-completed", "slackware", "snapshot_before", "failed",
                  "Package snapshot before update failed validation: supplied baseline failure", 1),
                 ("module-completed", "slackware", "failed",
                  "Slackware update stopped before package operations because the baseline snapshot is invalid", 1)]
        return end("failed", 0)
    values.update(PACKAGE_SNAPSHOT_BEFORE_VALID="1", PACKAGE_SNAPSHOT_BEFORE_COUNT="3", PACKAGE_SNAPSHOT_BEFORE_ERROR="")
    rows += [("action-completed", "slackware", "snapshot_before", "success",
              "Package snapshot before update captured and validated (3 records)", 0),
             ("action-started", "slackware", "geninitrd_grub_ownership",
              "Preparing exclusive GRUB ownership for the package transaction"), ("boot-probe",), ("ownership",)]
    if case["PREPARE_RETURN"]:
        values.update(GENINITRD_POLICY_OVERRIDE_STATUS="failed", GENINITRD_POLICY_OVERRIDE_ERROR="supplied ownership failure")
        output += "[ERROR] Cannot prepare GenInitrd GRUB ownership: supplied ownership failure\n"
        rows += [("action-completed", "slackware", "geninitrd_grub_ownership", "failed",
                  "GenInitrd GRUB ownership preparation failed: supplied ownership failure", 1),
                 ("module-completed", "slackware", "failed",
                  "Slackware update stopped before package operations because GRUB ownership is unsafe", 1)]
        return end("failed", 0)
    values.update(GENINITRD_POLICY_OVERRIDE_STATUS="supplied-prepared", GENINITRD_POLICY_OVERRIDE_ERROR="")
    rows += [("action-completed", "slackware", "geninitrd_grub_ownership", "success",
              "GenInitrd GRUB ownership state: supplied-prepared", 0),
             ("action-started", "slackware", "update_packages", "Applying Slackware package operations"), ("packages",)]
    codes = (case["RAW_UPDATE"], case["RAW_INSTALL"], case["RAW_UPGRADE"])
    # Authored ordered precedence table; no call to the implementation for expectations.
    raw = next((code for code, accepted in zip(codes, ((-1, 0), (-1, 0, 20), (-1, 0, 20))) if code not in accepted), 0)
    state = "failed" if raw else "success"
    values.update(SLACKPKG_UPDATE_STATUS=str(codes[0]), SLACKPKG_INSTALL_NEW_STATUS=str(codes[1]),
                  SLACKPKG_UPGRADE_ALL_STATUS=str(codes[2]))
    rows += [("action-completed", "slackware", "update_packages", state, "Slackware package operations completed", raw),
             ("action-started", "slackware", "restore_geninitrd_policy",
              "Restoring the original GenInitrd policy after package operations"), ("restore",)]
    if case["RESTORE_RETURN"]:
        state, raw = "failed", 1
        values.update(GENINITRD_POLICY_OVERRIDE_STATUS="failed", GENINITRD_POLICY_OVERRIDE_ERROR="supplied restoration failure")
        output += "[ERROR] Cannot restore the original GenInitrd policy: supplied restoration failure\n"
        rows += [("action-completed", "slackware", "restore_geninitrd_policy", "failed",
                  "GenInitrd policy restoration failed: supplied restoration failure", 1)]
    else:
        values.update(GENINITRD_POLICY_OVERRIDE_STATUS="supplied-restored", GENINITRD_POLICY_OVERRIDE_ERROR="")
        rows += [("action-completed", "slackware", "restore_geninitrd_policy", "success",
                  "GenInitrd policy restoration state: supplied-restored", 0)]
    rows += [("action-started", "slackware", "snapshot_after", "Capturing package snapshot after update"), ("after",)]
    if case["AFTER_RETURN"]:
        values.update(PACKAGE_SNAPSHOT_AFTER_VALID="0", PACKAGE_SNAPSHOT_AFTER_COUNT="0",
                      PACKAGE_SNAPSHOT_AFTER_ERROR="supplied final snapshot failure")
        output += "[ERROR] Cannot capture package snapshot after update: supplied final snapshot failure\n"
        rows += [("action-completed", "slackware", "snapshot_after", "failed",
                  "Package snapshot after update failed validation: supplied final snapshot failure", 1),
                 ("module-completed", "slackware", "failed",
                  "Slackware package operations completed but post-update package state could not be validated", 1)]
        return end("failed", 1)
    values.update(PACKAGE_SNAPSHOT_AFTER_VALID="1", PACKAGE_SNAPSHOT_AFTER_COUNT="4", PACKAGE_SNAPSHOT_AFTER_ERROR="")
    rows += [("action-completed", "slackware", "snapshot_after", "success",
              "Package snapshot after update captured and validated (4 records)", 0),
             ("module-completed", "slackware", state, "Slackware package operations completed", raw)]
    if raw:
        values.update(SECONDARY_MODULES_BLOCKED="1", SECONDARY_MODULES_BLOCK_REASON=BLOCK_REASON)
        for module in MODULES:
            values.update({module + "_MODULE_STATE": "blocked", module + "_MODULE_REASON": BLOCK_REASON,
                           module + "_MODULE_RUN": "0"})
        output += f"[ERROR] {BLOCK_REASON}; secondary modules were not started\n"
        return end(state, raw, 1)
    rows += [("continuation", state, raw)]
    return output.encode(), rows, values, True


def encoded(rows):
    return b"".join(b"".join(str(v).encode() + b"\0" for v in row) + b"\n" for row in rows)


def run_case(work, case):
    output, rows, values, checkpoint = expected(case)
    trace = work / "callback trace"
    fields = tuple(initial_state())
    state_function = "print_state() { printf '%s\\0' \"$1\" " + " ".join(f'"${{{name}}}"' for name in fields) + ' "$IFS"; }\n'
    for aux_return in (0, 19):
        trace.write_bytes(b"")
        settings = initial_state() | {name: str(value) for name, value in case.items()} | {"AUX_RETURN": str(aux_return)}
        assignments = "\n".join(f"{name}={shlex.quote(value)}" for name, value in settings.items())
        driver = PREFIX + GUARDS + "\n" + state_function + assignments + r'''
IFS='|: '
action_exit=777
slackware_state=outer-state
run_status=0
run_apply_workflow || run_status=$?
print_state "$run_status"
printf '%s\0' "$action_exit" "$slackware_state"
'''
        result = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "apply-early-exit-test",
                                 str(REFERENCE), str(trace)], cwd=work, capture_output=True, timeout=10)
        label = (case, aux_return)
        assert result.returncode == (86 if checkpoint else 0) and result.stderr == b"", (label, result.returncode, result.stderr)
        packet = output + b"".join(str(v).encode() + b"\0" for v in (
            "checkpoint" if checkpoint else "1", *values.values(), "|: "))
        if not checkpoint: packet += b"777\0outer-state\0"
        assert result.stdout == packet, (label, result.stdout, packet)
        assert trace.read_bytes() == encoded(rows), (label, trace.read_bytes(), rows)
        assert sorted(p.name for p in work.iterdir()) == ["callback trace"], label


def main():
    scenarios = list(cases())
    with tempfile.TemporaryDirectory(prefix="slack-update-apply-early-exits-") as directory:
        for index, case in enumerate(scenarios):
            work = Path(directory) / str(index)
            work.mkdir()
            run_case(work, case)
    print(f"Apply early exits: {len(scenarios)} scenarios, {2 * len(scenarios)} workflow entries, 0 failures")


if __name__ == "__main__":
    main()
