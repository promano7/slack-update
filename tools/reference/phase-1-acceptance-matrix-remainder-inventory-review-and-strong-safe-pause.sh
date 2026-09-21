#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause.sh [--output-dir DIR] [--help]

Review the accepted Phase 1 acceptance-matrix remainder inventory and emit a
strong-safe-pause checkpoint. The review is repository-only. It verifies the
frozen 24-scenario, six-family inventory and preserves every Phase 1 gate.
It grants no source, documentation, repository-refresh, network, machine,
package, boot, or Phase 2 authority.
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
step175_policy="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory-policy.json"
step175_record="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory.tsv"
helper_path="$repo_root/tools/reference/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}

for required in "$step175_policy" "$step175_record" "$helper_path"; do
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

check_hash "$step175_policy" '819a5696fb9854f64a012ba6091750b40c1d658e5edd61a93c0c1e03264b16fe'
check_hash "$step175_record" 'ad4697b230ab2b22a6d3cdf2e4cc2c74a61e469b9d70da11e7f25082265dd5ff'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause-policy.json"
record="$output_dir/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause.tsv"
step175_policy_sha=$(sha256sum -- "$step175_policy" | awk '{print $1}')
step175_record_sha=$(sha256sum -- "$step175_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step175_policy" "$step175_record" "$policy" "$record" "$step175_policy_sha" "$step175_record_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p175_path = Path(sys.argv[1])
r175_path = Path(sys.argv[2])
out_policy = Path(sys.argv[3])
out_record = Path(sys.argv[4])
p175_sha, r175_sha, helper_sha = sys.argv[5:8]

p175 = json.loads(p175_path.read_text(encoding='utf-8'))
with r175_path.open(encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))

assert p175['schema'] == 1
assert p175['scenario'] == 'phase-1-acceptance-matrix-remainder-inventory'
assert p175['review_only'] is True
inv = p175['inventory']
assert inv['family_count'] == 6
assert inv['scenario_count'] == 24
assert inv['classification'] == 'pending-real-system-acceptance-remainder'
assert inv['contains_machine_work'] is True
assert inv['machine_work_authorized'] is False
assert inv['candidate_set_bound'] is False
assert inv['repository_refresh_required_now'] is False
assert inv['roadmap_reconciliation_closed'] is True
assert inv['accepted_core_scenarios_must_not_be_replayed'] is True
assert len(inv['accepted_core_coverage']) == 5
assert len(rows) == 6
expected_counts = {
    'kernel-package-edge': 1,
    'boot-safety-failure-paths': 7,
    'sbo-elf-optional-runtime': 6,
    'cinnamon-optional-runtime': 3,
    'flatpak-optional-runtime': 3,
    'execution-control-failure-paths': 4,
}
assert {row['family']: int(row['scenario_count']) for row in rows} == expected_counts
assert sum(expected_counts.values()) == 24
assert all(row['runtime_boundary_required'] == 'true' for row in rows)
assert all(row['repository_refresh_requirement'] == 'conditional' for row in rows)
assert p175['gates']['acceptance_matrix_complete'] is False
assert p175['gates']['reference_freeze_status'] == 'blocked-behind-remaining-acceptance-work'
assert p175['gates']['c_port_status'] == 'blocked-by-phase-1-gate'
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
    assert p175['authorization'][key] is False
assert p175['authorization']['future_work_requires_explicit_authorization'] is True
assert p175['authorization']['future_work_requires_fresh_boundary'] is True
assert p175['safe_pause']['pause_safe'] is False
assert p175['safe_pause']['strong_safe_pause'] is False
assert p175['safe_pause']['machine_action_required'] is False
assert p175['safe_pause']['slackware_current_publication_invalidates_inventory'] is False
assert p175['next_stage'] == 'phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause'

policy = {
    'schema': 1,
    'scenario': 'phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause',
    'review_only': True,
    'accepted_inventory': {
        'step': 175,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-inventory-policy.json',
        'policy_sha256': p175_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-inventory.tsv',
        'record_sha256': r175_sha,
    },
    'review': {
        'inventory_family_count': 6,
        'inventory_scenario_count': 24,
        'inventory_consistent': True,
        'roadmap_reconciliation_closed': True,
        'accepted_core_scenarios_must_not_be_replayed': True,
        'accepted_core_coverage_count': 5,
        'remaining_work_requires_fresh_scenario_boundary': True,
        'candidate_set_bound': False,
        'family_selected_for_execution': False,
        'live_runtime_chain_open': False,
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
        'future_work_requires_fresh_boundary': True,
    },
    'safe_pause': {
        'pause_safe': True,
        'strong_safe_pause': True,
        'machine_action_required': False,
        'no_open_operational_authorization': True,
        'slackware_current_publication_invalidates_checkpoint': False,
        'accepted_inventory_remains_valid_across_publication': True,
    },
    'continuation': {
        'next_family_selection_required': True,
        'selection_must_occur_after_fresh_boundary': True,
        'repository_refresh_must_be_justified_by_selected_scenario': True,
        'no_runtime_family_preselected': True,
    },
    'evidence': {
        'review_helper_sha256': helper_sha,
    },
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause.tsv',
    'next_stage': 'phase-1-acceptance-matrix-remainder-resume-planning',
}

out_policy.write_text(json.dumps(policy, indent=2) + '\n', encoding='utf-8')
record_rows = [
    ('check', 'value'),
    ('accepted_inventory_step', '175'),
    ('inventory_family_count', '6'),
    ('inventory_scenario_count', '24'),
    ('inventory_consistent', 'yes'),
    ('roadmap_reconciliation_closed', 'yes'),
    ('accepted_core_scenarios_must_not_be_replayed', 'yes'),
    ('accepted_core_coverage_count', '5'),
    ('remaining_work_requires_fresh_scenario_boundary', 'yes'),
    ('candidate_set_bound', 'no'),
    ('family_selected_for_execution', 'no'),
    ('live_runtime_chain_open', 'no'),
    ('acceptance_matrix_complete', 'no'),
    ('reference_freeze_status', 'blocked-behind-remaining-acceptance-work'),
    ('c_port_status', 'blocked-by-phase-1-gate'),
    ('pause_safe', 'yes'),
    ('strong_safe_pause', 'yes'),
    ('machine_action_required', 'no'),
    ('no_open_operational_authorization', 'yes'),
    ('slackware_current_publication_invalidates_checkpoint', 'no'),
    ('accepted_inventory_remains_valid_across_publication', 'yes'),
    ('future_work_requires_explicit_authorization', 'yes'),
    ('future_work_requires_fresh_boundary', 'yes'),
    ('next_family_selection_required', 'yes'),
    ('no_runtime_family_preselected', 'yes'),
    ('next_stage', 'phase-1-acceptance-matrix-remainder-resume-planning'),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(record_rows)
PY

printf 'Phase 1 acceptance-matrix remainder inventory review completed successfully.\n'
printf 'Strong safe pause established; no runtime family is selected or authorized.\n'
