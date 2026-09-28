#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze.md"
policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review.tsv"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"

passes=0
failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert(){ local label=$1; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }
assert_hash(){ local label=$1 file=$2 expected=$3 actual; actual=$(sha256sum -- "$file" | awk '{print $1}'); [[ $actual == "$expected" ]] && pass "$label" || fail "$label"; }

for pair in \
    "$helper|step-255 helper" \
    "$doc|step-255 document" \
    "$policy|step-255 policy" \
    "$record|step-255 record" \
    "$prior_helper|accepted step-254 helper" \
    "$prior_doc|accepted step-254 document" \
    "$prior_harness|accepted step-254 harness" \
    "$prior_policy|accepted step-254 policy" \
    "$prior_record|accepted step-254 record" \
    "$body|executor-v2 body" \
    "$builder|executor-v2 builder" \
    "$executor|executor-v2 canonical payload" \
    "$acceptance_harness|executor-v2 acceptance harness" \
    "$repo_root/CHANGELOG.md|CHANGELOG"; do
    file=${pair%%|*}
    label=${pair#*|}
    assert "$label exists as regular file" bash -c '[[ -f "$1" && ! -L "$1" ]]' _ "$file"
done

assert_hash 'accepted step-254 helper SHA-256 matches' "$prior_helper" '40a8c9eb74607c9edd05607896acc61425f5c1b74aa33ecba5acba140c93e6bf'
assert_hash 'accepted step-254 document SHA-256 matches' "$prior_doc" '65de7659747f947bf9299a75d801d0f913939c563b56fb06586c4ae2453d5936'
assert_hash 'accepted step-254 harness SHA-256 matches' "$prior_harness" 'd5784fd853414d1129cf662b859ec37df53d338212cae65a0524cec480f83f7b'
assert_hash 'accepted step-254 policy SHA-256 matches' "$prior_policy" 'ac95d38ea65cb8911c09c93ca5cd33d106e016347cfc906ca329b106cfdaa537'
assert_hash 'accepted step-254 record SHA-256 matches' "$prior_record" '21003cc3cf68ea8996578e9b132ccbde615ef4b91958471857a10557d1802cde'
assert_hash 'executor-v2 body SHA-256 remains frozen' "$body" 'c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68'
assert_hash 'executor-v2 builder SHA-256 remains frozen' "$builder" '43c858e351d32c4ed2c28c687ccc9a06a1fc78f77032eaf20fb3d40a3ff197da'
assert_hash 'executor-v2 payload SHA-256 remains frozen' "$executor" 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d'
assert_hash 'executor-v2 acceptance harness SHA-256 remains frozen' "$acceptance_harness" '86fcfd31ebe023d6fdfe3ec0c0c6bebaac3a17fd47202de43ffa3afe89854eef'
assert_hash 'step-255 helper SHA-256 matches' "$helper" 'b0aabffa761c374efabac2f687c87bb3d6acc99094e532c347033032b07c6d08'
assert_hash 'step-255 document SHA-256 matches' "$doc" '4d55dbea026f59411a1afad7a60aaf3e937d9255dc8c6089dc8310b8ba952356'
assert_hash 'step-255 policy SHA-256 matches' "$policy" '416bbd6b33ce08f87e952b76036239352067e72002759d4fd3bbbea9dae6c25b'
assert_hash 'step-255 record SHA-256 matches' "$record" '97afc879507953d875367173349c0574d180611642d6ffec0493840c05ad8f13'

assert 'step-255 helper passes bash syntax validation' bash -n "$helper"
assert 'step-255 helper exposes non-mutating help' "$helper" --help
if "$helper" --invalid >/dev/null 2>&1; then fail 'step-255 helper rejects unknown option'; else pass 'step-255 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/helper.out"; then pass 'step-255 helper executes successfully'; else fail 'step-255 helper executes successfully'; fi
assert 'helper reproduces frozen policy exactly' cmp -s "$tmp/${policy##*/}" "$policy"
assert 'helper reproduces frozen record exactly' cmp -s "$tmp/${record##*/}" "$record"
assert 'helper reports PASS freeze status' grep -Fqx $'implementation_freeze_status\tPASS' "$tmp/helper.out"
assert 'helper freezes executor-v2 implementation' grep -Fqx $'implementation_frozen\tyes' "$tmp/helper.out"
assert 'helper revalidates 94-pass repository acceptance' grep -Fqx $'repository_acceptance_result\tPASS (94 passes, 0 failures)' "$tmp/helper.out"
assert 'helper revalidates deterministic builder' grep -Fqx $'builder_reproducibility_reverified\tyes' "$tmp/helper.out"
assert 'helper keeps executor-v2 transport closed' grep -Fqx $'runtime_executor_v2_transport_authorized\tno' "$tmp/helper.out"
assert 'helper keeps runtime rerun closed' grep -Fqx $'runtime_rerun_authorized\tno' "$tmp/helper.out"

if "$acceptance_harness" >"$tmp/acceptance.out" 2>&1; then pass 'executor-v2 repository acceptance executes successfully'; else fail 'executor-v2 repository acceptance executes successfully'; fi
assert 'executor-v2 repository acceptance remains 94/94' grep -Fqx 'Result: PASS (94 passes, 0 failures)' "$tmp/acceptance.out"

python3 - "$policy" "$record" <<'PYSEM' >"$tmp/semantic.out"
import csv
import json
import sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
with open(sys.argv[2], encoding='utf-8', newline='') as h:
    r=dict(csv.reader(h, delimiter='\t'))
f=p['frozen_executor_v2']
c=p['frozen_runtime_contract']
a=p['authorization']
checks={
'policy identifies step-255 freeze': p['step']==255 and p['scenario'].endswith('runtime-executor-v2-implementation-freeze') and r['step']=='255',
'freeze status is PASS': p['freeze_status']=='PASS' and r['freeze_status']=='PASS',
'step-254 semantics are consumed unchanged': p['accepted_step_254']['semantics_consumed_without_change'] is True,
'no machine authority is inherited': p['accepted_step_254']['no_machine_authority_inherited'] is True,
'executor-v2 implementation state is frozen': f['state']=='implementation-frozen-awaiting-runtime-authorization-review' and r['implementation_frozen']=='yes',
'exact body builder executor hashes are frozen': f['body_sha256']=='c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68' and f['builder_sha256']=='43c858e351d32c4ed2c28c687ccc9a06a1fc78f77032eaf20fb3d40a3ff197da' and f['executor_sha256']=='deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d',
'repository acceptance is reverified': f['repository_acceptance_result']=='PASS (94 passes, 0 failures)' and f['repository_acceptance_harness_sha256']=='86fcfd31ebe023d6fdfe3ec0c0c6bebaac3a17fd47202de43ffa3afe89854eef',
'builder reproducibility is reverified': f['builder_reproducibility_reverified'] is True and f['canonical_executor_rebuilt_byte_for_byte'] is True,
'fresh boot identity remains bound': f['boot_id']=='047e744d-d2ea-4d9a-8746-7734b58db3b2',
'accepted v3 manifest remains bound': f['local_source_generation']=='local-source-v3' and f['local_source_v3_tree_manifest_sha256']=='8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b',
'historical failed executor remains preserved': p['historical_failed_remediation_executor']['preserved_unchanged'] is True and p['historical_failed_remediation_executor']['runtime_authorization_reusable'] is False,
'human-spaced error guard remains exact': c['human_spaced_error_prefix']=='Error downloading from ' and c['human_spaced_error_prefix_hex']=='4572726f7220646f776e6c6f6164696e672066726f6d20',
'hyphenated literal remains forbidden': c['hyphenated_literal_guard_forbidden'] is True,
'slackpkg exit zero remains insufficient': c['slackpkg_exit_zero_required'] is True and c['slackpkg_exit_zero_sufficient'] is False,
'fresh transaction pkglist remains mandatory': c['pre_refresh_pkglist_must_be_absent'] is True and c['fresh_transaction_owned_pkglist_required'] is True,
'same-transaction candidate binding remains mandatory': c['same_transaction_candidate_binding_required'] is True and c['target_specific_candidate_guard_required'] is True and c['exact_target_candidate_row_count']==1,
'v3 PGP compatibility boundary remains frozen': c['v3_compatibility_PGP_marker_exact']=='PGP compatibility marker for Slackpkg checkchangelog only.' and c['v3_openpgp_signature_impersonation_forbidden'] is True,
'rollback and restoration invariants remain frozen': c['rollback_on_any_failure_after_mutation'] and c['slackpkg_state_restored'] and c['geninitrd_policy_restored'] and c['boot_artifacts_unchanged'],
'external network and reboot remain forbidden': c['external_network_forbidden'] and c['no_reboot'],
'only repository runtime authorization review is opened': a['repository_only_executor_v2_runtime_authorization_review_authorized'] is True,
'executor build transport and candidate binding remain closed': a['runtime_executor_v2_build_authorized'] is False and a['runtime_executor_v2_transport_authorized'] is False and a['runtime_candidate_binding_authorized'] is False,
'runtime rerun and package actions remain closed': a['runtime_rerun_authorized'] is False and a['package_action_authorized'] is False and a['slackpkg_mutation_authorized'] is False,
'network refresh boot reboot cleanup and Phase 2 remain closed': a['repository_refresh_authorized'] is False and a['network_access_authorized'] is False and a['boot_action_authorized'] is False and a['reboot_authorized'] is False and a['evidence_cleanup_authorized'] is False and a['phase_2_start_authorized'] is False,
'no machine or controller action is required': p['machine_action_required'] is False and p['controller_action_required'] is False,
'family remains active rather than safe-paused': p['pause_safe'] is False and p['strong_safe_pause'] is False,
'next stage is executor-v2 runtime authorization review': p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review',
}
for label,value in checks.items():
    print(('PASS' if value else 'FAIL')+'\t'+label)
PYSEM
while IFS=$'\t' read -r status label; do
    [[ $status == PASS ]] && pass "$label" || fail "$label"
done <"$tmp/semantic.out"

assert 'reference document freezes exact executor-v2 implementation' grep -Fq 'The frozen executor-v2 implementation consists of:' "$doc"
assert 'reference document records 94-pass acceptance' grep -Fq 'PASS (94 passes, 0 failures)' "$doc"
assert 'reference document preserves human-spaced error guard' grep -Fq 'Error downloading from ' "$doc"
assert 'reference document keeps transport and runtime closed' grep -Fq 'It does not authorize executor transport' "$doc"
assert 'reference document names runtime authorization review' grep -Fq 'runtime-executor-v2-runtime-authorization-review' "$doc"
assert 'CHANGELOG records step 255' grep -Fqx '## Phase 1 step 255 kernel-package-edge runtime-transaction remediation executor-v2 implementation freeze — 2026-09-28' "$repo_root/CHANGELOG.md"

for f in "$helper" "$doc" "$policy" "$record"; do
    if grep -nE '[[:blank:]]+$' "$f" >/dev/null; then fail "$(basename "$f") contains no trailing whitespace"; else pass "$(basename "$f") contains no trailing whitespace"; fi
done

if grep -En '(^|[;&|]) *([[:alnum:]_./-]*/)?(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown|poweroff)( |$)' "$helper" >/dev/null; then
    fail 'step-255 helper contains no executable network package boot reboot or shutdown command'
else
    pass 'step-255 helper contains no executable network package boot reboot or shutdown command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && echo PASS || echo FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
