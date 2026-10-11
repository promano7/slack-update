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
root=Path(sys.argv[1]);step='phase-1-operational-source-backend-independent-oracle-decision-review';prefix=root/'tests/fixtures/reference/acceptance/phase-1'
def load(suffix):return json.loads((prefix/(step+'-'+suffix+'.json')).read_bytes())
p=load('policy');c=load('confirmed384');r=load('step384-user-acceptance');d=load('dossier');s=load('sources')
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
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute():raise SystemExit('FAIL: unsafe384artifact '+rel)
    blobs[rel]=path.read_bytes()
addition=blobs['CHANGELOG.md'][:-p['accepted_changelog_size_bytes']]
inputs={key:(root/path).read_bytes() for key,path in p['whole_input_paths'].items()}
f=json.loads(inputs['freeze378']);sources={row['path']:(root/row['path']).read_bytes() for row in f['review_sources']};readme=blobs['README.md']
check('authored385policy independently frozen',m['validate_policy'](p))
check('all2001accepted384bytes exact except additiveCHANGELOG',m['validate_baseline'](blobs,addition,p))
check('complete384receipt exact283labels commit push clean matchingheads',m['validate_acceptance'](c,r,p))
check('whole378freeze21inputs379plan380through384decisions and four inert roots bound',m['validate_inputs'](inputs,sources,readme,p))
check('whole source backend independent oracle dossier validates',m['validate_dossier'](d,s,inputs,p))
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
for label,change in [('truncatedreceipt',lambda t:t[:-1]),('same-sizecommitedit',lambda t:t.replace('061a0a0','6c65758',1)),
                     ('injecteddirtyfinalstatus',lambda t:t.replace('061a0a0 (HEAD',' M README.md\n061a0a0 (HEAD',1)),
                     ('reorderedpredecessorPASS',lambda t:t.replace(p['expected_ordered_PASS_labels384'][0],p['expected_ordered_PASS_labels384'][1],1))]:
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
                     ('native boundary invented',lambda x:x['enforcement_boundary_questions'].update(actual_complete_dynamic_checked_to_used_graph='proven')),
                     ('automatic389',lambda x:x.update(no_automatic389=False))]:
    bad=copy.deepcopy(d);change(bad);check('reject '+label,rejected(m['validate_dossier'],bad,s,inputs,p))
for key,value in d['graph_oracle_review'].items():
    bad=copy.deepcopy(d);bad['graph_oracle_review'][key]=True if type(value) is bool else 'invented-known-outcome'
    check('reject graph or oracle promotion scope waiver or invented proof '+key,rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(d['graph_surface_review']):
    for key,value in [('native_graph_complete',True),('actual_selected_entry_or_source','selected')]:
        bad=copy.deepcopy(d);bad['graph_surface_review'][index][key]=value
        check('reject graph surface promoted to actual native binding '+row['id']+' '+key,rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(d['original375_case_evidence_review']):
    bad=copy.deepcopy(d);bad['original375_case_evidence_review'][index]['actual_native_result']='PASS'
    check('reject fabricated original native case result '+row['case_id']+' '+row['platform'],rejected(m['validate_dossier'],bad,s,inputs,p))
for key,field in [('role_trust_review','native_independence_proven'),('raw_group_evidence_review','native_group_complete'),('comparison_requirement_review','is_executable_native_comparator'),('fault_control_review','native_satisfied')]:
    for index,row in enumerate(d['original375_'+key]):
        bad=copy.deepcopy(d);bad['original375_'+key][index][field]=True
        check('reject original oracle review promoted to native proof '+key+' '+row['id'],rejected(m['validate_dossier'],bad,s,inputs,p))
for number in ['375','376']:
    for key in p['original'+number+'_review_keys']:
        bad=copy.deepcopy(d);value=bad['original'+number+'_'+key]
        if isinstance(value,list):value.pop()
        else:value.pop(next(iter(value)))
        check('reject shortened whole original'+number+' '+key,rejected(m['validate_dossier'],bad,s,inputs,p))
for label,change in [('original stage12 renamed',lambda x:x['original316_whole_stage12'].update(stage='short-publication')),
 ('original raw stage12 streams omitted',lambda x:x['original316_whole_stage12']['evidence'].pop('stderr')),
 ('whole entry conflict resolved',lambda x:x['original377_whole_entry_backend_conflict'].update(native_blocker_resolved=True)),
 ('whole native oracle conflict resolved',lambda x:x['original377_independent_two_platform_oracle_conflict'].update(native_blocker_resolved=True)),
 ('static census promoted to actual dynamic graph',lambda x:x['original325_reference_census'].update(actual_transitive_graph_complete=True)),
 ('static census row shortened',lambda x:x['original325_reference_census']['functions'].pop()),
 ('original designed domain omitted',lambda x:x['original325_catalogue_nodes'].pop()),
 ('original graph edge omitted',lambda x:x['original325_catalogue_edges'].pop()),
 ('whole entry replaced by three calls',lambda x:x['original325_graph_contract'].update(entry='three-calls')),
 ('upgrade20 promoted to success',lambda x:x['original325_selector_contract'].update(statuses='raw20-success')),
 ('original caller sticky stop waived',lambda x:x['original325_selector_contract'].update(latch='continue')),
 ('raw pin rebound',lambda x:x['original325_selector_contract'].update(refresh='rebind-current-pkglist')),
 ('original nested argv changed',lambda x:x['original325_nested_argv_contract'][2]['argv'].pop()),
 ('worker service FD allowed',lambda x:x['original321_fd_policy'].update(service='allowed')),
 ('native expectation vector invented',lambda x:x['original351_whole_expectation_contract'].update(actual_expected_vector_artifacts=[])),
 ('original verifier author role forbidden',lambda x:x['original375_role_trust_review'][2].update(non_inference='four-separate-people-required')),
 ('null observed as no-effect',lambda x:x['original375_comparison_requirement_review'][0].update(required_future_comparison='null-is-empty')),
 ('pending hides known mismatch',lambda x:x['original375_comparison_requirement_review'][4].update(required_future_comparison='pending-erases-mismatch'))]:
    bad=copy.deepcopy(d);change(bad);check('reject '+label,rejected(m['validate_dossier'],bad,s,inputs,p))
for index,row in enumerate(s):
    bad=copy.deepcopy(s);bad[index]['retrieval']='independent-platform-conformance'
    check('reject upstream retrieval promoted to native evidence '+row['id'],rejected(m['validate_dossier'],d,bad,inputs,p))
bad=dict(blobs);bad['README.md']+=b'\n';check('reject untouched acceptedREADMEdrift',rejected(m['validate_baseline'],bad,addition,p))
bad=dict(blobs);bad['CHANGELOG.md']+=b'\n';check('reject historicalCHANGELOGsuffixdrift',rejected(m['validate_baseline'],bad,addition,p))
bad=copy.deepcopy(p);bad['baseline_sha256']['README.md']='0'*64;check('reject reanchored policy substitution',rejected(m['validate_policy'],bad))
report=m['review'](d,s,c,r,inputs,sources,readme,p)
check('report retains whole graph census cases oracle and original stage12',report['dossier']['original316_whole_stage12']==d['original316_whole_stage12'] and all(report['dossier']['original'+n+'_'+key]==d['original'+n+'_'+key] for n,keys in p['original_contract_keys'].items() for key in keys) and all(report['dossier']['original'+n+'_'+key]==d['original'+n+'_'+key] for n in ['375','376'] for key in p['original'+n+'_review_keys']) and report['dossier']['original377_independent_two_platform_oracle_conflict']==d['original377_independent_two_platform_oracle_conflict'])
check('report retains whole normative input references and closed native entry',report['whole_input_bindings']==p['whole_input_sha256'] and report['native_entry_blocked'] and not report['strong_safe_pause'])
report['dossier']['candidates'][0]['native_blocker_resolved']=True
check('detached report mutation cannot promote caller or later review',not m['review'](d,s,c,r,inputs,sources,readme,p)['dossier']['candidates'][0]['native_blocker_resolved'] and not d['candidates'][0]['native_blocker_resolved'])
tree=ast.parse(tool.read_text());imports={a.name for n in ast.walk(tree) if isinstance(n,ast.Import) for a in n.names}
check('pure reviewer imports onlyhashlibjsonre',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen'}
check('reviewer has no filesystem clock network spawn service runner or native dispatch',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)'%passes)
PYTEST
