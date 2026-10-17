#!/usr/bin/env python3
"""Check current action classification and in-memory secondary-module blocking."""

from pathlib import Path
import itertools
import shlex
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
MODULES = ("FLATPAK", "SBO", "ELF", "CINNAMON", "BOOT")
NON_FAILURE = {"update": (-1, 0), "install-new": (-1, 0, 20), "upgrade-all": (-1, 0, 20)}
BLOCK_REASON = "Slackware package operations did not complete successfully"
FORBIDDEN = (
    "main", "initialize_runtime", "initialize_runtime_state", "initialize_execution_environment",
    "load_configuration", "probe_optional_modules", "probe_boot_module", "run_check_workflow",
    "run_dry_run_workflow", "run_apply_workflow", "capture_package_snapshot_before",
    "capture_package_snapshot_after", "update_slackware_system", "print_summary", "print_json_result",
    "emit_module_started_event", "emit_action_started_event", "emit_action_completed_event",
    "emit_module_completed_event", "slackpkg", "flatpak", "sbopkg", "sqg", "readelf", "mkinitrd",
    "grub-mkconfig", "git", "curl", "wget", "date", "find", "sort", "rm", "mv", "mktemp",
)
PREFIX = r'''
source "$1"
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
'''
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)


def classification_cases():
    for action, allowed in NON_FAILURE.items():
        for raw in range(-1, 256):
            yield action, str(raw), int(raw in allowed)
    for action, raw in itertools.product(("unknown", "", "install-new-extra", "update:other"), (-1, 0, 20)):
        yield action, str(raw), int(raw == -1)
    for action, raw in itertools.product(NON_FAILURE, ("00", "020", "-01", "+0", " 0", "0 ")):
        yield action, raw, 0


def initial_state(modes):
    values = dict(SECONDARY_MODULES_BLOCKED="99", SECONDARY_MODULES_BLOCK_REASON="stale blocking reason",
                  SLACKPKG_UPDATE_STATUS="0", SLACKPKG_INSTALL_NEW_STATUS="20", SLACKPKG_UPGRADE_ALL_STATUS="21",
                  PACKAGE_SNAPSHOT_BEFORE_VALID="1", PACKAGE_SNAPSHOT_BEFORE_COUNT="3",
                  PACKAGE_SNAPSHOT_AFTER_VALID="1", PACKAGE_SNAPSHOT_AFTER_COUNT="4",
                  SBO_TARGET_SELECTION_STATUS="17", SBO_OPTION_RECORD_COUNT="13", ELF_SCAN_STATUS="19",
                  FLATPAK_STATUS="23", CINNAMON_TRIGGER="3", KERNEL_TRIGGER="1",
                  SBO_SBOPKG_AVAILABLE="1", SBO_SQG_AVAILABLE="0", ELF_READELF_AVAILABLE="1",
                  ELF_LDCONFIG_AVAILABLE="0", CINNAMON_INSTALLED="1", BOOT_INITRD_AVAILABLE="1",
                  BOOT_GRUB_AVAILABLE="0", action="outer action", status="outer status")
    for index, (module, mode) in enumerate(zip(MODULES, modes)):
        values.update({module + "_MODE": mode,
                       module + "_MODULE_STATE": ("available", "unavailable", "disabled")[index % 3],
                       module + "_MODULE_REASON": "original " + module + " reason",
                       module + "_MODULE_RUN": str(index % 2)})
    return values


def run_case(work, kind, case):
    modes = case if kind == "block" else ("disabled", "enabled", "auto", "enabled", "disabled")
    values = initial_state(modes)
    expected = dict(values)
    if kind == "classify":
        action, raw, expected_return = case
        values.update(SUPPLIED_ACTION=action, SUPPLIED_RAW=raw)
        expected.update(SUPPLIED_ACTION=action, SUPPLIED_RAW=raw)
        operation = 'slackpkg_apply_action_failed "$SUPPLIED_ACTION" "$SUPPLIED_RAW"'
        guard = "block_secondary_modules_after_partial_slackware_update() { forbidden blocker; }"
    else:
        expected_return = 0
        expected.update(SECONDARY_MODULES_BLOCKED="1", SECONDARY_MODULES_BLOCK_REASON=BLOCK_REASON)
        for module in MODULES:
            expected.update({module + "_MODULE_STATE": "blocked", module + "_MODULE_REASON": BLOCK_REASON,
                             module + "_MODULE_RUN": "0"})
        operation = "block_secondary_modules_after_partial_slackware_update"
        guard = "slackpkg_apply_action_failed() { forbidden classifier; }"
    assignments = "\n".join(f"{name}={shlex.quote(value)}" for name, value in values.items())
    output = "printf '%s\\0' \"$call_return\" " + " ".join(f'"${{{name}}}"' for name in values) + ' "$IFS"\n'
    driver = PREFIX + GUARDS + "\n" + guard + "\n" + assignments + "\nIFS='|: '\n"
    # The second call is deliberately not reseeded: classification must preserve
    # state, while blocking must be idempotent after its first assignment pass.
    driver += "for repetition in 1 2; do\ncall_return=0\n" + operation + " || call_return=$?\n" + output + "done\n"
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "partial-update-policy-test",
                             str(REFERENCE)], cwd=work, capture_output=True, timeout=10)
    label = (kind, case)
    assert result.returncode == 0 and result.stderr == b"", (label, result.returncode, result.stderr)
    packet = b"".join(str(value).encode() + b"\0" for value in (expected_return, *expected.values(), "|: "))
    assert result.stdout == packet * 2, (label, result.stdout, packet * 2)
    assert list(work.iterdir()) == [], label


def main():
    classifications = list(classification_cases())
    blocks = list(itertools.product(("disabled", "enabled", "auto"), repeat=len(MODULES)))
    with tempfile.TemporaryDirectory(prefix="slack-update-partial-policy-") as directory:
        work = Path(directory)
        for case in classifications:
            run_case(work, "classify", case)
        for case in blocks:
            run_case(work, "block", case)
    total = len(classifications) + len(blocks)
    print(f"Partial update policy: {total} scenarios, {2 * total} entry calls, "
          f"{len(classifications)} classifier cases, {len(blocks)} blocker cases, 0 failures")


if __name__ == "__main__":
    main()
