#!/usr/bin/env python3
"""Inspect bound repository source bytes without executing their contents."""
import hashlib
import json
import re

SCOPE = 'repository-source-inventory-and-roadmap-workstream359-368-only'
SEMANTIC_STATUS = 'lexical-candidate-context-and-runtime-relation-unresolved'
REQUIRED_UNRESOLVED = (
    'shell-context-call-and-control-flow', 'external-installed-versioned-graph',
    'dynamic-writer-object-alias-lifetimes', 'native-platform-primitives',
    'independent-two-platform-conformance')
LIMITS = {
    'max_sources': 32, 'max_path_ascii_bytes': 240, 'max_source_bytes': 1048576,
    'max_total_source_bytes': 8388608, 'max_lines_per_source': 50000,
    'max_total_lines': 100000, 'max_line_bytes_including_terminator': 8192,
    'max_hint_records_per_source': 20000, 'max_total_hint_records': 40000,
    'max_snippet_utf8_bytes': 512}
REPORT_BOUNDARIES = {
    'execution_authorized': False, 'native_graph_complete': False,
    'actual_native_binding': None, 'actual_installed_dependency_versions': None,
    'actual_host_state': 'unobserved-not-claimed-absent', 'runtime_authority': False,
    'native_cases_run': 0, 'native_proofs_added': 0, 'operational_conformance': False,
    'operational_readiness': False, 'phase1_matrix_complete': False,
    'kernel_package_edge_complete': False, 'production_entry_closed': True, 'phase2_open': False}


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical_sha(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8'))


def exact(value, expected, label):
    if type(value) is not type(expected):
        raise ValueError(label)
    if isinstance(value, (set, bytes, type)):
        same = value == expected
    else:
        same = json.dumps(value, sort_keys=True) == json.dumps(expected, sort_keys=True)
    if not same:
        raise ValueError(label)


def integer(value, lower, upper, label):
    if type(value) is not int or not lower <= value <= upper:
        raise ValueError(label)


def validate_path(path, maximum=240):
    if type(path) is not str or not path or len(path.encode('utf-8')) > maximum:
        raise ValueError('bounded relative source path required')
    if not path.isascii() or path.startswith('/') or '\\' in path:
        raise ValueError('relative ASCII POSIX path required')
    if any(ord(c) < 32 or ord(c) == 127 for c in path):
        raise ValueError('control character in path')
    if any(component in ('', '.', '..') for component in path.split('/')):
        raise ValueError('unsafe path component')
    return True


def physical_lines(raw):
    """LF defines a physical line; a preceding CR remains part of the raw bytes."""
    if not raw:
        return []
    parts = raw.split(b'\n')
    rows = [part + b'\n' for part in parts[:-1]]
    if parts[-1]:
        rows.append(parts[-1])
    return rows


def snippet_prefix(line, maximum):
    text = line.decode('utf-8', errors='strict')
    prefix = bytearray()
    for char in text:
        encoded = char.encode('utf-8')
        if len(prefix) + len(encoded) > maximum:
            break
        prefix.extend(encoded)
    return prefix.decode('utf-8'), len(prefix) < len(line)


def validate_source_bytes(raw, limits):
    if type(raw) is not bytes or b'\0' in raw:
        raise ValueError('UTF8 source bytes without NUL required')
    integer(len(raw), 1, limits['max_source_bytes'], 'source byte limit')
    raw.decode('utf-8', errors='strict')
    lines = physical_lines(raw)
    integer(len(lines), 1, limits['max_lines_per_source'], 'source line count')
    if any(len(line) > limits['max_line_bytes_including_terminator'] for line in lines):
        raise ValueError('source line byte limit')
    return lines


def validate_bundle(roots, source_bytes, approved_roots, limits):
    exact(roots, approved_roots, 'explicit approved review roots only')
    integer(len(roots), 1, limits['max_sources'], 'source count limit')
    exact(set(source_bytes), {row['path'] for row in roots}, 'exact source byte inputs')
    if len({row['path'] for row in roots}) != len(roots):
        raise ValueError('duplicate source roots')
    total_bytes = total_lines = 0
    for row in roots:
        validate_path(row['path'], limits['max_path_ascii_bytes'])
        exact(row['review_selection_only'], True, 'review role only')
        exact(row['execution_authorized'], False, 'no source execution')
        exact(row['actual_native_binding'], None, 'no native source binding')
        raw = source_bytes[row['path']]
        lines = validate_source_bytes(raw, limits)
        exact(row['size_bytes'], len(raw), 'observed source size')
        exact(row['sha256'], sha(raw), 'observed source hash')
        total_bytes += len(raw); total_lines += len(lines)
    integer(total_bytes, 1, limits['max_total_source_bytes'], 'total byte limit')
    integer(total_lines, 1, limits['max_total_lines'], 'total line limit')
    return True


def validate_contract(contract, policy):
    exact(contract['schema'], 1, 'schema')
    exact(contract['step'], 360, 'contract step')
    exact(contract['scope'], SCOPE, 'contract scope')
    exact(contract['contract_version'], 'bounded-lexical-source-inventory-v1', 'contract version')
    exact(contract['state'], 'design-only-reader-and-inventory-implementation-pending361', 'reader not implemented')
    exact(contract['limits'], LIMITS, 'exact reviewed resource limits')
    exact(contract['report_boundaries'], REPORT_BOUNDARIES, 'repository report boundaries')
    exact(contract['required_unresolved_relation_categories'], list(REQUIRED_UNRESOLVED), 'mandatory unresolved native relations')
    exact(contract['implementation_due_step'], 361, 'reader due361')
    exact(contract['readme_reconciliation_step'], 367, 'README retained')
    exact(contract['conditional_pause_step'], 368, 'pause retained')
    exact(contract['new_live_binding_or_native_component_selected'], False, 'no component selected')
    exact(len(contract['required_controls361']), 18, 'eighteen future control families')
    exact(canonical_sha(contract), policy['contract_canonical_sha256'], 'full reviewed contract binding')
    return True


def source_view(raw, limits):
    lines = validate_source_bytes(raw, limits)
    offsets = []
    position = 0
    for line in lines:
        offsets.append(position)
        position += len(line)
    return {'sha256': sha(raw), 'lines': lines, 'offsets': offsets, 'line_checks': {}}


def validate_anchor_view(anchor, views, contract):
    exact(set(anchor), set(contract['anchor_fields']), 'closed source anchor')
    validate_path(anchor['path'], contract['limits']['max_path_ascii_bytes'])
    view = views[anchor['path']]
    lines = view['lines']
    exact(anchor['source_sha256'], view['sha256'], 'anchor source SHA')
    integer(anchor['line_number'], 1, len(lines), 'one-based anchor line')
    index = anchor['line_number'] - 1
    line = lines[index]
    exact(anchor['line_start_byte'], view['offsets'][index], 'zero-based byte offset')
    exact(anchor['line_length_bytes'], len(line), 'full raw line length')
    if index not in view['line_checks']:
        text, short = snippet_prefix(line, contract['limits']['max_snippet_utf8_bytes'])
        view['line_checks'][index] = (sha(line), text, short)
    digest, text, short = view['line_checks'][index]
    exact(anchor['raw_line_sha256'], digest, 'full raw line SHA')
    exact(anchor['snippet'], text, 'exact bounded UTF8 prefix')
    exact(anchor['snippet_truncated'], short, 'explicit short snippet flag')
    if anchor['kind'] not in contract['hint_kinds']:
        raise ValueError('undeclared lexical kind')
    exact(anchor['semantic_status'], SEMANTIC_STATUS, 'lexical uncertainty required')
    return True


def validate_anchor(anchor, source_bytes, contract):
    raw = source_bytes[anchor['path']]
    return validate_anchor_view(anchor, {anchor['path']: source_view(raw, contract['limits'])}, contract)


def validate_report_design(report, source_bytes, approved_roots, contract):
    """Check a data example; this function does not attest reader execution."""
    exact(set(report), set(contract['report_required_fields']), 'closed report fields')
    exact(report['schema'], 1, 'report schema')
    exact(report['scope'], SCOPE, 'report scope')
    exact(report['boundaries'], REPORT_BOUNDARIES, 'no native completeness or authority')
    exact(report['coverage'], {
        'kind': 'bounded-textual-hints-only', 'shell_parsed': False,
        'runtime_relations_verified': False, 'absence_of_effects_proven': False}, 'lexical coverage only')
    exact(report['unresolved_relations'], list(REQUIRED_UNRESOLVED), 'native unknowns cannot disappear')
    validate_bundle(report['review_sources'], source_bytes, approved_roots, contract['limits'])
    records = report['hint_records']
    if type(records) is not list:
        raise ValueError('hint record list required')
    integer(len(records), 0, contract['limits']['max_total_hint_records'], 'total record limit')
    per_source = {}
    root_order = {row['path']: i for i, row in enumerate(approved_roots)}
    kind_order = {kind: i for i, kind in enumerate(contract['hint_kinds'])}
    views = {path: source_view(raw, contract['limits']) for path, raw in source_bytes.items()}
    order = []
    for anchor in records:
        validate_anchor_view(anchor, views, contract)
        path = anchor['path']
        per_source[path] = per_source.get(path, 0) + 1
        integer(per_source[path], 1, contract['limits']['max_hint_records_per_source'], 'per-source record limit')
        order.append((root_order[path], anchor['line_number'], kind_order[anchor['kind']]))
    exact(order, sorted(order), 'stable hint source-line-kind ordering')
    return True


# Exact frozen360 data rules are statically copied above; source programs are never imported.
METADATA_BINDINGS = [{'path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-operational-bounded-source-inventory-contract-contract.json', 'sha256': '673c5a2a3c0cb146a42aa8ee0de1679f04730863e049062df6e2c4eae74496a0', 'size_bytes': 6539, 'role': 'frozen-inventory-contract-metadata-not-native-source', 'review_selection_only': True, 'execution_authorized': False, 'actual_native_binding': None}, {'path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-operational-bounded-source-inventory-contract-policy.json', 'sha256': '6c4c101a487e48ececf4309062940b735dbdbe7b70817da4d52184b900b18436', 'size_bytes': 398231, 'role': 'frozen-inventory-contract-metadata-not-native-source', 'review_selection_only': True, 'execution_authorized': False, 'actual_native_binding': None}]
import argparse
import os
import stat
import sys


def required_open_flags():
    names = ('O_RDONLY', 'O_DIRECTORY', 'O_NOFOLLOW', 'O_NONBLOCK', 'O_CLOEXEC')
    if any(not hasattr(os, name) for name in names):
        raise ValueError('required directory/no-follow/nonblocking open flags unavailable')
    return {name: getattr(os, name) for name in names}


def open_repository_root(path):
    if type(path) is not str or not path.startswith('/') or path != os.path.abspath(path):
        raise ValueError('explicit canonical absolute repository root required')
    components = path.split('/')[1:]
    if path != '/' and any(component in ('', '.', '..') for component in components):
        raise ValueError('unsafe repository root component')
    flags = required_open_flags()
    mode = flags['O_RDONLY'] | flags['O_DIRECTORY'] | flags['O_NOFOLLOW'] | flags['O_CLOEXEC']
    current = os.open('/', mode)
    try:
        for component in components if path != '/' else []:
            following = os.open(component, mode, dir_fd=current)
            os.close(current)
            current = following
        return current
    except BaseException:
        os.close(current)
        raise


def source_parent(root_fd, path, limits):
    validate_path(path, limits['max_path_ascii_bytes'])
    flags = required_open_flags()
    mode = flags['O_RDONLY'] | flags['O_DIRECTORY'] | flags['O_NOFOLLOW'] | flags['O_CLOEXEC']
    parts = path.split('/')
    current = os.dup(root_fd)
    try:
        for component in parts[:-1]:
            following = os.open(component, mode, dir_fd=current)
            os.close(current)
            current = following
        return current, parts[-1]
    except BaseException:
        os.close(current)
        raise


def stat_identity(value):
    return (value.st_dev, value.st_ino, value.st_size, value.st_mtime_ns, value.st_ctime_ns)


def validate_descriptor(row, limits):
    exact(set(row), {'path', 'sha256', 'size_bytes', 'role', 'review_selection_only',
                     'execution_authorized', 'actual_native_binding'}, 'closed source descriptor')
    validate_path(row['path'], limits['max_path_ascii_bytes'])
    integer(row['size_bytes'], 1, limits['max_source_bytes'], 'declared source byte limit')
    if type(row['sha256']) is not str or not re.fullmatch('[0-9a-f]{64}', row['sha256']):
        raise ValueError('lowercase SHA256 declaration required')
    if type(row['role']) is not str or not row['role'] or len(row['role']) > 240:
        raise ValueError('bounded explicit review role required')
    exact(row['review_selection_only'], True, 'review selection only')
    exact(row['execution_authorized'], False, 'source execution forbidden')
    exact(row['actual_native_binding'], None, 'native binding forbidden')


def read_bound_source(root_fd, row, limits):
    """Read one exact repository file; an open FD is not a native lifetime fence."""
    validate_descriptor(row, limits)
    parent, leaf = source_parent(root_fd, row['path'], limits)
    file_fd = None
    try:
        prior_path = os.stat(leaf, dir_fd=parent, follow_symlinks=False)
        if not stat.S_ISREG(prior_path.st_mode):
            raise ValueError('nonregular or symlink source refused before opening content')
        exact(prior_path.st_size, row['size_bytes'], 'pre-read source size')
        flags = required_open_flags()
        mode = flags['O_RDONLY'] | flags['O_NOFOLLOW'] | flags['O_NONBLOCK'] | flags['O_CLOEXEC']
        file_fd = os.open(leaf, mode, dir_fd=parent)
        before = os.fstat(file_fd)
        if not stat.S_ISREG(before.st_mode):
            raise ValueError('opened source is not regular')
        exact(stat_identity(before), stat_identity(prior_path), 'source path/open identity drift')
        remaining = row['size_bytes'] + 1
        raw = bytearray()
        while remaining:
            part = os.read(file_fd, min(65536, remaining))
            if not part:
                break
            raw.extend(part)
            remaining -= len(part)
        after = os.fstat(file_fd)
        after_path = os.stat(leaf, dir_fd=parent, follow_symlinks=False)
        if not stat.S_ISREG(after_path.st_mode):
            raise ValueError('source path rebound to nonregular object')
        exact(stat_identity(after), stat_identity(before), 'read-window source metadata drift')
        exact(stat_identity(after_path), stat_identity(before), 'read-window source path drift')
        raw = bytes(raw)
        exact(len(raw), row['size_bytes'], 'observed exact source size')
        exact(sha(raw), row['sha256'], 'observed exact source SHA')
        validate_source_bytes(raw, limits)
        return raw
    finally:
        if file_fd is not None:
            os.close(file_fd)
        os.close(parent)


def read_source_bundle(root_path, requested, approved, limits):
    exact(requested, approved, 'requested roots must equal explicitly reviewed selection')
    integer(len(requested), 1, limits['max_sources'], 'source count limit')
    if len({row['path'] for row in requested}) != len(requested):
        raise ValueError('duplicate source roots')
    for row in requested:
        validate_descriptor(row, limits)
    integer(sum(row['size_bytes'] for row in requested), 1,
            limits['max_total_source_bytes'], 'declared total byte budget')
    root_fd = open_repository_root(root_path)
    source_bytes = {}
    total_lines = 0
    try:
        for row in requested:
            raw = read_bound_source(root_fd, row, limits)
            total_lines += len(physical_lines(raw))
            integer(total_lines, 1, limits['max_total_lines'], 'total source line limit')
            source_bytes[row['path']] = raw
    finally:
        os.close(root_fd)
    validate_bundle(requested, source_bytes, approved, limits)
    return source_bytes


# Patterns identify text only. A match in a comment, payload or here-document is unresolved.
HINT_PATTERNS = (
    ('function-definition-hint', r'^[ \t]*(?:function[ \t]+)?[A-Za-z_][A-Za-z0-9_]*[ \t]*(?:\(\)[ \t]*\{|[ \t]+\{)'),
    ('source-eval-exec-hint', r'\b(?:source|eval|exec)\b|(?:^|[; \t])\.[ \t]+'),
    ('command-substitution-hint', r'\$\(|`'),
    ('pipeline-redirection-hint', r'[|<>]'),
    ('here-document-hint', r'<<'),
    ('command-name-hint', r'^[ \t]*(?:[A-Za-z_][A-Za-z0-9_.+-]*|/[A-Za-z0-9_./+-]+)'),
    ('generated-payload-marker-hint', r'base64|(?:BEGIN|END)[A-Za-z0-9_]*?(?:EMBEDDED|PAYLOAD)|__EMBEDDED'),
    ('dynamic-command-hint', r'\$\{?[A-Za-z_][A-Za-z0-9_]*'),
    ('trap-process-hint', r'\b(?:trap|kill|wait|unshare|setsid|nohup)\b|(?:^|[^&])&(?:[^&]|$)'))
COMPILED_HINTS = tuple((kind, re.compile(pattern)) for kind, pattern in HINT_PATTERNS)


def lexical_records(approved, source_bytes, contract):
    validate_bundle(approved, source_bytes, approved, contract['limits'])
    exact([kind for kind, _ in HINT_PATTERNS], contract['hint_kinds'], 'declared lexical kind order')
    records = []
    for row in approved:
        raw = source_bytes[row['path']]
        lines = physical_lines(raw)
        offset = count = 0
        for number, line in enumerate(lines, 1):
            text = line.decode('utf-8', errors='strict')
            matches = [kind for kind, pattern in COMPILED_HINTS if pattern.search(text)]
            if matches:
                snippet, short = snippet_prefix(line, contract['limits']['max_snippet_utf8_bytes'])
                digest = sha(line)
                for kind in matches:
                    count += 1
                    integer(count, 1, contract['limits']['max_hint_records_per_source'], 'source record budget')
                    integer(len(records) + 1, 1, contract['limits']['max_total_hint_records'], 'total record budget')
                    records.append({'path': row['path'], 'source_sha256': row['sha256'],
                        'line_number': number, 'line_start_byte': offset, 'line_length_bytes': len(line),
                        'raw_line_sha256': digest, 'snippet': snippet, 'snippet_truncated': short,
                        'kind': kind, 'semantic_status': SEMANTIC_STATUS})
            offset += len(line)
    return records


def inventory_report(root_path, approved, contract):
    """Return a complete lexical report or raise; source contents are never programs here."""
    raw = read_source_bundle(root_path, approved, approved, contract['limits'])
    report = {'schema': 1, 'scope': SCOPE, 'review_sources': approved,
        'hint_records': lexical_records(approved, raw, contract),
        'unresolved_relations': list(REQUIRED_UNRESOLVED),
        'coverage': {'kind': 'bounded-textual-hints-only', 'shell_parsed': False,
                     'runtime_relations_verified': False, 'absence_of_effects_proven': False},
        'boundaries': dict(REPORT_BOUNDARIES)}
    validate_report_design(report, raw, approved, contract)
    return report


def load_frozen_metadata(root_path):
    root_fd = open_repository_root(root_path)
    try:
        values = [json.loads(read_bound_source(root_fd, row, LIMITS)) for row in METADATA_BINDINGS]
    finally:
        os.close(root_fd)
    contract, policy = values
    validate_contract(contract, policy)
    return contract, policy['source_roots']


def main(argv=None):
    parser = argparse.ArgumentParser(description='Read exact reviewed source bytes; never execute inspected content.')
    parser.add_argument('--inspect-repository', required=True, metavar='ABSOLUTE_ROOT')
    args = parser.parse_args(argv)
    try:
        contract, approved = load_frozen_metadata(args.inspect_repository)
        report = inventory_report(args.inspect_repository, approved, contract)
        output = json.dumps(report, indent=2, sort_keys=True, ensure_ascii=False) + '\n'
    except (OSError, ValueError, TypeError, KeyError) as error:
        print('ERROR: ' + str(error), file=sys.stderr)
        return 1
    sys.stdout.write(output)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
