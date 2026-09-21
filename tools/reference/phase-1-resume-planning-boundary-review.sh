#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-resume-planning-boundary-review.sh [--help]

Read-only Phase 1 resume-planning boundary review. The helper verifies the
accepted step-161 strong-safe-pause checkpoint and emits the fresh planning
boundary record. It does not authorize source changes, repository refreshes,
network access, package operations, boot changes, or machine execution.
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

check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-workstream-closure-checkpoint-policy.json' '0b06a01e33b33da1eba3e6e4566c1b1ea929d801b8c5d1357d93b3e55cbc6fb9'
check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-workstream-closure-checkpoint.tsv' '3705921dab84bc1dbb47766743d4623d9b575179b4c449d99a4adf460f5d15e8'

record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-resume-planning-boundary-review.tsv"
if [[ ! -f $record || -L $record ]]; then
    printf 'ERROR: resume-planning boundary record is missing or unsafe\n' >&2
    exit 5
fi
cat -- "$record"
