#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
output_dir=''

usage() {
  cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze.sh [--output-dir DIR] [--help]

Consume the successful read-only step-241 characterization observation and
freeze the confirmed rollback baseline plus failure mechanism. The step opens
only repository-side remediation design review and grants no machine, package,
Slackpkg, network, boot, reboot, cleanup, probe, or runtime-rerun authority.
USAGE
}

while (($#)); do
  case "$1" in
    --output-dir)
      [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }
      output_dir=$2
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf 'ERROR: unknown option: %s\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

[[ -n $output_dir ]] || output_dir=$acceptance_dir
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory missing or unsafe\n' >&2; exit 3; }

cat > "$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze-policy.json" <<'POLICY'
{
  "accepted_step_241": {
    "doc_sha256": "c55980b0ba549e8649e2c8cc218d470e7d526feca030f43787a15bdc72fc9a03",
    "harness_sha256": "a2c1c56db5690b2e524199f1ba0e7f120a33f81f120354a8cc5b61d7aabd4185",
    "helper_sha256": "df6bf05be7cdca8bb6bbbb38d1a20e1edf1ee5bd4a0f37ca270a6fea0077bb72",
    "policy_sha256": "8eaf56961ff91db699b6de1b066a71736f8abf23c462142d4c4929e4e124c778",
    "probe_sha256": "bdb06d4a10ef6ef5994f49078beb70c2b2d9b02e7775ad7d9fac66664802f22a",
    "record_sha256": "537d87de8c81f3677ddfc49d922dd94efd6d04551ddfb9d5c306e0729f506985",
    "review_status": "PASS"
  },
  "authorization": {
    "boot_action_authorized": false,
    "evidence_cleanup_authorized": false,
    "failure_characterization_observation_authorized": false,
    "network_access_authorized": false,
    "package_action_authorized": false,
    "phase_2_start_authorized": false,
    "probe_transport_copy_authorized": false,
    "reboot_authorized": false,
    "repository_failure_remediation_design_review_authorized": true,
    "repository_refresh_authorized": false,
    "runtime_executor_transport_authorized": false,
    "runtime_rerun_authorized": false,
    "runtime_scenario_execution_authorized": false,
    "slackpkg_mutation_authorized": false
  },
  "controller_action_required": false,
  "design_constraints_for_next_stage": {
    "must_match_actual_human_spaced_download_error_signal": true,
    "must_not_treat_slackpkg_exit_zero_as_sufficient_refresh_success": true,
    "must_retain_exact_rollback_invariants": true,
    "must_retain_external_network_prohibition": true,
    "must_retain_target_specific_candidate_guard": true,
    "must_retain_transaction_owned_workdir_freshness_proof": true,
    "must_satisfy_installed_slackpkg_PGP_marker_gate": true,
    "preserve_failed_executor_generation_unchanged": true,
    "preserve_failed_runtime_evidence": true,
    "preserve_local_source_v2_unchanged": true
  },
  "failure_characterization": {
    "compatibility_asc_contains_PGP": false,
    "executor_error_signal_guard_form": "hyphenated-literal",
    "historical_failed_executor_mutation_authorized": false,
    "installed_slackpkg_error_message_form": "human-spaced",
    "installed_slackpkg_requires_PGP_marker": true,
    "local_source_v2_mutation_authorized": false,
    "mechanism": "compatibility-asc-pgp-marker-rejection-plus-error-signal-guard-mismatch",
    "slackpkg_update_error_line": "Error downloading from //var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2/.",
    "slackpkg_update_error_signal_form": "human-spaced-error-downloading-from",
    "slackpkg_update_exit_code": 0,
    "state": "frozen-confirmed",
    "transaction_pkglist_present": false,
    "transaction_workdir_entries": [
      "CHECKSUMS.md5.asc",
      "ChangeLog.txt"
    ]
  },
  "freeze_status": "PASS",
  "future_work_requires_explicit_authorization": true,
  "machine_action_required": false,
  "next_stage": "phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review",
  "pause_safe": false,
  "probe_protocol": {
    "first_invocation_mutation_performed": false,
    "first_invocation_result": "ABORTED_PRECONDITION_MISSING_PRESERVED_EXECUTOR",
    "further_probe_execution_authorized": false,
    "observation_authority_state": "consumed-and-closed",
    "observed_invocation_count": 2,
    "probe_sha256": "bdb06d4a10ef6ef5994f49078beb70c2b2d9b02e7775ad7d9fac66664802f22a",
    "successful_characterization_observation_count": 1,
    "successful_observation_result": "PASS"
  },
  "rollback_baseline": {
    "boot_artifacts_unchanged": true,
    "boot_id": "fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9",
    "cleanup_triggered": true,
    "current_header_record": "kernel-headers-6.18.45-x86-1",
    "geninitrd_policy_restored": true,
    "package_database_manifest_sha256": "726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6",
    "published_success_evidence_absent": true,
    "result_tsv_absent": true,
    "rollback_header_from": "kernel-headers-6.18.44-x86-1",
    "slackpkg_conf_restored": true,
    "slackpkg_mirrors_restored": true,
    "slackpkg_state_restored": true,
    "status": "PASS"
  },
  "scenario": "phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze",
  "schema": 1,
  "step": 242,
  "strong_safe_pause": false
}
POLICY
cat > "$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-characterization-freeze.tsv" <<'RECORD'
step	242
revision	runtime-failure-characterization-freeze
freeze_status	PASS
observed_runtime_result	FAIL
single_use_runtime_authority_state	consumed-by-failed-runtime-start
probe_invocation_count_observed	2
first_probe_invocation_result	ABORTED_PRECONDITION_MISSING_PRESERVED_EXECUTOR
successful_characterization_observation_count	1
successful_characterization_status	PASS
failure_characterization_observation_authority_state	consumed-and-closed
rollback_baseline_status	PASS
current_header_record	kernel-headers-6.18.45-x86-1
package_database_manifest_sha256	726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6
boot_id	fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9
cleanup_triggered	yes
slackpkg_update_exit_code	0
slackpkg_update_error_signal_form	human-spaced-error-downloading-from
transaction_pkglist_present	no
compatibility_asc_contains_PGP	no
installed_slackpkg_requires_PGP_marker	yes
executor_error_signal_guard_form	hyphenated-literal
failure_mechanism_state	frozen-confirmed
failure_mechanism	compatibility-asc-pgp-marker-rejection-plus-error-signal-guard-mismatch
runtime_rerun_authorized	no
package_action_authorized	no
slackpkg_mutation_authorized	no
network_access_authorized	no
boot_action_authorized	no
reboot_authorized	no
evidence_cleanup_authorized	no
repository_failure_remediation_design_review_authorized	yes
machine_action_required	no
controller_action_required	no
pause_safe	no
next_stage	phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review
RECORD
