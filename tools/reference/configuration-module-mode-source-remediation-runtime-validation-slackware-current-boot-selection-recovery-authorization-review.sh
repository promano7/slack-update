#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-authorization-review.sh [--help]

Validate and report the repository-only step-143 authorization review for the
selection-only Slackware-current boot recovery. This command performs no
source, configuration, package, boot, repository, reboot, or machine mutation.
USAGE
}

if (( $# > 1 )); then
    printf 'error: unexpected arguments\n' >&2
    exit 2
fi
if (( $# == 1 )); then
    case "$1" in
        -h|--help) usage; exit 0 ;;
        *) printf 'error: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
fi

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design.tsv"
design_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design-policy.json"
design_helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design.sh"
design_harness="$repo_root/tests/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design-harness.sh"
design_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design.md"
auth="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-authorization-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-authorization-review-policy.json"

require_regular_file() {
    local path=$1 label=$2
    [[ -f "$path" && ! -L "$path" ]] || {
        printf 'error: %s is not a regular non-symlink file: %s\n' "$label" "$path" >&2
        exit 1
    }
}
require_sha256() {
    local path=$1 expected=$2 label=$3 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    [[ "$actual" == "$expected" ]] || {
        printf 'error: %s SHA-256 mismatch: expected %s, got %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    }
}

require_regular_file "$design" "step-142 design record"
require_regular_file "$design_policy" "step-142 design policy"
require_regular_file "$design_helper" "step-142 design helper"
require_regular_file "$design_harness" "step-142 design harness"
require_regular_file "$design_doc" "step-142 design document"
require_regular_file "$auth" "step-143 authorization record"
require_regular_file "$policy" "step-143 authorization policy"

require_sha256 "$design" 565b3d30749dd3d1b75c29d36a37425c60005d9fb109ae1248f5aa6398fd1825 "step-142 design record"
require_sha256 "$design_policy" cac091fd160d4ae47f36d8e1d9da21cca753e416139a7959c9ee6b5e2233a139 "step-142 design policy"
require_sha256 "$design_helper" 1f65652d0175b10965e085b68f665203c54c9f981315f91a16dde422653d8293 "step-142 design helper"
require_sha256 "$design_harness" 675bf39c9865a7d6575b5793354e73bededd5c1686f1664d458a750318a33b4e "step-142 design harness"
require_sha256 "$design_doc" 130d3db195d621362b21f05a9009b8bfd853906c3cc402406a6aef58a1d728ca "step-142 design document"

python3 - "$design_policy" "$auth" "$policy" <<'PY'
import csv
import json
import sys

design_path, auth_path, policy_path = sys.argv[1:]
with open(design_path, encoding="utf-8") as handle:
    design = json.load(handle)
with open(auth_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(rows) == 1
row = rows[0]
assert policy["schema"] == 1
assert policy["authorization_review_only"] is True
assert policy["step142_design_policy_sha256"] == "cac091fd160d4ae47f36d8e1d9da21cca753e416139a7959c9ee6b5e2233a139"
assert design["pause_safe"] is True
assert design["next_stage"].endswith("boot-selection-recovery-authorization-review")
assert policy["diagnosis"]["classification"] == design["diagnosis"]["classification"] == "frozen-boot-selection-mismatch"
assert policy["diagnosis"]["authenticated_step140_evidence_sha256"] == design["diagnosis"]["authenticated_evidence_sha256"]
assert policy["diagnosis"]["source_remediation_exercised"] is False
assert policy["diagnosis"]["source_remediation_rejected"] is False

for key in ("hostname_fqdn", "accepted_kernel", "boot_image", "generic_kernel_target", "required_boot_profile", "dedicated_menuentry", "dedicated_linux_command", "grub_cfg_sha256", "custom_grub_script_sha256"):
    assert policy["target"][key] == design["target"][key]
assert policy["target"]["expected_mounted_root_device"] == design["diagnosis"]["underlying_root_device"] == "/dev/sda2"
assert policy["target"]["expected_post_reboot_root_token"] == design["diagnosis"]["frozen_root_token"] == "/dev/sda2"

auth = policy["authorization"]
assert auth["authorization_consumable"] is True
assert auth["machine_sequence_limit"] == 1
assert auth["reboot_limit"] == 1
assert auth["interactive_boot_selection_authorized"] is True
assert auth["interactive_boot_selection_limit"] == 1
assert auth["manual_menu_selection_required"] is True
assert auth["authorized_menuentry"] == design["target"]["dedicated_menuentry"]
assert auth["persistent_boot_selection_mutation_authorized"] is False
assert auth["boot_configuration_mutation_authorized"] is False
assert auth["grub_environment_mutation_authorized"] is False
assert auth["grub_cfg_regeneration_authorized"] is False
assert auth["package_mutation_authorized"] is False
assert auth["repository_refresh_authorized"] is False
assert auth["source_change_authorized"] is False
assert auth["configuration_template_change_authorized"] is False
assert auth["contract_change_authorized"] is False
assert auth["runtime_probe_authorized"] is False
assert auth["slackware_current_rerun_authorized"] is False
assert auth["slackware_15_execution_authorized"] is False

pre = policy["pre_reboot_gate"]
assert pre["required"] is True
assert pre["require_frozen_grub_hashes"] is True
assert pre["failure_stops_before_reboot"] is True
post = policy["post_reboot_characterization"]
assert post["required"] is True
assert post["runtime_probe_permitted"] is False
assert post["require_live_root_token"] == "/dev/sda2"
assert post["require_mounted_root_device"] == "/dev/sda2"
assert post["advance_on_success_only_to_fresh_rerun_authorization_review"] is True
assert policy["step139_authorization_reusable"] is False
assert policy["step143_machine_action_required"] is False
assert policy["future_machine_action_authorized"] is True
assert policy["slackware_repository_state_dependency"] is False
assert policy["repository_refresh_required"] is False
assert policy["pause_safe"] is True

assert row["authorization_id"] == auth["authorization_id"]
assert row["target"] == "slackware-current"
assert row["recovery_strategy"] == design["recovery_design"]["strategy"]
assert row["menuentry"] == auth["authorized_menuentry"]
assert row["machine_sequence_limit"] == "1"
assert row["reboot_limit"] == "1"
assert row["interactive_selection_authorized"] == "true"
assert row["boot_mutation_authorized"] == "false"
assert row["runtime_probe_authorized"] == "false"
assert row["replacement_rerun_authorized"] == "false"
assert row["slackware_15_authorized"] == "false"
assert row["repository_refresh_authorized"] == "false"
assert row["next_stage"] == policy["next_stage"]
assert row["status"] == "authorized"
PY

printf '%s\n' \
    $'schema\t1' \
    $'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-authorization-review' \
    $'failure_classification\tfrozen-boot-selection-mismatch' \
    $'authorization_consumable\ttrue' \
    $'machine_sequence_limit\t1' \
    $'reboot_limit\t1' \
    $'interactive_boot_selection_authorized\ttrue' \
    $'authorized_menuentry\tSlackware-current slack-update direct generic (no initrd)' \
    $'persistent_boot_selection_mutation_authorized\tfalse' \
    $'boot_configuration_mutation_authorized\tfalse' \
    $'runtime_probe_authorized\tfalse' \
    $'slackware_current_rerun_authorized\tfalse' \
    $'slackware_15_execution_authorized\tfalse' \
    $'repository_refresh_authorized\tfalse' \
    $'pre_reboot_gate_required\ttrue' \
    $'post_reboot_characterization_required\ttrue' \
    $'step139_authorization_reusable\tfalse' \
    $'machine_action_required\tfalse' \
    $'future_machine_action_authorized\ttrue' \
    $'slackware_repository_state_dependency\tfalse' \
    $'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution' \
    $'pause_safe\ttrue'
