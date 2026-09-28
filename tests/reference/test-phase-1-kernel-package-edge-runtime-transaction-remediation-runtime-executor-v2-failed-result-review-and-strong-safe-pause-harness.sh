#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.md"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause-policy.json"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze-harness.sh"
prior_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze-policy.json"
prior_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze.tsv"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
assert() {
    local label=$1
    shift
    if "$@"; then pass "$label"; else fail "$label"; fi
}
regular() { [[ -f $1 && ! -L $1 ]]; }
sha_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }

assert 'step-258 helper exists as regular file' regular "$helper"
assert 'step-258 document exists as regular file' regular "$doc"
assert 'step-258 policy exists as regular file' regular "$policy"
assert 'step-258 record exists as regular file' regular "$record"
assert 'accepted step-257 helper exists as regular file' regular "$prior_helper"
assert 'accepted step-257 document exists as regular file' regular "$prior_doc"
assert 'accepted step-257 harness exists as regular file' regular "$prior_harness"
assert 'accepted step-257 policy exists as regular file' regular "$prior_policy"
assert 'accepted step-257 record exists as regular file' regular "$prior_record"
assert 'executor-v2 canonical payload exists as regular file' regular "$executor"
assert 'CHANGELOG exists as regular file' regular "$changelog"

assert 'accepted step-257 helper SHA-256 matches' sha_is "$prior_helper" '43b63cf06bbc9b8de03fdca51e8d694b2c45132f46e1e77037a8ea8f51f98793'
assert 'accepted step-257 document SHA-256 matches' sha_is "$prior_doc" 'c254030cb9c0c81b2bc05efde66197a976385f4eccb9d3e1bac71483e195136b'
assert 'accepted step-257 harness SHA-256 matches' sha_is "$prior_harness" 'ef507545d94a54bb99ba1e54dde7ed4acabb80f1ba6a1b8169210cba9ab637d0'
assert 'accepted step-257 policy SHA-256 matches' sha_is "$prior_policy" 'adb641120d073e8ccef80ce9b3fcaddf7095a88575827d4ff7c2d43b5fa68e0b'
assert 'accepted step-257 record SHA-256 matches' sha_is "$prior_record" '310e711e59e9039238dc6d428dbeb61977e8e4632a153a98a92c918ebb637ae3'
assert 'executor-v2 SHA-256 remains frozen' sha_is "$executor" 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d'
assert 'step-258 helper SHA-256 matches' sha_is "$helper" 'f112bc1131db22a21d5561a15fd05cb2c9094389e9b27512861df4b3c53396a2'
assert 'step-258 document SHA-256 matches' sha_is "$doc" 'eafe9afb4da73466181bff7e00e58c8416ec9db24c0089cdc1c46d2a113654b1'
assert 'step-258 policy SHA-256 matches' sha_is "$policy" '0826aa5af2f5ae998a0d3604486f249922b56b7e47e0aaa7874660f852c3b1bc'
assert 'step-258 record SHA-256 matches' sha_is "$record" '20023a8057f7eea1260c22caa8b8dc52e9025f1cc2ff79af94962ca7d4c95bc5'

assert 'step-258 helper passes bash syntax validation' bash -n "$helper"
assert 'executor-v2 passes bash syntax validation' bash -n "$executor"
assert 'step-258 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail 'step-258 helper rejects unknown option'; else pass 'step-258 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp/generated" > "$tmp/helper.out" 2> "$tmp/helper.err"; then
    pass 'step-258 helper executes successfully'
else
    cat "$tmp/helper.err" >&2
    fail 'step-258 helper executes successfully'
fi
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$tmp/generated/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$tmp/generated/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.tsv"
assert 'helper reports PASS failed result review' grep -Fqx $'failed_result_review_status\tPASS' "$tmp/helper.out"
assert 'helper reports fail-closed runtime result' grep -Fqx $'runtime_result\tFAIL_CLOSED' "$tmp/helper.out"
assert 'helper reports empty pkglist identity' grep -Fqx $'fresh_pkglist_sha256\te3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' "$tmp/helper.out"
assert 'helper revokes runtime rerun' grep -Fqx $'runtime_rerun_authorized\tno' "$tmp/helper.out"
assert 'helper establishes strong safe pause' grep -Fqx $'strong_safe_pause\tyes' "$tmp/helper.out"

python3 - "$policy" "$record" > "$tmp/semantic.out" <<'PY'
import csv,json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
with open(sys.argv[2],encoding='utf-8',newline='') as f:
    r=dict(csv.reader(f,delimiter='\t'))
o=p['observed_runtime_result']
f=p['failure_characterization']
a=p['authorization']
s=p['safe_pause']
checks={
'policy identifies step-258 scenario': p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause' and p['step']==258,
'review status is PASS': p['review_status']=='PASS' and r['review_status']=='PASS',
'runtime result is fail-closed': p['runtime_result']=='FAIL_CLOSED' and o['runtime_result']=='FAIL_CLOSED' and r['runtime_result']=='FAIL_CLOSED',
'step-257 authorization is consumed': p['accepted_step_257']['single_use_authorization_consumed'] is True and p['accepted_step_257']['rerun_authority_revoked'] is True,
'executor start is recorded': o['executor_started'] is True and o['authorization_use_consumed'] is True,
'terminal error is frozen exactly': o['terminal_error']=='ERROR: fresh pkglist exposes 0 exact target candidates instead of one',
'failure stage is before reference apply': o['failure_stage']=='candidate-binding-after-local-refresh-before-reference-apply',
'evidence root is preserved': o['evidence_root']=='/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation-v2' and o['evidence_root_present'] is True,
'result TSV remains absent': o['result_tsv_present'] is False and r['result_tsv_present']=='no',
'candidate binding TSV remains absent': o['candidate_binding_tsv_present'] is False,
'Slackpkg refresh reported PASS': o['slackpkg_refresh']['refresh_status']=='PASS',
'Slackpkg refresh exited zero': o['slackpkg_refresh']['exit_code']==0,
'human-spaced error signal is absent': o['slackpkg_refresh']['human_spaced_error_signal']=='absent',
'pre-refresh pkglist was absent': o['slackpkg_refresh']['pre_refresh_pkglist_state']=='absent',
'post-refresh pkglist is regular': o['slackpkg_refresh']['post_refresh_pkglist_state']=='present-regular',
'fresh pkglist is zero bytes': o['slackpkg_refresh']['pkglist_size_bytes']==0 and r['fresh_pkglist_size_bytes']=='0',
'fresh pkglist SHA is empty-file SHA': o['slackpkg_refresh']['pkglist_sha256']=='e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
'fresh pkglist has zero kernel-header rows': o['slackpkg_refresh']['kernel_headers_rows']==0 and r['kernel_headers_rows']=='0',
'fresh pkglist first twenty rows are empty': o['slackpkg_refresh']['first_twenty_rows']==0,
'cleanup was triggered': o['cleanup']['cleanup_triggered'] is True and r['cleanup_triggered']=='yes',
'cleanup records predecessor rollback source': o['cleanup']['rollback_header_from']=='kernel-headers-6.18.44-x86-1',
'cleanup stderr was empty': o['cleanup']['cleanup_stderr_empty'] is True,
'post-failure header record is restored': o['post_failure_read_only_observation']['kernel_headers_record']=='kernel-headers-6.18.45-x86-1',
'post-failure slackpkg.conf hash is restored': o['post_failure_read_only_observation']['slackpkg_conf_sha256']=='f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
'post-failure mirrors hash is restored': o['post_failure_read_only_observation']['slackpkg_mirrors_sha256']=='71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
'predecessor staging was reached': o['control_flow']['predecessor_staging_reached'] is True,
'temporary Slackpkg configuration was reached': o['control_flow']['temporary_slackpkg_configuration_reached'] is True,
'local metadata refresh was reached': o['control_flow']['local_metadata_refresh_reached'] is True,
'candidate binding did not complete': o['control_flow']['candidate_binding_completed'] is False,
'reference apply was not reached': o['control_flow']['reference_apply_reached'] is False and r['reference_apply_reached']=='no',
'success publication was not reached': o['control_flow']['success_publication_reached'] is False,
'cleanup trap was reached': o['control_flow']['cleanup_trap_reached'] is True,
'failure class identifies empty fresh pkglist': f['class']=='empty-fresh-slackpkg-pkglist-after-successful-local-refresh',
'failure is not misclassified as row matching mismatch': f['not_a_row_matching_mismatch'] is True,
'Slackpkg exit zero is insufficient': f['slackpkg_exit_zero_did_not_establish_candidate_availability'] is True,
'human-spaced download error was not observed': f['human_spaced_download_error_not_observed'] is True,
'root cause remains deliberately unfrozen': f['root_cause_not_yet_frozen'] is True and r['root_cause_frozen']=='no',
'next root-cause focus is FILELIST/pkglist compatibility': 'FILELIST/pkglist' in f['next_root_cause_focus'],
'bounded mutation is acknowledged': p['restoration_assessment']['bounded_mutation_started'] is True,
'only pre-reference package mutation was header staging': p['restoration_assessment']['only_pre_reference_package_mutation']=='kernel-headers-6.18.45-to-6.18.44',
'restoration assessment accepts target header restore': p['restoration_assessment']['target_header_record_restored'] is True,
'restoration assessment accepts Slackpkg restore': p['restoration_assessment']['slackpkg_configuration_restored'] is True and p['restoration_assessment']['slackpkg_mirrors_restored'] is True,
'boot mutation path was not reached': p['restoration_assessment']['boot_mutation_path_not_reached'] is True,
'failed v2 evidence must be preserved': p['preservation_contract']['failed_v2_evidence_must_be_preserved_unchanged'] is True,
'accepted local-source-v3 manifest stays frozen': p['preservation_contract']['accepted_local_source_v3_manifest_sha256']=='8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b',
'executor-v2 remains frozen and must not rerun': p['preservation_contract']['canonical_executor_v2_sha256']=='deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d' and p['preservation_contract']['executor_v2_must_not_be_rerun'] is True,
'target observation is closed': a['target_observation_authorized'] is False,
'probe transport is closed': a['probe_transport_copy_authorized'] is False,
'executor build and transport are closed': a['runtime_executor_v2_build_authorized'] is False and a['runtime_executor_v2_transport_authorized'] is False,
'predecessor transport and staging are closed': a['predecessor_package_transport_authorized'] is False and a['predecessor_package_staging_authorized'] is False,
'temporary Slackpkg configuration is closed': a['temporary_slackpkg_configuration_authorized'] is False,
'local metadata and repository refresh are closed': a['local_source_metadata_refresh_authorized'] is False and a['repository_refresh_authorized'] is False,
'candidate binding and reference apply are closed': a['runtime_candidate_binding_authorized'] is False and a['reference_apply_authorized'] is False,
'runtime scenario and rerun are closed': a['runtime_scenario_execution_authorized'] is False and a['runtime_rerun_authorized'] is False,
'package and Slackpkg mutation are closed': a['package_action_authorized'] is False and a['slackpkg_mutation_authorized'] is False,
'external network and persistent configuration mutation are closed': a['network_access_authorized'] is False and a['persistent_configuration_change_authorized'] is False,
'boot and reboot are closed': a['boot_action_authorized'] is False and a['reboot_authorized'] is False,
'evidence cleanup and Phase 2 are closed': a['evidence_cleanup_authorized'] is False and a['phase_2_start_authorized'] is False,
'only repository root-cause review is open': a['repository_only_root_cause_review_authorized'] is True,
'strong safe pause is frozen': s['strong_safe_pause'] is True and p['strong_safe_pause'] is True and r['strong_safe_pause']=='yes',
'pause is safe': s['pause_safe'] is True and p['pause_safe'] is True and r['pause_safe']=='yes',
'no operational authority remains open': s['no_open_operational_authorization'] is True,
'no machine action is required': p['machine_action_required'] is False and s['machine_action_required'] is False and r['machine_action_required']=='no',
'no controller action is required': p['controller_action_required'] is False and s['controller_action_required'] is False and r['controller_action_required']=='no',
'future machine action requires fresh revalidation': s['fresh_revalidation_required_before_any_future_machine_action'] is True,
'next stage is repository-only root-cause review': p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review',
}
for label,ok in checks.items():
    print(('PASS' if ok else 'FAIL')+'\t'+label)
PY
while IFS=$'\t' read -r status label; do
    [[ $status == PASS ]] && pass "$label" || fail "$label"
done < "$tmp/semantic.out"

# Verify the observed failure was before reference apply in the canonical executor.
bind_line=$(grep -n '^    bind_candidate_set$' "$executor" | cut -d: -f1)
apply_line=$(grep -n '^    run_reference_apply$' "$executor" | cut -d: -f1)
publish_line=$(grep -n '^    publish_evidence$' "$executor" | cut -d: -f1)
if [[ -n $bind_line && -n $apply_line && $bind_line -lt $apply_line ]]; then pass 'executor control flow places candidate binding before reference apply'; else fail 'executor control flow places candidate binding before reference apply'; fi
if [[ -n $apply_line && -n $publish_line && $apply_line -lt $publish_line ]]; then pass 'executor control flow places success publication after reference apply'; else fail 'executor control flow places success publication after reference apply'; fi
assert 'executor fail string matches observed terminal error' grep -Fq 'fresh pkglist exposes $target_count exact target candidates instead of one' "$executor"
assert 'executor cleanup trap restores on failure after mutation' grep -Fq 'if [[ $MUTATION_STARTED -eq 1 && $RESTORATION_COMPLETE -eq 0 ]]' "$executor"
assert 'executor cleanup calls restore_transaction_state' grep -Fq 'restore_transaction_state || cleanup_rc=1' "$executor"
assert 'reference document records empty pkglist SHA-256' grep -Fq 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' "$doc"
assert 'reference document records exact terminal error' grep -Fq 'ERROR: fresh pkglist exposes 0 exact target candidates instead of one' "$doc"
assert 'reference document does not overclaim root cause' grep -Fq 'exact root cause of the empty `pkglist` is intentionally not frozen' "$doc"
assert 'reference document records restored header' grep -Fq 'kernel-headers-6.18.45-x86-1' "$doc"
assert 'reference document records restored Slackpkg fingerprints' grep -Fq 'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4' "$doc"
assert 'reference document records strong safe pause' grep -Fq 'strong_safe_pause=true' "$doc"
assert 'reference document names repository-only next stage' grep -Fq 'phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review' "$doc"
assert 'CHANGELOG records step 258' grep -Fqx '## Phase 1 step 258 kernel-package-edge runtime-transaction remediation executor-v2 failed result review and strong safe pause — 2026-09-28' "$changelog"

for f in "$helper" "$doc" "$policy" "$record"; do
    if grep -nE '[[:blank:]]+$' "$f" >/dev/null; then fail "$(basename "$f") contains no trailing whitespace"; else pass "$(basename "$f") contains no trailing whitespace"; fi
done

if grep -En '(^|[;&|]) *([[:alnum:]_./-]*/)?(slackpkg|upgradepkg|installpkg|removepkg|wget|curl|reboot|shutdown|poweroff)( |$)' "$helper" >/dev/null; then
    fail 'step-258 helper contains no executable network package boot reboot or shutdown command'
else
    pass 'step-258 helper contains no executable network package boot reboot or shutdown command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && echo PASS || echo FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
