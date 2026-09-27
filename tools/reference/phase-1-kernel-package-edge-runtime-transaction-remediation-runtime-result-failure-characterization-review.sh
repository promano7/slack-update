#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze.tsv"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review-probe.sh"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review.sh"
output_dir=''
usage(){ cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review.sh [--output-dir DIR] [--help]

Consume the accepted step-240 single-use runtime authorization together with
its observed one-use failure. Freeze the authority as consumed and open only a
single read-only failure-characterization observation. No rerun, package,
Slackpkg, network, boot, reboot, or evidence-cleanup authority is granted.
USAGE
}
while (($#)); do case "$1" in --output-dir) [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }; output_dir=$2; shift 2;; --help|-h) usage; exit 0;; *) printf 'ERROR: unknown option: %s\n' "$1" >&2; usage >&2; exit 2;; esac; done
check_hash(){ local p=$1 e=$2 a; [[ -f $p && ! -L $p ]] || { printf 'ERROR: required input missing or unsafe: %s\n' "$p" >&2; exit 3; }; a=$(sha256sum -- "$p"|awk '{print $1}'); [[ $a == "$e" ]] || { printf 'ERROR: frozen input SHA-256 drift: %s\nexpected: %s\nactual:   %s\n' "$p" "$e" "$a" >&2; exit 4; }; }
check_hash "$prior_helper" '5b2a707ffb1686eb41260956c5bd2423dbc25508e46b93796da703c3cbef3389'
check_hash "$prior_doc" 'e701fb391391aacb06d9b4d2b90e6db4d671f2b2129c89172c0307928c228c40'
check_hash "$prior_harness" 'aef384a497e66dba050107f6fd27c7ca1b6d1fa39c4a1a81c65d92f69fcf43e8'
check_hash "$prior_policy" 'dd80b32a42e278f4f9ed8cc80c1aace1159e501d0154dcf2c8f828cafa7d5ce1'
check_hash "$prior_record" '31e438ab895a31e4c952c9dc8af87c9a1280edd967c29504ee0c5bbdea6735d1'
check_hash "$probe" 'bdb06d4a10ef6ef5994f49078beb70c2b2d9b02e7775ad7d9fac66664802f22a'
[[ -f $helper_path && ! -L $helper_path ]] || { printf 'ERROR: helper path unsafe\n' >&2; exit 3; }
[[ -n $output_dir ]] || output_dir=$acceptance_dir
mkdir -p -- "$output_dir"; [[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory unsafe\n' >&2; exit 5; }
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review.tsv"
helper_sha=$(sha256sum -- "$helper_path"|awk '{print $1}')
python3 - "$prior_policy" "$prior_record" "$policy" "$record" "$helper_sha" <<'PYFREEZE'
import csv,json,sys
from pathlib import Path
pp,rp,outp,outr=map(Path,sys.argv[1:5]); helper_sha=sys.argv[5]
p=json.loads(pp.read_text(encoding='utf-8'))
with rp.open(encoding='utf-8',newline='') as h: r=dict(csv.reader(h,delimiter='	'))
assert p['step']==240 and p['freeze_status']=='PASS'
assert p['single_use_runtime_authority_state']=='authorized-awaiting-runtime-start'
assert p['single_use_constraints']['authority_consumed_on_runtime_start'] is True
assert p['single_use_constraints']['second_execution_forbidden'] is True
assert r['step']=='240' and r['freeze_status']=='PASS'
policy={
 'schema':1,'scenario':'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review','step':241,'review_status':'PASS',
 'observed_runtime_result':'FAIL','observed_runtime_error':'fresh transaction-owned Slackpkg pkglist is missing or unsafe',
 'single_use_runtime_authority_state':'consumed-by-failed-runtime-start','authorization_use_count':1,'second_execution_forbidden':True,
 'accepted_step_240':{'helper_sha256':'5b2a707ffb1686eb41260956c5bd2423dbc25508e46b93796da703c3cbef3389','document_sha256':'e701fb391391aacb06d9b4d2b90e6db4d671f2b2129c89172c0307928c228c40','harness_sha256':'aef384a497e66dba050107f6fd27c7ca1b6d1fa39c4a1a81c65d92f69fcf43e8','policy_sha256':'dd80b32a42e278f4f9ed8cc80c1aace1159e501d0154dcf2c8f828cafa7d5ce1','record_sha256':'31e438ab895a31e4c952c9dc8af87c9a1280edd967c29504ee0c5bbdea6735d1','freeze_status':'PASS'},
 'failure_hypothesis':{
   'state':'pending-read-only-runtime-confirmation',
   'compatibility_asc_expected_to_lack_PGP_marker':True,
   'installed_slackpkg_expected_to_require_PGP_marker':True,
   'installed_slackpkg_expected_error_message_form':'Error downloading from <SOURCE>.',
   'executor_error_guard_form':'error-downloading-from-local-source',
   'expected_refresh_exit_code':0,
   'expected_transaction_pkglist_present':False,
   'hypothesis':'compatibility-asc-pgp-marker-rejection-plus-error-signal-guard-mismatch'
 },
 'observation_contract':{
   'probe_path':'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review-probe.sh','probe_sha256':'bdb06d4a10ef6ef5994f49078beb70c2b2d9b02e7775ad7d9fac66664802f22a',
   'target_path':'/home/promano/Descargas/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review-probe.sh','execution_use_count':1,
   'exact_execution_command':'sudo bash phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-failure-characterization-review-probe.sh --observe-runtime-failure-characterization',
   'evidence_root':'/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation',
   'preserve_evidence_root':True,'preserve_failed_runtime_executor':True,'preserve_local_source_v2':True,
   'verify_rollback_baseline':True,'verify_slackpkg_refresh_evidence':True,'verify_installed_slackpkg_failure_semantics':True,
   'verify_executor_error_guard_mismatch':True
 },
 'authorization':{
   'probe_transport_copy_authorized':True,'failure_characterization_observation_authorized':True,
   'runtime_executor_transport_authorized':False,'runtime_scenario_execution_authorized':False,'runtime_rerun_authorized':False,
   'package_action_authorized':False,'slackpkg_mutation_authorized':False,'repository_refresh_authorized':False,'network_access_authorized':False,
   'boot_action_authorized':False,'reboot_authorized':False,'evidence_cleanup_authorized':False,'phase_2_start_authorized':False
 },
 'machine_action_required':True,'controller_action_required':True,'future_work_requires_explicit_authorization':True,
 'pause_safe':False,'strong_safe_pause':False,'next_stage':'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze'
}
outp.write_text(json.dumps(policy,indent=2,sort_keys=True)+'\n',encoding='utf-8')
rows=[
 ('step','241'),('revision','runtime-result-failure-characterization-review'),('review_status','PASS'),('observed_runtime_result','FAIL'),
 ('observed_runtime_error','fresh transaction-owned Slackpkg pkglist is missing or unsafe'),('single_use_runtime_authority_state','consumed-by-failed-runtime-start'),
 ('authorization_use_count','1'),('second_execution_forbidden','yes'),('failure_hypothesis_state','pending-read-only-runtime-confirmation'),
 ('failure_hypothesis','compatibility-asc-pgp-marker-rejection-plus-error-signal-guard-mismatch'),('probe_sha256','bdb06d4a10ef6ef5994f49078beb70c2b2d9b02e7775ad7d9fac66664802f22a'),
 ('probe_transport_copy_authorized','yes'),('failure_characterization_observation_authorized','yes'),('runtime_rerun_authorized','no'),
 ('package_action_authorized','no'),('slackpkg_mutation_authorized','no'),('network_access_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),
 ('evidence_cleanup_authorized','no'),('machine_action_required','yes'),('controller_action_required','yes'),('pause_safe','no'),
 ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze')]
with outr.open('w',encoding='utf-8',newline='') as h:
 for k,v in rows: h.write(f'{k}\t{v}\n')
PYFREEZE
