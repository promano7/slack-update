#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-design.sh"
DOC="$repo_root/docs/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-design.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-design-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-design.tsv"
BIND_HELPER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-freeze.sh"
BIND_DOC="$repo_root/docs/reference/phase-1-execution-control-failure-paths-runtime-target-binding-freeze.md"
BIND_HARNESS="$repo_root/tests/reference/test-phase-1-execution-control-failure-paths-runtime-target-binding-freeze-harness.sh"
BIND_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-target-binding-freeze-policy.json"
BIND_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-target-binding-freeze.tsv"
CHANGELOG="$repo_root/CHANGELOG.md"
PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
regular() { [[ -f $1 && ! -L $1 ]]; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }

for pair in \
 "$HELPER|step-183 implementation-design helper" \
 "$DOC|step-183 reference document" \
 "$POLICY|step-183 implementation-design policy" \
 "$RECORD|step-183 implementation-design record" \
 "$BIND_HELPER|accepted step-182 binding helper" \
 "$BIND_DOC|accepted step-182 binding document" \
 "$BIND_HARNESS|accepted step-182 binding harness" \
 "$BIND_POLICY|accepted step-182 binding policy" \
 "$BIND_RECORD|accepted step-182 binding record"; do
    file=${pair%%|*}; label=${pair#*|}
    if regular "$file"; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
done

[[ $(sha "$HELPER") == '3e4db3a9e945b1dc070daff1924a4b0e2344060251edb82ab5622c17e6602d0d' ]] && pass 'step-183 helper has the exact reviewed SHA-256' || fail 'step-183 helper SHA-256 mismatch'
[[ $(sha "$DOC") == '46c4b15dfd81feea48cccdc2412a8f5ff4bcd4c09193c38fb69fdfd450cd675d' ]] && pass 'step-183 reference document has the exact reviewed SHA-256' || fail 'step-183 reference document SHA-256 mismatch'
[[ $(sha "$POLICY") == 'f651e072223868a8eda3339834d18e51884e95faf9db92dafb5c203ee9fc90f5' ]] && pass 'step-183 policy has the exact reviewed SHA-256' || fail 'step-183 policy SHA-256 mismatch'
[[ $(sha "$RECORD") == 'a8a4539fb9cb37f1350e8cf79d65469350283e00c968e0691172453cc9bd6a96' ]] && pass 'step-183 record has the exact reviewed SHA-256' || fail 'step-183 record SHA-256 mismatch'
[[ $(sha "$BIND_HELPER") == 'd3ad25453035af04f7f7c25f886ddbab73cc983ab5a6a4e86d42ff0476a34e5f' ]] && pass 'accepted step-182 binding helper has the exact reviewed SHA-256' || fail 'accepted step-182 binding helper SHA-256 mismatch'
[[ $(sha "$BIND_DOC") == 'f06aeb242922c7f23bc02b34b7fa7ddedc13d5753bf994586d61b8bbd6283a18' ]] && pass 'accepted step-182 binding document has the exact reviewed SHA-256' || fail 'accepted step-182 binding document SHA-256 mismatch'
[[ $(sha "$BIND_HARNESS") == '054f7eff3e35743c5660b524178b26918d0e7fd2e8bed115083d568a38bce2b0' ]] && pass 'accepted step-182 binding harness has the exact reviewed SHA-256' || fail 'accepted step-182 binding harness SHA-256 mismatch'
[[ $(sha "$BIND_POLICY") == '2d14aef443f78ac3982538dc6cdb53d844cb987459ee824db4cf8d7b3c77f092' ]] && pass 'accepted step-182 binding policy has the exact reviewed SHA-256' || fail 'accepted step-182 binding policy SHA-256 mismatch'
[[ $(sha "$BIND_RECORD") == 'ca54d25b07938c9dfc9240f670fa0a5d03b47c35dd3e133e0a7fe8305eea2f49' ]] && pass 'accepted step-182 binding record has the exact reviewed SHA-256' || fail 'accepted step-182 binding record SHA-256 mismatch'

bash -n "$HELPER" && pass 'step-183 helper is shell-syntax valid' || fail 'step-183 helper has invalid shell syntax'
"$HELPER" --help >/dev/null 2>&1 && pass 'step-183 helper exposes a non-mutating help boundary' || fail 'step-183 helper help failed'
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-183 helper accepts an unknown option'; else pass 'step-183 helper rejects unknown options'; fi
python3 -m json.tool "$POLICY" >/dev/null && pass 'step-183 implementation-design policy is valid JSON' || fail 'step-183 policy is invalid JSON'

if python3 - "$POLICY" <<'INNERPY'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['schema']==1 and p['scenario']=='phase-1-execution-control-failure-paths-runtime-executor-implementation-design' and p['review_only'] is True
b=p['accepted_target_binding']
assert b['step']==182 and b['hostname_fqdn']=='vbox-slackcurrent.vbox-slackcurrent.org'
assert b['uname_release']=='6.18.45' and b['boot_id']=='cb85100b-9993-4876-ab32-b2457ed0ac6d'
assert b['reference_script_sha256']=='086b28b42be3135ebf47a28c1fcd2e5652f8fdd261e696ad48e612a241edf4ea'
assert b['effective_config_sha256']=='4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
d=p['runtime_executor_implementation_design']
assert d['state']=='frozen' and d['scenario_count']==4 and d['target_requires_repository'] is False
assert d['payload_form']=='single-self-contained-shell-script' and d['runtime_acknowledgement']=='--execute-runtime-validation'
g=d['pre_execution_binding_gate']
assert g['same_hostname_fqdn_required'] and g['same_uname_release_required'] and g['same_boot_id_required']
r=d['runtime_config_derivation']
assert r['allowed_overrides']==['core.work_dir','core.log_dir','core.lock_file'] and r['all_other_configuration_values_must_remain_identical'] is True
assert d['scenario_implementations'][1]['expected_second_exit_code']==6
assert d['scenario_implementations'][2]['signals']=={'SIGINT':130,'SIGTERM':143,'SIGHUP':129}
assert d['scenario_implementations'][3]['real_running_crond_required'] is True and d['scenario_implementations'][3]['maximum_wait_seconds']==90
for value in d['global_mutation_guards'].values(): assert value is False
a=p['authorization']
assert a['runtime_executor_implementation_authorization_review_authorized_for_next_stage'] is True
for key in ('runtime_executor_implementation_authorized','runtime_scenario_execution_authorized','repository_refresh_authorized','network_refresh_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized'): assert a[key] is False
assert p['machine_action_required'] is False and p['slackware_current_publication_invalidates_design'] is False
assert p['next_stage']=='phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review' and p['pause_safe'] is False
INNERPY
then pass 'step-183 runtime-executor implementation design completed successfully'; else fail 'step-183 semantic assertions failed'; fi

for line in \
 $'runtime_executor_implementation_design_state\tfrozen' \
 $'target_requires_repository\tno' \
 $'payload_form\tsingle-self-contained-shell-script' \
 $'runtime_acknowledgement\t--execute-runtime-validation' \
 $'boot_id\tcb85100b-9993-4876-ab32-b2457ed0ac6d' \
 $'runtime_config_override_count\t3' \
 $'simultaneous_second_exit_code\t6' \
 $'signal_sigint_exit_code\t130' \
 $'signal_sigterm_exit_code\t143' \
 $'signal_sighup_exit_code\t129' \
 $'cron_real_context_required\tyes' \
 $'runtime_executor_implementation_authorized\tno' \
 $'runtime_scenario_execution_authorized\tno' \
 $'next_stage\tphase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review'; do
    grep -Fqx "$line" "$RECORD" && pass "record freezes: ${line%%$'\t'*}" || fail "record missing frozen row: $line"
done

regen=$(mktemp -d); trap 'rm -rf -- "$regen"' EXIT
if "$HELPER" --output-dir "$regen" >/dev/null 2>&1; then pass 'step-183 helper regenerates policy and record'; else fail 'step-183 helper regeneration failed'; fi
cmp -s "$POLICY" "$regen/phase-1-execution-control-failure-paths-runtime-executor-implementation-design-policy.json" && pass 'step-183 helper reproduces the frozen policy exactly' || fail 'step-183 regenerated policy differs'
cmp -s "$RECORD" "$regen/phase-1-execution-control-failure-paths-runtime-executor-implementation-design.tsv" && pass 'step-183 helper reproduces the frozen record exactly' || fail 'step-183 regenerated record differs'

if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-183 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-183 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh|ping)\b' "$HELPER"; then fail 'step-183 helper contains a network client command'; else pass 'step-183 helper contains no network client command'; fi
if grep -Fq 'Phase 1 step 183 execution-control runtime-executor implementation design' "$CHANGELOG"; then pass 'CHANGELOG records step 183'; else fail 'CHANGELOG does not record step 183'; fi
normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'single self-contained shell payload'* && $normalized_doc == *'core.work_dir'* && $normalized_doc == *'SIGTERM `143`'* && $normalized_doc == *'runtime-executor-implementation-authorization-review'* ]]; then pass 'reference document records standalone payload, safe derivation, signal contract, and next stage'; else fail 'step-183 reference document is incomplete'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
