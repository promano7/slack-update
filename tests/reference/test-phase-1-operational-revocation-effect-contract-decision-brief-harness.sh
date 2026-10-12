#!/bin/bash
set -euo pipefail
export LC_ALL=C
repo=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 - "$repo" <<'PYTEST'
from pathlib import Path
import ast,copy,json,runpy,subprocess,sys
root=Path(sys.argv[1]);step='phase-1-operational-revocation-effect-contract-decision-brief';prefix=root/'tests/fixtures/reference/acceptance/phase-1'
def load(s):return json.loads((prefix/(step+'-'+s+'.json')).read_bytes())
entry,baseline,brief,sources,policy=[load(s) for s in ['entry390','baseline','brief','sources','policy']]
tool=root/'tools/reference'/(step+'.py');m=runpy.run_path(str(tool));passes=0
def check(label,v):
 global passes
 if not v:raise SystemExit('FAIL: '+label)
 passes+=1;print('PASS: '+label)
def rejected(fn,*a):
 try:fn(*a)
 except (ValueError,KeyError,TypeError):return True
 return False
def safe(rel):
 p=root/rel
 if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise SystemExit('FAIL: unsafe artifact '+rel)
 return p.read_bytes()
inputs={k:safe(v['path']) for k,v in sources['inputs'].items()};roots=sources['inert_roots']+sources['reviewer_roots']+[sources['readme']]
source_blobs={r['path']:safe(r['path']) for r in roots};blobs={p:safe(p) for p in baseline};addition=blobs['CHANGELOG.md'][:-policy['accepted_changelog_size_bytes']]
def shape(b):return m['validate_brief_shape'](b,inputs,sources,policy)
check('authored391 policy independently frozen',m['validate_policy'](policy))
check('whole entry baseline brief source fixtures exact',m['validate_fixtures'](entry,baseline,brief,sources,policy))
check('complete unchanged390 return exact210 labels creates commit push clean heads',m['validate_entry'](entry,policy))
check('all47 whole inputs four inert twelve reviewer and README roots',m['validate_inputs'](inputs,source_blobs,sources,policy))
check('all2050 accepted390 bytes exact except additive CHANGELOG',m['validate_baseline'](blobs,baseline,addition,policy))
check('four inactive options ten WHOLE clauses and eight conditional witnesses',shape(brief))
if(root/'.git').exists():
 raw=subprocess.run(['git','-C',str(root),'ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True).stdout;actual={x.decode() for x in raw.split(b'\0') if x}
else:actual={str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight new Git-visible artifacts no unrelated scope',actual==set(baseline)|set(policy['new_paths']))
mutations=[
 ('boolean schema',lambda b:b.update(schema=True)),
 ('shortened whole original live review',lambda b:b['whole_original_live_review']['original323_fence_contract'].pop('rule')),
 ('current full clauses waived',lambda b:b.update(whole_original_requirements_remain_normative=False)),
 ('writer proposal reference removed',lambda b:b['whole_accepted390_writer_brief_reference'].pop('sha256')),
 ('selected admission-cut amendment',lambda b:b.update(selected_option='declared-operation-admission-cuts')),
 ('approved migration',lambda b:b.update(approved_contract_migration={})),
 ('invented live enforcer',lambda b:b.update(actual_live_gate={})),
 ('invented worker channel',lambda b:b.update(actual_worker_channel={})),
 ('invented effect graph',lambda b:b.update(actual_effect_graph=[])),
 ('invented operation cut',lambda b:b.update(actual_operation_cuts=[])),
 ('native grant',lambda b:b.update(native_authority=True)),
 ('upstream source native proof',lambda b:b.update(source_documentation_is_native_proof=True)),
 ('universal impossibility',lambda b:b.update(universal_impossibility_proven=True)),
 ('new native proof',lambda b:b.update(new_native_proofs=1)),
 ('new native case',lambda b:b.update(new_native_cases=1)),
 ('premature safe pause',lambda b:b.update(current_step_strong_safe_pause=True)),
 ('close shifted earlier',lambda b:b.update(conditional_close_step=391)),
 ('successor skips392',lambda b:b.update(next_preparable_step_after_complete391_acceptance=393)),
 ('retention omitted',lambda b:b['options'].pop(0)),
 ('deferral omitted',lambda b:b['options'].pop()),
 ('channel permission merged into cuts',lambda b:b['options'][1].update(id=b['options'][2]['id'])),
 ('admission guarantee loss hidden',lambda b:b['options'][1].update(guarantees_lost_or_changed=[])),
 ('channel guarantee loss hidden',lambda b:b['options'][2].update(guarantees_lost_or_changed=[])),
 ('admission impact hidden',lambda b:b['options'][1]['migration_impact'].update(exact_changed_clause_candidates=[])),
 ('channel impact hidden',lambda b:b['options'][2]['migration_impact'].update(exact_changed_clause_candidates=[])),
 ('retention hides amendment',lambda b:b['options'][0]['proposed_clause_text'].update(rule='cut-only')),
 ('conditional witness omitted',lambda b:b['conditional_policy_witnesses'].pop()),
]
for label,mutate in mutations:
 bad=copy.deepcopy(brief);mutate(bad);check('semantic rejection: '+label,rejected(shape,bad))
for key,v in brief['boundaries'].items():
 bad=copy.deepcopy(brief);bad['boundaries'][key]=not v if type(v)is bool else(v+1 if type(v)is int else{})
 check('semantic rejection of closed boundary '+key,rejected(shape,bad))
for i,opt in enumerate(brief['options']):
 for field,v in [('explicit_user_decision_required',False),('implementation_selected',True),('runtime_authority',True),('independent_evidence_required',[]),('dependencies_and_incompatibilities',[])]:
  bad=copy.deepcopy(brief);bad['options'][i][field]=v;check('semantic option'+str(i)+' rejection '+field,rejected(shape,bad))
 for j,row in enumerate(opt['exact_current_clause_bindings']):
  bad=copy.deepcopy(brief);bad['options'][i]['exact_current_clause_bindings'][j]['whole_current_value']={'summary':True}
  check('semantic option'+str(i)+' WHOLE clause'+str(j)+' truncation rejected',rejected(shape,bad))
 for j,row in enumerate(opt['platform_rows']):
  for key in ['support','installed_versions','actual_composition','native_evidence','entry_authorized']:
   bad=copy.deepcopy(brief);bad['options'][i]['platform_rows'][j][key]=True
   check('semantic option'+str(i)+' platform'+str(j)+' promotion '+key,rejected(shape,bad))
 for key,v in [('approved_migration',{}),('affected_proofs_cases_relations_complete',True),('all_other_original_clauses_remain_binding',False)]:
  bad=copy.deepcopy(brief);bad['options'][i]['migration_impact'][key]=v;check('semantic option'+str(i)+' migration promotion '+key,rejected(shape,bad))
for i,row in enumerate(brief['conditional_policy_witnesses']):
 for key,v in [('actual_observation',{}),('native_execution',True),('exhaustive_coverage',True),('ordered_events',[]),('option_id','foreign')]:
  bad=copy.deepcopy(brief);bad['conditional_policy_witnesses'][i][key]=v
  check('semantic witness'+str(i)+' promotion or truncation '+key,rejected(shape,bad))
for key in inputs:
 bad=dict(inputs);bad[key]+=b'\n';check('reject whole original input drift '+key,rejected(m['validate_inputs'],bad,source_blobs,sources,policy))
for row in roots:
 bad=dict(source_blobs);bad[row['path']]+=b'\n';check('reject source root drift '+row['path'],rejected(m['validate_inputs'],inputs,bad,sources,policy))
bad=copy.deepcopy(entry);bad['receipt']['text']=bad['receipt']['text'][:-1];check('reject truncated actual390 return',rejected(m['validate_entry'],bad,policy))
bad=copy.deepcopy(entry);bad['confirmation']['commit_full']='invented';check('reject invented full commit identity',rejected(m['validate_entry'],bad,policy))
bad=copy.deepcopy(sources);bad['actual_installed_platform_support']=True;check('reject source register as native support',rejected(m['validate_inputs'],inputs,source_blobs,bad,policy))
for p in ['README.md','CHANGELOG.md']:
 bad=dict(blobs);bad[p]+=b'\n';check('reject immutable predecessor rewrite '+p,rejected(m['validate_baseline'],bad,baseline,addition,policy))
bad=copy.deepcopy(policy);bad['expected_option_ids'].pop();check('reject reanchored policy',rejected(m['validate_policy'],bad))
report=m['review'](entry,baseline,brief,sources,inputs,source_blobs,policy)
check('report keeps selection migration authority and current pause inactive',report['selected_option'] is None and report['approved_contract_migration'] is None and report['native_authority'] is False and report['strong_safe_pause'] is False)
check('report requires actual391 acceptance before392 and stops after398',report['after_actual391_acceptance_next_preparable_step']==392 and report['next_authorized_stage_after398'] is None)
report['brief']['options'].clear();check('detached report cannot alter original options',len(brief['options'])==4)
for path in [r['path'] for r in sources['reviewer_roots']]+['tools/reference/'+step+'.py']:
 tree=ast.parse(safe(path));imports={a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names};calls={n.func.id for n in ast.walk(tree) if isinstance(n,ast.Call) and isinstance(n.func,ast.Name)}
 forbidden={'open','exec','eval','compile','__import__','getattr','globals','locals','input','breakpoint'}
 check('pure supplied-data reviewer no native dispatch '+path,imports<={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)) and not(calls&forbidden))
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
