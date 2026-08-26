#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution-boundary.sh [--help]

Validate and report the repository-only step-144 execution boundary for the
single-use Slackware-current selection-only boot recovery. This command does
not execute the machine recovery, reboot, runtime probe, package operation,
repository refresh, or boot mutation.
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
auth_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-authorization-review-policy.json"
execution_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution-policy.json"
execution_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution.tsv"
execution_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery.sh"

auth_sha=$(sha256sum -- "$auth_policy" | awk '{print $1}')
policy_sha=$(sha256sum -- "$execution_policy" | awk '{print $1}')
harness_sha=$(sha256sum -- "$execution_harness" | awk '{print $1}')

python3 - "$auth_policy" "$execution_policy" "$execution_record" "$harness_sha" <<'PY'
import csv
import json
import sys

auth_path, policy_path, record_path, harness_sha = sys.argv[1:]
with open(auth_path, encoding="utf-8") as handle:
    auth = json.load(handle)
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)
with open(record_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))

assert policy["schema"] == 1
assert policy["step143_authorization_policy_sha256"] == "ef59179103f9fb2c7e1a7142abc1a302f59d06c2e7ca9eb9fe9658614f6aec6c"
assert policy["authorization_id"] == auth["authorization"]["authorization_id"]
assert policy["execution_harness_sha256"] == harness_sha
assert auth["authorization"]["authorization_consumable"] is True
assert auth["authorization"]["machine_sequence_limit"] == 1
assert auth["authorization"]["reboot_limit"] == policy["manual_reboot_boundary"]["reboot_limit"] == 1
assert auth["authorization"]["interactive_boot_selection_limit"] == policy["manual_reboot_boundary"]["interactive_boot_selection_limit"] == 1
assert auth["authorization"]["authorized_menuentry"] == policy["target"]["dedicated_menuentry"]
assert policy["manual_reboot_boundary"]["authorized_menuentry"] == policy["target"]["dedicated_menuentry"]
assert policy["manual_reboot_boundary"]["authorized_reboot_command"] == "sudo /sbin/reboot"
assert policy["machine_harness_performs_reboot"] is False
assert policy["runtime_probe_permitted"] is False
assert policy["repository_refresh_permitted"] is False
assert policy["package_mutation_permitted"] is False
assert policy["boot_configuration_mutation_permitted"] is False
assert policy["source_mutation_permitted"] is False
assert policy["configuration_template_mutation_permitted"] is False
assert policy["contract_mutation_permitted"] is False
assert policy["slackware_current_rerun_permitted"] is False
assert policy["slackware_15_execution_permitted"] is False
assert policy["pre_reboot_gate"]["must_pass_before_reboot"] is True
assert policy["pre_reboot_gate"]["failure_consumes_reboot_authorization"] is False
assert policy["post_reboot_characterization"]["authorization_consumed_when_reboot_proven"] is True
assert policy["post_reboot_characterization"]["require_live_root_token"] == "/dev/sda2"
assert policy["pause_safe_before_pre_reboot"] is True
assert policy["pause_safe_while_recovery_armed"] is False
assert policy["slackware_repository_state_dependency"] is False
assert len(rows) == 1
row = rows[0]
assert row["authorization_id"] == policy["authorization_id"]
assert row["target"] == "slackware-current"
assert row["pre_reboot_gate"] == "required"
assert row["reboot_limit"] == "1"
assert row["interactive_selection_limit"] == "1"
assert row["menuentry"] == policy["target"]["dedicated_menuentry"]
assert row["harness_reboots"] == "false"
assert row["runtime_probe_authorized"] == "false"
assert row["repository_refresh_authorized"] == "false"
assert row["package_mutation_authorized"] == "false"
assert row["boot_mutation_authorized"] == "false"
assert row["slackware_15_authorized"] == "false"
assert row["next_stage"] == policy["next_stage_on_success"]
PY

printf '%s\n' \
    $'schema\t1' \
    $'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution-boundary' \
    $'step143_authorization_policy_sha256\t'"$auth_sha" \
    $'execution_policy_sha256\t'"$policy_sha" \
    $'execution_harness_sha256\t'"$harness_sha" \
    $'authorization_id\tslackware-current-interactive-frozen-boot-selection-recovery' \
    $'pre_reboot_gate_required\ttrue' \
    $'machine_harness_performs_reboot\tfalse' \
    $'authorized_reboot_command\tsudo /sbin/reboot' \
    $'reboot_limit\t1' \
    $'interactive_boot_selection_limit\t1' \
    $'authorized_menuentry\tSlackware-current slack-update direct generic (no initrd)' \
    $'runtime_probe_authorized\tfalse' \
    $'repository_refresh_authorized\tfalse' \
    $'package_mutation_authorized\tfalse' \
    $'boot_configuration_mutation_authorized\tfalse' \
    $'slackware_15_execution_authorized\tfalse' \
    $'pause_safe_before_pre_reboot\ttrue' \
    $'pause_safe_while_recovery_armed\tfalse' \
    $'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution'
