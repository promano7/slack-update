#!/usr/bin/env python3
"""Validate supplied issuer/admission/launch design data without service or dispatch."""
import hashlib
import json
import re

def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(v,expected,label):
    if type(v) is not type(expected) or (v!=expected if isinstance(v,(set,bytes)) else canonical(v)!=canonical(expected)):raise ValueError(label)
    return True
POLICY_SHA='1864e89448348af982074d975ec64c9b83477d54b68a1fb1a6fe5ec0b15e3668'
DESIGN_SHA='304191bcd745d3d5eede16f1944d5e26f8b0297b335b5781172be78e6c9d17df'
BOUNDARIES={'C_port_open': False, 'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None, 'actual_native_refinement_complete': False, 'actual_successor_selected': False, 'controller_action_required': False, 'current_step_strong_safe_pause': False, 'design_is_actual_native_refinement': False, 'design_is_actual_source_implementation': False, 'design_is_complete_native_graph': False, 'design_proposal_is_operational_implementation': False, 'execution_authorized': False, 'historical_binding_or_authority_reuse_allowed': False, 'kernel_package_edge_complete': False, 'last_confirmed_strong_safe_pause_step': 368, 'later_current_refresh_invalidates_repository_only_pause': False, 'machine_action_required': False, 'native_cases_run': 0, 'native_components_selected': False, 'native_graph_complete': False, 'native_proofs_added': 0, 'operational_conformance': False, 'operational_readiness': False, 'phase1_matrix_complete': False, 'phase2_open': False, 'production_entry_closed': True, 'reference_v1_frozen': False, 'runtime_authority': False, 'strong_safe_pause': False, 'target_machine_actions_authorized': False, 'version1_schema_frozen': False, 'actual_admission_protocol_implemented': False, 'actual_cryptography_proven': False, 'actual_durable_claim_proven': False, 'actual_single_launch_proven': False}

def validate_policy(p):
    exact(canonical(p),POLICY_SHA,'authored policy changed')
    return True

def validate_acceptance(c,r,p):
    validate_policy(p)
    exact(canonical(c),p['confirmation_canonical_sha256'],'complete confirmed370')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete received370 message')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'receipt SHA');exact(len(raw),c['receipt_size_bytes'],'receipt bytes')
    text=r['text'];contract=p['accepted370_contract']
    exact([s for s in text.splitlines() if s.startswith('PASS: ')],contract['expected_ordered370_labels'],'all133 ordered PASS labels')
    for key in ('expected_overlay_status','expected_commit_scope_status','expected_zero_failure_summary','synthetic_expected_commit_stats'):
        if text.count(contract[key])!=1:raise ValueError('single exact predecessor marker '+key)
    if text.count('[main 607d43c] '+contract['expected_commit_message'])!=1 or text.count('3a99d10..607d43c  main -> main')!=1:raise ValueError('commit/push markers')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),contract['expected_created_paths'],'seven exact additions')
    head='607d43c (HEAD -> main, origin/main, origin/HEAD) '+contract['expected_commit_message']
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
    validate_frozen_inputs(inputs,p);exact(canonical(design),DESIGN_SHA,'whole authored draft admission design')
    exact(design['boundaries'],BOUNDARIES,'all closed design/native gates')
    a=inputs['freeze']['full_original_contracts320_327']['320'];h=inputs['freeze']['full_original_contracts320_327']['321']
    exact(design['full_original_admission_contract320'],a,'whole original320 contract')
    exact(design['full_original_handoff_contract321'],h,'whole original321 contract')
    exact(design['primary_gap_ids'],inputs['plan369']['roadmap'][2]['primary_gap_ids'],'three original primary assignments')
    for field,key in [('full_original_authentication321','authentication'),('full_original_bootstrap321','bootstrap'),('full_original_FD_policy321','fd_policy'),('full_original_lifecycle321','lifecycle')]:exact(design[field],h['document'][key],'whole original321 '+key)
    exact(design['full_original_stage_mapping320'],a['document']['stage_mapping'],'whole original stage map')
    exact([row['field'] for row in design['authenticated_original_fields']],h['document']['authentication']['covered_fields'],'all14 authenticated original fields')
    exact([row['full_original_failure_case320'] for row in design['original_failure_cut_review']],a['document']['failure_cases'],'all10 full original failure cut rows')
    for number in ('320','321'):
        exact(design['full_original_proof_obligations'+number],inputs['freeze']['full_original_contracts320_327'][number]['document']['future_proof_obligations'],'complete original proof obligations'+number)
    exact([row['platform'] for row in design['platform_readiness']],['Slackware-15.0','Slackware-current'],'separate unbound target records')
    return True

def review(design,c,r,inputs,sources,readme,p):
    validate_acceptance(c,r,p);validate_sources(sources,readme,p);validate_design(design,inputs,p)
    return json.loads(json.dumps({'schema':1,'step':371,'scope':design['scope'],
        'state':'draft-admission-launch-review-prepared-user-return-pending','design':design,'boundaries':BOUNDARIES,
        'full_original_native_gap_rows348':inputs['freeze']['full_original_native_gap_rows348'],
        'full_normative_rows347':inputs['freeze']['full_normative_rows347'],
        'all_original370_roles_and_interfaces':inputs['design370'],
        'native_cases_run':0,'native_proofs_added':0,'runtime_authority':False,
        'actual_current_strong_safe_pause_confirmed':False}))
