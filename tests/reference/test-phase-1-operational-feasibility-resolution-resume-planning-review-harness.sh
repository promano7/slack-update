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

root=Path(sys.argv[1]); step='phase-1-operational-feasibility-resolution-resume-planning-review'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
def load(suffix):
    return json.loads((fixture/(step+'-'+suffix+'.json')).read_bytes())
p=load('policy');plan=load('plan');c=load('confirmed378');r=load('step378-user-acceptance')
conditions=load('pause-conditions378')
tool=root/'tools/reference'/(step+'.py')
m=runpy.run_path(str(tool));passes=0
def check(label,value):
    global passes
    if not value:
        raise SystemExit('FAIL: '+label)
    passes+=1;print('PASS: '+label)
def rejected(fn,*args):
    try:
        fn(*args)
    except (ValueError,KeyError,TypeError):
        return True
    return False
inputs={key:(root/rel).read_bytes() for key,rel in p['whole_input_paths'].items()}
freeze=json.loads(inputs['freeze378'])
sources={row['path']:(root/row['path']).read_bytes() for row in freeze['review_sources']}
readme=(root/'README.md').read_bytes()
blobs={}
for rel in p['baseline_sha256']:
    path=root/rel
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute():
        raise SystemExit('FAIL: unsafe predecessor artifact '+rel)
    blobs[rel]=path.read_bytes()
addition=blobs['CHANGELOG.md'][:-p['accepted_changelog_size_bytes']]
check('authored policy independently frozen',m['validate_policy'](p))
check('all1953 accepted378 files exact except additive CHANGELOG',m['validate_baseline'](blobs,addition,p))
check('complete predecessor receipt and all nine scoped confirmations',m['validate_acceptance'](c,r,conditions,p))
check('whole378freeze and all21inherited inputs bound byte and canonical',m['validate_inputs'](inputs,sources,readme,p))
check('bounded379to388 decision plan validates',m['validate_plan'](plan,freeze,p))
check('whole unchanged412-label predecessor receipt preserved',len(p['expected_ordered_PASS_labels378'])==412 and r['size_bytes']==35184)
if (root/'.git').exists():
    inventory=subprocess.run(['git','-C',str(root),'ls-files','--cached','--others',
                              '--exclude-standard','-z'],capture_output=True,check=True).stdout
    actual_paths={name.decode('utf-8') for name in inventory.split(b'\0') if name}
else:
    # A detached delivery snapshot has no Git metadata or local ignored outputs.
    actual_paths={str(path.relative_to(root)) for path in root.rglob('*')
                  if path.is_file() and '.git' not in path.relative_to(root).parts}
expected_paths=set(p['baseline_sha256'])|set(p['new_paths'])
if actual_paths!=expected_paths:
    print('Unexpected Git-visible paths: '+repr(sorted(actual_paths-expected_paths)))
    print('Missing project paths: '+repr(sorted(expected_paths-actual_paths)))
check('only eight intended new Git-visible artifacts added',actual_paths==expected_paths)
for key in p['whole_input_paths']:
    check('complete whole input byte binding '+key,m['sha'](inputs[key])==p['whole_input_sha256'][key])
    bad=dict(inputs);bad[key]+=b'\n'
    check('reject whole normative input drift '+key,rejected(m['validate_inputs'],bad,sources,readme,p))
for field,value in [('strong_safe_pause',False),('commit_full','invented-full-id'),
                    ('runtime_authority',True),('native_cases_run',1),('native_proofs_added',1),
                    ('actual_host_state','absent'),('actual_global_host_closure',True),
                    ('actual_live_bindings',{}),('user_worktree_clean',False),
                    ('user_head_matches_origin',False)]:
    bad=copy.deepcopy(c);bad[field]=value
    check('reject predecessor promotion '+field,rejected(m['validate_acceptance'],bad,r,conditions,p))
for label,change in [('truncated return',lambda s:s[:-1]),('same-size receipt edit',lambda s:s.replace('c3a141c','c3a141d',1)),
                     ('reordered PASS',lambda s:s.replace(p['expected_ordered_PASS_labels378'][0],p['expected_ordered_PASS_labels378'][1],1)),
                     ('injected dirty status',lambda s:s.replace('c3a141c (HEAD',' M README.md\nc3a141c (HEAD',1))]:
    bad=copy.deepcopy(r);bad['text']=change(r['text'])
    check('reject '+label,rejected(m['validate_acceptance'],c,bad,conditions,p))
bad=copy.deepcopy(r);bad['capture_basis']='independent-original-terminal-capture'
check('reject invented terminal capture',rejected(m['validate_acceptance'],c,bad,conditions,p))
bad=copy.deepcopy(conditions);bad['confirmed_conditions'].pop()
check('reject omitted original pause condition',rejected(m['validate_acceptance'],c,r,bad,p))
bad=copy.deepcopy(conditions);bad['confirmed_conditions'].reverse()
check('reject reordered original pause conditions',rejected(m['validate_acceptance'],c,r,bad,p))
for key,value in plan['boundaries'].items():
    bad=copy.deepcopy(plan)
    bad['boundaries'][key]=not value if type(value) is bool else (value+1 if type(value) is int else {} )
    check('reject changed current boundary '+key,rejected(m['validate_plan'],bad,freeze,p))
for row in plan['roadmap']:
    index=row['step']-379
    bad=copy.deepcopy(plan);bad['roadmap'][index]['entry_requires_confirmed_step']-=1
    check('reject skipped acceptance at'+str(row['step']),rejected(m['validate_plan'],bad,freeze,p))
    bad=copy.deepcopy(plan);bad['roadmap'][index]['runtime_authorized']=True
    check('reject runtime grant at'+str(row['step']),rejected(m['validate_plan'],bad,freeze,p))
for label,change in [
    ('native implementation grant',lambda x:x.update(actual_implementation_authorized=True)),
    ('contract relaxation',lambda x:x.update(contract_relaxation_permitted=True)),
    ('primary scope waiver',lambda x:x.update(primary_assignments_limit_normative_scope=True)),
    ('universal impossibility claim',lambda x:x.update(universal_infeasibility_proven=True)),
    ('extra389 stage',lambda x:x['roadmap'].append(copy.deepcopy(x['roadmap'][-1]))),
    ('missing original conflict',lambda x:x['conflict_assignments'].pop()),
    ('invented native resolution',lambda x:x['conflict_assignments'][0].update(native_blocker_resolved=True)),
    ('missing whole input',lambda x:x['normative_inputs']['whole21_inherited_inputs']['paths'].pop('design372')),
    ('silently excluded privileged writers',lambda x:x['dossier_contract'].update(review_may_silently_exclude_privileged_writers=True)),
    ('circular test permission',lambda x:x['dossier_contract'].update(test_success_required_before_its_own_authorization=True)),
    ('negative test without safe containment',lambda x:x['dossier_contract'].update(negative_tests_require_independent_safe_containment_before_effects=False)),
    ('verdict promoted to native readiness',lambda x:x['dossier_contract'].update(compatible_unproven_is_native_readiness=True)),
    ('counterexample promoted to native experiment',lambda x:x['dossier_contract'].update(counterexample_is_native_execution=True)),
    ('future test automatically granted',lambda x:x['dossier_contract'].update(future_native_test_requires_separate_fresh_review_and_explicit_grant=False)),
    ('shortened stage12',lambda x:x['normative_inputs'].update(whole_original_stage12_required=False)),
    ('early README reconciliation',lambda x:x.update(readme_reconciliation_step=380)),
    ('private PASS made final pause',lambda x:x['pause_policy'].update(final_receipt_required=False)),
    ('automatic389',lambda x:x['pause_policy'].update(no_automatic389=False)),
    ('boolean schema',lambda x:x.update(schema=True)),
    ('floating point schema',lambda x:x.update(schema=1.0)),
]:
    bad=copy.deepcopy(plan);change(bad)
    check('reject '+label,rejected(m['validate_plan'],bad,freeze,p))
bad=dict(inputs);bad.pop('freeze378')
check('reject missing whole378freeze',rejected(m['validate_inputs'],bad,sources,readme,p))
for path in sources:
    bad=dict(sources);bad[path]+=b'\n'
    check('reject inert historical source drift '+path,rejected(m['validate_inputs'],inputs,bad,readme,p))
bad=dict(sources);bad['extra-worker.sh']=b'extra'
check('reject invented fifth source root',rejected(m['validate_inputs'],inputs,bad,readme,p))
check('reject premature README change',rejected(m['validate_inputs'],inputs,sources,readme+b'\n',p))
bad=dict(blobs);bad['README.md']+=b'\n'
check('reject accepted predecessor content drift',rejected(m['validate_baseline'],bad,addition,p))
bad=dict(blobs);bad.pop('LICENSE')
check('reject missing accepted predecessor file',rejected(m['validate_baseline'],bad,addition,p))
bad=dict(blobs);bad['invented-artifact']=b'extra'
check('reject undeclared predecessor file',rejected(m['validate_baseline'],bad,addition,p))
bad=dict(blobs);bad['CHANGELOG.md']=addition+blobs['CHANGELOG.md'][len(addition):]+b'\n'
check('reject modified historical CHANGELOG suffix',rejected(m['validate_baseline'],bad,addition,p))
bad=dict(blobs);changed_addition=addition.replace(b'379',b'999',1)
bad['CHANGELOG.md']=changed_addition+blobs['CHANGELOG.md'][len(addition):]
check('reject substituted CHANGELOG addition',rejected(m['validate_baseline'],bad,changed_addition,p))
bad=copy.deepcopy(p);bad['plan_canonical_sha256']=m['canonical'](plan)
bad['baseline_sha256']['README.md']='0'*64
check('reject reanchored policy substitution',rejected(m['validate_policy'],bad))
report=m['review'](plan,c,r,conditions,inputs,sources,readme,p)
check('report retains whole original eight conflict rows',report['full_original_conflicts']==freeze['full_accepted377_unresolved_conflict_review'])
check('report retains all nine whole original condition objects',report['whole_original_conditions']==conditions['confirmed_conditions'])
check('report grants no current pause or native entry',not report['current_pause_confirmed'] and report['native_entry_blocked'])
report['roadmap'][0]['step']=999;report['boundaries']['runtime_authority']=True
report['full_original_conflicts'][0]['native_blocker_resolved']=True
again=m['review'](plan,c,r,conditions,inputs,sources,readme,p)
check('mutating report does not alter caller or later review',again['roadmap'][0]['step']==379 and not again['boundaries']['runtime_authority'] and again['full_original_conflicts']==freeze['full_accepted377_unresolved_conflict_review'])
tree=ast.parse(tool.read_text())
imports={a.name for node in ast.walk(tree) if isinstance(node,ast.Import) for a in node.names}
check('pure reviewer imports only hashlib json re',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen'}
check('reviewer has no filesystem clock network service native runner or dispatch',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
