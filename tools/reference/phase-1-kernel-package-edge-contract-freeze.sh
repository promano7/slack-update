#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-contract-freeze.sh [--output-dir DIR] [--help]

Freeze the Phase 1 runtime-validation contract for the selected
kernel-package-edge family. The contract requires a controlled real-system
package-state transition in which configured kernel headers change while no
configured kernel boot package changes. This helper is review-only: it binds no
machine or package source and performs no repository, network, package, boot,
or system-restart action.
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
selection_policy="$acceptance_dir/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze-policy.json"
selection_record="$acceptance_dir/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze.tsv"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-contract-freeze.sh"

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
check_hash "$selection_policy" 'edc91e482043c73cf5566963145f078171c875c35c0f557f0643935818eac128'
check_hash "$selection_record" 'b2a1db47fd414f68fb8f18134fcc00b95a7b3cd4e3d7fa0650a19178eaa4a82d'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-contract-freeze-policy.json"
record="$output_dir/phase-1-kernel-package-edge-contract-freeze.tsv"
selection_policy_sha=$(sha256sum -- "$selection_policy" | awk '{print $1}')
selection_record_sha=$(sha256sum -- "$selection_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$selection_policy" "$selection_record" "$policy" "$record" \
    "$selection_policy_sha" "$selection_record_sha" "$helper_sha" <<'PY_INNER'
import csv
import json
import sys
from pathlib import Path

selection_policy_path, selection_record_path, out_policy, out_record = map(Path, sys.argv[1:5])
selection_policy_sha, selection_record_sha, helper_sha = sys.argv[5:8]

selection = json.loads(selection_policy_path.read_text(encoding='utf-8'))
with selection_record_path.open(encoding='utf-8', newline='') as handle:
    selection_record = dict(csv.reader(handle, delimiter='\t'))

scenario_text = 'Kernel headers update without a kernel image update.'
assert selection['schema'] == 1
assert selection['scenario'] == 'phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze'
assert selection['selection']['selected_family'] == 'kernel-package-edge'
assert selection['selection']['scenario_count'] == 1
assert selection['selection']['scenarios'] == [scenario_text]
assert selection['selection']['selection_frozen'] is True
assert selection['selection']['runtime_boundary_required'] is True
assert selection['selection']['candidate_set_bound'] is False
assert selection['selection']['live_runtime_chain_open'] is False
assert selection_record['selected_family'] == 'kernel-package-edge'
assert selection_record['selected_family_scenario_count'] == '1'
assert selection_record['selected_scenario'] == scenario_text
assert selection_record['selection_frozen'] == 'yes'

contract = {
    'state': 'frozen',
    'family': 'kernel-package-edge',
    'scenario_count': 1,
    'scenario': {
        'id': 'kernel-headers-update-without-kernel-boot-package-update',
        'inventory_text': scenario_text,
        'validation_mode': 'controlled-real-system-package-state-transition',
        'required_header_delta': 'at-least-one-configured-kernel-header-package-changes',
        'required_boot_package_delta': 'zero-configured-kernel-boot-packages-change',
        'kernel_trigger_expected': True,
        'initrd_update_expected': False,
        'grub_update_expected': False,
        'external_module_warning_expected': True,
        'boot_preparation_execution_allowed': False,
        'reboot_required': False,
    },
    'target_class': 'slackware-current-runtime-validation-vm',
    'target_binding_deferred': True,
    'package_source_binding_deferred': True,
    'candidate_set_bound': False,
    'live_runtime_chain_open': False,
    'runtime_boundary_required': True,
    'repository_refresh_requirement': 'conditional',
    'repository_refresh_default': 'forbidden',
    'network_access_default': 'forbidden',
    'package_mutation_during_future_runtime_may_be_authorized': True,
    'package_mutation_authorized_by_this_step': False,
    'boot_mutation_allowed': False,
    'persistent_boot_configuration_change_allowed': False,
    'boot_artifact_fingerprints_must_remain_unchanged': True,
    'running_kernel_must_remain_unchanged': True,
    'final_package_state_must_be_coherent': True,
    'temporary_runtime_artifacts_must_be_cleaned': True,
    'evidence_requirements': [
        'target-identity-and-runtime-boundary',
        'configured-kernel-header-and-boot-package-sets',
        'pre-and-post-package-snapshots',
        'proof-that-at-least-one-configured-header-package-changed',
        'proof-that-no-configured-kernel-boot-package-changed',
        'kernel-trigger-initrd-grub-decision-output',
        'external-module-warning-output',
        'pre-and-post-boot-artifact-fingerprints',
        'running-kernel-before-and-after',
        'cleanup-and-final-package-state',
    ],
    'acceptance_rule': 'header-delta-is-observed-while-boot-package-delta-is-zero-and-no-boot-preparation-or-system-restart-is-triggered',
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-contract-freeze',
    'review_only': True,
    'accepted_selection': {
        'step': 190,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze-policy.json',
        'policy_sha256': selection_policy_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze.tsv',
        'record_sha256': selection_record_sha,
        'selected_family': 'kernel-package-edge',
        'scenario_count': 1,
    },
    'contract': contract,
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
        'reboot_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'phase_2_start_authorized': False,
        'future_machine_work_requires_explicit_authorization': True,
    },
    'machine_action_required': False,
    'slackware_current_publication_invalidates_contract': False,
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-contract-freeze.sh',
    'helper_sha256': helper_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-contract-freeze.tsv',
    'next_stage': 'phase-1-kernel-package-edge-runtime-boundary-design',
    'pause_safe': False,
}
Path(out_policy).write_text(json.dumps(policy, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
rows = [
    ('check', 'value'),
    ('accepted_selection_step', '190'),
    ('accepted_selection_policy_sha256', selection_policy_sha),
    ('accepted_selection_record_sha256', selection_record_sha),
    ('selected_family', 'kernel-package-edge'),
    ('scenario_count', '1'),
    ('selected_scenario', scenario_text),
    ('contract_state', 'frozen'),
    ('validation_mode', 'controlled-real-system-package-state-transition'),
    ('target_class', 'slackware-current-runtime-validation-vm'),
    ('target_binding_deferred', 'yes'),
    ('package_source_binding_deferred', 'yes'),
    ('runtime_boundary_required', 'yes'),
    ('repository_refresh_requirement', 'conditional'),
    ('candidate_set_bound', 'no'),
    ('live_runtime_chain_open', 'no'),
    ('required_header_delta', 'at-least-one-configured-kernel-header-package-changes'),
    ('required_boot_package_delta', 'zero-configured-kernel-boot-packages-change'),
    ('kernel_trigger_expected', 'yes'),
    ('initrd_update_expected', 'no'),
    ('grub_update_expected', 'no'),
    ('external_module_warning_expected', 'yes'),
    ('boot_preparation_execution_allowed', 'no'),
    ('boot_artifact_fingerprints_must_remain_unchanged', 'yes'),
    ('running_kernel_must_remain_unchanged', 'yes'),
    ('reboot_required', 'no'),
    ('final_package_state_must_be_coherent', 'yes'),
    ('repository_refresh_default', 'forbidden'),
    ('network_access_default', 'forbidden'),
    ('package_mutation_authorized_by_this_step', 'no'),
    ('boot_mutation_allowed', 'no'),
    ('acceptance_matrix_complete', 'no'),
    ('reference_freeze_status', 'blocked-behind-remaining-acceptance-work'),
    ('c_port_status', 'blocked-by-phase-1-gate'),
    ('runtime_boundary_design_authorized_for_next_stage', 'yes'),
    ('repository_refresh_authorized', 'no'),
    ('network_refresh_authorized', 'no'),
    ('machine_execution_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('slackware_current_publication_invalidates_contract', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-kernel-package-edge-runtime-boundary-design'),
]
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY_INNER

cat -- "$record"
