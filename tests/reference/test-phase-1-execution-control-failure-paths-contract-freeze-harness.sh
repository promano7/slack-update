#!/bin/bash
set -u
IFS=$'\n\t'
PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-contract-freeze.sh"
DOC="$repo_root/docs/reference/phase-1-execution-control-failure-paths-contract-freeze.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-contract-freeze-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-contract-freeze.tsv"
STEP178_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-family-selection-freeze-policy.json"
STEP178_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-family-selection-freeze.tsv"
CHANGELOG="$repo_root/CHANGELOG.md"

check_regular() { local file=$1 label=$2; if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi; }
check_hash() { local file=$1 expected=$2 label=$3 actual; if [[ ! -f $file || -L $file ]]; then fail "$label hash cannot be checked"; return; fi; actual=$(sha256sum -- "$file" | awk '{print $1}'); if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi; }

for spec in \
    "$HELPER|step-179 contract helper" \
    "$DOC|step-179 reference document" \
    "$POLICY|step-179 contract policy" \
    "$RECORD|step-179 contract record" \
    "$STEP178_POLICY|accepted step-178 selection policy" \
    "$STEP178_RECORD|accepted step-178 selection record"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done
check_hash "$HELPER" '1da5e60a3c7f015c3817e51baf5d7c0598408df274cca49fdcfaee10256f81d1' 'step-179 contract helper'
check_hash "$DOC" '18ec6b31f104d7aed425d8ba5e96939be51a5207d0716e42b7fe78fca06e0ce1' 'step-179 reference document'
check_hash "$POLICY" '5ea897b193250dd99d9f7ac988cdd2fc95f1bc48df41c8d6189b6a689e1c1dd9' 'step-179 contract policy'
check_hash "$RECORD" '7a6ed7b1342f8d741debdc40de7d39bf1063fb84cb0e57e6f60f8e42db9f4bd6' 'step-179 contract record'
check_hash "$STEP178_POLICY" '9f06efed40e4bcf0f32939a9e4c0b6ec77b930696cd6cad0ad12ed1b75c168a0' 'accepted step-178 selection policy'
check_hash "$STEP178_RECORD" '8b783f4b7fc442a3fb5da2731e88b4c6882650cac1dbbc822073519b8f34a32c' 'accepted step-178 selection record'

if bash -n "$HELPER"; then pass 'step-179 contract helper is shell-syntax valid'; else fail 'step-179 contract helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-179 helper exposes a non-mutating help boundary'; else fail 'step-179 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-179 helper accepts unknown options'; else pass 'step-179 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-179 contract policy is valid JSON'; else fail 'step-179 contract policy is invalid JSON'; fi

output=$("$HELPER" 2>&1); helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-179 execution-control contract freeze completed successfully'; else fail 'step-179 contract helper failed'; printf '%s\n' "$output"; fi
expect_line() { local needle=$1 label=$2; if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi; }
expect_line $'accepted_selection_step\t178' 'contract starts from accepted step 178'
expect_line $'selected_family\texecution-control-failure-paths' 'contract preserves the selected execution-control family'
expect_line $'scenario_count\t4' 'contract contains all four selected scenarios'
expect_line $'contract_state\tfrozen' 'runtime-validation contract is frozen'
expect_line $'target_class\tslackware-current-runtime-validation-vm' 'target class is Slackware-current validation VM'
expect_line $'target_binding_deferred\tyes' 'exact machine binding remains deferred'
expect_line $'runtime_boundary_required\tyes' 'later runtime work still requires an explicit boundary'
expect_line $'candidate_set_bound\tno' 'no live candidate set is bound'
expect_line $'live_runtime_chain_open\tno' 'no live runtime chain is open'
expect_line $'live_package_publication_dependency\tno' 'contract does not depend on current package publication state'
expect_line $'repository_refresh_default\tforbidden' 'repository refresh is forbidden by default'
expect_line $'network_access_default\tforbidden' 'network access is forbidden by default'
expect_line $'package_mutation_allowed\tno' 'package mutation is forbidden'
expect_line $'boot_mutation_allowed\tno' 'boot mutation is forbidden'
expect_line $'reboot_required\tno' 'no reboot is required'
expect_line $'persistent_system_configuration_change_allowed\tno' 'persistent system configuration mutation is forbidden'
expect_line $'network_failure_required_result\tfail-closed-with-clean-control-state' 'network-failure path must fail closed and cleanly'
expect_line $'simultaneous_execution_required_result\tsecond-attempt-rejected-and-control-state-cleaned' 'simultaneous execution must reject the second attempt'
expect_line $'signal_set\tSIGINT,SIGTERM,SIGHUP' 'all three required signals are frozen into the contract'
expect_line $'signals_required_result\ttermination-is-observable-and-control-state-is-cleaned' 'signal runs must terminate observably and cleanly'
expect_line $'cron_execution_context\treal-cron-noninteractive-context' 'cron test requires a real noninteractive cron context'
expect_line $'cron_required_result\tnoninteractive-behavior-is-deterministic-and-clean' 'cron behavior must be deterministic and clean'
expect_line $'acceptance_matrix_complete\tno' 'acceptance matrix remains incomplete'
expect_line $'runtime_boundary_design_authorized_for_next_stage\tyes' 'only next-stage runtime-boundary design is authorized'
expect_line $'repository_refresh_authorized\tno' 'repository refresh is not authorized'
expect_line $'network_refresh_authorized\tno' 'network refresh is not authorized'
expect_line $'machine_execution_authorized\tno' 'machine execution is not authorized'
expect_line $'package_action_authorized\tno' 'package action is not authorized'
expect_line $'boot_action_authorized\tno' 'boot action is not authorized'
expect_line $'phase_2_start_authorized\tno' 'Phase 2 is not authorized'
expect_line $'machine_action_required\tno' 'step 179 requires no machine action'
expect_line $'slackware_current_publication_invalidates_contract\tno' 'later Slackware-current publication does not invalidate the contract'
expect_line $'next_stage\tphase-1-execution-control-failure-paths-runtime-boundary-design' 'next stage is runtime-boundary design'
expect_line $'pause_safe\tno' 'step 179 is not the requested end-of-session strong safe pause'

if python3 - "$POLICY" "$STEP178_POLICY" <<'PY'
import json, sys
p=json.load(open(sys.argv[1],encoding='utf-8')); s=json.load(open(sys.argv[2],encoding='utf-8'))
assert s['selection']['selected_family']=='execution-control-failure-paths' and s['selection']['selection_frozen'] is True
assert p['review_only'] is True and p['accepted_selection']['step']==178
c=p['contract']
assert c['state']=='frozen' and c['family']=='execution-control-failure-paths' and c['scenario_count']==4
assert c['target_class']=='slackware-current-runtime-validation-vm' and c['target_binding_deferred'] is True
assert c['runtime_boundary_required'] is True and c['candidate_set_bound'] is False and c['live_runtime_chain_open'] is False
assert c['live_package_publication_dependency'] is False
assert c['repository_refresh_default']=='forbidden' and c['network_access_default']=='forbidden'
assert c['package_mutation_allowed'] is False and c['boot_mutation_allowed'] is False and c['reboot_required'] is False
assert c['persistent_system_configuration_change_allowed'] is False
items={x['id']:x for x in c['scenario_contracts']}
assert set(items)=={'network-failure-before-repository-synchronization','simultaneous-execution-attempt','signals-during-safe-test-operations','cron-without-interactive-terminal'}
assert items['network-failure-before-repository-synchronization']['persistent_network_configuration_change_allowed'] is False
assert items['simultaneous-execution-attempt']['second_process_may_proceed_concurrently'] is False
assert items['signals-during-safe-test-operations']['signals']==['SIGINT','SIGTERM','SIGHUP'] and items['signals-during-safe-test-operations']['one_signal_per_run'] is True
assert items['cron-without-interactive-terminal']['execution_context']=='real-cron-noninteractive-context' and items['cron-without-interactive-terminal']['interactive_terminal_allowed'] is False
assert len(c['evidence_requirements'])==6 and c['acceptance_rule']=='all-four-scenarios-must-pass-under-one-explicitly-authorized-bounded-runtime-chain'
a=p['authorization']
assert a['runtime_boundary_design_authorized_for_next_stage'] is True
for key in ('source_change_authorized','documentation_change_authorized','repository_refresh_authorized','network_refresh_authorized','machine_execution_authorized','package_action_authorized','boot_action_authorized','phase_2_start_authorized'): assert a[key] is False
assert p['machine_action_required'] is False and p['slackware_current_publication_invalidates_contract'] is False
assert p['next_stage']=='phase-1-execution-control-failure-paths-runtime-boundary-design' and p['pause_safe'] is False
PY
then pass 'contract policy freezes all four failure paths with fail-closed, non-mutating runtime requirements'; else fail 'step-179 contract semantic assertions failed'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'execution-control-failure-paths'* && $normalized_doc == *'real noninteractive cron context'* && $normalized_doc == *'no package or boot mutation'* && $normalized_doc == *'phase-1-execution-control-failure-paths-runtime-boundary-design'* ]]; then pass 'reference document records the frozen four-scenario safety contract and next stage'; else fail 'step-179 reference document is incomplete'; fi
if grep -Fq 'Phase 1 step 179 execution-control failure-paths contract freeze' "$CHANGELOG" && grep -Fq 'phase-1-execution-control-failure-paths-runtime-boundary-design' "$CHANGELOG"; then pass 'CHANGELOG records step 179'; else fail 'CHANGELOG does not record step 179'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-179 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-179 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-179 helper contains a network client command'; else pass 'step-179 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
