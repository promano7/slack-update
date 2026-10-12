#!/usr/bin/env python3
"""Review inactive whole-entry/oracle proposals from supplied data only."""
import hashlib
import json
import re

POLICY_SHA = 'e40cb52595527afe88c33ef80760aa2de1ef27c24c89062b6659efda3a15f3e5'

def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def canonical(value):
    return sha(json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True).encode())


def exact(value, expected, label):
    if type(value) is not type(expected) or (value != expected if type(value) is bytes else canonical(value) != canonical(expected)):
        raise ValueError(label)
    return True


def validate_policy(policy):
    return exact(canonical(policy), POLICY_SHA, 'authored406 policy substitution')


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
    exact(entry['confirmation'], policy['expected_confirmation405'], 'whole accepted405 supplied-return confirmation')
    raw = entry['receipt']['text'].encode('utf-8')
    exact(sha(raw), policy['receipt_sha256'], 'complete disclosed405 transcript SHA')
    exact(len(raw), policy['receipt_size_bytes'], 'complete405 transcript length')
    exact(entry['receipt']['capture_basis'], entry['confirmation']['capture_basis'], 'transcription provenance disclosed')
    exact([s for s in entry['receipt']['text'].splitlines() if s.startswith('PASS: ')], policy['receipt_pass_labels'], 'all81 ordered405 PASS labels')
    exact(re.findall(r'^ create mode 100644 (.+)$', entry['receipt']['text'], re.M), policy['receipt_create_paths'], 'eight405 exact creates')
    for marker in policy['receipt_single_markers']:
        exact(entry['receipt']['text'].count(marker), 1, 'single405 acceptance marker')
    exact(entry['receipt']['text'].split(policy['receipt_push_marker'])[1], policy['receipt_final_tail'], 'reported empty final status and two matching405 heads')
    return True


def validate_sources(inputs, source_blobs, sources, policy):
    validate_policy(policy)
    exact(sorted(inputs), sorted(sources['inputs']), 'all91 whole JSON inputs')
    for key, row in sources['inputs'].items():
        exact(sha(inputs[key]), row['sha256'], 'whole input bytes ' + key)
        exact(canonical(json.loads(inputs[key])), row['canonical_sha256'], 'whole input canonical ' + key)
    previous = json.loads(inputs['sources405'])
    inherited = {k: v for k, v in sources['inputs'].items() if k not in ['publication405', 'sources405', 'policy405']}
    exact(inherited, previous['inputs'], 'all88 original405 input bindings unchanged')
    exact(sources['previous_readme_binding'], previous['readme'], 'previous accepted README binding retained')
    roots = sources['inert_roots'] + sources['reviewer_roots'] + [sources['readme']]
    exact(sorted(source_blobs), sorted(r['path'] for r in roots), 'all32 pure/inert/accepted405 README roots')
    for row in roots:
        exact(sha(source_blobs[row['path']]), row['sha256'], 'whole root bytes ' + row['path'])
    return True


def paper_record(record,policy):
    if type(record) is not dict or sorted(record)!=sorted(policy['paper_record_fields']):raise ValueError('whole paper record required')
    for key,value in record.items():
        if value is None:continue
        if type(value) is not list:raise ValueError('ordered list/unknown required')
        if key=='raw_statuses':
            if len(value)!=3 or any(type(x) is not int or x < -1 for x in value):raise ValueError('three exact integer raw statuses required')
        else:
            if any(type(x) is not str for x in value):raise ValueError('exact ordered string vector required')
            if key=='raw_stream_hex' and (len(value)!=6 or any(re.fullmatch(r'(?:[0-9a-f]{2})*',x) is None for x in value)):raise ValueError('six complete toy byte streams required')
    return True

def hypothetical_case(case,policy):
    """Compare toy supplied vectors as a review question,never native evidence."""
    validate_policy(policy);exact(case['hypothetical_only'],True,'paper only');exact(case['actual_native_evidence'],None,'no native observations');exact(case['runtime_authority'],False,'no authority')
    for key in policy['paper_bool_fields']:
        if case[key] is not None and type(case[key]) is not bool:raise ValueError('bool/unknown required')
    paper_record(case['expected'],policy);paper_record(case['observed'],policy)
    pending=[k for k in policy['paper_record_fields'] if case['expected'][k] is None or case['observed'][k] is None]
    disagreements=[k for k in policy['paper_record_fields'] if k not in pending and case['expected'][k]!=case['observed'][k]]
    qualified=all(case[k] is True for k in ['independent_expectations_known','independent_raw_capture_known','same_original_run_binding_known','separate_platform_binding_known'])
    known_mismatch=case['previous_known_mismatch'] is True or (qualified and bool(disagreements))
    statuses=case['observed']['raw_statuses']
    if known_mismatch:q='paper-deny-known-mismatch'
    elif case['independent_expectations_known'] is not True:q='paper-pending-independent-expectations'
    elif any(case[k] is not True for k in ['consumed_source_graph_complete','checked_to_used_identity_known']):q='paper-deny-consumed-source-gap'
    elif any(case[k] is not True for k in ['same_original_run_binding_known','separate_platform_binding_known']):q='paper-deny-run-platform-binding'
    elif case['independent_raw_capture_known'] is not True or pending:q='paper-pending-full-raw-data'
    elif any(x==-1 for x in statuses):q='paper-unattempted-not-success'
    elif statuses[0]!=0 or statuses[1] not in [0,20] or (statuses[1]==20 and (case['observed']['install_selector']!=[] or case['observed']['install_effects']!=[])) or statuses[2]!=0 or case['observed']['upgrade_selector']!=['synthetic-target']:q='paper-deny-original-status-selector-condition'
    elif any(case[k] is not True for k in ['positive_reference_known','negative_cut_reached_known','negative_cut_effective_known']):q='paper-pending-effective-fault-controls'
    elif case['own_actor_controls_known'] is not True:q='paper-deny-own-actor-controls'
    elif case['custody_known'] is not True:q='paper-pending-custody'
    elif case['original_forward_failed'] is None or case['previous_known_mismatch'] is None:q='paper-pending-original-outcome-state'
    elif case['original_forward_failed'] is True:q='paper-contained-original-failure-review-question'
    else:q='paper-full-raw-review-question'
    return {'oracle_review_question':q,'paper_qualified_mismatch_preserved':known_mismatch,'declared_disagreement_fields':disagreements,'pending_raw_fields':pending,'original_failure_preserved':case['original_forward_failed'] is True,'original_forward_failure_fact':case['original_forward_failed'],'prior_known_mismatch_fact':case['previous_known_mismatch'],'pending_qualification_fields':[k for k in policy['paper_bool_fields'] if case[k] is None],'actual_native_fact_or_action':None,'runtime_authority':False,'native_proof':False,'native_conformance':False,'actual_closed':False}

def validate_review_shape(review,inputs,sources,policy):
    validate_policy(policy);candidate=json.loads(inputs['candidate400']);dossier=json.loads(inputs['accepted385dossier']);oracle=json.loads(inputs['design375'])
    exact(review['schema'],1,'integer schema');exact(review['step'],406,'integer406');exact(review['state'],'inactive-joint-whole-entry-independent-two-platform-oracle-review','inactive review')
    exact(review['scope'],candidate['scope'],'finite399-408scope');exact(review['candidate_id'],'JCP400-A','same author draft');exact(review['boundaries'],candidate['boundaries'],'all original closed gates');exact(review['whole_original_requirements_remain_normative'],True,'whole original norms binding')
    for key,source in policy['reference_fields'].items():exact(review[key],sources['inputs'][source],'whole accepted source '+source)
    exact(sorted(review['whole_normative_sections']),sorted(policy['normative_section_fields']),'whole source scope')
    for key,names in policy['normative_section_fields'].items():exact(review['whole_normative_sections'][key],{k:json.loads(inputs[key])[k] for k in names},'WHOLE normative source statements '+key)
    for key,source,option in [('whole395_author_draft_retention_option','entry_brief395','complete-protected-source-consumption-hypothesis'),('whole396_author_draft_retention_option','oracle_brief396','protected-independent-raw-oracle-hypothesis')]:exact(review[key],next(o for o in json.loads(inputs[source])['options'] if o['id']==option),'whole unselected retention option')
    exact(review['whole400_entry_oracle_wording'],candidate['new_joint_wording'][5],'whole400 joint source/oracle hypothesis')
    exact([r['whole_original385_surface'] for r in review['all8_source_surface_reconciliations']],dossier['graph_surface_review'],'ALL8 WHOLE source surfaces')
    exact(review['all8_source_surface_reconciliations'],policy['expected_surfaces'],'all8 candidate surface constraints')
    exact([r['whole_original375_role'] for r in review['all6_oracle_role_reconciliations']],oracle['role_trust_review'],'ALL6 whole original oracle roles')
    exact(review['all6_oracle_role_reconciliations'],policy['expected_roles'],'all6 candidate own-source/actor role constraints')
    exact([r['whole_original375_fault_control'] for r in review['all6_fault_control_reconciliations']],oracle['fault_control_review'],'ALL6 whole original fault controls')
    exact(review['all6_fault_control_reconciliations'],policy['expected_faults'],'all6 reached/effective/own-effect control constraints')
    exact(review['all52_original_case_joint_reconciliations'],policy['expected_case_rows'],'ALL52 individually bound case requirements')
    for n,row in enumerate(review['all52_original_case_joint_reconciliations']):
        original=oracle['case_evidence_review'][n];exact(row['position'],n,'case position');exact(row['source_key'],'design375','whole case source');exact(row['json_pointer'],'/case_evidence_review/'+str(n),'exact source pointer');exact(row['whole_original_case_evidence_canonical_sha256'],canonical(original),'whole case-evidence object independently bound');exact((row['platform'],row['case_id']),(original['platform'],original['case_id']),'same whole platform-case tuple')
    exact(review['joint_proposed_statements'],policy['expected_statements'],'nine complete joint source/oracle statements')
    exact(review['verifier_may_author_independent_expectations'],True,'verifier may author independent expectations')
    for key in policy['null_fields']:exact(review[key],None,'no actual native state/selection/approval '+key)
    for key in policy['false_fields']:exact(review[key],False,'no unsafe shortcut/native/approval '+key)
    for key in ['native_cases_run','native_proofs_added']:exact(review[key],0,'zero native progress')
    exact(review['remaining_joint_reviews'],candidate['nine_unresolved_joint_reviews'],'all9 joint blockers unresolved')
    exact(review['authored_hypothetical_cases'],policy['expected_cases'],'all29 paper witnesses')
    for case in review['authored_hypothetical_cases']:exact(hypothetical_case(case,policy)['oracle_review_question'],case['expected_question'],'paper full ordered raw question')
    exact(review['next_preparable_step_after_complete406_acceptance'],407,'407after full406acceptance');exact(review['conditional_close_step'],408,'same finite close');exact(review['no_automatic409'],True,'STOPafter408')
    return True

def validate_fixtures(fixtures, policy):
    validate_policy(policy)
    exact(sorted(fixtures), sorted(policy['fixture_canonical_sha256']), 'exact406 fixture set')
    for name, value in fixtures.items():
        exact(canonical(value), policy['fixture_canonical_sha256'][name], 'whole authored406 fixture ' + name)
    return True


def validate_repository(blobs, baseline, policy):
    validate_policy(policy)
    exact(sorted(blobs), sorted(baseline), 'all2170 historical405 paths')
    for path, digest in baseline.items():
        raw = blobs[path]
        if path in policy['prefixes']:
            addition = policy['prefixes'][path].encode()
            if not raw.startswith(addition):
                raise ValueError('missing exact406 additive prefix')
            raw = raw[len(addition):]
        exact(sha(raw), digest, 'all historical405 bytes unchanged ' + path)
    return True


def review(entry,proposal,inputs,source_blobs,sources,policy):
    validate_entry(entry,policy);validate_sources(inputs,source_blobs,sources,policy);validate_review_shape(proposal,inputs,sources,policy)
    return {'step': 406, 'state': 'prepared-inactive-whole-entry-two-platform-oracle-user-acceptance-pending', 'selected_options': None, 'approved_contract_migration': None, 'runtime_authority': False, 'last_confirmed_repository_pause': 398, 'strong_safe_pause': False, 'after_complete406_acceptance_next_preparable_step': 407, 'conditional_close_step': 408, 'after_confirmed408_next_authorized_stage': None}
