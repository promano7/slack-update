#!/usr/bin/env python3
"""Review inactive whole decision packet freeze and conditional external repository pause proposals from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = 'e2f3b93af774d099f2ada2ad94002b8645c869b5e62f38d7288c9d4070bb6bed'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())

def exact(value, expected, label):
    if type(value) is not type(expected) or canonical(value) != canonical(expected):
        raise ValueError(label)
    return True

def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored398 policy substitution')

def validate_inputs(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(canonical(sources), policy['fixture_canonical_sha256']['sources'], 'whole source register')
    exact(sorted(inputs), sorted(sources['inputs']), 'all67 original input keys')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole original input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole original JSON ' + key)
    frozen = json.loads(inputs['freeze388'])
    inherited = {key: row['path'] for key, row in sources['inputs'].items() if key in frozen['frozen_inputs']['paths']}
    exact(inherited, frozen['frozen_inputs']['paths'], 'all40 original normative references')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(row['path'] for row in roots), 'four inert nineteen reviewer and README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole source root ' + row['path'])
    return True

def validate_baseline(blobs, baseline, addition, policy):
    validate_policy(policy)
    exact(canonical(baseline), policy['fixture_canonical_sha256']['baseline'], 'whole accepted397 baseline manifest')
    exact(sorted(blobs), sorted(baseline), 'all2106 original repository paths')
    exact(sha(addition), policy['changelog_addition_sha256'], 'exact additive398 CHANGELOG prefix')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path == 'CHANGELOG.md':
            if not raw.startswith(addition):
                raise ValueError('missing398 CHANGELOG prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'whole accepted397 bytes '+path)
    return True

def validate_entry(entry, policy):
    validate_policy(policy)
    exact(canonical(entry), policy['fixture_canonical_sha256']['entry397'], 'whole accepted397 receipt and confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['predecessor_receipt_sha256'], 'unchanged uploaded397 bytes')
    exact(len(raw), policy['predecessor_receipt_size_bytes'], 'complete397 receipt size')
    text = entry['receipt']['text']
    exact([line for line in text.splitlines() if line.startswith('PASS: ')], policy['required_predecessor_PASS_labels'], 'all430 ordered397 labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', text, re.M), policy['required_predecessor_create_paths'], 'eight exact397 create paths')
    for marker in ['step397_overlay_application_status\tPASS', 'step397_commit_scope_verification_status\tPASS',
                   'Result: PASS (430 passes, 0 failures)', '[main f4a642d] Phase 1 step 397: integrate unselected contract decision packet and roadmap',
                   ' 10 files changed, 32897 insertions(+)', '   792525e..f4a642d  main -> main\n']:
        exact(text.count(marker), 1, 'single397 marker '+marker)
    exact(text.split('   792525e..f4a642d  main -> main\n')[1], policy['expected_predecessor_tail'], 'clean matching reported397 heads')
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

def validate_fixtures(entry, baseline, freeze, sources, policy):
    validate_policy(policy)
    for name, value in [('entry397', entry), ('baseline', baseline), ('freeze', freeze), ('sources', sources)]:
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole398 fixture ' + name)
    return True

def validate_checkpoint(entry, step):
    exact(entry['confirmation']['step'], step, 'exact chain checkpoint step')
    exact(entry['receipt']['step'], step, 'exact chain receipt step')
    raw = entry['receipt']['text'].encode('utf-8')
    for part in [entry['confirmation'], entry['receipt']]:
        prefix = 'receipt_' if part is entry['confirmation'] else ''
        exact(part[prefix+'sha256'], sha(raw), 'whole raw checkpoint digest')
        exact(part[prefix+'size_bytes'], len(raw), 'whole raw checkpoint size')
    confirmation = entry['confirmation']
    for key in ['user_application_completed', 'user_harness_completed', 'user_commit_and_push_completed', 'user_worktree_clean', 'user_head_matches_origin']:
        exact(confirmation[key], True, 'accepted whole checkpoint '+key)
    for key in ['strong_safe_pause', 'runtime_authority', 'actual_global_host_closure']:
        exact(confirmation[key], False, 'no checkpoint scope promotion '+key)
    for key in ['commit_full', 'actual_live_bindings']:
        exact(confirmation[key], None, 'no invented checkpoint identity '+key)
    exact(confirmation['actual_host_state'], 'unobserved-not-claimed-absent', 'checkpoint host unknown')
    for key in ['native_cases_run', 'native_proofs_added']:
        exact(confirmation[key], 0, 'no native checkpoint progress')
    exact(confirmation['last_confirmed_strong_safe_pause_step'], 388, 'original confirmed388 scope retained')
    return True

def validate_freeze_shape(freeze, entry, inputs, sources, policy):
    """Retain whole prepared conditions; only an external final return can close."""
    validate_policy(policy)
    plan = json.loads(inputs['plan389'])
    packet = json.loads(inputs['packet397'])
    pause = json.loads(inputs['pause388'])
    exact(freeze['schema'], 1, 'integer schema')
    exact(freeze['step'], 398, 'integer398 step')
    exact(freeze['scope'], plan['scope'], 'repository389-398only scope')
    exact(freeze['frozen_inputs'], sources['inputs'], 'all67 WHOLE exact frozen input bindings')
    exact(freeze['frozen_source_roots'], sources['inert_roots']+sources['reviewer_roots']+[sources['readme']], 'all source roots and unchanged current README')
    exact(freeze['whole_accepted397_packet'], packet, 'WHOLE accepted397 options decisions pairs dimensions and original scope')
    exact(freeze['whole_389_roadmap'], plan['roadmap'], 'whole finite389-398roadmap')
    exact(freeze['whole_389_pause_policy'], plan['pause_policy'], 'whole original external pause policy')
    exact(freeze['whole_396_impact_reference'], sources['inputs']['oracle_brief396'], 'whole396impact bound without pruning')
    exact(freeze['whole_original_pause388_reference'], sources['inputs']['pause388'], 'whole original nested nine-condition input')
    exact(freeze['boundaries'], plan['boundaries'], 'all current original closed boundaries')
    chain = freeze['accepted_checkpoint_chain389_397']
    exact([r['confirmation']['step'] for r in chain], policy['expected_chain_steps'], 'complete nine checkpoint sequence389-397')
    for row, step in zip(chain, policy['expected_chain_steps']):
        original = entry if step==397 else json.loads(inputs['accepted_entry'+str(step)])
        exact(row, original, 'WHOLE unchanged actual checkpoint receipt '+str(step))
        validate_checkpoint(row, step)
    conditions = freeze['conditions']
    exact([r['id'] for r in conditions], policy['expected_condition_ids'], 'all nine whole original condition identities')
    for i, row in enumerate(conditions):
        original = pause['conditions'][i]
        exact(row['position'], i, 'exact condition order')
        exact(row['requirement'], original['requirement'], 'whole original requirement string')
        exact(row['full_original_prepared_condition388'], original, 'WHOLE original nested condition history '+str(i))
        expected_status = 'pending-complete-current398-return' if i==0 else 'repository-reviewed-eligible-pending-external-final398-confirmation'
        exact(row['repository_status'], expected_status, 'prepared scoped eligibility only')
        exact(row['repository_review_basis'], policy['expected_condition_review_bases'][i], 'complete exact current scoped condition basis')
        exact(row['current398_actual_user_confirmation'], None, 'external current398 confirmation pending')
        exact(row['actual_native_evidence'], None, 'no native condition evidence')
        exact(row['actual_global_host_closure'], False, 'no global condition closure')
    exact(freeze['after_final_acceptance'], policy['expected_after_final_acceptance'], 'whole external final close then STOP/noautomatic399')
    for key in ['all_whole_decision_inputs_required', 'final_pause_requires_all_nine_whole_original_conditions', 'final_pause_requires_complete_actual_user_receipt', 'repository_review_eligible_for_conditional_pause', 'whole_original_requirements_remain_normative', 'no_automatic399']:
        exact(freeze[key], True, 'whole required pause boundary '+key)
    for key in ['private_eligibility_is_actual_confirmation', 'actual_strong_safe_pause_confirmed', 'semantic_migration_complete', 'runtime_authority', 'machine_action_required', 'controller_action_required', 'actual_global_host_closure']:
        exact(freeze[key], False, 'no prepared promotion '+key)
    for key in ['current398_actual_final_user_receipt', 'current398_user_commit_prefix', 'current398_user_commit_full', 'current398_user_worktree_clean', 'current398_user_head_matches_origin', 'selected_options', 'approved_joint_specification', 'approved_contract_migration', 'actual_selected_implementation', 'actual_joint_native_graph', 'actual_native_evidence', 'actual_live_bindings', 'next_authorized_stage_after398']:
        exact(freeze[key], None, 'external actual or authority absent from prepared data '+key)
    for key in ['native_cases_run', 'native_proofs_added']:
        exact(freeze[key], 0, 'native progress zero')
    exact(freeze['actual_host_state'], 'unobserved-not-claimed-absent', 'actual host unknown not absent')
    exact(freeze['last_confirmed_strong_safe_pause_step'], 388, 'prepared last confirmed pause remains388')
    exact(freeze['required_final_commit_message'], policy['expected_commit_message'], 'exact final message')
    return True

def review(entry, baseline, freeze, sources, inputs, source_blobs, policy):
    validate_fixtures(entry, baseline, freeze, sources, policy)
    validate_inputs(inputs, source_blobs, sources, policy)
    validate_entry(entry, policy)
    validate_freeze_shape(freeze, entry, inputs, sources, policy)
    return json.loads(json.dumps({'step':398, 'state':'prepared-final-user-return-and-external-confirmation-pending', 'freeze':freeze, 'whole_entry397':entry, 'whole_input_bindings':sources['inputs'], 'last_confirmed_repository_pause':388, 'repository_review_eligible_for_conditional_pause':True, 'actual_strong_safe_pause_confirmed':False, 'selected_options':None, 'approved_contract_migration':None, 'runtime_authority':False, 'actual_host_state':'unobserved-not-claimed-absent', 'actual_live_bindings':None, 'actual_global_host_closure':False, 'next_authorized_stage_after398':None, 'stop_after_complete_actual_receipt_and_all_whole_conditions_confirmed':True}))
