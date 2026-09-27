#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze.tsv"

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

for f in "$helper" "$doc" "$policy" "$record" "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$repo_root/CHANGELOG.md"; do
    assert "$(basename "$f") is a regular non-symlink file" bash -c '[[ -f "$1" && ! -L "$1" ]]' _ "$f"
done
assert_hash 'accepted step-233 helper hash is frozen' "$prior_helper" 'e0b4937cd3a1144c374d39e00e374c6744f061beee2a76e2aa3e01a4cc53ecb6'
assert_hash 'accepted step-233 corrected document hash is frozen' "$prior_doc" '1a4e5b51176172dfcf6a43cfbb6ba2e545a2d049aa084224a3c813f93787b917'
assert_hash 'accepted step-233-r1 harness hash is frozen' "$prior_harness" '9e5b4dfa71bbdce733d249600f5ba75c99c08152a2f3bcb09a176bd540b8c7e9'
assert_hash 'accepted step-233 policy hash is frozen' "$prior_policy" '154b4bb46612da3f3827a04d7cc1d61968fdf153170f2cba8a8acfaecf5b13c2'
assert_hash 'accepted step-233 record hash is frozen' "$prior_record" 'b6c5351f987c5b36a61cd284c07c0a1aaafb51610ed7f44857311541f67ba4c1'
assert_hash 'step-234 helper hash is frozen' "$helper" '00f6eb580fdde4777d22fe89807057bc81d64b7ce0ee369a0dd2ac7c0abb17b3'
assert_hash 'step-234 document hash is frozen' "$doc" 'f1eeded49b539e2cf93af461f2ddd282498e1c657aee7c15f60bc56e7893b17c'
assert_hash 'step-234 policy hash is frozen' "$policy" '2cf0b22bfc87cf302354074dfa011a89092a4ed71aeb34d82b09f93df0011521'
assert_hash 'step-234 record hash is frozen' "$record" 'a936f539f0b219f2b5e26937ec0ec72380b90ff72ba5babdd23867239e9d29bc'
assert 'step-234 helper passes bash syntax validation' bash -n "$helper"
assert 'step-234 helper exposes non-mutating help' "$helper" --help
if "$helper" --definitely-invalid >/dev/null 2>&1; then fail 'step-234 helper rejects unknown option'; else pass 'step-234 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/helper.out"; then pass 'step-234 helper executes successfully'; else fail 'step-234 helper executes successfully'; fi
assert 'helper reproduces frozen policy exactly' cmp -s "$tmp/${policy##*/}" "$policy"
assert 'helper reproduces frozen record exactly' cmp -s "$tmp/${record##*/}" "$record"
assert 'helper reports PASS review status' grep -Fqx $'review_status\tPASS' "$tmp/helper.out"
assert 'helper keeps candidate set unbound' grep -Fqx $'candidate_set_bound\tno' "$tmp/helper.out"
assert 'helper retires global pkglist row guard' grep -Fqx $'global_pkglist_row_count_guard\tretired' "$tmp/helper.out"
assert 'helper opens only candidate binding freeze review' grep -Fqx $'repository_only_candidate_binding_freeze_authorized\tyes' "$tmp/helper.out"

python3 - "$policy" "$record" <<'PYSEM' >"$tmp/semantic.out"
import csv, json, sys
p=json.load(open(sys.argv[1]))
with open(sys.argv[2], newline='') as h: r=dict(csv.reader(h, delimiter='	'))
c=p['candidate_binding_contract']; v=p['local_source_v2_binding']; z=p['authorization']; e=p['executor_remediation_boundary']
checks={
 'policy identifies step-234 scenario': p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review' and p['step']==234 and r['step']=='234',
 'review status is PASS': p['review_status']=='PASS' and r['review_status']=='PASS',
 'step-233-r1 is consumed only as repository input': p['accepted_step_233_r1']['fresh_runtime_identity_consumed_for_repository_review_only'] is True and p['accepted_step_233_r1']['no_machine_authority_inherited'] is True,
 'fresh boot identity remains explicit': p['frozen_runtime_identity']['boot_id']=='fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9',
 'local-source-v2 remains the only candidate source': v['mirror_uri']=='file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2' and r['candidate_source_uri']==v['mirror_uri'],
 'v2 manifest identity is frozen': v['tree_manifest_sha256']=='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
 'candidate set remains unbound': c['candidate_set_state_at_step_234']=='not-bound' and r['candidate_set_bound']=='no',
 'truthful pre-staging candidate count remains zero': c['truthful_pre_staging_upgrade_candidate_count']==0 and c['truthful_pre_staging_reason']=='target-header-is-already-installed',
 'binding occurs only after exact predecessor staging': c['predecessor_record']=='kernel-headers-6.18.44-x86-1' and c['binding_time'].startswith('after-exact-predecessor-staging'),
 'binding lifetime is same transaction only': c['binding_lifetime']=='same-runtime-transaction-only' and c['binding_must_be_consumed_without_pause'] is True and c['durable_pre_staging_binding_forbidden'] is True,
 'refresh workdir must be new and empty': c['transaction_owned_new_empty_slackpkg_workdir_required'] and c['pre_refresh_pkglist_must_be_absent_in_transaction_workdir'] and c['post_refresh_pkglist_must_be_created_in_transaction_workdir'],
 'stale var-lib pkglist cannot prove refresh': c['preexisting_var_lib_slackpkg_pkglist_may_not_prove_refresh'] is True,
 'refresh requires zero exit and no local-source error': c['refresh_exit_status_must_be_zero'] and c['refresh_output_must_not_contain_error_downloading_from_local_source'],
 'global pkglist row-count guard is retired': c['global_pkglist_row_count_is_not_an_acceptance_guard'] and r['global_pkglist_row_count_guard']=='retired',
 'candidate guard is target-specific': c['candidate_guard_scope']=='target-specific' and r['candidate_guard_scope']=='target-specific',
 'exact target candidate is one row': c['expected_target_candidate_row_count']==1 and c['target_candidate_fullname']=='kernel-headers-6.18.45-x86-1' and c['target_candidate_location']=='./slackware64/d',
 'unexpected candidate classes remain zero': c['expected_install_new_candidate_count']==0 and c['expected_non_header_upgrade_candidate_count']==0 and c['expected_configured_boot_package_upgrade_candidate_count']==0,
 'target binding traces to frozen source bytes': c['target_source_binding_to_frozen_sha256_and_v2_manifest_required'] is True,
 'evidence encoding is real-tab TSV': c['evidence_encoding']=='real-tab-tsv' and r['evidence_encoding']=='real-tab-tsv',
 'binding invalidation is fail-closed': all(c[k] for k in ['invalidated_by_boot_id_change','invalidated_by_package_state_change','invalidated_by_slackpkg_configuration_change','invalidated_by_local_source_v2_change','invalidated_by_transaction_workdir_replacement','invalidated_by_refresh_reexecution']),
 'executor remediation remains required but closed': e['executor_remediation_required'] and e['executor_remediation_not_authorized_by_step_234'] and e['runtime_rerun_not_authorized_by_step_234'],
 'only repository candidate-binding freeze is opened': z['repository_only_candidate_binding_freeze_authorized'] is True,
 'live candidate binding is forbidden': z['runtime_candidate_binding_authorized'] is False,
 'executor remediation and rerun are forbidden': z['runtime_executor_remediation_authorized'] is False and z['runtime_rerun_authorized'] is False,
 'package and Slackpkg mutation are forbidden': z['package_action_authorized'] is False and z['slackpkg_mutation_authorized'] is False,
 'repository and network refresh are forbidden': z['repository_refresh_authorized'] is False and z['network_access_authorized'] is False,
 'boot reboot cleanup and Phase 2 are forbidden': z['boot_action_authorized'] is False and z['reboot_authorized'] is False and z['evidence_cleanup_authorized'] is False and z['phase_2_start_authorized'] is False,
 'no machine or controller action is required': p['machine_action_required'] is False and p['controller_action_required'] is False,
 'family remains active': p['pause_safe'] is False and p['strong_safe_pause'] is False,
 'next stage is candidate binding freeze': p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze',
}
for label,ok in checks.items(): print(('PASS' if ok else 'FAIL')+'	'+label)
PYSEM
while IFS=$'\t' read -r state label; do [[ $state == PASS ]] && pass "$label" || fail "$label"; done < "$tmp/semantic.out"

assert 'reference document states no live candidate is created' grep -Fq 'No live candidate set is created by this step' "$doc"
assert 'reference document names v2 source' grep -Fq 'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2' "$doc"
assert 'reference document retires global pkglist row-count guard' grep -Fq 'retired global `pkglist` row-count guard' "$doc"
assert 'reference document requires local-source error rejection' grep -Fq 'error-downloading-from-local-source' "$doc"
assert 'reference document requires exactly one target candidate' grep -Fq 'matching target candidate rows: one' "$doc"
assert 'step-234 document has no trailing whitespace' bash -c '! grep -nE "[[:blank:]]+$" "$1" >/dev/null' _ "$doc"
assert 'CHANGELOG records step 234' grep -Fq '## Phase 1 step 234 kernel-package-edge runtime-transaction remediation runtime candidate-set binding review' "$repo_root/CHANGELOG.md"
assert 'step-234 helper contains no executable network package boot or shutdown command' bash -c '! grep -Eq "(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]" "$1"' _ "$helper"

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
