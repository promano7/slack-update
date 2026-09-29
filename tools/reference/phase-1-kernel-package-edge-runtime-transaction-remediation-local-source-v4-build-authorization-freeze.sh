#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze'
prev_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review.sh"
prev_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review.md"
prev_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-revalidation-freeze-and-build-authorization-review.tsv"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-executor.sh"
usage() { cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze.sh --output-dir DIR

Freeze and grant exactly one local-source-v4 build attempt using the frozen executor
and builder identities. This repository helper performs no machine action itself.
USAGE
}
fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
require_hash() { local path=$1 expected=$2 label=$3 actual; [[ -f $path && ! -L $path ]] || fail "$label missing or unsafe"; actual=$(sha "$path"); [[ $actual == "$expected" ]] || fail "$label SHA-256 mismatch: $actual"; }
[[ ${1:-} == '--help' ]] && { usage; exit 0; }
[[ $# -eq 2 && $1 == '--output-dir' ]] || { usage >&2; exit 2; }
out_dir=$2
[[ -d $out_dir && ! -L $out_dir ]] || fail 'output directory must already exist and must not be a symlink'
require_hash "$prev_helper" '6b16ee9a7e904b173849486ba4119842e1fcc73ae41508286b039c8016a58171' 'accepted step-266 helper'
require_hash "$prev_doc" '3ce7f916d39efe4b3e80ac8648015f74bab61dda43f4c78d0ec72ff757311535' 'accepted step-266 document'
require_hash "$prev_harness" 'ca0c690ce437428c4a0f803f9e2c94b03a19e40e141318a6c0ef7341eac06f9a' 'accepted step-266 harness'
require_hash "$prev_policy" 'fd6ce003f5b46451a94319b3949d7354396934b937068dd0b1a871c942f197a3' 'accepted step-266 policy'
require_hash "$prev_record" 'd0bf5b8e88aaf8dab683ccff439d356071a222b184f85050509e54393b674a87' 'accepted step-266 record'
require_hash "$builder" '38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7' 'frozen local-source-v4 builder'
require_hash "$executor" 'f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985' 'frozen single-use v4 build executor'
helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import json,pathlib,sys
prev_policy_path,prev_record_path,out_policy,out_record,helper_sha=sys.argv[1:]
p=json.load(open(prev_policy_path,encoding='utf-8'))
r={}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if line: k,v=line.split('\t',1); r[k]=v
assert p['step']==266 and p['review_status']=='PASS'
assert p['reviewed_single_build_authorization']['state']=='reviewed-not-authorized'
assert p['reviewed_single_build_authorization']['authorization_use_count']==1
assert p['reviewed_single_build_authorization']['authorization_bound_boot_id']=='d34855ae-e039-4005-a842-1bef51082195'
assert p['frozen_v4_builder']['sha256']=='38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'
assert r['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze'
policy={
 'schema':1,'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze','step':267,'review_only':False,'review_status':'PASS',
 'accepted_step_266':{'helper_sha256':'6b16ee9a7e904b173849486ba4119842e1fcc73ae41508286b039c8016a58171','document_sha256':'3ce7f916d39efe4b3e80ac8648015f74bab61dda43f4c78d0ec72ff757311535','harness_sha256':'ca0c690ce437428c4a0f803f9e2c94b03a19e40e141318a6c0ef7341eac06f9a','policy_sha256':'fd6ce003f5b46451a94319b3949d7354396934b937068dd0b1a871c942f197a3','record_sha256':'d0bf5b8e88aaf8dab683ccff439d356071a222b184f85050509e54393b674a87'},
 'frozen_v4_builder':{'path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh','sha256':'38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'},
 'frozen_single_use_executor':{'path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-executor.sh','sha256':'f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985','acknowledgement':'--execute-authorized-local-source-v4-build'},
 'single_build_authorization':{
   'state':'frozen-and-authorized','authorization_use_count':1,'authorization_bound_boot_id':'d34855ae-e039-4005-a842-1bef51082195','same_boot_required_at_execution':True,
   'builder_and_executor_transport_authorized':True,'builder_execution_authorized':True,'local_source_v4_build_authorized':True,
   'builder_sha256':'38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7','executor_sha256':'f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985',
   'executor_must_revalidate_full_boundary_immediately_before_build':True,'final_outputs_must_be_absent':True,'temporary_build_roots_must_be_absent':True,
   'complete_executor_output_must_be_returned_for_result_review':True,'no_second_execution_authorized':True,'rerun_after_failure_authorized':False,
   'slackpkg_refresh_allowed':False,'repository_refresh_allowed':False,'network_access_allowed':False,'package_mutation_allowed':False,'persistent_configuration_change_allowed':False,'boot_mutation_allowed':False,'reboot_allowed':False,'evidence_cleanup_allowed':False
 },
 'expected_success_outputs':{'root':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4','tree_manifest':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256','tree_manifest_sidecar':'/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256.sha256'},
 'authorization':{'builder_and_executor_transport_authorized':True,'local_source_v4_builder_execution_authorized':True,'local_source_v4_build_authorized':True,'slackpkg_refresh_authorized':False,'repository_refresh_authorized':False,'package_action_authorized':False,'network_access_authorized':False,'persistent_configuration_change_authorized':False,'boot_action_authorized':False,'reboot_authorized':False,'evidence_cleanup_authorized':False,'runtime_rerun_authorized':False,'phase_2_start_authorized':False},
 'helper_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze.sh','helper_sha256':helper_sha,'machine_action_required':True,'controller_action_required':True,
 'future_work_requires_explicit_authorization':True,'pause_safe':False,'strong_safe_pause':False,
 'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-result-review-and-strong-safe-pause'
}
pathlib.Path(out_policy).write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[('step','267'),('review_status','PASS'),('single_build_authorization_state','frozen-and-authorized'),('authorization_use_count','1'),('authorization_bound_boot_id','d34855ae-e039-4005-a842-1bef51082195'),('frozen_v4_builder_sha256','38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7'),('frozen_executor_sha256','f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985'),('builder_and_executor_transport_authorized','yes'),('v4_builder_execution_authorized','yes'),('v4_build_authorized','yes'),('second_execution_authorized','no'),('rerun_after_failure_authorized','no'),('slackpkg_refresh_authorized','no'),('package_action_authorized','no'),('network_access_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),('machine_action_required','yes'),('controller_action_required','yes'),('strong_safe_pause','no'),('next_stage',policy['next_stage'])]
pathlib.Path(out_record).write_text(''.join(f'{k}\t{v}\n' for k,v in rows),encoding='utf-8')
PYGEN
printf 'v4_build_authorization_freeze_status\tPASS\n'
printf 'single_build_authorization_state\tfrozen-and-authorized\n'
printf 'authorization_use_count\t1\n'
printf 'authorization_bound_boot_id\td34855ae-e039-4005-a842-1bef51082195\n'
printf 'frozen_executor_sha256\tf91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985\n'
printf 'v4_build_authorized\tyes\n'
printf 'machine_action_required\tyes\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-result-review-and-strong-safe-pause\n'
