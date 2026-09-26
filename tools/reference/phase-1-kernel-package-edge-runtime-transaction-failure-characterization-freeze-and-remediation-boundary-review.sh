#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.sh [--output-dir DIR] [--help]

Freeze the accepted first-attempt failure characterization and the repository-only
remediation boundary for the Phase 1 kernel-package-edge runtime transaction.
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

step218_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review-policy.json"
step218_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review.tsv"
step218_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-probe.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
source_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"

for path in "$step218_policy" "$step218_record" "$step218_probe" "$executor" "$source_builder"; do
    [[ -f $path && ! -L $path ]] || { echo "ERROR: prerequisite missing or unsafe: $path" >&2; exit 1; }
done

[[ $(sha256sum -- "$step218_policy" | awk '{print $1}') == 'b60151eb7065a9300e931c8918f00553d8b34924fbbcd6d27def95787886389d' ]] || { echo 'ERROR: step-218-r1 policy SHA-256 drift' >&2; exit 1; }
[[ $(sha256sum -- "$step218_record" | awk '{print $1}') == '07141eefbc338fe7b41bae866c26ce7b7c4eba0a0aec7d4ead0b48d85ac66627' ]] || { echo 'ERROR: step-218-r1 record SHA-256 drift' >&2; exit 1; }
[[ $(sha256sum -- "$step218_probe" | awk '{print $1}') == '0f9388cde7fcb178e8f06ff2b200d503c29fb454fa9502091701cc5d2752098d' ]] || { echo 'ERROR: step-218-r1 probe SHA-256 drift' >&2; exit 1; }
[[ $(sha256sum -- "$executor" | awk '{print $1}') == '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300' ]] || { echo 'ERROR: failed executor identity drift' >&2; exit 1; }
[[ $(sha256sum -- "$source_builder" | awk '{print $1}') == '59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92' ]] || { echo 'ERROR: accepted local-source builder identity drift' >&2; exit 1; }

python3 - "$step218_policy" <<'PY'
import json,sys
p=json.load(open(sys.argv[1],encoding='utf-8'))
assert p['scenario']=='phase-1-kernel-package-edge-runtime-transaction-first-attempt-failure-review'
assert p['review_revision']=='218-r1'
assert p['runtime_rerun_authorized'] is False
assert p['failed_evidence_root_must_be_preserved'] is True
PY

cat > "$output_dir/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review-policy.json" <<'JSON'
{
  "scenario": "phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review",
  "step": 219,
  "review_status": "PASS",
  "failure_characterization_status": "PASS",
  "cleanup_triggered": true,
  "header_restored": true,
  "package_database_restored": true,
  "slackpkg_configuration_restored": true,
  "slackpkg_state_restored": true,
  "geninitrd_policy_restored": true,
  "boot_artifacts_unchanged": true,
  "published_success_evidence_absent": true,
  "failed_run_slackpkg_update_exit_code": 0,
  "failed_run_slackpkg_update_error_signal": "error-downloading-from-local-source",
  "restored_pkglist_rows": 2032,
  "restored_pkglist_target_rows": 1,
  "local_source_CHECKSUMS_md5_asc_absent": true,
  "failed_executor_sha256": "09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300",
  "accepted_local_source_builder_sha256": "59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92",
  "failure_mechanism": {
    "slackpkg_refresh_exit_code_alone_is_sufficient": false,
    "local_source_v1_is_slackpkg_update_compatible": false,
    "global_pkglist_row_count_is_valid_candidate_guard": false,
    "preflight_literal_backslash_t_is_accepted_for_future_runs": false
  },
  "remediation_boundary": {
    "preserve_local_source_v1": true,
    "preserve_failed_evidence_root": true,
    "modify_local_source_v1_in_place": false,
    "new_local_source_generation_required": true,
    "new_local_source_generation_name": "local-source-v2",
    "new_local_source_requires_slackpkg_refresh_compatibility_metadata": true,
    "new_local_source_requires_CHECKSUMS_md5_asc_compatibility_artifact": true,
    "new_local_source_requires_priority_tree_metadata": true,
    "metadata_authenticity_source": "frozen-package-sha256-and-tree-manifest-not-local-compatibility-asc",
    "refresh_success_requires_exit_zero": true,
    "refresh_success_requires_no_error_downloading_signal": true,
    "refresh_success_requires_workdir_metadata_freshness_proof": true,
    "candidate_guard_scope": "target-specific-not-global-pkglist-row-count",
    "candidate_guard_requires_exactly_one_target_row": true,
    "candidate_guard_requires_predecessor_installed": true,
    "candidate_guard_requires_target_source_binding": true,
    "evidence_encoding": "real-tab-tsv",
    "remediation_must_be_revalidated_before_package_mutation": true
  },
  "runtime_rerun_authorized": false,
  "package_action_authorized": false,
  "slackpkg_mutation_authorized": false,
  "network_access_authorized": false,
  "boot_action_authorized": false,
  "reboot_authorized": false,
  "persistent_configuration_change_authorized": false,
  "machine_action_required": false,
  "controller_action_required": false,
  "pause_safe": false,
  "next_stage": "phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause"
}
JSON

cat > "$output_dir/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review.tsv" <<'TSV'
step	219
review_status	PASS
failure_characterization_status	PASS
cleanup_triggered	yes
header_restored	yes
package_database_restored	yes
slackpkg_configuration_restored	yes
slackpkg_state_restored	yes
geninitrd_policy_restored	yes
boot_artifacts_unchanged	yes
published_success_evidence_absent	yes
failed_run_slackpkg_update_exit_code	0
failed_run_slackpkg_update_error_signal	error-downloading-from-local-source
restored_pkglist_rows	2032
restored_pkglist_target_rows	1
local_source_CHECKSUMS_md5_asc_absent	yes
failed_executor_sha256	09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300
accepted_local_source_builder_sha256	59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92
local_source_v1_preserved	yes
failed_evidence_root_preserved	yes
modify_local_source_v1_in_place	no
new_local_source_generation_required	yes
new_local_source_generation_name	local-source-v2
slackpkg_refresh_compatibility_metadata_required	yes
CHECKSUMS_md5_asc_compatibility_artifact_required	yes
priority_tree_metadata_required	yes
refresh_success_requires_exit_zero	yes
refresh_success_requires_no_error_downloading_signal	yes
refresh_success_requires_workdir_metadata_freshness_proof	yes
candidate_guard_scope	target-specific-not-global-pkglist-row-count
candidate_guard_requires_exactly_one_target_row	yes
candidate_guard_requires_predecessor_installed	yes
candidate_guard_requires_target_source_binding	yes
evidence_encoding	real-tab-tsv
remediation_must_be_revalidated_before_package_mutation	yes
runtime_rerun_authorized	no
package_action_authorized	no
slackpkg_mutation_authorized	no
network_access_authorized	no
boot_action_authorized	no
reboot_authorized	no
persistent_configuration_change_authorized	no
machine_action_required	no
controller_action_required	no
pause_safe	no
next_stage	phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause
TSV

printf 'review_status\tPASS\n'
printf 'failure_characterization_status\tPASS\n'
printf 'runtime_rerun_authorized\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause\n'
