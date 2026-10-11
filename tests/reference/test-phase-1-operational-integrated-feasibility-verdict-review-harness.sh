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
root=Path(sys.argv[1]);step='phase-1-operational-integrated-feasibility-verdict-review';prefix=root/'tests/fixtures/reference/acceptance/phase-1'
def load(suffix):return json.loads((prefix/(step+'-'+suffix+'.json')).read_bytes())
p=load('policy');c=load('confirmed385');r=load('step385-user-acceptance');d=load('dossier');s=load('sources')
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
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute():raise SystemExit('FAIL: unsafe385artifact '+rel)
    blobs[rel]=path.read_bytes()
addition=blobs['CHANGELOG.md'][:-p['accepted_changelog_size_bytes']]
inputs={key:(root/path).read_bytes() for key,path in p['whole_input_paths'].items()}
f=json.loads(inputs['freeze378']);sources={row['path']:(root/row['path']).read_bytes() for row in f['review_sources']};readme=blobs['README.md']
check('authored386policy independently frozen',m['validate_policy'](p))
check('all2009accepted385bytes exact except additiveCHANGELOG',m['validate_baseline'](blobs,addition,p))
check('complete385receipt exact339labels commit push clean matchingheads',m['validate_acceptance'](c,r,p))
check('whole378freeze21inputs379plan380through385decisions and four inert roots bound',m['validate_inputs'](inputs,sources,readme,p))
check('whole integrated bounded feasibility dossier validates',m['validate_dossier'](d,s,inputs,p))
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
for label,change in [('truncatedreceipt',lambda t:t[:-1]),('same-sizecommitedit',lambda t:t.replace('d457428','6c65758',1)),
                     ('injecteddirtyfinalstatus',lambda t:t.replace('d457428 (HEAD',' M README.md\nd457428 (HEAD',1)),
                     ('reorderedpredecessorPASS',lambda t:t.replace(p['expected_ordered_PASS_labels385'][0],p['expected_ordered_PASS_labels385'][1],1))]:
    bad=copy.deepcopy(r);bad['text']=change(r['text'])
    check('reject '+label,rejected(m['validate_acceptance'],c,bad,p))
for key,value in d['boundaries'].items():
    bad=copy.deepcopy(d);bad['boundaries'][key]=not value if type(value) is bool else (value+1 if type(value) is int else {})
    check('reject changed native or project boundary '+key,rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(d['candidates']):
    for key,value in [('disposition','proven-compatible'),('actual_component','selected'),('native_blocker_resolved',True),('grants_authority',True),('universal_impossibility_proven',True)]:
        bad=copy.deepcopy(d);bad['candidates'][index][key]=value
        check('reject candidate promotion '+row['id']+' '+key,rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(d['platform_unknowns']):
    bad=copy.deepcopy(d);bad['platform_unknowns'][index]['support_claimed']=True
    check('reject unobserved platform support '+row['candidate_id']+' '+row['platform'],rejected(m['validate_dossier'],bad,s,inputs,p))
for label,change in [('boolean schema',lambda x:x.update(schema=True)),('contract relaxation',lambda x:x.update(contract_relaxation_permitted=True)),
                     ('primary scope waiver',lambda x:x.update(primary_assignment_limits_normative_scope=True)),
                     ('shortened fullstage12',lambda x:x.update(whole_stage12_obligation='summary')),
                     ('missing independent criterion',lambda x:x['independent_resolution_criteria'].pop()),
                     ('native boundary invented',lambda x:x['enforcement_boundary_questions'].update(actual_joint_complete_graph_and_trust='proven')),
                     ('automatic389',lambda x:x.update(no_automatic389=False))]:
    bad=copy.deepcopy(d);change(bad);check('reject '+label,rejected(m['validate_dossier'],bad,s,inputs,p))
for key,value in d['integration_limits'].items():
    bad=copy.deepcopy(d);bad['integration_limits'][key]=True if type(value) is bool else 'invented-resolution'
    check('reject integrated verdict promotion or permission inference '+key,rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(d['candidates']):
    bad=copy.deepcopy(d);bad['candidates'][index]['whole_original_candidate']['disposition']='compatible-unproven'
    check('reject rewritten full source candidate '+row['id'],rejected(m['validate_dossier'],bad,s,inputs,p))
for name,flag,identity in [('cross_conflict_review','native_blocker_resolved','original_conflict'),('full_blocker_review','native_gap_closed','whole_original_blocker')]:
    for index,row in enumerate(d[name]):
        bad=copy.deepcopy(d);bad[name][index][flag]=True
        check('reject original integrated blocker resolved '+name+' '+str(index),rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(d['composition_review']):
    bad=copy.deepcopy(d);bad['composition_review'][index]['native_property_proven']=True
    check('reject conditional composition promoted to native proof '+row['id'],rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(d['source_review_bindings']):
    bad=copy.deepcopy(d);bad['source_review_bindings'][index]['whole_independent_resolution_criteria'].pop()
    check('reject shortened whole source resolution criteria '+str(row['source_step']),rejected(m['validate_dossier'],bad,s,inputs,p))
for label,change in [('taxonomy compatible grants test',lambda x:x['classification_taxonomy'].update(**{'compatible-unproven':'authorized-native-test'})),
 ('candidate verdict count rewritten',lambda x:x['bounded_candidate_verdict_counts'].update(unresolved=0)),
 ('source candidate omitted',lambda x:x['candidates'].pop()),
 ('whole conflict omitted',lambda x:x['cross_conflict_review'].pop()),
 ('whole blocker omitted',lambda x:x['full_blocker_review'].pop()),
 ('future test prerequisites shortened',lambda x:x['whole377_future_test_entry_prerequisites'].pop()),
 ('future operational prerequisites shortened',lambda x:x['whole377_future_operational_readiness_prerequisites'].pop()),
 ('whole stage12 shortened',lambda x:x['original316_whole_stage12'].update(operation='subset')),
 ('composition declared universally impossible',lambda x:x.update(universal_infeasibility_proven=True))]:
    bad=copy.deepcopy(d);change(bad);check('reject '+label,rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(s):
    bad=copy.deepcopy(s);bad[index]['retrieval']='independent-platform-conformance'
    check('reject upstream retrieval promoted to native evidence '+row['id'],rejected(m['validate_dossier'],d,bad,inputs,p))
bad=dict(blobs);bad['README.md']+=b'\n';check('reject untouched acceptedREADMEdrift',rejected(m['validate_baseline'],bad,addition,p))
bad=dict(blobs);bad['CHANGELOG.md']+=b'\n';check('reject historicalCHANGELOGsuffixdrift',rejected(m['validate_baseline'],bad,addition,p))
bad=copy.deepcopy(p);bad['baseline_sha256']['README.md']='0'*64;check('reject reanchored policy substitution',rejected(m['validate_policy'],bad))
report=m['review'](d,s,c,r,inputs,sources,readme,p)
check('report retains all source candidates original conflicts blockers and whole stage12',report['dossier']['candidates']==d['candidates'] and report['dossier']['cross_conflict_review']==d['cross_conflict_review'] and report['dossier']['full_blocker_review']==d['full_blocker_review'] and report['dossier']['original316_whole_stage12']==d['original316_whole_stage12'])
check('report retains whole normative input references and closed native entry',report['whole_input_bindings']==p['whole_input_sha256'] and report['native_entry_blocked'] and not report['strong_safe_pause'])
report['dossier']['candidates'][0]['native_blocker_resolved']=True
check('detached report mutation cannot promote caller or later review',not m['review'](d,s,c,r,inputs,sources,readme,p)['dossier']['candidates'][0]['native_blocker_resolved'] and not d['candidates'][0]['native_blocker_resolved'])
tree=ast.parse(tool.read_text());imports={a.name for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names}
check('pure reviewer imports onlyhashlibjsonre',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen'}
check('reviewer has no filesystem clock network spawn service runner or native dispatch',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
