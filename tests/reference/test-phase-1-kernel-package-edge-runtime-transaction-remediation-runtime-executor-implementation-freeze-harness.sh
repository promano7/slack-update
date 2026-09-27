#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze.md"
policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze-policy.json"
record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review-harness.sh"
prior_policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.tsv"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-executor.sh"
old_body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh"
old_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh"
old_executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
passes=0; failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert(){ local label=$1; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }
assert_hash(){ local label=$1 file=$2 expected=$3 actual; actual=$(sha256sum -- "$file"|awk '{print $1}'); [[ $actual == "$expected" ]] && pass "$label" || fail "$label"; }
for f in "$helper" "$doc" "$policy" "$record" "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$body" "$builder" "$executor" "$acceptance_harness" "$old_body" "$old_builder" "$old_executor" "$repo_root/CHANGELOG.md"; do assert "$(basename "$f") is a regular non-symlink file" bash -c '[[ -f "$1" && ! -L "$1" ]]' _ "$f"; done
assert_hash 'accepted step-237 helper hash is frozen' "$prior_helper" '4e11c6176988331cc9e2a21e4297857b3345573bc24f3b60a4db642996b65883'
assert_hash 'accepted step-237 document hash is frozen' "$prior_doc" '249da50ae155c37537fa0f3088c287e4b703defa2e8d60087453202cc120728d'
assert_hash 'accepted step-237 harness hash is frozen' "$prior_harness" '421f6a5c4e9d1bfc52bdc954601827e62138a22cee12758bc9541e96e6339825'
assert_hash 'accepted step-237 policy hash is frozen' "$prior_policy" '75b19adf4c35d1a3f12106388e10e1d5a36b4809a66c8a11c72d90784b878162'
assert_hash 'accepted step-237 record hash is frozen' "$prior_record" '2f08b3896171cd4a8da74fe910cf4bd0c4b74b690cbdba388a08376f09d05ea8'
assert_hash 'historical failed body remains frozen' "$old_body" '47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581'
assert_hash 'historical failed builder remains frozen' "$old_builder" '348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea'
assert_hash 'historical failed executor remains frozen' "$old_executor" '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300'
assert_hash 'remediated body hash is frozen' "$body" 'ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b'
assert_hash 'remediated builder hash is frozen' "$builder" 'a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379'
assert_hash 'remediated executor hash is frozen' "$executor" '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'
assert_hash 'repository acceptance harness hash is frozen' "$acceptance_harness" '9fac7f4ad77454bcec6ec9f3cb4df09cb69be54dbdc6c38652d0c7b7d23f7652'
assert_hash 'step-238 helper hash is frozen' "$helper" 'd24b7d2b62a39878935bdc5a1983a368351937e63aa93ae79b8520039480a0a4'
assert_hash 'step-238 document hash is frozen' "$doc" '96bdc5a543c608deba6e49f9287cf973cabd743ff361268b1cd66aa77c78b80b'
assert_hash 'step-238 policy hash is frozen' "$policy" '8648917cc2ed5188a73d3d2f53d799d11680da224cf98135a28262b7def23e9d'
assert_hash 'step-238 record hash is frozen' "$record" 'e3194088051d95db4df7a6f806a0003db814086a4f66c835ea4fcc7bfe09c902'
assert 'step-238 helper passes bash syntax validation' bash -n "$helper"
assert 'step-238 helper exposes non-mutating help' "$helper" --help
if "$helper" --invalid >/dev/null 2>&1; then fail 'step-238 helper rejects unknown option'; else pass 'step-238 helper rejects unknown option'; fi
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/helper.out"; then pass 'step-238 helper executes successfully'; else fail 'step-238 helper executes successfully'; fi
assert 'helper reproduces frozen policy exactly' cmp -s "$tmp/${policy##*/}" "$policy"
assert 'helper reproduces frozen record exactly' cmp -s "$tmp/${record##*/}" "$record"
assert 'helper reports PASS freeze status' grep -Fqx $'implementation_freeze_status\tPASS' "$tmp/helper.out"
assert 'helper freezes implementation' grep -Fqx $'implementation_frozen\tyes' "$tmp/helper.out"
assert 'helper revalidates repository acceptance' grep -Fqx $'repository_acceptance_result\tPASS (118 passes, 0 failures)' "$tmp/helper.out"
assert 'helper revalidates deterministic builder' grep -Fqx $'builder_reproducibility_reverified\tyes' "$tmp/helper.out"
assert 'helper keeps transport closed' grep -Fqx $'runtime_executor_transport_authorized\tno' "$tmp/helper.out"
python3 - "$policy" "$record" <<'PYSEM' >"$tmp/semantic.out"
import csv,json,sys
p=json.load(open(sys.argv[1])); r=dict(csv.reader(open(sys.argv[2]),delimiter='	'))
f=p['frozen_remediated_executor']; a=p['authorization']; c=p['frozen_candidate_and_refresh_contract']
checks={
'policy identifies step-238 freeze':p['step']==238 and p['scenario'].endswith('runtime-executor-implementation-freeze') and r['step']=='238',
'freeze status is PASS':p['freeze_status']=='PASS' and r['freeze_status']=='PASS',
'step-237 semantics are consumed unchanged':p['accepted_step_237']['semantics_consumed_without_change'] is True,
'no machine authority is inherited':p['accepted_step_237']['no_machine_authority_inherited'] is True,
'implementation state is frozen':f['state']=='implementation-frozen-awaiting-runtime-authorization-review' and r['implementation_frozen']=='yes',
'exact body builder executor hashes are frozen':f['body_sha256']=='ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b' and f['builder_sha256']=='a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379' and f['executor_sha256']=='9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c',
'repository acceptance is reverified':f['repository_acceptance_result']=='PASS (118 passes, 0 failures)' and f['repository_acceptance_harness_sha256']=='9fac7f4ad77454bcec6ec9f3cb4df09cb69be54dbdc6c38652d0c7b7d23f7652',
'builder reproducibility is reverified':f['builder_reproducibility_reverified'] is True and f['canonical_executor_rebuilt_byte_for_byte'] is True,
'historical failed executor remains preserved':p['historical_failed_executor']['preserved_unchanged'] is True,
'candidate guard remains target-specific':c['candidate_guard_scope']=='target-specific-source-backed',
'global pkglist guard remains retired':c['global_pkglist_row_count_guard_retired'] is True and r['global_pkglist_row_count_guard']=='retired',
'fresh workdir and local-source error guard remain frozen':c['fresh_workdir_pkglist_required'] and c['error_downloading_from_local_source_forbidden'],
'exact target and same-transaction binding remain frozen':c['exact_target_candidate_row_count']==1 and c['target_candidate_fullname']=='kernel-headers-6.18.45-x86-1' and c['candidate_binding_lifetime']=='same-runtime-transaction-only',
'evidence encoding remains real-tab TSV':c['evidence_encoding']=='real-tab-tsv' and r['evidence_encoding']=='real-tab-tsv',
'only repository runtime authorization review is opened':a['repository_only_runtime_authorization_review_authorized'] is True,
'executor build and transport remain closed':a['runtime_executor_build_authorized'] is False and a['runtime_executor_transport_authorized'] is False,
'predecessor transport and staging remain closed':a['predecessor_package_transport_authorized'] is False and a['predecessor_package_staging_authorized'] is False,
'Slackpkg refresh binding and apply remain closed':a['temporary_slackpkg_configuration_authorized'] is False and a['local_source_metadata_refresh_authorized'] is False and a['runtime_candidate_binding_authorized'] is False and a['reference_apply_authorized'] is False,
'runtime rerun and package actions remain closed':a['runtime_rerun_authorized'] is False and a['package_action_authorized'] is False and a['slackpkg_mutation_authorized'] is False,
'network boot reboot cleanup and Phase 2 remain closed':a['network_access_authorized'] is False and a['boot_action_authorized'] is False and a['reboot_authorized'] is False and a['evidence_cleanup_authorized'] is False and a['phase_2_start_authorized'] is False,
'no machine or controller action is required':p['machine_action_required'] is False and p['controller_action_required'] is False,
'family remains active':p['pause_safe'] is False and p['strong_safe_pause'] is False,
'next stage is runtime authorization review':p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review',
}
for k,v in checks.items(): print(('PASS' if v else 'FAIL')+'	'+k)
PYSEM
while IFS=$'\t' read -r status label; do [[ $status == PASS ]] && pass "$label" || fail "$label"; done <"$tmp/semantic.out"
assert 'reference document freezes exact implementation' grep -Fq 'The frozen implementation consists of:' "$doc"
assert 'reference document records 118-pass acceptance' grep -Fq 'PASS (118 passes, 0 failures)' "$doc"
assert 'reference document keeps runtime transport closed' grep -Fq 'does not authorize rebuilding for transport' "$doc"
assert 'reference document names runtime authorization review' grep -Fq 'runtime-executor-runtime-authorization-review' "$doc"
for f in "$doc" "$helper"; do if grep -nE '[[:blank:]]+$' "$f" >/dev/null; then fail "$(basename "$f") has no trailing whitespace"; else pass "$(basename "$f") has no trailing whitespace"; fi; done
assert 'CHANGELOG records step 238' grep -Fqx '## Phase 1 step 238 kernel-package-edge runtime-transaction remediation runtime executor implementation freeze — 2026-09-27' "$repo_root/CHANGELOG.md"
if grep -En '(^|[;&|]) *([[:alnum:]_./-]*/)?(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown|poweroff)( |$)' "$helper" >/dev/null; then fail 'step-238 helper contains no executable network package boot or shutdown command'; else pass 'step-238 helper contains no executable network package boot or shutdown command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && echo PASS || echo FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
