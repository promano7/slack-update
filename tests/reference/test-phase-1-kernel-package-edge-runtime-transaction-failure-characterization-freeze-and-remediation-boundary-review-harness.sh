#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.sh"
policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.tsv"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.md"
step218_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review-policy.json"
step218_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review.tsv"
step218_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-probe.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
source_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures+1)); }
check_file() {
    local path=$1 label=$2
    if [[ -f $path && ! -L $path ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi
}
check_sha() {
    local path=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    if [[ $actual == "$expected" ]]; then pass "$label hash is frozen"; else fail "$label hash is frozen"; fi
}
record_value() { awk -F '\t' -v key="$1" '$1==key {print $2; exit}' "$record"; }

check_file "$helper" 'step-219 helper'
check_file "$policy" 'step-219 policy'
check_file "$record" 'step-219 record'
check_file "$doc" 'step-219 reference document'
check_file "$step218_policy" 'accepted step-218-r1 policy'
check_file "$step218_record" 'accepted step-218-r1 record'
check_file "$step218_probe" 'accepted step-218-r1 probe'
check_file "$executor" 'failed step-217 executor'
check_file "$source_builder" 'accepted local-source builder'

check_sha "$step218_policy" 'b60151eb7065a9300e931c8918f00553d8b34924fbbcd6d27def95787886389d' 'accepted step-218-r1 policy'
check_sha "$step218_record" '07141eefbc338fe7b41bae866c26ce7b7c4eba0a0aec7d4ead0b48d85ac66627' 'accepted step-218-r1 record'
check_sha "$step218_probe" '0f9388cde7fcb178e8f06ff2b200d503c29fb454fa9502091701cc5d2752098d' 'accepted step-218-r1 probe'
check_sha "$executor" '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300' 'failed executor'
check_sha "$source_builder" '59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92' 'accepted local-source builder'

if bash -n "$helper"; then pass 'step-219 helper passes bash syntax validation'; else fail 'step-219 helper passes bash syntax validation'; fi
if "$helper" --help >/dev/null; then pass 'step-219 helper exposes non-mutating help'; else fail 'step-219 helper exposes non-mutating help'; fi
if "$helper" --definitely-invalid >/dev/null 2>&1; then fail 'step-219 helper rejects unknown option'; else pass 'step-219 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp" > "$tmp/output.tsv"; then pass 'step-219 helper executes successfully'; else fail 'step-219 helper executes successfully'; fi
if cmp -s "$tmp/$(basename "$policy")" "$policy"; then pass 'helper reproduces frozen policy exactly'; else fail 'helper reproduces frozen policy exactly'; fi
if cmp -s "$tmp/$(basename "$record")" "$record"; then pass 'helper reproduces frozen record exactly'; else fail 'helper reproduces frozen record exactly'; fi

grep -Fqx $'review_status\tPASS' "$tmp/output.tsv" && pass 'helper reports PASS review status' || fail 'helper reports PASS review status'
grep -Fqx $'failure_characterization_status\tPASS' "$tmp/output.tsv" && pass 'helper freezes PASS failure characterization' || fail 'helper freezes PASS failure characterization'
grep -Fqx $'runtime_rerun_authorized\tno' "$tmp/output.tsv" && pass 'helper keeps runtime rerun unauthorized' || fail 'helper keeps runtime rerun unauthorized'

if python3 - "$policy" <<'PY'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review'
assert p['step']==219
assert p['review_status']=='PASS'
assert p['failure_characterization_status']=='PASS'
for k in ('cleanup_triggered','header_restored','package_database_restored','slackpkg_configuration_restored','slackpkg_state_restored','geninitrd_policy_restored','boot_artifacts_unchanged','published_success_evidence_absent'):
    assert p[k] is True
assert p['failed_run_slackpkg_update_exit_code']==0
assert p['failed_run_slackpkg_update_error_signal']=='error-downloading-from-local-source'
assert p['restored_pkglist_rows']==2032
assert p['restored_pkglist_target_rows']==1
assert p['local_source_CHECKSUMS_md5_asc_absent'] is True
f=p['failure_mechanism']
assert f['slackpkg_refresh_exit_code_alone_is_sufficient'] is False
assert f['local_source_v1_is_slackpkg_update_compatible'] is False
assert f['global_pkglist_row_count_is_valid_candidate_guard'] is False
assert f['preflight_literal_backslash_t_is_accepted_for_future_runs'] is False
r=p['remediation_boundary']
assert r['preserve_local_source_v1'] is True
assert r['preserve_failed_evidence_root'] is True
assert r['modify_local_source_v1_in_place'] is False
assert r['new_local_source_generation_required'] is True
assert r['new_local_source_generation_name']=='local-source-v2'
assert r['new_local_source_requires_slackpkg_refresh_compatibility_metadata'] is True
assert r['new_local_source_requires_CHECKSUMS_md5_asc_compatibility_artifact'] is True
assert r['new_local_source_requires_priority_tree_metadata'] is True
assert r['metadata_authenticity_source']=='frozen-package-sha256-and-tree-manifest-not-local-compatibility-asc'
assert r['refresh_success_requires_exit_zero'] is True
assert r['refresh_success_requires_no_error_downloading_signal'] is True
assert r['refresh_success_requires_workdir_metadata_freshness_proof'] is True
assert r['candidate_guard_scope']=='target-specific-not-global-pkglist-row-count'
assert r['candidate_guard_requires_exactly_one_target_row'] is True
assert r['candidate_guard_requires_predecessor_installed'] is True
assert r['candidate_guard_requires_target_source_binding'] is True
assert r['evidence_encoding']=='real-tab-tsv'
assert r['remediation_must_be_revalidated_before_package_mutation'] is True
for k in ('runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','persistent_configuration_change_authorized','machine_action_required','controller_action_required','pause_safe'):
    assert p[k] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause'
PY
then pass 'step-219 policy semantic assertions pass'; else fail 'step-219 policy semantic assertions pass'; fi

for pair in \
    'step:219' \
    'review_status:PASS' \
    'failure_characterization_status:PASS' \
    'cleanup_triggered:yes' \
    'header_restored:yes' \
    'package_database_restored:yes' \
    'slackpkg_configuration_restored:yes' \
    'slackpkg_state_restored:yes' \
    'geninitrd_policy_restored:yes' \
    'boot_artifacts_unchanged:yes' \
    'published_success_evidence_absent:yes' \
    'failed_run_slackpkg_update_exit_code:0' \
    'restored_pkglist_rows:2032' \
    'restored_pkglist_target_rows:1' \
    'local_source_v1_preserved:yes' \
    'failed_evidence_root_preserved:yes' \
    'modify_local_source_v1_in_place:no' \
    'new_local_source_generation_required:yes' \
    'new_local_source_generation_name:local-source-v2' \
    'slackpkg_refresh_compatibility_metadata_required:yes' \
    'refresh_success_requires_no_error_downloading_signal:yes' \
    'refresh_success_requires_workdir_metadata_freshness_proof:yes' \
    'candidate_guard_scope:target-specific-not-global-pkglist-row-count' \
    'evidence_encoding:real-tab-tsv' \
    'runtime_rerun_authorized:no' \
    'package_action_authorized:no' \
    'slackpkg_mutation_authorized:no' \
    'network_access_authorized:no' \
    'boot_action_authorized:no' \
    'reboot_authorized:no' \
    'machine_action_required:no' \
    'pause_safe:no'; do
    key=${pair%%:*}; expected=${pair#*:}
    if [[ $(record_value "$key") == "$expected" ]]; then pass "record freezes: $key"; else fail "record freezes: $key"; fi
done

grep -Fq 'successful rollback' "$doc" && pass 'reference document records successful rollback' || fail 'reference document records successful rollback'
grep -Fq 'local-source-v2' "$doc" && pass 'reference document selects separate v2 source' || fail 'reference document selects separate v2 source'
grep -Fq 'must not be edited in place' "$doc" && pass 'reference document preserves v1 evidence' || fail 'reference document preserves v1 evidence'
grep -Fq 'error-downloading-from-local-source' "$doc" && pass 'reference document freezes Slackpkg error signal' || fail 'reference document freezes Slackpkg error signal'
grep -Fq 'real tab characters' "$doc" && pass 'reference document remediates evidence encoding' || fail 'reference document remediates evidence encoding'
grep -Fq 'global `pkglist` row-count requirement is retired' "$doc" && pass 'reference document retires global pkglist guard' || fail 'reference document retires global pkglist guard'
grep -Fq 'Phase 1 step 219 kernel-package-edge runtime transaction failure characterization freeze and remediation boundary review' "$repo_root/CHANGELOG.md" && pass 'CHANGELOG records step 219' || fail 'CHANGELOG records step 219'

if grep -Eq '(^|[;&|[:space:]])(upgradepkg|installpkg|removepkg|slackpkg|reboot|shutdown|poweroff)[[:space:]]' "$helper"; then fail 'step-219 helper contains no executable package/boot command'; else pass 'step-219 helper contains no executable package/boot command'; fi
if grep -Eq '(^|[;&|[:space:]])(curl|wget|ftp)[[:space:]]' "$helper"; then fail 'step-219 helper contains no network client command'; else pass 'step-219 helper contains no network client command'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
