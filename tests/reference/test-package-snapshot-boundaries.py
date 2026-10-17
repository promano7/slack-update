#!/usr/bin/env python3
"""Check snapshot validation, private atomic capture and wrapper failure limits."""

from pathlib import Path
import itertools
import shlex
import stat
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
RECORDS = ("zlib-1.3.1-x86_64-1", "aaa_libraries-15.0-x86_64-19", "gtk+3-3.24.49-x86_64-1.txz")
NORMALIZED = b"aaa_libraries-15.0-x86_64-19\ngtk+3-3.24.49-x86_64-1\nzlib-1.3.1-x86_64-1\n"
OLD = b"previous destination snapshot\n"
VALIDATORS = (
    ("missing", None, 1, 0, "snapshot does not exist: {destination}"),
    ("directory", None, 1, 0, "snapshot does not exist: {destination}"),
    ("empty", b"", 1, 0, "snapshot is empty: {destination}"),
    ("unreadable", NORMALIZED, 1, 0, "snapshot is not readable: {destination}"),
    ("unsorted", b"zlib-1.3.1-x86_64-1\naaa_libraries-15.0-x86_64-19\n", 1, 0,
     "snapshot records are not strictly sorted and unique: {destination}"),
    ("duplicate", b"zlib-1.3.1-x86_64-1\nzlib-1.3.1-x86_64-1\n", 1, 0,
     "snapshot records are not strictly sorted and unique: {destination}"),
    ("invalid", b"invalid-record\n", 1, 0, "snapshot contains an invalid package record: invalid-record"),
    ("archive", b"zlib-1.3.1-x86_64-1.txz\n", 1, 0,
     "snapshot contains a non-canonical package record: zlib-1.3.1-x86_64-1.txz"),
    ("path", b"/supplied/path/zlib-1.3.1-x86_64-1\n", 1, 0,
     "snapshot contains a non-canonical package record: /supplied/path/zlib-1.3.1-x86_64-1"),
    ("valid-one", b"zlib-1.3.1-x86_64-1\n", 0, 1, ""),
    ("valid-three", NORMALIZED, 0, 3, ""),
    ("valid-no-newline", b"zlib-1.3.1-x86_64-1", 0, 1, ""),
    ("invalid-tail", b"aaa_libraries-15.0-x86_64-19\nz-invalid\n", 1, 0,
     "snapshot contains an invalid package record: z-invalid"),
)
CAPTURES = ("regular", "compat-link", "internal-link", "nested", "missing-db", "db-file", "empty-db",
            "invalid-db", "duplicate-db", "unreadable-db", "unsearchable-db",
            "mktemp-1", "mktemp-2", "mktemp-3", "enumerate", "sort", "validate", "install")
PREFIX = r'''
source "$1"
WORK=$2
TRACE=$WORK/trace
HEAD_TRACE=$WORK/head-trace
COUNTER=$WORK/counter
DEST=$WORK/'destination snapshot'
BEFORE_PKGS=$WORK/'before snapshot'
AFTER_PKGS=$WORK/'after snapshot'
PACKAGE_DATABASE=$WORK/'database directory'
trace() { printf '%s\0' "$@" >> "$TRACE"; printf '\n' >> "$TRACE"; }
forbidden() { printf 'ERROR: prohibited boundary: %s\n' "$1" >&2; exit 97; }
tag() {
    case "$1" in
        "$DEST") printf destination ;;
        "$BEFORE_PKGS") printf before ;;
        "$AFTER_PKGS") printf after ;;
        "$PACKAGE_DATABASE") printf database ;;
        "$WORK/.package-records."*) printf listing ;;
        "$WORK/.package-normalized."*) printf normalized ;;
        "$WORK/.package-snapshot."*) printf candidate ;;
        *) forbidden "path:$1" ;;
    esac
}
function [ {
    local op= path= negate=0
    if [[ $# == 4 && $1 == '!' && $4 == ']' ]]; then op=$2; path=$3; negate=1
    elif [[ $# == 3 && $3 == ']' ]]; then op=$1; path=$2
    fi
    case "$op" in
        -f|-d|-r|-x|-s)
            tag "$path" >/dev/null
            if [[ ( $CASE == unreadable && $path == "$DEST" && $op == -r ) ||
                  ( $CASE == unreadable-db && $path == "$PACKAGE_DATABASE" && $op == -r ) ||
                  ( $CASE == unsearchable-db && $path == "$PACKAGE_DATABASE" && $op == -x ) ]]; then
                trace access "$op" "$(tag "$path")" false
                (( negate == 1 )); return
            fi
            ;;
    esac
    builtin [ "$@"
}
dirname() {
    [[ $# == 2 && $1 == -- && $2 == "$DEST" ]] || forbidden dirname-arguments
    trace dirname
    builtin command dirname "$@"
}
mktemp() {
    local number
    IFS= read -r number < "$COUNTER"
    number=$((number + 1)); printf '%s\n' "$number" > "$COUNTER"
    case "$number:$*" in
        "1:$WORK/.package-records.XXXXXX"|"2:$WORK/.package-normalized.XXXXXX"|"3:$WORK/.package-snapshot.XXXXXX") ;;
        *) forbidden mktemp-arguments ;;
    esac
    [[ $# == 1 ]] || forbidden mktemp-count
    trace mktemp "$number"
    [[ $CASE != "mktemp-$number" ]] || return 23
    builtin command mktemp "$@"
}
find() {
    [[ $# == 8 && $1 == -H && $2 == "$PACKAGE_DATABASE" && $3 == -maxdepth && $4 == 1 &&
       $5 == -type && $6 == f && $7 == -printf && $8 == '%f\n' ]] || forbidden find-arguments
    trace find
    builtin command find "$@" || return
    [[ $CASE != enumerate ]]
}
sort() {
    [[ ${LC_ALL:-} == C ]] || forbidden sort-locale
    if [[ $# == 3 && $1 == -c && $2 == -u ]]; then
        trace sort-check "$(tag "$3")"
    elif [[ $# == 1 && $(tag "$1") == normalized ]]; then
        trace sort-capture
        [[ $CASE != sort ]] || return 23
    else forbidden sort-arguments
    fi
    builtin command sort "$@"
}
uniq() {
    [[ $# == 2 && $1 == -d && $(tag "$2") == candidate ]] || forbidden uniq-arguments
    trace uniq
    builtin command uniq "$@"
}
head() {
    [[ $# == 2 && $1 == -n && $2 == 1 ]] || forbidden head-arguments
    printf 'head\n' >> "$HEAD_TRACE"
    builtin command head "$@"
}
rm() {
    [[ $# -ge 2 && $1 == -f ]] || forbidden rm-arguments
    shift
    local path
    local tags=()
    for path in "$@"; do tags+=("$(tag "$path")"); done
    trace rm "${tags[@]}"
    [[ $CASE != remove ]] || return 23
    builtin command rm -f -- "$@"
}
mv() {
    [[ $# == 4 && $1 == -f && $2 == -- && $(tag "$3") == candidate && $4 == "$DEST" ]] || forbidden mv-arguments
    trace install
    [[ $CASE != install ]] || return 23
    builtin command mv "$@"
}
'''
FORBIDDEN = (
    "main", "initialize_runtime", "initialize_runtime_state", "load_configuration", "probe_optional_modules",
    "probe_boot_module", "prepare_geninitrd_grub_policy_override", "stage_geninitrd_grub_policy_override",
    "run_check_workflow", "run_dry_run_workflow", "run_apply_workflow", "update_slackware_system",
    "slackpkg", "sbopkg", "sqg", "flatpak", "readelf", "mkinitrd", "grub-mkconfig", "git", "curl", "wget", "date",
)
GUARDS = "\n".join(f"{name}() {{ forbidden {name}; }}" for name in FORBIDDEN)


def encoded(rows):
    return b"".join(b"".join(str(v).encode() + b"\0" for v in row) + b"\n" for row in rows)


def snapshot(work, excluded):
    result = {}
    for p in work.rglob("*"):
        if p.name in excluded:
            continue
        mode = p.lstat().st_mode
        value = str(p.readlink()) if p.is_symlink() else (p.read_bytes() if stat.S_ISREG(mode) else None)
        result[p.relative_to(work).as_posix()] = (mode, value)
    return result


def invoke(work, name, operation, callback=""):
    for path, data in (("trace", b""), ("head-trace", b""), ("counter", b"0\n")):
        (work / path).write_bytes(data)
    driver = PREFIX + GUARDS + "\nCASE=" + shlex.quote(name) + "\n" + callback + r'''
IFS='|: '
PACKAGE_SNAPSHOT_ERROR='stale error'
PACKAGE_SNAPSHOT_RECORD_COUNT=987
PACKAGE_SNAPSHOT_BEFORE_VALID=7; PACKAGE_SNAPSHOT_BEFORE_COUNT=8; PACKAGE_SNAPSHOT_BEFORE_ERROR=before-stale
PACKAGE_SNAPSHOT_AFTER_VALID=9; PACKAGE_SNAPSHOT_AFTER_COUNT=10; PACKAGE_SNAPSHOT_AFTER_ERROR=after-stale
status=0
''' + operation + r''' || status=$?
printf '%s\0' "$status" "$PACKAGE_SNAPSHOT_RECORD_COUNT" "$PACKAGE_SNAPSHOT_ERROR" "$IFS" \
    "$PACKAGE_SNAPSHOT_BEFORE_VALID" "$PACKAGE_SNAPSHOT_BEFORE_COUNT" "$PACKAGE_SNAPSHOT_BEFORE_ERROR" \
    "$PACKAGE_SNAPSHOT_AFTER_VALID" "$PACKAGE_SNAPSHOT_AFTER_COUNT" "$PACKAGE_SNAPSHOT_AFTER_ERROR"
'''
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "snapshot-boundary-test",
                             str(REFERENCE), str(work)], cwd=work, capture_output=True, timeout=10)
    assert result.returncode == 0 and result.stderr == b"", (name, result.returncode, result.stderr)
    values = result.stdout.split(b"\0")
    assert len(values) == 11 and values[-1] == b"", (name, result.stdout)
    return [v.decode() for v in values[:-1]], (work / "trace").read_bytes(), (work / "head-trace").read_bytes()


def validate_case(work, case):
    name, data, status, count, error = case
    destination = work / "destination snapshot"
    if name == "directory": destination.mkdir()
    elif data is not None: destination.write_bytes(data)
    before = snapshot(work, {"trace", "head-trace", "counter"})
    rows = [("access", "-r", "destination", "false")] if name == "unreadable" else (
        [] if name in ("missing", "directory", "empty") else [("sort-check", "destination")])
    expected = [str(status), str(count), error.format(destination=destination), "|: ",
                "7", "8", "before-stale", "9", "10", "after-stale"]
    for _ in range(2):
        values, trace, heads = invoke(work, name, 'validate_package_snapshot "$DEST"')
        assert values == expected and trace == encoded(rows) and heads == b"", (name, values, trace, expected, rows)
        assert snapshot(work, {"trace", "head-trace", "counter"}) == before, name


def capture_expected(name, work):
    db, destination = work / "database directory", work / "destination snapshot"
    errors = {
        "missing-db": f"package database directory does not exist: {db}",
        "db-file": f"package database directory does not exist: {db}",
        "empty-db": f"package database contains no package records: {db}",
        "invalid-db": "package database contains an invalid package record: invalid-record",
        "duplicate-db": "package database produces a duplicate normalized record: aaa_libraries-15.0-x86_64-19",
        "unreadable-db": f"package database directory is not readable: {db}",
        "unsearchable-db": f"package database directory is not readable: {db}",
        "mktemp-1": f"cannot create a temporary package listing in: {work}",
        "mktemp-2": f"cannot create a temporary normalized snapshot in: {work}",
        "mktemp-3": f"cannot create a temporary validated snapshot in: {work}",
        "enumerate": f"cannot enumerate package database records: {db}",
        "sort": "cannot sort package snapshot records", "validate": "supplied candidate validation failure",
        "install": f"cannot install validated package snapshot: {destination}",
    }
    if name in ("missing-db", "db-file"): return errors[name], [], b""
    if name in ("unreadable-db", "unsearchable-db"):
        return errors[name], [("access", "-r" if name == "unreadable-db" else "-x", "database", "false")], b""
    rows = [("dirname",), ("mktemp", 1)]
    if name == "mktemp-1": return errors[name], rows, b""
    rows += [("mktemp", 2)]
    if name == "mktemp-2": return errors[name], rows + [("rm", "listing")], b""
    rows += [("mktemp", 3)]
    if name == "mktemp-3": return errors[name], rows + [("rm", "listing", "normalized")], b""
    rows += [("find",)]
    if name in ("enumerate", "invalid-db"):
        return errors[name], rows + [("rm", "listing", "normalized", "candidate")], b""
    rows += [("rm", "listing")]
    if name == "empty-db": return errors[name], rows + [("rm", "normalized", "candidate")], b""
    rows += [("sort-capture",)]
    if name == "sort": return errors[name], rows + [("rm", "normalized", "candidate")], b""
    rows += [("rm", "normalized"), ("uniq",)]
    if name == "duplicate-db": return errors[name], rows + [("rm", "candidate")], b"head\n"
    rows += [("supplied-validation",)] if name == "validate" else [("sort-check", "candidate")]
    if name == "validate": return errors[name], rows + [("rm", "candidate")], b"head\n"
    rows += [("install",)]
    if name == "install": rows += [("rm", "candidate")]
    return errors.get(name, ""), rows, b"head\n"


def capture_case(work, name, previous):
    db = work / "database directory"
    if name == "db-file": db.write_bytes(b"not a directory\n")
    elif name != "missing-db":
        actual = work / "database target" if name == "compat-link" else db
        actual.mkdir()
        if name == "compat-link": db.symlink_to(actual.name)
        records = () if name == "empty-db" else RECORDS
        if name == "duplicate-db": records = ("aaa_libraries-15.0-x86_64-19", "aaa_libraries-15.0-x86_64-19.txz")
        for record in records: (actual / record).write_bytes(b"private package record\n")
        if name == "invalid-db": (actual / "invalid-record").write_bytes(b"invalid\n")
        if name == "internal-link":
            target = work / "external-record-1.0-x86_64-1"
            target.write_bytes(b"owned private target\n")
            (actual / "linked-1.0-x86_64-1").symlink_to(target)
        if name == "nested":
            (actual / "nested").mkdir()
            (actual / "nested/ignored-1.0-x86_64-1").write_bytes(b"nested private record\n")
    excluded = {"destination snapshot", "trace", "head-trace", "counter"}
    before = snapshot(work, excluded)
    error, rows, heads = capture_expected(name, work)
    callback = r'''
validate_package_snapshot() {
    [[ $# == 1 && $(tag "$1") == candidate ]] || forbidden validation-arguments
    trace supplied-validation
    PACKAGE_SNAPSHOT_ERROR='supplied candidate validation failure'
    PACKAGE_SNAPSHOT_RECORD_COUNT=0
    return 23
}
''' if name == "validate" else ""
    destination = work / "destination snapshot"
    for _ in range(2):
        if previous: destination.write_bytes(OLD)
        else: destination.unlink(missing_ok=True)
        values, trace, actual_heads = invoke(work, name, 'capture_validated_package_snapshot "$DEST"', callback)
        expected = [str(int(bool(error))), "0" if error else "3", error, "|: ",
                    "7", "8", "before-stale", "9", "10", "after-stale"]
        assert values == expected and trace == encoded(rows) and actual_heads == heads, (name, values, trace, expected, rows)
        expected_bytes = OLD if error and previous else (None if error else NORMALIZED)
        assert (destination.read_bytes() if destination.exists() else None) == expected_bytes, (name, previous)
        assert snapshot(work, excluded) == before, name


def wrapper_case(work, kind, outcome, previous):
    before_path, after_path = work / "before snapshot", work / "after snapshot"
    callback = r'''
capture_validated_package_snapshot() {
    [[ $# == 1 ]] || forbidden capture-count
    if [[ $KIND == before ]]; then
        [[ $1 == "$BEFORE_PKGS" && ! -e $BEFORE_PKGS && ! -e $AFTER_PKGS ]] || forbidden before-sequencing
    else
        [[ $1 == "$AFTER_PKGS" && ! -e $AFTER_PKGS ]] || forbidden after-sequencing
    fi
    trace supplied-capture "$(tag "$1")"
    PACKAGE_SNAPSHOT_ERROR=
    PACKAGE_SNAPSHOT_RECORD_COUNT=0
    if [[ $CASE == capture ]]; then PACKAGE_SNAPSHOT_ERROR='supplied capture failure'; return 23; fi
    printf '%s\n' 'aaa_libraries-15.0-x86_64-19' 'gtk+3-3.24.49-x86_64-1' 'zlib-1.3.1-x86_64-1' > "$1"
    PACKAGE_SNAPSHOT_RECORD_COUNT=3
}
'''
    rows = [("rm", "before", "after") if kind == "before" else ("rm", "after")]
    if outcome != "remove": rows += [("supplied-capture", kind)]
    error = ("cannot remove stale package snapshots" if kind == "before" else
             "cannot remove stale post-update package snapshot") if outcome == "remove" else (
                 "supplied capture failure" if outcome == "capture" else "")
    fields = ["7", "8", "before-stale", "9", "10", "after-stale"]
    offset = 0 if kind == "before" else 3
    fields[offset:offset + 3] = ["0" if error else "1", "0" if error else "3", error]
    common_count, common_error = ("987", "stale error") if outcome == "remove" else (
        ("0", "supplied capture failure") if outcome == "capture" else ("3", ""))
    for _ in range(2):
        for p in (before_path, after_path):
            if previous: p.write_bytes(OLD)
            else: p.unlink(missing_ok=True)
        values, trace, heads = invoke(work, outcome, "capture_package_snapshot_" + kind,
                                     "KIND=" + kind + "\n" + callback)
        expected = [str(int(bool(error))), common_count, common_error, "|: ", *fields]
        assert values == expected and trace == encoded(rows) and heads == b"", (kind, outcome, values, expected, trace)
        for p in (before_path, after_path):
            target = p == (before_path if kind == "before" else after_path)
            removed = outcome != "remove" and (kind == "before" or p == after_path)
            expected_bytes = NORMALIZED if target and not error else (
                None if removed or not previous else OLD)
            assert (p.read_bytes() if p.exists() else None) == expected_bytes, (kind, outcome, p)
        assert {p.name for p in work.iterdir()} <= {"before snapshot", "after snapshot", "trace", "head-trace", "counter"}


def main():
    count = 0
    with tempfile.TemporaryDirectory(prefix="slack-update-snapshot-boundaries-") as directory:
        root = Path(directory)
        for case in VALIDATORS:
            work = root / str(count); work.mkdir(); validate_case(work, case); count += 1
        for case in itertools.product(CAPTURES, (False, True)):
            work = root / str(count); work.mkdir(); capture_case(work, *case); count += 1
        for case in itertools.product(("before", "after"), ("remove", "capture", "success"), (False, True)):
            work = root / str(count); work.mkdir(); wrapper_case(work, *case); count += 1
    print(f"Package snapshot boundaries: {count} scenarios, {2 * count} entry calls, 0 failures")


if __name__ == "__main__":
    main()
