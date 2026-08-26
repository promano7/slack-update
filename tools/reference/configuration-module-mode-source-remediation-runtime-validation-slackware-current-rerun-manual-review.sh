#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review.sh [--help]

Validate and report the repository-only step-141 manual review of the failed
Slackware-current rerun characterization. This command performs no source,
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
rerun_authorization_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review-policy.json"
rerun_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun.sh"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review-policy.json"

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
require_regular_file "$rerun_authorization_policy" "step-139 rerun-authorization policy"
require_regular_file "$rerun_harness" "step-140 rerun harness"
require_regular_file "$review" "step-141 manual-review record"
require_regular_file "$policy" "step-141 manual-review policy"

require_sha256 "$source_file" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 "accepted remediated reference implementation"
require_sha256 "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "frozen configuration template"
require_sha256 "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
require_sha256 "$rerun_authorization_policy" 5d0dc91852d8efe5ff203be68468ca5db4cfb6c718e1f4430caf4bf75550a6ba "step-139 rerun-authorization policy"
require_sha256 "$rerun_harness" 0099213437acb8184019dd4f98f63de8f1c6821924ad08f93e8ff85f4288b120 "step-140 rerun harness"

python3 - "$binding_policy" "$rerun_authorization_policy" "$review" "$policy" <<'PY'
import csv
import json
import sys

binding_path, authorization_path, review_path, policy_path = sys.argv[1:]
with open(binding_path, encoding="utf-8") as handle:
    binding = json.load(handle)
with open(authorization_path, encoding="utf-8") as handle:
    authorization = json.load(handle)
with open(review_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(rows) == 1
row = rows[0]
assert policy["schema"] == 1
assert policy["review_only"] is True
assert policy["step140_evidence"]["archive_sha256"] == row["evidence_sha256"]
assert policy["step140_evidence"]["archive_sha256"] == "def71e947186de4e3df4f4af4cddc55f0b41397076e17fbc1b97f13129e58eb8"
assert policy["step140_evidence"]["authenticated"] is True
assert policy["step140_evidence"]["passes"] == 16
assert policy["step140_evidence"]["failures"] == 1
assert policy["step140_evidence"]["skips"] == 2
assert policy["source_sha256"] == authorization["source_sha256"]
assert policy["template_sha256"] == authorization["template_sha256"]
assert policy["step132_binding_policy_sha256"] == authorization["accepted_step132_target_binding_policy_sha256"]
assert policy["step139_rerun_authorization_policy_sha256"] == "5d0dc91852d8efe5ff203be68468ca5db4cfb6c718e1f4430caf4bf75550a6ba"
assert policy["step140_rerun_harness_sha256"] == authorization["slackware_current"]["execution_harness_sha256"]

assert policy["target"]["hostname_fqdn"] == binding["slackware_current"]["hostname_fqdn"]
assert policy["target"]["running_kernel"] == binding["slackware_current"]["accepted_kernel"]
assert policy["target"]["required_boot_profile"] == binding["slackware_current"]["required_boot_profile"]
assert policy["target"]["frozen_root_device"] == binding["slackware_current"]["expected_root_device"]
assert policy["target"]["mounted_root_device"] == "/dev/sda2"
assert policy["target"]["live_root_token"] == "UUID=d1a09d24-cdbf-41cd-8cd6-2faff4d72863"
assert policy["target"]["dedicated_menuentry_root_token"] == "/dev/sda2"
assert policy["target"]["underlying_root_device_matches"] is True
assert policy["target"]["frozen_boot_selection_matches"] is False
assert policy["target"]["characterization_accepted"] is False

assert policy["execution"]["rerun_attempt_started"] is True
assert policy["execution"]["rerun_attempt_consumed"] is True
assert policy["execution"]["harness_reported_authorization_consumed_by_execution"] is False
assert policy["execution"]["runtime_probe_completed"] is False
assert policy["execution"]["runtime_probe_accepted"] is False
assert policy["execution"]["rerun_under_step139_authorization_permitted"] is False
assert all(policy["non_mutation"].values())
assert policy["failure"]["stage"] == "pre-probe-target-characterization"
assert policy["failure"]["assertion"] == "live-root-device-matches-frozen-direct-generic-boot-entry"
assert policy["failure"]["classification"] == "frozen-boot-selection-mismatch"
assert policy["failure"]["source_runtime_initialization_remediation_exercised"] is False
assert policy["failure"]["source_runtime_initialization_remediation_rejected"] is False
assert policy["boot_selection_remediation_required"] is True
assert policy["source_change_required"] is False
assert policy["source_change_authorized"] is False
assert policy["machine_execution_authorized"] is False
assert policy["reboot_authorized"] is False
assert policy["boot_mutation_authorized"] is False
assert policy["slackware_current_rerun_authorized"] is False
assert policy["slackware_15_execution_released"] is False
assert policy["slackware_15_execution_authorized"] is False
assert policy["repository_refresh_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["machine_action_required"] is False
assert policy["pause_safe"] is True

assert row["characterization_accepted"] == "false"
assert row["runtime_probe_completed"] == "false"
assert row["system_state_preserved"] == "true"
assert row["failure_class"] == "frozen-boot-selection-mismatch"
assert row["live_root_token"] == policy["target"]["live_root_token"]
assert row["mounted_root_device"] == policy["target"]["mounted_root_device"]
assert row["frozen_root_device"] == policy["target"]["frozen_root_device"]
assert row["rerun_attempt_consumed"] == "true"
assert row["rerun_authorized"] == "false"
assert row["slackware_15_released"] == "false"
assert row["remediation_required"] == "true"
assert row["status"] == "accepted-manual-review"

assert authorization["machine_execution_limit_total"] == 1
assert authorization["slackware_current"]["machine_execution_limit"] == 1
assert authorization["slackware_current"]["expected_root_device"] == "/dev/sda2"
assert authorization["slackware_current"]["direct_generic_menuentry"] == policy["target"]["dedicated_menuentry"]
assert authorization["slackware_15"]["execution_authorized"] is False
assert authorization["slackware_15"]["authorization_consumable"] is False
PY

printf '%s\n' \
    $'schema\t1' \
    $'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-manual-review' \
    $'evidence_archive_sha256\tdef71e947186de4e3df4f4af4cddc55f0b41397076e17fbc1b97f13129e58eb8' \
    $'evidence_authenticated\ttrue' \
    $'target_characterization_accepted\tfalse' \
    $'underlying_root_device_matches\ttrue' \
    $'frozen_boot_selection_matches\tfalse' \
    $'runtime_probe_completed\tfalse' \
    $'runtime_probe_accepted\tfalse' \
    $'system_state_preserved\ttrue' \
    $'failure_stage\tpre-probe-target-characterization' \
    $'failure_classification\tfrozen-boot-selection-mismatch' \
    $'source_runtime_initialization_remediation_exercised\tfalse' \
    $'rerun_attempt_consumed\ttrue' \
    $'rerun_under_step139_authorization_permitted\tfalse' \
    $'boot_selection_remediation_required\ttrue' \
    $'source_change_required\tfalse' \
    $'source_change_authorized\tfalse' \
    $'machine_execution_authorized\tfalse' \
    $'reboot_authorized\tfalse' \
    $'boot_mutation_authorized\tfalse' \
    $'slackware_current_rerun_authorized\tfalse' \
    $'slackware_15_execution_released\tfalse' \
    $'slackware_15_execution_authorized\tfalse' \
    $'repository_refresh_required\tfalse' \
    $'slackware_repository_state_dependency\tfalse' \
    $'machine_action_required\tfalse' \
    $'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design' \
    $'pause_safe\ttrue'
