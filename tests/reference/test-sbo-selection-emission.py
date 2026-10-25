#!/usr/bin/env python3
"""Compose installed-reader writer refusal through ABI and dry-run selection."""
from collections import Counter
import importlib.util
import itertools
import json
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
SUPPORT = Path(__file__).with_name("test-sbo-installed-emission.py")
spec = importlib.util.spec_from_file_location("installed_emission_support", SUPPORT)
BASE = importlib.util.module_from_spec(spec)
spec.loader.exec_module(BASE)
PROFILES = {
    "empty": ([], []),
    "one": (["alpha-1.0-x86_64-1_SBo"], ["alpha"]),
    "duplicates": (["alpha-1.0-x86_64-1_SBo", "alpha-2.0-i586-2_SBo", "beta-1.0-noarch-1_SBo"], ["alpha", "alpha", "beta"]),
    "symlink": (["alpha-1.0-x86_64-1_SBo", "alpha-2.0-i586-2_SBo", "beta-1.0-noarch-1_SBo"], ["alpha", "alpha", "beta"]),
}
EXTRA = r'''
wc() {
    [[ $# == 1 && $1 == -l && ( ${FUNCNAME[1]} == add_abi_rebuild_targets || ${FUNCNAME[1]} == collect_installed_sbo_candidates ) ]] || forbidden count-vector
    record count "$PHASE"
    builtin command wc "$@"
}
touch() {
    [[ ${FUNCNAME[1]} == add_abi_rebuild_targets && $# == 1 && $1 == "$TEST_ROOT/selected" && $ABI_TRIGGER == 0 ]] || forbidden touch-vector
    record touch
    builtin command touch "$@"
}
'''


def scenario(root, profile, writer, phase, conditional, seeded):
    records, selected = PROFILES[profile]
    database = root / "packages"
    database.mkdir(mode=0o700)
    for name in records:
        path = database / name; path.write_text("private inert manifest\n"); path.chmod(0o600)
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
        destination.write_text("old-targets\n"); destination.chmod(0o640)
    (root / "sentinel").write_text("unchanged\n"); (root / "sentinel").chmod(0o600)
    expected = BASE.inventory(root)
    entered = phase != "abi-disabled"
    active = entered and writer != "normal" and bool(selected)
    if entered and not active:
        expected["selected"] = ("file", 0o600, "".join(n + "\n" for n in sorted(set(selected))).encode())
    elif not entered and not seeded:
        expected["selected"] = ("file", 0o600, b"")
    error = "cannot normalize installed SBo package targets" if active else "" if entered else "old-error"
    total, plan = 9, 8
    if entered and not active:
        if phase == "abi": total = len(set(selected))
        else: plan = len(set(selected))
    code = {"normal": 0, "first-quiet": 43, "first-late": 127, "all-quiet": 1, "all-late": 43}[writer]
    settings = dict(PACKAGE_DATABASE=argument, SBO_PACKAGE_TAG="_SBo", SBO_TARGET_SELECTION_ERROR="old-error",
        QUEUE_EXTRA=destination, ABI_CANDIDATES=destination, ABI_TRIGGER=0 if phase == "abi-disabled" else 1,
        TOTAL_EXTRA=9, PLAN_ABI_SBO_COUNT=8, TOTAL_CORE=7, SBO_OPTION_RECORD_COUNT=6,
        PHASE=phase, WRITER=writer, WRITER_STATUS=code, WRITES=0)
    guards = [name for name in BASE.GUARDS if name not in ("collect_installed_sbo_candidates", "add_abi_rebuild_targets")]
    shell = BASE.SETUP + EXTRA + "\n" + "\n".join(name + "() { forbidden " + name + "; }" for name in guards)
    shell += "\n" + "\n".join(name + "=" + shlex.quote(str(value)) for name, value in settings.items()) + "\n"
    shell += "umask 077\nIFS='|: '\nsaved_ifs=$IFS\nabi_count=outer-abi\ncandidate_count=outer-count\ndestination=outer-destination\npackage_records=outer-records\ncandidate=outer-candidate\ndestination_directory=outer-directory\nemission_failed=123\n"
    operation = "collect_installed_sbo_candidates" if phase == "dry-run" else "add_abi_rebuild_targets"
    shell += ("if " + operation + "; then result=0; else result=$?; fi\n" if conditional else operation + "\nresult=$?\n")
    shell += '[[ $IFS == "$saved_ifs" && $abi_count == outer-abi && $candidate_count == outer-count && $destination == outer-destination && $package_records == outer-records && $candidate == outer-candidate && $destination_directory == outer-directory && $emission_failed == 123 ]] || exit 96\n'
    shell += 'builtin printf "\\0STATE\\0%s\\0%s\\0%s\\0%s\\0%s\\0%s\\0" "$result" "$SBO_TARGET_SELECTION_ERROR" "$TOTAL_EXTRA" "$PLAN_ABI_SBO_COUNT" "$TOTAL_CORE" "$SBO_OPTION_RECORD_COUNT"\n'
    completed = subprocess.run(["bash", "--noprofile", "--norc", "-c", shell, "selection-emission", str(REFERENCE), str(root)],
        capture_output=True, cwd=root, env=dict(os.environ, LC_ALL="C", TMPDIR=str(root)), timeout=15)
    output = "[7] ABI trigger -> anadiendo todos los paquetes SBo a cola extra\n" if phase == "abi" else ""
    if active: output += "  [ERROR] " + error + "\n"
    elif phase == "abi": output += "  Cola ABI extra: " + str(total) + " paquetes\n"
    wanted = output.encode() + b"\0STATE\0" + b"\0".join(str(v).encode() for v in [1 if active else 0, error, total, plan, 7, 6]) + b"\0"
    label = dict(profile=profile, writer=writer, phase=phase, conditional=conditional, seeded=seeded)
    assert (completed.returncode, completed.stdout, completed.stderr) == (0, wanted, b""), (label, completed, wanted)
    events = [line.split("|") for line in (root / "trace").read_text().splitlines()]
    if not entered:
        assert events == [["touch"]], (label, events)
        failures = []
    else:
        failures = list(range(1, len(selected) + 1)) if active and writer.startswith("all-") else [1] if active else []
        assert Counter(e[0] for e in events) == Counter(allocate=3, enumerate=1, write=len(selected), fault=len(failures),
            normalize=1, publish=0 if active else 1, remove=3 if active else 2, count=0 if active else 1)
        allocations = {e[1]: e[2] for e in events if e[0] == "allocate"}
        assert set(allocations) == {"records", "candidate", "normalizer"} and len(set(allocations.values())) == 3
        writes = [e for e in events if e[0] == "write"]
        assert [e[1] for e in writes] == [str(i) for i in range(1, len(selected) + 1)]
        assert Counter(e[2] for e in writes) == Counter(selected)
        assert [e for e in events if e[0] == "fault"] == [["fault", str(i), writer, str(code)] for i in failures]
        assert [e for e in events if e[0] == "count"] == ([] if active else [["count", phase]])
        assert [e for e in events if e[0] == "publish"] == ([] if active else [["publish", allocations["candidate"]]])
        removes = [("normalize_sbo_target_names_from_stream", allocations["normalizer"]),
                   ("collect_installed_sbo_targets", allocations["records"])]
        if active: removes.append(("collect_installed_sbo_targets", allocations["candidate"]))
        assert Counter(tuple(e[1:]) for e in events if e[0] == "remove") == Counter(removes)
    assert BASE.inventory(root) == expected, (label, BASE.inventory(root), expected)
    aliases = {e[2]: "<" + e[1].upper() + ">" for e in events if e[0] == "allocate"}
    normalized = [[aliases.get(field, field) for field in event] for event in events]
    return label | dict(active_fault=active, inactive_fault=writer != "normal" and not active, entered=entered,
        failed_emissions=failures, raw_status=1 if active else 0, error=error, total_extra=total, plan_count=plan,
        published=entered and not active, counted=entered and not active, touched=not entered,
        private_inventory_exact=True, stdout=completed.stdout.decode(), stderr=completed.stderr.decode(), events=normalized)


def main():
    rows = []
    for cell in itertools.product(PROFILES, ("normal", "first-quiet", "first-late", "all-quiet", "all-late"),
                                  ("abi", "dry-run", "abi-disabled"), (False, True), (False, True)):
        with tempfile.TemporaryDirectory(prefix="selection-emission-test-") as temporary:
            rows.append(scenario(Path(temporary), *cell))
    totals = dict(cases=len(rows), active=sum(r["active_fault"] for r in rows), inactive=sum(r["inactive_fault"] for r in rows),
        normal=sum(r["writer"] == "normal" for r in rows), multiple_fault_cases=sum(len(r["failed_emissions"]) > 1 for r in rows),
        failed_emissions=sum(len(r["failed_emissions"]) for r in rows), published=sum(r["published"] for r in rows),
        counted=sum(r["counted"] for r in rows), touched=sum(r["touched"] for r in rows))
    assert totals == dict(cases=240, active=96, inactive=96, normal=48, multiple_fault_cases=32,
                         failed_emissions=160, published=64, counted=64, touched=80), totals
    if len(sys.argv) == 3 and sys.argv[1] == "--report":
        Path(sys.argv[2]).write_text(json.dumps(dict(schema=1, totals=totals, rows=rows,
            scope="Real private installed/ABI/dry-run selection helpers and counts; declared559 callback support; no complete workflow/native acceptance"),
            indent=2, sort_keys=True) + "\n")
    else:
        assert len(sys.argv) == 1, "usage: test-sbo-selection-emission.py [--report /absolute/report.json]"
    print("SBo selection emission: 240 scenarios PASS; 96 active refusals before publication/count; 96 inactive fault controls; 48 normal controls; 80 disabled-ABI touch controls")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
