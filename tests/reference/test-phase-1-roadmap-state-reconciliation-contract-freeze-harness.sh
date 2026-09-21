#!/bin/bash
set -u
IFS=$'\n\t'
PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-roadmap-state-reconciliation-contract-freeze.sh"
DOC="$repo_root/docs/reference/phase-1-roadmap-state-reconciliation-contract-freeze.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-roadmap-state-reconciliation-contract-freeze-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-roadmap-state-reconciliation-contract-freeze.tsv"
STEP171_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-post-comment-language-next-workstream-selection-freeze-policy.json"
STEP171_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-post-comment-language-next-workstream-selection-freeze.tsv"
CHANGELOG="$repo_root/CHANGELOG.md"
check_regular() { local file=$1 label=$2; if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi; }
check_hash() { local file=$1 expected=$2 label=$3 actual; if [[ ! -f $file || -L $file ]]; then fail "$label hash cannot be checked"; return; fi; actual=$(sha256sum -- "$file" | awk '{print $1}'); if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi; }
for spec in "$HELPER|step-172 contract helper" "$DOC|step-172 reference document" "$POLICY|step-172 contract policy" "$RECORD|step-172 contract record" "$STEP171_POLICY|accepted step-171 selection policy" "$STEP171_RECORD|accepted step-171 selection record"; do check_regular "${spec%%|*}" "${spec#*|}"; done
check_hash "$HELPER" 'a7b0c286d51e937659ad7f040199f4290af47189ad0949b6ca342bf950366eb4' 'step-172 contract helper'
check_hash "$DOC" 'fef40fd27eb89aecb17de0603c9588135eac97eafbadb2ab3c387c6d674c9726' 'step-172 reference document'
check_hash "$POLICY" '0b9bfc71f9677fbadf76c94394b5517c6c9ecfc4cfdc8ec535703ac2147913bc' 'step-172 contract policy'
check_hash "$RECORD" 'c4419ace9ac4dabbe0c31beaba24ca0469fc2f7463bdbf49d7e68e4778748b43' 'step-172 contract record'
check_hash "$STEP171_POLICY" '2992453f2d5e03f34241a3fcc8be3ee48da57630ccceb9aef2f1b560ab76547a' 'accepted step-171 selection policy'
check_hash "$STEP171_RECORD" '88734d47d6b85c2dc8e05f527ac0613bc01aad9254ffac1fc75ad98508ca5e0d' 'accepted step-171 selection record'
if bash -n "$HELPER"; then pass 'step-172 contract helper is shell-syntax valid'; else fail 'step-172 contract helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-172 helper exposes a non-mutating help boundary'; else fail 'step-172 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-172 helper accepts unknown options'; else pass 'step-172 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-172 contract policy is valid JSON'; else fail 'step-172 contract policy is invalid JSON'; fi
output=$("$HELPER" 2>&1); helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-172 roadmap reconciliation contract freeze completed successfully'; else fail 'step-172 contract helper failed'; printf '%s\n' "$output"; fi
expect_line() { local needle=$1 label=$2; if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi; }
expect_line $'accepted_selection_step\t171' 'contract starts from accepted step 171'
expect_line $'selected_workstream\troadmap-state-reconciliation' 'contract preserves selected roadmap workstream'
expect_line $'contract_state\tfrozen' 'roadmap reconciliation contract is frozen'
expect_line $'target_path\tREADME.md' 'contract targets README.md only'
expect_line $'allowed_change_class\tdocumentation-roadmap-presentation-only' 'change class is documentation-only'
expect_line $'stale_current_rollback_continuation\treconcile-to-accepted-step-92-closure' 'current rollback continuation is bound to step-92 closure'
expect_line $'stale_elilo_cleanup_continuation\treconcile-to-accepted-step-116-closure' 'ELILO continuation is bound to step-116 closure'
expect_line $'immediate_next_steps\treconcile-to-current-phase-1-gates' 'immediate next steps must reflect current Phase 1 gates'
expect_line $'acceptance_matrix_completion_claim\tforbidden' 'acceptance matrix completion claim is forbidden'
expect_line $'acceptance_matrix_checkbox_mass_update\tforbidden' 'acceptance matrix mass checkbox update is forbidden'
expect_line $'reference_freeze_status\tblocked-behind-remaining-acceptance-work' 'reference freeze remains blocked'
expect_line $'c_port_status\tblocked-by-phase-1-gate' 'C port remains blocked by the Phase 1 gate'
expect_line $'preserve_phase_1_gate\ttrue' 'Phase 1 gate must be preserved'
expect_line $'preserve_historical_evidence\ttrue' 'historical evidence must be preserved'
expect_line $'documentation_execution_authorized_for_next_stage\ttrue' 'next stage may execute only the frozen documentation reconciliation'
expect_line $'source_code_change_authorized\tfalse' 'source-code changes are not authorized'
expect_line $'configuration_change_authorized\tfalse' 'configuration changes are not authorized'
expect_line $'runtime_test_change_authorized\tfalse' 'runtime-test changes are not authorized'
expect_line $'repository_refresh_authorized\tfalse' 'repository refresh is not authorized'
expect_line $'network_refresh_authorized\tfalse' 'network refresh is not authorized'
expect_line $'machine_execution_authorized\tfalse' 'machine execution is not authorized'
expect_line $'package_action_authorized\tfalse' 'package action is not authorized'
expect_line $'boot_action_authorized\tfalse' 'boot action is not authorized'
expect_line $'phase_2_start_authorized\tfalse' 'Phase 2 is not authorized'
expect_line $'machine_action_required\tfalse' 'step 172 requires no machine action'
expect_line $'slackware_current_publication_invalidates_contract\tfalse' 'later Slackware-current publication does not invalidate this contract'
expect_line $'next_stage\tphase-1-roadmap-state-reconciliation-execution' 'next stage is roadmap reconciliation execution'
expect_line $'pause_safe\tfalse' 'step 172 is not the requested end-of-session strong safe pause'
if python3 - "$POLICY" "$STEP171_POLICY" <<'PYCHECK'
import json, sys
p=json.load(open(sys.argv[1],encoding='utf-8')); p171=json.load(open(sys.argv[2],encoding='utf-8'))
assert p171['selection']['selected_workstream']=='roadmap-state-reconciliation' and p171['selection']['selection_frozen'] is True
assert p['review_only'] is True and p['accepted_selection']['step']==171 and p['accepted_selection']['selected_workstream']=='roadmap-state-reconciliation'
assert p['contract']['state']=='frozen' and p['contract']['target_paths']==['README.md'] and p['contract']['allowed_change_class']=='documentation-roadmap-presentation-only'
assert p['contract']['preserve_phase_1_gate'] is True and p['contract']['preserve_historical_evidence'] is True and p['contract']['acceptance_matrix_checkbox_mass_update_allowed'] is False
assert p['contract']['reference_freeze_status']=='blocked-behind-remaining-acceptance-work' and p['contract']['c_port_status']=='blocked-by-phase-1-gate'
items={x['id']:x for x in p['contract']['reconciliation_items']}
assert items['current-rollback-continuation']['required_state']=='accepted-step-92-closure-summary' and items['current-rollback-continuation']['actionable_commands_allowed'] is False
assert items['slackware-15-elilo-cleanup-continuation']['required_state']=='accepted-step-116-closure-summary' and items['slackware-15-elilo-cleanup-continuation']['actionable_commands_allowed'] is False
assert items['immediate-next-steps']['may_claim_acceptance_matrix_complete'] is False
assert p['authorization']['documentation_execution_authorized_for_next_stage'] is True
for key in ('source_code_change_authorized','configuration_change_authorized','runtime_test_change_authorized','repository_refresh_authorized','network_refresh_authorized','machine_execution_authorized','package_action_authorized','boot_action_authorized','phase_2_start_authorized'): assert p['authorization'][key] is False
assert p['machine_action_required'] is False and p['next_stage']=='phase-1-roadmap-state-reconciliation-execution' and p['slackware_current_publication_invalidates_contract'] is False and p['pause_safe'] is False
PYCHECK
then pass 'contract policy freezes only the README roadmap reconciliation and preserves all operational gates'; else fail 'step-172 contract semantic assertions failed'; fi
normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'documentation-roadmap-presentation-only'* && $normalized_doc == *'accepted step-92 rollback closure'* && $normalized_doc == *'accepted step-116 scenario closure'* && $normalized_doc == *'Bulk completion of acceptance-matrix checkboxes is explicitly forbidden'* && $normalized_doc == *'phase-1-roadmap-state-reconciliation-execution'* ]]; then pass 'reference document records the frozen reconciliation scope, preserved gates, and next stage'; else fail 'step-172 reference document is incomplete'; fi
if grep -Fq 'Phase 1 step 172 roadmap-state reconciliation contract freeze' "$CHANGELOG" && grep -Fq 'phase-1-roadmap-state-reconciliation-execution' "$CHANGELOG"; then pass 'CHANGELOG records step 172'; else fail 'CHANGELOG does not record step 172'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-172 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-172 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-172 helper contains a network client command'; else pass 'step-172 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
