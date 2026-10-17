#!/usr/bin/env python3
"""Check the real result mapper against authored combined-state expectations."""

from pathlib import Path
import re
import shlex
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
BASE = dict(
    OPERATION="apply", CHECK_STATUS=0, CHECK_ERROR="",
    PACKAGE_SNAPSHOT_BEFORE_VALID=1, PACKAGE_SNAPSHOT_AFTER_VALID=1,
    PACKAGE_SNAPSHOT_BEFORE_ERROR="before-invalid", PACKAGE_SNAPSHOT_AFTER_ERROR="after-invalid",
    SLACKPKG_UPDATE_STATUS=0, SLACKPKG_INSTALL_NEW_STATUS=0, SLACKPKG_UPGRADE_ALL_STATUS=0,
    PENDING_NEW_CONFIG_FILES_VALID=1, PENDING_NEW_CONFIG_FILES_COUNT=0,
    PENDING_NEW_CONFIG_FILES_ERROR="pending-invalid", FLATPAK_STATUS=0,
    SBOPKG_SYNC_STATUS=0, SQG_SYNC_STATUS=0, SBO_TARGET_SELECTION_STATUS=0,
    SBO_TARGET_SELECTION_ERROR="targets-invalid", SBO_BUILD_STATUS=0, CINNAMON_TRIGGER=0,
    INITRD_REQUIRED=0, INITRD_UPDATE=0, INITRD_OK=0, INITRD_VALIDATION_ERROR="initrd-invalid",
    GRUB_REQUIRED=0, GRUB_UPDATE=0, GRUB_OK=0, GRUB_BLOCKED_BY_INITRD=0,
    GRUB_BLOCK_REASON="initrd-block", GRUB_VALIDATION_ERROR="grub-invalid",
    ELF_MODULE_RUN=0, KERNEL_TRIGGER=0,
)
MODULES = (("FLATPAK", "Flatpak"), ("SBO", "SBo"), ("ELF", "ELF"),
           ("CINNAMON", "Cinnamon"), ("BOOT", "Boot"))
UNAVAILABLE = {}
MODULE_ERRORS = []
for prefix, label in MODULES:
    BASE.update({prefix + "_MODE": "disabled", prefix + "_MODULE_STATE": "disabled",
                 prefix + "_MODULE_REASON": "missing-" + prefix.lower()})
    UNAVAILABLE.update({prefix + "_MODE": "enabled", prefix + "_MODULE_STATE": "unavailable"})
    MODULE_ERRORS.append(f"{label} module is enabled but unavailable: missing-{prefix.lower()}")

PACKAGE_FAILURES = dict(SLACKPKG_UPDATE_STATUS=10, SLACKPKG_INSTALL_NEW_STATUS=11,
                        SLACKPKG_UPGRADE_ALL_STATUS=12)
PACKAGE_ERRORS = ["slackpkg update failed with exit code 10",
                  "slackpkg install-new failed with exit code 11",
                  "slackpkg upgrade-all failed with exit code 12"]
SNAPSHOTS = dict(PACKAGE_SNAPSHOT_BEFORE_VALID=0, PACKAGE_SNAPSHOT_AFTER_VALID=0)
SNAPSHOT_ERRORS = ["Package snapshot before update is invalid: before-invalid"]
SBO_FAILURES = dict(SBOPKG_SYNC_STATUS=14, SQG_SYNC_STATUS=15,
                    SBO_TARGET_SELECTION_STATUS=1, SBO_BUILD_STATUS=16, CINNAMON_TRIGGER=3)
SBO_ERRORS = ["sbopkg repository synchronization failed with exit code 14",
              "sqg queue generation failed with exit code 15",
              "SBo target selection failed: targets-invalid",
              "sbopkg queue processing failed with exit code 16",
              "Cinnamon required rebuilding but the rebuild failed"]
ELF_ERRORS = ["ELF dependency verification still reports broken objects"]
CRITICAL_WARNING = "Critical system packages were updated; a reboot is recommended"
PENDING_WARNING = "2 pending Slackware .new configuration file(s) require manual review"
DRY_WARNING = "Exact Slackware package changes remain unresolved until package metadata is refreshed during apply"
INITRD_ERRORS = ["initrd preparation failed validation: initrd-invalid"]
GRUB_ERRORS = ["GRUB configuration transaction failed: grub-invalid"]
BLOCK_ERRORS = ["GRUB configuration generation was blocked to protect boot safety: initrd-block"]

# Each outcome is (code, success, partial, boot_safe, reboot).
# Entries are clean/noncritical, clean/critical, failed/noncritical, failed/critical.
NO_BOOT = ((0, 1, 0, 1, "none"), (4, 1, 0, 1, "recommended"),
           (2, 0, 1, 1, "none"), (2, 0, 1, 1, "recommended"))
GOOD_BOOT = ((5, 1, 0, 1, "required"), (5, 1, 0, 1, "required"),
             (2, 0, 1, 1, "required"), (2, 0, 1, 1, "required"))
BAD_BOOT = ((3, 0, 1, 0, "unsafe"), (3, 0, 1, 0, "unsafe"),
            (3, 0, 1, 0, "unsafe"), (3, 0, 1, 0, "unsafe"))
BOOT_CASES = (
    ("none", {}, [], NO_BOOT),
    ("initrd-good", dict(INITRD_REQUIRED=1, INITRD_UPDATE=1, INITRD_OK=1), [], GOOD_BOOT),
    ("grub-good", dict(GRUB_REQUIRED=1, GRUB_UPDATE=1, GRUB_OK=1), [], GOOD_BOOT),
    ("both-good", dict(INITRD_REQUIRED=1, INITRD_UPDATE=1, INITRD_OK=1,
                       GRUB_REQUIRED=1, GRUB_UPDATE=1, GRUB_OK=1), [], GOOD_BOOT),
    ("initrd-bad", dict(INITRD_REQUIRED=1, INITRD_UPDATE=1), INITRD_ERRORS, BAD_BOOT),
    ("grub-bad", dict(GRUB_REQUIRED=1, GRUB_UPDATE=1), GRUB_ERRORS, BAD_BOOT),
    ("both-bad", dict(INITRD_REQUIRED=1, INITRD_UPDATE=1, GRUB_REQUIRED=1, GRUB_UPDATE=1),
     INITRD_ERRORS + GRUB_ERRORS, BAD_BOOT),
    ("grub-blocked", dict(GRUB_REQUIRED=1, GRUB_UPDATE=1, GRUB_BLOCKED_BY_INITRD=1),
     BLOCK_ERRORS, BAD_BOOT),
)
COMBINED = (UNAVAILABLE | SNAPSHOTS | PACKAGE_FAILURES | SBO_FAILURES
            | dict(FLATPAK_STATUS=13, ELF_MODULE_RUN=1, PENDING_NEW_CONFIG_FILES_COUNT=2))
COMBINED_ERRORS = (MODULE_ERRORS + SNAPSHOT_ERRORS + PACKAGE_ERRORS
                   + ["flatpak update failed with exit code 13"] + SBO_ERRORS)
# Nonboot diagnostics are explicitly split around the boot diagnostic position.
FAULT_CASES = (
    ("clean", {}, [], [], [], False),
    ("packages", PACKAGE_FAILURES, PACKAGE_ERRORS, [], [], False),
    ("snapshots", SNAPSHOTS, SNAPSHOT_ERRORS, [], [], False),
    ("modules", UNAVAILABLE, MODULE_ERRORS, [], [], False),
    ("sbo", SBO_FAILURES, SBO_ERRORS, [], [], False),
    ("elf-clean", dict(ELF_MODULE_RUN=1), [], [], [], False),
    ("elf", dict(ELF_MODULE_RUN=1), [], ELF_ERRORS, [], True),
    ("pending-invalid", dict(PENDING_NEW_CONFIG_FILES_VALID=0), [], [],
     ["Pending Slackware .new configuration files could not be enumerated: pending-invalid"], False),
    ("pending-count", dict(PENDING_NEW_CONFIG_FILES_COUNT=2), [], [], [PENDING_WARNING], False),
    ("combined", COMBINED, COMBINED_ERRORS, ELF_ERRORS, [PENDING_WARNING], True),
)
FORBIDDEN = (
    "main", "date", "id", "flock", "initialize_runtime_state", "initialize_runtime",
    "initialize_dry_run_runtime", "load_configuration", "acquire_instance_lock",
    "run_check_workflow", "run_apply_workflow", "run_dry_run_workflow",
    "print_json_result", "emit_final_events", "update_slackware_system",
)
PREFIX = 'source "$1"\nBROKEN=$2\n'
GUARDS = "\n".join(f'{name}() {{ printf "ERROR: prohibited boundary: {name}\\n" >&2; exit 97; }}'
                   for name in FORBIDDEN)
SUFFIX = r'''
IFS='|: '
for repetition in 1 2; do
    RESULT_ERRORS+=(stale-error)
    RESULT_WARNINGS+=(stale-warning)
    RESULT_SUCCESS=stale
    RESULT_PARTIAL=stale
    RESULT_BOOT_SAFE=stale
    RESULT_REBOOT=stale
    STABLE_EXIT_CODE=stale
    determine_stable_exit_code "$3"
    call_status=$?
    printf '%s\0' "$call_status" "$STABLE_EXIT_CODE" "$RESULT_SUCCESS" "$RESULT_PARTIAL" \
        "$RESULT_BOOT_SAFE" "$RESULT_REBOOT" "$IFS" "${#RESULT_ERRORS[@]}" \
        "${RESULT_ERRORS[@]}" "${#RESULT_WARNINGS[@]}" "${RESULT_WARNINGS[@]}"
done
'''


def cases():
    for boot, boot_values, boot_errors, outcomes in BOOT_CASES:
        for fault, values, before, after, warnings, broken in FAULT_CASES:
            for critical in (False, True):
                for workflow in (0, 1, 23):
                    failed = bool(before or after or workflow)
                    outcome = outcomes[2 * int(failed) + int(critical)]
                    yield (f"apply/{boot}/{fault}/{critical}/{workflow}",
                           BASE | boot_values | values, critical, broken, workflow,
                           outcome, before + boot_errors + after,
                           warnings + ([CRITICAL_WARNING] if critical else []))
    for operation in ("check", "dry-run"):
        warning = [DRY_WARNING] if operation == "dry-run" else []
        rows = [
            ("clean", {}, 0, 0, []),
            ("updates", dict(CHECK_STATUS=100), 0, 0, []),
            ("check-failure", dict(CHECK_STATUS=42), 0, 1,
             ["slackpkg check-updates failed with exit code 42"]),
            ("explicit-error", dict(CHECK_STATUS=42, CHECK_ERROR="explicit-check-error"), 0, 1,
             ["explicit-check-error"]),
            ("workflow-failure", {}, 23, 1, []),
        ]
        if operation == "check":
            rows.append(("ignore-apply-state", COMBINED | BOOT_CASES[6][1], 0, 0, []))
        else:
            rows.append(("combined", COMBINED | dict(CHECK_STATUS=42), 0, 1,
                         ["slackpkg check-updates failed with exit code 42"] + MODULE_ERRORS
                         + ["SBo target selection failed: targets-invalid"]))
        for label, values, workflow, code, errors in rows:
            yield (f"{operation}/{label}", BASE | values | dict(OPERATION=operation),
                   True, True, workflow, (code, 1 - code, 0, 1, "none"), errors, warning)


def run_cases():
    count = 0
    with tempfile.TemporaryDirectory(prefix="slack-update-result-precedence-") as directory:
        work = Path(directory)
        broken_file = work / "broken objects"
        for label, values, critical, broken, workflow, outcome, errors, warnings in cases():
            content = b"/supplied/broken-object\n" if broken else b""
            broken_file.write_bytes(content)
            assert all(re.fullmatch(r"[A-Z][A-Z0-9_]*", key) for key in values)
            assignments = "\n".join(f"{key}={shlex.quote(str(value))}" for key, value in values.items())
            assignments += "\nCRITICAL_UPDATED=(glibc)\n" if critical else "\nCRITICAL_UPDATED=()\n"
            driver = PREFIX + GUARDS + "\n" + assignments + "\n" + SUFFIX
            result = subprocess.run(
                ["bash", "--noprofile", "--norc", "-c", driver, "result-precedence-test",
                 str(REFERENCE), str(broken_file), str(workflow)],
                cwd=work, capture_output=True, timeout=10)
            assert result.returncode == 0 and result.stderr == b"", (label, result.returncode, result.stderr)
            fields = [0, *outcome, "|: ", len(errors), *errors, len(warnings), *warnings]
            expected = b"".join(str(value).encode() + b"\0" for value in fields) * 2
            assert result.stdout == expected, (label, result.stdout, expected)
            assert broken_file.read_bytes() == content, (label, "changed supplied broken-object file")
            count += 1
    return count


def main():
    count = run_cases()
    print(f"Result precedence: {count} scenarios, {2 * count} mapper calls, 0 failures")


if __name__ == "__main__":
    main()
