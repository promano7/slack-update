#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-remaining-work-inventory.sh [--help]

Read-only Phase 1 remaining-work inventory. The helper verifies the accepted
step-162 resume-planning boundary and emits the frozen step-163 inventory.
It does not authorize source changes, repository or network refreshes, machine
execution, package actions, boot actions, or Phase 2/C implementation work.
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

check_hash 'tests/fixtures/reference/acceptance/phase-1/phase-1-resume-planning-boundary-review-policy.json' '47210ad2f1ce84946452c862be172a7e3b803c29772ecf8aae1e693dce4e3ae9'
check_hash 'tests/fixtures/reference/acceptance/phase-1/phase-1-resume-planning-boundary-review.tsv' '338ca5c43dd79a02b7362c2a4cd661b4333139351902689c7af4d479a4bdf521'

record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-remaining-work-inventory.tsv"
if [[ ! -f $record || -L $record ]]; then
    printf 'ERROR: remaining-work inventory is missing or unsafe\n' >&2
    exit 5
fi
cat -- "$record"
