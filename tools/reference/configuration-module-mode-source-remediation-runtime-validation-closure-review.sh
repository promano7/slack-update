#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-closure-review.sh [--help]

Read-only Phase 1 runtime-validation closure review. The helper verifies the
accepted Slackware 15.0 and Slackware-current review identities together with
the accepted source/template identities, then emits the frozen closure record.
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

check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-review-policy.json' '2ead4c6e4b144b7bc6c3f927eaeea8c46160cc8ebdf1054684046767444bd46a'
check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-review.tsv' 'dbeded2f525a52dd4155c41963d8e154b6a4e90917c994c4b4a993d81a1e0ba4'
check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review-policy.json' 'de2813f328b1af80531d68a22c049f9c3be58b6a445398c5c3795b49036ead4b'
check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review.tsv' '9f8c384d4709e8161ac2f6a3e928b7f3e7baea677e7d850c4c061c1aa4d71361'
check_hash 'tools/reference/slack-update-reference.sh' 'aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7'
check_hash 'data/config/slack-update.conf' '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'

record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-closure-review.tsv"
if [[ ! -f $record || -L $record ]]; then
    printf 'ERROR: closure record is missing or unsafe\n' >&2
    exit 5
fi
cat -- "$record"
