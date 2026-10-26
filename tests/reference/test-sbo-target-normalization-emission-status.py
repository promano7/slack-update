#!/usr/bin/env python3
"""Require target-normalizer writer refusals before sort and target output."""

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
# Each valid prefix and ordinary sorted result is authored without the parser.
PROFILES = {
    "empty": ([], [], "", False),
    "blank": (["", ""], [], "", False),
    "one": (["oak"], ["oak"], "oak\n", False),
    "duplicates": (["reed", "bamboo", "bamboo", "oak"], ["reed", "bamboo", "bamboo", "oak"], "bamboo\noak\nreed\n", False),
    "blank-tail": (["reed", "", "oak", ""], ["reed", "oak"], "oak\nreed\n", False),
    "invalid-first": (["-bad", "oak"], [], "", True),
    "invalid-middle": (["reed", "@bad", "oak"], ["reed"], "", True),
    "invalid-last": (["reed", "oak", "bad/name"], ["reed", "oak"], "", True),
}
WRITERS = {"normal": 0, "first-quiet": 43, "first-late": 127, "all-quiet": 1, "all-late": 43}
SHELL = r'''
source "$1"
TEST_ROOT=$2
TRACE=$TEST_ROOT/trace
deny() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
note() { builtin printf '%s\0' "$@" >> "$TRACE"; builtin printf '\n' >> "$TRACE"; }
mktemp() {
    [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 0 ]] || deny allocation-vector
    local file
    file=$(builtin command mktemp) || return $?
    [[ $file == "$TEST_ROOT"/tmp.* && -f $file && ! -L $file ]] || deny allocation-path
    [[ $(builtin command stat -c %a -- "$file") == 600 ]] || deny allocation-mode
    note allocated "$file"
    builtin printf '%s\n' "$file"
}
printf() {
    [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 2 && $1 == '%s\n' ]] || deny write-vector
    [[ $2 == oak || $2 == reed || $2 == bamboo ]] || deny write-name
    WRITE_INDEX=$((WRITE_INDEX + 1))
    note write "$WRITE_INDEX" "$2"
    if [[ $WRITER != normal && ( $WRITER == all-* || $WRITE_INDEX == 1 ) ]]; then
        note refused "$WRITE_INDEX" "$WRITE_STATUS"
        [[ $WRITER == *-late ]] || return "$WRITE_STATUS"
        builtin printf "$@"
        return "$WRITE_STATUS"
    fi
    builtin printf "$@"
}
sort() {
    [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 2 && $1 == -u && $2 == "$temporary" && $2 == "$TEST_ROOT"/tmp.* && -f $2 && ! -L $2 ]] || deny sort-vector
    note sorted
    builtin command sort "$@"
}
rm() {
    [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 2 && $1 == -f && $2 == "$temporary" && $2 == "$TEST_ROOT"/tmp.* && -f $2 && ! -L $2 ]] || deny removal-vector
    note removed
    builtin command rm "$@"
}
'''
GUARDS = (
    "main", "initialize_execution_environment", "load_configuration", "initialize_runtime",
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
    for p in root.iterdir():
        if p.name == "trace":
            continue
        metadata = p.lstat()
        assert stat.S_ISREG(metadata.st_mode), (p, metadata)
        result[p.name] = (stat.S_IMODE(metadata.st_mode), p.read_bytes())
    return result


def check(root, profile, writer, newline, conditional):
    lines, prefix, ordinary_output, invalid = PROFILES[profile]
    (root / "input").write_text("\n".join(lines) + ("\n" if newline else ""))
    (root / "input").chmod(0o640)
    (root / "sentinel").write_text("unchanged\n")
    (root / "sentinel").chmod(0o600)
    (root / "trace").touch(mode=0o600)
    before = inventory(root)
    active = bool(prefix) and writer != "normal"
    expected_names = prefix[:1] if active else prefix
    refused = active or invalid
    result = 1 if refused else 0
    text = "" if refused else ordinary_output
    settings = dict(WRITER=writer, WRITE_STATUS=WRITERS[writer], WRITE_INDEX=0)
    script = SHELL + "\n".join(n + "() { deny " + n + "; }" for n in GUARDS) + "\n"
    script += "\n".join(n + "=" + shlex.quote(str(v)) for n, v in settings.items()) + "\n"
    script += "umask 077\nIFS='|: '\nsaved_ifs=$IFS\ntarget=outer-target\ntemporary=outer-temporary\nstatus=outer-status\n"
    operation = 'normalize_sbo_target_names_from_stream < "$TEST_ROOT/input"'
    script += ("if " + operation + "; then answer=0; else answer=$?; fi\n" if conditional else operation + "\nanswer=$?\n")
    script += '[[ $IFS == "$saved_ifs" && $target == outer-target && $temporary == outer-temporary && $status == outer-status ]] || exit 96\n'
    script += 'builtin printf "\\0STATUS\\0%s\\0" "$answer"\n'
    observed = subprocess.run(["bash", "--noprofile", "--norc", "-c", script,
        "target-normalization-status", str(REFERENCE), str(root)], cwd=root, capture_output=True,
        env=dict(os.environ, TMPDIR=str(root), LC_ALL="C"), timeout=10)
    label = dict(profile=profile, writer=writer, final_newline=newline, conditional=conditional)
    expected = text.encode() + b"\0STATUS\0" + str(result).encode() + b"\0"
    assert (observed.returncode, observed.stdout, observed.stderr) == (0, expected, b""), (label, observed, expected)
    events = [line[:-1].decode().split("\0") for line in (root / "trace").read_bytes().splitlines()]
    assert len(events[0]) == 2 and events[0][0] == "allocated", (label, events)
    allocated = Path(events[0][1])
    assert allocated.parent == root and allocated.name.startswith("tmp."), (label, events)
    wanted_events = [["allocated", "<TEMPORARY>"]]
    for i, n in enumerate(expected_names, 1):
        wanted_events.append(["write", str(i), n])
        if active:
            wanted_events.append(["refused", str(i), str(WRITERS[writer])])
    if not refused:
        wanted_events.append(["sorted"])
    wanted_events.append(["removed"])
    actual_events = [["allocated", "<TEMPORARY>"]] + events[1:]
    assert actual_events == wanted_events, (label, actual_events, wanted_events)
    assert inventory(root) == before and not allocated.exists(), (label, inventory(root), before)
    assert stat.S_IMODE((root / "trace").stat().st_mode) == 0o600
    return label | dict(active_fault=active, invalid_record=invalid, raw_status=result,
        stdout=observed.stdout.decode(), stderr=observed.stderr.decode(), events=actual_events,
        stopped_at_first_writer_failure=active, sort_called=not refused,
        failed_writes=1 if active else 0, private_inventory_exact=True, temporary_mode=0o600)


def main():
    rows = []
    for cell in itertools.product(PROFILES, WRITERS, (False, True), (False, True)):
        with tempfile.TemporaryDirectory(prefix="normalizer-status-") as area:
            rows.append(check(Path(area), *cell))
    totals = dict(cases=len(rows), active=sum(r["active_fault"] for r in rows),
        inactive=sum(r["writer"] != "normal" and not r["active_fault"] for r in rows),
        normal=sum(r["writer"] == "normal" for r in rows),
        invalid=sum(r["invalid_record"] for r in rows), sorted=sum(r["sort_called"] for r in rows),
        failed_writes=sum(r["failed_writes"] for r in rows))
    assert totals == dict(cases=160, active=80, inactive=48, normal=32, invalid=60, sorted=52, failed_writes=80), totals
    if len(sys.argv) == 3 and sys.argv[1] == "--report":
        Path(sys.argv[2]).write_text(json.dumps(dict(schema=1, totals=totals, rows=rows,
            scope="Direct normalizer; authored expected names/status/traces; supplied printf faults and real private allocation/stat/sort/removal; no caller/native acceptance"),
            indent=2, sort_keys=True) + "\n")
    else:
        assert len(sys.argv) == 1, "usage: test-sbo-target-normalization-emission-status.py [--report /absolute/report.json]"
    print("SBo target normalization emission: 160 scenarios PASS; 80 active refusals before sort/output; 48 inactive fault controls; 32 normal controls; selected temporary cleanup")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
