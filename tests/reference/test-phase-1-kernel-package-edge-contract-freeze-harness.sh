#!/bin/bash
set -u
IFS=$'\n\t'
PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-kernel-package-edge-contract-freeze.sh"
DOC="$repo_root/docs/reference/phase-1-kernel-package-edge-contract-freeze.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-contract-freeze-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-contract-freeze.tsv"
STEP190_HELPER="$repo_root/tools/reference/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze.sh"
STEP190_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze-policy.json"
STEP190_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze.tsv"
CHANGELOG="$repo_root/CHANGELOG.md"

check_regular() { local file=$1 label=$2; if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi; }
check_hash() { local file=$1 expected=$2 label=$3 actual; if [[ ! -f $file || -L $file ]]; then fail "$label hash cannot be checked"; return; fi; actual=$(sha256sum -- "$file" | awk '{print $1}'); if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi; }

for spec in \
    "$HELPER|step-191 contract helper" \
    "$DOC|step-191 reference document" \
    "$POLICY|step-191 contract policy" \
    "$RECORD|step-191 contract record" \
    "$STEP190_HELPER|accepted step-190 selection helper" \
    "$STEP190_POLICY|accepted step-190 selection policy" \
    "$STEP190_RECORD|accepted step-190 selection record"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done
check_hash "$HELPER" 'd47e283f81738763563cdc27f17a2badf7a44cdb8d11240be4d01c4a3dce3896' 'step-191 contract helper'
check_hash "$DOC" 'e288b124db9ec5a3141bd97258db13cd2bf248da0d2cecb31f14d56c38ea9afd' 'step-191 reference document'
check_hash "$POLICY" '95f065e015106467e25f81d1cb9c4199967edd51aee821ed70d3001c301a35fc' 'step-191 contract policy'
check_hash "$RECORD" 'ab90fa4f61dd5de7db5fe76cebcd72adfe7d25c95d6925aeb1c67bd09db7f28d' 'step-191 contract record'
check_hash "$STEP190_HELPER" '5469e526a37457d78d615d258ce6a6f456531e7ba683297bd53226315b95454a' 'accepted step-190 selection helper'
check_hash "$STEP190_POLICY" 'edc91e482043c73cf5566963145f078171c875c35c0f557f0643935818eac128' 'accepted step-190 selection policy'
check_hash "$STEP190_RECORD" 'b2a1db47fd414f68fb8f18134fcc00b95a7b3cd4e3d7fa0650a19178eaa4a82d' 'accepted step-190 selection record'

if bash -n "$HELPER"; then pass 'step-191 contract helper is shell-syntax valid'; else fail 'step-191 contract helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-191 helper exposes a non-mutating help boundary'; else fail 'step-191 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-191 helper accepts unknown options'; else pass 'step-191 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-191 contract policy is valid JSON'; else fail 'step-191 contract policy is invalid JSON'; fi

output=$("$HELPER" 2>&1); helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-191 kernel-package-edge contract freeze completed successfully'; else fail 'step-191 contract helper failed'; printf '%s\n' "$output"; fi
expect_line() { local needle=$1 label=$2; if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi; }
expect_line $'accepted_selection_step\t190' 'contract starts from accepted step 190'
expect_line $'selected_family\tkernel-package-edge' 'contract preserves the selected kernel-package-edge family'
expect_line $'scenario_count\t1' 'contract contains the one selected scenario'
expect_line $'selected_scenario\tKernel headers update without a kernel image update.' 'selected scenario text remains exact'
expect_line $'contract_state\tfrozen' 'runtime-validation contract is frozen'
expect_line $'validation_mode\tcontrolled-real-system-package-state-transition' 'contract requires a controlled real-system package transition'
expect_line $'target_class\tslackware-current-runtime-validation-vm' 'target class is Slackware-current validation VM'
expect_line $'target_binding_deferred\tyes' 'exact machine binding remains deferred'
expect_line $'package_source_binding_deferred\tyes' 'exact package source remains deferred'
expect_line $'runtime_boundary_required\tyes' 'later runtime work still requires an explicit boundary'
expect_line $'repository_refresh_requirement\tconditional' 'repository refresh remains conditional'
expect_line $'candidate_set_bound\tno' 'no live candidate set is bound'
expect_line $'live_runtime_chain_open\tno' 'no live runtime chain is open'
expect_line $'required_header_delta\tat-least-one-configured-kernel-header-package-changes' 'header package delta is required'
expect_line $'required_boot_package_delta\tzero-configured-kernel-boot-packages-change' 'boot-package delta must be zero'
expect_line $'kernel_trigger_expected\tyes' 'kernel trigger must still fire'
expect_line $'initrd_update_expected\tno' 'initrd update must remain clear'
expect_line $'grub_update_expected\tno' 'GRUB update must remain clear'
expect_line $'external_module_warning_expected\tyes' 'external-module warning must remain observable'
expect_line $'boot_preparation_execution_allowed\tno' 'boot preparation may not execute'
expect_line $'boot_artifact_fingerprints_must_remain_unchanged\tyes' 'boot artifact fingerprints must remain unchanged'
expect_line $'running_kernel_must_remain_unchanged\tyes' 'running kernel must remain unchanged'
expect_line $'reboot_required\tno' 'scenario requires no reboot'
expect_line $'final_package_state_must_be_coherent\tyes' 'final package state must be coherent'
expect_line $'repository_refresh_default\tforbidden' 'repository refresh is forbidden by default at this step'
expect_line $'network_access_default\tforbidden' 'network access is forbidden by default at this step'
expect_line $'package_mutation_authorized_by_this_step\tno' 'step 191 authorizes no package mutation'
expect_line $'boot_mutation_allowed\tno' 'boot mutation is forbidden'
expect_line $'acceptance_matrix_complete\tno' 'acceptance matrix remains incomplete'
expect_line $'runtime_boundary_design_authorized_for_next_stage\tyes' 'only next-stage runtime-boundary design is authorized'
expect_line $'repository_refresh_authorized\tno' 'repository refresh is not authorized'
expect_line $'network_refresh_authorized\tno' 'network refresh is not authorized'
expect_line $'machine_execution_authorized\tno' 'machine execution is not authorized'
expect_line $'package_action_authorized\tno' 'package action is not authorized'
expect_line $'boot_action_authorized\tno' 'boot action is not authorized'
expect_line $'reboot_authorized\tno' 'reboot is not authorized'
expect_line $'runtime_scenario_execution_authorized\tno' 'runtime scenario execution is not authorized'
expect_line $'phase_2_start_authorized\tno' 'Phase 2 is not authorized'
expect_line $'machine_action_required\tno' 'step 191 requires no machine action'
expect_line $'slackware_current_publication_invalidates_contract\tno' 'later Slackware-current publication does not invalidate the contract'
expect_line $'next_stage\tphase-1-kernel-package-edge-runtime-boundary-design' 'next stage is kernel-package-edge runtime-boundary design'
expect_line $'pause_safe\tno' 'step 191 remains inside the active chain'

if python3 - "$POLICY" "$STEP190_POLICY" <<'PY_ASSERT'
import json, sys
p=json.load(open(sys.argv[1],encoding='utf-8')); s=json.load(open(sys.argv[2],encoding='utf-8'))
assert s['selection']['selected_family']=='kernel-package-edge'
assert s['selection']['scenario_count']==1 and s['selection']['selection_frozen'] is True
assert p['review_only'] is True and p['accepted_selection']['step']==190
c=p['contract']; sc=c['scenario']
assert c['state']=='frozen' and c['family']=='kernel-package-edge' and c['scenario_count']==1
assert sc['inventory_text']=='Kernel headers update without a kernel image update.'
assert sc['validation_mode']=='controlled-real-system-package-state-transition'
assert sc['required_header_delta']=='at-least-one-configured-kernel-header-package-changes'
assert sc['required_boot_package_delta']=='zero-configured-kernel-boot-packages-change'
assert sc['kernel_trigger_expected'] is True
assert sc['initrd_update_expected'] is False and sc['grub_update_expected'] is False
assert sc['external_module_warning_expected'] is True and sc['boot_preparation_execution_allowed'] is False
assert sc['reboot_required'] is False
assert c['target_class']=='slackware-current-runtime-validation-vm'
assert c['target_binding_deferred'] is True and c['package_source_binding_deferred'] is True
assert c['candidate_set_bound'] is False and c['live_runtime_chain_open'] is False
assert c['runtime_boundary_required'] is True and c['repository_refresh_requirement']=='conditional'
assert c['repository_refresh_default']=='forbidden' and c['network_access_default']=='forbidden'
assert c['package_mutation_authorized_by_this_step'] is False
assert c['boot_mutation_allowed'] is False and c['persistent_boot_configuration_change_allowed'] is False
assert c['boot_artifact_fingerprints_must_remain_unchanged'] is True
assert c['running_kernel_must_remain_unchanged'] is True
assert c['final_package_state_must_be_coherent'] is True and c['temporary_runtime_artifacts_must_be_cleaned'] is True
assert len(c['evidence_requirements'])==10
assert c['acceptance_rule']=='header-delta-is-observed-while-boot-package-delta-is-zero-and-no-boot-preparation-or-system-restart-is-triggered'
a=p['authorization']
assert a['runtime_boundary_design_authorized_for_next_stage'] is True
for key in ('source_change_authorized','documentation_change_authorized','repository_refresh_authorized','network_refresh_authorized','machine_execution_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','runtime_scenario_execution_authorized','phase_2_start_authorized'):
    assert a[key] is False
assert p['machine_action_required'] is False and p['slackware_current_publication_invalidates_contract'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-boundary-design' and p['pause_safe'] is False
PY_ASSERT
then pass 'contract policy freezes header-only kernel behavior with zero boot-package delta and no boot work'; else fail 'step-191 contract semantic assertions failed'; fi

repro_dir=$(mktemp -d)
if "$HELPER" --output-dir "$repro_dir" >/dev/null 2>&1 && cmp -s "$POLICY" "$repro_dir/$(basename "$POLICY")" && cmp -s "$RECORD" "$repro_dir/$(basename "$RECORD")"; then
    pass 'step-191 evidence reproduces deterministically in an isolated output directory'
else
    fail 'step-191 evidence does not reproduce deterministically'
fi
rm -rf -- "$repro_dir"

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'kernel-package-edge'* && $normalized_doc == *'KERNEL_TRIGGER=1'* && $normalized_doc == *'INITRD_UPDATE=0'* && $normalized_doc == *'GRUB_UPDATE=0'* && $normalized_doc == *'phase-1-kernel-package-edge-runtime-boundary-design'* ]]; then pass 'reference document records the frozen header-only contract and next stage'; else fail 'step-191 reference document is incomplete'; fi
if grep -Fq 'Phase 1 step 191 kernel-package-edge contract freeze' "$CHANGELOG" && grep -Fq 'phase-1-kernel-package-edge-runtime-boundary-design' "$CHANGELOG"; then pass 'CHANGELOG records step 191'; else fail 'CHANGELOG does not record step 191'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-191 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-191 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-191 helper contains a network client command'; else pass 'step-191 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
