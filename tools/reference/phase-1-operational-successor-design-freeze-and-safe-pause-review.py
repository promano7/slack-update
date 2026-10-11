#!/usr/bin/env python3
"""Validate supplied successor design freeze and conditional scoped pause; never confirm the final user return or issue authority."""
import hashlib
import json
import re

def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(v,expected,label):
    if type(v) is not type(expected) or (v!=expected if isinstance(v,(set,bytes)) else canonical(v)!=canonical(expected)):raise ValueError(label)
    return True
POLICY_SHA='0a5a05a7a863317966c22cb86a927d8f555f32dbc7ec97c0066fdc181886492e'
FREEZE_SHA='94f014db22b98f34c415933b72823a513d5f4bc4752deae65a7e6cbc22c2de5d'
PAUSE_SHA='d10e8791ec5e63c1bf08fd05c6dba69c248876263d7d46df99f25a8c4b5291af'
BOUNDARIES={'C_port_open': False, 'README_is_native_evidence': False, 'actual_admission_protocol_implemented': False, 'actual_consumer_handoff_proven': False, 'actual_cryptography_proven': False, 'actual_durable_claim_proven': False, 'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_independent_collector_selected': False, 'actual_independent_expectations_proven': False, 'actual_independent_verifier_selected': False, 'actual_last_receipt_durable': False, 'actual_live_bindings': None, 'actual_native_comparison_proven': False, 'actual_native_concurrency_coverage_proven': False, 'actual_native_crash_schedule_proven': False, 'actual_native_fault_effectiveness_proven': False, 'actual_native_fence_proven': False, 'actual_native_microevents_selected': False, 'actual_native_refinement_complete': False, 'actual_original_baseline_captured': False, 'actual_owned_commit_proven': False, 'actual_platform_feasibility_proven': False, 'actual_proof_case_refinement_proven': False, 'actual_publication_controls_proven': False, 'actual_recovery_authorized': False, 'actual_single_launch_proven': False, 'actual_successor_selected': False, 'actual_target_closure_proven': False, 'actual_target_release_proven': False, 'actual_target_unchanged_proven': False, 'actual_writer_exclusion_proven': False, 'controller_action_required': False, 'current_step_strong_safe_pause': False, 'design_is_actual_native_refinement': False, 'design_is_actual_source_implementation': False, 'design_is_complete_native_graph': False, 'design_proposal_is_operational_implementation': False, 'execution_authorized': False, 'future_test_authorization_issued': False, 'historical_binding_or_authority_reuse_allowed': False, 'kernel_package_edge_complete': False, 'last_confirmed_strong_safe_pause_step': 368, 'later_current_refresh_invalidates_repository_only_pause': False, 'machine_action_required': False, 'native_cases_run': 0, 'native_components_selected': False, 'native_graph_complete': False, 'native_proofs_added': 0, 'operational_conformance': False, 'operational_readiness': False, 'phase1_matrix_complete': False, 'phase2_open': False, 'production_entry_closed': True, 'readiness_review_is_authorization': False, 'reference_v1_frozen': False, 'runtime_authority': False, 'strong_safe_pause': False, 'target_machine_actions_authorized': False, 'version1_schema_frozen': False}

def validate_policy(p):
    exact(canonical(p),POLICY_SHA,'authored policy changed')
    return True

def validate_acceptance(c,r,p):
    validate_policy(p)
    exact(canonical(c),p['confirmation_canonical_sha256'],'complete confirmed377')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete received377 message')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'receipt SHA');exact(len(raw),c['receipt_size_bytes'],'receipt bytes')
    text=r['text'];contract=p['accepted377_contract']
    exact([s for s in text.splitlines() if s.startswith('PASS: ')],contract['expected_ordered377_labels'],'all332 ordered PASS labels')
    for key in ('expected_overlay_status','expected_commit_scope_status','expected_zero_failure_summary','synthetic_expected_commit_stats'):
        if text.count(contract[key])!=1:raise ValueError('single exact predecessor marker '+key)
    if text.count('[main 009a8c5] '+contract['expected_commit_message'])!=1 or text.count('24e5dcc..009a8c5  main -> main')!=1:raise ValueError('commit/push markers')
    for marker in contract['expected_additional_overlay_markers']:
        if text.count(marker)!=1:raise ValueError('single exact predecessor overlay marker')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),contract['expected_created_paths'],'seven exact predecessor additions')
    head='009a8c5 (HEAD -> main, origin/main, origin/HEAD) '+contract['expected_commit_message']
    if text.count(head)!=2 or not text.endswith(head+'\n'+head+'\npromano@pc-arch ~/Descargas $ \n'):raise ValueError('complete reported clean matching-head ending')
    return True

def validate_frozen_inputs(inputs,p):
    validate_policy(p)
    exact(set(inputs),set(p['input_paths']),'all complete frozen inputs')
    for key,v in inputs.items():exact(canonical(v),p['input_canonical_sha256'][key],'full frozen input '+key)
    return True

def validate_sources(sources,readme,p):
    validate_policy(p);exact(set(sources),{r['path'] for r in p['source_roots']},'four historical roots')
    for row in p['source_roots']:
        raw=sources[row['path']]
        if type(raw) is not bytes or sha(raw)!=row['sha256'] or len(raw)!=row['size_bytes']:raise ValueError('source drift')
    if type(readme) is not bytes or sha(readme)!=p['readme_at_entry_sha256']:raise ValueError('accepted377 README drift')
    return True

def validate_freeze(freeze,pause,inputs,p):
    validate_frozen_inputs(inputs,p);exact(canonical(freeze),FREEZE_SHA,'whole authored successor design freeze')
    exact(freeze['boundaries'],BOUNDARIES,'all native and pause gates closed')
    original=inputs['freeze'];plan=inputs['plan369'];previous=inputs['design377']
    exact(freeze['full_roadmap369_378'],plan['roadmap'],'whole ten-stage bounded roadmap')
    exact(freeze['primary_gap_ids'],plan['roadmap'][9]['primary_gap_ids'],'no378primarygap narrowing')
    for key in ('full_original_contracts320_327','full_normative_rows347','full_original_native_gap_rows348','full_qualified_proof_rows347','full_native_case_rows347','full_independent_raw_groups335','ordered_required_proof_case_relations'):exact(freeze[key],original[key],'whole pending original '+key)
    exact(freeze['full_original_prerequisite_rows365'],previous['full_original_prerequisite_rows'],'whole sixteen original prerequisites')
    for suffix in ('gap_readiness_review','successor_design_findings','unresolved_conflict_review','future_test_entry_prerequisites','future_operational_readiness_prerequisites'):exact(freeze['full_accepted377_'+suffix],previous[suffix],'whole accepted377 '+suffix)
    for key in ('stage12_receipt_causal_obligation','inherited372_feasibility_blockers'):exact(freeze[key],previous[key],'whole unresolved inherited '+key)
    exact(freeze['readme']['full_accepted377_reconciliation'],previous['readme_reconciliation'],'whole acceptedREADMEreconciliation')
    exact(freeze['readme']['accepted377_exact_sha256'],p['readme_at_entry_sha256'],'accepted377README exact')
    exact(freeze['after_final_acceptance'],plan['pause_policy'],'stop/noautomatic379/originalconditions')
    exact([row['step'] for row in freeze['accepted_checkpoint_chain369_377']],list(range(369,378)),'all nine accepted predecessor checkpoints')
    for row in freeze['accepted_checkpoint_chain369_377']:
        confirmation=row['full_external_confirmation']
        exact(confirmation['step'],row['step'],'actual predecessor step')
        exact(row['whole_confirmation_canonical_sha256'],canonical(confirmation),'whole original external confirmation')
        exact(confirmation['runtime_authority'],False,'no predecessor grant')
        exact(confirmation['strong_safe_pause'],False,'no predecessor new pause')
    validate_pause_conditions(pause,freeze,inputs,p)
    return True

def validate_pause_conditions(pause,freeze,inputs,p):
    validate_policy(p);exact(canonical(pause),PAUSE_SHA,'whole authored conditional pause conditions')
    exact(canonical(pause),freeze['pause_conditions_canonical_sha256'],'freeze to pause binding')
    exact([row['id'] for row in pause['conditions']],inputs['plan369']['pause_policy']['original_condition_ids'],'all nine original scoped condition identities')
    exact([row['position'] for row in pause['conditions']],list(range(9)),'whole original condition order')
    for row,original in zip(pause['conditions'],inputs['pause']['conditions']):
        exact(row['full_original_condition368'],original,'whole original condition368')
        exact(row['full_original_condition358'],original['full_original_condition358'],'whole original condition358')
        exact(row['current378_actual_user_confirmation'],None,'no current378 confirmation')
        exact(row['actual_native_evidence'],None,'no native evidence inferred')
    exact(pause['after_final_acceptance'],inputs['plan369']['pause_policy'],'same final stop policy')
    exact(pause['actual_strong_safe_pause_confirmed'],False,'candidate not confirmed')
    return True

def review(freeze,pause,c,r,inputs,sources,readme,p):
    validate_acceptance(c,r,p);validate_sources(sources,readme,p);validate_freeze(freeze,pause,inputs,p)
    return json.loads(json.dumps({'schema':1,'step':378,'scope':freeze['scope'],'state':freeze['state'],
        'freeze':freeze,'pause_conditions':pause,'boundaries':BOUNDARIES,'full_frozen_inputs':inputs,
        'repository_review_eligible_for_conditional_pause':True,'private_eligibility_is_actual_confirmation':False,
        'actual_current_strong_safe_pause_confirmed':False,'native_cases_run':0,'native_proofs_added':0,
        'runtime_authority':False,'next_authorized_stage_after378':None,'no_automatic379':True}))
