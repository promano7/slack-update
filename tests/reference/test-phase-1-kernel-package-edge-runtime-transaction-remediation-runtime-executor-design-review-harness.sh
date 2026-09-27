#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze-harness.sh"
prior_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze-policy.json"
prior_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.tsv"
old_body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh"
old_build="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh"
old_exec="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
failure_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review-policy.json"
failure_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.tsv"
reference_file="$repo_root/tools/reference/slack-update-reference.sh"
config_file="$repo_root/data/config/slack-update.conf"
passes=0; failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert(){ local label=$1; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }
assert_hash(){ local label=$1 file=$2 expected=$3 actual; actual=$(sha256sum -- "$file"|awk '{print $1}'); [[ $actual == "$expected" ]] && pass "$label" || fail "$label"; }
for f in "$helper" "$doc" "$policy" "$record" "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$old_body" "$old_build" "$old_exec" "$failure_policy" "$failure_record" "$reference_file" "$config_file" "$repo_root/CHANGELOG.md"; do assert "$(basename "$f") is a regular non-symlink file" bash -c '[[ -f "$1" && ! -L "$1" ]]' _ "$f"; done
assert_hash 'accepted step-235 helper hash is frozen' "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.sh" '0ea822e030dbf22304f4564f9e075fc0e1d3da38f2b9b0621b986ac5f3783cf8'
assert_hash 'accepted step-235 document hash is frozen' "$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.md" '2cd5540b287845ef178c3e4387bdfa6e9debaebfa9405f1784a59e629d6018ba'
assert_hash 'accepted step-235 harness hash is frozen' "$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze-harness.sh" '2271d7157ef3f9cff268549fd344b103bed8c3da75be106f6c7c20f37666c3b4'
assert_hash 'accepted step-235 policy hash is frozen' "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze-policy.json" '73244a59e776a9a9ab41802d1995211a1e3ba2505cb36bf950f09ba7084f6878'
assert_hash 'accepted step-235 record hash is frozen' "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze.tsv" '0496250d4f680485559b043278725c5437f6fe830d2692640feeb479b4b8f389'
assert_hash 'historical failed executor body hash is frozen' "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh" '47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581'
assert_hash 'historical failed executor builder hash is frozen' "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh" '348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea'
assert_hash 'historical failed executor payload hash is frozen' "$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh" '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300'
assert_hash 'accepted step-219 failure policy hash is frozen' "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review-policy.json" '6a55e2e600dbb192cb7e14e9d3514a9a6dd7ab2ac019fd7478f84d631c670d75'
assert_hash 'accepted step-219 failure record hash is frozen' "$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.tsv" '9bb2cb29fce3529b9d4b726846db433558dfbbb9de5127b54c71d49d13bb982f'
assert_hash 'frozen reference script hash is frozen' "$repo_root/tools/reference/slack-update-reference.sh" '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
assert_hash 'frozen effective config hash is frozen' "$repo_root/data/config/slack-update.conf" '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
assert_hash 'step-236 helper hash is frozen' "$helper" 'f76b7e618c879565cc9e8483a7db435eb16826d39d96506702ed0ab63c9e94cb'
assert_hash 'step-236 document hash is frozen' "$doc" '3ae3393f2ae2c991e1396fefa24e52ba50b887f4e6a93a3761d7898753816b4b'
assert_hash 'step-236 policy hash is frozen' "$policy" '0a861ac5ca77f427664ae521245d91cf209bfc92099a7cedb2f47cb250d7a559'
assert_hash 'step-236 record hash is frozen' "$record" '68fe35a6d3ae05325307033178d7cf0f151cf1f2d1d56058c46c71162dcb6269'
assert 'step-236 helper passes bash syntax validation' bash -n "$helper"
assert 'step-236 helper exposes non-mutating help' "$helper" --help
if "$helper" --invalid >/dev/null 2>&1; then fail 'step-236 helper rejects unknown option'; else pass 'step-236 helper rejects unknown option'; fi
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/helper.out"; then pass 'step-236 helper executes successfully'; else fail 'step-236 helper executes successfully'; fi
assert 'helper reproduces frozen policy exactly' cmp -s "$tmp/${policy##*/}" "$policy"
assert 'helper reproduces frozen record exactly' cmp -s "$tmp/${record##*/}" "$record"
assert 'helper reports PASS design review' grep -Fqx $'review_status\tPASS' "$tmp/helper.out"
assert 'helper preserves failed executor' grep -Fqx $'historical_failed_executor_preserved\tyes' "$tmp/helper.out"
assert 'helper requires new executor generation' grep -Fqx $'new_executor_generation_required\tyes' "$tmp/helper.out"
assert 'helper freezes target-specific guard' grep -Fqx $'candidate_guard_scope\ttarget-specific' "$tmp/helper.out"
assert 'helper forbids global pkglist row guard' grep -Fqx $'global_pkglist_row_count_guard\tforbidden' "$tmp/helper.out"
assert 'helper freezes real-tab evidence' grep -Fqx $'evidence_encoding\treal-tab-tsv' "$tmp/helper.out"
python3 - "$policy" "$record" <<'PYSEM' >"$tmp/semantic.out"
import csv,json,sys
p=json.load(open(sys.argv[1])); r=dict(csv.reader(open(sys.argv[2]),delimiter='\t'))
h=p['historical_failed_executor']; d=p['remediated_executor_design']; s=d['slackpkg_isolation']; g=d['refresh_guard']; c=d['candidate_guard']; e=d['evidence_remediation']; u=d['unchanged_transaction_semantics']; a=p['authorization']; i=p['implementation_boundary']
checks={
'policy identifies step-236 design':p['step']==236 and p['scenario'].endswith('runtime-executor-design-review') and r['step']=='236',
'design review status is PASS':p['review_status']=='PASS' and r['review_status']=='PASS',
'step-235 contract is consumed unchanged':p['accepted_step_235']['candidate_binding_contract_consumed_without_change'] is True,
'no machine authority is inherited':p['accepted_step_235']['no_machine_authority_inherited'] is True,
'historical executor remains immutable evidence':h['state']=='historical-failed-evidence-do-not-modify-in-place' and h['runtime_authorization_reusable'] is False,
'historical failure mechanism is preserved':h['refresh_exit_status_observed']==0 and h['refresh_error_signal_observed']=='error-downloading-from-local-source' and '2032' in h['observed_failure'],
'new executor generation is required':d['new_generation_required'] and d['old_executor_files_must_not_be_modified_in_place'],
'new evidence root is separate':d['runtime_evidence_root'].endswith('runtime-transaction-remediation'),
'fresh runtime identity is frozen':p['frozen_inputs']['boot_id']=='fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9' and p['frozen_inputs']['running_kernel']=='6.18.45',
'v2 source identity is frozen':p['frozen_inputs']['local_source_v2_tree_manifest_sha256']=='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
'preflight requires exact v2 verification':all(d['pre_execution_gate'][k] for k in ['local_source_v2_manifest_sidecar_must_verify','local_source_v2_exact_manifest_coverage_must_verify','local_source_v2_priority_tree_contract_must_verify','local_source_v2_compatibility_asc_must_be_present']),
'failed evidence must remain present':d['pre_execution_gate']['failed_runtime_evidence_root_must_remain_present'] is True,
'transaction WORKDIR is isolated':s['rewrite_WORKDIR_to_transaction_owned_path'] and s['transaction_workdir_must_start_empty'] and s['pre_refresh_pkglist_must_be_absent'] and s['post_refresh_pkglist_must_be_regular_and_present'],
'transaction TEMP is isolated':s['rewrite_TEMP_to_transaction_owned_path'] is True,
'canonical var-lib pkglist is non-authoritative':s['canonical_var_lib_slackpkg_must_not_be_used_as_refresh_evidence'] is True,
'canonical Slackpkg state must be unchanged':s['canonical_var_lib_slackpkg_fingerprint_must_be_unchanged_after_transaction'] is True,
'refresh is network-isolated':g['network_namespace']=='unshare-network-disabled' and g['external_network_access_allowed'] is False,
'refresh rejects silent local-source error':g['exit_status_must_be_zero'] and g['error_downloading_from_local_source_signal_forbidden'] and g['stdout_and_stderr_must_be_captured'],
'fresh pkglist creation proves refresh':g['workdir_pkglist_creation_is_required_freshness_proof'] is True,
'target-specific candidate guard replaces global guard':c['scope']=='target-specific' and c['global_pkglist_row_count_guard_forbidden'] is True,
'exact target candidate is frozen':c['exact_target_candidate_row_count']==1 and c['target_candidate_fullname']=='kernel-headers-6.18.45-x86-1' and c['target_candidate_location']=='./slackware64/d',
'unexpected candidate classes remain zero':c['install_new_candidate_count']==0 and c['non_header_upgrade_candidate_count']==0 and c['configured_boot_package_upgrade_candidate_count']==0,
'candidate binding remains same transaction':c['binding_lifetime']=='same-runtime-transaction-only' and c['binding_must_be_consumed_without_pause'],
'evidence encoding is remediated':e['encoding']=='real-tab-tsv' and e['literal_backslash_t_field_separators_forbidden'] and e['preflight_tsv_must_use_record_kv_or_printf_real_tabs'] and e['candidate_binding_tsv_must_use_record_kv_or_printf_real_tabs'],
'core transaction semantics remain unchanged':all(u[k] for k in ['stage_only_frozen_predecessor_header','header_only_package_delta_required','reference_apply_uses_frozen_reference_and_derived_config','reference_apply_runs_without_external_network','rollback_restores_target_header_on_any_failure_after_mutation','slackpkg_configuration_restored','geninitrd_policy_restored','boot_artifacts_unchanged','no_reboot','success_evidence_published_only_after_final_invariants_pass']),
'kernel reference expectations remain exact':u['expected_kernel_trigger_count']==1 and u['expected_initrd_update_count']==0 and u['expected_grub_update_count']==0,
'implementation review is repository-only':i['repository_only_implementation_review_authorized'] and i['implementation_review_may_not_transport_or_execute_payload'],
'implementation must use new files':i['implementation_must_create_new_generation_files'] is True,
'runtime authorization remains future-only':i['machine_runtime_authorization_requires_later_explicit_step'] is True,
'only repository implementation review is open':a['repository_only_runtime_executor_remediation_implementation_review_authorized'] is True,
'build transport and rerun are closed':a['runtime_executor_remediation_build_authorized'] is False and a['runtime_executor_transport_authorized'] is False and a['runtime_rerun_authorized'] is False,
'package Slackpkg and candidate actions are closed':a['package_action_authorized'] is False and a['slackpkg_mutation_authorized'] is False and a['runtime_candidate_binding_authorized'] is False,
'network boot reboot cleanup and Phase 2 are closed':a['network_access_authorized'] is False and a['boot_action_authorized'] is False and a['reboot_authorized'] is False and a['evidence_cleanup_authorized'] is False and a['phase_2_start_authorized'] is False,
'no machine or controller action is required':p['machine_action_required'] is False and p['controller_action_required'] is False,
'family remains active':p['pause_safe'] is False and p['strong_safe_pause'] is False,
'next stage is remediation implementation review':p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review',
}
for k,v in checks.items(): print(('PASS' if v else 'FAIL')+'\t'+k)
PYSEM
while IFS=$'\t' read -r status label; do [[ $status == PASS ]] && pass "$label" || fail "$label"; done <"$tmp/semantic.out"
assert 'reference document preserves historical executor' grep -Fq 'historical files must remain byte-for-byte unchanged' "$doc"
assert 'reference document retires global pkglist guard' grep -Fq 'global `pkglist` row-count guard is permanently retired' "$doc"
assert 'reference document defines transaction-owned WORKDIR' grep -Fq 'rewrites Slackpkg `WORKDIR` to a new transaction-owned directory' "$doc"
assert 'reference document requires error-signal rejection' grep -Fq 'without `error-downloading-from-local-source`' "$doc"
assert 'reference document requires real tabs' grep -Fq 'Literal `\t` separators' "$doc"
assert 'reference document names next stage' grep -Fq 'runtime-executor-implementation-review' "$doc"
if grep -nE '[[:blank:]]+$' "$doc" >/dev/null; then fail 'step-236 document has no trailing whitespace'; else pass 'step-236 document has no trailing whitespace'; fi
assert 'CHANGELOG records step 236' grep -Fqx '## Phase 1 step 236 kernel-package-edge runtime-transaction remediation runtime executor design review — 2026-09-27' "$repo_root/CHANGELOG.md"
if grep -En '(^|[;&|]) *([[:alnum:]_./-]*/)?(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown|poweroff)( |$)' "$helper" >/dev/null; then fail 'step-236 helper contains no executable network package boot or shutdown command'; else pass 'step-236 helper contains no executable network package boot or shutdown command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && echo PASS || echo FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
