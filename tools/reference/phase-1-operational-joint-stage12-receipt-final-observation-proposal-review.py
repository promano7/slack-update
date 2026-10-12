#!/usr/bin/env python3
"""Review inactive whole-stage receipt/custody proposals from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = '9df8377099adbf85d710a9ea84066b817a30a4004c0c08abbfaf5106c8ca3213'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())


def exact(value, expected, label):
    if type(value) is not type(expected) or (value != expected if type(value) is bytes else canonical(value) != canonical(expected)):
        raise ValueError(label)
    return True


def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored405 policy substitution')


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
    exact(entry['confirmation'], policy['expected_confirmation404'], 'whole accepted404 supplied-return confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['receipt_sha256'], 'complete disclosed404 transcript SHA')
    exact(len(raw), policy['receipt_size_bytes'], 'complete404 transcript length')
    exact(entry['receipt']['capture_basis'], entry['confirmation']['capture_basis'], 'transcription provenance disclosed')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')], policy['receipt_pass_labels'], 'all74 ordered404 PASS labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', entry['receipt']['text'], re.M), policy['receipt_create_paths'], 'eight404 exact creates')
    for marker in policy['receipt_single_markers']:
        exact(entry['receipt']['text'].count(marker), 1, 'single404 acceptance marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1], policy['receipt_final_tail'], 'reported empty final status and two matching404 heads')
    return True


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(sorted(inputs), sorted(sources['inputs']), 'all88 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole input canonical ' + key)
    previous = json.loads(inputs['sources404'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in ['storage404', 'sources404', 'policy404']}
    exact(inherited, previous['inputs'], 'all85 original404 input bindings unchanged')
    exact(sources['previous_readme_binding'], previous['readme'], 'previous accepted README binding retained')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(r['path'] for r in roots), 'all31 pure/inert/accepted404 README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole root bytes ' + row['path'])
    return True


def hypothetical_case(case,policy):
    """Return a supplied-data finite-cut question,never publish or authorize."""
    validate_policy(policy);exact(case['hypothetical_only'],True,'paper only')
    exact(case['actual_native_evidence'],None,'no native observations');exact(case['runtime_authority'],False,'no action authority')
    for key in policy['paper_bool_fields']:
        if case[key] is not None and type(case[key]) is not bool:raise ValueError('bool/unknown paper field required')
    for key in ['original_budget','original_spent']:
        if case[key] is not None and (type(case[key]) is not int or case[key]<0):raise ValueError('integer/unknown original budget required')
    if case['commit_outcome_uncertain'] is not False:q='paper-quarantine-uncertain-commit-no-replay'
    elif case['known_mismatch'] is True:q='paper-deny-known-mismatch'
    elif case['unclassified_later_effect'] is not False:q='paper-block-unclassified-later-effect'
    elif case['producer_trace_closed'] is not True:q='paper-deny-payload-before-trace-closure'
    elif case['payload_prior_only'] is not True:q='paper-deny-self-completion-payload'
    elif any(case[k] is not True for k in ['source_trust_controls_known','original_publication_rights_known','original_clock_known','durable_spend_known']):q='paper-deny-unknown-original-controls'
    elif case['new_action_requested'] is not False and (case['original_budget'] is None or case['original_spent'] is None or case['original_spent']>=case['original_budget']):q='paper-deny-new-action-budget'
    elif any(case[k] is not True for k in ['captured_target_qualified','captured_object_qualified']):q='paper-pending-unqualified-captured-data'
    elif any(case[k] is not True for k in ['receipt_commit_known','receipt_writer_trace_closed','final_observation_independent','custody_ACK_known','all_external_effects_accounted']):q='paper-pending-external-outcomes'
    else:q='paper-declared-finite-cut-review-question'
    return {'finite_cut_review_question':q,'qualified_captured_target_fact_retained':case['captured_target_qualified'] is True,'qualified_captured_object_fact_retained':case['captured_object_qualified'] is True,'original_failure_preserved':case['original_forward_failed'] is True,'known_mismatch_preserved':case['known_mismatch'] is True,'republish_permission':False,'actual_native_fact_or_action':None,'runtime_authority':False,'native_proof':False,'actual_closed':False}

def validate_review_shape(review,inputs,sources,policy):
    validate_policy(policy);candidate=json.loads(inputs['candidate400']);brief=json.loads(inputs['receipt_brief394']);dossier=json.loads(inputs['accepted384dossier'])
    exact(review['schema'],1,'integer schema');exact(review['step'],405,'integer405')
    exact(review['state'],'inactive-joint-whole-stage12-external-receipt-final-custody-review','inactive review')
    exact(review['scope'],candidate['scope'],'finite399-408scope');exact(review['candidate_id'],'JCP400-A','same draft')
    exact(review['boundaries'],candidate['boundaries'],'all original closed gates');exact(review['whole_original_requirements_remain_normative'],True,'whole original norms binding')
    for key,source in policy['reference_fields'].items():exact(review[key],sources['inputs'][source],'whole accepted source '+source)
    exact(review['whole_original316_stage12'],json.loads(inputs['publication_requirements316'])['immutable_design_facts']['stages'][12],'WHOLE original316 stage12 function/operation/guard/paths/seams')
    exact(review['whole_original384_causal_and_event_review'],{k:dossier[k] for k in policy['dossier_fields']},'WHOLE original384 causal/events/failure cuts/criteria/platforms')
    exact(review['whole_original323_publication_closure_and_clock'],{k:json.loads(inputs['original323'])[k] for k in ['closure_contract','clock_contract','fence_contract']},'whole original closure/clock/fence')
    exact(review['whole_original324_publication_and_guard'],{k:json.loads(inputs['original324'])[k] for k in ['publication_contract','guard_contract']},'whole original publication/guard')
    option=next(o for o in brief['options'] if o['id']=='explicit-producer-and-external-finalization-cut')
    exact(review['whole394_selected_for_drafting_option'],option,'WHOLE unselected394 amendment and guarantee losses')
    exact(review['whole394_declared_graph_questions'],brief['declared_graph_questions'],'both declared graph questions,no native proof')
    exact(review['whole394_proposed_terminal_cut'],brief['proposed_terminal_cut'],'whole original ten event terminal questions')
    exact(review['whole400_producer_receipt_custody_wording'],candidate['new_joint_wording'][4],'whole400 joint wording')
    exact([r['whole_original394_event'] for r in review['all10_event_joint_reconciliations']],brief['proposed_terminal_cut']['event_rows'],'ALL10 whole394 events')
    exact(review['all10_event_joint_reconciliations'],policy['expected_events'],'all exact joint event controls')
    exact(review['all6_external_role_obligation_questions'],policy['expected_roles'],'all6 own-effect role questions and null actual bindings')
    exact(review['exact_inactive_clause_replacements'],policy['expected_changes'],'three whole current/proposed explicit replacements')
    for row in review['exact_inactive_clause_replacements']:
        exact(row['whole_current_value'],pointer(json.loads(inputs[row['input_key']]),row['json_pointer']),'whole current clause independently bound')
        exact(row['approved'],False,'inactive replacement never approval')
    exact(review['exact_inactive_clause_replacements'][0]['whole_proposed_value'],json.loads(option['proposed_clause_text']['/immutable_design_facts/stages/12']),'exact394 producer amendment')
    exact(review['joint_proposed_statements'],policy['expected_statements'],'ten complete joint statements')
    for key in policy['null_fields']:exact(review[key],None,'no actual native state/selection/approval '+key)
    for key in policy['false_fields']:exact(review[key],False,'no unsafe shortcut/authority/approval '+key)
    for key in ['native_cases_run','native_proofs_added']:exact(review[key],0,'zero native progress')
    exact(review['remaining_joint_reviews'],candidate['nine_unresolved_joint_reviews'],'all9 joint blockers unresolved')
    exact(review['authored_hypothetical_cases'],policy['expected_cases'],'all24 paper questions')
    for case in review['authored_hypothetical_cases']:exact(hypothetical_case(case,policy)['finite_cut_review_question'],case['expected_question'],'paper finite custody question')
    exact(review['next_preparable_step_after_complete405_acceptance'],406,'406after full405acceptance');exact(review['conditional_close_step'],408,'same finite close');exact(review['no_automatic409'],True,'STOPafter408')
    return True

def validate_fixtures(fixtures, policy):
    validate_policy(policy)
    exact(sorted(fixtures), sorted(policy['fixture_canonical_sha256']), 'exact405 fixture set')
    for name, value in fixtures.items():
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole authored405 fixture ' + name)
    return True


def validate_repository(blobs, baseline, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(baseline), 'all2162 historical404 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            addition = policy['prefixes'][path].encode()
            if not raw.startswith(addition):
                raise ValueError('missing exact405 additive prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'all historical404 bytes unchanged ' + path)
    return True


def review(entry,proposal,inputs,source_blobs,sources,policy):
    validate_entry(entry,policy);validate_sources(inputs,source_blobs,sources,policy);validate_review_shape(proposal,inputs,sources,policy)
    return {'step': 405, 'state': 'prepared-inactive-stage12-receipt-custody-review-user-acceptance-pending', 'selected_options': None, 'approved_contract_migration': None, 'runtime_authority': False, 'last_confirmed_repository_pause': 398, 'strong_safe_pause': False, 'after_complete405_acceptance_next_preparable_step': 406, 'conditional_close_step': 408, 'after_confirmed408_next_authorized_stage': None}
