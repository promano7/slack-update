#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review.md"
policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review-policy.json"
record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review.tsv"
step230_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause.sh"
step230_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause.md"
step230_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause-harness.sh"
step230_policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause-policy.json"
step230_record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause.tsv"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1" >&2; failures=$((failures+1)); }
check_file(){ [[ -f $1 && ! -L $1 ]] && pass "$2 is a regular non-symlink file" || fail "$2 is a regular non-symlink file"; }
check_sha(){ local actual; actual=$(sha256sum -- "$1" | awk '{print $1}'); [[ $actual == "$2" ]] && pass "$3 hash is frozen" || fail "$3 hash is frozen"; }
record_value(){ awk -F '\t' -v key="$1" '$1==key {print $2; exit}' "$record"; }

for spec in \
 "$helper|step-231 helper" "$doc|step-231 reference document" "$policy|step-231 policy" "$record|step-231 record" \
 "$step230_helper|accepted step-230 helper" "$step230_doc|accepted step-230 document" "$step230_harness|accepted step-230 harness" \
 "$step230_policy|accepted step-230 policy" "$step230_record|accepted step-230 record" "$changelog|CHANGELOG"; do
    IFS='|' read -r path label <<<"$spec"
    check_file "$path" "$label"
done

check_sha "$step230_helper" '32fa3bac652bb7de985bfa675d9b03f7b25a2ee6cc84158fe0c0c230f211882b' 'accepted step-230 helper'
check_sha "$step230_doc" '4f4579e287135a6c66442c2416fa932a6a59c5fb030df03cec3c129043b9eaca' 'accepted step-230 document'
check_sha "$step230_harness" 'ddcc0b383cba9e48eb059c6dd14c30f8fa3c0b7663889bad6322c3a329d1586e' 'accepted step-230 harness'
check_sha "$step230_policy" 'a65037c1da85360d7f9351c31a352f02208b72562ff3abc9c31ca399c8ef9beb' 'accepted step-230 policy'
check_sha "$step230_record" 'cec962a34963ea591f07edeff5f68065f9e9a258551028745bf92eaebc4f4898' 'accepted step-230 record'

if bash -n "$helper"; then pass 'step-231 helper passes bash syntax validation'; else fail 'step-231 helper passes bash syntax validation'; fi
if "$helper" --help >/dev/null; then pass 'step-231 helper exposes non-mutating help'; else fail 'step-231 helper exposes non-mutating help'; fi
if "$helper" --bad >/dev/null 2>&1; then fail 'step-231 helper rejects unknown option'; else pass 'step-231 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/output.tsv"; then pass 'step-231 helper executes successfully'; else fail 'step-231 helper executes successfully'; fi
cmp -s "$tmp/$(basename "$policy")" "$policy" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s "$tmp/$(basename "$record")" "$record" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'

if python3 - "$policy" <<'PY'
import json, sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
assert p['schema']==1
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review'
assert p['step']==231 and p['review_only'] is True and p['review_status']=='PASS'
a=p['accepted_checkpoint']
assert a['step']==230 and a['strong_safe_pause'] is True and a['no_open_operational_authorization'] is True
assert a['accepted_local_source_v2_tree_manifest_sha256']=='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'
f=p['fresh_boundary']
assert f['opened'] is True
assert f['scope']=='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning'
assert f['kernel_package_edge_family_state']=='open-runtime-remediation-pending'
assert f['phase_1_acceptance_matrix_complete'] is False
assert f['runtime_chain_open'] is False and f['runtime_candidate_set_bound'] is False
v=p['accepted_local_source_v2']
assert v['state']=='built-accepted-preserve-unchanged-resume-boundary'
assert v['tree_manifest_sha256']=='e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'
assert v['target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
r=p['revalidation_boundary']
assert r['fresh_target_revalidation_required_before_any_machine_action'] is True
assert r['accepted_local_source_v2_tree_revalidation_required_before_runtime_use'] is True
assert r['accepted_local_source_v2_tree_manifest_sidecar_must_verify'] is True
assert r['accepted_local_source_v2_tree_contents_must_verify_against_manifest'] is True
assert r['prior_boot_id_reusable'] is False
assert r['prior_package_database_manifest_reusable'] is False
assert r['prior_candidate_binding_reusable'] is False
assert r['prior_runtime_authorization_reusable'] is False
assert r['prior_builder_authorization_reusable'] is False
assert r['fresh_candidate_set_required_before_runtime_rerun'] is True
assert r['runtime_executor_remediation_review_required_before_rerun'] is True
assert r['target_observation_authorized_now'] is False
x=p['runtime_executor_boundary']
assert x['historical_executor_may_be_used_as_design_input'] is True
assert x['historical_executor_runtime_authority_reusable'] is False
assert x['must_use_local_source_v2'] is True
assert x['transaction_owned_new_empty_slackpkg_workdir_required'] is True
assert x['target_specific_candidate_guard_required'] is True
assert x['real_tab_tsv_evidence_required'] is True
assert x['refresh_exit_zero_alone_is_sufficient'] is False
assert x['no_error_downloading_signal_required'] is True
assert x['runtime_network_access_forbidden'] is True
for value in p['authorization'].values(): assert value is False
assert p['machine_action_required'] is False
assert p['controller_action_required'] is False
assert p['future_work_requires_explicit_authorization'] is True
assert p['pause_safe'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review'
PY
then pass 'step-231 policy semantic assertions pass'; else fail 'step-231 policy semantic assertions pass'; fi

for pair in \
 'step:231' 'review_status:PASS' 'accepted_checkpoint_step:230' 'accepted_checkpoint_strong_safe_pause:yes' \
 'accepted_checkpoint_no_open_operational_authorization:yes' 'fresh_boundary:yes' \
 'family_state:open-runtime-remediation-pending' 'acceptance_matrix_complete:no' \
 'accepted_local_source_v2_preserve_unchanged:yes' \
 'local_source_v2_tree_manifest_sha256:e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945' \
 'staged_target_sha256:c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c' \
 'fresh_target_revalidation_required_before_any_machine_action:yes' \
 'local_source_v2_tree_revalidation_required_before_runtime_use:yes' \
 'local_source_v2_tree_manifest_sidecar_must_verify:yes' \
 'local_source_v2_tree_contents_must_verify_against_manifest:yes' \
 'prior_boot_id_reusable:no' 'prior_package_database_manifest_reusable:no' 'prior_prebuild_observation_reusable:no' \
 'prior_candidate_binding_reusable:no' 'prior_runtime_authorization_reusable:no' 'prior_builder_authorization_reusable:no' \
 'fresh_candidate_set_required_before_runtime_rerun:yes' 'runtime_executor_remediation_review_required_before_rerun:yes' \
 'target_observation_authorized:no' 'probe_transport_copy_authorized:no' 'runtime_executor_remediation_authorized:no' \
 'runtime_rerun_authorized:no' 'package_action_authorized:no' 'slackpkg_mutation_authorized:no' \
 'repository_refresh_authorized:no' 'network_access_authorized:no' 'boot_action_authorized:no' 'reboot_authorized:no' \
 'evidence_cleanup_authorized:no' 'phase_2_start_authorized:no' 'machine_action_required:no' 'controller_action_required:no' \
 'future_work_requires_explicit_authorization:yes' 'pause_safe:no' \
 'next_stage:phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review'; do
    key=${pair%%:*}; value=${pair#*:}
    [[ $(record_value "$key") == "$value" ]] && pass "record freezes: $key" || fail "record freezes: $key"
done

grep -Fq 'repository-only planning boundary' "$doc" && pass 'reference document opens a repository-only boundary' || fail 'reference document opens a repository-only boundary'
grep -Fq 'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945' "$doc" && pass 'reference document freezes the accepted v2 manifest identity' || fail 'reference document freezes the accepted v2 manifest identity'
grep -Fq 'does not yet authorize design or transport of a revalidation probe' "$doc" && pass 'reference document keeps target observation closed' || fail 'reference document keeps target observation closed'
grep -Fq 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review' "$doc" && pass 'reference document names the next stage' || fail 'reference document names the next stage'
grep -Fq '## Phase 1 step 231 kernel-package-edge runtime-transaction remediation post-local-source-v2-build resume-planning boundary review' "$changelog" && pass 'CHANGELOG records step 231' || fail 'CHANGELOG records step 231'

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(curl|wget|ftp|rsync|ssh|scp|slackpkg|upgradepkg|installpkg|removepkg|grub-install|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail 'step-231 helper contains an operational command'
else
    pass 'step-231 helper contains no executable network, package, boot, reboot, or shutdown command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
