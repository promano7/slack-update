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

root=Path(sys.argv[1]);name='phase-1-operational-issuer-admission-launch-design-review'
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
p=load('policy');design=load('design');c=load('confirmed370');r=load('step370-user-acceptance')
check('authored371 policy independently frozen',m['validate_policy'](p))
check('all1896 accepted370 baseline bindings retained',len(p['baseline_sha256'])==p['accepted_source_count']==1896)
history={}
for rel,digest in p['baseline_sha256'].items():
    path=root/rel
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute() or not path.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=path.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-p['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted370 drift: '+rel)
    history[rel]=raw
check('all accepted370 bytes preserved except additive CHANGELOG',len(history)==1896)
check('complete370 uploaded return and reported acceptance validate',m['validate_acceptance'](c,r,p))
check('all133 exact predecessor labels and reported eight-file scope retained',len(p['accepted370_contract']['expected_ordered370_labels'])==133 and len(p['accepted370_contract']['expected_changed_paths'])==8)
check('exact received message SHA size and no normalization',sha(r['text'].encode())==r['sha256']==c['receipt_sha256'] and len(r['text'].encode())==r['size_bytes']==c['receipt_size_bytes']==10516 and r['normalization']=='none')
check('370 is not a new pause or independent native inspection',c['commit_prefix']=='607d43c' and c['commit_full'] is None and not c['strong_safe_pause'] and c['last_confirmed_strong_safe_pause_step']==368 and 'not-independent-terminal-byte-capture' in r['capture_basis'])
inputs={k:json.loads(history[path]) for k,path in p['input_paths'].items()}
for k,path in p['input_paths'].items():check('whole input byte and canonical binding '+k,sha(history[path])==p['input_file_sha256'][k] and m['canonical'](inputs[k])==p['input_canonical_sha256'][k])
sources={row['path']:history[row['path']] for row in p['source_roots']};readme=history['README.md'];freeze=inputs['freeze']
check('all full frozen design inputs validate',m['validate_frozen_inputs'](inputs,p))
check('four unchanged review roots and accepted README validate',m['validate_sources'](sources,readme,p))
check('complete issuer admission launch draft validates',m['validate_design'](design,inputs,p))
a=freeze['full_original_contracts320_327']['320'];h=freeze['full_original_contracts320_327']['321']
check('whole original320 contract retained without rewritten modeled flags',design['full_original_admission_contract320']==a)
check('whole original321 contract and original handoff retained',design['full_original_handoff_contract321']==h and h['document']['selected_handoff']=='single-bounded-one-way-anonymous-bootstrap-pipe-into-worker-supervisor-memory')
check('five trust boundaries have no actual principal keys or components',len(design['trust_review_rows'])==5 and all(row['actual_principal'] is None and row['actual_trust_root'] is None and row['actual_key_provisioning'] is None and not row['native_proof'] for row in design['trust_review_rows']))
check('ten proposed responsibilities no actual events conformance or grant',len(design['protocol_review_rows'])==10 and all(row['actual_native_event_relation'] is None and not row['native_conformance'] and not row['runtime_authority'] for row in design['protocol_review_rows']))
check('all14 original authenticated fields in exact order',len(design['authenticated_original_fields'])==14 and [row['field'] for row in design['authenticated_original_fields']]==h['document']['authentication']['covered_fields'])
for i,row in enumerate(design['authenticated_original_fields']):check('original authenticated field '+row['field'],row['original_position']==i and row['actual_binding'] is None and not row['native_verified'])
check('original authentication domain trust and complete-field contract exact',design['full_original_authentication321']==h['document']['authentication'])
b=design['full_original_bootstrap321']
check('original65536byte10secondFD3 symbols retained without native claim',b==h['document']['bootstrap'] and b['maximum_raw_bytes']==65536 and b['deadline_seconds']==10 and b['symbolic_read_fd']==3 and not design['symbolic_limits_are_native_verified'])
check('full original FD policy lifecycle and stage mapping exact',design['full_original_FD_policy321']==h['document']['fd_policy'] and design['full_original_lifecycle321']==h['document']['lifecycle'] and design['full_original_stage_mapping320']==a['document']['stage_mapping'])
check('all ten complete original failure cases retained',len(design['original_failure_cut_review'])==10 and [row['full_original_failure_case320'] for row in design['original_failure_cut_review']]==a['document']['failure_cases'])
for row in design['original_failure_cut_review']:check('original failure cut remains unobserved '+row['id'],all(row[key] is None for key in ('actual_observed_consumption','actual_observed_spawn','actual_controller_obligations','actual_machine_obligations','actual_effective_quarantine','independent_raw_observation')) and not row['native_case_run'] and not row['native_proof'])
unknown=next(row for row in design['original_failure_cut_review'] if row['id']=='claim-durability-unknown')
check('original unknown consumption remains null not inferred known',unknown['full_original_failure_case320']['modeled_grant_consumed'] is None and unknown['actual_observed_consumption'] is None)
check('all twelve original320321 future proof obligations exact',len(design['full_original_proof_obligations320'])==len(design['full_original_proof_obligations321'])==6 and design['full_original_proof_obligations320']==a['document']['future_proof_obligations'] and design['full_original_proof_obligations321']==h['document']['future_proof_obligations'])
check('eight authored fault questions are not native tests or new original cases',len(design['additional_fault_design_questions'])==8 and all(not row['native_case_run'] and row['actual_fault_effectiveness'] is None and row['actual_observation'] is None for row in design['additional_fault_design_questions']))
check('two platforms separately unbound for every native input',len(design['platform_readiness'])==2 and [x['platform'] for x in design['platform_readiness']]==['Slackware-15.0','Slackware-current'] and all(v is None for row in design['platform_readiness'] for k,v in row.items() if k.startswith('actual_')))
for key,count in [('full_original_contracts320_327',8),('full_normative_rows347',16),('full_original_native_gap_rows348',16),('full_qualified_proof_rows347',46),('full_native_case_rows347',52),('full_independent_raw_groups335',12),('ordered_required_proof_case_relations',1072)]:check('full original normative rows '+key,len(freeze[key])==count)
check('all original370 design roles and interfaces remain complete frozen input',len(inputs['design370']['roles'])==9 and len(inputs['design370']['interfaces'])==8 and design['all_original370_roles_and_interfaces_retained'])
check('README377 conditional378 pause and no automatic379 unchanged',sha(readme)==p['readme_at_entry_sha256'] and design['readme_reconciliation_step']==377 and design['conditional_pause_step']==378 and design['no_automatic379'])
for key,value in [('commit_full','invented'),('strong_safe_pause',True),('runtime_authority',True),('actual_host_state','absent'),('actual_global_host_closure',True),('actual_live_bindings',{}),('user_worktree_clean',False),('user_head_matches_origin',False),('native_cases_run',1),('native_proofs_added',1)]:
    bad=copy.deepcopy(c);bad[key]=value;check('reject invented370 '+key,rejected(m['validate_acceptance'],bad,r,p))
for label,edit in [('truncated upload',lambda x:x[:-1]),('same-length upload edit',lambda x:x.replace('607d43c','607d43d',1)),('injected dirty status',lambda x:x.replace('607d43c (HEAD',' M README.md\n607d43c (HEAD',1))]:
    bad=copy.deepcopy(r);bad['text']=edit(r['text']);check('reject '+label,rejected(m['validate_acceptance'],c,bad,p))
bad=copy.deepcopy(r);bad['capture_basis']='independently-captured-terminal';check('reject invented capture origin',rejected(m['validate_acceptance'],c,bad,p))
for key in inputs:
    bad=copy.deepcopy(inputs);bad[key]['invented']=True;check('reject changed complete input '+key,rejected(m['validate_frozen_inputs'],bad,p))
bad=dict(sources);bad[next(iter(sources))]+=b'\n';check('reject historical source drift',rejected(m['validate_sources'],bad,readme,p))
bad=dict(sources);bad['new-service.sh']=b'claimed';check('reject fifth review root made service',rejected(m['validate_sources'],bad,readme,p))
check('reject premature README edit',rejected(m['validate_sources'],sources,readme+b'\n',p))
for label,mutate in [('original320 shortened',lambda x:x['full_original_admission_contract320']['document'].pop('service_traps')),('original321 shortened',lambda x:x['full_original_handoff_contract321']['document'].pop('fd_policy')),('signature trust from receipt',lambda x:x['full_original_authentication321'].update(trust_source='self-rehash')),('worker admission RPC',lambda x:x['full_original_authentication321'].update(no_admission_socket_or_online_RPC_for_worker=False)),('receipt bearer dispatch',lambda x:x['full_original_authentication321'].update(receipt_not_bearer_dispatch_capability=False)),('bootstrap bound changed',lambda x:x['full_original_bootstrap321'].update(maximum_raw_bytes=65537)),('bootstrap deadline renewed',lambda x:x['full_original_bootstrap321'].update(deadline_seconds=11)),('writer FD inherited',lambda x:x['full_original_bootstrap321'].update(closure='inherit writer')),('stage0 worker ledger',lambda x:x['full_original_bootstrap321'].update(process_effect='write ledger')),('missing original FD denial',lambda x:x['full_original_FD_policy321']['denied'].pop()),('missing lifecycle step',lambda x:x['full_original_lifecycle321'].pop()),('original stage map rewritten',lambda x:x['full_original_stage_mapping320'].pop()),('victim burn allowed',lambda x:x['protocol_review_rows'][1].update(required_design_behavior='burn before authentication')),('claim reverted unused',lambda x:x['protocol_review_rows'][2].update(required_design_behavior='return unused on failure')),('spawn before spend',lambda x:x['protocol_review_rows'][4].update(required_design_behavior='spawn before durable spend')),('lost ACK permits relaunch',lambda x:x['protocol_review_rows'][3].update(required_design_behavior='retry launch')),('missing original failure cut',lambda x:x['original_failure_cut_review'].pop()),('unknown consumption set known',lambda x:x['original_failure_cut_review'][2]['full_original_failure_case320'].update(modeled_grant_consumed=True)),('native spawn observed',lambda x:x['original_failure_cut_review'][6].update(actual_observed_spawn=True)),('native no-child claimed',lambda x:x['original_failure_cut_review'][6].update(actual_machine_obligations=False)),('fault question marked run',lambda x:x['additional_fault_design_questions'][0].update(native_case_run=True)),('service component selected',lambda x:x['platform_readiness'][0].update(actual_service='service')),('platform evidence shared',lambda x:x['platform_readiness'].pop()),('cryptographic proof claimed',lambda x:x['boundaries'].update(actual_cryptography_proven=True)),('symbolic limits promoted native',lambda x:x.update(symbolic_limits_are_native_verified=True)),('executable state machine claimed',lambda x:x.update(case_matrix_is_executable_state_machine=True)),('admission runner implemented',lambda x:x.update(admission_runner_implemented=True)),('native authority grant',lambda x:x.update(runtime_authority=True)),('whole normative scope waived',lambda x:x.update(all_full_original_requirements_normative=False)),('premature pause',lambda x:x.update(conditional_pause_step=371)),('bool schema',lambda x:x.update(schema=True))]:
    bad=copy.deepcopy(design);mutate(bad);check('reject '+label,rejected(m['validate_design'],bad,inputs,p))
for i,row in enumerate(design['authenticated_original_fields']):
    bad=copy.deepcopy(design);bad['authenticated_original_fields'].pop(i);check('reject omitted authenticated field '+row['field'],rejected(m['validate_design'],bad,inputs,p))
for key,value in [('C_port_open',True),('production_entry_closed',False),('phase2_open',True),('machine_action_required',True),('controller_action_required',True),('historical_binding_or_authority_reuse_allowed',True),('current_step_strong_safe_pause',True),('native_components_selected',True)]:
    bad=copy.deepcopy(design);bad['boundaries'][key]=value;check('reject closed boundary changed '+key,rejected(m['validate_design'],bad,inputs,p))
bad=copy.deepcopy(p);bad['baseline_sha256']['README.md']='0'*64;check('reject policy substitution',rejected(m['validate_policy'],bad))
out=m['review'](design,c,r,inputs,sources,readme,p)
check('review report retains all original native gaps normative rows and370design',out['full_original_native_gap_rows348']==freeze['full_original_native_gap_rows348'] and out['full_normative_rows347']==freeze['full_normative_rows347'] and out['all_original370_roles_and_interfaces']==inputs['design370'])
out['design']['full_original_bootstrap321']['deadline_seconds']=999;out['full_original_native_gap_rows348'].pop();out['boundaries']['runtime_authority']=True
again=m['review'](design,c,r,inputs,sources,readme,p)
check('mutable report detached from caller and subsequent frozen review',again['design']['full_original_bootstrap321']['deadline_seconds']==10 and len(again['full_original_native_gap_rows348'])==16 and not again['boundaries']['runtime_authority'] and design['full_original_bootstrap321']['deadline_seconds']==10)
tree=ast.parse(tool.read_text());imports={a.name for node in ast.walk(tree) if isinstance(node,ast.Import) for a in node.names}
check('pure reviewer imports only hashlib json re',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen','sign','verify','fork','spawn','pipe','fsync'}
check('reviewer has no filesystem crypto service storage pipe network or spawn operation',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
