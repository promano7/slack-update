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

root=Path(sys.argv[1]);name='phase-1-operational-baseline-owned-recovery-design-review'
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
p=load('policy');design=load('design');c=load('confirmed372');r=load('step372-user-acceptance')
check('authored373 policy independently frozen',m['validate_policy'](p))
check('all1910 accepted372 baseline bindings retained',len(p['baseline_sha256'])==p['accepted_source_count']==1910)
history={}
for rel,digest in p['baseline_sha256'].items():
    path=root/rel
    if not path.is_file() or path.is_symlink() or path.resolve()!=path.absolute() or not path.resolve().is_relative_to(root):raise ValueError('unsafe accepted source: '+rel)
    raw=path.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-p['accepted_changelog_size_bytes']:]
    if sha(raw)!=digest:raise ValueError('accepted372 drift: '+rel)
    history[rel]=raw
check('all accepted372 bytes preserved except additive CHANGELOG',len(history)==1910)
check('complete372 uploaded return and reported acceptance validate',m['validate_acceptance'](c,r,p))
check('all215 exact predecessor labels and reported eight-file scope retained',len(p['accepted372_contract']['expected_ordered372_labels'])==215 and len(p['accepted372_contract']['expected_changed_paths'])==8)
check('exact received message SHA size and no normalization',sha(r['text'].encode())==r['sha256']==c['receipt_sha256'] and len(r['text'].encode())==r['size_bytes']==c['receipt_size_bytes']==16313 and r['normalization']=='none')
check('372 is not a new pause or independent native inspection',c['commit_prefix']=='f8059fc' and c['commit_full'] is None and not c['strong_safe_pause'] and c['last_confirmed_strong_safe_pause_step']==368 and 'not-independent-terminal-byte-capture' in r['capture_basis'])
inputs={k:json.loads(history[path]) for k,path in p['input_paths'].items()}
for k,path in p['input_paths'].items():check('whole input byte and canonical binding '+k,sha(history[path])==p['input_file_sha256'][k] and m['canonical'](inputs[k])==p['input_canonical_sha256'][k])
sources={row['path']:history[row['path']] for row in p['source_roots']};readme=history['README.md'];freeze=inputs['freeze']
check('all full frozen design inputs validate',m['validate_frozen_inputs'](inputs,p))
check('four unchanged review roots and accepted README validate',m['validate_sources'](sources,readme,p))
check('complete original baseline owned recovery draft validates',m['validate_design'](design,inputs,p))
check('three original373 assignments retained without limiting scope',design['primary_gap_ids']==inputs['plan369']['roadmap'][4]['primary_gap_ids'] and len(design['primary_gap_review'])==3 and not design['primary_assignment_limits_normative_scope'] and design['all_full_original_requirements_normative'])
for n in ('322','323','324'):
    check('whole original contract'+n+' retained',design['full_original_contract'+n]==freeze['full_original_contracts320_327'][n])
o=design['full_original_contract322']['document'];t=design['full_original_contract323']['document'];g=design['full_original_contract324']['document'];norm=freeze['full_normative_rows347']
check('whole original27 phase trace retained with native nulls',design['full_original_entry_trace347']==norm['original_phase_and_bootstrap_contract']['entry_trace'] and len(design['full_original_entry_trace347'])==27 and all(row['actual_evidence'] is None and row['actual_implementation'] is None and not row['runtime_authorized'] for row in design['full_original_entry_trace347']))
check('seven original full baseline domains exact',len(design['baseline_domain_review'])==7 and [row['domain'] for row in design['baseline_domain_review']]==g['resource_domains'])
for row in design['baseline_domain_review']:
    check('fresh original vector absent '+row['domain'],all(row[k] is None for k in ('actual_original_vector','actual_expected_approved_vectors','actual_object_alias_writer_binding','actual_backup_bytes_metadata_presence')) and row['capture_before_any_owned_effect'] and not row['native_capture_proven'] and row['full_original_baseline_contract324_sha256']==m['canonical'](g['baseline_contract']))
check('sixteen phase observations exact original sequence',len(design['proposed_phase_observation_rows'])==16 and design['full_original_successor_sequence324']==g['successor_sequence'] and [row['original_sequence_name'] for row in design['proposed_phase_observation_rows']]==g['successor_sequence'])
for row in design['proposed_phase_observation_rows']:
    check('future phase unobserved '+row['original_sequence_name'],row['actual_native_event'] is None and not row['native_order_proven'] and not row['current_authority'])
check('traps guard fresh memory baseline before owned writes exact original',g['interstage_contract']==freeze['full_original_contracts320_327']['324']['document']['interstage_contract'])
check('whole original baseline approved deltas and raw pkglist roles exact',all(g[k]==freeze['full_original_contracts320_327']['324']['document'][k] for k in ('baseline_contract','pkglist_contract','guard_contract','recovery_contract')) and not design['production_state_restore_rebinds_audit_pin'])
check('historical stage7 facts immutable and successor owned effects retained',o['immutable_stage_facts']==freeze['full_original_contracts320_327']['322']['document']['immutable_stage_facts'] and o['successor_stage7']['effect']=='owned-files' and o['immutable_stage_facts']['frozen_stage7']['effect']=='read-only')
check('all nine original owned microsteps exact order',design['full_original_owned_microsteps347']==norm['owned_stage7_microsteps'] and len(design['owned_microstep_review'])==9 and [row['source_step'] for row in design['owned_microstep_review']]==o['commit_contract']['sequence'])
for i,row in enumerate(design['owned_microstep_review']):
    check('whole owned microstep and unknown outcomes '+row['source_step'],row['position']==i and row['full_original_microstep347']==norm['owned_stage7_microsteps'][i] and row['actual_syscall_storage_sequence'] is None and row['actual_owned_commit_outcome'] is None and row['actual_target_outcome'] is None and not row['native_proof'] and not row['current_authority'])
    check('three inert cut questions '+row['source_step'],[x['location'] for x in row['declared_review_cut_questions']]==['before','within','after'] and all(x['actual_fault_effectiveness'] is None and x['actual_observation'] is None and not x['native_case_run'] for x in row['declared_review_cut_questions']))
check('all eight original owned failure events retained',len(design['original_owned_failure_review'])==8 and [row['original_failure_event322'] for row in design['original_owned_failure_review']]==o['failure_events'])
for row in design['original_owned_failure_review']:
    check('owned failure remains independently unknown '+row['original_failure_event322'],all(v is None for k,v in row.items() if k.startswith('actual_')) and row['original_failure_status_preserved'] and not row['native_case_run'] and not row['current_recovery_authority'])
check('ten original-rights recovery gate questions no grant',len(design['recovery_gate_review'])==10 and len({x['id'] for x in design['recovery_gate_review']})==10 and all(x['actual_binding_or_evidence'] is None and not x['native_satisfied'] and not x['current_authority'] for x in design['recovery_gate_review']))
for row in design['recovery_gate_review']:check('unbound recovery gate '+row['id'],bool(row['requirement']))
check('full original finite clock budget fences and recovery whitelist retained',all(t[k]==freeze['full_original_contracts320_327']['323']['document'][k] for k in ('clock_contract','forward_contract','fence_contract','recovery_contract','closure_contract')) and t['clock_contract']['actual_recovery_budget'] is None and t['clock_contract']['actual_recovery_deadline'] is None)
check('eighteen branches inert not native cases or action selector',len(design['recovery_branch_review'])==18 and len({x['id'] for x in design['recovery_branch_review']})==18 and not design['recovery_branches_are_executable_model'] and not design['recovery_dispatcher_implemented'])
for row in design['recovery_branch_review']:
    check('conditional branch unobserved '+row['id'],row['actual_condition_observed'] is None and row['actual_action_or_noop_outcome'] is None and row['all_original_recovery_gates_required_when_applicable'] and not row['native_case_run'] and not row['is_new_original_native_case'] and not row['is_executable_action_selector'] and not row['current_recovery_authority'])
check('owned uncertainty no-backup target state and forward status remain distinct',not design['unknown_owned_binding_implies_unknown_or_absent_target'] and not design['missing_backup_implies_unchanged_target'] and not design['restoration_success_erases_forward_failure'] and not design['recovery_decision_is_current_grant'])
check('all ten exact372 candidate blockers retained unresolved',len(design['inherited372_feasibility_blockers'])==10 and [row['full_original372_candidate_family'] for row in design['inherited372_feasibility_blockers']]==inputs['design372']['candidate_families'] and all(not row['native_gap_closed'] and not row['current_authority'] for row in design['inherited372_feasibility_blockers']) and design['native_readiness_still_blocked'] and not design['contract_relaxation_permitted'])
check('two separate platform recovery inputs entirely unbound',[row['platform'] for row in design['platform_readiness']]==['Slackware-15.0','Slackware-current'] and all(v is None for row in design['platform_readiness'] for k,v in row.items() if k.startswith('actual_')) and all(not row['native_case_run'] and not row['native_proof'] and not row['current_authority'] for row in design['platform_readiness']))
for row in design['primary_gap_review']:
    original=next(x for x in freeze['full_original_native_gap_rows348'] if x['inherited_gap']['id']==row['id'])
    check('whole original primary gap remains unresolved '+row['id'],row['full_original_gap348']==original and not row['native_gap_closed'])
for key,count in [('full_original_contracts320_327',8),('full_normative_rows347',16),('full_original_native_gap_rows348',16),('full_qualified_proof_rows347',46),('full_native_case_rows347',52),('full_independent_raw_groups335',12),('ordered_required_proof_case_relations',1072)]:check('whole inherited normative scope '+key,len(freeze[key])==count)
check('README377 conditional378 no automatic379 and current implementation absent',sha(readme)==p['readme_at_entry_sha256'] and design['readme_reconciliation_step']==377 and design['conditional_pause_step']==378 and design['no_automatic379'] and not design['baseline_is_actual_capture'] and not design['owned_commit_implemented'] and design['native_cases_run']==design['native_proofs_added']==0)
for key,value in [('commit_full','invented'),('strong_safe_pause',True),('runtime_authority',True),('actual_host_state','absent'),('actual_global_host_closure',True),('actual_live_bindings',{}),('user_worktree_clean',False),('user_head_matches_origin',False),('native_cases_run',1),('native_proofs_added',1)]:
    bad=copy.deepcopy(c);bad[key]=value;check('reject invented372 '+key,rejected(m['validate_acceptance'],bad,r,p))
labels=p['accepted372_contract']['expected_ordered372_labels']
for label,edit in [('truncated upload',lambda x:x[:-1]),('same-length receipt edit',lambda x:x.replace('f8059fc','f8059fd',1)),('dirty status injection',lambda x:x.replace('f8059fc (HEAD',' M README.md\nf8059fc (HEAD',1)),('reordered PASS labels',lambda x:x.replace(labels[0]+'\n'+labels[1],labels[1]+'\n'+labels[0]))]:
    bad=copy.deepcopy(r);bad['text']=edit(r['text']);check('reject '+label,rejected(m['validate_acceptance'],c,bad,p))
bad=copy.deepcopy(r);bad['capture_basis']='independent-terminal';check('reject invented capture origin',rejected(m['validate_acceptance'],c,bad,p))
for key in inputs:
    bad=copy.deepcopy(inputs);bad[key]['invented']=True;check('reject changed whole input '+key,rejected(m['validate_frozen_inputs'],bad,p))
bad=dict(sources);bad[next(iter(sources))]+=b'\n';check('reject historical source drift',rejected(m['validate_sources'],bad,readme,p))
bad=dict(sources);bad['restore-worker.sh']=b'claimed';check('reject fifth restoration root',rejected(m['validate_sources'],bad,readme,p))
check('reject premature README reconciliation',rejected(m['validate_sources'],sources,readme+b'\n',p))
mutations=[
 ('contract322 truncated',lambda x:x['full_original_contract322']['document'].pop('commit_contract')),
 ('contract323 recovery made blanket exemption',lambda x:x['full_original_contract323']['document']['recovery_contract'].update(expiry_relation='always restore')),
 ('contract324 baseline rebound',lambda x:x['full_original_contract324']['document']['baseline_contract'].update(identity='current observed state')),
 ('original full entry phase removed',lambda x:x['full_original_entry_trace347'].pop()),
 ('stage0 preflight made original baseline',lambda x:x['proposed_phase_observation_rows'][2].update(required_future_behavior='reuse stage0 capture')),
 ('owned workspace before guard',lambda x:x['proposed_phase_observation_rows'].reverse()),
 ('baseline capture before traps',lambda x:x['baseline_domain_review'][0].update(required_fresh_original_capture='capture before traps')),
 ('approved delta invented from observation',lambda x:x['baseline_domain_review'][0].update(actual_expected_approved_vectors={'observed':'trusted'})),
 ('unrelated packages exempted',lambda x:x['baseline_domain_review'][0].update(approved_delta_design='ignore unrelated records')),
 ('broad owned subtree exclusion',lambda x:x['baseline_domain_review'][-1].update(approved_delta_design='exclude whole owned subtree')),
 ('raw row equivalence replaces bytes',lambda x:x['full_original_contract324']['document']['pkglist_contract'].update(replacement='equivalent parsed rows')),
 ('production restore rebinds audit pin',lambda x:x.update(production_state_restore_rebinds_audit_pin=True)),
 ('stage7 made read-only',lambda x:x['full_original_contract322']['document']['successor_stage7'].update(effect='read-only')),
 ('historical frozen stage7 rewritten',lambda x:x['full_original_contract322']['document']['immutable_stage_facts']['frozen_stage7'].update(effect='owned-files')),
 ('binding made stage8 bearer grant',lambda x:x['owned_microstep_review'][-1].update(required_future_native_observation='dispatch stage8 on binding')),
 ('intent omitted',lambda x:x['owned_microstep_review'].pop(1)),
 ('same attempt renewed on write',lambda x:x['full_original_contract322']['document']['commit_contract'].update(grant='new grant per write')),
 ('exclusive staging reused',lambda x:x['owned_microstep_review'][2].update(required_future_native_observation='reuse existing pending')),
 ('partial bytes made complete',lambda x:x['owned_microstep_review'][3].update(actual_owned_commit_outcome='complete')),
 ('directory durability omitted',lambda x:x['owned_microstep_review'].pop(7)),
 ('unknown no-replace commit replay',lambda x:x['owned_microstep_review'][6].update(uncertainty_disposition='retry rename')),
 ('occupied final overwritten',lambda x:x['original_owned_failure_review'][-1].update(required_design_disposition='force overwrite')),
 ('prior package effects falsely absent',lambda x:x['original_owned_failure_review'][0].update(actual_target_effect_extent='absent')),
 ('failure case omitted',lambda x:x['original_owned_failure_review'].pop()),
 ('failure erased by successful restore',lambda x:x.update(restoration_success_erases_forward_failure=True)),
 ('owned uncertainty implies target absent',lambda x:x.update(unknown_owned_binding_implies_unknown_or_absent_target=True)),
 ('missing backup implies target unchanged',lambda x:x.update(missing_backup_implies_unchanged_target=True)),
 ('no-backup branch made automatic closure',lambda x:x['recovery_branch_review'][7].update(proposed_future_disposition='declare safe pause')),
 ('unknown backup used for restore',lambda x:x['recovery_branch_review'][9].update(proposed_future_disposition='restore unknown backup')),
 ('unknown restoration ACK retried',lambda x:x['recovery_branch_review'][11].update(proposed_future_disposition='repeat restore')),
 ('foreign drift restored',lambda x:x['recovery_branch_review'][15].update(proposed_future_disposition='restore onto foreign state')),
 ('partial package backed only by filename',lambda x:x['recovery_branch_review'][16].update(proposed_future_disposition='backup filename proves rollback')),
 ('parent exit made known child drain',lambda x:x['recovery_gate_review'][6].update(requirement='parent exited')),
 ('guard reacquired after loss',lambda x:x['recovery_gate_review'][5].update(requirement='reacquire guard')),
 ('budget refunded after unknown',lambda x:x['recovery_branch_review'][14].update(proposed_future_disposition='refund spend')),
 ('deadline renewed after expiry',lambda x:x['recovery_branch_review'][13].update(proposed_future_disposition='renew deadline')),
 ('forward-only revoke made implicit recovery',lambda x:x['recovery_branch_review'][2].update(proposed_future_disposition='automatic recovery permission')),
 ('all revocation ignored',lambda x:x['recovery_branch_review'][3].update(proposed_future_disposition='restore anyway')),
 ('wrong boot restored',lambda x:x['recovery_branch_review'][4].update(proposed_future_disposition='rebind boot')),
 ('finite synthetic budget made actual',lambda x:x['full_original_contract323']['document']['clock_contract'].update(actual_recovery_budget=5)),
 ('verified no-op made uncertain action replay',lambda x:x['recovery_branch_review'][10].update(proposed_future_disposition='repeat previous action')),
 ('target evidence skipped before release',lambda x:x['recovery_gate_review'][-1].update(requirement='release then capture')),
 ('primitive blockers waived',lambda x:x['inherited372_feasibility_blockers'][0].update(native_gap_closed=True)),
 ('native readiness made complete',lambda x:x.update(native_readiness_still_blocked=False)),
 ('contract relaxation permitted',lambda x:x.update(contract_relaxation_permitted=True)),
 ('branch dispatcher implemented',lambda x:x.update(recovery_dispatcher_implemented=True)),
 ('table made executable scheduler',lambda x:x.update(recovery_branches_are_executable_model=True)),
 ('future recovery decision made grant',lambda x:x.update(recovery_decision_is_current_grant=True)),
 ('runtime authority granted',lambda x:x.update(runtime_authority=True)),
 ('native case run',lambda x:x.update(native_cases_run=1)),
 ('native proof discharged',lambda x:x.update(native_proofs_added=1)),
 ('primary scope made restrictive',lambda x:x.update(primary_assignment_limits_normative_scope=True)),
 ('premature pause',lambda x:x.update(conditional_pause_step=373)),
 ('bool schema',lambda x:x.update(schema=True))]
for label,mutate in mutations:
    bad=copy.deepcopy(design);mutate(bad);check('reject '+label,rejected(m['validate_design'],bad,inputs,p))
for i,row in enumerate(design['baseline_domain_review']):
    bad=copy.deepcopy(design);bad['baseline_domain_review'][i]['actual_original_vector']={'historical':'reused'};check('reject invented original capture '+row['domain'],rejected(m['validate_design'],bad,inputs,p))
for i,row in enumerate(design['owned_microstep_review']):
    bad=copy.deepcopy(design);bad['owned_microstep_review'][i]['declared_review_cut_questions'][1]['native_case_run']=True;check('reject microstep cut promoted native '+row['source_step'],rejected(m['validate_design'],bad,inputs,p))
for i,row in enumerate(design['recovery_gate_review']):
    bad=copy.deepcopy(design);bad['recovery_gate_review'][i]['native_satisfied']=True;check('reject unproven recovery gate '+row['id'],rejected(m['validate_design'],bad,inputs,p))
for i,row in enumerate(design['recovery_branch_review']):
    bad=copy.deepcopy(design);bad['recovery_branch_review'][i]['current_recovery_authority']=True;check('reject branch granted authority '+row['id'],rejected(m['validate_design'],bad,inputs,p))
bad=copy.deepcopy(design);bad['platform_readiness'][1]=copy.deepcopy(bad['platform_readiness'][0]);check('reject platform evidence borrowing',rejected(m['validate_design'],bad,inputs,p))
for key,value in [('C_port_open',True),('production_entry_closed',False),('phase2_open',True),('machine_action_required',True),('controller_action_required',True),('historical_binding_or_authority_reuse_allowed',True),('current_step_strong_safe_pause',True),('native_components_selected',True),('actual_original_baseline_captured',True),('actual_owned_commit_proven',True),('actual_recovery_authorized',True),('actual_target_unchanged_proven',True),('actual_global_host_closure',True),('actual_live_bindings',{})]:
    bad=copy.deepcopy(design);bad['boundaries'][key]=value;check('reject closed boundary changed '+key,rejected(m['validate_design'],bad,inputs,p))
bad=copy.deepcopy(p);bad['baseline_sha256']['README.md']='0'*64;check('reject policy substitution',rejected(m['validate_policy'],bad))
out=m['review'](design,c,r,inputs,sources,readme,p)
check('report retains full original gaps normative rows and accepted372 blockers',out['full_original_native_gap_rows348']==freeze['full_original_native_gap_rows348'] and out['full_normative_rows347']==freeze['full_normative_rows347'] and out['full_accepted_design372']==inputs['design372'])
out['design']['owned_microstep_review'].pop();out['full_normative_rows347'].clear();out['boundaries']['actual_recovery_authorized']=True
again=m['review'](design,c,r,inputs,sources,readme,p)
check('report mutations detached from caller and later review',len(again['design']['owned_microstep_review'])==len(design['owned_microstep_review'])==9 and len(again['full_normative_rows347'])==16 and not again['boundaries']['actual_recovery_authorized'])
tree=ast.parse(tool.read_text());imports={a.name for node in ast.walk(tree) if isinstance(node,ast.Import) for a in node.names}
check('pure reviewer imports only hashlib json re',imports=={'hashlib','json','re'} and not any(isinstance(n,ast.ImportFrom) for n in ast.walk(tree)))
forbidden={'open','exec','eval','compile','__import__','system','popen','run','read_bytes','read_text','decode','socket','urlopen','sign','verify','fork','spawn','pipe','fsync','kill','clock_gettime','rename','unlink','mkdir'}
check('reviewer has no capture backup storage clock service restore or dispatch',not any(isinstance(n,ast.Call) and ((isinstance(n.func,ast.Name) and n.func.id in forbidden) or (isinstance(n.func,ast.Attribute) and n.func.attr in forbidden)) for n in ast.walk(tree)))
print('Result: PASS (%d passes, 0 failures)' % passes)
PYTEST
