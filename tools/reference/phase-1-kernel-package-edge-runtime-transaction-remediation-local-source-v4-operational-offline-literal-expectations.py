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


if __name__ == '__main__':
    raise SystemExit('Import-only literal expectation contract; no generator, comparator or native execution.')
