#!/usr/bin/env python3
"""Validate supplied apply result states; never execute an apply workflow."""

import copy
import json
import os
from pathlib import Path
import re
import shlex
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
from json_result_test_support import compare, decode

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
FIXTURE = ROOT / "tests/fixtures/reference/apply-json-supplied-baseline.json"
SCENARIOS = ["success", "headers-only", "critical-reboot", "boot-success", "partial-before-reboot",
             "initrd-failure", "grub-failure", "snapshot-before", "snapshot-after", "snapshot-both",
             "package-failure", "reference-no-match", "flatpak-failure", "sbo-failure", "elf-broken",
             "cinnamon-0", "cinnamon-1", "cinnamon-2", "cinnamon-3", "pending-configs", "pending-scan-error",
             "sbo-records", "direct-generic-metadata", "geninitrd-metadata"]


def failure(wanted, errors, code=2):
    wanted.update(success=False, partial=True, exit_code=code,
                  exit_code_meaning="critical boot preparation failure; do not reboot" if code == 3
                  else "partial update or verification failure", errors=errors)
    if code == 3:
        wanted.update(boot_safe=False, reboot="unsafe")


def activate(state, modules, prefix, module):
    state.update({prefix + "_MODE": "enabled", prefix + "_MODULE_STATE": "available",
                  prefix + "_MODULE_REASON": "supplied available", prefix + "_MODULE_RUN": "1"})
    modules[module].update(mode="enabled", activation_state="available", reason="supplied available")


def scenario(name, directory):
    # Expectations come from an authored fixture and explicit case overrides,
    # never from the subject's output or its result-mapping helpers.
    wanted = json.loads(FIXTURE.read_text())
    modules = wanted["modules"]
    state = {"SLACKPKG_UPDATE_STATUS": "0", "SLACKPKG_INSTALL_NEW_STATUS": "0", "SLACKPKG_UPGRADE_ALL_STATUS": "0",
             "PACKAGE_SNAPSHOT_BEFORE_VALID": "1", "PACKAGE_SNAPSHOT_AFTER_VALID": "1",
             "PACKAGE_SNAPSHOT_BEFORE_COUNT": "4", "PACKAGE_SNAPSHOT_AFTER_COUNT": "4",
             "PENDING_NEW_CONFIG_FILES_VALID": "1", "LOG": "/supplied/log", "CONFIG_FILE": "/supplied/config",
             "FINISHED_AT": "2000-01-01T00:00:01Z", "SBO_PERSONAL_QUEUE_DIR": "/supplied/personal",
             "SBO_GENERATED_QUEUE_DIR": "/supplied/generated", "SBO_OPTIONS_FILE": "/supplied/options.conf",
             "INITRD_KERNEL_PACKAGE": "kernel-generic", "KERNEL_MODULES_DIRECTORY": "/supplied/lib/modules",
             "GRUB_CONFIG": "/supplied/grub.cfg", "GENINITRD_POLICY_PATH": "/supplied/geninitrd"}
    for prefix in ["FLATPAK", "SBO", "ELF", "CINNAMON", "BOOT"]:
        state.update({prefix + "_MODE": "disabled", prefix + "_MODULE_STATE": "disabled",
                      prefix + "_MODULE_REASON": "supplied disabled"})
    for variable, filename in [("BROKEN", "broken"), ("PENDING_NEW_CONFIG_FILES", "pending"),
                               ("SBO_OPTION_RECORDS", "options")]:
        path = directory / filename
        path.write_text("")
        state[variable] = str(path)
    critical, workflow = [], 0
    if name == "headers-only":
        state["KERNEL_TRIGGER"] = "1"
        modules["slackware"]["kernel_changes"] = True
    if name == "critical-reboot":
        critical = ["glibc"]
        modules["slackware"]["critical_packages"] = ["glibc"]
        wanted.update(reboot="recommended", exit_code=4, exit_code_meaning="success; reboot recommended",
                      warnings=["Critical system packages were updated; a reboot is recommended"])
    if name in ["boot-success", "partial-before-reboot"]:
        activate(state, modules, "BOOT", "boot")
        state.update(INITRD_REQUIRED="1", INITRD_UPDATE="1", INITRD_OK="1", INITRD_VALIDATION_STATUS="0",
                     GRUB_REQUIRED="1", GRUB_UPDATE="1", GRUB_OK="1", GRUB_COMMAND_ATTEMPTED="1",
                     GRUB_GENERATION_STATUS="0", GRUB_VALIDATION_STATUS="0", GRUB_INSTALL_STATUS="0",
                     GRUB_REPLACEMENT_ATTEMPTED="1", GRUB_CONFIG_REPLACED="1")
        modules["boot"].update(state="success", initrd_required=True, initrd_state="success", initrd_validation_exit_code=0,
                               grub_required=True, grub_state="success", grub_command_attempted=True,
                               grub_generation_exit_code=0, grub_validation_exit_code=0, grub_install_exit_code=0,
                               grub_replacement_attempted=True, grub_config_replaced=True)
        wanted.update(reboot="required", exit_code=5, exit_code_meaning="success; reboot required")
        if name == "partial-before-reboot":
            workflow = 1
            failure(wanted, [])
    if name == "initrd-failure":
        activate(state, modules, "BOOT", "boot")
        state.update(INITRD_REQUIRED="1", INITRD_UPDATE="1", INITRD_VALIDATION_STATUS="42",
                     INITRD_VALIDATION_ERROR="supplied initrd failure", GRUB_REQUIRED="1", GRUB_UPDATE="1",
                     GRUB_BLOCKED_BY_INITRD="1", GRUB_BLOCK_REASON="supplied block")
        modules["boot"].update(state="failed", initrd_required=True, initrd_state="failed", initrd_validation_exit_code=42,
                               initrd_validation_error="supplied initrd failure", grub_required=True, grub_state="blocked",
                               grub_blocked_by_initrd=True, grub_block_reason="supplied block")
        failure(wanted, ["initrd preparation failed validation: supplied initrd failure",
                         "GRUB configuration generation was blocked to protect boot safety: supplied block"], 3)
    if name == "grub-failure":
        activate(state, modules, "BOOT", "boot")
        state.update(GRUB_REQUIRED="1", GRUB_UPDATE="1", GRUB_VALIDATION_STATUS="42",
                     GRUB_VALIDATION_ERROR="supplied GRUB failure")
        modules["boot"].update(state="failed", grub_required=True, grub_state="failed", grub_validation_exit_code=42,
                               grub_validation_error="supplied GRUB failure")
        failure(wanted, ["GRUB configuration transaction failed: supplied GRUB failure"], 3)
    if name.startswith("snapshot-"):
        before = name != "snapshot-after"
        after = name != "snapshot-before"
        if before:
            state.update(PACKAGE_SNAPSHOT_BEFORE_VALID="0", PACKAGE_SNAPSHOT_BEFORE_ERROR="supplied before error")
            modules["slackware"].update(snapshot_before_valid=False, snapshot_before_error="supplied before error")
        if after:
            state.update(PACKAGE_SNAPSHOT_AFTER_VALID="0", PACKAGE_SNAPSHOT_AFTER_ERROR="supplied after error")
            modules["slackware"].update(snapshot_after_valid=False, snapshot_after_error="supplied after error")
        state.update(SECONDARY_MODULES_BLOCKED="1", SECONDARY_MODULES_BLOCK_REASON="supplied block")
        modules["slackware"].update(state="failed", secondary_modules_blocked=True, secondary_modules_block_reason="supplied block")
        modules["boot"].update(state="blocked", initrd_state="blocked", grub_state="blocked")
        failure(wanted, ["Package snapshot before update is invalid: supplied before error" if before
                         else "Package snapshot after update is invalid: supplied after error"])
    if name == "package-failure":
        state.update(SLACKPKG_UPDATE_STATUS="42", SLACKPKG_INSTALL_NEW_STATUS="-1", SLACKPKG_UPGRADE_ALL_STATUS="-1")
        modules["slackware"].update(state="failed", update_exit_code=42, install_new_exit_code=None, upgrade_all_exit_code=None)
        failure(wanted, ["slackpkg update failed with exit code 42"])
    if name == "reference-no-match":
        state.update(SLACKPKG_INSTALL_NEW_STATUS="20", SLACKPKG_UPGRADE_ALL_STATUS="20")
        modules["slackware"].update(install_new_exit_code=20, upgrade_all_exit_code=20)
    if name == "flatpak-failure":
        activate(state, modules, "FLATPAK", "flatpak")
        state["FLATPAK_STATUS"] = "42"
        modules["flatpak"].update(state="failed", exit_code=42)
        failure(wanted, ["flatpak update failed with exit code 42"])
    if name == "sbo-failure":
        activate(state, modules, "SBO", "sbo")
        state.update(SBOPKG_SYNC_STATUS="0", SQG_SYNC_STATUS="0", SBO_TARGET_SELECTION_STATUS="0", SBO_BUILD_STATUS="42")
        modules["sbo"].update(state="failed", sync_exit_code=0, queue_generation_exit_code=0,
                              target_selection_exit_code=0, build_exit_code=42)
        failure(wanted, ["sbopkg queue processing failed with exit code 42"])
    if name == "elf-broken":
        activate(state, modules, "ELF", "elf")
        state.update(ELF_SCAN_STATUS="0", ELF_VERIFICATION_STATUS="42")
        Path(state["BROKEN"]).write_text('/supplied/broken "object"\n')
        modules["elf"].update(state="warning", scan_exit_code=0, verification_exit_code=42,
                              broken_objects=['/supplied/broken "object"'])
        failure(wanted, ["ELF dependency verification still reports broken objects"])
    if name.startswith("cinnamon-"):
        activate(state, modules, "CINNAMON", "cinnamon")
        trigger = int(name[-1])
        state["CINNAMON_TRIGGER"] = str(trigger)
        modules["cinnamon"]["state"] = ["not-required", "incomplete", "success", "failed"][trigger]
        if trigger == 1:
            workflow = 1
            failure(wanted, [])
        if trigger == 3:
            failure(wanted, ["Cinnamon required rebuilding but the rebuild failed"])
    if name == "pending-configs":
        state["PENDING_NEW_CONFIG_FILES_COUNT"] = "2"
        Path(state["PENDING_NEW_CONFIG_FILES"]).write_text("/supplied/a.new\n/supplied/b.new")
        modules["slackware"].update(pending_new_config_files_count=2,
                                    pending_new_config_files=["/supplied/a.new", "/supplied/b.new"])
        wanted["warnings"] = ["2 pending Slackware .new configuration file(s) require manual review"]
    if name == "pending-scan-error":
        state.update(PENDING_NEW_CONFIG_FILES_VALID="0", PENDING_NEW_CONFIG_FILES_ERROR="supplied scan error")
        modules["slackware"].update(pending_new_config_files_valid=False, pending_new_config_files_error="supplied scan error")
        wanted["warnings"] = ["Pending Slackware .new configuration files could not be enumerated: supplied scan error"]
    if name == "sbo-records":
        state.update(SBO_OPTION_RECORD_COUNT="2", SBO_PERSONAL_QUEUE_FILE_COUNT="3", SBO_PERSONAL_QUEUE_SYMLINK_COUNT="1",
                     SBO_QUEUE_GENERATION_READY="1", TOTAL_CORE="2", TOTAL_EXTRA="1", TOTAL_EN_COLA="3")
        Path(state["SBO_OPTION_RECORDS"]).write_text('alpha\tCFLAGS="-O2"\nbeta\tENABLE=yes\n')
        modules["sbo"].update(build_option_record_count=2, personal_queue_files_copied=3, personal_queue_symlinks_ignored=1,
                              private_queue_generation_ready=True, core_queue_count=2, extra_queue_count=1, submitted_queue_count=3,
                              build_options=[{"target": "alpha", "options": 'CFLAGS="-O2"'}, {"target": "beta", "options": "ENABLE=yes"}])
    if name == "direct-generic-metadata":
        state.update(BOOT_PREPARATION_LAYOUT="direct-generic-no-initrd", BOOT_DIRECT_GENERIC_AVAILABLE="1",
                     BOOT_DIRECT_GENERIC_REASON="supplied direct", BOOT_DIRECT_GENERIC_BOOT_IMAGE="/supplied/vmlinuz",
                     BOOT_DIRECT_GENERIC_KERNEL_PATH="/supplied/running", DIRECT_GENERIC_VALIDATION_STATUS="0",
                     DIRECT_GENERIC_INSTALLED_KERNEL_VERSION="mock-version", DIRECT_GENERIC_INSTALLED_KERNEL_RECORD_COUNT="1",
                     DIRECT_GENERIC_KERNEL_PATH="/supplied/kernel", DIRECT_GENERIC_MODULES_PATH="/supplied/modules")
        modules["boot"].update(preparation_layout="direct-generic-no-initrd", direct_generic_available=True,
                               direct_generic_reason="supplied direct", direct_generic_boot_image="/supplied/vmlinuz",
                               direct_generic_running_kernel_path="/supplied/running", direct_generic_validation_exit_code=0,
                               direct_generic_installed_kernel_version="mock-version", direct_generic_installed_kernel_records=1,
                               direct_generic_kernel_path="/supplied/kernel", direct_generic_modules_path="/supplied/modules")
    if name == "geninitrd-metadata":
        state.update(GENINITRD_POLICY_OVERRIDE_REQUIRED="1", GENINITRD_POLICY_OVERRIDE_APPLIED="1",
                     GENINITRD_POLICY_OVERRIDE_RESTORED="1", GENINITRD_POLICY_OVERRIDE_STATUS="supplied-restored",
                     GENINITRD_TRANSITION_EXPECTED="1", GENINITRD_POST_STATE="supplied-verified",
                     GENINITRD_POST_VALIDATION_STATUS="0", GENINITRD_POST_KERNEL_VERSION="mock-version",
                     GENINITRD_POST_KERNEL_PATH="/supplied/kernel", GENINITRD_POST_MODULES_PATH="/supplied/modules",
                     GENINITRD_POST_INITRD_PATH="/supplied/initrd", GENINITRD_POST_NAMED_LINK="/supplied/link")
        modules["boot"].update(geninitrd_policy_override_required=True, geninitrd_policy_override_applied=True,
                               geninitrd_policy_override_restored=True, geninitrd_policy_override_status="supplied-restored",
                               geninitrd_transition_expected=True, geninitrd_post_state="supplied-verified",
                               geninitrd_post_validation_exit_code=0, geninitrd_post_kernel_version="mock-version",
                               geninitrd_post_kernel_path="/supplied/kernel", geninitrd_post_modules_path="/supplied/modules",
                               geninitrd_post_initrd_path="/supplied/initrd", geninitrd_post_named_link="/supplied/link")
    return state, critical, workflow, wanted


def run_case(name):
    with tempfile.TemporaryDirectory(prefix="slack-update-apply-json-") as directory:
        state, critical, workflow, wanted = scenario(name, Path(directory))
        assignments = []
        for key, value in state.items():
            if not re.fullmatch(r"[A-Z_][A-Z0-9_]*", key):
                raise AssertionError("invalid supplied variable name")
            assignments.append(key + "=" + shlex.quote(value))
        # The audited state initializer assigns variables and calls only date;
        # stub that call. Do not call initialize_runtime or any workflow.
        driver = '\n'.join(['source "$1"', 'date() { printf "%s\\n" 2000-01-01T00:00:00Z; }',
                            'initialize_runtime_state || exit 99', 'OPERATION=apply', *assignments,
                            'CRITICAL_UPDATED=(' + ' '.join(shlex.quote(item) for item in critical) + ')',
                            f'determine_stable_exit_code {workflow}', 'print_json_result "$STABLE_EXIT_CODE"'])
        environment = os.environ.copy()
        environment.pop("BASH_ENV", None)
        environment.pop("ENV", None)
        environment["LC_ALL"] = "C"
        result = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "apply-json-test", str(REFERENCE)],
                                env=environment, capture_output=True, timeout=15, check=False)
        if result.returncode != 0 or result.stderr:
            raise AssertionError(f"serializer status={result.returncode}; stderr={result.stderr!r}")
        compare(decode(result.stdout), wanted)


def negative_controls():
    wanted = json.loads(FIXTURE.read_text())
    mutations = []
    for key, value in [("success", 1), ("exit_code", 5), ("boot_safe", 1)]:
        item = copy.deepcopy(wanted)
        item[key] = value
        mutations.append(item)
    for module, field, value in [("boot", "initrd_validation_exit_code", 0), ("sbo", "core_queue_count", "0"),
                                  ("slackware", "snapshot_before_valid", False), ("elf", "executes_inspected_objects", True)]:
        item = copy.deepcopy(wanted)
        item["modules"][module][field] = value
        mutations.append(item)
    item = copy.deepcopy(wanted)
    del item["modules"]["boot"]["geninitrd_post_state"]
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
    print(f"Apply JSON result tests: {len(SCENARIOS)} scenarios, {controls} negative controls, {failures} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
