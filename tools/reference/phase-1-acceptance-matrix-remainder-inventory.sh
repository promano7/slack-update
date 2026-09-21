#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-acceptance-matrix-remainder-inventory.sh [--help]

Read-only verifier for the Phase 1 acceptance-matrix remainder inventory.
It validates the accepted step-174 roadmap review and the step-163 high-level
remaining-work inventory, then prints the frozen six-family remainder table.
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
step174_policy="$acceptance_dir/phase-1-roadmap-state-reconciliation-review-policy.json"
step174_record="$acceptance_dir/phase-1-roadmap-state-reconciliation-review.tsv"
step163_policy="$acceptance_dir/phase-1-remaining-work-inventory-policy.json"
step163_record="$acceptance_dir/phase-1-remaining-work-inventory.tsv"
record="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory.tsv"
policy="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory-policy.json"

check_hash() {
    local file=$1 expected=$2 actual
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file is missing or unsafe: %s\n' "$file" >&2; exit 3; }
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] || { printf 'ERROR: SHA-256 mismatch for %s\nexpected: %s\nactual:   %s\n' "$file" "$expected" "$actual" >&2; exit 4; }
}

check_hash "$step174_policy" '63da904c6c3b97acba8d648c0f586780ff460885755d5fa31371b055e853e119'
check_hash "$step174_record" 'ab250e343bf2c1968f6a6c27021b50d2aaf598a2fb791b6f0c10ecfbd81a3861'
check_hash "$step163_policy" 'fb9ab7db1adad032b29be14a6100fdc6221eefd8de3360374085e8b3d76e4f03'
check_hash "$step163_record" '8a1160121683117fc247cbf35d2943d35b6b219323e8e58a2fb9baed165f8b01'

python3 - "$step174_policy" "$step163_policy" "$policy" "$record" <<'PYCHECK'
import csv, json, sys
from pathlib import Path
p174 = json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
p163 = json.loads(Path(sys.argv[2]).read_text(encoding='utf-8'))
p = json.loads(Path(sys.argv[3]).read_text(encoding='utf-8'))
with Path(sys.argv[4]).open(encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))
assert p174['scenario'] == 'phase-1-roadmap-state-reconciliation-review'
assert p174['review']['roadmap_reconciliation_closed'] is True
assert p174['review']['acceptance_matrix_complete'] is False
assert p163['scenario'] == 'phase-1-remaining-work-inventory'
assert p163['inventory']['pending_acceptance_work_count'] == 1
assert p163['inventory']['contains_machine_work'] is True
assert p['scenario'] == 'phase-1-acceptance-matrix-remainder-inventory'
assert p['inventory']['family_count'] == 6
assert p['inventory']['scenario_count'] == 24
assert p['inventory']['machine_work_authorized'] is False
assert p['inventory']['candidate_set_bound'] is False
assert len(rows) == 6
assert sum(int(row['scenario_count']) for row in rows) == 24
assert all(row['runtime_boundary_required'] == 'true' for row in rows)
assert all(row['repository_refresh_requirement'] == 'conditional' for row in rows)
assert p['gates']['acceptance_matrix_complete'] is False
assert p['gates']['reference_freeze_status'] == 'blocked-behind-remaining-acceptance-work'
assert p['gates']['c_port_status'] == 'blocked-by-phase-1-gate'
PYCHECK

cat -- "$record"
