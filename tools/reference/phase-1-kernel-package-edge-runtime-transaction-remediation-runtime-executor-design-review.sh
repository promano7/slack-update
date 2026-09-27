#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review.sh"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze-harness.sh"
prior_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze-policy.json"
prior_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.tsv"
old_body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh"
old_build="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh"
old_exec="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
failure_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review-policy.json"
failure_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.tsv"
reference_file="$repo_root/tools/reference/slack-update-reference.sh"
config_file="$repo_root/data/config/slack-update.conf"
output_dir=''
usage() {
    cat <<'EOF'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review.sh [--output-dir DIR] [--help]

Review and freeze the repository-only design for the remediated Phase 1
kernel-package-edge runtime executor. The design consumes the accepted step-235
candidate-binding contract, preserves the failed executor as historical
evidence, and opens only repository-side implementation review. It grants no
machine, package, Slackpkg, network, boot, reboot, transport, or rerun authority.
EOF
}
while (($#)); do
    case "$1" in
        --output-dir) [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }; output_dir=$2; shift 2 ;;
        --help) usage; exit 0 ;;
        *) printf 'ERROR: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done
for f in "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$old_body" "$old_build" "$old_exec" "$failure_policy" "$failure_record" "$reference_file" "$config_file" "$helper_path"; do
    [[ -f $f && ! -L $f ]] || { printf 'ERROR: required repository input is missing or unsafe: %s\n' "$f" >&2; exit 3; }
done
check_hash() { local path=$1 expected=$2 actual; actual=$(sha256sum -- "$path"|awk '{print $1}'); [[ $actual == "$expected" ]] || { printf 'ERROR: frozen input SHA-256 drift: %s\n' "$path" >&2; exit 4; }; }
check_hash "$prior_helper" '0ea822e030dbf22304f4564f9e075fc0e1d3da38f2b9b0621b986ac5f3783cf8'
check_hash "$prior_doc" '2cd5540b287845ef178c3e4387bdfa6e9debaebfa9405f1784a59e629d6018ba'
check_hash "$prior_harness" '2271d7157ef3f9cff268549fd344b103bed8c3da75be106f6c7c20f37666c3b4'
check_hash "$prior_policy" '73244a59e776a9a9ab41802d1995211a1e3ba2505cb36bf950f09ba7084f6878'
check_hash "$prior_record" '0496250d4f680485559b043278725c5437f6fe830d2692640feeb479b4b8f389'
check_hash "$old_body" '47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581'
check_hash "$old_build" '348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea'
check_hash "$old_exec" '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300'
check_hash "$failure_policy" '6a55e2e600dbb192cb7e14e9d3514a9a6dd7ab2ac019fd7478f84d631c670d75'
check_hash "$failure_record" '9bb2cb29fce3529b9d4b726846db433558dfbbb9de5127b54c71d49d13bb982f'
check_hash "$reference_file" '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
check_hash "$config_file" '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review.tsv"
helper_sha=$(sha256sum -- "$helper_path"|awk '{print $1}')
python3 - "$prior_policy" "$prior_record" "$failure_policy" "$policy" "$record" "$helper_sha" <<'PYREVIEW'
import csv,json,sys
from pathlib import Path
ppath,rpath,fpath,outp,outr=map(Path,sys.argv[1:6]); helper_sha=sys.argv[6]
p=json.loads(ppath.read_text())
with rpath.open(newline='') as h: r=dict(csv.reader(h,delimiter='\t'))
f=json.loads(fpath.read_text())
assert p['step']==235 and p['freeze_status']=='PASS'
assert p['candidate_binding_freeze_contract']['global_pkglist_row_count_guard_retired'] is True
assert p['candidate_binding_freeze_contract']['candidate_guard_scope']=='target-specific'
assert p['authorization']['repository_only_runtime_executor_remediation_design_review_authorized'] is True
assert r['candidate_set_bound']=='no'
assert f['step']==219 and f['failure_characterization_status']=='PASS'
assert f['failed_run_slackpkg_update_exit_code']==0
assert f['failed_run_slackpkg_update_error_signal']=='error-downloading-from-local-source'
assert f['failure_mechanism']['global_pkglist_row_count_is_valid_candidate_guard'] is False
assert f['remediation_boundary']['evidence_encoding']=='real-tab-tsv'
policy={
 'schema':1,
 'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review',
 'step':236,
 'review_only':True,
 'review_status':'PASS',
 'accepted_step_235':{
   'helper_sha256':'0ea822e030dbf22304f4564f9e075fc0e1d3da38f2b9b0621b986ac5f3783cf8','document_sha256':'2cd5540b287845ef178c3e4387bdfa6e9debaebfa9405f1784a59e629d6018ba','harness_sha256':'2271d7157ef3f9cff268549fd344b103bed8c3da75be106f6c7c20f37666c3b4',
   'policy_sha256':'73244a59e776a9a9ab41802d1995211a1e3ba2505cb36bf950f09ba7084f6878','record_sha256':'0496250d4f680485559b043278725c5437f6fe830d2692640feeb479b4b8f389',
   'candidate_binding_contract_consumed_without_change':True,'no_machine_authority_inherited':True
 },
 'historical_failed_executor':{
   'body_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh','body_sha256':'47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581',
   'builder_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh','builder_sha256':'348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea',
   'executor_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh','executor_sha256':'09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300',
   'state':'historical-failed-evidence-do-not-modify-in-place',
   'runtime_authorization_reusable':False,
   'observed_failure':'refreshed local pkglist contains 2032 package rows instead of exactly one',
   'refresh_exit_status_observed':0,
   'refresh_error_signal_observed':'error-downloading-from-local-source',
   'failed_evidence_root_must_remain_preserved':True,
 },
 'frozen_inputs':{
   'hostname':'vbox-slackcurrent.vbox-slackcurrent.org','boot_id':'fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9','running_kernel':'6.18.45',
   'package_database_manifest_sha256':'726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
   'slackpkg_conf_sha256':'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
   'slackpkg_mirrors_sha256':'71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
   'reference_script_path':'tools/reference/slack-update-reference.sh','reference_script_sha256':'1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415',
   'effective_config_path':'data/config/slack-update.conf','effective_config_sha256':'4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba',
   'predecessor_record':'kernel-headers-6.18.44-x86-1','predecessor_artifact':'kernel-headers-6.18.44-x86-1.txz',
   'predecessor_transport_path':'/home/promano/Descargas/kernel-headers-6.18.44-x86-1.txz',
   'predecessor_sha256':'3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d',
   'target_record':'kernel-headers-6.18.45-x86-1','target_artifact':'kernel-headers-6.18.45-x86-1.txz',
   'target_sha256':'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
   'staged_target_path':'/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz',
   'local_source_v2_root':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2',
   'local_source_v2_uri':'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2/',
   'local_source_v2_tree_manifest':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256',
   'local_source_v2_tree_manifest_sha256':'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
   'local_source_v2_tree_manifest_sidecar':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256.sha256',
 },
 'remediated_executor_design':{
   'state':'design-reviewed-not-implemented',
   'new_generation_required':True,
   'old_executor_files_must_not_be_modified_in_place':True,
   'body_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh',
   'builder_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh',
   'executor_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh',
   'runtime_acknowledgement':'--execute-runtime-remediation-validation',
   'runtime_evidence_root':'/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation',
   'published_archive_path':'/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-evidence.tar.gz',
   'published_sha256_path':'/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-evidence.tar.gz.sha256',
   'pre_execution_gate':{
     'fresh_runtime_identity_must_match_step_233_freeze':True,
     'predecessor_transport_sha256_must_match':True,
     'staged_target_sha256_must_match':True,
     'local_source_v2_manifest_sidecar_must_verify':True,
     'local_source_v2_exact_manifest_coverage_must_verify':True,
     'local_source_v2_priority_tree_contract_must_verify':True,
     'local_source_v2_compatibility_asc_must_be_present':True,
     'failed_runtime_evidence_root_must_remain_present':True,
     'new_runtime_evidence_root_must_be_absent':True,
     'published_success_evidence_must_be_absent':True,
   },
   'slackpkg_isolation':{
     'temporary_configuration_required':True,
     'temporary_CHECKGPG':'off',
     'mirror_uri':'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2/',
     'transaction_workdir':'/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation/slackpkg-workdir',
     'transaction_cache':'/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation/slackpkg-cache',
     'rewrite_WORKDIR_to_transaction_owned_path':True,
     'rewrite_TEMP_to_transaction_owned_path':True,
     'transaction_workdir_must_start_empty':True,
     'pre_refresh_pkglist_must_be_absent':True,
     'post_refresh_pkglist_must_be_regular_and_present':True,
     'canonical_var_lib_slackpkg_must_not_be_used_as_refresh_evidence':True,
     'canonical_var_lib_slackpkg_fingerprint_must_be_unchanged_after_transaction':True,
     'temporary_slackpkg_conf_and_mirrors_must_be_restored_byte_for_byte':True,
   },
   'refresh_guard':{
     'network_namespace':'unshare-network-disabled',
     'external_network_access_allowed':False,
     'source_tree_must_verify_immediately_before_refresh':True,
     'exit_status_must_be_zero':True,
     'stdout_and_stderr_must_be_captured':True,
     'error_downloading_from_local_source_signal_forbidden':True,
     'workdir_pkglist_creation_is_required_freshness_proof':True,
     'refresh_must_fail_closed_before_candidate_binding_on_any_guard_failure':True,
   },
   'candidate_guard':{
     'scope':'target-specific',
     'global_pkglist_row_count_guard_forbidden':True,
     'predecessor_must_be_installed':'kernel-headers-6.18.44-x86-1',
     'target_candidate_fullname':'kernel-headers-6.18.45-x86-1',
     'target_candidate_location':'./slackware64/d',
     'target_candidate_priority_tree':'slackware64',
     'exact_target_candidate_row_count':1,
     'install_new_candidate_count':0,
     'non_header_upgrade_candidate_count':0,
     'configured_boot_package_upgrade_candidate_count':0,
     'candidate_source_must_bind_to_target_sha256_and_v2_manifest':True,
     'binding_lifetime':'same-runtime-transaction-only',
     'binding_must_be_consumed_without_pause':True,
   },
   'evidence_remediation':{
     'encoding':'real-tab-tsv',
     'literal_backslash_t_field_separators_forbidden':True,
     'preflight_tsv_must_use_record_kv_or_printf_real_tabs':True,
     'candidate_binding_tsv_must_use_record_kv_or_printf_real_tabs':True,
     'refresh_stdout_stderr_exit_code_and_pkglist_sha256_must_be_preserved':True,
     'workdir_path_and_pre_post_pkglist_state_must_be_recorded':True,
   },
   'unchanged_transaction_semantics':{
     'stage_only_frozen_predecessor_header':True,
     'header_only_package_delta_required':True,
     'reference_apply_uses_frozen_reference_and_derived_config':True,
     'reference_apply_runs_without_external_network':True,
     'expected_kernel_trigger_count':1,
     'expected_initrd_update_count':0,
     'expected_grub_update_count':0,
     'rollback_restores_target_header_on_any_failure_after_mutation':True,
     'slackpkg_configuration_restored':True,
     'geninitrd_policy_restored':True,
     'boot_artifacts_unchanged':True,
     'no_reboot':True,
     'success_evidence_published_only_after_final_invariants_pass':True,
   },
   'transaction_order':p['future_transaction_order'],
 },
 'preservation_contract':p['preservation_contract'],
 'implementation_boundary':{
   'repository_only_implementation_review_authorized':True,
   'implementation_must_create_new_generation_files':True,
   'implementation_must_conform_to_step_236_design':True,
   'implementation_review_may_build_canonical_payload_for_repository_acceptance':True,
   'implementation_review_may_not_transport_or_execute_payload':True,
   'machine_runtime_authorization_requires_later_explicit_step':True,
 },
 'authorization':{
   'repository_only_runtime_executor_remediation_implementation_review_authorized':True,
   'runtime_executor_remediation_build_authorized':False,
   'runtime_executor_transport_authorized':False,
   'runtime_rerun_authorized':False,
   'runtime_candidate_binding_authorized':False,
   'target_observation_authorized':False,
   'package_action_authorized':False,
   'slackpkg_mutation_authorized':False,
   'repository_refresh_authorized':False,
   'network_access_authorized':False,
   'boot_action_authorized':False,
   'reboot_authorized':False,
   'evidence_cleanup_authorized':False,
   'persistent_configuration_change_authorized':False,
   'phase_2_start_authorized':False,
 },
 'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review.sh','helper_sha256':helper_sha,
 'machine_action_required':False,'controller_action_required':False,
 'future_work_requires_explicit_authorization':True,'pause_safe':False,'strong_safe_pause':False,
 'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review'
}
Path(outp).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n')
rows=[
 ('step','236'),('revision','runtime-executor-remediation-design-review'),('review_status','PASS'),
 ('accepted_step_235','yes'),('historical_failed_executor_preserved','yes'),('historical_executor_runtime_authorization_reusable','no'),
 ('new_executor_generation_required','yes'),('local_source_generation','local-source-v2'),
 ('local_source_v2_tree_manifest_sha256','e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'),
 ('runtime_boot_id','fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9'),('candidate_guard_scope','target-specific'),
 ('global_pkglist_row_count_guard','forbidden'),('transaction_workdir_strategy','new-empty-WORKDIR-from-temporary-slackpkg-config'),
 ('transaction_cache_strategy','transaction-owned-TEMP'),('pre_refresh_pkglist_absent_required','yes'),('post_refresh_pkglist_present_required','yes'),
 ('refresh_exit_status_zero_required','yes'),('refresh_local_source_error_signal_forbidden','yes'),
 ('target_candidate_row_count','1'),('target_candidate_fullname','kernel-headers-6.18.45-x86-1'),
 ('evidence_encoding','real-tab-tsv'),('literal_backslash_t_separators_forbidden','yes'),
 ('runtime_executor_remediation_implementation_authorized','no'),('runtime_rerun_authorized','no'),
 ('package_action_authorized','no'),('slackpkg_mutation_authorized','no'),('network_access_authorized','no'),
 ('boot_action_authorized','no'),('reboot_authorized','no'),('machine_action_required','no'),('controller_action_required','no'),
 ('pause_safe','no'),('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review')]
with Path(outr).open('w',newline='') as h:
 w=csv.writer(h,delimiter='\t',lineterminator='\n'); w.writerows(rows)
PYREVIEW
printf 'review_status\tPASS\n'
printf 'historical_failed_executor_preserved\tyes\n'
printf 'new_executor_generation_required\tyes\n'
printf 'candidate_guard_scope\ttarget-specific\n'
printf 'global_pkglist_row_count_guard\tforbidden\n'
printf 'evidence_encoding\treal-tab-tsv\n'
printf 'repository_only_runtime_executor_remediation_implementation_review_authorized\tyes\n'
printf 'runtime_rerun_authorized\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review\n'
