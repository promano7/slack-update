#!/bin/bash
set -u
IFS=$'\n\t'
export LC_ALL=C

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review.md"
policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review-policy.json"
record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review.tsv"
changelog="$repo_root/CHANGELOG.md"
step250_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause.sh"
step250_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause.md"
step250_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause-harness.sh"
step250_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause-policy.json"
step250_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause.tsv"
step246_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze-policy.json"
step246_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze.tsv"

check_file() {
    local file=$1 label=$2
    [[ -f $file && ! -L $file ]] && pass "$label exists as regular file" || fail "$label exists as regular file"
}

check_sha() {
    local file=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$file" 2>/dev/null | awk '{print $1}')
    [[ $actual == "$expected" ]] && pass "$label SHA-256 matches" || fail "$label SHA-256 matches"
}

record_value() {
    local key=$1
    awk -F '\t' -v k="$key" '$1 == k { sub(/^[^\t]*\t/, ""); print; exit }' "$record"
}

for spec in \
    "$helper|step-251 helper" \
    "$doc|step-251 document" \
    "$policy|step-251 policy" \
    "$record|step-251 record" \
    "$changelog|CHANGELOG" \
    "$step250_helper|accepted step-250 helper" \
    "$step250_doc|accepted step-250 document" \
    "$step250_harness|accepted step-250 harness" \
    "$step250_policy|accepted step-250 policy" \
    "$step250_record|accepted step-250 record" \
    "$step246_policy|accepted step-246 policy" \
    "$step246_record|accepted step-246 record"; do
    IFS='|' read -r path label <<<"$spec"
    check_file "$path" "$label"
done

check_sha "$step250_helper" '42d9f34ab315435d121f2b03660330ffefc4620600af090ad16df557ab0da948' 'accepted step-250 helper'
check_sha "$step250_doc" '23f19c62e16624e077f01b892115c7549d5b4c64a9901bbeb37791490efaa1f6' 'accepted step-250 document'
check_sha "$step250_harness" 'c82edeafd56a3e7f55d4ea65def0b60ae0469e93583266d5d62e128e82d53768' 'accepted step-250 harness'
check_sha "$step250_policy" '66cad52375c1d3945c90af3ece869dd5a3178a3a9e6875e0ba76bbf458a52a0c' 'accepted step-250 policy'
check_sha "$step250_record" '45a23c6f33a34d834dbfdb569045f33ea87e21cab04033579eaebe31303f4701' 'accepted step-250 record'
check_sha "$step246_policy" 'cf32f3d6b5df64d176c154e506c356c53e63da794c961edbbcbf1557ecef25f0' 'accepted step-246 policy'
check_sha "$step246_record" '2f55b4a83a498fdf1c347ba2f35c25b5b0a3a87233f3df66f2362cfa12491071' 'accepted step-246 record'
check_sha "$helper" '4f1313ecdfb852e055c7c316cdfa0d88343f7553c8cb44dd7b4980175a09163d' 'step-251 helper'
check_sha "$doc" '30fb7202fa0142c3ce308b4c6071c84128bfcd791207858c1d9cb6a7d4c198fc' 'step-251 document'
check_sha "$policy" '8bf9a935033695491467abb1bc24af4437a3dcb454e25914094c4d0f2c222cba' 'step-251 policy'
check_sha "$record" '50fa21c28ac444ef7edbe379cb204f6d649d4e78bd64480df1b0fe6f568309c6' 'step-251 record'

if bash -n "$helper"; then pass 'step-251 helper passes bash syntax validation'; else fail 'step-251 helper passes bash syntax validation'; fi
if "$helper" --help >/dev/null; then pass 'step-251 helper exposes non-mutating help'; else fail 'step-251 helper exposes non-mutating help'; fi
if "$helper" --bad >/dev/null 2>&1; then fail 'step-251 helper rejects unknown option'; else pass 'step-251 helper rejects unknown option'; fi

tmp=$(mktemp -d)
trap 'rm -rf -- "$tmp"' EXIT
if "$helper" --output-dir "$tmp" >"$tmp/output.tsv"; then pass 'step-251 helper executes successfully'; else fail 'step-251 helper executes successfully'; fi
cmp -s "$tmp/$(basename "$policy")" "$policy" && pass 'helper reproduces frozen policy exactly' || fail 'helper reproduces frozen policy exactly'
cmp -s "$tmp/$(basename "$record")" "$record" && pass 'helper reproduces frozen record exactly' || fail 'helper reproduces frozen record exactly'

if python3 - "$policy" <<'PY'
import json
import sys

p = json.load(open(sys.argv[1], encoding='utf-8'))
assert p['schema'] == 1
assert p['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review'
assert p['step'] == 251 and p['review_only'] is True and p['review_status'] == 'PASS'
a = p['accepted_checkpoint']
assert a['step'] == 250 and a['strong_safe_pause'] is True and a['no_open_operational_authorization'] is True
assert a['accepted_local_source_v3_tree_manifest_sha256'] == '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'
assert a['accepted_target_sha256'] == 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert a['accepted_builder_r1_sha256'] == '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
c = p['frozen_executor_v2_contract_checkpoint']
assert c['step'] == 246 and c['state'] == 'reviewed-frozen-not-implemented'
assert c['source_generation'] == 'local-source-v3'
assert c['implementation_must_wait_for_accepted_v3_manifest_identity'] is True
f = p['fresh_boundary']
assert f['opened'] is True
assert f['scope'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning'
assert f['kernel_package_edge_family_state'] == 'open-runtime-remediation-v2-pending'
assert f['phase_1_acceptance_matrix_complete'] is False
assert f['runtime_chain_open'] is False and f['runtime_candidate_set_bound'] is False
assert f['runtime_executor_v2_contract_frozen'] is True
assert f['accepted_v3_manifest_bound_as_future_executor_input'] is True
assert f['runtime_executor_v2_implementation_open'] is False
v = p['accepted_local_source_v3']
assert v['state'] == 'built-accepted-preserve-unchanged-resume-boundary'
assert v['tree_manifest_sha256'] == '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'
assert v['target_sha256'] == 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
x = p['future_executor_v2_contract']
assert x['state'] == 'reviewed-frozen-not-implemented'
assert x['source_generation'] == 'local-source-v3'
assert x['accepted_local_source_v3_tree_manifest_sha256'] == v['tree_manifest_sha256']
assert x['accepted_target_sha256'] == v['target_sha256']
assert x['manifest_identity_binding_state'] == 'bound-for-future-implementation-after-fresh-revalidation'
assert x['implementation_authorized_now'] is False and x['runtime_authorized_now'] is False
rsc = x['refresh_success_contract']
assert rsc['human_spaced_error_prefix'] == 'Error downloading from '
assert rsc['human_spaced_error_must_fail_closed'] is True
assert rsc['hyphenated_literal_guard_forbidden'] is True
assert rsc['slackpkg_exit_zero_required'] is True and rsc['slackpkg_exit_zero_sufficient'] is False
assert rsc['fresh_transaction_owned_pkglist_required'] is True
assert rsc['same_transaction_candidate_binding_required'] is True
r = p['revalidation_boundary']
assert r['fresh_target_revalidation_required_before_any_machine_action'] is True
assert r['accepted_local_source_v3_tree_revalidation_required_before_executor_implementation_or_runtime_use'] is True
assert r['accepted_local_source_v3_tree_manifest_sidecar_must_verify'] is True
assert r['accepted_local_source_v3_tree_contents_must_verify_against_manifest'] is True
assert r['prior_boot_id_reusable'] is False
assert r['prior_package_database_manifest_reusable'] is False
assert r['prior_prebuild_observation_reusable'] is False
assert r['prior_candidate_binding_reusable'] is False
assert r['prior_runtime_authorization_reusable'] is False
assert r['prior_builder_authorization_reusable'] is False
assert r['fresh_candidate_set_required_before_runtime_rerun'] is True
assert r['target_observation_authorized_now'] is False
assert r['revalidation_probe_design_authorized_now'] is False
assert r['runtime_executor_v2_implementation_authorized_now'] is False
b = p['runtime_executor_v2_boundary']
assert b['contract_frozen'] is True and b['accepted_v3_manifest_identity_bound'] is True
assert b['implementation_state'] == 'closed-pending-fresh-target-and-v3-tree-revalidation'
assert b['historical_failed_executor_runtime_authority_reusable'] is False
assert b['human_spaced_error_prefix_required'] == 'Error downloading from '
assert b['hyphenated_error_literal_guard_forbidden'] is True
assert b['fresh_transaction_owned_pkglist_required'] is True
assert b['same_transaction_target_specific_candidate_binding_required'] is True
assert b['runtime_network_access_forbidden'] is True
for value in p['authorization'].values():
    assert value is False
assert p['machine_action_required'] is False
assert p['controller_action_required'] is False
assert p['future_work_requires_explicit_authorization'] is True
assert p['pause_safe'] is False
assert p['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review'
PY
then pass 'step-251 policy semantic assertions pass'; else fail 'step-251 policy semantic assertions pass'; fi

for pair in \
    'step:251' 'review_status:PASS' 'accepted_checkpoint_step:250' \
    'accepted_checkpoint_strong_safe_pause:yes' 'accepted_checkpoint_no_open_operational_authorization:yes' \
    'fresh_boundary:yes' 'family_state:open-runtime-remediation-v2-pending' 'acceptance_matrix_complete:no' \
    'accepted_local_source_v3_preserve_unchanged:yes' \
    'local_source_v3_tree_manifest_sha256:8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b' \
    'staged_target_sha256:c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c' \
    'builder_r1_sha256:80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30' \
    'executor_v2_contract_frozen:yes' 'executor_v2_bound_to_accepted_v3_manifest:yes' 'executor_v2_implementation_open:no' \
    'fresh_target_revalidation_required_before_any_machine_action:yes' \
    'local_source_v3_tree_revalidation_required_before_executor_implementation_or_runtime_use:yes' \
    'local_source_v3_tree_manifest_sidecar_must_verify:yes' 'local_source_v3_tree_contents_must_verify_against_manifest:yes' \
    'prior_boot_id_reusable:no' 'prior_package_database_manifest_reusable:no' 'prior_prebuild_observation_reusable:no' \
    'prior_candidate_binding_reusable:no' 'prior_runtime_authorization_reusable:no' 'prior_builder_authorization_reusable:no' \
    'fresh_candidate_set_required_before_runtime_rerun:yes' 'hyphenated_error_literal_guard_forbidden:yes' \
    'fresh_transaction_owned_pkglist_required:yes' 'target_observation_authorized:no' 'probe_transport_copy_authorized:no' \
    'runtime_executor_v2_implementation_authorized:no' 'runtime_executor_v2_transport_authorized:no' \
    'runtime_candidate_binding_authorized:no' 'runtime_rerun_authorized:no' 'package_action_authorized:no' \
    'slackpkg_mutation_authorized:no' 'repository_refresh_authorized:no' 'network_access_authorized:no' \
    'boot_action_authorized:no' 'reboot_authorized:no' 'evidence_cleanup_authorized:no' 'phase_2_start_authorized:no' \
    'machine_action_required:no' 'controller_action_required:no' 'future_work_requires_explicit_authorization:yes' \
    'pause_safe:no' \
    'next_stage:phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review'; do
    key=${pair%%:*}
    value=${pair#*:}
    [[ $(record_value "$key") == "$value" ]] && pass "record freezes: $key" || fail "record freezes: $key"
done

[[ $(record_value 'human_spaced_error_prefix_required') == 'Error downloading from ' ]] && pass 'record freezes exact human-spaced Slackpkg error prefix' || fail 'record freezes exact human-spaced Slackpkg error prefix'
grep -Fq 'repository-only planning boundary' "$doc" && pass 'reference document opens a repository-only boundary' || fail 'reference document opens a repository-only boundary'
grep -Fq '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b' "$doc" && pass 'reference document freezes the accepted v3 manifest identity' || fail 'reference document freezes the accepted v3 manifest identity'
grep -Fq 'Binding the manifest identity is not implementation authorization.' "$doc" && pass 'reference document keeps executor-v2 implementation closed' || fail 'reference document keeps executor-v2 implementation closed'
grep -Fq 'does not yet authorize design, transport, or execution of a revalidation probe' "$doc" && pass 'reference document keeps target observation closed' || fail 'reference document keeps target observation closed'
grep -Fq 'Error downloading from ' "$doc" && pass 'reference document freezes the human-spaced error guard' || fail 'reference document freezes the human-spaced error guard'
grep -Fq 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review' "$doc" && pass 'reference document names the next stage' || fail 'reference document names the next stage'
grep -Fq '## Phase 1 step 251 kernel-package-edge runtime-transaction remediation post-local-source-v3 build resume-planning boundary review' "$changelog" && pass 'CHANGELOG records step 251' || fail 'CHANGELOG records step 251'

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(curl|wget|ftp|rsync|ssh|scp|slackpkg|upgradepkg|installpkg|removepkg|grub-install|grub-mkconfig|mkinitrd|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail 'step-251 helper contains an operational command'
else
    pass 'step-251 helper contains no executable network, package, boot, reboot, or shutdown command'
fi

printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
