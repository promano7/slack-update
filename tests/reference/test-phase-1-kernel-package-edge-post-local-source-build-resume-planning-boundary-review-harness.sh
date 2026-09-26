#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review.sh"
policy="$acceptance_dir/phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review.tsv"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review.md"
step210_policy="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause-policy.json"
step210_record="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause.tsv"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
stager="$repo_root/tools/reference/phase-1-kernel-package-edge-target-artifact-stage.sh"

pass=0
fail=0
ok() { printf 'PASS: %s\n' "$1"; pass=$((pass + 1)); }
bad() { printf 'FAIL: %s\n' "$1"; fail=$((fail + 1)); }
check_regular() { local label=$1 file=$2; if [[ -f $file && ! -L $file ]]; then ok "$label"; else bad "$label"; fi; }
check_hash() { local label=$1 file=$2 expected=$3 actual; actual=$(sha256sum -- "$file" | awk '{print $1}'); if [[ $actual == "$expected" ]]; then ok "$label"; else bad "$label"; printf '  expected: %s\n  actual:   %s\n' "$expected" "$actual"; fi; }
check_line() { local label=$1 expected=$2; if grep -Fxq -- "$expected" "$record"; then ok "$label"; else bad "$label"; fi; }

check_regular 'step-211 helper is a regular file' "$helper"
check_regular 'step-211 policy is a regular file' "$policy"
check_regular 'step-211 record is a regular file' "$record"
check_regular 'step-211 reference document is a regular file' "$doc"
check_regular 'accepted step-210 policy is present' "$step210_policy"
check_regular 'accepted step-210 record is present' "$step210_record"
check_regular 'frozen builder is present' "$builder"
check_regular 'frozen stager is present' "$stager"
check_hash 'accepted step-210 policy identity is preserved' "$step210_policy" '14735ff6414e1014c804610dbd501518af49abd57001691d3124563e13164bc1'
check_hash 'accepted step-210 record identity is preserved' "$step210_record" '616c6220bc5e98433ca45465e7a598e22d8286c24f34439e67725c372d3789dc'
check_hash 'frozen builder identity is preserved' "$builder" '59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92'
check_hash 'frozen stager identity is preserved' "$stager" 'a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb'

if bash -n "$helper"; then ok 'step-211 helper passes bash syntax validation'; else bad 'step-211 helper passes bash syntax validation'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/stdout" 2>"$tmp/stderr"; then ok 'step-211 helper executes successfully'; else bad 'step-211 helper executes successfully'; cat "$tmp/stderr"; fi
if cmp -s -- "$policy" "$tmp/phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review-policy.json"; then ok 'generated step-211 policy matches frozen fixture'; else bad 'generated step-211 policy matches frozen fixture'; fi
if cmp -s -- "$record" "$tmp/phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review.tsv"; then ok 'generated step-211 record matches frozen fixture'; else bad 'generated step-211 record matches frozen fixture'; fi
if grep -Fqx $'boundary_review_status\tPASS' "$tmp/stdout"; then ok 'helper reports PASS boundary status'; else bad 'helper reports PASS boundary status'; fi
if grep -Fqx $'machine_action_required\tno' "$tmp/stdout"; then ok 'helper reports no machine action'; else bad 'helper reports no machine action'; fi

if python3 - "$policy" <<'PY'
import json
import sys
p = json.load(open(sys.argv[1], encoding='utf-8'))
assert p['schema'] == 1
assert p['scenario'] == 'phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review'
assert p['review_only'] is True
assert p['accepted_checkpoint']['step'] == 210
assert p['accepted_checkpoint']['strong_safe_pause'] is True
assert p['accepted_checkpoint']['no_open_operational_authorization'] is True
assert p['fresh_boundary']['opened'] is True
assert p['fresh_boundary']['selected_family_preserved'] is True
assert p['fresh_boundary']['live_runtime_chain_open'] is False
assert p['fresh_boundary']['runtime_candidate_set_bound'] is False
assert p['fresh_boundary']['prior_runtime_target_binding_reusable'] is False
assert p['selected_family']['family'] == 'kernel-package-edge'
assert p['selected_family']['family_closed'] is False
assert p['artifact_byte_binding']['predecessor_sha256'] == '3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'
assert p['artifact_byte_binding']['target_sha256'] == 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert p['artifact_byte_binding']['survives_later_publication'] is True
assert p['artifact_byte_binding']['controller_reacquisition_authorized'] is False
assert p['local_source_state']['state'] == 'built-and-manifest-bound-preserved'
assert p['local_source_state']['local_source_tree_built'] is True
assert p['local_source_state']['local_source_tree_manifest_bound'] is True
assert p['local_source_state']['tree_manifest_sha256'] == '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'
assert p['local_source_state']['built_tree_must_remain_unchanged'] is True
assert p['local_source_state']['revalidation_required_before_runtime'] is True
assert p['local_source_state']['revalidation_authorized_now'] is False
assert p['local_source_state']['builder_rerun_authorized'] is False
assert p['runtime_revalidation']['prior_target_binding_reusable'] is False
assert p['runtime_revalidation']['fresh_target_revalidation_required_before_any_machine_action'] is True
assert p['runtime_revalidation']['fresh_target_observation_authorized_now'] is False
assert p['runtime_revalidation']['local_source_tree_revalidation_required_before_runtime'] is True
assert p['runtime_revalidation']['local_source_tree_revalidation_authorized_now'] is False
assert p['runtime_revalidation']['fresh_candidate_set_required_before_runtime'] is True
assert p['runtime_revalidation']['candidate_set_binding_authorized_now'] is False
assert p['runtime_revalidation']['predecessor_package_staging_authorized_now'] is False
assert all(v is False for k, v in p['authorization'].items() if k != 'future_work_requires_explicit_authorization')
assert p['authorization']['future_work_requires_explicit_authorization'] is True
assert p['machine_action_required'] is False
assert p['controller_action_required'] is False
assert p['pause_safe'] is False
assert p['strong_safe_pause'] is False
assert p['gates']['acceptance_matrix_complete'] is False
assert p['gates']['kernel_package_edge_family_closed'] is False
assert p['next_stage'] == 'phase-1-kernel-package-edge-post-local-source-build-revalidation-review'
PY
then ok 'step-211 policy semantic assertions pass'; else bad 'step-211 policy semantic assertions pass'; fi

check_line 'record identifies step 211' $'step\t211'
check_line 'record opens fresh boundary' $'fresh_boundary\tyes'
check_line 'record preserves kernel-package-edge family' $'selected_family\tkernel-package-edge'
check_line 'record keeps family open' $'family_closed\tno'
check_line 'record preserves built local source' $'local_source_tree_built\tyes'
check_line 'record preserves manifest binding' $'local_source_tree_manifest_bound\tyes'
check_line 'record preserves accepted tree-manifest SHA-256' $'tree_manifest_sha256\t0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'
check_line 'record expires prior target binding' $'prior_target_binding_reusable\tno'
check_line 'record requires fresh target revalidation' $'fresh_target_revalidation_required_before_any_machine_action\tyes'
check_line 'record does not yet authorize target observation' $'fresh_target_observation_authorized_now\tno'
check_line 'record requires local-source revalidation' $'local_source_tree_revalidation_required_before_runtime\tyes'
check_line 'record does not yet authorize local-source revalidation' $'local_source_tree_revalidation_authorized_now\tno'
check_line 'record requires fresh candidate set' $'fresh_candidate_set_required_before_runtime\tyes'
check_line 'record does not yet authorize candidate binding' $'candidate_set_binding_authorized_now\tno'
check_line 'record forbids predecessor staging now' $'predecessor_package_staging_authorized_now\tno'
check_line 'record forbids builder rerun' $'builder_rerun_authorized\tno'
check_line 'record forbids repository refresh' $'repository_refresh_authorized\tno'
check_line 'record forbids runtime execution' $'runtime_scenario_execution_authorized\tno'
check_line 'record forbids package action' $'package_action_authorized\tno'
check_line 'record forbids boot action' $'boot_action_authorized\tno'
check_line 'record forbids reboot' $'reboot_authorized\tno'
check_line 'record requires no machine action' $'machine_action_required\tno'
check_line 'record requires no controller action' $'controller_action_required\tno'
check_line 'record is not a new strong safe pause' $'strong_safe_pause\tno'
check_line 'record routes to revalidation review' $'next_stage\tphase-1-kernel-package-edge-post-local-source-build-revalidation-review'

if grep -Fq 'Expired runtime identity' "$doc" && grep -Fq '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e' "$doc" && grep -Fq 'grants no target, controller, network, package, boot, reboot, or runtime execution authority' "$doc"; then ok 'reference document records preservation and expired runtime identity'; else bad 'reference document records preservation and expired runtime identity'; fi
if grep -Fq 'Phase 1 step 211 kernel-package-edge post-local-source-build resume-planning boundary review' "$repo_root/CHANGELOG.md"; then ok 'CHANGELOG records step 211'; else bad 'CHANGELOG records step 211'; fi
if grep -Eq '(^|[;&|[:space:]])(slackpkg|upgradepkg|installpkg|removepkg|reboot|shutdown|poweroff|curl|wget|rsync|scp|ssh)[[:space:]]' "$helper"; then bad 'step-211 helper contains no executable network/package/boot/reboot command'; else ok 'step-211 helper contains no executable network/package/boot/reboot command'; fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $fail -eq 0 ]] && echo PASS || echo FAIL)" "$pass" "$fail"
[[ $fail -eq 0 ]]
