#!/bin/bash
set -euo pipefail
export LC_ALL=C
repo=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 - "$repo" <<'PYTEST'
from pathlib import Path
import ast, copy, json, runpy, subprocess, sys
root=Path(sys.argv[1]); step='phase-1-operational-writer-trust-contract-decision-brief'
prefix=root/'tests/fixtures/reference/acceptance/phase-1'
def load(s): return json.loads((prefix/(step+'-'+s+'.json')).read_bytes())
entry,baseline,brief,sources,policy=[load(s) for s in ['entry389','baseline','brief','sources','policy']]
tool=root/'tools/reference'/(step+'.py');m=runpy.run_path(str(tool));passes=0
def check(label,value):
 global passes
 if not value: raise SystemExit('FAIL: '+label)
 passes+=1;print('PASS: '+label)
def rejected(fn,*args):
 try: fn(*args)
 except (ValueError,KeyError,TypeError): return True
 return False
def safe(rel):
 p=root/rel
 if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root): raise SystemExit('FAIL: unsafe artifact '+rel)
 return p.read_bytes()
inputs={k:safe(v['path']) for k,v in sources['inputs'].items()}
roots=sources['inert_roots']+sources['reviewer_roots']+[sources['readme']]
source_blobs={r['path']:safe(r['path']) for r in roots}
blobs={p:safe(p) for p in baseline};addition=blobs['CHANGELOG.md'][:-policy['accepted_changelog_size_bytes']]
check('authored390 policy independently frozen',m['validate_policy'](policy))
check('whole entry baseline brief and source fixtures exact',m['validate_fixtures'](entry,baseline,brief,sources,policy))
check('complete unchanged389 return exact171 labels creates commit push and clean matching heads',m['validate_entry'](entry,policy))
check('all44 normative inputs four inert eleven reviewer and README roots',m['validate_inputs'](inputs,source_blobs,sources,policy))
check('all2042 accepted389 bytes preserved except additive CHANGELOG',m['validate_baseline'](blobs,baseline,addition,policy))
check('three inactive options WHOLE original clauses and unselected draft migration',m['validate_brief_shape'](brief,inputs,sources))
if (root/'.git').exists():
 raw=subprocess.run(['git','-C',str(root),'ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True).stdout
 actual={x.decode() for x in raw.split(b'\0') if x}
else: actual={str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight new Git-visible artifacts and no unrelated scope',actual==set(baseline)|set(policy['new_paths']))
mutations=[
 ('boolean schema',lambda b:b.update(schema=True)),
 ('shortened WHOLE writer review',lambda b:b['whole_original_writer_review']['original324_guard_contract'].pop('coverage')),
 ('original requirement removed',lambda b:b.update(whole_original_requirements_remain_normative=False)),
 ('writer domain omitted',lambda b:b['resource_domain_rows'].pop()),
 ('privileged writer class omitted',lambda b:b['writer_classes'].remove('privileged')),
 ('classification promoted to inventory',lambda b:b.update(writer_classification_is_actual_inventory=True)),
 ('selected trust amendment',lambda b:b.update(selected_option='explicit-trusted-host-boundary')),
 ('approved draft migration',lambda b:b.update(approved_contract_migration={})),
 ('invented actual trusted actor boundary',lambda b:b.update(actual_trust_boundary={})),
 ('invented actual guard policy',lambda b:b.update(actual_guard_policy={})),
 ('invented writer inventory',lambda b:b.update(actual_writer_inventory=[])),
 ('native grant',lambda b:b.update(native_authority=True)),
 ('upstream source as native proof',lambda b:b.update(source_documentation_is_native_proof=True)),
 ('universal impossibility claimed',lambda b:b.update(universal_impossibility_proven=True)),
 ('new native proof',lambda b:b.update(new_native_proofs=1)),
 ('new native case',lambda b:b.update(new_native_cases=1)),
 ('premature safe pause',lambda b:b.update(current_step_strong_safe_pause=True)),
 ('close shifted earlier',lambda b:b.update(conditional_close_step=390)),
 ('wrong successor',lambda b:b.update(next_preparable_step_after_complete390_acceptance=392)),
 ('retention omitted',lambda b:b['options'].pop(0)),
 ('deferral omitted',lambda b:b['options'].pop()),
 ('amendment guarantee loss hidden',lambda b:b['options'][1].update(guarantees_lost_or_changed=[])),
 ('amendment impact hidden',lambda b:b['options'][1]['migration_impact'].update(exact_changed_clause_candidates=[])),
 ('amendment wording shortened',lambda b:b['options'][1]['proposed_clause_text'].pop('trusted_host_assumption')),
 ('amendment hidden inside retention',lambda b:b['options'][0]['proposed_clause_text'].update(coverage='subset')),
]
for label,mutate in mutations:
 bad=copy.deepcopy(brief);mutate(bad)
 check('semantic rejection: '+label,rejected(m['validate_brief_shape'],bad,inputs,sources))
for key,value in brief['boundaries'].items():
 bad=copy.deepcopy(brief);bad['boundaries'][key]=not value if type(value)is bool else (value+1 if type(value)is int else {})
 check('semantic rejection of closed boundary '+key,rejected(m['validate_brief_shape'],bad,inputs,sources))
for i,opt in enumerate(brief['options']):
 for field,value in [('explicit_user_decision_required',False),('implementation_selected',True),('runtime_authority',True),('independent_evidence_required',[]),('dependencies_and_incompatibilities',[])]:
  bad=copy.deepcopy(brief);bad['options'][i][field]=value
  check('semantic option'+str(i)+' rejection '+field,rejected(m['validate_brief_shape'],bad,inputs,sources))
 for j,row in enumerate(opt['exact_current_clause_bindings']):
  bad=copy.deepcopy(brief);bad['options'][i]['exact_current_clause_bindings'][j]['whole_current_value']={'summary':True}
  check('semantic option'+str(i)+' WHOLE clause'+str(j)+' truncation rejected',rejected(m['validate_brief_shape'],bad,inputs,sources))
 for j,row in enumerate(opt['platform_rows']):
  for key in ['support','installed_versions','actual_composition','native_evidence','entry_authorized']:
   bad=copy.deepcopy(brief);bad['options'][i]['platform_rows'][j][key]=True
   check('semantic option'+str(i)+' platform'+str(j)+' promotion '+key,rejected(m['validate_brief_shape'],bad,inputs,sources))
 for key,value in [('approved_migration',{}),('affected_proofs_cases_relations_complete',True),('all_other_original_clauses_remain_binding',False)]:
  bad=copy.deepcopy(brief);bad['options'][i]['migration_impact'][key]=value
  check('semantic option'+str(i)+' migration promotion '+key,rejected(m['validate_brief_shape'],bad,inputs,sources))
for key in inputs:
 bad=dict(inputs);bad[key]+=b'\n'
 check('reject whole original input drift '+key,rejected(m['validate_inputs'],bad,source_blobs,sources,policy))
for row in roots:
 bad=dict(source_blobs);bad[row['path']]+=b'\n'
 check('reject source root drift '+row['path'],rejected(m['validate_inputs'],inputs,bad,sources,policy))
bad=copy.deepcopy(entry);bad['receipt']['text']=bad['receipt']['text'][:-1]
check('reject truncated actual389 return',rejected(m['validate_entry'],bad,policy))
bad=copy.deepcopy(entry);bad['confirmation']['commit_full']='invented'
check('reject invented full commit identity',rejected(m['validate_entry'],bad,policy))
bad=copy.deepcopy(sources);bad['actual_installed_platform_support']=True
check('reject source register promoted to actual support',rejected(m['validate_inputs'],inputs,source_blobs,bad,policy))
for path in ['README.md','CHANGELOG.md']:
 bad=dict(blobs);bad[path]+=b'\n'
 check('reject immutable predecessor rewrite '+path,rejected(m['validate_baseline'],bad,baseline,addition,policy))
bad=copy.deepcopy(policy);bad['step']=391
check('reject reanchored policy',rejected(m['validate_policy'],bad))
report=m['review'](entry,baseline,brief,sources,inputs,source_blobs,policy)
check('report leaves selection migration authority and current pause inactive',report['selected_option'] is None and report['approved_contract_migration'] is None and report['native_authority'] is False and report['strong_safe_pause'] is False)
check('report requires actual390 acceptance before391 and stops after398',report['after_actual390_acceptance_next_preparable_step']==391 and report['next_authorized_stage_after398'] is None)
report['brief']['options'].clear()
check('detached report cannot alter retained decision options',len(brief['options'])==3)
for path in [r['path'] for r in sources['reviewer_roots']]+['tools/reference/'+step+'.py']:
 tree=ast.parse(safe(path));imports={a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names}
 calls={n.func.id for n in ast.walk(tree) if isinstance(n,ast.Call) and isinstance(n.func,ast.Name)}
 forbidden={'open','exec','eval','compile','__import__','getattr','globals','locals','input','breakpoint'}
 check('pure supplied-data reviewer no native dispatch '+path,imports<={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)) and not(calls&forbidden))
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
