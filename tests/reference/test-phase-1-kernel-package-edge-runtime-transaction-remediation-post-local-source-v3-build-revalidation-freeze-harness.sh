#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze.md"
policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze-policy.json"
record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review.sh"
prior_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review-probe.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review-harness.sh"
prior_policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review.tsv"
contract_policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze-policy.json"
contract_record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze.tsv"

passes=0; failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert(){ local label=$1; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }
assert_hash(){ local label=$1 file=$2 expected=$3 actual; actual=$(sha256sum -- "$file"|awk '{print $1}'); [[ $actual == "$expected" ]] && pass "$label" || fail "$label"; }

for f in "$helper" "$doc" "$policy" "$record" "$prior_helper" "$prior_probe" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$contract_policy" "$contract_record" "$repo_root/CHANGELOG.md"; do
  assert "$(basename "$f") exists as regular file" bash -c '[[ -f "$1" && ! -L "$1" ]]' _ "$f"
done
assert_hash 'accepted step-252 helper SHA-256 matches' "$prior_helper" '07c21cf008809db4c24d51fd334a0696ddc783928236de4ae2962e4eaf58de2f'
assert_hash 'accepted step-252 probe SHA-256 matches' "$prior_probe" 'dae84e86aab2ee6103748c0437d301e7923b69e76e193214ded9f3c2832fa663'
assert_hash 'accepted step-252 document SHA-256 matches' "$prior_doc" 'f3a40685cd2f5b0a8f9f7f6ae02be5e35883d91d04e7f47750febb82b9cd903c'
assert_hash 'accepted step-252 harness SHA-256 matches' "$prior_harness" '0cb138b2c1ca31beda29e0b03ecbced845f3ee4888e686906e932ae61645e2b2'
assert_hash 'accepted step-252 policy SHA-256 matches' "$prior_policy" '3f2286e99dd804da9d9e5e85f3d6aae9747bc2a4382123f79817f87aafc90034'
assert_hash 'accepted step-252 record SHA-256 matches' "$prior_record" 'b28c4fbefe2c27dc528c40752bc0671ff72b79efb783dcfb761994558dae5095'
assert_hash 'accepted step-246 policy SHA-256 matches' "$contract_policy" 'cf32f3d6b5df64d176c154e506c356c53e63da794c961edbbcbf1557ecef25f0'
assert_hash 'accepted step-246 record SHA-256 matches' "$contract_record" '2f55b4a83a498fdf1c347ba2f35c25b5b0a3a87233f3df66f2362cfa12491071'
assert_hash 'step-253 helper SHA-256 matches' "$helper" '8c54917fbfdafafc6e1aa698a5395bee64fe684f4dcf7705b3cbbc77bab1166c'
assert_hash 'step-253 document SHA-256 matches' "$doc" '6dc6db58fc8d03f346bb6b8d59ce5aae9503bd19a450a6633004fcd60dc8553e'
assert_hash 'step-253 policy SHA-256 matches' "$policy" 'af5a87022c2379ede9d7c6ec4fae4d15fc86bf08b491b3ea21082bebe5ff8d84'
assert_hash 'step-253 record SHA-256 matches' "$record" 'ec9b98e3b48fcc35c02d9e3fa50b9cba2b23e051e46af0e957519dd67ec56b97'
assert 'step-253 helper passes bash syntax validation' bash -n "$helper"
assert 'step-253 helper exposes non-mutating help' "$helper" --help
if "$helper" --invalid >/dev/null 2>&1; then fail 'step-253 helper rejects unknown option'; else pass 'step-253 helper rejects unknown option'; fi

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/out"; then pass 'step-253 helper executes successfully'; else fail 'step-253 helper executes successfully'; fi
assert 'helper reproduces frozen policy exactly' cmp -s "$tmp/${policy##*/}" "$policy"
assert 'helper reproduces frozen record exactly' cmp -s "$tmp/${record##*/}" "$record"
assert 'helper reports PASS freeze status' grep -Fqx $'post_v3_build_revalidation_freeze_status\tPASS' "$tmp/out"
assert 'helper freezes runtime identity' grep -Fqx $'fresh_runtime_identity\tfrozen' "$tmp/out"
assert 'helper freezes fresh boot ID' grep -Fqx $'fresh_boot_id\t047e744d-d2ea-4d9a-8746-7734b58db3b2' "$tmp/out"
assert 'helper freezes accepted v3 manifest identity' grep -Fqx $'local_source_v3_tree_manifest_sha256\t8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b' "$tmp/out"
assert 'helper opens repository executor-v2 review only' grep -Fqx $'repository_only_executor_v2_implementation_review_authorized\tyes' "$tmp/out"

python3 - "$policy" "$record" <<'PY' >"$tmp/semantic"
import csv,json,sys
p=json.load(open(sys.argv[1]));
with open(sys.argv[2],newline='') as h:r=dict(csv.reader(h,delimiter='\t'))
a=p['accepted_revalidation_evidence']; f=p['fresh_runtime_identity']; v=p['preserved_local_source_v3_binding']; c=p['preserved_context']; e=p['executor_v2_implementation_boundary']; z=p['authorization']
checks={
 'policy identifies step-253 scenario':p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze' and r['step']=='253',
 'freeze status is PASS':p['freeze_status']=='PASS' and r['freeze_status']=='PASS' and a['status']=='PASS',
 'step-252 result is consumed and authority revoked':p['accepted_step_252']['single_use_probe_result_consumed'] and p['accepted_step_252']['probe_authority_revoked'] and r['step_252_probe_result_consumed']=='yes',
 'fresh boot ID is frozen':f['boot_id']=='047e744d-d2ea-4d9a-8746-7734b58db3b2' and r['fresh_boot_id']==f['boot_id'],
 'historical runtime identity is not reused':not f['historical_boot_id_reused'] and not a['prior_runtime_binding_reused'],
 'package database identity is frozen':f['package_database_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
 'kernel package baseline is frozen':f['header_package_record']=='kernel-headers-6.18.45-x86-1' and f['kernel_generic_record']=='kernel-generic-6.18.45-x86_64-1',
 'slackpkg fingerprints are frozen':f['slackpkg_conf_sha256']=='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4' and f['slackpkg_mirrors_sha256']=='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
 'local-source-v3 is revalidated and frozen':v['state']=='revalidated-and-frozen' and a['local_source_v3_tree_verified'] and v['tree_manifest_sidecar_verified'],
 'v3 manifest identity is frozen':v['tree_manifest_sha256']=='8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b',
 'v3 exact coverage and priority contract are frozen':v['manifest_exact_coverage_verified'] and v['priority_tree_contract_verified'],
 'v3 PGP compatibility marker is bounded and verified':v['compatibility_PGP_marker_verified'] and v['openpgp_signature_absent'],
 'local-source-v2 historical no-PGP state is preserved':c['local_source_v2_state']=='preserved-and-revalidated' and c['local_source_v2_historical_no_PGP_state_preserved'],
 'failed remediation evidence remains preserved':c['failed_runtime_evidence_state']=='preserved-unchanged' and c['failed_evidence_root_present'] and c['failed_success_result_absent'] and c['published_success_evidence_absent'],
 'failed remediation pkglist remains absent':c['failed_pkglist_absent'] and c['human_error_preserved'],
 'failure baseline fingerprints still match':c['boot_artifacts_match_failed_preflight'] and c['slackpkg_state_matches_failed_preflight'] and c['geninitrd_policy_matches_failed_preflight'],
 'candidate set remains unbound':not f['fresh_candidate_set_bound'] and not e['fresh_candidate_set_bound'] and r['fresh_candidate_set_bound']=='no',
 'executor-v2 contract remains not implemented':e['contract_state']=='reviewed-frozen-not-implemented' and not e['implementation_authorized'],
 'executor-v2 is bound to accepted v3 manifest':e['accepted_v3_manifest_sha256']==v['tree_manifest_sha256'],
 'human-spaced error prefix is exact':e['human_spaced_error_prefix']=='Error downloading from ' and e['human_spaced_error_prefix_record_encoding']=='hex:4572726f7220646f776e6c6f6164696e672066726f6d20',
 'hyphenated literal guard remains forbidden':e['hyphenated_literal_guard_forbidden'],
 'fresh transaction pkglist and same-transaction binding remain required':e['fresh_transaction_owned_pkglist_required'] and e['same_transaction_candidate_binding_required'] and e['target_specific_candidate_guard_required'],
 'slackpkg exit zero remains insufficient alone':e['slackpkg_exit_zero_required'] and not e['slackpkg_exit_zero_sufficient'] and e['stdout_and_stderr_capture_required'],
 'runtime invariants remain frozen':e['transaction_owned_WORKDIR_and_TEMP'] and e['external_network_forbidden'] and e['rollback_on_any_failure_after_mutation'] and e['slackpkg_state_restored'] and e['geninitrd_policy_restored'] and e['boot_artifacts_unchanged'] and e['real_tab_tsv_evidence'] and e['no_reboot'],
 'only repository executor-v2 implementation review is open':z['repository_only_executor_v2_implementation_review_authorized'] is True,
 'target observation and probe authority are closed':not z['target_observation_authorized'] and not z['probe_transport_copy_authorized'] and not z['probe_execution_authorized'],
 'executor implementation transport and runtime remain closed':not z['runtime_executor_v2_implementation_authorized'] and not z['runtime_executor_v2_transport_authorized'] and not z['runtime_rerun_authorized'],
 'candidate binding remains closed':not z['runtime_candidate_binding_authorized'],
 'package and slackpkg mutation remain closed':not z['package_action_authorized'] and not z['slackpkg_mutation_authorized'],
 'network and repository refresh remain closed':not z['network_access_authorized'] and not z['repository_refresh_authorized'],
 'boot reboot cleanup remain closed':not z['boot_action_authorized'] and not z['reboot_authorized'] and not z['evidence_cleanup_authorized'],
 'no machine or controller action is required':not p['machine_action_required'] and not p['controller_action_required'],
 'family remains active rather than safe-paused':not p['pause_safe'] and not p['strong_safe_pause'],
 'next stage is executor-v2 implementation review':p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review',
}
for k,v in checks.items(): print(('PASS' if v else 'FAIL')+'\t'+k)
PY
while IFS=$'\t' read -r state label; do [[ $state == PASS ]] && pass "$label" || fail "$label"; done < "$tmp/semantic"

assert 'reference document records fresh boot ID' grep -Fq '047e744d-d2ea-4d9a-8746-7734b58db3b2' "$doc"
assert 'reference document binds executor v2 to v3 manifest' grep -Fq '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b' "$doc"
assert 'reference document preserves human-spaced error guard' grep -Fq 'Error downloading from ' "$doc"
assert 'reference document names next stage' grep -Fq 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review' "$doc"
assert 'CHANGELOG records step 253' grep -Fq '## Phase 1 step 253 kernel-package-edge runtime-transaction remediation post-local-source-v3 build revalidation freeze' "$repo_root/CHANGELOG.md"
assert 'new step-253 artifacts contain no trailing whitespace' bash -c '! grep -nE "[[:blank:]]+$" "$1" "$2" "$3" "$4" >/dev/null' _ "$helper" "$doc" "$policy" "$record"
assert 'step-253 helper contains no executable network package boot reboot or shutdown command' bash -c '! grep -Eq "(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]" "$1"' _ "$helper"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
