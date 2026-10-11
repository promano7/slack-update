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

root=Path(sys.argv[1]);name='phase-1-operational-successor-design-freeze-and-safe-pause-review'
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
p=load('policy');freeze=load('freeze');pause=load('pause-conditions');c=load('confirmed377');r=load('step377-user-acceptance')
check('authored378 policy independently frozen',m['validate_policy'](p))
check('all1945 accepted377 baseline bindings retained',len(p['baseline_sha256'])==p['accepted_source_count']==1945)
history={}
for rel,digest in p['baseline_sha256'].items():
    path=root/rel
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute() or not path.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=path.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-p['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted377 drift: '+rel)
    history[rel]=raw
check('all accepted377 bytes preserved except additive CHANGELOG',len(history)==1945)
check('complete377 uploaded return and reported acceptance validate',m['validate_acceptance'](c,r,p))
check('all332 exact predecessor labels and reported nine-file scope retained',len(p['accepted377_contract']['expected_ordered377_labels'])==332 and len(p['accepted377_contract']['expected_changed_paths'])==9)
check('exact received message SHA size and no normalization',sha(r['text'].encode())==r['sha256']==c['receipt_sha256'] and len(r['text'].encode())==r['size_bytes']==c['receipt_size_bytes']==27577 and r['normalization']=='none')
check('377 is not a new pause or independent native inspection',c['commit_prefix']=='009a8c5' and c['commit_full'] is None and not c['strong_safe_pause'] and c['last_confirmed_strong_safe_pause_step']==368 and 'not-independent-terminal-byte-capture' in r['capture_basis'])
inputs={k:json.loads(history[path]) for k,path in p['input_paths'].items()}
for k,path in p['input_paths'].items():check('whole input byte and canonical binding '+k,sha(history[path])==p['input_file_sha256'][k] and m['canonical'](inputs[k])==p['input_canonical_sha256'][k])
sources={row['path']:history[row['path']] for row in p['source_roots']};readme=(root/'README.md').read_bytes();original=inputs['freeze']
check('all full frozen design inputs validate',m['validate_frozen_inputs'](inputs,p))
check('four unchanged review roots and exact accepted377 README validate',m['validate_sources'](sources,readme,p))
check('complete successor design freeze validates',m['validate_freeze'](freeze,pause,inputs,p))
check('all nine original scoped pause conditions validate',m['validate_pause_conditions'](pause,freeze,inputs,p))
check('whole original ten-stage369through378 roadmap frozen',freeze['full_roadmap369_378']==inputs['plan369']['roadmap'] and [row['step'] for row in freeze['full_roadmap369_378']]==list(range(369,379)) and freeze['batch_length']==10)
check('nine accepted checkpoint confirmations in exact order',[row['step'] for row in freeze['accepted_checkpoint_chain369_377']]==list(range(369,378)))
prefixes=['3a99d10','607d43c','e6d341f','f8059fc','39f33f8','9bc9668','2218052','24e5dcc','009a8c5']
for row,prefix in zip(freeze['accepted_checkpoint_chain369_377'],prefixes):
    confirmation=row['full_external_confirmation']
    check('full external accepted checkpoint '+str(row['step']),confirmation['step']==row['step'] and confirmation['commit_prefix']==prefix and confirmation['commit_full'] is None and row['whole_confirmation_canonical_sha256']==m['canonical'](confirmation) and not confirmation['strong_safe_pause'] and not confirmation['runtime_authority'] and confirmation['user_worktree_clean'] and confirmation['user_head_matches_origin'])
check('historical369 transcription basis preserved','transcrib' in freeze['accepted_checkpoint_chain369_377'][0]['full_external_confirmation']['basis'].lower())
for key,count in [('full_original_contracts320_327',8),('full_normative_rows347',16),('full_original_native_gap_rows348',16),('full_qualified_proof_rows347',46),('full_native_case_rows347',52),('full_independent_raw_groups335',12),('ordered_required_proof_case_relations',1072)]:
    check('whole original normative collection exact '+key,freeze[key]==original[key] and len(freeze[key])==count)
for key,rows in freeze['full_normative_rows347'].items():check('whole original normative section '+key,rows==original['full_normative_rows347'][key])
for row,source in zip(freeze['full_original_native_gap_rows348'],original['full_original_native_gap_rows348']):check('whole original gap still pending '+row['inherited_gap']['id'],row==source)
check('all original proof-case relation tuples full and ordered',freeze['ordered_required_proof_case_relations']==inputs['design376']['full_ordered_required_proof_case_relations'] and len(inputs['design376']['proof_case_relation_review'])==1072)
previous=inputs['design377']
check('whole original sixteen prerequisites frozen',freeze['full_original_prerequisite_rows365']==previous['full_original_prerequisite_rows'])
for row in freeze['full_original_prerequisite_rows365']:
    check('original full prerequisite source and pending '+row['id'],row==next(x for x in inputs['prerequisites']['prerequisite_rows'] if x['id']==row['id']) and not row['gap_discharged'] and row['actual_selected_component'] is None and row['actual_native_event_refinement'] is None)
    for platform in row['platform_readiness']:check('native platform still unbound '+platform['id'],all(v is None for k,v in platform.items() if k.startswith('actual_')) and not platform['execution_authorized'] and not platform['native_proof'])
for suffix,count in [('gap_readiness_review',16),('successor_design_findings',7),('unresolved_conflict_review',8),('future_test_entry_prerequisites',10),('future_operational_readiness_prerequisites',5)]:check('whole accepted377 '+suffix,freeze['full_accepted377_'+suffix]==previous[suffix] and len(freeze['full_accepted377_'+suffix])==count)
check('whole ten original372 blockers unresolved',freeze['inherited372_feasibility_blockers']==previous['inherited372_feasibility_blockers'] and len(freeze['inherited372_feasibility_blockers'])==10 and all(not row['native_gap_closed'] for row in freeze['inherited372_feasibility_blockers']))
check('whole original stage12 causal gap unmodified',freeze['stage12_receipt_causal_obligation']==previous['stage12_receipt_causal_obligation']==inputs['design376']['stage12_receipt_causal_obligation'])
check('test-entry vs later conformance distinction frozen without grant',not previous['future_test_entry_requires_prior_native_test_success'] and not previous['future_test_authorization_issued'] and not previous['review_acceptance_is_authorization'])
check('exact accepted377README retained no378edit',sha(readme)==p['readme_at_entry_sha256']==freeze['readme']['accepted377_exact_sha256']==p['baseline_sha256']['README.md'] and freeze['readme']['full_accepted377_reconciliation']==previous['readme_reconciliation'] and not freeze['readme']['step378_changes_readme'])
check('377preparedwording immutable externalconfirmation supersedes',freeze['readme']['prepared377_acceptance_wording_superseded_only_by_external_CONFIRMED377'] and b'Step **377 is prepared; user acceptance is pending**' in readme and c['step']==377 and c['user_commit_and_push_completed'])
check('full historical361 private limitations exact',freeze['historical361_control_coverage']==original['historical361_control_coverage'])
check('twentyone whole input paths byte and canonical freeze exact',freeze['frozen_inputs']['paths']==p['input_paths'] and freeze['frozen_inputs']['file_sha256']==p['input_file_sha256'] and freeze['frozen_inputs']['canonical_sha256']==p['input_canonical_sha256'] and len(inputs)==21)
check('four original inert review source roles frozen',freeze['review_sources']==p['source_roots'] and len(freeze['review_sources'])==4)
check('no378primaryassignment no normative narrowing',freeze['primary_gap_ids']==inputs['plan369']['roadmap'][9]['primary_gap_ids']==[] and freeze['all_full_original_requirements_normative'] and not freeze['primary_assignment_limits_normative_scope'])
check('all nine original condition IDs full original order',[row['id'] for row in pause['conditions']]==inputs['plan369']['pause_policy']['original_condition_ids'] and [row['position'] for row in pause['conditions']]==list(range(9)))
for row,source in zip(pause['conditions'],inputs['pause']['conditions']):
    check('whole original scoped condition preserved '+row['id'],row['id']==row['requirement']==source['id'] and row['full_original_condition368']==source and row['full_original_condition358']==source['full_original_condition358'] and row['current378_actual_user_confirmation'] is None and row['actual_native_evidence'] is None and not row['actual_global_host_closure'] and bool(row['repository_review_basis']))
check('final receipt condition remains pending',pause['conditions'][0]['repository_status']=='pending-complete-current378-return')
check('eight other conditions scoped candidate reviewed not confirmed',all(row['repository_status']=='reviewed-candidate-repository-scope-only-with-native-blockers-retained' for row in pause['conditions'][1:]))
check('pause original358and368 full source hashes exact',pause['full_original_conditions358_canonical_sha256']==inputs['pause']['full_original_conditions358_canonical_sha256'] and pause['full_original_conditions368_canonical_sha256']==m['canonical'](inputs['pause']['conditions']))
check('pause scope exactly original369plan',pause['scope']==freeze['scope']==inputs['plan369']['scope'] and pause['scope']=='repository-operational-successor-design-workstream369-378-only')
check('private eligibility is never actual378confirmation',freeze['repository_review_eligible_for_conditional_pause'] and not freeze['private_eligibility_is_actual_confirmation'] and not pause['private_eligibility_is_actual_confirmation'] and not freeze['actual_strong_safe_pause_confirmed'] and not pause['actual_strong_safe_pause_confirmed'])
check('current378actualcommit and final status unknown',all(pause[k] is None for k in ['current378_user_commit_prefix','current378_user_commit_full','current378_user_worktree_clean','current378_user_head_matches_origin']))
check('complete final receipt AND all nine conditions required',freeze['final_pause_requires_complete_user_receipt'] and freeze['final_pause_requires_all_nine_conditions'] and 'AND all nine' in pause['final_receipt_rule']['confirmation'])
check('stop after acceptance no nextauthorizedstage noautomatic379',freeze['after_final_acceptance']==pause['after_final_acceptance']==inputs['plan369']['pause_policy'] and freeze['after_final_acceptance']['stop_after_final_acceptance'] and freeze['after_final_acceptance']['future_batch_requires_new_user_request'] and freeze['next_authorized_stage_after378'] is None and freeze['no_automatic379'])
check('native readiness and all unknown host scope remain blocked',freeze['native_readiness_still_blocked'] and not freeze['runtime_authority'] and not freeze['contract_relaxation_permitted'] and freeze['native_cases_run']==freeze['native_proofs_added']==0 and pause['actual_host_state']=='unobserved-not-claimed-absent' and pause['actual_live_bindings'] is None and not pause['actual_global_host_closure'])
for key,value in [('commit_full','invented'),('strong_safe_pause',True),('runtime_authority',True),('actual_host_state','absent'),('actual_global_host_closure',True),('actual_live_bindings',{}),('user_worktree_clean',False),('user_head_matches_origin',False),('native_cases_run',1),('native_proofs_added',1)]:
    bad=copy.deepcopy(c);bad[key]=value;check('reject invented377 '+key,rejected(m['validate_acceptance'],bad,r,p))
labels=p['accepted377_contract']['expected_ordered377_labels']
for label,edit in [('truncated upload',lambda x:x[:-1]),('same-length receipt edit',lambda x:x.replace('009a8c5','009a8c6',1)),('dirty status injection',lambda x:x.replace('009a8c5 (HEAD',' M README.md\n009a8c5 (HEAD',1)),('reordered PASS labels',lambda x:x.replace(labels[0]+'\n'+labels[1],labels[1]+'\n'+labels[0]))]:
    bad=copy.deepcopy(r);bad['text']=edit(r['text']);check('reject '+label,rejected(m['validate_acceptance'],c,bad,p))
bad=copy.deepcopy(r);bad['capture_basis']='independent-terminal';check('reject invented capture origin',rejected(m['validate_acceptance'],c,bad,p))
for key in inputs:
    bad=copy.deepcopy(inputs);bad[key]['invented']=True;check('reject changed whole input '+key,rejected(m['validate_frozen_inputs'],bad,p))
bad=dict(sources);bad[next(iter(sources))]+=b'\n';check('reject historical source drift',rejected(m['validate_sources'],bad,readme,p))
bad=dict(sources);bad['restore-worker.sh']=b'claimed';check('reject fifth restoration root',rejected(m['validate_sources'],bad,readme,p))
check('reject accepted377 README edit',rejected(m['validate_sources'],sources,readme+b'\n',p))
mutations=[
('roadmap shortened',lambda x:x['full_roadmap369_378'].pop()),
('automatic379 roadmap stage',lambda x:x['full_roadmap369_378'].append({'step':379})),
('predecessor skipped',lambda x:x['accepted_checkpoint_chain369_377'].pop()),
('prior synthetic ID invented',lambda x:x['accepted_checkpoint_chain369_377'][0]['full_external_confirmation'].update(commit_full='invented')),
('native gap removed',lambda x:x['full_original_native_gap_rows348'].pop()),
('original contract waived',lambda x:x['full_original_contracts320_327'].clear()),
('proof subset',lambda x:x['full_qualified_proof_rows347'].pop()),
('case subset',lambda x:x['full_native_case_rows347'].pop()),
('raw group subset',lambda x:x['full_independent_raw_groups335'].pop()),
('relation subset',lambda x:x['ordered_required_proof_case_relations'].pop()),
('original prerequisite waived',lambda x:x['full_original_prerequisite_rows365'].pop()),
('stage12 causal gap resolved',lambda x:x.update(stage12_receipt_causal_obligation={})),
('native family blocker waived',lambda x:x['inherited372_feasibility_blockers'][0].update(native_gap_closed=True)),
('README modified',lambda x:x['readme'].update(step378_changes_readme=True)),
('historical361 limits hidden',lambda x:x['historical361_control_coverage'].clear()),
('whole input changed',lambda x:x['frozen_inputs']['canonical_sha256'].update(design376='0'*64)),
('all conditions no longer required',lambda x:x.update(final_pause_requires_all_nine_conditions=False)),
('receipt no longer required',lambda x:x.update(final_pause_requires_complete_user_receipt=False)),
('private eligibility confirms',lambda x:x.update(private_eligibility_is_actual_confirmation=True)),
('currentpause confirmed',lambda x:x.update(actual_strong_safe_pause_confirmed=True)),
('nextstage379 authorized',lambda x:x.update(next_authorized_stage_after378=379)),
('automatic379',lambda x:x.update(no_automatic379=False)),
('native readiness ready',lambda x:x.update(native_readiness_still_blocked=False)),
('native run claimed',lambda x:x.update(native_cases_run=1)),
('nativeproof claimed',lambda x:x.update(native_proofs_added=1)),
('runtime granted',lambda x:x.update(runtime_authority=True)),
('guarantee relaxed',lambda x:x.update(contract_relaxation_permitted=True)),
('bool schema',lambda x:x.update(schema=True))]
for label,mutate in mutations:
    bad=copy.deepcopy(freeze);mutate(bad);check('reject '+label,rejected(m['validate_freeze'],bad,pause,inputs,p))
for key in freeze['full_normative_rows347']:
    bad=copy.deepcopy(freeze);bad['full_normative_rows347'][key]=[];check('reject original normative section waived '+key,rejected(m['validate_freeze'],bad,pause,inputs,p))
for suffix in ['gap_readiness_review','successor_design_findings','unresolved_conflict_review','future_test_entry_prerequisites','future_operational_readiness_prerequisites']:
    bad=copy.deepcopy(freeze);bad['full_accepted377_'+suffix].pop();check('reject accepted377 scope truncated '+suffix,rejected(m['validate_freeze'],bad,pause,inputs,p))
for i,row in enumerate(pause['conditions']):
    for key,value in [('id','renamed-condition'),('requirement','relaxed-condition'),('position',9),('current378_actual_user_confirmation',True),('actual_native_evidence','PASS'),('actual_global_host_closure',True),('full_original_condition358',{}),('full_original_condition368',{})]:
        bad=copy.deepcopy(pause);bad['conditions'][i][key]=value;check('reject original condition mutation '+row['id']+' '+key,rejected(m['validate_pause_conditions'],bad,freeze,inputs,p))
for key,value in [('scope','host-global'),('current378_user_commit_prefix','synthetic'),('current378_user_commit_full','invented'),('current378_user_worktree_clean',True),('current378_user_head_matches_origin',True),('actual_strong_safe_pause_confirmed',True),('private_eligibility_is_actual_confirmation',True),('runtime_authority',True),('actual_host_state','absent'),('actual_live_bindings',{}),('actual_global_host_closure',True)]:
    bad=copy.deepcopy(pause);bad[key]=value;check('reject premature pause or host inference '+key,rejected(m['validate_pause_conditions'],bad,freeze,inputs,p))
for label,mutate in [('condition missing',lambda x:x['conditions'].pop()),('condition reordered',lambda x:x['conditions'].reverse()),('condition extra',lambda x:x['conditions'].append(copy.deepcopy(x['conditions'][0]))),('stop disabled',lambda x:x['after_final_acceptance'].update(stop_after_final_acceptance=False)),('future request waived',lambda x:x['after_final_acceptance'].update(future_batch_requires_new_user_request=False)),('automatic379 allowed',lambda x:x['after_final_acceptance'].update(next_authorized_stage_after378=379)),('receipt rule shortened',lambda x:x['final_receipt_rule'].update(confirmation='private PASS enough'))]:
    bad=copy.deepcopy(pause);mutate(bad);check('reject '+label,rejected(m['validate_pause_conditions'],bad,freeze,inputs,p))
for key,value in freeze['boundaries'].items():
    if isinstance(value,bool):changed=not value
    elif value is None:changed={}
    elif isinstance(value,int):changed=value+1
    else:changed='invented-state'
    bad=copy.deepcopy(freeze);bad['boundaries'][key]=changed;check('reject closed frozen boundary changed '+key,rejected(m['validate_freeze'],bad,pause,inputs,p))
for label,raw in [('same length current edit',readme.replace(b'24e5dcc',b'24e5dcd',1)),('extra current prefix',b'X'+readme),('historical suffix edit',readme[:-1]+b'X')]:check('reject acceptedREADME '+label,rejected(m['validate_sources'],sources,raw,p))
bad=copy.deepcopy(p);bad['baseline_sha256']['README.md']='0'*64;check('reject policy substitution',rejected(m['validate_policy'],bad))
out=m['review'](freeze,pause,c,r,inputs,sources,readme,p)
check('report retains full frozen inputs and candidateconditions',out['full_frozen_inputs']==inputs and out['pause_conditions']==pause and not out['actual_current_strong_safe_pause_confirmed'])
out['freeze']['full_normative_rows347'].clear();out['pause_conditions']['conditions'].clear();out['full_frozen_inputs']['design376']['proof_case_relation_review'].clear();out['boundaries']['strong_safe_pause']=True
again=m['review'](freeze,pause,c,r,inputs,sources,readme,p)
check('report mutations detached from caller and laterreview',len(again['freeze']['full_normative_rows347'])==len(freeze['full_normative_rows347'])==16 and len(again['pause_conditions']['conditions'])==len(pause['conditions'])==9 and len(again['full_frozen_inputs']['design376']['proof_case_relation_review'])==len(inputs['design376']['proof_case_relation_review'])==1072 and not again['boundaries']['strong_safe_pause'])
tree=ast.parse(tool.read_text());imports={a.name for node in ast.walk(tree) if isinstance(node,ast.Import) for a in node.names}
check('pure reviewer imports only hashlib json re',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen','sign','verify','fork','spawn','pipe','fsync','kill','clock_gettime','rename','unlink','mkdir'}
check('reviewer has no filesystem network native runner service channel or dispatch',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
