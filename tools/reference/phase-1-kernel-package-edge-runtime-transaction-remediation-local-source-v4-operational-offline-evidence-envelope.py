#!/usr/bin/env python3
"""Bounded immutable evidence metadata; supplied labels never establish native proof."""
from dataclasses import dataclass
import hashlib
import json
import re

SCHEMA_VERSION = 1
MAX_WIRE_BYTES = 262144
MAX_DEPTH = 12
MAX_ARTIFACTS = 128
MAX_ARTIFACT_BYTES = 67108864
MAX_TOTAL_ARTIFACT_BYTES = 134217728
PLATFORMS = ('Slackware-15.0', 'Slackware-current')
ORIGINS = ('private-fixture', 'captured-data-unverified')
GROUP_IDS = ('subject-source-graph', 'platform-original-authority', 'independent-provenance', 'original-identity-timeline', 'raw-status-selector-vector', 'target-owned-effect-vector', 'writer-child-lifetimes', 'time-fence-recovery-budget', 'original-restoration-verification', 'publication-last-receipt', 'positive-negative-fault-controls', 'scoped-closure-or-pending')
CASE_IDS = ('issuer-authentication', 'durable-consumption', 'single-launch-slot', 'bootstrap-bounds', 'namespace-FDs', 'time-revocation-fence', 'rights-budgets', 'guard-writer-inventory', 'original-backups', 'phase-deltas', 'stage7-binding', 'reference-entry', 'actual-selector', 'raw-status-latch', 'raw-pkglist-pin', 'package-hooks-effects', 'source-archives', 'helper-dependencies', 'child-quiescence', 'retained-restoration', 'original-verification', 'signal-crash-interleavings', 'publication-controls', 'record-last-receipt', 'unknown-publication', 'cross-closure-oracle')
GROUP_STATUSES = ('missing', 'unknown', 'present-unverified', 'conflicting')
PRODUCER_ROLES = ('subject', 'collector', 'verifier', 'expectation-author', 'unattributed')
CAPTURE_STAGES = ('before', 'during', 'after', 'output', 'unspecified')
MEDIA_TYPES = ('application/octet-stream', 'text/plain', 'application/json')
EMPTY_SHA256 = hashlib.sha256(b'').hexdigest()
ID_PATTERN = re.compile(r'[a-z][a-z0-9._-]{0,63}\Z', re.ASCII)
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
class Artifact:
    logical_id: str
    evidence_group: str
    sha256: str
    size_bytes: int
    media_type: str
    producer_role: str
    capture_stage: str


@dataclass(frozen=True)
class Group:
    group_id: str
    status: str
    artifact_ids: tuple


@dataclass(frozen=True)
class Envelope:
    schema_version: int
    origin: str
    case_id: str
    identity: Identity
    artifacts: tuple
    groups: tuple


@dataclass(frozen=True)
class Assessment:
    schema_valid: bool
    all_group_ids: tuple
    groups_without_complete_declared_data: tuple
    declared_artifact_bytes: int
    raw_bytes_verified: bool
    provenance_verified: bool
    native_conformance: bool
    native_cases_run: int
    native_proofs_added: int
    runtime_authority: bool
    comparison_performed: bool


def require(condition, message):
    if not condition:
        raise ValueError(message)


def member(value, allowed, label):
    require(type(value) is str and value in allowed, label)


def bounded_label(value, label):
    if value is None:
        return
    require(type(value) is str and 1 <= len(value) <= 128, label)
    require(value == value.strip() and all(32 <= ord(c) <= 126 for c in value), label)


def digest(value, label):
    require(type(value) is str and SHA_PATTERN.fullmatch(value) is not None, label)


def logical_id(value):
    require(type(value) is str and ID_PATTERN.fullmatch(value) is not None, 'invalid logical artifact ID')


def validate(envelope):
    require(type(envelope) is Envelope, 'exact Envelope required')
    require(type(envelope.schema_version) is int and envelope.schema_version == SCHEMA_VERSION, 'schema version')
    member(envelope.origin, ORIGINS, 'unverified data origin')
    member(envelope.case_id, CASE_IDS, 'original source-bound case ID')
    identity = envelope.identity
    require(type(identity) is Identity, 'exact immutable identity required')
    member(identity.platform, PLATFORMS, 'one explicit platform required')
    for field in ('platform_version', 'boot_id', 'source_epoch', 'original_attempt', 'test_run_id'):
        bounded_label(getattr(identity, field), 'invalid captured identity ' + field)
    if identity.subject_source_sha256 is not None:
        digest(identity.subject_source_sha256, 'invalid declared subject digest')
    require(type(envelope.artifacts) is tuple and len(envelope.artifacts) <= MAX_ARTIFACTS, 'bounded immutable artifact inventory')
    artifacts = {}
    total = 0
    for artifact in envelope.artifacts:
        require(type(artifact) is Artifact, 'exact immutable Artifact required')
        logical_id(artifact.logical_id)
        require(artifact.logical_id not in artifacts, 'duplicate logical artifact ID')
        member(artifact.evidence_group, GROUP_IDS, 'unknown evidence group')
        digest(artifact.sha256, 'invalid declared artifact digest')
        require(type(artifact.size_bytes) is int and 0 <= artifact.size_bytes <= MAX_ARTIFACT_BYTES, 'bounded exact artifact byte count')
        if artifact.size_bytes == 0:
            require(artifact.sha256 == EMPTY_SHA256, 'known empty raw artifact needs empty-byte digest')
        member(artifact.media_type, MEDIA_TYPES, 'data-only media type')
        member(artifact.producer_role, PRODUCER_ROLES, 'declared producer role')
        member(artifact.capture_stage, CAPTURE_STAGES, 'declared capture stage')
        artifacts[artifact.logical_id] = artifact
        total += artifact.size_bytes
    require(total <= MAX_TOTAL_ARTIFACT_BYTES, 'total declared raw byte bound')
    require(type(envelope.groups) is tuple and len(envelope.groups) == len(GROUP_IDS), 'all12 immutable group states required')
    references = []
    for expected, group in zip(GROUP_IDS, envelope.groups):
        require(type(group) is Group and type(group.group_id) is str and group.group_id == expected, 'complete original ordered group IDs')
        member(group.status, GROUP_STATUSES, 'explicit unverified group status')
        require(type(group.artifact_ids) is tuple and len(group.artifact_ids) <= MAX_ARTIFACTS, 'bounded immutable group references')
        for key in group.artifact_ids:
            logical_id(key)
        require(len(set(group.artifact_ids)) == len(group.artifact_ids), 'duplicate group artifact reference')
        if group.status == 'missing':
            require(not group.artifact_ids, 'missing data cannot reference artifacts')
        if group.status in ('present-unverified', 'conflicting'):
            require(bool(group.artifact_ids), 'declared present or conflicting group needs raw artifact reference')
        for key in group.artifact_ids:
            logical_id(key)
            require(key in artifacts, 'dangling raw artifact reference')
            require(artifacts[key].evidence_group == group.group_id, 'foreign group raw reference')
            references.append(key)
    require(len(references) == len(artifacts) and set(references) == set(artifacts), 'every artifact referenced once in its declared group')
    return envelope


def assess(envelope):
    validate(envelope)
    # Even every group marked present remains a declaration, not raw verification,
    # an independent oracle, current authority or an actual completed native case.
    return Assessment(True, GROUP_IDS,
                      tuple(g.group_id for g in envelope.groups if g.status != 'present-unverified'),
                      sum(a.size_bytes for a in envelope.artifacts),
                      False, False, False, 0, 0, False, False)


def mapping(envelope):
    validate(envelope)
    identity = {key: getattr(envelope.identity, key) for key in Identity.__dataclass_fields__}
    artifacts = [{key: getattr(a, key) for key in Artifact.__dataclass_fields__} for a in envelope.artifacts]
    groups = [dict(group_id=g.group_id, status=g.status, artifact_ids=list(g.artifact_ids)) for g in envelope.groups]
    return dict(schema_version=envelope.schema_version, origin=envelope.origin, case_id=envelope.case_id,
                identity=identity, artifacts=artifacts, groups=groups)


def encode(envelope):
    wire = (json.dumps(mapping(envelope), sort_keys=True, separators=(',', ':'), ensure_ascii=True, allow_nan=False) + '\n').encode('ascii')
    require(len(wire) <= MAX_WIRE_BYTES, 'encoded envelope byte bound')
    return wire


def pairs(items):
    value = {}
    for key, item in items:
        require(key not in value, 'duplicate JSON field')
        value[key] = item
    return value


def nonfinite(value):
    raise ValueError('nonfinite JSON number')


def keys(value, expected, label):
    require(type(value) is dict and set(value) == set(expected), 'closed ' + label + ' fields')


def depth_bound(wire):
    # Scan bounded bytes before JSON decoding; braces in strings do not add depth.
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
    require(type(wire) is bytes and 0 < len(wire) <= MAX_WIRE_BYTES, 'bounded exact wire bytes required')
    require(all(b < 128 for b in wire), 'ASCII canonical envelope bytes required')
    depth_bound(wire)
    try:
        value = json.loads(wire.decode('ascii'), object_pairs_hook=pairs, parse_constant=nonfinite)
    except (ValueError, RecursionError) as error:
        raise ValueError('invalid bounded envelope JSON') from error
    keys(value, Envelope.__dataclass_fields__, 'envelope')
    keys(value['identity'], Identity.__dataclass_fields__, 'identity')
    require(type(value['artifacts']) is list and len(value['artifacts']) <= MAX_ARTIFACTS, 'bounded wire artifact inventory')
    require(type(value['groups']) is list and len(value['groups']) == len(GROUP_IDS), 'all12 wire group states required')
    artifacts = []
    for row in value['artifacts']:
        keys(row, Artifact.__dataclass_fields__, 'artifact')
        artifacts.append(Artifact(**row))
    groups = []
    for row in value['groups']:
        keys(row, Group.__dataclass_fields__, 'group')
        require(type(row['artifact_ids']) is list and len(row['artifact_ids']) <= MAX_ARTIFACTS, 'bounded wire references')
        groups.append(Group(row['group_id'], row['status'], tuple(row['artifact_ids'])))
    envelope = Envelope(value['schema_version'], value['origin'], value['case_id'], Identity(**value['identity']), tuple(artifacts), tuple(groups))
    validate(envelope)
    require(encode(envelope) == wire, 'noncanonical or trailing envelope wire')
    return envelope


if __name__ == '__main__':
    raise SystemExit('Import-only evidence metadata schema; no command interface or native execution.')
