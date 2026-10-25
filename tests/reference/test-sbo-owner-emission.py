#!/usr/bin/env python3
"""Compose package-name writer refusals through real private broken-object owners."""
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
PROFILES = ("empty", "missing", "unowned", "native-only", "single", "shared", "duplicates", "last-owner")
SETUP = r'''
source "$1"
TEST_ROOT=$2
record() { local IFS='|'; builtin printf '%s\n' "$*" >> "$TEST_ROOT/trace"; }
forbidden() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
printf() {
    if [[ ${FUNCNAME[1]} == package_names_with_build_suffix_from_stream ]]; then
        [[ $# == 2 && $1 == '%s\n' ]] || forbidden writer-vector
        case "$2" in alpha|beta|gamma) ;; *) forbidden writer-name ;; esac
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
grep() {
    [[ ${FUNCNAME[1]} == map_broken_objects_to_sbo_packages && $# == 7 && $1 == -rlFx \
        && $2 == -e && $4 == -e && $5 == "${3#/}" && $6 == -- && $7 == "$PACKAGE_DATABASE/" \
        && ( $3 == "$TEST_ROOT/objects/first[abi]" || $3 == "$TEST_ROOT/objects/last+name" ) ]] || forbidden grep-vector
    record lookup "${3##*/}"
    builtin command grep "$@"
}
mktemp() {
    local caller=${FUNCNAME[1]} kind value
    if [[ $caller == map_broken_objects_to_sbo_packages && $# == 0 ]]; then kind=owners
    elif [[ $caller == merge_sbo_target_sets && $# == 1 && $1 == "$TEST_ROOT/.sbo-targets.XXXXXX" ]]; then kind=merged
    elif [[ $caller == normalize_sbo_target_names_from_stream && $# == 0 ]]; then kind=normalizer
    else forbidden mktemp-vector; fi
    value=$(builtin command mktemp "$@") || forbidden real-mktemp
    [[ $value == "$TEST_ROOT/"* ]] || forbidden mktemp-path
    record allocate "$kind" "$value"
    builtin printf '%s\n' "$value"
}
sort() {
    [[ $LC_ALL == C ]] || forbidden sort-locale
    if [[ ${FUNCNAME[1]} == map_broken_objects_to_sbo_packages && $# == 1 && $1 == -u ]]; then
        record owner-sort
    elif [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 2 && $1 == -u && $2 == "$TEST_ROOT/tmp."* ]]; then
        record merge-sort "$2"
    else forbidden sort-vector; fi
    builtin command sort "$@"
}
cat() {
    [[ ${FUNCNAME[1]} == merge_sbo_target_sets && $# == 2 && $1 == "$QUEUE_EXTRA" && $2 == "$_BROKEN_PKGS" ]] || forbidden merge-input-vector
    record merge-input "$2"
    builtin command cat "$@"
}
wc() {
    [[ ${FUNCNAME[1]} == map_broken_objects_to_sbo_packages && $# == 1 && $1 == -l ]] || forbidden count-vector
    record count
    builtin command wc "$@"
}
mv() {
    [[ $# == 4 && $1 == -f && $2 == -- ]] || forbidden move-vector
    if [[ ${FUNCNAME[1]} == merge_sbo_target_sets && $3 == "$TEST_ROOT/.sbo-targets."* && $4 == "$QUEUE_EXTRA.merged" ]]; then
        record merge-stage "$3"
    elif [[ ${FUNCNAME[1]} == map_broken_objects_to_sbo_packages && $3 == "$QUEUE_EXTRA.merged" && $4 == "$QUEUE_EXTRA" ]]; then
        record publish
    else forbidden move-destination; fi
    builtin command mv "$@"
}
rm() {
    local caller=${FUNCNAME[1]} path
    [[ $caller == map_broken_objects_to_sbo_packages || $caller == normalize_sbo_target_names_from_stream ]] || forbidden remove-caller
    [[ $# -ge 2 && $1 == -f ]] || forbidden remove-vector
    for path in "${@:2}"; do
        [[ $path == -- ]] && continue
        [[ $path == "$TEST_ROOT/tmp."* || $path == "$QUEUE_EXTRA.merged" ]] || forbidden remove-path
        record remove "$caller" "$path"
    done
    builtin command rm "$@"
}
'''
GUARDS = (
    "main", "initialize_execution_environment", "load_configuration", "initialize_runtime",
    "initialize_dry_run_runtime", "configure_logging", "run_apply_workflow", "run_check_workflow",
    "run_dry_run_workflow", "collect_installed_sbo_targets", "collect_installed_sbo_candidates",
    "add_abi_rebuild_targets", "detect_broken_elf_objects", "verify_broken_elf_objects_after_rebuild",
    "slackpkg", "sbopkg", "sqg", "flatpak", "readelf", "ldd", "ldconfig", "git", "curl", "wget",
    "regenerate_initrd", "update_grub_configuration",
)


def inventory(root):
    result = {}
    for path in root.rglob("*"):
        if path == root / "trace":
            continue
        mode = stat.S_IMODE(path.lstat().st_mode)
        result[path.relative_to(root).as_posix()] = ("directory", mode) if path.is_dir() else ("file", mode, path.read_bytes())
    return result


def scenario(root, profile, writer, terminated, conditional):
    objects, database = root / "objects", root / "packages"
    objects.mkdir(mode=0o700); database.mkdir(mode=0o700)
    first, last = objects / "first[abi]", objects / "last+name"
    for path in [first, last]:
        path.write_text("private inert object; never executed\n"); path.chmod(0o600)
    names = {
        "empty": [[], []], "missing": [[], []], "unowned": [[], []], "native-only": [[], []],
        "single": [["alpha"], []], "shared": [["alpha", "alpha", "beta"], ["gamma"]],
        "duplicates": [["alpha", "beta"], ["alpha"]], "last-owner": [[], ["beta", "gamma"]],
    }[profile]
    manifests = {}
    if profile != "unowned":
        manifests["native-1.0-x86_64-1"] = [str(first), str(last).lstrip("/")]
    if profile == "single": manifests["alpha-1.0-x86_64-1_SBo"] = [str(first)]
    if profile == "shared":
        manifests |= {"alpha-1.0-x86_64-1_SBo": [str(first)], "alpha-2.0-noarch-2_SBo": [str(first)],
                      "beta-1.0-noarch-1_SBo": [str(first)], "gamma-1.0-x86_64-1_SBo": [str(last).lstrip("/")]}
    if profile == "duplicates":
        manifests |= {"alpha-1.0-x86_64-1_SBo": [str(first), str(last).lstrip("/")], "beta-1.0-noarch-1_SBo": [str(first)]}
    if profile == "last-owner":
        manifests |= {"beta-1.0-noarch-1_SBo": [str(last).lstrip("/")], "gamma-1.0-x86_64-1_SBo": [str(last)]}
    manifests["near-1.0-noarch-1_SBo"] = [str(first) + "-suffix", str(last) + "-suffix"]
    for name, lines in manifests.items():
        path = database / name; path.write_text("\n".join(lines) + "\n"); path.chmod(0o600)
    order = [] if profile in ("empty", "missing") else [first, first, last] if profile == "duplicates" else [first, last]
    broken, queue = root / "broken", root / "queue"
    if profile != "missing":
        broken.write_text("\n".join(map(str, order)) + ("\n" if order and terminated else "")); broken.chmod(0o600)
    queue.write_text("zeta\nabi\nzeta\n"); queue.chmod(0o640)
    expected = inventory(root)
    traversed, groups = [], []
    for path in order:
        group = names[0 if path == first else 1]
        traversed.append(path.name); groups.append(group)
        if writer != "normal" and group:
            break
    active = writer != "normal" and any(groups)
    entered = bool(order)
    targets = sorted({"abi", "zeta"} | {name for group in groups for name in group})
    if entered and not active:
        expected["queue"] = ("file", 0o600, "".join(name + "\n" for name in targets).encode())
    total = len(targets) if entered and not active else 9
    error = "cannot collect broken-object SBo owners" if active else ""
    code = {"normal": 0, "first-quiet": 43, "first-late": 127, "all-quiet": 1, "all-late": 43}[writer]
    settings = dict(BROKEN=broken, QUEUE_EXTRA=queue, PACKAGE_DATABASE=database, SBO_PACKAGE_TAG="_SBo",
        SBO_TARGET_SELECTION_ERROR="", TOTAL_EXTRA=9, ELF_SCAN_STATUS=8, ELF_VERIFICATION_STATUS=7,
        PLAN_ABI_SBO_COUNT=6, TOTAL_CORE=5, _BROKEN_PKGS="outer-stage", WRITER=writer, WRITER_STATUS=code, WRITES=0)
    shell = SETUP + "\n" + "\n".join(name + "() { forbidden " + name + "; }" for name in GUARDS)
    shell += "\n" + "\n".join(name + "=" + shlex.quote(str(value)) for name, value in settings.items()) + "\n"
    shell += "IFS='|: '\nsaved_ifs=$IFS\nowner_records=outer-records\nowner_status=outer-status\ntotal_extra=outer-total\nemission_failed=123\n"
    shell += ('if map_broken_objects_to_sbo_packages; then result=0; else result=$?; fi\n' if conditional else 'map_broken_objects_to_sbo_packages\nresult=$?\n')
    shell += '[[ $IFS == "$saved_ifs" && $owner_records == outer-records && $owner_status == outer-status && $total_extra == outer-total && $emission_failed == 123 ]] || exit 96\n'
    shell += ('[[ $_BROKEN_PKGS == "$TEST_ROOT/tmp."* && ! -e $_BROKEN_PKGS ]] || exit 96\n' if entered else '[[ $_BROKEN_PKGS == outer-stage ]] || exit 96\n')
    shell += 'builtin printf "\\0STATE\\0%s\\0%s\\0%s\\0%s\\0%s\\0%s\\0%s\\0" "$result" "$TOTAL_EXTRA" "$SBO_TARGET_SELECTION_ERROR" "$ELF_SCAN_STATUS" "$ELF_VERIFICATION_STATUS" "$PLAN_ABI_SBO_COUNT" "$TOTAL_CORE"\n'
    completed = subprocess.run(["bash", "--noprofile", "--norc", "-c", shell, "owner-emission", str(REFERENCE), str(root)],
        capture_output=True, cwd=root, env=dict(os.environ, LC_ALL="C", TMPDIR=str(root)), timeout=15)
    output = "[9] Mapeando binarios rotos a paquetes SBo\n"
    output += "  [ERROR] " + error + "\n" if active else "  Cola extra tras rotos: " + str(total) + " paquetes\n" if entered else "  Sin binarios rotos, nada que anadir\n"
    wanted = output.encode() + b"\0STATE\0" + b"\0".join(str(v).encode() for v in [1 if active else 0, total, error, 8, 7, 6, 5]) + b"\0"
    label = dict(profile=profile, writer=writer, final_newline=terminated, conditional=conditional)
    assert (completed.returncode, completed.stdout, completed.stderr) == (0, wanted, b""), (label, completed, wanted)
    events = [line.split("|") for line in (root / "trace").read_text().splitlines()] if (root / "trace").exists() else []
    assert [e[1] for e in events if e[0] == "lookup"] == traversed
    allocations = {e[1]: e[2] for e in events if e[0] == "allocate"}
    assert set(allocations) == ({"owners"} if active else {"owners", "merged", "normalizer"} if entered else set())
    observed = []
    for event in events:
        if event[0] == "lookup": observed.append([])
        elif event[0] in ("write", "fault"): observed[-1].append(event)
    failures = 0
    for expected_names, stream in zip(groups, observed):
        writes = [e for e in stream if e[0] == "write"]
        assert [e[1] for e in writes] == [str(i) for i in range(1, len(expected_names) + 1)]
        assert Counter(e[2] for e in writes) == Counter(expected_names)
        indices = list(range(1, len(expected_names) + 1)) if writer != "normal" and writer.startswith("all-") else [1] if writer != "normal" and expected_names else []
        assert [e for e in stream if e[0] == "fault"] == [["fault", str(i), writer, str(code)] for i in indices]
        failures += len(indices)
    success = entered and not active
    assert Counter(e[0] for e in events) == Counter(lookup=len(traversed), allocate=len(allocations),
        write=sum(map(len, groups)), fault=failures, **{"owner-sort": int(entered), "merge-input": int(success),
        "merge-sort": int(success), "merge-stage": int(success), "count": int(success), "publish": int(success),
        "remove": 2 if success else 1 if entered else 0}), (label, events)
    expected_removes = [("map_broken_objects_to_sbo_packages", allocations["owners"])] if entered else []
    if success: expected_removes.append(("normalize_sbo_target_names_from_stream", allocations["normalizer"]))
    assert Counter(tuple(e[1:]) for e in events if e[0] == "remove") == Counter(expected_removes)
    if success:
        assert [e for e in events if e[0] == "merge-input"] == [["merge-input", allocations["owners"]]]
        assert [e for e in events if e[0] == "merge-sort"] == [["merge-sort", allocations["normalizer"]]]
        assert [e for e in events if e[0] == "merge-stage"] == [["merge-stage", allocations["merged"]]]
    assert inventory(root) == expected, (label, inventory(root), expected)
    normalized = [[next(("<" + kind.upper() + ">" for kind, value in allocations.items() if field == value), field) for field in event] for event in events]
    return label | dict(active_fault=active, inactive_fault=writer != "normal" and not active, entered=entered,
        raw_status=1 if active else 0, total_extra=total, error=error, traversed_objects=traversed,
        selected_groups=groups, failed_emissions=failures, published=success, private_inventory_exact=True,
        stdout=completed.stdout.decode(), stderr=completed.stderr.decode(), events=normalized,
        owner_stage_global="removed-private-path" if entered else "unchanged")


def main():
    rows = []
    for cell in itertools.product(PROFILES, ("normal", "first-quiet", "first-late", "all-quiet", "all-late"), (False, True), (False, True)):
        with tempfile.TemporaryDirectory(prefix="owner-emission-test-") as temporary:
            rows.append(scenario(Path(temporary), *cell))
    totals = dict(cases=len(rows), active=sum(r["active_fault"] for r in rows), inactive=sum(r["inactive_fault"] for r in rows),
        normal=sum(r["writer"] == "normal" for r in rows), multiple_fault_cases=sum(r["failed_emissions"] > 1 for r in rows),
        failed_emissions=sum(r["failed_emissions"] for r in rows))
    assert totals == dict(cases=160, active=64, inactive=64, normal=32, multiple_fault_cases=24, failed_emissions=96), totals
    if len(sys.argv) == 3 and sys.argv[1] == "--report":
        Path(sys.argv[2]).write_text(json.dumps(dict(schema=1, totals=totals, rows=rows,
            scope="Real private grep/parser/emission/owner collection/merge/count/publication; supplied writer faults; no native DB or full apply"),
            indent=2, sort_keys=True) + "\n")
    else:
        assert len(sys.argv) == 1, "usage: test-sbo-owner-emission.py [--report /absolute/report.json]"
    print("SBo owner emission: 160 scenarios PASS; 64 active refusals before merge/count/publication; 64 inactive fault controls; 32 normal controls; private inventory exact")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
