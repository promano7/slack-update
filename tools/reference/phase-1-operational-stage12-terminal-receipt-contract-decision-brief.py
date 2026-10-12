#!/usr/bin/env python3
"""Review inactive whole-stage12 and terminal receipt proposals from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = '19d8e5ecf8d065e671b713cea4ab85bcdda175aed69f039db4510115b28d6882'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())

def exact(value, expected, label):
    if type(value) is not type(expected) or canonical(value) != canonical(expected):
        raise ValueError(label)
    return True

def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored394 policy substitution')

def validate_inputs(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole source register')
    exact(sorted(inputs), sorted(sources['inputs']), 'all55 original input keys')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole original input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole original JSON ' + key)
    frozen = json.loads(inputs['freeze388'])
    inherited = {key: row['path'] for key, row in sources['inputs'].items() if key in frozen['frozen_inputs']['paths']}
    exact(inherited, frozen['frozen_inputs']['paths'], 'all40 original normative references')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'four inert fifteen reviewer and README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole source root ' + row['path'])
    return True

def validate_baseline(blobs, baseline, addition, policy):
    validate_policy(policy)
    exact(canonical(baseline), policy['fixture_canonical_sha256']['baseline'], 'whole accepted393 baseline manifest')
    exact(sorted(blobs), sorted(baseline), 'all2074 original repository paths')
    exact(sha(addition), policy['changelog_addition_sha256'], 'exact additive394 CHANGELOG prefix')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path == 'CHANGELOG.md':
            if not raw.startswith(addition):
                raise ValueError('missing394 CHANGELOG prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'whole accepted393 bytes ' + path)
    return True

def validate_entry(entry, policy):
    validate_policy(policy)
    exact(canonical(entry), policy['fixture_canonical_sha256']['entry393'], 'whole accepted393 receipt and confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['predecessor_receipt_sha256'], 'unchanged uploaded393 bytes')
    exact(len(raw), policy['predecessor_receipt_size_bytes'], 'complete393 receipt size')
    text = entry['receipt']['text']
    exact([line for line in text.splitlines() if line.startswith('PASS: ')], policy['required_predecessor_PASS_labels'], 'all382 ordered393 labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', text, re.M), policy['required_predecessor_create_paths'], 'eight exact393 create paths')
    for marker in ['step393_overlay_application_status\tPASS', 'step393_commit_scope_verification_status\tPASS',
                   'Result: PASS (382 passes, 0 failures)', '[main 17db6be] Phase 1 step 393: document baseline storage and finite rights options',
                   ' 9 files changed, 6662 insertions(+)', '   63c8c5c..17db6be  main -> main\n']:
        exact(text.count(marker), 1, 'single393 marker ' + marker)
    exact(text.split('   63c8c5c..17db6be  main -> main\n')[1], policy['expected_predecessor_tail'], 'clean matching reported393 heads')
    return True

def pointer(value, path):
    for encoded in path.lstrip('/').split('/'):
        key = encoded.replace('~1', '/').replace('~0', '~')
        if type(value) is list:
            if not re.fullmatch(r'0|[1-9][0-9]*', key) or int(key) >= len(value):
                raise ValueError('invalid list pointer')
            value = value[int(key)]
        else:
            value = value[key]
    return value

def declared_cycle(graph):
    nodes = graph['nodes']
    if type(nodes) is not list or not nodes or len(set(nodes)) != len(nodes):
        raise ValueError('invalid declared nodes')
    outgoing = {node: [] for node in nodes}
    incoming = {node: 0 for node in nodes}
    for edge in graph['edges']:
        if type(edge) is not list or len(edge) != 2 or any(node not in incoming for node in edge):
            raise ValueError('invalid declared edge')
        outgoing[edge[0]].append(edge[1])
        incoming[edge[1]] += 1
    ready = [node for node in nodes if incoming[node] == 0]
    visited = 0
    while ready:
        node = ready.pop()
        visited += 1
        for target in outgoing[node]:
            incoming[target] -= 1
            if incoming[target] == 0:
                ready.append(target)
    return visited != len(nodes)

def validate_fixtures(entry, baseline, brief, sources, policy):
    validate_policy(policy)
    for name, value in [('entry393', entry), ('baseline', baseline), ('brief', brief), ('sources', sources)]:
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole394 fixture ' + name)
    return True

def validate_brief_shape(brief, inputs, sources, policy):
    """Check inactive proposals, exact originals and conditional policy witnesses."""
    validate_policy(policy)
    plan = json.loads(inputs['plan389'])
    original = json.loads(inputs['accepted384dossier'])
    exact(brief['schema'], 1, 'integer schema')
    exact(brief['step'], 394, 'integer394 step')
    exact(brief['primary_conflict_ids'], ['whole-stage12-final-receipt-causality'], 'whole original stage12 conflict')
    exact(brief['whole_original_receipt_review'], original, 'WHOLE unchanged384 causal actor event custody review')
    for key, path, field in [('publication_requirements316', '/immutable_design_facts/stages/12', 'original316_whole_stage12'), ('original325', '/publication_contract', 'original325_publication_contract'), ('original327', '/crossclosure_contract', 'original327_crossclosure_contract')]:
        exact(pointer(json.loads(inputs[key]), path), original[field], 'WHOLE actual original clause '+key)
    for field, key in policy['whole_reference_fields'].items():
        exact(brief[field], sources['inputs'][key], 'whole reference ' + key)
    for key in ['writer_brief390', 'revocation_brief391', 'loss_brief392', 'storage_brief393']:
        prior = json.loads(inputs[key])
        exact(prior['selected_option'], None, 'prior proposal still unselected')
        exact(prior['approved_contract_migration'], None, 'prior migration still inactive')
    exact(brief['boundaries'], plan['boundaries'], 'every original closed boundary')
    for key in ['selected_option', 'approved_contract_migration', 'actual_stage12_event_set', 'actual_collector', 'actual_receipt_writer', 'actual_receipt_payload_cut', 'actual_final_observer', 'actual_custody_endpoint']:
        exact(brief[key], None, 'inactive or unknown ' + key)
    for key in ['native_authority', 'source_documentation_is_native_proof', 'universal_impossibility_proven', 'current_step_strong_safe_pause']:
        exact(brief[key], False, 'no promotion ' + key)
    for key in ['new_native_proofs', 'new_native_cases']:
        exact(brief[key], 0, 'no native progress')
    exact(brief['whole_original_requirements_remain_normative'], True, 'full original contracts remain binding')
    exact(brief['conditional_close_step'], 398, 'finite close398')
    exact(brief['next_preparable_step_after_complete394_acceptance'], 395, 'actual394 acceptance before395')
    cut = brief['proposed_terminal_cut']
    exact(cut['option_id'], 'explicit-producer-and-external-finalization-cut', 'amendment-only cut')
    exact(cut['graph_id'], 'proposed-producer-external-cut-only', 'declared cut graph')
    exact(canonical(cut['event_rows']), policy['expected_event_rows_canonical_sha256'], 'ten exact inactive proposed event rows')
    for key in ['changes_original_stage_membership', 'all_original_observer_effects_require_review']:
        exact(cut[key], True, 'explicit amendment and full observer controls '+key)
    for key in ['current_original_stage12_equivalent', 'normative_migration_applied', 'receipt_payload_self_completion_claimed', 'atomic_pair_claimed', 'observer_controls_waived', 'unbounded_self_receipt_chain_required', 'native_complete_accounting_proven']:
        exact(cut[key], False, 'no terminal/native promotion '+key)
    exact(cut['actual_terminal_boundary'], None, 'actual terminal boundary unknown')
    graphs = brief['declared_graph_questions']
    exact([g['id'] for g in graphs], policy['expected_graph_ids'], 'two declared graph identities')
    exact([g['expected_cycle'] for g in graphs], policy['expected_graph_cycles'], 'declared cycle expectations')
    for graph in graphs:
        exact(declared_cycle(graph), graph['expected_cycle'], 'finite authored dependency cycle only')
        exact(graph['actual_native_graph'], None, 'no actual native graph')
        for key in ['original_stage12_reconciled', 'native_proof', 'current_authority']:
            exact(graph[key], False, 'no graph promotion '+key)
    exact(graphs[0]['nodes'], ['payload-bound', 'same-payload-final-completion'], 'whole strict self-observation model')
    exact(graphs[0]['edges'], [['payload-bound', 'same-payload-final-completion'], ['same-payload-final-completion', 'payload-bound']], 'whole strict self-observation dependencies')
    exact(graphs[1]['nodes'], [r['event_id'] for r in cut['event_rows']], 'ten proposed graph events')
    expected_edges = [['captured-target-closed-data', 'archive-commit-known'], ['archive-commit-known', 'sidecar-commit-known'], ['sidecar-commit-known', 'subject-trace-closed'], ['subject-trace-closed', 'receipt-payload-bound'], ['receipt-payload-bound', 'receipt-commit-known'], ['receipt-commit-known', 'final-observation-known'], ['receipt-commit-known', 'custody-handoff-known'], ['final-observation-known', 'external-outcomes-accounted'], ['custody-handoff-known', 'external-outcomes-accounted'], ['external-outcomes-accounted', 'terminal-acceptance-cut']]
    exact(graphs[1]['edges'], expected_edges, 'ten complete proposed dependencies; no native inference')
    options = brief['options']
    exact([o['id'] for o in options], policy['expected_option_ids'], 'four explicit original alternatives')
    exact([o['disposition'] for o in options], policy['expected_dispositions'], 'retention explicit amendment custody hypothesis and deferral')
    ids = [r['id'] for r in plan['whole_original_conflicts']]
    for opt in options:
        exact(sorted(opt), sorted(plan['proposal_rules']['required_option_fields']), 'complete option fields')
        exact([[r['input_key'], r['json_pointer']] for r in opt['exact_current_clause_bindings']], policy['expected_clause_pairs'], 'all ten whole current clause bindings')
        for row in opt['exact_current_clause_bindings']:
            exact(row['path'], sources['inputs'][row['input_key']]['path'], 'bound original path')
            exact(row['whole_current_value'], pointer(json.loads(inputs[row['input_key']]), row['json_pointer']), 'WHOLE current clause')
        for key in ['guarantees_retained', 'trust_assumptions', 'effect_and_failure_boundaries', 'residual_native_unknowns', 'independent_evidence_required']:
            if type(opt[key]) is not list or not opt[key] or not all(type(x) is str and x.strip() for x in opt[key]):
                raise ValueError('missing concrete field ' + key)
        exact(opt['dependencies_and_incompatibilities'], ids, 'all eight conflict dependencies')
        exact(opt['explicit_user_decision_required'], True, 'separate explicit decision')
        exact(opt['implementation_selected'], False, 'no implementation selected')
        exact(opt['runtime_authority'], False, 'no runtime grant')
        exact([r['platform'] for r in opt['platform_rows']], plan['proposal_rules']['platforms'], 'separate actual platform scopes')
        for row in opt['platform_rows']:
            for key in ['installed_versions', 'support', 'actual_composition', 'native_evidence']:
                exact(row[key], None, 'unknown actual platform ' + key)
            exact(row['entry_authorized'], False, 'no actual platform entry')
        impact = opt['migration_impact']
        exact(impact['state'], 'initial-draft-incomplete-until396-and397', 'initial migration not complete')
        exact(impact['whole_current_clause_bindings_retained'], True, 'whole original migration basis')
        exact(impact['all_other_original_clauses_remain_binding'], True, 'other obligations unchanged')
        exact(impact['affected_proofs_cases_relations_complete'], False, 'full impact still pending')
        exact(impact['approved_migration'], None, 'migration inactive')
        exact(sorted(opt['proposed_clause_text']), policy['expected_proposed_clause_keys'][opt['id']], 'exact amendment surfaces')
        if opt['disposition'] == 'amendment-proposal':
            if not opt['guarantees_lost_or_changed'] or not impact['exact_changed_clause_candidates']:
                raise ValueError('hidden amendment guarantee loss or impacts')
            if not all(type(v) is str and v.strip() for v in opt['proposed_clause_text'].values()):
                raise ValueError('missing proposed clause wording')
        else:
            exact(opt['guarantees_lost_or_changed'], [], 'retention and deferral no guarantee change')
            exact(impact['exact_changed_clause_candidates'], [], 'retention and deferral no amendment')
    witnesses = brief['conditional_policy_witnesses']
    exact([r['id'] for r in witnesses], policy['expected_witness_ids'], 'all eight conditional policy witnesses')
    for row in witnesses:
        if row['option_id'] not in policy['expected_option_ids'] or type(row['ordered_events']) is not list or len(row['ordered_events']) < 2:
            raise ValueError('unbound or truncated witness')
        exact(row['actual_observation'], None, 'paper witness not native observation')
        exact(row['native_execution'], False, 'no native witness run')
        exact(row['exhaustive_coverage'], False, 'no exhaustive fault coverage')
    return True

def review(entry, baseline, brief, sources, inputs, source_blobs, policy):
    validate_fixtures(entry, baseline, brief, sources, policy)
    validate_inputs(inputs, source_blobs, sources, policy)
    validate_entry(entry, policy)
    validate_brief_shape(brief, inputs, sources, policy)
    return json.loads(json.dumps({
        'step': 394, 'state': 'prepared-inactive-stage12-terminal-receipt-brief-user-acceptance-pending',
        'brief': brief, 'whole_entry393': entry, 'whole_input_bindings': sources['inputs'],
        'last_confirmed_repository_pause': 388, 'strong_safe_pause': False,
        'selected_option': None, 'approved_contract_migration': None, 'native_authority': False,
        'conditional_close_step': 398, 'after_actual394_acceptance_next_preparable_step': 395,
        'next_authorized_stage_after398': None,
    }))
