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
root=Path(sys.argv[1]);step='phase-1-operational-writer-alias-lifetime-decision-review';prefix=root/'tests/fixtures/reference/acceptance/phase-1'
def load(suffix):return json.loads((prefix/(step+'-'+suffix+'.json')).read_bytes())
p=load('policy');c=load('confirmed380');r=load('step380-user-acceptance');d=load('dossier');s=load('sources')
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
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute():raise SystemExit('FAIL: unsafe380artifact '+rel)
    blobs[rel]=path.read_bytes()
addition=blobs['CHANGELOG.md'][:-p['accepted_changelog_size_bytes']]
inputs={key:(root/path).read_bytes() for key,path in p['whole_input_paths'].items()}
f=json.loads(inputs['freeze378']);sources={row['path']:(root/row['path']).read_bytes() for row in f['review_sources']};readme=blobs['README.md'];writer_raw=(root/d['original_writer_resource_map_binding']['path']).read_bytes()
check('authored381policy independently frozen',m['validate_policy'](p))
check('all1969accepted380bytes exact except additiveCHANGELOG',m['validate_baseline'](blobs,addition,p))
check('complete380receipt exact157labels commit push clean matchingheads',m['validate_acceptance'](c,r,p))
check('whole378freeze21inputs379plan380decisions and four inert roots bound',m['validate_inputs'](inputs,sources,readme,writer_raw,p))
check('whole writer alias lifetime decision dossier validates',m['validate_dossier'](d,s,inputs,p))
if (root/'.git').exists():
    raw=subprocess.run(['git','-C',str(root),'ls-files','--cached','--others','--exclude-standard','-z'],capture_output=True,check=True).stdout
    actual={x.decode() for x in raw.split(b'\0') if x}
else:actual={str(path.relative_to(root)) for path in root.rglob('*') if path.is_file() and '.git' not in path.relative_to(root).parts}
expected=set(p['baseline_sha256'])|set(p['new_paths'])
if actual!=expected:print('Unexpected Git-visible paths: '+repr(sorted(actual-expected)));print('Missing project paths: '+repr(sorted(expected-actual)))
check('exact eight new Git-visible artifacts ignored local outputs retained',actual==expected)
for key in inputs:
    bad=dict(inputs);bad[key]+=b'\n'
    check('reject whole normative input drift '+key,rejected(m['validate_inputs'],bad,sources,readme,writer_raw,p))
for path in sources:
    bad=dict(sources);bad[path]+=b'\n'
    check('reject inert source drift '+path,rejected(m['validate_inputs'],inputs,bad,readme,writer_raw,p))
for key,value in [('commit_full','invented'),('strong_safe_pause',True),('native_cases_run',1),('native_proofs_added',1),
                  ('runtime_authority',True),('actual_host_state','absent'),('actual_live_bindings',{}),('actual_global_host_closure',True),
                  ('user_worktree_clean',False),('user_head_matches_origin',False)]:
    bad=copy.deepcopy(c);bad[key]=value
    check('reject predecessor promotion '+key,rejected(m['validate_acceptance'],bad,r,p))
for label,change in [('truncatedreceipt',lambda t:t[:-1]),('same-sizecommitedit',lambda t:t.replace('7820d1a','7820d1b',1)),
                     ('injecteddirtyfinalstatus',lambda t:t.replace('7820d1a (HEAD',' M README.md\n7820d1a (HEAD',1)),
                     ('reorderedpredecessorPASS',lambda t:t.replace(p['expected_ordered_PASS_labels380'][0],p['expected_ordered_PASS_labels380'][1],1))]:
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
    check('reject unobserved platform support '+row['domain']+' '+row['platform'],rejected(m['validate_dossier'],bad,s,inputs,p))
for label,change in [('boolean schema',lambda x:x.update(schema=True)),('contract relaxation',lambda x:x.update(contract_relaxation_permitted=True)),
                     ('primary scope waiver',lambda x:x.update(primary_assignment_limits_normative_scope=True)),
                     ('shortened fullstage12',lambda x:x.update(whole_stage12_obligation='summary')),
                     ('missing whole324guard',lambda x:x['original324_guard_contract'].pop('owner_loss')),
                     ('guard reacquisition permitted',lambda x:x['original324_guard_contract'].update(failure='reacquire')),
                     ('missing independent criterion',lambda x:x['independent_resolution_criteria'].pop()),
                     ('native boundary invented',lambda x:x['enforcement_boundary_questions'].update(all_writer_admission_and_prevention_boundary='proven')),
                     ('automatic389',lambda x:x.update(no_automatic389=False))]:
    bad=copy.deepcopy(d);change(bad);check('reject '+label,rejected(m['validate_dossier'],bad,s,inputs,p))
for key,value in [('actual_trusted_administrator_assumptions','assumed-safe'),('actual_kernel_enforcer_trust','selected'),('actual_device_storage_virtualization_trust','excluded'),('original_contract_compatibility_verdict','proven'),('privileged_writer_exclusion_by_assumption_permitted',True)]:
    bad=copy.deepcopy(d);bad['trust_boundary_review'][key]=value
    check('reject unreviewed privileged trust promotion '+key,rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(d['original_writer_resource_rows']):
    bad=copy.deepcopy(d);bad['original_writer_resource_rows'][index]['writers']='known wrappers only'
    check('reject shortened original writer domain '+row['domain'],rejected(m['validate_dossier'],bad,s,inputs,p))
check('reject original writer map byte drift',rejected(m['validate_inputs'],inputs,sources,readme,writer_raw+b'\n',p))
for index,row in enumerate(s):
    bad=copy.deepcopy(s);bad[index]['retrieval']='independent-platform-conformance'
    check('reject upstream retrieval promoted to native evidence '+row['id'],rejected(m['validate_dossier'],d,bad,inputs,p))
bad=dict(blobs);bad['README.md']+=b'\n';check('reject untouched acceptedREADMEdrift',rejected(m['validate_baseline'],bad,addition,p))
bad=dict(blobs);bad['CHANGELOG.md']+=b'\n';check('reject historicalCHANGELOGsuffixdrift',rejected(m['validate_baseline'],bad,addition,p))
bad=copy.deepcopy(p);bad['baseline_sha256']['README.md']='0'*64;check('reject reanchored policy substitution',rejected(m['validate_policy'],bad))
report=m['review'](d,s,c,r,inputs,sources,readme,writer_raw,p)
check('report retains whole original324 guard baseline interstage domains and377 conflict',all(report['dossier'][key]==d[key] for key in ['original324_guard_contract','original324_baseline_contract','original324_interstage_contract','original324_resource_domains','original377_writer_conflict','original372_writer_blocker']))
check('report retains whole normative input references and closed native entry',report['whole_input_bindings']==p['whole_input_sha256'] and report['native_entry_blocked'] and not report['strong_safe_pause'])
report['dossier']['candidates'][0]['native_blocker_resolved']=True
check('detached report mutation cannot promote caller or later review',not m['review'](d,s,c,r,inputs,sources,readme,writer_raw,p)['dossier']['candidates'][0]['native_blocker_resolved'] and not d['candidates'][0]['native_blocker_resolved'])
tree=ast.parse(tool.read_text());imports={a.name for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names}
check('pure reviewer imports onlyhashlibjsonre',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen'}
check('reviewer has no filesystem clock network spawn service runner or native dispatch',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
