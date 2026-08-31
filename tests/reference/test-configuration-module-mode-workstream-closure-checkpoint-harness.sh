#!/bin/bash
set -u
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/configuration-module-mode-workstream-closure-checkpoint.sh"
DOC="$repo_root/docs/reference/configuration-module-mode-workstream-closure-checkpoint.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-workstream-closure-checkpoint-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-workstream-closure-checkpoint.tsv"
STEP121_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-boundary-review-policy.json"
STEP160_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-closure-review-policy.json"
STEP160_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-closure-review.tsv"
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

for spec in \
    "$HELPER|step-161 closure helper" \
    "$DOC|step-161 reference document" \
    "$POLICY|step-161 closure policy" \
    "$RECORD|step-161 closure record" \
    "$STEP121_POLICY|accepted step-121 boundary policy" \
    "$STEP160_POLICY|accepted step-160 closure policy" \
    "$STEP160_RECORD|accepted step-160 closure record" \
    "$CONTRACT|optional-module contract" \
    "$SOURCE|accepted remediated reference source" \
    "$TEMPLATE|configuration template"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done

check_hash "$HELPER" '6fb6ac22a4f1ef704a2e2a0f9e641766648e9a777c40943206467cd21bf6aa88' 'step-161 closure helper'
check_hash "$DOC" 'fa3b1ff28ba6475cdf2f3f8d56476c2e20b11e036a869e88e088e0a260b0696d' 'step-161 reference document'
check_hash "$POLICY" '0b06a01e33b33da1eba3e6e4566c1b1ea929d801b8c5d1357d93b3e55cbc6fb9' 'step-161 closure policy'
check_hash "$RECORD" '3705921dab84bc1dbb47766743d4623d9b575179b4c449d99a4adf460f5d15e8' 'step-161 closure record'
check_hash "$STEP121_POLICY" 'a03e299a87596ad66246031c3a47839bac5ab2a869073c43eeae6be0788ebc4e' 'accepted step-121 boundary policy'
check_hash "$STEP160_POLICY" '019636bde8167d61ad680680da83500ab3db599b830f16c3b4c7acd6cca42fc9' 'accepted step-160 closure policy'
check_hash "$STEP160_RECORD" '4165eb4c6191eb189666de2a7ebe4d05874de6a6001c5178320e85819335d070' 'accepted step-160 closure record'
check_hash "$CONTRACT" 'f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9' 'optional-module contract'
check_hash "$SOURCE" 'aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7' 'accepted remediated reference source'
check_hash "$TEMPLATE" '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' 'configuration template'

if bash -n "$HELPER"; then pass 'step-161 closure helper is shell-syntax valid'; else fail 'step-161 closure helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-161 helper exposes a non-mutating help boundary'; else fail 'step-161 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-161 helper accepts unknown options'; else pass 'step-161 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-161 closure policy is valid JSON'; else fail 'step-161 closure policy is invalid JSON'; fi

output=$("$HELPER" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-161 module-mode workstream closure completed successfully'; else fail 'step-161 closure helper failed'; printf '%s\n' "$output"; fi
expect_line() {
    local needle=$1 label=$2
    if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi
}
expect_line $'fresh_boundary_origin_step\t121' 'workstream remains rooted in the fresh step-121 boundary'
expect_line $'module_count\t5' 'all five optional modules remain in scope'
expect_line $'mode_count\t3' 'all three module modes remain in scope'
expect_line $'contract_rows\t15' 'all 15 optional-module contract rows remain in scope'
expect_line $'conforming_rows\t15' 'all 15 optional-module contract rows remain conforming'
expect_line $'discrepancy_rows\t0' 'no optional-module conformance discrepancy remains'
expect_line $'mandatory_targets_accepted\ttrue' 'both mandatory Slackware targets remain accepted'
expect_line $'source_remediation_closed\ttrue' 'source-remediation chain remains closed'
expect_line $'runtime_validation_closed\ttrue' 'runtime-validation chain remains closed'
expect_line $'module_mode_workstream_closed\ttrue' 'optional-module mode workstream is closed'
expect_line $'pending_module_mode_action\tfalse' 'no pending module-mode action remains'
expect_line $'source_change_authorized\tfalse' 'no source change is authorized'
expect_line $'additional_machine_execution_authorized\tfalse' 'no additional machine execution is authorized'
expect_line $'repository_refresh_required\tfalse' 'checkpoint requires no repository refresh'
expect_line $'machine_action_required\tfalse' 'checkpoint requires no machine action'
expect_line $'future_work_requires_fresh_boundary\ttrue' 'all future work requires a fresh boundary'
expect_line $'slackware_current_publication_invalidates_checkpoint\tfalse' 'later Slackware-current publication does not invalidate the checkpoint'
expect_line $'next_stage\tphase-1-resume-planning' 'workstream returns Phase 1 to resume planning'
expect_line $'pause_safe\ttrue' 'step-161 checkpoint is pause-safe'

if python3 - "$POLICY" "$STEP121_POLICY" "$STEP160_POLICY" "$CONTRACT" <<'PY'
import csv, json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    p121 = json.load(handle)
with open(sys.argv[3], encoding='utf-8') as handle:
    p160 = json.load(handle)
with open(sys.argv[4], encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))
assert p121['fresh_boundary'] is True
assert p121['accepted_step120_future_work_requires_fresh_boundary'] is True
assert p121['next_stage'] == 'phase-1-configuration-module-mode-contract-freeze'
assert sorted(p121['supported_targets']) == ['slackware-15.0', 'slackware-current']
assert len(p121['reviewed_modules']) == 5
assert p160['closure']['source_remediation_closed'] is True
assert p160['closure']['runtime_validation_closed'] is True
assert p160['closure']['pending_source_remediation_action'] is False
assert p160['closure']['source_change_authorized'] is False
assert p160['closure']['additional_machine_execution_authorized'] is False
assert p160['next_stage'] == 'phase-1-configuration-module-mode-workstream-closure-checkpoint'
assert p160['pause_safe'] is True
assert len(rows) == 15
assert {row['module'] for row in rows} == {'flatpak', 'sbo', 'elf', 'boot', 'cinnamon'}
assert {row['mode'] for row in rows} == {'enabled', 'disabled', 'auto'}
assert p['accepted_repository_state']['contract_rows'] == 15
assert p['accepted_repository_state']['conforming_rows'] == 15
assert p['accepted_repository_state']['discrepancy_rows'] == 0
assert p['closure']['mandatory_targets_accepted'] is True
assert p['closure']['module_mode_workstream_closed'] is True
assert p['closure']['pending_module_mode_action'] is False
assert p['closure']['source_change_authorized'] is False
assert p['closure']['additional_machine_execution_authorized'] is False
assert p['closure']['repository_refresh_required'] is False
assert p['closure']['machine_action_required'] is False
assert p['closure']['slackware_current_publication_invalidates_checkpoint'] is False
assert p['future_work_requires_fresh_boundary'] is True
assert p['next_stage'] == 'phase-1-resume-planning'
assert p['pause_safe'] is True
PY
then pass 'closure policy proves fresh-boundary lineage, accepted contract, and fully closed workstream'; else fail 'step-161 closure semantic assertions failed'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'Step 161 closes the optional-module mode workstream'* && $normalized_doc == *'module_mode_workstream_closed=true'* && $normalized_doc == *'strong safe pause'* && $normalized_doc == *'New Slackware-current publications do not invalidate this checkpoint'* ]]; then
    pass 'reference document records workstream closure and strong safe pause'
else
    fail 'step-161 reference document is incomplete'
fi
if grep -Fq 'Phase 1 step 161 optional-module mode workstream closure checkpoint' "$CHANGELOG" && grep -Fq 'module_mode_workstream_closed=true' "$CHANGELOG" && grep -Fq 'phase-1-resume-planning' "$CHANGELOG"; then pass 'CHANGELOG records step 161'; else fail 'CHANGELOG does not record step 161'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-161 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-161 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-161 helper contains a network client command'; else pass 'step-161 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
