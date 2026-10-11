#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 -B - "$repo_root" <<'PYTEST'
from pathlib import Path
import ast
import copy
import hashlib
import json
import runpy
import sys

root=Path(sys.argv[1]);name='phase-1-operational-native-refinement-case-design-review'
f=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(name+'.py')
m=runpy.run_path(str(tool));passes=0
sha=lambda raw:hashlib.sha256(raw).hexdigest()
def load(tail):return json.loads((f/(name+'-'+tail+'.json')).read_bytes())
def check(label,value):
    global passes
    if not value:raise AssertionError(label)
    passes+=1;print('PASS: '+label,flush=True)
def rejected(fn,*args):
    try:fn(*args)
    except (ValueError,KeyError,TypeError):return True
    return False
p=load('policy');design=load('design');c=load('confirmed375');r=load('step375-user-acceptance')
check('authored376 policy independently frozen',m['validate_policy'](p))
check('all1931 accepted375 baseline bindings retained',len(p['baseline_sha256'])==p['accepted_source_count']==1931)
history={}
for rel,digest in p['baseline_sha256'].items():
    path=root/rel
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute() or not path.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=path.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-p['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted375 drift: '+rel)
    history[rel]=raw
check('all accepted375 bytes preserved except additive CHANGELOG',len(history)==1931)
check('complete375 uploaded return and reported acceptance validate',m['validate_acceptance'](c,r,p))
check('all386 exact predecessor labels and reported eight-file scope retained',len(p['accepted375_contract']['expected_ordered375_labels'])==386 and len(p['accepted375_contract']['expected_changed_paths'])==8)
check('exact received message SHA size and no normalization',sha(r['text'].encode())==r['sha256']==c['receipt_sha256'] and len(r['text'].encode())==r['size_bytes']==c['receipt_size_bytes']==26781 and r['normalization']=='none')
check('375 is not a new pause or independent native inspection',c['commit_prefix']=='2218052' and c['commit_full'] is None and not c['strong_safe_pause'] and c['last_confirmed_strong_safe_pause_step']==368 and 'not-independent-terminal-byte-capture' in r['capture_basis'])
inputs={k:json.loads(history[path]) for k,path in p['input_paths'].items()}
for k,path in p['input_paths'].items():check('whole input byte and canonical binding '+k,sha(history[path])==p['input_file_sha256'][k] and m['canonical'](inputs[k])==p['input_canonical_sha256'][k])
sources={row['path']:history[row['path']] for row in p['source_roots']};readme=history['README.md'];freeze=inputs['freeze']
check('all full frozen design inputs validate',m['validate_frozen_inputs'](inputs,p))
check('four unchanged review roots and accepted README validate',m['validate_sources'](sources,readme,p))
check('complete native refinement case draft validates',m['validate_design'](design,inputs,p))
check('one original376 gap retains whole normative scope',design['primary_gap_ids']==inputs['plan369']['roadmap'][7]['primary_gap_ids'] and len(design['primary_gap_review'])==1 and design['all_full_original_requirements_normative'] and not design['primary_assignment_limits_normative_scope'])
n=freeze['full_normative_rows347'];proofs=freeze['full_qualified_proof_rows347'];cases=freeze['full_native_case_rows347'];relations=freeze['ordered_required_proof_case_relations'];rawids=[row['id'] for row in freeze['full_independent_raw_groups335']]
check('whole16 original normative sections retained',design['full_original_normative_rows347']==n and len(design['full_original_normative_rows347'])==16)
for key,count in [('all35_nominal_types',35),('all26_nominal_interfaces',26),('all27_phase_boundaries',27),('all95_macro_design_relations',95),('macro_cut_obligations',81),('owned_stage7_microsteps',9),('effect_domain_reconciliation',30),('seven_capability_reconciliation',7),('ten_cross_obligation_reconciliation',10),('authority_window_reconciliation',9),('qualified_proof_reconciliation',46),('native_case_templates',52)]:check('whole normative section exact '+key,len(n[key])==count and design['full_original_normative_rows347'][key]==n[key])
check('full twelve original raw groups and1072ordered relations',design['full_original_raw_groups335']==freeze['full_independent_raw_groups335'] and design['full_ordered_required_proof_case_relations']==relations and len(relations)==1072)
families=design['native_observation_family_review'];familyids=[row['id'] for row in families]
check('ten proposed native families not selected primitives',len(families)==10 and len(set(familyids))==10)
for row in families:check('native family all outcomes unbound '+row['id'],all(v is None for k,v in row.items() if k.startswith('actual_')) and not row['native_refinement_complete'] and not row['current_authority'])
dimensions=design['native_cut_resolution_dimensions'];dimensionids=[row['id'] for row in dimensions]
check('nine native cut resolution dimensions applicability unresolved',len(dimensions)==9 and len(set(dimensionids))==9 and all(row['applicability_must_be_independently_resolved'] and row['actual_native_sites_and_effectiveness'] is None and not row['current_authority'] for row in dimensions))
check('all27 phase questions exact original order',[row['phase_id'] for row in design['phase_microevent_review']]==[row['id'] for row in n['all27_phase_boundaries']])
for row,original in zip(design['phase_microevent_review'],n['all27_phase_boundaries']):
    check('full original phase requirements unrefined '+row['phase_id'],row['position']==original['position'] and row['whole_original_phase347_canonical_sha256']==m['canonical'](original) and row['original_actor']==original['actor'] and row['original_rights_window']==original['rights_window'] and row['primary_review_family_id'] in familyids and row['all_original_qualified_proof_ids']==[p['qualified_id'] for p in proofs if row['phase_id'] in p['candidate_phase_ids']] and row['all_original_macro_cut_ids']==[x['id'] for x in n['macro_cut_obligations'] if x['phase_id']==row['phase_id']] and all(v is None for k,v in row.items() if k.startswith('actual_')) and not row['native_refinement_complete'] and not row['primary_family_limits_normative_scope'] and not row['current_authority'])
check('all26 interface questions exact original order',[row['interface_id'] for row in design['interface_refinement_review']]==[row['id'] for row in n['all26_nominal_interfaces']])
for row,original in zip(design['interface_refinement_review'],n['all26_nominal_interfaces']):check('whole nominal interface not native ABI '+row['interface_id'],row['whole_original_interface347_canonical_sha256']==m['canonical'](original) and row['all_original_phase_contexts']==original['allowed_phase_contexts'] and row['all_original_required_proof_ids']==original['required_future_proofs'] and row['primary_review_family_id'] in familyids and row['actual_component_protocol_ABI'] is None and row['actual_refinement_or_native_proof'] is None and not row['primary_family_limits_normative_scope'] and not row['current_authority'])
check('all81 macro cuts preserve full source and dimensions',len(design['macro_cut_refinement_review'])==81 and all(row['macro_cut_id']==original['id'] and row['whole_original_macro_cut347_canonical_sha256']==m['canonical'](original) and row['phase_id']==original['phase_id'] and row['location']==original['location'] and row['all_original_required_proof_ids']==original['required_future_proofs'] and row['required_native_resolution_dimensions']==dimensionids and all(v is None for k,v in row.items() if k.startswith('actual_')) and not row['is_selected_native_injection_site'] and not row['is_exhaustive_native_schedule'] and not row['current_authority'] for row,original in zip(design['macro_cut_refinement_review'],n['macro_cut_obligations'])))
for phase in design['phase_microevent_review']:check('three original macro cuts not native coverage '+phase['phase_id'],[row['location'] for row in design['macro_cut_refinement_review'] if row['phase_id']==phase['phase_id']]==['before-declared-operation','within-declared-operation','after-declared-operation'])
check('all nine owned microsteps in original order',[row['source_step'] for row in design['owned_microstep_refinement_review']]==[row['source_step'] for row in n['owned_stage7_microsteps']])
for i,(row,original) in enumerate(zip(design['owned_microstep_refinement_review'],n['owned_stage7_microsteps'])):check('owned native storage cuts pending '+row['source_step'],row['position']==original['position'] and row['whole_original_microstep347_canonical_sha256']==m['canonical'](original) and row['whole_accepted373_owned_review']==inputs['design373']['owned_microstep_review'][i] and row['required_native_resolution_dimensions']==dimensionids and row['actual_syscall_order_and_storage'] is None and row['actual_fault_coverage_and_writer_lifetimes'] is None and not row['native_refinement_complete'] and not row['current_authority'])
check('all30 effect domains exact original order',[row['domain_id'] for row in design['effect_domain_refinement_review']]==[row['id'] for row in n['effect_domain_reconciliation']])
for row,original in zip(design['effect_domain_refinement_review'],n['effect_domain_reconciliation']):check('full original effect domain grants no authority '+row['domain_id'],row['whole_original_domain347_canonical_sha256']==m['canonical'](original) and row['all_original_phase_ids']==original['phase_ids'] and row['all_original_required_proof_ids']==original['required_qualified_proofs'] and row['actual_complete_effect_graph'] is None and row['actual_native_effect_or_absence_proof'] is None and not row['domain_presence_grants_effect_authority'] and not row['current_authority'])
check('all46 proofs exact source order',[row['qualified_proof_id'] for row in design['qualified_proof_refinement_review']]==[row['qualified_id'] for row in proofs])
for row,original in zip(design['qualified_proof_refinement_review'],proofs):check('whole original qualified proof pending '+row['qualified_proof_id'],row['whole_original_proof347_canonical_sha256']==m['canonical'](original) and row['all_original_candidate_phase_ids']==original['candidate_phase_ids'] and row['all_original_domain_ids']==original['domain_ids'] and row['all_original_nominal_interface_ids']==original['nominal_interface_ids'] and row['all_original_required_native_case_tuples']==original['required_native_case_tuples'] and set(row['required_review_family_ids'])<=set(familyids) and row['required_raw_group_ids']==rawids and all(v is None for k,v in row.items() if k.startswith('actual_')) and not row['native_proof_discharged'] and not row['mapping_is_exhaustive_native_refinement'] and not row['current_authority'])
check('all52 cases exact tuple order',[(row['case_id'],row['platform']) for row in design['native_case_refinement_review']]==[(row['case_id'],row['platform']) for row in cases])
for row,original in zip(design['native_case_refinement_review'],cases):check('full native case future question not run '+row['platform']+' '+row['case_id'],row['whole_original_case347_canonical_sha256']==m['canonical'](original) and row['all_original_qualified_proof_ids']==original['required_qualified_proofs'] and row['all_original_raw_group_ids']==original['evidence_group_ids'] and row['all_original_source_evidence_gates']==original['required_source_evidence_gates'] and bool(row['required_future_case_microevent_question']) and all(v is None for k,v in row.items() if k.startswith('actual_')) and not row['is_new_original_native_case'] and not row['is_executable_test_scenario'] and not row['current_authority'])
proofids={row['qualified_id'] for row in proofs};casetuples={(row['case_id'],row['platform']) for row in cases}
check('every1072 relation full source references and native unknown',len(design['proof_case_relation_review'])==1072 and all(row['qualified_proof_id']==original['qualified_proof_id'] and row['case_id']==original['case_id'] and row['platform']==original['platform'] and row['whole_original_relation_canonical_sha256']==m['canonical'](original) and row['proof_refinement_reference']==row['qualified_proof_id'] and row['qualified_proof_id'] in proofids and row['case_refinement_reference']=={'case_id':row['case_id'],'platform':row['platform']} and (row['case_id'],row['platform']) in casetuples and row['actual_native_event_raw_oracle_binding'] is None and row['actual_independent_effective_controls'] is None and not row['native_relation_proven'] and not row['current_authority'] for row,original in zip(design['proof_case_relation_review'],relations)))
for suffix,count in [('role_trust_review',6),('raw_group_evidence_review',12),('fault_control_review',6),('comparison_requirement_review',10)]:check('whole accepted375 '+suffix,design['full_accepted375_'+suffix]==inputs['design375'][suffix] and len(design['full_accepted375_'+suffix])==count)
check('whole stage12 last receipt causal gap remains pending',design['stage12_receipt_causal_obligation']==inputs['design375']['stage12_receipt_causal_obligation'] and not design['stage12_receipt_causal_refinement_proven'])
check('all ten original372 candidate blockers intact unresolved',design['inherited372_feasibility_blockers']==inputs['design375']['inherited372_feasibility_blockers'] and len(design['inherited372_feasibility_blockers'])==10 and all(not row['native_gap_closed'] and not row['current_authority'] for row in design['inherited372_feasibility_blockers']))
no_claim_keys=['actual_native_refinement_complete','native_microevents_selected','native_scheduler_implemented','native_case_runner_implemented','native_fault_injector_implemented','microevent_questions_are_native_protocol','macro_cuts_are_actual_injection_sites','macro_triples_are_exhaustive_schedules','nominal_types_are_native_ABI_or_capability','macro_relations_are_actual_runtime_edges','primary_family_limits_normative_scope','stage12_receipt_causal_refinement_proven','contract_relaxation_permitted','runtime_authority']
for key in no_claim_keys:check('claim boundary closed '+key,design[key] is False)
check('native readiness blocked no native case proof or new case',design['native_readiness_still_blocked'] and design['native_cases_run']==design['native_proofs_added']==design['new_native_cases_added']==0)
check('both native platforms independently all-null',[row['platform'] for row in design['platform_readiness']]==['Slackware-15.0','Slackware-current'] and all(v is None for row in design['platform_readiness'] for k,v in row.items() if k.startswith('actual_')) and all(not row['native_case_run'] and not row['native_proof'] and not row['current_authority'] for row in design['platform_readiness']))
for row in design['primary_gap_review']:check('whole original primary gap remains pending '+row['id'],row['full_original_gap348']==next(x for x in freeze['full_original_native_gap_rows348'] if x['inherited_gap']['id']==row['id']) and not row['native_gap_closed'])
for key,count in [('full_original_contracts320_327',8),('full_normative_rows347',16),('full_original_native_gap_rows348',16),('full_qualified_proof_rows347',46),('full_native_case_rows347',52),('full_independent_raw_groups335',12),('ordered_required_proof_case_relations',1072)]:check('whole inherited normative scope '+key,len(freeze[key])==count)
check('README377 conditional378 no automatic379 and377 conditional next',sha(readme)==p['readme_at_entry_sha256'] and design['readme_reconciliation_step']==377 and design['conditional_pause_step']==378 and design['no_automatic379'] and design['next_preparable_step_after_complete376_acceptance']==377)
for key,value in [('commit_full','invented'),('strong_safe_pause',True),('runtime_authority',True),('actual_host_state','absent'),('actual_global_host_closure',True),('actual_live_bindings',{}),('user_worktree_clean',False),('user_head_matches_origin',False),('native_cases_run',1),('native_proofs_added',1)]:
    bad=copy.deepcopy(c);bad[key]=value;check('reject invented375 '+key,rejected(m['validate_acceptance'],bad,r,p))
labels=p['accepted375_contract']['expected_ordered375_labels']
for label,edit in [('truncated upload',lambda x:x[:-1]),('same-length receipt edit',lambda x:x.replace('2218052','2218053',1)),('dirty status injection',lambda x:x.replace('2218052 (HEAD',' M README.md\n2218052 (HEAD',1)),('reordered PASS labels',lambda x:x.replace(labels[0]+'\n'+labels[1],labels[1]+'\n'+labels[0]))]:
    bad=copy.deepcopy(r);bad['text']=edit(r['text']);check('reject '+label,rejected(m['validate_acceptance'],c,bad,p))
bad=copy.deepcopy(r);bad['capture_basis']='independent-terminal';check('reject invented capture origin',rejected(m['validate_acceptance'],c,bad,p))
for key in inputs:
    bad=copy.deepcopy(inputs);bad[key]['invented']=True;check('reject changed whole input '+key,rejected(m['validate_frozen_inputs'],bad,p))
bad=dict(sources);bad[next(iter(sources))]+=b'\n';check('reject historical source drift',rejected(m['validate_sources'],bad,readme,p))
bad=dict(sources);bad['restore-worker.sh']=b'claimed';check('reject fifth restoration root',rejected(m['validate_sources'],bad,readme,p))
check('reject premature README reconciliation',rejected(m['validate_sources'],sources,readme+b'\n',p))
mutations=[
 ('phase skipped',lambda x:x['phase_microevent_review'].pop()),
 ('phase order changed',lambda x:x['phase_microevent_review'].reverse()),
 ('traps after owned write',lambda x:x['phase_microevent_review'][7].update(required_future_micro_observation='arm later')),
 ('stage0 preflight promoted baseline',lambda x:x['phase_microevent_review'][6].update(required_future_micro_observation='reuse preflight baseline')),
 ('claim lost ACK replay',lambda x:x['phase_microevent_review'][1].update(required_future_micro_observation='retry claim')),
 ('launch spend refunded',lambda x:x['phase_microevent_review'][2].update(required_future_micro_observation='refund uncertain spend')),
 ('child spawn unknown relaunch',lambda x:x['phase_microevent_review'][3].update(required_future_micro_observation='spawn again')),
 ('worker broker FD permitted',lambda x:x['phase_microevent_review'][5].update(required_future_micro_observation='keep broker FD')),
 ('guard reacquired',lambda x:x['phase_microevent_review'][8].update(required_future_micro_observation='reacquire guard')),
 ('missing backup implies unchanged',lambda x:x['phase_microevent_review'][10].update(required_future_micro_observation='absence means unchanged')),
 ('raw pin rebound',lambda x:x['phase_microevent_review'][13].update(required_future_micro_observation='refresh to equivalent rows')),
 ('binding bearer stage8 grant',lambda x:x['phase_microevent_review'][15].update(required_future_micro_observation='dispatch on binding')),
 ('whole entry truncated three calls',lambda x:x['phase_microevent_review'][16].update(required_future_micro_observation='three calls only')),
 ('failure barrier return0 only',lambda x:x['phase_microevent_review'][17].update(required_future_micro_observation='return0 means known')),
 ('parent exit proves child drain',lambda x:x['phase_microevent_review'][18].update(required_future_micro_observation='parent exit enough')),
 ('unknown restore retried',lambda x:x['phase_microevent_review'][19].update(required_future_micro_observation='repeat unknown action')),
 ('foreign target rebound',lambda x:x['phase_microevent_review'][20].update(required_future_micro_observation='compare current to itself')),
 ('target evidence after release',lambda x:x['phase_microevent_review'][21].update(required_future_micro_observation='release first')),
 ('release ACK repeated',lambda x:x['phase_microevent_review'][22].update(required_future_micro_observation='force unlock retry')),
 ('target guard publication permission',lambda x:x['phase_microevent_review'][23].update(required_future_micro_observation='target lock enough')),
 ('archive sidecar pair atomic',lambda x:x['phase_microevent_review'][24].update(required_future_micro_observation='atomic pair')),
 ('receipt own final durability',lambda x:x['phase_microevent_review'][25].update(required_future_micro_observation='self receipt')),
 ('handoff unknown received',lambda x:x['phase_microevent_review'][26].update(required_future_micro_observation='ACK loss received')),
 ('macro before within after native exhaustive',lambda x:x.update(macro_triples_are_exhaustive_schedules=True)),
 ('macro cut selected injection',lambda x:x['macro_cut_refinement_review'][0].update(is_selected_native_injection_site=True)),
 ('partial operation omitted',lambda x:x['native_cut_resolution_dimensions'].pop(1)),
 ('writer lifetime dimension omitted',lambda x:x['native_cut_resolution_dimensions'].pop(5)),
 ('native applicability blanket exemption',lambda x:x['native_cut_resolution_dimensions'][3].update(applicability_must_be_independently_resolved=False)),
 ('offline receipt proves live fence',lambda x:x['native_observation_family_review'][3].update(required_future_native_refinement='offline receipt enough')),
 ('supervisor loss survivors waived',lambda x:x['native_observation_family_review'][4].update(required_future_native_refinement='ignore surviving children')),
 ('directory proof close only',lambda x:x['native_observation_family_review'][7].update(required_future_native_refinement='file close enough')),
 ('nominal type actual ABI',lambda x:x['full_original_normative_rows347']['all35_nominal_types'][0].update(native_abi='selected')),
 ('macro relation actual runtime edge',lambda x:x['full_original_normative_rows347']['all95_macro_design_relations'][0].update(actual_edge_proven=True)),
 ('native proof row waived',lambda x:x['full_original_normative_rows347']['qualified_proof_reconciliation'].pop()),
 ('native case template removed',lambda x:x['full_original_normative_rows347']['native_case_templates'].pop()),
 ('capability obligation waived',lambda x:x['full_original_normative_rows347']['seven_capability_reconciliation'].pop()),
 ('cross obligation waived',lambda x:x['full_original_normative_rows347']['ten_cross_obligation_reconciliation'].pop()),
 ('forbidden boot domain grants authority',lambda x:x['effect_domain_refinement_review'][16].update(domain_presence_grants_effect_authority=True)),
 ('unresolved graph domain omitted',lambda x:x['effect_domain_refinement_review'].pop()),
 ('raw group omitted',lambda x:x['full_original_raw_groups335'].pop()),
 ('proof required phase omitted',lambda x:x['qualified_proof_refinement_review'][0]['all_original_candidate_phase_ids'].pop()),
 ('proof required native tuple omitted',lambda x:x['qualified_proof_refinement_review'][0]['all_original_required_native_case_tuples'].pop()),
 ('case raw group omitted',lambda x:x['native_case_refinement_review'][0]['all_original_raw_group_ids'].pop()),
 ('case source gate omitted',lambda x:x['native_case_refinement_review'][0]['all_original_source_evidence_gates'].pop()),
 ('original relation missing',lambda x:x['full_ordered_required_proof_case_relations'].pop()),
 ('review relation missing',lambda x:x['proof_case_relation_review'].pop()),
 ('same length relation substituted',lambda x:x['proof_case_relation_review'][0].update(case_id='raw-status-latch')),
 ('relation wrong platform',lambda x:x['proof_case_relation_review'][0].update(platform='Slackware-current')),
 ('dangling proof reference',lambda x:x['proof_case_relation_review'][0].update(proof_refinement_reference='invented')),
 ('dangling case reference',lambda x:x['proof_case_relation_review'][0].update(case_refinement_reference={'case_id':'invented','platform':'Slackware-15.0'})),
 ('partial last relation native proof',lambda x:x['proof_case_relation_review'][-1].update(native_relation_proven=True)),
 ('verifier author allowance waived',lambda x:x['full_accepted375_role_trust_review'][2].update(non_inference='verifier cannot author')),
 ('unknown empty expected',lambda x:x['full_accepted375_comparison_requirement_review'][0].update(required_future_comparison='null empty')),
 ('known mismatch hidden by pending',lambda x:x['full_accepted375_comparison_requirement_review'][4].update(required_future_comparison='pending hides mismatch')),
 ('negative flag proves fault',lambda x:x['full_accepted375_fault_control_review'][1].update(required_future_observation='flag enough')),
 ('stage12 scope shortened',lambda x:x.update(stage12_receipt_causal_obligation='omit final status')),
 ('primitive blocker waived',lambda x:x['inherited372_feasibility_blockers'][0].update(native_gap_closed=True)),
 ('primary family restricts scope',lambda x:x.update(primary_family_limits_normative_scope=True)),
 ('native run claimed',lambda x:x.update(native_cases_run=1)),
 ('proof discharged',lambda x:x.update(native_proofs_added=1)),
 ('new native case invented',lambda x:x.update(new_native_cases_added=1)),
 ('native feasibility ready',lambda x:x.update(native_readiness_still_blocked=False)),
 ('contract relaxed',lambda x:x.update(contract_relaxation_permitted=True)),
 ('premature pause',lambda x:x.update(conditional_pause_step=376)),
 ('automatic379',lambda x:x.update(no_automatic379=False)),
 ('bool schema',lambda x:x.update(schema=True))]
for label,mutate in mutations:
    bad=copy.deepcopy(design);mutate(bad);check('reject '+label,rejected(m['validate_design'],bad,inputs,p))
for key in no_claim_keys:
    bad=copy.deepcopy(design);bad[key]=True;check('reject false current '+key,rejected(m['validate_design'],bad,inputs,p))
for collection,key in [('native_observation_family_review','actual_instruction_syscall_protocol'),('phase_microevent_review','actual_native_effect_order'),('owned_microstep_refinement_review','actual_syscall_order_and_storage')]:
    for i,row in enumerate(design[collection]):
        bad=copy.deepcopy(design);bad[collection][i][key]='invented-native-refinement';check('reject invented observation '+collection+' '+str(i),rejected(m['validate_design'],bad,inputs,p))
for i,row in enumerate(design['native_case_refinement_review']):
    bad=copy.deepcopy(design);bad['native_case_refinement_review'][i]['actual_native_result']='PASS';check('reject invented native case '+row['platform']+' '+row['case_id'],rejected(m['validate_design'],bad,inputs,p))
bad=copy.deepcopy(design);bad['platform_readiness'][1]=copy.deepcopy(bad['platform_readiness'][0]);check('reject platform evidence borrowing',rejected(m['validate_design'],bad,inputs,p))
for key,value in [('C_port_open',True),('production_entry_closed',False),('phase2_open',True),('machine_action_required',True),('controller_action_required',True),('historical_binding_or_authority_reuse_allowed',True),('current_step_strong_safe_pause',True),('native_components_selected',True),('actual_native_microevents_selected',True),('actual_native_crash_schedule_proven',True),('actual_native_concurrency_coverage_proven',True),('actual_proof_case_refinement_proven',True),('actual_global_host_closure',True),('actual_live_bindings',{})]:
    bad=copy.deepcopy(design);bad['boundaries'][key]=value;check('reject closed boundary changed '+key,rejected(m['validate_design'],bad,inputs,p))
bad=copy.deepcopy(p);bad['baseline_sha256']['README.md']='0'*64;check('reject policy substitution',rejected(m['validate_policy'],bad))
out=m['review'](design,c,r,inputs,sources,readme,p)
check('report retains whole normative gaps and full accepted375',out['full_original_native_gap_rows348']==freeze['full_original_native_gap_rows348'] and out['full_normative_rows347']==n and out['full_accepted_design375']==inputs['design375'])
out['design']['proof_case_relation_review'].pop();out['full_normative_rows347'].clear();out['boundaries']['actual_proof_case_refinement_proven']=True
again=m['review'](design,c,r,inputs,sources,readme,p)
check('report mutations detached from caller and later review',len(again['design']['proof_case_relation_review'])==len(design['proof_case_relation_review'])==1072 and len(again['full_normative_rows347'])==16 and not again['boundaries']['actual_proof_case_refinement_proven'])
tree=ast.parse(tool.read_text());imports={a.name for node in ast.walk(tree) if isinstance(node,ast.Import) for a in node.names}
check('pure reviewer imports only hashlib json re',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen','sign','verify','fork','spawn','pipe','fsync','kill','clock_gettime','rename','unlink','mkdir'}
check('reviewer has no native syscall scheduler fault injector runner or dispatch',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
