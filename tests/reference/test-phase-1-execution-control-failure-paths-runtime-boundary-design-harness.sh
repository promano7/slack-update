#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-boundary-design.sh"
DOC="$repo_root/docs/reference/phase-1-execution-control-failure-paths-runtime-boundary-design.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-boundary-design-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-boundary-design.tsv"
STEP179_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-contract-freeze-policy.json"
STEP179_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-contract-freeze.tsv"
CHANGELOG="$repo_root/CHANGELOG.md"
PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
check_regular() { local file=$1 label=$2; if [[ -f $file && ! -L $file ]]; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi; }
check_hash() { local file=$1 expected=$2 label=$3 actual; if [[ ! -f $file || -L $file ]]; then fail "$label hash cannot be checked"; return; fi; actual=$(sha256sum -- "$file" | awk '{print $1}'); if [[ $actual == $expected ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label SHA-256 mismatch"; fi; }

for spec in \
    "$HELPER|step-180 boundary-design helper" \
    "$DOC|step-180 reference document" \
    "$POLICY|step-180 boundary-design policy" \
    "$RECORD|step-180 boundary-design record" \
    "$STEP179_POLICY|accepted step-179 contract policy" \
    "$STEP179_RECORD|accepted step-179 contract record"
do
    check_regular "${spec%%|*}" "${spec#*|}"
done
check_hash "$HELPER" 'abaea6bcb3fa132b1379ac8ca3e7ed3b28e77e21956a95f5cd1f019ac2f1b6f6' 'step-180 boundary-design helper'
check_hash "$DOC" '77614733431f6ceffb01e3c5527d196b4772ee25938b0b139bff145c82bd14b3' 'step-180 reference document'
check_hash "$POLICY" '63a1605b36cddbc12fb3e0b3b68a349435f2230348bf3be76c71cd04e1c84cf1' 'step-180 boundary-design policy'
check_hash "$RECORD" '0d4c3f5015da8f32bdb431d1246b5f670ace8cece2ccfc8331a69f73d87fcab1' 'step-180 boundary-design record'
check_hash "$STEP179_POLICY" '5ea897b193250dd99d9f7ac988cdd2fc95f1bc48df41c8d6189b6a689e1c1dd9' 'accepted step-179 contract policy'
check_hash "$STEP179_RECORD" '7a6ed7b1342f8d741debdc40de7d39bf1063fb84cb0e57e6f60f8e42db9f4bd6' 'accepted step-179 contract record'

if bash -n "$HELPER"; then pass 'step-180 boundary-design helper is shell-syntax valid'; else fail 'step-180 boundary-design helper has invalid shell syntax'; fi
if "$HELPER" --help >/dev/null 2>&1; then pass 'step-180 helper exposes a non-mutating help boundary'; else fail 'step-180 helper help boundary failed'; fi
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-180 helper accepts unknown options'; else pass 'step-180 helper rejects unknown options'; fi
if python3 -m json.tool "$POLICY" >/dev/null 2>&1; then pass 'step-180 boundary-design policy is valid JSON'; else fail 'step-180 boundary-design policy is invalid JSON'; fi

output=$("$HELPER" 2>&1); helper_rc=$?
if [[ $helper_rc -eq 0 ]]; then pass 'step-180 runtime-boundary design completed successfully'; else fail 'step-180 boundary-design helper failed'; printf '%s\n' "$output"; fi
expect_line() { local needle=$1 label=$2; if grep -Fqx "$needle" <<<"$output"; then pass "$label"; else fail "$label"; fi; }
expect_line $'accepted_contract_step\t179' 'design starts from accepted step 179'
expect_line $'selected_family\texecution-control-failure-paths' 'design preserves the selected execution-control family'
expect_line $'scenario_count\t4' 'design contains all four selected scenarios'
expect_line $'runtime_boundary_design_state\tfrozen' 'runtime-boundary design is frozen'
expect_line $'target_class\tslackware-current-runtime-validation-vm' 'target class remains Slackware-current validation VM'
expect_line $'target_binding_deferred\tyes' 'exact machine binding remains deferred'
expect_line $'planned_acceptance_executor_path\ttests/acceptance/reference/test-execution-control-failure-paths.sh' 'future acceptance executor path is frozen'
expect_line $'planned_execution_acknowledgement\t--execute-runtime-validation' 'future explicit execution acknowledgement is frozen'
expect_line $'required_network_isolation\ttemporary-network-namespace' 'network failure uses temporary namespace isolation'
expect_line $'missing_capability_action\tblock-without-installing-or-changing-the-target' 'missing runtime capability blocks without target changes'
expect_line $'repository_refresh_allowed\tno' 'repository refresh is forbidden by the design'
expect_line $'successful_network_access_allowed\tno' 'successful network access is forbidden by the design'
expect_line $'package_mutation_allowed\tno' 'package mutation is forbidden by the design'
expect_line $'boot_mutation_allowed\tno' 'boot mutation is forbidden by the design'
expect_line $'reboot_allowed\tno' 'reboot is forbidden by the design'
expect_line $'source_change_allowed_on_target\tno' 'source change on target is forbidden'
expect_line $'persistent_system_configuration_change_allowed\tno' 'persistent target configuration change is forbidden'
expect_line $'signal_set\tSIGINT,SIGTERM,SIGHUP' 'all three required signals remain in scope'
expect_line $'signal_expected_statuses\tSIGINT=130,SIGTERM=143,SIGHUP=129' 'signal statuses are frozen'
expect_line $'real_cron_required\tyes' 'cron scenario requires real cron'
expect_line $'root_crontab_exact_restore_required\tyes' 'root crontab must be restored exactly'
expect_line $'target_binding_review_authorized_for_next_stage\tyes' 'only next-stage target binding review is authorized'
expect_line $'runtime_executor_implementation_authorized\tno' 'runtime executor implementation is not authorized yet'
expect_line $'runtime_execution_authorized\tno' 'runtime execution is not authorized'
expect_line $'repository_refresh_authorized\tno' 'repository refresh authorization remains false'
expect_line $'network_refresh_authorized\tno' 'network refresh authorization remains false'
expect_line $'package_action_authorized\tno' 'package action is not authorized'
expect_line $'boot_action_authorized\tno' 'boot action is not authorized'
expect_line $'reboot_authorized\tno' 'reboot is not authorized'
expect_line $'phase_2_start_authorized\tno' 'Phase 2 is not authorized'
expect_line $'machine_action_required\tno' 'step 180 requires no machine action'
expect_line $'slackware_current_publication_invalidates_design\tno' 'later Slackware-current publication does not invalidate the design'
expect_line $'next_stage\tphase-1-execution-control-failure-paths-runtime-target-binding-review' 'next stage is target-binding review'
expect_line $'pause_safe\tno' 'step 180 is not the requested end-of-session strong safe pause'

if python3 - "$POLICY" "$STEP179_POLICY" <<'PY'
import json, sys
p=json.load(open(sys.argv[1],encoding='utf-8')); c=json.load(open(sys.argv[2],encoding='utf-8'))
assert c['contract']['state']=='frozen' and c['contract']['family']=='execution-control-failure-paths'
assert p['review_only'] is True and p['accepted_contract']['step']==179
b=p['runtime_boundary_design']
assert b['state']=='frozen' and b['target_class']=='slackware-current-runtime-validation-vm' and b['target_binding_deferred'] is True
assert b['planned_acceptance_executor_path']=='tests/acceptance/reference/test-execution-control-failure-paths.sh'
assert b['planned_execution_acknowledgement']=='--execute-runtime-validation'
assert b['missing_capability_action']=='block-without-installing-or-changing-the-target'
assert b['repository_refresh_allowed'] is False and b['successful_network_access_allowed'] is False
assert b['package_mutation_allowed'] is False and b['boot_mutation_allowed'] is False and b['reboot_allowed'] is False
assert b['source_change_allowed_on_target'] is False and b['persistent_system_configuration_change_allowed'] is False
assert 'unshare-network-namespace' in b['required_capabilities'] and 'running-crond' in b['required_capabilities']
items={x['id']:x for x in b['scenario_designs']}
assert set(items)=={'network-failure-before-repository-synchronization','simultaneous-execution-attempt','signals-during-safe-test-operations','cron-without-interactive-terminal'}
assert items['network-failure-before-repository-synchronization']['host_network_configuration_change'] is False
assert items['simultaneous-execution-attempt']['second_process_may_acquire_execution_lock'] is False
assert items['signals-during-safe-test-operations']['signals']==['SIGINT','SIGTERM','SIGHUP']
assert items['signals-during-safe-test-operations']['expected_statuses']=={'SIGINT':130,'SIGTERM':143,'SIGHUP':129}
assert items['cron-without-interactive-terminal']['real_cron_required'] is True
assert items['cron-without-interactive-terminal']['existing_root_crontab_must_be_backed_up_and_restored_exactly'] is True
assert len(b['pre_post_evidence'])==6 and len(b['cleanup_requirements'])==6
assert b['published_archive_path'].startswith('/home/promano/') and b['published_owner']=='promano:users' and b['published_mode']=='0600'
a=p['authorization']
assert a['target_binding_review_authorized_for_next_stage'] is True
for key in ('runtime_executor_implementation_authorized','runtime_execution_authorized','repository_refresh_authorized','network_refresh_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized'): assert a[key] is False
assert p['machine_action_required'] is False and p['slackware_current_publication_invalidates_design'] is False
assert p['next_stage']=='phase-1-execution-control-failure-paths-runtime-target-binding-review' and p['pause_safe'] is False
PY
then pass 'boundary policy freezes a non-mutating four-scenario runtime design with exact cleanup gates'; else fail 'step-180 boundary-design semantic assertions failed'; fi

normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'temporary network namespace'* && $normalized_doc == *'root crontab byte for byte'* && $normalized_doc == *'no repository synchronization can succeed'* && $normalized_doc == *'phase-1-execution-control-failure-paths-runtime-target-binding-review'* ]]; then pass 'reference document records isolation, exact cron restoration, and next-stage binding'; else fail 'step-180 reference document is incomplete'; fi
if grep -Fq 'Phase 1 step 180 execution-control failure-paths runtime-boundary design' "$CHANGELOG" && grep -Fq 'phase-1-execution-control-failure-paths-runtime-target-binding-review' "$CHANGELOG"; then pass 'CHANGELOG records step 180'; else fail 'CHANGELOG does not record step 180'; fi
if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-180 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-180 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh)\b' "$HELPER"; then fail 'step-180 helper contains a network client command'; else pass 'step-180 helper contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
