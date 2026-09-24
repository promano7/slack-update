#!/bin/bash
set -uo pipefail
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze.sh"
DOC="$repo_root/docs/reference/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze.tsv"
STEP189_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review-policy.json"
STEP189_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review.tsv"
RESIDUAL_INVENTORY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv"
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
    "$HELPER|step-190 selection helper" \
    "$DOC|step-190 reference document" \
    "$POLICY|step-190 selection policy" \
    "$RECORD|step-190 selection record" \
    "$STEP189_POLICY|accepted step-189 boundary policy" \
    "$STEP189_RECORD|accepted step-189 boundary record" \
    "$RESIDUAL_INVENTORY|accepted residual inventory"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done

check_hash "$HELPER" '5469e526a37457d78d615d258ce6a6f456531e7ba683297bd53226315b95454a' 'step-190 selection helper'
check_hash "$DOC" 'bc4d9356af3652a85a1f8e4f79c09012c45e29c03cc83741f9546fb2492eb9e8' 'step-190 reference document'
check_hash "$POLICY" 'edc91e482043c73cf5566963145f078171c875c35c0f557f0643935818eac128' 'step-190 selection policy'
check_hash "$RECORD" 'b2a1db47fd414f68fb8f18134fcc00b95a7b3cd4e3d7fa0650a19178eaa4a82d' 'step-190 selection record'
check_hash "$STEP189_POLICY" 'e14c2a8ac8d11fe5d8416bf52e724e5883c523228193e4f0c1235a5510540c9f' 'accepted step-189 boundary policy'
check_hash "$STEP189_RECORD" '8a9a5e70ea1eec093f0ed5528d99f9436b3eafcaa835002227c25b817164bacc' 'accepted step-189 boundary record'
check_hash "$RESIDUAL_INVENTORY" '8aa3f1dbe177ec336025f4b3983e22b07205d8bf72fb214442704764131094e9' 'accepted residual inventory'

if bash -n "$HELPER"; then pass 'step-190 selection helper is shell-syntax valid'; else fail 'step-190 selection helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-190 helper exposes a non-mutating help boundary'; else fail 'step-190 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-190 helper accepts unknown options'; else pass 'step-190 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-190 selection policy is valid JSON'; else fail 'step-190 selection policy is invalid JSON'; fi

output=$("$HELPER" 2>&1)
helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-190 family selection freeze completed successfully'; else fail 'step-190 selection helper failed'; printf '%s\n' "$output"; fi
expect_line() {
    local needle=$1 label=$2
    if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi
}
expect_line $'accepted_boundary_step\t189' 'selection starts from accepted step 189'
expect_line $'inventory_family_count\t5' 'accepted residual inventory contains five families'
expect_line $'inventory_scenario_count\t20' 'accepted residual inventory contains 20 scenarios'
expect_line $'closed_family\texecution-control-failure-paths' 'closed execution-control family remains identified'
expect_line $'closed_family_reopened\tno' 'closed execution-control family is not reopened'
expect_line $'selected_family\tkernel-package-edge' 'kernel-package-edge family is selected'
expect_line $'selected_family_scenario_count\t1' 'selected family contains one scenario'
expect_line $'selected_scenario\tKernel headers update without a kernel image update.' 'selected kernel/package edge scenario is exact'
expect_line $'selection_state\tselected' 'selection state is selected'
expect_line $'selection_frozen\tyes' 'family selection is frozen'
expect_line $'runtime_boundary_required\tyes' 'selected family requires a fresh runtime boundary'
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
expect_line $'reboot_authorized\tno' 'no reboot is authorized'
expect_line $'runtime_scenario_execution_authorized\tno' 'no runtime scenario execution is authorized'
expect_line $'phase_2_start_authorized\tno' 'Phase 2 is not authorized'
expect_line $'machine_action_required\tno' 'step 190 requires no machine action'
expect_line $'slackware_current_publication_invalidates_selection\tno' 'later Slackware-current publication does not invalidate the family selection'
expect_line $'next_stage\tphase-1-kernel-package-edge-contract-freeze' 'next stage is the kernel-package-edge contract freeze'
expect_line $'pause_safe\tno' 'step 190 remains inside the active planning chain'

if python3 - "$POLICY" "$STEP189_POLICY" "$RESIDUAL_INVENTORY" <<'PY'
import csv, json, sys
with open(sys.argv[1], encoding='utf-8') as handle:
    p = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    p189 = json.load(handle)
with open(sys.argv[3], encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))
assert p189['fresh_boundary']['opened'] is True
assert p189['fresh_boundary']['family_selected_for_execution'] is False
assert p189['inventory']['family_count'] == 5
assert p189['inventory']['scenario_count'] == 20
families = {row['family']: row for row in rows}
assert 'execution-control-failure-paths' not in families
family = families['kernel-package-edge']
assert family['scenario_count'] == '1'
assert family['scenarios'] == 'Kernel headers update without a kernel image update.'
assert p['review_only'] is True
assert p['accepted_boundary']['step'] == 189
assert p['accepted_inventory']['family_count'] == 5
assert p['accepted_inventory']['scenario_count'] == 20
assert p['selection']['selected_family'] == 'kernel-package-edge'
assert p['selection']['scenario_count'] == 1
assert p['selection']['scenarios'] == ['Kernel headers update without a kernel image update.']
assert p['selection']['runtime_boundary_required'] is True
assert p['selection']['repository_refresh_requirement'] == 'conditional'
assert p['selection']['selection_frozen'] is True
assert p['selection']['candidate_set_bound'] is False
assert p['selection']['live_runtime_chain_open'] is False
assert p['selection']['closed_execution_control_family_reopened'] is False
assert p['selection']['slackware_current_publication_invalidates_selection'] is False
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
assert p['next_stage'] == 'phase-1-kernel-package-edge-contract-freeze'
assert p['pause_safe'] is False
PY
then pass 'selection policy freezes only kernel-package-edge, preserves the closed family, and grants no operational authorization'; else fail 'step-190 selection semantic assertions failed'; fi

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
if "$HELPER" --output-dir "$tmpdir" >/dev/null 2>&1; then
    pass 'step-190 evidence reproduces successfully in an isolated output directory'
else
    fail 'step-190 isolated evidence reproduction failed'
fi
if cmp -s "$POLICY" "$tmpdir/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze-policy.json"; then pass 'step-190 policy is deterministically reproducible'; else fail 'step-190 policy is not deterministic'; fi
if cmp -s "$RECORD" "$tmpdir/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze.tsv"; then pass 'step-190 record is deterministically reproducible'; else fail 'step-190 record is not deterministic'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'kernel-package-edge'* && $normalized_doc == *'Kernel headers update without a kernel image update.'* && $normalized_doc == *'phase-1-kernel-package-edge-contract-freeze'* ]]; then
    pass 'reference document records the selected family, exact scenario, and next stage'
else
    fail 'step-190 reference document is incomplete'
fi
if grep -Fq 'Phase 1 step 190 post-execution-control remainder family selection freeze' "$CHANGELOG" && grep -Fq 'phase-1-kernel-package-edge-contract-freeze' "$CHANGELOG"; then pass 'CHANGELOG records step 190'; else fail 'CHANGELOG does not record step 190'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-190 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-190 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-190 helper contains a network client command'; else pass 'step-190 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
