#!/bin/bash
set -u
set -o pipefail
export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd -P)
HELPER="$ROOT/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review.sh"
POLICY="$ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review-policy.json"
RECORD="$ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review.tsv"
STEP146_POLICY="$ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization-review-policy.json"
STEP146_RECORD="$ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization.tsv"
STEP147="$ROOT/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun.sh"
BINDING="$ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
DOC="$ROOT/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review.md"
CHANGELOG="$ROOT/CHANGELOG.md"

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

regular "$HELPER" 'step-148 review helper'
regular "$POLICY" 'step-148 review policy'
regular "$RECORD" 'step-148 review record'
regular "$STEP146_POLICY" 'step-146 authorization policy'
regular "$STEP146_RECORD" 'step-146 authorization record'
regular "$STEP147" 'step-147 execution harness'
regular "$BINDING" 'step-132 target-binding policy'
regular "$DOC" 'step-148 reference document'
regular "$CHANGELOG" 'CHANGELOG'

expect_hash "$HELPER" db85e74373b785f314d120424da1480b6132db5e3678a75c6ccd102c94df243c 'step-148 review helper'
expect_hash "$POLICY" de2813f328b1af80531d68a22c049f9c3be58b6a445398c5c3795b49036ead4b 'step-148 review policy'
expect_hash "$RECORD" 9f8c384d4709e8161ac2f6a3e928b7f3e7baea677e7d850c4c061c1aa4d71361 'step-148 review record'
expect_hash "$STEP146_POLICY" 0a7959de44c4ca849d4f8064d1a6b58632f5735701d2cbf3de626648252bcc8d 'step-146 authorization policy'
expect_hash "$STEP146_RECORD" 200a798e369c5043147f34922a80785c27a73c1b3a21badce5d9bc6ed7205818 'step-146 authorization record'
expect_hash "$STEP147" 60b126b458c69226b8353a13e91b5f3ce1ce0b5a83a00314ce51d2e0857de379 'step-147 execution harness'
expect_hash "$BINDING" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 'step-132 target-binding policy'
expect_hash "$DOC" 15cb62594d0e18372a012ef40ed4dcd1cd67fa5616a3b113503d380b7510fee1 'step-148 reference document'

bash -n "$HELPER" && pass 'the step-148 helper has valid Bash syntax' || fail 'the step-148 helper has invalid Bash syntax'
bash -n "$STEP147" && pass 'the frozen step-147 harness still has valid Bash syntax' || fail 'the frozen step-147 harness has invalid Bash syntax'
python3 -m json.tool "$POLICY" >/dev/null && pass 'the step-148 review policy is valid JSON' || fail 'the step-148 review policy is invalid JSON'
"$HELPER" --help >/dev/null 2>&1 && pass 'the step-148 helper exposes a non-mutating help boundary' || fail 'the step-148 helper help boundary failed'
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'the step-148 helper accepted an unknown option'; else pass 'the step-148 helper rejects unknown options'; fi

helper_output=$(mktemp)
trap 'rm -f "$helper_output"' EXIT
if "$HELPER" > "$helper_output"; then
    pass 'the authenticated post-recovery rerun review completed successfully'
else
    fail 'the authenticated post-recovery rerun review failed'
fi

expect() {
    local key=$1 value=$2 label=$3
    grep -Fqx "$(printf '%s\t%s' "$key" "$value")" "$helper_output" && pass "$label" || fail "$label"
}
expect scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review 'review output records the exact step-148 scenario'
expect evidence_archive_sha256 cccabfa5e3258fee7485bab6cb6b5b0dbc687cf8850d0b96deb9e96854072a46 'the exact step-147 evidence archive is authenticated'
expect step146_authorization_policy_sha256 0a7959de44c4ca849d4f8064d1a6b58632f5735701d2cbf3de626648252bcc8d 'review is bound to the exact step-146 authorization policy'
expect step146_authorization_record_sha256 200a798e369c5043147f34922a80785c27a73c1b3a21badce5d9bc6ed7205818 'review is bound to the exact step-146 authorization record'
expect step147_execution_harness_sha256 60b126b458c69226b8353a13e91b5f3ce1ce0b5a83a00314ce51d2e0857de379 'review is bound to the exact step-147 execution harness'
expect review_policy_sha256 de2813f328b1af80531d68a22c049f9c3be58b6a445398c5c3795b49036ead4b 'helper reports the exact step-148 policy identity'
expect review_record_sha256 9f8c384d4709e8161ac2f6a3e928b7f3e7baea677e7d850c4c061c1aa4d71361 'helper reports the exact step-148 record identity'
expect running_kernel 6.18.45 'the accepted rerun remains on kernel 6.18.45'
expect boot_image /boot/vmlinuz-generic 'the accepted rerun preserves the generic boot image'
expect live_root_token /dev/sda2 'the accepted rerun preserves the recovered live root token'
expect mounted_root_device /dev/sda2 'the accepted rerun preserves the mounted root device'
expect boot_profile grub-direct-generic-no-initrd 'the accepted rerun matches the recovered direct-generic profile'
expect runtime_probe_invoked true 'the runtime probe was exercised by the fresh rerun'
expect runtime_probe_accepted true 'the runtime probe verdict is accepted'
expect system_state_preserved true 'the runtime probe preserved system state'
expect authorization_consumed true 'the fresh step-146 authorization is consumed by execution'
expect authorization_reusable false 'the consumed step-146 authorization is non-reusable'
expect source_remediation_exercised true 'the remediated source is now exercised on Slackware-current'
expect source_remediation_accepted true 'the exercised source remediation is accepted'
expect slackware_current_validation_accepted true 'Slackware-current runtime validation is accepted'
expect slackware_15_released_to_fresh_authorization_review true 'Slackware 15.0 is released only to a fresh authorization review'
expect slackware_15_execution_authorized false 'step 148 grants no Slackware 15.0 machine execution'
expect step132_slackware15_harness_reusable false 'the pre-remediation step-132 Slackware 15.0 harness is not reusable'
expect machine_action_required false 'step 148 itself requires no machine action'
expect repository_refresh_required false 'step 148 requires no Slackware repository refresh'
expect slackware_repository_state_dependency false 'the step-148 safe pause is publication-independent'
expect next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review 'review advances only to a fresh Slackware 15.0 authorization review'
expect pause_safe true 'the completed step-148 review is pause-safe'

if python3 - "$POLICY" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p=json.load(handle)
assert p['evidence']['packages_before_sha256'] == p['evidence']['packages_after_sha256']
assert p['evidence']['slackpkg_metadata_before_sha256'] == p['evidence']['slackpkg_metadata_after_sha256']
assert p['evidence']['boot_state_before_sha256'] == p['evidence']['boot_state_after_sha256']
assert p['evidence']['source_before_record_sha256'] == p['evidence']['source_after_record_sha256']
assert p['evidence']['template_before_record_sha256'] == p['evidence']['template_after_record_sha256']
assert p['slackware_current']['expected_runtime_verdict'] == {
    'boot_mode':'auto','boot_module_state':'available','boot_module_run':1,
    'boot_preparation_layout':'direct-generic-no-initrd','boot_initrd_available':0,
    'boot_grub_available':1,'boot_direct_generic_available':1}
PY
then
    pass 'the review policy freezes exact non-mutation pairs and the accepted runtime verdict'
else
    fail 'the review policy does not preserve the accepted evidence invariants'
fi

if python3 - "$POLICY" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p=json.load(handle)
s15=p['slackware_15']
assert s15['step132_bound_source_sha256'] == 'c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c'
assert s15['accepted_remediated_source_sha256'] == 'aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7'
assert s15['step132_bound_source_sha256'] != s15['accepted_remediated_source_sha256']
assert s15['fresh_authorization_required'] is True
assert s15['fresh_execution_harness_required'] is True
assert s15['step132_slackware15_execution_harness_reusable'] is False
assert s15['execution_authorized'] is False
PY
then
    pass 'the Slackware 15.0 continuation rejects the obsolete pre-remediation harness identity'
else
    fail 'the Slackware 15.0 continuation does not enforce a fresh source-bound harness'
fi

if grep -Fq $'cccabfa5e3258fee7485bab6cb6b5b0dbc687cf8850d0b96deb9e96854072a46\t0a7959de44c4ca849d4f8064d1a6b58632f5735701d2cbf3de626648252bcc8d' "$RECORD" \
    && grep -Fq $'\ttrue\ttrue\ttrue\ttrue\ttrue\ttrue\ttrue\ttrue\tfalse\tfalse\tfalse\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review\ttrue\taccepted' "$RECORD"; then
    pass 'the step-148 record preserves accepted runtime, consumed authorization, held execution, and safe-pause state'
else
    fail 'the step-148 review record is incomplete'
fi

if grep -Fq 'Step 148' "$DOC" \
    && grep -Fq 'cccabfa5e3258fee7485bab6cb6b5b0dbc687cf8850d0b96deb9e96854072a46' "$DOC" \
    && grep -Fq 'root=/dev/sda2' "$DOC" \
    && grep -Fq 'reusing the old step-132 Slackware 15.0 harness would be an invalid' "$DOC" \
    && grep -Fq '`pause_safe=true`' "$DOC"; then
    pass 'the reference document records the accepted rerun, fresh Slackware 15.0 gate, and safe pause'
else
    fail 'the step-148 reference document is incomplete'
fi

if grep -Fq 'Phase 1 step 148' "$CHANGELOG" \
    && grep -Fq 'post-recovery rerun review' "$CHANGELOG"; then
    pass 'CHANGELOG records the step-148 accepted rerun review'
else
    fail 'CHANGELOG does not record step 148'
fi

if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then
    fail 'the step-148 helper contains a package, boot, reboot, or shutdown mutation command'
else
    pass 'the step-148 helper contains no package, boot, reboot, or shutdown mutation command'
fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then
    fail 'the step-148 helper contains a network client command'
else
    pass 'the step-148 helper contains no network client command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
