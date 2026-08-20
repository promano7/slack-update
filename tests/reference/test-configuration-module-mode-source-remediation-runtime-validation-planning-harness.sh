#!/bin/bash
set -uo pipefail
IFS=$'\n\t'

passes=0
failures=0

pass() {
    printf 'PASS: %s\n' "$1"
    passes=$((passes + 1))
}
fail() {
    printf 'FAIL: %s\n' "$1" >&2
    failures=$((failures + 1))
}

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
step129_review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-regression-review.tsv"
step129_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-regression-review-policy.json"
plan="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-planning.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-planning-policy.json"
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-planning.sh"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-planning.md"

check_regular() {
    local path=$1 label=$2
    if [[ -f "$path" && ! -L "$path" ]]; then
        pass "$label is a regular non-symlink file"
    else
        fail "$label is a regular non-symlink file"
    fi
}
check_hash() {
    local path=$1 expected=$2 label=$3 actual
    if [[ ! -f "$path" || -L "$path" ]]; then
        fail "$label has the exact reviewed SHA-256"
        return
    fi
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    if [[ "$actual" == "$expected" ]]; then
        pass "$label has the exact reviewed SHA-256"
    else
        fail "$label has the exact reviewed SHA-256"
    fi
}

check_regular "$source_file" "reference implementation"
check_regular "$template" "configuration template"
check_regular "$step129_review" "step-129 regression review"
check_regular "$step129_policy" "step-129 regression-review policy"
check_regular "$plan" "step-130 runtime-validation plan"
check_regular "$policy" "step-130 runtime-validation planning policy"
check_regular "$helper" "step-130 runtime-validation planning helper"
check_regular "$doc" "step-130 runtime-validation planning document"

check_hash "$source_file" c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "post-remediation reference implementation"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
check_hash "$step129_review" 95343b045a16a9fe943b46e1e7887173c9b7f1bb2c18ddcc8e2de867afc94ee8 "step-129 regression review"
check_hash "$step129_policy" f97b4e392a7fdacd7bc6585c7b790231614041a163f733cac171a21bf3259ff2 "step-129 regression-review policy"

if bash -n "$helper"; then
    pass "runtime-validation planning helper is shell-syntax valid"
else
    fail "runtime-validation planning helper is shell-syntax valid"
fi
if "$helper" --help >/dev/null 2>&1; then
    pass "runtime-validation planning helper exposes a non-mutating help boundary"
else
    fail "runtime-validation planning helper exposes a non-mutating help boundary"
fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then
    fail "unknown options fail closed"
else
    pass "unknown options fail closed"
fi
if python3 -m json.tool "$policy" >/dev/null 2>&1; then
    pass "runtime-validation planning policy is valid JSON"
else
    fail "runtime-validation planning policy is valid JSON"
fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_review=$(sha256sum -- "$step129_review" | awk '{print $1}')
before_step129_policy=$(sha256sum -- "$step129_policy" | awk '{print $1}')
output=$($helper 2>&1)
helper_status=$?
after_source=$(sha256sum -- "$source_file" | awk '{print $1}')
after_template=$(sha256sum -- "$template" | awk '{print $1}')
after_review=$(sha256sum -- "$step129_review" | awk '{print $1}')
after_step129_policy=$(sha256sum -- "$step129_policy" | awk '{print $1}')

if (( helper_status == 0 )); then
    pass "runtime-validation planning completed successfully"
else
    fail "runtime-validation planning completed successfully"
fi
[[ "$before_source" == "$after_source" ]] && pass "planning did not modify the reference implementation" || fail "planning did not modify the reference implementation"
[[ "$before_template" == "$after_template" ]] && pass "planning did not modify the configuration template" || fail "planning did not modify the configuration template"
[[ "$before_review" == "$after_review" ]] && pass "planning did not modify the step-129 regression review" || fail "planning did not modify the step-129 regression review"
[[ "$before_step129_policy" == "$after_step129_policy" ]] && pass "planning did not modify the step-129 regression-review policy" || fail "planning did not modify the step-129 regression-review policy"

check_output() {
    local key=$1 expected=$2 label=$3 actual
    actual=$(printf '%s\n' "$output" | awk -F '\t' -v k="$key" '$1 == k { print $2; exit }')
    if [[ "$actual" == "$expected" ]]; then
        pass "$label"
    else
        fail "$label"
    fi
}

check_output schema 1 "planning output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-planning "planning output records the expected scenario"
check_output source_sha256 c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "planning remains bound to the accepted post-remediation source"
check_output repository_contract_conformance 15-of-15 "planning preserves complete repository contract conformance"
check_output runtime_validation_pending true "runtime target validation remains pending"
check_output planned_machine_executions 2 "planning limits target validation to two machine executions"
check_output planned_slackware_15_executions 1 "planning allocates one Slackware 15.0 execution"
check_output planned_slackware_current_executions 1 "planning allocates one Slackware-current VM execution"
check_output planned_physical_current_executions 0 "physical Slackware-current is not in the default execution plan"
check_output planned_reboots 0 "planning requires no reboot"
check_output characterization_combined_with_runtime_probe true "each target combines characterization and runtime probing"
check_output slackware_15_environment existing-vm "planning keeps the established Slackware 15.0 VM"
check_output slackware_15_hostname vbox-slack15.vbox-slack15.org "planning binds the established Slackware 15.0 hostname"
check_output slackware_current_environment new-vm-preferred "planning selects the new VM as the preferred Slackware-current environment"
check_output slackware_current_hostname_binding deferred-to-runtime-validation-authorization "Slackware-current hostname binding remains deferred"
check_output slackware_current_required_boot_profile grub-direct-generic-no-initrd "Slackware-current VM must preserve the direct-generic-no-initrd profile"
check_output physical_current_default_required false "physical Slackware-current remains fallback-only"
check_output repository_refresh_required false "runtime validation requires no Slackware repository refresh"
check_output slackware_repository_state_dependency false "runtime validation has no Slackware repository-state dependency"
check_output package_mutation_authorized false "package mutation remains unauthorized"
check_output boot_mutation_authorized false "boot mutation remains unauthorized"
check_output source_change_authorized false "source modification remains unauthorized"
check_output machine_execution_authorized false "step 130 authorizes no machine execution"
check_output machine_action_required false "step 130 itself requires no machine action"
check_output future_machine_action_required true "future target runtime validation is explicitly required"
check_output evidence_archive_required_per_execution true "each future machine execution requires an evidence archive"
check_output evidence_copy_directory /home/promano "future evidence is copied directly to /home/promano"
check_output evidence_owner promano "future evidence ownership is bound to promano"
check_output evidence_group users "future evidence group is bound to users"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-authorization "planning advances only to runtime-validation authorization"
check_output pause_safe true "repository-only planning boundary remains pause-safe"

if python3 - "$plan" "$policy" <<'PY'
import csv
import json
import sys

plan_path, policy_path = sys.argv[1:]
with open(plan_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(rows) == 3
assert sum(int(r["machine_executions"]) for r in rows) == 2
assert sum(int(r["reboots"]) for r in rows) == 0
assert sum(1 for r in rows if r["status"] == "planned") == 2
assert sum(1 for r in rows if r["status"] == "fallback") == 1
assert all(r["repository_refresh"] == "false" for r in rows)
assert all(r["package_mutation"] == "false" for r in rows)
assert all(r["boot_mutation"] == "false" for r in rows)
assert policy["schema"] == 1
assert policy["scenario"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-planning"
assert policy["planning_only"] is True
assert policy["source_sha256"] == "c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c"
assert policy["template_sha256"] == "4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba"
assert policy["step129_review_sha256"] == "95343b045a16a9fe943b46e1e7887173c9b7f1bb2c18ddcc8e2de867afc94ee8"
assert policy["step129_policy_sha256"] == "f97b4e392a7fdacd7bc6585c7b790231614041a163f733cac171a21bf3259ff2"
assert policy["supported_targets"] == ["slackware-15.0", "slackware-current"]
assert policy["runtime_validation_pending"] is True
assert policy["slackware_15_plan"]["expected_boot_profile"] == "elilo-generic-with-initrd"
assert policy["slackware_15_plan"]["characterization_and_runtime_probe_combined"] is True
assert policy["slackware_current_plan"]["characterization_and_runtime_probe_combined"] is True
assert policy["slackware_current_plan"]["vm_snapshot_recommended_before_binding"] is True
assert len(policy["physical_current_fallback"]["allowed_only_if"]) == 3
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
PY
then
    pass "runtime-validation TSV and policy are internally consistent"
else
    fail "runtime-validation TSV and policy are internally consistent"
fi

if grep -Fq 'two machine executions total' "$doc" && grep -Fq 'one per target' "$doc"; then
    pass "planning document fixes the two-execution runtime boundary"
else
    fail "planning document fixes the two-execution runtime boundary"
fi
if grep -Fq 'vbox-slack15.vbox-slack15.org' "$doc" && grep -Fq 'new Slackware-current VM' "$doc"; then
    pass "planning document records both intended target environments"
else
    fail "planning document records both intended target environments"
fi
if grep -Fq 'grub-direct-generic-no-initrd' "$doc" && grep -Fq 'ELILO' "$doc"; then
    pass "planning document distinguishes the two live boot profiles"
else
    fail "planning document distinguishes the two live boot profiles"
fi
if grep -Fq '/home/promano' "$doc" && grep -Fq 'promano:users' "$doc"; then
    pass "planning document preserves the evidence-copy convention"
else
    fail "planning document preserves the evidence-copy convention"
fi
if grep -Fq 'must not run `slackpkg update`' "$doc" && grep -Fq 'reboot' "$doc"; then
    pass "planning document excludes repository refresh and reboot"
else
    fail "planning document excludes repository refresh and reboot"
fi
if grep -Fq 'physical Slackware-current machine is not part of the default plan' "$doc"; then
    pass "planning document keeps the physical current host as fallback"
else
    fail "planning document keeps the physical current host as fallback"
fi
if grep -Fq 'machine_execution_authorized=false' "$doc"; then
    pass "planning document preserves the machine-authorization boundary"
else
    fail "planning document preserves the machine-authorization boundary"
fi
if grep -Fq 'runtime-validation-authorization' "$doc"; then
    pass "planning document names the authorization stage as the only next stage"
else
    fail "planning document names the authorization stage as the only next stage"
fi

if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|reboot|shutdown|poweroff)([[:space:]]|$)' "$helper"; then
    fail "runtime-validation planning helper contains no package, boot, or shutdown mutation command"
else
    pass "runtime-validation planning helper contains no package, boot, or shutdown mutation command"
fi
if grep -Eq '^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync|scp|ssh)([[:space:]]|$)' "$helper"; then
    fail "runtime-validation planning helper contains no network client command"
else
    pass "runtime-validation planning helper contains no network client command"
fi

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
