#!/usr/bin/env python3
"""Test offline authored package-case data, never package/native workflows."""
import copy
from dataclasses import asdict, replace
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

from json_result_test_support import compare

sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
SUBJECT = ROOT / 'tools/reference/json_v1_package_case.py'


def subject():
    if not SUBJECT.is_file():
        raise AssertionError('offline package-case assessor has not been implemented')
    name = 'prospective_package_case'
    spec = importlib.util.spec_from_file_location(name, SUBJECT)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def supplied(m):
    identity = m.CaseIdentity('private-case', 'Slackware-current', 'private-version',
                              'private-source', 'private-boot', 'private-attempt', 'private-run')
    config = m.ConfigurationFacts('private-config', True, True)
    def stream(data):
        return m.ByteCapture('complete', data, len(data), hashlib.sha256(data).hexdigest())
    actions = tuple(m.ActionFacts(name, raw, stream(b''), stream(b''), (), (), (), ())
                    for name, raw in (('update', 0), ('install-new', 20), ('upgrade-all', 0)))
    rules = tuple(m.ActionRule(name, 'required', criterion) for name, criterion in (
        ('update', 'original-update'), ('install-new', 'empty-install20'), ('upgrade-all', 'mandatory-upgrade')))
    profile = m.CaseProfile(identity, config, rules, False)
    process = m.ProcessFacts('authored-fixture', 0, stream(b''), stream(b''))
    evidence = m.CaseEvidence(identity, config, actions, True, stream(b'pin'), identity, 'private-pin', process)
    return profile, m.CaseExpectations(evidence, b'{}', 'success', False), evidence


class RecordValidation(unittest.TestCase):
    def test_private_enum_labels_never_invoke_caller_callbacks(self):
        m=subject();p,e,o=supplied(m)
        owner=self
        class Callback:
            def __eq__(self,other):
                owner.fail('caller equality callback reached')
        value=Callback()
        variants=[(p,e,replace(o,raw_pkglist=replace(o.raw_pkglist,state=value))),
            (p,e,replace(o,actions=(replace(o.actions[0],name=value),)+o.actions[1:])),
            (replace(p,actions=(replace(p.actions[0],applicability=value),)+p.actions[1:]),e,o),
            (replace(p,actions=(replace(p.actions[0],criterion=value),)+p.actions[1:]),e,o),
            (p,e,replace(o,process=replace(o.process,origin=value))),
            (p,replace(e,outcome=value),o)]
        for index,(profile,expected,observed) in enumerate(variants):
            with self.subTest(index=index),self.assertRaises(ValueError):
                m.validate_case_inputs(profile,expected,observed)

    def test_hash_only_declaration_stays_unknown(self):
        m = subject(); profile, expected, observed = supplied(m)
        missing = m.ByteCapture('unknown', None, 3, hashlib.sha256(b'pin').hexdigest())
        try:
            result = m.validate_case_inputs(profile, expected, replace(observed, raw_pkglist=missing))
        except ValueError as error:
            self.fail('Declared metadata without bytes must remain unknown data: ' + str(error))
        self.assertIsNone(result)

    def test_valid_immutable_inputs_and_unknown_vector(self):
        m = subject()
        profile, expected, observed = supplied(m)
        self.assertIsNone(m.validate_case_inputs(profile, expected, observed))
        actions = list(observed.actions)
        actions[1] = replace(actions[1], target_effects=None)
        self.assertIsNone(m.validate_case_inputs(profile, expected, replace(observed, actions=tuple(actions))))

    def test_boolean_is_not_an_observed_raw_integer(self):
        m = subject(); profile, expected, observed = supplied(m)
        actions = (replace(observed.actions[0], raw_status=True),) + observed.actions[1:]
        with self.assertRaises(ValueError):
            m.validate_case_inputs(profile, expected, replace(observed, actions=actions))

    def test_mutable_or_nullable_vector_members_rejected(self):
        m = subject(); profile, expected, observed = supplied(m)
        for value in ([], (None,), ('ok', 1)):
            actions = (replace(observed.actions[0], selector=value),) + observed.actions[1:]
            with self.subTest(value=value), self.assertRaises(ValueError):
                m.validate_case_inputs(profile, expected, replace(observed, actions=actions))

    def test_wrong_action_order_and_mutable_action_container(self):
        m = subject(); profile, expected, observed = supplied(m)
        for actions in (observed.actions[::-1], list(observed.actions)):
            with self.assertRaises(ValueError):
                m.validate_case_inputs(profile, expected, replace(observed, actions=actions))

    def test_complete_capture_requires_bytes_but_conflict_is_data(self):
        m = subject(); profile, expected, observed = supplied(m)
        with self.assertRaises(ValueError):
            m.validate_case_inputs(profile, expected, replace(observed, raw_pkglist=m.ByteCapture('complete', None, 0, None)))
        self.assertIsNone(m.validate_case_inputs(profile, expected, replace(observed, raw_pkglist=m.ByteCapture('complete', b'x', 0, '0' * 64))))

    def test_not_produced_is_not_an_empty_capture(self):
        m = subject(); profile, expected, observed = supplied(m)
        capture = m.ByteCapture('not-produced', None, None, None)
        self.assertIsNone(m.validate_case_inputs(profile, expected, replace(observed, raw_pkglist=capture)))
        with self.assertRaises(ValueError):
            m.validate_case_inputs(profile, expected, replace(observed, raw_pkglist=replace(capture, data=b'')))

    def test_boolean_size_or_unbounded_raw_refused(self):
        m = subject(); profile, expected, observed = supplied(m)
        with self.assertRaises(ValueError):
            m.validate_case_inputs(profile, expected, replace(observed, raw_pkglist=m.ByteCapture('complete', b'', False, None)))
        for raw in (-2, 256, '0'):
            actions = (replace(observed.actions[0], raw_status=raw),) + observed.actions[1:]
            with self.assertRaises(ValueError):
                m.validate_case_inputs(profile, expected, replace(observed, actions=actions))


FIXTURES = ROOT / 'tests/fixtures/reference/json-v1-package-case'


def load_case(case_id, m):
    data = json.loads((FIXTURES / (case_id + '.data.json')).read_text())
    def capture(row):
        return m.ByteCapture(row['state'], None if row['hex'] is None else bytes.fromhex(row['hex']),
                             row['declared_size'], row['declared_sha256'])
    def evidence(row):
        actions = []
        for action in row['actions']:
            actions.append(m.ActionFacts(action['name'], action['raw_status'], capture(action['stdout']),
                capture(action['stderr']), *(None if action[k] is None else tuple(action[k])
                for k in ('selector','target_effects','owned_effects','unexpected_effects'))))
        process = row['process']
        return m.CaseEvidence(m.CaseIdentity(**row['identity']),m.ConfigurationFacts(**row['configuration']),
            tuple(actions),row['update_streams_error_free'],capture(row['raw_pkglist']),
            m.CaseIdentity(**row['pin_identity']),row['pin_artifact_id'],
            m.ProcessFacts(process['origin'],process['status'],capture(process['stdout']),capture(process['stderr'])))
    row = data['profile']
    profile = m.CaseProfile(m.CaseIdentity(**row['identity']),m.ConfigurationFacts(**row['configuration']),
                            tuple(m.ActionRule(**a) for a in row['actions']),row['boot_unsafe'])
    read = lambda name: None if name is None else (FIXTURES / name).read_bytes()
    row = data['expectations']
    expected = m.CaseExpectations(evidence(row['evidence']),read(row['result_file']),row['outcome'],row['forward_failure_expected'])
    wanted = json.loads((FIXTURES / (case_id + '.assessment.json')).read_text())
    return read(data['result_file']),profile,expected,evidence(data['observations']),wanted


def case(case_id):
    m = subject()
    if not hasattr(m,'assess_package_case'):
        raise AssertionError('assess_package_case behavior is not implemented')
    raw,profile,expected,observed,wanted = load_case(case_id,m)
    actual = m.assess_package_case(raw,profile,expected,observed)
    compare(json.loads(json.dumps(asdict(actual))),wanted)
    return actual


class EvidenceRelations(unittest.TestCase):
    def test_literal_baseline_empty_stdout_and_missing_evidence(self):
        for name in ('P01','P02','P03','P04','P05','P06','P07','P08','P20','P25'):
            with self.subTest(case=name):
                case(name)

    def test_hash_only_pin_and_missing_error_free_remain_pending(self):
        m=subject(); self.assertTrue(hasattr(m,'assess_package_case'),'assessment not implemented')
        raw,p,e,o,_=load_case('P01',m)
        for changed in (replace(o,raw_pkglist=replace(o.raw_pkglist,state='unknown',data=None)),
                        replace(o,update_streams_error_free=None),
                        replace(o,raw_pkglist=replace(o.raw_pkglist,state='incomplete',data=b'app'))):
            result=m.assess_package_case(raw,p,e,changed)
            self.assertEqual(result.data_disposition,'pending')
            self.assertFalse(result.native_acceptance)

    def test_declared_size_and_digest_conflicts_are_not_ignored(self):
        m=subject(); self.assertTrue(hasattr(m,'assess_package_case'),'assessment not implemented')
        raw,p,e,o,_=load_case('P01',m)
        for change in ({'declared_size':0},{'declared_sha256':'0'*64}):
            actual=m.assess_package_case(raw,p,e,replace(o,raw_pkglist=replace(o.raw_pkglist,**change)))
            self.assertEqual(actual.data_disposition,'mismatch')


class CaseMatrix(unittest.TestCase):
    pass


def matrix_test(name):
    def run(self):
        case(name)
    return run


for number in range(1,29):
    name='P'+str(number).zfill(2)
    setattr(CaseMatrix,'test_'+name,matrix_test(name))


class ResultShape(unittest.TestCase):
    def test_strict_decoding_and_mathematical_integral_numbers(self):
        m=subject(); self.assertTrue(hasattr(m,'assess_package_case'),'assessment not implemented')
        raw,p,e,o,_=load_case('P01',m)
        for changed in (raw+raw,raw.replace(b'"schema_version": 1',b'"schema_version": 1, "schema_version": 1'),
                        raw.replace(b'"schema_version": 1',b'"schema_version": NaN'),b'\xff'):
            result=m.assess_package_case(changed,p,e,o)
            self.assertEqual((result.shape,result.data_disposition),('invalid','mismatch'))
        changed=raw.replace(b'"schema_version": 1',b'"schema_version": 1.0').replace(
            b'"install_new_exit_code": 20',b'"install_new_exit_code": 2e1')
        self.assertEqual(m.assess_package_case(changed,p,e,o).data_disposition,'match')

    def test_helper_process_zero_is_not_failed_operation_status(self):
        m=subject(); self.assertTrue(hasattr(m,'assess_package_case'),'assessment not implemented')
        raw,p,e,o,_=load_case('P12',m)
        for origin,want in (('serializer-helper','match'),('captured-operation','mismatch')):
            o2=replace(o,process=replace(o.process,origin=origin))
            e2=replace(e,evidence=replace(e.evidence,process=replace(e.evidence.process,origin=origin)))
            self.assertEqual(m.assess_package_case(raw,p,e2,o2).data_disposition,want)


class Integration(unittest.TestCase):
    def test_supplied_paths_remain_inert_and_only_schemas_are_read(self):
        m=subject(); raw,p,e,o,_=load_case('P01',m)
        value=json.loads(raw);value['log_path']='/private/package-case-do-not-read'
        raw=json.dumps(value).encode();e=replace(e,result_bytes=raw)
        allowed={ROOT/'data/schemas/candidates/result-v1.schema.json',
                 ROOT/'data/schemas/candidates/event-v1.schema.json'}
        original=Path.open
        def guarded(path,*args,**kwargs):
            if path not in allowed:
                raise AssertionError('unexpected data path read')
            return original(path,*args,**kwargs)
        with patch.object(Path,'open',guarded):
            with self.assertRaisesRegex(AssertionError,'unexpected data path'):
                Path(value['log_path']).read_bytes()
            self.assertEqual(m.assess_package_case(raw,p,e,o).data_disposition,'match')

    def test_import_and_assessment_have_no_command_dispatch(self):
        def forbidden(*args, **kwargs):
            raise AssertionError('execution capability reached')
        import subprocess
        with patch.object(subprocess,'Popen',forbidden), patch.object(os,'system',forbidden):
            with self.assertRaisesRegex(AssertionError,'capability reached'):
                os.system('guard self-check; never executed')
            actual=case('P01')
            self.assertEqual(actual.data_disposition,'match')
            self.assertFalse(actual.runtime_authority)

    def test_new_input_bindings_and_preserved_originals(self):
        path=ROOT/'data/schemas/candidates/package-case-inputs.json'
        self.assertTrue(path.is_file(),'exact package-case bindings not integrated')
        record=json.loads(path.read_text())
        for row in record['files']+record['preserved_original_inputs']:
            value=ROOT/row['path']
            self.assertFalse(value.is_symlink())
            self.assertEqual(hashlib.sha256(value.read_bytes()).hexdigest(),row['sha256'],row['path'])
        cases={p.name.split('.')[0] for p in FIXTURES.glob('P*.data.json')}
        self.assertEqual(cases,{'P'+str(i).zfill(2) for i in range(1,29)})


class FinalReviewRegression(unittest.TestCase):
    def test_unknown_boot_justification_survives_known_failure(self):
        m=subject();raw,p,e,o,_=load_case('P09',m)
        result=m.assess_package_case(raw,replace(p,boot_unsafe=None),e,o)
        self.assertTrue(result.mismatched_checks)
        self.assertTrue(result.pending_checks)

    def test_unknown_digest_survives_known_size_conflict(self):
        m=subject();raw,p,e,o,_=load_case('P01',m)
        result=m.assess_package_case(raw,p,e,replace(o,raw_pkglist=replace(o.raw_pkglist,declared_size=0,declared_sha256=None)))
        self.assertTrue(result.mismatched_checks)
        self.assertTrue(result.pending_checks)

    def test_known_conflicting_pin_prefix_survives_incomplete_capture(self):
        m=subject();raw,p,e,o,_=load_case('P01',m)
        for size,digest in ((o.raw_pkglist.declared_size,None),(0,o.raw_pkglist.declared_sha256)):
            prefix=replace(o.raw_pkglist,state='incomplete',data=b'wrong-prefix',declared_size=size,declared_sha256=digest)
            result=m.assess_package_case(raw,p,e,replace(o,raw_pkglist=prefix))
            with self.subTest(size=size):
                self.assertTrue(result.mismatched_checks)
                self.assertTrue(result.pending_checks)

    def test_attempted_required_streams_cannot_be_not_produced(self):
        m=subject();raw,p,e,o,_=load_case('P01',m)
        missing=m.ByteCapture('not-produced',None,None,None)
        for index in range(3):
            for key in ('stdout','stderr'):
                actual=list(o.actions);wanted=list(e.evidence.actions)
                actual[index]=replace(actual[index],**{key:missing})
                wanted[index]=replace(wanted[index],**{key:missing})
                with self.subTest(action=index,stream=key):
                    result=m.assess_package_case(raw,p,replace(e,evidence=replace(e.evidence,actions=tuple(wanted))),replace(o,actions=tuple(actual)))
                    self.assertEqual(result.data_disposition,'mismatch')

    def test_required_pkglist_cannot_be_not_produced(self):
        m=subject();raw,p,e,o,_=load_case('P01',m)
        missing=m.ByteCapture('not-produced',None,None,None)
        result=m.assess_package_case(raw,p,replace(e,evidence=replace(e.evidence,raw_pkglist=missing)),replace(o,raw_pkglist=missing))
        self.assertEqual(result.data_disposition,'mismatch')

    def test_unattempted_streams_are_not_fabricated_empty_bytes(self):
        m=subject()
        for name,index in (('P15',2),('P17',1)):
            raw,p,e,o,_=load_case(name,m)
            actual=list(o.actions);wanted=list(e.evidence.actions)
            empty=m.ByteCapture('complete',b'',0,hashlib.sha256(b'').hexdigest())
            for key in ('stdout','stderr'):
                actual[index]=replace(actual[index],**{key:empty});wanted[index]=replace(wanted[index],**{key:empty})
            with self.subTest(case=name):
                result=m.assess_package_case(raw,p,replace(e,evidence=replace(e.evidence,actions=tuple(wanted))),replace(o,actions=tuple(actual)))
                self.assertTrue(result.mismatched_checks)
                self.assertTrue(any(c.key.endswith('.production') for c in result.mismatched_checks))

    def test_applicability_and_configuration_must_agree(self):
        m=subject()
        for name,key,wrong in [('P01','install_new',False),('P15','upgrade_all',True)]:
            raw,p,e,o,_=load_case(name,m)
            p=replace(p,configuration=replace(p.configuration,**{key:wrong}))
            e=replace(e,evidence=replace(e.evidence,configuration=replace(e.evidence.configuration,**{key:wrong})))
            o=replace(o,configuration=replace(o.configuration,**{key:wrong}))
            with self.subTest(case=name):
                self.assertEqual(m.assess_package_case(raw,p,e,o).data_disposition,'mismatch')

    def test_nonempty_incomplete_install_prefix_keeps_conflict_and_pending(self):
        m=subject();raw,p,e,o,_=load_case('P01',m)
        actions=list(o.actions);actions[1]=replace(actions[1],stdout=m.ByteCapture('incomplete',b'\n',10,None))
        result=m.assess_package_case(raw,p,e,replace(o,actions=tuple(actions)))
        self.assertTrue(result.mismatched_checks)
        self.assertTrue(result.pending_checks)
        self.assertTrue(result.forward_failure_known)

    def test_required_no_action_and_disabled_native_criteria_refused(self):
        m=subject()
        for name,index,criterion in [('P01',1,'no-action'),('P15',2,'mandatory-upgrade'),('P17',1,'empty-install20')]:
            raw,p,e,o,_=load_case(name,m);rules=list(p.actions);rules[index]=replace(rules[index],criterion=criterion)
            with self.subTest(case=name),self.assertRaises(ValueError):
                m.assess_package_case(raw,replace(p,actions=tuple(rules)),e,o)


class KnownConflictRepair(unittest.TestCase):
    """Unknown facts must not suppress contradictions already present in supplied data."""

    def test_forbidden_effect_survives_unknown_raw(self):
        m=subject()
        for case_id,index in (('P17',1),('P15',2)):
            for vector in ('selector','target_effects','owned_effects','unexpected_effects'):
                raw,p,e,o,_=load_case(case_id,m)
                def changed(facts):
                    actions=list(facts.actions)
                    actions[index]=replace(actions[index],raw_status=None,**{vector:('known-later-effect',)})
                    return replace(facts,actions=tuple(actions))
                result=m.assess_package_case(raw,p,replace(e,evidence=changed(e.evidence)),changed(o))
                states={check.key:check.state for check in result.checks}
                with self.subTest(case=case_id,vector=vector):
                    self.assertEqual(states[p.actions[index].name+'.admission'],'mismatch')
                    self.assertEqual(result.data_disposition,'mismatch')
                    self.assertTrue(result.pending_checks)

    def test_required_absence_survives_unknown_criterion(self):
        m=subject()
        for case_id,index in (('P15',2),('P17',1)):
            raw,p,e,o,_=load_case(case_id,m)
            rules=list(p.actions)
            rules[index]=replace(rules[index],applicability='required',criterion='unknown')
            key='upgrade_all' if index==2 else 'install_new'
            p=replace(p,actions=tuple(rules),configuration=replace(p.configuration,**{key:True}))
            e=replace(e,evidence=replace(e.evidence,configuration=replace(e.evidence.configuration,**{key:True})))
            o=replace(o,configuration=replace(o.configuration,**{key:True}))
            result=m.assess_package_case(raw,p,e,o)
            states={check.key:check.state for check in result.checks}
            with self.subTest(case=case_id):
                self.assertEqual(states[p.actions[index].name+'.admission'],'mismatch')
                self.assertTrue(result.forward_failure_known)
                self.assertTrue(result.pending_checks)

    def test_profile_expected_identity_conflict_survives_unknown_observation(self):
        m=subject()
        for name in ('case_id','platform','platform_version','source_epoch','boot_id','attempt_id','run_id'):
            raw,p,e,o,_=load_case('P01',m)
            e=replace(e,evidence=replace(e.evidence,identity=replace(e.evidence.identity,**{name:'known-other-identity'})))
            o=replace(o,identity=replace(o.identity,**{name:None}))
            result=m.assess_package_case(raw,p,e,o)
            with self.subTest(component=name):
                self.assertEqual(result.data_disposition,'mismatch')
                self.assertTrue(result.mismatched_checks)
                self.assertTrue(result.pending_checks)

    def test_profile_expected_configuration_identity_conflict_survives_unknown_observation(self):
        m=subject();raw,p,e,o,_=load_case('P01',m)
        e=replace(e,evidence=replace(e.evidence,configuration=replace(e.evidence.configuration,identity='known-other-config')))
        o=replace(o,configuration=replace(o.configuration,identity=None))
        result=m.assess_package_case(raw,p,e,o)
        self.assertEqual(result.data_disposition,'mismatch')
        self.assertTrue(result.pending_checks)

    def test_profile_expected_pin_conflict_survives_unknown_observation(self):
        m=subject()
        for name in ('case_id','platform','platform_version','source_epoch','boot_id','attempt_id','run_id'):
            raw,p,e,o,_=load_case('P01',m)
            e=replace(e,evidence=replace(e.evidence,pin_identity=replace(e.evidence.pin_identity,**{name:'known-other-pin'})))
            o=replace(o,pin_identity=replace(o.pin_identity,**{name:None}))
            result=m.assess_package_case(raw,p,e,o)
            with self.subTest(component=name):
                self.assertEqual(result.data_disposition,'mismatch')
                self.assertTrue(result.pending_checks)

    def test_unknown_raw_without_known_forbidden_effect_stays_pending(self):
        m=subject();raw,p,e,o,_=load_case('P15',m)
        def changed(facts):
            actions=list(facts.actions);actions[2]=replace(actions[2],raw_status=None)
            return replace(facts,actions=tuple(actions))
        result=m.assess_package_case(raw,p,replace(e,evidence=changed(e.evidence)),changed(o))
        self.assertEqual(result.data_disposition,'pending')
        self.assertFalse(result.mismatched_checks)

    def test_agreeing_declarations_with_unknown_observation_do_not_invent_conflict(self):
        m=subject();raw,p,e,o,_=load_case('P01',m)
        result=m.assess_package_case(raw,p,e,replace(o,identity=replace(o.identity,run_id=None)))
        self.assertEqual(result.data_disposition,'pending')
        self.assertFalse(result.mismatched_checks)

    def test_unknown_criterion_does_not_borrow_native_success_semantics(self):
        m=subject();raw,p,e,o,_=load_case('P01',m)
        rules=list(p.actions);rules[2]=replace(rules[2],criterion='unknown')
        result=m.assess_package_case(raw,replace(p,actions=tuple(rules)),e,o)
        self.assertEqual(result.data_disposition,'pending')
        self.assertFalse(result.mismatched_checks)
        self.assertFalse(result.forward_failure_known)


if __name__ == '__main__':
    unittest.main()
