#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
HELPER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-freeze.sh"
DOC="$repo_root/docs/reference/phase-1-execution-control-failure-paths-runtime-target-binding-freeze.md"
POLICY="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-target-binding-freeze-policy.json"
RECORD="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-target-binding-freeze.tsv"
REVIEW_HELPER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-review.sh"
REVIEW_PROBE="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-probe.sh"
REVIEW_POLICY="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-target-binding-review-policy.json"
REVIEW_RECORD="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-target-binding-review.tsv"
CHANGELOG="$repo_root/CHANGELOG.md"
PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
regular() { [[ -f $1 && ! -L $1 ]]; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }

for pair in  "$HELPER|step-182 target-binding freeze helper"  "$DOC|step-182 reference document"  "$POLICY|step-182 target-binding freeze policy"  "$RECORD|step-182 target-binding freeze record"  "$REVIEW_HELPER|accepted step-181-r1 review helper"  "$REVIEW_PROBE|accepted step-181-r1 standalone probe"  "$REVIEW_POLICY|accepted step-181-r1 review policy"  "$REVIEW_RECORD|accepted step-181-r1 review record"; do
    file=${pair%%|*}; label=${pair#*|}
    if regular "$file"; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
done

[[ $(sha "$HELPER") == 'd3ad25453035af04f7f7c25f886ddbab73cc983ab5a6a4e86d42ff0476a34e5f' ]] && pass 'step-182 helper has the exact reviewed SHA-256' || fail 'step-182 helper SHA-256 mismatch'
[[ $(sha "$DOC") == 'f06aeb242922c7f23bc02b34b7fa7ddedc13d5753bf994586d61b8bbd6283a18' ]] && pass 'step-182 reference document has the exact reviewed SHA-256' || fail 'step-182 reference document SHA-256 mismatch'
[[ $(sha "$POLICY") == '2d14aef443f78ac3982538dc6cdb53d844cb987459ee824db4cf8d7b3c77f092' ]] && pass 'step-182 policy has the exact reviewed SHA-256' || fail 'step-182 policy SHA-256 mismatch'
[[ $(sha "$RECORD") == 'ca54d25b07938c9dfc9240f670fa0a5d03b47c35dd3e133e0a7fe8305eea2f49' ]] && pass 'step-182 record has the exact reviewed SHA-256' || fail 'step-182 record SHA-256 mismatch'
[[ $(sha "$REVIEW_HELPER") == '32d1e0865c2ae733e2ee7caccc686684d257fcfda0d0c1e64da4c50b40312490' ]] && pass 'accepted step-181-r1 review helper has the exact reviewed SHA-256' || fail 'accepted step-181-r1 review helper SHA-256 mismatch'
[[ $(sha "$REVIEW_PROBE") == 'fbf840f19c51aaa29c3d6fb1eb00d6ca87bf2b594b91cb4524d31e4853fbc82b' ]] && pass 'accepted step-181-r1 standalone probe has the exact reviewed SHA-256' || fail 'accepted step-181-r1 standalone probe SHA-256 mismatch'
[[ $(sha "$REVIEW_POLICY") == '2a5f0289be049539de65ab08a0a8a585717ec0f79cc830872074e20cc86f4e48' ]] && pass 'accepted step-181-r1 review policy has the exact reviewed SHA-256' || fail 'accepted step-181-r1 review policy SHA-256 mismatch'
[[ $(sha "$REVIEW_RECORD") == 'ce7ab5b5ded166bb8b56ffbfe72901acfa22f1cb86130b42b536e1f68c25c3bf' ]] && pass 'accepted step-181-r1 review record has the exact reviewed SHA-256' || fail 'accepted step-181-r1 review record SHA-256 mismatch'

bash -n "$HELPER" && pass 'step-182 helper is shell-syntax valid' || fail 'step-182 helper has invalid shell syntax'
"$HELPER" --help >/dev/null 2>&1 && pass 'step-182 helper exposes a non-mutating help boundary' || fail 'step-182 helper help failed'
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-182 helper accepts an unknown option'; else pass 'step-182 helper rejects unknown options'; fi
python3 -m json.tool "$POLICY" >/dev/null && pass 'step-182 target-binding freeze policy is valid JSON' || fail 'step-182 policy is invalid JSON'

if python3 - "$POLICY" <<'INNERPY'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['schema']==1 and p['scenario']=='phase-1-execution-control-failure-paths-runtime-target-binding-freeze' and p['review_only'] is True
assert p['accepted_target_binding_review']['step']==181 and p['accepted_target_binding_review']['revision']=='r1-standalone-probe'
b=p['runtime_target_binding']
assert b['state']=='frozen' and b['observation_status']=='PASS'
assert b['hostname_fqdn']=='vbox-slackcurrent.vbox-slackcurrent.org'
assert b['uname_release']=='6.18.45' and b['slackware_version']=='Slackware 15.0+'
assert b['boot_id']=='cb85100b-9993-4876-ab32-b2457ed0ac6d'
assert b['reference_script_sha256']=='086b28b42be3135ebf47a28c1fcd2e5652f8fdd261e696ad48e612a241edf4ea'
assert b['effective_config_sha256']=='4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba' and b['probe_sha256']=='fbf840f19c51aaa29c3d6fb1eb00d6ca87bf2b594b91cb4524d31e4853fbc82b'
assert b['target_repository_required'] is False
for v in b['capabilities'].values(): assert v=='PASS'
for key in ('repository_refresh_performed','external_network_access_performed','package_mutation_performed','boot_mutation_performed','system_restart_performed','persistent_configuration_change_performed'): assert b[key] is False
v=b['validity_requirements']
assert v['same_boot_id_required_before_runtime_execution'] is True and v['same_running_kernel_required_before_runtime_execution'] is True
assert v['later_slackware_current_publication_invalidates_binding'] is False
assert v['target_reboot_invalidates_binding'] is True and v['running_kernel_change_invalidates_binding'] is True and v['controller_reference_or_config_change_invalidates_binding'] is True
a=p['authorization']
assert a['runtime_executor_implementation_design_authorized_for_next_stage'] is True
for key in ('runtime_executor_implementation_authorized','runtime_scenario_execution_authorized','repository_refresh_authorized','network_refresh_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized'): assert a[key] is False
assert p['machine_action_required'] is False and p['slackware_current_publication_invalidates_binding'] is False
assert p['next_stage']=='phase-1-execution-control-failure-paths-runtime-executor-implementation-design' and p['pause_safe'] is False
INNERPY
then pass 'step-182 target binding freeze completed successfully'; else fail 'step-182 target-binding semantic assertions failed'; fi

for line in  $'runtime_target_binding_state\tfrozen'  $'observation_status\tPASS'  $'hostname_fqdn\tvbox-slackcurrent.vbox-slackcurrent.org'  $'uname_release\t6.18.45'  $'boot_id\tcb85100b-9993-4876-ab32-b2457ed0ac6d'  $'reference_script_sha256\t086b28b42be3135ebf47a28c1fcd2e5652f8fdd261e696ad48e612a241edf4ea'  $'effective_config_sha256\t4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'  $'probe_sha256\tfbf840f19c51aaa29c3d6fb1eb00d6ca87bf2b594b91cb4524d31e4853fbc82b'  $'target_reboot_invalidates_binding\tyes'  $'runtime_scenario_execution_authorized\tno'  $'next_stage\tphase-1-execution-control-failure-paths-runtime-executor-implementation-design'; do
    grep -Fqx "$line" "$RECORD" && pass "record freezes: ${line%%$'\t'*}" || fail "record missing frozen row: $line"
done

regen=$(mktemp -d); trap 'rm -rf -- "$regen"' EXIT
if "$HELPER" --output-dir "$regen" >/dev/null 2>&1; then pass 'step-182 helper regenerates policy and record'; else fail 'step-182 helper regeneration failed'; fi
cmp -s "$POLICY" "$regen/phase-1-execution-control-failure-paths-runtime-target-binding-freeze-policy.json" && pass 'step-182 helper reproduces the frozen policy exactly' || fail 'step-182 regenerated policy differs'
cmp -s "$RECORD" "$regen/phase-1-execution-control-failure-paths-runtime-target-binding-freeze.tsv" && pass 'step-182 helper reproduces the frozen record exactly' || fail 'step-182 regenerated record differs'

if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-182 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-182 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh|ping)\b' "$HELPER"; then fail 'step-182 helper contains a network client command'; else pass 'step-182 helper contains no network client command'; fi
if grep -Fq 'Phase 1 step 182 execution-control runtime target-binding freeze' "$CHANGELOG"; then pass 'CHANGELOG records step 182'; else fail 'CHANGELOG does not record step 182'; fi
normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'cb85100b-9993-4876-ab32-b2457ed0ac6d'* && $normalized_doc == *'6.18.45'* && $normalized_doc == *'target reboot'* && $normalized_doc == *'runtime-executor-implementation-design'* ]]; then pass 'reference document records exact binding, invalidation rule, and next stage'; else fail 'step-182 reference document is incomplete'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
