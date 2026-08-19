#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-remediation-decision-freeze.sh [--help]

Freeze the accepted remediation decision for the single optional-module mode
conformance gap without modifying source, configuration, packages, boot state,
repositories, or machines.
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
template_file="$repo_root/data/config/slack-update.conf"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
step123_review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-review.tsv"
step123_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-review-policy.json"
step124_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-conformance-discrepancy-classification-policy.json"
decision="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-remediation-decision.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-remediation-decision-freeze-policy.json"

expected_source_sha256=0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6
expected_template_sha256=4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba
expected_contract_sha256=f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9
expected_step123_review_sha256=8d642b84b9e23c7c88a5af259ec4ff75bc68d57e60f7b87d1baaa7664f40e9e1
expected_step123_policy_sha256=823fee83b57d701f3e4fe6021d778f1217ad58c82dc4356c405b6ebb04420753
expected_step124_policy_sha256=a5c75793771c60b1717614ceea1e8832f29eb4b25f94865204cd3c8208b37258

require_regular_file() {
    local path=$1 label=$2
    if [[ ! -f "$path" || -L "$path" ]]; then
        printf 'error: %s is not a regular non-symlink file: %s\n' "$label" "$path" >&2
        exit 1
    fi
}
require_sha256() {
    local path=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    if [[ "$actual" != "$expected" ]]; then
        printf 'error: %s SHA-256 mismatch: expected %s, got %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    fi
}

require_regular_file "$source_file" "reference implementation"
require_regular_file "$template_file" "configuration template"
require_regular_file "$contract" "step-122 frozen mode contract"
require_regular_file "$step123_review" "step-123 conformance review"
require_regular_file "$step123_policy" "step-123 conformance policy"
require_regular_file "$step124_policy" "step-124 classification policy"
require_regular_file "$decision" "step-125 frozen remediation decision"
require_regular_file "$policy" "step-125 decision-freeze policy"
require_sha256 "$source_file" "$expected_source_sha256" "reference implementation"
require_sha256 "$template_file" "$expected_template_sha256" "configuration template"
require_sha256 "$contract" "$expected_contract_sha256" "step-122 frozen mode contract"
require_sha256 "$step123_review" "$expected_step123_review_sha256" "step-123 conformance review"
require_sha256 "$step123_policy" "$expected_step123_policy_sha256" "step-123 conformance policy"
require_sha256 "$step124_policy" "$expected_step124_policy_sha256" "step-124 classification policy"

python3 - "$contract" "$step123_review" "$step123_policy" "$step124_policy" "$decision" "$policy" <<'PY'
import csv
import json
import sys

contract_path, review_path, step123_path, step124_path, decision_path, policy_path = sys.argv[1:]
with open(contract_path, encoding="utf-8", newline="") as handle:
    contract = list(csv.DictReader(handle, delimiter="\t"))
with open(review_path, encoding="utf-8", newline="") as handle:
    review = list(csv.DictReader(handle, delimiter="\t"))
with open(step123_path, encoding="utf-8") as handle:
    step123 = json.load(handle)
with open(step124_path, encoding="utf-8") as handle:
    step124 = json.load(handle)
with open(decision_path, encoding="utf-8", newline="") as handle:
    decision = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(contract) == 15
assert len(review) == 15
assert step123["scenario"] == "phase-1-configuration-module-mode-conformance-review"
assert step123["conforming_rows"] == 14
assert step123["discrepancy_rows"] == 1
assert step124["scenario"] == "phase-1-configuration-module-mode-conformance-discrepancy-classification"
d = step124["discrepancy"]
assert d["id"] == "boot-auto-partial-path-availability"
assert d["module"] == "boot"
assert d["mode"] == "auto"
assert d["classification"] == "implementation-conformance-gap"
assert d["safety_domain"] == "boot-preparation"
assert d["resolution_direction"] == "preserve-contract-tighten-source"
assert d["contract_change_recommended"] is False
assert d["source_change_recommended"] is True
assert step124["source_change_authorized"] is False
assert step124["contract_change_authorized"] is False

assert len(decision) == 1
row = decision[0]
assert row == {
    "discrepancy_id": "boot-auto-partial-path-availability",
    "module": "boot",
    "mode": "auto",
    "classification": "implementation-conformance-gap",
    "safety_domain": "boot-preparation",
    "resolution_direction": "preserve-contract-tighten-source",
    "contract_preservation": "required",
    "source_remediation_required": "true",
    "future_source_scope": "boot-auto-partial-applicability-only",
    "target_behavior": "auto-not-runnable-unless-validated-supported-preparation-path",
    "source_change_authorized": "false",
    "contract_change_authorized": "false",
}

assert policy["schema"] == 1
assert policy["scenario"] == "phase-1-configuration-module-mode-remediation-decision-freeze"
frozen = policy["frozen_decision"]
assert frozen["discrepancy_id"] == row["discrepancy_id"]
assert frozen["module"] == row["module"]
assert frozen["mode"] == row["mode"]
assert frozen["classification"] == row["classification"]
assert frozen["safety_domain"] == row["safety_domain"]
assert frozen["resolution_direction"] == row["resolution_direction"]
assert frozen["contract_preservation"] == "required"
assert frozen["source_remediation_required"] is True
assert frozen["future_source_scope"] == row["future_source_scope"]
assert frozen["target_behavior"] == row["target_behavior"]
assert policy["decision_frozen"] is True
assert policy["runtime_behavior_change"] is False
assert policy["configuration_template_change"] is False
assert policy["source_change_authorized"] is False
assert policy["contract_change_authorized"] is False
assert policy["machine_action_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["pause_safe"] is True
assert policy["next_stage"] == "phase-1-configuration-module-mode-source-remediation-design"
PY

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-remediation-decision-freeze\n'
printf 'discrepancy_id\tboot-auto-partial-path-availability\n'
printf 'discrepancy_module\tboot\n'
printf 'discrepancy_mode\tauto\n'
printf 'discrepancy_classification\timplementation-conformance-gap\n'
printf 'safety_domain\tboot-preparation\n'
printf 'resolution_direction\tpreserve-contract-tighten-source\n'
printf 'contract_preservation\trequired\n'
printf 'source_remediation_required\ttrue\n'
printf 'future_source_scope\tboot-auto-partial-applicability-only\n'
printf 'target_behavior\tauto-not-runnable-unless-validated-supported-preparation-path\n'
printf 'decision_frozen\ttrue\n'
printf 'runtime_behavior_change\tfalse\n'
printf 'configuration_template_change\tfalse\n'
printf 'source_change_authorized\tfalse\n'
printf 'contract_change_authorized\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'next_stage\tphase-1-configuration-module-mode-source-remediation-design\n'
printf 'pause_safe\ttrue\n'
