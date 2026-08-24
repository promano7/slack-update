#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review.sh [--help]

Validate and report the repository-only step-136 authorization review for the
direct-generic GENERIC_KERNEL_LINK initialization remediation designed in step
135. This command authorizes only the frozen future source relocation; it does
not modify source, configuration, packages, boot state, repositories, or machines.
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
step134_review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review.tsv"
step134_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review-policy.json"
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design.tsv"
design_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design-policy.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review-policy.json"

expected_source_sha256=c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c
expected_template_sha256=4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba
expected_step134_review_sha256=18380df076d7a264053ffb5aa3bcf85a73cf142feb9adf8adeb64b82b16a3939
expected_step134_policy_sha256=7fd3da927af6223b97f7669defe32530af1aae9028af57da1fb1b4b39464e8c4
expected_design_sha256=92f32e694de60beefea4066a33bd12bdc55ad787e7d24da65ee8fa5f30c62ee2
expected_design_policy_sha256=ea809c4c9e7c1fa46d812d7a778969c9b6b441821a306553e4f6bfff167c2c7b

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

require_regular_file "$source_file" "accepted pre-edit reference implementation"
require_regular_file "$template" "frozen configuration template"
require_regular_file "$step134_review" "step-134 failure-review record"
require_regular_file "$step134_policy" "step-134 failure-review policy"
require_regular_file "$design" "step-135 remediation design"
require_regular_file "$design_policy" "step-135 remediation-design policy"
require_regular_file "$authorization" "step-136 source authorization"
require_regular_file "$policy" "step-136 authorization-review policy"
require_sha256 "$source_file" "$expected_source_sha256" "accepted pre-edit reference implementation"
require_sha256 "$template" "$expected_template_sha256" "frozen configuration template"
require_sha256 "$step134_review" "$expected_step134_review_sha256" "step-134 failure-review record"
require_sha256 "$step134_policy" "$expected_step134_policy_sha256" "step-134 failure-review policy"
require_sha256 "$design" "$expected_design_sha256" "step-135 remediation design"
require_sha256 "$design_policy" "$expected_design_policy_sha256" "step-135 remediation-design policy"

python3 - "$source_file" "$step134_review" "$step134_policy" "$design" "$design_policy" "$authorization" "$policy" <<'PY'
import csv
import json
import re
import sys

source_path, review_path, step134_path, design_path, design_policy_path, authorization_path, policy_path = sys.argv[1:]
with open(source_path, encoding="utf-8") as handle:
    source = handle.read()
with open(review_path, encoding="utf-8", newline="") as handle:
    review_rows = list(csv.DictReader(handle, delimiter="\t"))
with open(step134_path, encoding="utf-8") as handle:
    step134 = json.load(handle)
with open(design_path, encoding="utf-8", newline="") as handle:
    design_rows = list(csv.DictReader(handle, delimiter="\t"))
with open(design_policy_path, encoding="utf-8") as handle:
    design_policy = json.load(handle)
with open(authorization_path, encoding="utf-8", newline="") as handle:
    authorization_rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(review_rows) == 1
review = review_rows[0]
assert review["failure_class"] == "source-runtime-initialization-defect"
assert review["failure_variable"] == "GENERIC_KERNEL_LINK"
assert review["execution_attempt_consumed"] == "true"
assert review["rerun_authorized"] == "false"
assert step134["source_change_authorized"] is False
assert step134["machine_execution_authorized"] is False

assert len(design_rows) == 1
design = design_rows[0]
assert design["design_id"] == "direct-generic-initialization-remediation"
assert design["variable"] == "GENERIC_KERNEL_LINK"
assert design["edit_strategy"] == "relocate-existing-assignment-before-first-use"
assert design["source_change_authorized"] == "false"
assert design["machine_execution_authorized"] == "false"
assert design_policy["scenario"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design"
assert design_policy["source_change_authorized"] is False
assert design_policy["machine_execution_authorized"] is False
assert design_policy["next_stage"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review"

assignment = "GENERIC_KERNEL_LINK=/boot/vmlinuz-generic"
anchor = "GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot"
assert source.count(assignment) == 1
assert source.count(anchor) == 1
classifier = re.search(r"classify_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", source, re.S)
probe = re.search(r"probe_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", source, re.S)
assert classifier is not None and probe is not None
assert assignment in classifier.group("body")
assert '"$GENERIC_KERNEL_LINK"' in probe.group("body")
assert "classify_direct_generic_boot_layout" in probe.group("body")
assert source.index(anchor) < source.index("classify_direct_generic_boot_layout() {")

assert len(authorization_rows) == 1
row = authorization_rows[0]
assert row == {
    "design_id": "direct-generic-initialization-remediation",
    "function": "probe_direct_generic_boot_layout",
    "variable": "GENERIC_KERNEL_LINK",
    "authorization_scope": "direct-generic-generic-kernel-link-initialization-only",
    "authorized_edit": "relocate-existing-assignment-before-first-use",
    "remove_from_function": "classify_direct_generic_boot_layout",
    "insert_after_exact_anchor": "GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot",
    "assignment": "GENERIC_KERNEL_LINK=/boot/vmlinuz-generic",
    "preserve_assignment_count": "true",
    "preserve_assignment_value": "true",
    "preserve_variable_mutability": "true",
    "function_signature_change_authorized": "false",
    "boot_semantics_change_authorized": "false",
    "configuration_template_change_authorized": "false",
    "contract_change_authorized": "false",
    "source_change_authorized": "true",
    "machine_execution_authorized": "false",
}
assert policy["schema"] == 1
assert policy["scenario"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review"
assert policy["authorization_review_only"] is True
assert policy["accepted_step135_scenario"] == design_policy["scenario"]
authorized = policy["authorized_source_change"]
assert authorized["design_id"] == row["design_id"]
assert authorized["scope"] == row["authorization_scope"]
assert authorized["authorized_edit"] == row["authorized_edit"]
assert authorized["required_pre_edit_source_sha256"] == policy["accepted_source_sha256"]
assert authorized["assignment"] == row["assignment"]
assert authorized["remove_from_function"] == row["remove_from_function"]
assert authorized["insert_after_exact_anchor"] == row["insert_after_exact_anchor"]
assert authorized["preserve_assignment_count"] == 1
assert authorized["preserve_assignment_value"] is True
assert authorized["preserve_variable_mutability"] is True
assert authorized["add_readonly_authorized"] is False
assert authorized["classifier_signature_change_authorized"] is False
assert authorized["probe_signature_change_authorized"] is False
assert authorized["classifier_generic_link_argument_change_authorized"] is False
assert authorized["boot_layout_semantics_change_authorized"] is False
assert authorized["other_source_change_authorized"] is False
assert all(policy["authorization_constraints"].values())
assert all(policy["preserved_boundaries"].values())
assert policy["source_change_applied"] is False
assert policy["source_change_authorized"] is True
assert policy["configuration_template_change_authorized"] is False
assert policy["contract_change_authorized"] is False
assert policy["machine_execution_authorized"] is False
assert policy["slackware_current_rerun_authorized"] is False
assert policy["slackware_15_execution_released"] is False
assert policy["slackware_15_execution_authorized"] is False
assert policy["repository_refresh_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["machine_action_required"] is False
assert policy["next_stage"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation"
assert policy["pause_safe"] is True
PY

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review\n'
printf 'accepted_source_sha256\t%s\n' "$expected_source_sha256"
printf 'step135_design_sha256\t%s\n' "$expected_design_sha256"
printf 'step135_design_policy_sha256\t%s\n' "$expected_design_policy_sha256"
printf 'design_id\tdirect-generic-initialization-remediation\n'
printf 'failure_variable\tGENERIC_KERNEL_LINK\n'
printf 'authorization_scope\tdirect-generic-generic-kernel-link-initialization-only\n'
printf 'authorized_edit\trelocate-existing-assignment-before-first-use\n'
printf 'assignment\tGENERIC_KERNEL_LINK=/boot/vmlinuz-generic\n'
printf 'remove_from_function\tclassify_direct_generic_boot_layout\n'
printf 'insert_after_exact_anchor\tGENINITRD_VERSIONED_INITRD_DIRECTORY=/boot\n'
printf 'preserve_assignment_count\t1\n'
printf 'preserve_assignment_value\ttrue\n'
printf 'preserve_variable_mutability\ttrue\n'
printf 'function_signature_change_authorized\tfalse\n'
printf 'boot_semantics_change_authorized\tfalse\n'
printf 'configuration_template_change_authorized\tfalse\n'
printf 'contract_change_authorized\tfalse\n'
printf 'source_change_applied\tfalse\n'
printf 'source_change_authorized\ttrue\n'
printf 'machine_execution_authorized\tfalse\n'
printf 'slackware_current_rerun_authorized\tfalse\n'
printf 'slackware_15_execution_released\tfalse\n'
printf 'repository_refresh_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-implementation\n'
printf 'pause_safe\ttrue\n'
