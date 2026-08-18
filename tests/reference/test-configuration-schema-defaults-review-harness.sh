#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template_file="$repo_root/data/config/slack-update.conf"
inventory="$repo_root/tools/reference/configuration-schema-inventory.sh"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-schema-defaults-review-policy.json"
step117_inventory="$repo_root/tools/reference/configuration-boundary-inventory.sh"
step117_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-boundary-review-policy.json"
step117_harness="$repo_root/tests/reference/test-configuration-boundary-review-harness.sh"
step117_doc="$repo_root/docs/reference/configuration-boundary-review.md"

passes=0
failures=0

pass() { printf 'PASS: %s\n' "$1"; passes=$((passes + 1)); }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

check_regular() {
    local file=$1 label=$2
    if [[ -f "$file" && ! -L "$file" ]]; then pass "$label is a regular non-symlink file"; else fail "$label is a regular non-symlink file"; fi
}

check_hash() {
    local file=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    if [[ "$actual" == "$expected" ]]; then pass "$label has the exact reviewed SHA-256"; else fail "$label has the exact reviewed SHA-256"; fi
}

check_regular "$source_file" "reference implementation"
check_regular "$template_file" "configuration template"
check_regular "$inventory" "schema inventory helper"
check_regular "$policy" "schema/defaults policy"
check_regular "$step117_inventory" "step-117 boundary inventory"
check_regular "$step117_policy" "step-117 boundary policy"
check_regular "$step117_harness" "step-117 boundary harness"
check_regular "$step117_doc" "step-117 boundary review"

check_hash "$source_file" "0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6" "reference implementation"
check_hash "$step117_inventory" "4582d37c3b765b253c816b4fcbd8f05a69e67382907882ccdd73cc28d0a60fbe" "step-117 boundary inventory"
check_hash "$step117_policy" "8e5ffa31c3925190fad53b391e34596eb1aec1acb45df69885d4c823d4dbc9ec" "step-117 boundary policy"
check_hash "$step117_harness" "0641c9aee41cb1a78fe232c9bf9f4bf974ee6bc070b70b61075769c8b496c479" "step-117 boundary harness"
check_hash "$step117_doc" "afdf520b1bff550184863903b451a89b42fbf3f38afe3178c48b408d201e8abd" "step-117 boundary review"

if bash -n "$inventory"; then pass "schema inventory helper is shell-syntax valid"; else fail "schema inventory helper is shell-syntax valid"; fi
if "$inventory" --help >/dev/null; then pass "schema inventory helper exposes a non-mutating help boundary"; else fail "schema inventory helper exposes a non-mutating help boundary"; fi
if "$inventory" --definitely-unknown >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi

if python3 - "$policy" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
assert data['schema'] == 1
assert data['scenario'] == 'phase-1-configuration-schema-defaults-review'
assert data['review_only'] is True
assert data['runtime_behavior_change'] is False
assert data['configuration_file_created'] is False
assert data['existing_configuration_surface'] is True
assert data['expected_config_variable_count'] == 35
assert data['configuration_source_variables'] == ['CONFIG_FILE']
assert data['module_mode_migration_deferred'] is True
assert data['next_stage'] == 'phase-1-configuration-default-parity-freeze'
assert data['schema_control_variables'] == ['CONFIG_SCHEMA_VERSION']
assert data['deferred_module_mode_variables'] == [
    'CONFIG_FLATPAK_MODE', 'CONFIG_SBO_MODE', 'CONFIG_ELF_MODE',
    'CONFIG_BOOT_MODE', 'CONFIG_CINNAMON_MODE'
]
PY
then pass "schema/defaults policy is valid and review-only"; else fail "schema/defaults policy is valid and review-only"; fi

source_before=$(sha256sum -- "$source_file" | awk '{print $1}')
template_before=$(sha256sum -- "$template_file" | awk '{print $1}')
out=$(mktemp)
trap 'rm -f -- "$out"' EXIT
if "$inventory" >"$out"; then pass "schema inventory completed successfully"; else fail "schema inventory completed successfully"; fi
source_after=$(sha256sum -- "$source_file" | awk '{print $1}')
template_after=$(sha256sum -- "$template_file" | awk '{print $1}')
[[ "$source_before" == "$source_after" ]] && pass "schema inventory did not modify the reference implementation" || fail "schema inventory did not modify the reference implementation"
[[ "$template_before" == "$template_after" ]] && pass "schema inventory did not modify the configuration template" || fail "schema inventory did not modify the configuration template"

grep -Fqx $'schema\t1' "$out" && pass "inventory schema is recorded" || fail "inventory schema is recorded"
grep -Fqx $'scenario\tphase-1-configuration-schema-defaults-review' "$out" && pass "inventory scenario is recorded" || fail "inventory scenario is recorded"
grep -Fqx $'runtime_behavior_change\tfalse' "$out" && pass "inventory records zero runtime behavior change" || fail "inventory records zero runtime behavior change"
grep -Fqx $'configuration_file_created\tfalse' "$out" && pass "inventory records that no configuration file was created" || fail "inventory records that no configuration file was created"
grep -Fqx $'existing_configuration_surface\ttrue' "$out" && pass "inventory recognizes the existing configuration surface" || fail "inventory recognizes the existing configuration surface"
grep -Fqx $'module_mode_migration_deferred\ttrue' "$out" && pass "inventory keeps module-mode migration deferred" || fail "inventory keeps module-mode migration deferred"

bootstrap_count=$(awk -F '\t' '$1=="bootstrap" {n++} END {print n+0}' "$out")
unique_count=$(awk -F '\t' '$1=="bootstrap" {print $3}' "$out" | LC_ALL=C sort -u | wc -l)
[[ "$bootstrap_count" -eq 35 ]] && pass "exactly 35 distinct CONFIG_* variables are inventoried" || fail "exactly 35 distinct CONFIG_* variables are inventoried"
[[ "$unique_count" -eq 35 ]] && pass "all CONFIG_* variable names are unique" || fail "all CONFIG_* variable names are unique"

source_count=$(awk -F '\t' '$1=="bootstrap" && $4=="configuration-source" {n++} END {print n+0}' "$out")
schema_count=$(awk -F '\t' '$1=="bootstrap" && $4=="schema-control" {n++} END {print n+0}' "$out")
deferred_count=$(awk -F '\t' '$1=="bootstrap" && $4=="deferred-module-mode" {n++} END {print n+0}' "$out")
surface_count=$(awk -F '\t' '$1=="bootstrap" && $4=="existing-config-surface" {n++} END {print n+0}' "$out")
[[ "$source_count" -eq 1 ]] && pass "exactly one configuration-source variable is classified" || fail "exactly one configuration-source variable is classified"
[[ "$schema_count" -eq 1 ]] && pass "exactly one schema-control variable is classified" || fail "exactly one schema-control variable is classified"
[[ "$deferred_count" -eq 5 ]] && pass "exactly five module-mode variables remain deferred" || fail "exactly five module-mode variables remain deferred"
[[ "$surface_count" -eq 28 ]] && pass "the remaining 28 bootstrap variables are existing configuration surface" || fail "the remaining 28 bootstrap variables are existing configuration surface"

for name in CONFIG_FLATPAK_MODE CONFIG_SBO_MODE CONFIG_ELF_MODE CONFIG_BOOT_MODE CONFIG_CINNAMON_MODE; do
    if awk -F '\t' -v n="$name" '$1=="bootstrap" && $3==n && $4=="deferred-module-mode" {found=1} END {exit !found}' "$out"; then
        pass "$name remains deferred to the later module-mode boundary"
    else
        fail "$name remains deferred to the later module-mode boundary"
    fi
done

check_initializer() {
    local name=$1 expected=$2
    if awk -F '\t' -v n="$name" -v e="$expected" '$1=="bootstrap" && $3==n && $5==e {found=1} END {exit !found}' "$out"; then
        pass "$name bootstrap initializer matches the reviewed value"
    else
        fail "$name bootstrap initializer matches the reviewed value"
    fi
}
check_initializer CONFIG_FLATPAK_MODE auto
check_initializer CONFIG_SBO_MODE auto
check_initializer CONFIG_SBO_OPTIONS_FILE /etc/slack-update/sbo-options.sqf
check_initializer CONFIG_ELF_MODE auto
check_initializer CONFIG_BOOT_MODE auto
check_initializer CONFIG_INITRD_KERNEL_PACKAGE kernel-generic
check_initializer CONFIG_KERNEL_MODULES_DIRECTORY /lib/modules
check_initializer CONFIG_CINNAMON_MODE auto

template_key_count=$(awk -F '\\t' '$1=="template-key" {n++} END {print n+0}' "$out")
if (( template_key_count > 0 )); then pass "the real configuration template exposes at least one section/key value"; else fail "the real configuration template exposes at least one section/key value"; fi
if grep -Fq '/etc/slack-update/slack-update.conf' "$source_file"; then pass "the reference implementation retains the reviewed system configuration path"; else fail "the reference implementation retains the reviewed system configuration path"; fi

if grep -Eq '(^|[^A-Za-z])(rm|mv|cp|install)[[:space:]]' "$inventory"; then fail "inventory helper contains no file-mutation command"; else pass "inventory helper contains no file-mutation command"; fi
if grep -Eq 'slackpkg[[:space:]]|mkinitrd[[:space:]]+-F|grub-mkconfig[[:space:]]+-o' "$inventory"; then fail "inventory helper contains no package or boot mutation command"; else pass "inventory helper contains no package or boot mutation command"; fi
if grep -Eq '(^|[^A-Za-z])(curl|wget|git[[:space:]]+(fetch|pull|clone))[[:space:]]' "$inventory"; then fail "inventory helper contains no network client command"; else pass "inventory helper contains no network client command"; fi

if (( failures == 0 )); then
    printf 'Result: %d passes, 0 failures\n' "$passes"
    exit 0
fi
printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
exit 1
