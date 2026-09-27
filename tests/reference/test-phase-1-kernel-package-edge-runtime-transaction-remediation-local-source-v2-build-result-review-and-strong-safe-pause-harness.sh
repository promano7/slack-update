#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review'
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh"
helper="$repo_root/tools/reference/${base}.sh"
doc="$repo_root/docs/reference/${base}.md"
policy="$acc/${base}-policy.json"
record="$acc/${base}.tsv"
prev_helper="$repo_root/tools/reference/${prev}.sh"
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
for item in "$builder|frozen v2 builder" "$helper|step-230 helper" "$doc|step-230 reference document" "$policy|step-230 policy" "$record|step-230 record" "$prev_helper|accepted step-229 helper" "$prev_doc|accepted step-229 document" "$prev_harness|accepted step-229 harness" "$prev_policy|accepted step-229 policy" "$prev_record|accepted step-229 record" "$changelog|CHANGELOG"; do IFS='|' read -r path label <<< "$item"; check_regular "$path" "$label"; done
check_hash "$builder" '8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d' 'frozen v2 builder'
check_hash "$prev_helper" 'f2bc0431a0481e52ee9f577f6d57f40831aa3ce1d17fda7416fbbc43115fac46' 'accepted step-229 helper'
check_hash "$prev_doc" '7e2fd6c8f16884344fb0c3b60ccff350364469c23a646255ad38c8d0b2893cfe' 'accepted step-229 document'
check_hash "$prev_harness" '2a6ffcd9fc68f6ca0303f2c2b9bb608e51d75d33f18ee69130b207dcc4e9ea64' 'accepted step-229 harness'
check_hash "$prev_policy" '1a0123363f811b57108f5947512d1655c11d5c11d9e41ab0216f3edd6fe8ae73' 'accepted step-229 policy'
check_hash "$prev_record" '6904c6046ae6e778b3de8762e078b91b63c2d57d13ecdca3a5924a3c0749d86a' 'accepted step-229 record'
bash -n "$builder" && pass 'frozen v2 builder passes bash syntax validation' || fail 'frozen v2 builder passes bash syntax validation'
bash -n "$helper" && pass 'step-230 helper passes bash syntax validation' || fail 'step-230 helper passes bash syntax validation'
"$helper" --help >/dev/null && pass 'step-230 helper exposes non-mutating help' || fail 'step-230 helper exposes non-mutating help'
if "$helper" --unknown >/dev/null 2>&1; then fail 'step-230 helper rejects unknown option'; else pass 'step-230 helper rejects unknown option'; fi
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
"$helper" --output-dir "$tmp" && pass 'step-230 helper executes successfully' || fail 'step-230 helper executes successfully'
cmp -s "$tmp/${base}-policy.json" "$policy" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s "$tmp/${base}.tsv" "$record" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'
python3 - "$policy" <<'PYSEM'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['step']==230 and p['review_status']=='PASS' and p['review_only'] is True
assert p['revision']=='accepted-local-source-v2-build-result-strong-safe-pause'
assert p['build_result_state']=='accepted-pass-build-authority-consumed'
r=p['consumed_build_result']
assert r['local_source_v2_build_status']=='PASS'
assert r['local_source_v2_root']=='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2'
assert r['target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert r['tree_manifest_sha256']=='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'
assert r['compatibility_asc_present']=='yes'
for k in ('network_access_performed','package_action_performed','slackpkg_configuration_change_performed','boot_action_performed','reboot_performed'):
    assert r[k]=='no'
assert p['accepted_local_source_v2']['state']=='built-accepted-preserve-unchanged'
assert p['accepted_local_source_v2']['tree_manifest_sha256']=='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'
assert p['builder_implementation']['state']=='implemented-frozen-executed-pass-authority-consumed'
assert p['local_source_v2_design']['state']=='design-frozen-implementation-frozen-built-accepted'
for k,v in p['authorization'].items():
    assert v is False, (k,v)
rb=p['runtime_boundary_after_pause']
assert rb['prior_target_binding_reusable_after_pause'] is False
assert rb['fresh_target_revalidation_required_before_any_machine_action'] is True
assert rb['local_source_v2_tree_revalidation_required_before_runtime'] is True
assert rb['fresh_candidate_set_required_before_runtime'] is True
assert rb['runtime_executor_remediation_review_required_before_rerun'] is True
sp=p['safe_pause']
assert sp['strong_safe_pause'] is True and sp['pause_safe'] is True and sp['no_open_operational_authorization'] is True
assert p['machine_action_required'] is False and p['controller_action_required'] is False
assert p['pause_safe'] is True and p['strong_safe_pause'] is True
assert p['family_closed'] is False and p['phase_1_acceptance_matrix_complete'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review'
PYSEM
[[ $? -eq 0 ]] && pass 'step-230 policy semantic assertions pass' || fail 'step-230 policy semantic assertions pass'
for key in step review_status revision pause_state pause_safe strong_safe_pause selected_family family_closed acceptance_matrix_complete builder_sha256 build_result_status local_source_v2_tree_built local_source_v2_root target_sha256 priority_trees compatibility_asc_present tree_manifest_path tree_manifest_sha256 tree_manifest_sha256_path build_authority_consumed local_source_v2_builder_execution_authorized local_source_v2_build_authorized repository_refresh_authorized runtime_candidate_binding_authorized runtime_executor_remediation_authorized runtime_rerun_authorized package_action_authorized boot_action_authorized reboot_authorized phase_2_start_authorized prior_target_binding_reusable_after_pause fresh_target_revalidation_required_before_any_machine_action local_source_v2_tree_revalidation_required_before_runtime fresh_candidate_set_required_before_runtime runtime_executor_remediation_review_required_before_rerun machine_action_required controller_action_required no_open_operational_authorization future_work_requires_fresh_boundary next_stage; do [[ -n $(record_value "$key") ]] && pass "record contains $key" || fail "record contains $key"; done
[[ $(record_value step) == 230 ]] && pass 'record freezes step 230' || fail 'record freezes step 230'
[[ $(record_value build_result_status) == PASS ]] && pass 'record accepts v2 build PASS' || fail 'record accepts v2 build PASS'
[[ $(record_value tree_manifest_sha256) == 'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945' ]] && pass 'record freezes accepted v2 tree-manifest SHA-256' || fail 'record freezes accepted v2 tree-manifest SHA-256'
[[ $(record_value build_authority_consumed) == yes ]] && pass 'record consumes build authority' || fail 'record consumes build authority'
[[ $(record_value no_open_operational_authorization) == yes ]] && pass 'record closes all operational authority' || fail 'record closes all operational authority'
[[ $(record_value pause_safe) == yes && $(record_value strong_safe_pause) == yes ]] && pass 'record establishes strong safe pause' || fail 'record establishes strong safe pause'
[[ $(record_value prior_target_binding_reusable_after_pause) == no ]] && pass 'record expires prior runtime binding' || fail 'record expires prior runtime binding'
[[ $(record_value next_stage) == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review' ]] && pass 'record names fresh resume boundary next' || fail 'record names fresh resume boundary next'
grep -Fq '## Strong safe pause' "$doc" && grep -Fq 'No target observation, controller transport, builder execution' "$doc" && grep -Fq 'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945' "$doc" && pass 'reference document defines accepted v2 result and strong safe pause' || fail 'reference document defines accepted v2 result and strong safe pause'
grep -Fq '## Phase 1 step 230 kernel-package-edge runtime-transaction remediation local-source-v2 build result review and strong safe pause' "$changelog" && pass 'CHANGELOG records step 230' || fail 'CHANGELOG records step 230'
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget)[[:space:]]' "$helper"; then fail 'step-230 helper contains executable machine mutation command'; else pass 'step-230 helper contains no executable machine mutation command'; fi
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
