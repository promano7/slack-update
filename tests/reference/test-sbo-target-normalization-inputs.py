#!/usr/bin/env python3
"""Check literal target layouts and first/second/third normalizer write faults."""
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
# Input, validated emission prefix, ordinary sorted output, invalid-record flag.
# Expected prefixes/results are authored; no parser derives these expectations.
PROFILES = {
    "empty": ([], [], "", False),
    "blank": (["", "", ""], [], "", False),
    "literal": (["pkg++", "foo.bar", "_hidden", ".dot", "x-y_9"], ["pkg++", "foo.bar", "_hidden", ".dot", "x-y_9"], ".dot\n_hidden\nfoo.bar\npkg++\nx-y_9\n", False),
    "duplicates": (["zeta", "alpha", "zeta", "alpha"], ["zeta", "alpha", "zeta", "alpha"], "alpha\nzeta\n", False),
    "blank-gaps": (["", "beta", "", "alpha", "", "beta", ""], ["beta", "alpha", "beta"], "alpha\nbeta\n", False),
    "digits": (["9p", "_pkg", "a_1"], ["9p", "_pkg", "a_1"], "9p\n_pkg\na_1\n", False),
    "dot-names": ([".config", "a..b", "..."], [".config", "a..b", "..."], "...\n.config\na..b\n", False),
    "trailing-punctuation": (["name-", "name+", "name."], ["name-", "name+", "name."], "name+\nname-\nname.\n", False),
    "invalid-dot": ([".", "alpha", "beta"], [], "", True),
    "invalid-space": (["alpha", "bad name", "beta"], ["alpha"], "", True),
    "invalid-slash": (["alpha", "beta", "bad/name"], ["alpha", "beta"], "", True),
    "invalid-tab": (["alpha", "\tbad", "beta"], ["alpha"], "", True),
    "invalid-parent": (["..", "alpha", "beta"], [], "", True),
    "invalid-at": (["@queue", "alpha", "beta"], [], "", True),
    "invalid-dash": (["-unsafe", "alpha", "beta"], [], "", True),
    "invalid-cr": (["alpha", "beta\r", "gamma"], ["alpha"], "", True),
}
WRITERS = {"normal": (0, 0), "first-quiet": (1, 43), "first-late": (1, 127),
           "second-quiet": (2, 43), "second-late": (2, 127), "third-quiet": (3, 43), "third-late": (3, 127)}
SHELL = r'''
source "$1"
TEST_ROOT=$2
TRACE=$TEST_ROOT/trace
deny() { builtin printf 'prohibited boundary: %s\n' "$1" >&2; exit 97; }
note() { builtin printf '%s\0' "$@" >> "$TRACE"; builtin printf '\n' >> "$TRACE"; }
mktemp() {
    [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 0 ]] || deny allocate-vector
    local file
    file=$(builtin command mktemp) || return $?
    [[ $file == "$TEST_ROOT"/tmp.* && -f $file && ! -L $file ]] || deny allocate-path
    [[ $(builtin command stat -c %a -- "$file") == 600 ]] || deny allocate-mode
    note allocate "$file"
    builtin printf '%s\n' "$file"
}
printf() {
    [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 2 && $1 == '%s\n' ]] || deny write-vector
    case "$2" in
        @ALLOWED@) ;;
        *) deny write-name ;;
    esac
    WRITES=$((WRITES + 1))
    note write "$WRITES" "$2"
    if [[ $WRITER != normal && $WRITES == "$FAULT_POSITION" ]]; then
        note fault "$WRITES" "$WRITER_STATUS"
        [[ $WRITER == *-late ]] || return "$WRITER_STATUS"
        builtin printf "$@"
        return "$WRITER_STATUS"
    fi
    builtin printf "$@"
}
sort() {
    [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 2 && $1 == -u && $2 == "$temporary" && $2 == "$TEST_ROOT"/tmp.* && -f $2 && ! -L $2 ]] || deny sort-vector
    note sort
    builtin command sort "$@"
}
rm() {
    [[ ${FUNCNAME[1]} == normalize_sbo_target_names_from_stream && $# == 2 && $1 == -f && $2 == "$temporary" && $2 == "$TEST_ROOT"/tmp.* && -f $2 && ! -L $2 ]] || deny remove-vector
    note remove
    builtin command rm "$@"
}
'''
GUARDS = ("main", "initialize_execution_environment", "load_configuration", "initialize_runtime",
    "initialize_dry_run_runtime", "configure_logging", "run_apply_workflow", "run_check_workflow",
    "run_dry_run_workflow", "collect_installed_sbo_targets", "enumerate_package_database_records",
    "collect_sbo_targets_from_queue_directory", "collect_ordered_sbo_targets_from_queue_directory",
    "package_names_with_build_suffix_from_stream", "map_broken_objects_to_sbo_packages",
    "detect_broken_elf_objects", "verify_broken_elf_objects_after_rebuild", "slackpkg", "sbopkg", "sqg",
    "flatpak", "readelf", "ldd", "ldconfig", "git", "curl", "wget", "find", "touch", "mv", "cp",
    "regenerate_initrd", "update_grub_configuration")


def inventory(root):
    result = {}
    for p in root.iterdir():
        if p.name == "trace":
            continue
        metadata = p.lstat()
        assert stat.S_ISREG(metadata.st_mode), (p, metadata)
        result[p.name] = (stat.S_IMODE(metadata.st_mode), p.read_bytes())
    return result


def scenario(root, profile, writer, newline, conditional):
    lines, prefix, ordinary, invalid = PROFILES[profile]
    position, code = WRITERS[writer]
    active = writer != "normal" and len(prefix) >= position
    attempted = prefix[:position] if active else prefix
    refused = active or invalid
    status = int(refused)
    output = "" if refused else ordinary
    (root / "input").write_bytes(("\n".join(lines) + ("\n" if newline else "")).encode())
    (root / "input").chmod(0o640)
    (root / "sentinel").write_bytes(b"unchanged\n"); (root / "sentinel").chmod(0o600)
    (root / "trace").touch(mode=0o600)
    before = inventory(root)
    # Quote every authored permitted name so punctuation stays literal in case.
    names = sorted(set(n for _, group, _, _ in PROFILES.values() for n in group))
    script = SHELL.replace("@ALLOWED@", "|".join(shlex.quote(n) for n in names))
    script += "\n".join(n + "() { deny " + n + "; }" for n in GUARDS) + "\n"
    values = dict(WRITER=writer, FAULT_POSITION=position, WRITER_STATUS=code, WRITES=0)
    script += "\n".join(n + "=" + shlex.quote(str(v)) for n, v in values.items()) + "\n"
    script += "umask 077\nIFS='|: '\nsaved_ifs=$IFS\ntarget=outer-target\ntemporary=outer-temporary\nstatus=outer-status\n"
    operation = 'normalize_sbo_target_names_from_stream < "$TEST_ROOT/input"'
    script += ("if " + operation + "; then answer=0; else answer=$?; fi\n" if conditional else operation + "\nanswer=$?\n")
    script += '[[ $IFS == "$saved_ifs" && $target == outer-target && $temporary == outer-temporary && $status == outer-status ]] || exit 96\n'
    script += 'builtin printf "\\0STATUS\\0%s\\0" "$answer"\n'
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", script, "normalizer-inputs", str(REFERENCE), str(root)],
        cwd=root, capture_output=True, env=dict(os.environ, TMPDIR=str(root), LC_ALL="C"), timeout=10)
    label = dict(profile=profile, writer=writer, final_newline=newline, conditional=conditional)
    expected = output.encode() + b"\0STATUS\0" + str(status).encode() + b"\0"
    assert (result.returncode, result.stdout, result.stderr) == (0, expected, b""), (label, result, expected)
    events = [line[:-1].decode().split("\0") for line in (root / "trace").read_bytes().splitlines()]
    assert len(events[0]) == 2 and events[0][0] == "allocate", (label, events)
    allocation = Path(events[0][1]); assert allocation.parent == root and allocation.name.startswith("tmp.")
    wanted = [["allocate", "<TEMPORARY>"]]
    for i, n in enumerate(attempted, 1):
        wanted.append(["write", str(i), n])
        if active and i == position:
            wanted.append(["fault", str(i), str(code)])
    if not refused:
        wanted.append(["sort"])
    wanted.append(["remove"])
    normalized = [["allocate", "<TEMPORARY>"]] + events[1:]
    assert normalized == wanted, (label, normalized, wanted)
    assert inventory(root) == before and not allocation.exists(), (label, inventory(root), before)
    assert stat.S_IMODE((root / "trace").stat().st_mode) == 0o600
    return label | dict(active_fault=active, invalid_record=invalid, raw_status=status, sort_called=not refused,
        fault_position=position, failed_writes=int(active), stdout=result.stdout.decode(), stderr=result.stderr.decode(),
        events=normalized, private_inventory_exact=True, temporary_mode=0o600)


def main():
    rows = []
    for cell in itertools.product(PROFILES, WRITERS, (False, True), (False, True)):
        with tempfile.TemporaryDirectory(prefix="normalizer-inputs-") as area:
            rows.append(scenario(Path(area), *cell))
    totals = dict(cases=len(rows), active=sum(r["active_fault"] for r in rows),
        inactive=sum(r["writer"] != "normal" and not r["active_fault"] for r in rows),
        normal=sum(r["writer"] == "normal" for r in rows), invalid=sum(r["invalid_record"] for r in rows),
        sorted=sum(r["sort_called"] for r in rows), failed_writes=sum(r["failed_writes"] for r in rows))
    assert totals == dict(cases=448, active=184, inactive=200, normal=64, invalid=224, sorted=80, failed_writes=184), totals
    if len(sys.argv) == 3 and sys.argv[1] == "--report":
        Path(sys.argv[2]).write_text(json.dumps(dict(schema=1, totals=totals, rows=rows,
            scope="Direct normalizer literal/input/positional-writer cells;real selected private IO;no caller/native acceptance"),
            indent=2, sort_keys=True) + "\n")
    else:
        assert len(sys.argv) == 1, "usage: test-sbo-target-normalization-inputs.py [--report /absolute/report.json]"
    print("SBo target normalization inputs: 448 scenarios PASS; 184 active positional refusals; 200 inactive fault controls; 64 normal controls; literal names and ordered duplicate attempts")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
