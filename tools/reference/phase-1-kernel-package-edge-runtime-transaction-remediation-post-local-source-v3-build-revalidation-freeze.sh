#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze.sh [--output-dir DIR] [--help]

Consume the successful single-use Phase 1 step-252 post-local-source-v3-build
read-only observation and freeze the fresh target/local-source-v3 identity for
repository-only executor-v2 implementation review. This helper grants no
machine, package, Slackpkg, network, boot, reboot, candidate-binding, executor
runtime, or rerun authority.
USAGE
}

output_dir=
while (($#)); do
    case "$1" in
        --output-dir) [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }; output_dir=$2; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'ERROR: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
step252_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review-policy.json"
step252_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review.tsv"
step252_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review-probe.sh"
step246_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze-policy.json"
step246_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze.tsv"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze.sh"

require_regular(){ [[ -f $1 && ! -L $1 ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$1" >&2; exit 3; }; }
check_hash(){ local actual; actual=$(sha256sum -- "$1" | awk '{print $1}'); [[ $actual == "$2" ]] || { printf 'ERROR: accepted prerequisite SHA-256 mismatch: %s\nexpected: %s\nactual:   %s\n' "$1" "$2" "$actual" >&2; exit 4; }; }
for f in "$step252_policy" "$step252_record" "$step252_probe" "$step246_policy" "$step246_record" "$helper_path"; do require_regular "$f"; done
check_hash "$step252_policy" '3f2286e99dd804da9d9e5e85f3d6aae9747bc2a4382123f79817f87aafc90034'
check_hash "$step252_record" 'b28c4fbefe2c27dc528c40752bc0671ff72b79efb783dcfb761994558dae5095'
check_hash "$step252_probe" 'dae84e86aab2ee6103748c0437d301e7923b69e76e193214ded9f3c2832fa663'
check_hash "$step246_policy" 'cf32f3d6b5df64d176c154e506c356c53e63da794c961edbbcbf1557ecef25f0'
check_hash "$step246_record" '2f55b4a83a498fdf1c347ba2f35c25b5b0a3a87233f3df66f2362cfa12491071'

[[ -n $output_dir ]] || output_dir=$acceptance_dir
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze.tsv"

python3 - "$step252_policy" "$step252_record" "$step246_policy" "$step246_record" "$policy" "$record" \
  "$(sha256sum -- "$step252_policy"|awk '{print $1}')" "$(sha256sum -- "$step252_record"|awk '{print $1}')" \
  "$(sha256sum -- "$step252_probe"|awk '{print $1}')" "$(sha256sum -- "$step246_policy"|awk '{print $1}')" \
  "$(sha256sum -- "$step246_record"|awk '{print $1}')" "$(sha256sum -- "$helper_path"|awk '{print $1}')" <<'PY'
import csv,json,sys
from pathlib import Path
p252p,r252p,p246p,r246p,outp,outr=map(Path,sys.argv[1:7])
p252_sha,r252_sha,probe_sha,p246_sha,r246_sha,helper_sha=sys.argv[7:13]
p252=json.loads(p252p.read_text()); p246=json.loads(p246p.read_text())
with r252p.open(newline='') as h: r252=dict(csv.reader(h,delimiter='\t'))
with r246p.open(newline='') as h: r246=dict(csv.reader(h,delimiter='\t'))
assert p252['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review'
assert p252['review_status']=='PASS' and r252['step']=='252'
assert p252['authorization']['probe_execution_authorized'] is True and p252['authorization']['probe_execution_use_count']==1
assert p252['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze'
assert p246['freeze_status']=='PASS' and r246['step']=='246'
assert p246['future_executor_v2_contract']['state']=='reviewed-frozen-not-implemented'

accepted={
 'status':'PASS','prior_runtime_binding_reused':False,'fresh_boot_id':'047e744d-d2ea-4d9a-8746-7734b58db3b2',
 'hostname_fqdn':'vbox-slackcurrent.vbox-slackcurrent.org','uname_machine':'x86_64','uname_release':'6.18.45','slackware_version':'Slackware 15.0+',
 'package_database_manifest_sha256':'726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
 'header_package_record':'kernel-headers-6.18.45-x86-1','kernel_generic_record':'kernel-generic-6.18.45-x86_64-1','kernel_huge_absent':True,'kernel_modules_absent':True,
 'slackpkg_conf_sha256':'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4','slackpkg_mirrors_sha256':'71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
 'staged_target_sha256':'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
 'local_source_v2_tree_verified':True,'local_source_v2_tree_manifest_sha256':'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945','local_source_v2_historical_compatibility_asc_without_PGP_preserved':True,
 'local_source_v3_tree_verified':True,'local_source_v3_tree_manifest_sha256':'8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b','local_source_v3_tree_manifest_sidecar_verified':True,
 'local_source_v3_manifest_coverage_verified':True,'local_source_v3_priority_tree_contract_verified':True,'local_source_v3_compatibility_PGP_marker_verified':True,'local_source_v3_openpgp_signature_absent':True,'local_source_v3_temporary_build_roots_absent':True,
 'failed_remediation_evidence_root_present':True,'failed_remediation_success_result_absent':True,'published_remediation_success_evidence_absent':True,'failed_remediation_pkglist_absent':True,'failed_remediation_human_error_preserved':True,
 'boot_artifacts_match_failed_remediation_preflight':True,'slackpkg_state_matches_failed_remediation_preflight':True,'geninitrd_policy_matches_failed_remediation_preflight':True,
 'probe_sha256':probe_sha,'runtime_executor_v2_implementation_performed':False,'candidate_set_bound':False,'runtime_rerun_performed':False,'repository_refresh_performed':False,
 'network_access_performed':False,'package_action_performed':False,'slackpkg_mutation_performed':False,'boot_action_performed':False,'reboot_performed':False,'evidence_cleanup_performed':False,'persistent_configuration_change_performed':False,
}
exec_contract=p246['future_executor_v2_contract']
policy={
 'schema':1,'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze','review_only':True,'freeze_status':'PASS',
 'accepted_step_252':{'policy_sha256':p252_sha,'record_sha256':r252_sha,'probe_sha256':probe_sha,'single_use_probe_result_consumed':True,'probe_authority_revoked':True},
 'accepted_step_246_executor_v2_contract':{'policy_sha256':p246_sha,'record_sha256':r246_sha,'contract_state':'reviewed-frozen-not-implemented'},
 'accepted_revalidation_evidence':accepted,
 'fresh_runtime_identity':{'state':'frozen','binding_origin':'step-252-post-local-source-v3-build-read-only-revalidation','historical_boot_id_reused':False,'boot_id':accepted['fresh_boot_id'],'package_database_manifest_sha256':accepted['package_database_manifest_sha256'],'header_package_record':accepted['header_package_record'],'kernel_generic_record':accepted['kernel_generic_record'],'slackpkg_conf_sha256':accepted['slackpkg_conf_sha256'],'slackpkg_mirrors_sha256':accepted['slackpkg_mirrors_sha256'],'valid_until_machine_package_slackpkg_boot_or_local_source_state_changes':True,'fresh_candidate_set_bound':False},
 'preserved_local_source_v3_binding':{'state':'revalidated-and-frozen','root':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3','tree_manifest':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256','tree_manifest_sha256':accepted['local_source_v3_tree_manifest_sha256'],'tree_manifest_sidecar_verified':True,'manifest_exact_coverage_verified':True,'priority_tree_contract_verified':True,'compatibility_PGP_marker_verified':True,'openpgp_signature_absent':True,'target_relative_path':'slackware64/d/kernel-headers-6.18.45-x86-1.txz','target_sha256':accepted['staged_target_sha256'],'predecessor_archive_absent':True,'rebuild_authorized':False},
 'preserved_context':{'local_source_v2_state':'preserved-and-revalidated','local_source_v2_tree_manifest_sha256':accepted['local_source_v2_tree_manifest_sha256'],'local_source_v2_historical_no_PGP_state_preserved':True,'failed_runtime_evidence_state':'preserved-unchanged','failed_evidence_root_present':True,'failed_success_result_absent':True,'published_success_evidence_absent':True,'failed_pkglist_absent':True,'human_error_preserved':True,'boot_artifacts_match_failed_preflight':True,'slackpkg_state_matches_failed_preflight':True,'geninitrd_policy_matches_failed_preflight':True},
 'executor_v2_implementation_boundary':{'contract_state':'reviewed-frozen-not-implemented','source_generation':'local-source-v3','accepted_v3_manifest_sha256':accepted['local_source_v3_tree_manifest_sha256'],'body_path':exec_contract['body_path'],'builder_path':exec_contract['builder_path'],'executor_path':exec_contract['executor_path'],'runtime_acknowledgement':exec_contract['runtime_acknowledgement'],'human_spaced_error_prefix':'Error downloading from ','human_spaced_error_prefix_record_encoding':'hex:4572726f7220646f776e6c6f6164696e672066726f6d20','hyphenated_literal_guard_forbidden':True,'fresh_transaction_owned_pkglist_required':True,'same_transaction_candidate_binding_required':True,'target_specific_candidate_guard_required':True,'slackpkg_exit_zero_required':True,'slackpkg_exit_zero_sufficient':False,'stdout_and_stderr_capture_required':True,'transaction_owned_WORKDIR_and_TEMP':True,'external_network_forbidden':True,'rollback_on_any_failure_after_mutation':True,'slackpkg_state_restored':True,'geninitrd_policy_restored':True,'boot_artifacts_unchanged':True,'real_tab_tsv_evidence':True,'no_reboot':True,'repository_only_executor_v2_implementation_review_authorized':True,'implementation_authorized':False,'transport_authorized':False,'runtime_authorized':False,'fresh_candidate_set_bound':False},
 'authorization':{'target_observation_authorized':False,'probe_transport_copy_authorized':False,'probe_execution_authorized':False,'repository_only_executor_v2_implementation_review_authorized':True,'runtime_executor_v2_implementation_authorized':False,'runtime_executor_v2_transport_authorized':False,'runtime_candidate_binding_authorized':False,'runtime_rerun_authorized':False,'package_action_authorized':False,'slackpkg_mutation_authorized':False,'repository_refresh_authorized':False,'network_access_authorized':False,'boot_action_authorized':False,'reboot_authorized':False,'evidence_cleanup_authorized':False,'persistent_configuration_change_authorized':False,'phase_2_start_authorized':False},
 'future_work_requires_explicit_authorization':True,'machine_action_required':False,'controller_action_required':False,'pause_safe':False,'strong_safe_pause':False,
 'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze.sh','helper_sha256':helper_sha,
 'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review'
}
outp.write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n')
rows=[
 ('step','253'),('revision','post-local-source-v3-build-revalidation-freeze'),('freeze_status','PASS'),('accepted_step_252_policy_sha256',p252_sha),('accepted_step_252_record_sha256',r252_sha),('probe_sha256',probe_sha),('step_252_probe_result_consumed','yes'),('step_252_probe_authority_revoked','yes'),
 ('fresh_boot_id',accepted['fresh_boot_id']),('hostname_fqdn',accepted['hostname_fqdn']),('uname_release',accepted['uname_release']),('uname_machine',accepted['uname_machine']),('package_database_manifest_sha256',accepted['package_database_manifest_sha256']),('header_package_record',accepted['header_package_record']),('kernel_generic_record',accepted['kernel_generic_record']),('slackpkg_conf_sha256',accepted['slackpkg_conf_sha256']),('slackpkg_mirrors_sha256',accepted['slackpkg_mirrors_sha256']),('staged_target_sha256',accepted['staged_target_sha256']),
 ('local_source_v2_tree_manifest_sha256',accepted['local_source_v2_tree_manifest_sha256']),('local_source_v2_historical_no_PGP_state_preserved','yes'),('local_source_v3_tree_manifest_sha256',accepted['local_source_v3_tree_manifest_sha256']),('local_source_v3_tree_verified','yes'),('local_source_v3_manifest_coverage_verified','yes'),('local_source_v3_priority_tree_contract_verified','yes'),('local_source_v3_compatibility_PGP_marker_verified','yes'),('local_source_v3_openpgp_signature_absent','yes'),('failed_runtime_evidence_preserved','yes'),('fresh_runtime_identity','frozen'),('fresh_candidate_set_bound','no'),('executor_v2_contract_state','reviewed-frozen-not-implemented'),('executor_v2_bound_v3_manifest_sha256',accepted['local_source_v3_tree_manifest_sha256']),('human_spaced_error_prefix_hex','4572726f7220646f776e6c6f6164696e672066726f6d20'),('hyphenated_error_literal_guard_forbidden','yes'),('fresh_transaction_owned_pkglist_required','yes'),('same_transaction_candidate_binding_required','yes'),('repository_only_executor_v2_implementation_review_authorized','yes'),('target_observation_authorized','no'),('runtime_executor_v2_implementation_authorized','no'),('runtime_executor_v2_transport_authorized','no'),('runtime_candidate_binding_authorized','no'),('runtime_rerun_authorized','no'),('package_action_authorized','no'),('slackpkg_mutation_authorized','no'),('repository_refresh_authorized','no'),('network_access_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),('evidence_cleanup_authorized','no'),('machine_action_required','no'),('controller_action_required','no'),('pause_safe','no'),('strong_safe_pause','no'),('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review')]
with outr.open('w',newline='') as h: csv.writer(h,delimiter='\t',lineterminator='\n').writerows(rows)
print('post_v3_build_revalidation_freeze_status\tPASS')
print('fresh_runtime_identity\tfrozen')
print('fresh_boot_id\t'+accepted['fresh_boot_id'])
print('local_source_v3_tree_manifest_sha256\t'+accepted['local_source_v3_tree_manifest_sha256'])
print('executor_v2_contract_state\treviewed-frozen-not-implemented')
print('repository_only_executor_v2_implementation_review_authorized\tyes')
print('machine_action_required\tno')
print('next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review')
PY
