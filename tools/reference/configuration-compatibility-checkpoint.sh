#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-compatibility-checkpoint.sh

Validate the frozen Phase 1 configuration/default parity and emit the
repository-only compatibility checkpoint. This command is read-only.
USAGE
}

if (($#)); then
    case "$1" in
        -h|--help)
            (($# == 1)) || { echo "ERROR: --help accepts no additional arguments" >&2; exit 2; }
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown option: $1" >&2
            exit 2
            ;;
    esac
fi

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/../.." && pwd -P)
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template_file="$repo_root/data/config/slack-update.conf"
parity_check="$repo_root/tools/reference/configuration-default-parity-check.sh"
contract_file="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-default-parity-contract.tsv"
step119_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-default-parity-freeze-policy.json"

expected_source_sha256='0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6'
expected_template_sha256='4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
expected_parity_check_sha256='39b4e7cd7ceb94de76b5329d00291c1d9921419e3bfa5578103eeceb1af22bc4'
expected_contract_sha256='2b6f200c4de671356c0ffcf2ab8d10428421b145c32b44a5a6efe8c146f95125'
expected_step119_policy_sha256='baa3e642aa042640da528aca1a22052121aa4e07b4e968e027c2ba69e9d7bec8'

check_regular_hash() {
    local file=$1
    local expected=$2
    local label=$3
    local actual

    if [[ ! -f "$file" || -L "$file" || ! -r "$file" ]]; then
        echo "ERROR: $label is not a readable regular non-symlink file: $file" >&2
        exit 1
    fi
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    if [[ "$actual" != "$expected" ]]; then
        echo "ERROR: $label SHA-256 differs from the reviewed boundary" >&2
        echo "Expected: $expected" >&2
        echo "Actual:   $actual" >&2
        exit 1
    fi
}

check_regular_hash "$source_file" "$expected_source_sha256" "reference implementation"
check_regular_hash "$template_file" "$expected_template_sha256" "configuration template"
check_regular_hash "$parity_check" "$expected_parity_check_sha256" "step-119 parity checker"
check_regular_hash "$contract_file" "$expected_contract_sha256" "step-119 parity contract"
check_regular_hash "$step119_policy" "$expected_step119_policy_sha256" "step-119 parity policy"

parity_output=$(mktemp)
trap 'rm -f -- "$parity_output"' EXIT
"$parity_check" >"$parity_output"

require_line() {
    local expected=$1
    if ! grep -Fqx -- "$expected" "$parity_output"; then
        echo "ERROR: step-119 parity output is missing: $expected" >&2
        exit 1
    fi
}

require_line $'schema\t1'
require_line $'scenario\tphase-1-configuration-default-parity-freeze'
require_line $'source_sha256\t0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6'
require_line $'template_sha256\t4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
require_line $'contract_sha256\t2b6f200c4de671356c0ffcf2ab8d10428421b145c32b44a5a6efe8c146f95125'
require_line $'runtime_behavior_change\tfalse'
require_line $'default_parity_frozen\ttrue'
require_line $'module_mode_migration_deferred\ttrue'
require_line $'parity_rows\t34'
require_line $'deferred_module_mode_rows\t5'
require_line $'bootstrap_template_overlap_rows\t8'
require_line $'configuration_source_is_not_template_key\ttrue'
require_line $'parity_status\taccepted'

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-compatibility-checkpoint\n'
printf 'source_sha256\t%s\n' "$expected_source_sha256"
printf 'template_sha256\t%s\n' "$expected_template_sha256"
printf 'contract_sha256\t%s\n' "$expected_contract_sha256"
printf 'runtime_behavior_change\tfalse\n'
printf 'default_parity_frozen\ttrue\n'
printf 'configuration_surface_compatibility_preserved\ttrue\n'
printf 'compatibility_scope\tconfiguration-surface-only\n'
printf 'slackware_15_0_target_preserved\ttrue\n'
printf 'slackware_current_target_preserved\ttrue\n'
printf 'runtime_machine_revalidation_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'module_mode_migration_deferred\ttrue\n'
printf 'pending_configuration_action\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'future_work_requires_fresh_boundary\ttrue\n'
printf 'pause_safe\ttrue\n'
printf 'next_stage\tphase-1-resume-planning\n'
