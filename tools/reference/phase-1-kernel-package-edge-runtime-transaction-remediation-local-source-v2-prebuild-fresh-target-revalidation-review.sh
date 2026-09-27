#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-freeze'
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review-probe.sh"
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
usage() { cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review.sh --output-dir DIR

Generate the repository-side step-228 policy and record that authorize one exact read-only
prebuild target revalidation probe. This helper itself performs no target observation,
builder transport/execution, package, Slackpkg, network, boot, or reboot action.
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
require_hash "$probe" '207ce41439c6ce2fe0f98a40266528bed4178073d5bab781d19b6d938bc64984' 'step-228 read-only probe'
require_hash "$prev_helper" '0882eb6636170e7ffde474f0d3c11f90dbf8b2431a29b9fe062bafcac2dee425' 'accepted step-227 helper'
require_hash "$prev_doc" 'c62c652a2d91d0855f2ee619a8eca92468ded3fa5c2536a0abfccff38e533b12' 'accepted step-227 document'
require_hash "$prev_harness" '928e699dc3c0e953ba65d8bb1694c1071043bb4404835bb5bbf306ff17ee4995' 'accepted step-227 harness'
require_hash "$prev_policy" '79fcbc19be0de464ba41e02fbd4b7f4a66b15b34e41648df7a6763bb706149ad' 'accepted step-227 policy'
require_hash "$prev_record" 'c4fb4fce881ac6cf5254dd67399233a64361caf81b14638aa2d506d0edd073d4' 'accepted step-227 record'
helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import copy,json,pathlib,sys
prev_policy_path,prev_record_path,out_policy_path,out_record_path,helper_sha=sys.argv[1:]
p227=json.load(open(prev_policy_path,encoding='utf-8'))
record={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); record[k]=v
assert p227['step']==227 and p227['review_status']=='PASS'
assert p227['builder_implementation']['state']=='implemented-frozen-not-executed'
assert p227['builder_implementation']['builder_sha256']=='8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert p227['authorization']['repository_only_prebuild_fresh_target_revalidation_review_authorized'] is True
assert p227['authorization']['target_observation_authorized'] is False
assert record['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review'
policy={
 'schema':1,'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review','step':228,'review_only':True,'review_status':'PASS',
 'accepted_step_227':{'builder_sha256':'8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d','helper_sha256':'0882eb6636170e7ffde474f0d3c11f90dbf8b2431a29b9fe062bafcac2dee425','document_sha256':'c62c652a2d91d0855f2ee619a8eca92468ded3fa5c2536a0abfccff38e533b12','harness_sha256':'928e699dc3c0e953ba65d8bb1694c1071043bb4404835bb5bbf306ff17ee4995','policy_sha256':'79fcbc19be0de464ba41e02fbd4b7f4a66b15b34e41648df7a6763bb706149ad','record_sha256':'c4fb4fce881ac6cf5254dd67399233a64361caf81b14638aa2d506d0edd073d4'},
 'historical_frozen_runtime_identity':copy.deepcopy(p227['frozen_runtime_identity']),
 'preservation_contract':copy.deepcopy(p227['preservation_contract']),
 'local_source_v2_design':copy.deepcopy(p227['local_source_v2_design']),
 'builder_implementation':copy.deepcopy(p227['builder_implementation']),
 'future_refresh_acceptance_contract':copy.deepcopy(p227['future_refresh_acceptance_contract']),
 'prebuild_fresh_target_revalidation':{
   'state':'read-only-observation-authorized',
   'probe_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review-probe.sh',
   'probe_sha256':'207ce41439c6ce2fe0f98a40266528bed4178073d5bab781d19b6d938bc64984',
   'probe_execution':'root-via-sudo',
   'acknowledgement':'--observe-prebuild-fresh-target-revalidation',
   'probe_scope':'standalone-read-only-prebuild-target-v1-evidence-and-v2-absence-revalidation',
   'fresh_boot_id_required':True,
   'previous_frozen_boot_id_match_required':False,
   'previous_frozen_boot_id_must_not_be_used_as_binding':True,
   'package_database_manifest_must_match_frozen_baseline':True,
   'local_source_v1_tree_verification_required':True,
   'staged_target_verification_required':True,
   'failed_evidence_root_presence_required':True,
   'failed_success_result_must_remain_absent':True,
   'published_success_evidence_must_remain_absent':True,
   'boot_artifacts_must_match_failed_preflight':True,
   'slackpkg_state_must_match_failed_preflight':True,
   'geninitrd_policy_must_match_failed_preflight':True,
   'local_source_v2_final_outputs_must_be_absent':True,
   'local_source_v2_temporary_build_roots_must_be_absent':True,
   'frozen_builder_sha256':'8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d',
   'builder_must_not_be_transported_by_probe':True,
   'builder_must_not_be_executed_by_probe':True,
   'observation_output_must_be_returned_for_build_authorization':True,
   'repository_refresh_allowed':False,
   'network_access_allowed':False,
   'package_mutation_allowed':False,
   'slackpkg_mutation_allowed':False,
   'boot_mutation_allowed':False,
   'persistent_configuration_change_allowed':False,
   'reboot_allowed':False,
 },
 'authorization':{
   'repository_only_prebuild_fresh_target_revalidation_review_authorized':False,
   'target_observation_authorized':True,
   'probe_transport_copy_authorized':True,
   'prebuild_fresh_target_revalidation_freeze_and_build_authorization_review_authorized_after_successful_observation':True,
   'local_source_v2_builder_transport_authorized':False,
   'local_source_v2_builder_execution_authorized':False,
   'local_source_v2_build_authorized':False,
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
 'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review.sh','helper_sha256':helper_sha,
 'machine_action_required':True,'machine_action_type':'read-only-prebuild-fresh-target-revalidation-observation',
 'controller_action_required':True,'controller_action_type':'copy-exact-step-228-probe-to-target-and-verify-sha256',
 'future_work_requires_explicit_authorization':True,'pause_safe':False,'strong_safe_pause':False,
 'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review',
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','228'),('review_status','PASS'),('accepted_step_227_builder_sha256','8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'),
 ('historical_frozen_boot_id',policy['historical_frozen_runtime_identity']['boot_id']),
 ('builder_implementation_state',policy['builder_implementation']['state']),('builder_sha256','8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'),
 ('prebuild_fresh_target_revalidation_state','read-only-observation-authorized'),('probe_execution','root-via-sudo'),
 ('runtime_acknowledgement','--observe-prebuild-fresh-target-revalidation'),('prebuild_revalidation_probe_sha256','207ce41439c6ce2fe0f98a40266528bed4178073d5bab781d19b6d938bc64984'),
 ('fresh_boot_id_required','yes'),('previous_frozen_boot_id_match_required','no'),
 ('local_source_v1_must_be_preserved_unchanged','yes'),('failed_runtime_evidence_root_must_be_preserved_unchanged','yes'),('staged_target_must_be_preserved_unchanged','yes'),
 ('local_source_v2_final_outputs_must_be_absent','yes'),('local_source_v2_temporary_build_roots_must_be_absent','yes'),
 ('target_observation_authorized','yes'),('probe_transport_copy_authorized','yes'),
 ('prebuild_fresh_target_revalidation_freeze_and_build_authorization_review_authorized_after_successful_observation','yes'),
 ('local_source_v2_builder_transport_authorized','no'),('local_source_v2_builder_execution_authorized','no'),('local_source_v2_build_authorized','no'),
 ('runtime_executor_remediation_authorized','no'),('runtime_rerun_authorized','no'),('package_action_authorized','no'),('slackpkg_mutation_authorized','no'),('repository_refresh_authorized','no'),('network_access_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),('evidence_cleanup_authorized','no'),('phase_2_start_authorized','no'),
 ('machine_action_required','yes'),('machine_action_type','read-only-prebuild-fresh-target-revalidation-observation'),
 ('controller_action_required','yes'),('controller_action_type','copy-exact-step-228-probe-to-target-and-verify-sha256'),
 ('future_work_requires_explicit_authorization','yes'),('pause_safe','no'),
 ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review')]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN
