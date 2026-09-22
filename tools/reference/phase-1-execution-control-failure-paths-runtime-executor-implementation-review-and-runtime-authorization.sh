#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization.sh [--output-dir DIR] [--help]

Review the exact step-185 runtime executor implementation and freeze the
bounded authorization for copying and executing that exact payload on the
already-bound Slackware-current validation VM. This helper performs no machine
action and contacts no network.
USAGE
}

output_dir=
while (($#)); do
    case "$1" in
        --output-dir)
            [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }
            output_dir=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'ERROR: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
step185_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-policy.json"
step185_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation.tsv"
builder="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor-build.sh"
executor="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor.sh"
acceptance="$repo_root/tests/acceptance/reference/test-execution-control-failure-paths.sh"
implementation_doc="$repo_root/docs/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation.md"
helper_path="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization.sh"

regular() { [[ -f $1 && ! -L $1 ]]; }
for f in "$step185_policy" "$step185_record" "$builder" "$executor" "$acceptance" "$implementation_doc" "$helper_path"; do
    regular "$f" || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$f" >&2; exit 3; }
done
check_hash() {
    local f=$1 expected=$2 actual
    actual=$(sha256sum -- "$f" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: reviewed SHA-256 mismatch: %s\nexpected: %s\nactual:   %s\n' "$f" "$expected" "$actual" >&2
        exit 4
    }
}
check_hash "$step185_policy" '3cdb3277df0e4bafa4f8f258b65feb66f2b4fe1e9b19b59f560f6c37d1fbe914'
check_hash "$step185_record" 'f717cb0ca29ee8592ab362e04c735640a07f4648860ac07e2579e3123a5d6757'
check_hash "$builder" '69846171f89a1ec0e6be3856680b6c3e8f7b6121819a9bae1d46ba69400c7578'
check_hash "$executor" '13aa5c511c3caaaea51757f3ae6f71c4ba255470ff76be49fc830fabffc1e326'
check_hash "$acceptance" '5414d18212118ddd72c0bc0a701449c416ac3f8dd3b4689ca48ed8da948bfedf'
check_hash "$implementation_doc" '9065f59af0590afeb874499a300c21a70c4400cfd0e85c94f7947e1d7d6bb430'

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }
policy="$output_dir/phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization-policy.json"
record="$output_dir/phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step185_policy" "$step185_record" "$policy" "$record" "$helper_sha" <<'PYINNER'
import csv,json,sys
from pathlib import Path
p185,r185,outp,outr=map(Path,sys.argv[1:5]); helper_sha=sys.argv[5]
p=json.loads(p185.read_text())
with r185.open(newline='',encoding='utf-8') as f: r=dict(csv.reader(f,delimiter='\t'))
assert p['schema']==1
assert p['scenario']=='phase-1-execution-control-failure-paths-runtime-executor-implementation'
assert p['implementation']['state']=='implemented-awaiting-review'
assert p['authorization']['runtime_scenario_execution_authorized'] is False
assert r['runtime_executor_implementation_state']=='implemented-awaiting-review'
assert r['next_stage']=='phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization'
impl=p['implementation']; binding=impl['frozen_binding']
policy={
  'schema':1,
  'scenario':'phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization',
  'review_only':True,
  'accepted_implementation':{
    'step':185,
    'policy_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-policy.json',
    'policy_sha256':'3cdb3277df0e4bafa4f8f258b65feb66f2b4fe1e9b19b59f560f6c37d1fbe914',
    'record_path':'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation.tsv',
    'record_sha256':'f717cb0ca29ee8592ab362e04c735640a07f4648860ac07e2579e3123a5d6757',
    'builder_path':'tools/reference/phase-1-execution-control-failure-paths-runtime-executor-build.sh',
    'builder_sha256':'69846171f89a1ec0e6be3856680b6c3e8f7b6121819a9bae1d46ba69400c7578',
    'executor_path':'tools/reference/phase-1-execution-control-failure-paths-runtime-executor.sh',
    'executor_sha256':'13aa5c511c3caaaea51757f3ae6f71c4ba255470ff76be49fc830fabffc1e326',
    'acceptance_harness_path':'tests/acceptance/reference/test-execution-control-failure-paths.sh',
    'acceptance_harness_sha256':'5414d18212118ddd72c0bc0a701449c416ac3f8dd3b4689ca48ed8da948bfedf',
    'implementation_document_path':'docs/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation.md',
    'implementation_document_sha256':'9065f59af0590afeb874499a300c21a70c4400cfd0e85c94f7947e1d7d6bb430',
    'repository_acceptance_result':'PASS (48 passes, 0 failures)',
  },
  'runtime_authorization':{
    'state':'authorized-exact-payload-on-exact-binding',
    'family':'execution-control-failure-paths',
    'scenario_count':4,
    'hostname_fqdn':binding['hostname_fqdn'],
    'uname_release':binding['uname_release'],
    'boot_id':binding['boot_id'],
    'reference_script_sha256':impl['reference_script_sha256'],
    'effective_config_sha256':impl['effective_config_sha256'],
    'executor_sha256':'13aa5c511c3caaaea51757f3ae6f71c4ba255470ff76be49fc830fabffc1e326',
    'runtime_acknowledgement':impl['runtime_acknowledgement'],
    'target_requires_repository':False,
    'copy_executor_to_target_authorized':True,
    'copy_destination':'/home/promano/Descargas/phase-1-execution-control-failure-paths-runtime-executor.sh',
    'target_sha256_verification_required_before_execution':True,
    'runtime_execution_authorized':True,
    'authorized_command':'sudo bash phase-1-execution-control-failure-paths-runtime-executor.sh --execute-runtime-validation',
    'binding_must_be_revalidated_by_executor_before_first_scenario':True,
    'target_reboot_invalidates_authorization':True,
    'kernel_drift_invalidates_authorization':True,
    'executor_identity_drift_invalidates_authorization':True,
    'evidence_archive_path':impl['published_archive_path'],
    'evidence_sha256_path':impl['published_sha256_path'],
    'post_execution_review_required':True,
  },
  'scenario_safety_contract':{
    'network_failure_uses_temporary_network_namespace':True,
    'successful_external_network_access_authorized':False,
    'repository_refresh_authorized':False,
    'package_mutation_authorized':False,
    'boot_mutation_authorized':False,
    'reboot_authorized':False,
    'persistent_configuration_change_authorized':False,
    'temporary_root_crontab_change_authorized_only_inside_cron_scenario':True,
    'root_crontab_exact_restoration_required':True,
    'evidence_file_publication_authorized':True,
  },
  'authorization':{
    'copy_executor_to_runtime_target_authorized':True,
    'runtime_scenario_execution_authorized':True,
    'evidence_collection_authorized':True,
    'repository_refresh_authorized':False,
    'network_refresh_authorized':False,
    'package_action_authorized':False,
    'boot_action_authorized':False,
    'reboot_authorized':False,
    'phase_2_start_authorized':False,
  },
  'machine_action_required_for_next_stage':True,
  'machine_action_required_in_this_step':False,
  'slackware_current_publication_invalidates_review':False,
  'helper_path':'tools/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization.sh',
  'helper_sha256':helper_sha,
  'next_stage':'phase-1-execution-control-failure-paths-runtime-validation',
  'pause_safe':False,
}
Path(outp).write_text(json.dumps(policy,indent=2)+'\n')
rows=[
 ('check','value'),('accepted_implementation_step','185'),
 ('runtime_authorization_state','authorized-exact-payload-on-exact-binding'),
 ('selected_family','execution-control-failure-paths'),('scenario_count','4'),
 ('hostname_fqdn',binding['hostname_fqdn']),('uname_release',binding['uname_release']),('boot_id',binding['boot_id']),
 ('reference_script_sha256',impl['reference_script_sha256']),('effective_config_sha256',impl['effective_config_sha256']),
 ('builder_sha256','69846171f89a1ec0e6be3856680b6c3e8f7b6121819a9bae1d46ba69400c7578'),('executor_sha256','13aa5c511c3caaaea51757f3ae6f71c4ba255470ff76be49fc830fabffc1e326'),('acceptance_harness_sha256','5414d18212118ddd72c0bc0a701449c416ac3f8dd3b4689ca48ed8da948bfedf'),
 ('runtime_acknowledgement',impl['runtime_acknowledgement']),('target_requires_repository','no'),
 ('copy_executor_to_runtime_target_authorized','yes'),('target_sha256_verification_required_before_execution','yes'),
 ('runtime_scenario_execution_authorized','yes'),('repository_refresh_authorized','no'),('network_refresh_authorized','no'),
 ('package_action_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),
 ('root_crontab_exact_restoration_required','yes'),('evidence_file_publication_authorized','yes'),
 ('post_execution_review_required','yes'),('machine_action_required_for_next_stage','yes'),
 ('pause_safe','no'),('next_stage','phase-1-execution-control-failure-paths-runtime-validation')]
with Path(outr).open('w',newline='',encoding='utf-8') as f: csv.writer(f,delimiter='\t',lineterminator='\n').writerows(rows)
PYINNER
printf 'Step 186 implementation review and runtime authorization completed successfully\n'
