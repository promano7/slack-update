#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design.sh [--help]

Validate and report the repository-only step-142 design for recovering the
frozen Slackware-current boot selection. This command performs no source,
configuration, package, boot, repository, reboot, or machine mutation.
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
source_file="$repo_root/tools/reference/slack-update-reference.sh"
template="$repo_root/data/config/slack-update.conf"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
step141_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review-policy.json"
step141_harness="$repo_root/tests/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review-harness.sh"
step141_r1_harness="$repo_root/tests/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review-revision-1-harness.sh"
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design-policy.json"

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

require_regular_file "$source_file" "accepted reference implementation"
require_regular_file "$template" "frozen configuration template"
require_regular_file "$binding_policy" "step-132 target-binding policy"
require_regular_file "$step141_policy" "step-141 manual-review policy"
require_regular_file "$step141_harness" "corrected step-141 manual-review harness"
require_regular_file "$step141_r1_harness" "step-141 revision-1 harness"
require_regular_file "$design" "step-142 remediation design record"
require_regular_file "$policy" "step-142 remediation design policy"

require_sha256 "$source_file" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 "accepted remediated reference implementation"
require_sha256 "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "frozen configuration template"
require_sha256 "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
require_sha256 "$step141_policy" b5bf2d88f0f6b0e0b8627f6f1bfa1f37bd8349359d6964be84d6ca3f6068c730 "step-141 manual-review policy"
require_sha256 "$step141_harness" 21c620597e01e673688f85ef4b116219ca9a611254f423135ffa8983c4d6c1d3 "corrected step-141 manual-review harness"
require_sha256 "$step141_r1_harness" f3f696ef0d62a993f6ec2bcfb34a807afa01751517360c14419a1087119cc04e "step-141 revision-1 harness"

python3 - "$binding_policy" "$step141_policy" "$design" "$policy" <<'PY'
import csv
import json
import sys

binding_path, review_path, design_path, policy_path = sys.argv[1:]
with open(binding_path, encoding="utf-8") as handle:
    binding = json.load(handle)
with open(review_path, encoding="utf-8") as handle:
    review = json.load(handle)
with open(design_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(rows) == 1
row = rows[0]
assert policy["schema"] == 1
assert policy["design_only"] is True
assert policy["source_sha256"] == review["source_sha256"]
assert policy["template_sha256"] == review["template_sha256"]
assert policy["step132_binding_policy_sha256"] == review["step132_binding_policy_sha256"]
assert policy["step141_manual_review_policy_sha256"] == "b5bf2d88f0f6b0e0b8627f6f1bfa1f37bd8349359d6964be84d6ca3f6068c730"
assert policy["step141_manual_review_harness_revision1_sha256"] == "21c620597e01e673688f85ef4b116219ca9a611254f423135ffa8983c4d6c1d3"
assert policy["step141_revision1_harness_sha256"] == "f3f696ef0d62a993f6ec2bcfb34a807afa01751517360c14419a1087119cc04e"

assert policy["diagnosis"]["classification"] == review["failure"]["classification"] == "frozen-boot-selection-mismatch"
assert policy["diagnosis"]["authenticated_evidence_sha256"] == review["step140_evidence"]["archive_sha256"]
assert policy["diagnosis"]["underlying_root_device"] == review["target"]["mounted_root_device"] == "/dev/sda2"
assert policy["diagnosis"]["frozen_root_token"] == review["target"]["frozen_root_device"] == "/dev/sda2"
assert policy["diagnosis"]["observed_live_root_token"] == review["target"]["live_root_token"]
assert policy["diagnosis"]["source_remediation_exercised"] is False
assert policy["diagnosis"]["source_remediation_rejected"] is False

assert policy["target"]["hostname_fqdn"] == binding["slackware_current"]["hostname_fqdn"]
assert policy["target"]["accepted_kernel"] == binding["slackware_current"]["accepted_kernel"] == "6.18.45"
assert policy["target"]["boot_image"] == "/boot/vmlinuz-generic"
assert policy["target"]["required_boot_profile"] == binding["slackware_current"]["required_boot_profile"]
assert policy["target"]["dedicated_menuentry"] == review["target"]["dedicated_menuentry"]
assert policy["target"]["dedicated_linux_command"] == "linux /boot/vmlinuz-generic root=/dev/sda2 ro"
assert policy["target"]["grub_cfg_sha256"] == "f9864ba5d8bbe78689b3b1e3ff337049e48026c1cd3f4289b3d4297af3a40593"
assert policy["target"]["custom_grub_script_sha256"] == "766bc1d8fabee076d521c641e19eeb03353733657031975a87131e72dd31bec1"

recovery = policy["recovery_design"]
assert recovery["strategy"] == "interactive-grub-menu-selection"
assert recovery["selection_only"] is True
assert recovery["manual_menu_selection_required"] is True
assert recovery["reboot_required"] is True
assert recovery["reboot_count"] == 1
assert recovery["persistent_boot_selection_mutation_required"] is False
assert recovery["grub_cfg_regeneration_required"] is False
assert recovery["grub_environment_mutation_required"] is False
assert recovery["package_action_required"] is False
assert recovery["repository_refresh_required"] is False

post = policy["post_reboot_characterization"]
assert post["required"] is True
assert post["runtime_probe_permitted"] is False
assert post["expected_live_root_token"] == "/dev/sda2"
assert post["expected_mounted_root_device"] == "/dev/sda2"
assert post["require_uefi"] is True
assert post["require_frozen_kernel"] is True
assert post["require_frozen_boot_image"] is True
assert post["require_frozen_grub_hashes"] is True
assert post["require_no_initrd_command"] is True
assert post["advance_on_success_only_to_fresh_rerun_authorization_review"] is True

assert policy["step139_authorization_reusable"] is False
assert policy["source_change_authorized"] is False
assert policy["configuration_template_change_authorized"] is False
assert policy["contract_change_authorized"] is False
assert policy["machine_execution_authorized"] is False
assert policy["reboot_authorized"] is False
assert policy["boot_mutation_authorized"] is False
assert policy["slackware_current_rerun_authorized"] is False
assert policy["slackware_15_execution_released"] is False
assert policy["slackware_15_execution_authorized"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["machine_action_required"] is False
assert policy["pause_safe"] is True

assert row["failure_class"] == "frozen-boot-selection-mismatch"
assert row["recovery_strategy"] == recovery["strategy"]
assert row["dedicated_menuentry"] == policy["target"]["dedicated_menuentry"]
assert row["frozen_root_device"] == "/dev/sda2"
assert row["live_root_token"] == review["target"]["live_root_token"]
assert row["persistent_boot_mutation_required"] == "false"
assert row["reboot_required"] == "true"
assert row["post_reboot_characterization_required"] == "true"
assert row["replacement_rerun_authorized"] == "false"
assert row["slackware_15_released"] == "false"
assert row["machine_execution_authorized"] == "false"
assert row["next_stage"] == policy["next_stage"]
assert row["status"] == "accepted-design"
PY

printf '%s\n' \
    $'schema\t1' \
    $'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design' \
    $'failure_classification\tfrozen-boot-selection-mismatch' \
    $'recovery_strategy\tinteractive-grub-menu-selection' \
    $'dedicated_menuentry\tSlackware-current slack-update direct generic (no initrd)' \
    $'dedicated_linux_command\tlinux /boot/vmlinuz-generic root=/dev/sda2 ro' \
    $'persistent_boot_selection_mutation_required\tfalse' \
    $'reboot_required_by_design\ttrue' \
    $'post_reboot_characterization_required\ttrue' \
    $'runtime_probe_permitted_during_recovery\tfalse' \
    $'step139_authorization_reusable\tfalse' \
    $'machine_execution_authorized\tfalse' \
    $'reboot_authorized\tfalse' \
    $'boot_mutation_authorized\tfalse' \
    $'slackware_current_rerun_authorized\tfalse' \
    $'slackware_15_execution_released\tfalse' \
    $'repository_refresh_required\tfalse' \
    $'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-authorization-review' \
    $'pause_safe\ttrue'
