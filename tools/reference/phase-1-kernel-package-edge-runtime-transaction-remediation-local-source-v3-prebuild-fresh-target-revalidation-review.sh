#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze'
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh"
probe="$repo_root/tools/reference/${base}-probe.sh"
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
usage() { cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review.sh --output-dir DIR

Generate the repository-side step-247 policy and record that authorize one exact read-only
prebuild local-source-v3 target/baseline revalidation probe. This helper itself performs no
target observation, builder transport/execution, package, Slackpkg, network, boot, or reboot action.
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
require_hash "$builder" '56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582' 'frozen local-source-v3 builder'
require_hash "$probe" '7872bbcad0c21515273451a919deaeba9e1a84d8ad79a03160bbc1f822827949' 'step-247 read-only probe'
require_hash "$prev_helper" '8fd3a7268c7fa2ea5b55a2dc1d154b7340ac673458513105b617aa78bccb597c' 'accepted step-246 helper'
require_hash "$prev_doc" '8673e5fb07a728ed8e65b9253d2e33d031f6a0dd9051d950b696fd421a1630f5' 'accepted step-246 document'
require_hash "$prev_harness" 'cbec46f7d355251dd4b3862258274ebef8ff6456088d3b6af9fc295f0f34707d' 'accepted step-246 harness'
require_hash "$prev_policy" 'cf32f3d6b5df64d176c154e506c356c53e63da794c961edbbcbf1557ecef25f0' 'accepted step-246 policy'
require_hash "$prev_record" '2f55b4a83a498fdf1c347ba2f35c25b5b0a3a87233f3df66f2362cfa12491071' 'accepted step-246 record'
helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import copy,json,pathlib,sys
prev_policy_path,prev_record_path,out_policy_path,out_record_path,helper_sha=sys.argv[1:]
p246=json.load(open(prev_policy_path,encoding='utf-8'))
record={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); record[k]=v
assert p246['step']==246 and p246['freeze_status']=='PASS'
assert p246['local_source_v3_builder_implementation']['state']=='implemented-frozen-not-executed'
assert p246['local_source_v3_builder_implementation']['builder_sha256']=='56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'
assert p246['authorization']['repository_prebuild_fresh_target_revalidation_review_authorized'] is True
assert p246['authorization']['target_observation_authorized'] is False
assert record['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review'
policy={
 'schema':1,
 'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review',
 'step':247,
 'review_only':True,
 'review_status':'PASS',
 'accepted_step_246':{
   'helper_sha256':'8fd3a7268c7fa2ea5b55a2dc1d154b7340ac673458513105b617aa78bccb597c',
   'document_sha256':'8673e5fb07a728ed8e65b9253d2e33d031f6a0dd9051d950b696fd421a1630f5',
   'harness_sha256':'cbec46f7d355251dd4b3862258274ebef8ff6456088d3b6af9fc295f0f34707d',
   'policy_sha256':'cf32f3d6b5df64d176c154e506c356c53e63da794c961edbbcbf1557ecef25f0',
   'record_sha256':'2f55b4a83a498fdf1c347ba2f35c25b5b0a3a87233f3df66f2362cfa12491071',
   'builder_sha256':'56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582',
 },
 'historical_preservation':copy.deepcopy(p246['historical_preservation']),
 'local_source_v3_builder_implementation':copy.deepcopy(p246['local_source_v3_builder_implementation']),
 'future_executor_v2_contract':copy.deepcopy(p246['future_executor_v2_contract']),
 'prebuild_v3_fresh_target_revalidation':{
   'state':'read-only-observation-authorized',
   'probe_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review-probe.sh',
   'probe_sha256':'7872bbcad0c21515273451a919deaeba9e1a84d8ad79a03160bbc1f822827949',
   'probe_execution':'root-via-sudo',
   'acknowledgement':'--observe-prebuild-v3-fresh-target-revalidation',
   'probe_scope':'standalone-read-only-restored-baseline-v2-evidence-staged-target-and-v3-absence-revalidation',
   'fresh_boot_id_required':True,
   'prior_runtime_binding_reusable':False,
   'package_database_manifest_must_match_restored_baseline':True,
   'slackpkg_configuration_must_match_restored_baseline':True,
   'local_source_v2_tree_verification_required':True,
   'local_source_v2_historical_no_PGP_state_must_be_preserved':True,
   'staged_target_verification_required':True,
   'failed_remediation_evidence_presence_required':True,
   'failed_remediation_pkglist_must_remain_absent':True,
   'failed_remediation_human_error_must_remain_preserved':True,
   'failed_success_result_must_remain_absent':True,
   'published_success_evidence_must_remain_absent':True,
   'boot_artifacts_must_match_failed_remediation_preflight':True,
   'slackpkg_state_must_match_failed_remediation_preflight':True,
   'geninitrd_policy_must_match_failed_remediation_preflight':True,
   'local_source_v3_final_outputs_must_be_absent':True,
   'local_source_v3_temporary_build_roots_must_be_absent':True,
   'frozen_builder_sha256':'56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582',
   'builder_must_not_be_transported_by_probe':True,
   'builder_must_not_be_executed_by_probe':True,
   'future_executor_v2_must_remain_unimplemented':True,
   'observation_output_must_be_returned_for_step_248':True,
   'repository_refresh_allowed':False,
   'network_access_allowed':False,
   'package_mutation_allowed':False,
   'slackpkg_mutation_allowed':False,
   'boot_mutation_allowed':False,
   'persistent_configuration_change_allowed':False,
   'reboot_allowed':False,
 },
 'authorization':{
   'repository_prebuild_fresh_target_revalidation_review_authorized':False,
   'target_observation_authorized':True,
   'probe_transport_copy_authorized':True,
   'prebuild_v3_revalidation_freeze_and_build_authorization_review_authorized_after_successful_observation':True,
   'local_source_v3_builder_transport_authorized':False,
   'local_source_v3_builder_execution_authorized':False,
   'local_source_v3_build_authorized':False,
   'runtime_executor_v2_implementation_authorized':False,
   'runtime_executor_v2_transport_authorized':False,
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
 'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review.sh',
 'helper_sha256':helper_sha,
 'machine_action_required':True,
 'machine_action_type':'read-only-prebuild-v3-fresh-target-revalidation-observation',
 'controller_action_required':True,
 'controller_action_type':'copy-exact-step-247-probe-to-target-and-verify-sha256',
 'future_work_requires_explicit_authorization':True,
 'pause_safe':False,
 'strong_safe_pause':False,
 'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review',
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','247'),('review_status','PASS'),('accepted_step_246_builder_sha256','56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'),
 ('builder_implementation_state','implemented-frozen-not-executed'),('builder_sha256','56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582'),
 ('prebuild_v3_fresh_target_revalidation_state','read-only-observation-authorized'),('probe_execution','root-via-sudo'),
 ('runtime_acknowledgement','--observe-prebuild-v3-fresh-target-revalidation'),('prebuild_v3_revalidation_probe_sha256','7872bbcad0c21515273451a919deaeba9e1a84d8ad79a03160bbc1f822827949'),
 ('fresh_boot_id_required','yes'),('prior_runtime_binding_reusable','no'),
 ('local_source_v2_must_be_preserved_unchanged','yes'),('failed_remediation_evidence_must_be_preserved_unchanged','yes'),('staged_target_must_be_preserved_unchanged','yes'),
 ('local_source_v3_final_outputs_must_be_absent','yes'),('local_source_v3_temporary_build_roots_must_be_absent','yes'),
 ('future_executor_v2_state','reviewed-frozen-not-implemented'),('target_observation_authorized','yes'),('probe_transport_copy_authorized','yes'),
 ('local_source_v3_builder_transport_authorized','no'),('local_source_v3_builder_execution_authorized','no'),('local_source_v3_build_authorized','no'),
 ('runtime_executor_v2_implementation_authorized','no'),('runtime_rerun_authorized','no'),('package_action_authorized','no'),('slackpkg_mutation_authorized','no'),
 ('repository_refresh_authorized','no'),('network_access_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),('evidence_cleanup_authorized','no'),
 ('phase_2_start_authorized','no'),('machine_action_required','yes'),('machine_action_type','read-only-prebuild-v3-fresh-target-revalidation-observation'),
 ('controller_action_required','yes'),('controller_action_type','copy-exact-step-247-probe-to-target-and-verify-sha256'),('pause_safe','no'),
 ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review')]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN
