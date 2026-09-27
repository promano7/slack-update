#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review'
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh"
helper="$repo_root/tools/reference/${base}.sh"
doc="$repo_root/docs/reference/${base}.md"
policy="$acc/${base}-policy.json"
record="$acc/${base}.tsv"
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-review-probe.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$acc/${prev}-policy.json"
prev_record="$acc/${prev}.tsv"
changelog="$repo_root/CHANGELOG.md"
passes=0; failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures+1)); }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
check_regular() { [[ -f $1 && ! -L $1 ]] && pass "$2 is a regular non-symlink file" || fail "$2 is a regular non-symlink file"; }
check_hash() { [[ $(sha "$1") == "$2" ]] && pass "$3 hash is frozen" || fail "$3 hash is frozen"; }
record_value() { awk -F '\t' -v k="$1" '$1==k {print substr($0,length($1)+2); exit}' "$record"; }
for item in "$builder|frozen v2 builder" "$helper|step-229 helper" "$doc|step-229 reference document" "$policy|step-229 policy" "$record|step-229 record" "$prev_helper|accepted step-228 helper" "$prev_probe|accepted step-228 probe" "$prev_doc|accepted step-228 document" "$prev_harness|accepted step-228 harness" "$prev_policy|accepted step-228 policy" "$prev_record|accepted step-228 record" "$changelog|CHANGELOG"; do IFS='|' read -r path label <<< "$item"; check_regular "$path" "$label"; done
check_hash "$builder" '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d' 'frozen v2 builder'
check_hash "$prev_helper" '1f3bfde8aaa93dd36e6438c7e6c4397b427fa50f03e1d5e1b98b3c1f3886b7a0' 'accepted step-228 helper'
check_hash "$prev_probe" '207ce41439c6ce2fe0f98a40266528bed4178073d5bab781d19b6d938bc64984' 'accepted step-228 probe'
check_hash "$prev_doc" '09b1d2f0baff2de6b97229536c72e6fa817c8a919e6ae8d584e8fa3022d0a413' 'accepted step-228 document'
check_hash "$prev_harness" 'c7913ba7052c9807dd1987cc6051e46db933c01b2227faa7e02b3e51797e8ffa' 'accepted step-228 harness'
check_hash "$prev_policy" 'a9eb0db7a4f6e003d66d2e7c1005483e1de827a5c44f98d5aae47b71b32db283' 'accepted step-228 policy'
check_hash "$prev_record" 'c3f9e70ee0d0136bbd43216e657052c92b6f3eeee612472916d0403e4182ff44' 'accepted step-228 record'
bash -n "$builder" && pass 'frozen v2 builder passes bash syntax validation' || fail 'frozen v2 builder passes bash syntax validation'
bash -n "$helper" && pass 'step-229 helper passes bash syntax validation' || fail 'step-229 helper passes bash syntax validation'
"$builder" --help >/dev/null && pass 'frozen v2 builder exposes non-mutating help' || fail 'frozen v2 builder exposes non-mutating help'
"$helper" --help >/dev/null && pass 'step-229 helper exposes non-mutating help' || fail 'step-229 helper exposes non-mutating help'
if "$helper" --unknown >/dev/null 2>&1; then fail 'step-229 helper rejects unknown option'; else pass 'step-229 helper rejects unknown option'; fi
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
"$helper" --output-dir "$tmp" && pass 'step-229 helper executes successfully' || fail 'step-229 helper executes successfully'
cmp -s "$tmp/${base}-policy.json" "$policy" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s "$tmp/${base}.tsv" "$record" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'
python3 - "$policy" <<'PYSEM'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['step']==229 and p['review_status']=='PASS' and p['review_only'] is True
assert p['prebuild_observation_state']=='consumed-and-frozen-for-single-build-authorization'
o=p['consumed_prebuild_observation']
assert o['prebuild_revalidation_status']=='PASS'
assert o['fresh_boot_id']=='cd975bdc-a133-47d1-9e92-e9b51bef9d99'
assert o['package_database_manifest_sha256']=='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
assert o['staged_target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert o['local_source_v1_tree_manifest_sha256']=='0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'
assert o['local_source_v2_final_outputs_absent']=='yes'
assert o['local_source_v2_temporary_build_roots_absent']=='yes'
a=p['single_build_authorization']
assert a['state']=='authorized-not-executed'
assert a['authorization_use_count']==1
assert a['authorization_bound_boot_id']==o['fresh_boot_id']
assert a['same_boot_required_at_execution'] is True
assert a['builder_sha256']=='8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d'
assert a['acknowledgement']=='--build-local-source-v2'
assert a['no_second_execution_authorized'] is True
assert p['authorization']['target_observation_authorized'] is False
assert p['authorization']['local_source_v2_builder_transport_authorized'] is True
assert p['authorization']['local_source_v2_builder_execution_authorized'] is True
assert p['authorization']['local_source_v2_build_authorized'] is True
assert p['authorization']['local_source_v2_build_result_review_authorized_after_successful_build'] is True
for k in ('runtime_candidate_binding_authorized','runtime_executor_remediation_authorized','runtime_rerun_authorized','package_action_authorized','slackpkg_mutation_authorized','repository_refresh_authorized','network_access_authorized','boot_action_authorized','reboot_authorized','persistent_configuration_change_authorized','evidence_cleanup_authorized','phase_2_start_authorized'):
    assert p['authorization'][k] is False
assert p['machine_action_required'] is True and p['pause_safe'] is False and p['strong_safe_pause'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause'
PYSEM
[[ $? -eq 0 ]] && pass 'step-229 policy semantic assertions pass' || fail 'step-229 policy semantic assertions pass'
for key in step review_status prebuild_observation_state fresh_boot_id package_database_manifest_sha256 staged_target_sha256 local_source_v1_tree_manifest_sha256 local_source_v2_final_outputs_absent_at_authorization local_source_v2_temporary_build_roots_absent_at_authorization builder_sha256 builder_execution_acknowledgement authorization_use_count same_boot_required_at_execution target_observation_authorized local_source_v2_builder_transport_authorized local_source_v2_builder_execution_authorized local_source_v2_build_authorized local_source_v2_build_result_review_authorized_after_successful_build runtime_candidate_binding_authorized runtime_rerun_authorized package_action_authorized machine_action_required pause_safe next_stage; do [[ -n $(record_value "$key") ]] && pass "record contains $key" || fail "record contains $key"; done
[[ $(record_value step) == 229 ]] && pass 'record freezes step 229' || fail 'record freezes step 229'
[[ $(record_value fresh_boot_id) == 'cd975bdc-a133-47d1-9e92-e9b51bef9d99' ]] && pass 'record freezes returned prebuild boot ID' || fail 'record freezes returned prebuild boot ID'
[[ $(record_value local_source_v2_builder_execution_authorized) == yes ]] && pass 'record authorizes one builder execution' || fail 'record authorizes one builder execution'
[[ $(record_value authorization_use_count) == 1 ]] && pass 'record limits builder authorization to one use' || fail 'record limits builder authorization to one use'
[[ $(record_value runtime_rerun_authorized) == no ]] && pass 'record keeps runtime rerun closed' || fail 'record keeps runtime rerun closed'
[[ $(record_value package_action_authorized) == no ]] && pass 'record keeps package action closed' || fail 'record keeps package action closed'
[[ $(record_value next_stage) == phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause ]] && pass 'record names build-result review and strong-safe-pause next' || fail 'record names build-result review and strong-safe-pause next'
grep -Fq 'Exactly one transport/copy' "$doc" && grep -Fq 'No second builder execution is authorized.' "$doc" && grep -Fq 'If the builder returns non-zero' "$doc" && pass 'reference document defines single-use fail-closed build authority' || fail 'reference document defines single-use fail-closed build authority'
grep -Fq '## Phase 1 step 229 kernel-package-edge runtime-transaction remediation local-source-v2 prebuild fresh target revalidation freeze and build authorization review' "$changelog" && pass 'CHANGELOG records step 229' || fail 'CHANGELOG records step 229'
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]' "$helper"; then fail 'step-229 helper contains executable machine mutation command'; else pass 'step-229 helper contains no executable machine mutation command'; fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|grub-install|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$builder"; then fail 'frozen builder contains package, boot, reboot, or shutdown mutation command'; else pass 'frozen builder contains no package, boot, reboot, or shutdown mutation command'; fi
if grep -Eq '^[[:space:]]*(curl|wget|ftp|rsync|scp|ssh|ping)([[:space:]]|$)' "$builder"; then fail 'frozen builder contains network client command'; else pass 'frozen builder contains no network client command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
