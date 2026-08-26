#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review.sh [--help]

Validate and report the repository-only step-145 manual review of the completed
Slackware-current selection-only boot recovery. This command performs no
runtime probe, rerun, reboot, package operation, repository refresh, boot
mutation, source mutation, or other machine action.
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
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review-policy.json"

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

require_regular_file "$auth_policy" "step-143 recovery authorization policy"
require_regular_file "$execution_policy" "step-144 execution policy"
require_regular_file "$execution_record" "step-144 execution record"
require_regular_file "$execution_harness" "step-144 machine harness"
require_regular_file "$review" "step-145 manual-review record"
require_regular_file "$policy" "step-145 manual-review policy"

require_sha256 "$auth_policy" ef59179103f9fb2c7e1a7142abc1a302f59d06c2e7ca9eb9fe9658614f6aec6c "step-143 recovery authorization policy"
require_sha256 "$execution_policy" 4d056fcf9287ffbbdf83ec8b9fc5bb709b781989f59a719639aab77f58c93e6f "step-144 execution policy"
require_sha256 "$execution_record" 1d4f5a7b5ae5ae21130dec5da6771269cf043ba601094c2c7eae57bbfe8f3adf "step-144 execution record"
require_sha256 "$execution_harness" 300335ef07df2f091e9b0d8f849f8c65fcece5a134880301d684c36bb10bf12f "step-144 machine harness"

python3 - "$auth_policy" "$execution_policy" "$review" "$policy" <<'PY'
import csv
import json
import sys

auth_path, execution_path, review_path, policy_path = sys.argv[1:]
with open(auth_path, encoding="utf-8") as handle:
    auth = json.load(handle)
with open(execution_path, encoding="utf-8") as handle:
    execution = json.load(handle)
with open(review_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(rows) == 1
row = rows[0]
assert policy["schema"] == 1
assert policy["review_only"] is True
assert policy["step143_authorization_policy_sha256"] == "ef59179103f9fb2c7e1a7142abc1a302f59d06c2e7ca9eb9fe9658614f6aec6c"
assert policy["step144_execution_policy_sha256"] == "4d056fcf9287ffbbdf83ec8b9fc5bb709b781989f59a719639aab77f58c93e6f"
assert policy["step144_execution_harness_sha256"] == "300335ef07df2f091e9b0d8f849f8c65fcece5a134880301d684c36bb10bf12f"
assert policy["step144_execution_record_sha256"] == "1d4f5a7b5ae5ae21130dec5da6771269cf043ba601094c2c7eae57bbfe8f3adf"

assert policy["authorization"]["authorization_id"] == auth["authorization"]["authorization_id"]
assert policy["authorization"]["pre_reboot_marker_sha256"] == row["pre_marker_sha256"]
assert policy["authorization"]["single_authorized_reboot_occurred"] is True
assert policy["authorization"]["single_authorized_interactive_selection_occurred"] is True
assert policy["authorization"]["consumed_by_reboot"] is True
assert policy["authorization"]["reusable"] is False

assert policy["evidence"]["pre_reboot_archive_sha256"] == row["pre_evidence_sha256"]
assert policy["evidence"]["pre_reboot_archive_sha256"] == "7779072439d48eaace4b3a5b468647887fe89ca173eb78b1cdb0cb5876d9f60f"
assert policy["evidence"]["post_reboot_archive_sha256"] == row["post_evidence_sha256"]
assert policy["evidence"]["post_reboot_archive_sha256"] == "0356cb5ac64e8a560b132c61d0c9df3228de1a74af2cd32fef9323850c4b5eb9"
assert policy["evidence"]["post_reboot_authenticated"] is True
assert policy["evidence"]["post_reboot_passes"] == 24
assert policy["evidence"]["post_reboot_failures"] == 0
assert policy["evidence"]["post_reboot_skips"] == 0

assert policy["target"]["hostname_fqdn"] == "vbox-slackcurrent.vbox-slackcurrent.org"
assert policy["target"]["running_kernel"] == "6.18.45"
assert policy["target"]["boot_image"] == "/boot/vmlinuz-generic"
assert policy["target"]["generic_kernel_target"] == "/boot/vmlinuz-6.18.45"
assert policy["target"]["mounted_root_device"] == "/dev/sda2"
assert policy["target"]["pre_recovery_live_root_token"] == "UUID=d1a09d24-cdbf-41cd-8cd6-2faff4d72863"
assert policy["target"]["recovered_live_root_token"] == "/dev/sda2"
assert policy["target"]["dedicated_menuentry"] == execution["target"]["dedicated_menuentry"]
assert policy["target"]["dedicated_linux_command"] == execution["target"]["dedicated_linux_command"]
assert policy["target"]["boot_selection_mismatch_resolved"] is True
assert policy["target"]["recovered_characterization_accepted"] is True

pres = policy["preservation"]
assert pres["packages_manifest_sha256"] == "a47173892802bbb64413b9201c7647578d67beb3b78cf8a19280804176a18a3f"
assert pres["slackpkg_metadata_manifest_sha256"] == "1800023c57b976b1eed486bae9661ac9e88b0c52b3f147c86aec9ecd456bd676"
assert pres["grub_cfg_sha256"] == execution["target"]["grub_cfg_sha256"]
assert pres["custom_grub_script_sha256"] == execution["target"]["custom_grub_script_sha256"]
assert pres["source_sha256"] == "aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7"
assert pres["template_sha256"] == "4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba"
assert all(pres[key] is True for key in (
    "package_state_preserved", "slackpkg_metadata_preserved", "boot_state_preserved",
    "source_state_preserved", "template_state_preserved", "system_state_preserved"
))

runtime = policy["runtime_remediation"]
assert runtime["source_remediation_exercised"] is False
assert runtime["source_remediation_rejected"] is False
assert runtime["runtime_probe_invoked_during_recovery"] is False
assert runtime["fresh_rerun_required_to_exercise_source"] is True

authz = policy["authorization_boundary"]
assert authz["step139_rerun_authorization_reusable"] is False
assert authz["step143_recovery_authorization_reusable"] is False
assert authz["runtime_probe_authorized"] is False
assert authz["slackware_current_rerun_authorized"] is False
assert authz["fresh_slackware_current_rerun_authorization_review_required"] is True
assert authz["repository_refresh_authorized"] is False
assert authz["package_mutation_authorized"] is False
assert authz["boot_mutation_authorized"] is False
assert authz["source_change_authorized"] is False
assert authz["configuration_template_change_authorized"] is False
assert authz["contract_change_authorized"] is False
assert authz["slackware_15_execution_released"] is False
assert authz["slackware_15_execution_authorized"] is False

assert row["target"] == "slackware-current"
assert row["reboot_authorization_consumed"] == "true"
assert row["recovery_accepted"] == "true"
assert row["pre_root_token"] == policy["target"]["pre_recovery_live_root_token"]
assert row["recovered_root_token"] == policy["target"]["recovered_live_root_token"]
assert row["mounted_root_device"] == policy["target"]["mounted_root_device"]
assert row["system_state_preserved"] == "true"
assert row["runtime_probe_invoked"] == "false"
assert row["source_remediation_exercised"] == "false"
assert row["fresh_rerun_authorization_required"] == "true"
assert row["slackware_15_released"] == "false"
assert row["status"] == "accepted-manual-review"
assert row["next_stage"] == policy["next_stage"]

assert policy["repository_refresh_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["machine_action_required"] is False
assert policy["pause_safe"] is True
PY

printf '%s\n' \
    $'schema\t1' \
    $'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review' \
    $'pre_reboot_evidence_sha256\t7779072439d48eaace4b3a5b468647887fe89ca173eb78b1cdb0cb5876d9f60f' \
    $'post_reboot_evidence_sha256\t0356cb5ac64e8a560b132c61d0c9df3228de1a74af2cd32fef9323850c4b5eb9' \
    $'pre_reboot_marker_sha256\t9d3a00371ef60a1bcd0a399feba31004a98ba807fbd6445de574bd94f9a48cd7' \
    $'authorization_consumed_by_reboot\ttrue' \
    $'authorization_reusable\tfalse' \
    $'boot_selection_mismatch_resolved\ttrue' \
    $'recovered_live_root_token\t/dev/sda2' \
    $'mounted_root_device\t/dev/sda2' \
    $'running_kernel\t6.18.45' \
    $'boot_image\t/boot/vmlinuz-generic' \
    $'system_state_preserved\ttrue' \
    $'runtime_probe_invoked\tfalse' \
    $'source_remediation_exercised\tfalse' \
    $'source_remediation_rejected\tfalse' \
    $'fresh_slackware_current_rerun_authorization_review_required\ttrue' \
    $'slackware_current_rerun_authorized\tfalse' \
    $'slackware_15_execution_authorized\tfalse' \
    $'repository_refresh_required\tfalse' \
    $'machine_action_required\tfalse' \
    $'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review' \
    $'pause_safe\ttrue'
