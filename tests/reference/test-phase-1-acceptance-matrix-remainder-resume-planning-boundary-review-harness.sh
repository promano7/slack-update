#!/bin/bash
set -u
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review.sh"
DOC="$repo_root/docs/reference/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review.tsv"
STEP176_HELPER="$repo_root/tools/reference/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause.sh"
STEP176_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause-policy.json"
STEP176_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause.tsv"
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
    "$HELPER|step-177 boundary helper" \
    "$DOC|step-177 reference document" \
    "$POLICY|step-177 boundary policy" \
    "$RECORD|step-177 boundary record" \
    "$STEP176_HELPER|accepted step-176 review helper" \
    "$STEP176_POLICY|accepted step-176 checkpoint policy" \
    "$STEP176_RECORD|accepted step-176 checkpoint record"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done

check_hash "$HELPER" '891a212bb94dc766bdcb6f71791beff2e1cf089483d1e9c986beb0d1132bed3a' 'step-177 boundary helper'
check_hash "$DOC" 'cbcb5e764dc69a4d885875a70efdf4cabda2d8f00c2b4a9d4f5f976425216153' 'step-177 reference document'
check_hash "$POLICY" '3a90d6bde471d3a55eca0cec86fb34f4c4678e4a0d046f2fa40450868bc18bef' 'step-177 boundary policy'
check_hash "$RECORD" 'e9615d879ae1adcb4e062e4f2911e810d47198a37c90c031b8aee7ab81c2f0a8' 'step-177 boundary record'
check_hash "$STEP176_HELPER" 'ce9d2058788e7743d62d63114a6531b9238cbc142cb3d6994fd4c4ae6264bc7b' 'accepted step-176 review helper'
check_hash "$STEP176_POLICY" '86eaf01a35bfee7bae0450d669b06a3d1aa3f6f7e8d47776a09f036d62ff6ea6' 'accepted step-176 checkpoint policy'
check_hash "$STEP176_RECORD" 'eff7de99e6a31e47cd09fff61aa26d600f34f09cffedce5cabafb0736be6c389' 'accepted step-176 checkpoint record'

if bash -n "$HELPER"; then pass 'step-177 boundary helper is shell-syntax valid'; else fail 'step-177 boundary helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-177 helper exposes a non-mutating help boundary'; else fail 'step-177 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-177 helper accepts unknown options'; else pass 'step-177 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-177 boundary policy is valid JSON'; else fail 'step-177 boundary policy is invalid JSON'; fi

tmpdir=$(mktemp -d)
trap 'rm -rf -- "$tmpdir"' EXIT
output=$("$HELPER" --output-dir "$tmpdir" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-177 resume-planning boundary review completed successfully'; else fail 'step-177 boundary helper failed'; printf '%s\n' "$output"; fi

if cmp -s "$POLICY" "$tmpdir/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review-policy.json"; then
    pass 'step-177 helper reproduces the frozen boundary policy exactly'
else
    fail 'step-177 helper does not reproduce the frozen boundary policy'
fi
if cmp -s "$RECORD" "$tmpdir/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review.tsv"; then
    pass 'step-177 helper reproduces the frozen boundary record exactly'
else
    fail 'step-177 helper does not reproduce the frozen boundary record'
fi

expect_line() {
    local needle=$1 label=$2
    if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi
}
expect_line $'accepted_checkpoint_step\t176' 'boundary starts from accepted step 176'
expect_line $'accepted_checkpoint_strong_safe_pause\tyes' 'step-176 strong safe pause is the accepted starting point'
expect_line $'inventory_family_count\t6' 'accepted inventory still contains six families'
expect_line $'inventory_scenario_count\t24' 'accepted inventory still contains 24 scenarios'
expect_line $'inventory_consistent\tyes' 'accepted inventory remains internally consistent'
expect_line $'accepted_core_scenarios_must_not_be_replayed\tyes' 'accepted core scenarios remain excluded from replay'
expect_line $'fresh_boundary\tyes' 'step 177 opens a fresh boundary'
expect_line $'boundary_scope\tphase-1-acceptance-matrix-remainder-resume-planning' 'fresh boundary has the required resume-planning scope'
expect_line $'candidate_set_bound\tno' 'no live candidate set is bound'
expect_line $'family_selected_for_execution\tno' 'no runtime family is selected yet'
expect_line $'live_runtime_chain_open\tno' 'no live runtime chain is opened'
expect_line $'acceptance_matrix_complete\tno' 'acceptance matrix remains incomplete'
expect_line $'source_change_authorized\tno' 'no source change is authorized'
expect_line $'documentation_change_authorized\tno' 'no documentation change outside the overlay is authorized'
expect_line $'repository_refresh_authorized\tno' 'no repository refresh is authorized'
expect_line $'network_refresh_authorized\tno' 'no network refresh is authorized'
expect_line $'machine_execution_authorized\tno' 'no machine execution is authorized'
expect_line $'package_action_authorized\tno' 'no package action is authorized'
expect_line $'boot_action_authorized\tno' 'no boot action is authorized'
expect_line $'phase_2_start_authorized\tno' 'Phase 2 is not authorized'
expect_line $'machine_action_required\tno' 'step 177 requires no machine action'
expect_line $'slackware_current_publication_invalidates_boundary\tno' 'later Slackware-current publication does not invalidate the planning boundary'
expect_line $'pause_safe\tno' 'step 177 intentionally opens the next planning chain rather than closing it'
expect_line $'next_stage\tphase-1-acceptance-matrix-remainder-family-selection-freeze' 'next stage is the remainder-family selection freeze'

if python3 - "$POLICY" "$STEP176_POLICY" <<'PY'
import json
import sys

with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    p176 = json.load(handle)

assert p176['safe_pause']['strong_safe_pause'] is True
assert p176['safe_pause']['no_open_operational_authorization'] is True
assert p176['continuation']['selection_must_occur_after_fresh_boundary'] is True
assert p176['next_stage'] == 'phase-1-acceptance-matrix-remainder-resume-planning'
assert p['review_only'] is True
assert p['accepted_checkpoint']['step'] == 176
assert p['accepted_checkpoint']['strong_safe_pause'] is True
assert p['accepted_checkpoint']['inventory_family_count'] == 6
assert p['accepted_checkpoint']['inventory_scenario_count'] == 24
assert p['fresh_boundary']['opened'] is True
assert p['fresh_boundary']['scope'] == 'phase-1-acceptance-matrix-remainder-resume-planning'
assert p['fresh_boundary']['candidate_set_bound'] is False
assert p['fresh_boundary']['family_selected_for_execution'] is False
assert p['fresh_boundary']['live_runtime_chain_open'] is False
assert p['fresh_boundary']['slackware_current_publication_invalidates_boundary'] is False
assert p['inventory']['family_count'] == 6
assert p['inventory']['scenario_count'] == 24
assert p['inventory']['accepted_core_scenarios_must_not_be_replayed'] is True
assert p['gates']['acceptance_matrix_complete'] is False
assert p['gates']['reference_freeze_status'] == 'blocked-behind-remaining-acceptance-work'
assert p['gates']['c_port_status'] == 'blocked-by-phase-1-gate'
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
assert p['authorization']['future_work_requires_explicit_authorization'] is True
assert p['machine_action_required'] is False
assert p['pause_safe'] is False
assert p['next_stage'] == 'phase-1-acceptance-matrix-remainder-family-selection-freeze'
PY
then
    pass 'boundary policy preserves step 176 and grants no operational authorization'
else
    fail 'step-177 boundary semantic assertions failed'
fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'Step 177 resumes Phase 1 from the accepted step-176 strong-safe-pause checkpoint'* && \
      $normalized_doc == *'No family is selected for execution'* && \
      $normalized_doc == *'phase-1-acceptance-matrix-remainder-family-selection-freeze'* ]]; then
    pass 'reference document records the fresh boundary and next stage'
else
    fail 'step-177 reference document is incomplete'
fi

if grep -Fq 'Phase 1 step 177 acceptance-matrix remainder resume-planning boundary review' "$CHANGELOG" && \
   grep -Fq 'phase-1-acceptance-matrix-remainder-family-selection-freeze' "$CHANGELOG"; then
    pass 'CHANGELOG records step 177'
else
    fail 'CHANGELOG does not record step 177'
fi

if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then
    fail 'step-177 helper contains a package, boot, reboot, or shutdown mutation command'
else
    pass 'step-177 helper contains no package, boot, reboot, or shutdown mutation command'
fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then
    fail 'step-177 helper contains a network client command'
else
    pass 'step-177 helper contains no network client command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
