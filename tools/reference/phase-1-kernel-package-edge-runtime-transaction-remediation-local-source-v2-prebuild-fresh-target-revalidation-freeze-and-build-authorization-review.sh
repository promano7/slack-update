#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review'
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh"
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review-probe.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
usage() { cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review.sh --output-dir DIR

Generate the repository-side step-229 policy and record that consume the successful
step-228 read-only observation and authorize one exact local-source-v2 builder transport
and one exact builder execution. This helper itself performs no target, package, Slackpkg,
network, boot, reboot, or local-source build action.
USAGE
}
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
regular() { [[ -f $1 && ! -L $1 ]]; }
require_hash() { local path=$1 expected=$2 label=$3 actual; regular "$path" || fail "$label is missing or unsafe: $path"; actual=$(sha "$path"); [[ $actual == "$expected" ]] || fail "$label SHA-256 mismatch: $actual"; }
[[ ${1:-} == '--help' ]] && { usage; exit 0; }
[[ $# -eq 2 && $1 == '--output-dir' ]] || { usage >&2; exit 2; }
out_dir=$2
[[ -d $out_dir && ! -L $out_dir ]] || fail 'output directory must already exist and must not be a symlink'
require_hash "$builder" '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d' 'frozen v2 builder'
require_hash "$prev_helper" '1f3bfde8aaa93dd36e6438c7e6c4397b427fa50f03e1d5e1b98b3c1f3886b7a0' 'accepted step-228 helper'
require_hash "$prev_probe" '207ce41439c6ce2fe0f98a40266528bed4178073d5bab781d19b6d938bc64984' 'accepted step-228 probe'
require_hash "$prev_doc" '09b1d2f0baff2de6b97229536c72e6fa817c8a919e6ae8d584e8fa3022d0a413' 'accepted step-228 document'
require_hash "$prev_harness" 'c7913ba7052c9807dd1987cc6051e46db933c01b2227faa7e02b3e51797e8ffa' 'accepted step-228 harness'
require_hash "$prev_policy" 'a9eb0db7a4f6e003d66d2e7c1005483e1de827a5c44f98d5aae47b71b32db283' 'accepted step-228 policy'
require_hash "$prev_record" 'c3f9e70ee0d0136bbd43216e657052c92b6f3eeee612472916d0403e4182ff44' 'accepted step-228 record'
helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import copy,json,pathlib,sys
prev_policy_path,prev_record_path,out_policy_path,out_record_path,helper_sha=sys.argv[1:]
p228=json.load(open(prev_policy_path,encoding='utf-8'))
record={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); record[k]=v
assert p228['step']==228 and p228['review_status']=='PASS'
assert p228['authorization']['target_observation_authorized'] is True
assert p228['authorization']['local_source_v2_builder_execution_authorized'] is False
assert p228['builder_implementation']['builder_sha256']=='8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert record['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review'
observation={"boot_action_performed": "no", "boot_artifacts_match_failed_preflight": "yes", "builder_execution_performed": "no", "builder_transport_performed": "no", "candidate_set_bound": "no", "failed_evidence_root_present": "yes", "failed_success_result_absent": "yes", "fresh_boot_id": "cd975bdc-a133-47d1-9e92-e9b51bef9d99", "frozen_builder_sha256": "8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d", "geninitrd_policy_matches_failed_preflight": "yes", "header_package_record": "kernel-headers-6.18.45-x86-1", "hostname_fqdn": "vbox-slackcurrent.vbox-slackcurrent.org", "kernel_generic_record": "kernel-generic-6.18.45-x86_64-1", "kernel_huge_absent": "yes", "kernel_modules_absent": "yes", "local_source_v1_tree_manifest_sha256": "0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e", "local_source_v1_tree_verified": "yes", "local_source_v2_build_performed": "no", "local_source_v2_final_outputs_absent": "yes", "local_source_v2_temporary_build_roots_absent": "yes", "network_access_performed": "no", "package_action_performed": "no", "package_database_manifest_sha256": "726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6", "persistent_configuration_change_performed": "no", "prebuild_revalidation_status": "PASS", "prior_runtime_binding_reused": "no", "published_success_evidence_absent": "yes", "reboot_performed": "no", "repository_refresh_performed": "no", "slackpkg_conf_sha256": "f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4", "slackpkg_mirrors_sha256": "71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12", "slackpkg_mutation_performed": "no", "slackpkg_state_matches_failed_preflight": "yes", "slackware_version": "Slackware 15.0+", "staged_target_sha256": "c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c", "uname_machine": "x86_64", "uname_release": "6.18.45"}
assert observation['prebuild_revalidation_status']=='PASS'
assert observation['frozen_builder_sha256']=='8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert observation['package_database_manifest_sha256']==p228['historical_frozen_runtime_identity']['package_database_manifest_sha256']
assert observation['staged_target_sha256']==p228['preservation_contract']['staged_target_sha256']
assert observation['local_source_v1_tree_manifest_sha256']==p228['preservation_contract']['local_source_v1_tree_manifest_sha256']
for k in ('local_source_v2_final_outputs_absent','local_source_v2_temporary_build_roots_absent','boot_artifacts_match_failed_preflight','slackpkg_state_matches_failed_preflight','geninitrd_policy_matches_failed_preflight'):
    assert observation[k]=='yes'
policy={
 'schema':1,'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review','step':229,'review_only':True,'review_status':'PASS',
 'accepted_step_228':{'builder_sha256':'8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d','helper_sha256':'1f3bfde8aaa93dd36e6438c7e6c4397b427fa50f03e1d5e1b98b3c1f3886b7a0','probe_sha256':'207ce41439c6ce2fe0f98a40266528bed4178073d5bab781d19b6d938bc64984','document_sha256':'09b1d2f0baff2de6b97229536c72e6fa817c8a919e6ae8d584e8fa3022d0a413','harness_sha256':'c7913ba7052c9807dd1987cc6051e46db933c01b2227faa7e02b3e51797e8ffa','policy_sha256':'a9eb0db7a4f6e003d66d2e7c1005483e1de827a5c44f98d5aae47b71b32db283','record_sha256':'c3f9e70ee0d0136bbd43216e657052c92b6f3eeee612472916d0403e4182ff44'},
 'consumed_prebuild_observation':observation,
 'prebuild_observation_state':'consumed-and-frozen-for-single-build-authorization',
 'preservation_contract':copy.deepcopy(p228['preservation_contract']),
 'local_source_v2_design':copy.deepcopy(p228['local_source_v2_design']),
 'builder_implementation':copy.deepcopy(p228['builder_implementation']),
 'future_refresh_acceptance_contract':copy.deepcopy(p228['future_refresh_acceptance_contract']),
 'single_build_authorization':{
   'state':'authorized-not-executed',
   'authorization_use_count':1,
   'authorization_bound_boot_id':observation['fresh_boot_id'],
   'same_boot_required_at_execution':True,
   'authorization_invalid_if_target_state_changes_before_execution':True,
   'builder_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh',
   'builder_sha256':'8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d',
   'builder_transport':'copy-exact-frozen-builder-only',
   'controller_must_verify_builder_sha256_before_execution':True,
   'execution':'root-via-sudo',
   'acknowledgement':'--build-local-source-v2',
   'expected_final_root':p228['builder_implementation']['local_source_v2_root'],
   'expected_tree_manifest':p228['builder_implementation']['tree_manifest'],
   'expected_tree_manifest_sha256_sidecar':p228['builder_implementation']['tree_manifest_sha256_sidecar'],
   'final_outputs_must_still_be_absent_immediately_before_execution':True,
   'temporary_build_roots_must_still_be_absent_immediately_before_execution':True,
   'builder_output_must_report_local_source_v2_build_status_PASS':True,
   'builder_output_must_be_returned_for_step_230_review':True,
   'builder_must_self_verify_tree_before_success':True,
   'no_second_execution_authorized':True,
   'repository_refresh_allowed':False,
   'network_access_allowed':False,
   'package_mutation_allowed':False,
   'slackpkg_mutation_allowed':False,
   'boot_mutation_allowed':False,
   'persistent_configuration_change_allowed':False,
   'reboot_allowed':False,
 },
 'authorization':{
   'target_observation_authorized':False,
   'probe_transport_copy_authorized':False,
   'local_source_v2_builder_transport_authorized':True,
   'local_source_v2_builder_execution_authorized':True,
   'local_source_v2_build_authorized':True,
   'local_source_v2_build_result_review_authorized_after_successful_build':True,
   'runtime_candidate_binding_authorized':False,
   'runtime_executor_remediation_authorized':False,
   'runtime_rerun_authorized':False,
   'package_action_authorized':False,
   'slackpkg_mutation_authorized':False,
   'repository_refresh_authorized':False,
   'network_access_authorized':False,
   'boot_action_authorized':False,
   'reboot_authorized':False,
   'persistent_configuration_change_authorized':False,
   'evidence_cleanup_authorized':False,
   'phase_2_start_authorized':False,
 },
 'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review.sh','helper_sha256':helper_sha,
 'machine_action_required':True,'machine_action_type':'single-local-source-v2-builder-execution',
 'controller_action_required':True,'controller_action_type':'copy-exact-frozen-builder-verify-sha256-and-run-once',
 'future_work_requires_explicit_authorization':True,'pause_safe':False,'strong_safe_pause':False,
 'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause',
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','229'),('review_status','PASS'),('prebuild_observation_state',policy['prebuild_observation_state']),
 ('fresh_boot_id',observation['fresh_boot_id']),('package_database_manifest_sha256',observation['package_database_manifest_sha256']),
 ('staged_target_sha256',observation['staged_target_sha256']),('local_source_v1_tree_manifest_sha256',observation['local_source_v1_tree_manifest_sha256']),
 ('local_source_v2_final_outputs_absent_at_authorization','yes'),('local_source_v2_temporary_build_roots_absent_at_authorization','yes'),
 ('builder_sha256','8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'),('builder_execution_acknowledgement','--build-local-source-v2'),('authorization_use_count','1'),
 ('same_boot_required_at_execution','yes'),('target_observation_authorized','no'),('probe_transport_copy_authorized','no'),
 ('local_source_v2_builder_transport_authorized','yes'),('local_source_v2_builder_execution_authorized','yes'),('local_source_v2_build_authorized','yes'),
 ('local_source_v2_build_result_review_authorized_after_successful_build','yes'),
 ('runtime_candidate_binding_authorized','no'),('runtime_executor_remediation_authorized','no'),('runtime_rerun_authorized','no'),
 ('package_action_authorized','no'),('slackpkg_mutation_authorized','no'),('repository_refresh_authorized','no'),('network_access_authorized','no'),
 ('boot_action_authorized','no'),('reboot_authorized','no'),('evidence_cleanup_authorized','no'),('phase_2_start_authorized','no'),
 ('machine_action_required','yes'),('machine_action_type','single-local-source-v2-builder-execution'),
 ('controller_action_required','yes'),('controller_action_type','copy-exact-frozen-builder-verify-sha256-and-run-once'),
 ('future_work_requires_explicit_authorization','yes'),('pause_safe','no'),
 ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause')]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN
