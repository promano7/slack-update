#!/bin/bash
set -euo pipefail
export LC_ALL=C
repo=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 - "$repo" <<'PYTEST'
from pathlib import Path
import ast,copy,json,runpy,subprocess,sys
root=Path(sys.argv[1]);step='phase-1-operational-contract-decision-packet-freeze-and-safe-pause-review';prefix=root/'tests/fixtures/reference/acceptance/phase-1'
def load(s):return json.loads((prefix/(step+'-'+s+'.json')).read_bytes())
entry,baseline,freeze,sources,policy=[load(s) for s in ['entry397','baseline','freeze','sources','policy']]
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
source_blobs={r['path']:safe(r['path']) for r in roots};blobs={p:safe(p) for p in baseline};addition=blobs['CHANGELOG.md'][:-policy['accepted_changelog_size_bytes']]
def shape(p):return m['validate_freeze_shape'](p,entry,inputs,sources,policy)
check('authored398 policy independently frozen',m['validate_policy'](policy))
check('whole entry baseline freeze source fixtures exact',m['validate_fixtures'](entry,baseline,freeze,sources,policy))
check('complete unchanged397 return exact430 labels creates commit push clean heads',m['validate_entry'](entry,policy))
check('all67 inputs four inert nineteen reviewer and current README roots',m['validate_inputs'](inputs,source_blobs,sources,policy))
check('all2106 accepted397 historical bytes exact except additive CHANGELOG;README unchanged',m['validate_baseline'](blobs,baseline,addition,policy))
check('WHOLE packet chain and nine whole conditions;actual398confirmation pending',shape(freeze))
if(root/'.git').exists():
 raw=subprocess.run(['git','-C',str(root),'ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True).stdout;actual={x.decode() for x in raw.split(b'\0') if x}
else:actual={str(p.relative_to(root)) for p in root.rglob('*') if p.is_file() and '.git' not in p.relative_to(root).parts}
check('exact eight additions plus CHANGELOG no unrelated scope',actual==set(baseline)|set(policy['new_paths']))
mutations=[('boolean schema',lambda f:f.update(schema=True)),('shortened WHOLE packet',lambda f:f['whole_accepted397_packet']['option_register'].pop()),('shortened roadmap',lambda f:f['whole_389_roadmap'].pop()),('shortened whole pause policy',lambda f:f['whole_389_pause_policy'].clear()),('missing checkpoint',lambda f:f['accepted_checkpoint_chain389_397'].pop()),('missing whole condition',lambda f:f['conditions'].pop()),('frozen inputs truncated',lambda f:f['frozen_inputs'].pop('oracle_brief396')),('frozen roots truncated',lambda f:f['frozen_source_roots'].pop()),('current398receipt invented',lambda f:f.update(current398_actual_final_user_receipt={})),('premature confirmed pause',lambda f:f.update(actual_strong_safe_pause_confirmed=True)),('private eligibility as confirmation',lambda f:f.update(private_eligibility_is_actual_confirmation=True)),('original obligations waived',lambda f:f.update(whole_original_requirements_remain_normative=False)),('semantic migration complete',lambda f:f.update(semantic_migration_complete=True)),('runtime grant',lambda f:f.update(runtime_authority=True)),('machine action required',lambda f:f.update(machine_action_required=True)),('controller action required',lambda f:f.update(controller_action_required=True)),('new native case',lambda f:f.update(native_cases_run=1)),('new native proof',lambda f:f.update(native_proofs_added=1)),('host claimed absent',lambda f:f.update(actual_host_state='absent')),('host globally closed',lambda f:f.update(actual_global_host_closure=True)),('lastconfirmed398 invented',lambda f:f.update(last_confirmed_strong_safe_pause_step=398)),('automatic399',lambda f:f.update(no_automatic399=False)),('future stage selected',lambda f:f.update(next_authorized_stage_after398=399))]
for field in ['current398_user_commit_prefix','current398_user_commit_full','current398_user_worktree_clean','current398_user_head_matches_origin','selected_options','approved_joint_specification','approved_contract_migration','actual_selected_implementation','actual_joint_native_graph','actual_native_evidence','actual_live_bindings']:
 mutations.append(('invented '+field,lambda f,field=field:f.update({field:{}})))
for label,mutate in mutations:
 bad=copy.deepcopy(freeze);mutate(bad);check('semantic rejection: '+label,rejected(shape,bad))
for key,v in freeze['boundaries'].items():
 bad=copy.deepcopy(freeze);bad['boundaries'][key]=not v if type(v)is bool else(v+1 if type(v)is int else{})
 check('semantic rejection of closed boundary '+key,rejected(shape,bad))
for i,row in enumerate(freeze['conditions']):
 for key,v in [('full_original_prepared_condition388',{'id':row['id']}),('repository_review_basis','summary only'),('current398_actual_user_confirmation',True),('actual_native_evidence',{}),('actual_global_host_closure',True),('repository_status','confirmed-safe-pause')]:
  bad=copy.deepcopy(freeze);bad['conditions'][i][key]=v
  check('semantic WHOLE condition'+str(i)+' truncation or promotion '+key,rejected(shape,bad))
for i,row in enumerate(freeze['accepted_checkpoint_chain389_397']):
 for part,key,v in [('receipt','text',row['receipt']['text'][:-1]),('confirmation','commit_full','invented'),('confirmation','runtime_authority',True),('confirmation','user_head_matches_origin',False)]:
  bad=copy.deepcopy(freeze);bad['accepted_checkpoint_chain389_397'][i][part][key]=v
  check('semantic complete checkpoint'+str(i+389)+' drift or promotion '+key,rejected(shape,bad))
for key,v in freeze['after_final_acceptance'].items():
 bad=copy.deepcopy(freeze);bad['after_final_acceptance'][key]=not v if type(v)is bool else{}
 check('semantic rejection of final stop boundary '+key,rejected(shape,bad))
for key in inputs:
 bad=dict(inputs);bad[key]+=b'\n';check('reject whole original input drift '+key,rejected(m['validate_inputs'],bad,source_blobs,sources,policy))
for row in roots:
 bad=dict(source_blobs);bad[row['path']]+=b'\n';check('reject source root drift '+row['path'],rejected(m['validate_inputs'],inputs,bad,sources,policy))
bad=copy.deepcopy(entry);bad['receipt']['text']=bad['receipt']['text'][:-1];check('reject truncated actual397 return',rejected(m['validate_entry'],bad,policy))
bad=copy.deepcopy(entry);bad['confirmation']['commit_full']='invented';check('reject invented full commit identity',rejected(m['validate_entry'],bad,policy))
for p in ['README.md','CHANGELOG.md']:
 bad=dict(blobs);bad[p]+=b'\n';check('reject immutable accepted397 bytes '+p,rejected(m['validate_baseline'],bad,baseline,addition,policy))
bad=copy.deepcopy(policy);bad['expected_condition_ids'].pop();check('reject reanchored policy',rejected(m['validate_policy'],bad))
report=m['review'](entry,baseline,freeze,sources,inputs,source_blobs,policy)
check('report private eligibility is not actual pause confirmation',report['repository_review_eligible_for_conditional_pause'] is True and report['actual_strong_safe_pause_confirmed'] is False and report['last_confirmed_repository_pause']==388)
check('report requires external whole conditions then STOP no399',report['stop_after_complete_actual_receipt_and_all_whole_conditions_confirmed'] is True and report['next_authorized_stage_after398'] is None)
check('report no selection migration runtime hostabsence or globalclosure',report['selected_options'] is None and report['approved_contract_migration'] is None and report['runtime_authority'] is False and report['actual_host_state']=='unobserved-not-claimed-absent' and report['actual_live_bindings'] is None and report['actual_global_host_closure'] is False)
report['freeze']['conditions'].clear();check('detached report preserves all nine whole conditions',len(freeze['conditions'])==9)
for path in [r['path'] for r in sources['reviewer_roots']]+['tools/reference/'+step+'.py']:
 tree=ast.parse(safe(path));imports={a.name.split('.')[0] for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names};calls={n.func.id for n in ast.walk(tree) if isinstance(n,ast.Call) and isinstance(n.func,ast.Name)}
 forbidden={'open','exec','eval','compile','__import__','getattr','globals','locals','input','breakpoint'}
 check('pure supplied-data reviewer no native dispatch '+path,imports<={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)) and not(calls&forbidden))
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
