#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause.sh [--output-dir DIR] [--help]

Freeze the accepted runtime failure remediation boundary and close the current
continuation chain at a strong safe pause.
USAGE
}

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
output_dir="$acceptance_dir"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --output-dir)
            [[ $# -ge 2 ]] || { echo 'ERROR: --output-dir requires an argument' >&2; exit 2; }
            output_dir=$2
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

mkdir -p -- "$output_dir"

step219_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.sh"
step219_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.md"
step219_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review-harness.sh"
step219_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review-policy.json"
step219_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.tsv"

for path in "$step219_helper" "$step219_doc" "$step219_harness" "$step219_policy" "$step219_record"; do
    [[ -f $path && ! -L $path ]] || { echo "ERROR: prerequisite missing or unsafe: $path" >&2; exit 1; }
done

[[ $(sha256sum -- "$step219_helper" | awk '{print $1}') == '9bf7605293f03686374b1dda5394fd1d0e510886da1f2159a096d15df31b9789' ]] || { echo 'ERROR: step-219 helper SHA-256 drift' >&2; exit 1; }
[[ $(sha256sum -- "$step219_doc" | awk '{print $1}') == '782c4d102d3925e3b31d62159ab8c88b69b48d928e433670730f5ad643166180' ]] || { echo 'ERROR: step-219 document SHA-256 drift' >&2; exit 1; }
[[ $(sha256sum -- "$step219_harness" | awk '{print $1}') == '0d9b86f4e96fdcbdc1ae326aa4aba130072411f0e9ad7669675b191483b2abb0' ]] || { echo 'ERROR: step-219 harness SHA-256 drift' >&2; exit 1; }
[[ $(sha256sum -- "$step219_policy" | awk '{print $1}') == '6a55e2e600dbb192cb7e14e9d3514a9a6dd7ab2ac019fd7478f84d631c670d75' ]] || { echo 'ERROR: step-219 policy SHA-256 drift' >&2; exit 1; }
[[ $(sha256sum -- "$step219_record" | awk '{print $1}') == '9bb2cb29fce3529b9d4b726846db433558dfbbb9de5127b54c71d49d13bb982f' ]] || { echo 'ERROR: step-219 record SHA-256 drift' >&2; exit 1; }

python3 - "$step219_policy" <<'PY'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review'
assert p['step']==219
assert p['review_status']=='PASS'
assert p['failure_characterization_status']=='PASS'
assert p['cleanup_triggered'] is True
assert p['header_restored'] is True
assert p['package_database_restored'] is True
assert p['slackpkg_configuration_restored'] is True
assert p['slackpkg_state_restored'] is True
assert p['geninitrd_policy_restored'] is True
assert p['boot_artifacts_unchanged'] is True
assert p['published_success_evidence_absent'] is True
assert p['runtime_rerun_authorized'] is False
assert p['package_action_authorized'] is False
assert p['slackpkg_mutation_authorized'] is False
assert p['network_access_authorized'] is False
assert p['boot_action_authorized'] is False
assert p['reboot_authorized'] is False
assert p['machine_action_required'] is False
assert p['controller_action_required'] is False
assert p['remediation_boundary']['preserve_local_source_v1'] is True
assert p['remediation_boundary']['preserve_failed_evidence_root'] is True
assert p['remediation_boundary']['new_local_source_generation_name']=='local-source-v2'
PY

cat > "$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause-policy.json" <<'JSON'
{
  "scenario": "phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause",
  "step": 220,
  "review_status": "PASS",
  "kernel_package_edge_family_state": "open-remediation-pending",
  "phase_1_acceptance_matrix_complete": false,
  "accepted_step_219": {
    "helper_sha256": "9bf7605293f03686374b1dda5394fd1d0e510886da1f2159a096d15df31b9789",
    "document_sha256": "782c4d102d3925e3b31d62159ab8c88b69b48d928e433670730f5ad643166180",
    "harness_sha256": "0d9b86f4e96fdcbdc1ae326aa4aba130072411f0e9ad7669675b191483b2abb0",
    "policy_sha256": "6a55e2e600dbb192cb7e14e9d3514a9a6dd7ab2ac019fd7478f84d631c670d75",
    "record_sha256": "9bb2cb29fce3529b9d4b726846db433558dfbbb9de5127b54c71d49d13bb982f"
  },
  "contained_runtime_failure": {
    "characterization_status": "PASS",
    "cleanup_triggered": true,
    "header_restored": true,
    "package_database_restored": true,
    "slackpkg_configuration_restored": true,
    "slackpkg_state_restored": true,
    "geninitrd_policy_restored": true,
    "boot_artifacts_unchanged": true,
    "published_success_evidence_absent": true,
    "failed_executor_sha256": "09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300",
    "failure_signal": "error-downloading-from-local-source",
    "failed_run_must_not_be_reused_as_success_evidence": true
  },
  "preservation_contract": {
    "local_source_v1_must_be_preserved_unchanged": true,
    "failed_runtime_evidence_root_must_be_preserved_unchanged": true,
    "staged_target_must_be_preserved_unchanged": true,
    "external_artifact_evidence_must_be_preserved_unchanged": true,
    "failed_executor_identity_is_historical_only": true,
    "local_source_v1_may_be_modified_in_place": false,
    "failed_runtime_evidence_may_be_deleted": false
  },
  "remediation_contract": {
    "new_local_source_generation_required": true,
    "new_local_source_generation_name": "local-source-v2",
    "slackpkg_refresh_compatibility_metadata_required": true,
    "CHECKSUMS_md5_asc_compatibility_artifact_required": true,
    "priority_tree_metadata_required": true,
    "refresh_success_requires_exit_zero": true,
    "refresh_success_requires_no_error_downloading_signal": true,
    "refresh_success_requires_workdir_metadata_freshness_proof": true,
    "candidate_guard_scope": "target-specific-not-global-pkglist-row-count",
    "candidate_guard_requires_exactly_one_target_row": true,
    "candidate_guard_requires_predecessor_installed": true,
    "candidate_guard_requires_target_source_binding": true,
    "evidence_encoding": "real-tab-tsv",
    "remediation_must_be_revalidated_before_package_mutation": true,
    "implementation_authorized_at_pause": false,
    "runtime_rerun_authorized_at_pause": false
  },
  "authorization": {
    "controller_transport_authorized": false,
    "local_source_v2_build_authorized": false,
    "runtime_executor_build_authorized": false,
    "runtime_executor_transport_authorized": false,
    "runtime_rerun_authorized": false,
    "package_action_authorized": false,
    "slackpkg_mutation_authorized": false,
    "repository_refresh_authorized": false,
    "network_access_authorized": false,
    "boot_action_authorized": false,
    "reboot_authorized": false,
    "persistent_configuration_change_authorized": false,
    "evidence_cleanup_authorized": false,
    "phase_2_start_authorized": false
  },
  "resume_boundary": {
    "fresh_resume_planning_boundary_required": true,
    "fresh_target_revalidation_required_before_any_machine_action": true,
    "prior_runtime_authorization_reusable": false,
    "prior_candidate_binding_reusable": false,
    "prior_failed_executor_authorization_reusable": false,
    "local_source_v2_design_and_build_requires_fresh_authorization": true,
    "remediation_validation_required_before_package_mutation": true,
    "later_slackware_current_publication_invalidates_preserved_artifact_bytes": false,
    "later_slackware_current_publication_requires_live_target_revalidation": true
  },
  "safe_pause": {
    "strong_safe_pause": true,
    "pause_safe": true,
    "no_open_operational_authorization": true,
    "machine_action_required": false,
    "controller_action_required": false,
    "package_action_authority_open": false,
    "slackpkg_mutation_authority_open": false,
    "repository_or_network_refresh_authority_open": false,
    "runtime_execution_authority_open": false,
    "local_source_v2_build_authority_open": false,
    "boot_action_authority_open": false,
    "reboot_authority_open": false,
    "evidence_cleanup_authority_open": false,
    "phase_2_authority_open": false
  },
  "machine_action_required": false,
  "controller_action_required": false,
  "pause_safe": true,
  "next_stage": "phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review"
}
JSON

cat > "$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause.tsv" <<'TSV'
step	220
review_status	PASS
kernel_package_edge_family_state	open-remediation-pending
phase_1_acceptance_matrix_complete	no
failure_characterization_status	PASS
cleanup_triggered	yes
header_restored	yes
package_database_restored	yes
slackpkg_configuration_restored	yes
slackpkg_state_restored	yes
geninitrd_policy_restored	yes
boot_artifacts_unchanged	yes
published_success_evidence_absent	yes
local_source_v1_must_be_preserved_unchanged	yes
failed_runtime_evidence_root_must_be_preserved_unchanged	yes
new_local_source_generation_required	yes
new_local_source_generation_name	local-source-v2
remediation_must_be_revalidated_before_package_mutation	yes
fresh_resume_planning_boundary_required	yes
fresh_target_revalidation_required_before_any_machine_action	yes
prior_runtime_authorization_reusable	no
prior_candidate_binding_reusable	no
runtime_rerun_authorized	no
package_action_authorized	no
slackpkg_mutation_authorized	no
repository_refresh_authorized	no
network_access_authorized	no
boot_action_authorized	no
reboot_authorized	no
evidence_cleanup_authorized	no
phase_2_start_authorized	no
machine_action_required	no
controller_action_required	no
strong_safe_pause	yes
pause_safe	yes
next_stage	phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review
TSV

cat <<'OUT'
review_status	PASS
strong_safe_pause	yes
pause_safe	yes
machine_action_required	no
controller_action_required	no
runtime_rerun_authorized	no
next_stage	phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review
OUT
