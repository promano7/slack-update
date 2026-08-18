#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template_file="$repo_root/data/config/slack-update.conf"
checkpoint="$repo_root/tools/reference/configuration-compatibility-checkpoint.sh"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-compatibility-checkpoint-policy.json"
doc="$repo_root/docs/reference/configuration-compatibility-checkpoint.md"
step119_check="$repo_root/tools/reference/configuration-default-parity-check.sh"
step119_contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-default-parity-contract.tsv"
step119_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-default-parity-freeze-policy.json"
step119_harness="$repo_root/tests/reference/test-configuration-default-parity-freeze-harness.sh"
step119_doc="$repo_root/docs/reference/configuration-default-parity-freeze.md"

passes=0
failures=0
pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

check_regular() {
    local file=$1
    local label=$2
    if [[ -f "$file" && ! -L "$file" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi
}

check_hash() {
    local file=$1
    local expected=$2
    local label=$3
    local actual
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi
}

check_regular "$source_file" "reference implementation"
check_regular "$template_file" "configuration template"
check_regular "$checkpoint" "compatibility checkpoint"
check_regular "$policy" "compatibility-checkpoint policy"
check_regular "$doc" "compatibility-checkpoint review"
check_regular "$step119_check" "step-119 parity checker"
check_regular "$step119_contract" "step-119 parity contract"
check_regular "$step119_policy" "step-119 parity policy"
check_regular "$step119_harness" "step-119 parity harness"
check_regular "$step119_doc" "step-119 parity review"

check_hash "$source_file" "0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6" "reference implementation"
check_hash "$template_file" "4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba" "configuration template"
check_hash "$step119_check" "39b4e7cd7ceb94de76b5329d00291c1d9921419e3bfa5578103eeceb1af22bc4" "step-119 parity checker"
check_hash "$step119_contract" "2b6f200c4de671356c0ffcf2ab8d10428421b145c32b44a5a6efe8c146f95125" "step-119 parity contract"
check_hash "$step119_policy" "baa3e642aa042640da528aca1a22052121aa4e07b4e968e027c2ba69e9d7bec8" "step-119 parity policy"
check_hash "$step119_harness" "f44560b64892d84af5930ff032d6aaa46a3f72c957a455873b091964c0e507ad" "step-119 parity harness"
check_hash "$step119_doc" "700fea95125f34043d9b2bd4fb159a84bbdda6347042e24463822ef3c7dc847c" "step-119 parity review"

if bash -n "$checkpoint"; then pass "compatibility checkpoint is shell-syntax valid"; else fail "compatibility checkpoint is shell-syntax valid"; fi
if "$checkpoint" --help >/dev/null; then pass "compatibility checkpoint exposes a non-mutating help boundary"; else fail "compatibility checkpoint exposes a non-mutating help boundary"; fi
if "$checkpoint" --definitely-unknown >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi

if python3 - "$policy" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
assert data['schema'] == 1
assert data['scenario'] == 'phase-1-configuration-compatibility-checkpoint'
assert data['checkpoint_only'] is True
assert data['runtime_behavior_change'] is False
assert data['source_sha256'] == '0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6'
assert data['template_sha256'] == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
assert data['step119_parity_check_sha256'] == '39b4e7cd7ceb94de76b5329d00291c1d9921419e3bfa5578103eeceb1af22bc4'
assert data['step119_contract_sha256'] == '2b6f200c4de671356c0ffcf2ab8d10428421b145c32b44a5a6efe8c146f95125'
assert data['step119_policy_sha256'] == 'baa3e642aa042640da528aca1a22052121aa4e07b4e968e027c2ba69e9d7bec8'
assert data['step119_harness_sha256'] == 'f44560b64892d84af5930ff032d6aaa46a3f72c957a455873b091964c0e507ad'
assert data['step119_review_sha256'] == '700fea95125f34043d9b2bd4fb159a84bbdda6347042e24463822ef3c7dc847c'
assert data['parity_rows'] == 34
assert data['schema_control_rows'] == 1
assert data['existing_configuration_rows'] == 28
assert data['deferred_module_mode_rows'] == 5
assert data['bootstrap_template_overlap_rows'] == 8
assert data['configuration_source_variable'] == 'CONFIG_FILE'
assert data['configuration_source_is_template_key'] is False
assert data['compatibility_scope'] == 'configuration-surface-only'
assert data['supported_targets'] == ['slackware-15.0', 'slackware-current']
assert data['configuration_surface_compatibility_preserved'] is True
assert data['runtime_machine_revalidation_required'] is False
assert data['slackware_repository_state_dependency'] is False
assert data['module_mode_migration_deferred'] is True
assert data['pending_configuration_action'] is False
assert data['machine_action_required'] is False
assert data['future_work_requires_fresh_boundary'] is True
assert data['pause_safe'] is True
assert data['next_stage'] == 'phase-1-resume-planning'
PY
then pass "compatibility-checkpoint policy is valid and closes a repository-only boundary"; else fail "compatibility-checkpoint policy is valid and closes a repository-only boundary"; fi

source_before=$(sha256sum -- "$source_file" | awk '{print $1}')
template_before=$(sha256sum -- "$template_file" | awk '{print $1}')
contract_before=$(sha256sum -- "$step119_contract" | awk '{print $1}')
out=$(mktemp)
trap 'rm -f -- "$out"' EXIT
if "$checkpoint" >"$out"; then pass "compatibility checkpoint completed successfully"; else fail "compatibility checkpoint completed successfully"; fi
source_after=$(sha256sum -- "$source_file" | awk '{print $1}')
template_after=$(sha256sum -- "$template_file" | awk '{print $1}')
contract_after=$(sha256sum -- "$step119_contract" | awk '{print $1}')
[[ "$source_before" == "$source_after" ]] && pass "checkpoint did not modify the reference implementation" || fail "checkpoint did not modify the reference implementation"
[[ "$template_before" == "$template_after" ]] && pass "checkpoint did not modify the configuration template" || fail "checkpoint did not modify the configuration template"
[[ "$contract_before" == "$contract_after" ]] && pass "checkpoint did not modify the frozen parity contract" || fail "checkpoint did not modify the frozen parity contract"

expect_line() {
    local line=$1
    local label=$2
    if grep -Fqx -- "$line" "$out"; then pass "$label"; else fail "$label"; fi
}

expect_line $'schema\t1' "checkpoint output records schema 1"
expect_line $'scenario\tphase-1-configuration-compatibility-checkpoint' "checkpoint output records the expected scenario"
expect_line $'runtime_behavior_change\tfalse' "checkpoint records zero runtime behavior change"
expect_line $'default_parity_frozen\ttrue' "checkpoint preserves frozen default parity"
expect_line $'configuration_surface_compatibility_preserved\ttrue' "checkpoint preserves the common configuration surface"
expect_line $'compatibility_scope\tconfiguration-surface-only' "checkpoint limits the compatibility claim to the reviewed configuration surface"
expect_line $'slackware_15_0_target_preserved\ttrue' "Slackware 15.0 remains a preserved configuration target"
expect_line $'slackware_current_target_preserved\ttrue' "Slackware-current remains a preserved configuration target"
expect_line $'runtime_machine_revalidation_required\tfalse' "checkpoint requires no runtime machine revalidation"
expect_line $'slackware_repository_state_dependency\tfalse' "checkpoint has no Slackware repository-state dependency"
expect_line $'module_mode_migration_deferred\ttrue' "module-mode migration remains deferred"
expect_line $'pending_configuration_action\tfalse' "checkpoint leaves no pending configuration action"
expect_line $'machine_action_required\tfalse' "checkpoint requires no machine action"
expect_line $'future_work_requires_fresh_boundary\ttrue' "future work requires a fresh review boundary"
expect_line $'pause_safe\ttrue' "checkpoint establishes a safe pause"
expect_line $'next_stage\tphase-1-resume-planning' "checkpoint returns only to Phase 1 resume planning"

if grep -Ev '^trap .*rm -f -- .*parity_output.* EXIT$' "$checkpoint" | grep -Eq '(^|[^A-Za-z])(rm|mv|cp|install)[[:space:]]'; then
    fail "checkpoint source contains no repository file-mutation command"
else
    pass "checkpoint source contains no repository file-mutation command"
fi
if grep -Eq 'slackpkg[[:space:]]|mkinitrd[[:space:]]+-F|grub-mkconfig[[:space:]]+-o' "$checkpoint"; then fail "checkpoint source contains no package or boot mutation command"; else pass "checkpoint source contains no package or boot mutation command"; fi
if grep -Eq '(^|[^A-Za-z])(curl|wget|git[[:space:]]+(fetch|pull|clone))[[:space:]]' "$checkpoint"; then fail "checkpoint source contains no network client command"; else pass "checkpoint source contains no network client command"; fi
if grep -Eq '(^|[^A-Za-z])(reboot|shutdown|poweroff|halt)[[:space:]]' "$checkpoint"; then fail "checkpoint source contains no reboot or shutdown command"; else pass "checkpoint source contains no reboot or shutdown command"; fi

if grep -Fq 'enabled`/`disabled`/`auto`' "$doc" && grep -Fq 'remains deferred' "$doc"; then pass "checkpoint documentation keeps the module-mode boundary deferred"; else fail "checkpoint documentation keeps the module-mode boundary deferred"; fi
if grep -Fq 'configuration-surface' "$doc" && grep -Fq 'does not claim' "$doc"; then pass "checkpoint documentation limits its compatibility claim"; else fail "checkpoint documentation limits its compatibility claim"; fi

if (( failures == 0 )); then
    printf 'Result: %d passes, 0 failures\n' "$passes"
    exit 0
fi
printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
exit 1
