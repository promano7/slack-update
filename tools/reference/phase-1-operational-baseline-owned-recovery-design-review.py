#!/usr/bin/env python3
"""Validate supplied original baseline/owned/recovery designs without effects or restoration dispatch."""
import hashlib
import json
import re

def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(v,expected,label):
    if type(v) is not type(expected) or (v!=expected if isinstance(v,(set,bytes)) else canonical(v)!=canonical(expected)):raise ValueError(label)
    return True
POLICY_SHA='395324b6abb62b660409930db7dad8ab988e8c6982a777de1a83f70fd6b27ecc'
DESIGN_SHA='d8e6819ff6d5048d18b8e34e274490bc3accf7e866b7bc498ce6390c70c5258e'
BOUNDARIES={'C_port_open': False, 'actual_admission_protocol_implemented': False, 'actual_cryptography_proven': False, 'actual_durable_claim_proven': False, 'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None, 'actual_native_fence_proven': False, 'actual_native_refinement_complete': False, 'actual_platform_feasibility_proven': False, 'actual_single_launch_proven': False, 'actual_successor_selected': False, 'actual_writer_exclusion_proven': False, 'controller_action_required': False, 'current_step_strong_safe_pause': False, 'design_is_actual_native_refinement': False, 'design_is_actual_source_implementation': False, 'design_is_complete_native_graph': False, 'design_proposal_is_operational_implementation': False, 'execution_authorized': False, 'historical_binding_or_authority_reuse_allowed': False, 'kernel_package_edge_complete': False, 'last_confirmed_strong_safe_pause_step': 368, 'later_current_refresh_invalidates_repository_only_pause': False, 'machine_action_required': False, 'native_cases_run': 0, 'native_components_selected': False, 'native_graph_complete': False, 'native_proofs_added': 0, 'operational_conformance': False, 'operational_readiness': False, 'phase1_matrix_complete': False, 'phase2_open': False, 'production_entry_closed': True, 'reference_v1_frozen': False, 'runtime_authority': False, 'strong_safe_pause': False, 'target_machine_actions_authorized': False, 'version1_schema_frozen': False, 'actual_original_baseline_captured': False, 'actual_owned_commit_proven': False, 'actual_recovery_authorized': False, 'actual_target_unchanged_proven': False}

def validate_policy(p):
    exact(canonical(p),POLICY_SHA,'authored policy changed')
    return True

def validate_acceptance(c,r,p):
    validate_policy(p)
    exact(canonical(c),p['confirmation_canonical_sha256'],'complete confirmed372')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete received372 message')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'receipt SHA');exact(len(raw),c['receipt_size_bytes'],'receipt bytes')
    text=r['text'];contract=p['accepted372_contract']
    exact([s for s in text.splitlines() if s.startswith('PASS: ')],contract['expected_ordered372_labels'],'all215 ordered PASS labels')
    for key in ('expected_overlay_status','expected_commit_scope_status','expected_zero_failure_summary','synthetic_expected_commit_stats'):
        if text.count(contract[key])!=1:raise ValueError('single exact predecessor marker '+key)
    if text.count('[main f8059fc] '+contract['expected_commit_message'])!=1 or text.count('e6d341f..f8059fc  main -> main')!=1:raise ValueError('commit/push markers')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),contract['expected_created_paths'],'seven exact additions')
    head='f8059fc (HEAD -> main, origin/main, origin/HEAD) '+contract['expected_commit_message']
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
    validate_frozen_inputs(inputs,p);exact(canonical(design),DESIGN_SHA,'whole authored baseline owned recovery draft')
    exact(design['boundaries'],BOUNDARIES,'closed native and recovery gates')
    for number in ('322','323','324'):
        exact(design['full_original_contract'+number],inputs['freeze']['full_original_contracts320_327'][number],'whole original contract'+number)
    exact(design['primary_gap_ids'],inputs['plan369']['roadmap'][4]['primary_gap_ids'],'original373 primary gaps')
    gaps={row['inherited_gap']['id']:row for row in inputs['freeze']['full_original_native_gap_rows348']}
    for row in design['primary_gap_review']:exact(row['full_original_gap348'],gaps[row['id']],'whole original gap')
    g=inputs['freeze']['full_original_contracts320_327']['324']['document']
    exact([row['domain'] for row in design['baseline_domain_review']],g['resource_domains'],'seven full original baseline domains')
    exact(design['full_original_successor_sequence324'],g['successor_sequence'],'whole original ordered successor sequence')
    exact([row['original_sequence_name'] for row in design['proposed_phase_observation_rows']],g['successor_sequence'],'sixteen proposed phase observations')
    normative=inputs['freeze']['full_normative_rows347']
    exact(design['full_original_entry_trace347'],normative['original_phase_and_bootstrap_contract']['entry_trace'],'whole original entry trace')
    exact(design['full_original_owned_microsteps347'],normative['owned_stage7_microsteps'],'nine original full normative microsteps')
    exact([row['full_original_microstep347'] for row in design['owned_microstep_review']],normative['owned_stage7_microsteps'],'complete reviewed microstep bindings')
    exact([row['original_failure_event322'] for row in design['original_owned_failure_review']],inputs['freeze']['full_original_contracts320_327']['322']['document']['failure_events'],'all eight original owned failure events')
    exact([row['full_original372_candidate_family'] for row in design['inherited372_feasibility_blockers']],inputs['design372']['candidate_families'],'all ten original primitive blockers')
    exact([row['platform'] for row in design['platform_readiness']],['Slackware-15.0','Slackware-current'],'separate unknown platform bindings')
    return True

def review(design,c,r,inputs,sources,readme,p):
    validate_acceptance(c,r,p);validate_sources(sources,readme,p);validate_design(design,inputs,p)
    return json.loads(json.dumps({'schema':1,'step':373,'scope':design['scope'],
        'state':'draft-baseline-owned-recovery-review-prepared-user-return-pending','design':design,'boundaries':BOUNDARIES,
        'full_original_native_gap_rows348':inputs['freeze']['full_original_native_gap_rows348'],
        'full_normative_rows347':inputs['freeze']['full_normative_rows347'],
        'full_accepted_design370':inputs['design370'],'full_accepted_design371':inputs['design371'],'full_accepted_design372':inputs['design372'],
        'native_cases_run':0,'native_proofs_added':0,'runtime_authority':False,
        'actual_current_strong_safe_pause_confirmed':False}))
