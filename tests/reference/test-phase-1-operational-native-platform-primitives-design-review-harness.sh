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

root=Path(sys.argv[1]);name='phase-1-operational-native-platform-primitives-design-review'
f=root/'tests/fixtures/reference/acceptance/phase-1';tool=root/'tools/reference'/(name+'.py')
m=runpy.run_path(str(tool));passes=0
sha=lambda raw:hashlib.sha256(raw).hexdigest()
def load(tail):return json.loads((f/(name+'-'+tail+'.json')).read_bytes())
def check(label,value):
    global passes
    if not value:raise AssertionError(label)
    passes+=1;print('PASS: '+label,flush=True)
def rejected(fn,*args):
    try:fn(*args)
    except (ValueError,KeyError,TypeError):return True
    return False
p=load('policy');design=load('design');c=load('confirmed371');r=load('step371-user-acceptance')
check('authored372 policy independently frozen',m['validate_policy'](p))
check('all1903 accepted371 baseline bindings retained',len(p['baseline_sha256'])==p['accepted_source_count']==1903)
history={}
for rel,digest in p['baseline_sha256'].items():
    path=root/rel
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute() or not path.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=path.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-p['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted371 drift: '+rel)
    history[rel]=raw
check('all accepted371 bytes preserved except additive CHANGELOG',len(history)==1903)
check('complete371 uploaded return and reported acceptance validate',m['validate_acceptance'](c,r,p))
check('all151 exact predecessor labels and reported eight-file scope retained',len(p['accepted371_contract']['expected_ordered371_labels'])==151 and len(p['accepted371_contract']['expected_changed_paths'])==8)
check('exact received message SHA size and no normalization',sha(r['text'].encode())==r['sha256']==c['receipt_sha256'] and len(r['text'].encode())==r['size_bytes']==c['receipt_size_bytes']==11007 and r['normalization']=='none')
check('371 is not a new pause or independent native inspection',c['commit_prefix']=='e6d341f' and c['commit_full'] is None and not c['strong_safe_pause'] and c['last_confirmed_strong_safe_pause_step']==368 and 'not-independent-terminal-byte-capture' in r['capture_basis'])
inputs={k:json.loads(history[path]) for k,path in p['input_paths'].items()}
for k,path in p['input_paths'].items():check('whole input byte and canonical binding '+k,sha(history[path])==p['input_file_sha256'][k] and m['canonical'](inputs[k])==p['input_canonical_sha256'][k])
sources={row['path']:history[row['path']] for row in p['source_roots']};readme=history['README.md'];freeze=inputs['freeze']
check('all full frozen design inputs validate',m['validate_frozen_inputs'](inputs,p))
check('four unchanged review roots and accepted README validate',m['validate_sources'](sources,readme,p))
check('complete platform primitive comparison validates',m['validate_design'](design,inputs,p))
check('original372 assignments exact and not reduced scope',design['primary_gap_ids']==inputs['plan369']['roadmap'][3]['primary_gap_ids'] and len(design['primary_gap_review'])==3 and not design['primary_assignment_limits_normative_scope'] and design['all_full_original_requirements_normative'])
for n in ('321','323','324'):
    check('whole original contract'+n+' and modeled flags retained',design['full_original_contract'+n]==freeze['full_original_contracts320_327'][n])
a=design['full_original_contract321']['document'];t=design['full_original_contract323']['document'];g=design['full_original_contract324']['document']
check('original bootstrap authenticated fields symbolic limits and FD policy retained',len(a['authentication']['covered_fields'])==14 and a['bootstrap']['maximum_raw_bytes']==65536 and a['bootstrap']['deadline_seconds']==10 and a['bootstrap']['symbolic_read_fd']==3 and a['fd_policy']==freeze['full_original_contracts320_327']['321']['document']['fd_policy'])
check('full original clock fence recovery and closure contracts retained',all(t[k]==freeze['full_original_contracts320_327']['323']['document'][k] for k in ('clock_contract','fence_contract','recovery_contract','closure_contract')))
check('full original guard baseline pkglist and resource domains retained',all(g[k]==freeze['full_original_contracts320_327']['324']['document'][k] for k in ('guard_contract','baseline_contract','pkglist_contract','resource_domains')))
source_ids={row['id'] for row in design['primary_source_review']}
check('twelve primary source reviews distinguish upstream from native support',len(source_ids)==12 and all(not row['actual_platform_support_proven'] and not row['whole_original_page_bytes_captured'] and row['verified_date_UTC']=='2026-10-11' and row['retrieval_basis'] for row in design['primary_source_review']))
for row in design['primary_source_review']:
    check('reviewed primary source '+row['id'],row['url'].startswith(('https://man7.org/','https://www.man7.org/','https://docs.kernel.org/')) and row['upstream_observation'] and row['retrieval_ref'])
check('ten candidate families have explicit blockers and alternatives',len(design['candidate_families'])==10 and all(row['decision'].startswith(('blocked-','architecture-blocked-')) and row['alternative_review_without_contract_relaxation'] and row['required_future_native_evidence'] for row in design['candidate_families']))
qualified={row['qualified_id'] for row in freeze['full_qualified_proof_rows347']}
for row in design['candidate_families']:
    check('candidate normative and source mapping '+row['id'],set(row['primary_source_ids'])<=source_ids and set(row['qualified_obligation_ids'])<=qualified and not row['actual_component_selected'] and not row['native_property_proven'])
platforms=['Slackware-15.0','Slackware-current'];ids=[row['id'] for row in design['candidate_families']]
check('two distinct platform bindings remain wholly unknown',len(design['platform_readiness'])==2 and [row['platform'] for row in design['platform_readiness']]==platforms and all(v is None for row in design['platform_readiness'] for k,v in row.items() if k.startswith('actual_')))
check('twenty ordered platform-family assessments no evidence borrowing',[(row['platform'],row['family_id']) for row in design['separate_platform_assessments']]==[(plat,id) for plat in platforms for id in ids])
for row in design['separate_platform_assessments']:
    check('native inputs absent '+row['platform']+' '+row['family_id'],all(v is None for k,v in row.items() if k.startswith('actual_')) and not row['native_feasibility_proven'] and not row['native_case_run'] and not row['current_authority'])
check('fourteen exact original writer-domain assessments',[(row['platform'],row['domain']) for row in design['separate_platform_writer_domains']]==[(plat,dom) for plat in platforms for dom in g['resource_domains']])
for row in design['separate_platform_writer_domains']:
    check('unknown writers block admission '+row['platform']+' '+row['domain'],all(v is None for k,v in row.items() if k.startswith('actual_')) and not row['continuously_excluded'] and row['unknown_or_nonparticipant_blocks_admission'] and row['full_original_guard_contract324_sha256']==m['canonical'](g['guard_contract']))
for row in design['primary_gap_review']:
    original=next(x for x in freeze['full_original_native_gap_rows348'] if x['inherited_gap']['id']==row['id'])
    check('whole original primary gap remains unresolved '+row['id'],row['full_original_gap348']==original and not row['native_gap_closed'] and set(row['candidate_family_ids'])<=set(ids))
check('architecture blockers explicit for revocation and all writers',all(next(x for x in design['candidate_families'] if x['id']==id)['decision'].startswith('architecture-blocked-') for id in ('external-live-revocation','writer-object-alias-exclusion')))
check('native feasibility blocked without contract relaxation',design['feasibility_verdict']=='native-readiness-blocked-pending-complete-per-platform-refinement' and not design['contract_relaxation_permitted'] and not design['upstream_documentation_is_native_evidence'] and not design['candidate_composition_is_actual_selected_implementation'])
for key,count in [('full_original_contracts320_327',8),('full_normative_rows347',16),('full_original_native_gap_rows348',16),('full_qualified_proof_rows347',46),('full_native_case_rows347',52),('full_independent_raw_groups335',12),('ordered_required_proof_case_relations',1072)]:
    check('whole frozen normative scope '+key,len(freeze[key])==count)
check('accepted370 roles and371 failure cuts unchanged',len(inputs['design370']['roles'])==9 and len(inputs['design370']['interfaces'])==8 and len(inputs['design371']['original_failure_cut_review'])==10 and inputs['design371']['original_failure_cut_review'][2]['actual_observed_consumption'] is None)
check('README377 conditional378 pause no automatic379 and no native cases',sha(readme)==p['readme_at_entry_sha256'] and design['readme_reconciliation_step']==377 and design['conditional_pause_step']==378 and design['no_automatic379'] and design['native_cases_run']==design['native_proofs_added']==0 and design['all_46_original_proofs_and_52_cases_still_pending'])
for key,value in [('commit_full','invented'),('strong_safe_pause',True),('runtime_authority',True),('actual_host_state','absent'),('actual_global_host_closure',True),('actual_live_bindings',{}),('user_worktree_clean',False),('user_head_matches_origin',False),('native_cases_run',1),('native_proofs_added',1)]:
    bad=copy.deepcopy(c);bad[key]=value;check('reject invented371 '+key,rejected(m['validate_acceptance'],bad,r,p))
for label,edit in [('truncated upload',lambda x:x[:-1]),('same-length receipt edit',lambda x:x.replace('e6d341f','e6d341e',1)),('dirty status injection',lambda x:x.replace('e6d341f (HEAD',' M README.md\ne6d341f (HEAD',1)),('reordered labels',lambda x:x.replace('PASS: whole original320 contract retained without rewritten modeled flags\nPASS: whole original321 contract and original handoff retained','PASS: whole original321 contract and original handoff retained\nPASS: whole original320 contract retained without rewritten modeled flags'))]:
    bad=copy.deepcopy(r);bad['text']=edit(r['text']);check('reject '+label,rejected(m['validate_acceptance'],c,bad,p))
bad=copy.deepcopy(r);bad['capture_basis']='independent-terminal';check('reject invented capture origin',rejected(m['validate_acceptance'],c,bad,p))
for key in inputs:
    bad=copy.deepcopy(inputs);bad[key]['invented']=True;check('reject changed whole frozen input '+key,rejected(m['validate_frozen_inputs'],bad,p))
bad=dict(sources);bad[next(iter(sources))]+=b'\n';check('reject accepted historical source drift',rejected(m['validate_sources'],bad,readme,p))
bad=dict(sources);bad['native-service.sh']=b'claimed';check('reject fifth executable root',rejected(m['validate_sources'],bad,readme,p))
check('reject premature README reconciliation',rejected(m['validate_sources'],sources,readme+b'\n',p))
mutations=[
 ('whole321 FD policy truncated',lambda x:x['full_original_contract321']['document'].pop('fd_policy')),
 ('whole323 gate relaxed',lambda x:x['full_original_contract323']['document']['fence_contract'].update(rule='worker polls lease')),
 ('whole324 guard reacquisition',lambda x:x['full_original_contract324']['document']['guard_contract'].update(failure='reacquire')),
 ('original primary gap removed',lambda x:x['primary_gap_review'].pop()),
 ('original gap promoted closed',lambda x:x['primary_gap_review'][0].update(native_gap_closed=True)),
 ('symbolic bootstrap limit made pipe capacity',lambda x:x['full_original_contract321']['document']['bootstrap'].update(maximum_raw_bytes=4096)),
 ('candidate marked selected',lambda x:x['candidate_families'][0].update(actual_component_selected=True)),
 ('candidate primitive marked proven',lambda x:x['candidate_families'][0].update(native_property_proven=True)),
 ('FD numeric range made complete inventory',lambda x:x['candidate_families'][1].update(required_future_native_evidence='FD3 closed so all capabilities safe')),
 ('namespace name made whole isolation',lambda x:x['candidate_families'][2].update(decision='feasible')),
 ('parent exit made all descendants drained',lambda x:x['candidate_families'][3].update(limitation_and_design_inference='parent exit proves closure')),
 ('timer made issuer time authority',lambda x:x['candidate_families'][4].update(decision='trusted-native-time')),
 ('offline receipt made live revocation',lambda x:x['candidate_families'][5].update(candidate_composition='finite signed lease alone')),
 ('advisory lock made privileged writer exclusion',lambda x:x['candidate_families'][6].update(decision='all-writers-excluded')),
 ('hash-before-reopen made consumption proof',lambda x:x['candidate_families'][7].update(required_future_native_evidence='hash pathname once')),
 ('no-replace made durable claim CAS',lambda x:x['candidate_families'][8].update(candidate_composition='rename alone durably consumes grant')),
 ('backend name made complete graph',lambda x:x['candidate_families'][9].update(decision='native-graph-complete')),
 ('primary source invented support',lambda x:x['primary_source_review'][0].update(actual_platform_support_proven=True)),
 ('source capture origin fabricated',lambda x:x['primary_source_review'][0].update(whole_original_page_bytes_captured=True)),
 ('non-primary citation substituted',lambda x:x['primary_source_review'][0].update(url='https://unreviewed.invalid/')),
 ('all native readiness feasible',lambda x:x.update(feasibility_verdict='ready')),
 ('contract relaxation granted',lambda x:x.update(contract_relaxation_permitted=True)),
 ('documentation promoted to native evidence',lambda x:x.update(upstream_documentation_is_native_evidence=True)),
 ('normative scope limited to primary gaps',lambda x:x.update(primary_assignment_limits_normative_scope=True)),
 ('runtime authority granted',lambda x:x.update(runtime_authority=True)),
 ('extra native case run',lambda x:x.update(native_cases_run=1)),
 ('native proof added',lambda x:x.update(native_proofs_added=1)),
 ('automatic379 inserted',lambda x:x.update(no_automatic379=False)),
 ('premature pause',lambda x:x.update(conditional_pause_step=372)),
 ('bool schema',lambda x:x.update(schema=True))]
for label,mutate in mutations:
    bad=copy.deepcopy(design);mutate(bad);check('reject '+label,rejected(m['validate_design'],bad,inputs,p))
for i,row in enumerate(design['separate_platform_assessments']):
    bad=copy.deepcopy(design);bad['separate_platform_assessments'][i]['actual_api_and_configuration_binding']='invented support';check('reject invented native binding '+row['platform']+' '+row['family_id'],rejected(m['validate_design'],bad,inputs,p))
for i,row in enumerate(design['separate_platform_writer_domains']):
    bad=copy.deepcopy(design);bad['separate_platform_writer_domains'][i]['unknown_or_nonparticipant_blocks_admission']=False;check('reject waived writer barrier '+row['platform']+' '+row['domain'],rejected(m['validate_design'],bad,inputs,p))
bad=copy.deepcopy(design);bad['separate_platform_assessments'][10]=copy.deepcopy(bad['separate_platform_assessments'][0]);check('reject platform evidence borrowing',rejected(m['validate_design'],bad,inputs,p))
for key,value in [('C_port_open',True),('production_entry_closed',False),('phase2_open',True),('machine_action_required',True),('controller_action_required',True),('historical_binding_or_authority_reuse_allowed',True),('current_step_strong_safe_pause',True),('native_components_selected',True),('actual_platform_feasibility_proven',True),('actual_native_fence_proven',True),('actual_writer_exclusion_proven',True),('actual_global_host_closure',True),('actual_live_bindings',{})]:
    bad=copy.deepcopy(design);bad['boundaries'][key]=value;check('reject closed boundary changed '+key,rejected(m['validate_design'],bad,inputs,p))
bad=copy.deepcopy(p);bad['baseline_sha256']['README.md']='0'*64;check('reject policy substitution',rejected(m['validate_policy'],bad))
out=m['review'](design,c,r,inputs,sources,readme,p)
check('report retains original gaps normative rows and both accepted designs',out['full_original_native_gap_rows348']==freeze['full_original_native_gap_rows348'] and out['full_normative_rows347']==freeze['full_normative_rows347'] and out['full_accepted_design370']==inputs['design370'] and out['full_accepted_design371']==inputs['design371'])
out['design']['separate_platform_assessments'].pop();out['full_normative_rows347'].clear();out['boundaries']['runtime_authority']=True
again=m['review'](design,c,r,inputs,sources,readme,p)
check('mutating report cannot change caller or subsequent results',len(again['design']['separate_platform_assessments'])==len(design['separate_platform_assessments'])==20 and len(again['full_normative_rows347'])==16 and not again['boundaries']['runtime_authority'])
tree=ast.parse(tool.read_text());imports={a.name for node in ast.walk(tree) if isinstance(node,ast.Import) for a in node.names}
check('pure reviewer imports only hashlib json re',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen','sign','verify','fork','spawn','pipe','fsync','kill','clock_gettime'}
check('reviewer has no native lookup syscall filesystem service crypto or dispatch',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
