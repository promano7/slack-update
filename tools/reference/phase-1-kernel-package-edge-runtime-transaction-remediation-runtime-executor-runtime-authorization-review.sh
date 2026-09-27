#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.sh"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze.tsv"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-executor.sh"
output_dir=''

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.sh [--output-dir DIR] [--help]

Review the exact single-use runtime authorization contract for the frozen
remediated kernel-package-edge executor. This step is repository-only: it
records transport, target, preflight, invalidation, bounded-mutation, result,
and evidence requirements but grants no machine or controller action yet.
USAGE
}
while (($#)); do
    case "$1" in
        --output-dir) [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }; output_dir=$2; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'ERROR: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done
for f in "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$executor" "$acceptance_harness" "$helper_path"; do
    [[ -f $f && ! -L $f ]] || { printf 'ERROR: required repository input missing or unsafe: %s\n' "$f" >&2; exit 3; }
done
check_hash() {
    local path=$1 expected=$2 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: frozen input SHA-256 drift: %s\nexpected: %s\nactual:   %s\n' "$path" "$expected" "$actual" >&2
        exit 4
    }
}
check_hash "$prior_helper" 'd24b7d2b62a39878935bdc5a1983a368351937e63aa93ae79b8520039480a0a4'
check_hash "$prior_doc" '96bdc5a543c608deba6e49f9287cf973cabd743ff361268b1cd66aa77c78b80b'
check_hash "$prior_harness" '135da2a0ab0443164961182b9afff3a7c48fceea0a491620623a7c0f0d00340d'
check_hash "$prior_policy" '8648917cc2ed5188a73d3d2f53d799d11680da224cf98135a28262b7def23e9d'
check_hash "$prior_record" 'e3194088051d95db4df7a6f806a0003db814086a4f66c835ea4fcc7bfe09c902'
check_hash "$executor" '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'
check_hash "$acceptance_harness" '9fac7f4ad77454bcec6ec9f3cb4df09cb69be54dbdc6c38652d0c7b7d23f7652'

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
python3 - "$prior_policy" "$prior_record" "$policy" "$record" "$helper_sha" <<'PYREVIEW'
import csv,json,sys
from pathlib import Path
ppath,rpath,outp,outr=map(Path,sys.argv[1:5]); helper_sha=sys.argv[5]
p=json.loads(ppath.read_text(encoding='utf-8'))
with rpath.open(encoding='utf-8',newline='') as h: r=dict(csv.reader(h,delimiter='\t'))
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze'
assert p['step']==238 and p['freeze_status']=='PASS'
assert p['frozen_remediated_executor']['state']=='implementation-frozen-awaiting-runtime-authorization-review'
assert p['authorization']['repository_only_runtime_authorization_review_authorized'] is True
assert p['authorization']['runtime_executor_transport_authorized'] is False
assert r['step']=='238' and r['freeze_status']=='PASS'
policy={
 'schema':1,
 'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review',
 'step':239,
 'review_only':True,
 'review_status':'PASS',
 'accepted_step_238':{
   'helper_sha256':'d24b7d2b62a39878935bdc5a1983a368351937e63aa93ae79b8520039480a0a4',
   'document_sha256':'96bdc5a543c608deba6e49f9287cf973cabd743ff361268b1cd66aa77c78b80b',
   'harness_sha256':'135da2a0ab0443164961182b9afff3a7c48fceea0a491620623a7c0f0d00340d',
   'policy_sha256':'8648917cc2ed5188a73d3d2f53d799d11680da224cf98135a28262b7def23e9d',
   'record_sha256':'e3194088051d95db4df7a6f806a0003db814086a4f66c835ea4fcc7bfe09c902',
   'freeze_status':'PASS','semantics_consumed_without_change':True,'no_machine_authority_inherited':True,
 },
 'reviewed_runtime_authorization_contract':{
   'state':'reviewed-awaiting-single-use-authorization-freeze',
   'authorization_scope':'single-bounded-kernel-header-edge-runtime-remediation-transaction',
   'execution_target':'vbox-slackcurrent.vbox-slackcurrent.org',
   'required_running_kernel':'6.18.45',
   'required_boot_id':'fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9',
   'required_package_database_manifest_sha256':'726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
   'required_slackpkg_conf_sha256':'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
   'required_slackpkg_mirrors_sha256':'71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
   'executor':{
      'repository_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh',
      'sha256':'9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c',
      'target_transport_path':'/home/promano/Descargas/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh',
      'must_be_regular_non_symlink':True,'target_hash_verification_required_before_execution':True,
      'rebuild_before_transport_authorized':False,
   },
   'predecessor':{
      'artifact':'kernel-headers-6.18.44-x86-1.txz','record':'kernel-headers-6.18.44-x86-1',
      'sha256':'3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d',
      'controller_source':'/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts/kernel-headers-6.18.44-x86-1.txz',
      'target_transport_path':'/home/promano/Descargas/kernel-headers-6.18.44-x86-1.txz',
      'must_be_regular_non_symlink':True,'controller_hash_verification_required_before_transport':True,
      'target_hash_verification_required_before_execution':True,'redownload_authorized':False,
   },
   'staged_target':{
      'path':'/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz',
      'sha256':'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
   },
   'local_source_v2':{
      'root':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2',
      'tree_manifest':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256',
      'tree_manifest_sha256':'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
      'manifest_sidecar_verification_required':True,'exact_coverage_required':True,
      'priority_tree_contract_required':True,'compatibility_asc_contract_required':True,
   },
   'historical_failed_evidence':{
      'root':'/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction',
      'must_remain_present':True,'success_result_must_remain_absent':True,
      'published_success_archive_must_remain_absent':True,
   },
   'new_evidence':{
      'runtime_root':'/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation',
      'runtime_root_must_be_absent_before_start':True,
      'published_archive':'/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-evidence.tar.gz',
      'published_sha256':'/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-evidence.tar.gz.sha256',
      'published_outputs_must_be_absent_before_start':True,
      'publication_required_for_result_review':True,
      'result_review_required_before_any_further_machine_action':True,
   },
   'exact_execution_command':'sudo bash phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh --execute-runtime-remediation-validation',
   'runtime_acknowledgement':'--execute-runtime-remediation-validation',
   'transaction_lifetime':'single-execution-authority-consumed-on-runtime-start',
   'candidate_binding_lifetime':'same-runtime-transaction-only',
   'preflight_must_complete_before_first_mutation':True,
   'drift_action':'abort-before-first-mutation-and-return-to-fresh-revalidation-review',
   'authorization_invalidated_by':[
      'executor-byte-drift','predecessor-byte-drift','fqdn-drift','running-kernel-drift','boot-id-drift',
      'package-database-manifest-drift','slackpkg-configuration-drift','slackpkg-mirrors-drift','staged-target-drift',
      'local-source-v2-tree-drift','local-source-v2-manifest-sidecar-failure','local-source-v2-coverage-drift',
      'local-source-v2-priority-contract-drift','local-source-v2-compatibility-asc-drift','historical-failed-evidence-loss',
      'preexisting-remediation-evidence-root','preexisting-remediation-published-output'
   ],
   'bounded_mutation':{
      'temporary_predecessor_staging_authorized_in_future_single_use_freeze':True,
      'temporary_slackpkg_configuration_authorized_in_future_single_use_freeze':True,
      'local_file_source_metadata_refresh_authorized_in_future_single_use_freeze':True,
      'single_target_specific_candidate_binding_authorized_in_future_single_use_freeze':True,
      'frozen_reference_apply_authorized_in_future_single_use_freeze':True,
      'package_mutation_scope':'kernel-headers-6.18.45-to-6.18.44-to-6.18.45-only',
      'external_network_access_authorized':False,'boot_action_authorized':False,'reboot_authorized':False,
      'persistent_configuration_change_authorized':False,
   },
   'required_final_state':{
      'header_record':'kernel-headers-6.18.45-x86-1','package_database_manifest_sha256':'726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
      'boot_id':'fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9','running_kernel':'6.18.45',
      'local_source_v2_tree_manifest_sha256':'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
      'predecessor_terminal_state_forbidden':True,'slackpkg_configuration_and_state_restored':True,
      'geninitrd_policy_restored':True,'boot_artifacts_unchanged':True,'reboot_performed':False,
   },
 },
 'authorization':{
   'repository_only_runtime_authorization_freeze_authorized':True,
   'runtime_executor_build_authorized':False,'runtime_executor_transport_authorized':False,
   'predecessor_package_transport_authorized':False,'predecessor_package_redownload_authorized':False,
   'predecessor_package_staging_authorized':False,'temporary_slackpkg_configuration_authorized':False,
   'local_source_metadata_refresh_authorized':False,'runtime_candidate_binding_authorized':False,
   'reference_apply_authorized':False,'runtime_scenario_execution_authorized':False,'runtime_rerun_authorized':False,
   'package_action_authorized':False,'repository_refresh_authorized':False,'network_access_authorized':False,
   'boot_action_authorized':False,'reboot_authorized':False,'evidence_cleanup_authorized':False,'phase_2_start_authorized':False,
 },
 'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.sh',
 'helper_sha256':helper_sha,'machine_action_required':False,'controller_action_required':False,
 'future_work_requires_explicit_authorization':True,'pause_safe':False,'strong_safe_pause':False,
 'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze',
}
outp.write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','239'),('revision','runtime-executor-remediation-runtime-authorization-review'),('review_status','PASS'),
 ('accepted_step_238','yes'),('runtime_authorization_contract_state','reviewed-awaiting-single-use-authorization-freeze'),
 ('authorization_scope','single-bounded-kernel-header-edge-runtime-remediation-transaction'),
 ('target_hostname','vbox-slackcurrent.vbox-slackcurrent.org'),('required_running_kernel','6.18.45'),
 ('required_boot_id','fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9'),
 ('required_package_database_manifest_sha256','726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'),
 ('canonical_executor_sha256','9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'),
 ('executor_target_transport_path','/home/promano/Descargas/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh'),
 ('predecessor_record','kernel-headers-6.18.44-x86-1'),('predecessor_sha256','3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'),
 ('local_source_v2_tree_manifest_sha256','e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'),
 ('runtime_acknowledgement','--execute-runtime-remediation-validation'),('candidate_binding_lifetime','same-runtime-transaction-only'),
 ('repository_only_runtime_authorization_freeze_authorized','yes'),('runtime_executor_transport_authorized','no'),
 ('predecessor_package_transport_authorized','no'),('runtime_scenario_execution_authorized','no'),('runtime_rerun_authorized','no'),
 ('package_action_authorized','no'),('network_access_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),
 ('machine_action_required','no'),('controller_action_required','no'),('pause_safe','no'),
 ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze'),
]
with outr.open('w',encoding='utf-8',newline='') as h: csv.writer(h,delimiter='\t',lineterminator='\n').writerows(rows)
PYREVIEW
printf 'runtime_authorization_review_status\tPASS\n'
printf 'runtime_authorization_contract_state\treviewed-awaiting-single-use-authorization-freeze\n'
printf 'runtime_executor_transport_authorized\tno\n'
printf 'runtime_rerun_authorized\tno\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze\n'
