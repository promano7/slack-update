#!/bin/bash
set -euo pipefail
export LC_ALL=C
repo=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 - "$repo" <<'PYTEST'
from pathlib import Path
import ast
import copy
import json
import runpy
import subprocess
import sys
root=Path(sys.argv[1]);step='phase-1-operational-supervisor-clock-drain-decision-review';prefix=root/'tests/fixtures/reference/acceptance/phase-1'
def load(suffix):return json.loads((prefix/(step+'-'+suffix+'.json')).read_bytes())
p=load('policy');c=load('confirmed381');r=load('step381-user-acceptance');d=load('dossier');s=load('sources')
tool=root/'tools/reference'/(step+'.py');m=runpy.run_path(str(tool));passes=0
def check(label,value):
    global passes
    if not value:raise SystemExit('FAIL: '+label)
    passes+=1;print('PASS: '+label)
def rejected(fn,*args):
    try:fn(*args)
    except (ValueError,KeyError,TypeError):return True
    return False
blobs={}
for rel in p['baseline_sha256']:
    path=root/rel
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute():raise SystemExit('FAIL: unsafe381artifact '+rel)
    blobs[rel]=path.read_bytes()
addition=blobs['CHANGELOG.md'][:-p['accepted_changelog_size_bytes']]
inputs={key:(root/path).read_bytes() for key,path in p['whole_input_paths'].items()}
f=json.loads(inputs['freeze378']);sources={row['path']:(root/row['path']).read_bytes() for row in f['review_sources']};readme=blobs['README.md']
check('authored382policy independently frozen',m['validate_policy'](p))
check('all1977accepted381bytes exact except additiveCHANGELOG',m['validate_baseline'](blobs,addition,p))
check('complete381receipt exact184labels commit push clean matchingheads',m['validate_acceptance'](c,r,p))
check('whole378freeze21inputs379plan380and381decisions and four inert roots bound',m['validate_inputs'](inputs,sources,readme,p))
check('whole supervisor clock drain decision dossier validates',m['validate_dossier'](d,s,inputs,p))
if (root/'.git').exists():
    raw=subprocess.run(['git','-C',str(root),'ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True).stdout
    actual={x.decode() for x in raw.split(b'\0') if x}
else:actual={str(path.relative_to(root)) for path in root.rglob('*') if path.is_file() and '.git' not in path.relative_to(root).parts}
expected=set(p['baseline_sha256'])|set(p['new_paths'])
if actual!=expected:print('Unexpected Git-visible paths: '+repr(sorted(actual-expected)));print('Missing project paths: '+repr(sorted(expected-actual)))
check('exact eight new Git-visible artifacts ignored local outputs retained',actual==expected)
for key in inputs:
    bad=dict(inputs);bad[key]+=b'\n'
    check('reject whole normative input drift '+key,rejected(m['validate_inputs'],bad,sources,readme,p))
for path in sources:
    bad=dict(sources);bad[path]+=b'\n'
    check('reject inert source drift '+path,rejected(m['validate_inputs'],inputs,bad,readme,p))
for key,value in [('commit_full','invented'),('strong_safe_pause',True),('native_cases_run',1),('native_proofs_added',1),
                  ('runtime_authority',True),('actual_host_state','absent'),('actual_live_bindings',{}),('actual_global_host_closure',True),
                  ('user_worktree_clean',False),('user_head_matches_origin',False)]:
    bad=copy.deepcopy(c);bad[key]=value
    check('reject predecessor promotion '+key,rejected(m['validate_acceptance'],bad,r,p))
for label,change in [('truncatedreceipt',lambda t:t[:-1]),('same-sizecommitedit',lambda t:t.replace('0f099fe','0f099ff',1)),
                     ('injecteddirtyfinalstatus',lambda t:t.replace('0f099fe (HEAD',' M README.md\n0f099fe (HEAD',1)),
                     ('reorderedpredecessorPASS',lambda t:t.replace(p['expected_ordered_PASS_labels381'][0],p['expected_ordered_PASS_labels381'][1],1))]:
    bad=copy.deepcopy(r);bad['text']=change(r['text'])
    check('reject '+label,rejected(m['validate_acceptance'],c,bad,p))
for key,value in d['boundaries'].items():
    bad=copy.deepcopy(d);bad['boundaries'][key]=not value if type(value) is bool else (value+1 if type(value) is int else {})
    check('reject changed native or project boundary '+key,rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(d['candidates']):
    for key,value in [('disposition','proven-compatible'),('actual_component','selected'),('native_blocker_resolved',True),('grants_authority',True),('universal_impossibility_proven',True)]:
        bad=copy.deepcopy(d);bad['candidates'][index][key]=value
        check('reject candidate promotion '+row['id']+' '+key,rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(d['adversarial_schedules']):
    bad=copy.deepcopy(d);bad['adversarial_schedules'][index]['ordered_events'].reverse()
    check('reject changed conditional event order '+row['id'],rejected(m['validate_dossier'],bad,s,inputs,p))
    bad=copy.deepcopy(d);bad['adversarial_schedules'][index]['native_execution']=True
    check('reject paper schedule promoted to native execution '+row['id'],rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(d['platform_unknowns']):
    bad=copy.deepcopy(d);bad['platform_unknowns'][index]['support_claimed']=True
    check('reject unobserved platform support '+row['candidate_id']+' '+row['platform'],rejected(m['validate_dossier'],bad,s,inputs,p))
for label,change in [('boolean schema',lambda x:x.update(schema=True)),('contract relaxation',lambda x:x.update(contract_relaxation_permitted=True)),
                     ('primary scope waiver',lambda x:x.update(primary_assignment_limits_normative_scope=True)),
                     ('shortened fullstage12',lambda x:x.update(whole_stage12_obligation='summary')),
                     ('missing whole324guard',lambda x:x['original324_guard_contract'].pop('owner_loss')),
                     ('guard reacquisition permitted',lambda x:x['original324_guard_contract'].update(failure='reacquire')),
                     ('missing independent criterion',lambda x:x['independent_resolution_criteria'].pop()),
                     ('native boundary invented',lambda x:x['enforcement_boundary_questions'].update(whole_child_FD_stream_storage_effect_drain_receipt='proven')),
                     ('automatic389',lambda x:x.update(no_automatic389=False))]:
    bad=copy.deepcopy(d);change(bad);check('reject '+label,rejected(m['validate_dossier'],bad,s,inputs,p))
for key,value in [('actual_owner_loss_detection_and_enforcement','selected'),('actual_pre_effect_membership_protocol','proven'),('actual_surviving_exclusion_or_independent_prevention','assumed'),('actual_child_FD_stream_effect_completion_protocol','closed'),('actual_same_boot_clock_and_discontinuity_mapping','trusted'),('actual_original_compatible_trust_verdict','compatible'),('parent_exit_is_full_drain',True),('task_state_is_full_effect_receipt',True),('unknown_is_valid',True),('automatic_replay_or_rights_renewal_permitted',True)]:
    bad=copy.deepcopy(d);bad['lifetime_review'][key]=value
    check('reject unproven lifetime or clock promotion '+key,rejected(m['validate_dossier'],bad,s,inputs,p))
for label,change in [('self-authenticated local clock',lambda x:x['original323_clock_contract'].update(actual_clock='local-trusted')),('invented absolute deadline',lambda x:x['original323_clock_contract'].update(actual_forward_deadline=100)),('blanket recovery exemption',lambda x:x['original323_recovery_contract'].update(expiry_relation='always-valid-after-forward-expiry')),('atomic cancellation of admitted effects',lambda x:x['original323_forward_contract'].update(in_flight='all-cancelled-on-kill')),('parent status promoted to closure',lambda x:x['original323_closure_contract'].update(machine='parent-exit-is-closed')),('private model promoted to native proof',lambda x:x['original326_model_contract'].update(boundary='complete-native-proof')),('shortened whole372blockers',lambda x:x['original372_supervision_and_time_blockers'].pop())]:
    bad=copy.deepcopy(d);change(bad)
    check('reject '+label,rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(s):
    bad=copy.deepcopy(s);bad[index]['retrieval']='independent-platform-conformance'
    check('reject upstream retrieval promoted to native evidence '+row['id'],rejected(m['validate_dossier'],d,bad,inputs,p))
bad=dict(blobs);bad['README.md']+=b'\n';check('reject untouched acceptedREADMEdrift',rejected(m['validate_baseline'],bad,addition,p))
bad=dict(blobs);bad['CHANGELOG.md']+=b'\n';check('reject historicalCHANGELOGsuffixdrift',rejected(m['validate_baseline'],bad,addition,p))
bad=copy.deepcopy(p);bad['baseline_sha256']['README.md']='0'*64;check('reject reanchored policy substitution',rejected(m['validate_policy'],bad))
report=m['review'](d,s,c,r,inputs,sources,readme,p)
check('report retains whole clock fence forward recovery closure guard model and conflicts',all(report['dossier'][key]==d[key] for key in ['original323_clock_contract','original323_fence_contract','original323_forward_contract','original323_recovery_contract','original323_closure_contract','original324_guard_contract','original326_model_contract','original326_independent_conformance_contract','original377_supervisor_conflict','original377_finite_time_conflict','original372_supervision_and_time_blockers']))
check('report retains whole normative input references and closed native entry',report['whole_input_bindings']==p['whole_input_sha256'] and report['native_entry_blocked'] and not report['strong_safe_pause'])
report['dossier']['candidates'][0]['native_blocker_resolved']=True
check('detached report mutation cannot promote caller or later review',not m['review'](d,s,c,r,inputs,sources,readme,p)['dossier']['candidates'][0]['native_blocker_resolved'] and not d['candidates'][0]['native_blocker_resolved'])
tree=ast.parse(tool.read_text());imports={a.name for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names}
check('pure reviewer imports onlyhashlibjsonre',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen'}
check('reviewer has no filesystem clock network spawn service runner or native dispatch',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
