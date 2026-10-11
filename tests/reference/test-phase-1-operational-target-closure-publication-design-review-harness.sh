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

root=Path(sys.argv[1]);name='phase-1-operational-target-closure-publication-design-review'
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
p=load('policy');design=load('design');c=load('confirmed373');r=load('step373-user-acceptance')
check('authored374 policy independently frozen',m['validate_policy'](p))
check('all1917 accepted373 baseline bindings retained',len(p['baseline_sha256'])==p['accepted_source_count']==1917)
history={}
for rel,digest in p['baseline_sha256'].items():
    path=root/rel
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute() or not path.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=path.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-p['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted373 drift: '+rel)
    history[rel]=raw
check('all accepted373 bytes preserved except additive CHANGELOG',len(history)==1917)
check('complete373 uploaded return and reported acceptance validate',m['validate_acceptance'](c,r,p))
check('all276 exact predecessor labels and reported eight-file scope retained',len(p['accepted373_contract']['expected_ordered373_labels'])==276 and len(p['accepted373_contract']['expected_changed_paths'])==8)
check('exact received message SHA size and no normalization',sha(r['text'].encode())==r['sha256']==c['receipt_sha256'] and len(r['text'].encode())==r['size_bytes']==c['receipt_size_bytes']==18933 and r['normalization']=='none')
check('373 is not a new pause or independent native inspection',c['commit_prefix']=='39f33f8' and c['commit_full'] is None and not c['strong_safe_pause'] and c['last_confirmed_strong_safe_pause_step']==368 and 'not-independent-terminal-byte-capture' in r['capture_basis'])
inputs={k:json.loads(history[path]) for k,path in p['input_paths'].items()}
for k,path in p['input_paths'].items():check('whole input byte and canonical binding '+k,sha(history[path])==p['input_file_sha256'][k] and m['canonical'](inputs[k])==p['input_canonical_sha256'][k])
sources={row['path']:history[row['path']] for row in p['source_roots']};readme=history['README.md'];freeze=inputs['freeze']
check('all full frozen design inputs validate',m['validate_frozen_inputs'](inputs,p))
check('four unchanged review roots and accepted README validate',m['validate_sources'](sources,readme,p))
check('complete target closure captured-data publication draft validates',m['validate_design'](design,inputs,p))
check('two original374 gap assignments retain whole normative scope',design['primary_gap_ids']==inputs['plan369']['roadmap'][5]['primary_gap_ids'] and len(design['primary_gap_review'])==2 and design['all_full_original_requirements_normative'] and not design['primary_assignment_limits_normative_scope'])
for n in ('323','324','325','327'):check('whole original contract'+n+' retained',design['full_original_contract'+n]==freeze['full_original_contracts320_327'][n])
check('whole original316 publication owner path and proof requirements',design['full_original_publication_requirements316']==inputs['publication_requirements316'])
check('all original316 operational publication bindings remain null',all(v is None for v in inputs['publication_requirements316']['operational_publication_bindings'].values()))
check('all nine original authority windows remain unbound',design['full_original_authority_windows347']==freeze['full_normative_rows347']['authority_window_reconciliation'] and len(design['full_original_authority_windows347'])==9 and all(row['actual_binding'] is None and row['actual_grant'] is None for row in design['full_original_authority_windows347']))
check('all twelve original independent raw groups retained',design['full_original_independent_raw_groups335']==freeze['full_independent_raw_groups335'] and len(design['full_original_independent_raw_groups335'])==12)
for suffix,count in [('baseline_domain_review',7),('recovery_gate_review',10),('recovery_branch_review',18),('owned_microstep_review',9)]:check('whole accepted373 '+suffix,design['full_accepted373_'+suffix]==inputs['design373'][suffix] and len(design['full_accepted373_'+suffix])==count)
check('all ten primitive candidate blockers retained unresolved',design['inherited372_feasibility_blockers']==inputs['design373']['inherited372_feasibility_blockers'] and len(design['inherited372_feasibility_blockers'])==10 and all(not row['native_gap_closed'] and not row['current_authority'] for row in design['inherited372_feasibility_blockers']))
closure_ids=['irreversible-forward-stop','same-original-scope-and-finite-rights','continuous-all-writer-exclusion','complete-known-child-drain','safe-original-equivalence-path','whole-original-invariants','complete-target-evidence-under-guard','sealed-captured-data-boundary','explicit-scoped-obligation-accounting','known-release-after-evidence','no-target-effects-after-release']
check('eleven target gates evidence before release exact order',[row['id'] for row in design['target_closure_review']]==closure_ids)
for i,row in enumerate(design['target_closure_review']):check('target gate future unobserved '+row['id'],row['position']==i and row['actual_evidence'] is None and row['actual_outcome'] is None and not row['native_satisfied'] and not row['current_authority'])
domain_ids=['target','owned-artifacts','controller-claim-launch-budget','publication-record','archive-and-sidecar','external-last-receipt','consumer-handoff']
check('seven distinct uncertainty domains exact',[row['domain'] for row in design['independent_uncertainty_domains']]==domain_ids)
for row in design['independent_uncertainty_domains']:check('independent domain unknown '+row['domain'],row['actual_state'] is None and row['actual_evidence'] is None and not row['is_current_closure_claim'] and bool(row['non_inference']))
publication_ids=['independent-publication-admission','captured-data-preparation-record','archive-exclusive-staging-and-commit','sidecar-exclusive-staging-and-commit','complete-stage12-external-evidence','external-last-receipt-no-replace','last-receipt-directory-storage-proof','durable-consumer-handoff','separate-publication-rights-accounting']
check('nine publication dependencies exact order',[row['id'] for row in design['publication_sequence_review']]==publication_ids)
for i,row in enumerate(design['publication_sequence_review']):check('publication row captured only unbound '+row['id'],row['position']==i and row['required_input_role']=='captured-closed-data-only' and not row['target_access_allowed'] and all(v is None for k,v in row.items() if k.startswith('actual_')) and not row['native_satisfied'] and not row['current_authority'])
check('sixteen inert cut questions not cases or selectors',len(design['publication_failure_cut_review'])==16 and len({row['id'] for row in design['publication_failure_cut_review']})==16 and not design['failure_cuts_are_executable_model'])
for row in design['publication_failure_cut_review']:check('fault cut effectiveness unknown '+row['id'],row['actual_condition'] is None and row['actual_observation'] is None and row['actual_fault_effectiveness'] is None and not row['native_case_run'] and not row['is_new_original_native_case'] and not row['is_executable_action_selector'] and not row['current_authority'])
no_claim_keys=['stage12_receipt_causal_refinement_proven','target_closure_implemented','publication_dispatcher_implemented','captured_data_is_actual_capture','target_release_implies_publication_controls','target_closure_implies_global_or_controller_closure','publication_pair_is_atomic','last_receipt_is_in_own_archive','last_receipt_contains_own_final_hash_or_durability','sha_implies_trusted_origin_or_authority','unknown_ACK_allows_replay','contained_failure_erases_original_status','publication_failure_grants_target_rights','contract_relaxation_permitted','runtime_authority']
for key in no_claim_keys:check('current claim closed '+key,design[key] is False)
check('native readiness blocked and no case or proof',design['native_readiness_still_blocked'] and design['native_cases_run']==design['native_proofs_added']==0)
check('both platforms entirely unbound separately',[row['platform'] for row in design['platform_readiness']]==['Slackware-15.0','Slackware-current'] and all(v is None for row in design['platform_readiness'] for k,v in row.items() if k.startswith('actual_')) and all(not row['native_case_run'] and not row['native_proof'] and not row['current_authority'] for row in design['platform_readiness']))
for row in design['primary_gap_review']:check('whole original gap retained pending '+row['id'],row['full_original_gap348']==next(x for x in freeze['full_original_native_gap_rows348'] if x['inherited_gap']['id']==row['id']) and not row['native_gap_closed'])
for key,count in [('full_original_contracts320_327',8),('full_normative_rows347',16),('full_original_native_gap_rows348',16),('full_qualified_proof_rows347',46),('full_native_case_rows347',52),('full_independent_raw_groups335',12),('ordered_required_proof_case_relations',1072)]:check('whole inherited normative scope '+key,len(freeze[key])==count)
check('README377 conditional378 no automatic379 and375 conditional next',sha(readme)==p['readme_at_entry_sha256'] and design['readme_reconciliation_step']==377 and design['conditional_pause_step']==378 and design['no_automatic379'] and design['next_preparable_step_after_complete374_acceptance']==375)
for key,value in [('commit_full','invented'),('strong_safe_pause',True),('runtime_authority',True),('actual_host_state','absent'),('actual_global_host_closure',True),('actual_live_bindings',{}),('user_worktree_clean',False),('user_head_matches_origin',False),('native_cases_run',1),('native_proofs_added',1)]:
    bad=copy.deepcopy(c);bad[key]=value;check('reject invented373 '+key,rejected(m['validate_acceptance'],bad,r,p))
labels=p['accepted373_contract']['expected_ordered373_labels']
for label,edit in [('truncated upload',lambda x:x[:-1]),('same-length receipt edit',lambda x:x.replace('39f33f8','39f33f9',1)),('dirty status injection',lambda x:x.replace('39f33f8 (HEAD',' M README.md\n39f33f8 (HEAD',1)),('reordered PASS labels',lambda x:x.replace(labels[0]+'\n'+labels[1],labels[1]+'\n'+labels[0]))]:
    bad=copy.deepcopy(r);bad['text']=edit(r['text']);check('reject '+label,rejected(m['validate_acceptance'],c,bad,p))
bad=copy.deepcopy(r);bad['capture_basis']='independent-terminal';check('reject invented capture origin',rejected(m['validate_acceptance'],c,bad,p))
for key in inputs:
    bad=copy.deepcopy(inputs);bad[key]['invented']=True;check('reject changed whole input '+key,rejected(m['validate_frozen_inputs'],bad,p))
bad=dict(sources);bad[next(iter(sources))]+=b'\n';check('reject historical source drift',rejected(m['validate_sources'],bad,readme,p))
bad=dict(sources);bad['restore-worker.sh']=b'claimed';check('reject fifth restoration root',rejected(m['validate_sources'],bad,readme,p))
check('reject premature README reconciliation',rejected(m['validate_sources'],sources,readme+b'\n',p))
mutations=[
 ('target evidence after release',lambda x:x['target_closure_review'].reverse()),
 ('child drain replaced by parent exit',lambda x:x['target_closure_review'][3].update(required_future_observation='parent exit suffices')),
 ('guard reacquisition made continuous',lambda x:x['target_closure_review'][2].update(required_future_observation='reacquire after loss')),
 ('missing backup made unchanged',lambda x:x['target_closure_review'][4].update(required_future_observation='missing backup means unchanged')),
 ('original vectors rebound to current',lambda x:x['target_closure_review'][5].update(required_future_observation='compare current to itself')),
 ('release uncertain ACK retried',lambda x:x['target_closure_review'][9].update(required_future_observation='retry release')),
 ('sealed capture made actual',lambda x:x.update(captured_data_is_actual_capture=True)),
 ('owned uncertainty collapsed into target',lambda x:x['independent_uncertainty_domains'][1].update(non_inference='unknown owned means no target effect')),
 ('claim and launch reset after restoration',lambda x:x['independent_uncertainty_domains'][2].update(non_inference='reset consumed admission')),
 ('record made archive completion proof',lambda x:x['independent_uncertainty_domains'][3].update(non_inference='record proves all outputs')),
 ('target release made publication permission',lambda x:x.update(target_release_implies_publication_controls=True)),
 ('scoped target made global closure',lambda x:x.update(target_closure_implies_global_or_controller_closure=True)),
 ('numeric UID namespace replaced by name',lambda x:x['publication_sequence_review'][0].update(required_future_observation='promano users name sufficient')),
 ('published0600 treated immutable',lambda x:x['publication_sequence_review'][-1].update(required_future_observation='0600 means immutable')),
 ('leaf safe made ancestry proof',lambda x:x['publication_sequence_review'][0].update(required_future_observation='realpath string and leaf safe sufficient')),
 ('live target refresh during archive',lambda x:x['publication_sequence_review'][2].update(target_access_allowed=True)),
 ('archive and sidecar pair atomic',lambda x:x.update(publication_pair_is_atomic=True)),
 ('archive includes own receipt',lambda x:x.update(last_receipt_is_in_own_archive=True)),
 ('receipt self hash and durability',lambda x:x.update(last_receipt_contains_own_final_hash_or_durability=True)),
 ('SHA substituted for trusted origin',lambda x:x.update(sha_implies_trusted_origin_or_authority=True)),
 ('last receipt before complete stage12 evidence',lambda x:x['publication_sequence_review'].reverse()),
 ('directory storage proof skipped',lambda x:x['publication_sequence_review'].pop(6)),
 ('file flush made directory durability',lambda x:x['publication_sequence_review'][6].update(required_future_observation='file close sufficient')),
 ('collector final observation put inside own receipt',lambda x:x['publication_sequence_review'][5].update(required_future_observation='receipt proves its own final storage')),
 ('handoff removed recipient writer exclusion',lambda x:x['publication_sequence_review'][7].update(required_future_observation='release controls before consumer')),
 ('lost ACK replay enabled',lambda x:x.update(unknown_ACK_allows_replay=True)),
 ('original contained failure relabelled success',lambda x:x.update(contained_failure_erases_original_status=True)),
 ('publication failure grants target rights',lambda x:x.update(publication_failure_grants_target_rights=True)),
 ('occupied final overwritten',lambda x:x['publication_failure_cut_review'][4].update(required_future_disposition='force rename')),
 ('partial archive rebuilt',lambda x:x['publication_failure_cut_review'][6].update(required_future_disposition='rearchive')),
 ('sidecar unknown pair marked complete',lambda x:x['publication_failure_cut_review'][8].update(required_future_disposition='pair complete')),
 ('missing streams fabricated exit0',lambda x:x['publication_failure_cut_review'][10].update(required_future_disposition='assume exit0')),
 ('unknown receipt republished',lambda x:x['publication_failure_cut_review'][11].update(required_future_disposition='republish')),
 ('handoff ACK loss treated received',lambda x:x['publication_failure_cut_review'][13].update(required_future_disposition='received')),
 ('uncatchable loss treated absent',lambda x:x['publication_failure_cut_review'][-1].update(required_future_disposition='traps ensure no effect')),
 ('whole316 requirement waived',lambda x:x['full_original_publication_requirements316']['requirements'].update(receipt_last_required_no_self_hash_or_self_contained_archive_completion_claim=False)),
 ('original323 closure truncated',lambda x:x['full_original_contract323']['document'].pop('closure_contract')),
 ('original324 raw audit pin rebound',lambda x:x['full_original_contract324']['document']['pkglist_contract'].update(rebind=True)),
 ('original325 receipt contract changed',lambda x:x['full_original_contract325']['document']['publication_contract'].update(actual_receipt_origin='verified')),
 ('original327 rights windows waived',lambda x:x['full_original_contract327']['document'].pop('authority_windows')),
 ('inherited recovery gates truncated',lambda x:x['full_accepted373_recovery_gate_review'].pop()),
 ('finite recovery deadline renewed',lambda x:x['full_accepted373_recovery_branch_review'][13].update(proposed_future_disposition='renew')),
 ('owned microstep directory proof removed',lambda x:x['full_accepted373_owned_microstep_review'].pop(7)),
 ('independent raw group removed',lambda x:x['full_original_independent_raw_groups335'].pop()),
 ('authority window binding invented',lambda x:x['full_original_authority_windows347'][0].update(actual_binding='claimed')),
 ('primitive blocker waived',lambda x:x['inherited372_feasibility_blockers'][0].update(native_gap_closed=True)),
 ('primary assignments narrow normative scope',lambda x:x.update(primary_assignment_limits_normative_scope=True)),
 ('proof promoted',lambda x:x.update(native_proofs_added=1)),
 ('native case run',lambda x:x.update(native_cases_run=1)),
 ('feasibility blocker ignored',lambda x:x.update(native_readiness_still_blocked=False)),
 ('contract relaxation',lambda x:x.update(contract_relaxation_permitted=True)),
 ('premature pause',lambda x:x.update(conditional_pause_step=374)),
 ('automatic379',lambda x:x.update(no_automatic379=False)),
 ('bool schema',lambda x:x.update(schema=True))]
for label,mutate in mutations:
    bad=copy.deepcopy(design);mutate(bad);check('reject '+label,rejected(m['validate_design'],bad,inputs,p))
for key in no_claim_keys:
    bad=copy.deepcopy(design);bad[key]=True;check('reject false current '+key,rejected(m['validate_design'],bad,inputs,p))
for collection,evidence_key in [('target_closure_review','actual_evidence'),('independent_uncertainty_domains','actual_state'),('publication_sequence_review','actual_commit_outcome'),('publication_failure_cut_review','actual_fault_effectiveness')]:
    for i,row in enumerate(design[collection]):
        bad=copy.deepcopy(design);bad[collection][i][evidence_key]='invented-native-evidence';check('reject invented observation '+collection+' '+str(i),rejected(m['validate_design'],bad,inputs,p))
for i,row in enumerate(design['publication_sequence_review']):
    bad=copy.deepcopy(design);bad['publication_sequence_review'][i]['current_authority']=True;check('reject publication authority '+row['id'],rejected(m['validate_design'],bad,inputs,p))
bad=copy.deepcopy(design);bad['platform_readiness'][1]=copy.deepcopy(bad['platform_readiness'][0]);check('reject platform evidence borrowing',rejected(m['validate_design'],bad,inputs,p))
for key,value in [('C_port_open',True),('production_entry_closed',False),('phase2_open',True),('machine_action_required',True),('controller_action_required',True),('historical_binding_or_authority_reuse_allowed',True),('current_step_strong_safe_pause',True),('native_components_selected',True),('actual_original_baseline_captured',True),('actual_target_closure_proven',True),('actual_target_release_proven',True),('actual_publication_controls_proven',True),('actual_last_receipt_durable',True),('actual_consumer_handoff_proven',True),('actual_global_host_closure',True),('actual_live_bindings',{})]:
    bad=copy.deepcopy(design);bad['boundaries'][key]=value;check('reject closed boundary changed '+key,rejected(m['validate_design'],bad,inputs,p))
bad=copy.deepcopy(p);bad['baseline_sha256']['README.md']='0'*64;check('reject policy substitution',rejected(m['validate_policy'],bad))
out=m['review'](design,c,r,inputs,sources,readme,p)
check('report retains original gaps normative rows and full accepted373',out['full_original_native_gap_rows348']==freeze['full_original_native_gap_rows348'] and out['full_normative_rows347']==freeze['full_normative_rows347'] and out['full_accepted_design373']==inputs['design373'])
out['design']['publication_sequence_review'].pop();out['full_normative_rows347'].clear();out['boundaries']['actual_last_receipt_durable']=True
again=m['review'](design,c,r,inputs,sources,readme,p)
check('report mutations detached from caller and later review',len(again['design']['publication_sequence_review'])==len(design['publication_sequence_review'])==9 and len(again['full_normative_rows347'])==16 and not again['boundaries']['actual_last_receipt_durable'])
tree=ast.parse(tool.read_text());imports={a.name for node in ast.walk(tree) if isinstance(node,ast.Import) for a in node.names}
check('pure reviewer imports only hashlib json re',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen','sign','verify','fork','spawn','pipe','fsync','kill','clock_gettime','rename','unlink','mkdir'}
check('reviewer has no target capture clock storage crypto native publisher or dispatch',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
