#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
repo_root=$(cd "$(dirname "$0")/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
policy="$acc/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-authorization-review-policy.json"
record="$acc/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-authorization-review.tsv"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-authorization-review.sh"
stager="$repo_root/tools/reference/phase-1-kernel-package-edge-target-artifact-stage.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
prior_policy="$acc/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-review-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-review.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-review.sh"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-review-harness.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-review.md"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-authorization-review.md"
pass=0; fail=0
ok() { printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL: %s\n' "$1"; fail=$((fail+1)); }
reg() { [[ -f $1 && ! -L $1 ]]; }
check_file() { reg "$2" && ok "$1 is a regular file" || bad "$1 is a regular file"; }
check_hash() { local actual; actual=$(sha256sum "$2"|awk '{print $1}'); [[ $actual == "$3" ]] && ok "$1" || bad "$1"; }
check_line() { grep -Fxq "$2" "$record" && ok "$1" || bad "$1"; }
check_file 'step-208 policy' "$policy"
check_file 'step-208 record' "$record"
check_file 'step-208 helper' "$helper"
check_file 'step-208 document' "$doc"
check_file 'accepted step-207 policy' "$prior_policy"
check_file 'accepted step-207 record' "$prior_record"
check_file 'reviewed stager' "$stager"
check_file 'frozen builder' "$builder"
check_hash 'accepted step-207 policy hash is frozen' "$prior_policy" 'd31bfef0c279061d78c5a70192f2ab6892ca3f80c2461b586688257c94d4c00c'
check_hash 'accepted step-207 record hash is frozen' "$prior_record" '882f4c4b42e1e9acfb67cb5a66d554d45f261a679b0238cb512da865bccef543'
check_hash 'accepted step-207 helper hash is frozen' "$prior_helper" 'e7374f48ce3b553099799dacb6e878c75c25fe402c016943c7928e2edb92fdbe'
check_hash 'accepted step-207 harness hash is frozen' "$prior_harness" 'a798ead36cbf6dcae11239c250b066759a9e2e47c8264cc62faf04d84405e0c3'
check_hash 'accepted step-207 document hash is frozen' "$prior_doc" 'c32c2ce7c11ed1283b3b9cabd55316048a6c97d5572b348c2085cfa371602426'
check_hash 'reviewed stager SHA remains frozen' "$stager" 'a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb'
check_hash 'builder SHA remains frozen' "$builder" '59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92'
bash -n "$helper" && ok 'step-208 helper passes shell syntax validation' || bad 'step-208 helper passes shell syntax validation'
bash -n "$stager" && ok 'reviewed stager still passes shell syntax validation' || bad 'reviewed stager still passes shell syntax validation'
if bash "$prior_harness" >/dev/null 2>&1; then ok 'accepted step-207 review still passes'; else bad 'accepted step-207 review still passes'; fi
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
"$helper" --output-dir "$tmp" >/dev/null
cmp -s "$policy" "$tmp/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-authorization-review-policy.json" && ok 'helper reproduces policy deterministically' || bad 'helper reproduces policy deterministically'
cmp -s "$record" "$tmp/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-authorization-review.tsv" && ok 'helper reproduces record deterministically' || bad 'helper reproduces record deterministically'
python3 - "$policy" <<'PY208' && ok 'policy grants only single staging machine authority' || bad 'policy grants only single staging machine authority'
import json,sys
p=json.load(open(sys.argv[1])); s=p['target_artifact_staging']; a=p['authorization']
assert p['machine_action_required'] is True and p['pause_safe'] is False and p['review_only'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review'
assert s['state']=='authorized-awaiting-single-execution'
assert s['stager_sha256']=='a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb'
assert s['controller_transport_source']=='/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts/kernel-headers-6.18.45-x86-1.txz'
assert s['transport_source']=='/home/promano/Descargas/kernel-headers-6.18.45-x86-1.txz'
assert s['target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
c=s['authorization_contract']
assert c['authorization_scope']=='single-target-artifact-staging-execution' and c['authorization_consumed_when_acceptance_root_created']
assert c['authorization_expires_on_runtime_binding_drift'] and c['authorization_expires_on_transport_hash_or_type_drift'] and c['authorization_expires_on_stager_byte_drift']
assert c['post_execution_result_review_required'] and c['manual_transport_placement_to_fixed_vm_path_authorized']
assert a['controller_transport_copy_authorized'] and a['target_artifact_copy_authorized'] and a['stager_execution_authorized']
assert a['target_artifact_staging_result_review_required_after_execution']
for k,v in a.items():
    if k not in {'controller_transport_copy_authorized','target_artifact_copy_authorized','stager_execution_authorized','target_artifact_staging_result_review_required_after_execution'}: assert v is False, (k,v)
PY208
check_line 'record authorizes staging state' $'target_artifact_staging_state\tauthorized-awaiting-single-execution'
check_line 'record freezes stager SHA' $'stager_sha256\ta57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb'
check_line 'record authorizes controller transport copy' $'controller_transport_copy_authorized\tyes'
check_line 'record authorizes target artifact copy' $'target_artifact_copy_authorized\tyes'
check_line 'record authorizes stager execution' $'stager_execution_authorized\tyes'
check_line 'record keeps builder execution forbidden' $'builder_execution_authorized\tno'
check_line 'record keeps local-source build forbidden' $'local_source_build_authorized\tno'
check_line 'record keeps repository refresh forbidden' $'repository_refresh_authorized\tno'
check_line 'record keeps package action forbidden' $'package_action_authorized\tno'
check_line 'record keeps boot action forbidden' $'boot_action_authorized\tno'
check_line 'record keeps reboot forbidden' $'reboot_authorized\tno'
check_line 'record requires machine action' $'machine_action_required\tyes'
check_line 'record is not safe pause' $'pause_safe\tno'
check_line 'record routes only to staging result review' $'next_stage\tphase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review'
if grep -Fq 'single-use' "$doc" && grep -Fq 'Builder execution and local-source construction remain forbidden' "$doc"; then ok 'reference document records narrow single-use authority'; else bad 'reference document records narrow single-use authority'; fi
if grep -Fq 'Phase 1 step 208 kernel-package-edge target-artifact staging authorization review' "$repo_root/CHANGELOG.md"; then ok 'CHANGELOG records step 208'; else bad 'CHANGELOG records step 208'; fi
# Authorization step must not introduce a changed stager or any executable mutation helper.
if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget|rsync|scp|ssh)[[:space:]]' "$helper"; then bad 'step-208 helper contains no executable network/package/boot/reboot command'; else ok 'step-208 helper contains no executable network/package/boot/reboot command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail -eq 0 ]] && echo PASS || echo FAIL)" "$pass" "$fail"
[[ $fail -eq 0 ]]
