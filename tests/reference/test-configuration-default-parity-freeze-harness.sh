#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template_file="$repo_root/data/config/slack-update.conf"
parity_check="$repo_root/tools/reference/configuration-default-parity-check.sh"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-default-parity-contract.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-default-parity-freeze-policy.json"
doc="$repo_root/docs/reference/configuration-default-parity-freeze.md"
step118_inventory="$repo_root/tools/reference/configuration-schema-inventory.sh"
step118_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-schema-defaults-review-policy.json"
step118_harness="$repo_root/tests/reference/test-configuration-schema-defaults-review-harness.sh"
step118_doc="$repo_root/docs/reference/configuration-schema-defaults-review.md"

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
check_regular "$parity_check" "default-parity checker"
check_regular "$contract" "default-parity contract"
check_regular "$policy" "default-parity policy"
check_regular "$doc" "default-parity review"
check_regular "$step118_inventory" "step-118 schema inventory"
check_regular "$step118_policy" "step-118 schema/defaults policy"
check_regular "$step118_harness" "step-118 schema/defaults harness"
check_regular "$step118_doc" "step-118 schema/defaults review"

check_hash "$source_file" "0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6" "reference implementation"
check_hash "$template_file" "4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba" "configuration template"
check_hash "$parity_check" "39b4e7cd7ceb94de76b5329d00291c1d9921419e3bfa5578103eeceb1af22bc4" "default-parity checker"
check_hash "$contract" "2b6f200c4de671356c0ffcf2ab8d10428421b145c32b44a5a6efe8c146f95125" "default-parity contract"
check_hash "$policy" "baa3e642aa042640da528aca1a22052121aa4e07b4e968e027c2ba69e9d7bec8" "default-parity policy"
check_hash "$doc" "700fea95125f34043d9b2bd4fb159a84bbdda6347042e24463822ef3c7dc847c" "default-parity review"
check_hash "$step118_inventory" "5592f4f20c71b368169471bb1d680ce58a8ad956cf8462fd035b0c912efdcec6" "step-118 schema inventory"
check_hash "$step118_policy" "1191b0e531ed13d52c43f8e1df49703dd8343d23b9e33329d476f26f2aa25b9b" "step-118 schema/defaults policy"
check_hash "$step118_harness" "094ab645428518ba752ea3d79f73e09846912a6982c7b0045d35d0908b6328d4" "step-118 schema/defaults harness"
check_hash "$step118_doc" "4ed03ebd74b27c42210235f5f93e0f55811e34741d7d7fac39f0fe0512debb4e" "step-118 schema/defaults review"

if bash -n "$parity_check"; then pass "default-parity checker is shell-syntax valid"; else fail "default-parity checker is shell-syntax valid"; fi
if "$parity_check" --help >/dev/null; then pass "default-parity checker exposes a non-mutating help boundary"; else fail "default-parity checker exposes a non-mutating help boundary"; fi
if "$parity_check" --definitely-unknown >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi

if python3 - "$policy" <<'PY'
import json, sys
with open(sys.argv[1], encoding='utf-8') as f:
    data = json.load(f)
assert data['schema'] == 1
assert data['scenario'] == 'phase-1-configuration-default-parity-freeze'
assert data['review_only'] is True
assert data['runtime_behavior_change'] is False
assert data['default_parity_frozen'] is True
assert data['source_sha256'] == '0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6'
assert data['template_sha256'] == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
assert data['contract_sha256'] == '2b6f200c4de671356c0ffcf2ab8d10428421b145c32b44a5a6efe8c146f95125'
assert data['expected_contract_rows'] == 34
assert data['schema_control_rows'] == 1
assert data['existing_config_surface_rows'] == 28
assert data['deferred_module_mode_rows'] == 5
assert data['bootstrap_template_overlap_rows'] == 8
assert data['configuration_source_variable'] == 'CONFIG_FILE'
assert data['configuration_source_is_template_key'] is False
assert data['machine_action_required'] is False
assert data['slackware_repository_state_dependency'] is False
assert data['module_mode_migration_deferred'] is True
assert data['next_stage'] == 'phase-1-configuration-compatibility-checkpoint'
PY
then pass "default-parity policy is valid and repository-only"; else fail "default-parity policy is valid and repository-only"; fi

rows=$(awk -F '\t' 'NR>1 {n++} END {print n+0}' "$contract")
vars=$(awk -F '\t' 'NR>1 {print $1}' "$contract" | LC_ALL=C sort -u | wc -l)
keys=$(awk -F '\t' 'NR>1 {print $2}' "$contract" | LC_ALL=C sort -u | wc -l)
schema_rows=$(awk -F '\t' 'NR>1 && $3=="schema-control" {n++} END {print n+0}' "$contract")
surface_rows=$(awk -F '\t' 'NR>1 && $3=="existing-config-surface" {n++} END {print n+0}' "$contract")
deferred_rows=$(awk -F '\t' 'NR>1 && $3=="deferred-module-mode" {n++} END {print n+0}' "$contract")
overlap_rows=$(awk -F '\t' 'NR>1 && $4!="<empty>" {n++} END {print n+0}' "$contract")
[[ "$rows" -eq 34 ]] && pass "default-parity contract contains exactly 34 rows" || fail "default-parity contract contains exactly 34 rows"
[[ "$vars" -eq 34 ]] && pass "default-parity contract variables are unique" || fail "default-parity contract variables are unique"
[[ "$keys" -eq 34 ]] && pass "default-parity contract keys are unique" || fail "default-parity contract keys are unique"
[[ "$schema_rows" -eq 1 ]] && pass "contract contains exactly one schema-control row" || fail "contract contains exactly one schema-control row"
[[ "$surface_rows" -eq 28 ]] && pass "contract contains exactly 28 existing configuration rows" || fail "contract contains exactly 28 existing configuration rows"
[[ "$deferred_rows" -eq 5 ]] && pass "contract keeps exactly five module modes deferred" || fail "contract keeps exactly five module modes deferred"
[[ "$overlap_rows" -eq 8 ]] && pass "contract records exactly eight bootstrap/template overlaps" || fail "contract records exactly eight bootstrap/template overlaps"

if awk -F '\t' 'NR>1 && $1=="CONFIG_FILE" {bad=1} END {exit bad}' "$contract"; then pass "CONFIG_FILE is excluded from template-key parity"; else fail "CONFIG_FILE is excluded from template-key parity"; fi

for name in CONFIG_FLATPAK_MODE CONFIG_SBO_MODE CONFIG_ELF_MODE CONFIG_BOOT_MODE CONFIG_CINNAMON_MODE; do
    if awk -F '\t' -v n="$name" 'NR>1 && $1==n && $3=="deferred-module-mode" && $4=="auto" && $5=="auto" {ok=1} END {exit !ok}' "$contract"; then
        pass "$name remains deferred with bootstrap/template auto parity"
    else
        fail "$name remains deferred with bootstrap/template auto parity"
    fi
done

check_overlap() {
    local variable=$1 expected=$2
    if awk -F '\t' -v n="$variable" -v e="$expected" 'NR>1 && $1==n && $4==e && $5==e {ok=1} END {exit !ok}' "$contract"; then
        pass "$variable bootstrap/template overlap is value-identical"
    else
        fail "$variable bootstrap/template overlap is value-identical"
    fi
}
check_overlap CONFIG_SBO_OPTIONS_FILE /etc/slack-update/sbo-options.sqf
check_overlap CONFIG_INITRD_KERNEL_PACKAGE kernel-generic
check_overlap CONFIG_KERNEL_MODULES_DIRECTORY /lib/modules

source_before=$(sha256sum -- "$source_file" | awk '{print $1}')
template_before=$(sha256sum -- "$template_file" | awk '{print $1}')
out=$(mktemp)
trap 'rm -f -- "$out"' EXIT
if "$parity_check" >"$out"; then pass "default-parity checker completed successfully"; else fail "default-parity checker completed successfully"; fi
source_after=$(sha256sum -- "$source_file" | awk '{print $1}')
template_after=$(sha256sum -- "$template_file" | awk '{print $1}')
[[ "$source_before" == "$source_after" ]] && pass "parity check did not modify the reference implementation" || fail "parity check did not modify the reference implementation"
[[ "$template_before" == "$template_after" ]] && pass "parity check did not modify the configuration template" || fail "parity check did not modify the configuration template"

grep -Fqx $'schema\t1' "$out" && pass "parity output records schema 1" || fail "parity output records schema 1"
grep -Fqx $'scenario\tphase-1-configuration-default-parity-freeze' "$out" && pass "parity output records the expected scenario" || fail "parity output records the expected scenario"
grep -Fqx $'runtime_behavior_change\tfalse' "$out" && pass "parity output records zero runtime behavior change" || fail "parity output records zero runtime behavior change"
grep -Fqx $'default_parity_frozen\ttrue' "$out" && pass "parity output freezes the reviewed defaults" || fail "parity output freezes the reviewed defaults"
grep -Fqx $'module_mode_migration_deferred\ttrue' "$out" && pass "parity output keeps module-mode migration deferred" || fail "parity output keeps module-mode migration deferred"
grep -Fqx $'parity_rows\t34' "$out" && pass "parity output covers all 34 template rows" || fail "parity output covers all 34 template rows"
grep -Fqx $'deferred_module_mode_rows\t5' "$out" && pass "parity output records five deferred module-mode rows" || fail "parity output records five deferred module-mode rows"
grep -Fqx $'bootstrap_template_overlap_rows\t8' "$out" && pass "parity output records eight bootstrap/template overlaps" || fail "parity output records eight bootstrap/template overlaps"
grep -Fqx $'configuration_source_is_not_template_key\ttrue' "$out" && pass "parity output keeps CONFIG_FILE outside template-key parity" || fail "parity output keeps CONFIG_FILE outside template-key parity"
grep -Fqx $'parity_status\taccepted' "$out" && pass "parity output accepts the frozen mapping" || fail "parity output accepts the frozen mapping"

if grep -Ev '^trap .*rm -f -- .*inventory_out.* EXIT$' "$parity_check" | grep -Eq '(^|[^A-Za-z])(rm|mv|cp|install)[[:space:]]'; then
    fail "parity checker contains no repository file-mutation command"
else
    pass "parity checker contains no repository file-mutation command"
fi
if grep -Eq 'slackpkg[[:space:]]|mkinitrd[[:space:]]+-F|grub-mkconfig[[:space:]]+-o' "$parity_check"; then fail "parity checker contains no package or boot mutation command"; else pass "parity checker contains no package or boot mutation command"; fi
if grep -Eq '(^|[^A-Za-z])(curl|wget|git[[:space:]]+(fetch|pull|clone))[[:space:]]' "$parity_check"; then fail "parity checker contains no network client command"; else pass "parity checker contains no network client command"; fi

if (( failures == 0 )); then
    printf 'Result: %d passes, 0 failures\n' "$passes"
    exit 0
fi
printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
exit 1
