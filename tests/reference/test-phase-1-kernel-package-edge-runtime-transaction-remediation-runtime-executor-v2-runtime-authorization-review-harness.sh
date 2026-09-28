#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review.md"
policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze.tsv"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"

passes=0
failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert(){ local label=$1; shift; if "$@"; then pass "$label"; else fail "$label"; fi; }
assert_hash(){ local label=$1 file=$2 expected=$3 actual; actual=$(sha256sum -- "$file" | awk '{print $1}'); [[ $actual == "$expected" ]] && pass "$label" || fail "$label"; }

for pair in \
    "$helper|step-256 helper" \
    "$doc|step-256 document" \
    "$policy|step-256 policy" \
    "$record|step-256 record" \
    "$prior_helper|accepted step-255 helper" \
    "$prior_doc|accepted step-255 document" \
    "$prior_harness|accepted step-255 harness" \
    "$prior_policy|accepted step-255 policy" \
    "$prior_record|accepted step-255 record" \
    "$executor|executor-v2 canonical payload" \
    "$acceptance_harness|executor-v2 acceptance harness" \
    "$repo_root/CHANGELOG.md|CHANGELOG"; do
    file=${pair%%|*}
    label=${pair#*|}
    assert "$label exists as regular file" bash -c '[[ -f "$1" && ! -L "$1" ]]' _ "$file"
done

assert_hash 'accepted step-255 helper SHA-256 matches' "$prior_helper" 'b0aabffa761c374efabac2f687c87bb3d6acc99094e532c347033032b07c6d08'
assert_hash 'accepted step-255 document SHA-256 matches' "$prior_doc" '4d55dbea026f59411a1afad7a60aaf3e937d9255dc8c6089dc8310b8ba952356'
assert_hash 'accepted step-255 harness SHA-256 matches' "$prior_harness" '5fec4c3bffaceb6fea5f24f012639533ffff0f45985b89452330a2a681b3bd0a'
assert_hash 'accepted step-255 policy SHA-256 matches' "$prior_policy" '416bbd6b33ce08f87e952b76036239352067e72002759d4fd3bbbea9dae6c25b'
assert_hash 'accepted step-255 record SHA-256 matches' "$prior_record" '97afc879507953d875367173349c0574d180611642d6ffec0493840c05ad8f13'
assert_hash 'executor-v2 payload SHA-256 remains frozen' "$executor" 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d'
assert_hash 'executor-v2 acceptance harness SHA-256 remains frozen' "$acceptance_harness" '86fcfd31ebe023d6fdfe3ec0c0c6bebaac3a17fd47202de43ffa3afe89854eef'
assert_hash 'step-256 helper SHA-256 matches' "$helper" '68185a9ab2a5c5695bc359e3981a39ade9e41ffd4858741eab6bbf9551a51f6d'
assert_hash 'step-256 document SHA-256 matches' "$doc" 'dd88d0c97392cba2a32deff8201c116d10f1516d9f3d6f1b47c3c08d414fe42b'
assert_hash 'step-256 policy SHA-256 matches' "$policy" 'd298c04f78640dc7e173055534e2efbfadd6dbda9c1056cf45b9da4e9f637ab1'
assert_hash 'step-256 record SHA-256 matches' "$record" '8ad103a636f2dfc27b8c6dd452a07c556b1785f160c4d6b8951f860a0a2d61ca'

assert 'step-256 helper passes bash syntax validation' bash -n "$helper"
assert 'step-256 helper exposes non-mutating help' "$helper" --help
if "$helper" --invalid >/dev/null 2>&1; then fail 'step-256 helper rejects unknown option'; else pass 'step-256 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/helper.out"; then pass 'step-256 helper executes successfully'; else fail 'step-256 helper executes successfully'; fi
assert 'helper reproduces frozen policy exactly' cmp -s "$tmp/${policy##*/}" "$policy"
assert 'helper reproduces frozen record exactly' cmp -s "$tmp/${record##*/}" "$record"
assert 'helper reports PASS authorization review' grep -Fqx $'runtime_authorization_review_status\tPASS' "$tmp/helper.out"
assert 'helper records reviewed single-use state' grep -Fqx $'runtime_authorization_contract_state\treviewed-awaiting-single-use-authorization-freeze-v2' "$tmp/helper.out"
assert 'helper keeps executor-v2 transport closed' grep -Fqx $'runtime_executor_v2_transport_authorized\tno' "$tmp/helper.out"
assert 'helper keeps runtime rerun closed' grep -Fqx $'runtime_rerun_authorized\tno' "$tmp/helper.out"
assert 'helper requires no machine action' grep -Fqx $'machine_action_required\tno' "$tmp/helper.out"

python3 - "$policy" "$record" <<'PYSEM' >"$tmp/semantic.out"
import csv
import json
import sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
with open(sys.argv[2],encoding='utf-8',newline='') as h:
    r=dict(csv.reader(h,delimiter='\t'))
c=p['reviewed_runtime_authorization_contract']
a=p['authorization']
b=c['bounded_mutation']
checks={
'policy identifies step-256 review': p['step']==256 and p['scenario'].endswith('runtime-executor-v2-runtime-authorization-review') and r['step']=='256',
'review status is PASS': p['review_status']=='PASS' and r['review_status']=='PASS',
'step-255 semantics are consumed unchanged': p['accepted_step_255']['semantics_consumed_without_change'] is True,
'no machine authority is inherited': p['accepted_step_255']['no_machine_authority_inherited'] is True,
'authorization contract awaits freeze': c['state']=='reviewed-awaiting-single-use-authorization-freeze-v2' and r['runtime_authorization_contract_state']=='reviewed-awaiting-single-use-authorization-freeze-v2',
'execution target is frozen': c['execution_target']=='vbox-slackcurrent.vbox-slackcurrent.org' and r['target_hostname']=='vbox-slackcurrent.vbox-slackcurrent.org',
'running kernel is frozen': c['required_running_kernel']=='6.18.45' and r['required_running_kernel']=='6.18.45',
'fresh boot ID is frozen': c['required_boot_id']=='047e744d-d2ea-4d9a-8746-7734b58db3b2' and r['required_boot_id']=='047e744d-d2ea-4d9a-8746-7734b58db3b2',
'package database identity is frozen': c['required_package_database_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
'slackpkg fingerprints are frozen': c['required_slackpkg_conf_sha256']=='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4' and c['required_slackpkg_mirrors_sha256']=='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
'executor-v2 exact bytes are frozen': c['executor']['sha256']=='deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d' and r['canonical_executor_v2_sha256']=='deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d',
'executor rebuild remains forbidden': c['executor']['rebuild_before_transport_authorized'] is False,
'predecessor exact bytes are frozen': c['predecessor']['sha256']=='3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d' and c['predecessor']['redownload_authorized'] is False,
'staged target remains frozen': c['staged_target']['sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
'accepted v3 manifest remains frozen': c['local_source_v3']['tree_manifest_sha256']=='8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b',
'v3 sidecar coverage and priority remain mandatory': c['local_source_v3']['manifest_sidecar_verification_required'] and c['local_source_v3']['exact_coverage_required'] and c['local_source_v3']['priority_tree_contract_required'],
'v3 PGP compatibility marker remains exact': c['local_source_v3']['compatibility_PGP_marker_exact']=='PGP compatibility marker for Slackpkg checkchangelog only.',
'OpenPGP impersonation remains forbidden': c['local_source_v3']['openpgp_signature_impersonation_forbidden'] is True,
'historical failed evidence remains preserved': c['historical_state']['failed_evidence_must_remain_present'] is True,
'historical local-source-v2 remains preserved': c['historical_state']['local_source_v2_must_remain_unchanged'] is True and c['historical_state']['local_source_v2_manifest_sha256']=='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
'new v2 evidence destinations must start absent': c['new_evidence']['runtime_root_must_be_absent_before_start'] and c['new_evidence']['published_outputs_must_be_absent_before_start'],
'v2 result publication is mandatory': c['new_evidence']['publication_required_for_result_review'] and c['new_evidence']['result_review_required_before_any_further_machine_action'],
'exact v2 runtime acknowledgement is frozen': c['runtime_acknowledgement']=='--execute-runtime-remediation-v2-validation' and r['runtime_acknowledgement']=='--execute-runtime-remediation-v2-validation',
'exact v2 execution command is frozen': c['exact_execution_command']=='sudo bash phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh --execute-runtime-remediation-v2-validation',
'candidate binding is same-transaction only': c['candidate_binding_lifetime']=='same-runtime-transaction-only',
'preflight must finish before mutation': c['preflight_must_complete_before_first_mutation'] is True,
'drift returns to fresh revalidation': c['drift_action']=='abort-before-first-mutation-and-return-to-fresh-revalidation-review',
'fresh transaction pkglist remains required': b['fresh_transaction_owned_pkglist_required'] is True,
'human-spaced Slackpkg error remains fail-closed': b['human_spaced_error_must_fail_closed'] is True and b['slackpkg_exit_zero_sufficient'] is False,
'bounded package mutation remains header-only': b['package_mutation_scope']=='kernel-headers-6.18.45-to-6.18.44-to-6.18.45-only',
'external network boot and reboot stay forbidden': b['external_network_access_authorized'] is False and b['boot_action_authorized'] is False and b['reboot_authorized'] is False,
'required final target state is frozen': c['required_final_state']['header_record']=='kernel-headers-6.18.45-x86-1' and c['required_final_state']['predecessor_terminal_state_forbidden'] is True,
'final restoration remains mandatory': c['required_final_state']['slackpkg_configuration_and_state_restored'] and c['required_final_state']['geninitrd_policy_restored'] and c['required_final_state']['boot_artifacts_unchanged'],
'only repository freeze review is opened': a['repository_only_runtime_authorization_freeze_authorized'] is True,
'executor transport remains closed': a['runtime_executor_v2_transport_authorized'] is False and r['runtime_executor_v2_transport_authorized']=='no',
'predecessor transport remains closed': a['predecessor_package_transport_authorized'] is False and r['predecessor_package_transport_authorized']=='no',
'candidate binding remains closed': a['runtime_candidate_binding_authorized'] is False,
'runtime execution remains closed': a['runtime_scenario_execution_authorized'] is False and a['runtime_rerun_authorized'] is False,
'package and Slackpkg mutation remain closed': a['package_action_authorized'] is False and a['slackpkg_mutation_authorized'] is False,
'network and repository refresh remain closed': a['network_access_authorized'] is False and a['repository_refresh_authorized'] is False,
'boot reboot cleanup and Phase 2 remain closed': a['boot_action_authorized'] is False and a['reboot_authorized'] is False and a['evidence_cleanup_authorized'] is False and a['phase_2_start_authorized'] is False,
'no machine or controller action is required': p['machine_action_required'] is False and p['controller_action_required'] is False,
'family remains active rather than safe-paused': p['pause_safe'] is False and p['strong_safe_pause'] is False,
'next stage is runtime authorization freeze': p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze',
}
for label, ok in checks.items():
    print(('PASS' if ok else 'FAIL')+'\t'+label)
PYSEM
while IFS=$'\t' read -r status label; do
    [[ $status == PASS ]] && pass "$label" || fail "$label"
done < "$tmp/semantic.out"

assert 'reference document is repository-only' grep -Fq 'This step is repository-only and grants no controller or target-machine authority.' "$doc"
assert 'reference document freezes executor-v2 SHA-256' grep -Fq 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d' "$doc"
assert 'reference document records fresh boot ID' grep -Fq '047e744d-d2ea-4d9a-8746-7734b58db3b2' "$doc"
assert 'reference document preserves human-spaced error guard' grep -Fq 'Error downloading from ' "$doc"
assert 'reference document preserves v3 PGP marker' grep -Fq 'PGP compatibility marker for Slackpkg checkchangelog only.' "$doc"
assert 'reference document names next stage' grep -Fq 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze' "$doc"
assert 'CHANGELOG records step 256' grep -Fqx '## Phase 1 step 256 kernel-package-edge runtime-transaction remediation executor-v2 runtime authorization review — 2026-09-28' "$repo_root/CHANGELOG.md"

for f in "$helper" "$doc" "$policy" "$record"; do
    if grep -nE '[[:blank:]]+$' "$f" >/dev/null; then fail "$(basename "$f") contains no trailing whitespace"; else pass "$(basename "$f") contains no trailing whitespace"; fi
done

if grep -En '(^|[;&|]) *([[:alnum:]_./-]*/)?(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown|poweroff)( |$)' "$helper" >/dev/null; then
    fail 'step-256 helper contains no executable network package boot reboot or shutdown command'
else
    pass 'step-256 helper contains no executable network package boot reboot or shutdown command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && echo PASS || echo FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
