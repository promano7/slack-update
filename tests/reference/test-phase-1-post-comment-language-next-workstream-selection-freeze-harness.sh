#!/bin/bash
set -u
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-post-comment-language-next-workstream-selection-freeze.sh"
DOC="$repo_root/docs/reference/phase-1-post-comment-language-next-workstream-selection-freeze.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-post-comment-language-next-workstream-selection-freeze-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-post-comment-language-next-workstream-selection-freeze.tsv"
STEP170_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-post-comment-language-resume-planning-boundary-review-policy.json"
STEP170_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-post-comment-language-resume-planning-boundary-review.tsv"
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
    "$HELPER|step-171 selection helper" \
    "$DOC|step-171 reference document" \
    "$POLICY|step-171 selection policy" \
    "$RECORD|step-171 selection record" \
    "$STEP170_POLICY|accepted step-170 boundary policy" \
    "$STEP170_RECORD|accepted step-170 boundary record"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done

check_hash "$HELPER" 'b60846d097e6a4c5355ca6d4b5f8e200cb8139cf6597cb8c85d30013912030d7' 'step-171 selection helper'
check_hash "$DOC" '43bd4e2f685eade80a8934dbd4c237e4b0dbfb17db4b8f766ebe1a640e3c751a' 'step-171 reference document'
check_hash "$POLICY" '2992453f2d5e03f34241a3fcc8be3ee48da57630ccceb9aef2f1b560ab76547a' 'step-171 selection policy'
check_hash "$RECORD" '88734d47d6b85c2dc8e05f527ac0613bc01aad9254ffac1fc75ad98508ca5e0d' 'step-171 selection record'
check_hash "$STEP170_POLICY" 'b5fb9bc7dc95a27a7d2c119eceb5142a8d7c851044b78d2484ae165f346cf7b8' 'accepted step-170 boundary policy'
check_hash "$STEP170_RECORD" '0063d67c00a3d441fd32d225b70b4da210c9b9fd301a5928dbf20116668fca05' 'accepted step-170 boundary record'

if bash -n "$HELPER"; then pass 'step-171 selection helper is shell-syntax valid'; else fail 'step-171 selection helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-171 helper exposes a non-mutating help boundary'; else fail 'step-171 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-171 helper accepts unknown options'; else pass 'step-171 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-171 selection policy is valid JSON'; else fail 'step-171 selection policy is invalid JSON'; fi

output=$("$HELPER" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-171 next-workstream selection freeze completed successfully'; else fail 'step-171 selection helper failed'; printf '%s\n' "$output"; fi
expect_line() {
    local needle=$1 label=$2
    if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi
}
expect_line $'accepted_boundary_step\t170' 'selection starts from accepted step 170'
expect_line $'selected_workstream\troadmap-state-reconciliation' 'roadmap reconciliation is selected'
expect_line $'selection_state\tselected' 'selection state is frozen as selected'
expect_line $'classification\tplanning-hygiene' 'selected workstream remains planning hygiene'
expect_line $'scope\trepository-only' 'selected workstream remains repository-only'
expect_line $'phase_1_blocking\tfalse' 'roadmap reconciliation is not misclassified as blocking acceptance work'
expect_line $'machine_execution_required\tfalse' 'selected workstream requires no machine execution'
expect_line $'acceptance_matrix_selected\tfalse' 'acceptance-matrix runtime work is not selected'
expect_line $'acceptance_matrix_requires_later_explicit_boundary\ttrue' 'acceptance-matrix work requires a later explicit boundary'
expect_line $'reference_freeze_status\tblocked-behind-remaining-acceptance-work' 'reference freeze remains blocked'
expect_line $'c_port_status\tblocked-by-phase-1-gate' 'C port remains blocked by the Phase 1 gate'
expect_line $'source_change_authorized\tfalse' 'no source change is authorized'
expect_line $'repository_refresh_authorized\tfalse' 'no repository refresh is authorized'
expect_line $'network_refresh_authorized\tfalse' 'no network refresh is authorized'
expect_line $'machine_execution_authorized\tfalse' 'no machine execution is authorized'
expect_line $'package_action_authorized\tfalse' 'no package action is authorized'
expect_line $'boot_action_authorized\tfalse' 'no boot action is authorized'
expect_line $'phase_2_start_authorized\tfalse' 'Phase 2 is not authorized'
expect_line $'machine_action_required\tfalse' 'step 171 requires no machine action'
expect_line $'slackware_current_publication_invalidates_selection\tfalse' 'later Slackware-current publication does not invalidate this selection'
expect_line $'next_stage\tphase-1-roadmap-state-reconciliation-contract-freeze' 'next stage is the roadmap reconciliation contract freeze'
expect_line $'pause_safe\tfalse' 'step 171 is not the requested end-of-session strong safe pause'

if python3 - "$POLICY" "$STEP170_POLICY" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    p170 = json.load(handle)
assert p170['fresh_boundary']['opened'] is True
assert p170['remaining_phase_1_work']['roadmap_reconciliation'] == 'pending-repository-only-nonblocking'
assert p170['remaining_phase_1_work']['acceptance_matrix_remainder'] == 'pending-future-machine-work'
assert p['review_only'] is True
assert p['accepted_boundary']['step'] == 170
assert p['selection']['selected_workstream'] == 'roadmap-state-reconciliation'
assert p['selection']['classification'] == 'planning-hygiene'
assert p['selection']['scope'] == 'repository-only'
assert p['selection']['phase_1_blocking'] is False
assert p['selection']['machine_execution_required'] is False
assert p['selection']['repository_refresh_required'] is False
assert p['selection']['acceptance_matrix_selected'] is False
assert p['selection']['acceptance_matrix_requires_later_explicit_boundary'] is True
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
assert p['machine_action_required'] is False
assert p['slackware_current_publication_invalidates_selection'] is False
assert p['next_stage'] == 'phase-1-roadmap-state-reconciliation-contract-freeze'
assert p['pause_safe'] is False
PY
then pass 'selection policy chooses only roadmap reconciliation and grants no operational authorization'; else fail 'step-171 selection semantic assertions failed'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'freezes the next repository-only workstream as'\ *'roadmap-state-reconciliation'* && $normalized_doc == *'acceptance-matrix remainder is complete'* && $normalized_doc == *'phase-1-roadmap-state-reconciliation-contract-freeze'* ]]; then
    pass 'reference document records the selection, preserved acceptance remainder, and next stage'
else
    fail 'step-171 reference document is incomplete'
fi
if grep -Fq 'Phase 1 step 171 post-comment-language next-workstream selection freeze' "$CHANGELOG" && grep -Fq 'phase-1-roadmap-state-reconciliation-contract-freeze' "$CHANGELOG"; then pass 'CHANGELOG records step 171'; else fail 'CHANGELOG does not record step 171'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-171 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-171 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-171 helper contains a network client command'; else pass 'step-171 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
