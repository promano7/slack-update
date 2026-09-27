#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.sh"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review.tsv"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
output_dir=''
usage(){ cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.sh [--output-dir DIR] [--help]

Consume the accepted step-239 repository-only runtime authorization review and
freeze exactly one bounded runtime-remediation authority. The frozen authority
permits transport of the exact executor and predecessor plus one runtime start;
it is consumed when that executor starts. No second run, external network,
boot, reboot, evidence cleanup, or Phase 2 authority is granted.
USAGE
}
while (($#)); do case "$1" in
 --output-dir) [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }; output_dir=$2; shift 2;;
 --help|-h) usage; exit 0;;
 *) printf 'ERROR: unknown option: %s\n' "$1" >&2; usage >&2; exit 2;;
esac; done
for f in "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$executor" "$helper_path"; do [[ -f $f && ! -L $f ]] || { printf 'ERROR: required repository input missing or unsafe: %s\n' "$f" >&2; exit 3; }; done
check_hash(){ local p=$1 e=$2 a; a=$(sha256sum -- "$p"|awk '{print $1}'); [[ $a == "$e" ]] || { printf 'ERROR: frozen input SHA-256 drift: %s\nexpected: %s\nactual:   %s\n' "$p" "$e" "$a" >&2; exit 4; }; }
check_hash "$prior_helper" 'c40913a7b59accd6a76ccb5435e4d12a85c828cc9bbbbcc991bf2949a8a8755c'
check_hash "$prior_doc" '7d27c65fe87e81e7a808f01add3cfcf04a0e04451692808da84348390007732f'
check_hash "$prior_harness" '104ca01a3c9c582950d9f8c24700c105dbdaf01e8120963edc608bdacbf79af5'
check_hash "$prior_policy" '9bf93ea719de95e8413b36913bd347744cbcb0cd2431182e55ce87b3d9a338df'
check_hash "$prior_record" '8884fdd1d74f7bbe7b358e4630a60090bad3b417d9c45802ee1acbe1abad9cd8'
check_hash "$executor" '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'
[[ -n $output_dir ]] || output_dir=$acceptance_dir
mkdir -p -- "$output_dir"; [[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory unsafe\n' >&2; exit 5; }
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.tsv"
helper_sha=$(sha256sum -- "$helper_path"|awk '{print $1}')
python3 - "$prior_policy" "$prior_record" "$policy" "$record" "$helper_sha" <<'PYFREEZE'
import csv,json,sys
from pathlib import Path
ppath,rpath,outp,outr=map(Path,sys.argv[1:5]); helper_sha=sys.argv[5]
p=json.loads(ppath.read_text(encoding='utf-8'))
with rpath.open(encoding='utf-8',newline='') as h: r=dict(csv.reader(h,delimiter='\t'))
assert p['step']==239 and p['review_status']=='PASS'
assert p['reviewed_runtime_authorization_contract']['state']=='reviewed-awaiting-single-use-authorization-freeze'
assert p['authorization']['repository_only_runtime_authorization_freeze_authorized'] is True
assert p['authorization']['runtime_scenario_execution_authorized'] is False
assert r['step']=='239' and r['review_status']=='PASS'
c=p['reviewed_runtime_authorization_contract']
policy={
 'schema':1,'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze','step':240,
 'freeze_status':'PASS','single_use_runtime_authority_state':'authorized-awaiting-runtime-start','authorization_use_count':1,
 'accepted_step_239':{'helper_sha256':'c40913a7b59accd6a76ccb5435e4d12a85c828cc9bbbbcc991bf2949a8a8755c','document_sha256':'7d27c65fe87e81e7a808f01add3cfcf04a0e04451692808da84348390007732f','harness_sha256':'104ca01a3c9c582950d9f8c24700c105dbdaf01e8120963edc608bdacbf79af5','policy_sha256':'9bf93ea719de95e8413b36913bd347744cbcb0cd2431182e55ce87b3d9a338df','record_sha256':'8884fdd1d74f7bbe7b358e4630a60090bad3b417d9c45802ee1acbe1abad9cd8','review_status':'PASS','semantics_consumed_without_change':True},
 'frozen_runtime_authority':c,
 'single_use_constraints':{
   'authority_consumed_on_runtime_start':True,'second_execution_forbidden':True,'runtime_result_review_required_before_any_further_machine_action':True,
   'executor_controller_sha256_verification_required':True,'executor_target_sha256_verification_required':True,
   'predecessor_controller_sha256_verification_required':True,'predecessor_target_sha256_verification_required':True,
   'exact_execution_command':c['exact_execution_command'],'runtime_acknowledgement':c['runtime_acknowledgement'],
   'preflight_must_complete_before_first_mutation':True,'preflight_failure_consumes_authority':True,
   'preflight_failure_next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-runtime-revalidation-review',
 },
 'authorization':{
   'runtime_executor_build_authorized':False,'runtime_executor_transport_authorized':True,'predecessor_package_transport_authorized':True,
   'predecessor_package_redownload_authorized':False,'predecessor_package_staging_authorized':True,'temporary_slackpkg_configuration_authorized':True,
   'local_source_metadata_refresh_authorized':True,'runtime_candidate_binding_authorized':True,'reference_apply_authorized':True,
   'runtime_scenario_execution_authorized':True,'runtime_rerun_authorized':True,'package_action_authorized':True,
   'repository_refresh_authorized':True,'network_access_authorized':False,'boot_action_authorized':False,'reboot_authorized':False,
   'evidence_cleanup_authorized':False,'phase_2_start_authorized':False,
 },
 'transport':{
   'executor_controller_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh',
   'executor_controller_export_path':'/home/promano/Descargas/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh',
   'executor_target_path':'/home/promano/Descargas/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh',
   'executor_sha256':'9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c',
   'predecessor_controller_path':'/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts/kernel-headers-6.18.44-x86-1.txz',
   'predecessor_controller_export_path':'/home/promano/Descargas/kernel-headers-6.18.44-x86-1.txz',
   'predecessor_target_path':'/home/promano/Descargas/kernel-headers-6.18.44-x86-1.txz',
   'predecessor_sha256':'3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d',
 },
 'expected_runtime_result':{
   'status_key':'runtime_remediation_validation_status','status_value':'PASS',
   'evidence_archive':'/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-evidence.tar.gz',
   'evidence_sha256_sidecar':'/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-evidence.tar.gz.sha256',
   'result_review_required':True,
 },
 'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.sh','helper_sha256':helper_sha,
 'machine_action_required':True,'controller_action_required':True,'future_work_requires_explicit_authorization':True,
 'pause_safe':False,'strong_safe_pause':False,'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-review',
}
outp.write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[('step','240'),('revision','runtime-executor-remediation-runtime-authorization-freeze'),('freeze_status','PASS'),('single_use_runtime_authority_state','authorized-awaiting-runtime-start'),('authorization_use_count','1'),('canonical_executor_sha256','9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'),('predecessor_sha256','3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'),('required_boot_id','fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9'),('runtime_executor_transport_authorized','yes'),('predecessor_package_transport_authorized','yes'),('runtime_scenario_execution_authorized','yes'),('runtime_rerun_authorized','yes'),('package_action_authorized','yes'),('repository_refresh_authorized','yes'),('network_access_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),('evidence_cleanup_authorized','no'),('phase_2_start_authorized','no'),('authority_consumed_on_runtime_start','yes'),('second_execution_forbidden','yes'),('machine_action_required','yes'),('controller_action_required','yes'),('pause_safe','no'),('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-review')]
with outr.open('w',encoding='utf-8',newline='') as h: csv.writer(h,delimiter='\t',lineterminator='\n').writerows(rows)
PYFREEZE
printf 'runtime_authorization_freeze_status\tPASS\n'
printf 'single_use_runtime_authority_state\tauthorized-awaiting-runtime-start\n'
printf 'authorization_use_count\t1\n'
printf 'runtime_executor_transport_authorized\tyes\n'
printf 'runtime_scenario_execution_authorized\tyes\n'
printf 'network_access_authorized\tno\n'
printf 'reboot_authorized\tno\n'
printf 'machine_action_required\tyes\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-review\n'
