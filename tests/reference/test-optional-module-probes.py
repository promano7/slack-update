#!/usr/bin/env python3
"""Check optional-module probes using modeled availability and private checkout state."""

from pathlib import Path
import itertools
import shlex
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
DEFAULTS = dict(HAS_FLATPAK=0, HAS_SBOPKG=0, HAS_SQG=0, HAS_READELF=0,
                HAS_GIT=0, HAS_CINNAMON=0, INSTALLED=0, PACKAGE_PRESENT=0, LDCONFIG=0)
PREFIX = r'''
source "$1"
TRACE=$2
CSB_DIR_CONFIG=$3
trace() { printf '%s\n' "$1" >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
command() {
    [[ $# == 2 && $1 == -v ]] || forbidden command-arguments
    trace "lookup:$2"
    case "$2" in
        flatpak) (( HAS_FLATPAK == 1 )) ;;
        sbopkg) (( HAS_SBOPKG == 1 )) ;;
        sqg) (( HAS_SQG == 1 )) ;;
        readelf) (( HAS_READELF == 1 )) ;;
        git) (( HAS_GIT == 1 )) ;;
        cinnamon) (( HAS_CINNAMON == 1 )) ;;
        *) forbidden "command:$2" ;;
    esac
}
function [ {
    if [[ $# == 3 && $1 == -x && $2 == /sbin/ldconfig && $3 == ']' ]]; then
        trace predicate:ldconfig
        (( LDCONFIG == 1 )); return
    fi
    if [[ $# == 3 && $1 == -d && $2 == "$CSB_DIR_CONFIG/.git" && $3 == ']' ]]; then
        trace predicate:checkout
    elif [[ $# == 3 && ( $1 == -x || $1 == -d || $1 == -f || $1 == -r || $1 == -L ) ]]; then
        forbidden "path:$2"
    fi
    builtin [ "$@"
}
package_database_contains_name() {
    [[ $# == 1 && $1 == cinnamon ]] || forbidden package-arguments
    trace packages:cinnamon
    (( PACKAGE_PRESENT == 1 ))
}
'''
FORBIDDEN = (
    "main", "initialize_runtime", "initialize_runtime_state", "load_configuration",
    "probe_boot_module", "run_check_workflow", "run_apply_workflow", "run_dry_run_workflow",
    "enumerate_package_database_records", "flatpak", "sbopkg", "sqg", "readelf", "git",
)
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)
FIELDS = {
    "flatpak": ("FLATPAK_MODULE_STATE", "FLATPAK_MODULE_RUN", "FLATPAK_MODULE_REASON"),
    "sbo": ("SBO_MODULE_STATE", "SBO_MODULE_RUN", "SBO_MODULE_REASON", "SBO_SBOPKG_AVAILABLE", "SBO_SQG_AVAILABLE"),
    "elf": ("ELF_MODULE_STATE", "ELF_MODULE_RUN", "ELF_MODULE_REASON", "ELF_READELF_AVAILABLE", "ELF_LDCONFIG_AVAILABLE"),
    "cinnamon": ("CINNAMON_MODULE_STATE", "CINNAMON_MODULE_RUN", "CINNAMON_MODULE_REASON", "CINNAMON_INSTALLED", "CINNAMON_GIT_AVAILABLE"),
    "detect": (),
}
SBO_ROWS = {
    (0, 0): ("unavailable", 0, "sbopkg and sqg are not installed", 0, 0),
    (0, 1): ("unavailable", 0, "sbopkg is not installed", 0, 1),
    (1, 0): ("unavailable", 0, "sqg is not installed", 1, 0),
    (1, 1): ("available", 1, "", 1, 1),
}
ELF_ROWS = {
    (0, 0): ("unavailable", 0, "readelf and /sbin/ldconfig are unavailable", 0, 0),
    (0, 1): ("unavailable", 0, "readelf is unavailable", 0, 1),
    (1, 0): ("unavailable", 0, "/sbin/ldconfig is unavailable", 1, 0),
    (1, 1): ("available", 1, "", 1, 1),
}
CINNAMON_ROWS = {
    ("enabled", 0, 0): ("unavailable", 0, "git is unavailable", 0, 0),
    ("enabled", 0, 1): ("available", 1, "", 0, 1),
    ("enabled", 1, 0): ("unavailable", 0, "git is unavailable", 1, 0),
    ("enabled", 1, 1): ("available", 1, "", 1, 1),
    ("auto", 0, 0): ("unavailable", 0, "no Cinnamon installation or managed CSB checkout was detected", 0, 0),
    ("auto", 0, 1): ("unavailable", 0, "no Cinnamon installation or managed CSB checkout was detected", 0, 1),
    ("auto", 1, 0): ("unavailable", 0, "git is unavailable", 1, 0),
    ("auto", 1, 1): ("available", 1, "", 1, 1),
}


def cases():
    for mode in ("disabled", "enabled", "auto"):
        for available in (0, 1):
            row = ("disabled", 0, "disabled by configuration") if mode == "disabled" else (
                ("available", 1, "") if available else ("unavailable", 0, "flatpak is not installed"))
            yield "flatpak", mode, dict(HAS_FLATPAK=available), False, (0, *row), ([] if mode == "disabled" else ["lookup:flatpak"])
        for first, second in itertools.product((0, 1), repeat=2):
            for kind, rows, values, lookups in (
                ("sbo", SBO_ROWS, dict(HAS_SBOPKG=first, HAS_SQG=second), ["lookup:sbopkg", "lookup:sqg"]),
                ("elf", ELF_ROWS, dict(HAS_READELF=first, LDCONFIG=second), ["lookup:readelf", "predicate:ldconfig"]),
                ("cinnamon", CINNAMON_ROWS, dict(INSTALLED=first, HAS_GIT=second), ["detect-cinnamon", "lookup:git"]),
            ):
                row = ("disabled", 0, "disabled by configuration", 0, 0) if mode == "disabled" else (
                    rows[(mode, first, second)] if kind == "cinnamon" else rows[(first, second)])
                yield kind, mode, values, False, (0, *row), ([] if mode == "disabled" else lookups)
    for command, package, checkout in itertools.product((0, 1), repeat=3):
        lookups = ["lookup:cinnamon"]
        if not command:
            lookups.append("packages:cinnamon")
            if not package:
                lookups.append("predicate:checkout")
        yield ("detect", "auto", dict(HAS_CINNAMON=command, PACKAGE_PRESENT=package),
               bool(checkout), (0 if command or package or checkout else 1,), lookups)


def run_cases():
    count = 0
    with tempfile.TemporaryDirectory(prefix="slack-update-module-probes-") as directory:
        work = Path(directory)
        trace, checkout = work / "trace", work / "managed checkout"
        checkout.mkdir()
        for kind, mode, values, has_checkout, expected, lookups in cases():
            git_directory = checkout / ".git"
            if git_directory.exists():
                git_directory.rmdir()
            if has_checkout:
                git_directory.mkdir()
            trace.write_bytes(b"")
            assignments = DEFAULTS | values | {kind.upper() + "_MODE": mode}
            setup = "\n".join(f"{key}={shlex.quote(str(value))}" for key, value in assignments.items())
            if kind != "detect":
                setup += '\ndetect_cinnamon_installation() { trace detect-cinnamon; (( INSTALLED == 1 )); }\n'
            fields = FIELDS[kind]
            poison = "\n".join(f"{name}=stale" for name in fields)
            function = "detect_cinnamon_installation" if kind == "detect" else f"probe_{kind}_module"
            output = 'printf \'%s\\0\' "$status" ' + " ".join(f'"${{{name}}}"' for name in fields) + ' "$IFS"\n'
            driver = PREFIX + GUARDS + "\n" + setup + "\nIFS='|: '\nfor repetition in 1 2; do\n" + poison + "\n" + function + '\nstatus=$?\n' + output + "done\n"
            result = subprocess.run(
                ["bash", "--noprofile", "--norc", "-c", driver, "module-probe-test",
                 str(REFERENCE), str(trace), str(checkout)], cwd=work, capture_output=True, timeout=10)
            label = (kind, mode, values, has_checkout)
            assert result.returncode == 0 and result.stderr == b"", (label, result.returncode, result.stderr)
            packet = b"".join(str(value).encode() + b"\0" for value in (*expected, "|: "))
            assert result.stdout == packet * 2, (label, result.stdout, packet * 2)
            assert trace.read_bytes() == ("".join(line + "\n" for line in lookups) * 2).encode(), (label, trace.read_bytes(), lookups)
            assert git_directory.is_dir() == has_checkout, label
            count += 1
    return count


def main():
    count = run_cases()
    print(f"Optional module probes: {count} scenarios, {2 * count} probe calls, 0 failures")


if __name__ == "__main__":
    main()
