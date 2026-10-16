#!/usr/bin/env python3
"""Exercise supplied progress events, never a reference operation workflow."""

import copy
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
from json_result_test_support import compare, decode

REFERENCE = Path(__file__).resolve().parents[2] / "tools/reference/slack-update-reference.sh"
STAMP = "2000-01-01T00:00:00Z"
DESCRIPTIONS = ["success; no reboot required", "general failure", "partial update or verification failure",
                "critical boot preparation failure; do not reboot", "success; reboot recommended",
                "success; reboot required", "another instance is already running",
                "invalid configuration or command-line arguments", "required privilege was denied or unavailable"]
FLAGS = [(1, 0, 1, "success"), (0, 0, 1, "failed"), (0, 1, 1, "warning"), (0, 1, 0, "failed"),
         (1, 0, 1, "success"), (1, 0, 1, "success"), (0, 0, 1, "failed"), (0, 0, 1, "failed"), (0, 0, 1, "failed")]
OPERATIONS = ["check", "check", "apply", "apply", "apply", "apply", "check", "dry-run", "apply"]
RAW_CODES = [100, 42, 20, -1, 0, 0, 6, 7, 126]
PRELUDE = 'source "$1"\ndate() { printf "%s\\n" 2000-01-01T00:00:00Z; }\n'


def record(sequence, operation, kind, module, action, state, message, code):
    return {"schema_version": 0, "schema_status": "provisional", "sequence": sequence, "timestamp": STAMP,
            "operation": operation, "type": kind, "module": module, "action": action,
            "state": state, "message": message, "exit_code": code}


def stream(raw):
    if not raw.endswith(b"\n"):
        raise AssertionError("NDJSON stream must end in a newline")
    lines = raw.split(b"\n")[:-1]
    if not lines or any(not line for line in lines):
        raise AssertionError("empty NDJSON record")
    return [decode(line) for line in lines]


def run(driver, *arguments, stderr=b""):
    environment = os.environ.copy()
    environment.pop("BASH_ENV", None)
    environment.pop("ENV", None)
    environment["LC_ALL"] = "C"
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", PRELUDE + driver,
                             "event-json-test", str(REFERENCE), *arguments],
                            env=environment, capture_output=True, timeout=15, check=False)
    if result.returncode != 0 or result.stderr != stderr:
        raise AssertionError(f"emitter status={result.returncode}; stderr={result.stderr!r}")
    return result.stdout


def lifecycle(code):
    operation = OPERATIONS[code]
    success, partial, boot_safe, final_state = FLAGS[code]
    seed = 41 if code == 8 else 0
    warnings, errors = [], []
    if code in [4, 5]:
        warnings = ["supplied reboot warning"]
    elif code == 2:
        warnings = ['first\n\x1b"warning"', "second warning", 'first\n\x1b"warning"']
        errors = ["first error", "second\terror"]
    elif code != 0:
        errors = ["supplied failure"]
    rows = [
        ("operation_started", None, None, "running", "Operation started", None),
        ("module_started", "slackware", None, "running", "supplied module", None),
        ("action_started", "slackware", "supplied_action", "running", "supplied action", None),
        ("action_completed", "slackware", "supplied_action", "success" if success else "failed", "supplied completion", RAW_CODES[code]),
        ("module_completed", "slackware", None, "success" if success else "failed", "supplied module completion", RAW_CODES[code]),
    ]
    rows.extend(("warning", None, None, "warning", message, None) for message in warnings)
    rows.extend(("error", None, None, "failed", message, None) for message in errors)
    rows.append(("operation_completed", None, None, final_state, "Operation completed: " + DESCRIPTIONS[code], code))
    wanted = [record(seed + index, operation, *row) for index, row in enumerate(rows, 1)]
    driver = '\n'.join([
        f'EVENTS_OUTPUT=1 EVENT_SEQUENCE={seed} OPERATION={shlex.quote(operation)}', 'exec 3>&1',
        f'RESULT_SUCCESS={success} RESULT_PARTIAL={partial} RESULT_BOOT_SAFE={boot_safe}',
        'RESULT_WARNINGS=(' + ' '.join(shlex.quote(item) for item in warnings) + ')',
        'RESULT_ERRORS=(' + ' '.join(shlex.quote(item) for item in errors) + ')',
        'emit_operation_started_event', 'emit_module_started_event slackware "supplied module"',
        'emit_action_started_event slackware supplied_action "supplied action"',
        f'emit_action_completed_event slackware supplied_action {"success" if success else "failed"} "supplied completion" {RAW_CODES[code]}',
        f'emit_module_completed_event slackware {"success" if success else "failed"} "supplied module completion" {RAW_CODES[code]}',
        f'emit_final_events {code}', f'test "$EVENT_SEQUENCE" -eq {seed + len(rows)}',
    ])
    compare(stream(run(driver)), wanted)
    return wanted


def empty_fields(code):
    argument = "''" if code is None else "0"
    actual = stream(run(f"EVENTS_OUTPUT=1 EVENT_SEQUENCE=0 OPERATION=check\nexec 3>&1\nemit_event supplied '' '' '' '' {argument}"))
    compare(actual, [record(1, "check", "supplied", None, None, None, "", code)])


def disabled_unset():
    driver = r'''
EVENTS_OUTPUT=0
unset EVENT_SEQUENCE OPERATION
exec 3>&-
date() { printf 'unexpected clock call\n' >&2; return 99; }
emit_event supplied '' '' '' '' '' || exit 91
test "${EVENT_SEQUENCE+x}" != x || exit 92
'''
    compare(run(driver), b"")


def disabled_wrappers():
    driver = r'''
EVENTS_OUTPUT=0 EVENT_SEQUENCE=17 OPERATION=check
RESULT_SUCCESS=1 RESULT_PARTIAL=0 RESULT_BOOT_SAFE=1
RESULT_WARNINGS=('supplied warning') RESULT_ERRORS=('supplied error')
exec 3>&-
date() { printf 'unexpected clock call\n' >&2; return 99; }
emit_operation_started_event
emit_module_started_event core supplied
emit_action_started_event core supplied supplied
emit_action_completed_event core supplied success supplied 100
emit_module_completed_event core success supplied 100
emit_final_events 0
test "$EVENT_SEQUENCE" -eq 17
'''
    compare(run(driver), b"")


def descriptor_routing():
    with tempfile.TemporaryDirectory(prefix="slack-update-event-json-") as directory:
        path = Path(directory) / "events"
        driver = r'''
EVENTS_OUTPUT=1 EVENT_SEQUENCE=0 OPERATION=check
exec 3>"$2"
printf 'human progress\n'
printf 'human diagnostic\n' >&2
emit_operation_started_event
'''
        compare(run(driver, str(path), stderr=b"human diagnostic\n"), b"human progress\n")
        compare(stream(path.read_bytes()), [record(1, "check", "operation_started", None, None, "running", "Operation started", None)])


def negative_controls(wanted):
    mutations = []
    item = copy.deepcopy(wanted)
    item.reverse()
    mutations.append(item)
    item = copy.deepcopy(wanted)
    item[1]["sequence"] = item[0]["sequence"]
    mutations.append(item)
    for key, value in [("exit_code", False), ("exit_code", "0"), ("state", "failed"), ("timestamp", "different")]:
        item = copy.deepcopy(wanted)
        item[-1][key] = value
        mutations.append(item)
    item = copy.deepcopy(wanted)
    del item[-1]["module"]
    mutations.append(item)
    for index, item in enumerate(mutations):
        try:
            compare(item, wanted)
        except AssertionError:
            continue
        raise AssertionError(f"negative control {index} was accepted")
    try:
        stream(b'{}\n\n')
    except AssertionError:
        return len(mutations) + 1
    raise AssertionError("blank NDJSON frame was accepted")


def main():
    failures, controls = 0, 0
    baseline = None
    cases = [(f"stable code {code}", lambda code=code: lifecycle(code)) for code in range(9)]
    cases.extend([("absent optional fields", lambda: empty_fields(None)), ("explicit zero", lambda: empty_fields(0)),
                  ("disabled without descriptor or state", disabled_unset), ("disabled wrappers", disabled_wrappers),
                  ("descriptor routing", descriptor_routing)])
    for label, operation in cases:
        try:
            value = operation()
            if label == "stable code 0":
                baseline = value
        except (AssertionError, ValueError, OSError, subprocess.SubprocessError) as error:
            failures += 1
            print(f"FAIL: {label}: {error}", file=sys.stderr)
    try:
        if baseline is None:
            raise AssertionError("baseline scenario did not pass")
        controls = negative_controls(baseline)
    except (AssertionError, ValueError) as error:
        failures += 1
        print(f"FAIL: negative controls: {error}", file=sys.stderr)
    print(f"Event NDJSON tests: {len(cases)} scenarios, {controls} negative controls, {failures} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
