#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.md"
policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review.tsv"
old_body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh"
old_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh"
old_executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-executor.sh"
changelog="$repo_root/CHANGELOG.md"

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail_test() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
regular() { [[ -f $1 && ! -L $1 ]]; }

for pair in \
    "$helper|step-237 helper" "$doc|step-237 reference document" "$policy|step-237 policy" "$record|step-237 record" \
    "$prior_helper|accepted step-236 helper" "$prior_doc|accepted step-236 document" "$prior_harness|accepted step-236 harness" \
    "$prior_policy|accepted step-236 policy" "$prior_record|accepted step-236 record" \
    "$old_body|historical failed body" "$old_builder|historical failed builder" "$old_executor|historical failed executor" \
    "$body|remediated body" "$builder|remediated builder" "$executor|remediated executor" \
    "$acceptance_harness|remediated executor acceptance harness" "$changelog|CHANGELOG"; do
    file=${pair%%|*}; label=${pair#*|}
    if regular "$file"; then pass "$label is a regular non-symlink file"; else fail_test "$label is missing or unsafe"; fi
done

for spec in \
    "$prior_helper|f76b7e618c879565cc9e8483a7db435eb16826d39d96506702ed0ab63c9e94cb|accepted step-236 helper hash is frozen" \
    "$prior_doc|3ae3393f2ae2c991e1396fefa24e52ba50b887f4e6a93a3761d7898753816b4b|accepted step-236 document hash is frozen" \
    "$prior_harness|b9b1afd118dc06f13ee50e9b713d0260e3504e2fb66284dfbdd61d29418bd7d5|accepted step-236 harness hash is frozen" \
    "$prior_policy|0a861ac5ca77f427664ae521245d91cf209bfc92099a7cedb2f47cb250d7a559|accepted step-236 policy hash is frozen" \
    "$prior_record|68fe35a6d3ae05325307033178d7cf0f151cf1f2d1d56058c46c71162dcb6269|accepted step-236 record hash is frozen" \
    "$old_body|47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581|historical failed body hash is frozen" \
    "$old_builder|348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea|historical failed builder hash is frozen" \
    "$old_executor|09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300|historical failed executor hash is frozen" \
    "$body|ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b|remediated body hash is frozen" \
    "$builder|a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379|remediated builder hash is frozen" \
    "$executor|9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c|remediated executor hash is frozen" \
    "$acceptance_harness|9fac7f4ad77454bcec6ec9f3cb4df09cb69be54dbdc6c38652d0c7b7d23f7652|repository acceptance harness hash is frozen" \
    "$helper|4e11c6176988331cc9e2a21e4297857b3345573bc24f3b60a4db642996b65883|step-237 helper hash is frozen" \
    "$doc|249da50ae155c37537fa0f3088c287e4b703defa2e8d60087453202cc120728d|step-237 document hash is frozen" \
    "$policy|75b19adf4c35d1a3f12106388e10e1d5a36b4809a66c8a11c72d90784b878162|step-237 policy hash is frozen" \
    "$record|2f08b3896171cd4a8da74fe910cf4bd0c4b74b690cbdba388a08376f09d05ea8|step-237 record hash is frozen"; do
    file=${spec%%|*}; rest=${spec#*|}; expected=${rest%%|*}; label=${rest#*|}
    [[ $(sha "$file") == "$expected" ]] && pass "$label" || fail_test "$label"
done

bash -n "$helper" && pass 'step-237 helper passes bash syntax validation' || fail_test 'step-237 helper has invalid shell syntax'
"$helper" --help >/dev/null 2>&1 && pass 'step-237 helper exposes non-mutating help' || fail_test 'step-237 helper help failed'
if "$helper" --unknown >/dev/null 2>&1; then fail_test 'step-237 helper accepts unknown option'; else pass 'step-237 helper rejects unknown option'; fi

regen=$(mktemp -d)
trap 'rm -rf -- "$regen"' EXIT
if "$helper" --output-dir "$regen" >/dev/null 2>&1; then pass 'step-237 helper executes successfully'; else fail_test 'step-237 helper execution failed'; fi
cmp -s "$policy" "$regen/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review-policy.json" && pass 'helper reproduces frozen policy exactly' || fail_test 'helper policy output differs from frozen fixture'
cmp -s "$record" "$regen/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review.tsv" && pass 'helper reproduces frozen record exactly' || fail_test 'helper record output differs from frozen fixture'

acceptance_output="$regen/acceptance.out"
if bash "$acceptance_harness" > "$acceptance_output"; then pass 'remediated executor repository acceptance harness passes'; else fail_test 'remediated executor repository acceptance harness failed'; fi
grep -Fxq 'Result: PASS (118 passes, 0 failures)' "$acceptance_output" && pass 'repository acceptance result is frozen at 118 passes' || fail_test 'repository acceptance pass count drift'

if python3 - "$policy" "$record" <<'PY'
import csv,json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
with open(sys.argv[2],encoding='utf-8',newline='') as h:
    r=dict(csv.reader(h,delimiter='\t'))
assert p['step']==237
assert p['review_status']=='PASS'
assert p['accepted_step_236']['design_consumed_without_change'] is True
assert p['accepted_step_236']['no_machine_authority_inherited'] is True
assert p['historical_failed_executor']['preserved_unchanged'] is True
assert p['historical_failed_executor']['runtime_authorization_reusable'] is False
impl=p['remediated_executor_implementation']
assert impl['state']=='implemented-reviewed-awaiting-freeze'
assert impl['body_sha256']=='ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b'
assert impl['builder_sha256']=='a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379'
assert impl['executor_sha256']=='9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'
assert impl['repository_acceptance_result']=='PASS (118 passes, 0 failures)'
assert impl['payload_reproducibility']=='builder-output-matches-canonical-executor-byte-for-byte'
assert impl['runtime_acknowledgement']=='--execute-runtime-remediation-validation'
rem=p['reviewed_remediations']
assert rem['isolated_slackpkg_workdir'] is True
assert rem['isolated_slackpkg_temp'] is True
assert rem['fresh_workdir_pkglist_required'] is True
assert rem['canonical_var_lib_pkglist_non_authoritative'] is True
assert rem['error_downloading_from_local_source_forbidden'] is True
assert rem['candidate_guard_scope']=='target-specific-source-backed'
assert rem['auxiliary_pkglist_rows_without_backing_v2_package_bytes_are_not_candidates'] is True
assert rem['exact_target_candidate_row_count']==1
assert rem['global_pkglist_row_count_guard_retired'] is True
assert rem['evidence_encoding']=='real-tab-tsv'
assert rem['historical_failed_evidence_preserved_before_and_after_transaction'] is True
assert rem['local_source_v1_preserved_before_and_after_transaction'] is True
a=p['authorization']
assert a['repository_only_runtime_executor_implementation_freeze_authorized'] is True
for key,value in a.items():
    if key!='repository_only_runtime_executor_implementation_freeze_authorized':
        assert value is False, (key,value)
assert p['machine_action_required'] is False
assert p['controller_action_required'] is False
assert p['pause_safe'] is False
assert p['strong_safe_pause'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze'
assert r['step']=='237'
assert r['review_status']=='PASS'
assert r['historical_failed_executor_preserved']=='yes'
assert r['remediated_executor_state']=='implemented-reviewed-awaiting-freeze'
assert r['global_pkglist_row_count_guard']=='retired'
assert r['runtime_executor_transport_authorized']=='no'
assert r['runtime_rerun_authorized']=='no'
assert r['next_stage']==p['next_stage']
PY
then pass 'step-237 policy and record semantic assertions pass'; else fail_test 'step-237 policy or record semantic assertions failed'; fi

for needle in \
    'historical failed executor generation remains unchanged evidence' \
    'PASS (118 passes, 0 failures)' \
    'Auxiliary `pkglist` rows are not themselves candidates' \
    'real tab characters through `record_kv`' \
    'repository-side freeze of the reviewed implementation' \
    'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze'; do
    grep -Fq "$needle" "$doc" && pass "reference document records: $needle" || fail_test "reference document missing: $needle"
done

if grep -n '[[:blank:]]$' "$doc" >/dev/null; then fail_test 'step-237 document contains trailing whitespace'; else pass 'step-237 document has no trailing whitespace'; fi
if grep -n '[[:blank:]]$' "$helper" >/dev/null; then fail_test 'step-237 helper contains trailing whitespace'; else pass 'step-237 helper has no trailing whitespace'; fi
if grep -n '[[:blank:]]$' "$acceptance_harness" >/dev/null; then fail_test 'repository acceptance harness contains trailing whitespace'; else pass 'repository acceptance harness has no trailing whitespace'; fi

grep -Fq '## Phase 1 step 237 kernel-package-edge runtime-transaction remediation runtime executor implementation review' "$changelog" && pass 'CHANGELOG records step 237' || fail_test 'CHANGELOG does not record step 237'

if grep -Eq '^[[:space:]]*(curl|wget|ftp|rsync|scp|ssh|ping|slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail_test 'step-237 helper contains executable machine/package/network command text'
else
    pass 'step-237 helper contains no machine/package/network command text'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
