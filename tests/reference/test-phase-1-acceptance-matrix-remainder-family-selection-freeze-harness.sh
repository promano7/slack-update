#!/bin/bash
set -u
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-acceptance-matrix-remainder-family-selection-freeze.sh"
DOC="$repo_root/docs/reference/phase-1-acceptance-matrix-remainder-family-selection-freeze.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-family-selection-freeze-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-family-selection-freeze.tsv"
STEP177_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review-policy.json"
STEP177_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review.tsv"
STEP175_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-inventory-policy.json"
STEP175_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-inventory.tsv"
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
    "$HELPER|step-178 selection helper" \
    "$DOC|step-178 reference document" \
    "$POLICY|step-178 selection policy" \
    "$RECORD|step-178 selection record" \
    "$STEP177_POLICY|accepted step-177 boundary policy" \
    "$STEP177_RECORD|accepted step-177 boundary record" \
    "$STEP175_POLICY|accepted step-175 inventory policy" \
    "$STEP175_RECORD|accepted step-175 inventory record"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done

check_hash "$HELPER" 'f116401777129c9dc83fc3a574572863c9028f6c6d3bd0837b9283e46b5e83ac' 'step-178 selection helper'
check_hash "$DOC" '3d518120c40e2d2132b341f5ac05684384e7cb631d7098c6e46a56700b838819' 'step-178 reference document'
check_hash "$POLICY" '9f06efed40e4bcf0f32939a9e4c0b6ec77b930696cd6cad0ad12ed1b75c168a0' 'step-178 selection policy'
check_hash "$RECORD" '8b783f4b7fc442a3fb5da2731e88b4c6882650cac1dbbc822073519b8f34a32c' 'step-178 selection record'
check_hash "$STEP177_POLICY" '3a90d6bde471d3a55eca0cec86fb34f4c4678e4a0d046f2fa40450868bc18bef' 'accepted step-177 boundary policy'
check_hash "$STEP177_RECORD" 'e9615d879ae1adcb4e062e4f2911e810d47198a37c90c031b8aee7ab81c2f0a8' 'accepted step-177 boundary record'
check_hash "$STEP175_POLICY" '819a5696fb9854f64a012ba6091750b40c1d658e5edd61a93c0c1e03264b16fe' 'accepted step-175 inventory policy'
check_hash "$STEP175_RECORD" 'ad4697b230ab2b22a6d3cdf2e4cc2c74a61e469b9d70da11e7f25082265dd5ff' 'accepted step-175 inventory record'

if bash -n "$HELPER"; then pass 'step-178 selection helper is shell-syntax valid'; else fail 'step-178 selection helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-178 helper exposes a non-mutating help boundary'; else fail 'step-178 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-178 helper accepts unknown options'; else pass 'step-178 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-178 selection policy is valid JSON'; else fail 'step-178 selection policy is invalid JSON'; fi

output=$("$HELPER" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-178 family selection freeze completed successfully'; else fail 'step-178 selection helper failed'; printf '%s\n' "$output"; fi
expect_line() {
    local needle=$1 label=$2
    if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi
}
expect_line $'accepted_boundary_step\t177' 'selection starts from accepted step 177'
expect_line $'accepted_inventory_step\t175' 'selection uses the accepted step-175 inventory'
expect_line $'inventory_family_count\t6' 'accepted inventory still contains six families'
expect_line $'inventory_scenario_count\t24' 'accepted inventory still contains 24 scenarios'
expect_line $'selected_family\texecution-control-failure-paths' 'execution-control failure paths are selected'
expect_line $'selected_family_scenario_count\t4' 'selected family contains four scenarios'
expect_line $'selection_state\tselected' 'selection state is selected'
expect_line $'selection_frozen\tyes' 'family selection is frozen'
expect_line $'runtime_boundary_required\tyes' 'selected family still requires a runtime boundary'
expect_line $'repository_refresh_requirement\tconditional' 'repository refresh remains conditional rather than authorized'
expect_line $'candidate_set_bound\tno' 'no live candidate set is bound'
expect_line $'live_runtime_chain_open\tno' 'no live runtime chain is open'
expect_line $'acceptance_matrix_complete\tno' 'acceptance matrix remains incomplete'
expect_line $'source_change_authorized\tno' 'no source change is authorized'
expect_line $'documentation_change_authorized\tno' 'no documentation change is authorized'
expect_line $'repository_refresh_authorized\tno' 'no repository refresh is authorized'
expect_line $'network_refresh_authorized\tno' 'no network refresh is authorized'
expect_line $'machine_execution_authorized\tno' 'no machine execution is authorized'
expect_line $'package_action_authorized\tno' 'no package action is authorized'
expect_line $'boot_action_authorized\tno' 'no boot action is authorized'
expect_line $'phase_2_start_authorized\tno' 'Phase 2 is not authorized'
expect_line $'machine_action_required\tno' 'step 178 requires no machine action'
expect_line $'slackware_current_publication_invalidates_selection\tno' 'later Slackware-current publication does not invalidate the selection'
expect_line $'next_stage\tphase-1-execution-control-failure-paths-contract-freeze' 'next stage is the execution-control failure-path contract freeze'
expect_line $'pause_safe\tno' 'step 178 is an active planning chain, not the final safe pause'

if python3 - "$POLICY" "$STEP177_POLICY" "$STEP175_POLICY" "$STEP175_RECORD" <<'PY'
import csv, json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    p177 = json.load(handle)
with open(sys.argv[3], encoding='utf-8') as handle:
    p175 = json.load(handle)
with open(sys.argv[4], encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))
assert p177['fresh_boundary']['opened'] is True
assert p177['fresh_boundary']['family_selected_for_execution'] is False
assert p175['inventory']['family_count'] == 6
family = next(row for row in rows if row['family'] == 'execution-control-failure-paths')
assert family['scenario_count'] == '4'
assert p['review_only'] is True
assert p['accepted_boundary']['step'] == 177
assert p['accepted_inventory']['step'] == 175
assert p['selection']['selected_family'] == 'execution-control-failure-paths'
assert p['selection']['scenario_count'] == 4
assert len(p['selection']['scenarios']) == 4
assert p['selection']['runtime_boundary_required'] is True
assert p['selection']['repository_refresh_requirement'] == 'conditional'
assert p['selection']['selection_frozen'] is True
assert p['selection']['candidate_set_bound'] is False
assert p['selection']['live_runtime_chain_open'] is False
assert p['selection']['slackware_current_publication_invalidates_selection'] is False
for key in (
    'source_change_authorized',
    'documentation_change_authorized',
    'repository_refresh_authorized',
    'network_refresh_authorized',
    'machine_execution_authorized',
    'package_action_authorized',
    'boot_action_authorized',
    'phase_2_start_authorized',
):
    assert p['authorization'][key] is False
assert p['machine_action_required'] is False
assert p['next_stage'] == 'phase-1-execution-control-failure-paths-contract-freeze'
assert p['pause_safe'] is False
PY
then pass 'selection policy freezes only the accepted execution-control failure-path family and grants no operational authorization'; else fail 'step-178 selection semantic assertions failed'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'execution-control-failure-paths'* && $normalized_doc == *'four accepted pending scenarios'* && $normalized_doc == *'phase-1-execution-control-failure-paths-contract-freeze'* ]]; then
    pass 'reference document records the selected family, four scenarios, and next stage'
else
    fail 'step-178 reference document is incomplete'
fi
if grep -Fq 'Phase 1 step 178 acceptance-matrix remainder family selection freeze' "$CHANGELOG" && grep -Fq 'phase-1-execution-control-failure-paths-contract-freeze' "$CHANGELOG"; then pass 'CHANGELOG records step 178'; else fail 'CHANGELOG does not record step 178'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-178 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-178 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-178 helper contains a network client command'; else pass 'step-178 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
