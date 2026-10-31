#!/usr/bin/env python3
"""Exercise exact prospective wire numbers; never run a native operation."""

from decimal import Decimal, Inexact, localcontext
import importlib.util
import json
from pathlib import Path
import random
import sys
import unittest

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    'numeric_candidate', ROOT / 'tools/reference/json_v1_candidate.py')
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)


class NumericExactness(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.validator = policy.CandidateValidator()
        cls.raw = (ROOT / 'tests/fixtures/reference/json-v1-candidate/check.json').read_bytes()

    def result(self, field, original, token):
        before = ('"' + field + '": ' + original).encode()
        after = ('"' + field + '": ' + token).encode()
        self.assertEqual(self.raw.count(before), 1)
        return policy.decode(self.raw.replace(before, after, 1))

    def stream(self, first, second):
        records = []
        for token, kind, code, state in (
                (first, 'operation_started', None, None),
                (second, 'operation_completed', 0, 'success')):
            value = dict(schema_version=1, schema_status='stable', sequence=1,
                         timestamp='', operation='check', type=kind, module=None,
                         action=None, state=state, message='authored numeric test',
                         exit_code=code)
            raw = json.dumps(value).replace('"sequence": 1', '"sequence": ' + token)
            records.append(raw.encode() + b'\n')
        return b''.join(records)

    def test_integral_version_spellings(self):
        for token in ('1', '1.0', '1e0', '10e-1', '0.1e1', '1.000000000000000000'):
            with self.subTest(token=token):
                self.validator.record(self.result('schema_version', '1', token), 'result')

    def test_versions_are_not_rounded_or_coerced(self):
        for token in ('1.0000000000000001', '0.99999999999999999', '1e-400',
                      '-1e-400', '1e400', '0', '2', 'true', 'false', 'null', '"1"'):
            with self.subTest(token=token), self.assertRaises(ValueError):
                self.validator.record(self.result('schema_version', '1', token), 'result')

    def test_fractional_raw_codes_are_rejected(self):
        for token in ('100.000000000000001', '99.99999999999999999', '1e-400', '-1e-400'):
            with self.subTest(token=token), self.assertRaises(ValueError):
                value = self.result('check_exit_code', '100', token)
                # Keep this numeric refusal independent of check-success coherence.
                self.assertFalse(policy.exact_integer(None, value['modules']['slackware']['check_exit_code']))
                value.update(success=False, exit_code=1, exit_code_meaning='general failure')
                value['modules']['slackware'].update(state='failed', updates_available=None)
                self.validator.record(value, 'result')

    def test_integral_raw_codes_and_zero_spellings(self):
        for token in ('100', '100.0', '1e2', '1000e-1'):
            with self.subTest(token=token):
                self.validator.record(self.result('check_exit_code', '100', token), 'result')
        for token in ('0', '-0', '0.0', '-0.0', '0e400'):
            with self.subTest(token=token):
                self.validator.record(self.result('exit_code', '0', token), 'result')

    def test_final_code_underflow_is_rejected(self):
        for token in ('1e-400', '-1e-400', '0.00000000000000000001'):
            with self.subTest(token=token), self.assertRaises(ValueError):
                self.validator.record(self.result('exit_code', '0', token), 'result')

    def test_large_raw_integer_is_preserved_and_not_narrowed(self):
        for token in ('9007199254740993.0', '9007199254740993e0', '1e400', '-1e400'):
            with self.subTest(token=token):
                value = self.result('check_exit_code', '100', token)
                module = value['modules']['slackware']
                self.assertEqual(module['check_exit_code'], Decimal(token))
                self.assertTrue(policy.exact_integer(None, module['check_exit_code']))
                module.update(state='failed', updates_available=None)
                value.update(success=False, exit_code=1, exit_code_meaning='general failure')
                self.validator.record(value, 'result')

    def test_decoder_preserves_numbers_without_nonfinite_overflow(self):
        for token in ('1.0000000000000001', '0.99999999999999999', '1e-400',
                      '-1e-400', '100.000000000000001', '9007199254740993.0',
                      '9007199254740993e0', '1e400', '-1e400'):
            with self.subTest(token=token):
                value = policy.decode(('{"value":' + token + '}').encode())['value']
                self.assertIsInstance(value, Decimal)
                self.assertTrue(value.is_finite())
                self.assertEqual(value, Decimal(token))

    def test_boolean_fractional_and_nonfinite_types(self):
        for value in (True, False, Decimal('0.1'), Decimal('NaN'), Decimal('Infinity'),
                      float('nan'), float('inf'), float('-inf'), '1', None):
            with self.subTest(value=repr(value)):
                self.assertFalse(policy.exact_integer(None, value))
        for value in (True, False, Decimal('NaN'), Decimal('Infinity'), float('inf'),
                      float('-inf'), float('nan')):
            with self.subTest(value=repr(value)):
                self.assertFalse(policy.exact_number(None, value))
        for value in (1, 1.0, Decimal('1.000'), Decimal('1e400')):
            self.assertTrue(policy.exact_integer(None, value))
            self.assertTrue(policy.exact_number(None, value))
        self.assertTrue(policy.exact_number(None, Decimal('0.1')))

    def test_strict_decoding_is_preserved(self):
        for raw in (b'{"x":NaN}', b'{"x":Infinity}', b'{"x":-Infinity}',
                    b'{"x":1,"x":2}', b'{"x":{"a":1,"a":2}}',
                    b'{} {}', b'\xff', b'{"x":01}'):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                policy.decode(raw)

    def test_repeated_large_sequences_are_rejected(self):
        for token in ('1e20', '1e400', '1e1000000', '9007199254740993.0'):
            with self.subTest(token=token), self.assertRaises(ValueError):
                self.validator.stream(self.stream(token, token), fragment=True)

    def test_exact_large_successors_are_accepted_as_fragments(self):
        for exponent in (20, 30, 100, 1000):
            first = '1e' + str(exponent)
            second = str(10 ** exponent + 1)
            with self.subTest(exponent=exponent):
                self.validator.stream(self.stream(first, second), fragment=True)
                with self.assertRaises(ValueError):
                    self.validator.stream(self.stream(first, second))

    def test_fractional_sequence_does_not_become_integral(self):
        with self.assertRaises(ValueError):
            self.validator.stream(self.stream('1.0000000000000001', '2'))

    def test_complete_integral_decimal_sequence(self):
        self.validator.stream(self.stream('1.0', '2e0'))

    def test_sequence_math_is_independent_of_caller_context(self):
        with localcontext() as context:
            context.prec = 1
            context.traps[Inexact] = True
            self.validator.stream(self.stream('1e30', str(10 ** 30 + 1)), fragment=True)
            self.assertFalse(policy.sequence_offset_matches(Decimal('1e400'), 1, 1))
            self.assertTrue(policy.sequence_offset_matches(Decimal('1e1000000'),
                                                          Decimal('1e1000000'), 0))

    def test_sequence_comparison_against_independent_integer_oracle(self):
        generator = random.Random(630)
        for case in range(200):
            first = generator.randrange(1, 10 ** generator.randrange(1, 101))
            offset = generator.randrange(0, 21)
            for error in (-1, 0, 1):
                current = first + offset + error
                with self.subTest(case=case, error=error):
                    self.assertEqual(policy.sequence_offset_matches(
                        Decimal(current), Decimal(first), offset), error == 0)


if __name__ == '__main__':
    unittest.main(verbosity=2)
