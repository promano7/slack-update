#!/usr/bin/env python3
"""Validate supplied per-platform primitive comparisons without native lookup or dispatch."""
import hashlib
import json
import re

def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(v,expected,label):
    if type(v) is not type(expected) or (v!=expected if isinstance(v,(set,bytes)) else canonical(v)!=canonical(expected)):raise ValueError(label)
    return True
POLICY_SHA='6ffc91af4769c3a45286ac01c66e28557ca4b8819a30d10f58f1b9d8aba3b63f'
DESIGN_SHA='356a079d87b3cb96b6195949a83f9ea1156711fe20aab3d7467a5ea92b54ba40'
BOUNDARIES={'C_port_open': False, 'actual_admission_protocol_implemented': False, 'actual_cryptography_proven': False, 'actual_durable_claim_proven': False, 'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_live_bindings': None, 'actual_native_refinement_complete': False, 'actual_single_launch_proven': False, 'actual_successor_selected': False, 'controller_action_required': False, 'current_step_strong_safe_pause': False, 'design_is_actual_native_refinement': False, 'design_is_actual_source_implementation': False, 'design_is_complete_native_graph': False, 'design_proposal_is_operational_implementation': False, 'execution_authorized': False, 'historical_binding_or_authority_reuse_allowed': False, 'kernel_package_edge_complete': False, 'last_confirmed_strong_safe_pause_step': 368, 'later_current_refresh_invalidates_repository_only_pause': False, 'machine_action_required': False, 'native_cases_run': 0, 'native_components_selected': False, 'native_graph_complete': False, 'native_proofs_added': 0, 'operational_conformance': False, 'operational_readiness': False, 'phase1_matrix_complete': False, 'phase2_open': False, 'production_entry_closed': True, 'reference_v1_frozen': False, 'runtime_authority': False, 'strong_safe_pause': False, 'target_machine_actions_authorized': False, 'version1_schema_frozen': False, 'actual_platform_feasibility_proven': False, 'actual_native_fence_proven': False, 'actual_writer_exclusion_proven': False}

def validate_policy(p):
    exact(canonical(p),POLICY_SHA,'authored policy changed')
    return True

def validate_acceptance(c,r,p):
    validate_policy(p)
    exact(canonical(c),p['confirmation_canonical_sha256'],'complete confirmed371')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete received371 message')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'receipt SHA');exact(len(raw),c['receipt_size_bytes'],'receipt bytes')
    text=r['text'];contract=p['accepted371_contract']
    exact([s for s in text.splitlines() if s.startswith('PASS: ')],contract['expected_ordered371_labels'],'all151 ordered PASS labels')
    for key in ('expected_overlay_status','expected_commit_scope_status','expected_zero_failure_summary','synthetic_expected_commit_stats'):
        if text.count(contract[key])!=1:raise ValueError('single exact predecessor marker '+key)
    if text.count('[main e6d341f] '+contract['expected_commit_message'])!=1 or text.count('607d43c..e6d341f  main -> main')!=1:raise ValueError('commit/push markers')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),contract['expected_created_paths'],'seven exact additions')
    head='e6d341f (HEAD -> main, origin/main, origin/HEAD) '+contract['expected_commit_message']
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
    validate_frozen_inputs(inputs,p);exact(canonical(design),DESIGN_SHA,'whole authored primitive comparison')
    exact(design['boundaries'],BOUNDARIES,'all closed native gates')
    for number in ('321','323','324'):
        exact(design['full_original_contract'+number],inputs['freeze']['full_original_contracts320_327'][number],'whole original contract'+number)
    exact(design['primary_gap_ids'],inputs['plan369']['roadmap'][3]['primary_gap_ids'],'original372 primary gaps')
    gaps={row['inherited_gap']['id']:row for row in inputs['freeze']['full_original_native_gap_rows348']}
    for row in design['primary_gap_review']:exact(row['full_original_gap348'],gaps[row['id']],'whole original gap')
    ids=[row['id'] for row in design['candidate_families']]
    exact([(row['platform'],row['family_id']) for row in design['separate_platform_assessments']],[(platform,id) for platform in ('Slackware-15.0','Slackware-current') for id in ids],'separate ordered twenty assessments')
    domains=inputs['freeze']['full_original_contracts320_327']['324']['document']['resource_domains']
    exact([(row['platform'],row['domain']) for row in design['separate_platform_writer_domains']],[(platform,domain) for platform in ('Slackware-15.0','Slackware-current') for domain in domains],'fourteen original writer-domain rows')
    refs={row['id'] for row in design['primary_source_review']}
    for row in design['candidate_families']:
        if not set(row['primary_source_ids'])<=refs:raise ValueError('unknown primary citation')
    return True

def review(design,c,r,inputs,sources,readme,p):
    validate_acceptance(c,r,p);validate_sources(sources,readme,p);validate_design(design,inputs,p)
    return json.loads(json.dumps({'schema':1,'step':372,'scope':design['scope'],
        'state':'draft-native-platform-primitives-review-prepared-user-return-pending','design':design,'boundaries':BOUNDARIES,
        'full_original_native_gap_rows348':inputs['freeze']['full_original_native_gap_rows348'],
        'full_normative_rows347':inputs['freeze']['full_normative_rows347'],
        'full_accepted_design370':inputs['design370'],'full_accepted_design371':inputs['design371'],
        'native_cases_run':0,'native_proofs_added':0,'runtime_authority':False,
        'actual_current_strong_safe_pause_confirmed':False}))
