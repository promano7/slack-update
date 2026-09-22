#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
HELPER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review.sh"
DOC="$repo_root/docs/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review.md"
POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review-policy.json"
RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review.tsv"
DESIGN_HELPER="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-design.sh"
DESIGN_DOC="$repo_root/docs/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-design.md"
DESIGN_HARNESS="$repo_root/tests/reference/test-phase-1-execution-control-failure-paths-runtime-executor-implementation-design-harness.sh"
DESIGN_POLICY="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-design-policy.json"
DESIGN_RECORD="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-design.tsv"
CHANGELOG="$repo_root/CHANGELOG.md"
PASS_COUNT=0
FAIL_COUNT=0
pass() { printf 'PASS: %s\n' "$1"; PASS_COUNT=$((PASS_COUNT+1)); }
fail() { printf 'FAIL: %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
regular() { [[ -f $1 && ! -L $1 ]]; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }

for pair in \
 "$HELPER|step-184 authorization-review helper" \
 "$DOC|step-184 reference document" \
 "$POLICY|step-184 authorization-review policy" \
 "$RECORD|step-184 authorization-review record" \
 "$DESIGN_HELPER|accepted step-183 design helper" \
 "$DESIGN_DOC|accepted step-183 design document" \
 "$DESIGN_HARNESS|accepted step-183 design harness" \
 "$DESIGN_POLICY|accepted step-183 design policy" \
 "$DESIGN_RECORD|accepted step-183 design record"; do
    file=${pair%%|*}; label=${pair#*|}
    if regular "$file"; then pass "$label is a regular non-symlink file"; else fail "$label is missing or unsafe"; fi
done

[[ $(sha "$HELPER") == '401860d40fd47942d4f75838d2f12c0123979eea10a1a1097224fcca4931293b' ]] && pass 'step-184 helper has the exact reviewed SHA-256' || fail 'step-184 helper SHA-256 mismatch'
[[ $(sha "$DOC") == '848fbbe15be862b51f72d961c69644e554cdd535a094d153fb03b1a4bad4ccaf' ]] && pass 'step-184 reference document has the exact reviewed SHA-256' || fail 'step-184 reference document SHA-256 mismatch'
[[ $(sha "$POLICY") == '16ca30b51e7f2875f45587611b7d7b4bbfdaa490a1f36b1adb96d12f34df67a3' ]] && pass 'step-184 policy has the exact reviewed SHA-256' || fail 'step-184 policy SHA-256 mismatch'
[[ $(sha "$RECORD") == '2c366f62c26f1af7e62d574037da584365c2e17aa7e74bc489d4952b5767c762' ]] && pass 'step-184 record has the exact reviewed SHA-256' || fail 'step-184 record SHA-256 mismatch'
[[ $(sha "$DESIGN_HELPER") == '3e4db3a9e945b1dc070daff1924a4b0e2344060251edb82ab5622c17e6602d0d' ]] && pass 'accepted step-183 design helper has the exact reviewed SHA-256' || fail 'accepted step-183 design helper SHA-256 mismatch'
[[ $(sha "$DESIGN_DOC") == '46c4b15dfd81feea48cccdc2412a8f5ff4bcd4c09193c38fb69fdfd450cd675d' ]] && pass 'accepted step-183 design document has the exact reviewed SHA-256' || fail 'accepted step-183 design document SHA-256 mismatch'
[[ $(sha "$DESIGN_HARNESS") == '5503709fa2dbb0bc62f818c4406fb52c0dd9b974ff3c0307680b31cb45df355d' ]] && pass 'accepted step-183 design harness has the exact reviewed SHA-256' || fail 'accepted step-183 design harness SHA-256 mismatch'
[[ $(sha "$DESIGN_POLICY") == 'f651e072223868a8eda3339834d18e51884e95faf9db92dafb5c203ee9fc90f5' ]] && pass 'accepted step-183 design policy has the exact reviewed SHA-256' || fail 'accepted step-183 design policy SHA-256 mismatch'
[[ $(sha "$DESIGN_RECORD") == 'a8a4539fb9cb37f1350e8cf79d65469350283e00c968e0691172453cc9bd6a96' ]] && pass 'accepted step-183 design record has the exact reviewed SHA-256' || fail 'accepted step-183 design record SHA-256 mismatch'

bash -n "$HELPER" && pass 'step-184 helper is shell-syntax valid' || fail 'step-184 helper has invalid shell syntax'
"$HELPER" --help >/dev/null 2>&1 && pass 'step-184 helper exposes a non-mutating help boundary' || fail 'step-184 helper help failed'
if "$HELPER" --unknown >/dev/null 2>&1; then fail 'step-184 helper accepts an unknown option'; else pass 'step-184 helper rejects unknown options'; fi
python3 -m json.tool "$POLICY" >/dev/null && pass 'step-184 authorization-review policy is valid JSON' || fail 'step-184 policy is invalid JSON'

if python3 - "$POLICY" <<'INNERPY'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['schema']==1 and p['scenario']=='phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review' and p['review_only'] is True
a=p['accepted_implementation_design']
assert a['step']==183 and a['family']=='execution-control-failure-paths' and a['scenario_count']==4
assert a['payload_form']=='single-self-contained-shell-script' and a['runtime_acknowledgement']=='--execute-runtime-validation'
b=p['accepted_target_binding']
assert b['hostname_fqdn']=='vbox-slackcurrent.vbox-slackcurrent.org' and b['uname_release']=='6.18.45'
assert b['boot_id']=='cb85100b-9993-4876-ab32-b2457ed0ac6d'
assert b['reference_script_sha256']=='086b28b42be3135ebf47a28c1fcd2e5652f8fdd261e696ad48e612a241edf4ea'
assert b['effective_config_sha256']=='4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
r=p['implementation_authorization_review']
assert r['state']=='accepted' and r['scope']=='controller-repository-only'
req=r['implementation_requirements']
assert req['generated_executor_must_be_single_self_contained_shell_script'] is True
assert req['generated_executor_must_revalidate_fqdn_kernel_and_boot_id_before_any_scenario'] is True
assert req['generated_executor_must_not_require_target_repository'] is True
assert req['repository_harness_must_not_contact_external_network'] is True
assert r['runtime_copy_to_target_authorized'] is False and r['runtime_execution_authorized'] is False
auth=p['authorization']
assert auth['runtime_executor_implementation_authorized'] is True
assert auth['repository_acceptance_harness_implementation_authorized'] is True
assert auth['runtime_executor_implementation_review_authorized_for_next_stage'] is True
for key in ('copy_executor_to_runtime_target_authorized','runtime_scenario_execution_authorized','repository_refresh_authorized','network_refresh_authorized','package_action_authorized','boot_action_authorized','reboot_authorized','phase_2_start_authorized'): assert auth[key] is False
assert p['machine_action_required'] is False
assert p['target_must_remain_on_frozen_boot_id']=='cb85100b-9993-4876-ab32-b2457ed0ac6d'
assert p['slackware_current_publication_invalidates_authorization_review'] is False
assert p['next_stage']=='phase-1-execution-control-failure-paths-runtime-executor-implementation' and p['pause_safe'] is False
INNERPY
then pass 'step-184 runtime-executor implementation authorization review completed successfully'; else fail 'step-184 semantic assertions failed'; fi

for line in \
 $'implementation_authorization_review_state\taccepted' \
 $'authorization_scope\tcontroller-repository-only' \
 $'payload_form\tsingle-self-contained-shell-script' \
 $'runtime_acknowledgement\t--execute-runtime-validation' \
 $'boot_id\tcb85100b-9993-4876-ab32-b2457ed0ac6d' \
 $'runtime_executor_implementation_authorized\tyes' \
 $'repository_acceptance_harness_implementation_authorized\tyes' \
 $'copy_executor_to_runtime_target_authorized\tno' \
 $'runtime_scenario_execution_authorized\tno' \
 $'machine_action_required\tno' \
 $'pause_safe\tno' \
 $'next_stage\tphase-1-execution-control-failure-paths-runtime-executor-implementation'; do
    grep -Fqx "$line" "$RECORD" && pass "record freezes: ${line%%$'\t'*}" || fail "record missing frozen row: $line"
done

regen=$(mktemp -d); trap 'rm -rf -- "$regen"' EXIT
if "$HELPER" --output-dir "$regen" >/dev/null 2>&1; then pass 'step-184 helper regenerates policy and record'; else fail 'step-184 helper regeneration failed'; fi
cmp -s "$POLICY" "$regen/phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review-policy.json" && pass 'step-184 helper reproduces the frozen policy exactly' || fail 'step-184 regenerated policy differs'
cmp -s "$RECORD" "$regen/phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review.tsv" && pass 'step-184 helper reproduces the frozen record exactly' || fail 'step-184 regenerated record differs'

if grep -Eq '\b(slackpkg|upgradepkg|installpkg|removepkg|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)\b' "$HELPER"; then fail 'step-184 helper contains a package, boot, reboot, or shutdown mutation command'; else pass 'step-184 helper contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '\b(curl|wget|rsync|scp|ssh|ping)\b' "$HELPER"; then fail 'step-184 helper contains a network client command'; else pass 'step-184 helper contains no network client command'; fi
if grep -Fq 'Phase 1 step 184 execution-control runtime-executor implementation authorization review' "$CHANGELOG"; then pass 'CHANGELOG records step 184'; else fail 'CHANGELOG does not record step 184'; fi
normalized_doc=$(tr '\n' ' ' < "$DOC" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'controller repository'* && $normalized_doc == *'--execute-runtime-validation'* && $normalized_doc == *'Copying the executor to the runtime VM remains unauthorized'* && $normalized_doc == *'runtime-executor-implementation'* ]]; then pass 'reference document records implementation-only authority and deferred runtime boundary'; else fail 'step-184 reference document is incomplete'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$( [[ $FAIL_COUNT -eq 0 ]] && printf PASS || printf FAIL )" "$PASS_COUNT" "$FAIL_COUNT"
[[ $FAIL_COUNT -eq 0 ]]
