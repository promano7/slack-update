#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review.md"
policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review-policy.json"
record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review.tsv"
step220_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause.sh"
step220_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause.md"
step220_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause-harness.sh"
step220_policy="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause-policy.json"
step220_record="$acc/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause.tsv"
changelog="$repo_root/CHANGELOG.md"

passes=0
failures=0
pass(){ printf 'PASS: %s\n' "$1"; passes=$((passes+1)); }
fail(){ printf 'FAIL: %s\n' "$1" >&2; failures=$((failures+1)); }
check_file(){ [[ -f $1 && ! -L $1 ]] && pass "$2 is a regular non-symlink file" || fail "$2 is a regular non-symlink file"; }
check_sha(){ local actual; actual=$(sha256sum -- "$1" | awk '{print $1}'); [[ $actual == "$2" ]] && pass "$3 hash is frozen" || fail "$3 hash is frozen"; }
record_value(){ awk -F '\t' -v key="$1" '$1==key {print $2; exit}' "$record"; }

for spec in \
 "$helper|step-221 helper" "$doc|step-221 reference document" "$policy|step-221 policy" "$record|step-221 record" \
 "$step220_helper|accepted step-220 helper" "$step220_doc|accepted step-220 document" "$step220_harness|accepted step-220 harness" \
 "$step220_policy|accepted step-220 policy" "$step220_record|accepted step-220 record" "$changelog|CHANGELOG"; do
    IFS='|' read -r path label <<<"$spec"
    check_file "$path" "$label"
done

check_sha "$step220_helper" '3d3002f5eb5063d7ac92a84dced9884953f0a4ee31d29c34fc395cd55a99191c' 'accepted step-220 helper'
check_sha "$step220_doc" '94cc57bac133a42ffcfe7bd234f279bae42cc9d69928945fabdfc076b87227a4' 'accepted step-220 document'
check_sha "$step220_harness" 'b07d1a41b774be3edc891af0db4fd970d26e3ef04f498004f30b894362844dd6' 'accepted step-220 harness'
check_sha "$step220_policy" 'f52b276f8c93d4e939b7093be95236ba719039dbb5d8d2fae850f3ac810a49a4' 'accepted step-220 policy'
check_sha "$step220_record" 'a91b731dcd27be6c57bfbca62c660bb92e3d75a94ba8e37e1f8d2d94fdbc68fe' 'accepted step-220 record'

if bash -n "$helper"; then pass 'step-221 helper passes bash syntax validation'; else fail 'step-221 helper passes bash syntax validation'; fi
if "$helper" --help >/dev/null; then pass 'step-221 helper exposes non-mutating help'; else fail 'step-221 helper exposes non-mutating help'; fi
if "$helper" --bad >/dev/null 2>&1; then fail 'step-221 helper rejects unknown option'; else pass 'step-221 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/output.tsv"; then pass 'step-221 helper executes successfully'; else fail 'step-221 helper executes successfully'; fi
cmp -s "$tmp/$(basename "$policy")" "$policy" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s "$tmp/$(basename "$record")" "$record" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'

if python3 - "$policy" <<'PY'
import json, sys
p=json.load(open(sys.argv[1], encoding='utf-8'))
assert p['schema']==1
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review'
assert p['step']==221 and p['review_only'] is True and p['review_status']=='PASS'
a=p['accepted_checkpoint']
assert a['step']==220 and a['strong_safe_pause'] is True and a['no_open_operational_authorization'] is True
f=p['fresh_boundary']
assert f['opened'] is True
assert f['scope']=='phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning'
assert f['kernel_package_edge_family_state']=='open-remediation-pending'
assert f['phase_1_acceptance_matrix_complete'] is False
assert f['runtime_chain_open'] is False and f['runtime_candidate_set_bound'] is False
pr=p['preservation_contract']
assert pr['local_source_v1_must_be_preserved_unchanged'] is True
assert pr['failed_runtime_evidence_root_must_be_preserved_unchanged'] is True
assert pr['local_source_v1_may_be_modified_in_place'] is False
r=p['remediation_contract']
assert r['new_local_source_generation_required'] is True
assert r['new_local_source_generation_name']=='local-source-v2'
assert r['CHECKSUMS_md5_asc_compatibility_artifact_required'] is True
assert r['priority_tree_metadata_required'] is True
assert r['refresh_success_requires_exit_zero'] is True
assert r['refresh_success_requires_no_error_downloading_signal'] is True
assert r['refresh_success_requires_workdir_metadata_freshness_proof'] is True
assert r['candidate_guard_scope']=='target-specific-not-global-pkglist-row-count'
assert r['evidence_encoding']=='real-tab-tsv'
assert r['remediation_must_be_revalidated_before_package_mutation'] is True
assert r['design_authorized_now'] is False and r['build_authorized_now'] is False and r['runtime_validation_authorized_now'] is False
rv=p['runtime_revalidation']
assert rv['fresh_target_revalidation_required_before_any_machine_action'] is True
assert rv['target_observation_authorized_now'] is False
assert rv['prior_target_binding_reusable'] is False
assert rv['prior_runtime_authorization_reusable'] is False
assert rv['prior_candidate_binding_reusable'] is False
assert rv['prior_failed_executor_authorization_reusable'] is False
assert rv['fresh_candidate_binding_required_before_runtime_rerun'] is True
for key,value in p['authorization'].items():
    if key=='future_work_requires_explicit_authorization': assert value is True
    else: assert value is False
assert p['machine_action_required'] is False
assert p['controller_action_required'] is False
assert p['pause_safe'] is False
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review'
PY
then pass 'step-221 policy semantic assertions pass'; else fail 'step-221 policy semantic assertions pass'; fi

for pair in \
 'step:221' 'review_status:PASS' 'accepted_checkpoint_step:220' 'accepted_checkpoint_strong_safe_pause:yes' \
 'fresh_boundary:yes' 'kernel_package_edge_family_state:open-remediation-pending' 'phase_1_acceptance_matrix_complete:no' \
 'local_source_v1_must_be_preserved_unchanged:yes' 'failed_runtime_evidence_root_must_be_preserved_unchanged:yes' \
 'new_local_source_generation_required:yes' 'new_local_source_generation_name:local-source-v2' \
 'local_source_v2_design_authorized:no' 'local_source_v2_build_authorized:no' \
 'remediation_must_be_revalidated_before_package_mutation:yes' \
 'fresh_target_revalidation_required_before_any_machine_action:yes' 'target_observation_authorized_now:no' \
 'prior_target_binding_reusable:no' 'prior_runtime_authorization_reusable:no' 'prior_candidate_binding_reusable:no' \
 'prior_failed_executor_authorization_reusable:no' 'fresh_candidate_binding_required_before_runtime_rerun:yes' \
 'runtime_rerun_authorized:no' 'package_action_authorized:no' 'slackpkg_mutation_authorized:no' \
 'repository_refresh_authorized:no' 'network_access_authorized:no' 'boot_action_authorized:no' 'reboot_authorized:no' \
 'evidence_cleanup_authorized:no' 'phase_2_start_authorized:no' 'machine_action_required:no' 'controller_action_required:no' \
 'future_work_requires_explicit_authorization:yes' 'pause_safe:no' \
 'next_stage:phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review'; do
    key=${pair%%:*}; value=${pair#*:}
    [[ $(record_value "$key") == "$value" ]] && pass "record freezes: $key" || fail "record freezes: $key"
done

grep -Fq 'fresh repository-only planning boundary' "$doc" && pass 'reference document opens a repository-only boundary' || fail 'reference document opens a repository-only boundary'
grep -Fq 'local-source-v2' "$doc" && pass 'reference document preserves v2 remediation' || fail 'reference document preserves v2 remediation'
grep -Fq 'authorizes no target observation' "$doc" && pass 'reference document keeps machine observation closed' || fail 'reference document keeps machine observation closed'
grep -Fq 'phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review' "$doc" && pass 'reference document names the next stage' || fail 'reference document names the next stage'
grep -Fq '## Phase 1 step 221 kernel-package-edge runtime transaction remediation resume-planning boundary review' "$changelog" && pass 'CHANGELOG records step 221' || fail 'CHANGELOG records step 221'

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(curl|wget|ftp|rsync|ssh|scp|slackpkg|upgradepkg|installpkg|removepkg|grub-install|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail 'step-221 helper contains an operational command'
else
    pass 'step-221 helper contains no executable network, package, boot, reboot, or shutdown command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
