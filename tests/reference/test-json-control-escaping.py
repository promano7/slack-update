#!/usr/bin/env python3
"""Exercise sourced JSON emitters with supplied data, without calling main()."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


REFERENCE = Path(__file__).resolve().parents[2] / "tools/reference/slack-update-reference.sh"
CHECKS = 0
FAILURES = 0

# Source only: the reference's main() guard remains false. The selected functions
# below serialize supplied values; no configuration, runtime or workflow is run.
DRIVER = r'''
source "$1"
shift
case "$1" in
    string) shift; json_string "$1" ;;
    array) shift; json_string_array "$@" ;;
    file-array) shift; json_string_array_from_file "$1" ;;
    result)
        OPERATION=check
        RESULT_SUCCESS=1 RESULT_PARTIAL=0 RESULT_BOOT_SAFE=1 RESULT_REBOOT=none
        STARTED_AT=2000-01-01T00:00:00Z FINISHED_AT=2000-01-01T00:00:01Z
        LOG=$2 CONFIG_FILE=$2 CHECK_STATUS=0
        RESULT_WARNINGS=("$2") RESULT_ERRORS=()
        print_json_result 0
        ;;
    event)
        EVENTS_OUTPUT=1 EVENT_SEQUENCE=0 OPERATION=check
        date() { printf '%s\n' 2000-01-01T00:00:00Z; }
        exec 3>&1
        emit_action_completed_event core supplied success "$2" 42
        emit_event operation_completed '' '' success "$2" 0
        ;;
    *) exit 99 ;;
esac
'''


def run(mode, *values):
    environment = os.environ.copy()
    # Prevent startup injection into the non-interactive child shell.
    environment.pop("BASH_ENV", None)
    environment.pop("ENV", None)
    environment["LC_ALL"] = "C"
    result = subprocess.run(
        ["bash", "--noprofile", "--norc", "-c", DRIVER, "json-test", str(REFERENCE), mode, *values],
        capture_output=True, env=environment, timeout=15, check=False,
    )
    if result.returncode != 0 or result.stderr:
        raise AssertionError(f"serializer status={result.returncode}; stderr={result.stderr!r}")
    return result.stdout


def check(label, operation):
    global CHECKS, FAILURES
    CHECKS += 1
    try:
        operation()
    except (AssertionError, ValueError, OSError, subprocess.SubprocessError) as error:
        FAILURES += 1
        print(f"FAIL: {label}: {error}", file=sys.stderr)


def equal(actual, expected):
    if actual != expected:
        raise AssertionError(f"expected {expected!r}, got {actual!r}")


def string_roundtrip(value):
    raw = run("string", value)
    equal(json.loads(raw), value)
    # No literal C0 byte may appear inside the serialized string.
    equal(any(byte < 32 for byte in raw), False)


def result_roundtrip(value):
    actual = json.loads(run("result", value))
    equal(actual["schema_version"], 0)
    equal(actual["schema_status"], "provisional")
    equal(actual["exit_code"], 0)
    equal(actual["success"], True)
    equal(actual["log_path"], value)
    equal(actual["config_path"], value)
    equal(actual["warnings"], [value])


def event_roundtrip(value):
    raw = run("event", value)
    lines = raw.splitlines()
    equal(len(lines), 2)
    records = [json.loads(line) for line in lines]
    equal([item["sequence"] for item in records], [1, 2])
    equal([item["exit_code"] for item in records], [42, 0])
    equal([item["type"] for item in records], ["action_completed", "operation_completed"])
    for item in records:
        equal(item["schema_version"], 0)
        equal(item["schema_status"], "provisional")
        equal(item["message"], value)
        equal(item["timestamp"], "2000-01-01T00:00:00Z")
    equal(records[0]["module"], "core")
    equal(records[0]["action"], "supplied")
    equal(records[1]["module"], None)
    equal(records[1]["action"], None)


def main():
    # Bash strings cannot carry NUL. Invalid UTF-8 byte streams are outside this
    # test; UTF-8 text and every representable U+0001..U+001F are covered.
    values = [
        "", "plain ASCII", 'quote: "', "backslash: \\", "/path/with/slashes",
        r"literal \n \u001b", "\nleading and trailing\n", "Espa\u00f1a \u03bb \U0001f427", "\x7f",
    ]
    values.extend(chr(code) for code in range(1, 32))
    values.append("prefix" + "".join(chr(code) for code in range(1, 32)) + "suffix")
    for index, value in enumerate(values):
        check(f"string roundtrip {index}", lambda value=value: string_roundtrip(value))

    check("empty array", lambda: equal(json.loads(run("array")), []))
    check("mixed array", lambda: equal(json.loads(run("array", *values)), values))
    conventional = {8: r'"\b"', 9: r'"\t"', 10: r'"\n"', 12: r'"\f"', 13: r'"\r"'}
    for code, expected in conventional.items():
        check(f"preserve conventional escape {code}",
              lambda code=code, expected=expected: equal(run("string", chr(code)).decode(), expected))

    with tempfile.TemporaryDirectory(prefix="slack-update-json-test-") as directory:
        path = Path(directory) / "lines"
        check("missing file array", lambda: equal(json.loads(run("file-array", str(path))), []))
        path.write_bytes(b"")
        check("empty file array", lambda: equal(json.loads(run("file-array", str(path))), []))
        lines = ["first\x01", "", "same", "same", "tab\tand\x1bescape", "last\x1f"]
        path.write_text("\n".join(lines), encoding="utf-8")
        check("file array preserves order, duplicates, blank and unterminated lines",
              lambda: equal(json.loads(run("file-array", str(path))), lines))

    for code in range(1, 32):
        value = f"supplied{chr(code)}text"
        check(f"result control {code}", lambda value=value: result_roundtrip(value))
        check(f"NDJSON control {code}", lambda value=value: event_roundtrip(value))

    print(f"JSON control escaping tests: {CHECKS} checks, {FAILURES} failures")
    return 1 if FAILURES else 0


if __name__ == "__main__":
    sys.exit(main())
