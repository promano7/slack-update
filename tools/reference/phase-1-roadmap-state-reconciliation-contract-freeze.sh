#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-roadmap-state-reconciliation-contract-freeze.sh [--help]

Read-only Phase 1 contract freeze for roadmap-state reconciliation. The frozen
contract limits the later execution stage to documentation-only reconciliation
of README.md and grants no runtime, repository-refresh, network, package, boot,
source-code, configuration, or Phase 2 authority.
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
selection_policy="$acceptance_dir/phase-1-post-comment-language-next-workstream-selection-freeze-policy.json"
selection_record="$acceptance_dir/phase-1-post-comment-language-next-workstream-selection-freeze.tsv"
record="$acceptance_dir/phase-1-roadmap-state-reconciliation-contract-freeze.tsv"

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

check_hash "$selection_policy" '2992453f2d5e03f34241a3fcc8be3ee48da57630ccceb9aef2f1b560ab76547a'
check_hash "$selection_record" '88734d47d6b85c2dc8e05f527ac0613bc01aad9254ffac1fc75ad98508ca5e0d'

python3 - "$selection_policy" "$selection_record" <<'PYCHECK'
import csv
import json
import sys
from pathlib import Path

policy = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
with Path(sys.argv[2]).open(encoding='utf-8', newline='') as handle:
    values = {key: value for key, value in csv.reader(handle, delimiter='\t')}
assert policy['schema'] == 1
assert policy['scenario'] == 'phase-1-post-comment-language-next-workstream-selection-freeze'
assert policy['selection']['selected_workstream'] == 'roadmap-state-reconciliation'
assert policy['selection']['scope'] == 'repository-only'
assert policy['selection']['selection_frozen'] is True
assert policy['selection']['acceptance_matrix_requires_later_explicit_boundary'] is True
assert policy['authorization']['machine_execution_authorized'] is False
assert policy['authorization']['phase_2_start_authorized'] is False
assert policy['next_stage'] == 'phase-1-roadmap-state-reconciliation-contract-freeze'
assert values['selected_workstream'] == 'roadmap-state-reconciliation'
assert values['selection_state'] == 'selected'
assert values['next_stage'] == 'phase-1-roadmap-state-reconciliation-contract-freeze'
PYCHECK

[[ -f $record && ! -L $record ]] || {
    printf 'ERROR: step-172 contract record is missing or unsafe\n' >&2
    exit 5
}
cat -- "$record"
