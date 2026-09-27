#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
output_dir=''
usage() {
cat <<'EOF'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze.sh [--output-dir DIR] [--help]

Consume the accepted step-245 repository-only implementation-contract review
and freeze the exact local-source-v3 builder plus the future executor-v2
contract. This helper grants no target observation, builder transport/build,
package, Slackpkg, network, boot, reboot, executor implementation, or rerun
authority.
EOF
}
while (($#)); do
 case "$1" in
  --output-dir) [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }; output_dir=$2; shift 2 ;;
  --help|-h) usage; exit 0 ;;
  *) printf 'ERROR: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
 esac
done
[[ -n $output_dir ]] || output_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory missing or unsafe\n' >&2; exit 3; }
cat > "$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze-policy.json" <<'JSON'
{
  "accepted_step_245": {
    "builder_sha256": "56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582",
    "doc_sha256": "b99b485cff14f5bad74e8c18780824902d024ba83ad9e2b3582abb28c33d3994",
    "harness_sha256": "f4942f581d7ea74d746ab00decf953c62b28cd128daaf5b66485185ae9baba19",
    "helper_sha256": "cfb13ed97cf819fa942dbcc7437e34d2b94fd54400b35c1b9901bdd000460515",
    "policy_sha256": "d95c7374cbd9944f6d9de7c6b04ced88b92fd262c0f4a2d3f5eb94097d02b83c",
    "record_sha256": "385e2f5cf95b98ddcd844eb0b6470cd04f4cb57d5429e3ec7ef87f3b00e8d33c",
    "review_status": "PASS"
  },
  "authorization": {
    "boot_action_authorized": false,
    "evidence_cleanup_authorized": false,
    "local_source_v3_build_authorized": false,
    "local_source_v3_builder_execution_authorized": false,
    "local_source_v3_builder_transport_authorized": false,
    "network_access_authorized": false,
    "package_action_authorized": false,
    "phase_2_start_authorized": false,
    "probe_transport_copy_authorized": false,
    "reboot_authorized": false,
    "repository_prebuild_fresh_target_revalidation_review_authorized": true,
    "repository_refresh_authorized": false,
    "runtime_executor_transport_authorized": false,
    "runtime_executor_v2_implementation_authorized": false,
    "runtime_rerun_authorized": false,
    "runtime_scenario_execution_authorized": false,
    "slackpkg_mutation_authorized": false,
    "target_observation_authorized": false
  },
  "controller_action_required": false,
  "freeze_status": "PASS",
  "future_executor_v2_contract": {
    "body_path": "tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh",
    "builder_path": "tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh",
    "executor_path": "tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh",
    "historical_failed_executor_files_must_remain_unchanged": true,
    "implementation_must_wait_for_accepted_v3_manifest_identity": true,
    "refresh_success_contract": {
      "fresh_transaction_owned_pkglist_required": true,
      "human_spaced_error_must_fail_closed": true,
      "human_spaced_error_prefix": "Error downloading from ",
      "hyphenated_literal_guard_forbidden": true,
      "same_transaction_candidate_binding_required": true,
      "slackpkg_exit_zero_required": true,
      "slackpkg_exit_zero_sufficient": false,
      "stdout_and_stderr_capture_required": true,
      "target_specific_candidate_guard_required": true
    },
    "retained_runtime_invariants": {
      "boot_artifacts_unchanged": true,
      "exact_predecessor_and_target_sha256": true,
      "external_network_forbidden": true,
      "geninitrd_policy_restored": true,
      "header_only_staging_delta": true,
      "no_reboot": true,
      "real_tab_tsv_evidence": true,
      "rollback_on_any_failure_after_mutation": true,
      "slackpkg_state_restored": true,
      "transaction_owned_WORKDIR_and_TEMP": true
    },
    "runtime_acknowledgement": "--execute-runtime-remediation-v2-validation",
    "source_generation": "local-source-v3",
    "state": "reviewed-frozen-not-implemented"
  },
  "future_work_requires_explicit_authorization": true,
  "historical_preservation": {
    "failed_executor_body_sha256": "ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b",
    "failed_executor_builder_sha256": "a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379",
    "failed_executor_generation_mutation_authorized": false,
    "failed_executor_sha256": "9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c",
    "local_source_v2_builder_sha256": "8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d",
    "local_source_v2_mutation_authorized": false,
    "local_source_v2_root": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2",
    "local_source_v2_tree_manifest_sha256": "e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945"
  },
  "implementation_contract_freeze": {
    "accepted_step_245_builder_bytes_are_immutable": true,
    "builder_execution_requires_later_single_use_explicit_authorization": true,
    "builder_sha256_is_execution_identity": true,
    "builder_transport_requires_later_explicit_authorization": true,
    "fresh_prebuild_target_revalidation_required_before_builder_transport_or_execution": true,
    "future_executor_v2_contract_is_frozen_but_not_implemented": true,
    "future_executor_v2_must_bind_accepted_v3_manifest_identity": true,
    "local_source_v3_build_result_must_be_reviewed_and_frozen_before_executor_v2_implementation": true,
    "repository_test_seam_is_not_production_authority": true
  },
  "local_source_v3_builder_implementation": {
    "boot_action_performed": false,
    "builder_path": "tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh",
    "builder_sha256": "56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582",
    "compatibility_asc": {
      "BEGIN_PGP_SIGNATURE_forbidden": true,
      "literal_PGP_marker_required": true,
      "no_cryptographic_authenticity_claim_required": true,
      "required": true,
      "required_marker_text": "PGP compatibility marker for Slackpkg checkchangelog only.",
      "upstream_signature_impersonation_forbidden": true
    },
    "exact_package_archive_count": 1,
    "execution_acknowledgement": "--build-local-source-v3",
    "final_paths_must_be_absent_before_build": true,
    "final_tree_root_owned_read_only": true,
    "generated_mtimes_epoch_zero": true,
    "network_access_performed": false,
    "package_action_performed": false,
    "predecessor_archive_forbidden": true,
    "priority_trees": [
      "patches",
      "slackware64",
      "extra",
      "pasture",
      "testing"
    ],
    "production_paths_overridable": false,
    "repository_test_seam": "SLACK_UPDATE_LOCAL_SOURCE_V3_BUILDER_LIBRARY_ONLY=1",
    "root": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3",
    "slackpkg_configuration_change_performed": false,
    "state": "implemented-frozen-not-executed",
    "target_bytes_must_equal_staged_target": true,
    "target_input": "/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz",
    "target_sha256": "c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c",
    "temporary_sibling_build_then_atomic_publish": true,
    "tree_manifest": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256",
    "tree_manifest_sidecar": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256.sha256"
  },
  "machine_action_required": false,
  "next_stage": "phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review",
  "pause_safe": false,
  "review_only": true,
  "scenario": "phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze",
  "schema": 1,
  "step": 246,
  "strong_safe_pause": false
}
JSON
cat > "$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze.tsv" <<'TSV'
step	246
revision	runtime-failure-remediation-implementation-contract-freeze
freeze_status	PASS
accepted_step_245	yes
local_source_v3_builder_implementation_state	implemented-frozen-not-executed
local_source_v3_builder_path	tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh
local_source_v3_builder_sha256	56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582
local_source_v3_execution_acknowledgement	--build-local-source-v3
local_source_v3_root	/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3
local_source_v3_target_sha256	c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c
compatibility_asc_marker_text	PGP compatibility marker for Slackpkg checkchangelog only.
compatibility_asc_BEGIN_PGP_SIGNATURE_forbidden	yes
future_executor_v2_state	reviewed-frozen-not-implemented
future_executor_v2_manifest_identity_required_before_implementation	yes
future_refresh_error_guard	human-spaced-Error-downloading-from
future_hyphenated_literal_guard	forbidden
fresh_prebuild_target_revalidation_required_before_builder_execution	yes
repository_prebuild_fresh_target_revalidation_review_authorized	yes
target_observation_authorized	no
probe_transport_copy_authorized	no
local_source_v3_builder_transport_authorized	no
local_source_v3_builder_execution_authorized	no
local_source_v3_build_authorized	no
runtime_executor_v2_implementation_authorized	no
runtime_rerun_authorized	no
package_action_authorized	no
slackpkg_mutation_authorized	no
network_access_authorized	no
boot_action_authorized	no
reboot_authorized	no
evidence_cleanup_authorized	no
phase_2_start_authorized	no
machine_action_required	no
controller_action_required	no
pause_safe	no
next_stage	phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review
TSV
printf 'implementation_contract_freeze_status\tPASS\n'
printf 'local_source_v3_builder_sha256\t56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582\n'
printf 'future_executor_v2_state\treviewed-frozen-not-implemented\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review\n'
