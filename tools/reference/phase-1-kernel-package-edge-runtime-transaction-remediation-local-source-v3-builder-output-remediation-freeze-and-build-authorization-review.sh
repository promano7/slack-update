#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
usage() {
  cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-builder-output-remediation-freeze-and-build-authorization-review.sh [--output-dir DIR] [--help]

Freeze the accepted step-248 corrected local-source-v3 builder r1 and open
exactly one bounded builder transport/execution authorization. No package,
Slackpkg, network, boot, reboot, executor-v2, or runtime-rerun authority is
granted.
USAGE
}
out='.'
while [[ $# -gt 0 ]]; do
  case $1 in
    --output-dir) [[ $# -ge 2 ]] || { usage >&2; exit 2; }; out=$2; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
mkdir -p -- "$out"
cat > "$out/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-builder-output-remediation-freeze-and-build-authorization-review-policy.json" <<'EOF_POLICY'
{
  "accepted_step_248": {
    "corrected_builder_r1_sha256": "80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30",
    "document_sha256": "2283eed2db70e77c70383505532435449aec6acc27306d06a5f1bf458f13aa10",
    "harness_sha256": "07cf31c476ce02d0360b067a0e0f03cddb776663a00bcb3e01b315170984a946",
    "helper_sha256": "5230b8d9f9d5fb06d6da72adc7f8b997f79a0faf81c3f7c5db8767144416bc00",
    "historical_builder_sha256": "56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582",
    "policy_sha256": "6b93336f6f35702e604fcad956f5c05570572d4d296c5a7d95369226abd40300",
    "record_sha256": "b3523649344b28dc14583939750e9ba03488fd81ee3dbf225fa819cc4512de67"
  },
  "authorization": {
    "boot_action_authorized": false,
    "evidence_cleanup_authorized": false,
    "local_source_v3_build_authorized": true,
    "local_source_v3_build_result_review_authorized_after_successful_build": true,
    "local_source_v3_builder_execution_authorized": true,
    "local_source_v3_builder_transport_authorized": true,
    "network_access_authorized": false,
    "package_action_authorized": false,
    "phase_2_start_authorized": false,
    "probe_transport_copy_authorized": false,
    "reboot_authorized": false,
    "repository_refresh_authorized": false,
    "runtime_executor_v2_implementation_authorized": false,
    "runtime_executor_v2_transport_authorized": false,
    "runtime_rerun_authorized": false,
    "slackpkg_mutation_authorized": false,
    "target_observation_authorized": false
  },
  "builder_output_remediation_freeze": {
    "allowed_change_count": 2,
    "allowed_changes": [
      "local_source_v2_build_status->local_source_v3_build_status",
      "local_source_v2_root->local_source_v3_root"
    ],
    "build_semantics_unchanged": true,
    "corrected_builder_path": "tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh",
    "corrected_builder_sha256": "80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30",
    "corrected_builder_state": "implemented-frozen-authorized-for-single-build",
    "execution_acknowledgement": "--build-local-source-v3",
    "historical_builder_execution_count": 0,
    "historical_builder_path": "tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh",
    "historical_builder_sha256": "56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582",
    "historical_builder_state": "preserved-reviewed-never-executed",
    "synthetic_render_manifest_equivalence_reverified": true
  },
  "consumed_prebuild_v3_observation": {
    "failed_remediation_evidence_preserved": true,
    "fresh_boot_id": "fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9",
    "local_source_v2_tree_manifest_sha256": "e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945",
    "local_source_v3_final_outputs_absent": true,
    "local_source_v3_temporary_build_roots_absent": true,
    "package_database_manifest_sha256": "726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6",
    "prebuild_v3_revalidation_status": "PASS",
    "prior_runtime_binding_reused": false,
    "probe_authority_consumed": true,
    "rollback_baseline_restored": true,
    "staged_target_sha256": "c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c",
    "state": "consumed-and-frozen-for-single-v3-build-authorization"
  },
  "controller_action_required": true,
  "controller_action_type": "copy-exact-corrected-builder-r1-verify-sha256-and-run-once",
  "future_executor_v2_state": "reviewed-frozen-not-implemented",
  "future_work_requires_explicit_authorization": true,
  "machine_action_required": true,
  "machine_action_type": "single-local-source-v3-builder-r1-execution",
  "next_stage": "phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause",
  "pause_safe": false,
  "review_only": true,
  "review_status": "PASS",
  "scenario": "phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-builder-output-remediation-freeze-and-build-authorization-review",
  "schema": 1,
  "single_build_authorization": {
    "acknowledgement": "--build-local-source-v3",
    "authority_consumed_on_builder_start": true,
    "authorization_bound_boot_id": "fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9",
    "authorization_invalid_if_target_state_changes_before_execution": true,
    "authorization_use_count": 1,
    "boot_mutation_allowed": false,
    "builder_must_self_verify_tree_before_success": true,
    "builder_output_must_be_returned_for_step_250_review": true,
    "builder_output_must_report_local_source_v3_build_status_PASS": true,
    "builder_output_must_report_local_source_v3_root": true,
    "builder_transport": "copy-exact-corrected-builder-r1-only",
    "controller_must_verify_builder_sha256_before_execution": true,
    "execution": "root-via-sudo",
    "expected_final_root": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3",
    "expected_tree_manifest": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256",
    "expected_tree_manifest_sha256_sidecar": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256.sha256",
    "final_outputs_must_still_be_absent_immediately_before_execution": true,
    "network_access_allowed": false,
    "no_second_execution_authorized": true,
    "package_mutation_allowed": false,
    "persistent_configuration_change_allowed": false,
    "reboot_allowed": false,
    "same_boot_required_at_execution": true,
    "slackpkg_mutation_allowed": false,
    "state": "authorized-not-executed",
    "temporary_build_roots_must_still_be_absent_immediately_before_execution": true
  },
  "step": 249,
  "strong_safe_pause": false
}
EOF_POLICY
cat > "$out/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-builder-output-remediation-freeze-and-build-authorization-review.tsv" <<'EOF_RECORD'
step	249
review_status	PASS
prebuild_v3_observation_state	consumed-and-frozen-for-single-v3-build-authorization
fresh_boot_id	fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9
package_database_manifest_sha256	726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6
staged_target_sha256	c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c
local_source_v2_tree_manifest_sha256	e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945
local_source_v3_final_outputs_absent_at_authorization	yes
local_source_v3_temporary_build_roots_absent_at_authorization	yes
historical_v3_builder_sha256	56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582
historical_v3_builder_execution_count	0
corrected_v3_builder_r1_sha256	80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30
corrected_v3_builder_r1_state	implemented-frozen-authorized-for-single-build
builder_execution_acknowledgement	--build-local-source-v3
authorization_use_count	1
authority_consumed_on_builder_start	yes
second_builder_execution_forbidden	yes
same_boot_required_at_execution	yes
target_observation_authorized	no
probe_transport_copy_authorized	no
local_source_v3_builder_transport_authorized	yes
local_source_v3_builder_execution_authorized	yes
local_source_v3_build_authorized	yes
local_source_v3_build_result_review_authorized_after_successful_build	yes
runtime_executor_v2_implementation_authorized	no
runtime_executor_v2_transport_authorized	no
runtime_rerun_authorized	no
package_action_authorized	no
slackpkg_mutation_authorized	no
repository_refresh_authorized	no
network_access_authorized	no
boot_action_authorized	no
reboot_authorized	no
evidence_cleanup_authorized	no
phase_2_start_authorized	no
machine_action_required	yes
machine_action_type	single-local-source-v3-builder-r1-execution
controller_action_required	yes
controller_action_type	copy-exact-corrected-builder-r1-verify-sha256-and-run-once
pause_safe	no
next_stage	phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause
EOF_RECORD
printf 'build_authorization_review_status\tPASS\n'
printf 'corrected_v3_builder_r1_sha256\t80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30\n'
printf 'authorization_use_count\t1\n'
printf 'local_source_v3_build_authorized\tyes\n'
printf 'runtime_executor_v2_implementation_authorized\tno\n'
printf 'machine_action_required\tyes\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause\n'
