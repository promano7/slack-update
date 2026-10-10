#!/usr/bin/env python3
"""Literal expectation declarations, never a subject-derived or native oracle."""
from dataclasses import dataclass
import json
import re

MAX_WIRE_BYTES = 262144
MAX_DEPTH = 12
MAX_VECTOR_ITEMS = 128
MAX_LABEL_CHARS = 128
MAX_BUDGET = 65535
MAX_TIME_NS = 9223372036854775807
PLATFORMS = ('Slackware-15.0', 'Slackware-current')
CASE_IDS = ('issuer-authentication', 'durable-consumption', 'single-launch-slot', 'bootstrap-bounds', 'namespace-FDs', 'time-revocation-fence', 'rights-budgets', 'guard-writer-inventory', 'original-backups', 'phase-deltas', 'stage7-binding', 'reference-entry', 'actual-selector', 'raw-status-latch', 'raw-pkglist-pin', 'package-hooks-effects', 'source-archives', 'helper-dependencies', 'child-quiescence', 'retained-restoration', 'original-verification', 'signal-crash-interleavings', 'publication-controls', 'record-last-receipt', 'unknown-publication', 'cross-closure-oracle')
FIELD_SPECS = (('selector-effects', (('update-raw-status', 'status'), ('update-stdout-sha256', 'digest'), ('update-stderr-sha256', 'digest'), ('update-streams-error-free', 'bool'), ('raw-pkglist-pin-sha256', 'digest'), ('install-new-raw-status', 'status'), ('install-new-selector', 'labels'), ('install-new-target-effects', 'labels'), ('install-new-owned-effects', 'labels'), ('upgrade-all-raw-status', 'status'), ('upgrade-all-selector', 'labels'), ('upgrade-all-target-effects', 'labels'), ('upgrade-all-owned-effects', 'labels'), ('unexpected-target-effects', 'labels'), ('unexpected-owned-effects', 'labels'), ('forward-stage-ids', 'labels'), ('full-forward-raw-status-vector', 'statuses'), ('original-identity-timeline', 'labels'))), ('recovery-obligations', (('original-forward-status', 'status'), ('forward-stopped', 'bool'), ('owned-child-identities', 'labels'), ('owned-children-quiescent', 'bool'), ('continuous-original-guard', 'bool'), ('recovery-rights-original-attempt', 'bool'), ('recovery-fence-valid', 'bool'), ('recovery-deadline-ns', 'time-ns'), ('recovery-budget-pre-spent', 'bool'), ('recovery-budget-remaining', 'budget'), ('verified-original-backups', 'labels'), ('original-restoration-state', 'label'), ('original-full-invariants-verified', 'bool'), ('target-evidence-closed', 'bool'), ('target-control-released', 'bool'), ('pending-target-obligations', 'labels'), ('pending-owned-obligations', 'labels'))), ('publication-controls', (('record-state', 'label'), ('record-sha256', 'digest'), ('record-no-replace', 'bool'), ('record-file-durable', 'bool'), ('record-metadata-durable', 'bool'), ('record-directory-durable', 'bool'), ('record-storage-durable', 'bool'), ('receipt-state', 'label'), ('receipt-sha256', 'digest'), ('receipt-no-replace', 'bool'), ('receipt-file-durable', 'bool'), ('receipt-metadata-durable', 'bool'), ('receipt-directory-durable', 'bool'), ('receipt-storage-durable', 'bool'), ('trusted-origin', 'bool'), ('handoff-acknowledged', 'bool'), ('pending-publication-obligations', 'labels'), ('target-effects-after-release', 'labels'), ('positive-control-effective', 'bool'), ('negative-control-effective', 'bool'), ('control-raw-consequence-ids', 'labels'))))
ORIGINS = ('private-literal', 'separately-reviewed-unverified')
AUTHOR_ROLES = ('expectation-author', 'verifier', 'unattributed')
DERIVATIONS = ('literal-independent-unverified', 'unknown')
SHA_PATTERN = re.compile(r'[0-9a-f]{64}\Z', re.ASCII)


@dataclass(frozen=True)
class Identity:
    platform: str
    platform_version: object
    boot_id: object
    source_epoch: object
    original_attempt: object
    test_run_id: object
    subject_source_sha256: object


@dataclass(frozen=True)
class Provenance:
    subject_source_sha256: object
    collector_source_sha256: object
    verifier_source_sha256: object
    author_source_sha256: object
    review_record_sha256: object
    author_role: str
    derivation: str


@dataclass(frozen=True)
class ExpectedField:
    field_id: str
    value: object


@dataclass(frozen=True)
class ExpectedVector:
    vector_id: str
    fields: tuple


@dataclass(frozen=True)
class Expectations:
    schema_version: int
    origin: str
    case_id: str
    identity: Identity
    provenance: Provenance
    vectors: tuple


@dataclass(frozen=True)
class Assessment:
    schema_valid: bool
    unknown_identity_fields: tuple
    pending_provenance_fields: tuple
    pending_expected_fields: tuple
    declaration_complete: bool
    independence_verified: bool
    native_oracle_selected: bool
    comparison_performed: bool
    native_cases_run: int
    native_proofs_added: int
    native_conformance: bool
    runtime_authority: bool


def require(condition, message):
    if not condition:
        raise ValueError(message)


def label(value):
    require(type(value) is str and 1 <= len(value) <= MAX_LABEL_CHARS, 'bounded exact label')
    require(value == value.strip() and all(32 <= ord(c) <= 126 for c in value), 'printable unnormalized label')


def digest(value):
    require(type(value) is str and SHA_PATTERN.fullmatch(value) is not None, 'lowercase declared SHA256')


def member(value, choices, message):
    require(type(value) is str and value in choices, message)


def field_value(value, kind):
    if value is None:
        return
    if kind == 'bool':
        require(type(value) is bool, 'exact nullable boolean')
    elif kind in ('status', 'budget', 'time-ns'):
        lower, upper = (-1, 255) if kind == 'status' else (0, MAX_BUDGET) if kind == 'budget' else (0, MAX_TIME_NS)
        require(type(value) is int and lower <= value <= upper, 'bounded exact ' + kind)
    elif kind == 'digest':
        digest(value)
    elif kind == 'label':
        label(value)
    else:
        require(kind in ('labels', 'statuses'), 'known literal field kind')
        require(type(value) is tuple and len(value) <= MAX_VECTOR_ITEMS, 'bounded immutable full vector')
        for item in value:
            field_value(item, 'label' if kind == 'labels' else 'status')
            require(item is not None, 'unknown whole vector is null, not nullable element')


def validate(expectations):
    require(type(expectations) is Expectations, 'exact immutable Expectations')
    require(type(expectations.schema_version) is int and expectations.schema_version == 1, 'schema version')
    member(expectations.origin, ORIGINS, 'unverified expectation origin')
    member(expectations.case_id, CASE_IDS, 'original case ID')
    identity = expectations.identity
    require(type(identity) is Identity, 'exact immutable identity')
    member(identity.platform, PLATFORMS, 'one explicit platform')
    for key in ('platform_version', 'boot_id', 'source_epoch', 'original_attempt', 'test_run_id'):
        if getattr(identity, key) is not None:
            label(getattr(identity, key))
    if identity.subject_source_sha256 is not None:
        digest(identity.subject_source_sha256)
    p = expectations.provenance
    require(type(p) is Provenance, 'exact immutable provenance declaration')
    for key in ('subject_source_sha256', 'collector_source_sha256', 'verifier_source_sha256', 'author_source_sha256', 'review_record_sha256'):
        if getattr(p, key) is not None:
            digest(getattr(p, key))
    member(p.author_role, AUTHOR_ROLES, 'subject cannot author the sole expectation')
    member(p.derivation, DERIVATIONS, 'subject/model/selector/cleanup derivation forbidden')
    if identity.subject_source_sha256 is not None and p.subject_source_sha256 is not None:
        require(identity.subject_source_sha256 == p.subject_source_sha256, 'declared subject source conflict')
    subject = identity.subject_source_sha256 or p.subject_source_sha256
    if subject is not None:
        for key in ('collector_source_sha256', 'verifier_source_sha256', 'author_source_sha256'):
            if getattr(p, key) is not None:
                require(getattr(p, key) != subject, 'declared subject source reused by ' + key)
    # Distinct hashes only reject declared sameness; they cannot prove independent
    # ancestry, source content, authorship, review timing or actual collection.
    require(type(expectations.vectors) is tuple and len(expectations.vectors) == len(FIELD_SPECS), 'all immutable expected vectors')
    for vector, (vector_id, specs) in zip(expectations.vectors, FIELD_SPECS):
        require(type(vector) is ExpectedVector and type(vector.vector_id) is str and vector.vector_id == vector_id, 'complete ordered vector ID')
        require(type(vector.fields) is tuple and len(vector.fields) == len(specs), 'all immutable expected field slots')
        for row, (field_id, kind) in zip(vector.fields, specs):
            require(type(row) is ExpectedField and type(row.field_id) is str and row.field_id == field_id, 'complete ordered expected field ID')
            field_value(row.value, kind)
    return expectations


def assess(expectations):
    validate(expectations)
    unknown_identity = tuple(key for key in Identity.__dataclass_fields__ if getattr(expectations.identity, key) is None)
    pending_provenance = tuple(key for key in ('subject_source_sha256', 'collector_source_sha256', 'verifier_source_sha256', 'author_source_sha256', 'review_record_sha256') if getattr(expectations.provenance, key) is None)
    if expectations.provenance.author_role == 'unattributed':
        pending_provenance += ('author_role',)
    if expectations.provenance.derivation == 'unknown':
        pending_provenance += ('derivation',)
    pending_expected = tuple((vector.vector_id, row.field_id) for vector in expectations.vectors for row in vector.fields if row.value is None)
    return Assessment(True, unknown_identity, pending_provenance, pending_expected,
                      not (unknown_identity or pending_provenance or pending_expected),
                      False, False, False, 0, 0, False, False)


def mapping(expectations):
    validate(expectations)
    identity = {key: getattr(expectations.identity, key) for key in Identity.__dataclass_fields__}
    provenance = {key: getattr(expectations.provenance, key) for key in Provenance.__dataclass_fields__}
    vectors = [dict(vector_id=v.vector_id, fields=[dict(field_id=r.field_id, value=list(r.value) if type(r.value) is tuple else r.value) for r in v.fields]) for v in expectations.vectors]
    return dict(schema_version=expectations.schema_version, origin=expectations.origin, case_id=expectations.case_id, identity=identity, provenance=provenance, vectors=vectors)


def encode(expectations):
    wire = (json.dumps(mapping(expectations), sort_keys=True, separators=(',', ':'), ensure_ascii=True, allow_nan=False) + '\n').encode('ascii')
    require(len(wire) <= MAX_WIRE_BYTES, 'encoded expectation byte bound')
    return wire


def pairs(items):
    result = {}
    for key, value in items:
        require(key not in result, 'duplicate JSON field')
        result[key] = value
    return result


def nonfinite(value):
    raise ValueError('nonfinite number')


def keys(value, expected):
    require(type(value) is dict and set(value) == set(expected), 'closed exact JSON fields')


def depth_bound(wire):
    depth = 0
    quoted = False
    escaped = False
    for byte in wire:
        if quoted:
            if escaped:
                escaped = False
            elif byte == 92:
                escaped = True
            elif byte == 34:
                quoted = False
        elif byte == 34:
            quoted = True
        elif byte in (91, 123):
            depth += 1
            require(depth <= MAX_DEPTH, 'JSON nesting bound')
        elif byte in (93, 125):
            depth -= 1
            require(depth >= 0, 'invalid JSON depth')


def decode(wire):
    require(type(wire) is bytes and 0 < len(wire) <= MAX_WIRE_BYTES, 'bounded exact wire bytes')
    require(all(byte < 128 for byte in wire), 'canonical ASCII wire')
    depth_bound(wire)
    try:
        value = json.loads(wire.decode('ascii'), object_pairs_hook=pairs, parse_constant=nonfinite)
    except (ValueError, RecursionError) as error:
        raise ValueError('invalid bounded literal expectation JSON') from error
    keys(value, Expectations.__dataclass_fields__)
    keys(value['identity'], Identity.__dataclass_fields__)
    keys(value['provenance'], Provenance.__dataclass_fields__)
    require(type(value['vectors']) is list and len(value['vectors']) == len(FIELD_SPECS), 'all wire expected vectors')
    vectors = []
    for vector, (_, specs) in zip(value['vectors'], FIELD_SPECS):
        keys(vector, ExpectedVector.__dataclass_fields__)
        require(type(vector['fields']) is list and len(vector['fields']) == len(specs), 'all wire expected fields')
        fields = []
        for row, (_, kind) in zip(vector['fields'], specs):
            keys(row, ExpectedField.__dataclass_fields__)
            item = row['value']
            if kind in ('labels', 'statuses') and item is not None:
                require(type(item) is list and len(item) <= MAX_VECTOR_ITEMS, 'bounded wire vector')
                item = tuple(item)
            fields.append(ExpectedField(row['field_id'], item))
        vectors.append(ExpectedVector(vector['vector_id'], tuple(fields)))
    expectations = Expectations(value['schema_version'], value['origin'], value['case_id'], Identity(**value['identity']), Provenance(**value['provenance']), tuple(vectors))
    validate(expectations)
    require(encode(expectations) == wire, 'noncanonical or trailing expectation bytes')
    return expectations


# Accepted351 shape validation and accepted353 pure packet/capture helpers only.
import hashlib

RECOVERY_PACKET_FIELDS = (
    ('forward-latch', 'raw-status-selector-vector',
     ('original-forward-status', 'forward-stopped')),
    ('owned-children-guard', 'writer-child-lifetimes',
     ('owned-child-identities', 'owned-children-quiescent', 'continuous-original-guard')),
    ('recovery-rights-budget', 'time-fence-recovery-budget',
     ('recovery-rights-original-attempt', 'recovery-fence-valid', 'recovery-deadline-ns',
      'recovery-budget-pre-spent', 'recovery-budget-remaining')),
    ('restoration-verification', 'original-restoration-verification',
     ('verified-original-backups', 'original-restoration-state', 'original-full-invariants-verified')),
    ('target-closure-obligations', 'scoped-closure-or-pending',
     ('target-evidence-closed', 'target-control-released',
      'pending-target-obligations', 'pending-owned-obligations')),
)
PACKET_SPECS = tuple((vector_id, group, tuple(spec for spec in FIELD_SPECS[1][1] if spec[0] in field_ids))
                     for vector_id, group, field_ids in RECOVERY_PACKET_FIELDS)
NATIVE_GROUP_IDS = ('subject-source-graph', 'platform-original-authority', 'independent-provenance', 'original-identity-timeline', 'raw-status-selector-vector', 'target-owned-effect-vector', 'writer-child-lifetimes', 'time-fence-recovery-budget', 'original-restoration-verification', 'publication-last-receipt', 'positive-negative-fault-controls', 'scoped-closure-or-pending')
PENDING_NATIVE_RECOVERY_REQUIREMENTS = (
    'authenticated-original-split-rights-no-renewal-or-new-grant',
    'same-original-boot-attempt-source-and-controlled-resource-identity',
    'trusted-clock-deadline-suspend-rollback-and-live-recovery-fence',
    'durable-pre-spend-finite-budget-and-no-replay-after-unknown',
    'complete-native-child-writer-inventory-and-known-quiescence',
    'continuous-original-guard-and-all-writer-exclusion',
    'exact-original-backup-bytes-metadata-presence-and-approved-deltas',
    'safe-restoration-fresh-full-original-invariant-verification',
    'independent-stop-drain-restore-verify-evidence-release-order',
    'original-failure-retention-and-unknown-obligation-artifact-retention',
)
MAX_CAPTURE_BYTES = 67108864
MAX_TOTAL_CAPTURE_BYTES = 134217728
RESTORATION_STATES = ('not-started', 'verified-restored', 'already-original-verified',
                      'unknown', 'partial', 'conflicting')


@dataclass(frozen=True)
class ObservationPacket:
    schema_version: int
    origin: str
    case_id: str
    identity: Identity
    vector_id: str
    fields: tuple


@dataclass(frozen=True)
class CapturedPacket:
    logical_id: str
    evidence_group: str
    declared_state: str
    observation_state: str
    case_id: str
    identity: Identity
    declared_size_bytes: int
    declared_sha256: str
    raw_complete: bool
    raw_sha256: object
    raw_bytes: object


@dataclass(frozen=True)
class FieldComparison:
    field_id: str
    expected: object
    observed: object
    state: str


@dataclass(frozen=True)
class Diagnostic:
    code: str
    subject: str
    severity: str


@dataclass(frozen=True)
class Comparison:
    agreement_state: str
    fields: tuple
    diagnostics: tuple
    captures: tuple
    original_forward_status: object
    original_forward_outcome: str
    pending_target_obligations: object
    pending_owned_obligations: object
    pending_native_groups: tuple
    pending_native_recovery_requirements: tuple
    pending_provenance_fields: tuple
    comparison_performed: bool = True
    forward_failure_cleared: bool = False
    recovery_writes_allowed: bool = False
    target_release_allowed: bool = False
    retry_or_new_grant_allowed: bool = False
    independence_verified: bool = False
    native_oracle_selected: bool = False
    native_conformance: bool = False
    native_cases_run: int = 0
    native_proofs_added: int = 0
    runtime_authority: bool = False


def validate_identity(identity):
    require(type(identity) is Identity, 'exact immutable observation identity')
    member(identity.platform, PLATFORMS, 'explicit observation platform')
    for key in ('platform_version', 'boot_id', 'source_epoch', 'original_attempt', 'test_run_id'):
        value = getattr(identity, key)
        if value is not None:
            label(value)
    if identity.subject_source_sha256 is not None:
        digest(identity.subject_source_sha256)


def validate_packet(packet):
    require(type(packet) is ObservationPacket, 'exact immutable observation packet')
    require(type(packet.schema_version) is int and packet.schema_version == 1, 'observation schema')
    require(packet.origin == 'captured-vector-unverified' and type(packet.origin) is str, 'unverified observation origin')
    member(packet.case_id, CASE_IDS, 'original observation case')
    validate_identity(packet.identity)
    member(packet.vector_id, tuple(row[0] for row in PACKET_SPECS), 'one packet kind')
    specs = next(row[2] for row in PACKET_SPECS if row[0] == packet.vector_id)
    require(type(packet.fields) is tuple and len(packet.fields) == len(specs), 'all immutable packet slots')
    for field, (field_id, kind) in zip(packet.fields, specs):
        require(type(field) is ExpectedField and type(field.field_id) is str and field.field_id == field_id, 'ordered exact packet field')
        field_value(field.value, kind)
    return packet


def encode_packet(packet):
    validate_packet(packet)
    value = dict(schema_version=1, origin=packet.origin, case_id=packet.case_id,
                 identity={key: getattr(packet.identity, key) for key in Identity.__dataclass_fields__},
                 vector_id=packet.vector_id,
                 fields=[dict(field_id=row.field_id, value=list(row.value) if type(row.value) is tuple else row.value) for row in packet.fields])
    wire = (json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True, allow_nan=False) + '\n').encode('ascii')
    require(len(wire) <= MAX_WIRE_BYTES, 'observation wire byte bound')
    return wire


def decode_packet(wire):
    require(type(wire) is bytes and 0 < len(wire) <= MAX_WIRE_BYTES, 'bounded exact observation bytes')
    require(all(byte < 128 for byte in wire), 'ASCII observation wire')
    depth_bound(wire)
    try:
        value = json.loads(wire.decode('ascii'), object_pairs_hook=pairs, parse_constant=nonfinite)
    except (ValueError, RecursionError) as error:
        raise ValueError('invalid observation JSON') from error
    keys(value, ObservationPacket.__dataclass_fields__)
    keys(value['identity'], Identity.__dataclass_fields__)
    member(value['vector_id'], tuple(row[0] for row in PACKET_SPECS), 'known packet kind')
    specs = next(row[2] for row in PACKET_SPECS if row[0] == value['vector_id'])
    require(type(value['fields']) is list and len(value['fields']) == len(specs), 'all observation wire slots')
    fields = []
    for field, (_, kind) in zip(value['fields'], specs):
        keys(field, ExpectedField.__dataclass_fields__)
        literal = field['value']
        if literal is not None and kind in ('labels', 'statuses'):
            require(type(literal) is list, 'wire observation vector array')
            literal = tuple(literal)
        fields.append(ExpectedField(field['field_id'], literal))
    packet = ObservationPacket(value['schema_version'], value['origin'], value['case_id'],
                               Identity(**value['identity']), value['vector_id'], tuple(fields))
    validate_packet(packet)
    require(encode_packet(packet) == wire, 'canonical observation bytes required')
    return packet


def validate_capture(capture, group):
    require(type(capture) is CapturedPacket, 'exact immutable explicit capture projection')
    require(type(capture.logical_id) is str and re.fullmatch(r'[a-z][a-z0-9._-]{0,63}', capture.logical_id, re.ASCII) is not None, 'bounded logical capture ID')
    require(type(capture.evidence_group) is str and capture.evidence_group == group, 'ordered evidence-group binding')
    member(capture.declared_state, ('missing', 'unknown', 'present-unverified', 'conflicting'), 'declared group state')
    member(capture.observation_state, ('missing', 'unknown', 'captured-unverified', 'conflicting'), 'observed raw state')
    member(capture.case_id, CASE_IDS, 'capture original case')
    validate_identity(capture.identity)
    require(type(capture.declared_size_bytes) is int and 0 <= capture.declared_size_bytes <= MAX_CAPTURE_BYTES, 'declared capture byte bound')
    digest(capture.declared_sha256)
    require(type(capture.raw_complete) is bool, 'exact raw completeness flag')
    if capture.raw_sha256 is not None:
        digest(capture.raw_sha256)
    require(capture.raw_bytes is None or type(capture.raw_bytes) is bytes, 'immutable raw bytes or unknown')
    if capture.raw_bytes is not None:
        require(len(capture.raw_bytes) <= capture.declared_size_bytes, 'retained raw bytes within declared cap')
    require(not capture.raw_complete or capture.raw_bytes is not None, 'complete capture has bytes')
    require(capture.raw_complete or capture.raw_sha256 is None, 'partial capture has no complete raw hash')
    if capture.observation_state in ('missing', 'unknown'):
        require(capture.raw_bytes is None and not capture.raw_complete and capture.raw_sha256 is None, 'unavailable capture has no raw evidence')
    if capture.declared_state == 'missing':
        require(capture.observation_state == 'missing', 'missing group cannot declare a captured artifact')





def compare(expectations, captures):
    """Compare declarations only; no outcome, right or recovery action is issued."""
    validate(expectations)
    require(type(captures) is tuple and len(captures) == len(PACKET_SPECS), 'five explicit immutable recovery packet projections')
    for capture, (_, group, _) in zip(captures, PACKET_SPECS):
        validate_capture(capture, group)
    require(len(set(c.logical_id for c in captures)) == len(captures), 'distinct recovery packet IDs')
    require(sum(c.declared_size_bytes for c in captures) <= MAX_TOTAL_CAPTURE_BYTES, 'aggregate declared capture byte bound')
    diagnostics = []
    expected = {row.field_id: row.value for row in expectations.vectors[1].fields}
    observed = {field_id: None for field_id, _ in FIELD_SPECS[1][1]}

    def note(code, subject, severity):
        diagnostics.append(Diagnostic(code, subject, severity))

    def same_identity(identity, case_id, subject):
        if case_id != expectations.case_id:
            note('case-mismatch', subject, 'mismatch')
        for key in Identity.__dataclass_fields__:
            a, b = getattr(expectations.identity, key), getattr(identity, key)
            if a is None or b is None:
                note('identity-pending', subject + '/' + key, 'pending')
            elif a != b:
                note('identity-mismatch', subject + '/' + key, 'mismatch')

    for capture, (vector_id, _, _) in zip(captures, PACKET_SPECS):
        same_identity(capture.identity, capture.case_id, vector_id + '/envelope')
        if capture.declared_state == 'conflicting' or capture.observation_state == 'conflicting':
            note('capture-conflict', vector_id, 'mismatch')
        if capture.declared_state in ('missing', 'unknown') or capture.observation_state in ('missing', 'unknown'):
            note('capture-pending', vector_id, 'pending')
        if not capture.raw_complete:
            note('incomplete-raw-bytes', vector_id, 'pending')
            continue
        actual = hashlib.sha256(capture.raw_bytes).hexdigest()
        if capture.raw_sha256 != actual:
            note('raw-hash-declaration-conflict', vector_id, 'mismatch')
        if capture.declared_sha256 != actual or capture.declared_size_bytes != len(capture.raw_bytes):
            note('descriptor-bytes-conflict', vector_id, 'mismatch')
        try:
            packet = decode_packet(capture.raw_bytes)
        except ValueError:
            note('malformed-observation-packet', vector_id, 'mismatch')
            continue
        if packet.vector_id != vector_id:
            note('packet-group-mismatch', vector_id, 'mismatch')
            continue
        same_identity(packet.identity, packet.case_id, vector_id + '/packet')
        if packet.identity != capture.identity or packet.case_id != capture.case_id:
            note('packet-envelope-identity-conflict', vector_id, 'mismatch')
        for row in packet.fields:
            observed[row.field_id] = row.value

    fields = []
    for field_id, _ in FIELD_SPECS[1][1]:
        a, b = expected[field_id], observed[field_id]
        state = 'pending' if a is None or b is None else ('match' if a == b else 'mismatch')
        fields.append(FieldComparison(field_id, a, b, state))
        if state != 'match':
            note('literal-field-' + state, field_id, state)

    restoration = observed['original-restoration-state']
    if restoration is None or restoration in ('unknown', 'partial', 'not-started'):
        note('original-restoration-pending', 'original-restoration-state', 'pending')
    elif restoration == 'conflicting':
        note('original-restoration-conflict', 'original-restoration-state', 'mismatch')
    elif restoration not in RESTORATION_STATES:
        note('unsupported-restoration-declaration', 'original-restoration-state', 'mismatch')

    writes_claimed = restoration in ('verified-restored', 'partial', 'conflicting')
    verification_claimed = restoration in ('verified-restored', 'already-original-verified')
    evidence_closed = observed['target-evidence-closed'] is True
    released = observed['target-control-released'] is True
    closure_effect_claimed = writes_claimed or verification_claimed or evidence_closed or released

    def need_true(code, field_id):
        value = observed[field_id]
        if value is None:
            note(code, field_id, 'pending')
        elif value is not True:
            note(code, field_id, 'mismatch')

    if closure_effect_claimed:
        for key, code in (('forward-stopped', 'forward-must-remain-stopped'),
                          ('owned-children-quiescent', 'known-child-quiescence-required'),
                          ('continuous-original-guard', 'continuous-original-guard-required')):
            need_true(code, key)
        if observed['owned-child-identities'] is None:
            note('complete-child-inventory-pending', 'owned-child-identities', 'pending')
    if writes_claimed:
        for key, code in (('recovery-rights-original-attempt', 'same-attempt-recovery-rights-required'),
                          ('recovery-fence-valid', 'valid-recovery-fence-required'),
                          ('recovery-budget-pre-spent', 'durable-budget-pre-spend-required')):
            need_true(code, key)
        for key in ('recovery-deadline-ns', 'recovery-budget-remaining'):
            if observed[key] is None:
                note('finite-recovery-declaration-pending', key, 'pending')
        backups = observed['verified-original-backups']
        if backups is None:
            note('exact-original-backups-required', 'verified-original-backups', 'pending')
        elif not backups:
            note('exact-original-backups-required', 'verified-original-backups', 'mismatch')
    if verification_claimed or evidence_closed or released:
        need_true('full-original-invariants-required', 'original-full-invariants-verified')
    if evidence_closed or released:
        if restoration is None:
            note('verified-original-before-closure', 'original-restoration-state', 'pending')
        elif restoration not in ('verified-restored', 'already-original-verified'):
            note('verified-original-before-closure', 'original-restoration-state', 'mismatch')
    if released:
        need_true('target-evidence-before-release', 'target-evidence-closed')
        # These are necessary data consistency checks, not proof of event order,
        # native exclusion, actual rights or permission to release anything.
        for key in ('pending-target-obligations', 'pending-owned-obligations'):
            value = observed[key]
            if value is None:
                note('obligation-inventory-pending-before-release', key, 'pending')
            elif value:
                note('release-with-pending-obligations', key, 'mismatch')
    else:
        note('target-control-closure-pending', 'target-control-released', 'pending')
    for key in ('pending-target-obligations', 'pending-owned-obligations'):
        value = observed[key]
        if value is None or value:
            note('retained-obligations-pending', key, 'pending')

    original_status = observed['original-forward-status']
    outcome = 'unknown' if original_status is None else ('unattempted' if original_status == -1 else ('succeeded' if original_status == 0 else 'failed'))
    if original_status == -1 and (writes_claimed or released):
        note('unattempted-forward-with-restoration-or-release', 'original-forward-status', 'mismatch')
    agreement = 'mismatch' if any(d.severity == 'mismatch' for d in diagnostics) else ('pending' if any(d.severity == 'pending' for d in diagnostics) else 'match')
    return Comparison(agreement, tuple(fields), tuple(diagnostics), captures, original_status, outcome,
                      observed['pending-target-obligations'], observed['pending-owned-obligations'],
                      NATIVE_GROUP_IDS, PENDING_NATIVE_RECOVERY_REQUIREMENTS,
                      assess(expectations).pending_provenance_fields)


if __name__ == '__main__':
    raise SystemExit('Import-only offline recovery comparator; no command execution interface.')
