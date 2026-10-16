#!/usr/bin/env python3
"""Check supplied dry-run result data; never initialize or execute a workflow."""

import copy
import os
from pathlib import Path
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
from json_result_test_support import compare, decode


REFERENCE = Path(__file__).resolve().parents[2] / "tools/reference/slack-update-reference.sh"
WARNING = "Exact Slackware package changes remain unresolved until package metadata is refreshed during apply"
UPDATE = "slackpkg -batch=on -default_answer=y update"
INSTALL = "slackpkg -batch=on -default_answer=y -postinst=off install-new"
UPGRADE = "slackpkg -batch=on -default_answer=y -postinst=off upgrade-all"
DRIVER = r'''
source "$1"
OPERATION=dry-run
RESULT_SUCCESS=0 RESULT_PARTIAL=1 RESULT_BOOT_SAFE=0 RESULT_REBOOT=unsafe
RESULT_WARNINGS=('stale warning') RESULT_ERRORS=('stale error')
determine_stable_exit_code "$SUPPLIED_WORKFLOW_RESULT"
print_json_result "$STABLE_EXIT_CODE"
'''


def base_state(directory):
    state = {
        "SUPPLIED_WORKFLOW_RESULT": "0", "CHECK_STATUS": "0", "CHECK_ERROR": "",
        "STARTED_AT": "2000-01-01T00:00:00Z", "FINISHED_AT": "2000-01-01T00:00:01Z",
        "LOG": '/supplied/log "quoted"', "CONFIG_FILE": "/supplied/config",
        "SLACKWARE_INSTALL_NEW": "true", "SLACKWARE_UPGRADE_ALL": "true",
        "PLAN_FLATPAK_AVAILABLE": "0", "PLAN_SBOPKG_AVAILABLE": "0", "PLAN_SQG_AVAILABLE": "0",
        "SBO_PERSONAL_QUEUE_DIR": "", "SBO_OPTION_RECORD_COUNT": "0",
        "SBO_TARGET_SELECTION_STATUS": "-1", "SBO_TARGET_SELECTION_ERROR": "",
        "PLAN_READELF_AVAILABLE": "0", "ELF_LDCONFIG_AVAILABLE": "0",
        "ELF_LIBRARY_CACHE_RECORD_COUNT": "0", "ELF_SCAN_STATUS": "-1",
        "CINNAMON_INSTALLED": "0", "PLAN_CINNAMON_REPOSITORY": "0", "PLAN_CINNAMON_BUILDER": "0",
        "PLAN_MKINITRD_AVAILABLE": "0", "PLAN_MKINITRD_CONFIGURED": "0",
        "PLAN_GRUB_AVAILABLE": "0", "PLAN_GRUB_VALIDATOR_AVAILABLE": "0", "PLAN_GRUB_CONFIGURED": "0",
        "INITRD_KERNEL_PACKAGE": "kernel-generic", "KERNEL_MODULES_DIRECTORY": "/supplied/lib/modules",
        "GRUB_CONFIG": "/supplied/grub.cfg", "SBODIR": str(directory / "queues"),
    }
    for prefix in ["FLATPAK", "SBO", "ELF", "CINNAMON", "BOOT"]:
        state.update({prefix + "_MODE": "disabled", prefix + "_MODULE_STATE": "disabled",
                      prefix + "_MODULE_REASON": "supplied disabled", prefix + "_MODULE_RUN": "0"})
    for variable, filename in [("SBO_OPTIONS_FILE", "options.conf"), ("SBO_OPTION_RECORDS", "options.tsv"),
                               ("QUEUE_CORE", "queue"), ("ABI_CANDIDATES", "abi"),
                               ("QUEUE_EXTRA", "extra"), ("BROKEN", "broken")]:
        path = directory / filename
        path.write_text("")
        state[variable] = str(path)
    return state


def expected_modules(directory):
    common = {"mode": "disabled", "activation_state": "disabled", "reason": "supplied disabled"}
    return {
        "slackware": {"state": "success", "check_exit_code": 0, "updates_available": False,
                      "planned_commands": [UPDATE, INSTALL, UPGRADE]},
        "flatpak": {**common, "available": False, "would_update": False},
        "sbo": {**common, "sbopkg_available": False, "sqg_available": False,
                "queue_directory": str(directory / "queues"), "personal_queue_directory": str(directory / "queues"),
                "queue_workspace_isolated": True, "options_file": str(directory / "options.conf"),
                "build_option_record_count": 0, "build_options": [], "target_selection_exit_code": None,
                "target_selection_error": "", "current_queue_targets": [], "abi_rebuild_candidates": [],
                "broken_elf_targets": []},
        "elf": {**common, "inspection_method": "readelf+ldconfig-cache", "executes_inspected_objects": False,
                "architecture_specific_resolution": True, "architecture_match_fields": ["class", "data", "machine"],
                "library_cache_records": 0, "readelf_available": False, "ldconfig_available": False,
                "scan_exit_code": None, "broken_objects": []},
        "cinnamon": {**common, "installation_detected": False, "repository_available": False,
                     "builder_available": False},
        "boot": {**common, "mkinitrd_available": False, "mkinitrd_configured": False,
                 "kernel_version_source": "post-update-package-snapshot", "kernel_package": "kernel-generic",
                 "modules_directory": "/supplied/lib/modules", "kernel_validation_deferred_until_apply": True,
                 "grub_generator_available": False, "grub_validator_available": False, "grub_configured": False,
                 "grub_active_config": "/supplied/grub.cfg", "grub_temporary_generation": True,
                 "grub_validator": "grub-script-check", "grub_atomic_replacement": True},
    }


SCENARIOS = ["disabled", "updates", "install-only", "upgrade-only", "refresh-only", "check-failure",
             "mirror-diagnostic", "auto-unavailable", "enabled-unavailable", "selection-error",
             "available-with-records", "elf-failure", "zero-statuses", "missing-files"]


def scenario(name, directory):
    state = base_state(directory)
    modules = expected_modules(directory)
    errors = []
    stable = 0
    if name == "updates":
        state["CHECK_STATUS"] = "100"
        modules["slackware"].update(check_exit_code=100, updates_available=True)
    if name in ["install-only", "upgrade-only", "refresh-only"]:
        install, upgrade, commands = {
            "install-only": ("true", "false", [UPDATE, INSTALL]),
            "upgrade-only": ("false", "true", [UPDATE, UPGRADE]),
            "refresh-only": ("false", "false", [UPDATE]),
        }[name]
        state.update(SLACKWARE_INSTALL_NEW=install, SLACKWARE_UPGRADE_ALL=upgrade)
        modules["slackware"]["planned_commands"] = commands
    if name in ["check-failure", "mirror-diagnostic"]:
        raw, diagnostic = (42, "") if name == "check-failure" else (69, 'mirror\n\x1b"failure"')
        state.update(CHECK_STATUS=str(raw), CHECK_ERROR=diagnostic, SUPPLIED_WORKFLOW_RESULT="1")
        modules["slackware"].update(state="failed", check_exit_code=raw, updates_available=None)
        errors = ["slackpkg check-updates failed with exit code 42"] if not diagnostic else ['mirror\n\x1b"failure"']
        stable = 1
    if name in ["auto-unavailable", "enabled-unavailable", "available-with-records"]:
        mode = "auto" if name == "auto-unavailable" else "enabled"
        activation = "available" if name == "available-with-records" else "unavailable"
        for prefix, module in [("FLATPAK", "flatpak"), ("SBO", "sbo"), ("ELF", "elf"),
                               ("CINNAMON", "cinnamon"), ("BOOT", "boot")]:
            state.update({prefix + "_MODE": mode, prefix + "_MODULE_STATE": activation,
                          prefix + "_MODULE_REASON": "supplied reason"})
            modules[module].update(mode=mode, activation_state=activation, reason="supplied reason")
        if name == "enabled-unavailable":
            stable = 1
            errors = ["Flatpak module is enabled but unavailable: supplied reason",
                      "SBo module is enabled but unavailable: supplied reason",
                      "ELF module is enabled but unavailable: supplied reason",
                      "Cinnamon module is enabled but unavailable: supplied reason",
                      "Boot module is enabled but unavailable: supplied reason"]
    if name == "available-with-records":
        for key in ["PLAN_FLATPAK_AVAILABLE", "FLATPAK_MODULE_RUN", "PLAN_SBOPKG_AVAILABLE", "PLAN_SQG_AVAILABLE",
                    "PLAN_READELF_AVAILABLE", "ELF_LDCONFIG_AVAILABLE", "CINNAMON_INSTALLED",
                    "PLAN_CINNAMON_REPOSITORY", "PLAN_CINNAMON_BUILDER", "PLAN_MKINITRD_AVAILABLE",
                    "PLAN_MKINITRD_CONFIGURED", "PLAN_GRUB_AVAILABLE", "PLAN_GRUB_VALIDATOR_AVAILABLE", "PLAN_GRUB_CONFIGURED"]:
            state[key] = "1"
        state.update(SBO_PERSONAL_QUEUE_DIR=str(directory / "personal"), SBO_OPTION_RECORD_COUNT="2",
                     SBO_TARGET_SELECTION_STATUS="0", ELF_SCAN_STATUS="0", ELF_LIBRARY_CACHE_RECORD_COUNT="3")
        Path(state["SBO_OPTION_RECORDS"]).write_text('zeta\tCFLAGS="-O2 -g"\nalpha\tENABLE=yes\n')
        Path(state["QUEUE_CORE"]).write_text("zeta\nalpha\nalpha")
        Path(state["ABI_CANDIDATES"]).write_text("abi-target\n")
        Path(state["QUEUE_EXTRA"]).write_text("elf-target\n")
        Path(state["BROKEN"]).write_text('/supplied/broken "object"\n')
        modules["flatpak"].update(available=True, would_update=True)
        modules["sbo"].update(sbopkg_available=True, sqg_available=True,
                              personal_queue_directory=str(directory / "personal"), build_option_record_count=2,
                              build_options=[{"target": "zeta", "options": 'CFLAGS="-O2 -g"'},
                                             {"target": "alpha", "options": "ENABLE=yes"}],
                              target_selection_exit_code=0, current_queue_targets=["zeta", "alpha", "alpha"],
                              abi_rebuild_candidates=["abi-target"], broken_elf_targets=["elf-target"])
        modules["elf"].update(library_cache_records=3, readelf_available=True, ldconfig_available=True,
                              scan_exit_code=0, broken_objects=['/supplied/broken "object"'])
        modules["cinnamon"].update(installation_detected=True, repository_available=True, builder_available=True)
        modules["boot"].update(mkinitrd_available=True, mkinitrd_configured=True, grub_generator_available=True,
                               grub_validator_available=True, grub_configured=True)
    if name == "selection-error":
        state.update(SBO_TARGET_SELECTION_STATUS="42", SBO_TARGET_SELECTION_ERROR="supplied selection error")
        modules["sbo"].update(target_selection_exit_code=42, target_selection_error="supplied selection error")
        errors, stable = ["SBo target selection failed: supplied selection error"], 1
    if name == "elf-failure":
        state.update(ELF_SCAN_STATUS="42", SUPPLIED_WORKFLOW_RESULT="1")
        modules["elf"]["scan_exit_code"] = 42
        stable = 1
    if name == "zero-statuses":
        state.update(SBO_TARGET_SELECTION_STATUS="0", ELF_SCAN_STATUS="0")
        modules["sbo"]["target_selection_exit_code"] = 0
        modules["elf"]["scan_exit_code"] = 0
    if name == "missing-files":
        for key in ["SBO_OPTION_RECORDS", "QUEUE_CORE", "ABI_CANDIDATES", "QUEUE_EXTRA", "BROKEN"]:
            Path(state[key]).unlink()
    wanted = {
        "schema_version": 0, "schema_status": "provisional", "operation": "dry-run", "success": stable == 0,
        "partial": False, "reboot": "none", "boot_safe": True, "exit_code": stable,
        "exit_code_meaning": "success; no reboot required" if stable == 0 else "general failure",
        "exit_code_stable": True, "started_at": "2000-01-01T00:00:00Z", "finished_at": "2000-01-01T00:00:01Z",
        "log_path": '/supplied/log "quoted"', "config_path": "/supplied/config", "modules": modules,
        "warnings": [WARNING], "errors": errors,
    }
    return state, wanted


def run_case(name):
    with tempfile.TemporaryDirectory(prefix="slack-update-dry-json-") as directory:
        state, wanted = scenario(name, Path(directory))
        environment = os.environ.copy()
        environment.pop("BASH_ENV", None)
        environment.pop("ENV", None)
        environment.update(state, LC_ALL="C")
        result = subprocess.run(["bash", "--noprofile", "--norc", "-c", DRIVER, "dry-json-test", str(REFERENCE)],
                                env=environment, capture_output=True, timeout=15, check=False)
        if result.returncode != 0 or result.stderr:
            raise AssertionError(f"serializer status={result.returncode}; stderr={result.stderr!r}")
        compare(decode(result.stdout), wanted)


def negative_controls():
    with tempfile.TemporaryDirectory(prefix="slack-update-dry-json-controls-") as directory:
        _, wanted = scenario("available-with-records", Path(directory))
        mutations = []
        for module, field, value in [("flatpak", "available", 1), ("sbo", "target_selection_exit_code", False),
                                      ("elf", "scan_exit_code", None), ("boot", "kernel_validation_deferred_until_apply", False)]:
            item = copy.deepcopy(wanted)
            item["modules"][module][field] = value
            mutations.append(item)
        item = copy.deepcopy(wanted)
        item["modules"]["slackware"]["planned_commands"].reverse()
        mutations.append(item)
        item = copy.deepcopy(wanted)
        item["modules"]["sbo"]["current_queue_targets"] = ["alpha", "zeta"]
        mutations.append(item)
        item = copy.deepcopy(wanted)
        del item["modules"]["cinnamon"]["builder_available"]
        mutations.append(item)
        item = copy.deepcopy(wanted)
        item["warnings"] = []
        mutations.append(item)
        for index, item in enumerate(mutations):
            try:
                compare(item, wanted)
            except AssertionError:
                continue
            raise AssertionError(f"negative control {index} was accepted")
        return len(mutations)


def main():
    failures, controls = 0, 0
    for name in SCENARIOS:
        try:
            run_case(name)
        except (AssertionError, ValueError, OSError, subprocess.SubprocessError) as error:
            failures += 1
            print(f"FAIL: {name}: {error}", file=sys.stderr)
    try:
        controls = negative_controls()
    except (AssertionError, ValueError, OSError) as error:
        failures += 1
        print(f"FAIL: negative controls: {error}", file=sys.stderr)
    print(f"Dry-run JSON result tests: {len(SCENARIOS)} scenarios, {controls} negative controls, {failures} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
