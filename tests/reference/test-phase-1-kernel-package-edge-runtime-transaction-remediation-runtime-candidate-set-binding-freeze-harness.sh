#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review-harness.sh"
prior_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review-policy.json"
prior_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review.tsv"
passes=0; failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert(){ local label=$1; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }
assert_hash(){ local label=$1 file=$2 expected=$3 actual; actual=$(sha256sum -- "$file"|awk '{print $1}'); [[ $actual == "$expected" ]] && pass "$label" || fail "$label"; }
for f in "$helper" "$doc" "$policy" "$record" "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$repo_root/CHANGELOG.md"; do assert "$(basename "$f") is a regular non-symlink file" bash -c '[[ -f "$1" && ! -L "$1" ]]' _ "$f"; done
assert_hash 'accepted step-234 helper hash is frozen' "$prior_helper" '00f6eb580fdde4777d22fe89807057bc81d64b7ce0ee369a0dd2ac7c0abb17b3'
assert_hash 'accepted step-234 document hash is frozen' "$prior_doc" 'f1eeded49b539e2cf93af461f2ddd282498e1c657aee7c15f60bc56e7893b17c'
assert_hash 'accepted step-234 harness hash is frozen' "$prior_harness" '381a0fc20b8cc8acfe242b920e80fab101c54b0dbf560095b8e7c31da81edbc0'
assert_hash 'accepted step-234 policy hash is frozen' "$prior_policy" '2cf0b22bfc87cf302354074dfa011a89092a4ed71aeb34d82b09f93df0011521'
assert_hash 'accepted step-234 record hash is frozen' "$prior_record" 'a936f539f0b219f2b5e26937ec0ec72380b90ff72ba5babdd23867239e9d29bc'
assert_hash 'step-235 helper hash is frozen' "$helper" '0ea822e030dbf22304f4564f9e075fc0e1d3da38f2b9b0621b986ac5f3783cf8'
assert_hash 'step-235 document hash is frozen' "$doc" '2cd5540b287845ef178c3e4387bdfa6e9debaebfa9405f1784a59e629d6018ba'
assert_hash 'step-235 policy hash is frozen' "$policy" '73244a59e776a9a9ab41802d1995211a1e3ba2505cb36bf950f09ba7084f6878'
assert_hash 'step-235 record hash is frozen' "$record" '0496250d4f680485559b043278725c5437f6fe830d2692640feeb479b4b8f389'
assert 'step-235 helper passes bash syntax validation' bash -n "$helper"
assert 'step-235 helper exposes non-mutating help' "$helper" --help
if "$helper" --invalid >/dev/null 2>&1; then fail 'step-235 helper rejects unknown option'; else pass 'step-235 helper rejects unknown option'; fi
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/helper.out"; then pass 'step-235 helper executes successfully'; else fail 'step-235 helper executes successfully'; fi
assert 'helper reproduces frozen policy exactly' cmp -s "$tmp/${policy##*/}" "$policy"
assert 'helper reproduces frozen record exactly' cmp -s "$tmp/${record##*/}" "$record"
assert 'helper reports PASS freeze status' grep -Fqx $'freeze_status\tPASS' "$tmp/helper.out"
assert 'helper freezes candidate contract' grep -Fqx $'candidate_binding_contract_frozen\tyes' "$tmp/helper.out"
assert 'helper keeps live candidate unbound' grep -Fqx $'candidate_set_bound\tno' "$tmp/helper.out"
assert 'helper opens only repository executor design review' grep -Fqx $'repository_only_runtime_executor_remediation_design_review_authorized\tyes' "$tmp/helper.out"
python3 - "$policy" "$record" <<'PYSEM' >"$tmp/semantic.out"
import csv,json,sys
p=json.load(open(sys.argv[1])); r=dict(csv.reader(open(sys.argv[2]),delimiter='\t'))
c=p['candidate_binding_freeze_contract']; z=p['authorization']; e=p['executor_remediation_design_boundary']
checks={
'policy identifies step-235 freeze':p['step']==235 and p['scenario'].endswith('runtime-candidate-set-binding-freeze') and r['step']=='235',
'freeze status is PASS':p['freeze_status']=='PASS' and r['freeze_status']=='PASS',
'step-234 semantics are consumed unchanged':p['accepted_step_234']['semantics_consumed_without_change'] is True,
'no machine authority is inherited':p['accepted_step_234']['no_machine_authority_inherited'] is True,
'candidate contract state is frozen':c['state']=='contract-frozen-live-binding-not-created' and c['accepted_step_234_semantics_must_not_change'] is True,
'live candidate set remains unbound':c['candidate_set_bound_at_freeze'] is False and r['candidate_set_bound']=='no',
'truthful pre-staging candidate count is zero':c['truthful_pre_staging_upgrade_candidate_count']==0,
'predecessor and target are exact':c['predecessor_record']=='kernel-headers-6.18.44-x86-1' and c['target_record']=='kernel-headers-6.18.45-x86-1',
'binding lifetime remains same transaction':c['binding_lifetime']=='same-runtime-transaction-only' and c['binding_must_be_consumed_without_pause'],
'pre-staging durable binding is forbidden':c['durable_pre_staging_binding_forbidden'] is True,
'fresh workdir contract is frozen':c['transaction_owned_new_empty_slackpkg_workdir_required'] and c['pre_refresh_pkglist_must_be_absent_in_transaction_workdir'] and c['post_refresh_pkglist_must_be_created_in_transaction_workdir'],
'stale var-lib pkglist remains non-authoritative':c['preexisting_var_lib_slackpkg_pkglist_may_not_prove_refresh'] is True,
'refresh result guard is frozen':c['refresh_exit_status_must_be_zero'] and c['refresh_output_must_not_contain_error_downloading_from_local_source'],
'global pkglist guard remains retired':c['global_pkglist_row_count_guard_retired'] and r['global_pkglist_row_count_guard']=='retired',
'target-specific guard is frozen':c['candidate_guard_scope']=='target-specific',
'exact target row count is one':c['expected_target_candidate_row_count']==1 and c['target_candidate_location']=='./slackware64/d',
'unexpected candidate counts are zero':c['expected_install_new_candidate_count']==0 and c['expected_non_header_upgrade_candidate_count']==0 and c['expected_configured_boot_package_upgrade_candidate_count']==0,
'v2 source binding remains required':c['target_source_binding_to_frozen_sha256_and_v2_manifest_required'] and c['source_tree_manifest_must_verify_immediately_before_refresh'],
'external network remains forbidden':c['external_network_access_forbidden'] is True,
'evidence encoding remains real-tab TSV':c['evidence_encoding']=='real-tab-tsv' and r['evidence_encoding']=='real-tab-tsv',
'binding invalidation remains fail-closed':c['binding_invalidated_by_any_relevant_state_change'] is True,
'candidate contract is required input for executor design':e['candidate_binding_contract_is_frozen_input'] and e['design_must_conform_to_frozen_candidate_binding_contract'],
'executor design review is repository-only':e['repository_only_design_review_authorized'] and e['design_review_may_not_authorize_implementation_or_execution'],
'implementation and rerun remain closed':e['executor_remediation_implementation_authorized'] is False and e['runtime_rerun_authorized'] is False,
'only repository executor design review is authorized':z['repository_only_runtime_executor_remediation_design_review_authorized'] is True,
'live candidate binding is forbidden':z['runtime_candidate_binding_authorized'] is False,
'executor remediation and rerun are forbidden':z['runtime_executor_remediation_authorized'] is False and z['runtime_rerun_authorized'] is False,
'package and Slackpkg mutation are forbidden':z['package_action_authorized'] is False and z['slackpkg_mutation_authorized'] is False,
'repository and network refresh are forbidden':z['repository_refresh_authorized'] is False and z['network_access_authorized'] is False,
'boot reboot cleanup and Phase 2 are forbidden':z['boot_action_authorized'] is False and z['reboot_authorized'] is False and z['evidence_cleanup_authorized'] is False and z['phase_2_start_authorized'] is False,
'no machine or controller action is required':p['machine_action_required'] is False and p['controller_action_required'] is False,
'family remains active':p['pause_safe'] is False and p['strong_safe_pause'] is False,
'next stage is executor remediation design review':p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review',
}
for k,v in checks.items(): print(('PASS' if v else 'FAIL')+'\t'+k)
PYSEM
while IFS=$'\t' read -r status label; do [[ $status == PASS ]] && pass "$label" || fail "$label"; done <"$tmp/semantic.out"
assert 'reference document freezes reviewed contract' grep -Fq 'candidate-binding contract is now frozen input' "$doc"
assert 'reference document keeps global pkglist guard retired' grep -Fq 'global `pkglist` row-count guard is permanently retired' "$doc"
assert 'reference document names next stage' grep -Fq 'runtime-executor-design-review' "$doc"
if grep -nE '[[:blank:]]+$' "$doc" >/dev/null; then fail 'step-235 document has no trailing whitespace'; else pass 'step-235 document has no trailing whitespace'; fi
assert 'CHANGELOG records step 235' grep -Fqx '## Phase 1 step 235 kernel-package-edge runtime-transaction remediation runtime candidate-set binding freeze — 2026-09-27' "$repo_root/CHANGELOG.md"
if grep -En '(^|[;&|]) *([[:alnum:]_./-]*/)?(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown|poweroff)( |$)' "$helper" >/dev/null; then fail 'step-235 helper contains no executable network package boot or shutdown command'; else pass 'step-235 helper contains no executable network package boot or shutdown command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && echo PASS || echo FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
