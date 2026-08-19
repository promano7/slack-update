#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
review="$repo_root/tools/reference/configuration-module-mode-boundary-review.sh"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-boundary-review-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-boundary-review.md"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template_file="$repo_root/data/config/slack-update.conf"
step120_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-compatibility-checkpoint-policy.json"
parity_contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-default-parity-contract.tsv"

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
check_regular "$step120_policy" "step-120 compatibility policy"
check_regular "$parity_contract" "step-119 frozen parity contract"
check_regular "$review" "step-121 mode-boundary review helper"
check_regular "$policy" "step-121 mode-boundary policy"
check_regular "$doc" "step-121 mode-boundary review document"

check_hash "$source_file" "0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6" "reference implementation"
check_hash "$template_file" "4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba" "configuration template"
check_hash "$step120_policy" "dbd3ff99948b6f5e3a42ae46f9d0b27f6fe26f41e84069df614b9f23239cf92a" "step-120 compatibility policy"
check_hash "$parity_contract" "2b6f200c4de671356c0ffcf2ab8d10428421b145c32b44a5a6efe8c146f95125" "step-119 frozen parity contract"

if bash -n "$review"; then pass "mode-boundary review helper is shell-syntax valid"; else fail "mode-boundary review helper is shell-syntax valid"; fi
if "$review" --help >/dev/null; then pass "mode-boundary review helper exposes a non-mutating help boundary"; else fail "mode-boundary review helper exposes a non-mutating help boundary"; fi
if "$review" --definitely-unknown >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi

if python3 - "$policy" <<'PY'
import json
import sys
with open(sys.argv[1], encoding="utf-8") as handle:
    data = json.load(handle)
assert data["schema"] == 1
assert data["scenario"] == "phase-1-configuration-module-mode-boundary-review"
assert data["review_only"] is True
assert data["fresh_boundary"] is True
assert data["accepted_step120_pause_safe"] is True
assert data["accepted_step120_future_work_requires_fresh_boundary"] is True
assert data["accepted_step120_next_stage"] == "phase-1-resume-planning"
assert data["accepted_step120_policy_sha256"] == "dbd3ff99948b6f5e3a42ae46f9d0b27f6fe26f41e84069df614b9f23239cf92a"
assert data["source_sha256"] == "0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6"
assert data["template_sha256"] == "4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba"
assert data["parity_contract_sha256"] == "2b6f200c4de671356c0ffcf2ab8d10428421b145c32b44a5a6efe8c146f95125"
assert data["runtime_behavior_change"] is False
assert data["configuration_template_change"] is False
assert data["mode_contract_change"] is False
assert data["supported_targets"] == ["slackware-15.0", "slackware-current"]
assert data["mode_values"] == ["enabled", "disabled", "auto"]
assert data["default_mode"] == "auto"
assert data["mode_semantics"]["enabled"] == {
    "probe_policy": "required",
    "run_policy": "attempt-when-applicable",
    "missing_requirements": "error",
}
assert data["mode_semantics"]["disabled"] == {
    "probe_policy": "bypassed",
    "run_policy": "never",
    "missing_requirements": "not-evaluated",
}
assert data["mode_semantics"]["auto"] == {
    "probe_policy": "conditional",
    "run_policy": "when-available-and-applicable",
    "missing_requirements": "non-fatal",
}
expected = [
    ("flatpak", "CONFIG_FLATPAK_MODE", "flatpak.mode", "auto"),
    ("sbo", "CONFIG_SBO_MODE", "sbo.mode", "auto"),
    ("elf", "CONFIG_ELF_MODE", "elf.mode", "auto"),
    ("boot", "CONFIG_BOOT_MODE", "boot.mode", "auto"),
    ("cinnamon", "CONFIG_CINNAMON_MODE", "cinnamon.mode", "auto"),
]
assert [(m["module"], m["variable"], m["key"], m["default"]) for m in data["reviewed_modules"]] == expected
assert data["boot_auto_specialization"] == "select-validated-supported-preparation-paths"
assert data["disabled_must_not_probe_or_run"] is True
assert data["enabled_missing_requirements_are_errors"] is True
assert data["auto_unavailable_or_irrelevant_is_non_fatal"] is True
assert data["machine_action_required"] is False
assert data["slackware_repository_state_dependency"] is False
assert data["next_stage"] == "phase-1-configuration-module-mode-contract-freeze"
assert data["pause_safe"] is True
PY
then pass "mode-boundary policy is valid and opens the required fresh review boundary"; else fail "mode-boundary policy is valid and opens the required fresh review boundary"; fi

source_before=$(sha256sum -- "$source_file" | awk '{print $1}')
template_before=$(sha256sum -- "$template_file" | awk '{print $1}')
contract_before=$(sha256sum -- "$parity_contract" | awk '{print $1}')
out=$(mktemp)
trap 'rm -f -- "$out"' EXIT
if "$review" >"$out"; then pass "mode-boundary review completed successfully"; else fail "mode-boundary review completed successfully"; fi
source_after=$(sha256sum -- "$source_file" | awk '{print $1}')
template_after=$(sha256sum -- "$template_file" | awk '{print $1}')
contract_after=$(sha256sum -- "$parity_contract" | awk '{print $1}')
[[ "$source_before" == "$source_after" ]] && pass "review did not modify the reference implementation" || fail "review did not modify the reference implementation"
[[ "$template_before" == "$template_after" ]] && pass "review did not modify the configuration template" || fail "review did not modify the configuration template"
[[ "$contract_before" == "$contract_after" ]] && pass "review did not modify the frozen parity contract" || fail "review did not modify the frozen parity contract"

expect_line() {
    local line=$1
    local label=$2
    if grep -Fqx -- "$line" "$out"; then pass "$label"; else fail "$label"; fi
}

expect_line $'schema\t1' "review output records schema 1"
expect_line $'scenario\tphase-1-configuration-module-mode-boundary-review' "review output records the expected scenario"
expect_line $'fresh_boundary\ttrue' "review opens a fresh boundary after step 120"
expect_line $'runtime_behavior_change\tfalse' "review records zero runtime behavior change"
expect_line $'configuration_template_change\tfalse' "review records zero configuration-template change"
expect_line $'mode_contract_change\tfalse' "review records zero mode-contract change"
expect_line $'machine_action_required\tfalse' "review requires no machine action"
expect_line $'slackware_repository_state_dependency\tfalse' "review has no Slackware repository-state dependency"
expect_line $'supported_targets\tslackware-15.0,slackware-current' "both mandatory Slackware targets remain in scope"
expect_line $'mode_values\tenabled,disabled,auto' "exactly the three reviewed activation modes are recorded"
expect_line $'default_mode\tauto' "auto remains the compatibility default"
expect_line $'module_count\t5' "exactly five optional modules are reviewed"
expect_line $'enabled\trequired\tattempt_when_applicable\terror' "enabled mode retains strict requirement behavior"
expect_line $'disabled\tbypassed\tnever\tnot-evaluated' "disabled mode bypasses probing and execution"
expect_line $'auto\tconditional\twhen_available_and_applicable\tnon-fatal' "auto mode remains conditional and non-fatal when unavailable"
expect_line $'next_stage\tphase-1-configuration-module-mode-contract-freeze' "review advances only to the module-mode contract freeze"
expect_line $'pause_safe\ttrue' "repository-only mode review remains pause-safe"

if python3 - "$out" <<'PY'
import csv
import sys

lines = open(sys.argv[1], encoding="utf-8").read().splitlines()
separators = [i for i, line in enumerate(lines) if line == "---"]
assert len(separators) == 3
module_lines = lines[separators[1] + 2:separators[2]]
rows = list(csv.reader(module_lines, delimiter="\t"))
assert len(rows) == 5
expected = [
    ("flatpak", "CONFIG_FLATPAK_MODE", "flatpak.mode", "auto"),
    ("sbo", "CONFIG_SBO_MODE", "sbo.mode", "auto"),
    ("elf", "CONFIG_ELF_MODE", "elf.mode", "auto"),
    ("boot", "CONFIG_BOOT_MODE", "boot.mode", "auto"),
    ("cinnamon", "CONFIG_CINNAMON_MODE", "cinnamon.mode", "auto"),
]
for row, prefix in zip(rows, expected):
    assert tuple(row[:4]) == prefix
    assert len(row) == 9
    assert all(value.isdigit() and int(value) > 0 for value in row[4:])
PY
then pass "all five module rows bind their reviewed configuration and source landmarks"; else fail "all five module rows bind their reviewed configuration and source landmarks"; fi

marker_count=$(awk -F '\t' '$1 == "disabled_marker_count" {print $2}' "$out")
if [[ "$marker_count" == "5" ]]; then pass "exactly five disabled-by-configuration reason markers are present"; else fail "exactly five disabled-by-configuration reason markers are present"; fi

if grep -Eq '(^|[^A-Za-z])(rm|mv|cp|install)[[:space:]]' "$review"; then
    fail "review helper contains no repository file-mutation command"
else
    pass "review helper contains no repository file-mutation command"
fi
if grep -Eq 'slackpkg[[:space:]]|mkinitrd[[:space:]]+-F|grub-mkconfig[[:space:]]+-o' "$review"; then fail "review helper contains no package or boot mutation command"; else pass "review helper contains no package or boot mutation command"; fi
if grep -Eq '(^|[^A-Za-z])(curl|wget|git[[:space:]]+(fetch|pull|clone))[[:space:]]' "$review"; then fail "review helper contains no network client command"; else pass "review helper contains no network client command"; fi
if grep -Eq '(^|[^A-Za-z])(reboot|shutdown|poweroff|halt)[[:space:]]' "$review"; then fail "review helper contains no reboot or shutdown command"; else pass "review helper contains no reboot or shutdown command"; fi

if grep -Fq '`enabled`' "$doc" && grep -Fq '`disabled`' "$doc" && grep -Fq '`auto`' "$doc"; then pass "review document names all three activation modes"; else fail "review document names all three activation modes"; fi
if grep -Fq 'Slackware 15.0' "$doc" && grep -Fq 'Slackware-current' "$doc"; then pass "review document preserves both mandatory Slackware targets"; else fail "review document preserves both mandatory Slackware targets"; fi
if grep -Fq 'phase-1-configuration-module-mode-contract-freeze' "$doc"; then pass "review document limits continuation to the contract-freeze stage"; else fail "review document limits continuation to the contract-freeze stage"; fi

if (( failures == 0 )); then
    printf 'Result: %d passes, 0 failures\n' "$passes"
    exit 0
fi
printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
exit 1
