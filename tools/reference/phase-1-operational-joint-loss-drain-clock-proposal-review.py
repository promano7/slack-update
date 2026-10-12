#!/usr/bin/env python3
"""Review inactive loss/drain/clock proposals from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = 'd72ea888c058bef13fc30f98b88378c5da0514df3dd859c71febe2ebf0ac6669'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())


def exact(value, expected, label):
    if type(value) is not type(expected) or (value != expected if type(value) is bytes else canonical(value) != canonical(expected)):
        raise ValueError(label)
    return True


def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored403 policy substitution')


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
    exact(entry['confirmation'], policy['expected_confirmation402'], 'whole accepted402 supplied-return confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['receipt_sha256'], 'complete disclosed402 transcript SHA')
    exact(len(raw), policy['receipt_size_bytes'], 'complete402 transcript length')
    exact(entry['receipt']['capture_basis'], entry['confirmation']['capture_basis'], 'transcription provenance disclosed')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')], policy['receipt_pass_labels'], 'all71 ordered402 PASS labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', entry['receipt']['text'], re.M), policy['receipt_create_paths'], 'eight402 exact creates')
    for marker in policy['receipt_single_markers']:
        exact(entry['receipt']['text'].count(marker), 1, 'single402 acceptance marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1], policy['receipt_final_tail'], 'reported empty final status and two matching402 heads')
    return True


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(sorted(inputs), sorted(sources['inputs']), 'all82 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole input canonical ' + key)
    previous = json.loads(inputs['sources402'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in ['operation402', 'sources402', 'policy402']}
    exact(inherited, previous['inputs'], 'all79 original402 input bindings unchanged')
    exact(sources['previous_readme_binding'], previous['readme'], 'historical399 README binding retained')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(r['path'] for r in roots), 'all29 pure/inert/accepted402 README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole root bytes ' + row['path'])
    return True


def hypothetical_case(case, policy):
    """Compare supplied paper knowledge and eligibility; produce no native permission."""
    validate_policy(policy)
    exact(case['hypothetical_only'],True,'hypothetical facts only')
    exact(case['actual_native_evidence'],None,'no native observation in paper case')
    exact(case['runtime_authority'],False,'paper case has no action rights')
    for key in policy['paper_bool_fields']:
        if case[key] is not None and type(case[key]) is not bool:
            raise ValueError('bool/unknown field required')
    for key in ['tick','forward_deadline','recovery_deadline','original_budget','original_spent']:
        if case[key] is not None and (type(case[key]) is not int or case[key]<0):
            raise ValueError('synthetic integer/unknown required')
    drain=all(case[k] is True for k in policy['paper_drain_fields'])
    time=all(case[k] is True for k in policy['paper_time_fields'])
    recovery_expired=case['tick'] is not None and case['recovery_deadline'] is not None and case['tick']>=case['recovery_deadline']
    forward_expired=case['tick'] is not None and case['forward_deadline'] is not None and case['tick']>=case['forward_deadline']
    spent=case['original_spent'];budget=case['original_budget']
    if not drain: question='paper-deny-incomplete-drain'
    elif case['rollback_or_restart_suspected'] is not False: question='paper-deny-suspected-rollback'
    elif not time or case['tick'] is None or case['recovery_deadline'] is None: question='paper-deny-unknown-clock'
    elif recovery_expired: question='paper-deny-recovery-expired'
    elif case['original_spend_known'] is not True or spent is None or budget is None: question='paper-deny-unknown-spend'
    elif spent>=budget: question='paper-deny-original-budget-exhausted'
    elif case['original_surviving_recovery_control_known'] is not True or case['original_recovery_scope_known'] is not True: question='paper-deny-unknown-original-control'
    elif case['recovery_revoked'] is not False: question='paper-deny-new-recovery-admission'
    else: question='paper-original-recovery-eligibility-question'
    forward_closed=forward_expired or case['tick'] is None or case['forward_deadline'] is None or not drain or any(case[k] is not True for k in ['supervisor_alive','guardian_alive','admission_controller_alive']) or case['original_forward_failed'] is True or case['known_mismatch'] is True or not time or case['rollback_or_restart_suspected'] is not False
    return {'drain_disposition':'paper-full-drain-declaration' if drain else 'paper-drain-pending',
        'recovery_eligibility_question':question,'forward_admission_closed_in_paper':forward_closed,
        'original_forward_failure_preserved':case['original_forward_failed'] is True,
        'known_mismatch_preserved':case['known_mismatch'] is True,
        'actual_native_drain_or_rights':None,'runtime_authority':False,'native_proof':False,'actual_closed':False}

def validate_review_shape(review,inputs,sources,policy):
    validate_policy(policy)
    candidate=json.loads(inputs['candidate400']);loss=json.loads(inputs['accepted382dossier'])
    contract=json.loads(inputs['original323']);guard=json.loads(inputs['original324'])
    option=next(o for o in json.loads(inputs['loss_brief392'])['options'] if o['id']=='explicit-local-clock-trust-boundary')
    exact(review['schema'],1,'integer schema');exact(review['step'],403,'integer403')
    exact(review['state'],'inactive-joint-loss-drain-original-clock-review','inactive proposal state')
    exact(review['scope'],candidate['scope'],'finite399-408scope');exact(review['candidate_id'],'JCP400-A','same author draft')
    exact(review['boundaries'],candidate['boundaries'],'closed original native/project gates')
    exact(review['whole_original_requirements_remain_normative'],True,'all original clauses remain normative')
    for key,source in [('whole_candidate400_reference','candidate400'),('whole_accepted401_trust_reference','trust401'),('whole_accepted402_operation_reference','operation402'),('whole_396_impact_reference','oracle_brief396')]:exact(review[key],sources['inputs'][source],'whole accepted input '+source)
    exact(review['whole_original323_clock_recovery_forward_closure'],{k:contract[k] for k in ['clock_contract','recovery_contract','forward_contract','fence_contract','closure_contract']},'whole original323finite rights and scopes')
    exact(review['whole_original324_guard_contract'],guard['guard_contract'],'whole original324guard')
    exact(review['whole_original326_independent_conformance'],json.loads(inputs['original326'])['independent_conformance_contract'],'whole original independent conformance')
    exact(review['whole_original382_supervisor_and_time_conflicts'],[loss['original377_supervisor_conflict'],loss['original377_finite_time_conflict']],'whole original loss/time conflicts')
    exact(review['whole_original382_independent_resolution_criteria'],loss['independent_resolution_criteria'],'all original independent loss/time criteria')
    exact(review['whole400_guardian_clock_joint_wording'],candidate['new_joint_wording'][2],'whole400guardian-clock combination')
    exact(review['whole392_clock_option'],option,'WHOLE392inactiveclock option including exact losses')
    exact(review['exact_clock_clause_proposal'],policy['expected_clock_clause'],'exact original and inactive proposed clock text')
    exact(review['exact_clock_clause_proposal']['whole_current_clause'],contract['clock_contract']['rule'],'original current clock not rewritten')
    exact(review['exact_clock_clause_proposal']['proposed_complete_clause_text'],option['proposed_clause_text']['/clock_contract/rule'],'exact complete original392draftclock wording')
    for key in ['proposed_loss_roles','seven_full_drain_requirements','joint_proposed_statements']:
        exact(review[key],policy['expected_sections'][key],'complete loss/drain/time requirements '+key)
    exact(review['whole_original_platform_assessments'],json.loads(inputs['design372'])['separate_platform_assessments'],'both platforms all original unknown assessments')
    for key in ['actual_guardian_or_surviving_control','actual_full_membership_and_drain','actual_clock_mapping_or_provider','actual_finite_recovery_rights','actual_native_evidence','selected_options','approved_joint_specification','approved_contract_migration','after_confirmed408_next_authorized_stage']:exact(review[key],None,'no actual binding or approval '+key)
    for key in ['guardian_is_immortal','parent_exit_or_signal_is_full_drain','safe_cut_latency_or_stop_bound_proven','known_drain_renews_expired_rights','unknown_time_erases_independent_captured_facts','clock_fallback_or_deadline_budget_refill_allowed','hidden_trusted_clock_tampering_detection_proven','semantic_migration_complete','independent_impact_review_accepted','runtime_authority']:exact(review[key],False,'no native shortcut or renewal '+key)
    for key in ['native_cases_run','native_proofs_added']:exact(review[key],0,'zero native progress')
    exact(review['remaining_joint_reviews'],candidate['nine_unresolved_joint_reviews'],'all nine joint blockers remain unresolved')
    exact(review['authored_hypothetical_cases'],policy['expected_cases'],'all22 explicit paper cases')
    for case in review['authored_hypothetical_cases']:
        result=hypothetical_case(case,policy)
        exact(result['drain_disposition'],case['expected_drain_disposition'],'paper independently declared drain')
        exact(result['recovery_eligibility_question'],case['expected_recovery_question'],'paper original scoped rights question')
    exact(review['next_preparable_step_after_complete403_acceptance'],404,'404 after complete403acceptance')
    exact(review['conditional_close_step'],408,'same finite close');exact(review['no_automatic409'],True,'STOP after408')
    return True

def validate_fixtures(fixtures, policy):
    validate_policy(policy)
    exact(sorted(fixtures), sorted(policy['fixture_canonical_sha256']), 'exact403 fixture set')
    for name, value in fixtures.items():
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole authored403 fixture ' + name)
    return True


def validate_repository(blobs, baseline, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(baseline), 'all2146 historical402 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            addition = policy['prefixes'][path].encode()
            if not raw.startswith(addition):
                raise ValueError('missing exact403 additive prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'all historical402 bytes unchanged ' + path)
    return True


def review(entry,proposal,inputs,source_blobs,sources,policy):
    validate_entry(entry,policy);validate_sources(inputs,source_blobs,sources,policy);validate_review_shape(proposal,inputs,sources,policy)
    return {'step':403,'state':'prepared-inactive-loss-clock-review-user-acceptance-pending',
        'selected_options':None,'approved_contract_migration':None,'runtime_authority':False,
        'last_confirmed_repository_pause':398,'strong_safe_pause':False,
        'after_complete403_acceptance_next_preparable_step':404,'conditional_close_step':408,
        'after_confirmed408_next_authorized_stage':None}
