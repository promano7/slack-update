#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design.sh [--help]

Validate and report the repository-only step-135 design for the direct-generic
GENERIC_KERNEL_LINK initialization remediation. This command performs no source,
configuration, package, boot, repository, or machine mutation.
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
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design-policy.json"

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

require_regular_file "$source_file" "accepted reference implementation"
require_regular_file "$template" "frozen configuration template"
require_regular_file "$step134_review" "step-134 failure-review record"
require_regular_file "$step134_policy" "step-134 failure-review policy"
require_regular_file "$design" "step-135 remediation design"
require_regular_file "$policy" "step-135 remediation-design policy"
require_sha256 "$source_file" c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "accepted reference implementation"
require_sha256 "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "frozen configuration template"
require_sha256 "$step134_review" 18380df076d7a264053ffb5aa3bcf85a73cf142feb9adf8adeb64b82b16a3939 "step-134 failure-review record"
require_sha256 "$step134_policy" 7fd3da927af6223b97f7669defe32530af1aae9028af57da1fb1b4b39464e8c4 "step-134 failure-review policy"

python3 - "$source_file" "$step134_review" "$step134_policy" "$design" "$policy" <<'PY'
import csv
import json
import re
import sys

source_path, review_path, step134_path, design_path, policy_path = sys.argv[1:]
with open(source_path, encoding="utf-8") as handle:
    source = handle.read()
with open(review_path, encoding="utf-8", newline="") as handle:
    review_rows = list(csv.DictReader(handle, delimiter="\t"))
with open(step134_path, encoding="utf-8") as handle:
    step134 = json.load(handle)
with open(design_path, encoding="utf-8", newline="") as handle:
    design_rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(review_rows) == 1
review = review_rows[0]
assert review["failure_class"] == "source-runtime-initialization-defect"
assert review["failure_variable"] == "GENERIC_KERNEL_LINK"
assert review["execution_attempt_consumed"] == "true"
assert review["rerun_authorized"] == "false"
assert review["slackware_15_released"] == "false"
assert step134["failure"]["function"] == "probe_direct_generic_boot_layout"
assert step134["failure"]["variable"] == "GENERIC_KERNEL_LINK"
assert step134["execution"]["attempt_consumed"] is True
assert step134["execution"]["rerun_under_step132_authorization_permitted"] is False
assert step134["source_change_authorized"] is False
assert step134["machine_execution_authorized"] is False

assignment = "GENERIC_KERNEL_LINK=/boot/vmlinuz-generic"
anchor = "GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot"
assert source.count(assignment) == 1
assert source.count(anchor) == 1
classifier = re.search(r"classify_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", source, re.S)
probe = re.search(r"probe_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", source, re.S)
assert classifier is not None and probe is not None
assert assignment in classifier.group("body")
assert "local generic_link=$4" in classifier.group("body")
assert '"$GENERIC_KERNEL_LINK"' in probe.group("body")
assert "classify_direct_generic_boot_layout" in probe.group("body")
assert source.index(anchor) < source.index("classify_direct_generic_boot_layout() {")
assert source.index("classify_direct_generic_boot_layout() {") < source.index("probe_direct_generic_boot_layout() {")

assert len(design_rows) == 1
row = design_rows[0]
assert row == {
    "design_id": "direct-generic-initialization-remediation",
    "failure_id": "current-runtime-unbound-generic-kernel-link",
    "function": "probe_direct_generic_boot_layout",
    "variable": "GENERIC_KERNEL_LINK",
    "current_assignment_scope": "classify_direct_generic_boot_layout",
    "planned_assignment_scope": "global-boot-path-initialization-boundary",
    "edit_strategy": "relocate-existing-assignment-before-first-use",
    "value_change": "false",
    "function_signature_change": "false",
    "boot_semantics_change": "false",
    "configuration_template_change": "false",
    "contract_change": "false",
    "source_change_authorized": "false",
    "machine_execution_authorized": "false",
    "status": "design-frozen",
}
assert policy["schema"] == 1
assert policy["scenario"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design"
assert policy["design_only"] is True
assert policy["failure_binding"]["failure_variable"] == row["variable"]
assert policy["failure_binding"]["failure_function"] == row["function"]
assert policy["failure_binding"]["execution_attempt_consumed"] is True
remediation = policy["designed_remediation"]
assert remediation["scope"] == "direct-generic-generic-kernel-link-initialization-only"
assert remediation["edit_strategy"] == row["edit_strategy"]
assert remediation["remove_from_function"] == "classify_direct_generic_boot_layout"
assert remediation["insert_after_exact_anchor"] == anchor
assert remediation["assignment"] == assignment
assert remediation["preserve_assignment_count"] == 1
assert remediation["preserve_assignment_value"] is True
assert remediation["preserve_variable_mutability"] is True
assert remediation["add_readonly"] is False
assert remediation["preserve_classifier_signature"] is True
assert remediation["preserve_probe_signature"] is True
assert remediation["preserve_classifier_generic_link_argument"] is True
assert remediation["preserve_boot_layout_semantics"] is True
assert remediation["preserve_optional_module_contract"] is True
assert remediation["preserve_configuration_template"] is True
regression = policy["planned_regression_boundary"]
assert all(regression.values())
assert policy["source_change_authorized"] is False
assert policy["configuration_template_change_authorized"] is False
assert policy["contract_change_authorized"] is False
assert policy["machine_execution_authorized"] is False
assert policy["slackware_current_rerun_authorized"] is False
assert policy["slackware_15_execution_released"] is False
assert policy["slackware_15_execution_authorized"] is False
assert policy["repository_refresh_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["machine_action_required"] is False
assert policy["next_stage"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review"
assert policy["pause_safe"] is True
PY

printf '%s\n' \
    $'schema\t1' \
    $'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design' \
    $'accepted_source_sha256\tc5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c' \
    $'failure_variable\tGENERIC_KERNEL_LINK' \
    $'failure_function\tprobe_direct_generic_boot_layout' \
    $'current_assignment_scope\tclassify_direct_generic_boot_layout' \
    $'planned_assignment_scope\tglobal-boot-path-initialization-boundary' \
    $'edit_strategy\trelocate-existing-assignment-before-first-use' \
    $'assignment_value_change\tfalse' \
    $'function_signature_change\tfalse' \
    $'boot_semantics_change\tfalse' \
    $'configuration_template_change\tfalse' \
    $'contract_change\tfalse' \
    $'source_change_authorized\tfalse' \
    $'machine_execution_authorized\tfalse' \
    $'slackware_current_rerun_authorized\tfalse' \
    $'slackware_15_execution_released\tfalse' \
    $'repository_refresh_required\tfalse' \
    $'slackware_repository_state_dependency\tfalse' \
    $'machine_action_required\tfalse' \
    $'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-authorization-review' \
    $'pause_safe\ttrue'
