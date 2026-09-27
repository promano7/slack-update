#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
base='phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review'
helper="$repo_root/tools/reference/${base}.sh"
probe="$repo_root/tools/reference/${base}-probe.sh"
doc="$repo_root/docs/reference/${base}.md"
policy="$acc/${base}-policy.json"
record="$acc/${base}.tsv"
step221_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review.sh"
step221_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review.md"
step221_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review-harness.sh"
step221_policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review-policy.json"
step221_record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review.tsv"
step213_policy="$acc/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze-policy.json"
step217_policy="$acc/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review-policy.json"
step219_policy="$acc/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review-policy.json"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1" >&2; failures=$((failures+1)); }
check_file(){ [[ -f $1 && ! -L $1 ]] && pass "$2 is a regular non-symlink file" || fail "$2 is a regular non-symlink file"; }
check_sha(){ local actual; actual=$(sha256sum -- "$1" | awk '{print $1}'); [[ $actual == "$2" ]] && pass "$3 hash is frozen" || fail "$3 hash is frozen"; }
record_value(){ awk -F '\t' -v key="$1" '$1==key {print $2; exit}' "$record"; }

for spec in \
 "$helper|step-222 helper" "$probe|step-222 read-only probe" "$doc|step-222 reference document" "$policy|step-222 policy" "$record|step-222 record" \
 "$step221_helper|accepted step-221 helper" "$step221_doc|accepted step-221 document" "$step221_harness|accepted step-221 harness" \
 "$step221_policy|accepted step-221 policy" "$step221_record|accepted step-221 record" "$step213_policy|accepted step-213 policy" \
 "$step217_policy|historical step-217 policy" "$step219_policy|accepted step-219 policy" "$changelog|CHANGELOG"; do
    IFS='|' read -r path label <<<"$spec"
    check_file "$path" "$label"
done

check_sha "$step221_helper" '8efa5d798e28b42bbb8aa6adea08e6a35c0e462e549149cc836e3aff54f12bc6' 'accepted step-221 helper'
check_sha "$step221_doc" '373ebbd547cfa2ad2565c1aad1ac03d8566f3ee8c4e7509639278122fa0d34c0' 'accepted step-221 document'
check_sha "$step221_harness" '25de59dcb66a29f477e074d91266855c334d508cbda3d86e89c92f171528e47d' 'accepted step-221 harness'
check_sha "$step221_policy" '692b37f0694e25dbed809d44a1abfa478d9deb14c769cd8d9834dba110747de4' 'accepted step-221 policy'
check_sha "$step221_record" '497100fe5e6a6838cce16ea6688e57abdb7dc8f152f3bf127c63bcbb4755a25b' 'accepted step-221 record'
check_sha "$step213_policy" 'ae790c0b857f64961ed267c19b7db58f33f447c260e0f6659217ddeba32c18eb' 'accepted step-213 policy'
check_sha "$step217_policy" 'ac49b4b12a9478351761f948d66cca7afaa225a18a2e1e4a7834ed84bfd8bdec' 'historical step-217 policy'
check_sha "$step219_policy" '6a55e2e600dbb192cb7e14e9d3514a9a6dd7ab2ac019fd7478f84d631c670d75' 'accepted step-219 policy'

if bash -n "$helper"; then pass 'step-222 helper passes bash syntax validation'; else fail 'step-222 helper passes bash syntax validation'; fi
if bash -n "$probe"; then pass 'step-222 probe passes bash syntax validation'; else fail 'step-222 probe passes bash syntax validation'; fi
if "$helper" --help >/dev/null; then pass 'step-222 helper exposes non-mutating help'; else fail 'step-222 helper exposes non-mutating help'; fi
if "$probe" --help >/dev/null; then pass 'step-222 probe exposes non-mutating help'; else fail 'step-222 probe exposes non-mutating help'; fi
if "$helper" --bad >/dev/null 2>&1; then fail 'step-222 helper rejects unknown option'; else pass 'step-222 helper rejects unknown option'; fi
if "$probe" --bad >/dev/null 2>&1; then fail 'step-222 probe rejects unknown option'; else pass 'step-222 probe rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/output.tsv"; then pass 'step-222 helper executes successfully'; else fail 'step-222 helper executes successfully'; fi
cmp -s "$tmp/$(basename "$policy")" "$policy" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s "$tmp/$(basename "$record")" "$record" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'

probe_sha=$(sha256sum -- "$probe" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper" | awk '{print $1}')
if python3 - "$policy" "$probe_sha" "$helper_sha" <<'PY'
import json
import sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
probe_sha, helper_sha=sys.argv[2:4]
assert p['schema']==1
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review'
assert p['step']==222 and p['review_only'] is True and p['review_status']=='PASS'
a=p['accepted_resume_boundary']
assert a['step']==221 and a['strong_safe_pause_origin_step']==220
assert a['prior_target_binding_reusable'] is False
assert a['prior_runtime_authorization_reusable'] is False
assert a['prior_candidate_binding_reusable'] is False
h=p['historical_restored_baseline']
assert h['post_local_source_revalidation_step']==213
assert h['historical_runtime_authorization_step']==217
assert h['failed_runtime_characterization_step']==219
assert h['historical_runtime_authorization_reusable'] is False
assert h['expected_hostname_fqdn']=='vbox-slackcurrent.vbox-slackcurrent.org'
assert h['expected_uname_machine']=='x86_64'
assert h['expected_uname_release']=='6.18.45'
assert h['expected_package_database_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
assert h['expected_header_package_record']=='kernel-headers-6.18.45-x86-1'
assert h['expected_kernel_generic_record']=='kernel-generic-6.18.45-x86_64-1'
assert h['expected_staged_target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert h['expected_local_source_v1_tree_manifest_sha256']=='0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'
pr=p['preservation_contract']
assert pr['local_source_v1_must_be_preserved_unchanged'] is True
assert pr['failed_runtime_evidence_root_must_be_preserved_unchanged'] is True
assert pr['local_source_v1_may_be_modified_in_place'] is False
r=p['remediation_contract']
assert r['new_local_source_generation_name']=='local-source-v2'
assert r['design_authorized_now'] is False
assert r['build_authorized_now'] is False
assert r['runtime_validation_authorized_now'] is False
f=p['fresh_target_revalidation']
assert f['state']=='read-only-observation-authorized'
assert f['probe_sha256']==probe_sha
assert f['probe_execution']=='root-via-sudo'
assert f['acknowledgement']=='--observe-fresh-target-revalidation'
assert f['fresh_boot_id_required'] is True
assert f['previous_boot_id_match_required'] is False
assert f['previous_boot_id_must_not_be_used_as_binding'] is True
assert f['local_source_v1_tree_verification_required'] is True
assert f['local_source_v1_CHECKSUMS_md5_asc_must_remain_absent'] is True
assert f['failed_evidence_root_presence_required'] is True
assert f['failed_success_result_must_remain_absent'] is True
assert f['boot_artifacts_must_match_failed_preflight'] is True
assert f['slackpkg_state_must_match_failed_preflight'] is True
assert f['geninitrd_policy_must_match_failed_preflight'] is True
assert f['live_candidate_set_bound'] is False
for key in ['repository_refresh_allowed','network_access_allowed','package_mutation_allowed','slackpkg_mutation_allowed','boot_mutation_allowed','persistent_configuration_change_allowed','reboot_allowed']:
    assert f[key] is False
auth=p['authorization']
assert auth['target_observation_authorized'] is True
assert auth['fresh_target_revalidation_freeze_authorized_after_successful_observation'] is True
assert auth['probe_transport_copy_authorized'] is True
assert auth['future_work_requires_explicit_authorization'] is True
for key,value in auth.items():
    if key in {'target_observation_authorized','fresh_target_revalidation_freeze_authorized_after_successful_observation','probe_transport_copy_authorized','future_work_requires_explicit_authorization'}:
        assert value is True
    else:
        assert value is False
assert p['helper_sha256']==helper_sha
assert p['machine_action_required'] is True
assert p['machine_action_type']=='read-only-fresh-target-revalidation-observation'
assert p['controller_action_required'] is True
assert p['controller_action_type']=='copy-exact-probe-to-target-and-verify-sha256'
assert p['pause_safe'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze'
PY
then pass 'step-222 policy semantic assertions pass'; else fail 'step-222 policy semantic assertions pass'; fi

for pair in \
 'step:222' 'review_status:PASS' 'accepted_resume_boundary_step:221' 'strong_safe_pause_origin_step:220' \
 'prior_target_binding_reusable:no' 'prior_runtime_authorization_reusable:no' 'prior_candidate_binding_reusable:no' \
 'fresh_target_revalidation_state:read-only-observation-authorized' 'probe_execution:root-via-sudo' \
 'runtime_acknowledgement:--observe-fresh-target-revalidation' 'fresh_boot_id_required:yes' 'previous_boot_id_match_required:no' \
 'local_source_v1_must_be_preserved_unchanged:yes' 'failed_runtime_evidence_root_must_be_preserved_unchanged:yes' \
 'target_observation_authorized:yes' 'probe_transport_copy_authorized:yes' \
 'fresh_target_revalidation_freeze_authorized_after_successful_observation:yes' \
 'local_source_v2_design_authorized:no' 'local_source_v2_build_authorized:no' 'runtime_rerun_authorized:no' \
 'package_action_authorized:no' 'slackpkg_mutation_authorized:no' 'repository_refresh_authorized:no' 'network_access_authorized:no' \
 'boot_action_authorized:no' 'reboot_authorized:no' 'evidence_cleanup_authorized:no' 'phase_2_start_authorized:no' \
 'machine_action_required:yes' 'machine_action_type:read-only-fresh-target-revalidation-observation' \
 'controller_action_required:yes' 'controller_action_type:copy-exact-probe-to-target-and-verify-sha256' \
 'future_work_requires_explicit_authorization:yes' 'pause_safe:no' \
 'next_stage:phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze'; do
    key=${pair%%:*}; value=${pair#*:}
    [[ $(record_value "$key") == "$value" ]] && pass "record freezes: $key" || fail "record freezes: $key"
done

[[ $(record_value revalidation_probe_sha256) == "$probe_sha" ]] && pass 'record binds exact read-only probe SHA-256' || fail 'record binds exact read-only probe SHA-256'

if grep -Fqx "readonly EXPECTED_FQDN='vbox-slackcurrent.vbox-slackcurrent.org'" "$probe" \
   && grep -Fqx "readonly EXPECTED_UNAME_RELEASE='6.18.45'" "$probe" \
   && grep -Fqx "readonly EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'" "$probe" \
   && grep -Fqx "readonly EXPECTED_HEADER_RECORD='kernel-headers-6.18.45-x86-1'" "$probe"; then
    pass 'probe embeds exact restored target package baseline'
else
    fail 'probe embeds exact restored target package baseline'
fi

if grep -Fqx "readonly EXPECTED_TREE_MANIFEST_SHA256='0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'" "$probe" \
   && grep -Fqx "readonly EXPECTED_TARGET_SHA256='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'" "$probe" \
   && grep -Fq 'local-source v1 unexpectedly contains CHECKSUMS.md5.asc' "$probe"; then
    pass 'probe freezes preserved local-source v1 and staged-target identity'
else
    fail 'probe freezes preserved local-source v1 and staged-target identity'
fi

if grep -Fq "readonly FAILED_EVIDENCE_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction'" "$probe" \
   && grep -Fq 'boot_fingerprint' "$probe" \
   && grep -Fq 'slackpkg_state_fingerprint' "$probe" \
   && grep -Fq 'geninitrd_policy_fingerprint' "$probe" \
   && grep -Fq 'cleanup_triggered' "$probe"; then
    pass 'probe revalidates contained-failure restoration evidence'
else
    fail 'probe revalidates contained-failure restoration evidence'
fi

if grep -Fq 'prior_target_binding_reused\tno' "$probe" \
   && grep -Fq 'fresh_boot_id\t%s' "$probe" \
   && ! grep -Fq '91901677-1dc3-4a39-a4b1-3f87e6875234' "$probe"; then
    pass 'probe observes a fresh boot ID without embedding the expired boot binding'
else
    fail 'probe observes a fresh boot ID without embedding the expired boot binding'
fi

if grep -Fq "printf 'revalidation_status\\tPASS\\n'" "$probe" \
   && grep -Fq "printf 'fresh_boot_id\\t%s\\n'" "$probe"; then
    pass 'probe evidence output uses printf tab escapes that emit real TSV tabs'
else
    fail 'probe evidence output uses printf tab escapes that emit real TSV tabs'
fi

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|grub-install|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$probe"; then
    fail 'read-only probe executes a package, boot, reboot, or shutdown mutation command'
else
    pass 'read-only probe executes no package, boot, reboot, or shutdown mutation command'
fi
if grep -Eq '^[[:space:]]*(curl|wget|ftp|rsync|scp|ssh|ping)([[:space:]]|$)' "$probe"; then
    fail 'read-only probe executes a network client command'
else
    pass 'read-only probe executes no network client command'
fi
if grep -Eq '^[[:space:]]*(cp|mv|rm|install|touch|mkdir|chmod|chown|ln)([[:space:]]|$)' "$probe"; then
    fail 'read-only probe executes a persistent filesystem mutation command'
else
    pass 'read-only probe executes no persistent filesystem mutation command'
fi

normalized_doc=$(tr '\n' ' ' < "$doc" | tr -s '[:space:]' ' ')
if [[ $normalized_doc == *'old boot ID is intentionally not embedded'* \
   && $normalized_doc == *'local-source` v1'* \
   && $normalized_doc == *'failed runtime evidence root must remain present'* \
   && $normalized_doc == *'phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze'* ]]; then
    pass 'reference document defines the bounded fresh observation and next freeze gate'
else
    fail 'reference document defines the bounded fresh observation and next freeze gate'
fi

grep -Fq '## Phase 1 step 222 kernel-package-edge runtime transaction remediation fresh target revalidation review' "$changelog" && pass 'CHANGELOG records step 222' || fail 'CHANGELOG records step 222'

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
