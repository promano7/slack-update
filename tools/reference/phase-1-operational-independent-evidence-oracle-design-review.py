#!/usr/bin/env python3
"""Validate supplied independent evidence and oracle requirements without native collection or comparison."""
import hashlib
import json
import re

def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(v,expected,label):
    if type(v) is not type(expected) or (v!=expected if isinstance(v,(set,bytes)) else canonical(v)!=canonical(expected)):raise ValueError(label)
    return True
POLICY_SHA='9600e24807f3ed857da9d5b4921d063416276f58ed3885679358db70974e9f42'
DESIGN_SHA='95f1b490684639ace6223d3362383e7b3666ed26010c38c23f82d3fc62aebceb'
BOUNDARIES={'C_port_open': False, 'actual_admission_protocol_implemented': False, 'actual_consumer_handoff_proven': False, 'actual_cryptography_proven': False, 'actual_durable_claim_proven': False, 'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_last_receipt_durable': False, 'actual_live_bindings': None, 'actual_native_fence_proven': False, 'actual_native_refinement_complete': False, 'actual_original_baseline_captured': False, 'actual_owned_commit_proven': False, 'actual_platform_feasibility_proven': False, 'actual_publication_controls_proven': False, 'actual_recovery_authorized': False, 'actual_single_launch_proven': False, 'actual_successor_selected': False, 'actual_target_closure_proven': False, 'actual_target_release_proven': False, 'actual_target_unchanged_proven': False, 'actual_writer_exclusion_proven': False, 'controller_action_required': False, 'current_step_strong_safe_pause': False, 'design_is_actual_native_refinement': False, 'design_is_actual_source_implementation': False, 'design_is_complete_native_graph': False, 'design_proposal_is_operational_implementation': False, 'execution_authorized': False, 'historical_binding_or_authority_reuse_allowed': False, 'kernel_package_edge_complete': False, 'last_confirmed_strong_safe_pause_step': 368, 'later_current_refresh_invalidates_repository_only_pause': False, 'machine_action_required': False, 'native_cases_run': 0, 'native_components_selected': False, 'native_graph_complete': False, 'native_proofs_added': 0, 'operational_conformance': False, 'operational_readiness': False, 'phase1_matrix_complete': False, 'phase2_open': False, 'production_entry_closed': True, 'reference_v1_frozen': False, 'runtime_authority': False, 'strong_safe_pause': False, 'target_machine_actions_authorized': False, 'version1_schema_frozen': False, 'actual_independent_collector_selected': False, 'actual_independent_verifier_selected': False, 'actual_independent_expectations_proven': False, 'actual_native_fault_effectiveness_proven': False, 'actual_native_comparison_proven': False}

def validate_policy(p):
    exact(canonical(p),POLICY_SHA,'authored policy changed')
    return True

def validate_acceptance(c,r,p):
    validate_policy(p)
    exact(canonical(c),p['confirmation_canonical_sha256'],'complete confirmed374')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete received374 message')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'receipt SHA');exact(len(raw),c['receipt_size_bytes'],'receipt bytes')
    text=r['text'];contract=p['accepted374_contract']
    exact([s for s in text.splitlines() if s.startswith('PASS: ')],contract['expected_ordered374_labels'],'all289 ordered PASS labels')
    for key in ('expected_overlay_status','expected_commit_scope_status','expected_zero_failure_summary','synthetic_expected_commit_stats'):
        if text.count(contract[key])!=1:raise ValueError('single exact predecessor marker '+key)
    if text.count('[main 9bc9668] '+contract['expected_commit_message'])!=1 or text.count('39f33f8..9bc9668  main -> main')!=1:raise ValueError('commit/push markers')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),contract['expected_created_paths'],'seven exact additions')
    head='9bc9668 (HEAD -> main, origin/main, origin/HEAD) '+contract['expected_commit_message']
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
    validate_frozen_inputs(inputs,p);exact(canonical(design),DESIGN_SHA,'whole authored independent evidence oracle draft')
    exact(design['boundaries'],BOUNDARIES,'closed independent native gates');freeze=inputs['freeze']
    exact(design['full_original_contract326'],freeze['full_original_contracts320_327']['326'],'whole original326 contract')
    exact(design['full_original_independence_contract335'],inputs['independent_scaffold335']['independence_contract'],'whole original335 independence')
    exact(design['full_original_independent_expectation_contract351'],inputs['independent_expectation351'],'whole original351 private expectation contract')
    for a,b in [('full_original_raw_groups335','full_independent_raw_groups335'),('full_original_qualified_proofs347','full_qualified_proof_rows347'),('full_original_native_cases347','full_native_case_rows347'),('full_ordered_required_proof_case_relations','ordered_required_proof_case_relations')]:exact(design[a],freeze[b],'whole original '+b)
    exact([row['full_original_raw_group335'] for row in design['raw_group_evidence_review']],freeze['full_independent_raw_groups335'],'all12 full raw groups')
    exact(design['primary_gap_ids'],inputs['plan369']['roadmap'][6]['primary_gap_ids'],'original375 primary gaps')
    gaps={row['inherited_gap']['id']:row for row in freeze['full_original_native_gap_rows348']}
    for row in design['primary_gap_review']:exact(row['full_original_gap348'],gaps[row['id']],'whole original gap')
    expected=[]
    for row in freeze['full_qualified_proof_rows347']:
        for case in row['required_native_case_tuples']:expected.append({'case_id':case['case_id'],'platform':case['platform'],'qualified_proof_id':row['qualified_id'],'case_status':'required-not-run','proof_status':'required-not-proven','native_proof':False})
    exact(design['full_ordered_required_proof_case_relations'],expected,'every original ordered proof-case relation')
    exact([(row['case_id'],row['platform']) for row in design['case_evidence_review']],[(row['case_id'],row['platform']) for row in freeze['full_native_case_rows347']],'every original case platform order')
    for row,original in zip(design['case_evidence_review'],freeze['full_native_case_rows347']):
        exact(row['whole_original_case347_canonical_sha256'],canonical(original),'complete original case SHA')
        for a,b in [('all_original_evidence_group_ids','evidence_group_ids'),('all_original_qualified_proof_ids','required_qualified_proofs'),('all_original_source_evidence_gates','required_source_evidence_gates')]:exact(row[a],original[b],'whole original case gate '+b)
    for a,b in [('full_accepted374_target_closure_review','target_closure_review'),('full_accepted374_uncertainty_domains','independent_uncertainty_domains'),('full_accepted374_publication_sequence_review','publication_sequence_review'),('full_accepted374_publication_failure_cut_review','publication_failure_cut_review'),('stage12_receipt_causal_obligation','stage12_receipt_causal_obligation'),('inherited372_feasibility_blockers','inherited372_feasibility_blockers')]:exact(design[a],inputs['design374'][b],'whole original374 '+b)
    exact([row['platform'] for row in design['platform_readiness']],['Slackware-15.0','Slackware-current'],'separate unbound native evidence platforms')
    return True

def review(design,c,r,inputs,sources,readme,p):
    validate_acceptance(c,r,p);validate_sources(sources,readme,p);validate_design(design,inputs,p)
    return json.loads(json.dumps({'schema':1,'step':375,'scope':design['scope'],
        'state':'draft-independent-evidence-oracle-review-prepared-user-return-pending','design':design,'boundaries':BOUNDARIES,
        'full_original_native_gap_rows348':inputs['freeze']['full_original_native_gap_rows348'],
        'full_normative_rows347':inputs['freeze']['full_normative_rows347'],
        'full_accepted_design370':inputs['design370'],'full_accepted_design371':inputs['design371'],'full_accepted_design372':inputs['design372'],'full_accepted_design373':inputs['design373'],'full_accepted_design374':inputs['design374'],
        'native_cases_run':0,'native_proofs_added':0,'runtime_authority':False,
        'actual_current_strong_safe_pause_confirmed':False}))
