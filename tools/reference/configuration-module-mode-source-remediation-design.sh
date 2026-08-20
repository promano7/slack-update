#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-design.sh [--help]

Validate and report the repository-only source remediation design accepted after
step 125. This command does not modify source, configuration, packages, boot
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
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-design.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-design-policy.json"

expected_source_sha256=0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6
expected_template_sha256=4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba
expected_contract_sha256=f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9
expected_step125_decision_sha256=9ed9ebe81da18b837a86d4bcc6d5c537aef3061378e0f9b1e7400cedfe422d83
expected_step125_policy_sha256=f5243cf0e14af0e2b94b06dbf904a53a122f1b59df807c9ed90bdccc2366ab5d
expected_design_sha256=36dcb8e9d4f91e166c00043f6f8930ecf6c985b49413fa44d4762dce4f81df45

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
        printf 'error: required source design landmark is missing: %s\n' "$literal" >&2
        exit 1
    fi
}

require_regular_file "$source_file" "reference implementation"
require_regular_file "$template_file" "configuration template"
require_regular_file "$contract" "step-122 frozen mode contract"
require_regular_file "$step125_decision" "step-125 frozen remediation decision"
require_regular_file "$step125_policy" "step-125 decision-freeze policy"
require_regular_file "$design" "step-126 remediation design"
require_regular_file "$policy" "step-126 remediation-design policy"
require_sha256 "$source_file" "$expected_source_sha256" "reference implementation"
require_sha256 "$template_file" "$expected_template_sha256" "configuration template"
require_sha256 "$contract" "$expected_contract_sha256" "step-122 frozen mode contract"
require_sha256 "$step125_decision" "$expected_step125_decision_sha256" "step-125 frozen remediation decision"
require_sha256 "$step125_policy" "$expected_step125_policy_sha256" "step-125 decision-freeze policy"
require_sha256 "$design" "$expected_design_sha256" "step-126 remediation design"

require_source_literal 'probe_boot_module() {'
require_source_literal 'mkinitrd-managed|direct-generic-no-initrd)'
require_source_literal 'BOOT_PREPARATION_LAYOUT=direct-generic-no-initrd'
require_source_literal 'elif [ "$BOOT_INITRD_AVAILABLE" -eq 1 ] || [ "$BOOT_GRUB_AVAILABLE" -eq 1 ]; then'
require_source_literal 'BOOT_PREPARATION_LAYOUT=partial'
require_source_literal 'auto mode detected a partial boot preparation path'
require_source_literal 'BOOT_MODULE_REASON="no supported initrd or GRUB preparation path was detected"'

python3 - "$contract" "$step125_decision" "$step125_policy" "$design" "$policy" <<'PY'
import csv
import json
import sys

contract_path, decision_path, step125_path, design_path, policy_path = sys.argv[1:]
with open(contract_path, encoding="utf-8", newline="") as handle:
    contract = list(csv.DictReader(handle, delimiter="\t"))
with open(decision_path, encoding="utf-8", newline="") as handle:
    decision = list(csv.DictReader(handle, delimiter="\t"))
with open(step125_path, encoding="utf-8") as handle:
    step125 = json.load(handle)
with open(design_path, encoding="utf-8", newline="") as handle:
    design = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(contract) == 15
boot_auto = next(row for row in contract if row["module"] == "boot" and row["mode"] == "auto")
assert boot_auto["applicability_policy"] == "validated-supported-preparation-path-only"
assert len(decision) == 1
assert decision[0]["discrepancy_id"] == "boot-auto-partial-path-availability"
assert decision[0]["future_source_scope"] == "boot-auto-partial-applicability-only"
assert decision[0]["target_behavior"] == "auto-not-runnable-unless-validated-supported-preparation-path"
assert decision[0]["source_change_authorized"] == "false"
assert step125["scenario"] == "phase-1-configuration-module-mode-remediation-decision-freeze"
assert step125["decision_frozen"] is True
assert step125["source_change_authorized"] is False
assert step125["contract_change_authorized"] is False
assert len(design) == 1
row = design[0]
assert row == {
    "discrepancy_id": "boot-auto-partial-path-availability",
    "function": "probe_boot_module",
    "mode": "auto",
    "edit_strategy": "remove-auto-partial-availability-branch",
    "remove_partial_runnable_branch": "true",
    "preserve_complete_layouts": "true",
    "partial_auto_state": "unavailable",
    "partial_auto_run": "0",
    "contract_change": "false",
    "template_change": "false",
    "source_change_authorized": "false",
}
assert policy["schema"] == 1
assert policy["scenario"] == "phase-1-configuration-module-mode-source-remediation-design"
assert policy["design_only"] is True
remediation = policy["designed_remediation"]
assert remediation["discrepancy_id"] == row["discrepancy_id"]
assert remediation["function"] == row["function"]
assert remediation["mode"] == row["mode"]
assert remediation["scope"] == "boot-auto-partial-applicability-only"
assert remediation["edit_strategy"] == row["edit_strategy"]
assert remediation["preserve_contract"] is True
assert remediation["preserve_capability_probes"] is True
assert remediation["preserve_enabled_semantics"] is True
assert remediation["preserve_disabled_semantics"] is True
assert remediation["preserve_mkinitrd_managed_layout"] is True
assert remediation["preserve_direct_generic_no_initrd_layout"] is True
assert remediation["partial_capability_result"] == "unavailable-non-runnable"
assert remediation["target_behavior"] == "auto-not-runnable-unless-validated-supported-preparation-path"
delta = policy["planned_source_delta"]
assert delta["remove_layout_assignment"] == "BOOT_PREPARATION_LAYOUT=partial"
assert delta["remove_reason_prefix"] == "auto mode detected a partial boot preparation path"
assert delta["reuse_existing_fallback_state"] == "BOOT_MODULE_STATE=unavailable"
regression = policy["post_remediation_regression_boundary"]
assert regression["auto_mkinitrd_managed"] == "available-runnable"
assert regression["auto_direct_generic_no_initrd"] == "available-runnable"
assert regression["auto_partial_initrd_only"] == "unavailable-non-runnable"
assert regression["auto_partial_grub_only_without_valid_direct_generic"] == "unavailable-non-runnable"
assert regression["auto_no_capabilities"] == "unavailable-non-runnable"
assert regression["enabled_partial"] == "unavailable-strict-error"
assert regression["disabled_any_layout"] == "disabled-non-runnable"
assert policy["runtime_behavior_change"] is False
assert policy["configuration_template_change"] is False
assert policy["source_change_authorized"] is False
assert policy["contract_change_authorized"] is False
assert policy["machine_action_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["next_stage"] == "phase-1-configuration-module-mode-source-remediation-authorization-review"
assert policy["pause_safe"] is True
PY

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-source-remediation-design\n'
printf 'source_sha256\t%s\n' "$expected_source_sha256"
printf 'template_sha256\t%s\n' "$expected_template_sha256"
printf 'contract_sha256\t%s\n' "$expected_contract_sha256"
printf 'step125_decision_sha256\t%s\n' "$expected_step125_decision_sha256"
printf 'step125_policy_sha256\t%s\n' "$expected_step125_policy_sha256"
printf 'design_sha256\t%s\n' "$expected_design_sha256"
printf 'supported_targets\tslackware-15.0,slackware-current\n'
printf 'discrepancy_id\tboot-auto-partial-path-availability\n'
printf 'target_function\tprobe_boot_module\n'
printf 'remediation_scope\tboot-auto-partial-applicability-only\n'
printf 'edit_strategy\tremove-auto-partial-availability-branch\n'
printf 'partial_auto_target\tunavailable-non-runnable\n'
printf 'preserve_complete_layouts\ttrue\n'
printf 'preserve_enabled_semantics\ttrue\n'
printf 'preserve_disabled_semantics\ttrue\n'
printf 'runtime_behavior_change\tfalse\n'
printf 'configuration_template_change\tfalse\n'
printf 'source_change_authorized\tfalse\n'
printf 'contract_change_authorized\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'next_stage\tphase-1-configuration-module-mode-source-remediation-authorization-review\n'
printf 'pause_safe\ttrue\n'
