#!/usr/bin/env python3
"""Check boot orchestration with supplied initrd/GRUB operations and event callbacks."""

from pathlib import Path
import itertools
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
DRIVER = r'''
source "$1"
TRACE=$2
trace() { printf '%s\0' "$@" >> "$TRACE"; printf '\n' >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
emit_module_started_event() { trace module-started "$@"; return "$AUX_RETURN"; }
emit_action_started_event() { trace action-started "$@"; return "$AUX_RETURN"; }
emit_action_completed_event() { trace action-completed "$@"; return "$AUX_RETURN"; }
emit_module_completed_event() { trace module-completed "$@"; return "$AUX_RETURN"; }
regenerate_initrd() { trace initrd "$@"; INITRD_OK=$INITRD_RESULT; return "$OP_RETURN"; }
grub_initrd_prerequisite_is_satisfied() {
    trace prerequisite "$@"
    if [[ $PREREQUISITE == 0 ]]; then
        GRUB_BLOCKED_BY_INITRD=1
        GRUB_BLOCK_REASON='supplied prerequisite rejection'
        return 23
    fi
    return 0
}
update_grub_configuration() {
    trace grub "$@"
    GRUB_COMMAND_ATTEMPTED=1
    GRUB_OK=$GRUB_RESULT
    return "$OP_RETURN"
}
'''
FORBIDDEN = (
    "main", "initialize_execution_environment", "initialize_runtime", "initialize_runtime_state",
    "load_configuration", "run_check_workflow", "run_dry_run_workflow", "run_apply_workflow",
    "probe_boot_module", "apply_boot_module_policy", "validate_initrd_kernel_configuration",
    "validate_generated_initrd_transition_state", "prepare_grub_transaction", "install_validated_grub_config",
    "print_json_result", "emit_event", "slackpkg", "flatpak", "sbopkg", "sqg", "mkinitrd",
    "geninitrd", "grub-mkconfig", "grub-script-check", "git", "curl", "wget", "find", "rm", "mv", "mktemp",
)
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)
FIELDS = ("GRUB_COMMAND_ATTEMPTED", "GRUB_BLOCKED_BY_INITRD", "GRUB_BLOCK_REASON", "INITRD_OK", "GRUB_OK",
          "INITRD_REQUIRED", "GRUB_REQUIRED", "INITRD_UPDATE", "GRUB_UPDATE", "BOOT_MODE", "BOOT_MODULE_RUN",
          "BOOT_MODULE_STATE", "BOOT_MODULE_REASON", "boot_state", "action_exit")


def cases():
    for mode, run, idle, required, updates, results, prerequisite in itertools.product(
            ("auto", "enabled", "disabled"), (0, 1), ("available", "unavailable", "blocked"),
            itertools.product((0, 1), repeat=2), itertools.product((0, 1), repeat=2),
            itertools.product((0, 1), repeat=2), (0, 1)):
        yield dict(BOOT_MODE=mode, BOOT_MODULE_RUN=run, BOOT_MODULE_STATE=idle,
                   BOOT_MODULE_REASON="supplied reason: with spaces", INITRD_REQUIRED=required[0],
                   GRUB_REQUIRED=required[1], INITRD_UPDATE=updates[0], GRUB_UPDATE=updates[1],
                   INITRD_RESULT=results[0], GRUB_RESULT=results[1], PREREQUISITE=prerequisite)


def expected(c):
    # This oracle describes the current coordinator projection, including authored inconsistent flags.
    initial = "skipped"
    if c["INITRD_REQUIRED"] or c["GRUB_REQUIRED"]:
        initial = "disabled" if c["BOOT_MODE"] == "disabled" else c["BOOT_MODULE_STATE"] if not c["BOOT_MODULE_RUN"] else "skipped"
    initrd_states = {"unneeded": initial, "inapplicable": initial, "success": "success", "failed": "failed"}
    initrd_kind = "unneeded" if not c["INITRD_REQUIRED"] else "inapplicable" if not c["INITRD_UPDATE"] else "success" if c["INITRD_RESULT"] else "failed"
    state = initrd_states[initrd_kind]
    initrd_report = {
        "unneeded": ("skipped", "initrd regeneration was not required", 0),
        "inapplicable": (state, "initrd regeneration was not applicable: mode=" + c["BOOT_MODE"] + ", " + c["BOOT_MODULE_REASON"], 0),
        "success": ("success", "initrd regeneration completed", 0),
        "failed": ("failed", "initrd regeneration failed", 1),
    }[initrd_kind]
    rows = [("module-started", "boot", "Boot preparation module started"),
            ("action-started", "boot", "regenerate_initrd", "Regenerating initrd when required"), ("initrd",),
            ("action-completed", "boot", "regenerate_initrd", *initrd_report)]
    values = {key: str(c[key]) for key in FIELDS if key in c}
    values.update(GRUB_COMMAND_ATTEMPTED="0", GRUB_BLOCKED_BY_INITRD="0", GRUB_BLOCK_REASON="",
                  INITRD_OK=str(c["INITRD_RESULT"]), GRUB_OK="9", boot_state="outer-boot", action_exit="outer-action")
    if not c["GRUB_REQUIRED"]:
        rows.append(("action-completed", "boot", "update_grub", "skipped", "GRUB configuration update was not required", 0))
    elif not c["GRUB_UPDATE"]:
        rows.append(("action-completed", "boot", "update_grub", state,
                     "GRUB configuration update was not applicable: mode=" + c["BOOT_MODE"] + ", " + c["BOOT_MODULE_REASON"], 0))
    else:
        rows.append(("prerequisite",))
        if not c["PREREQUISITE"]:
            state = "failed"
            values.update(GRUB_BLOCKED_BY_INITRD="1", GRUB_BLOCK_REASON="supplied prerequisite rejection")
            rows.append(("action-completed", "boot", "update_grub", "blocked", "GRUB configuration update was blocked: supplied prerequisite rejection", 1))
        else:
            rows.extend((("action-started", "boot", "update_grub", "Updating GRUB configuration when required"), ("grub",)))
            values.update(GRUB_COMMAND_ATTEMPTED="1", GRUB_OK=str(c["GRUB_RESULT"]))
            outcome = ("failed", "GRUB configuration update failed", 1)
            if c["GRUB_RESULT"]:
                outcome = ("success", "GRUB configuration update completed", 0)
                state = "failed" if state == "failed" else "success"
            else:
                state = "failed"
            rows.append(("action-completed", "boot", "update_grub", *outcome))
    raw = int(state == "failed")
    rows.append(("module-completed", "boot", state, "Boot preparation module completed", raw))
    return raw, values, rows


def encode_rows(rows):
    return b"".join(b"".join(str(field).encode() + b"\0" for field in row) + b"\n" for row in rows)


def run_case(work, c):
    trace = work / "callback trace"
    trace.write_bytes(b"")
    initial = dict(c, GRUB_COMMAND_ATTEMPTED=9, GRUB_BLOCKED_BY_INITRD=9, GRUB_BLOCK_REASON="stale-block",
                   INITRD_OK=9, GRUB_OK=9, boot_state="outer-boot", action_exit="outer-action")
    reset = "\n".join(f"{key}={shlex.quote(str(value))}" for key, value in initial.items())
    output = 'printf \'%s\\0\' "$status" ' + " ".join(f'"${{{name}}}"' for name in FIELDS) + ' "$IFS"\n'
    script = DRIVER + GUARDS + "\nIFS='|: '\nfor repetition in 0 1; do\n" + reset + r'''
    if [[ $repetition == 0 ]]; then AUX_RETURN=0; OP_RETURN=19; else AUX_RETURN=19; OP_RETURN=0; fi
    run_boot_preparation_module
    status=$?
''' + output + "done\n"
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", script, "boot-workflow-test", str(REFERENCE), str(trace)],
                            capture_output=True, timeout=10)
    raw, values, rows = expected(c)
    packet = b"".join(str(field).encode() + b"\0" for field in (raw, *(values[name] for name in FIELDS), "|: "))
    assert result.returncode == 0, (c, "driver", result.returncode, result.stderr)
    assert result.stderr == b"", (c, "stderr", result.stderr)
    assert result.stdout == packet * 2, (c, "stdout", result.stdout, packet * 2)
    assert trace.read_bytes() == encode_rows(rows) * 2, (c, "trace", trace.read_bytes(), encode_rows(rows) * 2)
    assert sorted(p.name for p in work.iterdir()) == ["callback trace"], (c, "private inventory")


def main():
    count = 0
    with tempfile.TemporaryDirectory(prefix="slack-update boot workflow ") as temporary:
        work = Path(temporary)
        for case in cases():
            run_case(work, case)
            count += 1
    print(f"Boot preparation workflow tests: {count} scenarios, {count * 2} entries, 0 failures")


if __name__ == "__main__":
    main()
