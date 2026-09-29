#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review'
prev_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review.sh"
prev_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review-probe.sh"
prev_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review.md"
prev_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review.tsv"
v4_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh"

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review.sh --output-dir DIR

Consume and freeze the successful step-265 read-only observation and review the exact
single-use local-source-v4 build authorization boundary. This helper does not authorize
or perform builder transport/execution, Slackpkg refresh, package/network/boot actions,
cleanup, reboot, or persistent configuration changes.
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

require_hash "$prev_helper" 'bf6fdad0eca2444c8be535eaaf8cd8aaeca54a548c10425fbccc363d3af9a52f' 'accepted step-265 helper'
require_hash "$prev_probe" '16ff1bc70e72a1fe363747f29db627d0cb76835ec265340771a23237cebe57fd' 'accepted step-265 probe'
require_hash "$prev_doc" 'b6a5892659c84f64a209edb750bc6c33e7aaf5ba2af5aee16691049a6bf7f3ec' 'accepted step-265 document'
require_hash "$prev_harness" '9e020da7b2a921478d915fb73c4b93bf40f071b16066dd70768da1b0e71d4566' 'accepted step-265 harness'
require_hash "$prev_policy" 'e1f76e643cd3bf2784f5038acdc01961290b724e3574a98d8ae951e59b480daf' 'accepted step-265 policy'
require_hash "$prev_record" '4ccfe17c7a6236d1bc4ad92d64015fd3bcaafd1bca1aceb931c5a417c7eeca55' 'accepted step-265 record'
require_hash "$v4_builder" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' 'frozen local-source-v4 builder'

helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import copy,json,pathlib,sys
prev_policy_path,prev_record_path,out_policy_path,out_record_path,helper_sha=sys.argv[1:]
p265=json.load(open(prev_policy_path,encoding='utf-8'))
r265={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); r265[k]=v
assert p265['step']==265 and p265['review_status']=='PASS'
assert p265['frozen_v4_builder']['sha256']=='38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'
assert p265['revalidation_probe']['sha256']=='16ff1bc70e72a1fe363747f29db627d0cb76835ec265340771a23237cebe57fd'
assert p265['authorization']['target_observation_authorized'] is True
assert p265['authorization']['local_source_v4_builder_execution_authorized'] is False
assert r265['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review'

observation={"boot_action_performed": "no", "boot_artifacts_match_failed_v2_preflight": "yes", "builder_execution_performed": "no", "evidence_cleanup_performed": "no", "failed_v2_candidate_binding_absent": "yes", "failed_v2_evidence_preserved": "yes", "failed_v2_pkglist_sha256": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "failed_v2_pkglist_size_bytes": "0", "failed_v2_result_absent": "yes", "fresh_boot_id": "d34855ae-e039-4005-a842-1bef51082195", "frozen_v4_builder_sha256": "38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7", "geninitrd_policy_matches_failed_v2_preflight": "yes", "header_package_record": "kernel-headers-6.18.45-x86-1", "hostname_fqdn": "vbox-slackcurrent.vbox-slackcurrent.org", "kernel_generic_record": "kernel-generic-6.18.45-x86_64-1", "kernel_huge_absent": "yes", "kernel_modules_absent": "yes", "local_source_v3_tree_manifest_sha256": "8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b", "local_source_v3_tree_verified": "yes", "local_source_v4_build_performed": "no", "local_source_v4_root_absent": "yes", "local_source_v4_temporary_build_roots_absent": "yes", "local_source_v4_tree_manifest_absent": "yes", "local_source_v4_tree_manifest_sidecar_absent": "yes", "network_access_performed": "no", "package_action_performed": "no", "package_database_manifest_sha256": "726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6", "persistent_configuration_change_performed": "no", "predecessor_installed_record_absent": "yes", "prior_runtime_binding_reused": "no", "probe_sha256": "16ff1bc70e72a1fe363747f29db627d0cb76835ec265340771a23237cebe57fd", "reboot_performed": "no", "slackpkg_conf_sha256": "f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4", "slackpkg_mirrors_sha256": "71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12", "slackpkg_refresh_performed": "no", "slackpkg_state_matches_failed_v2_preflight": "yes", "slackware_version": "Slackware 15.0+", "staged_target_sha256": "c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c", "uname_machine": "x86_64", "uname_release": "6.18.45", "v4_fresh_target_and_output_absence_revalidation_status": "PASS"}
assert observation['v4_fresh_target_and_output_absence_revalidation_status']=='PASS'
assert observation['prior_runtime_binding_reused']=='no'
assert observation['fresh_boot_id']=='d34855ae-e039-4005-a842-1bef51082195'
assert observation['hostname_fqdn']=='vbox-slackcurrent.vbox-slackcurrent.org'
assert observation['package_database_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
assert observation['header_package_record']=='kernel-headers-6.18.45-x86-1'
assert observation['predecessor_installed_record_absent']=='yes'
assert observation['staged_target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert observation['local_source_v3_tree_verified']=='yes'
assert observation['local_source_v3_tree_manifest_sha256']=='8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'
assert observation['failed_v2_evidence_preserved']=='yes'
assert observation['failed_v2_pkglist_size_bytes']=='0'
assert observation['failed_v2_pkglist_sha256']=='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'
for key in ('failed_v2_candidate_binding_absent','failed_v2_result_absent','boot_artifacts_match_failed_v2_preflight','slackpkg_state_matches_failed_v2_preflight','geninitrd_policy_matches_failed_v2_preflight','local_source_v4_root_absent','local_source_v4_tree_manifest_absent','local_source_v4_tree_manifest_sidecar_absent','local_source_v4_temporary_build_roots_absent'):
    assert observation[key]=='yes'
for key in ('builder_execution_performed','local_source_v4_build_performed','slackpkg_refresh_performed','package_action_performed','network_access_performed','boot_action_performed','reboot_performed','persistent_configuration_change_performed','evidence_cleanup_performed'):
    assert observation[key]=='no'
assert observation['frozen_v4_builder_sha256']=='38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'
assert observation['probe_sha256']=='16ff1bc70e72a1fe363747f29db627d0cb76835ec265340771a23237cebe57fd'

policy={
 'schema':1,'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review','step':266,'review_only':True,'review_status':'PASS',
 'accepted_step_265':{'helper_sha256':'bf6fdad0eca2444c8be535eaaf8cd8aaeca54a548c10425fbccc363d3af9a52f','probe_sha256':'16ff1bc70e72a1fe363747f29db627d0cb76835ec265340771a23237cebe57fd','document_sha256':'b6a5892659c84f64a209edb750bc6c33e7aaf5ba2af5aee16691049a6bf7f3ec','harness_sha256':'9e020da7b2a921478d915fb73c4b93bf40f071b16066dd70768da1b0e71d4566','policy_sha256':'e1f76e643cd3bf2784f5038acdc01961290b724e3574a98d8ae951e59b480daf','record_sha256':'4ccfe17c7a6236d1bc4ad92d64015fd3bcaafd1bca1aceb931c5a417c7eeca55'},
 'consumed_revalidation_observation':observation,
 'revalidation_state':'consumed-and-frozen-for-build-authorization-review',
 'fresh_target_binding':{
   'fresh_boot_id':observation['fresh_boot_id'],'hostname_fqdn':observation['hostname_fqdn'],'uname_machine':observation['uname_machine'],'uname_release':observation['uname_release'],'slackware_version':observation['slackware_version'],
   'package_database_manifest_sha256':observation['package_database_manifest_sha256'],'header_package_record':observation['header_package_record'],'kernel_generic_record':observation['kernel_generic_record'],
   'slackpkg_conf_sha256':observation['slackpkg_conf_sha256'],'slackpkg_mirrors_sha256':observation['slackpkg_mirrors_sha256'],'staged_target_sha256':observation['staged_target_sha256'],
   'local_source_v3_tree_manifest_sha256':observation['local_source_v3_tree_manifest_sha256'],'prior_runtime_binding_reused':False,
 },
 'frozen_v4_builder':{'path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh','sha256':'38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7','state':'implementation-frozen-not-executed'},
 'reviewed_single_build_authorization':{
   'state':'reviewed-not-authorized','authorization_use_count':1,'authorization_bound_boot_id':observation['fresh_boot_id'],'same_boot_required_at_execution':True,
   'authorization_invalid_if_target_state_changes_before_execution':True,
   'builder_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh','builder_sha256':'38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7',
   'builder_transport':'copy-exact-frozen-builder-only','controller_must_verify_builder_sha256_before_execution':True,
   'execution':'root-via-sudo','acknowledgement':'--build-local-source-v4',
   'expected_final_root':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4',
   'expected_tree_manifest':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256',
   'expected_tree_manifest_sha256_sidecar':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256.sha256',
   'final_outputs_must_still_be_absent_immediately_before_execution':True,'temporary_build_roots_must_still_be_absent_immediately_before_execution':True,
   'accepted_local_source_v3_must_remain_immutable':True,'failed_v2_evidence_must_remain_immutable':True,
   'builder_output_must_report_local_source_v4_build_status_PASS':True,'builder_output_must_be_returned_for_result_review':True,'builder_must_self_verify_tree_before_success':True,
   'no_second_execution_authorized':True,'slackpkg_refresh_allowed':False,'repository_refresh_allowed':False,'network_access_allowed':False,'package_mutation_allowed':False,'persistent_configuration_change_allowed':False,'boot_mutation_allowed':False,'reboot_allowed':False,'evidence_cleanup_allowed':False,
 },
 'authorization':{
   'build_authorization_freeze_review_authorized':True,
   'local_source_v4_builder_transport_authorized':False,'local_source_v4_builder_execution_authorized':False,'local_source_v4_build_authorized':False,
   'target_observation_authorized':False,'probe_transport_copy_authorized':False,'slackpkg_refresh_authorized':False,'repository_refresh_authorized':False,'package_action_authorized':False,'network_access_authorized':False,'persistent_configuration_change_authorized':False,'boot_action_authorized':False,'reboot_authorized':False,'evidence_cleanup_authorized':False,'runtime_rerun_authorized':False,'phase_2_start_authorized':False,
 },
 'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review.sh','helper_sha256':helper_sha,
 'machine_action_required':False,'controller_action_required':False,'future_work_requires_explicit_authorization':True,
 'pause_safe':False,'strong_safe_pause':False,
 'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze',
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','266'),('review_status','PASS'),('revalidation_state',policy['revalidation_state']),('fresh_boot_id',observation['fresh_boot_id']),
 ('package_database_manifest_sha256',observation['package_database_manifest_sha256']),('staged_target_sha256',observation['staged_target_sha256']),('local_source_v3_tree_manifest_sha256',observation['local_source_v3_tree_manifest_sha256']),
 ('failed_v2_pkglist_sha256',observation['failed_v2_pkglist_sha256']),('frozen_v4_builder_sha256',policy['frozen_v4_builder']['sha256']),
 ('single_build_authorization_state','reviewed-not-authorized'),('single_build_authorization_use_count','1'),('authorization_bound_boot_id',observation['fresh_boot_id']),
 ('v4_builder_transport_authorized','no'),('v4_builder_execution_authorized','no'),('v4_build_authorized','no'),('slackpkg_refresh_authorized','no'),('package_action_authorized','no'),('network_access_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),
 ('machine_action_required','no'),('controller_action_required','no'),('strong_safe_pause','no'),('next_stage',policy['next_stage'])]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN

printf 'v4_revalidation_freeze_and_build_authorization_review_status\tPASS\n'
printf 'fresh_boot_id\td34855ae-e039-4005-a842-1bef51082195\n'
printf 'single_build_authorization_state\treviewed-not-authorized\n'
printf 'v4_builder_execution_authorized\tno\n'
printf 'v4_build_authorized\tno\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze\n'
