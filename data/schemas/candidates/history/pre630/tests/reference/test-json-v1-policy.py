#!/usr/bin/env python3
"""Check candidate policy and supplied v0 projections, never a real operation."""

import copy
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys

sys.dont_write_bytecode = True
from json_result_test_support import compare

ROOT = Path(__file__).resolve().parents[2]
FIXTURES = ROOT / 'tests/fixtures/reference/json-v1-candidate'


def load(name, path):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


policy = load('json_v1_candidate', ROOT / 'tools/reference/json_v1_candidate.py')
validator = policy.CandidateValidator()
POSITIVE = 0
NEGATIVE = 0


def accepts(action):
    global POSITIVE
    action()
    POSITIVE += 1


def rejects(action):
    global NEGATIVE
    try:
        action()
    except ValueError:
        NEGATIVE += 1
        return
    raise AssertionError('invalid candidate data unexpectedly accepted')


def encode(rows):
    return b''.join(json.dumps(row, ensure_ascii=False).encode() + b'\n' for row in rows)


def record_changed(value, **fields):
    result = copy.deepcopy(value)
    result.update(fields)
    return result


def main():
    result = policy.decode((FIXTURES / 'check.json').read_bytes())
    dry = policy.decode((FIXTURES / 'dry-run.json').read_bytes())
    raw = (FIXTURES / 'events.ndjson').read_bytes()
    rows = validator.stream(raw)
    final = rows[-1]

    # Each final code has one allowed label and two independently rejected ones.
    states = {0: 'success', 1: 'failed', 2: 'warning', 3: 'failed', 4: 'success',
              5: 'success', 6: 'failed', 7: 'failed', 8: 'failed'}
    for code, wanted in states.items():
        for state in ('success', 'warning', 'failed'):
            value = record_changed(final, exit_code=code, state=state)
            action = lambda value=value: validator.record(value, 'event')
            (accepts if state == wanted else rejects)(action)

    # Opaque timestamps and open diagnostic labels deliberately have no grammar.
    for stamp in ('', 'not-a-date', '2026-02-30T99:00:00Z', 'time\nwith\tcontrols'):
        value = record_changed(result, started_at=stamp, finished_at=stamp)
        accepts(lambda value=value: validator.record(value, 'result'))
        value = record_changed(rows[0], timestamp=stamp)
        accepts(lambda value=value: validator.record(value, 'event'))
    for label in ('', 'future_label', 'diagnostic\ntext'):
        value = copy.deepcopy(dry)
        value['modules']['flatpak']['activation_state'] = label
        accepts(lambda value=value: validator.record(value, 'result'))
        value = record_changed(rows[3], state=label)
        accepts(lambda value=value: validator.record(value, 'event'))
    value = copy.deepcopy(dry)
    value['modules']['sbo']['current_queue_targets'] = ['beta', 'alpha', 'alpha']
    accepts(lambda: validator.record(value, 'result'))
    assert value['modules']['sbo']['current_queue_targets'] == ['beta', 'alpha', 'alpha']

    # Numeric JSON integers include 1.0; no implicit conversion of other versions.
    accepts(lambda: validator.record(record_changed(result, schema_version=1.0), 'result'))
    for version in (0, 2, True, '1', None):
        rejects(lambda version=version: validator.record(record_changed(result, schema_version=version), 'result'))
    rejects(lambda: validator.record(result, 'event'))
    rejects(lambda: validator.record(final, 'result'))
    rejects(lambda: validator.record(result, 'unknown'))
    for field, value in (('schema_status', 'provisional'), ('started_at', None),
                         ('finished_at', 0), ('exit_code', True)):
        rejects(lambda field=field, value=value: validator.record(record_changed(result, **{field: value}), 'result'))
    value = record_changed(result, unexpected='new producer field')
    rejects(lambda: validator.record(value, 'result'))
    value = copy.deepcopy(dry)
    value['modules']['flatpak']['mode'] = 'future_mode'
    rejects(lambda: validator.record(value, 'result'))

    accepts(lambda: validator.stream(raw))
    accepts(lambda: validator.stream(raw.replace(b'\n', b'\r\n')))
    offset = [record_changed(row, sequence=row['sequence'] + 41) for row in rows]
    accepts(lambda: validator.stream(encode(offset), fragment=True))
    rejects(lambda: validator.stream(encode(offset)))
    duplicate_start = copy.deepcopy(rows)
    duplicate_start.insert(1, copy.deepcopy(rows[0]))
    for index, row in enumerate(duplicate_start, 1):
        row['sequence'] = index
    rejects(lambda: validator.stream(encode(duplicate_start)))
    rejects(lambda: validator.stream(encode(duplicate_start), fragment=True))
    gap = copy.deepcopy(rows)
    gap[1]['sequence'] += 1
    mixed = copy.deepcopy(rows)
    mixed[1]['operation'] = 'dry-run' if rows[0]['operation'] != 'dry-run' else 'apply'
    for bad in (b'', raw[:-1], b'\n' + raw, raw + b'\n', encode(rows[1:]),
                encode(rows[:-1]), encode(gap), encode(mixed),
                raw + encode([final]), b'{} {}\n', b'\xff\n',
                b'{"x":1,"x":2}\n', b'{"x":NaN}\n', b'{"x":Infinity}\n'):
        rejects(lambda bad=bad: validator.stream(bad))
    for bad in (b'', b'{} {}', b'{"x":1,"x":2}', b'{"nested":{"x":1,"x":2}}',
                b'{"x":NaN}', b'{"x":Infinity}', b'\xff'):
        rejects(lambda bad=bad: validator.record(policy.decode(bad), 'result'))
    rejects(lambda: policy.internal_references({'$ref': 'https://invalid.example/schema'}))
    accepts(lambda: policy.internal_references({'$ref': '#/$defs/local'}))

    # Real current serializer, supplied states, independent existing expectations.
    # This is an in-memory prospective projection, never v1 captured operation data.
    check = load('check_json_result', ROOT / 'tests/reference/test-check-json-result.py')
    environment = os.environ.copy()
    environment.pop('BASH_ENV', None)
    environment.pop('ENV', None)
    environment['LC_ALL'] = 'C'
    for case in check.CASES:
        _, status, workflow, diagnostic, *_ = case
        capture = subprocess.run(
            ['bash', '--noprofile', '--norc', '-c', check.DRIVER, 'v1-policy-test',
             str(check.REFERENCE), str(status), str(workflow), diagnostic, check.START,
             check.FINISH, check.LOG_PATH, check.CONFIG_PATH],
            env=environment, capture_output=True, timeout=15, check=False)
        assert capture.returncode == 0 and capture.stderr == b'', (case[0], capture)
        actual = policy.decode(capture.stdout)
        compare(actual, check.expected(case))
        rejects(lambda actual=actual: validator.record(actual, 'result'))
        projected = record_changed(actual, schema_version=1, schema_status='stable')
        accepts(lambda projected=projected: validator.record(projected, 'result'))
        assert actual['schema_version'] == 0 and actual['schema_status'] == 'provisional'

    # The read-only CLI checks supplied files; it cannot create an operation.
    for family, path, status in (('result', FIXTURES / 'check.json', 0),
                                 ('event', FIXTURES / 'check.json', 1),
                                 ('stream', FIXTURES / 'events.ndjson', 0)):
        capture = subprocess.run([sys.executable, str(ROOT / 'tools/reference/json_v1_candidate.py'),
                                  family, str(path)], capture_output=True, timeout=15, check=False)
        assert capture.returncode == status, (family, capture)
        if status == 0:
            assert capture.stderr == b'' and capture.stdout.startswith(b'PASS: prospective v1')
        else:
            assert capture.stdout == b'' and capture.stderr.startswith(b'FAIL:')
    print(f'JSON v1 policy tests: {POSITIVE} positive checks, {NEGATIVE} negative controls, '
          '10 supplied v0 serializer projections, 3 CLI checks, 0 failures')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
