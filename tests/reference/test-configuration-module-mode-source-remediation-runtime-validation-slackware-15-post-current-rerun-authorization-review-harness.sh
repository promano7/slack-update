#!/bin/bash
set -u
set -o pipefail
export LC_ALL=C

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
HELPER="$REPO_ROOT/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review.sh"
POLICY="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review-policy.json"
RECORD="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization.tsv"
EXECUTION="$REPO_ROOT/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh"
STEP148_POLICY="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review-policy.json"
STEP148_RECORD="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review.tsv"
BINDING="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
OLD_HARNESS="$REPO_ROOT/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15.sh"
CLOSURE="$REPO_ROOT/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
SOURCE="$REPO_ROOT/tools/reference/slack-update-reference.sh"
TEMPLATE="$REPO_ROOT/data/config/slack-update.conf"
DOC="$REPO_ROOT/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review.md"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

PASS_COUNT=0
FAIL_COUNT=0
pass() { PASS_COUNT=$((PASS_COUNT + 1)); printf 'PASS: %s\n' "$*"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); printf 'FAIL: %s\n' "$*"; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
regular() {
    local path=$1 label=$2
    [[ -f $path && ! -L $path ]] && pass "$label is a regular non-symlink file" || fail "$label is missing or unsafe"
}
expect_hash() {
    local path=$1 expected=$2 label=$3
    [[ -f $path && $(sha "$path") == "$expected" ]] && pass "$label SHA-256 is frozen" || fail "$label SHA-256 changed"
}

regular "$HELPER" 'step-149 authorization helper'
regular "$POLICY" 'step-149 authorization policy'
regular "$RECORD" 'step-149 authorization record'
regular "$EXECUTION" 'fresh Slackware 15.0 execution harness'
regular "$STEP148_POLICY" 'step-148 accepted review policy'
regular "$STEP148_RECORD" 'step-148 accepted review record'
regular "$BINDING" 'step-132 target-binding policy'
regular "$OLD_HARNESS" 'obsolete step-132 Slackware 15.0 harness'
regular "$CLOSURE" 'accepted Slackware 15.0 ELILO closure record'
regular "$SOURCE" 'accepted remediated reference source'
regular "$TEMPLATE" 'configuration template'
regular "$DOC" 'step-149 reference document'
regular "$CHANGELOG" 'CHANGELOG'

expect_hash "$HELPER" 7b0f4391c934512b88723202750650ded03d6c3dff54dc7b3cab3fa675218b52 'step-149 authorization helper'
expect_hash "$POLICY" d2877fce33c417ff8318fbed3e64a0fe409786f475a1d25ccf97f712a159037f 'step-149 authorization policy'
expect_hash "$RECORD" 7058af65141f55d664857ada09d1c29431012f78925c38d4af08d628478d0634 'step-149 authorization record'
expect_hash "$EXECUTION" 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 'fresh Slackware 15.0 execution harness'
expect_hash "$STEP148_POLICY" de2813f328b1af80531d68a22c049f9c3be58b6a445398c5c3795b49036ead4b 'step-148 accepted review policy'
expect_hash "$STEP148_RECORD" 9f8c384d4709e8161ac2f6a3e928b7f3e7baea677e7d850c4c061c1aa4d71361 'step-148 accepted review record'
expect_hash "$BINDING" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 'step-132 target-binding policy'
expect_hash "$OLD_HARNESS" 0226e6d48483e0014c699e5affe224bceaa07f8d767673ba30700c7ee21b670c 'obsolete step-132 Slackware 15.0 harness'
expect_hash "$CLOSURE" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 'accepted Slackware 15.0 ELILO closure record'
expect_hash "$SOURCE" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 'accepted remediated reference source'
expect_hash "$TEMPLATE" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba 'configuration template'
expect_hash "$DOC" d514deaf025df1ffeab8911e0806968f3e18a557a10c3f91134ea883c609c4f5 'step-149 reference document'

bash -n "$HELPER" && pass 'the step-149 helper has valid Bash syntax' || fail 'the step-149 helper has invalid Bash syntax'
bash -n "$EXECUTION" && pass 'the fresh Slackware 15.0 execution harness has valid Bash syntax' || fail 'the fresh Slackware 15.0 execution harness has invalid Bash syntax'
python3 -m json.tool "$POLICY" >/dev/null && pass 'the step-149 authorization policy is valid JSON' || fail 'the step-149 authorization policy is invalid JSON'
"$HELPER" --help >/dev/null 2>&1 && pass 'the step-149 helper exposes a non-mutating help boundary' || fail 'the step-149 helper help boundary failed'
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'the step-149 helper accepted an unknown option'; else pass 'the step-149 helper rejects unknown options'; fi
"$EXECUTION" --help >/dev/null 2>&1 && pass 'the fresh execution harness exposes its explicit machine boundary' || fail 'the fresh execution harness help boundary failed'

helper_output=$(mktemp)
trap 'rm -f "$helper_output"' EXIT
if "$HELPER" > "$helper_output"; then
    pass 'fresh Slackware 15.0 authorization review completed successfully'
else
    fail 'fresh Slackware 15.0 authorization review failed'
fi

expect() {
    local key=$1 value=$2 label=$3
    grep -Fqx "$(printf '%s\t%s' "$key" "$value")" "$helper_output" && pass "$label" || fail "$label"
}
expect scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review 'authorization output records the exact step-149 scenario'
expect authorization_id runtime-slackware-15-post-current-rerun 'authorization output records a fresh Slackware 15.0 authorization identity'
expect step148_review_policy_sha256 de2813f328b1af80531d68a22c049f9c3be58b6a445398c5c3795b49036ead4b 'authorization is bound to the exact step-148 policy'
expect step148_review_record_sha256 9f8c384d4709e8161ac2f6a3e928b7f3e7baea677e7d850c4c061c1aa4d71361 'authorization is bound to the exact step-148 record'
expect source_sha256 aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 'authorization is bound to the accepted remediated source'
expect template_sha256 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba 'authorization preserves the configuration template'
expect target_binding_policy_sha256 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 'authorization preserves the historical target identity'
expect obsolete_step132_slackware15_harness_sha256 0226e6d48483e0014c699e5affe224bceaa07f8d767673ba30700c7ee21b670c 'authorization identifies the obsolete step-132 harness'
expect obsolete_step132_slackware15_harness_reusable false 'obsolete step-132 harness reuse is denied'
expect fresh_execution_harness_sha256 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 'authorization freezes the fresh execution harness'
expect authorization_record_sha256 7058af65141f55d664857ada09d1c29431012f78925c38d4af08d628478d0634 'authorization freezes the exact record'
expect authorization_policy_sha256 d2877fce33c417ff8318fbed3e64a0fe409786f475a1d25ccf97f712a159037f 'helper reports the exact step-149 policy identity'
expect slackware_current_validation_accepted true 'accepted Slackware-current validation is a prerequisite'
expect source_remediation_exercised_and_accepted true 'source remediation is already exercised and accepted'
expect fresh_slackware15_authorization_granted true 'a fresh Slackware 15.0 authorization is granted'
expect machine_execution_authorized true 'exactly one future Slackware 15.0 execution is authorized'
expect authorization_consumable true 'the authorization is single-use consumable'
expect machine_execution_limit 1 'machine execution limit is exactly one'
expect reboots_allowed 0 'no reboot is authorized'
expect repository_refresh_allowed false 'no repository refresh is authorized'
expect package_mutation_allowed false 'no package mutation is authorized'
expect boot_mutation_allowed false 'no boot mutation is authorized'
expect source_change_authorized false 'no source edit is authorized'
expect configuration_template_change_authorized false 'no configuration-template edit is authorized'
expect contract_change_authorized false 'no contract change is authorized'
expect retry_authorized false 'a failed execution does not authorize a retry'
expect machine_action_required false 'step 149 itself requires no machine action'
expect slackware_repository_state_dependency false 'authorization is independent of Slackware publication state'
expect next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-execution 'authorization advances only to the fresh Slackware 15.0 execution'
expect pause_safe true 'step-149 authorization boundary is pause-safe'

if python3 - "$POLICY" "$STEP148_POLICY" "$BINDING" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as h: p=json.load(h)
with open(sys.argv[2], encoding='utf-8') as h: s=json.load(h)
with open(sys.argv[3], encoding='utf-8') as h: b=json.load(h)
assert p['accepted_source_sha256'] == 'aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7'
assert p['step132_bound_source_sha256'] == 'c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c'
assert p['accepted_source_sha256'] != p['step132_bound_source_sha256']
assert p['obsolete_step132_slackware15_harness_reusable'] is False
assert p['execution']['execution_harness_sha256'] == '346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75'
assert p['authorization']['authorization_consumed_on_execution_attempt'] is True
assert p['authorization']['retry_authorized'] is False
assert p['execution']['evidence_must_preserve'] == ['package_inventory','slackpkg_metadata','boot_state','source','configuration_template']
assert s['source_remediation']['accepted'] is True
assert s['slackware_15']['step132_slackware15_execution_harness_reusable'] is False
assert b['source_sha256'] == p['step132_bound_source_sha256']
PY
then
    pass 'the policy enforces fresh-source binding, obsolete-harness rejection, single-attempt consumption, and strengthened evidence preservation'
else
    fail 'the step-149 policy does not enforce the required fresh authorization boundary'
fi

if grep -Fq 'RUNTIME_PROBE_INVOKED=true' "$EXECUTION" \
    && grep -Fq 'runtime probing is withheld because fail-closed target characterization failed' "$EXECUTION" \
    && grep -Fq 'capture_slackpkg_metadata' "$EXECUTION" \
    && grep -Fq 'AUTHORIZATION_CONSUMED_BY_EXECUTION=true' "$EXECUTION"; then
    pass 'the fresh execution harness consumes one attempt, gates the probe, and preserves Slackpkg metadata'
else
    fail 'the fresh execution harness lacks a required execution-safety control'
fi

if grep -Fq 'Step 149' "$DOC" \
    && grep -Fq 'historical Slackware 15.0 execution harness' "$DOC" \
    && grep -Fq '346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75' "$DOC" \
    && grep -Fq '`pause_safe=true`' "$DOC"; then
    pass 'the reference document records the fresh harness, obsolete boundary, and safe pause'
else
    fail 'the step-149 reference document is incomplete'
fi

if grep -Fq 'Phase 1 step 149' "$CHANGELOG" \
    && grep -Fq 'post-current-rerun authorization review' "$CHANGELOG"; then
    pass 'CHANGELOG records the step-149 authorization review'
else
    fail 'CHANGELOG does not record step 149'
fi

if grep -Eq '^[[:space:]]*(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$HELPER"; then
    fail 'the step-149 helper contains a package, boot, reboot, or shutdown mutation command'
else
    pass 'the step-149 helper contains no package, boot, reboot, or shutdown mutation command'
fi
if grep -Eq '^[[:space:]]*(curl|wget|rsync|scp|ssh)([[:space:]]|$)' "$HELPER"; then
    fail 'the step-149 helper contains a network client command'
else
    pass 'the step-149 helper contains no network client command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
