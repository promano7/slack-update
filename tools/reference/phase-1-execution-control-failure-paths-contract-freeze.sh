#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-execution-control-failure-paths-contract-freeze.sh [--output-dir DIR] [--help]

Freeze the Phase 1 runtime-validation contract for the selected
execution-control-failure-paths family. This helper is review-only: it defines
safe fault-injection and evidence requirements, but does not bind a machine,
open a live runtime chain, refresh repositories, access the network, or mutate
package or boot state.
USAGE
}

output_dir=
while (($#)); do
    case "$1" in
        --output-dir)
            [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }
            output_dir=$2
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            printf 'ERROR: unknown option: %s\n' "$1" >&2
            exit 2
            ;;
    esac
done

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
selection_policy="$acceptance_dir/phase-1-acceptance-matrix-remainder-family-selection-freeze-policy.json"
selection_record="$acceptance_dir/phase-1-acceptance-matrix-remainder-family-selection-freeze.tsv"
helper_path="$repo_root/tools/reference/phase-1-execution-control-failure-paths-contract-freeze.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}
for required in "$selection_policy" "$selection_record" "$helper_path"; do
    require_regular "$required"
done

check_hash() {
    local file=$1 expected=$2 actual
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: accepted prerequisite SHA-256 mismatch: %s\nexpected: %s\nactual:   %s\n' "$file" "$expected" "$actual" >&2
        exit 4
    }
}
check_hash "$selection_policy" '9f06efed40e4bcf0f32939a9e4c0b6ec77b930696cd6cad0ad12ed1b75c168a0'
check_hash "$selection_record" '8b783f4b7fc442a3fb5da2731e88b4c6882650cac1dbbc822073519b8f34a32c'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-execution-control-failure-paths-contract-freeze-policy.json"
record="$output_dir/phase-1-execution-control-failure-paths-contract-freeze.tsv"
selection_policy_sha=$(sha256sum -- "$selection_policy" | awk '{print $1}')
selection_record_sha=$(sha256sum -- "$selection_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$selection_policy" "$selection_record" "$policy" "$record" \
    "$selection_policy_sha" "$selection_record_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

selection_policy_path, selection_record_path, out_policy, out_record = map(Path, sys.argv[1:5])
selection_policy_sha, selection_record_sha, helper_sha = sys.argv[5:8]
selection = json.loads(selection_policy_path.read_text(encoding='utf-8'))
with selection_record_path.open(encoding='utf-8', newline='') as handle:
    selection_record = dict(csv.reader(handle, delimiter='\t'))

assert selection['schema'] == 1
assert selection['scenario'] == 'phase-1-acceptance-matrix-remainder-family-selection-freeze'
assert selection['selection']['selected_family'] == 'execution-control-failure-paths'
assert selection['selection']['scenario_count'] == 4
assert selection['selection']['selection_frozen'] is True
assert selection['selection']['runtime_boundary_required'] is True
assert selection['selection']['candidate_set_bound'] is False
assert selection['selection']['live_runtime_chain_open'] is False
assert selection_record['selected_family'] == 'execution-control-failure-paths'
assert selection_record['selected_family_scenario_count'] == '4'
assert selection_record['selection_frozen'] == 'yes'

scenario_contracts = [
    {
        'id': 'network-failure-before-repository-synchronization',
        'inventory_text': 'Network failure before repository synchronization.',
        'fault_model': 'controlled-failure-before-any-successful-repository-synchronization',
        'persistent_network_configuration_change_allowed': False,
        'successful_repository_synchronization_allowed': False,
        'package_or_boot_mutation_allowed': False,
        'required_result': 'fail-closed-with-clean-control-state',
    },
    {
        'id': 'simultaneous-execution-attempt',
        'inventory_text': 'Simultaneous execution attempt.',
        'fault_model': 'second-process-attempt-while-first-process-is-held-at-a-safe-non-mutating-point',
        'second_process_may_proceed_concurrently': False,
        'stale_execution_guard_allowed_after_test': False,
        'package_or_boot_mutation_allowed': False,
        'required_result': 'second-attempt-rejected-and-control-state-cleaned',
    },
    {
        'id': 'signals-during-safe-test-operations',
        'inventory_text': 'SIGINT, SIGTERM, and SIGHUP during safe test operations.',
        'signals': ['SIGINT', 'SIGTERM', 'SIGHUP'],
        'one_signal_per_run': True,
        'signal_injection_point': 'safe-non-mutating-test-operation',
        'stale_execution_guard_allowed_after_test': False,
        'package_or_boot_mutation_allowed': False,
        'required_result': 'termination-is-observable-and-control-state-is-cleaned',
    },
    {
        'id': 'cron-without-interactive-terminal',
        'inventory_text': 'Execution from cron with no interactive terminal.',
        'execution_context': 'real-cron-noninteractive-context',
        'interactive_terminal_allowed': False,
        'persistent_cron_entry_allowed_after_test': False,
        'package_or_boot_mutation_allowed': False,
        'required_result': 'noninteractive-behavior-is-deterministic-and-clean',
    },
]

inventory_texts = selection['selection']['scenarios']
assert [item['inventory_text'] for item in scenario_contracts] == inventory_texts

policy = {
    'schema': 1,
    'scenario': 'phase-1-execution-control-failure-paths-contract-freeze',
    'review_only': True,
    'accepted_selection': {
        'step': 178,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-family-selection-freeze-policy.json',
        'policy_sha256': selection_policy_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-family-selection-freeze.tsv',
        'record_sha256': selection_record_sha,
        'selected_family': 'execution-control-failure-paths',
        'scenario_count': 4,
    },
    'contract': {
        'state': 'frozen',
        'family': 'execution-control-failure-paths',
        'scenario_count': 4,
        'scenario_contracts': scenario_contracts,
        'target_class': 'slackware-current-runtime-validation-vm',
        'target_binding_deferred': True,
        'runtime_boundary_required': True,
        'candidate_set_bound': False,
        'live_runtime_chain_open': False,
        'live_package_publication_dependency': False,
        'repository_refresh_default': 'forbidden',
        'repository_refresh_exception': 'only-a-later-explicit-runtime-boundary-may-authorize-a-controlled-failing-sync-attempt',
        'network_access_default': 'forbidden',
        'source_change_allowed_during_runtime_validation': False,
        'package_mutation_allowed': False,
        'boot_mutation_allowed': False,
        'reboot_required': False,
        'persistent_system_configuration_change_allowed': False,
        'evidence_requirements': [
            'target-identity-and-runtime-boundary',
            'one-result-record-per-scenario',
            'separate-result-record-per-signal',
            'pre-and-post-control-state',
            'proof-of-no-package-or-boot-mutation',
            'cleanup-result-for-temporary-runtime-artifacts',
        ],
        'acceptance_rule': 'all-four-scenarios-must-pass-under-one-explicitly-authorized-bounded-runtime-chain',
    },
    'gates': {
        'acceptance_matrix_complete': False,
        'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
        'c_port_status': 'blocked-by-phase-1-gate',
    },
    'authorization': {
        'runtime_boundary_design_authorized_for_next_stage': True,
        'source_change_authorized': False,
        'documentation_change_authorized': False,
        'repository_refresh_authorized': False,
        'network_refresh_authorized': False,
        'machine_execution_authorized': False,
        'package_action_authorized': False,
        'boot_action_authorized': False,
        'phase_2_start_authorized': False,
        'future_machine_work_requires_explicit_authorization': True,
    },
    'machine_action_required': False,
    'slackware_current_publication_invalidates_contract': False,
    'helper_path': 'tools/reference/phase-1-execution-control-failure-paths-contract-freeze.sh',
    'helper_sha256': helper_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-contract-freeze.tsv',
    'next_stage': 'phase-1-execution-control-failure-paths-runtime-boundary-design',
    'pause_safe': False,
}
Path(out_policy).write_text(json.dumps(policy, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
rows = [
    ('check', 'value'),
    ('accepted_selection_step', '178'),
    ('accepted_selection_policy_sha256', selection_policy_sha),
    ('accepted_selection_record_sha256', selection_record_sha),
    ('selected_family', 'execution-control-failure-paths'),
    ('scenario_count', '4'),
    ('contract_state', 'frozen'),
    ('target_class', 'slackware-current-runtime-validation-vm'),
    ('target_binding_deferred', 'yes'),
    ('runtime_boundary_required', 'yes'),
    ('candidate_set_bound', 'no'),
    ('live_runtime_chain_open', 'no'),
    ('live_package_publication_dependency', 'no'),
    ('repository_refresh_default', 'forbidden'),
    ('network_access_default', 'forbidden'),
    ('package_mutation_allowed', 'no'),
    ('boot_mutation_allowed', 'no'),
    ('reboot_required', 'no'),
    ('persistent_system_configuration_change_allowed', 'no'),
    ('network_failure_required_result', 'fail-closed-with-clean-control-state'),
    ('simultaneous_execution_required_result', 'second-attempt-rejected-and-control-state-cleaned'),
    ('signal_set', 'SIGINT,SIGTERM,SIGHUP'),
    ('signals_required_result', 'termination-is-observable-and-control-state-is-cleaned'),
    ('cron_execution_context', 'real-cron-noninteractive-context'),
    ('cron_required_result', 'noninteractive-behavior-is-deterministic-and-clean'),
    ('acceptance_matrix_complete', 'no'),
    ('reference_freeze_status', 'blocked-behind-remaining-acceptance-work'),
    ('c_port_status', 'blocked-by-phase-1-gate'),
    ('runtime_boundary_design_authorized_for_next_stage', 'yes'),
    ('repository_refresh_authorized', 'no'),
    ('network_refresh_authorized', 'no'),
    ('machine_execution_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('slackware_current_publication_invalidates_contract', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-execution-control-failure-paths-runtime-boundary-design'),
]
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

cat -- "$record"
