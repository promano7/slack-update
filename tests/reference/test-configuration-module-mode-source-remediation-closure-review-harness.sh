#!/bin/bash
set -u
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/configuration-module-mode-source-remediation-closure-review.sh"
DOC="$repo_root/docs/reference/configuration-module-mode-source-remediation-closure-review.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-closure-review-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-closure-review.tsv"
STEP129_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-regression-review-policy.json"
STEP129_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-regression-review.tsv"
STEP138_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review-policy.json"
STEP138_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.tsv"
STEP159_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-closure-review-policy.json"
STEP159_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-closure-review.tsv"
CONTRACT="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
SOURCE="$repo_root/tools/reference/slack-update-reference.sh"
TEMPLATE="$repo_root/data/config/slack-update.conf"
CHANGELOG="$repo_root/CHANGELOG.md"

check_regular() {
    local file=$1 label=$2
    if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
}
check_hash() {
    local file=$1 expected=$2 label=$3 actual
    if [[ ! -f $file || -L $file ]]; then fail "$label hash cannot be checked"; return; fi
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi
}

for spec in     "$HELPER|step-160 closure helper"     "$DOC|step-160 reference document"     "$POLICY|step-160 closure policy"     "$RECORD|step-160 closure record"     "$STEP129_POLICY|accepted step-129 regression policy"     "$STEP129_RECORD|accepted step-129 regression record"     "$STEP138_POLICY|accepted step-138 regression policy"     "$STEP138_RECORD|accepted step-138 regression record"     "$STEP159_POLICY|accepted step-159 runtime closure policy"     "$STEP159_RECORD|accepted step-159 runtime closure record"     "$CONTRACT|optional-module contract"     "$SOURCE|accepted remediated reference source"     "$TEMPLATE|configuration template"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done

check_hash "$HELPER" '85a2b0c898af9318cd7b9ea6943d72faf0348b8b594b9c1e2735124fd819aa18' 'step-160 closure helper'
check_hash "$DOC" '6a25c1ae41ce067617dc04fc0602dbb1bef1e8076f70727c84eefe27e1b8a3ae' 'step-160 reference document'
check_hash "$POLICY" '019636bde8167d61ad680680da83500ab3db599b830f16c3b4c7acd6cca42fc9' 'step-160 closure policy'
check_hash "$RECORD" '4165eb4c6191eb189666de2a7ebe4d05874de6a6001c5178320e85819335d070' 'step-160 closure record'
check_hash "$STEP129_POLICY" 'f97b4e392a7fdacd7bc6585c7b790231614041a163f733cac171a21bf3259ff2' 'accepted step-129 regression policy'
check_hash "$STEP129_RECORD" '95343b045a16a9fe943b46e1e7887173c9b7f1bb2c18ddcc8e2de867afc94ee8' 'accepted step-129 regression record'
check_hash "$STEP138_POLICY" '43c7b538d06e142180aa343bc743ab11c341e71a4ace6ea0909efac1be90f4ac' 'accepted step-138 regression policy'
check_hash "$STEP138_RECORD" '18de033bdde24bf7c1072314cded46e134cee06aac8434f47f3318e97995d30d' 'accepted step-138 regression record'
check_hash "$STEP159_POLICY" '50e965ffe36d267b3467d3fde08e64dbbedbf17be3f17c41111d226b07575c4b' 'accepted step-159 runtime closure policy'
check_hash "$STEP159_RECORD" '11b5d6e9c0c802a244d481b485c9513f4240f390d82dacc96973d7590507cda0' 'accepted step-159 runtime closure record'
check_hash "$CONTRACT" 'f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9' 'optional-module contract'
check_hash "$SOURCE" 'aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7' 'accepted remediated reference source'
check_hash "$TEMPLATE" '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' 'configuration template'

if bash -n "$HELPER"; then pass 'step-160 closure helper is shell-syntax valid'; else fail 'step-160 closure helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-160 helper exposes a non-mutating help boundary'; else fail 'step-160 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-160 helper accepts unknown options'; else pass 'step-160 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-160 closure policy is valid JSON'; else fail 'step-160 closure policy is invalid JSON'; fi

output=$("$HELPER" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-160 source-remediation closure review completed successfully'; else fail 'step-160 closure helper failed'; printf '%s\n' "$output"; fi
expect_line() {
    local needle=$1 label=$2
    if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi
}
expect_line $'contract_rows\t15' 'all 15 optional-module contract rows remain in scope'
expect_line $'conforming_rows\t15' 'all 15 optional-module contract rows remain conforming'
expect_line $'discrepancy_rows\t0' 'no optional-module conformance discrepancy remains'
expect_line $'original_module_mode_source_remediation_closed\ttrue' 'original module-mode source remediation is closed'
expect_line $'direct_generic_initialization_remediation_closed\ttrue' 'direct-generic initialization remediation is closed'
expect_line $'runtime_validation_closed\ttrue' 'runtime validation remains closed'
expect_line $'source_remediation_closed\ttrue' 'complete source-remediation chain is closed'
expect_line $'source_change_authorized\tfalse' 'no further source change is authorized'
expect_line $'additional_machine_execution_authorized\tfalse' 'no additional machine execution is authorized'
expect_line $'pending_source_remediation_action\tfalse' 'no pending source-remediation action remains'
expect_line $'repository_refresh_required\tfalse' 'closure requires no repository refresh'
expect_line $'machine_action_required\tfalse' 'closure requires no machine action'
expect_line $'future_work_requires_fresh_boundary\ttrue' 'future work requires a fresh boundary'
expect_line $'next_stage\tphase-1-configuration-module-mode-workstream-closure-checkpoint' 'closure advances only to the module-mode workstream checkpoint'
expect_line $'pause_safe\ttrue' 'step-160 checkpoint is pause-safe'

if python3 - "$POLICY" "$STEP129_POLICY" "$STEP138_POLICY" "$STEP159_POLICY" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    p129 = json.load(handle)
with open(sys.argv[3], encoding='utf-8') as handle:
    p138 = json.load(handle)
with open(sys.argv[4], encoding='utf-8') as handle:
    p159 = json.load(handle)
assert p129['contract_rows_reviewed'] == 15
assert p129['conforming_rows'] == 15
assert p129['discrepancy_rows'] == 0
assert p129['all_rows_conform'] is True
assert p129['authorization_consumed'] is True
assert p129['further_source_change_authorized'] is False
assert p138['authorization_consumed'] is True
assert p138['further_source_change_authorized'] is False
assert p138['source_sha256'] == 'aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7'
assert p159['closure']['runtime_validation_closed'] is True
assert p159['closure']['mandatory_targets_accepted'] is True
assert p159['closure']['additional_machine_execution_authorized'] is False
assert p['closure']['source_remediation_closed'] is True
assert p['closure']['pending_source_remediation_action'] is False
assert p['closure']['source_change_authorized'] is False
assert p['closure']['additional_machine_execution_authorized'] is False
assert p['record_sha256'] == '4165eb4c6191eb189666de2a7ebe4d05874de6a6001c5178320e85819335d070'
assert p['future_work_requires_fresh_boundary'] is True
assert p['pause_safe'] is True
PY
then pass 'closure policy proves conformance, consumed source authorizations, and completed runtime validation'; else fail 'step-160 closure semantic assertions failed'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'Step 160 closes the complete source-remediation chain'* && $normalized_doc == *'source_remediation_closed=true'* && $normalized_doc == *'strong safe pause'* ]]; then
    pass 'reference document records the complete source-remediation closure and strong safe pause'
else
    fail 'step-160 reference document is incomplete'
fi
if grep -Fq 'Phase 1 step 160 source-remediation closure review' "$CHANGELOG" \
    && grep -Fq 'source_remediation_closed=true' "$CHANGELOG" \
    && grep -Fq '019636bde8167d61ad680680da83500ab3db599b830f16c3b4c7acd6cca42fc9' "$CHANGELOG" \
    && grep -Fq '4165eb4c6191eb189666de2a7ebe4d05874de6a6001c5178320e85819335d070' "$CHANGELOG"; then
    pass 'CHANGELOG records step 160 with final post-r1 policy and record hashes'
else
    fail 'CHANGELOG step 160 hashes are stale or incomplete'
fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-160 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-160 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-160 helper contains a network client command'; else pass 'step-160 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
