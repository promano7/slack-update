#!/usr/bin/env python3
"""Exercise SBo directory selection and queue merging using owned private files."""

from pathlib import Path
import os
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
PREFIX = r'''
source "$1"
TEST_ROOT=$2
TEST_KIND=$3
TEST_FAULT=$4
QUEUE_DIRECTORY=$5
DESTINATION=$6
SBO_TARGET_SELECTION_ERROR=old-error
SBO_OPTION_NORMALIZATION_ERROR=old-option-error
outside=kept
saved_ifs=$IFS
forbidden() { builtin printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
fault() { builtin printf 'fault:%s\n' "$1" >&2; return 43; }
private_path() { [[ $1 == "$TEST_ROOT/"* ]] || forbidden path; }
mktemp() {
    local count
    read -r count < "$TEST_ROOT/counter"
    count=$((count + 1))
    builtin printf '%s\n' "$count" > "$TEST_ROOT/counter"
    [[ $TEST_FAULT == "mktemp-$count" ]] && { fault "$TEST_FAULT"; return 43; }
    [[ $# == 0 ]] || private_path "$1"
    command mktemp "$@"
}
find() {
    [[ $1 == "$QUEUE_DIRECTORY" ]] || forbidden find
    [[ $TEST_FAULT != find ]] || { fault find; return 43; }
    command find "$@"
}
sort() {
    if [[ $TEST_FAULT == sort-z && ${1-} == -z || $TEST_FAULT == sort-u && ${1-} == -u ]]; then
        fault "$TEST_FAULT"; return 43
    fi
    command sort "$@"
}
mv() {
    [[ $TEST_FAULT != mv ]] || { fault mv; return 43; }
    [[ $1 == -f && $2 == -- && $# == 4 ]] || forbidden mv-vector
    private_path "$3"; private_path "$4"
    command mv "$@"
}
rm() {
    [[ $1 == -f ]] || forbidden rm-vector
    shift
    local path
    for path in "$@"; do private_path "$path"; done
    command rm -f -- "$@"
}
if [[ $TEST_FAULT == graph-1 || $TEST_FAULT == graph-2 ]]; then
    order_sbo_queue_graph() { builtin printf 'private-prefix\n'; return "${TEST_FAULT#graph-}"; }
fi
'''
FORBIDDEN = ("main", "initialize_execution_environment", "initialize_runtime", "load_configuration",
             "run_check_workflow", "run_dry_run_workflow", "run_apply_workflow", "sbopkg", "sqg",
             "slackpkg", "flatpak", "git", "curl", "wget", "enumerate_package_database_records",
             "collect_installed_sbo_targets", "build_sbo_core_queue", "build_and_apply_sbo_queue")
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)
SUFFIX = r'''
case "$TEST_KIND" in
    ordered) collect_ordered_sbo_targets_from_queue_directory "$QUEUE_DIRECTORY" "$DESTINATION" ;;
    selected) collect_sbo_targets_from_queue_directory "$QUEUE_DIRECTORY" "$DESTINATION" ;;
    set) merge_sbo_target_sets "$DESTINATION" "${@:7}" ;;
    final) merge_ordered_sbo_queue_with_target_sets "$DESTINATION" "${@:7}" ;;
    *) forbidden kind ;;
esac
status=$?
[[ $outside == kept && $IFS == "$saved_ifs" ]] || exit 96
builtin printf '%s\0%s\0%s\0' "$status" "$SBO_TARGET_SELECTION_ERROR" "$SBO_OPTION_NORMALIZATION_ERROR"
'''

# Files are relative to the private queue root. None means an absent optional root.
# name, files, ordered expected bytes (None means a cycle), selected expected bytes
DIRECTORIES = (
    ("missing", None, "", ""),
    ("empty", {}, "", ""),
    ("shared", {"z.sqf": "z\nb\na\n", "sub/a.sqf": "z\nc\ny\n"},
     "z\nb\na\nc\ny\n", "a\nb\nc\ny\nz\n"),
    ("controls", {"q.sqf": "z\r\n@ref\n-disabled\n# c\na | V='two words'"}, "z\na\n", "a\nz\n"),
    ("duplicate", {"q.sqf": "z\nz\na\na\n"}, "z\na\n", "a\nz\n"),
    ("cycle", {"a.sqf": "a\nb\n", "b.sqf": "b\na\n"}, None, "a\nb\n"),
    ("names", {"new\nline.sqf": "z\na\n", "space name.sqf": "z\nb\n", "ignored.txt": "../bad\n"},
     "z\na\nb\n", "a\nb\nz\n"),
    ("invalid", {"q.sqf": "z\n../bad\na\n"}, "invalid", "invalid"),
    ("symlink-file", {"plain.txt": "../bad\n", "q.sqf": "z\na\n"}, "z\na\n", "a\nz\n"),
    ("symlink-root", {"q.sqf": "z\na\n"}, "", ""),
)

# name, core bytes or missing, option-map bytes or missing, extra file bytes, status, expected bytes
FINAL = (
    ("empty", "", "", [], 0, ""),
    ("missing-core-map", None, None, [], 0, ""),
    ("ordered", "z\na\n", "", [], 0, "z\na\n"),
    ("extras", "z\na\n", "", ["z\nb\nc\n", "b\nA\n"], 0, "z\na\nA\nb\nc\n"),
    ("duplicates", "z\nz\na\n", "", ["a\nz\n"], 0, "z\na\n"),
    ("inline", "z | V=yes\na | X='two words'", "", [], 0, "z | V=yes\na | X='two words'\n"),
    ("override", "z | V=yes\na\n", "z\tV=no\na\tX=1\nunused\tY=2\n", ["b\n"], 0,
     "z | V=no\na | X=1\nb\n"),
    ("same-map-duplicate", "z\n", "z\tV=yes\nz\tV=yes\n", [], 0, "z | V=yes\n"),
    ("conflicting-map", "z\n", "z\tV=yes\nz\tV=no\n", [], 1, None),
    ("invalid-map", "z\n", "../bad\tV=yes\n", [], 1, None),
    ("invalid-core", "z\n../bad\n", "", [], 2, None),
    ("core-control", "z\n@skip\n", "", [], 1, None),
    ("core-comment", "z\n# comment\n", "", [], 1, None),
    ("core-blank", "\nz\n\na\n", "", [], 0, "z\na\n"),
    ("core-crlf", "z\r\na\r\n", "", [], 0, "z\na\n"),
    ("invalid-extra", "z\n", "", ["a\n../bad\n"], 1, None),
    ("missing-extra", "z\n", "", [None], 1, None),
    ("first-inline-wins", "z | V=yes\nz | V=no\n", "", [], 0, "z | V=yes\n"),
    ("invalid-duplicate-still-rejected", "z\nz | V=$(nope)\n", "", [], 2, None),
)
SETS = (
    ("none", [], 0, ""),
    ("empty", [""], 0, ""),
    ("union", ["z\na\n", "b\na\n"], 0, "a\nb\nz\n"),
    ("no-newline", ["z\na"], 0, "a\nz\n"),
    ("joined-no-newline", ["z", "a\n"], 0, "za\n"),
    ("missing", ["z\n", None], 1, None),
    ("invalid", ["z\n../bad\n"], 1, None),
    ("whitespace", ["a b\n"], 1, None),
    ("blank-lines", ["\nz\n\na\n\n"], 0, "a\nz\n"),
)


def inventory(root):
    return {str(p.relative_to(root)): ("link", os.readlink(p)) if p.is_symlink()
            else ("directory",) if p.is_dir() else ("file", p.read_bytes())
            for p in root.rglob("*") if p.name != "counter"}


def invoke(root, kind, fault, queue, destination, arguments, status, error, option_error, expected, stderr=""):
    before = inventory(root)
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", PREFIX + GUARDS + SUFFIX,
                             "sbo-queue-files", str(REFERENCE), str(root), kind, fault, str(queue),
                             str(destination), *map(str, arguments)], input=b"", capture_output=True,
                            cwd=root, env=dict(os.environ, LC_ALL="C", TMPDIR=str(root / "tmp")), timeout=10)
    wanted = b"\0".join(str(field).encode() for field in (status, error, option_error)) + b"\0"
    if (result.returncode, result.stdout, result.stderr) != (0, wanted, stderr.encode()):
        raise AssertionError(f"{kind}/{fault}: expected {(0, wanted, stderr.encode())!r}, "
                             f"got {(result.returncode, result.stdout, result.stderr)!r}")
    after = inventory(root)
    relative = str(destination.relative_to(root))
    if status == 0:
        before[relative] = ("file", expected.encode())
    if after != before:
        raise AssertionError(f"{kind}/{fault}: unexpected private file changes: "
                             f"{[n for n in set(before) | set(after) if before.get(n) != after.get(n)]!r}")


def workspace(parent, index, seeded):
    root = parent / str(index)
    root.mkdir()
    (root / "tmp").mkdir()
    (root / "counter").write_text("0\n")
    destination = root / "destination"
    if seeded:
        destination.write_text("preserved\n")
    return root, destination


def run():
    collection = merging = faults = index = 0
    with tempfile.TemporaryDirectory(prefix="slack-update-sbo-files-") as temporary:
        parent = Path(temporary)
        for kind in ("ordered", "selected"):
            for name, files, ordered, selected in DIRECTORIES:
                for seeded in (False, True):
                    index += 1
                    root, destination = workspace(parent, index, seeded)
                    queue = root / "queues"
                    if files is not None:
                        queue.mkdir()
                        for path, data in files.items():
                            target = queue / path
                            target.parent.mkdir(parents=True, exist_ok=True)
                            target.write_text(data)
                    if name == "symlink-file":
                        (queue / "ignored-link.sqf").symlink_to(queue / "plain.txt")
                    if name == "symlink-root":
                        link = root / "queue-link"
                        link.symlink_to(queue, target_is_directory=True)
                        queue = link
                    expected = ordered if kind == "ordered" else selected
                    status, error = 0, ""
                    if expected is None:
                        status, error = 1, f"SBo queue dependency order is cyclic or contradictory in: {queue}"
                    elif expected == "invalid":
                        status, error = 1, f"queue contains an invalid SBo target: {queue / 'q.sqf'}"
                    invoke(root, kind, "none", queue, destination, [], status, error,
                           "old-option-error", expected)
                    collection += 1
            for fault in ("mktemp-1", "mktemp-2", "mktemp-3", "find", "sort-z", "mv",
                          *( ("graph-1", "graph-2") if kind == "ordered" else ("sort-u",) )):
                for seeded in (False, True):
                    index += 1
                    root, destination = workspace(parent, index, seeded)
                    queue = root / "queues"; queue.mkdir()
                    (queue / "q.sqf").write_text("z\na\n")
                    if fault in ("mktemp-1", "mktemp-2"):
                        error = ""
                    elif fault == "mktemp-3":
                        label = "ordered SBo queue" if kind == "ordered" else "SBo target set"
                        error = f"cannot create a temporary {label} in: {root}"
                    elif fault in ("find", "sort-z"):
                        error = f"cannot enumerate SBo queue files: {queue}"
                    elif fault == "mv":
                        label = "dependency-ordered SBo queue" if kind == "ordered" else "selected SBo targets"
                        error = f"cannot install {label}: {destination}"
                    elif fault == "graph-2":
                        error = f"SBo queue dependency order is cyclic or contradictory in: {queue}"
                    elif fault == "graph-1":
                        error = f"cannot resolve SBo queue dependency order from: {queue}"
                    else:
                        error = f"cannot normalize SBo targets from: {queue}"
                    stderr = "" if fault.startswith("graph-") else f"fault:{fault}\n"
                    invoke(root, kind, fault, queue, destination, [], 1, error,
                           "old-option-error", None, stderr)
                    faults += 1
        for kind, profiles in (("set", SETS), ("final", FINAL)):
            for profile in profiles:
                for seeded in (False, True):
                    index += 1
                    root, destination = workspace(parent, index, seeded)
                    if kind == "set":
                        name, extras, status, expected = profile
                        arguments = []
                    else:
                        name, core, options, extras, status, expected = profile
                        arguments = [root / "core", root / "options"]
                        for path, data in zip(arguments, (core, options)):
                            if data is not None:
                                path.write_text(data)
                    for i, data in enumerate(extras):
                        path = root / f"extra-{i}"
                        if data is not None:
                            path.write_text(data)
                        arguments.append(path)
                    option_error = "old-option-error"
                    if kind == "final" and name != "invalid-extra" and name != "missing-extra" and options is not None:
                        option_error = ""
                    if name == "conflicting-map":
                        option_error = "conflicting SBo build options for target: z"
                    elif name == "invalid-map":
                        option_error = "invalid SBo build-option record"
                    invoke(root, kind, "none", root / "unused", destination, arguments, status,
                           "old-error", option_error, expected)
                    merging += 1
            selected_faults = ("mktemp-1", "mktemp-2", "sort-u", "mv") if kind == "set" else (
                "mktemp-1", "mktemp-2", "mktemp-3", "mktemp-4", "sort-u", "mv")
            for fault in selected_faults:
                for seeded in (False, True):
                    index += 1
                    root, destination = workspace(parent, index, seeded)
                    extra = root / "extra"; extra.write_text("a\n")
                    arguments = [extra]
                    option_error = "old-option-error"
                    if kind == "final":
                        core, options = root / "core", root / "options"
                        core.write_text("z\n"); options.write_text("")
                        arguments = [core, options, extra]
                        if fault == "mv":
                            option_error = ""
                    invoke(root, kind, fault, root / "unused", destination, arguments, 1,
                           "old-error", option_error, None, f"fault:{fault}\n")
                    faults += 1
    print(f"SBo queue files tests: {collection} collection entries, {merging} merge entries, "
          f"{faults} supplied fault entries, 0 failures")


if __name__ == "__main__":
    run()
