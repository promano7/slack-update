#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze.sh"
policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze-policy.json"
record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze.tsv"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze.md"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review.sh"
prior_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review-probe.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review-harness.sh"
prior_policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review.tsv"

passes=0
failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert(){ local label=$1; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }
assert_hash() {
    local label=$1 file=$2 expected=$3 actual
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] && pass "$label" || fail "$label"
}

for f in "$helper" "$policy" "$record" "$doc" "$prior_helper" "$prior_probe" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$repo_root/CHANGELOG.md"; do
    assert "$(basename "$f") is a regular non-symlink file" bash -c '[[ -f "$1" && ! -L "$1" ]]' _ "$f"
done
assert_hash 'accepted step-232 helper hash is frozen' "$prior_helper" '872c7ecbe6570f3ae384506e991089abc8448caa26fdb2c4d4c589fa368a1e79'
assert_hash 'accepted step-232 probe hash is frozen' "$prior_probe" '227d00873ad0832a969ef04732f9336e5d5de879c46c43102dccb7f4d7339b69'
assert_hash 'accepted step-232 document hash is frozen' "$prior_doc" 'fc175317a5ed91bb851e073620cf2315d1807acf6809105b2b553a6baadfdb36'
assert_hash 'accepted step-232 harness hash is frozen' "$prior_harness" '78275412b94d58aea5be7f65da737cc7ae248aabee3391e2a75bef91c5c1d7c2'
assert_hash 'accepted step-232 policy hash is frozen' "$prior_policy" 'ef430d92d9163247c2ae9a7c6fd681eb5c032a8a4746702cd03d0645aa40e4e6'
assert_hash 'accepted step-232 record hash is frozen' "$prior_record" '7cd3736efb81ea4480e3f28a9c2c06e98690ad53762bfab39a4a5db614b4a0cc'
assert 'step-233 helper passes bash syntax validation' bash -n "$helper"
assert 'step-233 helper exposes non-mutating help' "$helper" --help
if "$helper" --definitely-invalid >/dev/null 2>&1; then fail 'step-233 helper rejects unknown option'; else pass 'step-233 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/helper.out"; then pass 'step-233 helper executes successfully'; else fail 'step-233 helper executes successfully'; fi
assert 'helper reproduces frozen policy exactly' cmp -s "$tmp/${policy##*/}" "$policy"
assert 'helper reproduces frozen record exactly' cmp -s "$tmp/${record##*/}" "$record"
assert 'helper reports PASS freeze status' grep -Fqx $'post_v2_build_revalidation_freeze_status\tPASS' "$tmp/helper.out"
assert 'helper freezes runtime identity' grep -Fqx $'fresh_runtime_identity\tfrozen' "$tmp/helper.out"
assert 'helper freezes returned boot ID' grep -Fqx $'fresh_boot_id\tfc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9' "$tmp/helper.out"
assert 'helper keeps candidate set unbound' grep -Fqx $'fresh_candidate_set_bound\tno' "$tmp/helper.out"
assert 'helper opens only repository candidate review' grep -Fqx $'repository_only_candidate_binding_review_authorized\tyes' "$tmp/helper.out"

python3 - "$policy" "$record" <<'PYSEM' >"$tmp/semantic.out"
import csv, json, sys
p=json.load(open(sys.argv[1]))
with open(sys.argv[2], newline='') as h: r=dict(csv.reader(h, delimiter='\t'))
a=p['accepted_revalidation_evidence']; f=p['fresh_runtime_identity']; v=p['preserved_local_source_v2_binding']; c=p['candidate_binding_boundary']; e=p['executor_remediation_boundary']; z=p['authorization']
checks={
 'policy identifies step-233 scenario': p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze' and r['step']=='233',
 'freeze status is PASS': p['freeze_status']=='PASS' and r['freeze_status']=='PASS' and a['status']=='PASS',
 'step-232 result is consumed': p['accepted_step_232']['single_use_probe_result_consumed'] is True and p['accepted_step_232']['probe_authority_revoked'] is True and r['step_232_probe_result_consumed']=='yes',
 'fresh boot ID is frozen': f['boot_id']=='fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9' and r['fresh_boot_id']==f['boot_id'],
 'historical boot identity is not reused': f['historical_boot_id_reused'] is False and a['prior_runtime_binding_reused'] is False,
 'package database identity is frozen': f['package_database_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
 'kernel package baseline is frozen': f['header_package_record']=='kernel-headers-6.18.45-x86-1' and f['kernel_generic_record']=='kernel-generic-6.18.45-x86_64-1',
 'slackpkg fingerprints are frozen': f['slackpkg_conf_sha256']=='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4' and f['slackpkg_mirrors_sha256']=='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
 'local-source-v2 is revalidated and frozen': v['state']=='revalidated-and-frozen' and a['local_source_v2_tree_verified'] and v['tree_manifest_sidecar_verified'],
 'v2 manifest hash is frozen': v['tree_manifest_sha256']=='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
 'v2 exact coverage and priority contract are frozen': v['manifest_exact_coverage_verified'] and v['priority_tree_contract_verified'],
 'v2 compatibility asc is bounded and verified': v['compatibility_asc_verified'] is True,
 'failed runtime evidence remains preserved': p['preserved_context']['failed_runtime_evidence_state']=='preserved-unchanged' and a['failed_evidence_root_present'] and a['failed_success_result_absent'] and a['published_success_evidence_absent'],
 'failure baseline fingerprints still match': a['boot_artifacts_match_failed_preflight'] and a['slackpkg_state_matches_failed_preflight'] and a['geninitrd_policy_matches_failed_preflight'],
 'candidate set remains unbound': f['fresh_candidate_set_bound'] is False and c['candidate_set_state']=='not-yet-bound' and r['fresh_candidate_set_bound']=='no',
 'future candidate source is local-source-v2': c['candidate_source_uri']=='file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2' and r['candidate_source_uri']==c['candidate_source_uri'],
 'future candidate binding is same-transaction only': c['fresh_same_transaction_candidate_binding_required'] and c['candidate_binding_must_be_consumed_without_pause'],
 'future workdir is transaction-owned and empty': c['future_refresh_workdir_strategy']=='transaction-owned-new-empty-workdir',
 'future candidate guard is target-specific': c['future_candidate_guard_scope']=='target-specific-not-global-pkglist-row-count',
 'future refresh rejects local-source download error': c['future_refresh_rejects_error_downloading_from_local_source'] is True,
 'executor remediation remains required': e['runtime_executor_remediation_review_required_before_rerun'] is True and e['runtime_executor_remediation_not_yet_authorized'] is True,
 'only repository candidate review is opened': z['repository_only_candidate_binding_review_authorized'] is True,
 'target observation is closed': z['target_observation_authorized'] is False and z['probe_execution_authorized'] is False and z['probe_transport_copy_authorized'] is False,
 'runtime candidate binding is still forbidden': z['runtime_candidate_binding_authorized'] is False,
 'executor remediation and rerun are forbidden': z['runtime_executor_remediation_authorized'] is False and z['runtime_rerun_authorized'] is False,
 'package/slackpkg mutation is forbidden': z['package_action_authorized'] is False and z['slackpkg_mutation_authorized'] is False,
 'repository/network refresh is forbidden': z['repository_refresh_authorized'] is False and z['network_access_authorized'] is False,
 'boot/reboot/cleanup are forbidden': z['boot_action_authorized'] is False and z['reboot_authorized'] is False and z['evidence_cleanup_authorized'] is False,
 'no machine or controller action is required': p['machine_action_required'] is False and p['controller_action_required'] is False,
 'family remains active rather than safe-paused': p['pause_safe'] is False and p['strong_safe_pause'] is False,
 'next stage is remediation candidate-set binding review': p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review',
}
for label,ok in checks.items(): print(('PASS' if ok else 'FAIL')+'\t'+label)
PYSEM
while IFS=$'\t' read -r state label; do [[ $state == PASS ]] && pass "$label" || fail "$label"; done < "$tmp/semantic.out"

assert 'reference document records accepted fresh boot ID' grep -Fq 'fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9' "$doc"
assert 'reference document binds future source to local-source-v2' grep -Fq 'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2' "$doc"
assert 'reference document keeps live candidate set unbound' grep -Fq 'No live candidate set is frozen by this step' "$doc"
assert 'CHANGELOG records step 233' grep -Fq '## Phase 1 step 233 kernel-package-edge runtime-transaction remediation post-local-source-v2-build revalidation freeze' "$repo_root/CHANGELOG.md"
assert 'step-233 helper contains no executable network, package, boot, reboot, or shutdown command' bash -c '! grep -Eq "(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]" "$1"' _ "$helper"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
