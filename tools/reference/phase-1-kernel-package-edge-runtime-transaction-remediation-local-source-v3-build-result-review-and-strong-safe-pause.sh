#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C
usage() {
  cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause.sh [--output-dir DIR] [--help]

Consume the successful single-use local-source-v3 build result, freeze the
accepted v3 tree identity, revoke the step-249 build authority, and close the
continuation chain at a strong safe pause. No machine, package, Slackpkg,
network, boot, reboot, executor-v2, runtime-rerun, or cleanup authority remains.
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
cat > "$out/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause-policy.json" <<'EOF_POLICY'
{
  "accepted_local_source_v3": {
    "compatibility_asc_PGP_marker_present": true,
    "compatibility_asc_is_not_openpgp_signature": true,
    "compatibility_asc_present": true,
    "priority_trees": [
      "patches",
      "slackware64",
      "extra",
      "pasture",
      "testing"
    ],
    "root": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3",
    "state": "built-accepted-preserve-unchanged",
    "target_package": "kernel-headers-6.18.45-x86-1.txz",
    "target_sha256": "c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c",
    "tree_manifest": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256",
    "tree_manifest_must_be_preserved_unchanged": true,
    "tree_manifest_sha256": "8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b",
    "tree_manifest_sha256_sidecar": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256.sha256",
    "tree_manifest_sidecar_must_be_preserved_unchanged": true,
    "tree_must_be_preserved_unchanged": true
  },
  "accepted_step_249": {
    "builder_r1_sha256": "80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30",
    "document_sha256": "c13452fa99a40789a8f475251f7283fdc2b0e029915d48e272d2ade61d5f80a7",
    "harness_sha256": "e84ca066c634a509c5899f128b272aede9c96080359355645110a9c2e1c3ba8f",
    "helper_sha256": "38da99cfd70ea81e6b6b48e1c60fd61f5a7224aa05b1dcb9b10a7482ab606b0b",
    "policy_sha256": "63bb296e1ec1be3b329ffb8829c0a1c2fbc147e618f573380d590201192da790",
    "record_sha256": "9ac3d58470452f686a1e575c9ca3d07110cdb617587d93034e9405aa6165cb83"
  },
  "authorization": {
    "boot_action_authorized": false,
    "evidence_cleanup_authorized": false,
    "local_source_v3_build_authorized": false,
    "local_source_v3_build_result_review_authorized_after_successful_build": false,
    "local_source_v3_builder_execution_authorized": false,
    "local_source_v3_builder_transport_authorized": false,
    "network_access_authorized": false,
    "package_action_authorized": false,
    "persistent_configuration_change_authorized": false,
    "phase_2_start_authorized": false,
    "probe_transport_copy_authorized": false,
    "reboot_authorized": false,
    "repository_refresh_authorized": false,
    "runtime_candidate_binding_authorized": false,
    "runtime_executor_v2_implementation_authorized": false,
    "runtime_executor_v2_transport_authorized": false,
    "runtime_rerun_authorized": false,
    "slackpkg_mutation_authorized": false,
    "target_observation_authorized": false
  },
  "build_result_state": "accepted-pass-build-authority-consumed",
  "builder_implementation": {
    "builder_path": "tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh",
    "builder_sha256": "80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30",
    "compatibility_marker": "PGP compatibility marker for Slackpkg checkchangelog only.",
    "compatibility_marker_is_not_authenticity_evidence": true,
    "corrected_output_contract": true,
    "execution_acknowledgement": "--build-local-source-v3",
    "historical_unexecuted_builder_preserved": true,
    "historical_unexecuted_builder_sha256": "56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582",
    "openpgp_signature_block_forbidden": true,
    "state": "implemented-frozen-executed-pass-authority-consumed"
  },
  "consumed_build_result": {
    "boot_action_performed": "no",
    "compatibility_asc_PGP_marker_present": "yes",
    "compatibility_asc_present": "yes",
    "local_source_v3_build_status": "PASS",
    "local_source_v3_root": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3",
    "network_access_performed": "no",
    "package_action_performed": "no",
    "priority_trees": "patches,slackware64,extra,pasture,testing",
    "reboot_performed": "no",
    "slackpkg_configuration_change_performed": "no",
    "target_package": "kernel-headers-6.18.45-x86-1.txz",
    "target_sha256": "c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c",
    "tree_manifest": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256",
    "tree_manifest_sha256": "8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b"
  },
  "controller_action_required": false,
  "future_executor_v2_state": "reviewed-frozen-not-implemented",
  "future_work_requires_explicit_authorization": true,
  "future_work_requires_fresh_boundary": true,
  "machine_action_required": false,
  "next_stage": "phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review",
  "pause_safe": true,
  "phase_1_acceptance_matrix_complete": false,
  "preservation_contract": {
    "accepted_local_source_v3_must_be_preserved_unchanged": true,
    "failed_remediation_evidence_must_be_preserved_unchanged": true,
    "historical_unexecuted_v3_builder_must_be_preserved": true,
    "local_source_v2_historical_no_PGP_state_must_be_preserved": true,
    "local_source_v2_must_be_preserved_unchanged": true,
    "local_source_v2_tree_manifest_sha256": "e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945",
    "staged_target_must_be_preserved_unchanged": true,
    "staged_target_sha256": "c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c"
  },
  "review_only": true,
  "review_status": "PASS",
  "revision": "accepted-local-source-v3-build-result-strong-safe-pause",
  "runtime_boundary_after_pause": {
    "accepted_v3_manifest_identity_required_before_executor_v2_implementation": true,
    "fresh_candidate_set_required_before_runtime": true,
    "fresh_target_revalidation_required_before_any_machine_action": true,
    "local_source_v3_tree_must_match_bound_manifest_before_use": true,
    "local_source_v3_tree_revalidation_required_before_executor_implementation_or_runtime_use": true,
    "prior_boot_id": "fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9",
    "prior_package_database_manifest_sha256": "726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6",
    "prior_prebuild_observation_state": "expired-at-strong-safe-pause",
    "prior_target_binding_reusable_after_pause": false,
    "runtime_executor_v2_implementation_review_required_before_runtime": true,
    "runtime_network_access_forbidden": true
  },
  "safe_pause": {
    "accepted_local_source_v3_must_be_preserved_unchanged": true,
    "controller_action_required": false,
    "later_slackware_current_publication_invalidates_checkpoint": false,
    "machine_action_required": false,
    "no_open_operational_authorization": true,
    "pause_safe": true,
    "prior_runtime_target_observation_must_not_be_reused": true,
    "strong_safe_pause": true,
    "tree_manifest_sha256": "8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b"
  },
  "scenario": "phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause",
  "schema": 1,
  "selected_family": "kernel-package-edge",
  "step": 250,
  "strong_safe_pause": true
}
EOF_POLICY
cat > "$out/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause.tsv" <<'EOF_RECORD'
step	250
review_status	PASS
revision	accepted-local-source-v3-build-result-strong-safe-pause
pause_state	strong-safe-pause
pause_safe	yes
strong_safe_pause	yes
selected_family	kernel-package-edge
family_closed	no
acceptance_matrix_complete	no
accepted_step_249_policy_sha256	63bb296e1ec1be3b329ffb8829c0a1c2fbc147e618f573380d590201192da790
accepted_step_249_record_sha256	9ac3d58470452f686a1e575c9ca3d07110cdb617587d93034e9405aa6165cb83
builder_implementation_state	implemented-frozen-executed-pass-authority-consumed
builder_r1_sha256	80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30
build_result_status	PASS
local_source_v3_tree_built	yes
local_source_v3_root	/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3
target_package	kernel-headers-6.18.45-x86-1.txz
target_sha256	c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c
priority_trees	patches,slackware64,extra,pasture,testing
compatibility_asc_present	yes
compatibility_asc_PGP_marker_present	yes
tree_manifest_path	/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256
tree_manifest_sha256	8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b
tree_manifest_sha256_path	/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256.sha256
local_source_v3_tree_manifest_bound	yes
network_access_performed	no
package_action_performed	no
slackpkg_configuration_change_performed	no
boot_action_performed	no
reboot_performed	no
build_authority_consumed	yes
target_observation_authorized	no
probe_transport_copy_authorized	no
local_source_v3_builder_transport_authorized	no
local_source_v3_builder_execution_authorized	no
local_source_v3_build_authorized	no
runtime_executor_v2_implementation_authorized	no
runtime_executor_v2_transport_authorized	no
runtime_candidate_binding_authorized	no
runtime_rerun_authorized	no
package_action_authorized	no
slackpkg_mutation_authorized	no
repository_refresh_authorized	no
network_access_authorized	no
boot_action_authorized	no
reboot_authorized	no
evidence_cleanup_authorized	no
phase_2_start_authorized	no
prior_target_binding_reusable_after_pause	no
fresh_target_revalidation_required_before_any_machine_action	yes
local_source_v3_tree_revalidation_required_before_executor_implementation_or_runtime_use	yes
accepted_v3_manifest_identity_required_before_executor_v2_implementation	yes
fresh_candidate_set_required_before_runtime	yes
machine_action_required	no
controller_action_required	no
no_open_operational_authorization	yes
future_work_requires_fresh_boundary	yes
next_stage	phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review
EOF_RECORD
printf 'build_result_review_status\tPASS\n'
printf 'local_source_v3_tree_manifest_sha256\t8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b\n'
printf 'build_authority_consumed\tyes\n'
printf 'strong_safe_pause\tyes\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review\n'
