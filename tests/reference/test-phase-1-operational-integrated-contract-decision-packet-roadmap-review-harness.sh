#!/bin/bash
set -euo pipefail
export LC_ALL=C
repo=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 - "$repo" <<'PYTEST'
from pathlib import Path
import ast,copy,json,runpy,subprocess,sys
root=Path(sys.argv[1]);step='phase-1-operational-integrated-contract-decision-packet-roadmap-review';prefix=root/'tests/fixtures/reference/acceptance/phase-1'
def load(s):return json.loads((prefix/(step+'-'+s+'.json')).read_bytes())
entry,baseline,packet,sources,policy=[load(s) for s in ['entry396','baseline','packet','sources','policy']]
tool=root/'tools/reference'/(step+'.py');m=runpy.run_path(str(tool));passes=0
def check(label,v):
 global passes
 if not v:raise SystemExit('FAIL: '+label)
 passes+=1;print('PASS: '+label)
def rejected(fn,*a):
 try:fn(*a)
 except (ValueError,KeyError,TypeError,IndexError):return True
 return False
def safe(rel):
 p=root/rel
 if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise SystemExit('FAIL: unsafe artifact '+rel)
 return p.read_bytes()
inputs={k:safe(v['path']) for k,v in sources['inputs'].items()};roots=sources['inert_roots']+sources['reviewer_roots']+[sources['readme']]
source_blobs={r['path']:safe(r['path']) for r in roots};blobs={p:safe(p) for p in baseline};addition=blobs['CHANGELOG.md'][:-policy['accepted_changelog_size_bytes']];readme_addition=blobs['README.md'][:-policy['accepted_readme_size_bytes']]
def shape(p):return m['validate_packet_shape'](p,inputs,sources,policy)
check('authored397 policy independently frozen',m['validate_policy'](policy))
check('whole entry baseline packet source fixtures exact',m['validate_fixtures'](entry,baseline,packet,sources,policy))
check('complete unchanged396 return exact506 labels creates commit push clean heads',m['validate_entry'](entry,policy))
check('all58 inputs four inert eighteen reviewer and current README roots',m['validate_inputs'](inputs,source_blobs,sources,policy))
check('all2098 accepted396 historical bytes exact except two additive prefixes',m['validate_baseline'](blobs,baseline,addition,policy,readme_addition))
check('all26 whole options eight decisions325pairs nine joint dimensions inactive',shape(packet))
if(root/'.git').exists():
 raw=subprocess.run(['git','-C',str(root),'ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True).stdout;actual={x.decode() for x in raw.split(b'\0') if x}
else:actual={str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions and two documentation changes no unrelated scope',actual==set(baseline)|set(policy['new_paths']))
mutations=[('boolean schema',lambda p:p.update(schema=True)),('shortened WHOLE original feasibility',lambda p:p['whole_original_integrated_feasibility_review'].clear()),('shortened roadmap',lambda p:p['whole_finite_roadmap'].pop()),('shortened whole pause policy',lambda p:p['whole_pause_policy'].clear()),('missing full option',lambda p:p['option_register'].pop()),('missing decision',lambda p:p['decision_rows'].pop()),('missing pair',lambda p:p['pair_review_questions'].pop()),('missing joint dimension',lambda p:p['joint_review_dimensions'].pop()),('original obligations waived',lambda p:p.update(whole_original_requirements_remain_normative=False)),('semantic migration complete',lambda p:p.update(semantic_migration_complete=True)),('independent impact acceptance invented',lambda p:p.update(independent_impact_review_accepted=True)),('joint native compatibility invented',lambda p:p.update(joint_native_compatibility_proven=True)),('premature pause',lambda p:p.update(current_step_strong_safe_pause=True)),('native grant',lambda p:p.update(native_authority=True)),('new native case',lambda p:p.update(native_cases_run=1)),('new native proof',lambda p:p.update(native_proofs_added=1)),('close shifted',lambda p:p.update(conditional_close_step=397)),('successor skips398',lambda p:p.update(next_preparable_step_after_complete397_acceptance=399)),('pair order changed',lambda p:p['pair_review_questions'].reverse())]
for field in ['selected_options','approved_joint_specification','approved_contract_migration','actual_selected_implementation','actual_joint_native_graph','actual_native_evidence','after_confirmed398_next_authorized_stage']:
 mutations.append(('invented '+field,lambda p,field=field:p.update({field:{}})))
for label,mutate in mutations:
 bad=copy.deepcopy(packet);mutate(bad);check('semantic rejection: '+label,rejected(shape,bad))
for key,v in packet['boundaries'].items():
 bad=copy.deepcopy(packet);bad['boundaries'][key]=not v if type(v)is bool else(v+1 if type(v)is int else{})
 check('semantic rejection of closed boundary '+key,rejected(shape,bad))
for i,row in enumerate(packet['option_register']):
 for key,v in [('whole_option',{'id':row['option_id']}),('whole_396_impact_review_canonical_sha256','invented'),('selected',True),('approved_migration',{}),('native_joint_compatibility',True),('runtime_authority',True)]:
  bad=copy.deepcopy(packet);bad['option_register'][i][key]=v
  check('semantic option'+str(i)+' truncation or promotion '+key,rejected(shape,bad))
for i,row in enumerate(packet['decision_rows']):
 for key,v in [('whole_original_conflict',{'id':row['id']}),('available_option_ids',[]),('selected_option_ids',[]),('explicit_user_decision_required',False),('native_blocker_resolved',True),('runtime_authority',True)]:
  bad=copy.deepcopy(packet);bad['decision_rows'][i][key]=v
  check('semantic whole decision'+str(i)+' truncation or promotion '+key,rejected(shape,bad))
representatives={}
for i,row in enumerate(packet['pair_review_questions']):representatives.setdefault(row['review_disposition'],i)
for disposition,i in representatives.items():
 for key,v in [('actual_joint_compatibility',True),('joint_specification_approved',True),('selected',True),('runtime_authority',True),('whole_conflict_dependencies',[])]:
  bad=copy.deepcopy(packet);bad['pair_review_questions'][i][key]=v
  check('semantic pair class '+disposition+' promotion '+key,rejected(shape,bad))
for i,row in enumerate(packet['joint_review_dimensions']):
 for key,v in [('affected_option_ids',[]),('actual_joint_resolution',{}),('native_compatibility_proven',True),('current_authority',True)]:
  bad=copy.deepcopy(packet);bad['joint_review_dimensions'][i][key]=v
  check('semantic joint dimension'+str(i)+' promotion '+key,rejected(shape,bad))
for key in inputs:
 bad=dict(inputs);bad[key]+=b'\n';check('reject whole original input drift '+key,rejected(m['validate_inputs'],bad,source_blobs,sources,policy))
for row in roots:
 bad=dict(source_blobs);bad[row['path']]+=b'\n';check('reject source root drift '+row['path'],rejected(m['validate_inputs'],inputs,bad,sources,policy))
bad=copy.deepcopy(entry);bad['receipt']['text']=bad['receipt']['text'][:-1];check('reject truncated actual396 return',rejected(m['validate_entry'],bad,policy))
bad=copy.deepcopy(entry);bad['confirmation']['commit_full']='invented';check('reject invented full commit identity',rejected(m['validate_entry'],bad,policy))
for p in ['README.md','CHANGELOG.md']:
 bad=dict(blobs);bad[p]+=b'\n';check('reject rewritten historical bytes '+p,rejected(m['validate_baseline'],bad,baseline,addition,policy,readme_addition))
check('reject altered README prefix',rejected(m['validate_baseline'],blobs,baseline,addition,policy,readme_addition+b'\n'))
bad=copy.deepcopy(policy);bad['expected_option_ids'].pop();check('reject reanchored policy',rejected(m['validate_policy'],bad))
report=m['review'](entry,baseline,packet,sources,inputs,source_blobs,policy)
check('report selection migration authority and current pause inactive',report['selected_options'] is None and report['approved_contract_migration'] is None and report['native_authority'] is False and report['strong_safe_pause'] is False)
check('report actual397 before398 and stop after398',report['after_actual397_acceptance_next_preparable_step']==398 and report['next_authorized_stage_after398'] is None)
report['packet']['option_register'].clear();check('detached report preserves original26options',len(packet['option_register'])==26)
for path in [r['path'] for r in sources['reviewer_roots']]+['tools/reference/'+step+'.py']:
 tree=ast.parse(safe(path));imports={a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names};calls={n.func.id for n in ast.walk(tree) if isinstance(n,ast.Call) and isinstance(n.func,ast.Name)}
 forbidden={'open','exec','eval','compile','__import__','getattr','globals','locals','input','breakpoint'}
 check('pure supplied-data reviewer no native dispatch '+path,imports<={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)) and not(calls&forbidden))
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
