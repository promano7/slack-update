#!/usr/bin/env python3
"""Check prospective v1 data offline; never run or transform a reference operation."""

import argparse
from decimal import Context, Decimal, Inexact, InvalidOperation, MAX_EMAX, MIN_EMIN
import json
import math
from pathlib import Path
import sys

sys.dont_write_bytecode = True
try:
    from jsonschema import Draft202012Validator, ValidationError, validators
except ImportError:
    raise SystemExit('Test dependency missing: python-jsonschema 4.x')

ROOT = Path(__file__).resolve().parents[2]


def unique_object(pairs):
    value = {}
    for key, item in pairs:
        if key in value:
            raise ValueError('duplicate JSON key: ' + key)
        value[key] = item
    return value


def reject_constant(value):
    raise ValueError('non-JSON constant: ' + value)


def decimal_number(token):
    try:
        return Decimal(token)
    except InvalidOperation as error:
        raise ValueError('decimal number is outside the decoder representation') from error


def decode(raw):
    return json.loads(raw.decode('utf-8'), object_pairs_hook=unique_object,
                      parse_constant=reject_constant, parse_float=decimal_number)


def exact_integer(checker, value):
    if isinstance(value, bool):
        return False
    if isinstance(value, int):
        return True
    if isinstance(value, Decimal):
        return value.is_finite() and value == value.to_integral_value()
    return isinstance(value, float) and math.isfinite(value) and value.is_integer()


def exact_number(checker, value):
    if isinstance(value, bool):
        return False
    if isinstance(value, Decimal):
        return value.is_finite()
    return isinstance(value, int) or isinstance(value, float) and math.isfinite(value)


ExactDraft202012Validator = validators.extend(
    Draft202012Validator,
    type_checker=Draft202012Validator.TYPE_CHECKER.redefine_many(
        {'integer': exact_integer, 'number': exact_number}),
)


def sequence_offset_matches(value, first, offset):
    # Subtract under a private context. Trapping inexact subtraction prevents a
    # rounded difference from being mistaken for the small expected offset.
    # A valid difference equal to offset fits this coefficient-sized precision,
    # even when the starting integer has a large exponent. No zero padding or
    # conversion of that exponent to a giant Python integer is needed.
    left, right = Decimal(value), Decimal(first)
    precision = max(len(left.as_tuple().digits), len(right.as_tuple().digits),
                    len(str(offset))) + 2
    context = Context(prec=precision, Emax=MAX_EMAX, Emin=MIN_EMIN,
                      traps=[Inexact, InvalidOperation])
    try:
        return context.subtract(left, right) == offset
    except (Inexact, InvalidOperation):
        return False


def internal_references(value):
    if isinstance(value, dict):
        for key, child in value.items():
            if key in ('$ref', '$dynamicRef') and (
                    not isinstance(child, str) or not child.startswith('#')):
                raise ValueError('only internal schema references are supported')
            internal_references(child)
    elif isinstance(value, list):
        for child in value:
            internal_references(child)


class CandidateValidator:
    def __init__(self):
        self.validators = {}
        for family in ('result', 'event'):
            schema = decode((ROOT / 'data/schemas/candidates' /
                             (family + '-v1.schema.json')).read_bytes())
            internal_references(schema)
            Draft202012Validator.check_schema(schema)
            self.validators[family] = ExactDraft202012Validator(schema)

    def record(self, value, family):
        if family not in self.validators:
            raise ValueError('unsupported record family')
        if not isinstance(value, dict):
            raise ValueError('record must be an object')
        version = value.get('schema_version')
        # JSON Schema integers include 1.0; booleans are distinct from numbers.
        if not exact_integer(None, version) or version != 1:
            raise ValueError('unsupported schema version; no conversion or fallback')
        try:
            self.validators[family].validate(value)
        except ValidationError as error:
            path = '.'.join(str(item) for item in error.absolute_path) or '<root>'
            raise ValueError('candidate ' + family + ' violation at ' + path) from error
        return value

    def stream(self, raw, *, fragment=False):
        if not raw.endswith(b'\n'):
            raise ValueError('stream requires final LF')
        lines = raw.split(b'\n')[:-1]
        if not lines or any(not line.strip() for line in lines):
            raise ValueError('empty stream or blank frame')
        records = [self.record(decode(line), 'event') for line in lines]
        if records[0]['type'] != 'operation_started' or records[-1]['type'] != 'operation_completed':
            raise ValueError('stream requires initial start and final completion')
        for kind in ('operation_started', 'operation_completed'):
            if sum(row['type'] == kind for row in records) != 1:
                raise ValueError('stream requires exactly one ' + kind)
        first = records[0]['sequence']
        if not fragment and first != 1:
            raise ValueError('complete stream must start at sequence 1')
        operation = records[0]['operation']
        for index, row in enumerate(records):
            if not sequence_offset_matches(row['sequence'], first, index) or row['operation'] != operation:
                raise ValueError('stream sequence or operation drift')
        return records


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('family', choices=('result', 'event', 'stream', 'fragment'))
    parser.add_argument('input', type=Path, help='Existing supplied data, never an executable')
    args = parser.parse_args()
    validator = CandidateValidator()
    raw = args.input.read_bytes()
    if args.family in ('stream', 'fragment'):
        validator.stream(raw, fragment=args.family == 'fragment')
    else:
        validator.record(decode(raw), args.family)
    print('PASS: prospective v1 ' + args.family + ' data; no runtime/native acceptance')
    return 0


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (ValueError, OSError) as error:
        print('FAIL: ' + str(error), file=sys.stderr)
        raise SystemExit(1)
