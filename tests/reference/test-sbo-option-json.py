#!/usr/bin/env python3
"""Check supplied SBo option projection at EOF, without package operations."""

import copy
import importlib.util
import os
from pathlib import Path
import shlex
import subprocess
import sys
import tempfile

sys.dont_write_bytecode = True
from json_result_test_support import compare, decode

ROOT = Path(__file__).resolve().parents[2]
REFERENCE = ROOT / "tools/reference/slack-update-reference.sh"
ONE = [{"target": "alpha", "options": "MODE=yes"}]
TWO = ONE + [{"target": "beta", "options": 'CFLAGS="-O2 -g"'}]
CASES = [
    ("missing", None, []), ("empty", "", []), ("blank lines", "\n\n", []),
    ("one LF", "alpha\tMODE=yes\n", ONE), ("one EOF", "alpha\tMODE=yes", ONE),
    ("two LF", 'alpha\tMODE=yes\nbeta\tCFLAGS="-O2 -g"\n', TWO),
    ("two EOF", 'alpha\tMODE=yes\nbeta\tCFLAGS="-O2 -g"', TWO),
    ("leading blank EOF", "\nalpha\tMODE=yes", ONE), ("trailing blank", "alpha\tMODE=yes\n\n", ONE),
    ("quoted EOF", 'alpha\tCFLAGS="-O2 -g"', [{"target": "alpha", "options": 'CFLAGS="-O2 -g"'}]),
    ("backslash EOF", 'alpha\tPATH_HINT="C:\\tool"', [{"target": "alpha", "options": 'PATH_HINT="C:\\tool"'}]),
    ("UTF8 EOF", 'alpha\tLABEL="Espa\u00f1a"', [{"target": "alpha", "options": 'LABEL="Espa\u00f1a"'}]),
]


def run(driver, *arguments, environment=None):
    env = os.environ.copy()
    env.pop("BASH_ENV", None)
    env.pop("ENV", None)
    if environment:
        env.update(environment)
    env["LC_ALL"] = "C"
    result = subprocess.run(["bash", "--noprofile", "--norc", "-c", driver, "option-json-test", str(REFERENCE), *arguments],
                            env=env, capture_output=True, timeout=15, check=False)
    if result.returncode != 0 or result.stderr:
        raise AssertionError(f"serializer status={result.returncode}; stderr={result.stderr!r}")
    return decode(result.stdout)


def file_case(text, wanted):
    with tempfile.TemporaryDirectory(prefix="slack-update-option-json-") as directory:
        path = Path(directory) / "options"
        if text is not None:
            path.write_text(text, encoding="utf-8")
        actual = run('source "$1"; json_sbo_option_records_from_file "$2"', str(path))
        compare(actual, wanted)


def load_case_data(filename, name):
    # Reuse independently authored supplied-state expectations, not reference
    # output. Loading these Python tests does not execute their main() guards.
    specification = importlib.util.spec_from_file_location(name, Path(__file__).with_name(filename))
    module = importlib.util.module_from_spec(specification)
    specification.loader.exec_module(module)
    return module


def full_result(operation):
    with tempfile.TemporaryDirectory(prefix="slack-update-option-result-") as directory:
        if operation == "dry-run":
            module = load_case_data("test-dry-run-json-result.py", "dry_option_case")
            state, wanted = module.scenario("available-with-records", Path(directory))
            driver = module.DRIVER
        else:
            module = load_case_data("test-apply-json-result.py", "apply_option_case")
            state, critical, workflow, wanted = module.scenario("sbo-records", Path(directory))
            driver = '\n'.join(['source "$1"', 'date() { printf "%s\\n" 2000-01-01T00:00:00Z; }',
                                'initialize_runtime_state || exit 99', 'OPERATION=apply',
                                *(key + '=' + shlex.quote(value) for key, value in state.items()),
                                'CRITICAL_UPDATED=(' + ' '.join(shlex.quote(value) for value in critical) + ')',
                                f'determine_stable_exit_code {workflow}', 'print_json_result "$STABLE_EXIT_CODE"'])
        path = Path(state["SBO_OPTION_RECORDS"])
        path.write_bytes(path.read_bytes().rstrip(b"\n"))
        compare(run(driver, environment=state), wanted)


def negative_controls():
    mutations = [[], TWO[:1], list(reversed(TWO))]
    for field, value in [("options", "different"), ("options", False)]:
        item = copy.deepcopy(TWO)
        item[1][field] = value
        mutations.append(item)
    item = copy.deepcopy(TWO)
    del item[1]["target"]
    mutations.append(item)
    mutations.append(copy.deepcopy(TWO) + copy.deepcopy(ONE))
    item = copy.deepcopy(TWO)
    item[1]["extra"] = True
    mutations.append(item)
    for index, item in enumerate(mutations):
        try:
            compare(item, TWO)
        except AssertionError:
            continue
        raise AssertionError(f"negative control {index} was accepted")
    return len(mutations)


def main():
    failures, controls = 0, 0
    cases = [(label, lambda text=text, wanted=wanted: file_case(text, wanted)) for label, text, wanted in CASES]
    cases.extend([("full dry-run result EOF", lambda: full_result("dry-run")),
                  ("full apply result EOF", lambda: full_result("apply"))])
    for label, operation in cases:
        try:
            operation()
        except (AssertionError, ValueError, OSError, subprocess.SubprocessError) as error:
            failures += 1
            print(f"FAIL: {label}: {error}", file=sys.stderr)
    try:
        controls = negative_controls()
    except (AssertionError, ValueError) as error:
        failures += 1
        print(f"FAIL: negative controls: {error}", file=sys.stderr)
    print(f"SBo option JSON tests: {len(cases)} scenarios, {controls} negative controls, {failures} failures")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
