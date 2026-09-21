#!/bin/bash
set -u
IFS=$'\n\t'
PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-roadmap-state-reconciliation-execution.sh"
DOC="$repo_root/docs/reference/phase-1-roadmap-state-reconciliation-execution.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-roadmap-state-reconciliation-execution-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-roadmap-state-reconciliation-execution.tsv"
STEP172_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-roadmap-state-reconciliation-contract-freeze-policy.json"
STEP172_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-roadmap-state-reconciliation-contract-freeze.tsv"
README="$repo_root/README.md"
CHANGELOG="$repo_root/CHANGELOG.md"
check_regular() { local file=$1 label=$2; if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi; }
check_hash() { local file=$1 expected=$2 label=$3 actual; if [[ ! -f $file || -L $file ]]; then fail "$label hash cannot be checked"; return; fi; actual=$(sha256sum -- "$file" | awk '{print $1}'); if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi; }
for spec in "$HELPER|step-173 execution verifier" "$DOC|step-173 reference document" "$POLICY|step-173 execution policy" "$RECORD|step-173 execution record" "$STEP172_POLICY|accepted step-172 contract policy" "$STEP172_RECORD|accepted step-172 contract record" "$README|reconciled README"; do check_regular "${spec%%|*}" "${spec#*|}"; done
check_hash "$HELPER" '16580a7077164ad351c0e5b9543498c10518f5d17d18da02440591d253776d47' 'step-173 execution verifier'
check_hash "$DOC" '5540fe455a588a6c1f97c975926d1145e671b9c6f9f2528c7e04c378e355d569' 'step-173 reference document'
check_hash "$POLICY" '3e8e87dfc82d8ecde69144bfc0805abb413c85901af5ef97c0e6a05f734cdb9e' 'step-173 execution policy'
check_hash "$RECORD" '3b876857640b4cc6f7502f3b9a40718fd1ca205de9bd5ce71c4154be248aee94' 'step-173 execution record'
check_hash "$STEP172_POLICY" '0b9bfc71f9677fbadf76c94394b5517c6c9ecfc4cfdc8ec535703ac2147913bc' 'accepted step-172 contract policy'
check_hash "$STEP172_RECORD" 'c4419ace9ac4dabbe0c31beaba24ca0469fc2f7463bdbf49d7e68e4778748b43' 'accepted step-172 contract record'
if bash -n "$HELPER"; then pass 'step-173 execution verifier is shell-syntax valid'; else fail 'step-173 execution verifier has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-173 verifier exposes a non-mutating help boundary'; else fail 'step-173 verifier help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-173 verifier accepts unknown options'; else pass 'step-173 verifier rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-173 execution policy is valid JSON'; else fail 'step-173 execution policy is invalid JSON'; fi
output=$("$HELPER" 2>&1); helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-173 roadmap reconciliation execution verified successfully'; else fail 'step-173 execution verifier failed'; printf '%s\n' "$output"; fi
expect_line() { local needle=$1 label=$2; if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi; }
expect_line $'accepted_contract_step\t172' 'execution starts from accepted step 172'
expect_line $'selected_workstream\troadmap-state-reconciliation' 'execution preserves selected roadmap workstream'
expect_line $'execution_state\tcompleted' 'roadmap reconciliation execution is complete'
expect_line $'target_path\tREADME.md' 'execution substantive target is README.md'
expect_line $'current_rollback_presentation\taccepted-step-92-closure-summary' 'rollback continuation is reconciled to step-92 closure'
expect_line $'elilo_cleanup_presentation\taccepted-step-116-closure-summary' 'ELILO continuation is reconciled to step-116 closure'
expect_line $'immediate_next_steps\tcurrent-phase-1-gates-and-pending-work' 'Immediate next steps reflects current Phase 1 gates'
expect_line $'historical_checklist\tpreserved' 'historical checklist is preserved'
expect_line $'acceptance_matrix_complete\tfalse' 'acceptance matrix remains incomplete'
expect_line $'acceptance_matrix_checkbox_mass_update\tfalse' 'no acceptance checkbox mass update occurred'
expect_line $'reference_freeze_status\tblocked-behind-remaining-acceptance-work' 'reference freeze remains blocked'
expect_line $'c_port_status\tblocked-by-phase-1-gate' 'C port remains blocked by the Phase 1 gate'
expect_line $'source_code_changed\tfalse' 'source code was not changed'
expect_line $'configuration_changed\tfalse' 'configuration was not changed'
expect_line $'runtime_tests_changed\tfalse' 'runtime tests were not changed'
expect_line $'machine_action_required\tfalse' 'step 173 requires no machine action'
expect_line $'repository_refresh_authorized\tfalse' 'repository refresh remains unauthorized'
expect_line $'network_refresh_authorized\tfalse' 'network refresh remains unauthorized'
expect_line $'machine_execution_authorized\tfalse' 'machine execution remains unauthorized'
expect_line $'package_action_authorized\tfalse' 'package action remains unauthorized'
expect_line $'boot_action_authorized\tfalse' 'boot action remains unauthorized'
expect_line $'phase_2_start_authorized\tfalse' 'Phase 2 remains unauthorized'
expect_line $'next_stage\tphase-1-roadmap-state-reconciliation-review' 'next stage is roadmap reconciliation review'
expect_line $'pause_safe\tfalse' 'step 173 is not the requested end-of-session strong safe pause'
if python3 - "$POLICY" "$STEP172_POLICY" "$README" <<'PYCHECK'
import json, sys
from pathlib import Path
p=json.load(open(sys.argv[1],encoding='utf-8')); p172=json.load(open(sys.argv[2],encoding='utf-8')); text=Path(sys.argv[3]).read_text(encoding='utf-8')
assert p172['contract']['state']=='frozen' and p172['contract']['target_paths']==['README.md']
assert p['accepted_contract']['step']==172 and p['execution']['state']=='completed' and p['execution']['target_paths']==['README.md']
assert p['execution']['change_class']=='documentation-roadmap-presentation-only'
assert p['execution']['historical_checklist_preserved'] is True and p['execution']['acceptance_matrix_complete'] is False and p['execution']['acceptance_matrix_checkbox_mass_update_performed'] is False
assert p['execution']['reference_freeze_status']=='blocked-behind-remaining-acceptance-work' and p['execution']['c_port_status']=='blocked-by-phase-1-gate'
for key in ('repository_refresh_authorized','network_refresh_authorized','machine_execution_authorized','package_action_authorized','boot_action_authorized','phase_2_start_authorized'): assert p['authorization'][key] is False
assert p['machine_action_required'] is False and p['next_stage']=='phase-1-roadmap-state-reconciliation-review' and p['slackware_current_publication_invalidates_execution'] is False and p['pause_safe'] is False
assert text.count('## Accepted Slackware-current rollback closure') == 1
assert text.count('## Accepted Slackware 15.0 ELILO cleanup closure') == 1
assert '## Current optional rollback continuation' not in text and '## Slackware 15.0 ELILO cleanup continuation' not in text
assert '**Current Phase 1 gate:**' in text and 'remaining real-system acceptance work is still pending' in text
assert '`reference-v1` remains blocked' in text and 'the C port remains blocked by the Phase 1 gate' in text
assert 'preserved below as historical execution evidence' in text
PYCHECK
then pass 'execution policy and README preserve the frozen reconciliation contract'; else fail 'step-173 execution semantic assertions failed'; fi
if python3 - "$README" <<'PYCHECK'
import re, sys
from pathlib import Path
text=Path(sys.argv[1]).read_text(encoding='utf-8')
def section(start,end):
    a=text.index(start); b=text.index(end,a); return text[a:b]
rollback=section('## Accepted Slackware-current rollback closure','## Accepted Slackware 15.0 ELILO cleanup closure')
elilo=section('## Accepted Slackware 15.0 ELILO cleanup closure','## Goals')
for block in (rollback,elilo):
    assert 'sudo ' not in block
    assert not re.search(r'^```(?:bash|sh|shell)?$',block,re.M)
assert 'No rollback boot, return reboot, package action, GRUB mutation, or repository\nrefresh is pending or authorized by this summary.' in rollback
assert 'No cleanup, package, ELILO, recovery-backup, reboot, or repository action is\npending or authorized by this summary.' in elilo
PYCHECK
then pass 'accepted closure summaries are non-actionable and contain no command block'; else fail 'README closure summaries are actionable or incomplete'; fi
if grep -Fq 'Phase 1 step 173 roadmap-state reconciliation execution' "$CHANGELOG" && grep -Fq 'phase-1-roadmap-state-reconciliation-review' "$CHANGELOG"; then pass 'CHANGELOG records step 173'; else fail 'CHANGELOG does not record step 173'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-173 verifier contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-173 verifier contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-173 verifier contains a network client command'; else pass 'step-173 verifier contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL)" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
