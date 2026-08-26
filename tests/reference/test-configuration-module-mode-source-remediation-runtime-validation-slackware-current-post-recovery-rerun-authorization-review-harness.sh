#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
HELPER="$REPO_ROOT/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization-review.sh"
POLICY="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization-review-policy.json"
RECORD="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization.tsv"
RERUN="$REPO_ROOT/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun.sh"
STEP145_POLICY="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review-policy.json"
STEP145_RECORD="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review.tsv"
BINDING="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
SOURCE="$REPO_ROOT/tools/reference/slack-update-reference.sh"
TEMPLATE="$REPO_ROOT/data/config/slack-update.conf"
DOC="$REPO_ROOT/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization-review.md"
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
    [[ $(sha "$path") == "$expected" ]] && pass "$label SHA-256 is frozen" || fail "$label SHA-256 changed"
}

regular "$HELPER" 'step-146 authorization helper'
regular "$POLICY" 'step-146 authorization policy'
regular "$RECORD" 'step-146 authorization record'
regular "$RERUN" 'step-147 rerun execution harness'
regular "$STEP145_POLICY" 'step-145 manual-review policy'
regular "$STEP145_RECORD" 'step-145 manual-review record'
regular "$BINDING" 'step-132 target-binding policy'
regular "$SOURCE" 'accepted reference source'
regular "$TEMPLATE" 'configuration template'
regular "$DOC" 'step-146 reference document'
regular "$CHANGELOG" 'CHANGELOG'

expect_hash "$HELPER" 455539e05383cdaec3fef3d85bffeb1edfdbc8784a037e9f1fa420d5973d495f 'step-146 authorization helper'
expect_hash "$POLICY" 0a7959de44c4ca849d4f8064d1a6b58632f5735701d2cbf3de626648252bcc8d 'step-146 authorization policy'
expect_hash "$RECORD" 200a798e369c5043147f34922a80785c27a73c1b3a21badce5d9bc6ed7205818 'step-146 authorization record'
expect_hash "$RERUN" 60b126b458c69226b8353a13e91b5f3ce1ce0b5a83a00314ce51d2e0857de379 'step-147 rerun execution harness'
expect_hash "$STEP145_POLICY" f0976658c0c1a9ffbdb21bc3ec7a6f9157204f7642469488f515d136ff983e90 'step-145 manual-review policy'
expect_hash "$STEP145_RECORD" 4dd611a3fdb2f35724ba5ad4da3305d6ac8c26889baa346ee838d51662bb1bc3 'step-145 manual-review record'
expect_hash "$BINDING" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 'step-132 target-binding policy'
expect_hash "$SOURCE" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 'accepted remediated source'
expect_hash "$TEMPLATE" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba 'configuration template'
expect_hash "$DOC" ebe529634280235f295bf95bb73c51a53d390a31eb2ba9f4f7ffe1801832a641 'step-146 reference document'

bash -n "$HELPER" && pass 'the step-146 helper has valid Bash syntax' || fail 'the step-146 helper has invalid Bash syntax'
bash -n "$RERUN" && pass 'the step-147 rerun execution harness has valid Bash syntax' || fail 'the step-147 rerun execution harness has invalid Bash syntax'
python3 -m json.tool "$POLICY" >/dev/null && pass 'the step-146 authorization policy is valid JSON' || fail 'the step-146 authorization policy is invalid JSON'
"$HELPER" --help >/dev/null 2>&1 && pass 'the step-146 helper exposes a non-mutating help boundary' || fail 'the step-146 helper help boundary failed'
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'the step-146 helper accepted an unknown option'; else pass 'the step-146 helper rejects unknown options'; fi
"$RERUN" --help >/dev/null 2>&1 && pass 'the step-147 execution harness exposes its explicit execution boundary' || fail 'the step-147 execution harness help boundary failed'

helper_output=$(mktemp)
trap 'rm -f "$helper_output"' EXIT
if "$HELPER" > "$helper_output"; then
    pass 'fresh post-recovery rerun authorization review completed successfully'
else
    fail 'fresh post-recovery rerun authorization review failed'
fi

expect() {
    local key=$1 value=$2 label=$3
    grep -Fqx "$key	$value" "$helper_output" && pass "$label" || fail "$label"
}
expect scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization-review 'authorization output records the post-recovery scenario'
expect authorization_id runtime-slackware-current-post-recovery-rerun 'authorization output records a distinct fresh authorization identity'
expect step145_manual_review_policy_sha256 f0976658c0c1a9ffbdb21bc3ec7a6f9157204f7642469488f515d136ff983e90 'authorization is bound to the exact step-145 policy'
expect step145_manual_review_record_sha256 4dd611a3fdb2f35724ba5ad4da3305d6ac8c26889baa346ee838d51662bb1bc3 'authorization is bound to the exact step-145 record'
expect source_sha256 aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 'authorization remains bound to the accepted remediated source'
expect template_sha256 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba 'authorization preserves the configuration template'
expect target_binding_policy_sha256 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 'authorization preserves the exact target binding'
expect rerun_execution_harness_sha256 60b126b458c69226b8353a13e91b5f3ce1ce0b5a83a00314ce51d2e0857de379 'authorization freezes the new execution harness'
expect authorization_policy_sha256 0a7959de44c4ca849d4f8064d1a6b58632f5735701d2cbf3de626648252bcc8d 'helper reports the exact step-146 policy identity'
expect recovery_review_accepted true 'the accepted recovery review is a prerequisite'
expect recovered_live_root_token /dev/sda2 'the recovered live root token is frozen'
expect source_remediation_exercised false 'source remediation remains unexercised before the rerun'
expect step139_authorization_reused false 'the consumed step-139 authorization is not reused'
expect step143_authorization_reused false 'the consumed step-143 authorization is not reused'
expect fresh_rerun_authorization_granted true 'a fresh rerun authorization is granted'
expect runtime_probe_authorized true 'the runtime probe is authorized only inside the fresh rerun'
expect machine_execution_authorized true 'exactly the new Slackware-current rerun is authorized'
expect authorization_consumable true 'the fresh authorization is single-use consumable'
expect machine_execution_limit 1 'machine execution limit is exactly one'
expect reboots_allowed 0 'no reboot is authorized'
expect repository_refresh_allowed false 'no repository refresh is authorized'
expect package_mutation_allowed false 'no package mutation is authorized'
expect boot_mutation_allowed false 'no boot mutation is authorized'
expect source_change_authorized false 'no source edit is authorized'
expect slackware_15_execution_released false 'Slackware 15.0 remains held'
expect machine_action_required false 'step 146 itself requires no machine action'
expect slackware_repository_state_dependency false 'authorization is independent of Slackware publication state'
expect next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-execution 'authorization advances only to the fresh rerun execution'
expect pause_safe true 'step-146 authorization boundary is pause-safe'

if grep -Fq '"step139_rerun_authorization_reusable": false' "$POLICY" \
    && grep -Fq '"step143_recovery_authorization_reusable": false' "$POLICY" \
    && grep -Fq '"expected_live_root_token": "/dev/sda2"' "$POLICY" \
    && grep -Fq '"runtime_probe_invoked_during_recovery": false' "$POLICY" \
    && grep -Fq '"machine_execution_limit_total": 1' "$POLICY" \
    && grep -Fq '"reboot_limit": 0' "$POLICY"; then
    pass 'the policy records recovery, non-reuse, live-root, single-use, and zero-reboot boundaries'
else
    fail 'the policy is missing a required fresh-authorization boundary'
fi

if grep -Fq $'runtime-slackware-current-post-recovery-rerun\tf0976658c0c1a9ffbdb21bc3ec7a6f9157204f7642469488f515d136ff983e90\t4dd611a3fdb2f35724ba5ad4da3305d6ac8c26889baa346ee838d51662bb1bc3' "$RECORD" \
    && grep -Fq $'\t/dev/sda2\ttrue\ttrue\t1\t0\tfalse\tfalse\tfalse\tfalse\ttrue\tfalse\tfalse\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-execution\ttrue' "$RECORD"; then
    pass 'the authorization record preserves the fresh single-use recovered-root boundary'
else
    fail 'the authorization record does not preserve the expected boundary'
fi

if grep -Fq 'Step 146' "$DOC" \
    && grep -Fq 'root=/dev/sda2' "$DOC" \
    && grep -Fq 'Step 146 creates a distinct' "$DOC" \
    && grep -Fq 'Slackware 15.0 remains held' "$DOC" \
    && grep -Fq '`pause_safe=true`' "$DOC"; then
    pass 'the reference document records the fresh recovered-root authorization and safe pause'
else
    fail 'the step-146 reference document is incomplete'
fi

if grep -Fq 'Phase 1 step 146' "$CHANGELOG" \
    && grep -Fq 'post-recovery rerun authorization' "$CHANGELOG"; then
    pass 'CHANGELOG records the step-146 fresh rerun authorization'
else
    fail 'CHANGELOG does not record step 146'
fi

if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then
    fail 'the step-146 helper contains a package, boot, reboot, or shutdown mutation command'
else
    pass 'the step-146 helper contains no package, boot, reboot, or shutdown mutation command'
fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then
    fail 'the step-146 helper contains a network client command'
else
    pass 'the step-146 helper contains no network client command'
fi
if grep -Fq 'probe_boot_module' "$RERUN" \
    && grep -Fq 'RUNTIME_PROBE_INVOKED=true' "$RERUN" \
    && grep -Fq 'runtime probing is withheld because fail-closed target characterization failed' "$RERUN"; then
    pass 'the step-147 harness invokes the probe only after fail-closed characterization'
else
    fail 'the step-147 harness does not preserve the probe gating boundary'
fi
if grep -Fq 'capture_slackpkg_metadata' "$RERUN" \
    && grep -Fq 'runtime validation preserved package, Slackpkg metadata, boot, source, and template state' "$RERUN"; then
    pass 'the step-147 harness preserves Slackpkg metadata in its non-mutation comparison'
else
    fail 'the step-147 harness lacks the strengthened Slackpkg preservation check'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
