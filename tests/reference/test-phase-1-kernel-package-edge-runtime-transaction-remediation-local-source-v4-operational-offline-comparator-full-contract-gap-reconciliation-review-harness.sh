#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 -B - "$repo_root" <<'PYTEST'
from pathlib import Path
from dataclasses import FrozenInstanceError, replace
from types import SimpleNamespace
from unittest.mock import patch
import ast
import copy
import hashlib
import json
import os
import runpy
import subprocess
import sys
import tempfile

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-full-contract-gap-reconciliation-review';oldbase='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-adversarial-control-effectiveness-review';module=None
fixture=root/'tests/fixtures/reference/acceptance/phase-1';OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-full-contract-gap-reconciliation-review.md': '0b3546e98ec0c3a2f16fea26169d6855c89d3dc827a2cf127f1b00bad86eb722', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-full-contract-gap-reconciliation-review-checkpoint-confirmation.json': '4d348b1b46740e3c7ae02bef92efdd1efe7fc240c7820f746c3d9159c4843b1e', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-full-contract-gap-reconciliation-review-policy.json': '55337ec7bba0248ee18d1c6dd6bcdbb209fb82ba5d1a2a4878fc0175addf221d', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-full-contract-gap-reconciliation-review-reconciliation-contract.json': '93a293332853fd1eedba030bfd04cce6c1b5ec1b4dff307f6ec778a67e45a882', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-full-contract-gap-reconciliation-review-reconciliation-ledger.json': '7230d67ef7b99fdb8abba21076aa92d95ab74c2ef2e0e9555d81872da4859df2', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-full-contract-gap-reconciliation-review-retained-obligations.json': 'aa22f57ef4537de79253d9c23ff8e412e6831e879276927f9ece2d4989a9e943', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-full-contract-gap-reconciliation-review-step356-user-acceptance.json': '225cda77e66dace21408429f8e279c8aa2d84ab77c5b7bb4ed44699350d9b543', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-comparator-full-contract-gap-reconciliation-review-full-contract-source-map.json': '49a4cb45602ab223a04be610e7d38a55474767c38bb61f04cb3d63d92a90cf00'};passes=0
def check(label,condition):
    global passes
    if not condition:raise AssertionError(label)
    passes+=1;print('PASS: '+label,flush=True)
def sha(raw):return hashlib.sha256(raw).hexdigest()
def load(tail):return json.loads((fixture/(base+'-'+tail+'.json')).read_bytes())
def fails(fn,*args):
    try:fn(*args)
    except ValueError:return True
    return False
for rel,digest in OWN_HASHES.items():
    p=root/rel;check('exact current357 input '+p.name,p.is_file()and not p.is_symlink()and p.resolve()==p.absolute()and sha(p.read_bytes())==digest)
policy=load('policy');contract=load('reconciliation-contract');retained=load('retained-obligations');ledger=load('reconciliation-ledger');receipt=load('step356-user-acceptance');confirmed=load('checkpoint-confirmation')
history={}
for rel,digest in policy['baseline_sha256_bindings'].items():
    p=root/rel
    if not p.is_file()or p.is_symlink()or p.resolve()!=p.absolute():raise ValueError('unsafe accepted source')
    raw=p.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size']:]
    if sha(raw)!=digest:raise ValueError('accepted356 source drift '+rel)
    history[rel]=raw
check('all1791 accepted356 bytes and exact historical CHANGELOG suffix',len(history)==1791)
raw=receipt['text'].encode();lines=receipt['text'].splitlines()
check('complete54824-byte original356 receipt retained without normalization',len(raw)==54824 and sha(raw)=='60ee822a9e6935ae121dcd0c6227282281d8aa7a6a37f5f3072b8674081469b0' and receipt['original_display_sha256']==sha(raw) and receipt['original_display_size_bytes']==len(raw) and receipt['ordered_output_normalization']=='none')
check('complete530 predecessor labels exactly match original receipt',[x for x in lines if x.startswith('PASS: ')]==policy['expected_predecessor_labels'] and lines.count('Result: PASS (530 passes, 0 failures)')==1)
check('reported48b0d13 exact tenfiles6070 commit nine paths and successful push','[main 48b0d13] Phase 1 step 356: verify offline adversarial control effectiveness'in lines and ' 10 files changed, 6070 insertions(+)'in lines and set(x[len(' create mode 100644 '):]for x in lines if x.startswith(' create mode 100644 '))==set(policy['expected_predecessor_paths']) and '   8307f71..48b0d13  main -> main'in lines)
check('complete clean matching heads and full356 commit unknown',lines[-3:-1]==['48b0d13 (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 356: verify offline adversarial control effectiveness']*2 and confirmed['commit_full']is None and confirmed['evidence_sha256']==sha(raw) and all(confirmed[k]is True for k in ['user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','complete_ordered_return_matches_prepared_and_installed']))
bindings=list(retained['source_bindings'].values())+list(retained['model_modules'].values())+list(retained['original_design_bindings'].values())+sum((list(retained[k].values())for k in ['accepted350_bindings','accepted351_bindings','accepted352_bindings','accepted353_bindings','accepted354_bindings','accepted355_bindings','accepted356_bindings']),[])+[retained['accepted349_plan_binding'],retained['schema_module_binding'],retained['expectation_module_binding'],retained['observation_module_binding'],retained['selector_comparator_module_binding'],retained['recovery_comparator_module_binding'],retained['publication_comparator_module_binding'],retained['control_assessment_module_binding']]
for binding in bindings:check('source-bound unchanged inherited '+Path(binding['path']).name,sha(history[binding['path']])==binding['sha256'])
oracle=json.loads(history[retained['source_bindings']['oracle335']['path']])
check('full twelve original native evidence group rows retained',retained['original_evidence_group_rows']==oracle['evidence_groups'])
check('all eight full original320-327 contracts retained',set(retained['original_design_bindings'])==set(str(i)for i in range(320,328)))
check('all52 source-bound native cases still unrun',len(retained['original_case_row_sha256'])==len(oracle['cases'])==52 and all(row['status']=='required-not-run'and row['sha256']==sha(json.dumps(original,sort_keys=True,separators=(',',':')).encode())for row,original in zip(retained['original_case_row_sha256'],oracle['cases'])))
check('all46 proofs52 cases16 gaps retained',[retained['counts'][k]for k in ['native_proofs','native_cases','native_gaps']]==[46,52,16])
check('seven frozen modules nine original pause conditions retained',len(retained['model_modules'])==7 and len(retained['original_pause_conditions'])==9)
source_map=load('full-contract-source-map');norm=ledger['full_normative_rows']
original_reconciliation=json.loads(history[retained['source_bindings']['reconciliation347']['path']]);original_gaps=json.loads(history[retained['source_bindings']['gaps348']['path']]);original_freeze=json.loads(history[retained['source_bindings']['freeze348']['path']])
check('all full347 normative rows exact no count-only replacement',norm==original_reconciliation['retained_full_normative_rows'])
check('all full348 gap rows exact including offline disposition',ledger['full_original_native_gap_rows348']==original_gaps['native_gap_rows'])
check('all original335 evidence rows and independence contract exact',ledger['full_original_evidence_group_rows335']==oracle['evidence_groups']and ledger['full_original_independence_contract335']==oracle['independence_contract'])
check('original348 full81 frozen artifact registry exact',source_map['frozen_artifact_registry339_347']==original_freeze['frozen_artifact_registry339_347'])
for row in source_map['frozen_artifact_registry339_347']:check('exact retained frozen339-347 source '+row['path'],sha(history[row['path']])==row['sha256'])
check('eight whole original320-327 documents source-bound',set(source_map['full_original_contracts320_327'])==set(str(n)for n in range(320,328)))
for n,item in source_map['full_original_contracts320_327'].items():
 source=json.loads(history[item['binding']['path']]);check('full original design source320-327 all keys retained '+n,item['binding']==retained['original_design_bindings'][n]and item['document']==source and sha(history[item['binding']['path']])==item['binding']['sha256'])
 check('all original qualified proof requirements retained '+n,all(row['status']=='required-not-proven'for row in source['future_proof_obligations']))
check('source-map preserves all original normative source bindings',source_map['original_source_bindings']==retained['source_bindings'])
counts={'all26_nominal_interfaces':26,'all27_phase_boundaries':27,'all35_nominal_types':35,'all95_macro_design_relations':95,'authority_window_reconciliation':9,'effect_domain_reconciliation':30,'macro_cut_obligations':81,'native_case_templates':52,'native_gap_register':16,'owned_stage7_microsteps':9,'qualified_proof_reconciliation':46,'seven_capability_reconciliation':7,'ten_cross_obligation_reconciliation':10}
for key,count in counts.items():check('complete retained category count '+key,len(norm[key])==count)
domains={row['id']for row in norm['effect_domain_reconciliation']};phases={row['id']for row in norm['all27_phase_boundaries']};interfaces={row['id']for row in norm['all26_nominal_interfaces']};types={row['name']for row in norm['all35_nominal_types']};proofs={row['qualified_id']for row in norm['qualified_proof_reconciliation']};case_tuples={(row['platform'],row['case_id'])for row in norm['native_case_templates']};windows={row['window']for row in norm['authority_window_reconciliation']}
check('all indexed normative identities unique',len(domains)==30 and len(phases)==27 and len(interfaces)==26 and len(types)==35 and len(proofs)==46 and len(case_tuples)==52 and len(windows)==9)
for row in norm['all26_nominal_interfaces']:
 check('nominal interface no actual component or dispatch '+row['id'],row['dispatch_blocked']is True and all(value is None for key,value in row.items()if key.startswith('actual_'))and set(row['input_types']+row['success_output_types'])<=types)
 check('nominal interface phase actor rights and proofs linked '+row['id'],set(row['required_future_proofs'])<=proofs and all(context['id']in phases and context['rights_window']in windows and next(p for p in norm['all27_phase_boundaries']if p['id']==context['id'])['actor']==context['caller_actor']for context in row['allowed_phase_contexts']))
for row in norm['all35_nominal_types']:check('nominal type no native ABI authority '+row['name'],row['authority']is False and row['native_abi']is None and row['real_value']is None and row['proof_status']=='required-not-proven')
for row in norm['all27_phase_boundaries']:check('full phase no native instruction or runtime '+row['id'],row['position']in range(27)and row['rights_window']in windows and row['runtime_authorized']is False and row['actual_implementation']is None and row['actual_evidence']is None)
check('full phase positions exact ordered zero through26',[row['position']for row in norm['all27_phase_boundaries']]==list(range(27)))
for row in norm['all95_macro_design_relations']:check('macro relationship linked native edge unproven '+row['source']+' -> '+row['target'],row['source']in domains and row['target']in domains and row['actual_binding']is None and row['actual_edge_proven']is False and row['dispatch_authorized']is False)
for row in norm['effect_domain_reconciliation']:check('effect domain complete native pending '+row['id'],row['dispatch_blocked']is True and row['actual_component']is None and row['actual_effect_evidence']is None and set(row['phase_ids'])<=phases and set(row['required_qualified_proofs'])<=proofs and (row['nominal_interface_id']is None or row['nominal_interface_id']in interfaces))
for row in norm['authority_window_reconciliation']:check('right window no actual grant native binding '+row['window'],row['actual_binding']is None and row['actual_grant']is None and set(row['phase_ids'])<=phases and row['inherited_window']['actual_authority_valid']is False)
for row in norm['qualified_proof_reconciliation']:
 p=row['inherited_proof'];source=source_map['full_original_contracts320_327'][str(p['source_step'])];original=next(v for v in source['document']['future_proof_obligations']if v['id']==p['source_proof']['id'])
 check('qualified full original proof unproven '+row['qualified_id'],row['status']=='required-not-proven'and row['actual_evidence']is None and row['private_PASS_is_native_proof']is False and p['source_proof']==original and p['source_design_sha256']==source['binding']['sha256']and p['operational_proven']is False and p['actual_evidence']is None)
 check('qualified proof phase domain interface links '+row['qualified_id'],set(row['candidate_phase_ids'])<=phases and set(row['domain_ids'])<=domains and set(row['nominal_interface_ids'])<=interfaces)
 check('qualified proof both-platform original case links '+row['qualified_id'],all((v['platform'],v['case_id'])in case_tuples for v in row['required_native_case_tuples'])and {v['platform']for v in row['required_native_case_tuples']}=={'Slackware-15.0','Slackware-current'})
original326=source_map['full_original_contracts320_327']['326']['document'];group_ids=[row['id']for row in oracle['evidence_groups']]
for row in norm['native_case_templates']:
 label=row['platform']+'/'+row['case_id'];original=next(v for v in original326['conformance_plan']if(v['platform'],v['case_id'])==(row['platform'],row['case_id']))
 check('original platform case no private result promotion '+label,row['status']=='required-not-run'and row['inherited_case']==original and all(value is None for key,value in row.items()if key.startswith('actual_'))and row['evidence_group_ids']==group_ids)
 check('original platform case full proof and evidence dependencies '+label,set(row['required_qualified_proofs'])<=proofs and row['required_source_evidence_gates']==original326['conformance_evidence_gates'])
check('exact26 required case IDs per platform',all({row['case_id']for row in norm['native_case_templates']if row['platform']==platform}==set(original326['conformance_case_ids'])for platform in original326['conformance_platforms']))
for row in norm['macro_cut_obligations']:check('macro cut no actual fault site or oracle '+row['id'],row['phase_id']in phases and row['rights_window']in windows and set(row['required_future_proofs'])<=proofs and row['runtime_authorized']is False and all(value is None for key,value in row.items()if key.startswith('actual_')))
for row in norm['owned_stage7_microsteps']:check('owned durability step no instruction evidence '+row['source_step'],row['status']=='required-not-native-refined'and row['actual_instruction_or_syscall']is None and row['actual_durability_evidence']is None and row['no_unknown_replay']is True)
check('owned microsteps complete ordered0-8',[row['position']for row in norm['owned_stage7_microsteps']]==list(range(9)))
for category in ['seven_capability_reconciliation','ten_cross_obligation_reconciliation']:
 for row in norm[category]:check('full capability cross obligation still native pending '+row['id'],row['actual_evidence']is None and row['operational_conformance']is False and set(row['design_related_domain_ids'])<=domains and set(row['design_related_qualified_proofs'])<=proofs)
for row in ledger['full_original_native_gap_rows348']:check('native gap retained unwaived '+row['inherited_gap']['id'],row['status']=='required-not-selected-refined-or-proven'and row['native_status_promoted']is False and row['actual_independent_evidence']is None and row['actual_model_or_component']is None and row['actual_native_event_relation']is None and bool(row['refinement_requirement']))
for row in ledger['full_original_evidence_group_rows335']:check('native evidence group never supplied by private vector '+row['id'],row['status']=='required-native-evidence-not-captured'and all(value is None for key,value in row.items()if key.startswith('actual_')))
registry=ledger['accepted_artifact_registry349_356'];chain=ledger['accepted_checkpoint_chain348_356']
check('accepted349-356 exact72 distinct source bindings',len(registry)==72 and len({row['path']for row in registry})==72 and [row['step']for row in registry]==[n for n in range(349,357)for _ in range(9)])
for row in registry:check('accepted comparator artifact unchanged '+row['path'],row['scope']=='accepted-repository-artifact-not-native-implementation'and sha(history[row['path']])==row['sha256'])
check('complete original348-356 confirmation chain ordered',[row['step']for row in chain]==list(range(348,357)))
for row in chain:
 bindings=[row['confirmation'],row['receipt']]
 for b in bindings:check('chain input hash '+str(row['step'])+'/'+Path(b['path']).name,sha((root/b['path']).read_bytes())==b['sha256'])
 conf=json.loads((root/row['confirmation']['path']).read_text());rec=json.loads((root/row['receipt']['path']).read_text());original=rec['text'].encode();lines=rec['text'].splitlines();reported=conf['commit_prefix'];message=conf['exact_commit_message'];summary='Result: '+row['acceptance_result'];count=int(row['acceptance_result'].split('(')[1].split()[0])
 check('complete accepted original receipt facts '+str(row['step']),conf['step']==row['step']and conf['commit_prefix']==row['commit_prefix']and conf['commit_full']is row['commit_full']is None and conf['acceptance_result']==row['acceptance_result']and sha(original)==row['raw_receipt_sha256']==rec['original_display_sha256']==conf['evidence_sha256']and len(original)==row['raw_receipt_size_bytes']==rec['original_display_size_bytes']==conf['evidence_size_bytes']and len([v for v in lines if v.startswith('PASS: ')])==count and lines.count(summary)==1 and '[main '+reported+'] '+message in lines and lines[-3:-1]==[reported+' (HEAD -> main, origin/main, origin/HEAD) '+message]*2 and row['complete_user_return_accepted']is True and all(conf[key]is True for key in ['user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','complete_ordered_return_matches_prepared_and_installed']))
for row in ledger['stage_reconciliation349_356']:check('repository progress does not resolve native stage '+str(row['step']),row['step']in range(349,357)and row['artifact_bindings']==[v for v in registry if v['step']==row['step']]and row['confirmation']==next(v for v in chain if v['step']==row['step'])and row['native_state']=='required-not-selected-refined-or-proven'and row['actual_independent_evidence']is None and row['actual_live_bindings']is None and row['runtime_authority']is False and row['native_cases_run']==row['native_proofs_added']==0)
check('all nine scoped pause conditions exact never globally asserted',ledger['original_pause_conditions']==retained['original_pause_conditions']==original_freeze['original_pause_conditions'])
check('repository reconciliation source conflicts absent native refinement false',ledger['repository_reconciliation_complete']is True and ledger['repository_reconciliation_is_native_refinement']is False and ledger['repository_source_conflicts_found']==[] and ledger['counts']==retained['counts']==original_freeze['counts'])
for document in [contract,ledger,source_map]:check('reconciliation documents no native promotion '+str(document['scope']),document['native_cases_run']==document['native_proofs_added']==0 and document['runtime_authority']is False)
check('actual native selections null host remains unobserved',all(contract[key]is None for key in ['actual_expected_vector_artifacts','actual_expectation_author','actual_independent_collector','actual_independent_verifier','actual_native_fault_injector','actual_native_graph','actual_live_bindings'])and contract['actual_host_state']==ledger['actual_host_state']=='unobserved-not-claimed-absent')
check('no operational completion actual closure or authority inferred',all(ledger[key]is False for key in ['actual_native_refinement_complete','actual_operational_implementation_frozen','actual_independent_oracle_selected','actual_dynamic_graph_complete','phase2_open','phase1_matrix_complete','kernel_package_edge_complete','strong_safe_pause'])and ledger['production_entry_closed']is True)
check('no native dispatch cleanup refresh or historical authority reuse',all(contract[key]is False for key in ['new_runtime_work_authorized','new_batch_machine_cleanup_required','new_batch_controller_cleanup_required','historical_binding_or_authority_reuse_allowed','later_current_refresh_invalidates_repository_only_pause']))
with tempfile.TemporaryDirectory(prefix='step357-exact-accepted356-')as directory:
 historical=Path(directory)
 for rel,data in history.items():p=historical/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
 result=subprocess.run(['bash',str(historical/'tests/reference'/('test-'+oldbase+'-harness.sh'))],capture_output=True,text=True)
 if result.returncode:raise AssertionError('unchanged356 acceptance failed: '+result.stderr[-3000:])
 check('full unchanged356530 passes on exact1791 snapshot',result.stdout.splitlines().count('Result: PASS (530 passes, 0 failures)')==1)
 check('all530 unchanged predecessor labels match complete user return',[x for x in result.stdout.splitlines()if x.startswith('PASS: ')]==policy['expected_predecessor_labels'])
check('prepared357 preserves348 pause and conditional gate for358',contract['strong_safe_pause']is False and contract['last_confirmed_strong_safe_pause_step']==348 and contract['current_user_acceptance_pending']is True and contract['user_step357_checkpoint_confirmed']is False and contract['next_stage_after_complete357_acceptance']==358 and ledger['current_user_acceptance_pending']is True)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
