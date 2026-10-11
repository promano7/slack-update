#!/usr/bin/env python3
"""Validate supplied target closure and captured-data publication designs without native effects."""
import hashlib
import json
import re

def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(v,expected,label):
    if type(v) is not type(expected) or (v!=expected if isinstance(v,(set,bytes)) else canonical(v)!=canonical(expected)):raise ValueError(label)
    return True
POLICY_SHA='9801e37f79149eb5893dc358db03261d3e97c03af9af481f33e58b932a686715'
DESIGN_SHA='8bfbf9b76992c2110abafe7c6e7ccf774efd59e15c5cb92c9d3d1fa1a0491b8b'
BOUNDARIES={'C_port_open': False, 'actual_admission_protocol_implemented': False, 'actual_cryptography_proven': False, 'actual_durable_claim_proven': False, 'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None, 'actual_native_fence_proven': False, 'actual_native_refinement_complete': False, 'actual_original_baseline_captured': False, 'actual_owned_commit_proven': False, 'actual_platform_feasibility_proven': False, 'actual_recovery_authorized': False, 'actual_single_launch_proven': False, 'actual_successor_selected': False, 'actual_target_unchanged_proven': False, 'actual_writer_exclusion_proven': False, 'controller_action_required': False, 'current_step_strong_safe_pause': False, 'design_is_actual_native_refinement': False, 'design_is_actual_source_implementation': False, 'design_is_complete_native_graph': False, 'design_proposal_is_operational_implementation': False, 'execution_authorized': False, 'historical_binding_or_authority_reuse_allowed': False, 'kernel_package_edge_complete': False, 'last_confirmed_strong_safe_pause_step': 368, 'later_current_refresh_invalidates_repository_only_pause': False, 'machine_action_required': False, 'native_cases_run': 0, 'native_components_selected': False, 'native_graph_complete': False, 'native_proofs_added': 0, 'operational_conformance': False, 'operational_readiness': False, 'phase1_matrix_complete': False, 'phase2_open': False, 'production_entry_closed': True, 'reference_v1_frozen': False, 'runtime_authority': False, 'strong_safe_pause': False, 'target_machine_actions_authorized': False, 'version1_schema_frozen': False, 'actual_target_closure_proven': False, 'actual_target_release_proven': False, 'actual_publication_controls_proven': False, 'actual_last_receipt_durable': False, 'actual_consumer_handoff_proven': False}

def validate_policy(p):
    exact(canonical(p),POLICY_SHA,'authored policy changed')
    return True

def validate_acceptance(c,r,p):
    validate_policy(p)
    exact(canonical(c),p['confirmation_canonical_sha256'],'complete confirmed373')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete received373 message')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'receipt SHA');exact(len(raw),c['receipt_size_bytes'],'receipt bytes')
    text=r['text'];contract=p['accepted373_contract']
    exact([s for s in text.splitlines() if s.startswith('PASS: ')],contract['expected_ordered373_labels'],'all276 ordered PASS labels')
    for key in ('expected_overlay_status','expected_commit_scope_status','expected_zero_failure_summary','synthetic_expected_commit_stats'):
        if text.count(contract[key])!=1:raise ValueError('single exact predecessor marker '+key)
    if text.count('[main 39f33f8] '+contract['expected_commit_message'])!=1 or text.count('f8059fc..39f33f8  main -> main')!=1:raise ValueError('commit/push markers')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),contract['expected_created_paths'],'seven exact additions')
    head='39f33f8 (HEAD -> main, origin/main, origin/HEAD) '+contract['expected_commit_message']
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
    if type(readme) is not bytes or sha(readme)!=p['readme_at_entry_sha256']:raise ValueError('premature README edit')
    return True

def validate_design(design,inputs,p):
    validate_frozen_inputs(inputs,p);exact(canonical(design),DESIGN_SHA,'whole authored target closure publication draft')
    exact(design['boundaries'],BOUNDARIES,'closed target publication native gates')
    freeze=inputs['freeze']
    for n in ('323','324','325','327'):exact(design['full_original_contract'+n],freeze['full_original_contracts320_327'][n],'whole original contract'+n)
    exact(design['full_original_publication_requirements316'],inputs['publication_requirements316'],'whole original316 publication requirements')
    exact(design['full_original_authority_windows347'],freeze['full_normative_rows347']['authority_window_reconciliation'],'nine whole authority windows')
    exact(design['full_original_independent_raw_groups335'],freeze['full_independent_raw_groups335'],'twelve whole independent raw groups')
    exact(design['primary_gap_ids'],inputs['plan369']['roadmap'][5]['primary_gap_ids'],'original374 primary gaps')
    gaps={row['inherited_gap']['id']:row for row in freeze['full_original_native_gap_rows348']}
    for row in design['primary_gap_review']:exact(row['full_original_gap348'],gaps[row['id']],'whole original gap')
    for suffix in ('baseline_domain_review','recovery_gate_review','recovery_branch_review','owned_microstep_review'):exact(design['full_accepted373_'+suffix],inputs['design373'][suffix],'whole original373 '+suffix)
    exact(design['inherited372_feasibility_blockers'],inputs['design373']['inherited372_feasibility_blockers'],'ten whole original primitive blockers')
    exact([row['platform'] for row in design['platform_readiness']],['Slackware-15.0','Slackware-current'],'separate unbound native closure platforms')
    return True

def review(design,c,r,inputs,sources,readme,p):
    validate_acceptance(c,r,p);validate_sources(sources,readme,p);validate_design(design,inputs,p)
    return json.loads(json.dumps({'schema':1,'step':374,'scope':design['scope'],
        'state':'draft-target-closure-publication-review-prepared-user-return-pending','design':design,'boundaries':BOUNDARIES,
        'full_original_native_gap_rows348':inputs['freeze']['full_original_native_gap_rows348'],
        'full_normative_rows347':inputs['freeze']['full_normative_rows347'],
        'full_accepted_design370':inputs['design370'],'full_accepted_design371':inputs['design371'],'full_accepted_design372':inputs['design372'],'full_accepted_design373':inputs['design373'],
        'native_cases_run':0,'native_proofs_added':0,'runtime_authority':False,
        'actual_current_strong_safe_pause_confirmed':False}))
