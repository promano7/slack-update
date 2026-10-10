#!/usr/bin/env python3
"""Validate the bounded inventory data contract; no filesystem reader or scanner."""
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


def validate_return(confirmed, receipt, policy):
    exact(receipt['schema'], 1, 'receipt schema')
    exact(receipt['step'], 359, 'receipt step')
    exact(receipt['normalization'], 'none-after-transcription', 'receipt representation')
    basis = 'complete-user-message-text-transcribed-as-UTF8-with-final-storage-newline;not-original-terminal-byte-capture'
    exact(receipt['capture_basis'], basis, 'receipt capture basis')
    raw = receipt['text'].encode('utf-8')
    exact(sha(raw), policy['accepted_receipt_sha256'], 'complete pasted message SHA')
    exact(len(raw), policy['accepted_receipt_size_bytes'], 'pasted message size')
    exact(receipt['sha256'], sha(raw), 'declared receipt SHA')
    exact(receipt['size_bytes'], len(raw), 'declared receipt bytes')
    text = receipt['text']
    exact([l for l in text.splitlines() if l.startswith('PASS: ')], policy['expected_ordered359_labels'], 'all43 ordered359 labels')
    exact(text.count('Result: PASS (43 passes, 0 failures)'), 1, 'single43 summary')
    message = policy['accepted_commit_message']
    exact(text.count('[main aedcbc3] ' + message), 1, 'reported exact359 commit')
    exact(text.count('8 files changed, 2747 insertions(+)'), 1, 'exact359 scope')
    exact(re.findall(r'^ create mode 100644 (.+)$', text, re.M), policy['accepted_step359_created_paths'], 'seven exact359 paths')
    exact(text.count('64b63ed..aedcbc3  main -> main'), 1, 'successful359 push')
    head = 'aedcbc3 (HEAD -> main, origin/main, origin/HEAD) ' + message
    exact(text.count(head), 2, 'matching reported heads')
    if not text.endswith(head+'\n'+head+'\npromano@pc-arch ~/Descargas $ \n'):
        raise ValueError('complete reported status and heads ending')
    for marker in ('step359_overlay_application_status\tPASS', 'step359_commit_scope_verification_status\tPASS'):
        if marker not in text:
            raise ValueError('complete overlay/scope verification required')
    for key, value in {
        'schema': 1, 'step': 359, 'commit_prefix': 'aedcbc3', 'commit_full': None,
        'receipt_sha256': sha(raw), 'receipt_size_bytes': len(raw), 'basis': basis,
        'acceptance_result': 'PASS (43 passes, 0 failures)', 'scope': SCOPE,
        'strong_safe_pause': False, 'last_confirmed_strong_safe_pause_step': 358,
        'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent',
        'actual_live_bindings': None, 'runtime_authority': False, 'native_cases_run': 0,
        'native_proofs_added': 0, 'phase1_matrix_complete': False,
        'kernel_package_edge_complete': False, 'production_entry_closed': True, 'phase2_open': False,
        'exact_commit_scope_files': 8, 'exact_commit_scope_insertions': 2747}.items():
        exact(confirmed[key], value, 'confirmed359 ' + key)
    for key in ('user_application_completed', 'user_harness_completed', 'user_commit_and_push_completed',
                'user_worktree_clean', 'user_head_matches_origin'):
        exact(confirmed[key], True, 'reported359 ' + key)
    return True
