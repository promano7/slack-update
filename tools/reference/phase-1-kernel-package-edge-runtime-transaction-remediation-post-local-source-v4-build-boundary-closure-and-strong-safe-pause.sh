#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then printf 'Usage: %s --output-dir DIR\nRepository-only authority/effect closure; no runtime or target action.\n' "${0##*/}"; exit 0; fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYFREEZE'
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys
def validate_pause_closure(closure, accepted):
 def exact(actual, expected, label):
  if json.dumps(actual,sort_keys=True,separators=(',',':')) != json.dumps(expected,sort_keys=True,separators=(',',':')):raise ValueError(label)
 statuses={'schema':1,'step':298,'state':'all-authority-and-effect-obligations-closed-strong-pause-eligible-user-checkpoint-pending','scope':'completed-post-v4-build-revalidation-and-runtime-boundary-workstream-not-project-acceptance','all_authority_closed':True,'all_operational_authority_closed':True,'repository_review_and_freeze_authority_consumed':True}
 for key,value in statuses.items():exact(closure.get(key),value,'closure status '+key)
 exact(closure.get('authorization'),{key:False for key in accepted['authorization']},'reopened or missing authority')
 observation=closure['observation'];result=accepted['revalidation_result'];prior=accepted['observation_authority_closure']
 observation_checks={'authority_id':prior['authority_id'],'reviewed_invocations':1,'execution_consumed':True,'remaining_transport_and_observation_revoked':True,'success_accepted':True,'probe_sha256':accepted['implementation']['probe_sha256'],'normalized_observation_sha256':result['observation_sha256'],'provenance_kind':result['provenance_kind'],'original_stream_bytes_claimed':False,'exit_status':0,'field_count':50,'nine_no_effect_fields':result['no_effect_fields'],'all_nine_no_effect_values_no':True,'boot_id':result['fresh_boot_id'],'boot_id_scope':'historical-point-in-time-observation-not-current-or-continuous','prior_live_binding_state':'expired-at-workstream-closure','prior_live_binding_reusable':False,'current_boot_id':None,'current_boot_continuity_asserted':False,'retry_or_extra_probe_authorized':False}
 exact(observation,observation_checks,'observation binding or provenance drift')
 if not prior['all_operational_authority_closed'] or not prior['no_required_production_cleanup_identified'] or result['status']!='PASS' or result['probe_exit_status']!=0 or any(result['fixed_return_values'].get(key)!='no' for key in result['no_effect_fields']):raise ValueError('accepted effect boundary incomplete')
 for section in ['effects','preservation','runtime','pause','resume']:
  if not isinstance(closure.get(section),dict):raise ValueError('missing closure section '+section)
 effects_checks={'basis': 'complete-user-returned-no-effect-fields-and-reviewed-read-only-source-not-independent-post-return-host-inspection', 'read_only_source_and_complete_returned_result_reviewed': True, 'no_runtime_attempt_in_289_298': True, 'production_transaction_in_flight': False, 'unresolved_transaction': False, 'unreviewed_partial_publication': False, 'required_production_cleanup': False, 'required_controller_cleanup': False, 'pending_machine_obligations': [], 'pending_controller_obligations': [], 'controller_capture_role': 'completed-authorized-observation-capture-preserved-evidence-not-unfinished-transaction', 'controller_capture_preserved_no_cleanup_authorized': True, 'no_independent_post_return_host_inspection_claim': True, 'no_atime_sudo_audit_or_capture_byte_immutability_claim': True, 'historical_failed_v2_evidence_preserved_not_pending_transaction': True, 'historical_build_authority_consumed_and_revoked_at288': True}
 exact(closure['effects'],effects_checks,'effect or obligation drift')
 preservation=closure['preservation'];source=accepted['runtime_boundary_freeze']['source']
 preservation_checks={'repository_history_and_immutable_sources_bound': True, 'accepted_v4_manifest_sha256': 'a4b0fc122c6274c7fdf70907661511bcf6ba475a2aa3bc46b96e5bcbf6ed3db8', 'accepted_v4_sidecar_sha256': '7cd7b99c730f388ddc949d22ad5ed98da703ea8050dfa31dc11456683f2176fc', 'accepted_target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c', 'frozen_boundary_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze-boundary.json', 'frozen_boundary_sha256': '59907c7852b96de5be84f3358366971800d42ca2c8bd76ebb901738d12787931', 'source_and_evidence_guards_passed_at_returned_invocation': True, 'preservation_scope': 'accepted-repository-bytes-and-reviewed-observation-time-guards-not-current-or-continuous-host-state', 'source_builders_probes_executors_v2_v3_v4_evidence_preservation_required': True, 'source_edit_rebuild_chmod_overwrite_cleanup_authorized': False}
 preservation_checks=dict(preservation_checks,accepted_v4_manifest_sha256=source['manifest_sha256'],accepted_v4_sidecar_sha256=source['sidecar_sha256'],accepted_target_sha256=source['target_sha256'],frozen_boundary_path=accepted['runtime_boundary_freeze_path'])
 exact(preservation,preservation_checks,'source or preserved identity drift')
 runtime_checks={'v4_pkglist_generation_observed': False, 'current_pkglist_sha256': None, 'current_candidate_count': None, 'current_candidate_binding_created': False, 'future_executor_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor.sh', 'future_executor_sha256': None, 'future_executor_installed': False, 'historical_v2_executor_rerun_authorized': False, 'future_executor_implementation_transport_execution_authorized': False, 'phase1_matrix_complete': False, 'kernel_package_edge_complete': False, 'phase2_authorized': False}
 runtime_checks=dict(runtime_checks,future_executor_path=accepted['runtime_boundary_freeze']['executor']['future_executor_path'])
 exact(closure['runtime'],runtime_checks,'invented runtime or project acceptance')
 exact(closure['pause'],{'pause_safe': True, 'strong_safe_pause': True, 'eligibility_basis': 'complete-return-effect-review-frozen-boundary-and-closed-authority-not-preflight-alone', 'user_checkpoint_confirmation_required': True, 'user_step298_application_acceptance_commit_push_clean_tree_confirmed': False, 'prepared_snapshot_is_confirmed_user_checkpoint': False, 'machine_action_required': False, 'controller_action_required': False, 'pause_depends_on_current_boot_or_mirror': False, 'later_slackware_current_publication_invalidates_completed_checkpoint': False, 'later_publication_may_invalidate_live_state_for_future_work': True, 'completed_checkpoint_is_historical_and_stable': True, 'project_acceptance_complete': False},'premature confirmation or boot-dependent pause')
 exact(closure['resume'],{'automatic_next_step_opened': False, 'next_repository_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review', 'new_explicit_resume_planning_required': True, 'no_machine_authority_from_pause_or_roadmap': True, 'fresh_target_source_artifact_revalidation_before_any_future_machine_action': True, 'new_executor_detailed_design_implementation_review_and_freeze_required': True, 'new_single_attempt_machine_authorization_required': True, 'immediate_preflight_required': True, 'future_authorized_binding_requires_same_uninterrupted_boot': True, 'exact_same_transaction_target_only_pkglist_candidate_gate_required': True, 'old_uuid_executor_pkglist_or_authority_reuse_forbidden': True, 'preserved_v4_manifest_sidecar_target_must_verify_before_use': True, 'current_predecessor_availability_not_observed': True},'missing fresh resume gates or automatic authority')
 exact(sorted(closure),['all_authority_closed', 'all_operational_authority_closed', 'authorization', 'effects', 'observation', 'pause', 'preservation', 'repository_review_and_freeze_authority_consumed', 'resume', 'runtime', 'schema', 'scope', 'state', 'step'],'extra or missing closure fields')
 return True
root=Path(sys.argv[1]);out=Path(sys.argv[2]).absolute();base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze';own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause.md': '27177ec4720aaf1cad2e2dde91720edf4469ff226f6725f7c1a7ab204e48bf75', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause-policy.json': 'c033709d29dbced901c55faf33f9620e1ea52c9fa9ddb996cc9cd5577527ca1c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause.tsv': '55ae719ca25356182af33e4cd4007514fec864b958c7e812aa48a2dd6bb7dc81', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause-closure.json': '624c83e678102f92eb7859083c61a333015eca61a3676133a41ee709cdaf98f0'}
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
if not out.is_dir() or out.resolve()!=out:raise SystemExit('ERROR: unsafe output directory')
for rel,digest in own_hashes.items():
 p=root/rel
 if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or hashlib.sha256(p.read_bytes()).hexdigest()!=digest:raise SystemExit('ERROR: changed or unsafe freeze input: '+rel)
policy=json.loads((fixture/(base+'-policy.json')).read_text())
for rel,digest in policy['accepted_checkpoint']['sha256_bindings'].items():
 p=root/rel
 if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):raise SystemExit('ERROR: unsafe accepted input: '+rel)
 data=p.read_bytes()
 if rel=='CHANGELOG.md':
  marker=b'## Phase 1 step 297 ';position=data.find(marker)
  if position<0:raise SystemExit('ERROR: accepted CHANGELOG history missing')
  data=data[position:]
 if hashlib.sha256(data).hexdigest()!=digest:raise SystemExit('ERROR: accepted repository byte drift: '+rel)
suffixes=['-policy.json','.tsv','-closure.json']
for suffix in suffixes:
 p=out/(base+suffix)
 if p.exists() or p.is_symlink():raise SystemExit('ERROR: output already exists')
accepted=json.loads((fixture/(prior+'-policy.json')).read_text())
closure=json.loads((root/policy['boundary_closure_path']).read_text())
try:validate_pause_closure(closure,accepted)
except (ValueError,KeyError) as error:raise SystemExit('ERROR: '+str(error))
future=root/closure['runtime']['future_executor_path']
if future.exists() or future.is_symlink():raise SystemExit('ERROR: future executor must remain absent')
result=subprocess.run(['bash',str(root/'tests/reference'/('test-'+prior+'-harness.sh'))],capture_output=True,text=True)
if result.returncode or 'Result: PASS (308 passes, 0 failures)' not in result.stdout:raise SystemExit('ERROR: full accepted308 predecessor suite failed\n'+result.stdout+result.stderr)
for suffix in suffixes:(out/(base+suffix)).write_bytes((fixture/(base+suffix)).read_bytes())
print('step_298_boundary_closure_status\tPASS')
print('accepted_step297_revalidated\tPASS (308 passes, 0 failures)')
print('all_authority_closed\tyes')
print('all_operational_authority_closed\tyes')
print('live_binding_expired\tyes')
print('machine_action_required\tno')
print('controller_action_required\tno')
print('pause_safe\tyes')
print('strong_safe_pause\tyes')
print('strong_pause_scope\treviewed-closure-eligibility-user-checkpoint-pending')
print('user_step298_checkpoint_confirmed\tno')
print('automatic_next_step_opened\tno')
print('next_stage_not_authorized\tphase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review')
PYFREEZE
