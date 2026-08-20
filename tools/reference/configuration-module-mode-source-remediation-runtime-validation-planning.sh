#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-planning.sh [--help]

Validate and report the repository-only step-130 runtime-validation plan.
This command performs no source, configuration, package, boot, repository,
network, or machine mutation.
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
step129_review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-regression-review.tsv"
step129_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-regression-review-policy.json"
plan="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-planning.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-planning-policy.json"

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
require_regular_file "$step129_review" "step-129 regression review"
require_regular_file "$step129_policy" "step-129 regression-review policy"
require_regular_file "$plan" "step-130 runtime-validation plan"
require_regular_file "$policy" "step-130 runtime-validation planning policy"

require_sha256 "$source_file" c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "accepted post-remediation source"
require_sha256 "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
require_sha256 "$step129_review" 95343b045a16a9fe943b46e1e7887173c9b7f1bb2c18ddcc8e2de867afc94ee8 "step-129 regression review"
require_sha256 "$step129_policy" f97b4e392a7fdacd7bc6585c7b790231614041a163f733cac171a21bf3259ff2 "step-129 regression-review policy"

python3 - "$step129_review" "$step129_policy" "$plan" "$policy" <<'PY'
import csv
import json
import sys

review_path, step129_policy_path, plan_path, policy_path = sys.argv[1:]
with open(review_path, encoding="utf-8", newline="") as handle:
    review = list(csv.DictReader(handle, delimiter="\t"))
with open(step129_policy_path, encoding="utf-8") as handle:
    step129 = json.load(handle)
with open(plan_path, encoding="utf-8", newline="") as handle:
    plan = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(review) == 15
assert all(row["status"] == "conformant" for row in review)
assert step129["all_rows_conform"] is True
assert step129["discrepancy_rows"] == 0
assert step129["runtime_machine_validation_still_required"] is True
assert step129["further_source_change_authorized"] is False
assert len(plan) == 3
by_id = {row["test_id"]: row for row in plan}
assert set(by_id) == {
    "runtime-slackware-15",
    "runtime-slackware-current",
    "physical-current-fallback",
}
assert by_id["runtime-slackware-15"]["machine_executions"] == "1"
assert by_id["runtime-slackware-current"]["machine_executions"] == "1"
assert by_id["physical-current-fallback"]["machine_executions"] == "0"
assert all(row["reboots"] == "0" for row in plan)
assert all(row["repository_refresh"] == "false" for row in plan)
assert all(row["package_mutation"] == "false" for row in plan)
assert all(row["boot_mutation"] == "false" for row in plan)
assert policy["schema"] == 1
assert policy["scenario"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-planning"
assert policy["planning_only"] is True
assert policy["source_sha256"] == "c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c"
assert policy["template_sha256"] == "4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba"
assert policy["step129_review_sha256"] == "95343b045a16a9fe943b46e1e7887173c9b7f1bb2c18ddcc8e2de867afc94ee8"
assert policy["step129_policy_sha256"] == "f97b4e392a7fdacd7bc6585c7b790231614041a163f733cac171a21bf3259ff2"
assert policy["supported_targets"] == ["slackware-15.0", "slackware-current"]
assert policy["planned_machine_executions"] == 2
assert policy["planned_reboots"] == 0
assert policy["machine_execution_authorized"] is False
assert policy["machine_action_required_in_step130"] is False
assert policy["future_machine_action_required"] is True
assert policy["repository_refresh_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["package_mutation_authorized"] is False
assert policy["boot_mutation_authorized"] is False
assert policy["source_change_authorized"] is False
assert policy["configuration_template_change_authorized"] is False
assert policy["contract_change_authorized"] is False
assert policy["evidence"]["archive_required_per_machine_execution"] is True
assert policy["evidence"]["sha256_sidecar_required"] is True
assert policy["evidence"]["copy_directory"] == "/home/promano"
assert policy["evidence"]["owner"] == "promano"
assert policy["evidence"]["group"] == "users"
assert policy["slackware_15_plan"]["expected_hostname_fqdn"] == "vbox-slack15.vbox-slack15.org"
assert policy["slackware_15_plan"]["machine_executions"] == 1
assert policy["slackware_15_plan"]["reboots"] == 0
assert policy["slackware_current_plan"]["environment"] == "new-vm-preferred"
assert policy["slackware_current_plan"]["hostname_fqdn_binding"] == "deferred-to-runtime-validation-authorization"
assert policy["slackware_current_plan"]["required_boot_profile"] == "grub-direct-generic-no-initrd"
assert policy["slackware_current_plan"]["machine_executions"] == 1
assert policy["slackware_current_plan"]["reboots"] == 0
assert policy["physical_current_fallback"]["default_required"] is False
assert policy["physical_current_fallback"]["planned_machine_executions"] == 0
assert policy["runtime_acceptance_rules"]["characterization_precedes_verdict_in_each_execution"] is True
assert policy["runtime_acceptance_rules"]["characterization_failure_stops_before_runtime_acceptance"] is True
assert policy["runtime_acceptance_rules"]["no_guest_state_mutation_to_force_a_profile"] is True
assert policy["runtime_acceptance_rules"]["actual_boot_profile_cross_checked_independently"] is True
assert policy["runtime_acceptance_rules"]["boot_auto_must_be_runnable_only_for_a_validated_supported_preparation_path"] is True
assert policy["runtime_acceptance_rules"]["step128_source_sha256_must_match_on_target"] is True
assert policy["runtime_acceptance_rules"]["pre_and_post_non_mutation_evidence_required"] is True
assert policy["repository_regression_coverage_retained"]["contract_rows"] == 15
assert policy["repository_regression_coverage_retained"]["conforming_rows"] == 15
assert policy["repository_regression_coverage_retained"]["behavioral_cases"] == 7
assert policy["repository_regression_coverage_retained"]["mkinitrd_managed_path_needs_extra_machine_execution"] is False
assert policy["next_stage"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-authorization"
assert policy["pause_safe"] is True
PY

cat <<'EOF'
schema	1
scenario	phase-1-configuration-module-mode-source-remediation-runtime-validation-planning
source_sha256	c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c
repository_contract_conformance	15-of-15
runtime_validation_pending	true
planned_machine_executions	2
planned_slackware_15_executions	1
planned_slackware_current_executions	1
planned_physical_current_executions	0
planned_reboots	0
characterization_combined_with_runtime_probe	true
slackware_15_environment	existing-vm
slackware_15_hostname	vbox-slack15.vbox-slack15.org
slackware_current_environment	new-vm-preferred
slackware_current_hostname_binding	deferred-to-runtime-validation-authorization
slackware_current_required_boot_profile	grub-direct-generic-no-initrd
physical_current_default_required	false
repository_refresh_required	false
slackware_repository_state_dependency	false
package_mutation_authorized	false
boot_mutation_authorized	false
source_change_authorized	false
machine_execution_authorized	false
machine_action_required	false
future_machine_action_required	true
evidence_archive_required_per_execution	true
evidence_copy_directory	/home/promano
evidence_owner	promano
evidence_group	users
next_stage	phase-1-configuration-module-mode-source-remediation-runtime-validation-authorization
pause_safe	true
EOF
