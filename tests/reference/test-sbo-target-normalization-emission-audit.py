#!/usr/bin/env python3
"""Freeze historical target-normalizer writer observations; NOT a safety test."""

import hashlib
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
HISTORICAL_SHA256 = "57f814acf7640c8023f209c37c517eefa7c430567ddfd4266602e139070e199c"
# Inputs, attempted valid writes and invalid-record outcomes are authored separately.
PROFILES = {
    "empty": ([], [], False),
    "blank": (["", ""], [], False),
    "one": (["alpha"], ["alpha"], False),
    "duplicates": (["beta", "alpha", "alpha", "gamma"], ["beta", "alpha", "alpha", "gamma"], False),
    "blank-tail": (["beta", "", "alpha", ""], ["beta", "alpha"], False),
    "invalid-first": (["-bad", "alpha"], [], True),
    "invalid-middle": (["beta", "@bad", "alpha"], ["beta"], True),
    "invalid-last": (["beta", "alpha", "bad/name"], ["beta", "alpha"], True),
}
WRITERS = {"normal": 0, "first-quiet": 43, "first-late": 127, "all-quiet": 1, "all-late": 43}
SETUP = r'''
source "$1"
TEST_ROOT=$2
TRACE=$TEST_ROOT/trace
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
record() { builtin printf '%s\0' "$@" >> "$TRACE"; builtin printf '\n' >> "$TRACE"; }
mktemp() {
    [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 0 ]] || forbidden allocation-vector
    local allocated
    allocated=$(builtin command mktemp) || return $?
    [[ $allocated == "$TEST_ROOT"/tmp.* && -f $allocated && ! -L $allocated ]] || forbidden allocation-path
    record allocate "$allocated"
    builtin printf '%s\n' "$allocated"
}
printf() {
    [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 2 && $1 == '%s\n' ]] || forbidden writer-vector
    [[ $2 == alpha || $2 == beta || $2 == gamma ]] || forbidden writer-name
    WRITES=$((WRITES + 1))
    record write "$WRITES" "$2"
    if [[ $WRITER != normal && ( $WRITER == all-* || $WRITES == 1 ) ]]; then
        record fault "$WRITES" "$WRITER" "$WRITER_STATUS"
        [[ $WRITER == *-late ]] || return "$WRITER_STATUS"
        builtin printf "$@"
        return "$WRITER_STATUS"
    fi
    builtin printf "$@"
}
sort() {
    [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 2 && $1 == -u && $2 == "$temporary" && $2 == "$TEST_ROOT"/tmp.* && -f $2 && ! -L $2 ]] || forbidden sort-vector
    record sort
    builtin command sort "$@"
}
rm() {
    [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 2 && $1 == -f && $2 == "$temporary" && $2 == "$TEST_ROOT"/tmp.* && -f $2 && ! -L $2 ]] || forbidden removal-vector
    record remove
    builtin command rm "$@"
}
'''
GUARDS = (
    "main", "load_configuration", "initialize_execution_environment", "initialize_runtime",
    "initialize_dry_run_runtime", "configure_logging", "run_apply_workflow", "run_check_workflow",
    "run_dry_run_workflow", "collect_installed_sbo_targets", "enumerate_package_database_records",
    "collect_sbo_targets_from_queue_directory", "collect_ordered_sbo_targets_from_queue_directory",
    "package_names_with_build_suffix_from_stream", "map_broken_objects_to_sbo_packages",
    "detect_broken_elf_objects", "verify_broken_elf_objects_after_rebuild", "slackpkg", "sbopkg", "sqg",
    "flatpak", "readelf", "ldd", "ldconfig", "git", "curl", "wget", "find", "touch", "mv", "cp",
    "regenerate_initrd", "update_grub_configuration",
)


def inventory(root):
    result = {}
    for path in root.iterdir():
        if path.name == "trace":
            continue
        info = path.lstat()
        assert stat.S_ISREG(info.st_mode), (path, info)
        result[path.name] = (stat.S_IMODE(info.st_mode), path.read_bytes())
    return result


def scenario(root, profile, writer, newline, conditional):
    inputs, attempted, invalid = PROFILES[profile]
    payload = "\n".join(inputs) + ("\n" if newline else "")
    (root / "input").write_text(payload)
    (root / "input").chmod(0o640)
    (root / "sentinel").write_text("unchanged\n")
    (root / "sentinel").chmod(0o600)
    (root / "trace").touch(mode=0o600)
    before = inventory(root)
    settings = dict(WRITER=writer, WRITER_STATUS=WRITERS[writer], WRITES=0)
    shell = SETUP + "\n".join(name + "() { forbidden " + name + "; }" for name in GUARDS)
    shell += "\n" + "\n".join(name + "=" + shlex.quote(str(value)) for name, value in settings.items()) + "\n"
    shell += "umask 077\nIFS='|: '\nsaved_ifs=$IFS\ntarget=outer-target\ntemporary=outer-temporary\nstatus=outer-status\n"
    operation = 'normalize_sbo_target_names_from_stream < "$TEST_ROOT/input"'
    shell += ("if " + operation + "; then raw=0; else raw=$?; fi\n" if conditional else operation + "\nraw=$?\n")
    shell += '[[ $IFS == "$saved_ifs" && $target == outer-target && $temporary == outer-temporary && $status == outer-status ]] || exit 96\n'
    shell += 'builtin printf "\\0STATUS\\0%s\\0" "$raw"\n'
    completed = subprocess.run(
        ["bash", "--noprofile", "--norc", "-c", shell, "target-normalization-audit", str(REFERENCE), str(root)],
        cwd=root, capture_output=True, env=dict(os.environ, LC_ALL="C", TMPDIR=str(root)), timeout=10,
    )
    faults = [] if writer == "normal" or not attempted else (
        list(range(1, len(attempted) + 1)) if writer.startswith("all-") else [1])
    retained = [name for i, name in enumerate(attempted, 1) if not (i in faults and writer.endswith("-quiet"))]
    # Historical status comes from validation or sort, never from the earlier writes.
    raw = 1 if invalid else 0
    output = "" if invalid else "".join(name + "\n" for name in sorted(set(retained)))
    expected = output.encode() + b"\0STATUS\0" + str(raw).encode() + b"\0"
    label = dict(profile=profile, writer=writer, final_newline=newline, conditional=conditional)
    assert (completed.returncode, completed.stdout, completed.stderr) == (0, expected, b""), (label, completed, expected)
    events = [row[:-1].decode().split("\0") for row in (root / "trace").read_bytes().splitlines()]
    assert len(events[0]) == 2 and events[0][0] == "allocate", (label, events)
    allocation = Path(events[0][1])
    assert allocation.parent == root and allocation.name.startswith("tmp."), (label, events)
    expected_events = [["allocate", "<TEMPORARY>"]]
    for i, name in enumerate(attempted, 1):
        expected_events.append(["write", str(i), name])
        if i in faults:
            expected_events.append(["fault", str(i), writer, str(WRITERS[writer])])
    if not invalid:
        expected_events.append(["sort"])
    expected_events.append(["remove"])
    normalized = [["allocate", "<TEMPORARY>"]] + events[1:]
    assert normalized == expected_events, (label, events, expected_events)
    assert inventory(root) == before and not allocation.exists(), (label, inventory(root), before)
    assert stat.S_IMODE((root / "trace").stat().st_mode) == 0o600
    return label | dict(invalid_record=invalid, fault_activated=bool(faults), failed_emissions=faults,
        raw_status=raw, masked_failure=bool(faults) and raw == 0,
        surfaced_failure=bool(faults) and raw != 0, stdout=completed.stdout.decode(),
        stderr=completed.stderr.decode(), events=normalized, private_inventory_exact=True)


def main():
    actual = hashlib.sha256(REFERENCE.read_bytes()).hexdigest()
    if actual != HISTORICAL_SHA256:
        print("REFUSE SBO TARGET NORMALIZATION AUDIT: requires exact historical563 runtime " + HISTORICAL_SHA256, file=sys.stderr)
        return 1
    rows = []
    for cell in itertools.product(PROFILES, WRITERS, (False, True), (False, True)):
        with tempfile.TemporaryDirectory(prefix="target-normalization-audit-") as temporary_root:
            rows.append(scenario(Path(temporary_root), *cell))
    totals = dict(cases=len(rows), active=sum(r["fault_activated"] for r in rows),
        masked=sum(r["masked_failure"] for r in rows), surfaced=sum(r["surfaced_failure"] for r in rows),
        inactive=sum(r["writer"] != "normal" and not r["fault_activated"] for r in rows),
        normal=sum(r["writer"] == "normal" for r in rows), invalid=sum(r["invalid_record"] for r in rows),
        failed_emissions=sum(len(r["failed_emissions"]) for r in rows),
        multiple_fault_cases=sum(len(r["failed_emissions"]) > 1 for r in rows))
    assert totals == dict(cases=160, active=80, masked=48, surfaced=32, inactive=48, normal=32,
                         invalid=60, failed_emissions=120, multiple_fault_cases=24), totals
    if len(sys.argv) == 3 and sys.argv[1] == "--report":
        Path(sys.argv[2]).write_text(json.dumps(dict(schema=1, historical_runtime_sha256=actual,
            safety_pass=False, totals=totals, rows=rows,
            scope="Direct normalizer; supplied printf failures and real private allocation/sort/removal; no caller/native acceptance"),
            indent=2, sort_keys=True) + "\n")
    else:
        assert len(sys.argv) == 1, "usage: test-sbo-target-normalization-emission-audit.py [--report /absolute/report.json]"
    print("PASS SBO TARGET NORMALIZATION HISTORICAL CHARACTERIZATION: 160 exact observations; 80 active writer faults; 48 masked; 32 surfaced through invalid records; 48 inactive fault controls; 32 normal controls; NOT a safety pass")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
