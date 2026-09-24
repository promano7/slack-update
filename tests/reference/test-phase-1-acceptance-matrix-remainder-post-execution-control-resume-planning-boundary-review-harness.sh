#!/bin/bash
set -u
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review.sh"
DOC="$repo_root/docs/reference/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review.tsv"
STEP188_HELPER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.sh"
STEP188_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause-policy.json"
STEP188_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.tsv"
REMAINING="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv"
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
    "$HELPER|step-189 boundary helper" \
    "$DOC|step-189 reference document" \
    "$POLICY|step-189 boundary policy" \
    "$RECORD|step-189 boundary record" \
    "$STEP188_HELPER|accepted step-188 review helper" \
    "$STEP188_POLICY|accepted step-188 strong-safe-pause policy" \
    "$STEP188_RECORD|accepted step-188 closure record" \
    "$REMAINING|accepted residual inventory"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done

check_hash "$HELPER" '97d111172833e386d7761cc1fdcedf0868ffc062b6230b56e73091a5d363393a' 'step-189 boundary helper'
check_hash "$DOC" 'cc0cbb5309f369faa83e90c119c8a1096e22d5625f413851d4fc4683bfac4508' 'step-189 reference document'
check_hash "$POLICY" 'e14c2a8ac8d11fe5d8416bf52e724e5883c523228193e4f0c1235a5510540c9f' 'step-189 boundary policy'
check_hash "$RECORD" '8a9a5e70ea1eec093f0ed5528d99f9436b3eafcaa835002227c25b817164bacc' 'step-189 boundary record'
check_hash "$STEP188_HELPER" '296617f1e499a74151b68c96d08fb90273a0acbd30b566dcced6cc1a9f504fae' 'accepted step-188 review helper'
check_hash "$STEP188_POLICY" 'b7a78b9dfbb6eeb3c802820a2566deae96f43c5dace3a22a8e88ab513f623d63' 'accepted step-188 strong-safe-pause policy'
check_hash "$STEP188_RECORD" '427e07e26cfc9449c0df3e0bd20cc97dfcc681825e1a073d0d83ea9fd49969fb' 'accepted step-188 closure record'
check_hash "$REMAINING" '8aa3f1dbe177ec336025f4b3983e22b07205d8bf72fb214442704764131094e9' 'accepted residual inventory'

if bash -n "$HELPER"; then pass 'step-189 boundary helper is shell-syntax valid'; else fail 'step-189 boundary helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-189 helper exposes a non-mutating help boundary'; else fail 'step-189 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-189 helper accepts unknown options'; else pass 'step-189 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-189 boundary policy is valid JSON'; else fail 'step-189 boundary policy is invalid JSON'; fi

output=$("$HELPER" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-189 boundary review completed successfully'; else fail 'step-189 boundary helper failed'; printf '%s\n' "$output"; fi
expect_line() {
    local needle=$1 label=$2
    if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi
}
expect_line $'accepted_checkpoint_step\t188' 'boundary starts from accepted step 188'
expect_line $'accepted_checkpoint_strong_safe_pause\tyes' 'accepted checkpoint is a strong safe pause'
expect_line $'closed_family\texecution-control-failure-paths' 'execution-control remains the closed family'
expect_line $'closed_family_replay_required_by_default\tno' 'closed execution-control scenarios are not replayed by default'
expect_line $'inventory_family_count\t5' 'residual inventory contains five families'
expect_line $'inventory_scenario_count\t20' 'residual inventory contains 20 scenarios'
expect_line $'inventory_consistent\tyes' 'residual inventory is internally consistent'
expect_line $'fresh_boundary\tyes' 'a fresh planning boundary is open'
expect_line $'candidate_set_bound\tno' 'no live candidate set is bound'
expect_line $'family_selected_for_execution\tno' 'no residual family is selected yet'
expect_line $'live_runtime_chain_open\tno' 'no live runtime chain is open'
expect_line $'acceptance_matrix_complete\tno' 'acceptance matrix remains incomplete'
expect_line $'repository_refresh_authorized\tno' 'repository refresh is not authorized'
expect_line $'network_refresh_authorized\tno' 'network refresh is not authorized'
expect_line $'machine_execution_authorized\tno' 'machine execution is not authorized'
expect_line $'package_action_authorized\tno' 'package action is not authorized'
expect_line $'boot_action_authorized\tno' 'boot action is not authorized'
expect_line $'reboot_authorized\tno' 'reboot is not authorized'
expect_line $'runtime_scenario_execution_authorized\tno' 'runtime scenario execution is not authorized'
expect_line $'phase_2_start_authorized\tno' 'Phase 2 is not authorized'
expect_line $'machine_action_required\tno' 'step 189 requires no machine action'
expect_line $'future_work_requires_explicit_authorization\tyes' 'future operational work still requires explicit authorization'
expect_line $'slackware_current_publication_invalidates_boundary\tno' 'later Slackware-current publication does not invalidate this planning boundary'
expect_line $'next_stage\tphase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze' 'next stage is residual family selection freeze'
expect_line $'pause_safe\tno' 'step 189 is an active planning chain rather than the next strong safe pause'

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$HELPER" --output-dir "$tmp" >/dev/null; then pass 'step-189 evidence reproduces successfully in an isolated output directory'; else fail 'step-189 isolated reproduction failed'; fi
if cmp -s -- "$tmp/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review-policy.json" "$POLICY"; then pass 'step-189 policy is deterministically reproducible'; else fail 'step-189 policy is not deterministically reproducible'; fi
if cmp -s -- "$tmp/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review.tsv" "$RECORD"; then pass 'step-189 record is deterministically reproducible'; else fail 'step-189 record is not deterministically reproducible'; fi

if python3 - "$POLICY" "$STEP188_POLICY" "$REMAINING" <<'PY'
import csv
import json
import sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    p188 = json.load(handle)
with open(sys.argv[3], encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))
assert p188['safe_pause']['strong_safe_pause'] is True
assert p188['closed_family']['family'] == 'execution-control-failure-paths'
assert p['review_only'] is True
assert p['accepted_checkpoint']['step'] == 188
assert p['accepted_checkpoint']['strong_safe_pause'] is True
assert p['accepted_checkpoint']['closed_family'] == 'execution-control-failure-paths'
assert p['accepted_checkpoint']['closed_family_replay_required_by_default'] is False
assert p['fresh_boundary']['opened'] is True
assert p['fresh_boundary']['scope'] == 'phase-1-acceptance-matrix-remainder-resume-planning'
assert p['fresh_boundary']['candidate_set_bound'] is False
assert p['fresh_boundary']['family_selected_for_execution'] is False
assert p['fresh_boundary']['live_runtime_chain_open'] is False
assert p['inventory']['family_count'] == 5
assert p['inventory']['scenario_count'] == 20
assert p['inventory']['closed_execution_control_family_excluded'] is True
assert p['inventory']['accepted_closed_families_must_not_be_replayed'] is True
assert len(rows) == 5
assert sum(int(row['scenario_count']) for row in rows) == 20
assert {row['family'] for row in rows} == {
    'kernel-package-edge',
    'boot-safety-failure-paths',
    'sbo-elf-optional-runtime',
    'cinnamon-optional-runtime',
    'flatpak-optional-runtime',
}
for key in (
    'source_change_authorized',
    'documentation_change_authorized',
    'repository_refresh_authorized',
    'network_refresh_authorized',
    'machine_execution_authorized',
    'package_action_authorized',
    'boot_action_authorized',
    'reboot_authorized',
    'runtime_scenario_execution_authorized',
    'phase_2_start_authorized',
):
    assert p['authorization'][key] is False
assert p['machine_action_required'] is False
assert p['next_stage'] == 'phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze'
assert p['pause_safe'] is False
PY
then pass 'step-189 policy preserves the exact residual inventory and grants no operational authorization'; else fail 'step-189 semantic assertions failed'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'five families / 20 scenarios'* && $normalized_doc == *'execution-control-failure-paths'* && $normalized_doc == *'No residual family is selected'* && $normalized_doc == *'phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze'* ]]; then
    pass 'reference document records residual inventory, closed-family exclusion, no selection, and next stage'
else
    fail 'step-189 reference document is incomplete'
fi
if grep -Fq '## Phase 1 step 189 post-execution-control remainder resume-planning boundary review' "$CHANGELOG" && grep -Fq 'phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze' "$CHANGELOG"; then pass 'CHANGELOG records step 189'; else fail 'CHANGELOG does not record step 189'; fi
if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)([;&|[:space:]]|$)' "$HELPER"; then fail 'step-189 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-189 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '(^|[;&|[:space:]])(curl|wget|git[[:space:]]+(fetch|pull|clone)|rsync[[:space:]].*::|scp|ssh)([;&|[:space:]]|$)' "$HELPER"; then fail 'step-189 helper contains a network client command'; else pass 'step-189 helper contains no network client command'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
