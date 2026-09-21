#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-roadmap-state-reconciliation-execution.sh [--help]

Read-only verifier for the Phase 1 roadmap-state reconciliation execution.
It validates the accepted step-172 contract and the reconciled README state.
It grants no repository-refresh, network, machine, package, boot, source-code,
configuration, runtime-test, or Phase 2 authority.
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
contract_policy="$acceptance_dir/phase-1-roadmap-state-reconciliation-contract-freeze-policy.json"
contract_record="$acceptance_dir/phase-1-roadmap-state-reconciliation-contract-freeze.tsv"
readme="$repo_root/README.md"
record="$acceptance_dir/phase-1-roadmap-state-reconciliation-execution.tsv"

check_hash() {
    local file=$1 expected=$2 actual
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file is missing or unsafe: %s\n' "$file" >&2; exit 3; }
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] || { printf 'ERROR: SHA-256 mismatch for %s\nexpected: %s\nactual:   %s\n' "$file" "$expected" "$actual" >&2; exit 4; }
}

check_hash "$contract_policy" '0b9bfc71f9677fbadf76c94394b5517c6c9ecfc4cfdc8ec535703ac2147913bc'
check_hash "$contract_record" 'c4419ace9ac4dabbe0c31beaba24ca0469fc2f7463bdbf49d7e68e4778748b43'
[[ -f $readme && ! -L $readme ]] || { printf 'ERROR: README.md is missing or unsafe\n' >&2; exit 5; }
python3 - "$contract_policy" "$contract_record" "$readme" <<'PYCHECK'
import csv, json, sys
from pathlib import Path
policy=json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
with Path(sys.argv[2]).open(encoding='utf-8',newline='') as h:
    record={k:v for k,v in csv.reader(h,delimiter='\t')}
text=Path(sys.argv[3]).read_text(encoding='utf-8')
assert policy['scenario']=='phase-1-roadmap-state-reconciliation-contract-freeze'
assert policy['contract']['state']=='frozen' and policy['contract']['target_paths']==['README.md']
assert policy['authorization']['documentation_execution_authorized_for_next_stage'] is True
assert record['next_stage']=='phase-1-roadmap-state-reconciliation-execution'
assert '## Accepted Slackware-current rollback closure' in text
assert '## Accepted Slackware 15.0 ELILO cleanup closure' in text
assert '## Current optional rollback continuation' not in text
assert '## Slackware 15.0 ELILO cleanup continuation' not in text
assert '**Current Phase 1 gate:**' in text
assert 'remaining real-system acceptance work is still pending' in text
assert '`reference-v1` remains blocked' in text
assert 'the C port remains blocked by the Phase 1 gate' in text
assert 'preserved below as historical execution evidence' in text
PYCHECK
[[ -f $record && ! -L $record ]] || { printf 'ERROR: step-173 execution record is missing or unsafe\n' >&2; exit 6; }
cat -- "$record"
