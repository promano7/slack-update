#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-acceptance-matrix-remainder-resume-planning-boundary-review.sh [--output-dir DIR] [--help]

Open and review the fresh repository-only planning boundary that follows the
accepted Phase 1 step-176 strong-safe-pause checkpoint. This helper preserves
the accepted 24-scenario, six-family remainder inventory, selects no runtime
family, binds no live candidate set, and grants no operational authorization.
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
step176_policy="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause-policy.json"
step176_record="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause.tsv"
helper_path="$repo_root/tools/reference/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}

for required in "$step176_policy" "$step176_record" "$helper_path"; do
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

check_hash "$step176_policy" '86eaf01a35bfee7bae0450d669b06a3d1aa3f6f7e8d47776a09f036d62ff6ea6'
check_hash "$step176_record" 'eff7de99e6a31e47cd09fff61aa26d600f34f09cffedce5cabafb0736be6c389'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review-policy.json"
record="$output_dir/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review.tsv"
step176_policy_sha=$(sha256sum -- "$step176_policy" | awk '{print $1}')
step176_record_sha=$(sha256sum -- "$step176_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step176_policy" "$step176_record" "$policy" "$record" "$step176_policy_sha" "$step176_record_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p176_path = Path(sys.argv[1])
r176_path = Path(sys.argv[2])
out_policy = Path(sys.argv[3])
out_record = Path(sys.argv[4])
p176_sha, r176_sha, helper_sha = sys.argv[5:8]

p176 = json.loads(p176_path.read_text(encoding='utf-8'))
with r176_path.open(encoding='utf-8', newline='') as handle:
    r176 = dict(csv.reader(handle, delimiter='\t'))

assert p176['schema'] == 1
assert p176['scenario'] == 'phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause'
assert p176['review_only'] is True
assert p176['accepted_inventory']['step'] == 175
review = p176['review']
assert review['inventory_family_count'] == 6
assert review['inventory_scenario_count'] == 24
assert review['inventory_consistent'] is True
assert review['roadmap_reconciliation_closed'] is True
assert review['accepted_core_scenarios_must_not_be_replayed'] is True
assert review['remaining_work_requires_fresh_scenario_boundary'] is True
assert review['candidate_set_bound'] is False
assert review['family_selected_for_execution'] is False
assert review['live_runtime_chain_open'] is False
assert review['acceptance_matrix_complete'] is False
assert p176['safe_pause']['pause_safe'] is True
assert p176['safe_pause']['strong_safe_pause'] is True
assert p176['safe_pause']['machine_action_required'] is False
assert p176['safe_pause']['no_open_operational_authorization'] is True
assert p176['safe_pause']['slackware_current_publication_invalidates_checkpoint'] is False
assert p176['safe_pause']['accepted_inventory_remains_valid_across_publication'] is True
assert p176['continuation']['next_family_selection_required'] is True
assert p176['continuation']['selection_must_occur_after_fresh_boundary'] is True
assert p176['continuation']['no_runtime_family_preselected'] is True
assert p176['next_stage'] == 'phase-1-acceptance-matrix-remainder-resume-planning'
assert r176['strong_safe_pause'] == 'yes'
assert r176['family_selected_for_execution'] == 'no'
assert r176['next_stage'] == 'phase-1-acceptance-matrix-remainder-resume-planning'

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
    assert p176['authorization'][key] is False

policy = {
    'schema': 1,
    'scenario': 'phase-1-acceptance-matrix-remainder-resume-planning-boundary-review',
    'review_only': True,
    'accepted_checkpoint': {
        'step': 176,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause-policy.json',
        'policy_sha256': p176_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-inventory-review-and-strong-safe-pause.tsv',
        'record_sha256': r176_sha,
        'strong_safe_pause': True,
        'inventory_family_count': 6,
        'inventory_scenario_count': 24,
        'accepted_inventory_remains_valid_across_publication': True,
    },
    'fresh_boundary': {
        'opened': True,
        'scope': 'phase-1-acceptance-matrix-remainder-resume-planning',
        'purpose': 'select one accepted remainder family without inheriting any prior operational authorization',
        'candidate_set_bound': False,
        'family_selected_for_execution': False,
        'live_runtime_chain_open': False,
        'slackware_current_publication_invalidates_boundary': False,
    },
    'inventory': {
        'family_count': 6,
        'scenario_count': 24,
        'inventory_consistent': True,
        'accepted_core_scenarios_must_not_be_replayed': True,
        'remaining_work_requires_fresh_scenario_boundary': True,
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
        'boundary_helper_sha256': helper_sha,
    },
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-resume-planning-boundary-review.tsv',
    'next_stage': 'phase-1-acceptance-matrix-remainder-family-selection-freeze',
}

out_policy.write_text(json.dumps(policy, indent=2) + '\n', encoding='utf-8')
record_rows = [
    ('check', 'value'),
    ('accepted_checkpoint_step', '176'),
    ('accepted_checkpoint_policy_sha256', p176_sha),
    ('accepted_checkpoint_record_sha256', r176_sha),
    ('accepted_checkpoint_strong_safe_pause', 'yes'),
    ('inventory_family_count', '6'),
    ('inventory_scenario_count', '24'),
    ('inventory_consistent', 'yes'),
    ('accepted_core_scenarios_must_not_be_replayed', 'yes'),
    ('fresh_boundary', 'yes'),
    ('boundary_scope', 'phase-1-acceptance-matrix-remainder-resume-planning'),
    ('candidate_set_bound', 'no'),
    ('family_selected_for_execution', 'no'),
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
    ('slackware_current_publication_invalidates_boundary', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-acceptance-matrix-remainder-family-selection-freeze'),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(record_rows)
PY

cat "$record"
