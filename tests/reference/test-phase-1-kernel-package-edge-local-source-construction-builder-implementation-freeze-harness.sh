#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
policy="$acc/phase-1-kernel-package-edge-local-source-construction-builder-implementation-freeze-policy.json"
record="$acc/phase-1-kernel-package-edge-local-source-construction-builder-implementation-freeze.tsv"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-builder-implementation-freeze.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-builder-implementation-freeze.md"
prior_policy="$acc/phase-1-kernel-package-edge-local-source-construction-builder-implementation-review-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-local-source-construction-builder-implementation-review.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-builder-implementation-review.sh"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-local-source-construction-builder-implementation-review-harness.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-builder-implementation-review.md"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
pass=0; fail=0
ok(){ printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad(){ printf 'FAIL: %s\n' "$1"; fail=$((fail+1)); }
check_file(){ [[ -f $2 && ! -L $2 ]] && ok "$1" || bad "$1"; }
check_line(){ grep -Fqx "$2" "$record" && ok "$1" || bad "$1"; }
check_file 'step-206 policy is a regular file' "$policy"
check_file 'step-206 record is a regular file' "$record"
check_file 'step-206 helper is a regular file' "$helper"
check_file 'step-206 document is a regular file' "$doc"
check_file 'accepted step-205 policy is a regular file' "$prior_policy"
check_file 'accepted step-205 record is a regular file' "$prior_record"
check_file 'accepted step-205 helper is a regular file' "$prior_helper"
check_file 'accepted step-205 harness is a regular file' "$prior_harness"
check_file 'accepted step-205 document is a regular file' "$prior_doc"
check_file 'frozen builder is a regular file' "$builder"
[[ $(sha256sum "$prior_policy"|awk '{print $1}') == 1c8dcce9ac02594734e866bc6f5515900f6dfbdfbc8b630ef6e5c5ac8836fd1d ]] && ok 'accepted step-205 policy hash is frozen' || bad 'accepted step-205 policy hash is frozen'
[[ $(sha256sum "$prior_record"|awk '{print $1}') == 9ad8a0902cd5fe49152fefc4cc5ef6db3e7c979ed9d79441f350ab75693c5e6c ]] && ok 'accepted step-205 record hash is frozen' || bad 'accepted step-205 record hash is frozen'
[[ $(sha256sum "$prior_helper"|awk '{print $1}') == 35bf160fdc771a9d4e3bb409ce2e092347905d92665034f61dfa7b5d7c70d27b ]] && ok 'accepted step-205 helper hash is frozen' || bad 'accepted step-205 helper hash is frozen'
[[ $(sha256sum "$prior_harness"|awk '{print $1}') == 2235f8b12e7872373f06848b3f03820b8c1380e7e11dfa30b251e30fcb9a88d8 ]] && ok 'accepted step-205 harness hash is frozen' || bad 'accepted step-205 harness hash is frozen'
[[ $(sha256sum "$prior_doc"|awk '{print $1}') == b4e3ff239e542fa41cd1c3ef6323c14c77188445042d8f7956bdb504c4abcdc3 ]] && ok 'accepted step-205 document hash is frozen' || bad 'accepted step-205 document hash is frozen'
[[ $(sha256sum "$builder"|awk '{print $1}') == 59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92 ]] && ok 'builder implementation SHA-256 is frozen' || bad 'builder implementation SHA-256 is frozen'
bash -n "$builder" && ok 'frozen builder passes shell syntax validation' || bad 'frozen builder passes shell syntax validation'
bash -n "$helper" && ok 'step-206 helper passes shell syntax validation' || bad 'step-206 helper passes shell syntax validation'
if bash "$prior_harness" >/dev/null 2>&1; then ok 'accepted step-205 implementation review still passes'; else bad 'accepted step-205 implementation review still passes'; fi
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
"$helper" --output-dir "$tmp" >/dev/null
cmp -s "$policy" "$tmp/${policy##*/}" && ok 'helper reproduces policy deterministically' || bad 'helper reproduces policy deterministically'
cmp -s "$record" "$tmp/${record##*/}" && ok 'helper reproduces record deterministically' || bad 'helper reproduces record deterministically'
python3 - "$policy" <<'PYASSERT206' && ok 'policy freezes exact reviewed implementation with no operational authority' || bad 'policy freezes exact reviewed implementation with no operational authority'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8')); b=p['builder_implementation']; a=p['authorization']; s=p['accepted_step_205']
assert b['builder_implementation_state']=='frozen' and b['implementation_freeze_step']==206 and b['implementation_review_step']==205
assert p['builder_sha256']=='59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92' and b['builder_sha256']=='59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92' and s['builder_sha256']=='59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92'
assert b['accepted_builder_input_artifact_count']==1 and b['accepted_builder_input_artifact']=='kernel-headers-6.18.45-x86-1.txz'
assert b['predecessor_is_builder_input'] is False and b['exact_package_candidate_count']==1
assert b['repository_test_seam']['production_paths_overridable'] is False
assert b['input_guards']['builder_may_access_network'] is False
assert b['failure_contract']['must_not_modify_package_database'] and b['failure_contract']['must_not_modify_slackpkg_configuration'] and b['failure_contract']['must_not_modify_boot_state'] and b['failure_contract']['must_not_reboot']
assert a['target_artifact_staging_review_authorized_for_next_stage'] is True
for k,v in a.items():
    if k!='target_artifact_staging_review_authorized_for_next_stage': assert v is False
assert p['machine_action_required'] is False and p['pause_safe'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-review'
PYASSERT206
check_line 'record freezes builder design' $'builder_design_state\tfrozen'
check_line 'record freezes builder implementation' $'builder_implementation_state\tfrozen'
check_line 'record binds implementation review step' $'builder_implementation_review_step\t205'
check_line 'record freezes builder SHA' $'builder_sha256\t59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92'
check_line 'record preserves single builder input' $'accepted_builder_input_artifact_count\t1'
check_line 'record excludes predecessor from builder input' $'predecessor_is_builder_input\tno'
check_line 'record preserves single package candidate' $'exact_package_candidate_count\t1'
check_line 'record preserves repository-only test seam' $'repository_test_seam\tSLACK_UPDATE_LOCAL_SOURCE_BUILDER_LIBRARY_ONLY=1'
check_line 'record forbids production path override' $'production_paths_overridable\tno'
check_line 'record authorizes only staging review next' $'target_artifact_staging_review_authorized_for_next_stage\tyes'
check_line 'record does not authorize builder execution' $'builder_execution_authorized\tno'
check_line 'record does not authorize target artifact copy' $'target_artifact_copy_authorized\tno'
check_line 'record does not authorize local-source build' $'local_source_build_authorized\tno'
check_line 'record does not authorize runtime execution' $'runtime_scenario_execution_authorized\tno'
check_line 'record does not authorize package action' $'package_action_authorized\tno'
check_line 'record does not authorize boot action' $'boot_action_authorized\tno'
check_line 'record does not authorize reboot' $'reboot_authorized\tno'
check_line 'record requires no machine action' $'machine_action_required\tno'
check_line 'record routes to target-artifact staging review' $'next_stage\tphase-1-kernel-package-edge-local-source-construction-target-artifact-staging-review'
if grep -Fq '59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92' "$doc" && grep -Fq 'does **not** authorize executing the builder' "$doc" && grep -Fq 'target-artifact-staging-review' "$doc"; then ok 'reference document records exact freeze and staging-review boundary'; else bad 'reference document records exact freeze and staging-review boundary'; fi
if grep -Fq 'Phase 1 step 206 kernel-package-edge local-source construction builder implementation freeze' "$repo_root/CHANGELOG.md"; then ok 'CHANGELOG records step 206'; else bad 'CHANGELOG records step 206'; fi
if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget|rsync|scp|ssh)[[:space:]]' "$helper"; then bad 'step-206 helper contains no executable network/package/boot/reboot command'; else ok 'step-206 helper contains no executable network/package/boot/reboot command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail -eq 0 ]] && echo PASS || echo FAIL)" "$pass" "$fail"
[[ $fail -eq 0 ]]
