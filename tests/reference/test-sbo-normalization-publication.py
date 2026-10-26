#!/usr/bin/env python3
"""Compose normalizer writer refusal with three private publication helpers."""
from collections import Counter
import argparse
import itertools
import json
import os
from pathlib import Path
import shlex
import stat
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
PROFILES = {"empty": [], "one": ["alpha"], "two": ["beta", "alpha"],
    "duplicates": ["zeta", "alpha", "alpha"], "literal": [".dot", "pkg++", "name-with-dash"],
    "alias": ["zeta", "alpha", "alpha"]}
WRITERS = {"normal": (0, 0), "first-quiet": (1, 43), "first-late": (1, 127),
    "second-quiet": (2, 43), "second-late": (2, 127), "third-quiet": (3, 43), "third-late": (3, 127)}
OPERATIONS = {"queue": "collect_sbo_targets_from_queue_directory", "installed": "collect_installed_sbo_targets", "merge": "merge_sbo_target_sets"}
SHELL = r'''
source "$1"
TEST_ROOT=$2
TRACE=$TEST_ROOT/trace
STAGED=$TEST_ROOT/normalizer-input
deny() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
note() { builtin printf '%s\0' "$@" >> "$TRACE"; builtin printf '\n' >> "$TRACE"; }
# Preserve the sourced body under a distinct name, then supply a bounded adapter.
definition=$(declare -f normalize_sbo_target_names_from_stream)
eval "${definition/normalize_sbo_target_names_from_stream/source_normalizer}"
normalize_sbo_target_names_from_stream() {
    [[ $# == 0 && ${FUNCNAME[1]} == "$OPERATION" && ! -e $STAGED ]] || deny stage-vector
    note stage
    # Stage the complete producer stream before injecting a downstream writer fault.
    # Concurrent upstream SIGPIPE/backpressure is intentionally outside this test.
    builtin command cat > "$STAGED" || deny stage-input
    source_normalizer < "$STAGED"
}
mktemp() {
    local caller=${FUNCNAME[1]} file
    [[ $caller == "$OPERATION" || $caller == source_normalizer ]] || deny allocate-caller
    [[ $# == 0 || ( $# == 1 && $1 == "$TEST_ROOT/.sbo-targets.XXXXXX" && $caller == "$OPERATION" ) ]] || deny allocate-vector
    file=$(builtin command mktemp "$@") || return $?
    [[ $file == "$TEST_ROOT"/tmp.* || $file == "$TEST_ROOT"/.sbo-targets.* ]] || deny allocate-path
    [[ -f $file && ! -L $file && $(builtin command stat -c %a -- "$file") == 600 ]] || deny allocate-file
    note allocate "$caller" "$file"
    builtin printf '%s\n' "$file"
}
printf() {
    if [[ ${FUNCNAME[1]} == source_normalizer ]]; then
        [[ $# == 2 && $1 == '%s\n' ]] || deny write-vector
        case "$2" in alpha|beta|zeta|.dot|pkg++|name-with-dash) ;; *) deny write-name ;; esac
        WRITES=$((WRITES + 1))
        note write "$WRITES" "$2"
        if [[ $WRITER != normal && $WRITES == "$FAULT_POSITION" ]]; then
            note fault "$WRITES" "$WRITER_STATUS"
            [[ $WRITER == *-late ]] || return "$WRITER_STATUS"
            builtin printf "$@"
            return "$WRITER_STATUS"
        fi
    fi
    builtin printf "$@"
}
find() {
    if [[ ${FUNCNAME[1]} == enumerate_package_database_records ]]; then
        [[ $# == 8 && $1 == -H && $2 == "$PACKAGE_DATABASE" && $3 == -maxdepth && $4 == 1 && $5 == -type && $6 == f && $7 == -printf && $8 == '%f\n' ]] || deny enumeration-vector
    else
        [[ ${FUNCNAME[1]} == collect_sbo_targets_from_queue_directory && $# == 6 && $1 == "$TEST_ROOT/queues" && $2 == -type && $3 == f && $4 == -name && $5 == '*.sqf' && $6 == -print0 ]] || deny queue-enumeration-vector
    fi
    builtin command find "$@"
}
sort() {
    if [[ ${FUNCNAME[1]} == source_normalizer ]]; then
        [[ $# == 2 && $1 == -u && $2 == "$temporary" && $2 == "$TEST_ROOT"/tmp.* && -f $2 && ! -L $2 ]] || deny sort-vector
        note sort
    else
        [[ ${FUNCNAME[1]} == collect_sbo_targets_from_queue_directory && $# == 1 && $1 == -z ]] || deny queue-sort-vector
    fi
    builtin command sort "$@"
}
cat() {
    [[ ${FUNCNAME[1]} == merge_sbo_target_sets && $# == 2 && $1 == "$TEST_ROOT/set-a" && ( $2 == "$TEST_ROOT/set-b" || $2 == "$TEST_ROOT/set-b-alias" ) ]] || deny merge-input-vector
    builtin command cat "$@"
}
mv() {
    [[ ${FUNCNAME[1]} == "$OPERATION" && $# == 4 && $1 == -f && $2 == -- && $3 == "$candidate" && $3 == "$TEST_ROOT"/.sbo-targets.* && $4 == "$TEST_ROOT/selected" && -f $3 && ! -L $3 ]] || deny publish-vector
    note publish "$3"
    builtin command mv "$@"
}
rm() {
    [[ ${FUNCNAME[1]} == "$OPERATION" || ${FUNCNAME[1]} == source_normalizer ]] || deny remove-caller
    [[ $1 == -f && $# -ge 2 && $# -le 4 ]] || deny remove-vector
    local file
    for file in "${@:2}"; do
        [[ ( $file == "$TEST_ROOT"/tmp.* || $file == "$TEST_ROOT"/.sbo-targets.* ) && -f $file && ! -L $file ]] || deny remove-path
        note remove "${FUNCNAME[1]}" "$file"
    done
    builtin command rm "$@"
}
'''
GUARDS = ("main", "initialize_execution_environment", "load_configuration", "initialize_runtime",
    "initialize_dry_run_runtime", "configure_logging", "run_apply_workflow", "run_check_workflow", "run_dry_run_workflow",
    "collect_ordered_sbo_targets_from_queue_directory", "map_broken_objects_to_sbo_packages", "detect_broken_elf_objects",
    "verify_broken_elf_objects_after_rebuild", "add_abi_rebuild_targets", "collect_installed_sbo_candidates",
    "slackpkg", "sbopkg", "sqg", "flatpak", "readelf", "ldd", "ldconfig", "git", "curl", "wget",
    "touch", "cp", "regenerate_initrd", "update_grub_configuration")


def inventory(root):
    result = {}
    for p in root.rglob("*"):
        relative = p.relative_to(root).as_posix()
        if relative == "trace":
            continue
        mode = p.lstat().st_mode
        if stat.S_ISLNK(mode):
            value = ("link", stat.S_IMODE(mode), os.readlink(p))
        elif stat.S_ISDIR(mode):
            value = ("directory", stat.S_IMODE(mode))
        else:
            assert stat.S_ISREG(mode), (p, mode)
            value = ("file", stat.S_IMODE(mode), p.read_bytes())
        result[relative] = value
    return result


def put(path, data, mode=0o600):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data); path.chmod(mode)


def scenario(root, phase, profile, writer, seeded, conditional):
    names = PROFILES[profile]
    if phase == "queue":
        directory = root / "queues"; directory.mkdir(mode=0o700)
        put(directory / "a queue.sqf", ("# private queue\n" + "\n".join(names[:1]) + "\n").encode())
        put(directory / "nested/z.sqf", ("\n".join(names[1:]) + "\n").encode())
        (directory / "nested").chmod(0o700)
        put(directory / "ignored.txt", b"@unselected\n")
        if profile == "alias": (directory / "linked.sqf").symlink_to("a queue.sqf")
        command = 'collect_sbo_targets_from_queue_directory "$TEST_ROOT/queues" "$TEST_ROOT/selected"'
        argument = root / "unused-database"
    elif phase == "installed":
        directory = root / "packages"; directory.mkdir(mode=0o700)
        for i, name in enumerate(names): put(directory / (name + "-" + str(i + 1) + ".0-x86_64-1_SBo"), b"private inert manifest\n")
        put(directory / "native-1.0-noarch-1", b"native nonselected\n")
        put(directory / "malformed", b"invalid nonselected record\n")
        (directory / "ignored-dir-1.0-noarch-1_SBo").mkdir(mode=0o700)
        if names: (directory / "ignored-link-1.0-noarch-1_SBo").symlink_to(names[0] + "-1.0-x86_64-1_SBo")
        argument = directory
        if profile == "alias":
            (root / "database-alias").symlink_to("packages", target_is_directory=True); argument = root / "database-alias"
        command = 'collect_installed_sbo_targets "$TEST_ROOT/selected"'
    else:
        put(root / "set-a", ("\n".join(names[:1]) + ("\n" if names[:1] else "")).encode())
        put(root / "set-b", ("\n".join(names[1:]) + ("\n" if names[1:] else "")).encode())
        second = "set-b"
        if profile == "alias": (root / "set-b-alias").symlink_to("set-b"); second = "set-b-alias"
        argument = root / "unused-database"
        command = 'merge_sbo_target_sets "$TEST_ROOT/selected" "$TEST_ROOT/set-a" "$TEST_ROOT/' + second + '"'
    put(root / "sentinel", b"unchanged\n")
    if seeded: put(root / "selected", b"old-targets\n", 0o640)
    put(root / "trace", b"")
    before = inventory(root)
    position, code = WRITERS[writer]; active = writer != "normal" and len(names) >= position
    error = "old-error" if phase == "merge" else ("cannot normalize installed SBo package targets" if phase == "installed" else "cannot normalize SBo targets from: " + str(root / "queues")) if active else ""
    operation = OPERATIONS[phase]
    guards = GUARDS + tuple(n for n in OPERATIONS.values() if n != operation)
    script = SHELL + "\n".join(n + "() { deny " + n + "; }" for n in guards) + "\n"
    settings = dict(OPERATION=operation, PACKAGE_DATABASE=argument, SBO_PACKAGE_TAG="_SBo", SBO_TARGET_SELECTION_ERROR="old-error",
        WRITER=writer, FAULT_POSITION=position, WRITER_STATUS=code, WRITES=0, TOTAL_CORE=7, TOTAL_EXTRA=8, PLAN_ABI_SBO_COUNT=9)
    script += "\n".join(n + "=" + shlex.quote(str(v)) for n, v in settings.items()) + "\n"
    script += "umask 077\nIFS='|: '\nsaved_ifs=$IFS\ndestination=outer-destination\ncandidate=outer-candidate\nqueue_listing=outer-listing\nraw_targets=outer-raw\npackage_records=outer-records\ntarget=outer-target\ntemporary=outer-temporary\nstatus=outer-status\n"
    script += ("if " + command + "; then answer=0; else answer=$?; fi\n" if conditional else command + "\nanswer=$?\n")
    script += '[[ $IFS == "$saved_ifs" && $destination == outer-destination && $candidate == outer-candidate && $queue_listing == outer-listing && $raw_targets == outer-raw && $package_records == outer-records && $target == outer-target && $temporary == outer-temporary && $status == outer-status ]] || exit 96\n'
    script += 'builtin printf "\\0STATE\\0%s\\0%s\\0%s\\0%s\\0%s\\0" "$answer" "$SBO_TARGET_SELECTION_ERROR" "$TOTAL_CORE" "$TOTAL_EXTRA" "$PLAN_ABI_SBO_COUNT"\n'
    completed = subprocess.run(["bash", "--noprofile", "--norc", "-c", script, "normalization-publication", str(REFERENCE), str(root)],
        cwd=root, capture_output=True, env=dict(os.environ, LC_ALL="C", TMPDIR=str(root)), timeout=15)
    label = dict(phase=phase, profile=profile, writer=writer, seeded=seeded, conditional=conditional)
    expected_output = b"\0STATE\0" + b"\0".join(str(v).encode() for v in [int(active), error, 7, 8, 9]) + b"\0"
    assert (completed.returncode, completed.stdout, completed.stderr) == (0, expected_output, b""), (label, completed, expected_output)
    staged = (root / "normalizer-input").read_bytes(); lines = staged.decode().splitlines()
    assert staged == "".join(n + "\n" for n in lines).encode() and Counter(lines) == Counter(names), (label, staged, names)
    if phase != "installed": assert lines == names, (label, lines, names)
    events = [line[:-1].decode().split("\0") for line in (root / "trace").read_bytes().splitlines()]
    allocations = [e for e in events if e[0] == "allocate"]
    count = {"queue": 4, "installed": 3, "merge": 2}[phase]
    assert len(allocations) == count and len({e[2] for e in allocations}) == count, (label, events)
    assert [e[1] for e in allocations] == [operation] * (count - 1) + ["source_normalizer"]
    candidate = allocations[count - 2][2]; temporary = allocations[-1][2]
    assert Path(candidate).name.startswith(".sbo-targets.")
    for e in allocations: assert Path(e[2]).parent == root and not Path(e[2]).exists()
    attempted = lines[:position] if active else lines
    expected_events = allocations[:-1] + [["stage"], allocations[-1]]
    for i, n in enumerate(attempted, 1):
        expected_events.append(["write", str(i), n])
        if active and i == position: expected_events.append(["fault", str(i), str(code)])
    if not active: expected_events.append(["sort"])
    expected_events.append(["remove", "source_normalizer", temporary])
    if not active: expected_events.append(["publish", candidate])
    removed = allocations[:-1] if active else allocations[:-2]
    expected_events.extend(["remove", operation, e[2]] for e in removed)
    assert events == expected_events, (label, events, expected_events)
    after = dict(before, **{"normalizer-input": ("file", 0o600, staged)})
    if not active: after["selected"] = ("file", 0o600, "".join(n + "\n" for n in sorted(set(names))).encode())
    assert inventory(root) == after and stat.S_IMODE((root / "trace").stat().st_mode) == 0o600, (label, inventory(root), after)
    aliases = {e[2]: "<ALLOCATED-" + str(i) + ">" for i, e in enumerate(allocations, 1)}
    return label | dict(active_fault=active, raw_status=int(active), error=error, published=not active,
        stdout=completed.stdout.decode(), stderr=completed.stderr.decode(), staged_input=staged.decode(),
        events=[[aliases.get(v, v) for v in e] for e in events], selected_count_globals=[7, 8, 9], private_inventory_exact=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--phase", choices=OPERATIONS)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args(); rows = []
    phases = [args.phase] if args.phase else list(OPERATIONS)
    for cell in itertools.product(phases, PROFILES, WRITERS, (False, True), (False, True)):
        with tempfile.TemporaryDirectory(prefix="normalization-publication-") as area:
            rows.append(scenario(Path(area), *cell))
    totals = dict(cases=len(rows), active=sum(r["active_fault"] for r in rows),
        inactive=sum(r["writer"] != "normal" and not r["active_fault"] for r in rows),
        normal=sum(r["writer"] == "normal" for r in rows), published=sum(r["published"] for r in rows))
    scale = len(phases)
    assert totals == dict(cases=168*scale, active=96*scale, inactive=48*scale, normal=24*scale, published=72*scale), totals
    if args.report: args.report.write_text(json.dumps(dict(schema=1, totals=totals, rows=rows,
        producer_input_staged_before_fault=True, concurrent_upstream_pipe_failure_covered=False,
        scope="Three real private publication helpers with explicit complete-input staging adapter and sourced normalizer body;no workflow/native acceptance"), indent=2, sort_keys=True) + "\n")
    print("SBo normalization publication: " + str(totals["cases"]) + " scenarios PASS; " + str(totals["active"]) + " active refusals before publication; " + str(totals["inactive"]) + " inactive fault controls; " + str(totals["normal"]) + " normal controls; staged producer input")
    return 0


if __name__ == "__main__": raise SystemExit(main())
