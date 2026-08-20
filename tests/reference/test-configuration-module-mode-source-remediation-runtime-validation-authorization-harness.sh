#!/bin/bash
set -uo pipefail
IFS=$'\n\t'

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1" >&2; failures=$((failures + 1)); }

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
step130_plan="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-planning.tsv"
step130_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-planning-policy.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-authorization.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-authorization-policy.json"
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-authorization.sh"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-authorization.md"

check_regular() {
    local path=$1 label=$2
    [[ -f "$path" && ! -L "$path" ]] && pass "$label is a regular non-symlink file" || fail "$label is a regular non-symlink file"
}
check_hash() {
    local path=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$path" 2>/dev/null | awk '{print $1}')
    [[ "$actual" == "$expected" ]] && pass "$label has the exact reviewed SHA-256" || fail "$label has the exact reviewed SHA-256"
}

check_regular "$source_file" "reference implementation"
check_regular "$template" "configuration template"
check_regular "$step130_plan" "step-130 runtime-validation plan"
check_regular "$step130_policy" "step-130 runtime-validation planning policy"
check_regular "$authorization" "step-131 runtime-validation authorization"
check_regular "$policy" "step-131 runtime-validation authorization policy"
check_regular "$helper" "step-131 runtime-validation authorization helper"
check_regular "$doc" "step-131 runtime-validation authorization document"

check_hash "$source_file" c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "post-remediation reference implementation"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
check_hash "$step130_plan" 452b5b6eb8c5901171579127284c041de446d8a20e7feebaf35a5161b01fe89c "step-130 runtime-validation plan"
check_hash "$step130_policy" ab74c4cae4e5a80d52188c309134e494167034c04d96672e505d1a6cc13fdc79 "step-130 runtime-validation planning policy"

bash -n "$helper" && pass "runtime-validation authorization helper is shell-syntax valid" || fail "runtime-validation authorization helper is shell-syntax valid"
if "$helper" --help >/dev/null 2>&1; then pass "runtime-validation authorization helper exposes a non-mutating help boundary"; else fail "runtime-validation authorization helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi
if python3 -m json.tool "$policy" >/dev/null 2>&1; then pass "runtime-validation authorization policy is valid JSON"; else fail "runtime-validation authorization policy is valid JSON"; fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_plan=$(sha256sum -- "$step130_plan" | awk '{print $1}')
before_step130_policy=$(sha256sum -- "$step130_policy" | awk '{print $1}')
if output=$("$helper" 2>&1); then
    pass "runtime-validation authorization review completed successfully"
else
    fail "runtime-validation authorization review completed successfully"
    output=''
fi
after_source=$(sha256sum -- "$source_file" | awk '{print $1}')
after_template=$(sha256sum -- "$template" | awk '{print $1}')
after_plan=$(sha256sum -- "$step130_plan" | awk '{print $1}')
after_step130_policy=$(sha256sum -- "$step130_policy" | awk '{print $1}')
[[ "$before_source" == "$after_source" ]] && pass "authorization review did not modify the reference implementation" || fail "authorization review did not modify the reference implementation"
[[ "$before_template" == "$after_template" ]] && pass "authorization review did not modify the configuration template" || fail "authorization review did not modify the configuration template"
[[ "$before_plan" == "$after_plan" ]] && pass "authorization review did not modify the step-130 plan" || fail "authorization review did not modify the step-130 plan"
[[ "$before_step130_policy" == "$after_step130_policy" ]] && pass "authorization review did not modify the step-130 policy" || fail "authorization review did not modify the step-130 policy"

check_output() {
    local key=$1 expected=$2 label=$3 actual
    actual=$(printf '%s\n' "$output" | awk -F '\t' -v k="$key" '$1 == k { print $2; exit }')
    [[ "$actual" == "$expected" ]] && pass "$label" || fail "$label"
}

check_output schema 1 "authorization output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-authorization "authorization output records the expected scenario"
check_output source_sha256 c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "authorization remains bound to the accepted remediated source"
check_output runtime_validation_scope_authorized true "runtime validation scope is authorized"
check_output runtime_validation_pending true "target runtime validation remains pending"
check_output machine_execution_authorized false "no machine execution is yet authorized"
check_output authorization_consumable false "authorization remains non-consumable before target binding"
check_output authorization_blocker slackware-current-vm-host-binding-pending "authorization records the current-VM binding blocker"
check_output machine_action_required false "step 131 itself requires no machine action"
check_output future_machine_action_required true "future target machine action remains required"
check_output machine_execution_limit_after_binding 2 "authorization preserves the two-execution ceiling"
check_output reboot_limit_after_binding 0 "authorization preserves the zero-reboot boundary"
check_output slackware_15_scope_authorized true "Slackware 15.0 validation scope is approved"
check_output slackware_15_identity_binding_complete true "Slackware 15.0 target identity is already bound"
check_output slackware_15_execution_authorized_now false "Slackware 15.0 execution remains held"
check_output slackware_current_scope_authorized true "Slackware-current validation scope is approved"
check_output slackware_current_identity_binding_complete false "Slackware-current identity binding remains incomplete"
check_output slackware_current_execution_authorized_now false "Slackware-current execution remains unauthorized"
check_output slackware_current_hostname_binding pending-current-vm-fqdn "Slackware-current FQDN is not invented before the VM exists"
check_output slackware_current_required_boot_profile grub-direct-generic-no-initrd "Slackware-current required boot profile remains frozen"
check_output physical_current_default_authorized false "physical Slackware-current remains outside default authorization"
check_output repository_refresh_required false "runtime authorization requires no Slackware repository refresh"
check_output slackware_repository_state_dependency false "runtime authorization has no Slackware repository-state dependency"
check_output package_mutation_authorized false "package mutation remains unauthorized"
check_output boot_mutation_authorized false "boot mutation remains unauthorized"
check_output source_change_authorized false "source modification remains unauthorized"
check_output evidence_archive_required_per_execution true "each eventual machine execution requires evidence"
check_output evidence_copy_directory /home/promano "eventual evidence is copied directly to /home/promano"
check_output evidence_owner promano "eventual evidence ownership remains promano"
check_output evidence_group users "eventual evidence group remains users"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-target-binding "authorization advances only to target binding"
check_output pause_safe true "repository-only authorization boundary remains pause-safe"

if python3 - "$authorization" "$policy" <<'PY'
import csv
import json
import sys

authorization_path, policy_path = sys.argv[1:]
with open(authorization_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(rows) == 3
assert sum(int(row["machine_execution_limit"]) for row in rows) == 2
assert sum(int(row["reboots_allowed"]) for row in rows) == 0
assert sum(row["scope_authorized"] == "true" for row in rows) == 2
assert sum(row["execution_authorized_now"] == "true" for row in rows) == 0
assert all(row["repository_refresh_allowed"] == "false" for row in rows)
assert all(row["package_mutation_allowed"] == "false" for row in rows)
assert all(row["boot_mutation_allowed"] == "false" for row in rows)
assert policy["runtime_validation_scope_authorized"] is True
assert policy["machine_execution_authorized"] is False
assert policy["authorization_consumable"] is False
assert policy["authorization_blocker"] == "slackware-current-vm-host-binding-pending"
assert policy["machine_execution_limit_after_binding"] == 2
assert policy["reboot_limit_after_binding"] == 0
assert policy["slackware_15_authorization"]["expected_hostname_fqdn"] == "vbox-slack15.vbox-slack15.org"
assert policy["slackware_current_authorization"]["hostname_fqdn_binding"] == "pending-current-vm-fqdn"
assert policy["slackware_current_authorization"]["binding_required_before_execution"] is True
assert policy["target_binding_requirements"]["slackware_current_vm_must_exist_before_binding"] is True
assert policy["target_binding_requirements"]["binding_stage_must_not_execute_target_validation"] is True
PY
then
    pass "authorization TSV and policy are internally consistent"
else
    fail "authorization TSV and policy are internally consistent"
fi

if grep -Fq 'runtime_validation_scope_authorized=true' "$doc" && grep -Fq 'machine_execution_authorized=false' "$doc"; then
    pass "authorization document separates scope approval from machine execution"
else
    fail "authorization document separates scope approval from machine execution"
fi
if grep -Fq 'vbox-slack15.vbox-slack15.org' "$doc" && grep -Fq 'FQDN' "$doc"; then
    pass "authorization document preserves the asymmetric target-binding state"
else
    fail "authorization document preserves the asymmetric target-binding state"
fi
if grep -Fq 'grub-direct-generic-no-initrd' "$doc" && grep -Fq 'ELILO' "$doc"; then
    pass "authorization document preserves both required boot profiles"
else
    fail "authorization document preserves both required boot profiles"
fi
if grep -Fq 'must exist before that FQDN is frozen' "$doc"; then
    pass "authorization document refuses to invent the Slackware-current VM identity"
else
    fail "authorization document refuses to invent the Slackware-current VM identity"
fi
if grep -Fq '/home/promano' "$doc" && grep -Fq 'promano:users' "$doc"; then
    pass "authorization document preserves the evidence-copy convention"
else
    fail "authorization document preserves the evidence-copy convention"
fi
if grep -Fq 'physical Slackware-current host remains outside' "$doc"; then
    pass "authorization document keeps the physical current host fallback-only"
else
    fail "authorization document keeps the physical current host fallback-only"
fi
if grep -Fq 'Until that binding is complete, no runtime machine' "$doc"; then
    pass "authorization document preserves the pre-binding execution stop"
else
    fail "authorization document preserves the pre-binding execution stop"
fi
if grep -Fq 'runtime-validation-target-binding' "$doc"; then
    pass "authorization document names target binding as the only next stage"
else
    fail "authorization document names target binding as the only next stage"
fi

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail "runtime-validation authorization helper contains no package, boot, or shutdown mutation command"
else
    pass "runtime-validation authorization helper contains no package, boot, or shutdown mutation command"
fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync|scp|ssh)([[:space:]]|$)' "$helper"; then
    fail "runtime-validation authorization helper contains no network client command"
else
    pass "runtime-validation authorization helper contains no network client command"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
