#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze.sh"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.tsv"
old_body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh"
old_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh"
old_executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-executor.sh"
output_dir=''

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze.sh [--output-dir DIR] [--help]

Consume the accepted Phase 1 step-237 repository-only implementation review,
reprove deterministic executor generation and repository acceptance, and freeze
the exact remediated body, builder, canonical executor, and acceptance harness.
This grants no transport, package, Slackpkg, network, boot, reboot, or runtime
execution authority.
USAGE
}
while (($#)); do
    case "$1" in
        --output-dir) [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }; output_dir=$2; shift 2 ;;
        --help|-h) usage; exit 0 ;;
        *) printf 'ERROR: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done
for f in "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" \
         "$old_body" "$old_builder" "$old_executor" "$body" "$builder" "$executor" \
         "$acceptance_harness" "$helper_path"; do
    [[ -f $f && ! -L $f ]] || { printf 'ERROR: required repository input is missing or unsafe: %s\n' "$f" >&2; exit 3; }
done
check_hash() {
    local path=$1 expected=$2 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: frozen input SHA-256 drift: %s\nexpected: %s\nactual:   %s\n' "$path" "$expected" "$actual" >&2
        exit 4
    }
}
check_hash "$prior_helper" '4e11c6176988331cc9e2a21e4297857b3345573bc24f3b60a4db642996b65883'
check_hash "$prior_doc" '249da50ae155c37537fa0f3088c287e4b703defa2e8d60087453202cc120728d'
check_hash "$prior_harness" '421f6a5c4e9d1bfc52bdc954601827e62138a22cee12758bc9541e96e6339825'
check_hash "$prior_policy" '75b19adf4c35d1a3f12106388e10e1d5a36b4809a66c8a11c72d90784b878162'
check_hash "$prior_record" '2f08b3896171cd4a8da74fe910cf4bd0c4b74b690cbdba388a08376f09d05ea8'
check_hash "$old_body" '47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581'
check_hash "$old_builder" '348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea'
check_hash "$old_executor" '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300'
check_hash "$body" 'ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b'
check_hash "$builder" 'a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379'
check_hash "$executor" '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'
check_hash "$acceptance_harness" '9fac7f4ad77454bcec6ec9f3cb4df09cb69be54dbdc6c38652d0c7b7d23f7652'

work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
rebuilt="$work/remediated-executor.sh"
"$builder" --repo-root "$repo_root" --output "$rebuilt" >"$work/builder.out"
cmp -s -- "$rebuilt" "$executor" || { printf 'ERROR: rebuilt executor differs from canonical executor\n' >&2; exit 5; }
rebuilt_sha=$(sha256sum -- "$rebuilt" | awk '{print $1}')
[[ $rebuilt_sha == '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c' ]] || { printf 'ERROR: rebuilt executor hash mismatch\n' >&2; exit 5; }
if ! "$acceptance_harness" >"$work/acceptance.out" 2>&1; then
    cat -- "$work/acceptance.out" >&2
    printf 'ERROR: remediated executor repository acceptance failed\n' >&2
    exit 6
fi
grep -Fqx 'Result: PASS (118 passes, 0 failures)' "$work/acceptance.out" || { cat -- "$work/acceptance.out" >&2; printf 'ERROR: unexpected repository acceptance result\n' >&2; exit 6; }

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 7; }
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
python3 - "$prior_policy" "$prior_record" "$policy" "$record" "$helper_sha" <<'PYFREEZE'
import csv, json, sys
from pathlib import Path
ppath, rpath, outp, outr = map(Path, sys.argv[1:5])
helper_sha = sys.argv[5]
p = json.loads(ppath.read_text(encoding='utf-8'))
with rpath.open(encoding='utf-8', newline='') as h:
    r = dict(csv.reader(h, delimiter='\t'))
assert p['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review'
assert p['step'] == 237 and p['review_status'] == 'PASS'
assert p['remediated_executor_implementation']['state'] == 'implemented-reviewed-awaiting-freeze'
assert p['remediated_executor_implementation']['repository_acceptance_result'] == 'PASS (118 passes, 0 failures)'
assert p['authorization']['repository_only_runtime_executor_implementation_freeze_authorized'] is True
assert p['authorization']['runtime_executor_transport_authorized'] is False
assert r['step'] == '237' and r['review_status'] == 'PASS'
impl = p['remediated_executor_implementation']
policy = {
  'schema': 1,
  'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze',
  'step': 238,
  'review_only': True,
  'freeze_status': 'PASS',
  'accepted_step_237': {
    'helper_sha256': '4e11c6176988331cc9e2a21e4297857b3345573bc24f3b60a4db642996b65883',
    'document_sha256': '249da50ae155c37537fa0f3088c287e4b703defa2e8d60087453202cc120728d',
    'harness_sha256': '421f6a5c4e9d1bfc52bdc954601827e62138a22cee12758bc9541e96e6339825',
    'policy_sha256': '75b19adf4c35d1a3f12106388e10e1d5a36b4809a66c8a11c72d90784b878162',
    'record_sha256': '2f08b3896171cd4a8da74fe910cf4bd0c4b74b690cbdba388a08376f09d05ea8',
    'review_status': 'PASS',
    'semantics_consumed_without_change': True,
    'no_machine_authority_inherited': True,
  },
  'historical_failed_executor': dict(p['historical_failed_executor'], state='historical-evidence-preserved'),
  'frozen_remediated_executor': {
    'state': 'implementation-frozen-awaiting-runtime-authorization-review',
    'body_path': impl['body_path'],
    'body_sha256': impl['body_sha256'],
    'builder_path': impl['builder_path'],
    'builder_sha256': impl['builder_sha256'],
    'executor_path': impl['executor_path'],
    'executor_sha256': impl['executor_sha256'],
    'repository_acceptance_harness_path': impl['repository_acceptance_harness_path'],
    'repository_acceptance_harness_sha256': impl['repository_acceptance_harness_sha256'],
    'repository_acceptance_result': 'PASS (118 passes, 0 failures)',
    'builder_reproducibility_reverified': True,
    'canonical_executor_rebuilt_byte_for_byte': True,
    'runtime_acknowledgement': impl['runtime_acknowledgement'],
    'boot_id': impl['boot_id'],
    'local_source_generation': impl['local_source_generation'],
    'local_source_v2_tree_manifest_sha256': impl['local_source_v2_tree_manifest_sha256'],
    'runtime_evidence_root': impl['runtime_evidence_root'],
    'published_archive_path': impl['published_archive_path'],
  },
  'frozen_candidate_and_refresh_contract': {
    'candidate_guard_scope': p['reviewed_remediations']['candidate_guard_scope'],
    'global_pkglist_row_count_guard_retired': p['reviewed_remediations']['global_pkglist_row_count_guard_retired'],
    'fresh_workdir_pkglist_required': p['reviewed_remediations']['fresh_workdir_pkglist_required'],
    'error_downloading_from_local_source_forbidden': p['reviewed_remediations']['error_downloading_from_local_source_forbidden'],
    'exact_target_candidate_row_count': p['reviewed_remediations']['exact_target_candidate_row_count'],
    'target_candidate_fullname': p['reviewed_remediations']['target_candidate_fullname'],
    'candidate_binding_lifetime': p['reviewed_remediations']['candidate_binding_lifetime'],
    'evidence_encoding': p['reviewed_remediations']['evidence_encoding'],
  },
  'authorization': {
    'repository_only_runtime_authorization_review_authorized': True,
    'runtime_executor_build_authorized': False,
    'runtime_executor_transport_authorized': False,
    'predecessor_package_transport_authorized': False,
    'predecessor_package_staging_authorized': False,
    'temporary_slackpkg_configuration_authorized': False,
    'local_source_metadata_refresh_authorized': False,
    'runtime_candidate_binding_authorized': False,
    'reference_apply_authorized': False,
    'runtime_rerun_authorized': False,
    'package_action_authorized': False,
    'slackpkg_mutation_authorized': False,
    'repository_refresh_authorized': False,
    'network_access_authorized': False,
    'boot_action_authorized': False,
    'reboot_authorized': False,
    'evidence_cleanup_authorized': False,
    'phase_2_start_authorized': False,
  },
  'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze.sh',
  'helper_sha256': helper_sha,
  'machine_action_required': False,
  'controller_action_required': False,
  'future_work_requires_explicit_authorization': True,
  'pause_safe': False,
  'strong_safe_pause': False,
  'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review',
}
outp.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
 ('step','238'),('revision','runtime-executor-remediation-implementation-freeze'),('freeze_status','PASS'),
 ('accepted_step_237','yes'),('implementation_frozen','yes'),('historical_failed_executor_preserved','yes'),
 ('remediated_body_sha256',impl['body_sha256']),('remediated_builder_sha256',impl['builder_sha256']),
 ('remediated_executor_sha256',impl['executor_sha256']),('repository_acceptance_harness_sha256',impl['repository_acceptance_harness_sha256']),
 ('repository_acceptance_result','PASS (118 passes, 0 failures)'),('builder_reproducibility_reverified','yes'),
 ('canonical_executor_rebuilt_byte_for_byte','yes'),('runtime_acknowledgement',impl['runtime_acknowledgement']),
 ('candidate_guard_scope',p['reviewed_remediations']['candidate_guard_scope']),('global_pkglist_row_count_guard','retired'),
 ('target_candidate_fullname',p['reviewed_remediations']['target_candidate_fullname']),('candidate_binding_lifetime',p['reviewed_remediations']['candidate_binding_lifetime']),
 ('evidence_encoding',p['reviewed_remediations']['evidence_encoding']),('repository_only_runtime_authorization_review_authorized','yes'),
 ('runtime_executor_transport_authorized','no'),('runtime_rerun_authorized','no'),('package_action_authorized','no'),
 ('slackpkg_mutation_authorized','no'),('network_access_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),
 ('machine_action_required','no'),('controller_action_required','no'),('pause_safe','no'),
 ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review'),
]
with outr.open('w', encoding='utf-8', newline='') as h:
    csv.writer(h, delimiter='\t', lineterminator='\n').writerows(rows)
PYFREEZE
printf 'implementation_freeze_status\tPASS\n'
printf 'implementation_frozen\tyes\n'
printf 'repository_acceptance_result\tPASS (118 passes, 0 failures)\n'
printf 'builder_reproducibility_reverified\tyes\n'
printf 'runtime_executor_transport_authorized\tno\n'
printf 'runtime_rerun_authorized\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review\n'
