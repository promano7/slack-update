#!/bin/bash
set -u
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-closure-review.sh"
DOC="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-closure-review.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-closure-review-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-closure-review.tsv"
STEP158_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-review-policy.json"
STEP158_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-review.tsv"
CURRENT_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review-policy.json"
CURRENT_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review.tsv"
SOURCE="$repo_root/tools/reference/slack-update-reference.sh"
TEMPLATE="$repo_root/data/config/slack-update.conf"
CHANGELOG="$repo_root/CHANGELOG.md"
check_file() {
    local path=$1 label=$2
    if [[ -f $path && ! -L $path ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
}
check_hash() {
    local path=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}')
    if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi
}
check_file "$HELPER" 'step-159 closure helper'
check_file "$DOC" 'step-159 reference document'
check_file "$POLICY" 'step-159 closure policy'
check_file "$RECORD" 'step-159 closure record'
check_file "$STEP158_POLICY" 'accepted Slackware 15.0 review policy'
check_file "$STEP158_RECORD" 'accepted Slackware 15.0 review record'
check_file "$CURRENT_POLICY" 'accepted Slackware-current review policy'
check_file "$CURRENT_RECORD" 'accepted Slackware-current review record'
check_file "$SOURCE" 'accepted remediated reference source'
check_file "$TEMPLATE" 'configuration template'
check_hash "$HELPER" 'b674b1e03cbb84daaff947c3629f309b1aaa633bb9afb63b9a12b83bbce6cae3' 'step-159 closure helper'
check_hash "$DOC" '10f26b49959ee4532c74d0d96053acf601eb45c8a463cf7009dfa62f263004e5' 'step-159 reference document'
check_hash "$POLICY" '50e965ffe36d267b3467d3fde08e64dbbedbf17be3f17c41111d226b07575c4b' 'step-159 closure policy'
check_hash "$RECORD" '11b5d6e9c0c802a244d481b485c9513f4240f390d82dacc96973d7590507cda0' 'step-159 closure record'
check_hash "$STEP158_POLICY" '2ead4c6e4b144b7bc6c3f927eaeea8c46160cc8ebdf1054684046767444bd46a' 'accepted Slackware 15.0 review policy'
check_hash "$STEP158_RECORD" 'dbeded2f525a52dd4155c41963d8e154b6a4e90917c994c4b4a993d81a1e0ba4' 'accepted Slackware 15.0 review record'
check_hash "$CURRENT_POLICY" 'de2813f328b1af80531d68a22c049f9c3be58b6a445398c5c3795b49036ead4b' 'accepted Slackware-current review policy'
check_hash "$CURRENT_RECORD" '9f8c384d4709e8161ac2f6a3e928b7f3e7baea677e7d850c4c061c1aa4d71361' 'accepted Slackware-current review record'
check_hash "$SOURCE" 'aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7' 'accepted remediated reference source'
check_hash "$TEMPLATE" '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' 'configuration template'
if bash -n "$HELPER"; then pass 'step-159 closure helper is shell-syntax valid'; else fail 'step-159 closure helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-159 helper exposes a non-mutating help boundary'; else fail 'step-159 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-159 helper accepts unknown options'; else pass 'step-159 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-159 closure policy is valid JSON'; else fail 'step-159 closure policy is invalid JSON'; fi
output=$("$HELPER" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-159 runtime-validation closure review completed successfully'; else fail 'step-159 closure helper failed'; printf '%s\n' "$output"; fi
expect_line() {
    local needle=$1 label=$2
    if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi
}
expect_line $'slackware_15_runtime_validation_accepted\ttrue' 'Slackware 15.0 runtime validation remains accepted'
expect_line $'slackware_current_runtime_validation_accepted\ttrue' 'Slackware-current runtime validation remains accepted'
expect_line $'mandatory_targets_accepted\ttrue' 'both mandatory targets remain accepted'
expect_line $'characterization_remediation_accepted\ttrue' 'characterization remediation remains accepted'
expect_line $'runtime_validation_closed\ttrue' 'runtime-validation subchain is closed'
expect_line $'additional_machine_execution_authorized\tfalse' 'no additional machine execution is authorized'
expect_line $'repository_refresh_required\tfalse' 'closure requires no repository refresh'
expect_line $'machine_action_required\tfalse' 'closure requires no machine action'
expect_line $'future_work_requires_fresh_boundary\ttrue' 'future work requires a fresh boundary'
expect_line $'next_stage\tphase-1-configuration-module-mode-source-remediation-closure-review' 'closure advances only to complete source-remediation closure review'
expect_line $'pause_safe\ttrue' 'step-159 checkpoint is pause-safe'
if python3 - "$POLICY" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
assert p['step158_slackware_15_review']['runtime_validation_accepted'] is True
assert p['step148_slackware_current_review']['runtime_validation_accepted'] is True
assert p['closure']['mandatory_targets_accepted'] is True
assert p['closure']['runtime_validation_closed'] is True
assert p['closure']['additional_machine_execution_authorized'] is False
assert p['closure']['machine_action_required'] is False
assert p['future_work_requires_fresh_boundary'] is True
assert p['pause_safe'] is True
PY
then pass 'closure policy freezes both accepted targets, repository identity, and zero-machine boundary'; else fail 'step-159 closure policy semantic assertions failed'; fi
if grep -Fq 'Step 159' "$DOC" && grep -Fq 'runtime_validation_closed=true' "$DOC" && grep -Fq 'strong safe pause' "$DOC"; then pass 'reference document records the runtime-validation closure and strong safe pause'; else fail 'step-159 reference document is incomplete'; fi
if grep -Fq 'Phase 1 step 159' "$CHANGELOG" && grep -Fq 'runtime-validation closure review' "$CHANGELOG"; then pass 'CHANGELOG records step 159'; else fail 'CHANGELOG does not record step 159'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-159 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-159 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-159 helper contains a network client command'; else pass 'step-159 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
