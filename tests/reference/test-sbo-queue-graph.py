#!/usr/bin/env python3
"""Check real SBo constraint parsing and AWK ordering against authored graph models."""

from pathlib import Path
import itertools
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
PREFIX = r'''
source "$1"
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
'''
FORBIDDEN = ("main", "initialize_execution_environment", "initialize_runtime", "load_configuration",
             "run_check_workflow", "run_dry_run_workflow", "run_apply_workflow", "sbopkg", "sqg",
             "slackpkg", "flatpak", "git", "curl", "wget", "find", "mktemp", "mv", "rm",
             "collect_ordered_sbo_targets_from_queue_directory", "build_sbo_core_queue",
             "build_and_apply_sbo_queue")
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)


def ordered_prefix(nodes, edges):
    """Select from a mathematical relation; do not translate the AWK heap."""
    remaining = set(nodes) | {node for edge in edges for node in edge}
    result = []
    while remaining:
        eligible = [node for node in sorted(remaining)
                    if not any(left in remaining and right == node for left, right in edges)]
        if not eligible:
            return 2, "".join(node + "\n" for node in result)
        result.append(eligible[0])
        remaining.remove(eligible[0])
    return 0, "".join(node + "\n" for node in result)


def graph_cases():
    nodes = ("Z_1", "a+lib", "a-1")
    pairs = tuple(itertools.product(nodes, repeat=2))
    for mask in range(1 << len(pairs)):
        edges = {edge for index, edge in enumerate(pairs) if mask & (1 << index)}
        records = ["N\t" + node for node in nodes]
        records += ["E\t" + left + "\t" + right for left, right in sorted(edges)]
        yield f"three-node-{mask}", nodes, edges, records
    nodes = ("z", "b", "A", "_lib")
    pairs = tuple(itertools.combinations(nodes, 2))
    for mask in range(1 << len(pairs)):
        edges = {edge for index, edge in enumerate(pairs) if mask & (1 << index)}
        records = ["N\t" + node for node in nodes]
        records += ["E\t" + left + "\t" + right for left, right in sorted(edges)]
        yield f"four-node-dag-{mask}", nodes, edges, records
    yield "empty", (), set(), []
    yield "edge-only", (), {("z", "a"), ("a", "b")}, ["E\tz\ta", "E\ta\tb"]
    yield "cycle-and-free-prefix", ("0", "a", "b"), {("a", "b"), ("b", "a")}, [
        "N\t0", "E\ta\tb", "E\tb\ta"]


# Input records and exact graph bytes are authored separately from reference output.
CONSTRAINT_CASES = (
    ("empty", "", 0, ""),
    ("controls", "\n# comment\n@recursive\n-disabled\n \t \r\n", 0, ""),
    ("dependency", "z-dep\na-app\n", 0, "N\tz-dep\nN\ta-app\nE\tz-dep\ta-app\n"),
    ("duplicate", "a\na\nb\na\n", 0, "N\ta\nN\ta\nN\tb\nE\ta\tb\nN\ta\nE\tb\ta\n"),
    ("controls-between", "z\n@ref\n-no\n# c\na", 0, "N\tz\nN\ta\nE\tz\ta\n"),
    ("options-crlf", " z \r\na | TESTS=no\r\n", 0, "N\tz\nN\ta\nE\tz\ta\n"),
    ("quoted-options", "z | X='two words'\na | V=\"yes\" # tail", 0,
     "N\tz\nN\ta\nE\tz\ta\n"),
    ("comment-tail", "z# tail\na # end\n", 0, "N\tz\nN\ta\nE\tz\ta\n"),
    ("bad-first", "../escape\na\n", 2, ""),
    ("bad-later", "z\n../escape\na\n", 2, "N\tz\n"),
    ("bad-space", "a b\n", 2, ""),
    ("bad-options", "z\na | BAD=$(touch nope)\nb\n", 2, "N\tz\n"),
    ("extra-pipe", "a | V=yes | extra\n", 2, ""),
    ("empty-options", "a | \n", 2, ""),
    ("control-before-options", "@ref | V=$(nope)\n-disabled | nope\na\n", 0, "N\ta\n"),
    ("pipe-before-control", "@ref | x | y\n", 2, ""),
    ("dot", ".\n", 2, ""),
    ("dot-dot", "..\n", 2, ""),
    ("leading-dot", ".hidden\n+name\n", 0, "N\t.hidden\nN\t+name\nE\t.hidden\t+name\n"),
    ("internal-cr", "a\rb\n", 2, ""),
)


def invoke(script, data, workspace, *arguments):
    environment = dict(os.environ, LC_ALL="C", TMPDIR=str(workspace))
    return subprocess.run(["bash", "--noprofile", "--norc", "-c", PREFIX + GUARDS + script,
                           "sbo-graph-test", str(REFERENCE), *map(str, arguments)],
                          input=data.encode(), capture_output=True, cwd=workspace,
                          env=environment, timeout=10)


def check(result, status, output, label):
    actual = (result.returncode, result.stdout.decode(), result.stderr.decode())
    expected = (status, output, "")
    if actual != expected:
        raise AssertionError(f"{label}: expected {expected!r}, got {actual!r}")


def run():
    graphs = constraints = invalid = 0
    with tempfile.TemporaryDirectory(prefix="slack-update-sbo-graph-") as temporary:
        workspace = Path(temporary)
        for name, nodes, edges, records in graph_cases():
            status, expected = ordered_prefix(nodes, edges)
            for variant in (records, list(reversed(records)), records + records):
                data = "\n".join(variant) + ("\n" if variant else "")
                check(invoke("\norder_sbo_queue_graph\n", data, workspace), status, expected, name)
                graphs += 1
        for bad in ("X\ta", "N", "N\ta\tb", "E\ta", "E\ta\tb\tc", "", " N\ta", "N\ta\r"):
            # CR is data inside a name, not rejected record syntax.
            status, expected = (0, "a\r\n") if bad == "N\ta\r" else (1, "")
            check(invoke("\norder_sbo_queue_graph\n", bad + "\n", workspace), status, expected,
                  "record-syntax-" + repr(bad))
            invalid += 1
        graph = workspace / "constraints"
        for name, data, status, expected in CONSTRAINT_CASES:
            for seed in ("", "N\tseed\n"):
                graph.write_text(seed)
                script = r'''
outer=kept
saved_ifs=$IFS
append_sbo_queue_constraints_from_stream "$2"
status=$?
[[ $outer == kept && $IFS == "$saved_ifs" ]] || exit 96
exit "$status"
'''
                check(invoke(script, data, workspace, graph), status, "", name)
                if graph.read_text() != seed + expected:
                    raise AssertionError(f"{name}: constraint append bytes differ")
                constraints += 1
        graph.unlink()
        # A supplied writer failure is distinct from a native permission test.
        script = r'''
printf() {
    case "$1" in
        'N\t%s\n'|'E\t%s\t%s\n') return 41 ;;
    esac
    builtin printf "$@"
}
append_sbo_queue_constraints_from_stream "$2"
'''
        check(invoke(script, "a\n", workspace, graph), 1, "", "graph-write-failure")
        if not graph.is_file() or graph.read_bytes() != b"":
            raise AssertionError("writer failure must retain the shell-created empty graph")
        graph.unlink()
        constraints += 1
        if any(workspace.iterdir()):
            raise AssertionError("unexpected private files remain")
    print(f"SBo queue graph tests: {graphs} graph entries, {invalid} record cases, "
          f"{constraints} constraint entries, 0 failures")


if __name__ == "__main__":
    run()
