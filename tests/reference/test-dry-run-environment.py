#!/usr/bin/env python3
"""Check planning discovery gates with modeled commands and private predicates."""

from pathlib import Path
import itertools
import shlex
import stat
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
MODULES = ("FLATPAK", "SBO", "ELF", "BOOT", "CINNAMON")
COMMANDS = ("flatpak", "sbopkg", "sqg", "readelf", "mkinitrd", "grub-mkconfig", "grub-script-check")
FIELDS = (
    "PLAN_FLATPAK_AVAILABLE", "PLAN_SBOPKG_AVAILABLE", "PLAN_SQG_AVAILABLE", "PLAN_READELF_AVAILABLE",
    "PLAN_MKINITRD_AVAILABLE", "PLAN_GRUB_AVAILABLE", "PLAN_GRUB_VALIDATOR_AVAILABLE",
    "PLAN_MKINITRD_CONFIGURED", "PLAN_GRUB_CONFIGURED", "PLAN_CINNAMON_REPOSITORY", "PLAN_CINNAMON_BUILDER",
)
# name, configuration kind, GRUB kind, expected file predicate, expected directory predicate
BOOT_ROWS = (
    ("missing", "missing", "missing", 0, 0),
    ("regular", "file", "directory", 1, 1),
    ("wrong-types", "directory", "file", 0, 0),
    ("links", "file-link", "directory-link", 1, 1),
    ("broken-links", "broken-link", "broken-link", 0, 0),
    ("configuration-only", "file", "missing", 1, 0),
    ("grub-only", "missing", "directory", 0, 1),
    ("wrong-link-types", "directory-link", "file-link", 0, 0),
)
# name, checkout marker kind, builder kind, expected directory predicate, expected executable predicate
CINNAMON_ROWS = (
    ("missing", "missing", "missing", 0, 0),
    ("checkout-script", "directory", "executable", 1, 1),
    ("worktree-file", "file", "file", 0, 0),
    ("links", "directory-link", "executable-link", 1, 1),
    ("broken-links", "broken-link", "broken-link", 0, 0),
    ("checkout-only", "directory", "missing", 1, 0),
    ("builder-only", "missing", "executable", 0, 1),
    ("executable-directory", "file-link", "directory", 0, 1),
)
PREFIX = r'''
source "$1"
TRACE=$2
trace() { printf '%s\0' "$@" >> "$TRACE"; printf '\n' >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
command() {
    [[ $# == 2 && $1 == -v ]] || forbidden command-arguments
    trace lookup "$2"
    case "$2" in
        flatpak) (( HAS_0 == 1 )) ;;
        sbopkg) (( HAS_1 == 1 )) ;;
        sqg) (( HAS_2 == 1 )) ;;
        readelf) (( HAS_3 == 1 )) ;;
        mkinitrd) (( HAS_4 == 1 )) ;;
        grub-mkconfig) (( HAS_5 == 1 )) ;;
        grub-script-check) (( HAS_6 == 1 )) ;;
        *) forbidden "command:$2" ;;
    esac
}
function [ {
    if [[ $# == 3 && ( $1 == -f || $1 == -d || $1 == -x || $1 == -r || $1 == -L ) ]]; then
        [[ $3 == ']' ]] || forbidden predicate-arguments
        if [[ ( $1 == -f && $2 == "$MKINITRD_CONFIG" ) ||
              ( $1 == -d && $2 == "$GRUB_DIRECTORY" ) ||
              ( $1 == -d && $2 == "$CSB_DIR/.git" ) ||
              ( $1 == -x && $2 == "$CSB_DIR/$CSB_BUILDER" ) ]]; then
            trace predicate "$1" "$2"
        else
            forbidden "predicate:$1:$2"
        fi
    fi
    builtin [ "$@"
}
'''
FORBIDDEN = (
    "main", "initialize_runtime", "initialize_runtime_state", "initialize_dry_run_runtime",
    "load_configuration", "probe_optional_modules", "probe_boot_module", "run_check_workflow",
    "run_dry_run_workflow", "run_apply_workflow", "print_dry_run_plan", "date", "wget", "curl",
    "enumerate_package_database_records", *COMMANDS,
)
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)


def cases():
    disabled = dict.fromkeys(MODULES, "disabled")
    absent = (0,) * len(COMMANDS)
    for mode in ("disabled", "enabled", "auto"):
        for present in (0, 1):
            for module, index in (("FLATPAK", 0), ("ELF", 3)):
                available = list(absent)
                available[index] = present
                yield disabled | {module: mode}, available, BOOT_ROWS[0], CINNAMON_ROWS[0]
        for pair in itertools.product((0, 1), repeat=2):
            yield disabled | {"SBO": mode}, (0, *pair, 0, 0, 0, 0), BOOT_ROWS[0], CINNAMON_ROWS[0]
        for triple, layout in itertools.product(itertools.product((0, 1), repeat=3), BOOT_ROWS):
            yield disabled | {"BOOT": mode}, (0, 0, 0, 0, *triple), layout, CINNAMON_ROWS[0]
        for layout in CINNAMON_ROWS:
            yield disabled | {"CINNAMON": mode}, absent, BOOT_ROWS[0], layout
    for modes in itertools.product(("disabled", "enabled", "auto"), repeat=len(MODULES)):
        for available in ((1,) * len(COMMANDS), (1, 0, 1, 0, 1, 0, 1)):
            yield dict(zip(MODULES, modes)), available, BOOT_ROWS[3], CINNAMON_ROWS[3]


def fixture(path, kind):
    path.parent.mkdir(parents=True, exist_ok=True)
    if kind == "missing":
        return
    if kind.endswith("-link"):
        target = path.with_name(path.name + ".target")
        if kind != "broken-link":
            fixture(target, kind.removesuffix("-link"))
        path.symlink_to(target.name)
    elif kind == "directory":
        path.mkdir()
        path.chmod(0o755)
    else:
        assert kind in ("file", "executable"), kind
        path.write_bytes(b"private planning fixture\n")
        path.chmod(0o755 if kind == "executable" else 0o644)


def snapshot(work):
    result = {}
    for path in work.rglob("*"):
        if path.name == "callback trace":
            continue
        mode = path.lstat().st_mode
        contents = path.readlink().as_posix() if path.is_symlink() else (
            path.read_bytes() if stat.S_ISREG(mode) else None)
        result[path.relative_to(work).as_posix()] = (mode, contents)
    return result


def expected(modes, available, boot, cinnamon, settings):
    flags = [0] * len(FIELDS)
    trace = []
    for module, indexes in (("FLATPAK", (0,)), ("SBO", (1, 2)), ("ELF", (3,)), ("BOOT", (4, 5, 6))):
        if modes[module] != "disabled":
            for index in indexes:
                flags[index] = available[index]
                trace.append(("lookup", COMMANDS[index]))
    if modes["BOOT"] != "disabled":
        flags[7:9] = boot[3:5]
        trace += [("predicate", "-f", settings["MKINITRD_CONFIG"]),
                  ("predicate", "-d", settings["GRUB_DIRECTORY"])]
    if modes["CINNAMON"] != "disabled":
        flags[9:11] = cinnamon[3:5]
        trace += [("predicate", "-d", settings["CSB_DIR"] + "/.git"),
                  ("predicate", "-x", settings["CSB_DIR"] + "/" + settings["CSB_BUILDER"])]
    # The helper has no explicit return; the final conditional supplies this status.
    status = int(modes["CINNAMON"] != "disabled" and not cinnamon[4])
    return status, flags, trace


def run_case(work, modes, available, boot, cinnamon):
    settings = {module + "_MODE": mode for module, mode in modes.items()}
    settings |= dict(MKINITRD_CONFIG=str(work / "mkinitrd config"), GRUB_DIRECTORY=str(work / "GRUB directory"),
                     CSB_DIR=str(work / "managed checkout"), CSB_BUILDER="build helper.sh")
    fixture(Path(settings["MKINITRD_CONFIG"]), boot[1])
    fixture(Path(settings["GRUB_DIRECTORY"]), boot[2])
    fixture(Path(settings["CSB_DIR"]) / ".git", cinnamon[1])
    fixture(Path(settings["CSB_DIR"]) / settings["CSB_BUILDER"], cinnamon[2])
    before = snapshot(work)
    status, flags, rows = expected(modes, available, boot, cinnamon, settings)
    assignments = "\n".join(f"{key}={shlex.quote(value)}" for key, value in settings.items())
    assignments += "\n" + "\n".join(f"HAS_{i}={value}" for i, value in enumerate(available))
    poison = "\n".join(f"{name}=987" for name in FIELDS)
    output = "printf '%s\\0' \"$status\" " + " ".join(f'"${{{name}}}"' for name in FIELDS)
    output += ' "$IFS" ' + " ".join(f'"${{{name}}}"' for name in settings) + "\n"
    driver = PREFIX + GUARDS + "\n" + assignments + "\nIFS='|: '\nfor repetition in 1 2; do\n"
    driver += poison + "\ninspect_dry_run_environment\nstatus=$?\n" + output + "done\n"
    trace = work / "callback trace"
    trace.write_bytes(b"")
    process = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "dry-run-environment-test",
                              str(REFERENCE), str(trace)], cwd=work, capture_output=True, timeout=10)
    label = (modes, available, boot[0], cinnamon[0])
    assert process.returncode == 0 and process.stderr == b"", (label, process.returncode, process.stderr)
    packet = b"".join(str(v).encode() + b"\0" for v in (status, *flags, "|: ", *settings.values()))
    assert process.stdout == packet * 2, (label, process.stdout, packet * 2)
    encoded = b"".join(b"".join(str(v).encode() + b"\0" for v in row) + b"\n" for row in rows)
    assert trace.read_bytes() == encoded * 2, (label, trace.read_bytes(), rows)
    assert snapshot(work) == before, label


def main():
    scenarios = list(cases())
    with tempfile.TemporaryDirectory(prefix="slack-update-dry-run-environment-") as directory:
        for index, case in enumerate(scenarios):
            work = Path(directory) / str(index)
            work.mkdir()
            run_case(work, *case)
    print(f"Dry-run environment: {len(scenarios)} scenarios, {2 * len(scenarios)} inspection calls, 0 failures")


if __name__ == "__main__":
    main()
