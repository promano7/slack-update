#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-authorization-review.sh [--help]

Validate and report the repository-only authorization review for the source
remediation designed in step 126. This command grants only the frozen future
source-edit boundary; it does not modify source, configuration, packages, boot
state, repositories, or machines.
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
step125_decision="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-remediation-decision.tsv"
step125_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-remediation-decision-freeze-policy.json"
step126_design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-design.tsv"
step126_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-design-policy.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-authorization.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-authorization-review-policy.json"

expected_source_sha256=0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6
expected_template_sha256=4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba
expected_contract_sha256=f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9
expected_step125_decision_sha256=9ed9ebe81da18b837a86d4bcc6d5c537aef3061378e0f9b1e7400cedfe422d83
expected_step125_policy_sha256=f5243cf0e14af0e2b94b06dbf904a53a122f1b59df807c9ed90bdccc2366ab5d
expected_step126_design_sha256=36dcb8e9d4f91e166c00043f6f8930ecf6c985b49413fa44d4762dce4f81df45
expected_step126_policy_sha256=982fffd2d145d9c88b89d2b5f929f19f698ffba4b81e15597a00d33637002e58
expected_authorization_sha256=8b2443f3b5f1de52a68cd4f8e4286ed88e071ac50ea99ee36c13905c251bfc08

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

require_source_literal() {
    local literal=$1
    if ! grep -Fq -- "$literal" "$source_file"; then
        printf 'error: required authorization landmark is missing from accepted source: %s\n' "$literal" >&2
        exit 1
    fi
}

require_regular_file "$source_file" "reference implementation"
require_regular_file "$template_file" "configuration template"
require_regular_file "$contract" "step-122 frozen mode contract"
require_regular_file "$step125_decision" "step-125 frozen remediation decision"
require_regular_file "$step125_policy" "step-125 decision-freeze policy"
require_regular_file "$step126_design" "step-126 remediation design"
require_regular_file "$step126_policy" "step-126 remediation-design policy"
require_regular_file "$authorization" "step-127 source authorization"
require_regular_file "$policy" "step-127 authorization-review policy"

require_sha256 "$source_file" "$expected_source_sha256" "reference implementation"
require_sha256 "$template_file" "$expected_template_sha256" "configuration template"
require_sha256 "$contract" "$expected_contract_sha256" "step-122 frozen mode contract"
require_sha256 "$step125_decision" "$expected_step125_decision_sha256" "step-125 frozen remediation decision"
require_sha256 "$step125_policy" "$expected_step125_policy_sha256" "step-125 decision-freeze policy"
require_sha256 "$step126_design" "$expected_step126_design_sha256" "step-126 remediation design"
require_sha256 "$step126_policy" "$expected_step126_policy_sha256" "step-126 remediation-design policy"
require_sha256 "$authorization" "$expected_authorization_sha256" "step-127 source authorization"

require_source_literal 'probe_boot_module() {'
require_source_literal 'mkinitrd-managed|direct-generic-no-initrd)'
require_source_literal 'BOOT_PREPARATION_LAYOUT=direct-generic-no-initrd'
require_source_literal 'elif [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] || [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then'
require_source_literal 'BOOT_PREPARATION_LAYOUT=partial'
require_source_literal 'auto mode detected a partial boot preparation path'
require_source_literal 'BOOT_MODULE_REASON="no supported initrd or GRUB preparation path was detected"'

python3 - "$contract" "$step125_decision" "$step125_policy" "$step126_design" "$step126_policy" "$authorization" "$policy" <<'PY'
import csv
import json
import sys

(
    contract_path,
    decision_path,
    step125_path,
    design_path,
    step126_path,
    authorization_path,
    policy_path,
) = sys.argv[1:]

with open(contract_path, encoding="utf-8", newline="") as handle:
    contract = list(csv.DictReader(handle, delimiter="\t"))
with open(decision_path, encoding="utf-8", newline="") as handle:
    decision = list(csv.DictReader(handle, delimiter="\t"))
with open(step125_path, encoding="utf-8") as handle:
    step125 = json.load(handle)
with open(design_path, encoding="utf-8", newline="") as handle:
    design = list(csv.DictReader(handle, delimiter="\t"))
with open(step126_path, encoding="utf-8") as handle:
    step126 = json.load(handle)
with open(authorization_path, encoding="utf-8", newline="") as handle:
    authorization = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(contract) == 15
boot_auto = next(row for row in contract if row["module"] == "boot" and row["mode"] == "auto")
assert boot_auto["applicability_policy"] == "validated-supported-preparation-path-only"

assert len(decision) == 1
assert decision[0]["discrepancy_id"] == "boot-auto-partial-path-availability"
assert decision[0]["future_source_scope"] == "boot-auto-partial-applicability-only"
assert decision[0]["source_change_authorized"] == "false"
assert step125["scenario"] == "phase-1-configuration-module-mode-remediation-decision-freeze"
assert step125["source_change_authorized"] is False
assert step125["contract_change_authorized"] is False

assert len(design) == 1
design_row = design[0]
assert design_row["function"] == "probe_boot_module"
assert design_row["mode"] == "auto"
assert design_row["edit_strategy"] == "remove-auto-partial-availability-branch"
assert design_row["source_change_authorized"] == "false"
assert step126["scenario"] == "phase-1-configuration-module-mode-source-remediation-design"
assert step126["design_only"] is True
assert step126["source_change_authorized"] is False
assert step126["contract_change_authorized"] is False
assert step126["next_stage"] == "phase-1-configuration-module-mode-source-remediation-authorization-review"

assert len(authorization) == 1
row = authorization[0]
assert row == {
    "discrepancy_id": "boot-auto-partial-path-availability",
    "function": "probe_boot_module",
    "mode": "auto",
    "authorization_scope": "boot-auto-partial-applicability-only",
    "authorized_edit": "remove-auto-partial-availability-branch",
    "source_change_authorized": "true",
    "contract_change_authorized": "false",
    "template_change_authorized": "false",
    "capability_probe_change_authorized": "false",
    "enabled_semantics_change_authorized": "false",
    "disabled_semantics_change_authorized": "false",
}

assert policy["schema"] == 1
assert policy["scenario"] == "phase-1-configuration-module-mode-source-remediation-authorization-review"
assert policy["authorization_review_only"] is True
assert policy["accepted_step126_scenario"] == step126["scenario"]
assert policy["source_sha256"] == policy["authorized_source_change"]["required_pre_edit_source_sha256"]
authorized = policy["authorized_source_change"]
assert authorized["discrepancy_id"] == row["discrepancy_id"]
assert authorized["function"] == row["function"]
assert authorized["mode"] == row["mode"]
assert authorized["scope"] == row["authorization_scope"]
assert authorized["authorized_edit"] == row["authorized_edit"]
assert authorized["reuse_existing_fallback"] is True

preserved = policy["preserved_boundaries"]
assert all(preserved.values())
constraints = policy["authorization_constraints"]
assert all(constraints.values())
assert policy["runtime_behavior_change"] is False
assert policy["source_change_applied"] is False
assert policy["source_change_authorized"] is True
assert policy["contract_change_authorized"] is False
assert policy["configuration_template_change_authorized"] is False
assert policy["machine_action_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["next_stage"] == "phase-1-configuration-module-mode-source-remediation-implementation"
assert policy["pause_safe"] is True
assert policy["supported_targets"] == ["slackware-15.0", "slackware-current"]
PY

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-source-remediation-authorization-review\n'
printf 'discrepancy_id\tboot-auto-partial-path-availability\n'
printf 'target_function\tprobe_boot_module\n'
printf 'authorized_mode\tauto\n'
printf 'authorization_scope\tboot-auto-partial-applicability-only\n'
printf 'authorized_edit\tremove-auto-partial-availability-branch\n'
printf 'pre_edit_source_sha256\t%s\n' "$expected_source_sha256"
printf 'source_change_applied\tfalse\n'
printf 'source_change_authorized\ttrue\n'
printf 'contract_change_authorized\tfalse\n'
printf 'configuration_template_change_authorized\tfalse\n'
printf 'capability_probe_change_authorized\tfalse\n'
printf 'enabled_semantics_change_authorized\tfalse\n'
printf 'disabled_semantics_change_authorized\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'next_stage\tphase-1-configuration-module-mode-source-remediation-implementation\n'
printf 'pause_safe\ttrue\n'
