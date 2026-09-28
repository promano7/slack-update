#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review.md"
policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review.tsv"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
changelog="$repo_root/CHANGELOG.md"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze.tsv"
contract_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze-policy.json"
contract_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze.tsv"

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail_test() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
regular() { [[ -f $1 && ! -L $1 ]]; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
contains() { grep -Fq -- "$2" "$1"; }

for pair in \
    "$helper|step-254 helper" \
    "$doc|step-254 document" \
    "$policy|step-254 policy" \
    "$record|step-254 record" \
    "$body|executor-v2 body" \
    "$builder|executor-v2 builder" \
    "$executor|executor-v2 canonical payload" \
    "$acceptance_harness|executor-v2 acceptance harness" \
    "$prior_policy|accepted step-253 policy" \
    "$prior_record|accepted step-253 record" \
    "$contract_policy|accepted step-246 contract policy" \
    "$contract_record|accepted step-246 contract record" \
    "$changelog|CHANGELOG"; do
    file=${pair%%|*}
    label=${pair#*|}
    if regular "$file"; then pass "$label exists as regular file"; else fail_test "$label is missing or unsafe"; fi
done

for spec in \
    "$helper|40a8c9eb74607c9edd05607896acc61425f5c1b74aa33ecba5acba140c93e6bf|step-254 helper" \
    "$doc|65de7659747f947bf9299a75d801d0f913939c563b56fb06586c4ae2453d5936|step-254 document" \
    "$policy|ac95d38ea65cb8911c09c93ca5cd33d106e016347cfc906ca329b106cfdaa537|step-254 policy" \
    "$record|21003cc3cf68ea8996578e9b132ccbde615ef4b91958471857a10557d1802cde|step-254 record" \
    "$body|c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68|executor-v2 body" \
    "$builder|43c858e351d32c4ed2c28c687ccc9a06a1fc78f77032eaf20fb3d40a3ff197da|executor-v2 builder" \
    "$executor|deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d|executor-v2 payload" \
    "$acceptance_harness|86fcfd31ebe023d6fdfe3ec0c0c6bebaac3a17fd47202de43ffa3afe89854eef|executor-v2 acceptance harness" \
    "$prior_policy|af5a87022c2379ede9d7c6ec4fae4d15fc86bf08b491b3ea21082bebe5ff8d84|accepted step-253 policy" \
    "$prior_record|ec9b98e3b48fcc35c02d9e3fa50b9cba2b23e051e46af0e957519dd67ec56b97|accepted step-253 record" \
    "$contract_policy|cf32f3d6b5df64d176c154e506c356c53e63da794c961edbbcbf1557ecef25f0|accepted step-246 contract policy" \
    "$contract_record|2f55b4a83a498fdf1c347ba2f35c25b5b0a3a87233f3df66f2362cfa12491071|accepted step-246 contract record"; do
    file=${spec%%|*}; rest=${spec#*|}; expected=${rest%%|*}; label=${rest#*|}
    if [[ $(sha "$file") == "$expected" ]]; then pass "$label SHA-256 matches"; else fail_test "$label SHA-256 drift"; fi
done

bash -n "$helper" && pass 'step-254 helper passes bash syntax validation' || fail_test 'step-254 helper syntax invalid'
bash -n "$body" && pass 'executor-v2 body passes bash syntax validation' || fail_test 'executor-v2 body syntax invalid'
bash -n "$builder" && pass 'executor-v2 builder passes bash syntax validation' || fail_test 'executor-v2 builder syntax invalid'
bash -n "$executor" && pass 'executor-v2 payload passes bash syntax validation' || fail_test 'executor-v2 payload syntax invalid'
bash -n "$acceptance_harness" && pass 'executor-v2 acceptance harness passes bash syntax validation' || fail_test 'executor-v2 acceptance harness syntax invalid'
"$helper" --help >/dev/null 2>&1 && pass 'step-254 helper exposes non-mutating help' || fail_test 'step-254 helper help failed'
if "$helper" --unknown >/dev/null 2>&1; then fail_test 'step-254 helper accepts unknown option'; else pass 'step-254 helper rejects unknown option'; fi

work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
if "$helper" --output-dir "$work/generated" > "$work/helper.out" 2>&1; then pass 'step-254 helper executes successfully'; else cat "$work/helper.out"; fail_test 'step-254 helper execution failed'; fi
if cmp -s "$policy" "$work/generated/${policy##*/}"; then pass 'helper reproduces frozen policy exactly'; else fail_test 'helper policy reproduction differs'; fi
if cmp -s "$record" "$work/generated/${record##*/}"; then pass 'helper reproduces frozen record exactly'; else fail_test 'helper record reproduction differs'; fi
contains "$work/helper.out" $'implementation_review_status\tPASS' && pass 'helper reports PASS implementation review' || fail_test 'helper PASS status missing'
contains "$work/helper.out" $'repository_acceptance_result\tPASS (94 passes, 0 failures)' && pass 'helper reports executor-v2 acceptance result' || fail_test 'helper acceptance result missing'
contains "$work/helper.out" $'runtime_executor_v2_transport_authorized\tno' && pass 'helper keeps executor-v2 transport closed' || fail_test 'helper transport boundary drift'

if "$acceptance_harness" > "$work/acceptance.out" 2>&1; then pass 'executor-v2 repository acceptance executes successfully'; else cat "$work/acceptance.out"; fail_test 'executor-v2 repository acceptance failed'; fi
contains "$work/acceptance.out" 'Result: PASS (94 passes, 0 failures)' && pass 'executor-v2 repository acceptance is 94/94' || fail_test 'unexpected executor-v2 repository acceptance count'

if python3 - "$policy" <<'PY'
import json, sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
assert p['schema'] == 1
assert p['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review'
assert p['step'] == 254 and p['review_status'] == 'PASS'
assert p['accepted_step_253']['freeze_status'] == 'PASS'
assert p['accepted_step_246_contract']['contract_state'] == 'reviewed-frozen-consumed-by-v2-implementation'
assert p['historical_failed_remediation_executor']['preserved_unchanged'] is True
impl=p['executor_v2_implementation']
assert impl['state'] == 'implemented-reviewed-awaiting-freeze'
assert impl['body_sha256'] == 'c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68'
assert impl['builder_sha256'] == '43c858e351d32c4ed2c28c687ccc9a06a1fc78f77032eaf20fb3d40a3ff197da'
assert impl['executor_sha256'] == 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d'
assert impl['repository_acceptance_result'] == 'PASS (94 passes, 0 failures)'
assert impl['boot_id'] == '047e744d-d2ea-4d9a-8746-7734b58db3b2'
assert impl['local_source_generation'] == 'local-source-v3'
assert impl['local_source_v3_tree_manifest_sha256'] == '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'
c=p['reviewed_contract']
assert c['human_spaced_error_prefix'] == 'Error downloading from '
assert c['human_spaced_error_prefix_hex'] == '4572726f7220646f776e6c6f6164696e672066726f6d20'
assert c['human_spaced_error_must_fail_closed'] is True
assert c['hyphenated_literal_guard_forbidden'] is True
assert c['slackpkg_exit_zero_required'] is True and c['slackpkg_exit_zero_sufficient'] is False
assert c['stdout_and_stderr_capture_required'] is True
assert c['fresh_transaction_owned_pkglist_required'] is True
assert c['same_transaction_candidate_binding_required'] is True
assert c['target_specific_candidate_guard_required'] is True
assert c['historical_local_source_v2_no_PGP_state_preserved'] is True
assert c['failed_remediation_evidence_preserved'] is True
a=p['authorization']
assert a['repository_only_executor_v2_implementation_freeze_authorized'] is True
for key in ['runtime_executor_v2_implementation_authorized','runtime_executor_v2_transport_authorized','runtime_candidate_binding_authorized','runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','repository_refresh_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','evidence_cleanup_authorized','persistent_configuration_change_authorized','phase_2_start_authorized']:
    assert a[key] is False, key
assert p['machine_action_required'] is False
assert p['controller_action_required'] is False
assert p['pause_safe'] is False
assert p['strong_safe_pause'] is False
assert p['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze'
PY
then pass 'step-254 policy semantic assertions pass'; else fail_test 'step-254 policy semantic assertions failed'; fi

for expectation in \
    $'step\t254' \
    $'review_status\tPASS' \
    $'executor_v2_state\timplemented-reviewed-awaiting-freeze' \
    $'repository_acceptance_result\tPASS (94 passes, 0 failures)' \
    $'fresh_boot_id\t047e744d-d2ea-4d9a-8746-7734b58db3b2' \
    $'local_source_generation\tlocal-source-v3' \
    $'local_source_v3_tree_manifest_sha256\t8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b' \
    $'human_spaced_error_prefix_hex\t4572726f7220646f776e6c6f6164696e672066726f6d20' \
    $'hyphenated_literal_guard\tforbidden' \
    $'slackpkg_exit_zero_sufficient\tno' \
    $'fresh_transaction_owned_pkglist_required\tyes' \
    $'same_transaction_candidate_binding_required\tyes' \
    $'candidate_set_bound\tno' \
    $'runtime_executor_v2_transport_authorized\tno' \
    $'runtime_rerun_authorized\tno' \
    $'package_action_authorized\tno' \
    $'slackpkg_mutation_authorized\tno' \
    $'network_access_authorized\tno' \
    $'boot_action_authorized\tno' \
    $'reboot_authorized\tno' \
    $'machine_action_required\tno' \
    $'controller_action_required\tno' \
    $'pause_safe\tno' \
    $'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze'; do
    if grep -Fxq -- "$expectation" "$record"; then pass "record freezes: ${expectation%%$'\t'*}"; else fail_test "record missing: $expectation"; fi
done

contains "$doc" 'PASS. Step 254 implements and reviews the repository-only executor v2' && pass 'reference document records PASS implementation review' || fail_test 'reference document PASS statement missing'
contains "$doc" 'Error downloading from ' && pass 'reference document preserves human-spaced error guard' || fail_test 'reference document human-spaced guard missing'
contains "$doc" 'runtime-transaction-remediation-v2' && pass 'reference document records isolated v2 evidence root' || fail_test 'reference document v2 evidence root missing'
contains "$doc" 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze' && pass 'reference document names next stage' || fail_test 'reference document next stage missing'
contains "$changelog" '## Phase 1 step 254 kernel-package-edge runtime-transaction remediation executor-v2 implementation review' && pass 'CHANGELOG records step 254' || fail_test 'CHANGELOG step 254 entry missing'

trailing=0
for path in "$helper" "$doc" "$policy" "$record" "$body" "$builder" "$executor" "$acceptance_harness"; do
    if grep -nE '[[:blank:]]+$' "$path" >/dev/null; then
        printf 'Trailing whitespace in %s:\n' "$path"
        grep -nE '[[:blank:]]+$' "$path" || true
        trailing=1
    fi
done
if [[ $trailing -eq 0 ]]; then pass 'new step-254 artifacts contain no trailing whitespace'; else fail_test 'new step-254 artifacts contain trailing whitespace'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
