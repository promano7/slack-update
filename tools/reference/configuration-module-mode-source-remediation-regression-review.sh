#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-regression-review.sh [--help]

Validate and report the repository-only step-129 regression review state.
This command performs no source, configuration, package, boot, repository,
or machine mutation.
USAGE
}

if (( $# > 1 )); then
    printf 'error: unexpected arguments\n' >&2
    exit 2
fi
if (( $# == 1 )); then
    case "$1" in
        -h|--help) usage; exit 0 ;;
        *) printf 'error: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
step123_review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-review.tsv"
step123_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-review-policy.json"
step128_implementation="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-implementation.tsv"
step128_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-implementation-policy.json"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-regression-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-regression-review-policy.json"

require_regular_file() {
    local path=$1 label=$2
    [[ -f "$path" && ! -L "$path" ]] || {
        printf 'error: %s is not a regular non-symlink file: %s\n' "$label" "$path" >&2
        exit 1
    }
}
require_sha256() {
    local path=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    [[ "$actual" == "$expected" ]] || {
        printf 'error: %s SHA-256 mismatch: expected %s, got %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    }
}

require_regular_file "$source_file" "reference implementation"
require_regular_file "$template" "configuration template"
require_regular_file "$contract" "frozen mode contract"
require_regular_file "$step123_review" "step-123 conformance review"
require_regular_file "$step123_policy" "step-123 conformance policy"
require_regular_file "$step128_implementation" "step-128 implementation record"
require_regular_file "$step128_policy" "step-128 implementation policy"
require_regular_file "$review" "step-129 regression review"
require_regular_file "$policy" "step-129 regression-review policy"

require_sha256 "$source_file" c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "accepted post-remediation source"
require_sha256 "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
require_sha256 "$contract" f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9 "frozen mode contract"
require_sha256 "$step123_review" 8d642b84b9e23c7c88a5af259ec4ff75bc68d57e60f7b87d1baaa7664f40e9e1 "step-123 conformance review"
require_sha256 "$step123_policy" 823fee83b57d701f3e4fe6021d778f1217ad58c82dc4356c405b6ebb04420753 "step-123 conformance policy"
require_sha256 "$step128_implementation" 368ea87d0a71a96f9dc8a6a08a4afcdfe9e10191ed0a3b3a827e98b049333725 "step-128 implementation record"
require_sha256 "$step128_policy" e91c542c7918a0bdbab68fa2650583410416ebe49d5ee481f957af4793dafb18 "step-128 implementation policy"

python3 - "$contract" "$step123_review" "$step128_implementation" "$step128_policy" "$review" "$policy" <<'PY'
import csv
import json
import sys

contract_path, step123_path, implementation_path, step128_policy_path, review_path, policy_path = sys.argv[1:]
with open(contract_path, encoding="utf-8", newline="") as handle:
    contract = list(csv.DictReader(handle, delimiter="\t"))
with open(step123_path, encoding="utf-8", newline="") as handle:
    old = list(csv.DictReader(handle, delimiter="\t"))
with open(implementation_path, encoding="utf-8", newline="") as handle:
    implementation = list(csv.DictReader(handle, delimiter="\t"))
with open(step128_policy_path, encoding="utf-8") as handle:
    step128 = json.load(handle)
with open(review_path, encoding="utf-8", newline="") as handle:
    review = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(contract) == len(old) == len(review) == 15
assert [(r["module"], r["mode"]) for r in contract] == [(r["module"], r["mode"]) for r in review]
assert [(r["module"], r["mode"]) for r in old] == [(r["module"], r["mode"]) for r in review]
old_discrepancies = [r for r in old if r["status"] == "discrepancy"]
assert len(old_discrepancies) == 1
assert old_discrepancies[0]["discrepancy_id"] == "boot-auto-partial-path-availability"
assert all(r["status"] == "conformant" for r in review)
remediated = [r for r in review if r["resolved_discrepancy_id"] != "-"]
assert len(remediated) == 1
assert remediated[0]["module"] == "boot" and remediated[0]["mode"] == "auto"
assert remediated[0]["resolved_discrepancy_id"] == "boot-auto-partial-path-availability"
assert remediated[0]["evidence_basis"] == "step128-behavioral-regression"
assert sum(r["evidence_basis"] == "step123-conformance-plus-step128-exact-delta" for r in review) == 14
assert len(implementation) == 1
assert implementation[0]["post_edit_source_sha256"] == policy["source_sha256"]
assert implementation[0]["source_change_applied"] == "true"
assert implementation[0]["authorization_consumed"] == "true"
assert implementation[0]["further_source_change_authorized"] == "false"
assert step128["post_edit_source_sha256"] == policy["source_sha256"]
assert step128["source_change_applied"] is True
assert step128["authorization_consumed"] is True
assert step128["further_source_change_authorized"] is False
assert policy["contract_rows_reviewed"] == 15
assert policy["inherited_conforming_rows"] == 14
assert policy["remediated_rows_revalidated"] == 1
assert policy["conforming_rows"] == 15
assert policy["discrepancy_rows"] == 0
assert policy["all_rows_conform"] is True
assert policy["resolved_discrepancy_id"] == "boot-auto-partial-path-availability"
assert policy["behavioral_regression_cases"] == 7
assert policy["source_change_applied"] is True
assert policy["authorization_consumed"] is True
assert policy["further_source_change_authorized"] is False
assert policy["runtime_behavior_change_in_step129"] is False
assert policy["machine_action_required"] is False
assert policy["runtime_machine_validation_still_required"] is True
assert policy["pause_safe"] is True
PY

cat <<'EOF'
schema	1
scenario	phase-1-configuration-module-mode-source-remediation-regression-review
contract_rows_reviewed	15
inherited_conforming_rows	14
remediated_rows_revalidated	1
conforming_rows	15
discrepancy_rows	0
all_rows_conform	true
resolved_discrepancy_id	boot-auto-partial-path-availability
behavioral_regression_cases	7
source_sha256	c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c
source_change_applied	true
authorization_consumed	true
further_source_change_authorized	false
contract_change_authorized	false
configuration_template_change_authorized	false
runtime_behavior_change_reviewed	true
runtime_behavior_change_in_step129	false
machine_action_required	false
runtime_machine_validation_still_required	true
slackware_repository_state_dependency	false
next_stage	phase-1-configuration-module-mode-source-remediation-runtime-validation-planning
pause_safe	true
EOF
