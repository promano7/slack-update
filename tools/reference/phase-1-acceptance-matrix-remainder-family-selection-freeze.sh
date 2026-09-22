#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-acceptance-matrix-remainder-family-selection-freeze.sh [--output-dir DIR] [--help]

Freeze one family from the accepted Phase 1 remainder inventory after the
step-177 fresh planning boundary. This helper selects only the
execution-control-failure-paths family. It binds no live candidate set, opens
no runtime execution authorization, and performs no machine or network action.
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
step177_policy="$acceptance_dir/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review-policy.json"
step177_record="$acceptance_dir/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review.tsv"
step175_policy="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory-policy.json"
step175_record="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory.tsv"
helper_path="$repo_root/tools/reference/phase-1-acceptance-matrix-remainder-family-selection-freeze.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}

for required in "$step177_policy" "$step177_record" "$step175_policy" "$step175_record" "$helper_path"; do
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

check_hash "$step177_policy" '3a90d6bde471d3a55eca0cec86fb34f4c4678e4a0d046f2fa40450868bc18bef'
check_hash "$step177_record" 'e9615d879ae1adcb4e062e4f2911e810d47198a37c90c031b8aee7ab81c2f0a8'
check_hash "$step175_policy" '819a5696fb9854f64a012ba6091750b40c1d658e5edd61a93c0c1e03264b16fe'
check_hash "$step175_record" 'ad4697b230ab2b22a6d3cdf2e4cc2c74a61e469b9d70da11e7f25082265dd5ff'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-acceptance-matrix-remainder-family-selection-freeze-policy.json"
record="$output_dir/phase-1-acceptance-matrix-remainder-family-selection-freeze.tsv"
step177_policy_sha=$(sha256sum -- "$step177_policy" | awk '{print $1}')
step177_record_sha=$(sha256sum -- "$step177_record" | awk '{print $1}')
step175_policy_sha=$(sha256sum -- "$step175_policy" | awk '{print $1}')
step175_record_sha=$(sha256sum -- "$step175_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step177_policy" "$step177_record" "$step175_policy" "$step175_record" "$policy" "$record" \
    "$step177_policy_sha" "$step177_record_sha" "$step175_policy_sha" "$step175_record_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p177_path, r177_path, p175_path, r175_path, out_policy, out_record = map(Path, sys.argv[1:7])
p177_sha, r177_sha, p175_sha, r175_sha, helper_sha = sys.argv[7:12]

p177 = json.loads(p177_path.read_text(encoding='utf-8'))
p175 = json.loads(p175_path.read_text(encoding='utf-8'))
with r177_path.open(encoding='utf-8', newline='') as handle:
    r177 = dict(csv.reader(handle, delimiter='\t'))
with r175_path.open(encoding='utf-8', newline='') as handle:
    inventory_rows = list(csv.DictReader(handle, delimiter='\t'))

assert p177['schema'] == 1
assert p177['scenario'] == 'phase-1-acceptance-matrix-remainder-resume-planning-boundary-review'
assert p177['review_only'] is True
assert p177['accepted_checkpoint']['step'] == 176
assert p177['accepted_checkpoint']['strong_safe_pause'] is True
assert p177['fresh_boundary']['opened'] is True
assert p177['fresh_boundary']['candidate_set_bound'] is False
assert p177['fresh_boundary']['family_selected_for_execution'] is False
assert p177['fresh_boundary']['live_runtime_chain_open'] is False
assert p177['inventory']['family_count'] == 6
assert p177['inventory']['scenario_count'] == 24
assert p177['inventory']['inventory_consistent'] is True
assert p177['next_stage'] == 'phase-1-acceptance-matrix-remainder-family-selection-freeze'
assert r177['fresh_boundary'] == 'yes'
assert r177['family_selected_for_execution'] == 'no'

assert p175['schema'] == 1
assert p175['scenario'] == 'phase-1-acceptance-matrix-remainder-inventory'
assert p175['inventory']['family_count'] == 6
assert p175['inventory']['scenario_count'] == 24
families = {row['family']: row for row in inventory_rows}
selected = families['execution-control-failure-paths']
assert selected['scenario_count'] == '4'
assert selected['runtime_boundary_required'] == 'true'
assert selected['repository_refresh_requirement'] == 'conditional'

scenarios = [
    'Network failure before repository synchronization.',
    'Simultaneous execution attempt.',
    'SIGINT, SIGTERM, and SIGHUP during safe test operations.',
    'Execution from cron with no interactive terminal.',
]
for scenario in scenarios:
    assert scenario in selected['scenarios']

for key in (
    'source_change_authorized',
    'documentation_change_authorized',
    'repository_refresh_authorized',
    'network_refresh_authorized',
    'machine_execution_authorized',
    'package_action_authorized',
    'boot_action_authorized',
    'phase_2_start_authorized',
):
    assert p177['authorization'][key] is False

policy = {
    'schema': 1,
    'scenario': 'phase-1-acceptance-matrix-remainder-family-selection-freeze',
    'review_only': True,
    'accepted_boundary': {
        'step': 177,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review-policy.json',
        'policy_sha256': p177_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review.tsv',
        'record_sha256': r177_sha,
    },
    'accepted_inventory': {
        'step': 175,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-inventory-policy.json',
        'policy_sha256': p175_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-inventory.tsv',
        'record_sha256': r175_sha,
        'family_count': 6,
        'scenario_count': 24,
    },
    'selection': {
        'selected_family': 'execution-control-failure-paths',
        'scenario_count': 4,
        'scenarios': scenarios,
        'classification': 'pending-real-system-acceptance-remainder',
        'runtime_boundary_required': True,
        'repository_refresh_requirement': 'conditional',
        'selection_frozen': True,
        'selection_basis': 'deterministic failure injection independent of live package publication and suitable for one bounded runtime validation chain',
        'candidate_set_bound': False,
        'live_runtime_chain_open': False,
        'slackware_current_publication_invalidates_selection': False,
    },
    'gates': {
        'acceptance_matrix_complete': False,
        'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
        'c_port_status': 'blocked-by-phase-1-gate',
    },
    'authorization': {
        'source_change_authorized': False,
        'documentation_change_authorized': False,
        'repository_refresh_authorized': False,
        'network_refresh_authorized': False,
        'machine_execution_authorized': False,
        'package_action_authorized': False,
        'boot_action_authorized': False,
        'phase_2_start_authorized': False,
        'future_work_requires_explicit_authorization': True,
    },
    'machine_action_required': False,
    'pause_safe': False,
    'evidence': {
        'selection_helper_sha256': helper_sha,
    },
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-family-selection-freeze.tsv',
    'next_stage': 'phase-1-execution-control-failure-paths-contract-freeze',
}

out_policy.write_text(json.dumps(policy, indent=2) + '\n', encoding='utf-8')
rows = [
    ('check', 'value'),
    ('accepted_boundary_step', '177'),
    ('accepted_boundary_policy_sha256', p177_sha),
    ('accepted_boundary_record_sha256', r177_sha),
    ('accepted_inventory_step', '175'),
    ('accepted_inventory_policy_sha256', p175_sha),
    ('accepted_inventory_record_sha256', r175_sha),
    ('inventory_family_count', '6'),
    ('inventory_scenario_count', '24'),
    ('selected_family', 'execution-control-failure-paths'),
    ('selected_family_scenario_count', '4'),
    ('selection_state', 'selected'),
    ('selection_frozen', 'yes'),
    ('runtime_boundary_required', 'yes'),
    ('repository_refresh_requirement', 'conditional'),
    ('candidate_set_bound', 'no'),
    ('live_runtime_chain_open', 'no'),
    ('acceptance_matrix_complete', 'no'),
    ('reference_freeze_status', 'blocked-behind-remaining-acceptance-work'),
    ('c_port_status', 'blocked-by-phase-1-gate'),
    ('source_change_authorized', 'no'),
    ('documentation_change_authorized', 'no'),
    ('repository_refresh_authorized', 'no'),
    ('network_refresh_authorized', 'no'),
    ('machine_execution_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('future_work_requires_explicit_authorization', 'yes'),
    ('slackware_current_publication_invalidates_selection', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-execution-control-failure-paths-contract-freeze'),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    csv.writer(handle, delimiter='\t', lineterminator='\n').writerows(rows)
PY

cat "$record"
