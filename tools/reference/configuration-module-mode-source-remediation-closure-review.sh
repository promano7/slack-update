#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-closure-review.sh [--help]

Read-only Phase 1 source-remediation closure review. The helper verifies the
accepted repository conformance review, the direct-generic initialization
regression review, and the completed two-target runtime-validation closure,
then emits the frozen source-remediation closure record.
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

check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-regression-review-policy.json' 'f97b4e392a7fdacd7bc6585c7b790231614041a163f733cac171a21bf3259ff2'
check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-regression-review.tsv' '95343b045a16a9fe943b46e1e7887173c9b7f1bb2c18ddcc8e2de867afc94ee8'
check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review-policy.json' '43c7b538d06e142180aa343bc743ab11c341e71a4ace6ea0909efac1be90f4ac'
check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.tsv' '18de033bdde24bf7c1072314cded46e134cee06aac8434f47f3318e97995d30d'
check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-closure-review-policy.json' '50e965ffe36d267b3467d3fde08e64dbbedbf17be3f17c41111d226b07575c4b'
check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-closure-review.tsv' '11b5d6e9c0c802a244d481b485c9513f4240f390d82dacc96973d7590507cda0'
check_hash 'tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv' 'f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9'
check_hash 'tools/reference/slack-update-reference.sh' 'aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7'
check_hash 'data/config/slack-update.conf' '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'

record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-closure-review.tsv"
if [[ ! -f $record || -L $record ]]; then
    printf 'ERROR: closure record is missing or unsafe\n' >&2
    exit 5
fi
cat -- "$record"
