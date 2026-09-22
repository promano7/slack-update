#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
REPO_ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd -P)
HELPER="$REPO_ROOT/tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-review.sh"
PROBE="$REPO_ROOT/tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-probe.sh"
DOC="$REPO_ROOT/docs/reference/phase-1-execution-control-failure-paths-runtime-target-binding-review.md"
POLICY="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-target-binding-review-policy.json"
RECORD="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-target-binding-review.tsv"
STEP180_POLICY="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-boundary-design-policy.json"
STEP180_RECORD="$REPO_ROOT/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-boundary-design.tsv"
CHANGELOG="$REPO_ROOT/CHANGELOG.md"

check_regular() { local file=$1 label=$2; if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi; }
check_hash() { local file=$1 expected=$2 label=$3 actual; actual=$(sha256sum -- "$file" | awk '{print $1}'); if [[ $actual == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi; }

for spec in \
    "$HELPER|step-181 target-binding review helper" \
    "$PROBE|step-181 target-binding probe" \
    "$DOC|step-181 reference document" \
    "$POLICY|step-181 target-binding review policy" \
    "$RECORD|step-181 target-binding review record" \
    "$STEP180_POLICY|accepted step-180 boundary-design policy" \
    "$STEP180_RECORD|accepted step-180 boundary-design record"
do check_regular "${spec%%|*}" "${spec#*|}"; done
check_hash "$HELPER" 'b186507eb8e94312e6360142e1dc797b63ba46a55f5d3a7b2aa729b6fd5ccd72' 'step-181 target-binding review helper'
check_hash "$PROBE" 'a2f54a55ff191cec920b067130c0e4520d4987b01755e9170762f1738656ecfe' 'step-181 target-binding probe'
check_hash "$DOC" '80fc168cf104afc10729b85215cc0d6098dfde1894d52b7e852a227e0f3056a3' 'step-181 reference document'
check_hash "$POLICY" '38d595562c77071df235f788b0bae08b5a7ceb0112265b485226c6307772647f' 'step-181 target-binding review policy'
check_hash "$RECORD" '6325a4e1b39fa705ce0d34a464f4971380f89fa6580740d671769dc3991295b0' 'step-181 target-binding review record'
check_hash "$STEP180_POLICY" '63a1605b36cddbc12fb3e0b3b68a349435f2230348bf3be76c71cd04e1c84cf1' 'accepted step-180 boundary-design policy'
check_hash "$STEP180_RECORD" '0d4c3f5015da8f32bdb431d1246b5f670ace8cece2ccfc8331a69f73d87fcab1' 'accepted step-180 boundary-design record'

if bash -n "$HELPER"; then pass 'step-181 target-binding review helper is shell-syntax valid'; else fail 'step-181 helper has invalid shell syntax'; fi
if bash -n "$PROBE"; then pass 'step-181 target-binding probe is shell-syntax valid'; else fail 'step-181 probe has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-181 helper exposes a non-mutating help boundary'; else fail 'step-181 helper help boundary failed'; fi
if "$PROBE" --help >/dev/null 2>&1; then pass 'step-181 probe exposes a non-mutating help boundary'; else fail 'step-181 probe help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-181 helper accepts unknown options'; else pass 'step-181 helper rejects unknown options'; fi
if "$PROBE" --unknown >/dev/null 2>&1; then fail 'step-181 probe accepts unknown options'; else pass 'step-181 probe rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-181 target-binding review policy is valid JSON'; else fail 'step-181 target-binding review policy is invalid JSON'; fi

output=$("$HELPER" 2>&1); helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-181 target-binding review completed successfully'; else fail 'step-181 target-binding review helper failed'; printf '%s\n' "$output"; fi
expect_line() { local needle=$1 label=$2; if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi; }
expect_line $'accepted_runtime_boundary_design_step\t180' 'review starts from accepted step 180'
expect_line $'selected_family\texecution-control-failure-paths' 'review preserves the selected execution-control family'
expect_line $'scenario_count\t4' 'review preserves all four scenarios'
expect_line $'target_binding_review_state\truntime-observation-required' 'target binding requires runtime observation'
expect_line $'target_class\tslackware-current-runtime-validation-vm' 'target class remains Slackware-current validation VM'
expect_line $'expected_hostname_fqdn\tvbox-slackcurrent.vbox-slackcurrent.org' 'expected VM FQDN is frozen'
expect_line $'binding_probe_sha256\ta2f54a55ff191cec920b067130c0e4520d4987b01755e9170762f1738656ecfe' 'runtime probe identity is frozen'
expect_line $'probe_execution\troot-via-sudo' 'probe privilege boundary is frozen'
expect_line $'reference_script_path\ttools/reference/slack-update-reference.sh' 'reference script identity input is frozen'
expect_line $'effective_config_path\tdata/config/slack-update.conf' 'effective config identity input is frozen'
expect_line $'repository_refresh_allowed\tno' 'repository refresh remains forbidden'
expect_line $'successful_external_network_access_required\tno' 'external network access is not required'
expect_line $'package_mutation_allowed\tno' 'package mutation remains forbidden'
expect_line $'boot_mutation_allowed\tno' 'boot mutation remains forbidden'
expect_line $'reboot_allowed\tno' 'reboot remains forbidden'
expect_line $'persistent_system_configuration_change_allowed\tno' 'persistent target changes remain forbidden'
expect_line $'runtime_target_observation_authorized\tyes' 'read-only target observation is authorized'
expect_line $'target_binding_freeze_authorized_after_successful_observation\tyes' 'successful observation may proceed to binding freeze'
expect_line $'runtime_executor_implementation_authorized\tno' 'runtime executor implementation remains unauthorized'
expect_line $'runtime_scenario_execution_authorized\tno' 'runtime scenarios remain unauthorized'
expect_line $'repository_refresh_authorized\tno' 'repository refresh authorization remains false'
expect_line $'network_refresh_authorized\tno' 'network refresh authorization remains false'
expect_line $'package_action_authorized\tno' 'package action is not authorized'
expect_line $'boot_action_authorized\tno' 'boot action is not authorized'
expect_line $'reboot_authorized\tno' 'reboot is not authorized'
expect_line $'phase_2_start_authorized\tno' 'Phase 2 is not authorized'
expect_line $'machine_action_required\tyes' 'step 181 requires the read-only VM observation'
expect_line $'machine_action_type\tread-only-target-binding-observation' 'machine action is limited to binding observation'
expect_line $'slackware_current_publication_invalidates_review\tno' 'later Slackware-current publication does not invalidate this review'
expect_line $'next_stage\tphase-1-execution-control-failure-paths-runtime-target-binding-freeze' 'next stage is target-binding freeze'
expect_line $'pause_safe\tno' 'step 181 is not the requested end-of-session strong safe pause'

if python3 - "$POLICY" <<'INNERPY'
import json, sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['review_only'] is True and p['accepted_runtime_boundary_design']['step']==180
b=p['target_binding_review']
assert b['state']=='runtime-observation-required'
assert b['expected_hostname_fqdn']=='vbox-slackcurrent.vbox-slackcurrent.org'
assert b['binding_probe_sha256']=='a2f54a55ff191cec920b067130c0e4520d4987b01755e9170762f1738656ecfe'
assert b['reference_script_path']=='tools/reference/slack-update-reference.sh'
assert b['effective_config_path']=='data/config/slack-update.conf'
assert b['repository_refresh_allowed'] is False and b['successful_external_network_access_required'] is False
assert b['package_mutation_allowed'] is False and b['boot_mutation_allowed'] is False and b['reboot_allowed'] is False
assert b['persistent_system_configuration_change_allowed'] is False
assert 'unshare-network-namespace' in b['required_capability_observations'] and 'running-crond' in b['required_capability_observations']
a=p['authorization']
assert a['runtime_target_observation_authorized'] is True and a['target_binding_freeze_authorized_after_successful_observation'] is True
for key in ('runtime_executor_implementation_authorized','runtime_scenario_execution_authorized','repository_refresh_authorized','network_refresh_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized'): assert a[key] is False
assert p['machine_action_required'] is True and p['machine_action_type']=='read-only-target-binding-observation'
assert p['next_stage']=='phase-1-execution-control-failure-paths-runtime-target-binding-freeze' and p['pause_safe'] is False
INNERPY
then pass 'target-binding policy freezes only the read-only observation gate'; else fail 'step-181 target-binding semantic assertions failed'; fi

if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$PROBE"; then fail 'step-181 probe contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-181 probe contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh|ping)\b' "$PROBE"; then fail 'step-181 probe contains a network client command'; else pass 'step-181 probe contains no network client command'; fi
if grep -Eq '\b(crontab[[:space:]]+(-e|-r)|crontab[[:space:]]+[^-])\b' "$PROBE"; then fail 'step-181 probe contains a mutating crontab operation'; else pass 'step-181 probe only reads crontab state'; fi
if grep -Fq 'unshare --net -- true' "$PROBE"; then pass 'step-181 probe network-namespace check is bounded to true'; else fail 'step-181 probe network-namespace capability check is not frozen'; fi
if grep -Fq 'Phase 1 step 181 execution-control failure-paths runtime target-binding review' "$CHANGELOG" && grep -Fq 'phase-1-execution-control-failure-paths-runtime-target-binding-freeze' "$CHANGELOG"; then pass 'CHANGELOG records step 181'; else fail 'CHANGELOG does not record step 181'; fi
normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'vbox-slackcurrent.vbox-slackcurrent.org'* && $normalized_doc == *'unshare --net'* && $normalized_doc == *'binding_status'* && $normalized_doc == *'runtime-target-binding-freeze'* ]]; then pass 'reference document records target, bounded probe, and next binding-freeze gate'; else fail 'step-181 reference document is incomplete'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
