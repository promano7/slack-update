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

root=Path(sys.argv[1]);name='phase-1-operational-design-readiness-readme-review'
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
p=load('policy');design=load('design');c=load('confirmed376');r=load('step376-user-acceptance')
check('authored377 policy independently frozen',m['validate_policy'](p))
check('all1938 accepted376 baseline bindings retained',len(p['baseline_sha256'])==p['accepted_source_count']==1938)
history={}
for rel,digest in p['baseline_sha256'].items():
    path=root/rel
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute() or not path.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=path.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-p['accepted_changelog_size_bytes']:]
    if rel=='README.md':raw=raw[-p['accepted_readme_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted376 drift: '+rel)
    history[rel]=raw
check('all accepted376 bytes preserved except additive CHANGELOG and README',len(history)==1938)
check('complete376 uploaded return and reported acceptance validate',m['validate_acceptance'](c,r,p))
check('all547 exact predecessor labels and reported eight-file scope retained',len(p['accepted376_contract']['expected_ordered376_labels'])==547 and len(p['accepted376_contract']['expected_changed_paths'])==8)
check('exact received message SHA size and no normalization',sha(r['text'].encode())==r['sha256']==c['receipt_sha256'] and len(r['text'].encode())==r['size_bytes']==c['receipt_size_bytes']==39269 and r['normalization']=='none')
check('376 is not a new pause or independent native inspection',c['commit_prefix']=='24e5dcc' and c['commit_full'] is None and not c['strong_safe_pause'] and c['last_confirmed_strong_safe_pause_step']==368 and 'not-independent-terminal-byte-capture' in r['capture_basis'])
inputs={k:json.loads(history[path]) for k,path in p['input_paths'].items()}
for k,path in p['input_paths'].items():check('whole input byte and canonical binding '+k,sha(history[path])==p['input_file_sha256'][k] and m['canonical'](inputs[k])==p['input_canonical_sha256'][k])
sources={row['path']:history[row['path']] for row in p['source_roots']};readme=(root/'README.md').read_bytes();freeze=inputs['freeze']
check('all full frozen design inputs validate',m['validate_frozen_inputs'](inputs,p))
check('four unchanged review roots and additive current README validate',m['validate_sources'](sources,readme,p))
check('complete readiness and README draft validates',m['validate_design'](design,inputs,p))
check('original377 no primary assignment preserves whole scope',design['primary_gap_ids']==inputs['plan369']['roadmap'][8]['primary_gap_ids']==[] and design['all_full_original_requirements_normative'] and not design['primary_assignment_limits_normative_scope'])
check('exact new README and whole accepted376 suffix',sha(readme)==p['readme_postimage_sha256'] and sha(readme[-p['accepted_readme_size_bytes']:])==p['readme_at_entry_sha256']==p['baseline_sha256']['README.md'])
rec=design['readme_reconciliation'];addition=readme[:-p['accepted_readme_size_bytes']]
check('authored additive README prefix and no historical rewrite',sha(addition)==rec['addition_sha256'] and rec['postimage_sha256']==sha(readme) and rec['accepted376_size_bytes']==p['accepted_readme_size_bytes'] and not rec['historical367_bytes_rewritten'])
for phrase in ['step-377-readme-roadmap-reconciliation:start','step-377-readme-roadmap-reconciliation:end','Step **377 is prepared; user acceptance is pending**','confirmed strong repository-scoped safe pause is 368','no automatic 379','whole original stage 12','Phase 1 and the kernel package edge remain incomplete','52 native cases','five families/twenty scenarios','separate fresh explicit','actual live bindings remain null']:
    check('README current claim '+phrase,phrase.lower().encode() in addition.lower())
for prefix in ['3a99d10','607d43c','e6d341f','f8059fc','39f33f8','9bc9668','2218052','24e5dcc']:check('README individual accepted design '+prefix,prefix.encode() in addition)
original=inputs['prerequisites']['prerequisite_rows']
check('all sixteen whole original prerequisite rows',design['full_original_prerequisite_rows']==original and len(original)==16)
check('all sixteen gap readiness order',[row['id'] for row in design['gap_readiness_review']]==[row['id'] for row in original])
for row,source in zip(design['gap_readiness_review'],original):
    check('whole original prerequisite and native pending '+row['id'],row['full_original_prerequisite_row']==source and row['whole_original_prerequisite_canonical_sha256']==m['canonical'](source) and row['actual_native_gap_resolution'] is None and not row['implementation_selected'] and not row['native_gap_closed'] and row['all_original_requirements_normative'] and row['all_successor_design_steps_reviewed']==list(range(370,377)))
    for platform in row['full_original_prerequisite_row']['platform_readiness']:
        check('original platform evidence still null '+platform['id'],all(v is None for k,v in platform.items() if k.startswith('actual_')) and not platform['execution_authorized'] and not platform['native_proof'])
check('seven accepted design findings cover370through376',[row['step'] for row in design['successor_design_findings']]==list(range(370,377)))
for row in design['successor_design_findings']:check('whole source bound accepted finding '+str(row['step']),row['whole_accepted_design_canonical_sha256']==m['canonical'](inputs['design'+str(row['step'])]) and not row['native_conformance'] and not row['current_authority'])
check('eight authored conflicts not native resolution',len(design['unresolved_conflict_review'])==8)
for row in design['unresolved_conflict_review']:check('conflict remains pending '+row['id'],bool(row['unresolved_requirement']) and row['actual_resolution'] is None and not row['native_blocker_resolved'] and not row['normative_relaxation_allowed'] and not row['current_authority'])
check('whole stage12 causal obligation unchanged',design['stage12_receipt_causal_obligation']==inputs['design376']['stage12_receipt_causal_obligation'])
check('all ten inherited372 blocker rows unchanged',design['inherited372_feasibility_blockers']==inputs['design376']['inherited372_feasibility_blockers'] and len(design['inherited372_feasibility_blockers'])==10)
for collection,count,kind in [('future_test_entry_prerequisites',10,'before-separately-authorized-bounded-native-test'),('future_operational_readiness_prerequisites',5,'after-separately-authorized-tests-before-separate-operational-review')]:
    check('prerequisite stage count '+collection,len(design[collection])==count)
    for row in design[collection]:check('future requirement grants nothing '+row['id'],row['gate_kind']==kind and bool(row['required_future_review']) and row['actual_evidence'] is None and not row['satisfied'] and not row['authorization_issued'] and not row['automatic_action'])
check('no circular test-success prerequisite before test entry',not design['future_test_entry_requires_prior_native_test_success'])
for key,count in [('full_original_contracts320_327',8),('full_normative_rows347',16),('full_original_native_gap_rows348',16),('full_qualified_proof_rows347',46),('full_native_case_rows347',52),('full_independent_raw_groups335',12),('ordered_required_proof_case_relations',1072)]:check('whole inherited normative scope '+key,len(freeze[key])==count)
check('whole accepted376 normative and case relation mapping remains input',inputs['design376']['full_original_normative_rows347']==freeze['full_normative_rows347'] and inputs['design376']['full_ordered_required_proof_case_relations']==freeze['ordered_required_proof_case_relations'] and len(inputs['design376']['proof_case_relation_review'])==1072)
check('377 has no readiness grant or native proof run',design['native_readiness_still_blocked'] and not design['future_test_authorization_issued'] and not design['review_acceptance_is_authorization'] and not design['contract_relaxation_permitted'] and not design['runtime_authority'] and design['native_cases_run']==design['native_proofs_added']==0)
check('complete377 required before conditional378 then stop',design['next_preparable_step_after_complete377_acceptance']==design['conditional_pause_step']==378 and design['no_automatic379'] and not design['boundaries']['current_step_strong_safe_pause'])
for key,value in [('commit_full','invented'),('strong_safe_pause',True),('runtime_authority',True),('actual_host_state','absent'),('actual_global_host_closure',True),('actual_live_bindings',{}),('user_worktree_clean',False),('user_head_matches_origin',False),('native_cases_run',1),('native_proofs_added',1)]:
    bad=copy.deepcopy(c);bad[key]=value;check('reject invented376 '+key,rejected(m['validate_acceptance'],bad,r,p))
labels=p['accepted376_contract']['expected_ordered376_labels']
for label,edit in [('truncated upload',lambda x:x[:-1]),('same-length receipt edit',lambda x:x.replace('24e5dcc','24e5dcd',1)),('dirty status injection',lambda x:x.replace('24e5dcc (HEAD',' M README.md\n24e5dcc (HEAD',1)),('reordered PASS labels',lambda x:x.replace(labels[0]+'\n'+labels[1],labels[1]+'\n'+labels[0]))]:
    bad=copy.deepcopy(r);bad['text']=edit(r['text']);check('reject '+label,rejected(m['validate_acceptance'],c,bad,p))
bad=copy.deepcopy(r);bad['capture_basis']='independent-terminal';check('reject invented capture origin',rejected(m['validate_acceptance'],c,bad,p))
for key in inputs:
    bad=copy.deepcopy(inputs);bad[key]['invented']=True;check('reject changed whole input '+key,rejected(m['validate_frozen_inputs'],bad,p))
bad=dict(sources);bad[next(iter(sources))]+=b'\n';check('reject historical source drift',rejected(m['validate_sources'],bad,readme,p))
bad=dict(sources);bad['restore-worker.sh']=b'claimed';check('reject fifth restoration root',rejected(m['validate_sources'],bad,readme,p))
check('reject premature README reconciliation',rejected(m['validate_sources'],sources,readme+b'\n',p))
mutations=[
('original prerequisite omitted',lambda x:x['full_original_prerequisite_rows'].pop()),
('whole gap requirement replaced',lambda x:x['gap_readiness_review'][0]['full_original_prerequisite_row'].update(implementation_review_required=[])),
('gap order reversed',lambda x:x['gap_readiness_review'].reverse()),
('primary gap invented',lambda x:x.update(primary_gap_ids=['invented'])),
('scope reduced',lambda x:x.update(all_full_original_requirements_normative=False)),
('stage12 causal gap declared resolved',lambda x:x.update(stage12_receipt_causal_obligation={})),
('original candidate blocker waived',lambda x:x['inherited372_feasibility_blockers'][0].update(native_gap_closed=True)),
('test success required before test grant',lambda x:x.update(future_test_entry_requires_prior_native_test_success=True)),
('README historical rewrite',lambda x:x['readme_reconciliation'].update(historical367_bytes_rewritten=True)),
('README postimage substituted',lambda x:x['readme_reconciliation'].update(postimage_sha256='0'*64)),
('test grant issued',lambda x:x.update(future_test_authorization_issued=True)),
('review acceptance grants authority',lambda x:x.update(review_acceptance_is_authorization=True)),
('native readiness claimed',lambda x:x.update(native_readiness_still_blocked=False)),
('native proof added',lambda x:x.update(native_proofs_added=1)),
('native case run',lambda x:x.update(native_cases_run=1)),
('guarantee relaxed',lambda x:x.update(contract_relaxation_permitted=True)),
('runtime granted',lambda x:x.update(runtime_authority=True)),
('premature pause',lambda x:x.update(conditional_pause_step=377)),
('automatic379',lambda x:x.update(no_automatic379=False)),
('bool schema',lambda x:x.update(schema=True))]
for label,mutate in mutations:
    bad=copy.deepcopy(design);mutate(bad);check('reject '+label,rejected(m['validate_design'],bad,inputs,p))
for i,row in enumerate(design['gap_readiness_review']):
    for key,value in [('actual_native_gap_resolution','PASS'),('implementation_selected',True),('native_gap_closed',True)]:
        bad=copy.deepcopy(design);bad['gap_readiness_review'][i][key]=value;check('reject native gap promotion '+row['id']+' '+key,rejected(m['validate_design'],bad,inputs,p))
    for j,platform in enumerate(row['full_original_prerequisite_row']['platform_readiness']):
        bad=copy.deepcopy(design);bad['gap_readiness_review'][i]['full_original_prerequisite_row']['platform_readiness'][j]['actual_native_result']='PASS';check('reject invented native platform '+platform['id'],rejected(m['validate_design'],bad,inputs,p))
for collection,key in [('unresolved_conflict_review','native_blocker_resolved'),('future_test_entry_prerequisites','authorization_issued'),('future_operational_readiness_prerequisites','satisfied')]:
    for i,row in enumerate(design[collection]):
        bad=copy.deepcopy(design);bad[collection][i][key]=True;check('reject future row promotion '+row['id'],rejected(m['validate_design'],bad,inputs,p))
for key,value in [('C_port_open',True),('phase2_open',True),('production_entry_closed',False),('machine_action_required',True),('controller_action_required',True),('historical_binding_or_authority_reuse_allowed',True),('current_step_strong_safe_pause',True),('native_components_selected',True),('actual_global_host_closure',True),('actual_live_bindings',{}),('future_test_authorization_issued',True),('readiness_review_is_authorization',True),('README_is_native_evidence',True)]:
    bad=copy.deepcopy(design);bad['boundaries'][key]=value;check('reject closed boundary changed '+key,rejected(m['validate_design'],bad,inputs,p))
for label,raw in [('old README only',history['README.md']),('same length current edit',readme.replace(b'24e5dcc',b'24e5dcd',1)),('historical suffix edit',readme[:-1]+b'X'),('extra addition',b'X'+readme)]:check('reject README '+label,rejected(m['validate_sources'],sources,raw,p))
bad=copy.deepcopy(p);bad['readme_postimage_sha256']=sha(history['README.md']);check('reject policy substitution',rejected(m['validate_policy'],bad))
out=m['review'](design,c,r,inputs,sources,readme,p)
check('report retains whole normative gaps and accepted376',out['full_original_native_gap_rows348']==freeze['full_original_native_gap_rows348'] and out['full_normative_rows347']==freeze['full_normative_rows347'] and out['full_accepted_design376']==inputs['design376'])
out['design']['gap_readiness_review'].clear();out['full_normative_rows347'].clear();out['boundaries']['future_test_authorization_issued']=True
again=m['review'](design,c,r,inputs,sources,readme,p)
check('report mutations detached from caller and later review',len(again['design']['gap_readiness_review'])==len(design['gap_readiness_review'])==16 and len(again['full_normative_rows347'])==16 and not again['boundaries']['future_test_authorization_issued'])
tree=ast.parse(tool.read_text());imports={a.name for node in ast.walk(tree) if isinstance(node,ast.Import) for a in node.names}
check('pure reviewer imports only hashlib json re',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen','sign','verify','fork','spawn','pipe','fsync','kill','clock_gettime','rename','unlink','mkdir'}
check('reviewer has no filesystem network spawn native test or dispatch',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
