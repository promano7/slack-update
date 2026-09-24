#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze.sh [--output-dir DIR] [--help]

Freeze one family from the accepted post-execution-control Phase 1 remainder
inventory after the step-189 fresh planning boundary. This helper selects only
the kernel-package-edge family. It binds no live candidate set, opens no
runtime execution authorization, and performs no machine or network action.
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
step189_policy="$acceptance_dir/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review-policy.json"
step189_record="$acceptance_dir/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review.tsv"
residual_inventory="$acceptance_dir/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv"
helper_path="$repo_root/tools/reference/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}

for required in "$step189_policy" "$step189_record" "$residual_inventory" "$helper_path"; do
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

check_hash "$step189_policy" 'e14c2a8ac8d11fe5d8416bf52e724e5883c523228193e4f0c1235a5510540c9f'
check_hash "$step189_record" '8a9a5e70ea1eec093f0ed5528d99f9436b3eafcaa835002227c25b817164bacc'
check_hash "$residual_inventory" '8aa3f1dbe177ec336025f4b3983e22b07205d8bf72fb214442704764131094e9'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze-policy.json"
record="$output_dir/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze.tsv"
step189_policy_sha=$(sha256sum -- "$step189_policy" | awk '{print $1}')
step189_record_sha=$(sha256sum -- "$step189_record" | awk '{print $1}')
residual_inventory_sha=$(sha256sum -- "$residual_inventory" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step189_policy" "$step189_record" "$residual_inventory" "$policy" "$record" \
    "$step189_policy_sha" "$step189_record_sha" "$residual_inventory_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p189_path, r189_path, inventory_path, out_policy, out_record = map(Path, sys.argv[1:6])
p189_sha, r189_sha, inventory_sha, helper_sha = sys.argv[6:10]

p189 = json.loads(p189_path.read_text(encoding='utf-8'))
with r189_path.open(encoding='utf-8', newline='') as handle:
    r189 = dict(csv.reader(handle, delimiter='\t'))
with inventory_path.open(encoding='utf-8', newline='') as handle:
    inventory_rows = list(csv.DictReader(handle, delimiter='\t'))

assert p189['schema'] == 1
assert p189['scenario'] == 'phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review'
assert p189['review_only'] is True
assert p189['accepted_checkpoint']['step'] == 188
assert p189['accepted_checkpoint']['strong_safe_pause'] is True
assert p189['accepted_checkpoint']['closed_family'] == 'execution-control-failure-paths'
assert p189['accepted_checkpoint']['closed_family_replay_required_by_default'] is False
assert p189['fresh_boundary']['opened'] is True
assert p189['fresh_boundary']['candidate_set_bound'] is False
assert p189['fresh_boundary']['family_selected_for_execution'] is False
assert p189['fresh_boundary']['live_runtime_chain_open'] is False
assert p189['inventory']['family_count'] == 5
assert p189['inventory']['scenario_count'] == 20
assert p189['inventory']['inventory_consistent'] is True
assert p189['inventory']['closed_execution_control_family_excluded'] is True
assert p189['next_stage'] == 'phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze'
assert r189['accepted_checkpoint_step'] == '188'
assert r189['fresh_boundary'] == 'yes'
assert r189['family_selected_for_execution'] == 'no'

families = {row['family']: row for row in inventory_rows}
assert len(families) == 5
assert sum(int(row['scenario_count']) for row in inventory_rows) == 20
assert 'execution-control-failure-paths' not in families
selected = families['kernel-package-edge']
assert selected['scenario_count'] == '1'
assert selected['runtime_boundary_required'] == 'true'
assert selected['repository_refresh_requirement'] == 'conditional'
scenario = 'Kernel headers update without a kernel image update.'
assert selected['scenarios'] == scenario

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
    assert p189['authorization'][key] is False

policy = {
    'schema': 1,
    'scenario': 'phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze',
    'review_only': True,
    'accepted_boundary': {
        'step': 189,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review-policy.json',
        'policy_sha256': p189_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-resume-planning-boundary-review.tsv',
        'record_sha256': r189_sha,
    },
    'accepted_inventory': {
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv',
        'record_sha256': inventory_sha,
        'family_count': 5,
        'scenario_count': 20,
        'closed_family': 'execution-control-failure-paths',
        'closed_family_excluded': True,
    },
    'selection': {
        'selected_family': 'kernel-package-edge',
        'scenario_count': 1,
        'scenarios': [scenario],
        'classification': 'pending-real-system-acceptance-remainder',
        'runtime_boundary_required': True,
        'repository_refresh_requirement': 'conditional',
        'selection_frozen': True,
        'selection_basis': 'single narrow kernel-package edge scenario that can be isolated from boot-safety and optional-module acceptance families',
        'candidate_set_bound': False,
        'live_runtime_chain_open': False,
        'closed_execution_control_family_reopened': False,
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
        'reboot_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'phase_2_start_authorized': False,
        'future_work_requires_explicit_authorization': True,
    },
    'machine_action_required': False,
    'pause_safe': False,
    'evidence': {
        'selection_helper_sha256': helper_sha,
    },
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-post-execution-control-family-selection-freeze.tsv',
    'next_stage': 'phase-1-kernel-package-edge-contract-freeze',
}
Path(out_policy).write_text(json.dumps(policy, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
rows = [
    ('check', 'value'),
    ('accepted_boundary_step', '189'),
    ('accepted_boundary_policy_sha256', p189_sha),
    ('accepted_boundary_record_sha256', r189_sha),
    ('accepted_inventory_record_sha256', inventory_sha),
    ('inventory_family_count', '5'),
    ('inventory_scenario_count', '20'),
    ('closed_family', 'execution-control-failure-paths'),
    ('closed_family_reopened', 'no'),
    ('selected_family', 'kernel-package-edge'),
    ('selected_family_scenario_count', '1'),
    ('selected_scenario', scenario),
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
    ('reboot_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('future_work_requires_explicit_authorization', 'yes'),
    ('slackware_current_publication_invalidates_selection', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-kernel-package-edge-contract-freeze'),
]
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

cat -- "$record"
