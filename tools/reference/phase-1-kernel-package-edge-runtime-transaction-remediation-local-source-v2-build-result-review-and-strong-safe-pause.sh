#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review'
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh"
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
usage() { cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause.sh --output-dir DIR

Generate the repository-side step-230 policy and record that accept the single successful
local-source-v2 build result, consume all build authority, and close this continuation at
a strong safe pause. This helper performs no target, package, Slackpkg, network, boot,
reboot, cleanup, or local-source mutation action.
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
require_hash "$prev_helper" 'f2bc0431a0481e52ee9f577f6d57f40831aa3ce1d17fda7416fbbc43115fac46' 'accepted step-229 helper'
require_hash "$prev_doc" '7e2fd6c8f16884344fb0c3b60ccff350364469c23a646255ad38c8d0b2893cfe' 'accepted step-229 document'
require_hash "$prev_harness" '2a6ffcd9fc68f6ca0303f2c2b9bb608e51d75d33f18ee69130b207dcc4e9ea64' 'accepted step-229 harness'
require_hash "$prev_policy" '1a0123363f811b57108f5947512d1655c11d5c11d9e41ab0216f3edd6fe8ae73' 'accepted step-229 policy'
require_hash "$prev_record" '6904c6046ae6e778b3de8762e078b91b63c2d57d13ecdca3a5924a3c0749d86a' 'accepted step-229 record'
helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import copy,json,pathlib,sys
prev_policy_path,prev_record_path,out_policy_path,out_record_path,helper_sha=sys.argv[1:]
p229=json.load(open(prev_policy_path,encoding='utf-8'))
record={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); record[k]=v
assert p229['step']==229 and p229['review_status']=='PASS'
assert p229['single_build_authorization']['state']=='authorized-not-executed'
assert p229['single_build_authorization']['authorization_use_count']==1
assert p229['authorization']['local_source_v2_builder_execution_authorized'] is True
assert p229['authorization']['local_source_v2_build_authorized'] is True
assert p229['builder_implementation']['builder_sha256']=='8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert record['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause'
build_result={"boot_action_performed": "no", "compatibility_asc_present": "yes", "local_source_v2_build_status": "PASS", "local_source_v2_root": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2", "network_access_performed": "no", "package_action_performed": "no", "priority_trees": "patches,slackware64,extra,pasture,testing", "reboot_performed": "no", "slackpkg_configuration_change_performed": "no", "target_package": "kernel-headers-6.18.45-x86-1.txz", "target_sha256": "c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c", "tree_manifest": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256", "tree_manifest_sha256": "e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945", "tree_manifest_sha256_sidecar": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256.sha256"}
assert build_result['local_source_v2_build_status']=='PASS'
assert build_result['local_source_v2_root']==p229['builder_implementation']['local_source_v2_root']
assert build_result['target_sha256']==p229['builder_implementation']['target_sha256']
assert build_result['tree_manifest']==p229['builder_implementation']['tree_manifest']
assert build_result['tree_manifest_sha256_sidecar']==p229['builder_implementation']['tree_manifest_sha256_sidecar']
assert build_result['priority_trees']==','.join(p229['builder_implementation']['priority_trees'])
for k in ('network_access_performed','package_action_performed','slackpkg_configuration_change_performed','boot_action_performed','reboot_performed'):
    assert build_result[k]=='no'

builder_impl=copy.deepcopy(p229['builder_implementation'])
builder_impl['state']='implemented-frozen-executed-pass-authority-consumed'
design=copy.deepcopy(p229['local_source_v2_design'])
design['state']='design-frozen-implementation-frozen-built-accepted'

policy={
 'schema':1,
 'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause',
 'step':230,
 'review_only':True,
 'review_status':'PASS',
 'revision':'accepted-local-source-v2-build-result-strong-safe-pause',
 'selected_family':'kernel-package-edge',
 'family_closed':False,
 'phase_1_acceptance_matrix_complete':False,
 'accepted_step_229':{
   'builder_sha256':'8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d',
   'helper_sha256':'f2bc0431a0481e52ee9f577f6d57f40831aa3ce1d17fda7416fbbc43115fac46',
   'document_sha256':'7e2fd6c8f16884344fb0c3b60ccff350364469c23a646255ad38c8d0b2893cfe',
   'harness_sha256':'2a6ffcd9fc68f6ca0303f2c2b9bb608e51d75d33f18ee69130b207dcc4e9ea64',
   'policy_sha256':'1a0123363f811b57108f5947512d1655c11d5c11d9e41ab0216f3edd6fe8ae73',
   'record_sha256':'6904c6046ae6e778b3de8762e078b91b63c2d57d13ecdca3a5924a3c0749d86a',
 },
 'consumed_build_result':build_result,
 'build_result_state':'accepted-pass-build-authority-consumed',
 'preservation_contract':copy.deepcopy(p229['preservation_contract']),
 'local_source_v2_design':design,
 'builder_implementation':builder_impl,
 'accepted_local_source_v2':{
   'state':'built-accepted-preserve-unchanged',
   'root':build_result['local_source_v2_root'],
   'target_package':build_result['target_package'],
   'target_sha256':build_result['target_sha256'],
   'priority_trees':p229['builder_implementation']['priority_trees'],
   'compatibility_asc_present':True,
   'tree_manifest':build_result['tree_manifest'],
   'tree_manifest_sha256':build_result['tree_manifest_sha256'],
   'tree_manifest_sha256_sidecar':build_result['tree_manifest_sha256_sidecar'],
   'tree_must_be_preserved_unchanged':True,
   'tree_manifest_must_be_preserved_unchanged':True,
   'tree_manifest_sidecar_must_be_preserved_unchanged':True,
   'staged_target_must_be_preserved_unchanged':True,
   'local_source_v1_must_be_preserved_unchanged':True,
   'failed_runtime_evidence_must_be_preserved_unchanged':True,
 },
 'future_refresh_acceptance_contract':copy.deepcopy(p229['future_refresh_acceptance_contract']),
 'runtime_boundary_after_pause':{
   'prior_boot_id':p229['consumed_prebuild_observation']['fresh_boot_id'],
   'prior_package_database_manifest_sha256':p229['consumed_prebuild_observation']['package_database_manifest_sha256'],
   'prior_target_binding_reusable_after_pause':False,
   'prior_prebuild_observation_state':'expired-at-strong-safe-pause',
   'fresh_target_revalidation_required_before_any_machine_action':True,
   'local_source_v2_tree_revalidation_required_before_runtime':True,
   'local_source_v2_tree_must_match_bound_manifest_before_use':True,
   'staged_target_must_match_frozen_sha256_before_reuse':True,
   'fresh_candidate_set_required_before_runtime':True,
   'runtime_executor_remediation_review_required_before_rerun':True,
   'runtime_rerun_authorized':False,
   'package_action_authorized':False,
   'boot_action_authorized':False,
   'reboot_authorized':False,
   'runtime_network_access_forbidden':True,
 },
 'authorization':{
   'target_observation_authorized':False,
   'probe_transport_copy_authorized':False,
   'local_source_v2_builder_transport_authorized':False,
   'local_source_v2_builder_execution_authorized':False,
   'local_source_v2_build_authorized':False,
   'local_source_v2_build_result_review_authorized_after_successful_build':False,
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
 'safe_pause':{
   'strong_safe_pause':True,
   'pause_safe':True,
   'no_open_operational_authorization':True,
   'machine_action_required':False,
   'controller_action_required':False,
   'target_observation_authority_open':False,
   'builder_transport_authority_open':False,
   'builder_execution_authority_open':False,
   'local_source_v2_build_authority_open':False,
   'repository_or_network_refresh_authority_open':False,
   'runtime_execution_authority_open':False,
   'package_action_authority_open':False,
   'boot_action_authority_open':False,
   'reboot_authority_open':False,
   'phase_2_authority_open':False,
   'accepted_local_source_v2_must_be_preserved_unchanged':True,
   'tree_manifest_sha256':build_result['tree_manifest_sha256'],
   'prior_runtime_target_observation_must_not_be_reused':True,
   'later_slackware_current_publication_invalidates_checkpoint':False,
 },
 'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause.sh',
 'helper_sha256':helper_sha,
 'machine_action_required':False,
 'controller_action_required':False,
 'future_work_requires_explicit_authorization':True,
 'future_work_requires_fresh_boundary':True,
 'pause_safe':True,
 'strong_safe_pause':True,
 'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review',
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','230'),('review_status','PASS'),('revision',policy['revision']),('pause_state','strong-safe-pause'),('pause_safe','yes'),('strong_safe_pause','yes'),
 ('selected_family','kernel-package-edge'),('family_closed','no'),('acceptance_matrix_complete','no'),
 ('accepted_step_229_policy_sha256','1a0123363f811b57108f5947512d1655c11d5c11d9e41ab0216f3edd6fe8ae73'),('accepted_step_229_record_sha256','6904c6046ae6e778b3de8762e078b91b63c2d57d13ecdca3a5924a3c0749d86a'),
 ('builder_implementation_state',builder_impl['state']),('builder_sha256','8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'),('build_result_status','PASS'),('local_source_v2_tree_built','yes'),
 ('local_source_v2_root',build_result['local_source_v2_root']),('target_package',build_result['target_package']),('target_sha256',build_result['target_sha256']),
 ('priority_trees',build_result['priority_trees']),('compatibility_asc_present','yes'),('tree_manifest_path',build_result['tree_manifest']),
 ('tree_manifest_sha256',build_result['tree_manifest_sha256']),('tree_manifest_sha256_path',build_result['tree_manifest_sha256_sidecar']),('local_source_v2_tree_manifest_bound','yes'),
 ('network_access_performed','no'),('package_action_performed','no'),('slackpkg_configuration_change_performed','no'),('boot_action_performed','no'),('reboot_performed','no'),
 ('build_authority_consumed','yes'),('target_observation_authorized','no'),('local_source_v2_builder_transport_authorized','no'),('local_source_v2_builder_execution_authorized','no'),('local_source_v2_build_authorized','no'),
 ('repository_refresh_authorized','no'),('network_access_authorized','no'),('runtime_candidate_binding_authorized','no'),('runtime_executor_remediation_authorized','no'),('runtime_rerun_authorized','no'),
 ('package_action_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),('evidence_cleanup_authorized','no'),('phase_2_start_authorized','no'),
 ('prior_target_binding_reusable_after_pause','no'),('fresh_target_revalidation_required_before_any_machine_action','yes'),('local_source_v2_tree_revalidation_required_before_runtime','yes'),
 ('fresh_candidate_set_required_before_runtime','yes'),('runtime_executor_remediation_review_required_before_rerun','yes'),
 ('machine_action_required','no'),('controller_action_required','no'),('no_open_operational_authorization','yes'),('future_work_requires_fresh_boundary','yes'),
 ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review')]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN
