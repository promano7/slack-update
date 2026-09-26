#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; FAIL_COUNT=$((FAIL_COUNT+1)); }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
regular_non_symlink() { [[ -f $1 && ! -L $1 ]]; }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review.md"
policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review.tsv"
step216_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.sh"
step216_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.md"
step216_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review-harness.sh"
step216_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review-policy.json"
step216_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.tsv"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh"
acceptance="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-executor.sh"
changelog="$repo_root/CHANGELOG.md"

for spec in \
    "$helper|step-217 authorization-review helper" \
    "$doc|step-217 reference document" \
    "$policy|step-217 policy" \
    "$record|step-217 record" \
    "$step216_helper|accepted step-216 helper" \
    "$step216_doc|accepted step-216 document" \
    "$step216_harness|accepted step-216 review harness" \
    "$step216_policy|accepted step-216 policy" \
    "$step216_record|accepted step-216 record" \
    "$executor|reviewed canonical executor" \
    "$builder|reviewed builder" \
    "$acceptance|repository acceptance harness"; do
    file=${spec%%|*}; label=${spec#*|}
    if regular_non_symlink "$file"; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
done

[[ $(sha "$step216_policy") == 'ee0901faf8adf44cc0eb3d54b7e2711e6e02c55c2b83a651beee824b342d837a' ]] && pass 'accepted step-216 policy hash is frozen' || fail 'accepted step-216 policy hash drift'
[[ $(sha "$step216_record") == 'ae9a83777002c8392d7d38f3fab7c82cd20b87a4d7c835d23fe8f428e8b080e7' ]] && pass 'accepted step-216 record hash is frozen' || fail 'accepted step-216 record hash drift'
[[ $(sha "$step216_helper") == '2fa4d0bf124935180bff3ab88dc0c27204c03e05096b3809804d022169b11224' ]] && pass 'accepted step-216 helper hash is frozen' || fail 'accepted step-216 helper hash drift'
[[ $(sha "$step216_doc") == 'f12ff624f98b052246803bd336bafde63f368a78373269ced11f6af6cec050e5' ]] && pass 'accepted step-216 document hash is frozen' || fail 'accepted step-216 document hash drift'
[[ $(sha "$step216_harness") == '068c232265a10efaae255de13d932e9c49fff2b5ac964e2647b400ef9bd58ac0' ]] && pass 'accepted step-216 review harness hash is frozen' || fail 'accepted step-216 review harness hash drift'
[[ $(sha "$executor") == '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300' ]] && pass 'canonical executor hash is frozen' || fail 'canonical executor hash drift'
[[ $(sha "$builder") == '348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea' ]] && pass 'builder hash remains frozen' || fail 'builder hash drift'
[[ $(sha "$acceptance") == 'c9c15fbccd07ec3f74bb29784eff06092ca4fd501d5236996e2c21d6c34ec577' ]] && pass 'repository acceptance harness hash remains frozen' || fail 'repository acceptance harness hash drift'
[[ $(sha "$helper") == '737b47787883ebf99f5d306602b8ad1e0d3da5fcf105475e80eece878281768f' ]] && pass 'step-217 helper matches reviewed SHA-256' || fail 'step-217 helper SHA-256 drift'
[[ $(sha "$doc") == '81809719126afb5e8aca5b63a20b6e8ea2e9c27146bd5febdd56da06f747f6fa' ]] && pass 'step-217 document matches reviewed SHA-256' || fail 'step-217 document SHA-256 drift'
[[ $(sha "$policy") == 'ac49b4b12a9478351761f948d66cca7afaa225a18a2e1e4a7834ed84bfd8bdec' ]] && pass 'step-217 policy matches frozen fixture hash' || fail 'step-217 policy fixture hash drift'
[[ $(sha "$record") == 'ca3371e8667c4bb56937740210901ac13f2decac1d29cfb5758b3d294bb9745a' ]] && pass 'step-217 record matches frozen fixture hash' || fail 'step-217 record fixture hash drift'

bash -n "$helper" && pass 'step-217 helper passes bash syntax validation' || fail 'step-217 helper has invalid shell syntax'
"$helper" --help >/dev/null 2>&1 && pass 'step-217 helper exposes non-mutating help' || fail 'step-217 helper help failed'
if "$helper" --unknown >/dev/null 2>&1; then fail 'step-217 helper accepts unknown option'; else pass 'step-217 helper rejects unknown option'; fi

acceptance_output=$(mktemp)
trap 'rm -f -- "$acceptance_output"' EXIT
if "$acceptance" > "$acceptance_output" 2>&1; then
    pass 'repository acceptance harness still executes successfully'
else
    cat "$acceptance_output" >&2
    fail 'repository acceptance harness failed'
fi
grep -Fq 'Result: PASS (69 passes, 0 failures)' "$acceptance_output" && pass 'repository acceptance remains PASS (69/69)' || fail 'repository acceptance result differs from frozen result'

python3 -m json.tool "$policy" >/dev/null && pass 'step-217 policy is valid JSON' || fail 'step-217 policy is invalid JSON'
if python3 - "$policy" <<'PY'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['schema']==1
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review'
assert p['review_only'] is True
accepted=p['accepted_step_216']
assert accepted['repository_acceptance_result']=='PASS (69 passes, 0 failures)'
auth=p['runtime_authorization']
assert auth['state']=='accepted-single-runtime-transaction-pending-execution'
assert auth['authorization_scope']=='single-bounded-kernel-header-edge-runtime-transaction'
assert auth['execution_target']=='vbox-slackcurrent.vbox-slackcurrent.org'
assert auth['required_running_kernel']=='6.18.45'
assert auth['required_boot_id']=='91901677-1dc3-4a39-a4b1-3f87e6875234'
assert auth['executor']['sha256']=='09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300'
assert auth['executor']['rebuild_before_transport_authorized'] is False
assert auth['predecessor']['record']=='kernel-headers-6.18.44-x86-1'
assert auth['predecessor']['sha256']=='3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'
assert auth['predecessor']['redownload_authorized'] is False
assert auth['exact_execution_command']=='sudo bash phase-1-kernel-package-edge-runtime-transaction-executor.sh --execute-runtime-validation'
assert auth['transaction_lifetime']=='single-execution-authority-consumed-on-runtime-start'
assert auth['candidate_binding_lifetime']=='same-runtime-transaction-only'
assert auth['preflight_must_complete_before_first_mutation'] is True
assert 'boot-id-drift' in auth['authorization_invalidated_by']
assert 'preexisting-runtime-evidence-root' in auth['authorization_invalidated_by']
b=auth['bounded_mutation']
assert b['temporary_predecessor_staging_authorized'] is True
assert b['temporary_slackpkg_configuration_authorized'] is True
assert b['local_file_source_metadata_refresh_authorized'] is True
assert b['single_candidate_binding_authorized'] is True
assert b['frozen_reference_apply_authorized'] is True
assert b['package_mutation_scope']=='kernel-headers-6.18.45-to-6.18.44-to-6.18.45-only'
assert b['external_network_access_authorized'] is False
assert b['boot_action_authorized'] is False
assert b['reboot_authorized'] is False
final=auth['required_final_state']
assert final['header_record']=='kernel-headers-6.18.45-x86-1'
assert final['predecessor_terminal_state_forbidden'] is True
assert final['slackpkg_configuration_and_state_restored'] is True
assert final['geninitrd_policy_restored'] is True
assert final['boot_artifacts_unchanged'] is True
assert final['reboot_performed'] is False
assert auth['evidence']['publication_required_for_result_review'] is True
assert auth['evidence']['result_review_required_before_any_further_machine_action'] is True
a=p['authorization']
assert a['runtime_executor_build_authorized'] is False
assert a['runtime_executor_transport_authorized'] is True
assert a['predecessor_package_transport_authorized'] is True
assert a['predecessor_package_redownload_authorized'] is False
assert a['predecessor_package_staging_authorized'] is True
assert a['temporary_slackpkg_configuration_authorized'] is True
assert a['local_source_metadata_refresh_authorized'] is True
assert a['runtime_candidate_binding_authorized'] is True
assert a['reference_apply_authorized'] is True
assert a['runtime_scenario_execution_authorized'] is True
assert a['package_action_authorized'] is True
assert a['generic_repository_refresh_authorized'] is False
assert a['external_network_access_authorized'] is False
assert a['boot_action_authorized'] is False
assert a['reboot_authorized'] is False
assert a['phase_2_start_authorized'] is False
assert p['machine_action_required'] is True
assert p['controller_action_required'] is True
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-validation-result-review'
assert p['pause_safe'] is False and p['strong_safe_pause'] is False
PY
then pass 'step-217 runtime-authorization semantic assertions pass'; else fail 'step-217 semantic assertions failed'; fi

for line in \
    $'step\t217' \
    $'runtime_authorization_state\taccepted-single-runtime-transaction-pending-execution' \
    $'target_hostname\tvbox-slackcurrent.vbox-slackcurrent.org' \
    $'required_running_kernel\t6.18.45' \
    $'required_boot_id\t91901677-1dc3-4a39-a4b1-3f87e6875234' \
    $'canonical_executor_sha256\t09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300' \
    $'predecessor_record\tkernel-headers-6.18.44-x86-1' \
    $'predecessor_sha256\t3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d' \
    $'candidate_binding_lifetime\tsame-runtime-transaction-only' \
    $'runtime_executor_build_authorized\tno' \
    $'runtime_executor_transport_authorized\tyes' \
    $'predecessor_package_transport_authorized\tyes' \
    $'runtime_scenario_execution_authorized\tyes' \
    $'external_network_access_authorized\tno' \
    $'boot_action_authorized\tno' \
    $'reboot_authorized\tno' \
    $'machine_action_required\tyes' \
    $'controller_action_required\tyes' \
    $'pause_safe\tno' \
    $'next_stage\tphase-1-kernel-package-edge-runtime-transaction-validation-result-review'; do
    grep -Fqx "$line" "$record" && pass "record freezes: ${line%%$'\t'*}" || fail "record missing frozen row: $line"
done

regen=$(mktemp -d)
if "$helper" --output-dir "$regen" >/dev/null 2>&1; then pass 'step-217 helper regenerates policy and record'; else fail 'step-217 helper regeneration failed'; fi
cmp -s "$policy" "$regen/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review-policy.json" && pass 'helper reproduces frozen policy exactly' || fail 'regenerated policy differs'
cmp -s "$record" "$regen/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review.tsv" && pass 'helper reproduces frozen record exactly' || fail 'regenerated record differs'
rm -rf -- "$regen"

normalized_doc=$(tr '\n' ' ' < "$doc" | tr -s '[:space:]' ' ')
[[ $normalized_doc == *'09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300'* ]] && pass 'reference document records exact executor identity' || fail 'reference document omits executor identity'
[[ $normalized_doc == *'3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'* ]] && pass 'reference document records exact predecessor identity' || fail 'reference document omits predecessor identity'
[[ $normalized_doc == *'same-runtime-transaction-only'* ]] && pass 'reference document preserves same-transaction candidate lifetime' || fail 'reference document omits same-transaction candidate lifetime'
[[ $normalized_doc == *'External network access'* ]] && pass 'reference document keeps external network forbidden' || fail 'reference document omits external network prohibition'
[[ $normalized_doc == *'No further machine action is authorized until that result is reviewed'* ]] && pass 'reference document requires result review before further machine action' || fail 'reference document omits result-review gate'
[[ $normalized_doc == *'runtime-transaction-validation-result-review'* ]] && pass 'reference document routes to runtime result review' || fail 'reference document next stage mismatch'

grep -Fq 'Phase 1 step 217 kernel-package-edge runtime transaction executor runtime authorization review' "$changelog" && pass 'CHANGELOG records step 217' || fail 'CHANGELOG does not record step 217'
if grep -Eq '^[[:space:]]*(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then fail 'step-217 helper contains a runtime mutation command'; else pass 'step-217 helper contains no runtime mutation command'; fi
if grep -Eq '\b(curl|wget|ftp|rsync|scp|ssh|ping)\b' "$helper"; then fail 'step-217 helper contains a network client command'; else pass 'step-217 helper contains no network client command'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
