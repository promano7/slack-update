#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-boundary-review.sh [--help]

Review the existing optional-module enabled/disabled/auto behavior at the
fresh Phase 1 boundary opened after the accepted step-120 checkpoint.

This command is repository-local and read-only. It does not modify runtime
configuration, execute the reference update workflow, access the network, or
perform package, boot, module, or machine actions.
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
step120_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-compatibility-checkpoint-policy.json"
parity_contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-default-parity-contract.tsv"

expected_source_sha256=0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6
expected_template_sha256=4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba
expected_step120_policy_sha256=dbd3ff99948b6f5e3a42ae46f9d0b27f6fe26f41e84069df614b9f23239cf92a
expected_parity_contract_sha256=2b6f200c4de671356c0ffcf2ab8d10428421b145c32b44a5a6efe8c146f95125

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

first_line_for_literal() {
    local file=$1
    local literal=$2
    local line
    line=$(grep -nF -- "$literal" "$file" | head -n 1 | cut -d: -f1 || true)
    if [[ -z "$line" ]]; then
        printf 'error: required reviewed source marker is missing: %s\n' "$literal" >&2
        exit 1
    fi
    printf '%s\n' "$line"
}

require_regular_file "$source_file" "reference implementation"
require_regular_file "$template_file" "configuration template"
require_regular_file "$step120_policy" "step-120 compatibility policy"
require_regular_file "$parity_contract" "step-119 frozen parity contract"
require_sha256 "$source_file" "$expected_source_sha256" "reference implementation"
require_sha256 "$template_file" "$expected_template_sha256" "configuration template"
require_sha256 "$step120_policy" "$expected_step120_policy_sha256" "step-120 compatibility policy"
require_sha256 "$parity_contract" "$expected_parity_contract_sha256" "step-119 frozen parity contract"

python3 - "$parity_contract" <<'PY'
import csv
import sys

path = sys.argv[1]
expected = {
    "CONFIG_FLATPAK_MODE": ("flatpak.mode", "auto"),
    "CONFIG_SBO_MODE": ("sbo.mode", "auto"),
    "CONFIG_ELF_MODE": ("elf.mode", "auto"),
    "CONFIG_BOOT_MODE": ("boot.mode", "auto"),
    "CONFIG_CINNAMON_MODE": ("cinnamon.mode", "auto"),
}
with open(path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
selected = {row["variable"]: row for row in rows if row["variable"] in expected}
assert set(selected) == set(expected)
for variable, (key, default) in expected.items():
    row = selected[variable]
    assert row["key"] == key
    assert row["classification"] == "deferred-module-mode"
    assert row["bootstrap_initializer"] == default
    assert row["template_value"] == default
PY

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-boundary-review\n'
printf 'fresh_boundary\ttrue\n'
printf 'accepted_step120_pause_safe\ttrue\n'
printf 'accepted_step120_future_work_requires_fresh_boundary\ttrue\n'
printf 'runtime_behavior_change\tfalse\n'
printf 'configuration_template_change\tfalse\n'
printf 'mode_contract_change\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'supported_targets\tslackware-15.0,slackware-current\n'
printf 'mode_values\tenabled,disabled,auto\n'
printf 'default_mode\tauto\n'
printf 'module_count\t5\n'
printf '%s\t%s\n' source_sha256 "$expected_source_sha256"
printf '%s\t%s\n' template_sha256 "$expected_template_sha256"
printf '%s\t%s\n' step120_policy_sha256 "$expected_step120_policy_sha256"
printf '%s\t%s\n' parity_contract_sha256 "$expected_parity_contract_sha256"
printf '%s\n' '---'
printf 'mode\tprobe_policy\trun_policy\tmissing_requirements\n'
printf 'enabled\trequired\tattempt_when_applicable\terror\n'
printf 'disabled\tbypassed\tnever\tnot-evaluated\n'
printf 'auto\tconditional\twhen_available_and_applicable\tnon-fatal\n'
printf '%s\n' '---'
printf 'module\tconfig_variable\tconfig_key\tdefault\tbootstrap_line\truntime_bind_line\tdisabled_state_line\trun_enable_line\tunavailable_reason_line\n'

emit_module() {
    local module=$1
    local config_variable=$2
    local runtime_variable=$3
    local config_key=$4
    local state_variable=$5
    local run_variable=$6
    local unavailable_literal=$7
    local bootstrap_line runtime_line disabled_line run_line unavailable_line

    bootstrap_line=$(first_line_for_literal "$source_file" "${config_variable}=auto")
    runtime_line=$(first_line_for_literal "$source_file" "${runtime_variable}=\$${config_variable}")
    disabled_line=$(first_line_for_literal "$source_file" "${state_variable}=disabled")
    run_line=$(first_line_for_literal "$source_file" "${run_variable}=1")
    unavailable_line=$(first_line_for_literal "$source_file" "$unavailable_literal")

    printf '%s\t%s\t%s\tauto\t%s\t%s\t%s\t%s\t%s\n' \
        "$module" "$config_variable" "$config_key" "$bootstrap_line" "$runtime_line" \
        "$disabled_line" "$run_line" "$unavailable_line"
}

emit_module flatpak CONFIG_FLATPAK_MODE FLATPAK_MODE flatpak.mode FLATPAK_MODULE_STATE FLATPAK_MODULE_RUN 'flatpak is not installed'
emit_module sbo CONFIG_SBO_MODE SBO_MODE sbo.mode SBO_MODULE_STATE SBO_MODULE_RUN 'sbopkg and sqg are not installed'
emit_module elf CONFIG_ELF_MODE ELF_MODE elf.mode ELF_MODULE_STATE ELF_MODULE_RUN 'readelf and /sbin/ldconfig are unavailable'
emit_module boot CONFIG_BOOT_MODE BOOT_MODE boot.mode BOOT_MODULE_STATE BOOT_MODULE_RUN 'no supported initrd or GRUB preparation path was detected'
emit_module cinnamon CONFIG_CINNAMON_MODE CINNAMON_MODE cinnamon.mode CINNAMON_MODULE_STATE CINNAMON_MODULE_RUN 'no Cinnamon installation or managed CSB checkout was detected'

printf '%s\n' '---'
printf 'disabled_marker_count\t%s\n' "$(grep -Fc -- 'MODULE_REASON="disabled by configuration"' "$source_file")"
printf 'next_stage\tphase-1-configuration-module-mode-contract-freeze\n'
printf 'pause_safe\ttrue\n'
