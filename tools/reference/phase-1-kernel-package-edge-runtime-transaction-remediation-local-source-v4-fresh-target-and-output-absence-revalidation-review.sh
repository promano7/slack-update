#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze'
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review-probe.sh"
v4_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh"
step258_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause-policy.json"

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review.sh --output-dir DIR

Review and authorize one exact read-only local-source-v4 prebuild target/output-absence probe.
The helper itself performs no target observation, builder execution, Slackpkg refresh, package,
network, boot, reboot, cleanup, or persistent configuration action.
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

require_hash "$prev_helper" 'a2a95740b9d1837a6d0ef7ad5510199868b5ae07087ef692c55375f46af0beb7' 'accepted step-264 helper'
require_hash "$prev_doc" 'f0d706b90a1941d5987614ae75254a03d176a2701dd39f16b610b0ece3a28234' 'accepted step-264 document'
require_hash "$prev_harness" '5957d5a459d5d94231c8d7c18983d8a2ec31da6fbe87778ed4571697e48bc532' 'accepted step-264 harness'
require_hash "$prev_policy" 'c9f087b26eda42baef877438ec2b47dc7b257fc3e0562a10ca4bab2eeec4584d' 'accepted step-264 policy'
require_hash "$prev_record" 'b0f6075b9c048ef85dd7c7cc24fb283b6a9d618625b7b27eb3cc8c57426737d1' 'accepted step-264 record'
require_hash "$probe" '16ff1bc70e72a1fe363747f29db627d0cb76835ec265340771a23237cebe57fd' 'step-265 read-only probe'
require_hash "$v4_builder" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' 'frozen local-source-v4 builder'
require_hash "$step258_policy" '0826aa5af2f5ae998a0d3604486f249922b56b7e47e0aaa7874660f852c3b1bc' 'accepted failed-v2 strong-safe-pause policy'

helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$step258_policy" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import copy,json,pathlib,sys
prev_policy_path,prev_record_path,step258_path,out_policy_path,out_record_path,helper_sha=sys.argv[1:]
p264=json.load(open(prev_policy_path,encoding='utf-8'))
p258=json.load(open(step258_path,encoding='utf-8'))
record={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if line:
        k,v=line.split('\t',1); record[k]=v
assert p264['step']==264 and p264['review_status']=='PASS'
assert p264['frozen_v4_builder']['state']=='implementation-frozen-not-executed'
assert p264['frozen_v4_builder']['sha256']=='38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'
assert p264['authorization']['fresh_target_and_v4_output_absence_revalidation_authorized'] is True
assert p264['authorization']['local_source_v4_builder_execution_authorized'] is False
assert record['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation'
assert p258['step']==258 and p258['strong_safe_pause'] is True
assert p258['preservation_contract']['accepted_local_source_v3_manifest_sha256']=='8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'
assert p258['failure_characterization']['candidate_count']==0
assert p258['observed_runtime_result']['slackpkg_refresh']['pkglist_sha256']=='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'

policy={
 'schema':1,
 'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review',
 'step':265,
 'review_only':True,
 'review_status':'PASS',
 'accepted_step_264':{
   'helper_sha256':'a2a95740b9d1837a6d0ef7ad5510199868b5ae07087ef692c55375f46af0beb7','document_sha256':'f0d706b90a1941d5987614ae75254a03d176a2701dd39f16b610b0ece3a28234','harness_sha256':'5957d5a459d5d94231c8d7c18983d8a2ec31da6fbe87778ed4571697e48bc532','policy_sha256':'c9f087b26eda42baef877438ec2b47dc7b257fc3e0562a10ca4bab2eeec4584d','record_sha256':'b0f6075b9c048ef85dd7c7cc24fb283b6a9d618625b7b27eb3cc8c57426737d1',
 },
 'accepted_failed_v2_checkpoint':{
   'policy_sha256':'0826aa5af2f5ae998a0d3604486f249922b56b7e47e0aaa7874660f852c3b1bc','strong_safe_pause_was_true':True,'failed_v2_evidence_must_remain_immutable':True,
   'empty_pkglist_sha256':'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
   'accepted_local_source_v3_manifest_sha256':'8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b',
 },
 'frozen_v4_builder':copy.deepcopy(p264['frozen_v4_builder']),
 'revalidation_probe':{
   'path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review-probe.sh','sha256':'16ff1bc70e72a1fe363747f29db627d0cb76835ec265340771a23237cebe57fd','execution':'root-via-sudo','acknowledgement':'--observe-v4-fresh-target-and-output-absence-revalidation',
   'scope':'read-only-current-target-v3-preservation-failed-v2-preservation-and-v4-output-absence',
   'fresh_boot_id_required':True,'prior_runtime_binding_reusable':False,
   'expected_package_database_manifest_sha256':'726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
   'expected_header_record':'kernel-headers-6.18.45-x86-1','predecessor_installed_record_must_be_absent':True,
   'expected_staged_target_sha256':'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
   'accepted_local_source_v3_tree_verification_required':True,
   'failed_v2_evidence_preservation_required':True,'failed_v2_pkglist_must_remain_zero_bytes':True,'failed_v2_candidate_binding_must_remain_absent':True,'failed_v2_result_must_remain_absent':True,
   'boot_slackpkg_geninitrd_must_match_failed_v2_preflight':True,
   'local_source_v4_root_must_be_absent':True,'local_source_v4_manifest_must_be_absent':True,'local_source_v4_manifest_sidecar_must_be_absent':True,'local_source_v4_temp_roots_must_be_absent':True,
   'builder_transport_forbidden':True,'builder_execution_forbidden':True,'slackpkg_refresh_forbidden':True,'package_mutation_forbidden':True,'network_access_forbidden':True,'boot_mutation_forbidden':True,'reboot_forbidden':True,
   'returned_complete_output_required_for_next_step':True,
 },
 'authorization':{
   'target_observation_authorized':True,'probe_transport_copy_authorized':True,
   'revalidation_freeze_and_build_authorization_review_authorized_after_successful_observation':True,
   'local_source_v4_builder_transport_authorized':False,'local_source_v4_builder_execution_authorized':False,'local_source_v4_build_authorized':False,
   'slackpkg_refresh_authorized':False,'package_action_authorized':False,'repository_refresh_authorized':False,'network_access_authorized':False,'persistent_configuration_change_authorized':False,
   'boot_action_authorized':False,'reboot_authorized':False,'evidence_cleanup_authorized':False,'runtime_rerun_authorized':False,'phase_2_start_authorized':False,
 },
 'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-fresh-target-and-output-absence-revalidation-review.sh','helper_sha256':helper_sha,
 'machine_action_required':True,'machine_action_class':'read-only-v4-prebuild-target-and-output-absence-revalidation',
 'controller_action_required':True,'controller_action_class':'copy-exact-step-265-probe-to-target-and-verify-sha256',
 'future_work_requires_explicit_authorization':True,'pause_safe':False,'strong_safe_pause':False,
 'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review',
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','265'),('review_status','PASS'),('frozen_v4_builder_sha256','38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'),('probe_sha256','16ff1bc70e72a1fe363747f29db627d0cb76835ec265340771a23237cebe57fd'),
 ('revalidation_state','read-only-observation-authorized'),('prior_runtime_binding_reusable','no'),('target_observation_authorized','yes'),('probe_transport_copy_authorized','yes'),
 ('accepted_local_source_v3_manifest_sha256','8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'),('failed_v2_pkglist_sha256','e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855'),
 ('local_source_v4_outputs_must_be_absent','yes'),('v4_builder_execution_authorized','no'),('v4_build_authorized','no'),('slackpkg_refresh_authorized','no'),('package_action_authorized','no'),('network_access_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),
 ('machine_action_required','yes'),('machine_action_class','read-only-v4-prebuild-target-and-output-absence-revalidation'),('controller_action_required','yes'),('strong_safe_pause','no'),('next_stage',policy['next_stage'])]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN

printf 'v4_fresh_target_and_output_absence_revalidation_review_status\tPASS\n'
printf 'probe_sha256\t16ff1bc70e72a1fe363747f29db627d0cb76835ec265340771a23237cebe57fd\n'
printf 'target_observation_authorized\tyes\n'
printf 'v4_builder_execution_authorized\tno\n'
printf 'v4_build_authorized\tno\n'
printf 'machine_action_required\tyes\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review\n'
