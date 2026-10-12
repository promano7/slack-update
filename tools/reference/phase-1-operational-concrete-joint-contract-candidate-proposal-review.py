#!/usr/bin/env python3
"""Validate an inactive concrete joint draft from supplied repository data only."""
import hashlib
import json
import re

POLICY_SHA = 'bc9876ef3d8415d4e0787dc828573f593cfb6ea35c85e792b9d88b47a2030763'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())

def exact(value, expected, label):
    if type(value) is not type(expected) or (value != expected if type(value) is bytes else canonical(value) != canonical(expected)):
        raise ValueError(label)
    return True

def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored400 policy substitution')

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

def validate_entry(entry, policy):
    validate_policy(policy)
    exact(entry['confirmation'], policy['expected_confirmation399'], 'whole accepted399 supplied-return confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['receipt_sha256'], 'complete disclosed399 transcript SHA')
    exact(len(raw), policy['receipt_size_bytes'], 'complete399 transcript length')
    exact(entry['receipt']['capture_basis'], entry['confirmation']['capture_basis'], 'transcription provenance disclosed')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')], policy['receipt_pass_labels'], 'all43 ordered399 PASS labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', entry['receipt']['text'], re.M), policy['receipt_create_paths'], 'eight399 exact creates')
    for marker in policy['receipt_single_markers']:
        exact(entry['receipt']['text'].count(marker), 1, 'single399 acceptance marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1], policy['receipt_final_tail'], 'reported empty final status and two matching399 heads')
    return True

def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(sorted(inputs), sorted(sources['inputs']), 'all73 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole input canonical ' + key)
    previous = json.loads(inputs['sources399'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in ['plan399', 'sources399', 'policy399']}
    exact(inherited, previous['inputs'], 'all70 original399 input bindings unchanged')
    exact(sources['historical_readme_binding'], previous['readme'], 'historical398 README binding retained')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(r['path'] for r in roots), 'all26 pure/inert/accepted399 README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole root bytes ' + row['path'])
    return True

def expected_reference(row):
    return {k: row[k] for k in ['option_id', 'input_key', 'path', 'source_option_index', 'whole_option_canonical_sha256', 'whole_396_impact_review_canonical_sha256']} | {'packet397_whole_row_canonical_sha256': canonical(row), 'selected': False, 'approved_migration': None, 'native_joint_compatibility': None, 'runtime_authority': False}

def validate_option_reference(ref, register, inputs, sources):
    row = register[ref['option_id']]
    exact(ref, expected_reference(row), 'whole original option and impact bindings')
    exact(ref['path'], sources['inputs'][ref['input_key']]['path'], 'exact source option path')
    source = json.loads(inputs[ref['input_key']])
    option = source['options'][ref['source_option_index']]
    exact(option, row['whole_option'], 'whole exact option at original source index')
    exact(canonical(option), ref['whole_option_canonical_sha256'], 'whole source option canonical')
    for binding in option['exact_current_clause_bindings']:
        original = json.loads(inputs[binding['input_key']])
        exact(pointer(original, binding['json_pointer']), binding['whole_current_value'], 'whole current clause value')
    return True

def validate_candidate_shape(candidate, inputs, sources, policy):
    """Retain substantive source wording and unresolved joint semantics."""
    validate_policy(policy)
    packet = json.loads(inputs['packet397'])
    plan = json.loads(inputs['plan399'])
    register = {r['option_id']: r for r in packet['option_register']}
    exact(candidate['schema'], 1, 'integer schema')
    exact(candidate['step'], 400, 'integer400 step')
    exact(candidate['scope'], plan['scope'], 'finite399-408 repository scope')
    exact(candidate['state'], 'concrete-initial-joint-draft-semantic-integration-pending', 'initial unapproved joint draft state')
    exact(candidate['candidate_id'], 'JCP400-A', 'one concrete author draft')
    exact(candidate['candidate_title'], policy['expected_candidate_title'], 'exact candidate direction')
    exact(candidate['boundaries'], plan['boundaries'], 'all original closed native boundaries')
    for key in ['authored_for_further_review', 'recommended_for_further_drafting', 'whole_original_requirements_remain_normative', 'role_co_location_can_only_be_reviewed_with_exact_trust_source_control_and_oracle_provenance', 'no_automatic409']:
        exact(candidate[key], True, 'required review boundary ' + key)
    for key in ['user_selected', 'semantic_migration_complete', 'independent_impact_review_accepted', 'joint_native_compatibility_proven', 'runtime_authority', 'role_labels_are_independence_or_native_graph_proof', 'concrete_protocol_completeness_claimed']:
        exact(candidate[key], False, 'no draft/native/approval promotion ' + key)
    for key in ['selected_options', 'approved_joint_specification', 'approved_contract_migration', 'actual_selected_implementation', 'actual_joint_native_graph', 'native_evidence', 'actual_role_sharing_or_separation_review', 'after_confirmed408_next_authorized_stage']:
        exact(candidate[key], None, 'no invented actual decision or support ' + key)
    for key in ['native_cases_run', 'native_proofs_added']:
        exact(candidate[key], 0, 'zero native progress')
    exact(candidate['whole_accepted399_plan_reference'], sources['inputs']['plan399'], 'whole accepted399 roadmap')
    exact(candidate['whole_packet397_reference'], sources['inputs']['packet397'], 'whole26 options/325pairs retained')
    exact(candidate['whole_396_impact_reference'], sources['inputs']['oracle_brief396'], 'whole15category/1286member map retained')
    refs = candidate['draft_option_references']
    exact([r['option_id'] for r in refs], policy['expected_primary_option_ids'], 'exact nine draft option directions')
    for ref in refs:
        validate_option_reference(ref, register, inputs, sources)
    expected_wording = [{'option_id': oid, 'whole_option_reference': expected_reference(register[oid]), 'proposed_clause_text': register[oid]['whole_option']['proposed_clause_text']} for oid in policy['expected_primary_option_ids'] if register[oid]['whole_option']['proposed_clause_text']]
    exact(candidate['exact_adopted_inactive_option_wording'], expected_wording, 'all four exact original draft amendment wordings')
    expected_losses = [{'option_id': oid, 'whole_option_reference': expected_reference(register[oid]), 'guarantees_lost_or_changed': register[oid]['whole_option']['guarantees_lost_or_changed']} for oid in policy['expected_primary_option_ids']]
    exact(candidate['complete_source_guarantee_loss_register'], expected_losses, 'all nine full source loss lists retained without deduplication')
    exact(candidate['new_joint_wording'], policy['expected_joint_wording'], 'six complete joint clauses including same-brief combinations')
    decisions = candidate['eight_pending_decisions']
    exact([r['whole_original_decision'] for r in decisions], packet['decision_rows'], 'all eight WHOLE original decisions')
    for row, original in zip(decisions, packet['decision_rows']):
        exact(row['id'], original['id'], 'pending decision identity')
        matching = [oid for oid in policy['expected_primary_option_ids'] if register[oid]['input_key'] in original['source_family_input_keys']]
        exact(row['draft_option_ids'], matching, 'concrete draft coverage includes finite time and rights across families')
        exact(row['user_selected_option_ids'], None, 'no user option selection')
        exact(row['original_conflict_resolved'], False, 'original native conflict unresolved')
        exact(row['joint_native_compatibility'], None, 'joint compatibility unknown')
        exact(row['required_future_acceptance'], policy['expected_future_acceptance'], 'full semantic approval gate')
    joint = candidate['nine_unresolved_joint_reviews']
    exact([r['whole_original_dimension'] for r in joint], packet['joint_review_dimensions'], 'all nine WHOLE original joint dimensions')
    exact(joint, policy['expected_joint_questions'], 'nine substantive candidate-specific unresolved questions')
    exact(candidate['proposed_roles'], policy['expected_roles'], 'eleven unbound roles;no actual graph inferred')
    exact(candidate['platform_rows'], policy['expected_platforms'], 'distinct null15.0/current support and authority')
    for key, expected_ids in [('retention_comparator', policy['expected_retention_option_ids']), ('deferral_comparator', policy['expected_deferral_option_ids'])]:
        comparator = candidate[key]
        exact(comparator, policy['expected_comparators'][key], 'complete unselected comparator')
        exact([r['option_id'] for r in comparator['option_references']], expected_ids, 'all seven original comparator families')
        for ref in comparator['option_references']:
            validate_option_reference(ref, register, inputs, sources)
    exact(candidate['migration_coverage'], policy['expected_migration_coverage'], 'whole map is not independently approved semantic replacements')
    exact(candidate['known_draft_incompatibilities'], policy['expected_incompatibilities'], 'all three disclosed changed-guarantee families remain')
    exact(candidate['why_author_proposes_this_draft'], policy['expected_author_reason'], 'author recommendation not user selection or feasibility')
    exact(candidate['next_preparable_step_after_complete400_acceptance'], 401, '401 only after full400 acceptance')
    exact(candidate['conditional_close_step'], 408, 'conditional finite close408')
    return True

def validate_fixtures(fixtures, policy):
    validate_policy(policy)
    exact(sorted(fixtures), sorted(policy['fixture_canonical_sha256']), 'exact400 fixture set')
    for name, value in fixtures.items():
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole authored400 fixture ' + name)
    return True

def validate_repository(blobs, baseline, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(baseline), 'all2122 historical399 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            addition = policy['prefixes'][path].encode()
            if not raw.startswith(addition):
                raise ValueError('missing exact400 additive prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'all historical399 bytes unchanged ' + path)
    return True

def review(entry, candidate, inputs, source_blobs, sources, policy):
    validate_entry(entry, policy)
    validate_sources(inputs, source_blobs, sources, policy)
    validate_candidate_shape(candidate, inputs, sources, policy)
    return {'step': 400, 'state': 'prepared-inactive-candidate-user-acceptance-pending',
        'candidate_id': 'JCP400-A', 'selected_options': None, 'approved_contract_migration': None,
        'runtime_authority': False, 'joint_native_compatibility_proven': False,
        'last_confirmed_repository_pause': 398, 'strong_safe_pause': False,
        'after_complete400_acceptance_next_preparable_step': 401, 'conditional_close_step': 408,
        'after_confirmed408_next_authorized_stage': None}
