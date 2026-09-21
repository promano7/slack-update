#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-reference-comment-language-audit-contract-freeze.sh [--help]

Read-only Phase 1 comment-language audit contract freeze. The helper verifies
that the accepted step-164 selection remains exact, checks that the reference
shell target exists as a regular file, and emits the frozen step-165 contract.
It does not inspect language conformance, edit source, refresh repositories,
access the network, execute Slackware machines, or authorize Phase 2 work.
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

check_hash 'tests/fixtures/reference/acceptance/phase-1/phase-1-next-workstream-selection-freeze-policy.json' 'd2dfa3d4e1fe716d841a416a15f2c162573bca029b7f5742c543d5d071373c11'
check_hash 'tests/fixtures/reference/acceptance/phase-1/phase-1-next-workstream-selection-freeze.tsv' '9a00e18b56d4ce0a98b3c90db94fb1528e73e0501a6bc493769841cbacbcb79d'

target="$repo_root/tools/reference/slack-update-reference.sh"
if [[ ! -f $target || -L $target ]]; then
    printf 'ERROR: reference shell target is missing or unsafe: tools/reference/slack-update-reference.sh\n' >&2
    exit 5
fi

record="$repo_root/tests/fixtures/reference/acceptance/phase-1/phase-1-reference-comment-language-audit-contract-freeze.tsv"
if [[ ! -f $record || -L $record ]]; then
    printf 'ERROR: audit contract record is missing or unsafe\n' >&2
    exit 6
fi
cat -- "$record"
