#!/bin/bash
set -u
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-next-workstream-selection-freeze.sh"
DOC="$repo_root/docs/reference/phase-1-next-workstream-selection-freeze.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-next-workstream-selection-freeze-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-next-workstream-selection-freeze.tsv"
STEP163_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-remaining-work-inventory-policy.json"
STEP163_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-remaining-work-inventory.tsv"
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
    "$HELPER|step-164 selection helper" \
    "$DOC|step-164 reference document" \
    "$POLICY|step-164 selection policy" \
    "$RECORD|step-164 selection record" \
    "$STEP163_POLICY|accepted step-163 inventory policy" \
    "$STEP163_RECORD|accepted step-163 inventory record"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done

check_hash "$HELPER" '6699f69a84d8fb75db0e0b0a40e188b813576c2d4eda896c00ababd5200b0bb4' 'step-164 selection helper'
check_hash "$DOC" 'b6d885a5efbfb6d6ab04a53bd7945babbdf0fa90a51850a8bdd7f8d85c51e490' 'step-164 reference document'
check_hash "$POLICY" 'd2dfa3d4e1fe716d841a416a15f2c162573bca029b7f5742c543d5d071373c11' 'step-164 selection policy'
check_hash "$RECORD" '9a00e18b56d4ce0a98b3c90db94fb1528e73e0501a6bc493769841cbacbcb79d' 'step-164 selection record'
check_hash "$STEP163_POLICY" 'fb9ab7db1adad032b29be14a6100fdc6221eefd8de3360374085e8b3d76e4f03' 'accepted step-163 inventory policy'
check_hash "$STEP163_RECORD" '8a1160121683117fc247cbf35d2943d35b6b219323e8e58a2fb9baed165f8b01' 'accepted step-163 inventory record'

if bash -n "$HELPER"; then pass 'step-164 selection helper is shell-syntax valid'; else fail 'step-164 selection helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-164 helper exposes a non-mutating help boundary'; else fail 'step-164 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-164 helper accepts unknown options'; else pass 'step-164 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-164 selection policy is valid JSON'; else fail 'step-164 selection policy is invalid JSON'; fi

output=$("$HELPER" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-164 next-workstream selection freeze completed successfully'; else fail 'step-164 selection helper failed'; printf '%s\n' "$output"; fi

header=$(head -n 1 "$RECORD")
if [[ $header == $'workstream\tselection_state\tscope\tphase_1_blocking\tmachine_execution_required\trepository_refresh_required\tdisposition' ]]; then pass 'selection record has the frozen seven-column schema'; else fail 'selection record schema mismatch'; fi
rows=$(($(wc -l < "$RECORD") - 1))
if [[ $rows -eq 3 ]]; then pass 'selection record contains exactly three pending-work dispositions'; else fail 'selection record row count is not three'; fi

expect_record() {
    local pattern=$1 label=$2
    if grep -Eq "$pattern" "$RECORD"; then pass "$label"; else fail "$label"; fi
}
expect_record '^reference-comment-language-audit[[:space:]]+selected[[:space:]]+repository-only[[:space:]]+true[[:space:]]+false[[:space:]]+false[[:space:]]' 'English-comment audit is the selected blocking repository-only workstream'
expect_record '^roadmap-state-reconciliation[[:space:]]+pending-not-selected[[:space:]]+repository-only[[:space:]]+false[[:space:]]+false[[:space:]]+false[[:space:]]' 'roadmap reconciliation remains pending non-blocking planning hygiene'
expect_record '^acceptance-matrix-remainder[[:space:]]+pending-not-selected[[:space:]]+mixed-design-and-runtime[[:space:]]+true[[:space:]]+true[[:space:]]+conditional[[:space:]]' 'acceptance-matrix remainder remains pending and unselected'

if python3 - "$POLICY" "$STEP163_POLICY" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    p163 = json.load(handle)
assert p163['next_stage'] == 'phase-1-next-workstream-selection-freeze'
assert p163['inventory']['pending_repository_only_count'] == 2
assert p163['inventory']['pending_acceptance_work_count'] == 1
assert p['review_only'] is True
assert p['accepted_inventory']['step'] == 163
assert p['selection']['selected_workstream'] == 'reference-comment-language-audit'
assert p['selection']['classification'] == 'repository-review'
assert p['selection']['scope'] == 'repository-only'
assert p['selection']['phase_1_blocking'] is True
assert p['selection']['machine_execution_required'] is False
assert p['selection']['repository_refresh_required'] is False
assert p['selection']['roadmap_reconciliation_selected'] is False
assert p['selection']['acceptance_matrix_selected'] is False
assert p['selection']['selection_frozen'] is True
for key in (
    'source_change_authorized',
    'repository_refresh_authorized',
    'network_refresh_authorized',
    'machine_execution_authorized',
    'package_action_authorized',
    'boot_action_authorized',
    'phase_2_start_authorized',
):
    assert p['authorization'][key] is False
assert p['authorization']['future_work_requires_explicit_authorization'] is True
assert p['next_stage'] == 'phase-1-reference-comment-language-audit-contract-freeze'
assert p['slackware_current_publication_invalidates_selection'] is False
assert p['pause_safe'] is False
PY
then pass 'selection policy freezes the blocking repository-only workstream without operational authorization'; else fail 'step-164 selection semantic assertions failed'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'reference-comment-language-audit'* && $normalized_doc == *'does not claim that the reference script contains a language defect'* && $normalized_doc == *'phase-1-reference-comment-language-audit-contract-freeze'* ]]; then
    pass 'reference document explains selection scope and preserves the audit-before-conclusion boundary'
else
    fail 'step-164 reference document is incomplete'
fi
if grep -Fq 'Phase 1 step 164 next-workstream selection freeze' "$CHANGELOG" && grep -Fq 'phase-1-reference-comment-language-audit-contract-freeze' "$CHANGELOG"; then pass 'CHANGELOG records step 164'; else fail 'CHANGELOG does not record step 164'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-164 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-164 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-164 helper contains a network client command'; else pass 'step-164 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
