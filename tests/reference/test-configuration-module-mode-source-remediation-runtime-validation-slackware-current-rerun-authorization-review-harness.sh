#!/bin/bash
set -u
set -o pipefail
export LC_ALL=C

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(cd -- "$SCRIPT_DIR/../.." && pwd -P)
SOURCE="$REPO_ROOT/tools/reference/slack-update-reference.sh"
TEMPLATE="$REPO_ROOT/data/config/slack-update.conf"
CONTRACT="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
BINDING="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
OLD_HARNESS="$REPO_ROOT/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current.sh"
REGRESSION="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.tsv"
REGRESSION_POLICY="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review-policy.json"
REGRESSION_HELPER="$REPO_ROOT/tools/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.sh"
AUTH="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization.tsv"
POLICY="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review-policy.json"
HELPER="$REPO_ROOT/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review.sh"
DOC="$REPO_ROOT/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review.md"
RERUN="$REPO_ROOT/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun.sh"

PASS_COUNT=0
FAIL_COUNT=0
pass() { PASS_COUNT=$((PASS_COUNT+1)); printf 'PASS: %s\n' "$*"; }
fail() { FAIL_COUNT=$((FAIL_COUNT+1)); printf 'FAIL: %s\n' "$*"; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }

check_file() { local p=$1 l=$2; if [[ -f "$p" && ! -L "$p" ]]; then pass "$l is a regular non-symlink file"; else fail "$l is missing or unsafe"; fi; }
check_sha() { local p=$1 e=$2 l=$3; if [[ -f "$p" && $(sha "$p") == "$e" ]]; then pass "$l has the exact reviewed SHA-256"; else fail "$l SHA-256 mismatch"; fi; }

check_file "$SOURCE" "accepted remediated reference implementation"
check_file "$TEMPLATE" "configuration template"
check_file "$CONTRACT" "optional-module contract"
check_file "$BINDING" "accepted step-132 target-binding policy"
check_file "$OLD_HARNESS" "consumed step-133 execution harness"
check_file "$REGRESSION" "accepted step-138 regression record"
check_file "$REGRESSION_POLICY" "accepted step-138 regression policy"
check_file "$REGRESSION_HELPER" "corrected step-138 regression helper"
check_file "$AUTH" "step-139 rerun authorization record"
check_file "$POLICY" "step-139 rerun authorization policy"
check_file "$HELPER" "step-139 rerun authorization helper"
check_file "$DOC" "step-139 rerun authorization document"
check_file "$RERUN" "step-139 rerun execution harness"

check_sha "$SOURCE" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 "accepted remediated reference implementation"
check_sha "$TEMPLATE" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
check_sha "$CONTRACT" f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9 "optional-module contract"
check_sha "$BINDING" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "accepted step-132 target-binding policy"
check_sha "$OLD_HARNESS" 9f54d2c7d27f46e7d522a8046274d67860a5a59f455e796e467b7f6d23961d62 "consumed step-133 execution harness"
check_sha "$REGRESSION" 18de033bdde24bf7c1072314cded46e134cee06aac8434f47f3318e97995d30d "accepted step-138 regression record"
check_sha "$REGRESSION_POLICY" 43c7b538d06e142180aa343bc743ab11c341e71a4ace6ea0909efac1be90f4ac "accepted step-138 regression policy"
check_sha "$REGRESSION_HELPER" 791199d3f3967e87a610aed86bcaf62ef48e1d78f8941e398e0a962261066f97 "corrected step-138 regression helper"
check_sha "$AUTH" db55dd0eb7349790fa79cc8a1261075d59397e4c9b7a4d24120733093248d651 "step-139 rerun authorization record"
check_sha "$POLICY" 5d0dc91852d8efe5ff203be68468ca5db4cfb6c718e1f4430caf4bf75550a6ba "step-139 rerun authorization policy"
check_sha "$HELPER" 691994ce4bd64609b23ceefde849076a8ef72d0ab107680a8982c40f31dc28d2 "step-139 rerun authorization helper"
check_sha "$DOC" 12bd80dda1aa0501c201c3b2e172fba82994282436fd76d655221cb66b5bb593 "step-139 rerun authorization document"
check_sha "$RERUN" 0099213437acb8184019dd4f98f63de8f1c6821924ad08f93e8ff85f4288b120 "step-139 rerun execution harness"

if bash -n "$HELPER"; then pass "rerun-authorization helper is shell-syntax valid"; else fail "rerun-authorization helper has invalid shell syntax"; fi
if bash -n "$RERUN"; then pass "rerun execution harness is shell-syntax valid"; else fail "rerun execution harness has invalid shell syntax"; fi
if "$HELPER" --help >/dev/null 2>&1; then pass "rerun-authorization helper exposes a non-mutating help boundary"; else fail "rerun-authorization helper help boundary failed"; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail "rerun-authorization helper accepted an unknown option"; else pass "rerun-authorization helper rejects unknown options"; fi
if "$RERUN" --help >/dev/null 2>&1; then pass "rerun execution harness exposes its explicit execution boundary"; else fail "rerun execution harness help boundary failed"; fi
if python3 -m json.tool "$POLICY" >/dev/null; then pass "rerun-authorization policy is valid JSON"; else fail "rerun-authorization policy is invalid JSON"; fi

helper_output=$(mktemp)
source_before=$(sha "$SOURCE")
template_before=$(sha "$TEMPLATE")
contract_before=$(sha "$CONTRACT")
binding_before=$(sha "$BINDING")
old_harness_before=$(sha "$OLD_HARNESS")
regression_before=$(sha "$REGRESSION")
regression_policy_before=$(sha "$REGRESSION_POLICY")
regression_helper_before=$(sha "$REGRESSION_HELPER")
if "$HELPER" >"$helper_output"; then pass "Slackware-current rerun authorization review completed successfully"; else fail "Slackware-current rerun authorization review failed"; fi
[[ $(sha "$SOURCE") == "$source_before" ]] && pass "authorization review did not modify the reference implementation" || fail "authorization review modified the reference implementation"
[[ $(sha "$TEMPLATE") == "$template_before" ]] && pass "authorization review did not modify the configuration template" || fail "authorization review modified the configuration template"
[[ $(sha "$CONTRACT") == "$contract_before" ]] && pass "authorization review did not modify the optional-module contract" || fail "authorization review modified the optional-module contract"
[[ $(sha "$BINDING") == "$binding_before" ]] && pass "authorization review preserved the step-132 target binding" || fail "authorization review modified the step-132 target binding"
[[ $(sha "$OLD_HARNESS") == "$old_harness_before" ]] && pass "authorization review preserved the consumed step-133 harness" || fail "authorization review modified the consumed step-133 harness"
[[ $(sha "$REGRESSION") == "$regression_before" ]] && pass "authorization review preserved the accepted step-138 regression record" || fail "authorization review modified the regression record"
[[ $(sha "$REGRESSION_POLICY") == "$regression_policy_before" ]] && pass "authorization review preserved the accepted step-138 regression policy" || fail "authorization review modified the regression policy"
[[ $(sha "$REGRESSION_HELPER") == "$regression_helper_before" ]] && pass "authorization review preserved the corrected step-138 helper" || fail "authorization review modified the corrected regression helper"

expect() { local k=$1 v=$2; if grep -Fqx "$k	$v" "$helper_output"; then pass "$3"; else fail "$3"; fi; }
expect schema 1 "authorization output records schema 1"
expect scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review "authorization output records the expected scenario"
expect source_sha256 aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 "authorization remains bound to the accepted remediated source"
expect target_binding_policy_sha256 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "authorization preserves the exact step-132 VM binding"
expect rerun_execution_harness_sha256 0099213437acb8184019dd4f98f63de8f1c6821924ad08f93e8ff85f4288b120 "authorization freezes the new rerun harness"
expect step138_regression_accepted true "authorization consumes the accepted regression result"
expect target_binding_preserved true "authorization records the target binding as preserved"
expect consumed_step133_authorization_reused false "consumed step-133 authorization remains non-reusable"
expect fresh_rerun_authorization_granted true "a fresh rerun authorization is granted"
expect machine_execution_authorized true "exactly the new Slackware-current rerun is authorized"
expect authorization_consumable true "rerun authorization is single-use consumable"
expect machine_execution_limit 1 "machine execution limit is exactly one"
expect reboots_allowed 0 "no reboot is authorized"
expect repository_refresh_allowed false "no Slackware repository refresh is authorized"
expect package_mutation_allowed false "no package mutation is authorized"
expect boot_mutation_allowed false "no boot mutation is authorized"
expect source_change_authorized false "no further source edit is authorized"
expect slackware_15_execution_released false "Slackware 15.0 remains held"
expect machine_action_required false "step 139 itself requires no machine action"
expect slackware_repository_state_dependency false "authorization is independent of Slackware publication state"
expect next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-execution "authorization advances only to the single rerun execution"
expect pause_safe true "step-139 authorization boundary is pause-safe"

if grep -Fq 'accepted_step132_target_binding_policy_sha256' "$POLICY"    && grep -Fq 'runtime_machine_validation_still_required' "$POLICY"    && grep -Fq 'machine_execution_limit_total' "$POLICY"    && grep -Fq 'repository_refresh_forbidden' "$POLICY"; then
    pass "rerun policy records the binding, validation, single-use, and non-mutation boundaries"
else
    fail "rerun policy is missing a required authorization boundary"
fi
if grep -Fq 'Step 139' "$DOC" && grep -Fq 'Safe-pause boundary' "$DOC" && grep -Fq 'single-use' "$DOC"; then
    pass "rerun authorization document records the fresh single-use safe-pause boundary"
else
    fail "rerun authorization document is incomplete"
fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then
    fail "rerun-authorization helper contains a package, boot, or shutdown mutation command"
else
    pass "rerun-authorization helper contains no package, boot, or shutdown mutation command"
fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then
    fail "rerun-authorization helper contains a network client command"
else
    pass "rerun-authorization helper contains no network client command"
fi
rm -f "$helper_output"
printf 'Result: %d passes, %d failures\n' "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
