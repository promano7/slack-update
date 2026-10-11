#!/usr/bin/env python3
"""Validate supplied design readiness and future prerequisites without issuing authority."""
import hashlib
import json
import re

def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(v,expected,label):
    if type(v) is not type(expected) or (v!=expected if isinstance(v,(set,bytes)) else canonical(v)!=canonical(expected)):raise ValueError(label)
    return True
POLICY_SHA='5cdab1f5d9115cc989b6fa07af60af9715bfa94e5ce0c8563f3ecae37aecd759'
DESIGN_SHA='464aaf7d76bbf23d81386407fff728372293d3d82df60e407f5838b4db0d8a24'
BOUNDARIES={'C_port_open': False, 'actual_admission_protocol_implemented': False, 'actual_consumer_handoff_proven': False, 'actual_cryptography_proven': False, 'actual_durable_claim_proven': False, 'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_independent_collector_selected': False, 'actual_independent_expectations_proven': False, 'actual_independent_verifier_selected': False, 'actual_last_receipt_durable': False, 'actual_live_bindings': None, 'actual_native_comparison_proven': False, 'actual_native_concurrency_coverage_proven': False, 'actual_native_crash_schedule_proven': False, 'actual_native_fault_effectiveness_proven': False, 'actual_native_fence_proven': False, 'actual_native_microevents_selected': False, 'actual_native_refinement_complete': False, 'actual_original_baseline_captured': False, 'actual_owned_commit_proven': False, 'actual_platform_feasibility_proven': False, 'actual_proof_case_refinement_proven': False, 'actual_publication_controls_proven': False, 'actual_recovery_authorized': False, 'actual_single_launch_proven': False, 'actual_successor_selected': False, 'actual_target_closure_proven': False, 'actual_target_release_proven': False, 'actual_target_unchanged_proven': False, 'actual_writer_exclusion_proven': False, 'controller_action_required': False, 'current_step_strong_safe_pause': False, 'design_is_actual_native_refinement': False, 'design_is_actual_source_implementation': False, 'design_is_complete_native_graph': False, 'design_proposal_is_operational_implementation': False, 'execution_authorized': False, 'historical_binding_or_authority_reuse_allowed': False, 'kernel_package_edge_complete': False, 'last_confirmed_strong_safe_pause_step': 368, 'later_current_refresh_invalidates_repository_only_pause': False, 'machine_action_required': False, 'native_cases_run': 0, 'native_components_selected': False, 'native_graph_complete': False, 'native_proofs_added': 0, 'operational_conformance': False, 'operational_readiness': False, 'phase1_matrix_complete': False, 'phase2_open': False, 'production_entry_closed': True, 'reference_v1_frozen': False, 'runtime_authority': False, 'strong_safe_pause': False, 'target_machine_actions_authorized': False, 'version1_schema_frozen': False, 'future_test_authorization_issued': False, 'readiness_review_is_authorization': False, 'README_is_native_evidence': False}

def validate_policy(p):
    exact(canonical(p),POLICY_SHA,'authored policy changed')
    return True

def validate_acceptance(c,r,p):
    validate_policy(p)
    exact(canonical(c),p['confirmation_canonical_sha256'],'complete confirmed376')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete received376 message')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'receipt SHA');exact(len(raw),c['receipt_size_bytes'],'receipt bytes')
    text=r['text'];contract=p['accepted376_contract']
    exact([s for s in text.splitlines() if s.startswith('PASS: ')],contract['expected_ordered376_labels'],'all547 ordered PASS labels')
    for key in ('expected_overlay_status','expected_commit_scope_status','expected_zero_failure_summary','synthetic_expected_commit_stats'):
        if text.count(contract[key])!=1:raise ValueError('single exact predecessor marker '+key)
    if text.count('[main 24e5dcc] '+contract['expected_commit_message'])!=1 or text.count('2218052..24e5dcc  main -> main')!=1:raise ValueError('commit/push markers')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),contract['expected_created_paths'],'seven exact additions')
    head='24e5dcc (HEAD -> main, origin/main, origin/HEAD) '+contract['expected_commit_message']
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
    if type(readme) is not bytes or sha(readme)!=p['readme_postimage_sha256'] or sha(readme[-p['accepted_readme_size_bytes']:])!=p['readme_at_entry_sha256']:raise ValueError('README additive reconciliation drift')
    return True

def validate_design(design,inputs,p):
    validate_frozen_inputs(inputs,p);exact(canonical(design),DESIGN_SHA,'whole authored readiness and README review')
    exact(design['boundaries'],BOUNDARIES,'closed readiness gates')
    exact(design['primary_gap_ids'],inputs['plan369']['roadmap'][8]['primary_gap_ids'],'original377 no primary gap assignment')
    original=inputs['prerequisites']['prerequisite_rows']
    exact(design['full_original_prerequisite_rows'],original,'whole sixteen original prerequisite rows')
    exact([row['id'] for row in design['gap_readiness_review']],[row['id'] for row in original],'all sixteen original gap order')
    for row,source in zip(design['gap_readiness_review'],original):
        exact(row['full_original_prerequisite_row'],source,'whole original gap prerequisite')
        exact(row['whole_original_prerequisite_canonical_sha256'],canonical(source),'whole original gap source binding')
        exact(row['native_gap_closed'],False,'gap remains unresolved')
    for row in design['successor_design_findings']:exact(row['whole_accepted_design_canonical_sha256'],canonical(inputs['design'+str(row['step'])]),'whole successor findings binding')
    for key in ('stage12_receipt_causal_obligation','inherited372_feasibility_blockers'):exact(design[key],inputs['design376'][key],'whole inherited unresolved '+key)
    exact(design['readme_reconciliation']['postimage_sha256'],p['readme_postimage_sha256'],'authored README postimage')
    return True

def review(design,c,r,inputs,sources,readme,p):
    validate_acceptance(c,r,p);validate_sources(sources,readme,p);validate_design(design,inputs,p)
    return json.loads(json.dumps({'schema':1,'step':377,'scope':design['scope'],
        'state':'draft-design-readiness-readme-review-prepared-user-return-pending','design':design,'boundaries':BOUNDARIES,
        'full_original_native_gap_rows348':inputs['freeze']['full_original_native_gap_rows348'],
        'full_normative_rows347':inputs['freeze']['full_normative_rows347'],
        'full_accepted_design370':inputs['design370'],'full_accepted_design371':inputs['design371'],'full_accepted_design372':inputs['design372'],'full_accepted_design373':inputs['design373'],'full_accepted_design374':inputs['design374'],'full_accepted_design375':inputs['design375'],'full_accepted_design376':inputs['design376'],
        'native_cases_run':0,'native_proofs_added':0,'runtime_authority':False,
        'actual_current_strong_safe_pause_confirmed':False}))
