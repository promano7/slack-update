#!/usr/bin/env python3
"""Exercise the reference argument parser without calling main or workflows."""

from itertools import permutations, product
from pathlib import Path
import subprocess


ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
DRIVER = r'''
source "$1"
shift
# Deliberately dirty all parser globals before every invocation.
SHOW_HELP=91
JSON_OUTPUT=92
EVENTS_OUTPUT=93
OPERATION=stale
OPERATION_EXPLICIT=94
parse_arguments "$@"
status=$?
printf '%s\0' "$SHOW_HELP" "$JSON_OUTPUT" "$EVENTS_OUTPUT" "$OPERATION" "$OPERATION_EXPLICIT"
exit "$status"
'''
SEQUENCE_DRIVER = r'''
source "$1"
record() {
    parse_arguments "$@"
    status=$?
    printf '%s\0' "$status" "$SHOW_HELP" "$JSON_OUTPUT" "$EVENTS_OUTPUT" "$OPERATION" "$OPERATION_EXPLICIT"
}
record --check --json --help
record
record --dry-run --events
record --unknown
record --apply
record --help --json
record --
'''


def invoke(driver, arguments=()):
    return subprocess.run(["bash", "--noprofile", "--norc", "-c", driver,
                           "cli-arguments-test", str(REFERENCE), *arguments],
                          cwd=ROOT, capture_output=True, timeout=10)


def framed(values):
    return b"".join(str(value).encode("utf-8") + b"\0" for value in values)


def check_success(arguments, state):
    result = invoke(DRIVER, arguments)
    assert result.returncode == 0, (arguments, result.returncode, result.stderr)
    assert result.stderr == b"", (arguments, result.stderr)
    assert result.stdout == framed(state), (arguments, result.stdout, state)


def check_failure(arguments, diagnostic):
    result = invoke(DRIVER, arguments)
    assert result.returncode == 1, (arguments, result.returncode)
    assert result.stderr == (diagnostic + "\n").encode("utf-8"), (arguments, result.stderr)
    # State on a failed parse is not a public contract; only framing/no output
    # pollution is checked. Every subsequent parse must reset the globals.
    fields = result.stdout.split(b"\0")
    assert len(fields) == 6 and fields[-1] == b"", (arguments, result.stdout)


def run_cases():
    count = 0
    # Authored defaults include legacy apply, which is never dispatched here.
    successes = [
        ([], (0, 0, 0, "apply", 0)),
        (["--"], (0, 0, 0, "apply", 0)),
        (["--json"], (0, 1, 0, "apply", 0)),
        (["--events"], (0, 0, 1, "apply", 0)),
        (["-h"], (1, 0, 0, "apply", 0)),
        (["--help"], (1, 0, 0, "apply", 0)),
        (["--help", "-h", "--help"], (1, 0, 0, "apply", 0)),
        (["--json", "--json"], (0, 1, 0, "apply", 0)),
        (["--events", "--events"], (0, 0, 1, "apply", 0)),
        (["--help", "--"], (1, 0, 0, "apply", 0)),
    ]
    for operation in ("check", "apply", "dry-run"):
        successes.append((["--" + operation], (0, 0, 0, operation, 1)))
        successes.append((["--" + operation, "--"], (0, 0, 0, operation, 1)))
        for output, json_flag, events_flag in (("--json", 1, 0), ("--events", 0, 1)):
            for order in permutations(("--" + operation, output)):
                successes.append((list(order), (0, json_flag, events_flag, operation, 1)))
            for help_option in ("--help", "-h"):
                for order in permutations(("--" + operation, output, help_option)):
                    successes.append((list(order), (1, json_flag, events_flag, operation, 1)))
    for arguments, state in successes:
        check_success(arguments, state)
        count += 1

    failures = []
    for first, second in product(("--check", "--apply", "--dry-run"), repeat=2):
        failures.append(([first, second], "Error: only one operation may be specified"))
    for order in (("--json", "--events"), ("--events", "--json")):
        failures.append((list(order), "Error: --json and --events are mutually exclusive"))
        failures.append((["--help", *order], "Error: --json and --events are mutually exclusive"))
    for option in ("--unknown", "-x", "--check=true", "--config", "--JSON"):
        failures.append(([option], "Error: unknown option: " + option))
        failures.append((["--help", option], "Error: unknown option: " + option))
    for argument in ("apply", "", "two words", "-", "ñandú", "line\nbreak"):
        diagnostic = ("Error: unknown option: " if argument == "-" else
                      "Error: unexpected argument: ") + argument
        failures.append(([argument], diagnostic))
    for argument in ("extra", "--help", "--check", "--"):
        failures.append((["--", argument], "Error: unexpected argument: " + argument))
    failures.extend([
        (["--help", "extra"], "Error: unexpected argument: extra"),
        (["--check", "--help", "--apply"], "Error: only one operation may be specified"),
        (["--unknown", "extra"], "Error: unknown option: --unknown"),
        (["extra", "--unknown"], "Error: unexpected argument: extra"),
    ])
    for arguments, diagnostic in failures:
        check_failure(arguments, diagnostic)
        count += 1

    result = invoke(SEQUENCE_DRIVER)
    expected = [
        (0, 1, 1, 0, "check", 1),
        (0, 0, 0, 0, "apply", 0),
        (0, 0, 0, 1, "dry-run", 1),
        (1, 0, 0, 0, "apply", 0),
        (0, 0, 0, 0, "apply", 1),
        (0, 1, 1, 0, "apply", 0),
        (0, 0, 0, 0, "apply", 0),
    ]
    assert result.returncode == 0, result.returncode
    assert result.stdout == b"".join(framed(state) for state in expected), result.stdout
    assert result.stderr == b"Error: unknown option: --unknown\n", result.stderr
    return count + 1


def main():
    count = run_cases()
    print(f"CLI argument parser: {count} scenarios, 0 failures")


if __name__ == "__main__":
    main()
