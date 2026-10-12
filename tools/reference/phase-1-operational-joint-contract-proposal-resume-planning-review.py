#!/usr/bin/env python3
"""Validate supplied joint proposal planning records without native dispatch."""
import hashlib
import json
import re

POLICY_SHA = 'd395de193f389e4f91c01cb4ff787c910cbc05dd84fc11c3605125941da88b82'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())

def exact(value, expected, label):
    if type(value) is not type(expected) or (value != expected if type(value) is bytes else canonical(value) != canonical(expected)):
        raise ValueError(label)
    return True

def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored399 policy substitution')

def validate_entry(entry, inputs, policy):
    validate_policy(policy)
    receipt = entry['receipt']
    raw = receipt['text'].encode('utf-8')
    exact(raw, inputs['receipt398_raw'], 'unchanged full uploaded398 receipt bytes')
    exact(sha(raw), policy['receipt_sha256'], 'complete398 receipt SHA')
    exact(len(raw), policy['receipt_size_bytes'], 'complete398 receipt size')
    exact([s for s in receipt['text'].splitlines() if s.startswith('PASS: ')], policy['receipt_pass_labels'], 'all288 ordered398 PASS labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', receipt['text'], re.M), policy['receipt_create_paths'], 'eight exact398 creates')
    for marker in policy['receipt_single_markers']:
        exact(receipt['text'].count(marker), 1, 'single398 final marker')
    exact(receipt['text'].split(policy['receipt_push_marker'])[1], policy['receipt_final_tail'], 'empty status and matching reported398 heads')
    confirmation = entry['confirmation']
    exact(confirmation, policy['expected_confirmation398'], 'whole external398 confirmation')
    external = entry['external_conditions']
    frozen = json.loads(inputs['freeze398'])
    exact(external['prepared_freeze_canonical_sha256'], canonical(frozen), 'whole398 freeze canonical binding')
    exact(external['prepared_conditions_canonical_sha256'], canonical(frozen['conditions']), 'whole398 prepared conditions binding')
    exact(external['complete_final_receipt_sha256'], sha(raw), 'external conditions based on final actual receipt')
    exact(external['scope'], confirmation['scope'], 'historical398 repository-only scope')
    exact(external['all_nine_whole_conditions_confirmed'], True, 'all whole398 conditions externally confirmed')
    exact(external['confirmation_external_to_prepared_repository'], True, 'external rather than prepared confirmation')
    exact(external['next_authorized_stage_after398'], None, 'old block stopped before new user request')
    exact(len(external['conditions']), 9, 'nine whole nested conditions')
    for index, (row, original) in enumerate(zip(external['conditions'], frozen['conditions'])):
        exact(row['position'], index, 'condition order')
        exact(row['id'], original['id'], 'condition identity')
        exact(row['whole_prepared398_condition'], original, 'whole nested condition retained')
        exact(row['confirmed_repository_scope_only'], True, 'repository-only confirmation')
        exact(row['actual_native_evidence'], None, 'no native condition evidence')
        exact(row['actual_global_host_closure'], False, 'no condition global closure')
        if type(row['external_review_basis']) is not str or not row['external_review_basis'].strip():
            raise ValueError('missing external398 review basis')
    return True

def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(sorted(inputs), sorted(list(sources['inputs']) + ['receipt398_raw']), 'all70 whole JSON inputs and raw receipt')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole canonical input ' + key)
    old_sources = json.loads(inputs['sources398'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in ['freeze398', 'sources398', 'policy398']}
    exact(inherited, old_sources['inputs'], 'all67 inherited398 input bindings')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'all four inert twenty reviewer and README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole root bytes ' + row['path'])
    return True

def validate_plan_shape(plan, inputs, sources, policy):
    """Check scope and semantics before considering authored fixture digests."""
    validate_policy(policy)
    packet = json.loads(inputs['packet397'])
    prior = json.loads(inputs['plan389'])
    frozen = json.loads(inputs['freeze398'])
    exact(plan['schema'], 1, 'integer schema')
    exact(plan['step'], 399, 'integer step399')
    exact(plan['scope'], policy['scope'], 'finite repository scope')
    exact(plan['state'], 'prepared-unselected-joint-proposal-plan', 'prepared state only')
    expected_boundaries = dict(prior['boundaries'])
    expected_boundaries['last_confirmed_strong_safe_pause_step'] = 398
    exact(plan['boundaries'], expected_boundaries, 'all original closed boundaries plus confirmed398')
    exact(plan['whole_original_decisions'], packet['decision_rows'], 'eight whole pending original decisions')
    exact(plan['whole_joint_review_dimensions'], packet['joint_review_dimensions'], 'all nine whole joint dimensions')
    exact(plan['current_bounded_verdict_counts'], prior['current_bounded_verdict_counts'], 'all original45 verdicts unchanged')
    exact(plan['whole_input_references'], sources['inputs'], 'complete original/proposal references')
    exact(plan['proposal_rules'], prior['proposal_rules'], 'all original proposal approval rules')
    exact(plan['joint_draft_rules'], policy['expected_joint_draft_rules'], 'draft does not select approve or prove')
    exact(plan['authorization_basis'], policy['expected_authorization_basis'], 'new user request only authorizes repository draft work')
    exact(plan['entry_commit_prefix'], 'cb20576', 'reported accepted398 short prefix')
    exact(plan['whole_original_requirements_remain_normative'], True, 'all original requirements stay normative')
    for key in ['full_commit_id', 'selected_options', 'approved_joint_specification', 'approved_contract_migration', 'actual_selected_implementation', 'actual_joint_native_graph', 'native_evidence', 'draft_candidate']:
        exact(plan[key], None, 'no invented selection evidence or approval ' + key)
    for key in ['semantic_migration_complete', 'independent_impact_review_accepted']:
        exact(plan[key], False, 'no draft promotion ' + key)
    ids = [d['id'] for d in packet['decision_rows']]
    exact([r['step'] for r in plan['roadmap']], list(range(399, 409)), 'finite ordered399-408 roadmap')
    for index, row in enumerate(plan['roadmap']):
        exact(row['complete_predecessor_acceptance_required'], row['step'] - 1, 'full predecessor acceptance gate')
        exact(row['all_original_conflict_ids'], ids, 'all eight conflicts govern every joint review')
        exact(row['runtime_authority'], False, 'roadmap has no native grant')
        exact(row['contract_migration_approved'], False, 'roadmap has no approved migration')
        exact(row['product'], policy['expected_products'][index][0], 'concrete roadmap product')
        exact(row['required_result'], policy['expected_products'][index][1], 'substantive roadmap acceptance criteria')
    pause = plan['pause_policy']
    exact(pause, policy['expected_pause_policy'], 'complete conditional408 pause policy')
    exact(pause['original_condition_ids'], [r['id'] for r in frozen['conditions']], 'all nine original whole pause requirements')
    exact(pause['whole_original_conditions_reference'], sources['inputs']['freeze398'], 'whole nested pause conditions reachable unchanged')
    return True

def validate_fixtures(fixtures, policy):
    validate_policy(policy)
    exact(sorted(fixtures), sorted(policy['fixture_canonical_sha256']), 'exact399 fixture set')
    for name, value in fixtures.items():
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole authored fixture ' + name)
    return True

def validate_repository(blobs, baseline, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(baseline), 'all2114 accepted398 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            addition = policy['prefixes'][path].encode('utf-8')
            if not raw.startswith(addition):
                raise ValueError('missing exact399 additive prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'unchanged accepted398 historical bytes ' + path)
    return True

def review(entry, plan, sources, inputs, source_blobs, policy):
    validate_sources(inputs, source_blobs, sources, policy)
    validate_entry(entry, inputs, policy)
    validate_plan_shape(plan, inputs, sources, policy)
    return {'step': 399, 'scope': plan['scope'], 'state': 'prepared-user-acceptance-pending',
        'last_confirmed_repository_pause': 398, 'conditional_close_step': 408,
        'strong_safe_pause': False, 'selected_options': None, 'approved_contract_migration': None,
        'runtime_authority': False, 'native_cases_run': 0, 'native_proofs_added': 0,
        'after_complete_current_acceptance_next_preparable_step': 400,
        'after_confirmed408_next_authorized_stage': None}
