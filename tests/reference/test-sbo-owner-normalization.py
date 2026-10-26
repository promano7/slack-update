#!/usr/bin/env python3
"""Compose normalizer writer refusals through private broken-object owner merging."""
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
PROFILES = ("empty", "missing", "unowned", "native-only", "single", "shared", "duplicates", "last-owner")
OWNERS = {"empty": [], "missing": [], "unowned": [], "native-only": [], "single": ["alpha"],
    "shared": ["alpha", "beta", "gamma"], "duplicates": ["alpha", "beta"], "last-owner": ["beta", "gamma"]}
WRITERS = BASE.WRITERS
EXTRA = r'''
grep() {
    [[ ${FUNCNAME[1]} == map_broken_objects_to_sbo_packages && $# == 7 && $1 == -rlFx && $2 == -e && $4 == -e && $5 == "${3#/}" && $6 == -- && $7 == "$PACKAGE_DATABASE/" ]] || deny lookup-vector
    [[ $3 == "$TEST_ROOT/objects/first[abi]" || $3 == "$TEST_ROOT/objects/last+name" ]] || deny lookup-path
    note lookup "${3##*/}"
    builtin command grep "$@"
}
mktemp() {
    local caller=${FUNCNAME[1]} file
    if [[ $caller == map_broken_objects_to_sbo_packages || $caller == source_normalizer ]]; then
        [[ $# == 0 ]] || deny allocate-vector
    else
        [[ $caller == merge_sbo_target_sets && $# == 1 && $1 == "$TEST_ROOT/.sbo-targets.XXXXXX" ]] || deny allocate-caller
    fi
    file=$(builtin command mktemp "$@") || return $?
    [[ ( $file == "$TEST_ROOT"/tmp.* || $file == "$TEST_ROOT"/.sbo-targets.* ) && -f $file && ! -L $file && $(builtin command stat -c %a -- "$file") == 600 ]] || deny allocate-path
    note allocate "$caller" "$file"
    builtin printf '%s\n' "$file"
}
sort() {
    [[ $LC_ALL == C ]] || deny sort-locale
    if [[ ${FUNCNAME[1]} == map_broken_objects_to_sbo_packages ]]; then
        [[ $# == 1 && $1 == -u ]] || deny owner-sort-vector
    else
        [[ ${FUNCNAME[1]} == source_normalizer && $# == 2 && $1 == -u && $2 == "$temporary" && -f $2 && ! -L $2 ]] || deny normalize-sort-vector
        note sort
    fi
    builtin command sort "$@"
}
cat() {
    [[ ${FUNCNAME[1]} == merge_sbo_target_sets && $# == 2 && $1 == "$QUEUE_EXTRA" && $2 == "$_BROKEN_PKGS" ]] || deny merge-input-vector
    builtin command cat "$@"
}
wc() {
    [[ ${FUNCNAME[1]} == map_broken_objects_to_sbo_packages && $# == 1 && $1 == -l ]] || deny count-vector
    note count
    builtin command wc "$@"
}
mv() {
    [[ $# == 4 && $1 == -f && $2 == -- && -f $3 && ! -L $3 ]] || deny move-vector
    if [[ ${FUNCNAME[1]} == merge_sbo_target_sets ]]; then
        [[ $3 == "$candidate" && $3 == "$TEST_ROOT"/.sbo-targets.* && $4 == "$QUEUE_EXTRA.merged" ]] || deny merge-stage-vector
        note merge-stage "$3"
    else
        [[ ${FUNCNAME[1]} == map_broken_objects_to_sbo_packages && $3 == "$QUEUE_EXTRA.merged" && $4 == "$QUEUE_EXTRA" ]] || deny publish-vector
        note publish
    fi
    builtin command mv "$@"
}
rm() {
    local caller=${FUNCNAME[1]} file
    [[ $caller == map_broken_objects_to_sbo_packages || $caller == merge_sbo_target_sets || $caller == source_normalizer ]] || deny remove-caller
    [[ $# -ge 2 && $# -le 4 && $1 == -f ]] || deny remove-vector
    for file in "${@:2}"; do
        [[ $file == -- ]] && continue
        [[ $file == "$TEST_ROOT"/tmp.* || $file == "$TEST_ROOT"/.sbo-targets.* || $file == "$QUEUE_EXTRA.merged" ]] || deny remove-path
        [[ ! -e $file || ( -f $file && ! -L $file ) ]] || deny remove-type
        note remove "$caller" "$file"
    done
    builtin command rm "$@"
}
'''


def scenario(root, profile, writer, abi_targets, newline, conditional):
    objects = root / "objects"; objects.mkdir(mode=0o700)
    database = root / "packages"; database.mkdir(mode=0o700)
    first, last = objects / "first[abi]", objects / "last+name"
    for p in (first, last): BASE.put(p, b"inert private object;never executed\n")
    manifests = {}
    if profile != "unowned": manifests["native-1.0-x86_64-1"] = [str(first), str(last).lstrip("/")]
    if profile == "single": manifests["alpha-1.0-x86_64-1_SBo"] = [str(first)]
    if profile == "shared": manifests.update({"alpha-1.0-x86_64-1_SBo": [str(first)], "alpha-2.0-noarch-2_SBo": [str(first)], "beta-1.0-noarch-1_SBo": [str(first)], "gamma-1.0-noarch-1_SBo": [str(last).lstrip("/")]})
    if profile == "duplicates": manifests.update({"alpha-1.0-noarch-1_SBo": [str(first), str(last).lstrip("/")], "beta-1.0-noarch-1_SBo": [str(first)]})
    if profile == "last-owner": manifests.update({"beta-1.0-noarch-1_SBo": [str(last).lstrip("/")], "gamma-1.0-noarch-1_SBo": [str(last)]})
    manifests["near-1.0-noarch-1_SBo"] = [str(first) + "-suffix", str(last) + "-suffix"]
    for n, lines in manifests.items(): BASE.put(database / n, ("\n".join(lines) + "\n").encode())
    order = [] if profile in ("empty", "missing") else [first, first, last] if profile == "duplicates" else [first, last]
    broken, queue = root / "broken", root / "queue"
    if profile != "missing": BASE.put(broken, ("\n".join(map(str, order)) + ("\n" if order and newline else "")).encode())
    abi_names = ["zeta", "abi", "zeta"] if abi_targets else []
    BASE.put(queue, "".join(n + "\n" for n in abi_names).encode(), 0o640)
    BASE.put(root / "sentinel", b"unchanged\n"); BASE.put(root / "trace", b"")
    before = BASE.inventory(root)
    entered = bool(order); names = abi_names + OWNERS[profile]
    position, code = WRITERS[writer]
    active = entered and writer != "normal" and len(names) >= position
    published = entered and not active
    total = len(set(names)) if published else 9
    error = "cannot merge broken-object SBo targets" if active else "old-error"
    # Shared567 mechanics are declared support; the owner fixtures/oracles are separate.
    script = BASE.SHELL.replace("alpha|beta|zeta|.dot|pkg++|name-with-dash", "alpha|beta|gamma|abi|zeta|.dot|pkg++|name-with-dash") + EXTRA
    guards = [n for n in BASE.GUARDS if n != "map_broken_objects_to_sbo_packages"]
    guards += ["collect_installed_sbo_targets", "collect_sbo_targets_from_queue_directory"]
    script += "\n".join(n + "() { deny " + n + "; }" for n in guards) + "\n"
    values = dict(OPERATION="merge_sbo_target_sets", BROKEN=broken, QUEUE_EXTRA=queue, PACKAGE_DATABASE=database,
        SBO_PACKAGE_TAG="_SBo", SBO_TARGET_SELECTION_ERROR="old-error", TOTAL_EXTRA=9, ELF_SCAN_STATUS=8,
        ELF_VERIFICATION_STATUS=7, PLAN_ABI_SBO_COUNT=6, TOTAL_CORE=5, _BROKEN_PKGS="outer-stage",
        WRITER=writer, FAULT_POSITION=position, WRITER_STATUS=code, WRITES=0)
    script += "\n".join(n + "=" + shlex.quote(str(v)) for n, v in values.items()) + "\n"
    script += "umask 077\nIFS='|: '\nsaved_ifs=$IFS\nowner_records=outer-records\nowner_status=outer-status\ntotal_extra=outer-total\n"
    operation = "map_broken_objects_to_sbo_packages"
    script += ("if " + operation + "; then answer=0; else answer=$?; fi\n" if conditional else operation + "\nanswer=$?\n")
    script += '[[ $IFS == "$saved_ifs" && $owner_records == outer-records && $owner_status == outer-status && $total_extra == outer-total ]] || exit 96\n'
    script += ('[[ $_BROKEN_PKGS == "$TEST_ROOT"/tmp.* && ! -e $_BROKEN_PKGS ]] || exit 96\n' if entered else '[[ $_BROKEN_PKGS == outer-stage ]] || exit 96\n')
    script += 'builtin printf "\\0STATE\\0%s\\0%s\\0%s\\0%s\\0%s\\0%s\\0%s\\0" "$answer" "$TOTAL_EXTRA" "$SBO_TARGET_SELECTION_ERROR" "$ELF_SCAN_STATUS" "$ELF_VERIFICATION_STATUS" "$PLAN_ABI_SBO_COUNT" "$TOTAL_CORE"\n'
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", script, "owner-normalization", str(REFERENCE), str(root)],
        cwd=root, capture_output=True, env=dict(os.environ, LC_ALL="C", TMPDIR=str(root)), timeout=15)
    label = dict(profile=profile, writer=writer, abi_targets=abi_targets, final_newline=newline, conditional=conditional)
    text = "[9] Mapeando binarios rotos a paquetes SBo\n"
    text += "  [ERROR] " + error + "\n" if active else "  Cola extra tras rotos: " + str(total) + " paquetes\n" if entered else "  Sin binarios rotos, nada que anadir\n"
    expected = text.encode() + b"\0STATE\0" + b"\0".join(str(v).encode() for v in [int(active), total, error, 8, 7, 6, 5]) + b"\0"
    assert (result.returncode, result.stdout, result.stderr) == (0, expected, b""), (label, result, expected)
    events = [line[:-1].decode().split("\0") for line in (root / "trace").read_bytes().splitlines()]
    allocations = [e for e in events if e[0] == "allocate"]
    expected_events = []; aliases = {}; after = dict(before)
    if entered:
        assert len(allocations) == 3 and [e[1] for e in allocations] == [operation, "merge_sbo_target_sets", "source_normalizer"]
        assert len({e[2] for e in allocations}) == 3
        for i, e in enumerate(allocations, 1):
            assert Path(e[2]).parent == root and not Path(e[2]).exists()
            aliases[e[2]] = "<ALLOCATED-" + str(i) + ">"
        expected_events = [allocations[0]] + [["lookup", p.name] for p in order] + [allocations[1], ["stage"], allocations[2]]
        staged = "".join(n + "\n" for n in names).encode()
        assert (root / "normalizer-input").read_bytes() == staged
        after["normalizer-input"] = ("file", 0o600, staged)
        attempted = names[:position] if active else names
        for i, n in enumerate(attempted, 1):
            expected_events.append(["write", str(i), n])
            if active and i == position: expected_events.append(["fault", str(i), str(code)])
        if not active: expected_events.append(["sort"])
        expected_events.append(["remove", "source_normalizer", allocations[2][2]])
        if active:
            expected_events += [["remove", "merge_sbo_target_sets", allocations[1][2]], ["remove", operation, allocations[0][2]], ["remove", operation, str(queue) + ".merged"]]
        else:
            expected_events += [["merge-stage", allocations[1][2]], ["count"], ["publish"], ["remove", operation, allocations[0][2]]]
            after["queue"] = ("file", 0o600, "".join(n + "\n" for n in sorted(set(names))).encode())
    assert events == expected_events, (label, events, expected_events)
    assert BASE.inventory(root) == after and stat.S_IMODE((root / "trace").stat().st_mode) == 0o600, (label, BASE.inventory(root), after)
    aliases[str(queue) + ".merged"] = "<MERGED-PATH>"
    return label | dict(entered=entered, active_fault=active, raw_status=int(active), total_extra=total, error=error,
        published=published, counted=published, normalized_names=names if entered else [], private_inventory_exact=True,
        owner_stage_global="removed-private-path" if entered else "unchanged", stdout=result.stdout.decode(), stderr=result.stderr.decode(),
        events=[[aliases.get(v, v) for v in e] for e in events])


def main():
    rows = []
    for cell in itertools.product(PROFILES, WRITERS, (False, True), (False, True), (False, True)):
        with tempfile.TemporaryDirectory(prefix="owner-normalization-") as area: rows.append(scenario(Path(area), *cell))
    totals = dict(cases=len(rows), active=sum(r["active_fault"] for r in rows),
        inactive=sum(r["writer"] != "normal" and not r["active_fault"] for r in rows), normal=sum(r["writer"] == "normal" for r in rows),
        published=sum(r["published"] for r in rows), skipped=sum(not r["entered"] for r in rows))
    assert totals == dict(cases=448, active=208, inactive=176, normal=64, published=128, skipped=112), totals
    if len(sys.argv) == 3 and sys.argv[1] == "--report":
        Path(sys.argv[2]).write_text(json.dumps(dict(schema=1, totals=totals, rows=rows,
            declared_support=SUPPORT.name, producer_input_staged_before_fault=True, concurrent_upstream_pipe_failure_covered=False,
            scope="Real private literal owner lookup/parser/merge/count/publication with declared567 staging mechanics;no full workflow/native acceptance"), indent=2, sort_keys=True) + "\n")
    else: assert len(sys.argv) == 1, "usage: test-sbo-owner-normalization.py [--report /absolute/report.json]"
    print("SBo owner normalization: 448 scenarios PASS; 208 active refusals before count/publication; 176 inactive fault controls; 64 normal controls; 112 empty/missing-list skips; staged producer input")
    return 0


if __name__ == "__main__": raise SystemExit(main())
