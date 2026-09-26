#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
repo_root=$(cd "$(dirname "$0")/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
policy="$acc/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review-policy.json"
record="$acc/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review.tsv"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
stager="$repo_root/tools/reference/phase-1-kernel-package-edge-target-artifact-stage.sh"
prior_policy="$acc/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-authorization-review-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-authorization-review.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-authorization-review.sh"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-authorization-review-harness.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-authorization-review.md"
pass=0; fail=0
ok() { printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL: %s\n' "$1"; fail=$((fail+1)); }
regular() { [[ -f $2 && ! -L $2 ]] && ok "$1" || bad "$1"; }
check_hash() { local label=$1 path=$2 expected=$3 actual; actual=$(sha256sum -- "$path" | awk '{print $1}'); [[ $actual == "$expected" ]] && ok "$label" || { printf 'expected: %s\nactual:   %s\n' "$expected" "$actual"; bad "$label"; }; }
check_line() { grep -Fxq "$2" "$record" && ok "$1" || bad "$1"; }
regular 'step-209 policy is a regular file' "$policy"
regular 'step-209 record is a regular file' "$record"
regular 'step-209 helper is a regular file' "$helper"
regular 'step-209 document is a regular file' "$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review.md"
regular 'accepted step-208 policy is a regular file' "$prior_policy"
regular 'accepted step-208 record is a regular file' "$prior_record"
regular 'frozen builder is a regular file' "$builder"
regular 'reviewed stager is a regular file' "$stager"
check_hash 'accepted step-208 policy hash is frozen' "$prior_policy" '6e4cdc3f8e63ee7d88d30407a8e54838b12784915cd986e447eb3125f69f41a3'
check_hash 'accepted step-208 record hash is frozen' "$prior_record" '3c708a9e40b1b1756582d7550f1cd9b40a1fb7fc803361595848edebf7b6307c'
check_hash 'accepted step-208 helper hash is frozen' "$prior_helper" 'd3b72850a4844f010aa4d45ab45ca7d42b48daf25655d15d7e4c8585e96aeb34'
check_hash 'accepted step-208 harness hash is frozen' "$prior_harness" '785cfe75873c758db777cb89eced217733fc29925b33c4b036fbcd3c6bf1b85a'
check_hash 'accepted step-208 document hash is frozen' "$prior_doc" 'f411895a28f1477ff61dc9e0c9042889a61a810d3869c383a12c8a3a478077b8'
check_hash 'stager SHA remains frozen' "$stager" 'a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb'
check_hash 'builder SHA remains frozen' "$builder" '59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92'
bash -n "$helper" && ok 'step-209 helper passes shell syntax validation' || bad 'step-209 helper passes shell syntax validation'
bash -n "$builder" && ok 'frozen builder still passes shell syntax validation' || bad 'frozen builder still passes shell syntax validation'
if bash "$prior_harness" >/dev/null 2>&1; then ok 'accepted step-208 authorization still passes'; else bad 'accepted step-208 authorization still passes'; fi
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
"$helper" --output-dir "$tmp" >/dev/null
cmp -s "$policy" "$tmp/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review-policy.json" && ok 'helper reproduces policy deterministically' || bad 'helper reproduces policy deterministically'
cmp -s "$record" "$tmp/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review.tsv" && ok 'helper reproduces record deterministically' || bad 'helper reproduces record deterministically'
python3 - "$policy" <<'PY209' && ok 'policy accepts staging and grants only single builder authority' || bad 'policy accepts staging and grants only single builder authority'
import json,sys
p=json.load(open(sys.argv[1])); s=p['target_artifact_staging']; b=p['local_source_build_authorization']; a=p['authorization']
assert p['machine_action_required'] is True and p['pause_safe'] is False and p['review_only'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause'
assert s['state']=='accepted-pass-authority-consumed'
r=s['observed_result']; assert r['target_artifact_staging_status']=='PASS' and r['transport_source_preserved'] is True
assert r['staged_target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert r['staged_target_owner']=='root:root' and r['staged_target_mode']=='0444'
for k in ['network_access_performed','repository_refresh_performed','package_action_performed','slackpkg_configuration_change_performed','boot_action_performed','reboot_performed']: assert r[k] is False
rr=s['result_review']; assert rr['accepted'] and rr['single_use_staging_authority_consumed'] and rr['stager_execution_authority_revoked'] and rr['target_artifact_copy_authority_revoked']
assert b['state']=='authorized-awaiting-single-execution' and b['builder_sha256']=='59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92'
assert b['builder_transport_source']=='/home/promano/Descargas/phase-1-kernel-package-edge-local-source-build.sh'
assert b['execution_exact_command']=='sudo bash phase-1-kernel-package-edge-local-source-build.sh --build-local-source'
assert b['builder_execution_authorized'] and b['local_source_build_authorized'] and b['post_execution_result_review_required']
assert a['controller_builder_transport_copy_authorized'] and a['builder_execution_authorized'] and a['local_source_build_authorized'] and a['local_source_build_result_review_required_after_execution']
for k,v in a.items():
    if k not in {'controller_builder_transport_copy_authorized','builder_execution_authorized','local_source_build_authorized','local_source_build_result_review_required_after_execution'}: assert v is False, (k,v)
PY209
check_line 'record accepts staging PASS' $'staging_result_status\tPASS'
check_line 'record consumes staging authority' $'target_artifact_staging_state\taccepted-pass-authority-consumed'
check_line 'record revokes stager execution' $'stager_execution_authorized\tno'
check_line 'record revokes target copy' $'target_artifact_copy_authorized\tno'
check_line 'record freezes builder SHA' $'builder_sha256\t59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92'
check_line 'record authorizes builder execution' $'builder_execution_authorized\tyes'
check_line 'record authorizes local-source build' $'local_source_build_authorized\tyes'
check_line 'record keeps repository refresh forbidden' $'repository_refresh_authorized\tno'
check_line 'record keeps package action forbidden' $'package_action_authorized\tno'
check_line 'record keeps slackpkg mutation forbidden' $'slackpkg_configuration_change_authorized\tno'
check_line 'record keeps runtime scenario forbidden' $'runtime_scenario_execution_authorized\tno'
check_line 'record keeps boot action forbidden' $'boot_action_authorized\tno'
check_line 'record keeps reboot forbidden' $'reboot_authorized\tno'
check_line 'record requires machine action' $'machine_action_required\tyes'
check_line 'record is not safe pause' $'pause_safe\tno'
check_line 'record routes only to build result review and strong safe pause' $'next_stage\tphase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause'
if grep -Fq 'Staging authority consumed' "$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review.md" && grep -Fq 'Single local-source build authority' "$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review.md"; then ok 'reference document records consumed staging and narrow build authority'; else bad 'reference document records consumed staging and narrow build authority'; fi
if grep -Fq 'Phase 1 step 209 kernel-package-edge target-artifact staging result review' "$repo_root/CHANGELOG.md"; then ok 'CHANGELOG records step 209'; else bad 'CHANGELOG records step 209'; fi
if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget|rsync|scp|ssh)[[:space:]]' "$helper"; then bad 'step-209 helper contains no executable network/package/boot/reboot command'; else ok 'step-209 helper contains no executable network/package/boot/reboot command'; fi
# Builder remains the previously reviewed local-only implementation.
if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget|rsync|scp|ssh)[[:space:]]' "$builder"; then bad 'frozen builder contains no executable network/package/boot/reboot command'; else ok 'frozen builder contains no executable network/package/boot/reboot command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail -eq 0 ]] && echo PASS || echo FAIL)" "$pass" "$fail"
[[ $fail -eq 0 ]]
