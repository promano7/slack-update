#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
freeze="$repo_root/tools/reference/configuration-module-mode-contract-freeze.sh"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract-freeze-policy.json"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
step121_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-boundary-review-policy.json"
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template_file="$repo_root/data/config/slack-update.conf"
doc="$repo_root/docs/reference/configuration-module-mode-contract-freeze.md"

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
check_regular "$step121_policy" "step-121 mode-boundary policy"
check_regular "$contract" "step-122 frozen mode contract"
check_regular "$policy" "step-122 freeze policy"
check_regular "$freeze" "step-122 contract-freeze helper"
check_regular "$doc" "step-122 contract-freeze document"

check_hash "$source_file" "0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6" "reference implementation"
check_hash "$template_file" "4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba" "configuration template"
check_hash "$step121_policy" "a03e299a87596ad66246031c3a47839bac5ab2a869073c43eeae6be0788ebc4e" "step-121 mode-boundary policy"
check_hash "$contract" "f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9" "step-122 frozen mode contract"

if bash -n "$freeze"; then pass "contract-freeze helper is shell-syntax valid"; else fail "contract-freeze helper is shell-syntax valid"; fi
if "$freeze" --help >/dev/null; then pass "contract-freeze helper exposes a non-mutating help boundary"; else fail "contract-freeze helper exposes a non-mutating help boundary"; fi
if "$freeze" --definitely-unknown >/dev/null 2>&1; then fail "unknown options fail closed"; else pass "unknown options fail closed"; fi

if python3 - "$policy" "$contract" <<'PY'
import csv
import hashlib
import json
import sys

policy_path, contract_path = sys.argv[1:]
with open(policy_path, encoding="utf-8") as handle:
    data = json.load(handle)
with open(contract_path, "rb") as handle:
    contract_sha = hashlib.sha256(handle.read()).hexdigest()

assert data["schema"] == 1
assert data["scenario"] == "phase-1-configuration-module-mode-contract-freeze"
assert data["freeze_only"] is True
assert data["accepted_step121_scenario"] == "phase-1-configuration-module-mode-boundary-review"
assert data["accepted_step121_policy_sha256"] == "a03e299a87596ad66246031c3a47839bac5ab2a869073c43eeae6be0788ebc4e"
assert data["source_sha256"] == "0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6"
assert data["template_sha256"] == "4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba"
assert data["contract_sha256"] == contract_sha == "f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9"
assert data["supported_targets"] == ["slackware-15.0", "slackware-current"]
assert data["module_count"] == 5
assert data["mode_count"] == 3
assert data["contract_row_count"] == 15
assert data["mode_values"] == ["enabled", "disabled", "auto"]
assert data["default_mode"] == "auto"
assert data["mode_contract_frozen"] is True
assert data["runtime_behavior_change"] is False
assert data["configuration_template_change"] is False
assert data["source_change_authorized"] is False
assert data["template_change_authorized"] is False
assert data["machine_action_required"] is False
assert data["slackware_repository_state_dependency"] is False
assert data["boot_safety_specialization_preserved"] is True
assert data["next_stage"] == "phase-1-configuration-module-mode-conformance-review"
assert data["pause_safe"] is True

with open(contract_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
assert len(rows) == 15
assert len({(row["module"], row["mode"]) for row in rows}) == 15
assert [row["module"] for row in rows[::3]] == ["flatpak", "sbo", "elf", "boot", "cinnamon"]
for module in ["flatpak", "sbo", "elf", "boot", "cinnamon"]:
    selected = [row for row in rows if row["module"] == module]
    assert [row["mode"] for row in selected] == ["enabled", "disabled", "auto"]
    assert all(row["default_mode"] == "auto" for row in selected)
    enabled, disabled, auto = selected
    assert (enabled["probe_policy"], enabled["run_policy"], enabled["missing_requirements"], enabled["outcome_when_unavailable"]) == ("required", "attempt-when-applicable", "error", "error")
    assert (disabled["probe_policy"], disabled["run_policy"], disabled["missing_requirements"], disabled["outcome_when_unavailable"]) == ("bypassed", "never", "not-evaluated", "disabled")
    assert (auto["probe_policy"], auto["run_policy"], auto["missing_requirements"], auto["outcome_when_unavailable"]) == ("conditional", "when-available-and-applicable", "non-fatal", "skipped-non-fatally")
boot = [row for row in rows if row["module"] == "boot"]
assert boot[0]["applicability_policy"] == "validated-supported-preparation-path-required"
assert boot[1]["applicability_policy"] == "bypassed"
assert boot[2]["applicability_policy"] == "validated-supported-preparation-path-only"
PY
then
    pass "freeze policy and 15-row mode contract are internally consistent"
else
    fail "freeze policy and 15-row mode contract are internally consistent"
fi

source_before=$(sha256sum -- "$source_file" | awk '{print $1}')
template_before=$(sha256sum -- "$template_file" | awk '{print $1}')
step121_before=$(sha256sum -- "$step121_policy" | awk '{print $1}')
contract_before=$(sha256sum -- "$contract" | awk '{print $1}')
output=$(mktemp)
trap 'rm -f -- "$output"' EXIT
if "$freeze" >"$output"; then pass "module-mode contract freeze completed successfully"; else fail "module-mode contract freeze completed successfully"; fi
source_after=$(sha256sum -- "$source_file" | awk '{print $1}')
template_after=$(sha256sum -- "$template_file" | awk '{print $1}')
step121_after=$(sha256sum -- "$step121_policy" | awk '{print $1}')
contract_after=$(sha256sum -- "$contract" | awk '{print $1}')
[[ "$source_before" == "$source_after" ]] && pass "freeze did not modify the reference implementation" || fail "freeze did not modify the reference implementation"
[[ "$template_before" == "$template_after" ]] && pass "freeze did not modify the configuration template" || fail "freeze did not modify the configuration template"
[[ "$step121_before" == "$step121_after" ]] && pass "freeze did not modify the accepted step-121 policy" || fail "freeze did not modify the accepted step-121 policy"
[[ "$contract_before" == "$contract_after" ]] && pass "freeze did not modify its contract input" || fail "freeze did not modify its contract input"

check_output() {
    local key=$1
    local value=$2
    local label=$3
    if grep -Fxq -- "$key"$'\t'"$value" "$output"; then pass "$label"; else fail "$label"; fi
}

check_output schema 1 "freeze output records schema 1"
check_output scenario phase-1-configuration-module-mode-contract-freeze "freeze output records the expected scenario"
check_output module_count 5 "freeze output records exactly five modules"
check_output mode_count 3 "freeze output records exactly three modes"
check_output contract_row_count 15 "freeze output records the complete 15-row matrix"
check_output mode_values enabled,disabled,auto "freeze output preserves the reviewed mode ordering"
check_output default_mode auto "auto remains the compatibility default"
check_output mode_contract_frozen true "mode contract is explicitly frozen"
check_output runtime_behavior_change false "freeze records zero runtime behavior change"
check_output configuration_template_change false "freeze records zero configuration-template change"
check_output source_change_authorized false "freeze does not authorize source changes"
check_output template_change_authorized false "freeze does not authorize template changes"
check_output machine_action_required false "freeze requires no machine action"
check_output slackware_repository_state_dependency false "freeze has no Slackware repository-state dependency"
check_output boot_safety_specialization_preserved true "boot safety specialization remains frozen"
check_output next_stage phase-1-configuration-module-mode-conformance-review "freeze advances only to conformance review"
check_output pause_safe true "repository-only contract freeze remains pause-safe"

if grep -Eq '(^|[^[:alnum:]_])(curl|wget|ftp|rsync|scp|ssh)([^[:alnum:]_]|$)' "$freeze"; then fail "contract-freeze helper contains no network client command"; else pass "contract-freeze helper contains no network client command"; fi
if grep -Eq '(^|[^[:alnum:]_])(slackpkg|upgradepkg|installpkg|removepkg|mkinitrd|grub-mkconfig|eliloconfig)([^[:alnum:]_]|$)' "$freeze"; then fail "contract-freeze helper contains no package or boot mutation command"; else pass "contract-freeze helper contains no package or boot mutation command"; fi
if grep -Eq '^[[:space:]]*(sudo[[:space:]]+)?(reboot|shutdown|poweroff|halt)([[:space:]]|$)' "$freeze"; then fail "contract-freeze helper contains no reboot or shutdown command"; else pass "contract-freeze helper contains no reboot or shutdown command"; fi
if grep -Eq '(^|[;&|[:space:]])(rm|mv|cp|install|ln|sed[[:space:]]+-i|truncate|dd)([[:space:]]|$)' "$freeze"; then fail "contract-freeze helper contains no repository file-mutation command"; else pass "contract-freeze helper contains no repository file-mutation command"; fi

if grep -Fq '`enabled`' "$doc" && grep -Fq '`disabled`' "$doc" && grep -Fq '`auto`' "$doc"; then pass "freeze document names all three activation modes"; else fail "freeze document names all three activation modes"; fi
if grep -Fq '15-row' "$doc" && grep -Fq 'five optional modules' "$doc"; then pass "freeze document describes the complete module-mode matrix"; else fail "freeze document describes the complete module-mode matrix"; fi
if grep -Fq 'Slackware 15.0' "$doc" && grep -Fq 'Slackware-current' "$doc"; then pass "freeze document preserves both mandatory Slackware targets"; else fail "freeze document preserves both mandatory Slackware targets"; fi
if grep -Fq 'phase-1-configuration-module-mode-conformance-review' "$doc"; then pass "freeze document limits continuation to conformance review"; else fail "freeze document limits continuation to conformance review"; fi

if (( failures == 0 )); then
    printf 'Result: %d passes, 0 failures\n' "$passes"
    exit 0
fi
printf 'Result: %d passes, %d failures\n' "$passes" "$failures"
exit 1
