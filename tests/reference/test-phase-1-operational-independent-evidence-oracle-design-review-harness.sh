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

root=Path(sys.argv[1]);name='phase-1-operational-independent-evidence-oracle-design-review'
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
p=load('policy');design=load('design');c=load('confirmed374');r=load('step374-user-acceptance')
check('authored375 policy independently frozen',m['validate_policy'](p))
check('all1924 accepted374 baseline bindings retained',len(p['baseline_sha256'])==p['accepted_source_count']==1924)
history={}
for rel,digest in p['baseline_sha256'].items():
    path=root/rel
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute() or not path.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=path.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-p['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted374 drift: '+rel)
    history[rel]=raw
check('all accepted374 bytes preserved except additive CHANGELOG',len(history)==1924)
check('complete374 uploaded return and reported acceptance validate',m['validate_acceptance'](c,r,p))
check('all289 exact predecessor labels and reported eight-file scope retained',len(p['accepted374_contract']['expected_ordered374_labels'])==289 and len(p['accepted374_contract']['expected_changed_paths'])==8)
check('exact received message SHA size and no normalization',sha(r['text'].encode())==r['sha256']==c['receipt_sha256'] and len(r['text'].encode())==r['size_bytes']==c['receipt_size_bytes']==19805 and r['normalization']=='none')
check('374 is not a new pause or independent native inspection',c['commit_prefix']=='9bc9668' and c['commit_full'] is None and not c['strong_safe_pause'] and c['last_confirmed_strong_safe_pause_step']==368 and 'not-independent-terminal-byte-capture' in r['capture_basis'])
inputs={k:json.loads(history[path]) for k,path in p['input_paths'].items()}
for k,path in p['input_paths'].items():check('whole input byte and canonical binding '+k,sha(history[path])==p['input_file_sha256'][k] and m['canonical'](inputs[k])==p['input_canonical_sha256'][k])
sources={row['path']:history[row['path']] for row in p['source_roots']};readme=history['README.md'];freeze=inputs['freeze']
check('all full frozen design inputs validate',m['validate_frozen_inputs'](inputs,p))
check('four unchanged review roots and accepted README validate',m['validate_sources'](sources,readme,p))
check('complete independent evidence oracle draft validates',m['validate_design'](design,inputs,p))
check('one original375 assignment retains full normative scope',design['primary_gap_ids']==inputs['plan369']['roadmap'][6]['primary_gap_ids'] and len(design['primary_gap_review'])==1 and design['all_full_original_requirements_normative'] and not design['primary_assignment_limits_normative_scope'])
check('whole original326 independent conformance contract',design['full_original_contract326']==freeze['full_original_contracts320_327']['326'])
check('whole original335 independence contract',design['full_original_independence_contract335']==inputs['independent_scaffold335']['independence_contract'])
check('whole original351 private expectation contract',design['full_original_independent_expectation_contract351']==inputs['independent_expectation351'])
check('historical351 implemented private declarations not native expectations',inputs['independent_expectation351']['current_expectation_contract_implemented'] and not inputs['independent_expectation351']['actual_independent_oracle_selected'] and not design['private351_literals_are_native_expectations'])
for a,b,count in [('full_original_raw_groups335','full_independent_raw_groups335',12),('full_original_qualified_proofs347','full_qualified_proof_rows347',46),('full_original_native_cases347','full_native_case_rows347',52),('full_ordered_required_proof_case_relations','ordered_required_proof_case_relations',1072)]:check('full original rows retained '+b,design[a]==freeze[b] and len(design[a])==count)
roles=['subject','independent-collector','independent-verifier','independent-expectation-author','independent-fault-controls','evidence-custody-and-consumer']
check('six trust role reviews exact',[row['id'] for row in design['role_trust_review']]==roles)
for row in design['role_trust_review']:check('source trust independently unbound '+row['id'],all(v is None for k,v in row.items() if k.startswith('actual_')) and not row['native_independence_proven'] and not row['current_authority'])
check('all twelve original raw groups reviewed in order',[row['full_original_raw_group335'] for row in design['raw_group_evidence_review']]==freeze['full_independent_raw_groups335'] and len(design['raw_group_evidence_review'])==12)
for row in design['raw_group_evidence_review']:check('whole original group uncaptured '+row['id'],all(v is None for k,v in row.items() if k.startswith('actual_')) and not row['native_group_complete'] and not row['current_authority'] and all(v is None for k,v in row['full_original_raw_group335'].items() if k.startswith('actual_')))
check('six independent control review gates exact',len(design['fault_control_review'])==6 and len({row['id'] for row in design['fault_control_review']})==6)
for row in design['fault_control_review']:check('fault control raw effectiveness unknown '+row['id'],all(v is None for k,v in row.items() if k.startswith('actual_')) and not row['native_satisfied'] and not row['current_authority'])
check('ten comparison requirements no executable native comparator',len(design['comparison_requirement_review'])==10 and len({row['id'] for row in design['comparison_requirement_review']})==10 and not design['native_comparator_implemented'])
for row in design['comparison_requirement_review']:check('comparison expectation raw result all unknown '+row['id'],all(v is None for k,v in row.items() if k.startswith('actual_')) and not row['is_executable_native_comparator'] and not row['current_authority'])
check('all52 case-platform reviews exact original order',[(row['case_id'],row['platform']) for row in design['case_evidence_review']]==[(row['case_id'],row['platform']) for row in freeze['full_native_case_rows347']] and len(design['case_evidence_review'])==52)
for row,original in zip(design['case_evidence_review'],freeze['full_native_case_rows347']):
    check('whole native case gates remain unrun '+row['platform']+' '+row['case_id'],row['whole_original_case347_canonical_sha256']==m['canonical'](original) and row['all_original_evidence_group_ids']==original['evidence_group_ids'] and row['all_original_qualified_proof_ids']==original['required_qualified_proofs'] and row['all_original_source_evidence_gates']==original['required_source_evidence_gates'] and all(v is None for k,v in row.items() if k.startswith('actual_')) and row['status']=='required-not-run' and not row['current_authority'])
for platform in ('Slackware-15.0','Slackware-current'):check('26 original cases separately pending '+platform,sum(row['platform']==platform for row in design['case_evidence_review'])==26)
for a,b,count in [('full_accepted374_target_closure_review','target_closure_review',11),('full_accepted374_uncertainty_domains','independent_uncertainty_domains',7),('full_accepted374_publication_sequence_review','publication_sequence_review',9),('full_accepted374_publication_failure_cut_review','publication_failure_cut_review',16)]:check('whole accepted374 '+b,design[a]==inputs['design374'][b] and len(design[a])==count)
check('whole original stage12 causal requirement still pending',design['stage12_receipt_causal_obligation']==inputs['design374']['stage12_receipt_causal_obligation'] and not design['stage12_receipt_causal_refinement_proven'])
check('all ten primitive candidate blockers remain whole unresolved',design['inherited372_feasibility_blockers']==inputs['design374']['inherited372_feasibility_blockers'] and len(design['inherited372_feasibility_blockers'])==10 and all(not row['native_gap_closed'] and not row['current_authority'] for row in design['inherited372_feasibility_blockers']))
no_claim_keys=['stage12_receipt_causal_refinement_proven','collector_implemented','native_verifier_implemented','native_expectation_authentication_implemented','native_comparator_implemented','native_fault_injector_implemented','distinct_hashes_prove_independence','verifier_author_role_forbidden','subject_self_expectation_allowed','candidate_logic_is_sole_oracle_allowed','private351_literals_are_native_expectations','unknown_equals_empty_or_no_effect','pending_erases_known_mismatch','declared_match_is_native_conformance','historical_receipt_grants_fresh_test_authority','observer_writes_exempt_from_effect_scope','cross_platform_evidence_transfer_allowed','contract_relaxation_permitted','runtime_authority']
for key in no_claim_keys:check('claim boundary closed '+key,design[key] is False)
check('native readiness blocked no actual cases or proofs',design['native_readiness_still_blocked'] and design['native_cases_run']==design['native_proofs_added']==0)
check('both platforms all inputs independently unbound',[row['platform'] for row in design['platform_readiness']]==['Slackware-15.0','Slackware-current'] and all(v is None for row in design['platform_readiness'] for k,v in row.items() if k.startswith('actual_')) and all(not row['native_case_run'] and not row['native_proof'] and not row['current_authority'] for row in design['platform_readiness']))
for row in design['primary_gap_review']:check('full original primary gap remains pending '+row['id'],row['full_original_gap348']==next(x for x in freeze['full_original_native_gap_rows348'] if x['inherited_gap']['id']==row['id']) and not row['native_gap_closed'])
for key,count in [('full_original_contracts320_327',8),('full_normative_rows347',16),('full_original_native_gap_rows348',16),('full_qualified_proof_rows347',46),('full_native_case_rows347',52),('full_independent_raw_groups335',12),('ordered_required_proof_case_relations',1072)]:check('whole inherited normative scope '+key,len(freeze[key])==count)
check('README377 conditional378 no automatic379 and376 conditional next',sha(readme)==p['readme_at_entry_sha256'] and design['readme_reconciliation_step']==377 and design['conditional_pause_step']==378 and design['no_automatic379'] and design['next_preparable_step_after_complete375_acceptance']==376)
for key,value in [('commit_full','invented'),('strong_safe_pause',True),('runtime_authority',True),('actual_host_state','absent'),('actual_global_host_closure',True),('actual_live_bindings',{}),('user_worktree_clean',False),('user_head_matches_origin',False),('native_cases_run',1),('native_proofs_added',1)]:
    bad=copy.deepcopy(c);bad[key]=value;check('reject invented374 '+key,rejected(m['validate_acceptance'],bad,r,p))
labels=p['accepted374_contract']['expected_ordered374_labels']
for label,edit in [('truncated upload',lambda x:x[:-1]),('same-length receipt edit',lambda x:x.replace('9bc9668','9bc9669',1)),('dirty status injection',lambda x:x.replace('9bc9668 (HEAD',' M README.md\n9bc9668 (HEAD',1)),('reordered PASS labels',lambda x:x.replace(labels[0]+'\n'+labels[1],labels[1]+'\n'+labels[0]))]:
    bad=copy.deepcopy(r);bad['text']=edit(r['text']);check('reject '+label,rejected(m['validate_acceptance'],c,bad,p))
bad=copy.deepcopy(r);bad['capture_basis']='independent-terminal';check('reject invented capture origin',rejected(m['validate_acceptance'],c,bad,p))
for key in inputs:
    bad=copy.deepcopy(inputs);bad[key]['invented']=True;check('reject changed whole input '+key,rejected(m['validate_frozen_inputs'],bad,p))
bad=dict(sources);bad[next(iter(sources))]+=b'\n';check('reject historical source drift',rejected(m['validate_sources'],bad,readme,p))
bad=dict(sources);bad['restore-worker.sh']=b'claimed';check('reject fifth restoration root',rejected(m['validate_sources'],bad,readme,p))
check('reject premature README reconciliation',rejected(m['validate_sources'],sources,readme+b'\n',p))
mutations=[
 ('collector uses subject packet',lambda x:x['role_trust_review'][1].update(required_future_review='subject output is raw evidence')),
 ('different hashes imply independent trust',lambda x:x.update(distinct_hashes_prove_independence=True)),
 ('verifier cannot author expectations',lambda x:x.update(verifier_author_role_forbidden=True)),
 ('subject self authors expectation',lambda x:x.update(subject_self_expectation_allowed=True)),
 ('candidate selector reused as sole oracle',lambda x:x.update(candidate_logic_is_sole_oracle_allowed=True)),
 ('private351 literal promoted native',lambda x:x.update(private351_literals_are_native_expectations=True)),
 ('same raw pkglist pin rebound',lambda x:x['raw_group_evidence_review'][3].update(independent_expectation_and_comparison_requirement='refresh to current pin')),
 ('selector counts replace full vector',lambda x:x['raw_group_evidence_review'][4].update(required_future_raw_capture='one count only')),
 ('mandatory upgrade20 accepted',lambda x:x['raw_group_evidence_review'][4].update(independent_expectation_and_comparison_requirement='upgrade20 is success')),
 ('unattempted minus1 success',lambda x:x['comparison_requirement_review'][2].update(required_future_comparison='unattempted is success')),
 ('whole target replaced by owned exclusion',lambda x:x['raw_group_evidence_review'][5].update(independent_expectation_and_comparison_requirement='exclude entire owned subtree')),
 ('parent exit proves drain',lambda x:x['raw_group_evidence_review'][6].update(independent_expectation_and_comparison_requirement='parent exit enough')),
 ('offline receipt proves revocation',lambda x:x['raw_group_evidence_review'][7].update(required_future_raw_capture='offline receipt')),
 ('forward expiry implicit recovery right',lambda x:x['raw_group_evidence_review'][7].update(independent_expectation_and_comparison_requirement='failure grants restore')),
 ('missing backup proves unchanged',lambda x:x['raw_group_evidence_review'][8].update(independent_expectation_and_comparison_requirement='no backup means no target write')),
 ('last receipt self durability accepted',lambda x:x['raw_group_evidence_review'][9].update(independent_expectation_and_comparison_requirement='receipt certifies self')),
 ('fault flag proves negative effect',lambda x:x['raw_group_evidence_review'][10].update(required_future_raw_capture='requested flag enough')),
 ('scoped closure promoted global',lambda x:x['raw_group_evidence_review'][11].update(independent_expectation_and_comparison_requirement='all host closed')),
 ('observer evidence writes exempt',lambda x:x.update(observer_writes_exempt_from_effect_scope=True)),
 ('collector allowed worker broker FD',lambda x:x['role_trust_review'][1].update(required_future_review='inherit broker to worker')),
 ('positive control manufactures expectation',lambda x:x['fault_control_review'][0].update(required_future_observation='use observed positive output as expected')),
 ('missed cut marked effective',lambda x:x['fault_control_review'][1].update(actual_negative_control_effectiveness=True)),
 ('capture loss made empty',lambda x:x['fault_control_review'][4].update(required_future_observation='missing is empty')),
 ('unknown equals false zero empty',lambda x:x.update(unknown_equals_empty_or_no_effect=True)),
 ('ordered multiplicity dropped',lambda x:x['comparison_requirement_review'][1].update(required_future_comparison='sort and deduplicate')),
 ('pending hides known mismatch',lambda x:x.update(pending_erases_known_mismatch=True)),
 ('declaration match native PASS',lambda x:x.update(declared_match_is_native_conformance=True)),
 ('historical receipt native test grant',lambda x:x.update(historical_receipt_grants_fresh_test_authority=True)),
 ('platform transfer allowed',lambda x:x.update(cross_platform_evidence_transfer_allowed=True)),
 ('stage12 causal obligation shortened',lambda x:x.update(stage12_receipt_causal_obligation='omit final stage outcome')),
 ('proof row omitted',lambda x:x['full_original_qualified_proofs347'].pop()),
 ('case row omitted',lambda x:x['full_original_native_cases347'].pop()),
 ('proof-case edge omitted',lambda x:x['full_ordered_required_proof_case_relations'].pop()),
 ('same length edge substituted',lambda x:x['full_ordered_required_proof_case_relations'][0].update(case_id='raw-status-latch')),
 ('whole raw group omitted',lambda x:x['full_original_raw_groups335'].pop()),
 ('case source gate omitted',lambda x:x['case_evidence_review'][0]['all_original_source_evidence_gates'].pop()),
 ('whole326 oracle waived',lambda x:x['full_original_contract326']['document']['independent_conformance_contract'].update(oracle='subject PASS')),
 ('335 verifier author allowance waived',lambda x:x['full_original_independence_contract335'].update(expectation_author='must be fourth person')),
 ('351 nullable private boundary changed',lambda x:x['full_original_independent_expectation_contract351'].update(nullable_boundary='null equals empty')),
 ('374 child closure omitted',lambda x:x['full_accepted374_target_closure_review'].pop(3)),
 ('374 uncertainty collapsed',lambda x:x['full_accepted374_uncertainty_domains'][1].update(actual_state='absent')),
 ('374 publication selfreceipt added',lambda x:x['full_accepted374_publication_sequence_review'][5].update(required_future_observation='selfreceipt')),
 ('374 lost ACK replay',lambda x:x['full_accepted374_publication_failure_cut_review'][13].update(required_future_disposition='retry')),
 ('primitive native blocker waived',lambda x:x['inherited372_feasibility_blockers'][0].update(native_gap_closed=True)),
 ('primary scope made restrictive',lambda x:x.update(primary_assignment_limits_normative_scope=True)),
 ('native proof discharge',lambda x:x.update(native_proofs_added=1)),
 ('native case run',lambda x:x.update(native_cases_run=1)),
 ('runtime authority',lambda x:x.update(runtime_authority=True)),
 ('native feasibility made ready',lambda x:x.update(native_readiness_still_blocked=False)),
 ('premature pause',lambda x:x.update(conditional_pause_step=375)),
 ('automatic379',lambda x:x.update(no_automatic379=False)),
 ('bool schema',lambda x:x.update(schema=True))]
for label,mutate in mutations:
    bad=copy.deepcopy(design);mutate(bad);check('reject '+label,rejected(m['validate_design'],bad,inputs,p))
for key in no_claim_keys:
    bad=copy.deepcopy(design);bad[key]=True;check('reject false current '+key,rejected(m['validate_design'],bad,inputs,p))
for collection,key in [('role_trust_review','actual_trust_origin_review'),('raw_group_evidence_review','actual_expected_vector'),('fault_control_review','actual_negative_control_effectiveness'),('comparison_requirement_review','actual_result')]:
    for i,row in enumerate(design[collection]):
        bad=copy.deepcopy(design);bad[collection][i][key]='invented-native-evidence';check('reject invented observation '+collection+' '+str(i),rejected(m['validate_design'],bad,inputs,p))
for i,row in enumerate(design['case_evidence_review']):
    bad=copy.deepcopy(design);bad['case_evidence_review'][i]['actual_native_result']='PASS';check('reject invented native case '+row['platform']+' '+row['case_id'],rejected(m['validate_design'],bad,inputs,p))
for i,row in enumerate(design['role_trust_review']):
    bad=copy.deepcopy(design);bad['role_trust_review'][i]['current_authority']=True;check('reject role grant '+row['id'],rejected(m['validate_design'],bad,inputs,p))
bad=copy.deepcopy(design);bad['platform_readiness'][1]=copy.deepcopy(bad['platform_readiness'][0]);check('reject platform evidence borrowing',rejected(m['validate_design'],bad,inputs,p))
for key,value in [('C_port_open',True),('production_entry_closed',False),('phase2_open',True),('machine_action_required',True),('controller_action_required',True),('historical_binding_or_authority_reuse_allowed',True),('current_step_strong_safe_pause',True),('native_components_selected',True),('actual_independent_collector_selected',True),('actual_independent_verifier_selected',True),('actual_independent_expectations_proven',True),('actual_native_fault_effectiveness_proven',True),('actual_native_comparison_proven',True),('actual_global_host_closure',True),('actual_live_bindings',{})]:
    bad=copy.deepcopy(design);bad['boundaries'][key]=value;check('reject closed boundary changed '+key,rejected(m['validate_design'],bad,inputs,p))
bad=copy.deepcopy(p);bad['baseline_sha256']['README.md']='0'*64;check('reject policy substitution',rejected(m['validate_policy'],bad))
out=m['review'](design,c,r,inputs,sources,readme,p)
check('report retains whole normative rows gaps and accepted374',out['full_original_native_gap_rows348']==freeze['full_original_native_gap_rows348'] and out['full_normative_rows347']==freeze['full_normative_rows347'] and out['full_accepted_design374']==inputs['design374'])
out['design']['case_evidence_review'].pop();out['full_normative_rows347'].clear();out['boundaries']['actual_native_comparison_proven']=True
again=m['review'](design,c,r,inputs,sources,readme,p)
check('report mutations detached from caller and later review',len(again['design']['case_evidence_review'])==len(design['case_evidence_review'])==52 and len(again['full_normative_rows347'])==16 and not again['boundaries']['actual_native_comparison_proven'])
tree=ast.parse(tool.read_text());imports={a.name for node in ast.walk(tree) if isinstance(node,ast.Import) for a in node.names}
check('pure reviewer imports only hashlib json re',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen','sign','verify','fork','spawn','pipe','fsync','kill','clock_gettime','rename','unlink','mkdir'}
check('reviewer has no raw collector crypto storage clock native comparator injector or dispatch',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
