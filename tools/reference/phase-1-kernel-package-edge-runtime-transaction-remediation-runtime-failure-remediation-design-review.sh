#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
output_dir=''
usage() {
  cat <<'EOF'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review.sh [--output-dir DIR] [--help]

Review the repository-only second remediation design after the confirmed
step-242 runtime failure characterization. The design preserves local-source-v2
and the failed executor generation as historical evidence, introduces a new
local-source-v3 contract plus a future executor generation, and grants no
machine, package, Slackpkg, network, boot, reboot, build, transport, or rerun
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
[[ -n $output_dir ]] || output_dir=$acceptance_dir
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory missing or unsafe\n' >&2; exit 3; }
cat > "$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review-policy.json" <<'POLICY'
{
  "accepted_step_242": {
    "doc_sha256": "0f3c9b256d02201c46b7ea81d95d3deeab6423d635da2e9447afc64d378fee59",
    "freeze_status": "PASS",
    "harness_sha256": "31ea86e212b2a77c4e95daf557414c91bb4806dedf4a4d331cb04b6092ab3996",
    "helper_sha256": "042b3b925f0de7d583ded59240b54b0f66e5f116c51236ce44b3417f57a6a210",
    "policy_sha256": "6b7ae8b27212bd3d5c3a5aeeae7bc2eab828bf14d51f59d8d368e72ee4fd869a",
    "record_sha256": "07d5bfa3a6e4fca347c51a83d25a7e7e60015a2b11dc377c9ddc96a5fd50257a"
  },
  "authorization": {
    "boot_action_authorized": false,
    "evidence_cleanup_authorized": false,
    "local_source_v3_build_authorized": false,
    "local_source_v3_builder_implementation_authorized": false,
    "network_access_authorized": false,
    "package_action_authorized": false,
    "phase_2_start_authorized": false,
    "reboot_authorized": false,
    "repository_failure_remediation_design_freeze_authorized": true,
    "repository_refresh_authorized": false,
    "runtime_executor_transport_authorized": false,
    "runtime_executor_v2_implementation_authorized": false,
    "runtime_rerun_authorized": false,
    "runtime_scenario_execution_authorized": false,
    "slackpkg_mutation_authorized": false
  },
  "confirmed_failure_input": {
    "compatibility_asc_contains_PGP": false,
    "failed_executor_guard_form": "hyphenated-literal",
    "failure_mechanism": "compatibility-asc-pgp-marker-rejection-plus-error-signal-guard-mismatch",
    "installed_slackpkg_requires_PGP_marker": true,
    "rollback_baseline_status": "PASS",
    "runtime_result": "FAIL",
    "single_use_runtime_authority_state": "consumed",
    "slackpkg_error_message_form": "human-spaced",
    "slackpkg_error_prefix": "Error downloading from ",
    "slackpkg_update_exit_code": 0,
    "transaction_pkglist_present": false
  },
  "controller_action_required": false,
  "future_work_requires_explicit_authorization": true,
  "historical_preservation": {
    "failed_executor_body_sha256": "ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b",
    "failed_executor_builder_sha256": "a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379",
    "failed_executor_generation_mutation_authorized": false,
    "failed_executor_sha256": "9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c",
    "failed_runtime_evidence_cleanup_authorized": false,
    "local_source_v2_builder_sha256": "8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d",
    "local_source_v2_mutation_authorized": false,
    "local_source_v2_root": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2",
    "local_source_v2_tree_manifest_sha256": "e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945"
  },
  "implementation_sequence": [
    "freeze-remediation-design",
    "review-and-freeze-local-source-v3-builder-and-future-executor-contract",
    "fresh-prebuild-target-revalidation",
    "single-use-local-source-v3-build-authorization",
    "local-source-v3-build-result-review-and-strong-safe-pause"
  ],
  "machine_action_required": false,
  "next_stage": "phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze",
  "pause_safe": false,
  "remediation_design": {
    "compatibility_asc": {
      "CHECKGPG_runtime_setting": "off",
      "must_contain_literal_PGP_marker": true,
      "must_not_contain_BEGIN_PGP_SIGNATURE": true,
      "must_not_impersonate_upstream_signature": true,
      "must_state_no_cryptographic_authenticity_claim": true,
      "purpose": "satisfy-observed-installed-slackpkg-checkchangelog-marker-gate-only",
      "required": true,
      "required_marker_text": "PGP compatibility marker for Slackpkg checkchangelog only."
    },
    "future_executor_generation": {
      "body_path": "tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh",
      "builder_path": "tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh",
      "exact_v3_manifest_identity_must_be_bound_after_v3_build": true,
      "executor_path": "tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh",
      "historical_failed_executor_files_must_not_be_modified": true,
      "new_generation_required": true,
      "runtime_acknowledgement": "--execute-runtime-remediation-v2-validation",
      "source_generation_must_be_local_source_v3": true
    },
    "local_source_generation": "local-source-v3",
    "local_source_v3_must_be_new_and_absent_before_build": true,
    "local_source_v3_must_derive_from_frozen_v2_contract": true,
    "local_source_v3_priority_tree_contract_unchanged": true,
    "local_source_v3_root": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3",
    "local_source_v3_target_bytes_must_equal_staged_target": true,
    "local_source_v3_tree_manifest": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256",
    "local_source_v3_tree_manifest_sidecar": "/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256.sha256",
    "refresh_error_guard": {
      "actual_human_spaced_error_must_fail_closed": true,
      "actual_human_spaced_error_prefix": "Error downloading from ",
      "fresh_transaction_pkglist_is_independent_success_guard": true,
      "fresh_transaction_pkglist_required": true,
      "hyphenated_literal_guard_retired": true,
      "slackpkg_exit_zero_is_sufficient": false,
      "stdout_and_stderr_capture_required": true
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
      "same_transaction_candidate_binding": true,
      "slackpkg_state_restored": true,
      "target_specific_candidate_guard": true,
      "transaction_owned_WORKDIR_and_TEMP": true
    },
    "state": "reviewed-not-frozen-not-implemented"
  },
  "review_only": true,
  "review_status": "PASS",
  "scenario": "phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review",
  "schema": 1,
  "step": 243,
  "strong_safe_pause": false
}
POLICY
cat > "$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review.tsv" <<'RECORD'
step	243
revision	runtime-failure-remediation-design-review
review_status	PASS
accepted_step_242	yes
rollback_baseline_status	PASS
failure_mechanism	compatibility-asc-pgp-marker-rejection-plus-error-signal-guard-mismatch
historical_local_source_v2_preserved	yes
historical_failed_executor_preserved	yes
remediation_local_source_generation	local-source-v3
local_source_v3_root	/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3
compatibility_asc_literal_PGP_marker_required	yes
compatibility_asc_authenticity_claim	no
compatibility_asc_BEGIN_PGP_SIGNATURE_forbidden	yes
future_executor_generation	runtime-transaction-remediation-v2
future_executor_source_generation	local-source-v3
slackpkg_exit_zero_sufficient	no
refresh_error_guard_form	human-spaced-Error-downloading-from
hyphenated_literal_guard	retired
fresh_transaction_pkglist_required	yes
target_specific_candidate_guard_retained	yes
external_network_authorized	no
repository_failure_remediation_design_freeze_authorized	yes
local_source_v3_build_authorized	no
runtime_rerun_authorized	no
machine_action_required	no
controller_action_required	no
pause_safe	no
next_stage	phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze
RECORD
printf 'review_status\tPASS\n'
printf 'local_source_generation\tlocal-source-v3\n'
printf 'compatibility_asc_literal_PGP_marker_required\tyes\n'
printf 'refresh_error_guard_form\thuman-spaced-Error-downloading-from\n'
printf 'runtime_rerun_authorized\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze\n'
