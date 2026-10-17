#!/usr/bin/env python3
"""Check exact human planning output from supplied state and private files."""

from pathlib import Path
import itertools
import shlex
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
GOLDEN = ROOT / "tests/fixtures/reference/dry-run-plan-base.txt"
MODULES = ("FLATPAK", "SBO", "ELF", "CINNAMON", "BOOT")
# mode, activation state, run flag, authored output branch
PROFILES = (
    ("disabled", "disabled", 0, "disabled"),
    ("enabled", "unavailable", 0, "enabled-missing"),
    ("auto", "unavailable", 0, "auto-missing"),
    ("auto", "available", 1, "active"),
    ("enabled", "available", 1, "active"),
    ("disabled", "disabled", 1, "active"),
    ("enabled", "disabled", 0, "disabled"),
)
LABELS = {"FLATPAK": (2, "Flatpak", "Flatpak installation", "no Flatpak command would run"),
          "SBO": (4, "SBo", "SBo toolchain", "repository synchronization and builds would not run"),
          "ELF": (5, "ELF diagnostics", "ELF diagnostics backend", "no ELF object would be inspected"),
          "CINNAMON": (6, "Cinnamon", "Cinnamon installation", "graphical ABI changes would not trigger a rebuild"),
          "BOOT": (7, "Boot preparation", "boot preparation path", "kernel changes would not run initrd or GRUB actions")}
FILE_DATA = {
    "ABI_CANDIDATES": b"abi-z\nabi-a\nabi-z\n",
    "QUEUE_CORE": b"queue-z\nqueue-a\n",
    "QUEUE_EXTRA": b"elf-z\n",
    "BROKEN": b'/private/ELF "one"\n/path with spaces/two\\literal\n',
    "SBO_OPTION_RECORDS": b'zeta\tCFLAGS="-O2 -g"\nalpha\tPREFIX=/opt/a b\\c\nempty\t\n',
}
FILE_LINES = {
    "ABI_CANDIDATES": "      - abi-z\n      - abi-a\n      - abi-z\n",
    "QUEUE_CORE": "      - queue-z\n      - queue-a\n",
    "QUEUE_EXTRA": "      - elf-z\n",
    "BROKEN": '      - /private/ELF "one"\n      - /path with spaces/two\\literal\n',
    "SBO_OPTION_RECORDS": '      - zeta | CFLAGS="-O2 -g"\n      - alpha | PREFIX=/opt/a b\\c\n      - empty | \n',
}
PREFIX = r'''
source "$1"
TRACE=$2
trace() { printf '%s\0' "$@" >> "$TRACE"; printf '\n' >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
date() {
    [[ $# == 0 ]] || forbidden date-arguments
    trace date
    printf '%s\n' "$FIXED_DATE"
    return "$CLOCK_RETURN"
}
sed() {
    [[ $# == 2 && $1 == 's/^/      - /' ]] || forbidden sed-arguments
    case "$2" in "$ABI_CANDIDATES"|"$QUEUE_CORE"|"$QUEUE_EXTRA"|"$BROKEN") ;;
        *) forbidden sed-path ;; esac
    trace sed "$@"
    builtin command sed "$@"
}
'''
FORBIDDEN = (
    "main", "initialize_runtime", "initialize_runtime_state", "initialize_dry_run_runtime", "load_configuration",
    "inspect_dry_run_environment", "probe_optional_modules", "probe_boot_module", "run_check_workflow",
    "run_dry_run_workflow", "run_apply_workflow", "check_slackware_updates", "inspect_current_sbo_queues",
    "inspect_current_elf_state", "slackpkg", "sbopkg", "sqg", "flatpak", "readelf", "mkinitrd",
    "grub-mkconfig", "grub-script-check", "git", "curl", "wget", "print_json_result", "emit_final_events",
)
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)


def cases():
    for check, install, upgrade in itertools.product((0, 100, 69), ("true", "false"), ("true", "false")):
        yield dict(CHECK_STATUS=check, SLACKWARE_INSTALL_NEW=install, SLACKWARE_UPGRADE_ALL=upgrade), {}, "empty"
    for module in ("FLATPAK", "SBO", "ELF", "CINNAMON"):
        for profile in PROFILES:
            variants = itertools.product((0, 1), repeat=2) if module == "CINNAMON" else [(0, 0)]
            for repository, builder in variants:
                updates = dict(PLAN_CINNAMON_REPOSITORY=repository, PLAN_CINNAMON_BUILDER=builder)
                for files in (("empty", "missing", "records") if module in ("SBO", "ELF") else ("records",)):
                    yield updates, {module: profile}, files
    for profile in PROFILES:
        if profile[3] != "active":
            yield {}, {"BOOT": profile}, "empty"
        else:
            for layout, initrd, grub in itertools.product(
                    ("unknown", "mkinitrd-managed", "direct-generic-no-initrd"), (0, 1), (0, 1)):
                yield dict(BOOT_PREPARATION_LAYOUT=layout, BOOT_INITRD_AVAILABLE=initrd,
                           BOOT_GRUB_AVAILABLE=grub), {"BOOT": profile}, "records"
    for files, check, install, upgrade in itertools.product(
            ("empty", "missing", "records"), (0, 100, 42), ("true", "false"), ("true", "false")):
        yield dict(CHECK_STATUS=check, SLACKWARE_INSTALL_NEW=install, SLACKWARE_UPGRADE_ALL=upgrade,
                   PLAN_CINNAMON_REPOSITORY=1, PLAN_CINNAMON_BUILDER=1,
                   BOOT_PREPARATION_LAYOUT="mkinitrd-managed", BOOT_INITRD_AVAILABLE=1,
                   BOOT_GRUB_AVAILABLE=1), dict.fromkeys(MODULES, PROFILES[4]), files
    for index, files in itertools.product(range(5), ("empty", "missing", "records")):
        yield {}, {module: PROFILES[(index + offset) % 5] for offset, module in enumerate(MODULES)}, files


def settings(work, updates, profiles, files):
    values = dict(CHECK_STATUS="0", SLACKWARE_INSTALL_NEW="true", SLACKWARE_UPGRADE_ALL="true",
                  BOOT_PREPARATION_LAYOUT="unknown", BOOT_INITRD_AVAILABLE="0", BOOT_GRUB_AVAILABLE="0",
                  PLAN_CINNAMON_REPOSITORY="0", PLAN_CINNAMON_BUILDER="0", CSB_BRANCH='branch "quoted"',
                  CSB_BUILDER="build helper.sh", INITRD_KERNEL_PACKAGE="kernel-generic",
                  FIXED_DATE="fixed planning clock", KERNEL_MODULES_DIRECTORY="/private/modules with spaces",
                  SBODIR='/private/queues $(printf injected)', CSB_DIR="/private/CSB checkout",
                  GRUB_CONFIG="/private/GRUB/grub.cfg", SBO_OPTIONS_FILE='/private/options "quoted"',
                  CONFIG_FILE='/private/config $(printf injected)', LOG='/private/log `printf injected`')
    for name in ("TOTAL_CORE", "SBO_OPTION_RECORD_COUNT", "PLAN_ABI_SBO_COUNT", "PLAN_BROKEN_SBO_COUNT", "PLAN_BROKEN_COUNT"):
        values[name] = str({"TOTAL_CORE": 17, "SBO_OPTION_RECORD_COUNT": 13, "PLAN_ABI_SBO_COUNT": 11,
                            "PLAN_BROKEN_SBO_COUNT": 7, "PLAN_BROKEN_COUNT": 5}[name] if files == "records" else 0)
    for name in FILE_DATA:
        values[name] = str(work / name.lower().replace("_", " "))
        if files != "missing":
            Path(values[name]).write_bytes(FILE_DATA[name] if files == "records" else b"")
    for module in MODULES:
        mode, state, run, _ = profiles.get(module, PROFILES[0])
        values.update({module + "_MODE": mode, module + "_MODULE_STATE": state,
                       module + "_MODULE_RUN": str(run), module + "_MODULE_REASON": "supplied " + module + " reason"})
    values.update({key: str(value) for key, value in updates.items()})
    return values


def render_expected(values, profiles, files):
    text = GOLDEN.read_text()
    text = text.replace("no updates reported since the last slackpkg update.", {
        "0": "no updates reported since the last slackpkg update.", "100": "updates are available."
    }.get(values["CHECK_STATUS"], "unavailable because the check failed."))
    for key, command in (("SLACKWARE_INSTALL_NEW", "install-new"), ("SLACKWARE_UPGRADE_ALL", "upgrade-all")):
        if values[key] == "false":
            text = text.replace("      slackpkg -batch=on -default_answer=y -postinst=off " + command,
                                "      (" + command + " disabled by configuration)")
    traces = []

    def contents(name):
        if files == "records":
            if name != "SBO_OPTION_RECORDS":
                traces.append(("sed", "s/^/      - /", values[name]))
            return FILE_LINES[name]
        return "      (none)\n"

    text = text.replace("      (none)\n", contents("ABI_CANDIDATES"), 1)
    bodies = {
        "FLATPAK": "  Planned command: flatpak update -y --noninteractive\n",
        "SBO": "  Planned repository commands: sbopkg -r, then sqg -a in a private queue workspace\n"
               "  Personal queue directory (read-only): @SBODIR@\n"
               "  Current local queue targets: @TOTAL_CORE@\n@CORE_LINES@"
               "  Persistent build-options file: @SBO_OPTIONS_FILE@\n"
               "  Preserved build-option records: @SBO_OPTION_RECORD_COUNT@\n@OPTION_LINES@"
               "  Current broken-ELF SBo targets: @PLAN_BROKEN_SBO_COUNT@\n@EXTRA_LINES@"
               "  Apply would copy regular personal .sqf files into an isolated workspace,\n"
               "  run sqg only there, preserve dependency constraints from the resulting queues,\n"
               "  then append unique ABI-triggered and broken-ELF targets deterministically.\n",
        "ELF": "  Current broken ELF objects detected statically: @PLAN_BROKEN_COUNT@\n@BROKEN_LINES@"
               "  The apply workflow would repeat this scan after Slackware changes.\n",
    }
    for module in MODULES:
        mode, state, _, branch = profiles.get(module, PROFILES[0])
        number, label, missing, disabled = LABELS[module]
        header = f"[{number}] {label}\n  Mode: {mode}\n  Activation state: {state}\n"
        if module == "BOOT":
            header += "  Preparation layout: @BOOT_PREPARATION_LAYOUT@\n"
        if branch == "disabled":
            body = f"  The module is disabled; {disabled}.\n"
        elif branch == "enabled-missing":
            body = f"  [ERROR] Enabled module requirements are missing: @{module}_MODULE_REASON@\n"
        elif branch == "auto-missing":
            body = f"  Auto mode found no applicable {missing}: @{module}_MODULE_REASON@\n"
        elif module == "CINNAMON":
            body = "  This phase remains conditional on a graphical ABI trigger.\n"
            body += ("  Existing CSB repository: @CSB_DIR@\n"
                     "  Planned repository action: git fetch followed by reset to origin/@CSB_BRANCH@\n"
                     if values["PLAN_CINNAMON_REPOSITORY"] == "1" else
                     "  No existing CSB checkout was found; apply would attempt to clone it when triggered.\n")
            body += ("  Cinnamon build command: @CSB_DIR@/@CSB_BUILDER@\n" if values["PLAN_CINNAMON_BUILDER"] == "1" else
                     "  The Cinnamon build script is not currently executable or present.\n")
        elif module == "BOOT":
            body = "  These actions remain conditional on kernel-generic, kernel-huge, or kernel-modules changes.\n"
            if values["BOOT_PREPARATION_LAYOUT"] == "direct-generic-no-initrd":
                body += "  Direct generic policy: no initrd is required or generated.\n"
                body += "  Before GRUB generation, apply must validate the new package-owned vmlinuz-VERSION symlink target and module tree.\n"
            elif values["BOOT_INITRD_AVAILABLE"] == "1":
                body += "  Planned initrd command: mkinitrd -F\n"
                body += "  Installed kernel source: validated post-update @INITRD_KERNEL_PACKAGE@ package record\n"
                body += "  Required modules path: @KERNEL_MODULES_DIRECTORY@/<installed-version>\n"
                body += "  KERNEL_VERSION must match the installed package before mkinitrd can run.\n"
            else:
                body += ("  [ERROR] initrd requirements are missing and would fail if triggered.\n" if mode == "enabled" else
                         "  Auto mode would omit initrd preparation because it is not applicable.\n")
            if values["BOOT_GRUB_AVAILABLE"] == "1":
                body += "  Planned GRUB generation: grub-mkconfig writes an owner-only temporary file beside @GRUB_CONFIG@\n"
                body += "  Planned GRUB validation: grub-script-check <temporary-config>\n"
                body += "  Planned GRUB installation: atomic replacement of @GRUB_CONFIG@ after validation\n"
            else:
                body += ("  [ERROR] GRUB requirements are missing and would fail if triggered.\n" if mode == "enabled" else
                         "  Auto mode would omit GRUB because no supported GRUB installation was detected.\n")
        else:
            body = bodies[module]
            for token, name in (("CORE_LINES", "QUEUE_CORE"), ("OPTION_LINES", "SBO_OPTION_RECORDS"),
                                ("EXTRA_LINES", "QUEUE_EXTRA"), ("BROKEN_LINES", "BROKEN")):
                if "@" + token + "@" in body:
                    body = body.replace("@" + token + "@", contents(name))
        begin = text.index(f"[{number}] {label}\n")
        end = text.index("\n[", begin)
        text = text[:begin] + header + body + text[end:]
    for key, value in values.items():
        text = text.replace("@" + key + "@", value)
    traces.append(("date",))
    return text.encode(), traces


def encoded(rows):
    return b"".join(b"".join(str(v).encode() + b"\0" for v in row) + b"\n" for row in rows)


def run_case(work, case):
    updates, profiles, files = case
    values = settings(work, updates, profiles, files)
    expected, trace_rows = render_expected(values, profiles, files)
    before = {p.name: p.read_bytes() for p in work.iterdir()}
    assignments = "\n".join(f"{key}={shlex.quote(value)}" for key, value in values.items())
    state = "printf '\\0%s\\0' \"$status\" \"$IFS\" " + " ".join(f'"${{{name}}}"' for name in values) + "\n"
    driver = PREFIX + GUARDS + "\n" + assignments + r'''
IFS='|: '
for repetition in 1 2; do
    CLOCK_RETURN=0
    [[ $repetition == 1 ]] || CLOCK_RETURN=19
    status=0
    print_dry_run_plan || status=$?
''' + state + "done\n"
    trace = work / "callback trace"
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "dry-run-plan-test",
                             str(REFERENCE), str(trace)], cwd=work, capture_output=True, timeout=10)
    assert result.returncode == 0 and result.stderr == b"", (case, result.returncode, result.stderr)
    packet = expected + b"".join(b"\0" + str(v).encode() + b"\0" for v in (0, "|: ", *values.values()))
    assert result.stdout == packet * 2, (case, result.stdout, packet * 2)
    assert trace.read_bytes() == encoded(trace_rows) * 2, (case, trace.read_bytes(), trace_rows)
    assert {p.name: p.read_bytes() for p in work.iterdir() if p != trace} == before, case


def main():
    scenarios = list(cases())
    with tempfile.TemporaryDirectory(prefix="slack-update-dry-run-plan-") as directory:
        for index, case in enumerate(scenarios):
            work = Path(directory) / str(index)
            work.mkdir()
            run_case(work, case)
    print(f"Dry-run plan: {len(scenarios)} scenarios, {2 * len(scenarios)} render calls, 0 failures")


if __name__ == "__main__":
    main()
