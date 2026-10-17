#!/usr/bin/env python3
"""Check complete reference apply orchestration with private files and supplied operations."""

from pathlib import Path
import itertools
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
MODULES = ("FLATPAK", "SBO", "ELF", "CINNAMON")
DRIVER = r'''
source "$1"
TRACE=$2
trace() { printf '%s\0' "$@" >> "$TRACE"; printf '\n' >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
capture_package_snapshot_before() { trace before "$@"; PACKAGE_SNAPSHOT_BEFORE_COUNT=3; return 0; }
probe_boot_module() { trace boot-probe "$@"; return "$AUX_RETURN"; }
prepare_geninitrd_grub_policy_override() { trace ownership "$@"; GENINITRD_POLICY_OVERRIDE_STATUS=supplied-prepared; return 0; }
update_slackware_system() {
    trace packages "$@"
    SLACKPKG_UPDATE_STATUS=0; SLACKPKG_INSTALL_NEW_STATUS=0; SLACKPKG_UPGRADE_ALL_STATUS=0
    return "$AUX_RETURN"
}
restore_geninitrd_grub_policy_override() { trace restore "$@"; GENINITRD_POLICY_OVERRIDE_STATUS=supplied-restored; return 0; }
capture_package_snapshot_after() { trace after "$@"; PACKAGE_SNAPSHOT_AFTER_COUNT=4; return 0; }
emit_module_started_event() { trace module-started "$@"; return "$AUX_RETURN"; }
emit_action_started_event() { trace action-started "$@"; return "$AUX_RETURN"; }
emit_action_completed_event() { trace action-completed "$@"; return "$AUX_RETURN"; }
emit_module_completed_event() { trace module-completed "$@"; return "$AUX_RETURN"; }
probe_optional_modules() { trace optional-probe "$@"; return "$AUX_RETURN"; }
print_optional_module_activation() { trace activation "$@"; return "$AUX_RETURN"; }
update_flatpak() { trace flatpak "$@"; FLATPAK_STATUS=$FLAT_CODE; return "$AUX_RETURN"; }
detect_abi_changes() { trace abi "$@"; return "$AUX_RETURN"; }
detect_kernel_changes() { trace kernel "$@"; return "$AUX_RETURN"; }
synchronize_sbo_repository() {
    trace synchronize "$@"
    SBOPKG_SYNC_STATUS=$SYNC_SBOPKG; SQG_SYNC_STATUS=$SYNC_SQG
    return "$AUX_RETURN"
}
build_sbo_target_queues_after_synchronization() {
    trace queues "$@"
    printf 'built-core\n' > "$QUEUE_CORE"; printf 'built-extra\n' > "$QUEUE_EXTRA"
    if [[ -n $SBO_OPTION_RECORDS ]]; then printf 'built-options\n' > "$SBO_OPTION_RECORDS"; fi
    TOTAL_CORE=2; TOTAL_EXTRA=3; SBO_OPTION_RECORD_COUNT=4
    SBO_TARGET_SELECTION_ERROR='supplied selection error'; SBODIR=supplied-repository
    return "$QUEUE_RETURN"
}
detect_broken_elf_objects() {
    trace scan "$@"
    : > "$BROKEN"
    if [[ $BROKEN_PAYLOAD == 1 ]]; then printf 'supplied-object\n' > "$BROKEN"; fi
    return "$ELF_SCAN_RETURN"
}
map_broken_objects_to_sbo_packages() {
    trace map "$@"
    printf 'mapped-extra\n' > "$QUEUE_EXTRA"; TOTAL_EXTRA=5
    return "$ELF_MAP_RETURN"
}
build_and_apply_sbo_queue() { trace process "$@"; SBO_BUILD_STATUS=$BUILD_CODE; return "$AUX_RETURN"; }
rebuild_cinnamon() { trace cinnamon "$@"; CINNAMON_TRIGGER=$TRIGGER; return "$AUX_RETURN"; }
run_boot_preparation_module() { trace boot "$@"; return "$BOOT_RETURN"; }
print_summary() {
    trace summary "$@" "$slackware_state" "$flatpak_state" "$sbo_state" "$elf_state" "$cinnamon_state" "$action_exit"
    return "$AUX_RETURN"
}
'''
FORBIDDEN = (
    "main", "initialize_runtime", "initialize_execution_environment", "load_configuration",
    "run_check_workflow", "run_dry_run_workflow", "capture_validated_package_snapshot",
    "stage_geninitrd_grub_policy_override", "read_geninitrd_policy_boolean", "geninitrd_policy_fingerprint",
    "block_secondary_modules_after_partial_slackware_update", "print_json_result", "emit_final_events",
    "slackpkg", "flatpak", "sbopkg", "sqg", "readelf", "mkinitrd", "grub-mkconfig", "git", "curl", "wget",
    "date", "find", "sort", "rm", "mv", "mktemp",
)
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)


def cases():
    defaults = dict(FLATPAK_RUN=1, SBO_RUN=1, ELF_RUN=1, CINNAMON_RUN=1, IDLE_STATE="disabled",
                    FLAT_CODE=0, SYNC_SBOPKG=0, SYNC_SQG=0, QUEUE_RETURN=0, ELF_SCAN_RETURN=0,
                    ELF_MAP_RETURN=0, BROKEN_PAYLOAD=0, BUILD_CODE=0, TRIGGER=2, OPTION_PATH=1)
    rows = []
    for flags, idle in itertools.product(itertools.product((0, 1), repeat=4), ("disabled", "unavailable", "blocked")):
        rows.append(defaults | dict(zip((m + "_RUN" for m in MODULES), flags)) | dict(IDLE_STATE=idle))
    sbo_profiles = ((0, 0, 0, 0), (23, 42, 0, 0), (23, 0, 0, 0), (0, 42, 0, 0),
                    (-1, -1, 0, -1), (0, 0, 1, 0), (0, 0, 255, 0), (0, 0, 0, 42), (23, 42, 0, 255))
    elf_profiles = ((0, 0, 0), (0, 0, 1), (23, 0, 1), (0, 42, 1), (255, 255, 0))
    for sbo, elf, sp, ep, option in itertools.product((0, 1), (0, 1), sbo_profiles, elf_profiles, (0, 1)):
        rows.append(defaults | dict(SBO_RUN=sbo, ELF_RUN=elf, OPTION_PATH=option) |
                    dict(zip(("SYNC_SBOPKG", "SYNC_SQG", "QUEUE_RETURN", "BUILD_CODE"), sp)) |
                    dict(zip(("ELF_SCAN_RETURN", "ELF_MAP_RETURN", "BROKEN_PAYLOAD"), ep)))
    for flat, trigger, option in itertools.product((-1, 0, 1, 23, 255), (-1, 0, 1, 2, 3, 4, 255), (0, 1)):
        rows.append(defaults | dict(FLAT_CODE=flat, TRIGGER=trigger, OPTION_PATH=option))
    seen = set()
    for row in rows:
        key = tuple(row.items())
        if key not in seen:
            seen.add(key)
            yield row


def initial_state(case):
    values = dict(FLATPAK_STATUS="91", SBOPKG_SYNC_STATUS="92", SQG_SYNC_STATUS="93", SBO_BUILD_STATUS="94",
                  SBO_TARGET_SELECTION_STATUS="9", SBO_TARGET_SELECTION_ERROR="stale-selection", TOTAL_CORE="7",
                  TOTAL_EXTRA="8", SBO_OPTION_RECORD_COUNT="9", SBODIR="stale-repository", CINNAMON_TRIGGER="9",
                  SECONDARY_MODULES_BLOCKED="0", SECONDARY_MODULES_BLOCK_REASON="", SLACKPKG_UPDATE_STATUS="81",
                  SLACKPKG_INSTALL_NEW_STATUS="82", SLACKPKG_UPGRADE_ALL_STATUS="83",
                  PACKAGE_SNAPSHOT_BEFORE_COUNT="97", PACKAGE_SNAPSHOT_AFTER_COUNT="98",
                  GENINITRD_POLICY_OVERRIDE_STATUS="stale-policy")
    for index, module in enumerate(MODULES):
        values.update({module + "_MODE": ("auto", "enabled", "disabled")[index % 3],
                       module + "_MODULE_RUN": str(case[module + "_RUN"]),
                       module + "_MODULE_STATE": case["IDLE_STATE"], module + "_MODULE_REASON": "supplied " + module + " reason"})
    return values


# Authored event/callback order and payloads, independent of implementation execution.
PREFIX_ROWS = [
    ("module-started", "slackware", "Slackware update module started"),
    ("action-started", "slackware", "snapshot_before", "Capturing package snapshot before update"), ("before",),
    ("action-completed", "slackware", "snapshot_before", "success", "Package snapshot before update captured and validated (3 records)", 0),
    ("action-started", "slackware", "geninitrd_grub_ownership", "Preparing exclusive GRUB ownership for the package transaction"),
    ("boot-probe",), ("ownership",),
    ("action-completed", "slackware", "geninitrd_grub_ownership", "success", "GenInitrd GRUB ownership state: supplied-prepared", 0),
    ("action-started", "slackware", "update_packages", "Applying Slackware package operations"), ("packages",),
    ("action-completed", "slackware", "update_packages", "success", "Slackware package operations completed", 0),
    ("action-started", "slackware", "restore_geninitrd_policy", "Restoring the original GenInitrd policy after package operations"), ("restore",),
    ("action-completed", "slackware", "restore_geninitrd_policy", "success", "GenInitrd policy restoration state: supplied-restored", 0),
    ("action-started", "slackware", "snapshot_after", "Capturing package snapshot after update"), ("after",),
    ("action-completed", "slackware", "snapshot_after", "success", "Package snapshot after update captured and validated (4 records)", 0),
    ("module-completed", "slackware", "success", "Slackware package operations completed", 0),
    ("optional-probe",), ("activation",), ("module-started", "flatpak", "Flatpak update module started"),
]


def expected(case):
    c, values, rows = case, initial_state(case), list(PREFIX_ROWS)
    files = {name: ("stale-" + name + "\n").encode() for name in ("core", "extra", "options", "broken")}
    values.update(SLACKPKG_UPDATE_STATUS="0", SLACKPKG_INSTALL_NEW_STATUS="0", SLACKPKG_UPGRADE_ALL_STATUS="0",
                  PACKAGE_SNAPSHOT_BEFORE_COUNT="3", PACKAGE_SNAPSHOT_AFTER_COUNT="4", GENINITRD_POLICY_OVERRIDE_STATUS="supplied-restored")

    def start(module, action, message): rows.append(("action-started", module, action, message))
    def done(module, action, state, message, raw=0): rows.append(("action-completed", module, action, state, message, raw))
    def module_done(module, state, message, raw=0): rows.append(("module-completed", module, state, message, raw))
    def idle(module): return "supplied " + module.upper() + " reason"

    flat, sbo, elf, cinnamon, raw = "success", "success", "success", "skipped", 0
    if c["FLATPAK_RUN"]:
        start("flatpak", "update", "Updating Flatpak installations"); rows.append(("flatpak",))
        values["FLATPAK_STATUS"] = str(c["FLAT_CODE"])
        flat, raw = ("failed", c["FLAT_CODE"]) if c["FLAT_CODE"] > 0 else ("success", 0)
        done("flatpak", "update", flat, "Flatpak update action completed", raw)
    else:
        flat = c["IDLE_STATE"]
        done("flatpak", "update", flat, "Flatpak update was not applicable: " + idle("flatpak"))
    module_done("flatpak", flat, "Flatpak update module completed", raw)
    rows += [("module-started", "core", "Package change analysis started"),
             ("action-started", "core", "detect_triggers", "Detecting ABI and kernel changes"), ("abi",), ("kernel",)]
    done("core", "detect_triggers", "success", "ABI and kernel change detection completed")
    module_done("core", "success", "Package change analysis completed")
    rows.append(("module-started", "sbo", "SBo update module started"))
    if c["SBO_RUN"]:
        start("sbo", "synchronize", "Synchronizing the configured SBo repository"); rows.append(("synchronize",))
        values.update(SBOPKG_SYNC_STATUS=str(c["SYNC_SBOPKG"]), SQG_SYNC_STATUS=str(c["SYNC_SQG"]))
        raw = next((x for x in (c["SYNC_SBOPKG"], c["SYNC_SQG"]) if x > 0), 0)
        sbo = "failed" if raw else "success"
        done("sbo", "synchronize", sbo, "SBo repository synchronization completed", raw)
        start("sbo", "build_queues", "Building SBo target queues"); rows.append(("queues",))
        values.update(SBO_TARGET_SELECTION_STATUS="0", TOTAL_CORE="2", TOTAL_EXTRA="3", SBO_OPTION_RECORD_COUNT="4",
                      SBO_TARGET_SELECTION_ERROR="supplied selection error", SBODIR="supplied-repository")
        files.update(core=b"built-core\n", extra=b"built-extra\n")
        if c["OPTION_PATH"]: files["options"] = b"built-options\n"
        if c["QUEUE_RETURN"]:
            values["SBO_TARGET_SELECTION_STATUS"] = "1"; sbo, raw = "failed", 1
            done("sbo", "build_queues", "failed", "SBo target selection failed: supplied selection error", 1)
        else:
            done("sbo", "build_queues", "success", "Deterministic SBo target sets built")
    else:
        sbo, raw = c["IDLE_STATE"], 0
        values["SBODIR"] = "supplied-fallback"
        done("sbo", "synchronize", sbo, "SBo repository synchronization was not applicable: " + idle("sbo"))
        done("sbo", "build_queues", sbo, "SBo queue generation was not applicable: " + idle("sbo"))
    if not c["SBO_RUN"] or c["QUEUE_RETURN"]:
        files.update(core=b"", extra=b"")
        if c["OPTION_PATH"]: files["options"] = b""
        values.update(TOTAL_CORE="0", TOTAL_EXTRA="0", SBO_OPTION_RECORD_COUNT="0")
    rows.append(("module-started", "elf", "ELF dependency module started"))
    if c["ELF_RUN"]:
        start("elf", "scan_dependencies", "Scanning ELF dependencies statically"); rows.append(("scan",))
        files["broken"] = b"supplied-object\n" if c["BROKEN_PAYLOAD"] else b""
        if not c["ELF_SCAN_RETURN"]:
            rows.append(("map",)); files["extra"] = b"mapped-extra\n"; values["TOTAL_EXTRA"] = "5"
        if c["ELF_SCAN_RETURN"] or c["ELF_MAP_RETURN"]:
            elf, sbo, raw = "failed", "failed", 1; values["SBO_TARGET_SELECTION_STATUS"] = "1"
            done("elf", "scan_dependencies", "failed", "Static ELF inspection or ownership mapping failed", 1)
        else:
            elf = "warning" if c["BROKEN_PAYLOAD"] else "success"
            done("elf", "scan_dependencies", elf, "ELF dependency scan completed")
    else:
        elf = c["IDLE_STATE"]; files["broken"] = b""
        done("elf", "scan_dependencies", elf, "ELF dependency scan was not applicable: " + idle("elf"))
    module_done("elf", elf, "ELF dependency module completed")
    if c["SBO_RUN"] and values["SBO_TARGET_SELECTION_STATUS"] == "0":
        start("sbo", "process_queue", "Processing the final SBo queue"); rows.append(("process",))
        values["SBO_BUILD_STATUS"] = str(c["BUILD_CODE"])
        raw = max(c["BUILD_CODE"], 0)
        if raw: sbo = "failed"
        done("sbo", "process_queue", sbo, "Final SBo queue processing completed", raw)
    elif c["SBO_RUN"]:
        sbo, raw = "failed", 1
        done("sbo", "process_queue", sbo, "SBo queue processing was blocked because target selection failed", 1)
    else:
        done("sbo", "process_queue", sbo, "SBo queue processing was not applicable: " + idle("sbo"))
    module_done("sbo", sbo, "SBo update module completed", raw)
    rows.append(("module-started", "cinnamon", "Cinnamon rebuild module started"))
    raw = 0
    if c["CINNAMON_RUN"]:
        start("cinnamon", "rebuild", "Evaluating and rebuilding Cinnamon when required"); rows.append(("cinnamon",))
        values["CINNAMON_TRIGGER"] = str(c["TRIGGER"])
        cinnamon = {0: "skipped", 1: "failed", 2: "success", 3: "failed"}.get(c["TRIGGER"], "skipped")
        raw = 1 if c["TRIGGER"] in (1, 3) else 0
        done("cinnamon", "rebuild", cinnamon, "Cinnamon rebuild action completed", raw)
    else:
        cinnamon = c["IDLE_STATE"]
        done("cinnamon", "rebuild", cinnamon, "Cinnamon rebuild was not applicable: " + idle("cinnamon"))
    module_done("cinnamon", cinnamon, "Cinnamon rebuild module completed", raw)
    rows += [("boot",), ("summary", "success", flat, sbo, elf, cinnamon, raw)]
    return rows, values, files


def encoded(rows):
    return b"".join(b"".join(str(v).encode() + b"\0" for v in row) + b"\n" for row in rows)


def run_case(work, case):
    rows, values, files = expected(case)
    trace = work / "callback trace"
    fields = tuple(initial_state(case))
    for aux in (0, 19):
        trace.write_bytes(b"")
        for name in files: (work / name).write_bytes(("stale-" + name + "\n").encode())
        settings = initial_state(case) | {k: str(v) for k, v in case.items()}
        settings.update(AUX_RETURN=str(aux), BOOT_RETURN="255" if aux else "0", QUEUE_CORE=str(work / "core"),
                        QUEUE_EXTRA=str(work / "extra"), BROKEN=str(work / "broken"), SBO_QUEUE_DIR_FALLBACK="supplied-fallback",
                        SBO_OPTION_RECORDS=str(work / "options") if case["OPTION_PATH"] else "")
        assignments = "\n".join(f"{name}={shlex.quote(value)}" for name, value in settings.items())
        driver = DRIVER + GUARDS + "\n" + assignments + r'''
IFS='|: '
action_exit=777; slackware_state=outer-slackware; flatpak_state=outer-flatpak
sbo_state=outer-sbo; elf_state=outer-elf; cinnamon_state=outer-cinnamon
run_status=0
run_apply_workflow || run_status=$?
''' + "printf '%s\\0' \"$run_status\" " + " ".join(f'"${{{name}}}"' for name in fields) + r''' "$IFS" "$action_exit" "$slackware_state" "$flatpak_state" "$sbo_state" "$elf_state" "$cinnamon_state"
'''
        result = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "apply-secondary-test", str(REFERENCE), str(trace)],
                                cwd=work, capture_output=True, timeout=10)
        label = (case, aux)
        assert result.returncode == 0 and result.stderr == b"", (label, result.returncode, result.stderr)
        packet = b"".join(str(v).encode() + b"\0" for v in (aux, *values.values(), "|: ", 777, "outer-slackware",
                                                         "outer-flatpak", "outer-sbo", "outer-elf", "outer-cinnamon"))
        assert result.stdout == packet, (label, result.stdout, packet)
        assert trace.read_bytes() == encoded(rows), (label, trace.read_bytes(), rows)
        for name, raw in files.items(): assert (work / name).read_bytes() == raw, (label, name)
        assert sorted(p.name for p in work.iterdir()) == ["broken", "callback trace", "core", "extra", "options"], label


def main():
    scenarios = list(cases())
    with tempfile.TemporaryDirectory(prefix="slack-update-apply-secondary-") as directory:
        for index, case in enumerate(scenarios):
            work = Path(directory) / ("case " + str(index)); work.mkdir()
            run_case(work, case)
    print(f"Apply secondary workflow: {len(scenarios)} scenarios, {2 * len(scenarios)} workflow entries, 0 failures")


if __name__ == "__main__":
    main()
