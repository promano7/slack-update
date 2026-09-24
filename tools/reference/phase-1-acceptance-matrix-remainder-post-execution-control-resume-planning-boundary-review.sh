#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review.sh [--output-dir DIR] [--help]

Open and review the fresh repository-only planning boundary that follows the
accepted Phase 1 step-188 execution-control strong-safe-pause checkpoint.
This helper preserves the accepted 20-scenario, five-family residual inventory,
selects no runtime family, binds no live candidate set, and grants no
operational authorization.
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
step188_policy="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause-policy.json"
step188_record="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.tsv"
remaining_inventory="$acceptance_dir/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv"
helper_path="$repo_root/tools/reference/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}

for required in "$step188_policy" "$step188_record" "$remaining_inventory" "$helper_path"; do
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

check_hash "$step188_policy" 'b7a78b9dfbb6eeb3c802820a2566deae96f43c5dace3a22a8e88ab513f623d63'
check_hash "$step188_record" '427e07e26cfc9449c0df3e0bd20cc97dfcc681825e1a073d0d83ea9fd49969fb'
check_hash "$remaining_inventory" '8aa3f1dbe177ec336025f4b3983e22b07205d8bf72fb214442704764131094e9'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review-policy.json"
record="$output_dir/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review.tsv"
step188_policy_sha=$(sha256sum -- "$step188_policy" | awk '{print $1}')
step188_record_sha=$(sha256sum -- "$step188_record" | awk '{print $1}')
remaining_inventory_sha=$(sha256sum -- "$remaining_inventory" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step188_policy" "$step188_record" "$remaining_inventory" "$policy" "$record" "$step188_policy_sha" "$step188_record_sha" "$remaining_inventory_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p188_path = Path(sys.argv[1])
r188_path = Path(sys.argv[2])
remaining_path = Path(sys.argv[3])
out_policy = Path(sys.argv[4])
out_record = Path(sys.argv[5])
p188_sha, r188_sha, remaining_sha, helper_sha = sys.argv[6:10]

p188 = json.loads(p188_path.read_text(encoding='utf-8'))
with r188_path.open(encoding='utf-8', newline='') as handle:
    r188 = dict(csv.reader(handle, delimiter='\t'))
with remaining_path.open(encoding='utf-8', newline='') as handle:
    remaining = list(csv.DictReader(handle, delimiter='\t'))

assert p188['schema'] == 1
assert p188['scenario'] == 'phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause'
assert p188['review_only'] is True
assert p188['closed_family']['family'] == 'execution-control-failure-paths'
assert p188['closed_family']['closure_status'] == 'accepted'
assert p188['closed_family']['replay_required_by_default'] is False
assert p188['remaining_inventory']['family_count'] == 5
assert p188['remaining_inventory']['scenario_count'] == 20
assert p188['remaining_inventory']['record_sha256'] == remaining_sha
assert p188['safe_pause']['pause_safe'] is True
assert p188['safe_pause']['strong_safe_pause'] is True
assert p188['safe_pause']['machine_action_required'] is False
assert p188['safe_pause']['no_open_operational_authorization'] is True
assert p188['safe_pause']['slackware_current_publication_invalidates_checkpoint'] is False
assert p188['continuation']['next_family_selection_required'] is True
assert p188['continuation']['selection_must_occur_after_fresh_boundary'] is True
assert p188['continuation']['no_runtime_family_preselected'] is True
assert p188['next_stage'] == 'phase-1-acceptance-matrix-remainder-resume-planning'
assert r188['strong_safe_pause'] == 'yes'
assert r188['family_selected_for_execution'] == 'no'
assert r188['live_runtime_chain_open'] == 'no'
assert r188['runtime_scenario_execution_authorized'] == 'no'
assert r188['next_stage'] == 'phase-1-acceptance-matrix-remainder-resume-planning'

expected = {
    'kernel-package-edge': 1,
    'boot-safety-failure-paths': 7,
    'sbo-elf-optional-runtime': 6,
    'cinnamon-optional-runtime': 3,
    'flatpak-optional-runtime': 3,
}
assert {row['family']: int(row['scenario_count']) for row in remaining} == expected
assert sum(int(row['scenario_count']) for row in remaining) == 20
assert all(row['runtime_boundary_required'] == 'true' for row in remaining)
assert all(row['repository_refresh_requirement'] == 'conditional' for row in remaining)
assert 'execution-control-failure-paths' not in expected

for key in (
    'source_change_authorized',
    'documentation_change_authorized',
    'repository_refresh_authorized',
    'network_refresh_authorized',
    'machine_execution_authorized',
    'package_action_authorized',
    'boot_action_authorized',
    'reboot_authorized',
    'runtime_scenario_execution_authorized',
    'phase_2_start_authorized',
):
    assert p188['authorization'][key] is False

policy = {
    'schema': 1,
    'scenario': 'phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review',
    'review_only': True,
    'accepted_checkpoint': {
        'step': 188,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause-policy.json',
        'policy_sha256': p188_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.tsv',
        'record_sha256': r188_sha,
        'strong_safe_pause': True,
        'closed_family': 'execution-control-failure-paths',
        'closed_family_replay_required_by_default': False,
        'accepted_runtime_closure_remains_valid_across_publication': True,
    },
    'fresh_boundary': {
        'opened': True,
        'scope': 'phase-1-acceptance-matrix-remainder-resume-planning',
        'purpose': 'select one residual Phase 1 family without inheriting step-187 runtime authority or reopening the closed execution-control family',
        'candidate_set_bound': False,
        'family_selected_for_execution': False,
        'live_runtime_chain_open': False,
        'slackware_current_publication_invalidates_boundary': False,
    },
    'inventory': {
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv',
        'record_sha256': remaining_sha,
        'family_count': 5,
        'scenario_count': 20,
        'inventory_consistent': True,
        'closed_execution_control_family_excluded': True,
        'accepted_closed_families_must_not_be_replayed': True,
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
        'reboot_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'phase_2_start_authorized': False,
        'future_work_requires_explicit_authorization': True,
    },
    'machine_action_required': False,
    'pause_safe': False,
    'evidence': {
        'boundary_helper_sha256': helper_sha,
    },
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review.tsv',
    'next_stage': 'phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze',
}

out_policy.write_text(json.dumps(policy, indent=2) + '\n', encoding='utf-8')
record_rows = [
    ('check', 'value'),
    ('accepted_checkpoint_step', '188'),
    ('accepted_checkpoint_policy_sha256', p188_sha),
    ('accepted_checkpoint_record_sha256', r188_sha),
    ('accepted_checkpoint_strong_safe_pause', 'yes'),
    ('closed_family', 'execution-control-failure-paths'),
    ('closed_family_replay_required_by_default', 'no'),
    ('remaining_inventory_sha256', remaining_sha),
    ('inventory_family_count', '5'),
    ('inventory_scenario_count', '20'),
    ('inventory_consistent', 'yes'),
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
    ('reboot_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('future_work_requires_explicit_authorization', 'yes'),
    ('slackware_current_publication_invalidates_boundary', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze'),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(record_rows)
PY

cat "$record"
