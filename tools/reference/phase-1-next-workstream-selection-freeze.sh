#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-next-workstream-selection-freeze.sh [--help]

Read-only Phase 1 next-workstream selection freeze. The helper verifies the
accepted step-163 remaining-work inventory and emits the frozen step-164
selection record. It authorizes no source change, repository or network
refresh, machine execution, package action, boot action, or Phase 2 work.
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

check_hash() {
    local rel=$1 expected=$2 actual
    if [[ ! -f $repo_root/$rel || -L $repo_root/$rel ]]; then
        printf 'ERROR: required regular file is missing or unsafe: %s\n' "$rel" >&2
        exit 3
    fi
    actual=$(sha256sum -- "$repo_root/$rel" | awk '{print $1}')
    if [[ $actual != "$expected" ]]; then
        printf 'ERROR: SHA-256 mismatch for %s\n' "$rel" >&2
        printf 'expected: %s\nactual:   %s\n' "$expected" "$actual" >&2
        exit 4
    fi
}

check_hash 'tests/fixtures/reference/acceptance/phase-1/phase-1-remaining-work-inventory-policy.json' 'fb9ab7db1adad032b29be14a6100fdc6221eefd8de3360374085e8b3d76e4f03'
check_hash 'tests/fixtures/reference/acceptance/phase-1/phase-1-remaining-work-inventory.tsv' '8a1160121683117fc247cbf35d2943d35b6b219323e8e58a2fb9baed165f8b01'

record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-next-workstream-selection-freeze.tsv"
if [[ ! -f $record || -L $record ]]; then
    printf 'ERROR: next-workstream selection record is missing or unsafe\n' >&2
    exit 5
fi
cat -- "$record"
