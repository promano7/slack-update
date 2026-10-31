#!/usr/bin/env python3
"""Test owner-adopted S1-S3 on complete authored data, never native operations."""

import copy
from decimal import Decimal
import importlib.util
from pathlib import Path
import sys
import unittest

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location(
    'success_coherence_policy', ROOT / 'tools/reference/json_v1_candidate.py')
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)


def supplied(operation, final=0):
    """Copy the complete authored fixture and select a literal result envelope."""
    value = policy.decode((ROOT / 'tests/fixtures/reference/json-v1-candidate' /
                           (operation + '.json')).read_bytes())
    envelopes = {
        0: (True, False, True, 'none', 'success; no reboot required'),
        1: (False, False, True, 'none', 'general failure'),
        2: (False, True, True, 'none', 'partial update or verification failure'),
        3: (False, True, False, 'unsafe', 'critical boot preparation failure; do not reboot'),
        4: (True, False, True, 'recommended', 'success; reboot recommended'),
        5: (True, False, True, 'required', 'success; reboot required'),
    }
    success, partial, safe, reboot, meaning = envelopes[final]
    value.update(exit_code=final, success=success, partial=partial,
                 boot_safe=safe, reboot=reboot, exit_code_meaning=meaning)
    return value


class SuccessCoherence(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.current = policy.CandidateValidator()
        cls.previous = policy.ExactDraft202012Validator(policy.decode((ROOT /
            'data/schemas/candidates/history/pre743/data/schemas/candidates/result-v1.schema.json').read_bytes()))

    def newly_rejected(self, value, field):
        # The complete prior schema admits this exact document. The new refusal
        # must name the adopted condition, not an unrelated invalid fixture.
        self.previous.validate(value)
        with self.assertRaisesRegex(ValueError, field):
            self.current.record(value, 'result')

    def test_s1_dry_success_rejects_failed_raw(self):
        for raw in (-1, 1, 20, 42, Decimal('1e400')):
            value = supplied('dry-run')
            value['modules']['slackware'].update(
                check_exit_code=raw, state='failed', updates_available=None)
            with self.subTest(raw=raw):
                self.newly_rejected(value, 'check_exit_code')

    def test_s1_dry_success_rejects_errors(self):
        for errors in ([''], ['diagnostic'], ['same', 'same']):
            value = supplied('dry-run')
            value['errors'] = errors
            with self.subTest(errors=errors):
                self.newly_rejected(value, 'errors')

    def test_s1_dry_success_accepts_both_raw_codes(self):
        for raw in (0, 100, Decimal('0.0'), Decimal('1e2')):
            value = supplied('dry-run')
            value['modules']['slackware'].update(
                check_exit_code=raw, updates_available=raw == 100)
            with self.subTest(raw=raw):
                self.current.record(value, 'result')

    def test_s1_dry_failure_keeps_errors_and_raw_domain(self):
        for raw in (0, 100, 20, Decimal('1e400')):
            for errors in ([], ['diagnostic']):
                value = supplied('dry-run', 1)
                value['errors'] = errors
                value['modules']['slackware'].update(
                    check_exit_code=raw, state='success' if raw in (0, 100) else 'failed',
                    updates_available=(raw == 100) if raw in (0, 100) else None)
                with self.subTest(raw=raw, errors=errors):
                    self.previous.validate(value)
                    self.current.record(value, 'result')

    def test_s2_apply_success_rejects_errors_at_each_success_code(self):
        for final in (0, 4, 5):
            for errors in ([''], ['diagnostic']):
                value = supplied('apply', final)
                value['errors'] = errors
                with self.subTest(final=final, errors=errors):
                    self.newly_rejected(value, 'errors')

    def test_s2_apply_success_rejects_failed_slackware_at_each_success_code(self):
        for final in (0, 4, 5):
            value = supplied('apply', final)
            value['modules']['slackware']['state'] = 'failed'
            with self.subTest(final=final):
                self.newly_rejected(value, 'slackware.state')

    def test_s2_apply_coherent_success_accepts_each_success_code(self):
        for final in (0, 4, 5):
            with self.subTest(final=final):
                self.current.record(supplied('apply', final), 'result')

    def test_s2_apply_failure_keeps_error_and_state_independence(self):
        for final in (2, 3):
            for state in ('success', 'failed'):
                for errors in ([], ['diagnostic']):
                    value = supplied('apply', final)
                    value['modules']['slackware']['state'] = state
                    value['errors'] = errors
                    with self.subTest(final=final, state=state, errors=errors):
                        self.previous.validate(value)
                        self.current.record(value, 'result')

    def test_s3_replacement_without_attempt_rejected_on_success_and_failure(self):
        for final in (0, 2, 3, 4, 5):
            value = supplied('apply', final)
            value['modules']['boot'].update(
                grub_config_replaced=True, grub_replacement_attempted=False)
            with self.subTest(final=final):
                self.newly_rejected(value, 'grub_replacement_attempted')

    def test_s3_other_attempt_replacement_pairs_remain_representable(self):
        for final in (0, 2, 3, 4, 5):
            for attempted, replaced in ((False, False), (True, False), (True, True)):
                value = supplied('apply', final)
                value['modules']['boot'].update(
                    grub_replacement_attempted=attempted, grub_config_replaced=replaced)
                with self.subTest(final=final, attempted=attempted, replaced=replaced):
                    self.current.record(value, 'result')

    def test_s3_does_not_require_unselected_generation_flags(self):
        value = supplied('apply')
        value['modules']['boot'].update(grub_config_replaced=True,
            grub_replacement_attempted=True, grub_command_attempted=False,
            grub_generation_exit_code=None, grub_validation_exit_code=None)
        self.current.record(value, 'result')

    def test_warning_text_is_not_an_error(self):
        for operation in ('check', 'dry-run', 'apply'):
            value = supplied(operation)
            value['warnings'] = ['warning', 'warning']
            self.current.record(value, 'result')

    def test_missing_fields_and_invalid_types_still_rejected(self):
        controls = (
            ('dry-run', ('errors',), None),
            ('dry-run', ('modules', 'slackware', 'check_exit_code'), None),
            ('apply', ('modules', 'slackware', 'state'), None),
            ('apply', ('modules', 'boot', 'grub_replacement_attempted'), None),
        )
        for operation, pointer, _ in controls:
            value = supplied(operation)
            parent = value
            for key in pointer[:-1]:
                parent = parent[key]
            del parent[pointer[-1]]
            with self.subTest(operation=operation, missing=pointer), self.assertRaises(ValueError):
                self.current.record(value, 'result')
        for raw in (True, False, '0', None, Decimal('0.5')):
            value = supplied('dry-run')
            value['modules']['slackware']['check_exit_code'] = raw
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                self.current.record(value, 'result')
        for attempted in (0, 1, 'true', None):
            value = supplied('apply')
            value['modules']['boot']['grub_replacement_attempted'] = attempted
            with self.subTest(attempted=attempted), self.assertRaises(ValueError):
                self.current.record(value, 'result')

    def test_historical_upgrade20_shape_is_not_native_acceptance(self):
        value = supplied('apply')
        value['modules']['slackware'].update(install_new_exit_code=20, upgrade_all_exit_code=20)
        self.current.record(value, 'result')
        # S1-S3 intentionally do not infer native outcomes from raw package codes.
        # Native upgrade20 remains failure; install20 needs empty stdout AND no effects.

    def test_v0_metadata_remains_rejected(self):
        for operation in ('check', 'dry-run', 'apply'):
            value = supplied(operation)
            value.update(schema_version=0, schema_status='provisional')
            with self.subTest(operation=operation), self.assertRaises(ValueError):
                self.current.record(value, 'result')

    def test_complete_previous_schema_preserved_as_prefix(self):
        current = copy.deepcopy(self.current.validators['result'].schema)
        appended = current['allOf'][7:]
        current['allOf'] = current['allOf'][:7]
        self.assertEqual(current, self.previous.schema)
        self.assertEqual(len(appended), 3)


if __name__ == '__main__':
    unittest.main()
