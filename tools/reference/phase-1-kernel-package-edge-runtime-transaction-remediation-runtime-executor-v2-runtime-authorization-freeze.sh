#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze.sh"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review.tsv"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
output_dir=''

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze.sh [--output-dir DIR] [--help]

Consume the accepted Phase 1 step-256 repository-only runtime authorization
review, revalidate the frozen executor-v2 repository acceptance, and freeze one
single-use controller/target authorization for the exact reviewed transaction.
The helper itself performs no transport, package, Slackpkg, network, boot,
reboot, or target-machine action.
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

for f in "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" \
         "$executor" "$acceptance_harness" "$helper_path"; do
    [[ -f $f && ! -L $f ]] || {
        printf 'ERROR: required repository input is missing or unsafe: %s\n' "$f" >&2
        exit 3
    }
done

check_hash() {
    local path=$1 expected=$2 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: frozen input SHA-256 drift: %s\nexpected: %s\nactual:   %s\n' "$path" "$expected" "$actual" >&2
        exit 4
    }
}

check_hash "$prior_helper" '68185a9ab2a5c5695bc359e3981a39ade9e41ffd4858741eab6bbf9551a51f6d'
check_hash "$prior_doc" 'dd88d0c97392cba2a32deff8201c116d10f1516d9f3d6f1b47c3c08d414fe42b'
check_hash "$prior_harness" '23ad4b1f15013e2b10126e19e2dc72529791d4f4f5292862b4ab36762e1bade1'
check_hash "$prior_policy" 'd298c04f78640dc7e173055534e2efbfadd6dbda9c1056cf45b9da4e9f637ab1'
check_hash "$prior_record" '8ad103a636f2dfc27b8c6dd452a07c556b1785f160c4d6b8951f860a0a2d61ca'
check_hash "$executor" 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d'
check_hash "$acceptance_harness" '86fcfd31ebe023d6fdfe3ec0c0c6bebaac3a17fd47202de43ffa3afe89854eef'

work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
if ! "$acceptance_harness" >"$work/acceptance.out" 2>&1; then
    cat -- "$work/acceptance.out" >&2
    printf 'ERROR: executor-v2 repository acceptance failed\n' >&2
    exit 5
fi
grep -Fqx 'Result: PASS (94 passes, 0 failures)' "$work/acceptance.out" || {
    cat -- "$work/acceptance.out" >&2
    printf 'ERROR: unexpected executor-v2 repository acceptance result\n' >&2
    exit 5
}

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || {
    printf 'ERROR: output directory is unsafe\n' >&2
    exit 6
}
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$prior_policy" "$prior_record" "$policy" "$record" "$helper_sha" <<'PYFREEZE'
import csv
import json
import sys
from pathlib import Path

prior_policy_path, prior_record_path, out_policy_path, out_record_path = map(Path, sys.argv[1:5])
helper_sha = sys.argv[5]
prior = json.loads(prior_policy_path.read_text(encoding='utf-8'))
with prior_record_path.open(encoding='utf-8', newline='') as handle:
    prior_record = dict(csv.reader(handle, delimiter='\t'))

assert prior['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review'
assert prior['step'] == 256
assert prior['review_status'] == 'PASS'
assert prior['review_only'] is True
assert prior['reviewed_runtime_authorization_contract']['state'] == 'reviewed-awaiting-single-use-authorization-freeze-v2'
assert prior['authorization']['repository_only_runtime_authorization_freeze_authorized'] is True
assert prior['authorization']['runtime_executor_v2_transport_authorized'] is False
assert prior['authorization']['runtime_scenario_execution_authorized'] is False
assert prior_record['step'] == '256'
assert prior_record['review_status'] == 'PASS'

contract = prior['reviewed_runtime_authorization_contract']
policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze',
    'step': 257,
    'freeze_status': 'PASS',
    'strong_safe_pause': False,
    'accepted_step_256': {
        'helper_sha256': '68185a9ab2a5c5695bc359e3981a39ade9e41ffd4858741eab6bbf9551a51f6d',
        'document_sha256': 'dd88d0c97392cba2a32deff8201c116d10f1516d9f3d6f1b47c3c08d414fe42b',
        'harness_sha256': '23ad4b1f15013e2b10126e19e2dc72529791d4f4f5292862b4ab36762e1bade1',
        'policy_sha256': 'd298c04f78640dc7e173055534e2efbfadd6dbda9c1056cf45b9da4e9f637ab1',
        'record_sha256': '8ad103a636f2dfc27b8c6dd452a07c556b1785f160c4d6b8951f860a0a2d61ca',
        'review_status': 'PASS',
        'reviewed_contract_consumed_without_change': True,
        'no_machine_authority_inherited': True,
    },
    'frozen_runtime_authorization': {
        'state': 'single-use-authorized-awaiting-controller-transport-and-runtime-v2',
        'authorization_scope': contract['authorization_scope'],
        'execution_target': contract['execution_target'],
        'required_running_kernel': contract['required_running_kernel'],
        'required_boot_id': contract['required_boot_id'],
        'required_package_database_manifest_sha256': contract['required_package_database_manifest_sha256'],
        'required_slackpkg_conf_sha256': contract['required_slackpkg_conf_sha256'],
        'required_slackpkg_mirrors_sha256': contract['required_slackpkg_mirrors_sha256'],
        'executor': contract['executor'],
        'predecessor': contract['predecessor'],
        'staged_target': contract['staged_target'],
        'local_source_v3': contract['local_source_v3'],
        'historical_state': contract['historical_state'],
        'new_evidence': contract['new_evidence'],
        'runtime_acknowledgement': contract['runtime_acknowledgement'],
        'exact_execution_command': contract['exact_execution_command'],
        'preflight_must_complete_before_first_mutation': contract['preflight_must_complete_before_first_mutation'],
        'candidate_binding_lifetime': contract['candidate_binding_lifetime'],
        'bounded_mutation': contract['bounded_mutation'],
        'required_final_state': contract['required_final_state'],
        'authorization_invalidated_by': contract['authorization_invalidated_by'],
        'drift_action': contract['drift_action'],
        'execution_use_count': 1,
        'authorization_consumed_when': 'executor-runtime-command-starts',
        'rerun_after_any_exit_authorized': False,
        'result_review_required_before_any_further_machine_action': True,
        'executor_repository_acceptance_revalidated': 'PASS (94 passes, 0 failures)',
    },
    'authorization': {
        'runtime_executor_v2_build_authorized': False,
        'runtime_executor_v2_transport_authorized': True,
        'predecessor_package_redownload_authorized': False,
        'predecessor_package_transport_authorized': True,
        'predecessor_package_staging_authorized': True,
        'temporary_slackpkg_configuration_authorized': True,
        'local_source_metadata_refresh_authorized': True,
        'repository_refresh_authorized': True,
        'runtime_candidate_binding_authorized': True,
        'reference_apply_authorized': True,
        'runtime_scenario_execution_authorized': True,
        'runtime_rerun_authorized': True,
        'package_action_authorized': True,
        'slackpkg_mutation_authorized': True,
        'network_access_authorized': False,
        'persistent_configuration_change_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'evidence_cleanup_authorized': False,
        'phase_2_start_authorized': False,
        'result_review_only_after_execution': True,
    },
    'controller_action_required': True,
    'machine_action_required': True,
    'future_work_requires_explicit_authorization': True,
    'pause_safe': False,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-result-review',
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze.sh',
    'helper_sha256': helper_sha,
}

out_policy_path.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step', '257'),
    ('revision', 'runtime-executor-v2-runtime-authorization-freeze'),
    ('freeze_status', 'PASS'),
    ('accepted_step_256', 'yes'),
    ('runtime_authorization_state', policy['frozen_runtime_authorization']['state']),
    ('authorization_scope', policy['frozen_runtime_authorization']['authorization_scope']),
    ('execution_use_count', '1'),
    ('authorization_consumed_when', policy['frozen_runtime_authorization']['authorization_consumed_when']),
    ('rerun_after_any_exit_authorized', 'no'),
    ('target_hostname', policy['frozen_runtime_authorization']['execution_target']),
    ('required_running_kernel', policy['frozen_runtime_authorization']['required_running_kernel']),
    ('required_boot_id', policy['frozen_runtime_authorization']['required_boot_id']),
    ('required_package_database_manifest_sha256', policy['frozen_runtime_authorization']['required_package_database_manifest_sha256']),
    ('canonical_executor_v2_sha256', policy['frozen_runtime_authorization']['executor']['sha256']),
    ('executor_target_transport_path', policy['frozen_runtime_authorization']['executor']['target_transport_path']),
    ('predecessor_record', policy['frozen_runtime_authorization']['predecessor']['record']),
    ('predecessor_sha256', policy['frozen_runtime_authorization']['predecessor']['sha256']),
    ('local_source_v3_tree_manifest_sha256', policy['frozen_runtime_authorization']['local_source_v3']['tree_manifest_sha256']),
    ('runtime_acknowledgement', policy['frozen_runtime_authorization']['runtime_acknowledgement']),
    ('candidate_binding_lifetime', policy['frozen_runtime_authorization']['candidate_binding_lifetime']),
    ('runtime_executor_v2_transport_authorized', 'yes'),
    ('predecessor_package_transport_authorized', 'yes'),
    ('predecessor_package_staging_authorized', 'yes'),
    ('temporary_slackpkg_configuration_authorized', 'yes'),
    ('local_source_metadata_refresh_authorized', 'yes'),
    ('runtime_candidate_binding_authorized', 'yes'),
    ('reference_apply_authorized', 'yes'),
    ('runtime_scenario_execution_authorized', 'yes'),
    ('runtime_rerun_authorized', 'yes'),
    ('package_action_authorized', 'yes'),
    ('slackpkg_mutation_authorized', 'yes'),
    ('network_access_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('machine_action_required', 'yes'),
    ('controller_action_required', 'yes'),
    ('pause_safe', 'no'),
    ('next_stage', policy['next_stage']),
]
with out_record_path.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PYFREEZE

printf 'runtime_authorization_freeze_status\tPASS\n'
printf 'executor_v2_repository_acceptance\tPASS (94 passes, 0 failures)\n'
printf 'runtime_authorization_state\tsingle-use-authorized-awaiting-controller-transport-and-runtime-v2\n'
printf 'execution_use_count\t1\n'
printf 'runtime_executor_v2_transport_authorized\tyes\n'
printf 'runtime_scenario_execution_authorized\tyes\n'
printf 'external_network_access_authorized\tno\n'
printf 'boot_action_authorized\tno\n'
printf 'reboot_authorized\tno\n'
printf 'machine_action_required\tyes\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-result-review\n'
