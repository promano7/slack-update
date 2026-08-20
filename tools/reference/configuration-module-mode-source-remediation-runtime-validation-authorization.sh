#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-authorization.sh [--help]

Validate and report the repository-only step-131 runtime-validation authorization.
This command executes no target machine and performs no source, configuration,
package, boot, repository, network, or machine mutation.
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
step130_plan="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-planning.tsv"
step130_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-planning-policy.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-authorization.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-authorization-policy.json"

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
require_regular_file "$step130_plan" "step-130 runtime-validation plan"
require_regular_file "$step130_policy" "step-130 runtime-validation planning policy"
require_regular_file "$authorization" "step-131 runtime-validation authorization"
require_regular_file "$policy" "step-131 runtime-validation authorization policy"

require_sha256 "$source_file" c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "accepted post-remediation source"
require_sha256 "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
require_sha256 "$step130_plan" 452b5b6eb8c5901171579127284c041de446d8a20e7feebaf35a5161b01fe89c "step-130 runtime-validation plan"
require_sha256 "$step130_policy" ab74c4cae4e5a80d52188c309134e494167034c04d96672e505d1a6cc13fdc79 "step-130 runtime-validation planning policy"

python3 - "$step130_plan" "$step130_policy" "$authorization" "$policy" <<'PY'
import csv
import json
import sys

plan_path, step130_policy_path, authorization_path, policy_path = sys.argv[1:]
with open(plan_path, encoding="utf-8", newline="") as handle:
    plan = list(csv.DictReader(handle, delimiter="\t"))
with open(step130_policy_path, encoding="utf-8") as handle:
    step130 = json.load(handle)
with open(authorization_path, encoding="utf-8", newline="") as handle:
    authorization = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(plan) == 3
assert step130["planned_machine_executions"] == 2
assert step130["planned_reboots"] == 0
assert step130["machine_execution_authorized"] is False
assert step130["next_stage"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-authorization"
assert len(authorization) == 3
by_id = {row["authorization_id"]: row for row in authorization}
assert set(by_id) == {
    "runtime-slackware-15",
    "runtime-slackware-current",
    "physical-current-fallback",
}
assert by_id["runtime-slackware-15"]["scope_authorized"] == "true"
assert by_id["runtime-slackware-15"]["execution_authorized_now"] == "false"
assert by_id["runtime-slackware-current"]["scope_authorized"] == "true"
assert by_id["runtime-slackware-current"]["execution_authorized_now"] == "false"
assert by_id["runtime-slackware-current"]["binding_required"] == "true"
assert by_id["physical-current-fallback"]["scope_authorized"] == "false"
assert sum(int(row["machine_execution_limit"]) for row in authorization) == 2
assert all(row["reboots_allowed"] == "0" for row in authorization)
assert all(row["repository_refresh_allowed"] == "false" for row in authorization)
assert all(row["package_mutation_allowed"] == "false" for row in authorization)
assert all(row["boot_mutation_allowed"] == "false" for row in authorization)
assert policy["schema"] == 1
assert policy["scenario"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-authorization"
assert policy["authorization_review_only"] is True
assert policy["source_sha256"] == "c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c"
assert policy["template_sha256"] == "4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba"
assert policy["step130_plan_sha256"] == "452b5b6eb8c5901171579127284c041de446d8a20e7feebaf35a5161b01fe89c"
assert policy["step130_policy_sha256"] == "ab74c4cae4e5a80d52188c309134e494167034c04d96672e505d1a6cc13fdc79"
assert policy["supported_targets"] == ["slackware-15.0", "slackware-current"]
assert policy["runtime_validation_scope_authorized"] is True
assert policy["runtime_validation_pending"] is True
assert policy["machine_execution_authorized"] is False
assert policy["authorization_consumable"] is False
assert policy["authorization_blocker"] == "slackware-current-vm-host-binding-pending"
assert policy["machine_action_required_in_step131"] is False
assert policy["future_machine_action_required"] is True
assert policy["machine_execution_limit_after_binding"] == 2
assert policy["reboot_limit_after_binding"] == 0
assert policy["repository_refresh_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["package_mutation_authorized"] is False
assert policy["boot_mutation_authorized"] is False
assert policy["source_change_authorized"] is False
assert policy["configuration_template_change_authorized"] is False
assert policy["contract_change_authorized"] is False
assert policy["slackware_15_authorization"]["identity_binding_complete"] is True
assert policy["slackware_15_authorization"]["execution_authorized_now"] is False
assert policy["slackware_15_authorization"]["held_until_common_target_binding_freeze"] is True
assert policy["slackware_current_authorization"]["hostname_fqdn_binding"] == "pending-current-vm-fqdn"
assert policy["slackware_current_authorization"]["required_boot_profile"] == "grub-direct-generic-no-initrd"
assert policy["slackware_current_authorization"]["identity_binding_complete"] is False
assert policy["slackware_current_authorization"]["execution_authorized_now"] is False
assert policy["slackware_current_authorization"]["binding_required_before_execution"] is True
assert policy["physical_current_fallback"]["default_authorized"] is False
assert policy["physical_current_fallback"]["machine_execution_limit"] == 0
assert policy["physical_current_fallback"]["requires_new_explicit_review"] is True
assert all(policy["authorized_runtime_protocol"][key] is True for key in (
    "characterization_and_runtime_probe_combined",
    "characterization_failure_is_stop_condition",
    "actual_boot_profile_cross_checked_independently",
    "boot_auto_runnable_only_for_validated_supported_path",
    "accepted_source_sha256_required_on_target",
    "pre_and_post_non_mutation_evidence_required",
    "repository_refresh_forbidden",
    "package_mutation_forbidden",
    "boot_mutation_forbidden",
    "reboot_forbidden",
))
assert policy["evidence"]["copy_directory"] == "/home/promano"
assert policy["evidence"]["owner"] == "promano"
assert policy["evidence"]["group"] == "users"
assert policy["evidence"]["preserve_until_reviewed"] is True
assert policy["target_binding_requirements"]["slackware_15_binding_already_complete"] is True
assert policy["target_binding_requirements"]["slackware_current_vm_must_exist_before_binding"] is True
assert policy["target_binding_requirements"]["slackware_current_fqdn_must_be_frozen_before_execution"] is True
assert policy["target_binding_requirements"]["execution_harnesses_must_be_bound_before_machine_execution"] is True
assert policy["target_binding_requirements"]["binding_stage_must_not_execute_target_validation"] is True
assert policy["next_stage"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-target-binding"
assert policy["pause_safe"] is True
PY

cat <<'EOF'
schema	1
scenario	phase-1-configuration-module-mode-source-remediation-runtime-validation-authorization
source_sha256	c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c
runtime_validation_scope_authorized	true
runtime_validation_pending	true
machine_execution_authorized	false
authorization_consumable	false
authorization_blocker	slackware-current-vm-host-binding-pending
machine_action_required	false
future_machine_action_required	true
machine_execution_limit_after_binding	2
reboot_limit_after_binding	0
slackware_15_scope_authorized	true
slackware_15_identity_binding_complete	true
slackware_15_execution_authorized_now	false
slackware_current_scope_authorized	true
slackware_current_identity_binding_complete	false
slackware_current_execution_authorized_now	false
slackware_current_hostname_binding	pending-current-vm-fqdn
slackware_current_required_boot_profile	grub-direct-generic-no-initrd
physical_current_default_authorized	false
repository_refresh_required	false
slackware_repository_state_dependency	false
package_mutation_authorized	false
boot_mutation_authorized	false
source_change_authorized	false
evidence_archive_required_per_execution	true
evidence_copy_directory	/home/promano
evidence_owner	promano
evidence_group	users
next_stage	phase-1-configuration-module-mode-source-remediation-runtime-validation-target-binding
pause_safe	true

EOF
