"""Assess supplied prospective package-case data, never native truth or authority."""
from dataclasses import dataclass, field
from decimal import Decimal
from functools import lru_cache
import hashlib
import importlib.util
from pathlib import Path
import re
import sys

ACTIONS = ('update', 'install-new', 'upgrade-all')
IDENTITY_FIELDS = ('case_id', 'platform', 'platform_version', 'source_epoch',
                   'boot_id', 'attempt_id', 'run_id')
CONFIG_FIELDS = ('identity', 'install_new', 'upgrade_all')
VECTOR_FIELDS = ('selector', 'target_effects', 'owned_effects', 'unexpected_effects')
NATIVE_OBLIGATIONS = (
    'subject-source-graph', 'platform-original-authority', 'independent-provenance',
    'original-identity-timeline', 'raw-status-selector-vector', 'target-owned-effect-vector',
    'writer-child-lifetimes', 'time-fence-recovery-budget', 'original-restoration-verification',
    'publication-last-receipt', 'positive-negative-fault-controls', 'scoped-closure-or-pending')


@dataclass(frozen=True)
class CaseIdentity:
    case_id: object
    platform: object
    platform_version: object
    source_epoch: object
    boot_id: object
    attempt_id: object
    run_id: object


@dataclass(frozen=True)
class ConfigurationFacts:
    identity: object
    install_new: object
    upgrade_all: object


@dataclass(frozen=True)
class ByteCapture:
    state: str
    data: object
    declared_size: object
    declared_sha256: object


@dataclass(frozen=True)
class ActionRule:
    name: str
    applicability: str
    criterion: str


@dataclass(frozen=True)
class ActionFacts:
    name: str
    raw_status: object
    stdout: ByteCapture
    stderr: ByteCapture
    selector: object
    target_effects: object
    owned_effects: object
    unexpected_effects: object


@dataclass(frozen=True)
class ProcessFacts:
    origin: str
    status: object
    stdout: ByteCapture
    stderr: ByteCapture


@dataclass(frozen=True)
class CaseProfile:
    identity: CaseIdentity
    configuration: ConfigurationFacts
    actions: tuple
    boot_unsafe: object


@dataclass(frozen=True)
class CaseEvidence:
    identity: CaseIdentity
    configuration: ConfigurationFacts
    actions: tuple
    update_streams_error_free: object
    raw_pkglist: ByteCapture
    pin_identity: CaseIdentity
    pin_artifact_id: object
    process: ProcessFacts


@dataclass(frozen=True)
class CaseExpectations:
    evidence: CaseEvidence
    result_bytes: object
    outcome: str
    forward_failure_expected: object


@dataclass(frozen=True)
class Check:
    key: str
    state: str
    detail: str = ''


@dataclass(frozen=True)
class Assessment:
    shape: str
    checks: tuple
    matched_checks: tuple
    mismatched_checks: tuple
    pending_checks: tuple
    forward_failure_known: bool
    outcome_agreement: str
    data_disposition: str
    native_acceptance: bool = field(default=False, init=False)
    independence_verified: bool = field(default=False, init=False)
    runtime_authority: bool = field(default=False, init=False)
    phase1_complete: bool = field(default=False, init=False)
    outstanding_native_obligations: tuple = field(default=NATIVE_OBLIGATIONS, init=False)


def _require(condition, label):
    if not condition:
        raise ValueError('invalid private package-case input: ' + label)


def _optional(value, kind, label):
    _require(value is None or type(value) is kind, label)


def _identity(value):
    _require(type(value) is CaseIdentity, 'identity record')
    for name in IDENTITY_FIELDS:
        _optional(getattr(value, name), str, 'identity.' + name)


def _configuration(value):
    _require(type(value) is ConfigurationFacts, 'configuration record')
    _optional(value.identity, str, 'configuration identity')
    _optional(value.install_new, bool, 'install configuration')
    _optional(value.upgrade_all, bool, 'upgrade configuration')


def _capture(value):
    _require(type(value) is ByteCapture, 'byte capture record')
    _require(type(value.state) is str and value.state in ('complete', 'incomplete', 'unknown', 'not-produced'), 'capture state')
    _optional(value.data, bytes, 'capture bytes')
    _optional(value.declared_size, int, 'capture size')
    _require(value.declared_size is None or value.declared_size >= 0, 'nonnegative size')
    _require(value.declared_sha256 is None or type(value.declared_sha256) is str and
             re.fullmatch('[0-9a-f]{64}', value.declared_sha256) is not None, 'declared digest')
    if value.state == 'complete':
        _require(value.data is not None, 'complete capture needs bytes')
    elif value.state == 'unknown':
        _require(value.data is None, 'unknown capture has no observed bytes')
    elif value.state == 'not-produced':
        _require(value.data is value.declared_size is value.declared_sha256 is None,
                 'not-produced capture has no invented bytes or metadata')


def _evidence(value):
    _require(type(value) is CaseEvidence, 'evidence record')
    _identity(value.identity)
    _configuration(value.configuration)
    _require(type(value.actions) is tuple and len(value.actions) == 3, 'three immutable action records')
    for name, action in zip(ACTIONS, value.actions):
        _require(type(action) is ActionFacts and type(action.name) is str and action.name == name, 'ordered action facts')
        _optional(action.raw_status, int, 'observed raw integer')
        _require(action.raw_status is None or -1 <= action.raw_status <= 255, 'observed OS raw domain')
        _capture(action.stdout)
        _capture(action.stderr)
        for key in VECTOR_FIELDS:
            vector = getattr(action, key)
            _require(vector is None or type(vector) is tuple and all(type(x) is str for x in vector),
                     'complete ordered vector ' + key)
    _optional(value.update_streams_error_free, bool, 'update stream declaration')
    _capture(value.raw_pkglist)
    _identity(value.pin_identity)
    _optional(value.pin_artifact_id, str, 'pin artifact ID')
    _require(type(value.process) is ProcessFacts, 'process record')
    _require(type(value.process.origin) is str and value.process.origin in ('authored-fixture', 'serializer-helper', 'captured-operation', 'unknown'), 'process origin')
    _optional(value.process.status, int, 'process integer status')
    _require(value.process.status is None or 0 <= value.process.status <= 255, 'process status domain')
    _capture(value.process.stdout)
    _capture(value.process.stderr)


def validate_case_inputs(profile, expectations, observations):
    """Reject malformed private records; known observational conflicts remain data."""
    _require(type(profile) is CaseProfile, 'profile record')
    _identity(profile.identity)
    _configuration(profile.configuration)
    _optional(profile.boot_unsafe, bool, 'boot-unsafe case fact')
    _require(type(profile.actions) is tuple and len(profile.actions) == 3, 'three immutable action rules')
    criteria = ('original-update', 'empty-install20', 'mandatory-upgrade')
    for name, criterion, rule in zip(ACTIONS, criteria, profile.actions):
        _require(type(rule) is ActionRule and type(rule.name) is str and rule.name == name, 'ordered action rules')
        _require(type(rule.applicability) is str and rule.applicability in ('required', 'disabled', 'blocked', 'unknown'), 'applicability')
        _require(type(rule.criterion) is str and rule.criterion in (criterion, 'no-action', 'unknown'), 'action-specific criterion')
        if rule.applicability == 'required':
            _require(rule.criterion != 'no-action', 'required action criterion')
        elif rule.applicability in ('disabled', 'blocked'):
            _require(rule.criterion in ('no-action', 'unknown'), 'unattempted action criterion')
    _require(type(expectations) is CaseExpectations, 'expectation record')
    _optional(expectations.result_bytes, bytes, 'literal expected result bytes')
    _require(type(expectations.outcome) is str and expectations.outcome in ('success', 'failure', 'absence', 'unknown'), 'expected outcome')
    _optional(expectations.forward_failure_expected, bool, 'expected forward failure')
    _evidence(expectations.evidence)
    _evidence(observations)


@lru_cache(maxsize=1)
def _policy():
    # Only the existing repository reader is loaded. No input path or callback
    # selects code, and the reader's main/CLI is never entered.
    path = Path(__file__).with_name('json_v1_candidate.py')
    spec = importlib.util.spec_from_file_location('_package_case_candidate_reader', path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module, module.CandidateValidator()


def _same_json(left, right):
    if isinstance(left, bool) or isinstance(right, bool):
        return type(left) is type(right) and left == right
    if isinstance(left, (int, Decimal)) and isinstance(right, (int, Decimal)):
        return left == right
    if type(left) is not type(right):
        return False
    if isinstance(left, dict):
        return left.keys() == right.keys() and all(_same_json(left[k], right[k]) for k in left)
    if isinstance(left, list):
        return len(left) == len(right) and all(_same_json(a, b) for a, b in zip(left, right))
    return left == right


def _integrity(capture):
    if capture.state == 'not-produced':
        return True
    if capture.data is not None and capture.declared_size is not None and len(capture.data) > capture.declared_size:
        return False
    if capture.state != 'complete':
        return None
    if capture.declared_size is not None and len(capture.data) != capture.declared_size:
        return False
    if capture.declared_sha256 is not None and hashlib.sha256(capture.data).hexdigest() != capture.declared_sha256:
        return False
    return None if capture.declared_size is None or capture.declared_sha256 is None else True


def _stream_equal(expected, observed):
    # An incomplete prefix cannot prove equality, but a conflicting observed
    # byte already disproves it; retain that fact separately from completeness.
    if expected.data is not None and observed.data is not None:
        overlap = min(len(expected.data), len(observed.data))
        if expected.data[:overlap] != observed.data[:overlap]:
            return False
        if expected.state == 'complete' and len(observed.data) > len(expected.data):
            return False
        if observed.state == 'complete' and len(expected.data) > len(observed.data):
            return False
    if expected.state in ('unknown', 'incomplete') or observed.state in ('unknown', 'incomplete'):
        return None
    if expected.state == observed.state == 'not-produced':
        return True
    if expected.state != observed.state:
        return False
    return expected.data == observed.data


def _known_failure(rule, actual, expected, error_free):
    raw = actual.raw_status
    if rule.applicability in ('disabled', 'blocked'):
        return (raw is not None and raw != -1) or any(
            getattr(actual, k) is not None and bool(getattr(actual, k)) for k in VECTOR_FIELDS)
    if rule.applicability != 'required':
        return False
    if raw == -1:
        return True
    if rule.criterion == 'unknown':
        return False
    if rule.name == 'update':
        return raw is not None and raw != 0 or error_free is False
    if rule.name == 'install-new':
        if raw is not None and raw not in (0, 20):
            return True
        # Install0 has no silently inherited install20 stdout/selector rule.
        return raw == 20 and (actual.stdout.data is not None and actual.stdout.data != b'' or any(
            getattr(actual, k) is not None and bool(getattr(actual, k)) for k in VECTOR_FIELDS))
    if raw is not None and raw != 0:
        return True
    if raw == 0:
        if actual.selector is not None and len(actual.selector) != 1:
            return True
        if actual.target_effects == () or actual.unexpected_effects:
            return True
        return any(getattr(actual, k) is not None and getattr(expected, k) is not None and
                   getattr(actual, k) != getattr(expected, k) for k in VECTOR_FIELDS)
    return False


def assess_package_case(result_bytes, profile, expectations, observations):
    """Compare untrusted supplied data; never produce native acceptance/authority."""
    validate_case_inputs(profile, expectations, observations)
    _optional(result_bytes, bytes, 'observed result bytes')
    checks = []

    def note(key, value):
        checks.append(Check(key, 'pending' if value is None else 'match' if value else 'mismatch'))

    def compare(key, expected, actual):
        note(key, None if expected is None or actual is None else expected == actual)

    def stream(key, expected, actual):
        states = (_integrity(expected), _integrity(actual))
        note(key + '.integrity', False if False in states else None if None in states else True)
        note(key + '.expected', _stream_equal(expected, actual))
        if False in states and any(c.state != 'not-produced' and
                (c.declared_size is None or c.declared_sha256 is None) for c in (expected, actual)):
            note(key + '.metadata_pending', None)
        if False in states and any(c.state in ('unknown', 'incomplete') for c in (expected, actual)):
            note(key + '.completeness_pending', None)

    shape, value, literal = 'absent', None, None
    if result_bytes is not None or expectations.result_bytes is not None:
        reader, validator = _policy()
        if expectations.result_bytes is not None:
            try:
                literal = validator.record(reader.decode(expectations.result_bytes), 'result')
            except ValueError as error:
                raise ValueError('invalid literal prospective result expectation') from error
        if result_bytes is not None:
            try:
                value = validator.record(reader.decode(result_bytes), 'result')
                if value['operation'] != 'apply':
                    raise ValueError('package-case result must be apply')
                shape = 'valid'
            except ValueError:
                shape, value = 'invalid', None
    note('shape', True if shape == 'valid' else False if shape == 'invalid' else None)
    note('result.literal', None if value is None or literal is None else _same_json(value, literal))
    wanted = expectations.evidence
    # Known declaration conflicts do not depend on a third observed value.
    # Emit only conflicts here, retaining the existing complete case assessments
    # and their independently reported unknown observation checks.
    for prefix, left, right, fields in (
            ('identity', profile.identity, wanted.identity, IDENTITY_FIELDS),
            ('config', profile.configuration, wanted.configuration, CONFIG_FIELDS),
            ('pin', profile.identity, wanted.pin_identity, IDENTITY_FIELDS)):
        for name in fields:
            first, second = getattr(left, name), getattr(right, name)
            if first is not None and second is not None and first != second:
                note(prefix + '.declarations.' + name, False)
    for prefix, expected in (('identity.profile', profile.identity), ('identity.expected', wanted.identity)):
        for name in IDENTITY_FIELDS:
            compare(prefix + '.' + name, getattr(expected, name), getattr(observations.identity, name))
    for prefix, expected in (('config.profile', profile.configuration), ('config.expected', wanted.configuration)):
        for name in CONFIG_FIELDS:
            compare(prefix + '.' + name, getattr(expected, name), getattr(observations.configuration, name))
    for prefix, expected in (('pin.profile', profile.identity), ('pin.expected', wanted.pin_identity)):
        for name in IDENTITY_FIELDS:
            compare(prefix + '.' + name, getattr(expected, name), getattr(observations.pin_identity, name))
    compare('pin.artifact', wanted.pin_artifact_id, observations.pin_artifact_id)
    compare('update.error_free', wanted.update_streams_error_free, observations.update_streams_error_free)
    stream('pin.raw', wanted.raw_pkglist, observations.raw_pkglist)
    if profile.actions[0].applicability == 'required' and observations.actions[0].raw_status is not None and observations.actions[0].raw_status >= 0:
        if any(c.state == 'not-produced' for c in (wanted.raw_pkglist, observations.raw_pkglist)):
            note('pin.raw.production', False)
    forward_failure = False
    json_fields = ('update_exit_code', 'install_new_exit_code', 'upgrade_all_exit_code')
    for rule, expected, actual, json_field in zip(profile.actions, wanted.actions, observations.actions, json_fields):
        name = rule.name
        compare(name + '.raw.expected', expected.raw_status, actual.raw_status)
        stream(name + '.stdout', expected.stdout, actual.stdout)
        stream(name + '.stderr', expected.stderr, actual.stderr)
        for key in VECTOR_FIELDS:
            compare(name + '.' + key, getattr(expected, key), getattr(actual, key))
        raw = actual.raw_status
        mode = rule.applicability
        for label, facts in (('expected', expected), ('observed', actual)):
            for key in ('stdout', 'stderr'):
                capture = getattr(facts, key)
                if facts.raw_status is not None and ((facts.raw_status >= 0 and capture.state == 'not-produced') or
                        (facts.raw_status == -1 and capture.state in ('complete', 'incomplete'))):
                    note(name + '.' + key + '.' + label + '.production', False)
        vectors = tuple(getattr(actual, k) for k in VECTOR_FIELDS)
        if mode in ('disabled', 'blocked') and (
                raw is not None and raw != -1 or any(v is not None and len(v) for v in vectors)):
            admission = False
        elif mode == 'required' and raw == -1:
            admission = False
        elif mode == 'unknown' or rule.criterion == 'unknown' or raw is None:
            admission = None
        elif mode == 'required':
            admission = raw != -1
        else:
            vectors = tuple(getattr(actual, k) for k in VECTOR_FIELDS)
            admission = False if raw != -1 or any(v is not None and len(v) for v in vectors) else None if None in vectors else True
            if mode == 'blocked' and not forward_failure and admission is True:
                admission = None
        if name != 'update' and admission is True:
            key = 'install_new' if name == 'install-new' else 'upgrade_all'
            config = (profile.configuration.identity, observations.configuration.identity,
                      getattr(profile.configuration, key), getattr(observations.configuration, key))
            if None in config:
                admission = None
            elif config[0] != config[1] or config[2] != config[3]:
                admission = False
        if name != 'update' and mode in ('required', 'disabled', 'blocked'):
            key = 'install_new' if name == 'install-new' else 'upgrade_all'
            enabled = mode != 'disabled'
            values = tuple(getattr(c, key) for c in (profile.configuration, wanted.configuration, observations.configuration))
            if any(v is not None and v != enabled for v in values):
                admission = False
            elif None in values and admission is True:
                admission = None
        note(name + '.admission', admission)
        if admission is False and rule.criterion == 'unknown':
            note(name + '.criterion', None)
        note(name + '.latch', None if forward_failure and raw is None else raw == -1 if forward_failure else True)
        if value is None or raw is None:
            note(name + '.result_raw', None)
        else:
            note(name + '.result_raw', value['modules']['slackware'][json_field] == (None if raw == -1 else raw))
        forward_failure = forward_failure or _known_failure(rule, actual, expected, observations.update_streams_error_free)
    compare('process.origin', None if wanted.process.origin == 'unknown' else wanted.process.origin,
            None if observations.process.origin == 'unknown' else observations.process.origin)
    compare('process.status', wanted.process.status, observations.process.status)
    stream('process.stdout', wanted.process.stdout, observations.process.stdout)
    stream('process.stderr', wanted.process.stderr, observations.process.stderr)
    process_relation = True
    if observations.process.origin == 'captured-operation':
        process_relation = None if value is None or observations.process.status is None else observations.process.status == value['exit_code']
    elif observations.process.origin == 'unknown':
        process_relation = None
    note('process.result_relation', process_relation)
    compare('forward.expected', expectations.forward_failure_expected, forward_failure)
    if value is None:
        coherent = None
    elif not forward_failure:
        coherent = True
    else:
        required_code = None if profile.boot_unsafe is None else 3 if profile.boot_unsafe else 2
        coherent = (value['modules']['slackware']['state'] == 'failed' and
                    value['success'] is False and value['partial'] is True and value['exit_code'] in (2, 3))
        if coherent:
            coherent = None if required_code is None else value['exit_code'] == required_code
    note('result.package_failure', coherent)
    if forward_failure and profile.boot_unsafe is None and coherent is False:
        note('result.boot_justification', None)
    observed_outcome = 'absence' if shape == 'absent' else None if value is None else 'success' if value['success'] else 'failure'
    note('result.outcome', None if expectations.outcome == 'unknown' or observed_outcome is None else expectations.outcome == observed_outcome)
    matched = tuple(c for c in checks if c.state == 'match')
    mismatched = tuple(c for c in checks if c.state == 'mismatch')
    pending = tuple(c for c in checks if c.state == 'pending')
    return Assessment(shape, tuple(checks), matched, mismatched, pending, forward_failure,
                      checks[-1].state, 'mismatch' if mismatched else 'pending' if pending else 'match')


if __name__ == '__main__':
    raise SystemExit('Import-only offline case assessor; no execution interface.')
