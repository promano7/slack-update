#!/usr/bin/env python3
"""Exercise the selected check-only candidate rule on authored offline data."""

import copy
from decimal import Decimal
import importlib.util
from pathlib import Path
import sys
import unittest

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    'check_coherence_candidate', ROOT / 'tools/reference/json_v1_candidate.py')
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)


def supplied(raw, final=0, errors=()):
    """Author a complete result, independently of any serializer output."""
    return dict(
        schema_version=1, schema_status='stable', operation='check',
        success=final == 0, partial=False, reboot='none', boot_safe=True,
        exit_code=final,
        exit_code_meaning='success; no reboot required' if final == 0 else 'general failure',
        exit_code_stable=True, started_at='', finished_at='',
        log_path='/authored/log', config_path='/authored/config',
        modules=dict(slackware=dict(
            state='success' if raw in (0, 100) else 'failed',
            check_exit_code=raw,
            updates_available=(raw == 100) if raw in (0, 100) else None)),
        warnings=[], errors=list(errors))


class CheckCoherence(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.validator = policy.CandidateValidator()
        cls.schema = policy.decode((ROOT / 'data/schemas/candidates/result-v1.schema.json').read_bytes())
        old = policy.decode((ROOT / 'data/schemas/candidates/history/pre665/data/schemas/candidates/result-v1.schema.json').read_bytes())
        cls.previous = policy.ExactDraft202012Validator(old)

    def test_success_accepts_both_success_raw_codes(self):
        for raw in (0, 100, Decimal('0.0'), Decimal('1e2')):
            with self.subTest(raw=raw):
                self.validator.record(supplied(raw), 'result')

    def test_success_rejects_failed_raw_codes(self):
        for raw in (-1, 1, 20, 42, 127, Decimal('9007199254740993.0'), Decimal('1e400')):
            value = supplied(raw)
            with self.subTest(raw=raw):
                self.previous.validate(value)
                with self.assertRaises(ValueError):
                    self.validator.record(value, 'result')

    def test_success_rejects_nonempty_errors(self):
        for raw in (0, 100):
            for errors in ([''], ['authored error'], ['same', 'same']):
                value = supplied(raw, errors=errors)
                with self.subTest(raw=raw, errors=errors):
                    self.previous.validate(value)
                    with self.assertRaises(ValueError):
                        self.validator.record(value, 'result')

    def test_failure_keeps_raw_domain_and_error_independence(self):
        for raw in (0, 100, -1, 20, 42, Decimal('1e400')):
            for errors in ([], ['authored error']):
                with self.subTest(raw=raw, errors=errors):
                    self.validator.record(supplied(raw, final=1, errors=errors), 'result')

    def test_warning_text_is_not_an_error(self):
        value = supplied(100)
        value['warnings'] = ['authored warning', 'authored warning']
        self.validator.record(value, 'result')
        self.assertEqual(value['warnings'], ['authored warning', 'authored warning'])

    def test_required_fields_and_types_are_not_weakened(self):
        for pointer in (('errors',), ('modules',), ('modules', 'slackware'),
                        ('modules', 'slackware', 'check_exit_code')):
            value = supplied(0)
            parent = value
            for key in pointer[:-1]:
                parent = parent[key]
            del parent[pointer[-1]]
            with self.subTest(pointer=pointer), self.assertRaises(ValueError):
                self.validator.record(value, 'result')
        for raw in (True, False, '0', None, Decimal('0.1')):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                self.validator.record(supplied(raw), 'result')
        for errors in (None, '', False, {}, 0):
            value = supplied(0)
            value['errors'] = errors
            with self.subTest(errors=errors), self.assertRaises(ValueError):
                self.validator.record(value, 'result')

    def test_clause_is_inactive_outside_check_success(self):
        # Partial objects here test ONLY the added clause, never whole schemas.
        clause = policy.ExactDraft202012Validator(self.schema['allOf'][-1])
        for operation in ('dry-run', 'apply'):
            for final in (0, 1):
                with self.subTest(operation=operation, final=final):
                    clause.validate(dict(operation=operation, exit_code=final,
                                         modules=dict(slackware=dict(check_exit_code=20)),
                                         errors=['authored diagnostic']))
        clause.validate(dict(operation='check', exit_code=1, errors=['diagnostic']))
        clause.validate({})

    def test_schema_has_exactly_the_selected_append(self):
        old = copy.deepcopy(self.previous.schema)
        new = copy.deepcopy(self.schema)
        clause = new['allOf'].pop()
        self.assertEqual(old, new)
        self.assertEqual(clause, dict(
            **{'if': dict(properties=dict(operation=dict(const='check'), exit_code=dict(const=0)),
                          required=['operation', 'exit_code'])},
            then=dict(properties=dict(
                modules=dict(properties=dict(slackware=dict(properties=dict(check_exit_code=dict(enum=[0, 100]))))),
                errors=dict(maxItems=0)))))

    def test_existing_fixture_and_v0_refusal(self):
        value = policy.decode((ROOT / 'tests/fixtures/reference/json-v1-candidate/check.json').read_bytes())
        self.validator.record(value, 'result')
        value.update(schema_version=0, schema_status='provisional')
        with self.assertRaises(ValueError):
            self.validator.record(value, 'result')


if __name__ == '__main__':
    unittest.main()
