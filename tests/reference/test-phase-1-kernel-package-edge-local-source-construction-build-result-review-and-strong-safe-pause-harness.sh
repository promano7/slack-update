#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
repo_root=$(cd "$(dirname "$0")/../.." && pwd -P)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
policy="$acc/phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause-policy.json"
record="$acc/phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause.tsv"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause.md"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
stager="$repo_root/tools/reference/phase-1-kernel-package-edge-target-artifact-stage.sh"
prior_policy="$acc/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review-policy.json"
prior_record="$acc/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review.tsv"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review.sh"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review-harness.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review.md"
pass=0; fail=0
ok() { printf 'PASS: %s\n' "$1"; pass=$((pass+1)); }
bad() { printf 'FAIL: %s\n' "$1"; fail=$((fail+1)); }
regular() { [[ -f $2 && ! -L $2 ]] && ok "$1" || bad "$1"; }
check_hash() { local label=$1 path=$2 expected=$3 actual; actual=$(sha256sum -- "$path" | awk '{print $1}'); [[ $actual == "$expected" ]] && ok "$label" || { printf 'expected: %s\nactual:   %s\n' "$expected" "$actual"; bad "$label"; }; }
check_line() { grep -Fxq "$2" "$record" && ok "$1" || bad "$1"; }
regular 'step-210 policy is a regular file' "$policy"
regular 'step-210 record is a regular file' "$record"
regular 'step-210 helper is a regular file' "$helper"
regular 'step-210 document is a regular file' "$doc"
regular 'accepted step-209 policy is a regular file' "$prior_policy"
regular 'accepted step-209 record is a regular file' "$prior_record"
regular 'frozen builder is a regular file' "$builder"
regular 'reviewed stager is a regular file' "$stager"
check_hash 'accepted step-209 policy hash is frozen' "$prior_policy" 'dcea60310bc768e5d2b095879203eaad36d8d69d149e19d46c9865d546455182'
check_hash 'accepted step-209 record hash is frozen' "$prior_record" 'abe04d6c7e5baf34fe4cb5d186bb66769e677082ddf1b4ab1ac73f97fd21b8cc'
check_hash 'accepted step-209 helper hash is frozen' "$prior_helper" '88ea9e71c01c6c1ad524385540e2d07bffcc8e09073b20a5a5dab567aab186c6'
check_hash 'accepted step-209 harness hash is frozen' "$prior_harness" '80b5f5f463ea5c7816c996007e3e58a7c8007ccefe3dc82acbbc0e0671c0f7f0'
check_hash 'accepted step-209 document hash is frozen' "$prior_doc" '890188816fc8695bf63363acbd578e52788ec5bb8ca478c31dd36dd8ac0a0bc3'
check_hash 'builder SHA remains frozen' "$builder" '59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92'
check_hash 'stager SHA remains frozen' "$stager" 'a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb'
bash -n "$helper" && ok 'step-210 helper passes shell syntax validation' || bad 'step-210 helper passes shell syntax validation'
bash -n "$builder" && ok 'frozen builder still passes shell syntax validation' || bad 'frozen builder still passes shell syntax validation'
if bash "$prior_harness" >/dev/null 2>&1; then ok 'accepted step-209 build authorization still passes'; else bad 'accepted step-209 build authorization still passes'; fi
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
"$helper" --output-dir "$tmp" >/dev/null
cmp -s "$policy" "$tmp/phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause-policy.json" && ok 'helper reproduces policy deterministically' || bad 'helper reproduces policy deterministically'
cmp -s "$record" "$tmp/phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause.tsv" && ok 'helper reproduces record deterministically' || bad 'helper reproduces record deterministically'
python3 - "$policy" <<'PY210' && ok 'policy accepts exact build result and closes strong safe pause' || bad 'policy accepts exact build result and closes strong safe pause'
import json,sys
p=json.load(open(sys.argv[1])); r=p['local_source_build_result']; s=p['safe_pause']; c=p['continuation']; a=p['authorization']; rb=p['runtime_boundary_after_pause']; b=p['local_source_build_authorization']
assert p['pause_safe'] is True and p['machine_action_required'] is False and p['review_only'] is True
assert p['next_stage']=='phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review'
assert r['status']=='PASS' and r['local_source_root']=='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source'
assert r['target_package']=='kernel-headers-6.18.45-x86-1.txz' and r['target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert r['tree_manifest']=='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256' and r['tree_manifest_sha256']=='0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'
assert r['local_source_tree_built'] and r['local_source_tree_manifest_bound'] and r['local_source_tree_read_only_by_builder_contract']
assert r['single_candidate_contract_preserved'] and r['predecessor_excluded_from_local_source']
for k in ['network_access_performed','package_action_performed','slackpkg_configuration_change_performed','boot_action_performed','reboot_performed']: assert r[k] is False
assert b['state']=='consumed-pass-authority-revoked' and not b['builder_execution_authorized'] and not b['local_source_build_authorized']
assert b['result_review']['accepted'] and b['result_review']['single_use_build_authority_consumed'] and b['result_review']['builder_execution_authority_revoked']
assert s['pause_safe'] and s['strong_safe_pause'] and s['no_open_operational_authorization'] and not s['machine_action_required'] and not s['controller_action_required']
assert s['tree_manifest_sha256']=='0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e' and s['built_local_source_root_must_be_preserved_unchanged']
assert rb['prior_target_binding_reusable_after_pause'] is False and rb['fresh_target_revalidation_required_before_any_machine_action']
assert rb['local_source_tree_revalidation_required_before_runtime'] and rb['fresh_candidate_set_required_before_runtime']
assert c['future_work_requires_fresh_boundary'] and c['next_stage']=='phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review' and c['family_closed'] is False
assert p['gates']['acceptance_matrix_complete'] is False and p['gates']['kernel_package_edge_family_closed'] is False
assert all(v is False for v in a.values()), a
PY210
check_line 'record marks strong safe pause' $'pause_state\tstrong-safe-pause'
check_line 'record marks pause safe' $'pause_safe\tyes'
check_line 'record accepts build PASS' $'build_result_status\tPASS'
check_line 'record freezes builder SHA' $'builder_sha256\t59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92'
check_line 'record marks local source built' $'local_source_tree_built\tyes'
check_line 'record binds target SHA' $'target_sha256\tc7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
check_line 'record binds tree manifest SHA' $'tree_manifest_sha256\t0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'
check_line 'record binds local-source manifest' $'local_source_tree_manifest_bound\tyes'
check_line 'record consumes build authority' $'build_authority_consumed\tyes'
check_line 'record revokes builder execution' $'builder_execution_authorized\tno'
check_line 'record revokes local-source build' $'local_source_build_authorized\tno'
check_line 'record keeps repository refresh forbidden' $'repository_refresh_authorized\tno'
check_line 'record keeps runtime execution forbidden' $'runtime_scenario_execution_authorized\tno'
check_line 'record keeps package action forbidden' $'package_action_authorized\tno'
check_line 'record keeps boot action forbidden' $'boot_action_authorized\tno'
check_line 'record keeps reboot forbidden' $'reboot_authorized\tno'
check_line 'record expires prior target binding' $'prior_target_binding_reusable_after_pause\tno'
check_line 'record requires fresh target revalidation later' $'fresh_target_revalidation_required_before_any_machine_action\tyes'
check_line 'record requires source-tree revalidation before runtime' $'local_source_tree_revalidation_required_before_runtime\tyes'
check_line 'record requires fresh candidate set before runtime' $'fresh_candidate_set_required_before_runtime\tyes'
check_line 'record requires no machine action' $'machine_action_required\tno'
check_line 'record requires no controller action' $'controller_action_required\tno'
check_line 'record has no open operational authorization' $'no_open_operational_authorization\tyes'
check_line 'record requires fresh continuation boundary' $'future_work_requires_fresh_boundary\tyes'
check_line 'record keeps acceptance matrix open' $'acceptance_matrix_complete\tno'
check_line 'record routes to fresh post-build resume boundary' $'next_stage\tphase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review'
if grep -Fq 'Strong safe pause' "$doc" && grep -Fq '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e' "$doc" && grep -Fq 'Runtime identity expiry' "$doc"; then ok 'reference document records build result, manifest binding, and strong safe pause'; else bad 'reference document records build result, manifest binding, and strong safe pause'; fi
if grep -Fq 'Phase 1 step 210 kernel-package-edge local-source build result review and strong safe pause' "$repo_root/CHANGELOG.md"; then ok 'CHANGELOG records step 210'; else bad 'CHANGELOG records step 210'; fi
if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget|rsync|scp|ssh)[[:space:]]' "$helper"; then bad 'step-210 helper contains no executable network/package/boot/reboot command'; else ok 'step-210 helper contains no executable network/package/boot/reboot command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail -eq 0 ]] && echo PASS || echo FAIL)" "$pass" "$fail"
[[ $fail -eq 0 ]]
