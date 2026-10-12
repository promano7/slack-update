#!/usr/bin/env python3
"""Validate supplied repository decision-planning data; perform no native action."""
import hashlib
import json
import re

POLICY_SHA = 'a0dee417dc7817f786eb398c30adf542a958623472e9612d55a55e76c306a179'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())


def exact(value, expected, label):
    if type(value) is not type(expected) or canonical(value) != canonical(expected):
        raise ValueError(label)
    return True


def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored389 policy substitution')


def validate_fixtures(entry, baseline, plan, sources, policy):
    validate_policy(policy)
    for name, value in [('entry388', entry), ('baseline', baseline), ('plan', plan), ('sources', sources)]:
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole fixture ' + name)
    return True


def validate_entry(entry, inputs, policy):
    validate_policy(policy)
    exact(canonical(entry), policy['fixture_canonical_sha256']['entry388'], 'whole accepted388 entry')
    receipt = entry['receipt']
    raw = receipt['text'].encode('utf-8')
    exact(sha(raw), policy['predecessor_receipt_sha256'], 'unchanged uploaded388 UTF8 bytes')
    exact(len(raw), policy['predecessor_receipt_size_bytes'], 'whole388 receipt size')
    text = receipt['text']
    exact([line for line in text.splitlines() if line.startswith('PASS: ')],
          policy['required_predecessor_PASS_labels'], 'all223 ordered388 PASS labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', text, re.M),
          policy['required_predecessor_create_paths'], 'all nine reported388 creates')
    message = policy['required_predecessor_commit_message']
    for marker in ['step388_overlay_application_status\tPASS', 'step388_commit_scope_verification_status\tPASS',
                   'Result: PASS (223 passes, 0 failures)', '[main d31ba23] ' + message,
                   ' 10 files changed, 7214 insertions(+)', '086aab2..d31ba23  main -> main']:
        exact(text.count(marker), 1, 'single reported388 receipt marker ' + marker)
    prepared = json.loads(inputs['pause388'])
    confirmed = entry['confirmed_pause']
    exact([row['full_prepared_condition388'] for row in confirmed['confirmed_conditions']],
          prepared['conditions'], 'all nine whole nested original388 conditions')
    exact(confirmed['whole_prepared388_freeze_canonical_sha256'], canonical(json.loads(inputs['freeze388'])), 'whole frozen388 reference')
    exact(confirmed['whole_prepared388_pause_canonical_sha256'], canonical(prepared), 'whole prepared388 pause reference')
    exact(entry['confirmation']['last_confirmed_strong_safe_pause_step'], 388, 'confirmed prior repository pause')
    exact(entry['confirmation']['runtime_authority'], False, 'no native authority in accepted entry')
    exact(entry['confirmation']['commit_full'], None, 'no invented full commit ID')
    return True


def validate_inputs(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole source register')
    exact(sorted(inputs), sorted(sources['inputs']), 'all42 original input keys')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole original input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole original JSON ' + key)
    frozen = json.loads(inputs['freeze388'])
    inherited = {key: row['path'] for key, row in sources['inputs'].items() if key not in ['freeze388', 'pause388']}
    exact(inherited, frozen['frozen_inputs']['paths'], 'all40 original normative references')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'four inert ten reviewer and README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole source root ' + row['path'])
    return True


def validate_baseline(blobs, baseline, addition, policy):
    validate_policy(policy)
    exact(canonical(baseline), policy['fixture_canonical_sha256']['baseline'], 'whole accepted388 baseline manifest')
    exact(sorted(blobs), sorted(baseline), 'all2034 original repository paths')
    exact(sha(addition), policy['changelog_addition_sha256'], 'exact additive389 CHANGELOG prefix')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path == 'CHANGELOG.md':
            if not raw.startswith(addition):
                raise ValueError('missing389 CHANGELOG prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'whole accepted388 bytes ' + path)
    return True


def validate_plan_shape(plan, inputs, sources):
    """Check decision semantics independently of the frozen fixture digest."""
    frozen = json.loads(inputs['freeze388'])
    integrated = json.loads(inputs['accepted386dossier'])
    original = [row['original_conflict'] for row in integrated['cross_conflict_review']]
    ids = [row['id'] for row in original]
    exact(plan['schema'], 1, 'integer schema')
    exact(plan['step'], 389, 'integer plan step')
    exact(plan['whole_original_conflicts'], original, 'all eight WHOLE unchanged conflicts')
    exact(plan['current_bounded_verdict_counts'], integrated['bounded_candidate_verdict_counts'], 'original bounded verdicts unchanged')
    expected_boundaries = dict(frozen['boundaries'])
    expected_boundaries['last_confirmed_strong_safe_pause_step'] = 388
    exact(plan['boundaries'], expected_boundaries, 'all closed native and project boundaries')
    exact(plan['whole_original_requirements_remain_normative'], True, 'original requirements remain binding')
    exact(plan['whole_input_references'], {key: row['path'] for key, row in sources['inputs'].items()}, 'whole original reference scope')
    auth = plan['authorization_basis']
    exact(auth['new_repository_block_authorized'], True, 'new explicit repository block')
    for key in ['contract_amendment_authorized', 'component_selection_authorized', 'native_test_or_runtime_authorized']:
        exact(auth[key], False, 'proposal request grants no ' + key)
    for key in ['actual_decision_packet', 'selected_options', 'approved_contract_migration', 'native_evidence', 'full_commit_id']:
        exact(plan[key], None, 'unknown or unselected ' + key)
    exact(plan['unresolved_user_decisions'], ids, 'all eight unselected decisions')
    roadmap = plan['roadmap']
    exact([row['step'] for row in roadmap], list(range(389, 399)), 'finite ordered ten-step roadmap')
    covered = set()
    for row in roadmap:
        exact(row['acceptance_predecessor_required'], row['step'] - 1, 'complete predecessor acceptance before successor')
        exact(row['native_authority'], False, 'roadmap grants no native action')
        cids = row['primary_conflict_ids']
        if len(cids) != len(set(cids)) or not set(cids).issubset(ids):
            raise ValueError('duplicate or foreign roadmap conflict')
        if 390 <= row['step'] <= 396:
            covered.update(cids)
        if row['step'] in [397, 398]:
            exact(cids, ids, 'whole integration and freeze conflict scope')
        for key in ['product', 'required_result']:
            if type(row[key]) is not str or not row[key].strip():
                raise ValueError('missing concrete roadmap product')
    exact(sorted(covered), sorted(ids), 'briefs cover every original conflict')
    rules = plan['proposal_rules']
    exact(rules['allowed_dispositions'], ['retain-original', 'amendment-proposal', 'defer'], 'retention amendment and blocked deferral')
    for key in ['proposed_amendment_is_current_contract', 'new_block_request_selects_any_option',
                'author_recommendation_is_user_selection', 'review_pass_is_contract_compatibility_proof',
                'absence_of_proven_candidate_is_universal_impossibility', 'estimated_step_count_is_completion_percentage',
                'upstream_documentation_is_installed_platform_evidence']:
        exact(rules[key], False, 'no implied promotion ' + key)
    for key in ['retention_and_deferral_options_required', 'unchanged_original_clauses_bind_options_until_migration',
                'exact_original_clause_text_and_whole_object_reference_required', 'full_migration_impact_required_before_any_amendment',
                'current_primary_sources_required_for_new_technical_claims', 'native_test_entry_and_operational_readiness_remain_separate']:
        exact(rules[key], True, 'required decision boundary ' + key)
    exact(rules['platforms'], ['Slackware 15.0', 'Slackware-current'], 'two distinct actual platform evidence scopes')
    exact(rules['unknown_platform_support_value'], None, 'unknown support never promoted')
    pause = plan['pause_policy']
    exact(pause['last_confirmed_step'], 388, 'last confirmed pause388')
    exact(pause['conditional_close_step'], 398, 'bounded new repository close398')
    exact(pause['original_condition_ids'], [row['id'] for row in json.loads(inputs['pause388'])['conditions']], 'nine ordered original condition identities')
    for key in ['all_nine_whole_original_conditions_required', 'actual_complete_final_user_return_required',
                'confirmation_external_to_prepared_repository', 'native_conflicts_can_remain_unresolved_at_repository_pause',
                'actual_host_unobserved_not_claimed_absent', 'no_automatic399', 'new_block_requires_new_user_request']:
        exact(pause[key], True, 'required scoped pause boundary ' + key)
    for key in ['private_pass_is_confirmation', 'repository_pause_implies_global_host_closure',
                'machine_or_controller_action_required_for_this_block']:
        exact(pause[key], False, 'no implied close or host effect ' + key)
    exact(pause['after_confirmed398_next_authorized_stage'], None, 'stop after398')
    return True


def review(entry, baseline, plan, sources, inputs, source_blobs, policy):
    validate_fixtures(entry, baseline, plan, sources, policy)
    validate_inputs(inputs, source_blobs, sources, policy)
    validate_entry(entry, inputs, policy)
    validate_plan_shape(plan, inputs, sources)
    return json.loads(json.dumps({
        'step': 389, 'state': 'prepared-repository-plan-valid-user-acceptance-pending',
        'plan': plan, 'whole_accepted_entry': entry,
        'whole_input_bindings': sources['inputs'],
        'last_confirmed_repository_pause': 388,
        'strong_safe_pause': False, 'conditional_close_step': 398,
        'selected_options': None, 'approved_contract_migration': None,
        'native_authority': False, 'native_cases_run': 0, 'native_proofs_added': 0,
        'after_complete_current_user_acceptance_next_preparable_step': 390,
        'next_authorized_stage_after398': None,
    }))
