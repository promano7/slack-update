#!/usr/bin/env python3
"""Validate supplied native refinement and case questions without syscall selection or native execution."""
import hashlib
import json
import re

def sha(raw):return hashlib.sha256(raw).hexdigest()
def canonical(v):return sha(json.dumps(v,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode())
def exact(v,expected,label):
    if type(v) is not type(expected) or (v!=expected if isinstance(v,(set,bytes)) else canonical(v)!=canonical(expected)):raise ValueError(label)
    return True
POLICY_SHA='29103cd5ae2770738d67733aa1ed1a251253e74123a59094828c063edcb004fd'
DESIGN_SHA='1a0c6a69fe251134ca4e424042094ad305f44cff7880220d69dfc17e0b24dcc0'
BOUNDARIES={'C_port_open': False, 'actual_admission_protocol_implemented': False, 'actual_consumer_handoff_proven': False, 'actual_cryptography_proven': False, 'actual_durable_claim_proven': False, 'actual_global_host_closure': False, 'actual_host_state': 'unobserved-not-claimed-absent', 'actual_independent_collector_selected': False, 'actual_independent_expectations_proven': False, 'actual_independent_verifier_selected': False, 'actual_last_receipt_durable': False, 'actual_live_bindings': None, 'actual_native_comparison_proven': False, 'actual_native_fault_effectiveness_proven': False, 'actual_native_fence_proven': False, 'actual_native_refinement_complete': False, 'actual_original_baseline_captured': False, 'actual_owned_commit_proven': False, 'actual_platform_feasibility_proven': False, 'actual_publication_controls_proven': False, 'actual_recovery_authorized': False, 'actual_single_launch_proven': False, 'actual_successor_selected': False, 'actual_target_closure_proven': False, 'actual_target_release_proven': False, 'actual_target_unchanged_proven': False, 'actual_writer_exclusion_proven': False, 'controller_action_required': False, 'current_step_strong_safe_pause': False, 'design_is_actual_native_refinement': False, 'design_is_actual_source_implementation': False, 'design_is_complete_native_graph': False, 'design_proposal_is_operational_implementation': False, 'execution_authorized': False, 'historical_binding_or_authority_reuse_allowed': False, 'kernel_package_edge_complete': False, 'last_confirmed_strong_safe_pause_step': 368, 'later_current_refresh_invalidates_repository_only_pause': False, 'machine_action_required': False, 'native_cases_run': 0, 'native_components_selected': False, 'native_graph_complete': False, 'native_proofs_added': 0, 'operational_conformance': False, 'operational_readiness': False, 'phase1_matrix_complete': False, 'phase2_open': False, 'production_entry_closed': True, 'reference_v1_frozen': False, 'runtime_authority': False, 'strong_safe_pause': False, 'target_machine_actions_authorized': False, 'version1_schema_frozen': False, 'actual_native_microevents_selected': False, 'actual_native_crash_schedule_proven': False, 'actual_native_concurrency_coverage_proven': False, 'actual_proof_case_refinement_proven': False}

def validate_policy(p):
    exact(canonical(p),POLICY_SHA,'authored policy changed')
    return True

def validate_acceptance(c,r,p):
    validate_policy(p)
    exact(canonical(c),p['confirmation_canonical_sha256'],'complete confirmed375')
    exact(canonical(r),p['receipt_canonical_sha256'],'complete received375 message')
    raw=r['text'].encode('utf-8');exact(sha(raw),c['receipt_sha256'],'receipt SHA');exact(len(raw),c['receipt_size_bytes'],'receipt bytes')
    text=r['text'];contract=p['accepted375_contract']
    exact([s for s in text.splitlines() if s.startswith('PASS: ')],contract['expected_ordered375_labels'],'all386 ordered PASS labels')
    for key in ('expected_overlay_status','expected_commit_scope_status','expected_zero_failure_summary','synthetic_expected_commit_stats'):
        if text.count(contract[key])!=1:raise ValueError('single exact predecessor marker '+key)
    if text.count('[main 2218052] '+contract['expected_commit_message'])!=1 or text.count('9bc9668..2218052  main -> main')!=1:raise ValueError('commit/push markers')
    exact(re.findall(r'^ create mode 100644 (.+)$',text,re.M),contract['expected_created_paths'],'seven exact additions')
    head='2218052 (HEAD -> main, origin/main, origin/HEAD) '+contract['expected_commit_message']
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
    validate_frozen_inputs(inputs,p);exact(canonical(design),DESIGN_SHA,'whole authored native refinement case draft')
    exact(design['boundaries'],BOUNDARIES,'closed native refinement gates');freeze=inputs['freeze'];n=freeze['full_normative_rows347']
    exact(design['full_original_normative_rows347'],n,'whole16 original normative sections')
    exact(design['full_original_raw_groups335'],freeze['full_independent_raw_groups335'],'whole12 original raw groups')
    exact(design['full_ordered_required_proof_case_relations'],freeze['ordered_required_proof_case_relations'],'whole1072 original relations')
    exact(design['primary_gap_ids'],inputs['plan369']['roadmap'][7]['primary_gap_ids'],'original376 primary gap')
    gaps={row['inherited_gap']['id']:row for row in freeze['full_original_native_gap_rows348']}
    for row in design['primary_gap_review']:exact(row['full_original_gap348'],gaps[row['id']],'whole original gap')
    bindings=[('phase_microevent_review','phase_id','all27_phase_boundaries','id','whole_original_phase347_canonical_sha256'),('interface_refinement_review','interface_id','all26_nominal_interfaces','id','whole_original_interface347_canonical_sha256'),('macro_cut_refinement_review','macro_cut_id','macro_cut_obligations','id','whole_original_macro_cut347_canonical_sha256'),('owned_microstep_refinement_review','source_step','owned_stage7_microsteps','source_step','whole_original_microstep347_canonical_sha256'),('effect_domain_refinement_review','domain_id','effect_domain_reconciliation','id','whole_original_domain347_canonical_sha256'),('qualified_proof_refinement_review','qualified_proof_id','qualified_proof_reconciliation','qualified_id','whole_original_proof347_canonical_sha256')]
    for collection,id_key,source,source_id,hash_key in bindings:
        exact([row[id_key] for row in design[collection]],[row[source_id] for row in n[source]],'all original order '+source)
        for row,original in zip(design[collection],n[source]):exact(row[hash_key],canonical(original),'whole original row '+source)
    proofs={row['qualified_id']:row for row in freeze['full_qualified_proof_rows347']}
    for row in design['qualified_proof_refinement_review']:
        original=proofs[row['qualified_proof_id']]
        for a,b in [('all_original_candidate_phase_ids','candidate_phase_ids'),('all_original_domain_ids','domain_ids'),('all_original_nominal_interface_ids','nominal_interface_ids'),('all_original_required_native_case_tuples','required_native_case_tuples')]:exact(row[a],original[b],'whole original proof requirement '+b)
    exact([(row['case_id'],row['platform']) for row in design['native_case_refinement_review']],[(row['case_id'],row['platform']) for row in freeze['full_native_case_rows347']],'all52 original case tuples')
    for row,original in zip(design['native_case_refinement_review'],freeze['full_native_case_rows347']):
        exact(row['whole_original_case347_canonical_sha256'],canonical(original),'whole original native case')
        for a,b in [('all_original_qualified_proof_ids','required_qualified_proofs'),('all_original_raw_group_ids','evidence_group_ids'),('all_original_source_evidence_gates','required_source_evidence_gates')]:exact(row[a],original[b],'whole case requirements '+b)
    exact([(row['qualified_proof_id'],row['case_id'],row['platform']) for row in design['proof_case_relation_review']],[(row['qualified_proof_id'],row['case_id'],row['platform']) for row in freeze['ordered_required_proof_case_relations']],'all1072 original relation order')
    cases={(row['case_id'],row['platform']) for row in design['native_case_refinement_review']}
    for row,original in zip(design['proof_case_relation_review'],freeze['ordered_required_proof_case_relations']):
        exact(row['whole_original_relation_canonical_sha256'],canonical(original),'whole original relation')
        exact(row['proof_refinement_reference'],row['qualified_proof_id'],'original proof reference')
        exact(row['case_refinement_reference'],{'case_id':row['case_id'],'platform':row['platform']},'original case reference')
        if row['qualified_proof_id'] not in proofs or (row['case_id'],row['platform']) not in cases:raise ValueError('dangling original relation')
    for suffix in ('role_trust_review','raw_group_evidence_review','fault_control_review','comparison_requirement_review'):exact(design['full_accepted375_'+suffix],inputs['design375'][suffix],'whole original375 '+suffix)
    for key in ('stage12_receipt_causal_obligation','inherited372_feasibility_blockers'):exact(design[key],inputs['design375'][key],'whole inherited '+key)
    exact([row['platform'] for row in design['platform_readiness']],['Slackware-15.0','Slackware-current'],'separate unbound platforms')
    return True

def review(design,c,r,inputs,sources,readme,p):
    validate_acceptance(c,r,p);validate_sources(sources,readme,p);validate_design(design,inputs,p)
    return json.loads(json.dumps({'schema':1,'step':376,'scope':design['scope'],
        'state':'draft-native-refinement-case-review-prepared-user-return-pending','design':design,'boundaries':BOUNDARIES,
        'full_original_native_gap_rows348':inputs['freeze']['full_original_native_gap_rows348'],
        'full_normative_rows347':inputs['freeze']['full_normative_rows347'],
        'full_accepted_design370':inputs['design370'],'full_accepted_design371':inputs['design371'],'full_accepted_design372':inputs['design372'],'full_accepted_design373':inputs['design373'],'full_accepted_design374':inputs['design374'],'full_accepted_design375':inputs['design375'],
        'native_cases_run':0,'native_proofs_added':0,'runtime_authority':False,
        'actual_current_strong_safe_pause_confirmed':False}))
