#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
repo_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause'
helper="$repo_root/tools/reference/${base}.sh"; doc="$repo_root/docs/reference/${base}.md"; policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}-policy.json"; record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${base}.tsv"
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-builder-output-remediation-freeze-and-build-authorization-review'; prev_helper="$repo_root/tools/reference/${prev}.sh"; prev_doc="$repo_root/docs/reference/${prev}.md"; prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"; prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"; prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh"
passes=0; failures=0
assert() { local label=$1; shift; if "$@"; then printf 'PASS: %s\n' "$label"; passes=$((passes+1)); else printf 'FAIL: %s\n' "$label"; failures=$((failures+1)); fi; }
regular() { [[ -f $1 && ! -L $1 ]]; }
hash_is() { [[ $(sha256sum -- "$1" | awk '{print $1}') == "$2" ]]; }
record_is() { grep -Fxq "$1"$'\t'"$2" "$record"; }
for item in "$helper" "$doc" "$policy" "$record" "$builder"; do assert "step-250 ${item##*/} is a regular non-symlink file" regular "$item"; done
for item in "$prev_helper" "$prev_doc" "$prev_harness" "$prev_policy" "$prev_record"; do assert "accepted step-249 ${item##*/} is a regular non-symlink file" regular "$item"; done
assert 'accepted step-249 helper hash is frozen' hash_is "$prev_helper" '38da99cfd70ea81e6b6b48e1c60fd61f5a7224aa05b1dcb9b10a7482ab606b0b'
assert 'accepted step-249 document hash is frozen' hash_is "$prev_doc" 'c13452fa99a40789a8f475251f7283fdc2b0e029915d48e272d2ade61d5f80a7'
assert 'accepted step-249 harness hash is frozen' hash_is "$prev_harness" 'e84ca066c634a509c5899f128b272aede9c96080359355645110a9c2e1c3ba8f'
assert 'accepted step-249 policy hash is frozen' hash_is "$prev_policy" '63bb296e1ec1be3b329ffb8829c0a1c2fbc147e618f573380d590201192da790'
assert 'accepted step-249 record hash is frozen' hash_is "$prev_record" '9ac3d58470452f686a1e575c9ca3d07110cdb617587d93034e9405aa6165cb83'
assert 'accepted corrected builder r1 hash remains exact' hash_is "$builder" '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
assert 'step-250 helper passes bash syntax validation' bash -n "$helper"
assert 'step-250 helper exposes non-mutating help' bash -c '"$1" --help >/dev/null' _ "$helper"
assert 'step-250 helper rejects unknown option' bash -c '! "$1" --bad >/dev/null 2>&1' _ "$helper"
repro=$(mktemp -d); trap 'rm -rf -- "$repro"' EXIT
assert 'step-250 helper executes successfully' "$helper" --output-dir "$repro"
assert 'helper reproduces frozen policy exactly' cmp -s "$policy" "$repro/${base}-policy.json"
assert 'helper reproduces frozen record exactly' cmp -s "$record" "$repro/${base}.tsv"
assert 'step-250 policy semantic assertions pass' python3 - "$policy" <<'PYSEM'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['step']==250 and p['review_status']=='PASS'
assert p['build_result_state']=='accepted-pass-build-authority-consumed'
assert p['consumed_build_result']['local_source_v3_build_status']=='PASS'
assert p['consumed_build_result']['tree_manifest_sha256']=='8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'
assert p['accepted_local_source_v3']['state']=='built-accepted-preserve-unchanged'
assert p['accepted_local_source_v3']['compatibility_asc_PGP_marker_present'] is True
assert p['accepted_local_source_v3']['compatibility_asc_is_not_openpgp_signature'] is True
assert p['runtime_boundary_after_pause']['prior_prebuild_observation_state']=='expired-at-strong-safe-pause'
assert p['runtime_boundary_after_pause']['accepted_v3_manifest_identity_required_before_executor_v2_implementation'] is True
assert p['future_executor_v2_state']=='reviewed-frozen-not-implemented'
assert p['pause_safe'] is True and p['strong_safe_pause'] is True
assert p['machine_action_required'] is False and p['controller_action_required'] is False
assert p['safe_pause']['no_open_operational_authorization'] is True
assert all(v is False for v in p['authorization'].values())
assert p['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review'
PYSEM
assert 'record freezes PASS build result' record_is build_result_status PASS
assert 'record freezes strong safe pause' record_is strong_safe_pause yes
assert 'record freezes accepted v3 manifest' record_is tree_manifest_sha256 '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'
assert 'record consumes build authority' record_is build_authority_consumed yes
assert 'record closes builder transport' record_is local_source_v3_builder_transport_authorized no
assert 'record closes builder execution' record_is local_source_v3_builder_execution_authorized no
assert 'record closes v3 build' record_is local_source_v3_build_authorized no
assert 'record keeps executor v2 implementation closed' record_is runtime_executor_v2_implementation_authorized no
assert 'record keeps executor v2 transport closed' record_is runtime_executor_v2_transport_authorized no
assert 'record keeps candidate binding closed' record_is runtime_candidate_binding_authorized no
assert 'record keeps runtime rerun closed' record_is runtime_rerun_authorized no
assert 'record keeps package actions closed' record_is package_action_authorized no
assert 'record keeps Slackpkg mutation closed' record_is slackpkg_mutation_authorized no
assert 'record keeps repository refresh closed' record_is repository_refresh_authorized no
assert 'record keeps network closed' record_is network_access_authorized no
assert 'record keeps boot actions closed' record_is boot_action_authorized no
assert 'record keeps reboot closed' record_is reboot_authorized no
assert 'record keeps evidence cleanup closed' record_is evidence_cleanup_authorized no
assert 'record expires prior target binding' record_is prior_target_binding_reusable_after_pause no
assert 'record requires fresh target revalidation' record_is fresh_target_revalidation_required_before_any_machine_action yes
assert 'record requires v3 revalidation before executor/runtime use' record_is local_source_v3_tree_revalidation_required_before_executor_implementation_or_runtime_use yes
assert 'record requires accepted manifest for executor v2' record_is accepted_v3_manifest_identity_required_before_executor_v2_implementation yes
assert 'record requires fresh candidate set' record_is fresh_candidate_set_required_before_runtime yes
assert 'record requires no machine action' record_is machine_action_required no
assert 'record requires no controller action' record_is controller_action_required no
assert 'record closes all operational authorization' record_is no_open_operational_authorization yes
assert 'record routes to fresh post-v3 boundary' record_is next_stage 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review'
assert 'reference document accepts builder PASS' grep -Fq 'local_source_v3_build_status=PASS' "$doc"
assert 'reference document freezes v3 manifest identity' grep -Fq '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b' "$doc"
assert 'reference document records exact PGP compatibility marker' grep -Fq 'PGP compatibility marker for Slackpkg checkchangelog only.' "$doc"
assert 'reference document expires runtime identity' grep -Fq 'intentionally not reusable after this pause' "$doc"
assert 'reference document declares strong safe pause' grep -Fq 'A successful step 250 is a strong safe pause.' "$doc"
assert 'reference document names fresh next boundary' grep -Fq 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review' "$doc"
assert 'step-250 files have no trailing whitespace' bash -c '! grep -nE "[[:blank:]]+$" "$1" "$2" "$3" "$4"' _ "$helper" "$doc" "$policy" "$record"
assert 'CHANGELOG records step 250' grep -Fq '## Phase 1 step 250 ' "$repo_root/CHANGELOG.md"
assert 'step-250 helper contains no executable package network boot or shutdown command' bash -c '! grep -Eq "^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|upgradepkg|installpkg|removepkg|curl|wget|git|reboot|shutdown|poweroff)[[:space:]]" "$1"' _ "$helper"
printf 'Result: %s (%d passes, %d failures)\n' "$([[ $failures -eq 0 ]] && printf PASS || printf FAIL)" "$passes" "$failures"
[[ $failures -eq 0 ]]
