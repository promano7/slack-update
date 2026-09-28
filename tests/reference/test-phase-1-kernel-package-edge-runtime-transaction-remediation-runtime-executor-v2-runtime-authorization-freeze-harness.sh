#!/bin/bash
set -u
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze.md"
policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review.tsv"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert() {
    local label=$1
    shift
    if "$@"; then pass "$label"; else fail "$label"; fi
}
check_sha() {
    local label=$1 path=$2 expected=$3 actual
    actual=$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}')
    [[ $actual == "$expected" ]] && pass "$label" || fail "$label"
}

for spec in \
    "step-257 helper|$helper" \
    "step-257 document|$doc" \
    "step-257 policy|$policy" \
    "step-257 record|$record" \
    "accepted step-256 helper|$prior_helper" \
    "accepted step-256 document|$prior_doc" \
    "accepted step-256 harness|$prior_harness" \
    "accepted step-256 policy|$prior_policy" \
    "accepted step-256 record|$prior_record" \
    "executor-v2 canonical payload|$executor" \
    "executor-v2 acceptance harness|$acceptance_harness" \
    "CHANGELOG|$repo_root/CHANGELOG.md"; do
    label=${spec%%|*}; path=${spec#*|}
    [[ -f $path && ! -L $path ]] && pass "$label exists as regular file" || fail "$label exists as regular file"
done

check_sha 'accepted step-256 helper SHA-256 matches' "$prior_helper" '68185a9ab2a5c5695bc359e3981a39ade9e41ffd4858741eab6bbf9551a51f6d'
check_sha 'accepted step-256 document SHA-256 matches' "$prior_doc" 'dd88d0c97392cba2a32deff8201c116d10f1516d9f3d6f1b47c3c08d414fe42b'
check_sha 'accepted step-256 harness SHA-256 matches' "$prior_harness" '23ad4b1f15013e2b10126e19e2dc72529791d4f4f5292862b4ab36762e1bade1'
check_sha 'accepted step-256 policy SHA-256 matches' "$prior_policy" 'd298c04f78640dc7e173055534e2efbfadd6dbda9c1056cf45b9da4e9f637ab1'
check_sha 'accepted step-256 record SHA-256 matches' "$prior_record" '8ad103a636f2dfc27b8c6dd452a07c556b1785f160c4d6b8951f860a0a2d61ca'
check_sha 'executor-v2 payload SHA-256 remains frozen' "$executor" 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d'
check_sha 'executor-v2 acceptance harness SHA-256 remains frozen' "$acceptance_harness" '86fcfd31ebe023d6fdfe3ec0c0c6bebaac3a17fd47202de43ffa3afe89854eef'
check_sha 'step-257 helper SHA-256 matches' "$helper" '43b63cf06bbc9b8de03fdca51e8d694b2c45132f46e1e77037a8ea8f51f98793'
check_sha 'step-257 document SHA-256 matches' "$doc" 'c254030cb9c0c81b2bc05efde66197a976385f4eccb9d3e1bac71483e195136b'
check_sha 'step-257 policy SHA-256 matches' "$policy" 'adb641120d073e8ccef80ce9b3fcaddf7095a88575827d4ff7c2d43b5fa68e0b'
check_sha 'step-257 record SHA-256 matches' "$record" '310e711e59e9039238dc6d428dbeb61977e8e4632a153a98a92c918ebb637ae3'

assert 'step-257 helper passes bash syntax validation' bash -n "$helper"
if "$helper" --help >/dev/null 2>&1; then pass 'step-257 helper exposes non-mutating help'; else fail 'step-257 helper exposes non-mutating help'; fi
if "$helper" --definitely-invalid >/dev/null 2>&1; then fail 'step-257 helper rejects unknown option'; else pass 'step-257 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp/out" >"$tmp/helper.out" 2>"$tmp/helper.err"; then pass 'step-257 helper executes successfully'; else cat "$tmp/helper.err"; fail 'step-257 helper executes successfully'; fi
cmp -s -- "$tmp/out/$(basename "$policy")" "$policy" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s -- "$tmp/out/$(basename "$record")" "$record" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'
grep -Fqx $'runtime_authorization_freeze_status\tPASS' "$tmp/helper.out" && pass 'helper reports PASS authorization freeze' || fail 'helper reports PASS authorization freeze'
grep -Fqx $'execution_use_count\t1' "$tmp/helper.out" && pass 'helper freezes one execution use' || fail 'helper freezes one execution use'
grep -Fqx $'runtime_executor_v2_transport_authorized\tyes' "$tmp/helper.out" && pass 'helper opens executor-v2 transport' || fail 'helper opens executor-v2 transport'
grep -Fqx $'runtime_scenario_execution_authorized\tyes' "$tmp/helper.out" && pass 'helper opens bounded runtime execution' || fail 'helper opens bounded runtime execution'
grep -Fqx $'external_network_access_authorized\tno' "$tmp/helper.out" && pass 'helper keeps external network closed' || fail 'helper keeps external network closed'

if "$acceptance_harness" >"$tmp/acceptance.out" 2>&1; then pass 'executor-v2 repository acceptance executes successfully'; else cat "$tmp/acceptance.out"; fail 'executor-v2 repository acceptance executes successfully'; fi
grep -Fqx 'Result: PASS (94 passes, 0 failures)' "$tmp/acceptance.out" && pass 'executor-v2 repository acceptance remains 94/94' || fail 'executor-v2 repository acceptance remains 94/94'

python3 - "$policy" "$record" >"$tmp/semantic.out" <<'PYSEM'
import csv, json, sys
from pathlib import Path
p=json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
with Path(sys.argv[2]).open(encoding='utf-8', newline='') as h:
    r=dict(csv.reader(h, delimiter='\t'))
f=p['frozen_runtime_authorization']; a=p['authorization']; b=f['bounded_mutation']
checks={
'policy identifies step-257 freeze': p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze' and p['step']==257,
'freeze status is PASS': p['freeze_status']=='PASS',
'step-256 review is consumed': p['accepted_step_256']['review_status']=='PASS' and p['accepted_step_256']['reviewed_contract_consumed_without_change'] is True,
'no machine authority was inherited from step 256': p['accepted_step_256']['no_machine_authority_inherited'] is True,
'single-use authorization state is frozen': f['state']=='single-use-authorized-awaiting-controller-transport-and-runtime-v2',
'authorization scope remains bounded': f['authorization_scope']=='single-bounded-kernel-header-edge-runtime-remediation-v2-transaction',
'target hostname remains frozen': f['execution_target']=='vbox-slackcurrent.vbox-slackcurrent.org',
'running kernel remains frozen': f['required_running_kernel']=='6.18.45',
'fresh boot ID remains frozen': f['required_boot_id']=='047e744d-d2ea-4d9a-8746-7734b58db3b2',
'package database identity remains frozen': f['required_package_database_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
'slackpkg fingerprints remain frozen': f['required_slackpkg_conf_sha256']=='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4' and f['required_slackpkg_mirrors_sha256']=='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
'executor-v2 exact bytes remain frozen': f['executor']['sha256']=='deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d' and f['executor']['rebuild_before_transport_authorized'] is False,
'predecessor exact bytes remain frozen': f['predecessor']['sha256']=='3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d' and f['predecessor']['redownload_authorized'] is False,
'accepted v3 manifest remains frozen': f['local_source_v3']['tree_manifest_sha256']=='8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b',
'v3 sidecar exact coverage and priority remain mandatory': f['local_source_v3']['manifest_sidecar_verification_required'] and f['local_source_v3']['exact_coverage_required'] and f['local_source_v3']['priority_tree_contract_required'],
'v3 PGP marker remains exact': f['local_source_v3']['compatibility_PGP_marker_exact']=='PGP compatibility marker for Slackpkg checkchangelog only.',
'OpenPGP impersonation remains forbidden': f['local_source_v3']['openpgp_signature_impersonation_forbidden'] is True,
'historical failed evidence remains preserved': f['historical_state']['failed_evidence_must_remain_present'] is True,
'historical local-source-v2 remains preserved': f['historical_state']['local_source_v2_must_remain_unchanged'] is True and f['historical_state']['local_source_v2_manifest_sha256']=='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
'new v2 evidence must start absent': f['new_evidence']['runtime_root_must_be_absent_before_start'] is True and f['new_evidence']['published_outputs_must_be_absent_before_start'] is True,
'result review is mandatory': f['new_evidence']['result_review_required_before_any_further_machine_action'] is True and f['result_review_required_before_any_further_machine_action'] is True,
'exact acknowledgement remains frozen': f['runtime_acknowledgement']=='--execute-runtime-remediation-v2-validation',
'exact execution command remains frozen': f['exact_execution_command']=='sudo bash phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh --execute-runtime-remediation-v2-validation',
'preflight remains before first mutation': f['preflight_must_complete_before_first_mutation'] is True,
'candidate binding remains same-transaction only': f['candidate_binding_lifetime']=='same-runtime-transaction-only',
'fresh transaction pkglist remains required': b['fresh_transaction_owned_pkglist_required'] is True,
'human-spaced Slackpkg error remains fail-closed': b['human_spaced_error_must_fail_closed'] is True and b['slackpkg_exit_zero_sufficient'] is False,
'bounded package mutation remains header-only': b['package_mutation_scope']=='kernel-headers-6.18.45-to-6.18.44-to-6.18.45-only',
'authorization has exactly one execution use': f['execution_use_count']==1 and r['execution_use_count']=='1',
'authorization is consumed on executor start': f['authorization_consumed_when']=='executor-runtime-command-starts',
'rerun after any exit remains forbidden': f['rerun_after_any_exit_authorized'] is False and r['rerun_after_any_exit_authorized']=='no',
'executor repository acceptance is revalidated': f['executor_repository_acceptance_revalidated']=='PASS (94 passes, 0 failures)',
'executor transport is authorized': a['runtime_executor_v2_transport_authorized'] is True and r['runtime_executor_v2_transport_authorized']=='yes',
'predecessor transport is authorized': a['predecessor_package_transport_authorized'] is True and r['predecessor_package_transport_authorized']=='yes',
'predecessor staging is authorized inside transaction': a['predecessor_package_staging_authorized'] is True,
'temporary slackpkg configuration is authorized inside transaction': a['temporary_slackpkg_configuration_authorized'] is True,
'local file metadata refresh is authorized inside transaction': a['local_source_metadata_refresh_authorized'] is True and a['repository_refresh_authorized'] is True,
'candidate binding is authorized inside transaction': a['runtime_candidate_binding_authorized'] is True,
'frozen reference apply is authorized inside transaction': a['reference_apply_authorized'] is True,
'runtime scenario execution is authorized once': a['runtime_scenario_execution_authorized'] is True and a['runtime_rerun_authorized'] is True,
'package and Slackpkg mutation are authorized only inside transaction': a['package_action_authorized'] is True and a['slackpkg_mutation_authorized'] is True,
'executor rebuild remains forbidden': a['runtime_executor_v2_build_authorized'] is False,
'predecessor redownload remains forbidden': a['predecessor_package_redownload_authorized'] is False,
'external network remains forbidden': a['network_access_authorized'] is False,
'persistent configuration mutation remains forbidden': a['persistent_configuration_change_authorized'] is False,
'boot and reboot remain forbidden': a['boot_action_authorized'] is False and a['reboot_authorized'] is False,
'cleanup and Phase 2 remain forbidden': a['evidence_cleanup_authorized'] is False and a['phase_2_start_authorized'] is False,
'controller action is now required': p['controller_action_required'] is True and r['controller_action_required']=='yes',
'target machine action is now required': p['machine_action_required'] is True and r['machine_action_required']=='yes',
'family is active rather than safe-paused': p['pause_safe'] is False and p['strong_safe_pause'] is False,
'next stage is result review': p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-result-review',
}
for label, ok in checks.items():
    print(('PASS' if ok else 'FAIL')+'\t'+label)
PYSEM
while IFS=$'\t' read -r status label; do
    [[ $status == PASS ]] && pass "$label" || fail "$label"
done < "$tmp/semantic.out"

assert 'reference document records single-use authority' grep -Fq 'freezes exactly one runtime use' "$doc"
assert 'reference document records executor-v2 SHA-256' grep -Fq 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d' "$doc"
assert 'reference document records predecessor SHA-256' grep -Fq '3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d' "$doc"
assert 'reference document records exact runtime command' grep -Fq -- '--execute-runtime-remediation-v2-validation' "$doc"
assert 'reference document preserves human-spaced error guard' grep -Fq 'Error downloading from ' "$doc"
assert 'reference document preserves v3 PGP marker' grep -Fq 'PGP compatibility marker for Slackpkg checkchangelog only.' "$doc"
assert 'reference document forbids rerun after exit' grep -Fq 'A second invocation is not authorized.' "$doc"
assert 'reference document names result-review next stage' grep -Fq 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-result-review' "$doc"
assert 'CHANGELOG records step 257' grep -Fqx '## Phase 1 step 257 kernel-package-edge runtime-transaction remediation executor-v2 runtime authorization freeze — 2026-09-28' "$repo_root/CHANGELOG.md"

for f in "$helper" "$doc" "$policy" "$record"; do
    if grep -nE '[[:blank:]]+$' "$f" >/dev/null; then fail "$(basename "$f") contains no trailing whitespace"; else pass "$(basename "$f") contains no trailing whitespace"; fi
done

if grep -En '(^|[;&|]) *([[:alnum:]_./-]*/)?(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown|poweroff)( |$)' "$helper" >/dev/null; then
    fail 'step-257 helper contains no executable network package boot reboot or shutdown command'
else
    pass 'step-257 helper contains no executable network package boot reboot or shutdown command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && echo PASS || echo FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
