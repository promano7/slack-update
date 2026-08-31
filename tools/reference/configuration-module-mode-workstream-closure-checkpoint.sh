#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-workstream-closure-checkpoint.sh [--help]

Read-only Phase 1 optional-module mode workstream closure checkpoint. The
helper verifies the fresh step-121 boundary, the complete step-160 source-
remediation closure, and the frozen accepted repository state before emitting
the workstream closure record.
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

check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-boundary-review-policy.json' 'a03e299a87596ad66246031c3a47839bac5ab2a869073c43eeae6be0788ebc4e'
check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-closure-review-policy.json' '019636bde8167d61ad680680da83500ab3db599b830f16c3b4c7acd6cca42fc9'
check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-closure-review.tsv' '4165eb4c6191eb189666de2a7ebe4d05874de6a6001c5178320e85819335d070'
check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv' 'f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9'
check_hash 'tools/reference/slack-update-reference.sh' 'aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7'
check_hash 'data/config/slack-update.conf' '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'

record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-workstream-closure-checkpoint.tsv"
if [[ ! -f $record || -L $record ]]; then
    printf 'ERROR: workstream closure record is missing or unsafe\n' >&2
    exit 5
fi
cat -- "$record"
