#!/usr/bin/env python3
"""Compare real supplied-state v0 serializers with prospective v1, without workflows."""

import copy
import importlib.util
import json
from pathlib import Path
import sys

sys.dont_write_bytecode = True
from json_result_test_support import compare

ROOT = Path(__file__).resolve().parents[2]


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


policy = load('candidate_policy', 'tools/reference/json_v1_candidate.py')
validator = policy.CandidateValidator()


def rejected(action):
    try:
        action()
    except ValueError:
        return
    raise AssertionError('negative control was accepted')


def project(value):
    result = copy.deepcopy(value)
    rows = result if isinstance(result, list) else [result]
    for row in rows:
        row.update(schema_version=1, schema_status='stable')
    return result


def frames(rows):
    return b''.join(json.dumps(row, ensure_ascii=False).encode() + b'\n' for row in rows)


def observe(module, invoke, family, *, offset=False):
    original = module.compare
    captured = []

    def checked(actual, wanted):
        # Preserve the complete independent original oracle before adding checks.
        original(actual, wanted)
        captured.append(copy.deepcopy(actual))

    module.compare = checked
    try:
        invoke()
    finally:
        module.compare = original
    assert len(captured) == 1, 'expected exactly one original serializer comparison'
    actual = captured[0]
    original_snapshot = copy.deepcopy(actual)
    rows = actual if isinstance(actual, list) else [actual]
    for row in rows:
        assert type(row['schema_version']) is int and row['schema_version'] == 0
        assert row['schema_status'] == 'provisional'
        rejected(lambda row=row: validator.record(row, family))
    prospective = project(actual)
    if family == 'result':
        validator.record(prospective, 'result')
        # Metadata migration must not turn false into null or change any payload.
        stripped_actual = {k: v for k, v in actual.items() if k not in ('schema_version', 'schema_status')}
        stripped_projected = {k: v for k, v in prospective.items() if k not in ('schema_version', 'schema_status')}
        compare(stripped_projected, stripped_actual)
        for field, bad in (('schema_version', 0), ('schema_status', 'provisional')):
            mixed = copy.deepcopy(prospective)
            mixed[field] = bad
            rejected(lambda mixed=mixed: validator.record(mixed, 'result'))
    else:
        validator.stream(frames(prospective), fragment=offset)
        if offset:
            rejected(lambda: validator.stream(frames(prospective)))
        for index, row in enumerate(prospective):
            validator.record(row, 'event')
            compare({k: v for k, v in row.items() if k not in ('schema_version', 'schema_status')},
                    {k: v for k, v in actual[index].items() if k not in ('schema_version', 'schema_status')})
        mixed = copy.deepcopy(prospective)
        mixed[1].update(schema_version=0, schema_status='provisional')
        rejected(lambda: validator.stream(frames(mixed), fragment=offset))
        rejected(lambda: validator.stream(frames(prospective[:-1]), fragment=offset))
    compare(actual, original_snapshot)
    return len(rows)


def main():
    results, streams, events = 0, 0, 0
    for name in ('check', 'dry-run', 'apply'):
        module = load('compat_' + name.replace('-', '_'), 'tests/reference/test-' + name + '-json-result.py')
        cases = module.CASES if name == 'check' else module.SCENARIOS
        for case in cases:
            observe(module, lambda case=case: module.run_case(case), 'result')
            results += 1
    module = load('compat_events', 'tests/reference/test-event-ndjson.py')
    for code in range(9):
        events += observe(module, lambda code=code: module.lifecycle(code), 'event', offset=code == 8)
        streams += 1
    assert (results, streams) == (48, 9)
    print(f'JSON v1 serializer compatibility: {results} real supplied v0 results, '
          f'{streams} helper lifecycles ({events} events), prospective copies accepted; '
          'v0/mixed/incomplete controls rejected; 0 runtime v1 operations')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
