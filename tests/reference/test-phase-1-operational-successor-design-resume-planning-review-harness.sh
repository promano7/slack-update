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

root=Path(sys.argv[1]); name='phase-1-operational-successor-design-resume-planning-review'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
tool=root/'tools/reference'/(name+'.py'); m=runpy.run_path(str(tool)); passes=0
sha=lambda raw:hashlib.sha256(raw).hexdigest()
def load(tail):return json.loads((fixture/(name+'-'+tail+'.json')).read_bytes())
def check(label,value):
    global passes
    if not value:raise AssertionError(label)
    passes+=1;print('PASS: '+label,flush=True)
def rejected(fn,*args):
    try:fn(*args)
    except (ValueError,KeyError,TypeError):return True
    return False
p=load('policy');plan=load('plan');c=load('confirmed368');r=load('step368-user-acceptance');conditions=load('confirmed-pause-conditions368')
check('authored policy independently frozen',m['validate_policy'](p))
check('all1881 accepted repository files bound',len(p['baseline_sha256'])==p['accepted_source_count']==1881)
history={}
for rel,digest in p['baseline_sha256'].items():
    path=root/rel
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute() or not path.resolve().is_relative_to(root):raise ValueError('unsafe baseline path: '+rel)
    raw=path.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-p['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted repository drift: '+rel)
    history[rel]=raw
check('all accepted bytes preserved except additive CHANGELOG',len(history)==1881)
for tail,key in [('confirmed368','expected_confirmation_sha256'),('step368-user-acceptance','expected_receipt_sha256'),('confirmed-pause-conditions368','expected_conditions_sha256')]:
    check('exact external evidence fixture '+tail,sha((fixture/(name+'-'+tail+'.json')).read_bytes())==p[key])
check('complete368 return and all external condition confirmations',m['validate_acceptance'](c,r,conditions,p))
check('accepted368 has scoped pause and unknown full commit',c['strong_safe_pause'] and c['scoped_strong_safe_pause'] and c['commit_full'] is None and not c['actual_global_host_closure'])
check('all167 labels retained in full ordered acceptance contract',len(p['accepted368_contract']['expected_ordered_PASS_labels'])==167)
check('reported scope exact nine files and eight additions',len(p['accepted368_contract']['expected_changed_sha256'])==9 and len(p['accepted368_contract']['expected_created_paths'])==8)
inputs={k:json.loads(history[v]) for k,v in p['input_paths'].items()}
for key,path in p['input_paths'].items():
    check('whole frozen input byte and canonical binding '+key,sha(history[path])==p['input_file_sha256'][key] and m['canonical'](inputs[key])==p['input_canonical_sha256'][key])
sources={row['path']:history[row['path']] for row in p['source_roots']};readme=history['README.md']
check('full frozen requirements and four source roles validate',m['validate_inputs'](inputs,sources,readme,p))
check('368 candidate confirmation remains immutable and externally superseded',inputs['freeze']['actual_strong_safe_pause_confirmed'] is False and inputs['pause']['actual_strong_safe_pause_confirmed'] is False and conditions['strong_safe_pause'] is True)
check('finite369-378 design plan validates',m['validate_plan'](plan,inputs,p))
check('all16 gaps have one primary review assignment without limiting normative scope',len(p['expected_gap_ids'])==16 and not plan['gap_assignment_is_exhaustive_native_graph'] and plan['all_full_original_requirements_normative_at_every_stage'])
check('all eight original365 future reviews retained',len(plan['future_deliverables365'])==8 and plan['future_deliverables365']==inputs['prerequisites']['future_review_deliverables'])
freeze=inputs['freeze']
for key,count in [('full_original_contracts320_327',8),('full_normative_rows347',16),('full_original_native_gap_rows348',16),('full_qualified_proof_rows347',46),('full_native_case_rows347',52),('full_independent_raw_groups335',12),('ordered_required_proof_case_relations',1072)]:
    check('complete inherited normative rows '+key,len(freeze[key])==count)
check('all nine original scoped condition identities retained',plan['pause_policy']['original_condition_ids']==c['original_pause_conditions']==[row['id'] for row in inputs['pause']['conditions']])
check('README exact pending377 reconciliation',sha(readme)==p['readme_at_entry_sha256'] and plan['readme_reconciliation_step']==377)
check('conditional378 pause and no automatic379',plan['conditional_pause_step']==378 and plan['no_automatic379'] and plan['pause_policy']['next_authorized_stage_after378'] is None)
check('C and shell-reference gates retained',plan['implementation_policy']['C_port_gate_retained'] and plan['implementation_policy']['shell_reference_gate_retained'] and not plan['boundaries']['C_port_open'])
for field,value in [('strong_safe_pause',False),('commit_full','invented'),('runtime_authority',True),('native_cases_run',1),('native_proofs_added',1),('actual_live_bindings',{}),('actual_global_host_closure',True),('actual_host_state','absent'),('user_worktree_clean',False),('user_head_matches_origin',False)]:
    bad=copy.deepcopy(c);bad[field]=value;check('reject false accepted368 '+field,rejected(m['validate_acceptance'],bad,r,conditions,p))
for label,mutate in [('truncated receipt',lambda x:x[:-1]),('same-length receipt edit',lambda x:x.replace('030acb8','030acb9',1)),('injected dirty status',lambda x:x.replace('030acb8 (HEAD',' M README.md\n030acb8 (HEAD',1)),('reordered labels',lambda x:x.replace(p['accepted368_contract']['expected_ordered_PASS_labels'][0],p['accepted368_contract']['expected_ordered_PASS_labels'][1],1))]:
    bad=copy.deepcopy(r);bad['text']=mutate(r['text']);check('reject '+label,rejected(m['validate_acceptance'],c,bad,conditions,p))
bad=copy.deepcopy(r);bad['capture_basis']='independent-terminal-capture';check('reject invented original capture',rejected(m['validate_acceptance'],c,bad,conditions,p))
bad=copy.deepcopy(conditions);bad['confirmed_conditions'].pop();check('reject omitted original pause condition',rejected(m['validate_acceptance'],c,r,bad,p))
for key in inputs:
    bad=copy.deepcopy(inputs);bad[key]['invented_field']=True
    check('reject modified full frozen input '+key,rejected(m['validate_inputs'],bad,sources,readme,p))
bad=copy.deepcopy(inputs);bad.pop('native_gap');check('reject missing original gap register',rejected(m['validate_inputs'],bad,sources,readme,p))
bad=dict(sources);bad[next(iter(bad))]+=b'\n';check('reject original source drift',rejected(m['validate_inputs'],inputs,bad,readme,p))
bad=dict(sources);bad['extra-source.sh']=b'echo claimed';check('reject undeclared fifth root',rejected(m['validate_inputs'],inputs,bad,readme,p))
check('reject premature README modification',rejected(m['validate_inputs'],inputs,sources,readme+b'\n',p))
for key,value in [('runtime_authority',True),('machine_action_required',True),('controller_action_required',True),('native_components_selected',True),('C_port_open',True),('actual_live_bindings',{}),('actual_host_state','absent'),('actual_global_host_closure',True),('native_proofs_added',1),('native_cases_run',1),('operational_conformance',True),('production_entry_closed',False),('phase2_open',True),('historical_binding_or_authority_reuse_allowed',True),('current_step_strong_safe_pause',True)]:
    bad=copy.deepcopy(plan);bad['boundaries'][key]=value
    check('reject changed plan boundary '+key,rejected(m['validate_plan'],bad,inputs,p))
for label,mutate in [('skipped predecessor',lambda x:x['roadmap'][1].update(entry_requires_confirmed_step=368)),('runtime roadmap stage',lambda x:x['roadmap'][1].update(runtime_authorized=True)),('extra379 stage',lambda x:x['roadmap'].append(copy.deepcopy(x['roadmap'][-1]))),('missing primary gap',lambda x:x['roadmap'][1]['primary_gap_ids'].pop()),('missing future review',lambda x:x['future_deliverables365'].pop()),('early README reconciliation',lambda x:x.update(readme_reconciliation_step=370)),('waived full normative scope',lambda x:x.update(all_full_original_requirements_normative_at_every_stage=False)),('platform name promoted to evidence',lambda x:x['implementation_policy'].update(platform_property_may_be_claimed_from_generic_name=True)),('historical worker made executable',lambda x:x['implementation_policy'].update(historical_workers_generators_or_payloads_executable=True)),('authorization prerequisite made grant',lambda x:x['implementation_policy'].update(native_authorization_review='execute-now')),('premature pause',lambda x:x['pause_policy'].update(final_receipt_required=False)),('bool schema',lambda x:x.update(schema=True))]:
    bad=copy.deepcopy(plan);mutate(bad);check('reject '+label,rejected(m['validate_plan'],bad,inputs,p))
bad=copy.deepcopy(p);bad['baseline_sha256']['README.md']='0'*64;check('reject policy substitution',rejected(m['validate_policy'],bad))
report=m['review'](plan,c,r,conditions,inputs,sources,readme,p)
check('pure report retains all original gap rows',report['full_original_native_gap_rows348']==freeze['full_original_native_gap_rows348'])
report['roadmap'][0]['step']=999;report['full_original_native_gap_rows348'][0]['status']='claimed-proven';report['boundaries']['runtime_authority']=True
again=m['review'](plan,c,r,conditions,inputs,sources,readme,p)
check('mutating report cannot alter subsequent results or caller input',again['roadmap'][0]['step']==369 and again['full_original_native_gap_rows348']==freeze['full_original_native_gap_rows348'] and not again['boundaries']['runtime_authority'] and plan['roadmap'][0]['step']==369)
check('historical361 private control limitations exact through binding',m['canonical'](inputs['controls361'])==p['input_canonical_sha256']['controls361'])
tree=ast.parse(tool.read_text());imports={a.name for node in ast.walk(tree) if isinstance(node,ast.Import) for a in node.names}
check('pure reviewer imports only hashlib json re',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen'}
check('reviewer has no filesystem source execution decode network or spawn calls',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
