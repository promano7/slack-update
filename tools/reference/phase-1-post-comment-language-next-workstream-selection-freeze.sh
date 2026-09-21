#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-post-comment-language-next-workstream-selection-freeze.sh [--help]

Read-only Phase 1 workstream-selection freeze after the accepted step-170 fresh
planning boundary. The helper selects roadmap-state-reconciliation as the next
repository-only workstream and grants no source, network, repository, machine,
package, boot, or Phase 2 authority.
USAGE
}

if (($#)); then
    if [[ $# -eq 1 && $1 == --help ]]; then
        usage
        exit 0
    fi
    printf 'ERROR: unknown option: %s\n' "$1" >&2
    exit 2
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
boundary_policy="$acceptance_dir/phase-1-post-comment-language-resume-planning-boundary-review-policy.json"
boundary_record="$acceptance_dir/phase-1-post-comment-language-resume-planning-boundary-review.tsv"
record="$acceptance_dir/phase-1-post-comment-language-next-workstream-selection-freeze.tsv"

check_hash() {
    local file=$1 expected=$2 actual
    [[ -f $file && ! -L $file ]] || {
        printf 'ERROR: required regular file is missing or unsafe: %s\n' "$file" >&2
        exit 3
    }
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: SHA-256 mismatch for %s\nexpected: %s\nactual:   %s\n' "$file" "$expected" "$actual" >&2
        exit 4
    }
}

check_hash "$boundary_policy" 'b5fb9bc7dc95a27a7d2c119eceb5142a8d7c851044b78d2484ae165f346cf7b8'
check_hash "$boundary_record" '0063d67c00a3d441fd32d225b70b4da210c9b9fd301a5928dbf20116668fca05'

python3 - "$boundary_policy" "$boundary_record" <<'PY'
import csv
import json
import sys
from pathlib import Path

policy_path = Path(sys.argv[1])
record_path = Path(sys.argv[2])
policy = json.loads(policy_path.read_text(encoding='utf-8'))
with record_path.open(encoding='utf-8', newline='') as handle:
    rows = list(csv.reader(handle, delimiter='\t'))
values = {key: value for key, value in rows}

assert policy['schema'] == 1
assert policy['scenario'] == 'phase-1-post-comment-language-resume-planning-boundary-review'
assert policy['review_only'] is True
assert policy['accepted_checkpoint']['step'] == 169
assert policy['accepted_checkpoint']['comment_language_workstream_closed'] is True
assert policy['fresh_boundary']['opened'] is True
assert policy['fresh_boundary']['scope'] == 'phase-1-resume-planning-after-comment-language-closure'
assert policy['remaining_phase_1_work']['roadmap_reconciliation'] == 'pending-repository-only-nonblocking'
assert policy['remaining_phase_1_work']['acceptance_matrix_remainder'] == 'pending-future-machine-work'
assert policy['remaining_phase_1_work']['reference_freeze'] == 'blocked-behind-remaining-acceptance-work'
assert policy['remaining_phase_1_work']['c_port'] == 'blocked-by-phase-1-gate'
for key in (
    'source_change_authorized',
    'repository_refresh_authorized',
    'network_refresh_authorized',
    'machine_execution_authorized',
    'package_action_authorized',
    'boot_action_authorized',
    'phase_2_start_authorized',
):
    assert policy['authorization'][key] is False
assert policy['authorization']['future_work_requires_explicit_authorization'] is True
assert policy['machine_action_required'] is False
assert policy['next_stage'] == 'phase-1-post-comment-language-next-workstream-selection-freeze'
assert policy['pause_safe'] is False
assert values['accepted_checkpoint_step'] == '169'
assert values['roadmap_reconciliation_status'] == 'pending-repository-only-nonblocking'
assert values['acceptance_matrix_remainder_status'] == 'pending-future-machine-work'
assert values['machine_execution_authorized'] == 'false'
assert values['next_stage'] == 'phase-1-post-comment-language-next-workstream-selection-freeze'
PY

[[ -f $record && ! -L $record ]] || {
    printf 'ERROR: step-171 selection record is missing or unsafe\n' >&2
    exit 5
}
cat -- "$record"
