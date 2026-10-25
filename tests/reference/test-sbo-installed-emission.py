#!/usr/bin/env python3
"""Compose package-name writer failures through real private installed selection."""
from collections import Counter
import itertools
import json
import os
from pathlib import Path
import shlex
import stat
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
PROFILES = {
    "empty": ([], []),
    "filtered": (["native-1.0-x86_64-1", "extra-1.0-noarch-1_SBo_extra", "malformed"], []),
    "one": (["alpha-1.0-x86_64-1_SBo"], ["alpha"]),
    "two": (["alpha-1.0-x86_64-1_SBo", "beta-1.0-noarch-1_SBo"], ["alpha", "beta"]),
    "duplicates": (["alpha-1.0-x86_64-1_SBo", "alpha-2.0-i586-2_SBo", "beta-1.0-noarch-1_SBo"], ["alpha", "alpha", "beta"]),
    "symlink": (["alpha-1.0-x86_64-1_SBo", "alpha-2.0-i586-2_SBo", "beta-1.0-noarch-1_SBo"], ["alpha", "alpha", "beta"]),
}
SETUP = r'''
source "$1"
TEST_ROOT=$2
record() { local IFS='|'; builtin printf '%s\n' "$*" >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
printf() {
    if [[ ${FUNCNAME[1]} == package_names_with_build_suffix_from_stream ]]; then
        [[ $# == 2 && $1 == '%s\n' && ( $2 == alpha || $2 == beta ) ]] || forbidden writer-vector
        WRITES=$((WRITES + 1))
        record write "$WRITES" "$2"
        if [[ $WRITER != normal && ( $WRITER == all-* || $WRITES == 1 ) ]]; then
            record fault "$WRITES" "$WRITER" "$WRITER_STATUS"
            if [[ $WRITER == *-late ]]; then builtin printf "$@"; fi
            return "$WRITER_STATUS"
        fi
    fi
    builtin printf "$@"
}
find() {
    [[ ${FUNCNAME[1]} == enumerate_package_database_records && $# == 8 && $1 == -H \
        && $2 == "$PACKAGE_DATABASE" && $3 == -maxdepth && $4 == 1 && $5 == -type \
        && $6 == f && $7 == -printf && $8 == '%f\n' ]] || forbidden find-vector
    record enumerate
    builtin command find "$@"
}
mktemp() {
    local caller=${FUNCNAME[1]} value kind
    if [[ $caller == collect_installed_sbo_targets && $# == 0 ]]; then
        kind=records
    elif [[ $caller == collect_installed_sbo_targets && $# == 1 && $1 == "$TEST_ROOT/.sbo-targets.XXXXXX" ]]; then
        kind=candidate
    elif [[ $caller == normalize_sbo_target_names_from_stream && $# == 0 ]]; then
        kind=normalizer
    else
        forbidden mktemp-vector
    fi
    value=$(builtin command mktemp "$@") || forbidden real-mktemp
    [[ $value == "$TEST_ROOT/"* ]] || forbidden mktemp-path
    record allocate "$kind" "$value"
    builtin printf '%s\n' "$value"
}
sort() {
    [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 2 \
        && $1 == -u && $2 == "$TEST_ROOT/tmp."* && $LC_ALL == C ]] || forbidden sort-vector
    record normalize "$2"
    builtin command sort "$@"
}
mv() {
    [[ ${FUNCNAME[1]} == collect_installed_sbo_targets && $# == 4 && $1 == -f \
        && $2 == -- && $3 == "$TEST_ROOT/.sbo-targets."* && $4 == "$TEST_ROOT/selected" ]] || forbidden mv-vector
    record publish "$3"
    builtin command mv "$@"
}
rm() {
    local caller=${FUNCNAME[1]} path
    [[ $caller == collect_installed_sbo_targets || $caller == normalize_sbo_target_names_from_stream ]] || forbidden rm-caller
    [[ $# -ge 2 && $1 == -f ]] || forbidden rm-vector
    for path in "${@:2}"; do
        [[ $path == "$TEST_ROOT/tmp."* || $path == "$TEST_ROOT/.sbo-targets."* ]] || forbidden rm-path
        record remove "$caller" "$path"
    done
    builtin command rm "$@"
}
'''
GUARDS = (
    "main", "initialize_execution_environment", "load_configuration", "initialize_runtime",
    "initialize_dry_run_runtime", "configure_logging", "run_apply_workflow", "run_check_workflow",
    "run_dry_run_workflow", "collect_installed_sbo_candidates", "add_abi_rebuild_targets",
    "map_broken_objects_to_sbo_packages", "detect_broken_elf_objects", "verify_broken_elf_objects_after_rebuild",
    "slackpkg", "sbopkg", "sqg", "flatpak", "readelf", "ldd", "ldconfig", "git", "curl", "wget",
    "regenerate_initrd", "update_grub_configuration",
)


def inventory(root):
    result = {}
    for path in root.rglob("*"):
        if path == root / "trace":
            continue
        mode = stat.S_IMODE(path.lstat().st_mode)
        value = ("link", mode, os.readlink(path)) if path.is_symlink() else (
            ("directory", mode) if path.is_dir() else ("file", mode, path.read_bytes()))
        result[path.relative_to(root).as_posix()] = value
    return result


def scenario(root, profile, writer, conditional, seeded):
    records, selected = PROFILES[profile]
    database = root / "packages"
    database.mkdir(mode=0o700)
    for name in records:
        path = database / name
        path.write_text("private inert package manifest\n")
        path.chmod(0o600)
    if profile != "empty":
        (database / "ignored-directory-1.0-noarch-1_SBo").mkdir(mode=0o700)
        if records:
            (database / "ignored-link-1.0-noarch-1_SBo").symlink_to(records[0])
    if profile == "symlink":
        (root / "database-alias").symlink_to("packages", target_is_directory=True)
        argument = root / "database-alias"
    else:
        argument = database
    destination = root / "selected"
    if seeded:
        destination.write_text("previous-selected\n")
        destination.chmod(0o640)
    (root / "sentinel").write_text("unchanged\n")
    (root / "sentinel").chmod(0o600)
    expected = inventory(root)
    active = writer != "normal" and bool(selected)
    if not active:
        expected["selected"] = ("file", 0o600, "".join(name + "\n" for name in sorted(set(selected))).encode())
    error = "cannot normalize installed SBo package targets" if active else ""
    code = {"normal": 0, "first-quiet": 43, "first-late": 127, "all-quiet": 1, "all-late": 43}[writer]
    settings = dict(PACKAGE_DATABASE=argument, SBO_PACKAGE_TAG="_SBo", SBO_TARGET_SELECTION_ERROR="old-error",
        TOTAL_EXTRA=9, PLAN_ABI_SBO_COUNT=8, TOTAL_CORE=7, SBO_OPTION_RECORD_COUNT=6,
        WRITER=writer, WRITER_STATUS=code, WRITES=0)
    shell = SETUP + "\n" + "\n".join(name + "() { forbidden " + name + "; }" for name in GUARDS)
    shell += "\n" + "\n".join(name + "=" + shlex.quote(str(value)) for name, value in settings.items()) + "\n"
    shell += "IFS='|: '\nsaved_ifs=$IFS\ndestination=outer-destination\npackage_records=outer-records\ncandidate=outer-candidate\ndestination_directory=outer-directory\nemission_failed=123\n"
    if conditional:
        shell += 'if collect_installed_sbo_targets "$TEST_ROOT/selected"; then result=0; else result=$?; fi\n'
    else:
        shell += 'collect_installed_sbo_targets "$TEST_ROOT/selected"\nresult=$?\n'
    shell += '[[ $IFS == "$saved_ifs" && $destination == outer-destination && $package_records == outer-records && $candidate == outer-candidate && $destination_directory == outer-directory && $emission_failed == 123 ]] || exit 96\n'
    shell += 'builtin printf "\\0STATE\\0%s\\0%s\\0%s\\0%s\\0%s\\0%s\\0" "$result" "$SBO_TARGET_SELECTION_ERROR" "$TOTAL_EXTRA" "$PLAN_ABI_SBO_COUNT" "$TOTAL_CORE" "$SBO_OPTION_RECORD_COUNT"\n'
    completed = subprocess.run(["bash", "--noprofile", "--norc", "-c", shell, "installed-emission", str(REFERENCE), str(root)],
        capture_output=True, cwd=root, env=dict(os.environ, LC_ALL="C", TMPDIR=str(root)), timeout=15)
    wanted = b"\0STATE\0" + b"\0".join(str(value).encode() for value in [1 if active else 0, error, 9, 8, 7, 6]) + b"\0"
    label = dict(profile=profile, writer=writer, conditional=conditional, seeded=seeded)
    assert (completed.returncode, completed.stdout, completed.stderr) == (0, wanted, b""), (label, completed, wanted)
    events = [line.split("|") for line in (root / "trace").read_text().splitlines()]
    assert Counter(e[0] for e in events) == Counter(allocate=3, enumerate=1, write=len(selected),
        fault=(len(selected) if writer.startswith("all-") else 1) if active else 0,
        normalize=1, publish=0 if active else 1, remove=3 if active else 2), (label, events)
    allocations = {e[1]: e[2] for e in events if e[0] == "allocate"}
    assert set(allocations) == {"records", "candidate", "normalizer"} and len(set(allocations.values())) == 3
    assert [e for e in events if e[0] == "normalize"] == [["normalize", allocations["normalizer"]]]
    writes = [e for e in events if e[0] == "write"]
    assert [e[1] for e in writes] == [str(i) for i in range(1, len(selected) + 1)]
    assert Counter(e[2] for e in writes) == Counter(selected), (label, events)
    faults = [e for e in events if e[0] == "fault"]
    expected_indices = list(range(1, len(selected) + 1)) if active and writer.startswith("all-") else [1] if active else []
    assert faults == [["fault", str(i), writer, str(code)] for i in expected_indices]
    removes = Counter(tuple(e[1:]) for e in events if e[0] == "remove")
    expected_removes = Counter([
        ("normalize_sbo_target_names_from_stream", allocations["normalizer"]),
        ("collect_installed_sbo_targets", allocations["records"]),
    ] + ([("collect_installed_sbo_targets", allocations["candidate"])] if active else []))
    assert removes == expected_removes, (label, events)
    publishes = [e for e in events if e[0] == "publish"]
    assert publishes == ([] if active else [["publish", allocations["candidate"]]])
    assert inventory(root) == expected, (label, inventory(root), expected)
    normalized = [[next(("<" + kind.upper() + ">" for kind, value in allocations.items() if field == value), field)
                   for field in event] for event in events]
    return label | dict(active_fault=active, inactive_fault=writer != "normal" and not selected,
        selected_names=selected, failed_emissions=expected_indices, raw_status=1 if active else 0,
        error=error, stdout=completed.stdout.decode(), stderr=completed.stderr.decode(), events=normalized,
        published=not active, prior_destination_preserved=active, private_inventory_exact=True)


def main():
    rows = []
    for cell in itertools.product(PROFILES, ("normal", "first-quiet", "first-late", "all-quiet", "all-late"), (False, True), (False, True)):
        with tempfile.TemporaryDirectory(prefix="installed-emission-test-") as temporary:
            rows.append(scenario(Path(temporary), *cell))
    totals = dict(cases=len(rows), active=sum(r["active_fault"] for r in rows),
        inactive=sum(r["inactive_fault"] for r in rows), normal=sum(r["writer"] == "normal" for r in rows),
        multiple_fault_cases=sum(len(r["failed_emissions"]) > 1 for r in rows),
        failed_emissions=sum(len(r["failed_emissions"]) for r in rows))
    assert totals == dict(cases=120, active=64, inactive=32, normal=24, multiple_fault_cases=24, failed_emissions=104), totals
    if len(sys.argv) == 3 and sys.argv[1] == "--report":
        Path(sys.argv[2]).write_text(json.dumps(dict(schema=1, totals=totals, rows=rows,
            scope="Real private installed enumeration/stream/normalization/sort/move; supplied writer failures; no native package database"),
            indent=2, sort_keys=True) + "\n")
    else:
        assert len(sys.argv) == 1, "usage: test-sbo-installed-emission.py [--report /absolute/report.json]"
    print("SBo installed emission: 120 scenarios PASS; 64 active refusals before publication; 32 inactive fault controls; 24 normal controls; private inventory preserved")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
