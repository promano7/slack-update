#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-roadmap-state-reconciliation-review.sh [--help]

Read-only verifier for the Phase 1 roadmap-state reconciliation review.
It validates the exact accepted step-173 execution and the reconciled README.
It grants no source, documentation, repository-refresh, network, machine,
package, boot, or Phase 2 authority.
USAGE
}

if (($#)); then
    if [[ $# -eq 1 && $1 == --help ]]; then usage; exit 0; fi
    printf 'ERROR: unknown option: %s\n' "$1" >&2
    exit 2
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
step173_policy="$acceptance_dir/phase-1-roadmap-state-reconciliation-execution-policy.json"
step173_record="$acceptance_dir/phase-1-roadmap-state-reconciliation-execution.tsv"
step173_helper="$repo_root/tools/reference/phase-1-roadmap-state-reconciliation-execution.sh"
readme="$repo_root/README.md"
record="$acceptance_dir/phase-1-roadmap-state-reconciliation-review.tsv"

check_hash() {
    local file=$1 expected=$2 actual
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file is missing or unsafe: %s\n' "$file" >&2; exit 3; }
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] || { printf 'ERROR: SHA-256 mismatch for %s\nexpected: %s\nactual:   %s\n' "$file" "$expected" "$actual" >&2; exit 4; }
}

check_hash "$step173_policy" '3e8e87dfc82d8ecde69144bfc0805abb413c85901af5ef97c0e6a05f734cdb9e'
check_hash "$step173_record" '3b876857640b4cc6f7502f3b9a40718fd1ca205de9bd5ce71c4154be248aee94'
check_hash "$step173_helper" '16580a7077164ad351c0e5b9543498c10518f5d17d18da02440591d253776d47'
check_hash "$readme" '6cfc1556fd6ef50089be4f3b5472c268dd01a8330b6262e46b51994712a7cfad'

python3 - "$step173_policy" "$step173_record" "$readme" <<'PYCHECK'
import csv, json, sys
from pathlib import Path
policy = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
with Path(sys.argv[2]).open(encoding='utf-8', newline='') as handle:
    rows = {key: value for key, value in csv.reader(handle, delimiter='\t')}
text = Path(sys.argv[3]).read_text(encoding='utf-8')
assert policy['scenario'] == 'phase-1-roadmap-state-reconciliation-execution'
assert policy['execution']['state'] == 'completed'
assert policy['execution']['target_paths'] == ['README.md']
assert policy['execution']['change_class'] == 'documentation-roadmap-presentation-only'
assert policy['execution']['historical_checklist_preserved'] is True
assert policy['execution']['acceptance_matrix_complete'] is False
assert policy['execution']['acceptance_matrix_checkbox_mass_update_performed'] is False
assert rows['next_stage'] == 'phase-1-roadmap-state-reconciliation-review'
assert rows['machine_action_required'] == 'false'
assert text.count('## Accepted Slackware-current rollback closure') == 1
assert text.count('## Accepted Slackware 15.0 ELILO cleanup closure') == 1
assert '## Current optional rollback continuation' not in text
assert '## Slackware 15.0 ELILO cleanup continuation' not in text
assert '**Current Phase 1 gate:**' in text
assert 'remaining real-system acceptance work is still pending' in text
assert '`reference-v1` remains blocked behind that work' in text
assert 'the C port remains blocked by the Phase 1 gate' in text
assert 'The detailed checklist is preserved below as historical execution evidence.' in text
PYCHECK

[[ -f $record && ! -L $record ]] || { printf 'ERROR: step-174 review record is missing or unsafe\n' >&2; exit 5; }
cat -- "$record"
