#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause.md"
policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause.tsv"
step219_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.sh"
step219_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.md"
step219_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review-harness.sh"
step219_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review-policy.json"
step219_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.tsv"
passes=0; failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1" >&2; failures=$((failures+1)); }
check_file(){ [[ -f $1 && ! -L $1 ]] && pass "$2 is a regular non-symlink file" || fail "$2 is a regular non-symlink file"; }
check_sha(){ local a; a=$(sha256sum -- "$1"|awk '{print $1}'); [[ $a == "$2" ]] && pass "$3 hash is frozen" || fail "$3 hash is frozen"; }
record_value(){ awk -F '\t' -v key="$1" '$1==key {print $2; exit}' "$record"; }

for spec in \
 "$helper|step-220 helper" "$doc|step-220 reference document" "$policy|step-220 policy" "$record|step-220 record" \
 "$step219_helper|accepted step-219 helper" "$step219_doc|accepted step-219 document" "$step219_harness|accepted step-219 harness" "$step219_policy|accepted step-219 policy" "$step219_record|accepted step-219 record"; do
 IFS='|' read -r p l <<<"$spec"; check_file "$p" "$l"; done
check_sha "$step219_helper" '9bf7605293f03686374b1dda5394fd1d0e510886da1f2159a096d15df31b9789' 'accepted step-219 helper'
check_sha "$step219_doc" '782c4d102d3925e3b31d62159ab8c88b69b48d928e433670730f5ad643166180' 'accepted step-219 document'
check_sha "$step219_harness" '0d9b86f4e96fdcbdc1ae326aa4aba130072411f0e9ad7669675b191483b2abb0' 'accepted step-219 harness'
check_sha "$step219_policy" '6a55e2e600dbb192cb7e14e9d3514a9a6dd7ab2ac019fd7478f84d631c670d75' 'accepted step-219 policy'
check_sha "$step219_record" '9bb2cb29fce3529b9d4b726846db433558dfbbb9de5127b54c71d49d13bb982f' 'accepted step-219 record'
if bash -n "$helper"; then pass 'step-220 helper passes bash syntax validation'; else fail 'step-220 helper passes bash syntax validation'; fi
if "$helper" --help >/dev/null; then pass 'step-220 helper exposes non-mutating help'; else fail 'step-220 helper exposes non-mutating help'; fi
if "$helper" --bad >/dev/null 2>&1; then fail 'step-220 helper rejects unknown option'; else pass 'step-220 helper rejects unknown option'; fi

tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/output.tsv"; then pass 'step-220 helper executes successfully'; else fail 'step-220 helper executes successfully'; fi
cmp -s "$tmp/$(basename "$policy")" "$policy" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s "$tmp/$(basename "$record")" "$record" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'
grep -Fqx $'review_status\tPASS' "$tmp/output.tsv" && pass 'helper reports PASS review status' || fail 'helper reports PASS review status'
grep -Fqx $'strong_safe_pause\tyes' "$tmp/output.tsv" && pass 'helper reports strong safe pause' || fail 'helper reports strong safe pause'
grep -Fqx $'runtime_rerun_authorized\tno' "$tmp/output.tsv" && pass 'helper keeps runtime rerun closed' || fail 'helper keeps runtime rerun closed'

if python3 - "$policy" <<'PY'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause'
assert p['step']==220 and p['review_status']=='PASS'
assert p['kernel_package_edge_family_state']=='open-remediation-pending'
assert p['phase_1_acceptance_matrix_complete'] is False
c=p['contained_runtime_failure']
for k in ('cleanup_triggered','header_restored','package_database_restored','slackpkg_configuration_restored','slackpkg_state_restored','geninitrd_policy_restored','boot_artifacts_unchanged','published_success_evidence_absent','failed_run_must_not_be_reused_as_success_evidence'):
    assert c[k] is True
pr=p['preservation_contract']
for k in ('local_source_v1_must_be_preserved_unchanged','failed_runtime_evidence_root_must_be_preserved_unchanged','staged_target_must_be_preserved_unchanged','external_artifact_evidence_must_be_preserved_unchanged','failed_executor_identity_is_historical_only'):
    assert pr[k] is True
assert pr['local_source_v1_may_be_modified_in_place'] is False
assert pr['failed_runtime_evidence_may_be_deleted'] is False
r=p['remediation_contract']
assert r['new_local_source_generation_required'] is True and r['new_local_source_generation_name']=='local-source-v2'
assert r['slackpkg_refresh_compatibility_metadata_required'] is True
assert r['CHECKSUMS_md5_asc_compatibility_artifact_required'] is True
assert r['priority_tree_metadata_required'] is True
assert r['refresh_success_requires_exit_zero'] is True
assert r['refresh_success_requires_no_error_downloading_signal'] is True
assert r['refresh_success_requires_workdir_metadata_freshness_proof'] is True
assert r['candidate_guard_scope']=='target-specific-not-global-pkglist-row-count'
assert r['evidence_encoding']=='real-tab-tsv'
assert r['remediation_must_be_revalidated_before_package_mutation'] is True
assert r['implementation_authorized_at_pause'] is False and r['runtime_rerun_authorized_at_pause'] is False
for v in p['authorization'].values(): assert v is False
rb=p['resume_boundary']
assert rb['fresh_resume_planning_boundary_required'] is True
assert rb['fresh_target_revalidation_required_before_any_machine_action'] is True
assert rb['prior_runtime_authorization_reusable'] is False
assert rb['prior_candidate_binding_reusable'] is False
assert rb['prior_failed_executor_authorization_reusable'] is False
assert rb['local_source_v2_design_and_build_requires_fresh_authorization'] is True
assert rb['remediation_validation_required_before_package_mutation'] is True
s=p['safe_pause']
assert s['strong_safe_pause'] is True and s['pause_safe'] is True and s['no_open_operational_authorization'] is True
assert s['machine_action_required'] is False and s['controller_action_required'] is False
for k,v in s.items():
    if k.endswith('_authority_open'): assert v is False
assert p['machine_action_required'] is False and p['controller_action_required'] is False and p['pause_safe'] is True
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review'
PY
then pass 'step-220 policy semantic assertions pass'; else fail 'step-220 policy semantic assertions pass'; fi

for pair in \
 'step:220' 'review_status:PASS' 'kernel_package_edge_family_state:open-remediation-pending' 'phase_1_acceptance_matrix_complete:no' \
 'failure_characterization_status:PASS' 'cleanup_triggered:yes' 'header_restored:yes' 'package_database_restored:yes' \
 'slackpkg_configuration_restored:yes' 'slackpkg_state_restored:yes' 'geninitrd_policy_restored:yes' 'boot_artifacts_unchanged:yes' \
 'published_success_evidence_absent:yes' 'local_source_v1_must_be_preserved_unchanged:yes' 'failed_runtime_evidence_root_must_be_preserved_unchanged:yes' \
 'new_local_source_generation_required:yes' 'new_local_source_generation_name:local-source-v2' 'remediation_must_be_revalidated_before_package_mutation:yes' \
 'fresh_resume_planning_boundary_required:yes' 'fresh_target_revalidation_required_before_any_machine_action:yes' 'prior_runtime_authorization_reusable:no' \
 'prior_candidate_binding_reusable:no' 'runtime_rerun_authorized:no' 'package_action_authorized:no' 'slackpkg_mutation_authorized:no' \
 'repository_refresh_authorized:no' 'network_access_authorized:no' 'boot_action_authorized:no' 'reboot_authorized:no' \
 'evidence_cleanup_authorized:no' 'phase_2_start_authorized:no' 'machine_action_required:no' 'controller_action_required:no' \
 'strong_safe_pause:yes' 'pause_safe:yes'; do
 key=${pair%%:*}; val=${pair#*:}; [[ $(record_value "$key") == "$val" ]] && pass "record freezes: $key" || fail "record freezes: $key"; done

grep -Fq 'strong safe pause' "$doc" && pass 'reference document records strong safe pause' || fail 'reference document records strong safe pause'
grep -Fq 'family remains open' "$doc" && pass 'reference document keeps kernel-package-edge family open' || fail 'reference document keeps kernel-package-edge family open'
grep -Fq 'local-source-v2' "$doc" && pass 'reference document preserves v2 remediation' || fail 'reference document preserves v2 remediation'
grep -Fq 'must remain unchanged' "$doc" && pass 'reference document preserves historical evidence' || fail 'reference document preserves historical evidence'
grep -Fq 'No controller transport' "$doc" && pass 'reference document closes all operational authorization' || fail 'reference document closes all operational authorization'
grep -Fq 'fresh target revalidation' "$doc" && pass 'reference document requires fresh target revalidation on resume' || fail 'reference document requires fresh target revalidation on resume'
grep -Fq 'Phase 1 step 220 kernel-package-edge runtime transaction remediation boundary review and strong safe pause' "$repo_root/CHANGELOG.md" && pass 'CHANGELOG records step 220' || fail 'CHANGELOG records step 220'
if grep -Eq '(^|[;&|[:space:]])(upgradepkg|installpkg|removepkg|slackpkg|reboot|shutdown|poweroff)[[:space:]]' "$helper"; then fail 'step-220 helper contains no executable package/boot command'; else pass 'step-220 helper contains no executable package/boot command'; fi
if grep -Eq '(^|[;&|[:space:]])(curl|wget|ftp)[[:space:]]' "$helper"; then fail 'step-220 helper contains no network client command'; else pass 'step-220 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
