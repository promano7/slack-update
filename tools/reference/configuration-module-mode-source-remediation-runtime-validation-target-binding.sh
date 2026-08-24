#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-target-binding.sh [--help]

Validate and report the repository-only step-132 target binding. This command
freezes target identities and runtime harnesses but performs no target machine
execution and no source, configuration, package, boot, repository, or network
mutation.
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
step131_authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-authorization.tsv"
step131_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-authorization-policy.json"
binding="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
current_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current.sh"
slack15_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15.sh"
elilo_closure="$repo_root/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"

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
require_regular_file "$step131_authorization" "step-131 authorization TSV"
require_regular_file "$step131_policy" "step-131 authorization policy"
require_regular_file "$binding" "step-132 target-binding TSV"
require_regular_file "$policy" "step-132 target-binding policy"
require_regular_file "$current_harness" "Slackware-current execution harness"
require_regular_file "$slack15_harness" "Slackware 15.0 execution harness"
require_regular_file "$elilo_closure" "accepted Slackware 15.0 ELILO closure record"

require_sha256 "$source_file" c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "accepted post-remediation source"
require_sha256 "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
require_sha256 "$step131_authorization" 78026de8b5b149b7057aa6ff0185c8d9029aa6efe3a525a86d797100d6fc804e "step-131 authorization TSV"
require_sha256 "$step131_policy" 5b3bb21506e941e423058eaf36bf287b64d18f7a034023aa4c5e95e17191236b "step-131 authorization policy"
require_sha256 "$current_harness" 9f54d2c7d27f46e7d522a8046274d67860a5a59f455e796e467b7f6d23961d62 "Slackware-current execution harness"
require_sha256 "$slack15_harness" 0226e6d48483e0014c699e5affe224bceaa07f8d767673ba30700c7ee21b670c "Slackware 15.0 execution harness"
require_sha256 "$elilo_closure" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "accepted Slackware 15.0 ELILO closure record"

python3 - "$step131_authorization" "$step131_policy" "$binding" "$policy" <<'PY'
import csv
import json
import sys

step131_tsv_path, step131_policy_path, binding_path, policy_path = sys.argv[1:]
with open(step131_tsv_path, encoding="utf-8", newline="") as handle:
    step131_rows = list(csv.DictReader(handle, delimiter="\t"))
with open(step131_policy_path, encoding="utf-8") as handle:
    step131 = json.load(handle)
with open(binding_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(step131_rows) == 3
assert step131["scenario"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-authorization"
assert step131["runtime_validation_scope_authorized"] is True
assert step131["machine_execution_authorized"] is False
assert step131["authorization_consumable"] is False
assert step131["authorization_blocker"] == "slackware-current-vm-host-binding-pending"
assert step131["machine_execution_limit_after_binding"] == 2
assert step131["reboot_limit_after_binding"] == 0
assert step131["slackware_15_authorization"]["expected_hostname_fqdn"] == "vbox-slack15.vbox-slack15.org"
assert step131["slackware_current_authorization"]["required_boot_profile"] == "grub-direct-generic-no-initrd"
assert step131["target_binding_requirements"]["binding_stage_must_not_execute_target_validation"] is True

assert len(rows) == 3
by_id = {row["binding_id"]: row for row in rows}
assert set(by_id) == {"runtime-slackware-current", "runtime-slackware-15", "physical-current-fallback"}
current = by_id["runtime-slackware-current"]
slack15 = by_id["runtime-slackware-15"]
fallback = by_id["physical-current-fallback"]
assert current["hostname_fqdn"] == "vbox-slackcurrent.vbox-slackcurrent.org"
assert current["required_boot_profile"] == "grub-direct-generic-no-initrd"
assert current["accepted_kernel"] == "6.18.45"
assert current["execution_harness_sha256"] == "9f54d2c7d27f46e7d522a8046274d67860a5a59f455e796e467b7f6d23961d62"
assert current["execution_authorized"] == "true"
assert current["authorization_consumable"] == "true"
assert current["machine_execution_limit"] == "1"
assert slack15["hostname_fqdn"] == "vbox-slack15.vbox-slack15.org"
assert slack15["required_boot_profile"] == "elilo-generic-with-initrd"
assert slack15["accepted_kernel"] == "5.15.209"
assert slack15["execution_harness_sha256"] == "0226e6d48483e0014c699e5affe224bceaa07f8d767673ba30700c7ee21b670c"
assert slack15["execution_authorized"] == "false"
assert slack15["authorization_consumable"] == "false"
assert slack15["machine_execution_limit"] == "1"
assert fallback["execution_authorized"] == "false"
assert fallback["machine_execution_limit"] == "0"
assert sum(int(row["machine_execution_limit"]) for row in rows) == 2
assert sum(int(row["reboots_allowed"]) for row in rows) == 0
assert all(row["repository_refresh_allowed"] == "false" for row in rows)
assert all(row["package_mutation_allowed"] == "false" for row in rows)
assert all(row["boot_mutation_allowed"] == "false" for row in rows)

assert policy["schema"] == 1
assert policy["scenario"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-target-binding"
assert policy["binding_only"] is True
assert policy["source_sha256"] == "c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c"
assert policy["template_sha256"] == "4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba"
assert policy["step131_authorization_tsv_sha256"] == "78026de8b5b149b7057aa6ff0185c8d9029aa6efe3a525a86d797100d6fc804e"
assert policy["step131_authorization_policy_sha256"] == "5b3bb21506e941e423058eaf36bf287b64d18f7a034023aa4c5e95e17191236b"
assert policy["runtime_validation_scope_authorized"] is True
assert policy["target_binding_complete"] is True
assert policy["machine_execution_authorized"] is True
assert policy["authorization_consumable"] is True
assert policy["authorization_blocker"] == "none"
assert policy["machine_execution_limit_total"] == 2
assert policy["reboot_limit"] == 0
assert policy["repository_refresh_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["package_mutation_authorized"] is False
assert policy["boot_mutation_authorized"] is False
assert policy["source_change_authorized"] is False
assert policy["configuration_template_change_authorized"] is False
assert policy["contract_change_authorized"] is False
assert policy["machine_action_required_in_step132"] is False
assert policy["future_machine_action_required"] is True
assert policy["execution_order"] == ["slackware-current", "slackware-15.0"]
assert policy["review_each_execution_before_next"] is True

pc = policy["slackware_current"]
assert pc["hostname_fqdn"] == current["hostname_fqdn"]
assert pc["required_boot_profile"] == current["required_boot_profile"]
assert pc["accepted_kernel"] == current["accepted_kernel"]
assert pc["expected_root_device"] == "/dev/sda2"
assert pc["direct_generic_menuentry"] == "Slackware-current slack-update direct generic (no initrd)"
assert pc["execution_harness"] == current["execution_harness"]
assert pc["execution_harness_sha256"] == current["execution_harness_sha256"]
assert pc["execution_authorized"] is True
assert pc["authorization_consumable"] is True
assert pc["machine_execution_limit"] == 1
assert pc["reboot_limit"] == 0
assert pc["expected_runtime_verdict"] == {
    "boot_mode": "auto",
    "boot_module_state": "available",
    "boot_module_run": 1,
    "boot_preparation_layout": "direct-generic-no-initrd",
    "boot_initrd_available": 0,
    "boot_grub_available": 1,
    "boot_direct_generic_available": 1,
}

p15 = policy["slackware_15"]
assert p15["hostname_fqdn"] == slack15["hostname_fqdn"]
assert p15["required_boot_profile"] == slack15["required_boot_profile"]
assert p15["accepted_kernel"] == slack15["accepted_kernel"]
assert p15["required_boot_image_suffix"] == "\\EFI\\Slackware\\vmlinuz-generic-5.15.209"
assert p15["elilo_conf_sha256"] == "94b77b9f70a9d3b22d146c36af0ee6bbf09133d0b1931a2e731e881d3edc37f6"
assert p15["accepted_closure_record_sha256"] == "7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635"
assert p15["execution_harness"] == slack15["execution_harness"]
assert p15["execution_harness_sha256"] == slack15["execution_harness_sha256"]
assert p15["execution_authorized"] is False
assert p15["authorization_consumable"] is False
assert p15["held_until_current_review"] is True
release_gate = p15["release_gate"]
assert release_gate["required_review_policy"] == "tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-review-policy.json"
assert release_gate["required_scenario"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-review"
assert all(release_gate[key] is True for key in (
    "binding_policy_sha256_must_match",
    "accepted_source_sha256_must_match",
    "accepted_template_sha256_must_match",
    "current_execution_harness_sha256_must_match",
    "current_execution_evidence_sha256_required",
    "current_execution_reviewed_required",
    "current_execution_accepted_required",
    "slackware_15_execution_released_required",
    "slackware_15_execution_authorized_required",
))
assert p15["machine_execution_limit"] == 1
assert p15["reboot_limit"] == 0
assert p15["expected_runtime_verdict"]["boot_module_state"] == "unavailable"
assert p15["expected_runtime_verdict"]["boot_module_run"] == 0
assert p15["expected_runtime_verdict"]["boot_preparation_layout"] == "unknown"
assert p15["expected_runtime_verdict"]["boot_initrd_available"] == 1
assert p15["expected_runtime_verdict"]["boot_grub_available"] == 0

assert policy["physical_current_fallback"]["default_authorized"] is False
assert policy["physical_current_fallback"]["machine_execution_limit"] == 0
assert policy["authorized_runtime_protocol"]["characterization_and_runtime_probe_combined"] is True
assert policy["authorized_runtime_protocol"]["characterization_failure_is_stop_condition"] is True
assert policy["authorized_runtime_protocol"]["actual_boot_profile_cross_checked_independently"] is True
assert policy["authorized_runtime_protocol"]["repository_refresh_forbidden"] is True
assert policy["authorized_runtime_protocol"]["package_mutation_forbidden"] is True
assert policy["authorized_runtime_protocol"]["boot_mutation_forbidden"] is True
assert policy["authorized_runtime_protocol"]["reboot_forbidden"] is True
assert policy["evidence"]["copy_directory"] == "/home/promano"
assert policy["evidence"]["owner"] == "promano"
assert policy["evidence"]["group"] == "users"
assert policy["next_stage"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-execution"
assert policy["pause_safe"] is True
PY

cat <<'EOF'
schema	1
scenario	phase-1-configuration-module-mode-source-remediation-runtime-validation-target-binding
source_sha256	c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c
target_binding_complete	true
runtime_validation_scope_authorized	true
machine_execution_authorized	true
authorization_consumable	true
authorization_blocker	none
machine_execution_limit_total	2
reboot_limit	0
slackware_current_hostname	vbox-slackcurrent.vbox-slackcurrent.org
slackware_current_required_boot_profile	grub-direct-generic-no-initrd
slackware_current_accepted_kernel	6.18.45
slackware_current_expected_root_device	/dev/sda2
slackware_current_execution_harness_sha256	9f54d2c7d27f46e7d522a8046274d67860a5a59f455e796e467b7f6d23961d62
slackware_15_hostname	vbox-slack15.vbox-slack15.org
slackware_15_required_boot_profile	elilo-generic-with-initrd
slackware_15_accepted_kernel	5.15.209
slackware_15_execution_harness_sha256	0226e6d48483e0014c699e5affe224bceaa07f8d767673ba30700c7ee21b670c
slackware_15_execution_authorized_now	false
slackware_15_authorization_consumable	false
execution_order	slackware-current-then-review-then-slackware-15
review_each_execution_before_next	true
physical_current_default_authorized	false
repository_refresh_required	false
slackware_repository_state_dependency	false
package_mutation_authorized	false
boot_mutation_authorized	false
source_change_authorized	false
machine_action_required	false
future_machine_action_required	true
evidence_archive_required_per_execution	true
evidence_copy_directory	/home/promano
evidence_owner	promano
evidence_group	users
next_stage	phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-execution
pause_safe	true
EOF
