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
step131_authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-authorization.tsv"
step131_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-authorization-policy.json"
binding="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-target-binding.sh"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-target-binding.md"
current_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current.sh"
slack15_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15.sh"
elilo_closure="$repo_root/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"

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
check_regular "$step131_authorization" "step-131 runtime-validation authorization"
check_regular "$step131_policy" "step-131 runtime-validation authorization policy"
check_regular "$binding" "step-132 runtime-validation target binding"
check_regular "$policy" "step-132 runtime-validation target-binding policy"
check_regular "$helper" "step-132 target-binding helper"
check_regular "$doc" "step-132 target-binding document"
check_regular "$current_harness" "Slackware-current execution harness"
check_regular "$slack15_harness" "Slackware 15.0 execution harness"
check_regular "$elilo_closure" "accepted Slackware 15.0 ELILO closure record"

check_hash "$source_file" c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "accepted post-remediation reference implementation"
check_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "frozen configuration template"
check_hash "$step131_authorization" 78026de8b5b149b7057aa6ff0185c8d9029aa6efe3a525a86d797100d6fc804e "step-131 runtime-validation authorization"
check_hash "$step131_policy" 5b3bb21506e941e423058eaf36bf287b64d18f7a034023aa4c5e95e17191236b "step-131 runtime-validation authorization policy"
check_hash "$current_harness" 9f54d2c7d27f46e7d522a8046274d67860a5a59f455e796e467b7f6d23961d62 "frozen Slackware-current execution harness"
check_hash "$slack15_harness" 0226e6d48483e0014c699e5affe224bceaa07f8d767673ba30700c7ee21b670c "frozen Slackware 15.0 execution harness"
check_hash "$elilo_closure" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "accepted Slackware 15.0 ELILO closure record"

for script in "$helper" "$current_harness" "$slack15_harness"; do
    if bash -n "$script"; then
        pass "${script##*/} is shell-syntax valid"
    else
        fail "${script##*/} is shell-syntax valid"
    fi
done
if "$helper" --help >/dev/null 2>&1; then pass "target-binding helper exposes a non-mutating help boundary"; else fail "target-binding helper exposes a non-mutating help boundary"; fi
if "$helper" --definitely-unknown >/dev/null 2>&1; then fail "target-binding helper rejects unknown options"; else pass "target-binding helper rejects unknown options"; fi
if "$current_harness" --help >/dev/null 2>&1; then pass "Slackware-current harness exposes help without requiring root"; else fail "Slackware-current harness exposes help without requiring root"; fi
if "$slack15_harness" --help >/dev/null 2>&1; then pass "Slackware 15.0 harness exposes help without requiring root"; else fail "Slackware 15.0 harness exposes help without requiring root"; fi
if python3 -m json.tool "$policy" >/dev/null 2>&1; then pass "target-binding policy is valid JSON"; else fail "target-binding policy is valid JSON"; fi

before_source=$(sha256sum -- "$source_file" | awk '{print $1}')
before_template=$(sha256sum -- "$template" | awk '{print $1}')
before_step131=$(sha256sum -- "$step131_authorization" | awk '{print $1}')
before_step131_policy=$(sha256sum -- "$step131_policy" | awk '{print $1}')
before_current=$(sha256sum -- "$current_harness" | awk '{print $1}')
before_slack15=$(sha256sum -- "$slack15_harness" | awk '{print $1}')
if output=$("$helper" 2>&1); then
    pass "target-binding review completed successfully"
else
    fail "target-binding review completed successfully"
    printf '%s\n' "$output" >&2
    output=''
fi
after_source=$(sha256sum -- "$source_file" | awk '{print $1}')
after_template=$(sha256sum -- "$template" | awk '{print $1}')
after_step131=$(sha256sum -- "$step131_authorization" | awk '{print $1}')
after_step131_policy=$(sha256sum -- "$step131_policy" | awk '{print $1}')
after_current=$(sha256sum -- "$current_harness" | awk '{print $1}')
after_slack15=$(sha256sum -- "$slack15_harness" | awk '{print $1}')
[[ "$before_source" == "$after_source" ]] && pass "target binding did not modify the reference implementation" || fail "target binding did not modify the reference implementation"
[[ "$before_template" == "$after_template" ]] && pass "target binding did not modify the configuration template" || fail "target binding did not modify the configuration template"
[[ "$before_step131" == "$after_step131" ]] && pass "target binding did not modify the step-131 authorization TSV" || fail "target binding did not modify the step-131 authorization TSV"
[[ "$before_step131_policy" == "$after_step131_policy" ]] && pass "target binding did not modify the step-131 authorization policy" || fail "target binding did not modify the step-131 authorization policy"
[[ "$before_current" == "$after_current" ]] && pass "target binding did not modify the frozen Slackware-current harness" || fail "target binding did not modify the frozen Slackware-current harness"
[[ "$before_slack15" == "$after_slack15" ]] && pass "target binding did not modify the frozen Slackware 15.0 harness" || fail "target binding did not modify the frozen Slackware 15.0 harness"

check_output() {
    local key=$1 expected=$2 label=$3 actual
    actual=$(printf '%s\n' "$output" | awk -F '\t' -v k="$key" '$1 == k { print $2; exit }')
    [[ "$actual" == "$expected" ]] && pass "$label" || fail "$label"
}
check_output schema 1 "target-binding output records schema 1"
check_output scenario phase-1-configuration-module-mode-source-remediation-runtime-validation-target-binding "target-binding output records the expected scenario"
check_output source_sha256 c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "target binding remains tied to the accepted remediated source"
check_output target_binding_complete true "both runtime targets are completely bound"
check_output runtime_validation_scope_authorized true "runtime-validation scope remains authorized"
check_output machine_execution_authorized true "machine execution becomes authorized only after binding"
check_output authorization_consumable true "the two-execution authorization is now consumable"
check_output authorization_blocker none "the pre-binding authorization blocker is cleared"
check_output machine_execution_limit_total 2 "target binding preserves the exact two-execution ceiling"
check_output reboot_limit 0 "target binding preserves the zero-reboot ceiling"
check_output slackware_current_hostname vbox-slackcurrent.vbox-slackcurrent.org "Slackware-current is bound to the characterized VM FQDN"
check_output slackware_current_required_boot_profile grub-direct-generic-no-initrd "Slackware-current keeps the required direct-generic/no-initrd profile"
check_output slackware_current_accepted_kernel 6.18.45 "Slackware-current is bound to the characterized running kernel"
check_output slackware_current_expected_root_device /dev/sda2 "Slackware-current is bound to the characterized root device"
check_output slackware_current_execution_harness_sha256 9f54d2c7d27f46e7d522a8046274d67860a5a59f455e796e467b7f6d23961d62 "Slackware-current execution harness digest is frozen"
check_output slackware_15_hostname vbox-slack15.vbox-slack15.org "Slackware 15.0 remains bound to the accepted VM FQDN"
check_output slackware_15_required_boot_profile elilo-generic-with-initrd "Slackware 15.0 retains the accepted ELILO generic+initrd profile"
check_output slackware_15_accepted_kernel 5.15.209 "Slackware 15.0 retains the accepted running kernel"
check_output slackware_15_execution_harness_sha256 0226e6d48483e0014c699e5affe224bceaa07f8d767673ba30700c7ee21b670c "Slackware 15.0 execution harness digest is frozen"
check_output slackware_15_execution_authorized_now false "Slackware 15.0 execution remains held until current evidence review"
check_output slackware_15_authorization_consumable false "Slackware 15.0 authorization is not consumable before current review"
check_output execution_order slackware-current-then-review-then-slackware-15 "execution order requires current review before Slackware 15.0"
check_output review_each_execution_before_next true "each machine execution requires review before the next"
check_output physical_current_default_authorized false "physical Slackware-current remains fallback-only"
check_output repository_refresh_required false "runtime validation requires no Slackware repository refresh"
check_output slackware_repository_state_dependency false "runtime validation remains independent of repository publication state"
check_output package_mutation_authorized false "package mutation remains unauthorized"
check_output boot_mutation_authorized false "boot mutation remains unauthorized"
check_output source_change_authorized false "source modification remains unauthorized"
check_output machine_action_required false "step 132 itself requires no machine action"
check_output future_machine_action_required true "the next stage requires the bound current VM"
check_output evidence_archive_required_per_execution true "each authorized execution requires an evidence archive"
check_output evidence_copy_directory /home/promano "evidence must be copied directly to /home/promano"
check_output evidence_owner promano "evidence owner remains promano"
check_output evidence_group users "evidence group remains users"
check_output next_stage phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-execution "target binding advances only to the current-VM execution"
check_output pause_safe true "repository-only target binding remains pause-safe"

if python3 - "$binding" "$policy" <<'PY'
import csv
import json
import sys

binding_path, policy_path = sys.argv[1:]
with open(binding_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

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
assert current["status"] == "bound-ready-current-first"
assert slack15["hostname_fqdn"] == "vbox-slack15.vbox-slack15.org"
assert slack15["required_boot_profile"] == "elilo-generic-with-initrd"
assert slack15["accepted_kernel"] == "5.15.209"
assert slack15["execution_harness_sha256"] == "0226e6d48483e0014c699e5affe224bceaa07f8d767673ba30700c7ee21b670c"
assert slack15["execution_authorized"] == "false"
assert slack15["authorization_consumable"] == "false"
assert slack15["status"] == "bound-held-until-current-review"
assert fallback["execution_authorized"] == "false"
assert fallback["machine_execution_limit"] == "0"
assert sum(int(row["machine_execution_limit"]) for row in rows) == 2
assert sum(int(row["reboots_allowed"]) for row in rows) == 0
assert all(row["repository_refresh_allowed"] == "false" for row in rows)
assert all(row["package_mutation_allowed"] == "false" for row in rows)
assert all(row["boot_mutation_allowed"] == "false" for row in rows)

assert policy["binding_only"] is True
assert policy["target_binding_complete"] is True
assert policy["machine_execution_authorized"] is True
assert policy["authorization_consumable"] is True
assert policy["authorization_blocker"] == "none"
assert policy["machine_execution_limit_total"] == 2
assert policy["reboot_limit"] == 0
assert policy["execution_order"] == ["slackware-current", "slackware-15.0"]
assert policy["review_each_execution_before_next"] is True
assert policy["slackware_current"]["hostname_fqdn"] == current["hostname_fqdn"]
assert policy["slackware_current"]["execution_harness_sha256"] == current["execution_harness_sha256"]
assert policy["slackware_current"]["expected_runtime_verdict"] == {
    "boot_mode": "auto",
    "boot_module_state": "available",
    "boot_module_run": 1,
    "boot_preparation_layout": "direct-generic-no-initrd",
    "boot_initrd_available": 0,
    "boot_grub_available": 1,
    "boot_direct_generic_available": 1,
}
assert policy["slackware_15"]["hostname_fqdn"] == slack15["hostname_fqdn"]
assert policy["slackware_15"]["execution_harness_sha256"] == slack15["execution_harness_sha256"]
assert policy["slackware_15"]["execution_authorized"] is False
assert policy["slackware_15"]["authorization_consumable"] is False
assert policy["slackware_15"]["held_until_current_review"] is True
release_gate = policy["slackware_15"]["release_gate"]
assert release_gate["required_review_policy"] == "tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-review-policy.json"
assert release_gate["required_scenario"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-review"
assert all(value is True for key, value in release_gate.items() if key not in {"required_review_policy", "required_scenario"})
assert policy["slackware_15"]["expected_runtime_verdict"]["boot_module_state"] == "unavailable"
assert policy["slackware_15"]["expected_runtime_verdict"]["boot_module_run"] == 0
assert policy["slackware_15"]["expected_runtime_verdict"]["boot_initrd_available"] == 1
assert policy["slackware_15"]["expected_runtime_verdict"]["boot_grub_available"] == 0
assert policy["slackware_15"]["expected_runtime_verdict"]["boot_module_reason"] == "no supported initrd or GRUB preparation path was detected"
assert policy["physical_current_fallback"]["default_authorized"] is False
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
then
    pass "target-binding TSV and policy freeze identical targets, limits, and verdicts"
else
    fail "target-binding TSV and policy freeze identical targets, limits, and verdicts"
fi

if grep -Fq 'vbox-slackcurrent.vbox-slackcurrent.org' "$doc" && grep -Fq 'vbox-slack15.vbox-slack15.org' "$doc"; then
    pass "target-binding document names both frozen VM identities"
else
    fail "target-binding document names both frozen VM identities"
fi
if grep -Fq 'grub-direct-generic-no-initrd' "$doc" && grep -Fq 'UEFI/ELILO' "$doc"; then
    pass "target-binding document preserves both boot-profile boundaries"
else
    fail "target-binding document preserves both boot-profile boundaries"
fi
if grep -Fq 'authorization_consumable=true' "$doc" && grep -Fq 'machine_execution_authorized=true' "$doc"; then
    pass "target-binding document records the post-binding consumable authorization state"
else
    fail "target-binding document records the post-binding consumable authorization state"
fi
if grep -Fq 'Slackware-current VM;' "$doc" && grep -Fq 'evidence review of that single execution;' "$doc" && grep -Fq 'Slackware 15.0 VM;' "$doc"; then
    pass "target-binding document requires current execution review before Slackware 15.0"
else
    fail "target-binding document requires current execution review before Slackware 15.0"
fi
if grep -Fq '/home/promano' "$doc" && grep -Fq 'promano:users' "$doc"; then
    pass "target-binding document preserves the evidence-copy convention"
else
    fail "target-binding document preserves the evidence-copy convention"
fi
doc_flat=$(tr '\n' ' ' < "$doc")
if printf '%s\n' "$doc_flat" | grep -Fq 'physical Slackware-current host remains outside the default authorization'; then
    pass "target-binding document keeps the physical current host outside the default execution path"
else
    fail "target-binding document keeps the physical current host outside the default execution path"
fi
if printf '%s\n' "$doc_flat" | grep -Fq 'Step 132 itself performs no machine execution.'; then
    pass "target-binding document states that step 132 performs no machine execution"
else
    fail "target-binding document states that step 132 performs no machine execution"
fi

if grep -Fq -- '--confirm-current-review-policy-sha256' "$slack15_harness" \
    && grep -Fq 'configuration-module-mode-source-remediation-runtime-validation-slackware-current-review-policy.json' "$slack15_harness" \
    && grep -Fq 'slackware_15_execution_released' "$slack15_harness"; then
    pass "Slackware 15.0 harness enforces the accepted current-review release gate"
else
    fail "Slackware 15.0 harness enforces the accepted current-review release gate"
fi

mutation_pattern='^[[:space:]]*(sudo[[:space:]]+)?(slackpkg|installpkg|upgradepkg|removepkg|mkinitrd|grub-mkconfig|eliloconfig|reboot|shutdown|poweroff)([[:space:]]|$)'
network_pattern='^[[:space:]]*(curl|wget|git[[:space:]]+(clone|fetch|pull)|rsync|scp|ssh)([[:space:]]|$)'
for script in "$helper" "$current_harness" "$slack15_harness"; do
    label=${script##*/}
    if grep -Eq "$mutation_pattern" "$script"; then
        fail "$label contains no package, boot, or shutdown mutation command"
    else
        pass "$label contains no package, boot, or shutdown mutation command"
    fi
    if grep -Eq "$network_pattern" "$script"; then
        fail "$label contains no network client command"
    else
        pass "$label contains no network client command"
    fi
done
for script in "$current_harness" "$slack15_harness"; do
    label=${script##*/}
    if grep -Eq '^[[:space:]]*probe_boot_module([[:space:]]|$)' "$script"; then
        pass "$label invokes only the accepted boot probe entry point"
    else
        fail "$label invokes only the accepted boot probe entry point"
    fi
    if grep -Eq '^[[:space:]]*main([[:space:]]|$)' "$script"; then
        fail "$label does not invoke the normal slack-update main workflow"
    else
        pass "$label does not invoke the normal slack-update main workflow"
    fi
    if grep -Fq 'packages.before.txt' "$script" && grep -Fq 'packages.after.txt' "$script" \
        && grep -Fq 'boot-state.before.txt' "$script" && grep -Fq 'boot-state.after.txt' "$script"; then
        pass "$label captures pre/post package and boot state"
    else
        fail "$label captures pre/post package and boot state"
    fi
    if grep -Fq 'Evidence archive:' "$script" && grep -Fq 'Copy evidence command:' "$script" \
        && grep -Fq '/home/promano/' "$script" && grep -Fq 'promano' "$script" && grep -Fq 'users' "$script"; then
        pass "$label emits the required archive and /home/promano copy instructions"
    else
        fail "$label emits the required archive and /home/promano copy instructions"
    fi
done

printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
(( failures == 0 ))
