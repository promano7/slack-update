#!/bin/bash
set -u
IFS=$'\n\t'
PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-roadmap-state-reconciliation-review.sh"
DOC="$repo_root/docs/reference/phase-1-roadmap-state-reconciliation-review.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-roadmap-state-reconciliation-review-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-roadmap-state-reconciliation-review.tsv"
STEP173_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-roadmap-state-reconciliation-execution-policy.json"
STEP173_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-roadmap-state-reconciliation-execution.tsv"
STEP173_HELPER="$repo_root/tools/reference/phase-1-roadmap-state-reconciliation-execution.sh"
README="$repo_root/README.md"
CHANGELOG="$repo_root/CHANGELOG.md"
check_regular() { local file=$1 label=$2; if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi; }
check_hash() { local file=$1 expected=$2 label=$3 actual; if [[ ! -f $file || -L $file ]]; then fail "$label hash cannot be checked"; return; fi; actual=$(sha256sum -- "$file" | awk '{print $1}'); if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi; }
for spec in "$HELPER|step-174 review helper" "$DOC|step-174 reference document" "$POLICY|step-174 review policy" "$RECORD|step-174 review record" "$STEP173_POLICY|accepted step-173 execution policy" "$STEP173_RECORD|accepted step-173 execution record" "$STEP173_HELPER|accepted step-173 execution helper" "$README|accepted reconciled README"; do check_regular "${spec%%|*}" "${spec#*|}"; done
check_hash "$HELPER" 'e3f3f09f8c318d52a91b3bcacfbb2c7fbb93c1e7727e564ce41bea33b0688920' 'step-174 review helper'
check_hash "$DOC" '1f4fd3b9f876828bb1e069fef7583fa75c4490d0e12d5360e7f09d47b4b79b42' 'step-174 reference document'
check_hash "$POLICY" '63da904c6c3b97acba8d648c0f586780ff460885755d5fa31371b055e853e119' 'step-174 review policy'
check_hash "$RECORD" 'ab250e343bf2c1968f6a6c27021b50d2aaf598a2fb791b6f0c10ecfbd81a3861' 'step-174 review record'
check_hash "$STEP173_POLICY" '3e8e87dfc82d8ecde69144bfc0805abb413c85901af5ef97c0e6a05f734cdb9e' 'accepted step-173 execution policy'
check_hash "$STEP173_RECORD" '3b876857640b4cc6f7502f3b9a40718fd1ca205de9bd5ce71c4154be248aee94' 'accepted step-173 execution record'
check_hash "$STEP173_HELPER" '16580a7077164ad351c0e5b9543498c10518f5d17d18da02440591d253776d47' 'accepted step-173 execution helper'
check_hash "$README" '6cfc1556fd6ef50089be4f3b5472c268dd01a8330b6262e46b51994712a7cfad' 'accepted reconciled README'
if bash -n "$HELPER"; then pass 'step-174 review helper is shell-syntax valid'; else fail 'step-174 review helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-174 helper exposes a non-mutating help boundary'; else fail 'step-174 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-174 helper accepts unknown options'; else pass 'step-174 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-174 review policy is valid JSON'; else fail 'step-174 review policy is invalid JSON'; fi
output=$("$HELPER" 2>&1); helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-174 roadmap reconciliation review completed successfully'; else fail 'step-174 review helper failed'; printf '%s\n' "$output"; fi
expect_line() { local needle=$1 label=$2; if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi; }
expect_line $'accepted_execution_step\t173' 'review starts from accepted step 173'
expect_line $'selected_workstream\troadmap-state-reconciliation' 'review preserves selected roadmap workstream'
expect_line $'review_state\taccepted' 'roadmap reconciliation execution is accepted'
expect_line $'review_target\tREADME.md' 'review target remains README.md'
expect_line $'rollback_closure\taccepted-step-92' 'rollback closure remains bound to step 92'
expect_line $'elilo_cleanup_closure\taccepted-step-116' 'ELILO cleanup closure remains bound to step 116'
expect_line $'historical_checklist\tpreserved' 'historical checklist remains preserved'
expect_line $'acceptance_matrix_complete\tfalse' 'acceptance matrix remains incomplete'
expect_line $'roadmap_reconciliation_closed\ttrue' 'roadmap reconciliation workstream is closed'
expect_line $'reference_freeze_status\tblocked-behind-remaining-acceptance-work' 'reference freeze remains blocked'
expect_line $'c_port_status\tblocked-by-phase-1-gate' 'C port remains blocked by the Phase 1 gate'
expect_line $'machine_action_required\tfalse' 'step 174 requires no machine action'
expect_line $'repository_refresh_authorized\tfalse' 'repository refresh remains unauthorized'
expect_line $'network_refresh_authorized\tfalse' 'network refresh remains unauthorized'
expect_line $'machine_execution_authorized\tfalse' 'machine execution remains unauthorized'
expect_line $'package_action_authorized\tfalse' 'package action remains unauthorized'
expect_line $'boot_action_authorized\tfalse' 'boot action remains unauthorized'
expect_line $'phase_2_start_authorized\tfalse' 'Phase 2 remains unauthorized'
expect_line $'future_work_requires_fresh_boundary\ttrue' 'future operational work requires a fresh boundary'
expect_line $'next_stage\tphase-1-acceptance-matrix-remainder-inventory' 'next stage is acceptance-matrix remainder inventory'
expect_line $'pause_safe\tfalse' 'step 174 is not the requested end-of-session safe pause'
expect_line $'strong_safe_pause\tfalse' 'step 174 is not the requested end-of-session strong safe pause'
if python3 - "$POLICY" "$STEP173_POLICY" "$README" <<'PYCHECK'
import json, sys
from pathlib import Path
p = json.load(open(sys.argv[1], encoding='utf-8'))
p173 = json.load(open(sys.argv[2], encoding='utf-8'))
text = Path(sys.argv[3]).read_text(encoding='utf-8')
assert p['scenario'] == 'phase-1-roadmap-state-reconciliation-review'
assert p['review_only'] is True and p['accepted_execution']['step'] == 173
assert p173['execution']['state'] == 'completed' and p173['execution']['target_paths'] == ['README.md']
review = p['review']
assert review['state'] == 'accepted' and review['roadmap_reconciliation_closed'] is True
assert review['acceptance_matrix_complete'] is False
assert review['reference_freeze_status'] == 'blocked-behind-remaining-acceptance-work'
assert review['c_port_status'] == 'blocked-by-phase-1-gate'
assert p['remaining_phase_1_work']['acceptance_matrix_remainder'] == 'pending-future-machine-work'
for key in ('source_change_authorized','documentation_change_authorized','repository_refresh_authorized','network_refresh_authorized','machine_execution_authorized','package_action_authorized','boot_action_authorized','phase_2_start_authorized'):
    assert p['authorization'][key] is False
assert p['authorization']['future_work_requires_explicit_authorization'] is True
assert p['authorization']['future_work_requires_fresh_boundary'] is True
assert p['safe_pause']['pause_safe'] is False and p['safe_pause']['strong_safe_pause'] is False
assert p['safe_pause']['machine_action_required'] is False
assert p['safe_pause']['slackware_current_publication_invalidates_review'] is False
assert p['next_stage'] == 'phase-1-acceptance-matrix-remainder-inventory'
assert text.count('## Accepted Slackware-current rollback closure') == 1
assert text.count('## Accepted Slackware 15.0 ELILO cleanup closure') == 1
assert '**Current Phase 1 gate:**' in text
PYCHECK
then pass 'review policy closes only roadmap reconciliation and preserves all Phase 1 gates'; else fail 'step-174 review semantic assertions failed'; fi
if grep -Fq 'Phase 1 step 174 roadmap-state reconciliation review' "$CHANGELOG" && grep -Fq 'phase-1-acceptance-matrix-remainder-inventory' "$CHANGELOG"; then pass 'CHANGELOG records step 174'; else fail 'CHANGELOG does not record step 174'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-174 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-174 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-174 helper contains a network client command'; else pass 'step-174 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
