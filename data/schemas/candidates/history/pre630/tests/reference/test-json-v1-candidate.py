#!/usr/bin/env python3
"""Validate prospective v1 data; never run an update or emit runtime v1."""

import copy
import importlib.util
import json
from pathlib import Path
import re
import sys
import tempfile

sys.dont_write_bytecode = True
try:
    from jsonschema import Draft202012Validator, ValidationError
except ImportError:
    raise SystemExit('Test dependency missing: python-jsonschema (4.x); see docs/reference/json-v1-candidate.md')

from json_result_test_support import decode

ROOT = Path(__file__).resolve().parents[2]
SCHEMAS = ROOT / 'data/schemas/candidates'
FIXTURES = ROOT / 'tests/fixtures/reference/json-v1-candidate'
RESULT = json.loads((SCHEMAS / 'result-v1.schema.json').read_text())
EVENT = json.loads((SCHEMAS / 'event-v1.schema.json').read_text())


def local_references(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if key in ('$ref', '$dynamicRef') and not child.startswith('#'):
                raise ValueError('candidate tests permit internal references only')
            local_references(child)
    elif isinstance(value, list):
        for child in value:
            local_references(child)


local_references(RESULT)
local_references(EVENT)
Draft202012Validator.check_schema(RESULT)
Draft202012Validator.check_schema(EVENT)
RESULT_VALIDATOR = Draft202012Validator(RESULT)
EVENT_VALIDATOR = Draft202012Validator(EVENT)


def project(value):
    value = copy.deepcopy(value)
    value.update(schema_version=1, schema_status='stable')
    return value


def load_expectations(filename):
    spec = importlib.util.spec_from_file_location(filename.replace('-', '_'), ROOT / 'tests/reference' / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def result_fixture(operation):
    return decode((FIXTURES / (operation + '.json')).read_bytes())


def completed_stream(raw):
    # This is the declared complete-stream profile, separate from record shape.
    if not raw.endswith(b'\n'):
        raise ValueError('unterminated NDJSON stream')
    lines = raw.split(b'\n')[:-1]
    if not lines or any(not line.strip() for line in lines):
        raise ValueError('empty NDJSON frame')
    records = [decode(line) for line in lines]
    for record in records:
        EVENT_VALIDATOR.validate(record)
    if records[0]['type'] != 'operation_started':
        raise ValueError('missing initial event')
    if records[-1]['type'] != 'operation_completed':
        raise ValueError('missing final event')
    if sum(row['type'] == 'operation_completed' for row in records) != 1:
        raise ValueError('multiple final events')
    first = records[0]['sequence']
    operation = records[0]['operation']
    for index, row in enumerate(records):
        if row['sequence'] != first + index or row['operation'] != operation:
            raise ValueError('sequence or operation drift')
    return records


def changed(document, path, value):
    result = copy.deepcopy(document)
    current = result
    for key in path[:-1]:
        current = current[key]
    current[path[-1]] = value
    return result


def require_invalid(validator, document):
    if validator.is_valid(document):
        raise AssertionError('negative control unexpectedly accepted')


def field_inventory():
    source = (ROOT / 'tools/reference/slack-update-reference.sh').read_text()
    inventory = json.loads((SCHEMAS / 'source-field-inventory.json').read_text())
    groups = {'print_check_json_module': 'checkModules',
              'print_dry_run_json_modules': 'dryRunModules',
              'print_apply_json_modules': 'applyModules'}
    for name, row in inventory['functions'].items():
        begin = source.index(name + '() {')
        end = source.index('\n}\n', begin)
        tokens = re.findall(r'''printf ['"]\s*"([a-z_]+)"\s*:''', source[begin:end])
        if tokens != row['literal_printed_fields']:
            raise AssertionError('serializer field inventory drift: ' + name)
        if name in ('emit_event', 'print_json_result'):
            schema = EVENT if name == 'emit_event' else RESULT
            if set(tokens) != set(schema['properties']):
                raise AssertionError('root field mismatch: ' + name)
        else:
            schema = RESULT['$defs'][groups[name]]['properties']
            found = {}
            current = None
            for token in tokens:
                if token in schema:
                    current = token
                    found[current] = []
                elif current is None:
                    raise AssertionError('unclassified printed field')
                else:
                    found[current].append(token)
            if set(found) != set(schema):
                raise AssertionError('module set mismatch')
            for module, names in found.items():
                if set(names) != set(schema[module]['properties']):
                    raise AssertionError('module field mismatch: ' + module)


def main():
    positive = 0
    negative = 0
    field_inventory()
    for operation in ['check', 'dry-run', 'apply']:
        RESULT_VALIDATOR.validate(result_fixture(operation))
        positive += 1

    # These expectations are authored independently of the shell serializer.
    check = load_expectations('test-check-json-result.py')
    for case in check.CASES:
        RESULT_VALIDATOR.validate(project(check.expected(case)))
        positive += 1
    for filename in ['test-dry-run-json-result.py', 'test-apply-json-result.py']:
        module = load_expectations(filename)
        for name in module.SCENARIOS:
            with tempfile.TemporaryDirectory(prefix='slack-update-v1-data-') as directory:
                supplied = module.scenario(name, Path(directory))
                wanted = supplied[-1]
                RESULT_VALIDATOR.validate(project(wanted))
            positive += 1

    check_value = result_fixture('check')
    dry = result_fixture('dry-run')
    apply = result_fixture('apply')
    cases = [
        changed(check_value, ['schema_version'], 0),
        changed(check_value, ['schema_status'], 'provisional'),
        changed(check_value, ['success'], 1),
        changed(check_value, ['exit_code'], True),
        changed(check_value, ['exit_code'], 1.5),
        changed(check_value, ['exit_code'], 100),
        changed(check_value, ['exit_code_meaning'], 'translated meaning'),
        changed(check_value, ['warnings'], None),
        changed(check_value, ['modules', 'slackware', 'updates_available'], False),
        changed(check_value, ['modules', 'slackware', 'check_exit_code'], None),
        changed(check_value, ['modules', 'slackware', 'state'], 'failed'),
        changed(check_value, ['operation'], 'apply'),
        changed(apply, ['modules', 'sbo', 'build_exit_code'], -1),
        changed(apply, ['modules', 'sbo', 'core_queue_count'], -1),
        changed(apply, ['modules', 'elf', 'executes_inspected_objects'], True),
        changed(apply, ['modules', 'boot', 'grub_atomic_replacement'], False),
        changed(apply, ['reboot'], 'unsafe'),
        changed(apply, ['partial'], True),
        changed(dry, ['modules', 'sbo', 'build_options'], [{'target': 'x', 'options': 'MODE=yes', 'extra': 1}]),
        changed(dry, ['modules', 'elf', 'architecture_match_fields'], ['machine', 'class', 'data'])
    ]
    # Check every root field's requiredness independently of its value.
    for key in check_value:
        mutation = copy.deepcopy(check_value)
        del mutation[key]
        cases.append(mutation)
    for value in [check_value, dry, apply]:
        mutation = copy.deepcopy(value)
        mutation['unexpected'] = 1
        cases.append(mutation)
        for module in value['modules']:
            mutation = copy.deepcopy(value)
            mutation['modules'][module]['unexpected'] = 1
            cases.append(mutation)
    for value in cases:
        require_invalid(RESULT_VALIDATOR, value)
        negative += 1

    # Standard JSON Schema integers are mathematical integers, including 1.0.
    value = changed(check_value, ['schema_version'], 1.0)
    RESULT_VALIDATOR.validate(value)
    positive += 1
    # Null not-run and integer-zero status must both stay representable.
    for status in [None, 0, 20, 100, 255]:
        RESULT_VALIDATOR.validate(changed(apply, ['modules', 'sbo', 'build_exit_code'], status))
        positive += 1
    value = changed(dry, ['modules', 'sbo', 'current_queue_targets'], ['beta', 'alpha', 'alpha'])
    RESULT_VALIDATOR.validate(value)
    positive += 1

    raw = (FIXTURES / 'events.ndjson').read_bytes()
    records = completed_stream(raw)
    completed_stream(raw.replace(b'\n', b'\r\n'))
    positive += 2
    for code in [-1, 0, 20, 100, 126, None]:
        EVENT_VALIDATOR.validate(changed(records[3], ['exit_code'], code))
        positive += 1
    for code in range(9):
        # Shape coverage only; this is not a claim that startup emits a lifecycle.
        value = changed(records[-1], ['exit_code'], code)
        value['state'] = {0: 'success', 1: 'failed', 2: 'warning', 3: 'failed',
                          4: 'success', 5: 'success', 6: 'failed', 7: 'failed', 8: 'failed'}[code]
        EVENT_VALIDATOR.validate(value)
        positive += 1
    event_cases = [changed(records[0], ['sequence'], True),
                   changed(records[0], ['sequence'], 0),
                   changed(records[0], ['type'], 'unknown_event'),
                   changed(records[-1], ['exit_code'], 100),
                   changed(records[-1], ['exit_code'], None),
                   changed(records[-1], ['module'], 'slackware')]
    for value in event_cases:
        require_invalid(EVENT_VALIDATOR, value)
        negative += 1
    for bad in [b'', raw[:-1], b'\n' + raw,
                raw.replace(b'"sequence": 2', b'"sequence": 1'),
                raw + raw.splitlines(keepends=True)[-1],
                b'\n'.join(raw.splitlines()[::-1]) + b'\n']:
        try:
            completed_stream(bad)
        except (ValueError, ValidationError):
            pass
        else:
            raise AssertionError('invalid completed stream accepted')
        negative += 1
    for bad in [b'{"x":1,"x":2}', b'{"x":NaN}', b'{"x":Infinity}', b'{} {}']:
        try:
            decode(bad)
        except ValueError:
            pass
        else:
            raise AssertionError('strict JSON framing control accepted')
        negative += 1
    print(f'JSON v1 candidate tests: {positive} positive cases, {negative} negative controls, 0 failures')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
