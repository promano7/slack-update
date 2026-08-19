#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-contract-freeze.sh [--help]

Freeze the reviewed enabled/disabled/auto compatibility contract for the five
optional modules after the accepted step-121 boundary review.

This command is repository-local and read-only. It validates exact upstream
hashes and the frozen TSV contract, then emits a deterministic summary. It does
not modify configuration, execute the update workflow, access the network, or
perform package, boot, module, reboot, or shutdown actions.
USAGE
}

if (( $# > 1 )); then
    printf 'error: unexpected arguments\n' >&2
    exit 2
fi
if (( $# == 1 )); then
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'error: unknown option: %s\n' "$1" >&2
            exit 2
            ;;
    esac
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template_file="$repo_root/data/config/slack-update.conf"
step121_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-boundary-review-policy.json"
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"

expected_source_sha256=0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6
expected_template_sha256=4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba
expected_step121_policy_sha256=a03e299a87596ad66246031c3a47839bac5ab2a869073c43eeae6be0788ebc4e
expected_contract_sha256=f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9

require_regular_file() {
    local path=$1
    local label=$2
    if [[ ! -f "$path" || -L "$path" ]]; then
        printf 'error: %s is not a regular non-symlink file: %s\n' "$label" "$path" >&2
        exit 1
    fi
}

require_sha256() {
    local path=$1
    local expected=$2
    local label=$3
    local actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    if [[ "$actual" != "$expected" ]]; then
        printf 'error: %s SHA-256 mismatch: expected %s, got %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    fi
}

require_regular_file "$source_file" "reference implementation"
require_regular_file "$template_file" "configuration template"
require_regular_file "$step121_policy" "step-121 mode-boundary policy"
require_regular_file "$contract" "step-122 frozen mode contract"
require_sha256 "$source_file" "$expected_source_sha256" "reference implementation"
require_sha256 "$template_file" "$expected_template_sha256" "configuration template"
require_sha256 "$step121_policy" "$expected_step121_policy_sha256" "step-121 mode-boundary policy"
require_sha256 "$contract" "$expected_contract_sha256" "step-122 frozen mode contract"

python3 - "$step121_policy" "$contract" <<'PY'
import csv
import json
import sys

policy_path, contract_path = sys.argv[1:]
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert policy["schema"] == 1
assert policy["scenario"] == "phase-1-configuration-module-mode-boundary-review"
assert policy["fresh_boundary"] is True
assert policy["mode_values"] == ["enabled", "disabled", "auto"]
assert policy["default_mode"] == "auto"
assert policy["runtime_behavior_change"] is False
assert policy["configuration_template_change"] is False
assert policy["machine_action_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["next_stage"] == "phase-1-configuration-module-mode-contract-freeze"
assert policy["pause_safe"] is True

expected_modules = {
    "flatpak": ("CONFIG_FLATPAK_MODE", "flatpak.mode"),
    "sbo": ("CONFIG_SBO_MODE", "sbo.mode"),
    "elf": ("CONFIG_ELF_MODE", "elf.mode"),
    "boot": ("CONFIG_BOOT_MODE", "boot.mode"),
    "cinnamon": ("CONFIG_CINNAMON_MODE", "cinnamon.mode"),
}
expected_modes = {
    "enabled": ("required", "attempt-when-applicable", "error", "error"),
    "disabled": ("bypassed", "never", "not-evaluated", "disabled"),
    "auto": ("conditional", "when-available-and-applicable", "non-fatal", "skipped-non-fatally"),
}

with open(contract_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))

required_columns = [
    "module",
    "variable",
    "key",
    "default_mode",
    "mode",
    "probe_policy",
    "run_policy",
    "missing_requirements",
    "applicability_policy",
    "outcome_when_unavailable",
]
assert rows
assert list(rows[0]) == required_columns
assert len(rows) == 15
assert len({(row["module"], row["mode"]) for row in rows}) == 15
assert {row["module"] for row in rows} == set(expected_modules)
assert {row["mode"] for row in rows} == set(expected_modes)

for module, (variable, key) in expected_modules.items():
    module_rows = [row for row in rows if row["module"] == module]
    assert [row["mode"] for row in module_rows] == ["enabled", "disabled", "auto"]
    for row in module_rows:
        assert row["variable"] == variable
        assert row["key"] == key
        assert row["default_mode"] == "auto"
        probe, run, missing, unavailable = expected_modes[row["mode"]]
        assert row["probe_policy"] == probe
        assert row["run_policy"] == run
        assert row["missing_requirements"] == missing
        assert row["outcome_when_unavailable"] == unavailable
        if module == "boot" and row["mode"] == "enabled":
            assert row["applicability_policy"] == "validated-supported-preparation-path-required"
        elif module == "boot" and row["mode"] == "auto":
            assert row["applicability_policy"] == "validated-supported-preparation-path-only"
        elif row["mode"] == "disabled":
            assert row["applicability_policy"] == "bypassed"
        else:
            assert row["applicability_policy"] == "module-applicability-retained"
PY

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-contract-freeze\n'
printf 'accepted_step121_policy_sha256\t%s\n' "$expected_step121_policy_sha256"
printf 'source_sha256\t%s\n' "$expected_source_sha256"
printf 'template_sha256\t%s\n' "$expected_template_sha256"
printf 'contract_sha256\t%s\n' "$expected_contract_sha256"
printf 'supported_targets\tslackware-15.0,slackware-current\n'
printf 'module_count\t5\n'
printf 'mode_count\t3\n'
printf 'contract_row_count\t15\n'
printf 'mode_values\tenabled,disabled,auto\n'
printf 'default_mode\tauto\n'
printf 'mode_contract_frozen\ttrue\n'
printf 'runtime_behavior_change\tfalse\n'
printf 'configuration_template_change\tfalse\n'
printf 'source_change_authorized\tfalse\n'
printf 'template_change_authorized\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'boot_safety_specialization_preserved\ttrue\n'
printf 'next_stage\tphase-1-configuration-module-mode-conformance-review\n'
printf 'pause_safe\ttrue\n'
