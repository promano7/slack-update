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


# Read-only indexing extends the statically copied, byte-bound350 data codec.
# It does not import subject code, expectation generators or model reducers.
import os
import stat

CHUNK_BYTES = 65536
MAX_PATH_CHARS = 4096
MAX_COMPONENT_CHARS = 255


@dataclass(frozen=True)
class SourceLocation:
    logical_id: str
    state: str
    absolute_path: object


@dataclass(frozen=True)
class FileSnapshot:
    device: int
    inode: int
    mode: int
    uid: int
    gid: int
    links: int
    size: int
    mtime_ns: int
    ctime_ns: int


@dataclass(frozen=True)
class ArtifactObservation:
    descriptor: Artifact
    location: SourceLocation
    state: str
    reason: str
    raw_bytes: object
    raw_complete: bool
    raw_sha256: object
    before: object
    after: object
    declared_bytes_match: bool


@dataclass(frozen=True)
class GroupObservation:
    group_id: str
    declared_state: str
    state: str
    artifact_ids: tuple


@dataclass(frozen=True)
class ObservationIndex:
    envelope: Envelope
    artifacts: tuple
    groups: tuple
    retained_raw_bytes: int
    provenance_verified: bool
    native_conformance: bool
    native_cases_run: int
    native_proofs_added: int
    runtime_authority: bool
    comparison_performed: bool


def snapshot(value):
    return FileSnapshot(value.st_dev, value.st_ino, value.st_mode, value.st_uid,
                        value.st_gid, value.st_nlink, value.st_size,
                        value.st_mtime_ns, value.st_ctime_ns)


def path_parts(value):
    require(type(value) is str and 1 < len(value) <= MAX_PATH_CHARS and value.startswith('/'), 'explicit bounded absolute raw path')
    require(all(32 <= ord(c) <= 126 for c in value), 'printable exact raw path')
    parts = value[1:].split('/')
    require(all(part not in ('', '.', '..') and len(part) <= MAX_COMPONENT_CHARS and '\\' not in part for part in parts), 'no ambiguous path components')
    return tuple(parts)


def validate_locations(envelope, locations):
    validate(envelope)
    require(type(locations) is tuple and len(locations) == len(envelope.artifacts), 'one immutable location per declared artifact')
    paths = []
    for descriptor, location in zip(envelope.artifacts, locations):
        require(type(location) is SourceLocation and type(location.logical_id) is str and location.logical_id == descriptor.logical_id, 'exact ordered source location identity')
        member(location.state, ('file', 'missing', 'unknown'), 'explicit source availability declaration')
        if location.state == 'file':
            path_parts(location.absolute_path)
            paths.append(location.absolute_path)
        else:
            require(location.absolute_path is None, 'no path or default lookup for unavailable data')
    require(len(paths) == len(set(paths)), 'one explicit raw path cannot stand for independent logical artifacts')
    return locations


def observation(descriptor, location, state, reason, raw=None, complete=False, before=None, after=None, matched=False):
    # Digest only complete retained bytes; a bounded partial read never receives
    # the misleading label of a full raw artifact digest.
    digest_value = hashlib.sha256(raw).hexdigest() if complete and raw is not None else None
    return ArtifactObservation(descriptor, location, state, reason, raw, complete,
                               digest_value, before, after, matched)


def read_artifact(descriptor, location):
    if location.state != 'file':
        return observation(descriptor, location, location.state, 'explicit-' + location.state)
    parts = path_parts(location.absolute_path)
    require(all(hasattr(os, key) for key in ('O_NOFOLLOW', 'O_DIRECTORY', 'O_NONBLOCK', 'O_CLOEXEC')), 'supported no-follow read-only descriptor primitives required')
    directory_flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC
    file_flags = os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK | os.O_CLOEXEC
    directories = []
    edges = []
    fd = None
    before = None
    raw = None
    buffer = None
    complete = False
    after = None
    try:
        parent = os.open('/', directory_flags)
        directories.append(parent)
        for component in parts[:-1]:
            previous = os.stat(component, dir_fd=parent, follow_symlinks=False)
            require(stat.S_ISDIR(previous.st_mode), 'raw path ancestor must be a real directory, never symlink')
            child = os.open(component, directory_flags, dir_fd=parent)
            directories.append(child)
            current = os.fstat(child)
            require((current.st_dev, current.st_ino) == (previous.st_dev, previous.st_ino), 'directory changed during descriptor binding')
            edges.append((parent, component, current.st_dev, current.st_ino))
            parent = child
        leaf = parts[-1]
        previous = os.stat(leaf, dir_fd=parent, follow_symlinks=False)
        require(stat.S_ISREG(previous.st_mode) and previous.st_nlink == 1, 'raw input must be a regular non-symlink single-link file')
        fd = os.open(leaf, file_flags, dir_fd=parent)
        current = os.fstat(fd)
        require(stat.S_ISREG(current.st_mode) and current.st_nlink == 1, 'opened raw input must remain regular and single-link')
        before = snapshot(current)
        if snapshot(previous) != before:
            return observation(descriptor, location, 'conflicting', 'file-changed-during-open', before=before)
        if before.size > descriptor.size_bytes:
            return observation(descriptor, location, 'conflicting', 'file-exceeds-declared-size-no-read', before=before)
        # Each read is limited by the reviewed descriptor. One surplus byte detects
        # growth and is discarded; retained raw bytes never exceed the total bound.
        buffer = bytearray()
        while len(buffer) <= descriptor.size_bytes:
            chunk = os.read(fd, min(CHUNK_BYTES, descriptor.size_bytes + 1 - len(buffer)))
            if not chunk:
                complete = True
                break
            buffer.extend(chunk)
        raw = bytes(buffer[:descriptor.size_bytes])
        after = snapshot(os.fstat(fd))
        visible = snapshot(os.stat(leaf, dir_fd=parent, follow_symlinks=False))
        ancestors_match = True
        for directory, component, device, inode in edges:
            visible_directory = os.stat(component, dir_fd=directory, follow_symlinks=False)
            if (visible_directory.st_dev, visible_directory.st_ino) != (device, inode):
                ancestors_match = False
        if not complete or before != after or after != visible or not ancestors_match:
            return observation(descriptor, location, 'conflicting', 'file-or-path-changed-during-read', raw, False, before, after)
        actual_digest = hashlib.sha256(raw).hexdigest()
        matches = len(raw) == descriptor.size_bytes and actual_digest == descriptor.sha256
        return observation(descriptor, location, 'captured-unverified' if matches else 'conflicting',
                           'declared-size-and-digest-match' if matches else 'declared-size-or-digest-mismatch',
                           raw, True, before, after, matches)
    except FileNotFoundError:
        # A missing path during a read is a contradiction to the earlier open,
        # whereas absence before any open is only missing data, never no effects.
        return observation(descriptor, location, 'conflicting' if before is not None else 'missing',
                           'path-disappeared-during-read' if before is not None else 'explicit-file-not-found',
                           raw, False, before, after)
    except OSError:
        if buffer is not None:
            raw = bytes(buffer[:descriptor.size_bytes])
        return observation(descriptor, location, 'conflicting' if before is not None else 'unknown',
                           'read-failed-after-binding' if before is not None else 'raw-file-unavailable',
                           raw, False, before, after)
    finally:
        if fd is not None:
            os.close(fd)
        for directory in reversed(directories):
            os.close(directory)


def ingest(envelope_wire, locations):
    envelope = decode(envelope_wire)
    validate_locations(envelope, locations)
    artifacts = tuple(read_artifact(descriptor, location) for descriptor, location in zip(envelope.artifacts, locations))
    observations = {row.descriptor.logical_id: row for row in artifacts}
    groups = []
    for declared in envelope.groups:
        states = tuple(observations[key].state for key in declared.artifact_ids)
        if declared.status == 'conflicting' or 'conflicting' in states:
            effective = 'conflicting'
        elif declared.status == 'missing':
            effective = 'missing'
        elif declared.status == 'unknown' or 'unknown' in states:
            effective = 'unknown'
        elif states and all(state == 'captured-unverified' for state in states):
            effective = 'captured-unverified'
        elif states and all(state == 'missing' for state in states):
            effective = 'missing'
        else:
            effective = 'unknown'
        groups.append(GroupObservation(declared.group_id, declared.status, effective, declared.artifact_ids))
    retained = sum(len(row.raw_bytes) for row in artifacts if row.raw_bytes is not None)
    require(retained <= MAX_TOTAL_ARTIFACT_BYTES, 'retained raw byte bound')
    return ObservationIndex(envelope, artifacts, tuple(groups), retained, False, False, 0, 0, False, False)


if __name__ == '__main__':
    raise SystemExit('Import-only read-only observation index; no collector, comparator or native execution.')
