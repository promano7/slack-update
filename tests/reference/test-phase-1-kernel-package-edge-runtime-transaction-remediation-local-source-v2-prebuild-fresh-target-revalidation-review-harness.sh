#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-freeze'
helper="$repo_root/tools/reference/${base}.sh"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review-probe.sh"
doc="$repo_root/docs/reference/${base}.md"
policy="$acc/${base}-policy.json"
record="$acc/${base}.tsv"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh"
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$acc/${prev}-policy.json"
prev_record="$acc/${prev}.tsv"
changelog="$repo_root/CHANGELOG.md"
passes=0; failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1" >&2; failures=$((failures+1)); }
check_file(){ [[ -f $1 && ! -L $1 ]] && pass "$2 is a regular non-symlink file" || fail "$2 is a regular non-symlink file"; }
check_sha(){ local actual; actual=$(sha256sum -- "$1" | awk '{print $1}'); [[ $actual == "$2" ]] && pass "$3 hash is frozen" || fail "$3 hash is frozen"; }
record_value(){ awk -F '\t' -v key="$1" '$1==key {print $2; exit}' "$record"; }
for spec in "$builder|frozen v2 builder" "$helper|step-228 helper" "$probe|step-228 read-only probe" "$doc|step-228 reference document" "$policy|step-228 policy" "$record|step-228 record" "$prev_helper|accepted step-227 helper" "$prev_doc|accepted step-227 document" "$prev_harness|accepted step-227 harness" "$prev_policy|accepted step-227 policy" "$prev_record|accepted step-227 record" "$changelog|CHANGELOG"; do IFS='|' read -r path label <<<"$spec"; check_file "$path" "$label"; done
check_sha "$builder" '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d' 'frozen v2 builder'
check_sha "$prev_helper" '0882eb6636170e7ffde474f0d3c11f90dbf8b2431a29b9fe062bafcac2dee425' 'accepted step-227 helper'
check_sha "$prev_doc" 'c62c652a2d91d0855f2ee619a8eca92468ded3fa5c2536a0abfccff38e533b12' 'accepted step-227 document'
check_sha "$prev_harness" '928e699dc3c0e953ba65d8bb1694c1071043bb4404835bb5bbf306ff17ee4995' 'accepted step-227 harness'
check_sha "$prev_policy" '79fcbc19be0de464ba41e02fbd4b7f4a66b15b34e41648df7a6763bb706149ad' 'accepted step-227 policy'
check_sha "$prev_record" 'c4fb4fce881ac6cf5254dd67399233a64361caf81b14638aa2d506d0edd073d4' 'accepted step-227 record'
[[ $(sha256sum -- "$probe" | awk '{print $1}') == '207ce41439c6ce2fe0f98a40266528bed4178073d5bab781d19b6d938bc64984' ]] && pass 'step-228 read-only probe SHA-256 is frozen' || fail 'step-228 read-only probe SHA-256 is frozen'
bash -n "$helper" && pass 'step-228 helper passes bash syntax validation' || fail 'step-228 helper passes bash syntax validation'
bash -n "$probe" && pass 'step-228 probe passes bash syntax validation' || fail 'step-228 probe passes bash syntax validation'
"$helper" --help >/dev/null && pass 'step-228 helper exposes non-mutating help' || fail 'step-228 helper exposes non-mutating help'
"$probe" --help >/dev/null && pass 'step-228 probe exposes non-mutating help' || fail 'step-228 probe exposes non-mutating help'
if "$helper" --bad >/dev/null 2>&1; then fail 'step-228 helper rejects unknown option'; else pass 'step-228 helper rejects unknown option'; fi
if "$probe" --bad >/dev/null 2>&1; then fail 'step-228 probe rejects unknown option'; else pass 'step-228 probe rejects unknown option'; fi
tmp=$(mktemp -d); trap 'rm -rf -- "$tmp"' EXIT
"$helper" --output-dir "$tmp" >/dev/null && pass 'step-228 helper executes successfully' || fail 'step-228 helper executes successfully'
cmp -s "$policy" "$tmp/${base}-policy.json" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s "$record" "$tmp/${base}.tsv" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'
python3 - "$prev_policy" "$policy" <<'PYSEM' && pass 'step-228 policy semantic assertions pass' || fail 'step-228 policy semantic assertions pass'
import json,sys
p227=json.load(open(sys.argv[1],encoding='utf-8')); p=json.load(open(sys.argv[2],encoding='utf-8'))
assert p['step']==228 and p['review_only'] is True and p['review_status']=='PASS'
assert p['accepted_step_227']['builder_sha256']=='8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert p['historical_frozen_runtime_identity']==p227['frozen_runtime_identity']
assert p['preservation_contract']==p227['preservation_contract']
assert p['local_source_v2_design']==p227['local_source_v2_design']
assert p['builder_implementation']==p227['builder_implementation']
f=p['prebuild_fresh_target_revalidation']
assert f['state']=='read-only-observation-authorized'
assert f['probe_sha256']=='207ce41439c6ce2fe0f98a40266528bed4178073d5bab781d19b6d938bc64984'
assert f['acknowledgement']=='--observe-prebuild-fresh-target-revalidation'
assert f['previous_frozen_boot_id_match_required'] is False
assert f['previous_frozen_boot_id_must_not_be_used_as_binding'] is True
assert f['local_source_v2_final_outputs_must_be_absent'] is True
assert f['local_source_v2_temporary_build_roots_must_be_absent'] is True
assert f['frozen_builder_sha256']=='8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
for k in ('repository_refresh_allowed','network_access_allowed','package_mutation_allowed','slackpkg_mutation_allowed','boot_mutation_allowed','persistent_configuration_change_allowed','reboot_allowed'): assert f[k] is False,k
a=p['authorization']
assert a['target_observation_authorized'] is True
assert a['probe_transport_copy_authorized'] is True
assert a['prebuild_fresh_target_revalidation_freeze_and_build_authorization_review_authorized_after_successful_observation'] is True
for k in ('local_source_v2_builder_transport_authorized','local_source_v2_builder_execution_authorized','local_source_v2_build_authorized','runtime_candidate_binding_authorized','runtime_executor_remediation_authorized','runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','repository_refresh_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','persistent_configuration_change_authorized','evidence_cleanup_authorized','phase_2_start_authorized'): assert a[k] is False,k
assert p['machine_action_required'] is True and p['controller_action_required'] is True
assert p['pause_safe'] is False and p['strong_safe_pause'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review'
PYSEM
for key in step review_status accepted_step_227_builder_sha256 builder_implementation_state builder_sha256 prebuild_fresh_target_revalidation_state probe_execution runtime_acknowledgement prebuild_revalidation_probe_sha256 fresh_boot_id_required previous_frozen_boot_id_match_required local_source_v2_final_outputs_must_be_absent local_source_v2_temporary_build_roots_must_be_absent target_observation_authorized probe_transport_copy_authorized local_source_v2_builder_transport_authorized local_source_v2_builder_execution_authorized local_source_v2_build_authorized runtime_rerun_authorized package_action_authorized machine_action_required pause_safe next_stage; do [[ -n $(record_value "$key") ]] && pass "record contains $key" || fail "record contains $key"; done
[[ $(record_value step) == 228 ]] && pass 'record freezes step 228' || fail 'record freezes step 228'
[[ $(record_value target_observation_authorized) == yes ]] && pass 'record authorizes exactly the read-only target observation' || fail 'record authorizes exactly the read-only target observation'
[[ $(record_value local_source_v2_builder_execution_authorized) == no ]] && pass 'record keeps builder execution closed' || fail 'record keeps builder execution closed'
[[ $(record_value local_source_v2_build_authorized) == no ]] && pass 'record keeps v2 build closed' || fail 'record keeps v2 build closed'
[[ $(record_value local_source_v2_final_outputs_must_be_absent) == yes ]] && pass 'record requires v2 final outputs to be absent' || fail 'record requires v2 final outputs to be absent'
[[ $(record_value next_stage) == phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review ]] && pass 'record names build-authorization review next' || fail 'record names build-authorization review next'
grep -Fqx "readonly EXPECTED_BUILDER_SHA256='8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'" "$probe" && pass 'probe binds frozen builder identity for evidence output' || fail 'probe binds frozen builder identity for evidence output'
grep -Fq "readonly LOCAL_SOURCE_V2_ROOT='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2'" "$probe" && grep -Fq "readonly V2_TEMP_GLOB='.local-source-v2.build.*'" "$probe" && pass 'probe checks exact v2 final and temporary output namespace' || fail 'probe checks exact v2 final and temporary output namespace'
if grep -Fq 'cd975bdc-a133-47d1-9e92-e9b51bef9d99' "$probe"; then fail 'probe does not embed prior frozen boot ID'; else pass 'probe does not embed prior frozen boot ID'; fi
grep -Fq "printf 'prebuild_revalidation_status\tPASS\n'" "$probe" && grep -Fq "printf 'fresh_boot_id\t%s\n'" "$probe" && pass 'probe emits real-tab TSV evidence' || fail 'probe emits real-tab TSV evidence'
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|grub-install|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$probe"; then fail 'read-only probe executes a package, boot, reboot, or shutdown mutation command'; else pass 'read-only probe executes no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '^[[:space:]]*(curl|wget|ftp|rsync|scp|ssh|ping)([[:space:]]|$)' "$probe"; then fail 'read-only probe executes a network client command'; else pass 'read-only probe executes no network client command'; fi
if grep -Eq '^[[:space:]]*(cp|mv|rm|install|touch|mkdir|chmod|chown|ln)([[:space:]]|$)' "$probe"; then fail 'read-only probe executes a persistent filesystem mutation command'; else pass 'read-only probe executes no persistent filesystem mutation command'; fi
grep -Fq 'single-use builder authorization' "$doc" && grep -Fq 'final `local-source-v2` tree' "$doc" && grep -Fq 'historical context only' "$doc" && pass 'reference document defines prebuild observation and build-authorization gate' || fail 'reference document defines prebuild observation and build-authorization gate'
grep -Fq '## Phase 1 step 228 kernel-package-edge runtime-transaction remediation local-source-v2 prebuild fresh target revalidation review' "$changelog" && pass 'CHANGELOG records step 228' || fail 'CHANGELOG records step 228'
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]' "$helper"; then fail 'step-228 helper contains executable machine mutation command'; else pass 'step-228 helper contains no executable machine mutation command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
