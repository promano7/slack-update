#!/usr/bin/env python3
"""Compose installed-normalizer writer refusals through ABI and dry-run selection."""
from collections import Counter
import importlib.util
import itertools
import json
import os
from pathlib import Path
import shlex
import stat
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
SUPPORT = Path(__file__).with_name("test-sbo-normalization-publication.py")
spec = importlib.util.spec_from_file_location("normalization_publication_support", SUPPORT)
BASE = importlib.util.module_from_spec(spec)
spec.loader.exec_module(BASE)
PROFILES = {"empty": [], "one": ["alpha"], "two": ["beta", "alpha"], "duplicates": ["zeta", "alpha", "alpha"],
    "literal": [".dot", "pkg++", "name-with-dash"], "alias": ["zeta", "alpha", "alpha"]}
WRITERS = BASE.WRITERS
EXTRA = r'''
wc() {
    [[ $# == 1 && $1 == -l && ( ${FUNCNAME[1]} == add_abi_rebuild_targets || ${FUNCNAME[1]} == collect_installed_sbo_candidates ) ]] || deny count-vector
    note count "$PHASE"
    builtin command wc "$@"
}
touch() {
    [[ ${FUNCNAME[1]} == add_abi_rebuild_targets && $# == 1 && $1 == "$TEST_ROOT/selected" && $ABI_TRIGGER == 0 ]] || deny touch-vector
    note touch
    builtin command touch "$@"
}
'''


def scenario(root, profile, writer, phase, seeded, conditional):
    names = PROFILES[profile]
    database = root / "packages"; database.mkdir(mode=0o700)
    for i, name in enumerate(names): BASE.put(database / (name + "-" + str(i + 1) + ".0-x86_64-1_SBo"), b"private inert manifest\n")
    BASE.put(database / "native-1.0-noarch-1", b"nonselected\n")
    BASE.put(database / "malformed", b"invalid nonselected record\n")
    (database / "ignored-dir-1.0-noarch-1_SBo").mkdir(mode=0o700)
    if names: (database / "ignored-link-1.0-noarch-1_SBo").symlink_to(names[0] + "-1.0-x86_64-1_SBo")
    argument = database
    if profile == "alias":
        (root / "database-alias").symlink_to("packages", target_is_directory=True); argument = root / "database-alias"
    if seeded: BASE.put(root / "selected", b"old-targets\n", 0o640)
    BASE.put(root / "sentinel", b"unchanged\n"); BASE.put(root / "trace", b"")
    before = BASE.inventory(root)
    entered = phase != "abi-disabled"; position, code = WRITERS[writer]
    active = entered and writer != "normal" and len(names) >= position
    published = entered and not active
    error = "old-error" if not entered else "cannot normalize installed SBo package targets" if active else ""
    total, plan = 9, 8
    if published:
        if phase == "abi": total = len(set(names))
        else: plan = len(set(names))
    script = BASE.SHELL + EXTRA
    guards = [n for n in BASE.GUARDS if n not in ("add_abi_rebuild_targets", "collect_installed_sbo_candidates", "touch")]
    guards += ["collect_sbo_targets_from_queue_directory", "merge_sbo_target_sets"]
    script += "\n".join(n + "() { deny " + n + "; }" for n in guards) + "\n"
    values = dict(OPERATION="collect_installed_sbo_targets", PACKAGE_DATABASE=argument, SBO_PACKAGE_TAG="_SBo",
        QUEUE_EXTRA=root / "selected", ABI_CANDIDATES=root / "selected", SBO_TARGET_SELECTION_ERROR="old-error",
        ABI_TRIGGER=int(entered), TOTAL_EXTRA=9, PLAN_ABI_SBO_COUNT=8, TOTAL_CORE=7, SBO_OPTION_RECORD_COUNT=6,
        PHASE=phase, WRITER=writer, FAULT_POSITION=position, WRITER_STATUS=code, WRITES=0)
    script += "\n".join(n + "=" + shlex.quote(str(v)) for n, v in values.items()) + "\n"
    script += "umask 077\nIFS='|: '\nsaved_ifs=$IFS\nabi_count=outer-abi\ncandidate_count=outer-count\ndestination=outer-destination\npackage_records=outer-records\ncandidate=outer-candidate\ndestination_directory=outer-directory\n"
    operation = "collect_installed_sbo_candidates" if phase == "dry-run" else "add_abi_rebuild_targets"
    script += ("if " + operation + "; then answer=0; else answer=$?; fi\n" if conditional else operation + "\nanswer=$?\n")
    script += '[[ $IFS == "$saved_ifs" && $abi_count == outer-abi && $candidate_count == outer-count && $destination == outer-destination && $package_records == outer-records && $candidate == outer-candidate && $destination_directory == outer-directory ]] || exit 96\n'
    script += 'builtin printf "\\0STATE\\0%s\\0%s\\0%s\\0%s\\0%s\\0%s\\0" "$answer" "$SBO_TARGET_SELECTION_ERROR" "$TOTAL_EXTRA" "$PLAN_ABI_SBO_COUNT" "$TOTAL_CORE" "$SBO_OPTION_RECORD_COUNT"\n'
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", script, "selection-normalization", str(REFERENCE), str(root)],
        cwd=root, capture_output=True, env=dict(os.environ, LC_ALL="C", TMPDIR=str(root)), timeout=15)
    label = dict(profile=profile, writer=writer, phase=phase, seeded=seeded, conditional=conditional)
    text = "[7] ABI trigger -> anadiendo todos los paquetes SBo a cola extra\n" if phase == "abi" else ""
    if active: text += "  [ERROR] " + error + "\n"
    elif phase == "abi": text += "  Cola ABI extra: " + str(total) + " paquetes\n"
    wanted = text.encode() + b"\0STATE\0" + b"\0".join(str(v).encode() for v in [int(active), error, total, plan, 7, 6]) + b"\0"
    assert (result.returncode, result.stdout, result.stderr) == (0, wanted, b""), (label, result, wanted)
    events = [line[:-1].decode().split("\0") for line in (root / "trace").read_bytes().splitlines()]
    aliases = {}; after = dict(before); staged = b""
    if entered:
        staged = (root / "normalizer-input").read_bytes(); observed_names = staged.decode().splitlines()
        assert staged == "".join(n + "\n" for n in observed_names).encode() and Counter(observed_names) == Counter(names), (label, staged, names)
        allocations = [e for e in events if e[0] == "allocate"]
        assert len(allocations) == len({e[2] for e in allocations}) == 3
        assert [e[1] for e in allocations] == ["collect_installed_sbo_targets", "collect_installed_sbo_targets", "source_normalizer"]
        for i, e in enumerate(allocations, 1):
            assert Path(e[2]).parent == root and not Path(e[2]).exists()
            aliases[e[2]] = "<ALLOCATED-" + str(i) + ">"
        expected = allocations[:2] + [["stage"], allocations[2]]
        for i, n in enumerate(observed_names[:position] if active else observed_names, 1):
            expected.append(["write", str(i), n])
            if active and i == position: expected.append(["fault", str(i), str(code)])
        if not active: expected.append(["sort"])
        expected.append(["remove", "source_normalizer", allocations[2][2]])
        if published: expected.append(["publish", allocations[1][2]])
        expected.append(["remove", "collect_installed_sbo_targets", allocations[0][2]])
        if active: expected.append(["remove", "collect_installed_sbo_targets", allocations[1][2]])
        else: expected.append(["count", phase])
        after["normalizer-input"] = ("file", 0o600, staged)
        if published: after["selected"] = ("file", 0o600, "".join(n + "\n" for n in sorted(set(names))).encode())
    else:
        expected = [["touch"]]
        if not seeded: after["selected"] = ("file", 0o600, b"")
    assert events == expected, (label, events, expected)
    assert BASE.inventory(root) == after and stat.S_IMODE((root / "trace").stat().st_mode) == 0o600, (label, BASE.inventory(root), after)
    return label | dict(entered=entered, active_fault=active, raw_status=int(active), total_extra=total, plan_count=plan,
        error=error, published=published, counted=published, touched=not entered, private_inventory_exact=True,
        staged_input=staged.decode(), stdout=result.stdout.decode(), stderr=result.stderr.decode(),
        events=[[aliases.get(v, v) for v in e] for e in events])


def main():
    rows = []
    for cell in itertools.product(PROFILES, WRITERS, ("abi", "dry-run", "abi-disabled"), (False, True), (False, True)):
        with tempfile.TemporaryDirectory(prefix="selection-normalization-") as area: rows.append(scenario(Path(area), *cell))
    totals = dict(cases=len(rows), active=sum(r["active_fault"] for r in rows),
        inactive=sum(r["writer"] != "normal" and not r["active_fault"] for r in rows), normal=sum(r["writer"] == "normal" for r in rows),
        published=sum(r["published"] for r in rows), counted=sum(r["counted"] for r in rows), touched=sum(r["touched"] for r in rows))
    assert totals == dict(cases=504, active=192, inactive=240, normal=72, published=144, counted=144, touched=168), totals
    if len(sys.argv) == 3 and sys.argv[1] == "--report":
        Path(sys.argv[2]).write_text(json.dumps(dict(schema=1, totals=totals, rows=rows, declared_support=SUPPORT.name,
            producer_input_staged_before_fault=True, concurrent_upstream_pipe_failure_covered=False,
            scope="Real private installed selection/ABI/dry-run counts and disabled touch;declared567 staging mechanics;no full workflow/native acceptance"), indent=2, sort_keys=True) + "\n")
    else: assert len(sys.argv) == 1, "usage: test-sbo-selection-normalization.py [--report /absolute/report.json]"
    print("SBo selection normalization: 504 scenarios PASS; 192 active refusals before publication/count; 240 inactive fault controls; 72 normal controls; 168 disabled-ABI touch controls; staged producer input")
    return 0


if __name__ == "__main__": raise SystemExit(main())
