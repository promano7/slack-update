#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.md"
policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.tsv"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
acceptance="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-executor.sh"
step215_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-design-review.sh"
step215_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-executor-design-review.md"
step215_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-executor-design-review-harness.sh"
step215_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-design-review-policy.json"
step215_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-design-review.tsv"
reference="$repo_root/tools/reference/slack-update-reference.sh"
config="$repo_root/data/config/slack-update.conf"
changelog="$repo_root/CHANGELOG.md"

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
regular() { [[ -f $1 && ! -L $1 ]]; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }

for pair in \
    "$helper|step-216 implementation-review helper" \
    "$doc|step-216 reference document" \
    "$policy|step-216 policy" \
    "$record|step-216 record" \
    "$builder|reviewed builder" \
    "$body|reviewed executor body" \
    "$executor|reviewed canonical executor" \
    "$acceptance|repository acceptance harness" \
    "$step215_helper|accepted step-215 helper" \
    "$step215_doc|accepted step-215 document" \
    "$step215_harness|accepted step-215 harness" \
    "$step215_policy|accepted step-215 policy" \
    "$step215_record|accepted step-215 record" \
    "$reference|frozen reference script" \
    "$config|frozen effective configuration"; do
    file=${pair%%|*}
    label=${pair#*|}
    if regular "$file"; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
done

[[ $(sha "$step215_helper") == 'f49db1dd4e7406a53d10ae2ffe6fd7c15249f4f91565af136772ff7c049d28e7' ]] && pass 'accepted step-215 helper hash is frozen' || fail 'accepted step-215 helper hash mismatch'
[[ $(sha "$step215_doc") == '524231a17afa3e185fe6e1634ebc3dd6ae03ae2cbfd188f86a1c40919d7cc14c' ]] && pass 'accepted step-215 document hash is frozen' || fail 'accepted step-215 document hash mismatch'
[[ $(sha "$step215_harness") == '2e4677553ba440ddb587fd3c7c3fc61bfaeca3264bb0ddceb1890fffe30cbbcd' ]] && pass 'accepted step-215 harness hash is frozen' || fail 'accepted step-215 harness hash mismatch'
[[ $(sha "$step215_policy") == '7744fd2e3c55af9d9903a6d3e5000d2447342d05b0a3dec6b582c5544973e0e6' ]] && pass 'accepted step-215 policy hash is frozen' || fail 'accepted step-215 policy hash mismatch'
[[ $(sha "$step215_record") == 'cf2ad02bc99f8b51e8589a8f02a693e87b2d4317afb14ae6395baf90d07fc732' ]] && pass 'accepted step-215 record hash is frozen' || fail 'accepted step-215 record hash mismatch'
[[ $(sha "$reference") == '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415' ]] && pass 'frozen reference script hash is preserved' || fail 'reference script hash drift'
[[ $(sha "$config") == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' ]] && pass 'frozen effective configuration hash is preserved' || fail 'effective configuration hash drift'

[[ $(sha "$helper") == '2fa4d0bf124935180bff3ab88dc0c27204c03e05096b3809804d022169b11224' ]] && pass 'step-216 helper matches reviewed SHA-256' || fail 'step-216 helper SHA-256 drift'
[[ $(sha "$doc") == 'f12ff624f98b052246803bd336bafde63f368a78373269ced11f6af6cec050e5' ]] && pass 'step-216 document matches reviewed SHA-256' || fail 'step-216 document SHA-256 drift'
[[ $(sha "$builder") == '348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea' ]] && pass 'reviewed builder hash is frozen' || fail 'reviewed builder hash drift'
[[ $(sha "$body") == '47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581' ]] && pass 'reviewed executor body hash is frozen' || fail 'reviewed executor body hash drift'
[[ $(sha "$executor") == '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300' ]] && pass 'reviewed canonical executor hash is frozen' || fail 'reviewed canonical executor hash drift'
[[ $(sha "$acceptance") == 'c9c15fbccd07ec3f74bb29784eff06092ca4fd501d5236996e2c21d6c34ec577' ]] && pass 'repository acceptance harness hash is frozen' || fail 'repository acceptance harness hash drift'
[[ $(sha "$policy") == 'ee0901faf8adf44cc0eb3d54b7e2711e6e02c55c2b83a651beee824b342d837a' ]] && pass 'step-216 policy matches frozen fixture hash' || fail 'step-216 policy fixture hash drift'
[[ $(sha "$record") == 'ae9a83777002c8392d7d38f3fab7c82cd20b87a4d7c835d23fe8f428e8b080e7' ]] && pass 'step-216 record matches frozen fixture hash' || fail 'step-216 record fixture hash drift'

bash -n "$helper" && pass 'step-216 helper passes bash syntax validation' || fail 'step-216 helper has invalid shell syntax'
bash -n "$builder" && pass 'reviewed builder passes bash syntax validation' || fail 'reviewed builder has invalid shell syntax'
bash -n "$body" && pass 'reviewed executor body passes bash syntax validation' || fail 'reviewed executor body has invalid shell syntax'
bash -n "$executor" && pass 'reviewed canonical executor passes bash syntax validation' || fail 'reviewed canonical executor has invalid shell syntax'
"$helper" --help >/dev/null 2>&1 && pass 'step-216 helper exposes non-mutating help' || fail 'step-216 helper help failed'
if "$helper" --unknown >/dev/null 2>&1; then fail 'step-216 helper accepts unknown option'; else pass 'step-216 helper rejects unknown option'; fi

acceptance_output=$(mktemp)
trap 'rm -f -- "$acceptance_output"' EXIT
if "$acceptance" > "$acceptance_output" 2>&1; then
    pass 'repository acceptance harness executes successfully'
else
    cat "$acceptance_output" >&2
    fail 'repository acceptance harness failed'
fi
grep -Fq 'Result: PASS (69 passes, 0 failures)' "$acceptance_output" && pass 'repository acceptance result is frozen PASS (69/69)' || fail 'repository acceptance result differs from reviewed result'

python3 -m json.tool "$policy" >/dev/null && pass 'step-216 policy is valid JSON' || fail 'step-216 policy is invalid JSON'
if python3 - "$policy" <<'PY'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['schema']==1
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review'
assert p['review_only'] is True
assert p['accepted_step_215']['design_state']=='reviewed'
impl=p['implementation']
assert impl['state']=='implemented-reviewed-awaiting-runtime-authorization'
assert impl['builder_sha256']=='348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea'
assert impl['executor_body_sha256']=='47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581'
assert impl['canonical_executor_sha256']=='09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300'
assert impl['repository_acceptance_result']=='PASS (69 passes, 0 failures)'
assert impl['target_requires_repository'] is False
assert impl['runtime_acknowledgement']=='--execute-runtime-validation'
assert impl['predecessor_record']=='kernel-headers-6.18.44-x86-1'
assert impl['target_record']=='kernel-headers-6.18.45-x86-1'
guards=p['reviewed_runtime_guards']
assert guards['cleanup_trap_before_predecessor_staging'] is True
assert guards['header_only_staging_delta_required'] is True
assert guards['candidate_refresh_in_network_namespace'] is True
assert guards['reference_apply_in_network_namespace'] is True
assert guards['external_network_access_allowed'] is False
assert guards['candidate_binding_lifetime']=='same-runtime-transaction-only'
assert guards['expected_upgrade_count']==1
assert guards['expected_install_new_count']==0
assert guards['expected_non_header_upgrade_count']==0
assert guards['expected_configured_boot_upgrade_count']==0
assert guards['failure_restores_target_header'] is True
assert guards['slackpkg_configuration_and_state_restore_required'] is True
assert guards['geninitrd_policy_restore_required'] is True
assert guards['boot_artifact_fingerprint_must_be_unchanged'] is True
assert guards['predecessor_terminal_state_forbidden'] is True
assert guards['reboot_forbidden'] is True
a=p['authorization']
assert a['repository_only_runtime_authorization_review_authorized'] is True
for key in ('runtime_executor_build_authorized','runtime_executor_transport_authorized','predecessor_package_transport_authorized','predecessor_package_staging_authorized','temporary_slackpkg_configuration_authorized','local_source_metadata_refresh_authorized','runtime_candidate_binding_authorized','reference_apply_authorized','runtime_scenario_execution_authorized','package_action_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized'):
    assert a[key] is False
assert p['machine_action_required'] is False
assert p['controller_action_required'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review'
assert p['pause_safe'] is False and p['strong_safe_pause'] is False
PY
then pass 'step-216 implementation-review semantic assertions pass'; else fail 'step-216 semantic assertions failed'; fi

for line in \
    $'step\t216' \
    $'implementation_state\timplemented-reviewed-awaiting-runtime-authorization' \
    $'builder_sha256\t348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea' \
    $'executor_body_sha256\t47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581' \
    $'canonical_executor_sha256\t09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300' \
    $'repository_acceptance_result\tPASS (69 passes, 0 failures)' \
    $'fresh_boot_id\t91901677-1dc3-4a39-a4b1-3f87e6875234' \
    $'predecessor_record\tkernel-headers-6.18.44-x86-1' \
    $'target_record\tkernel-headers-6.18.45-x86-1' \
    $'candidate_binding_lifetime\tsame-runtime-transaction-only' \
    $'runtime_executor_build_authorized\tno' \
    $'runtime_scenario_execution_authorized\tno' \
    $'machine_action_required\tno' \
    $'pause_safe\tno' \
    $'next_stage\tphase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review'; do
    grep -Fqx "$line" "$record" && pass "record freezes: ${line%%$'\t'*}" || fail "record missing frozen row: $line"
done

regen=$(mktemp -d)
if "$helper" --output-dir "$regen" >/dev/null 2>&1; then pass 'step-216 helper regenerates policy and record'; else fail 'step-216 helper regeneration failed'; fi
cmp -s "$policy" "$regen/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review-policy.json" && pass 'helper reproduces frozen policy exactly' || fail 'regenerated policy differs'
cmp -s "$record" "$regen/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.tsv" && pass 'helper reproduces frozen record exactly' || fail 'regenerated record differs'
rm -rf -- "$regen"

normalized_doc=$(tr '\n' ' ' < "$doc" | tr -s '[:space:]' ' ')
[[ $normalized_doc == *'PASS (69 passes, 0 failures)'* ]] && pass 'reference document records repository acceptance result' || fail 'reference document omits repository acceptance result'
[[ $normalized_doc == *'same-runtime-transaction-only'* ]] && pass 'reference document records same-transaction candidate boundary' || fail 'reference document omits same-transaction candidate boundary'
[[ $normalized_doc == *'network namespace'* ]] && pass 'reference document records network namespace isolation' || fail 'reference document omits network namespace isolation'
[[ $normalized_doc == *'6.18.44 predecessor is never an acceptable terminal state'* ]] && pass 'reference document records predecessor terminal-state prohibition' || fail 'reference document omits predecessor terminal-state prohibition'
[[ $normalized_doc == *'runtime-transaction-executor-runtime-authorization-review'* ]] && pass 'reference document routes to runtime authorization review' || fail 'reference document next stage mismatch'

grep -Fq 'Phase 1 step 216 kernel-package-edge runtime transaction executor implementation review' "$changelog" && pass 'CHANGELOG records step 216' || fail 'CHANGELOG does not record step 216'
if grep -Eq '^[[:space:]]*(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then fail 'step-216 helper contains a runtime mutation command'; else pass 'step-216 helper contains no runtime mutation command'; fi
if grep -Eq '\b(curl|wget|ftp|rsync|scp|ssh|ping)\b' "$helper"; then fail 'step-216 helper contains a network client command'; else pass 'step-216 helper contains no network client command'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
