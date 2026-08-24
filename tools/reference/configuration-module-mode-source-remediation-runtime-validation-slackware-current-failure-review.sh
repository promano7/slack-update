#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review.sh [--help]

Validate and report the repository-only step-134 review of the consumed,
failed Slackware-current runtime-validation execution. This command performs
no source, configuration, package, boot, repository, or machine mutation.
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
current_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current.sh"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review-policy.json"

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
require_regular_file "$current_harness" "step-132 Slackware-current harness"
require_regular_file "$review" "step-134 failure-review record"
require_regular_file "$policy" "step-134 failure-review policy"

require_sha256 "$source_file" c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c "accepted reference implementation"
require_sha256 "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "frozen configuration template"
require_sha256 "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
require_sha256 "$current_harness" 9f54d2c7d27f46e7d522a8046274d67860a5a59f455e796e467b7f6d23961d62 "step-132 Slackware-current harness"

python3 - "$source_file" "$binding_policy" "$review" "$policy" <<'PY'
import csv
import json
import re
import sys

source_path, binding_path, review_path, policy_path = sys.argv[1:]
with open(source_path, encoding="utf-8") as handle:
    source = handle.read()
with open(binding_path, encoding="utf-8") as handle:
    binding = json.load(handle)
with open(review_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(rows) == 1
row = rows[0]
assert policy["schema"] == 1
assert policy["review_only"] is True
assert policy["step133_evidence"]["archive_sha256"] == row["evidence_sha256"]
assert policy["step133_evidence"]["archive_sha256"] == "78193b32b52094ec164a051f34589e33ca3918eb0a5bc0c0927033ea797840ed"
assert policy["step133_evidence"]["authenticated"] is True
assert policy["step133_evidence"]["assertions_passed_before_failure"] == 16
assert policy["step133_evidence"]["assertions_failed_before_failure"] == 0
assert policy["target"]["hostname_fqdn"] == "vbox-slackcurrent.vbox-slackcurrent.org"
assert policy["target"]["running_kernel"] == "6.18.45"
assert policy["target"]["boot_profile"] == "grub-direct-generic-no-initrd"
assert policy["target"]["root_device"] == "/dev/sda2"
assert policy["target"]["characterization_accepted"] is True
assert policy["execution"]["attempt_consumed"] is True
assert policy["execution"]["runtime_probe_completed"] is False
assert policy["execution"]["runtime_probe_accepted"] is False
assert policy["execution"]["rerun_under_step132_authorization_permitted"] is False
assert all(policy["non_mutation"].values())
assert policy["failure"]["stage"] == "probe_boot_module"
assert policy["failure"]["function"] == "probe_direct_generic_boot_layout"
assert policy["failure"]["type"] == "unbound-shell-variable"
assert policy["failure"]["variable"] == "GENERIC_KERNEL_LINK"
assert policy["failure"]["classification"] == "source-runtime-initialization-defect"
assert policy["remediation_required"] is True
assert policy["source_change_authorized"] is False
assert policy["machine_execution_authorized"] is False
assert policy["slackware_current_rerun_authorized"] is False
assert policy["slackware_15_execution_released"] is False
assert policy["slackware_15_execution_authorized"] is False
assert policy["repository_refresh_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["machine_action_required"] is False
assert policy["pause_safe"] is True
assert row["execution_attempt_consumed"] == "true"
assert row["runtime_probe_completed"] == "false"
assert row["system_state_preserved"] == "true"
assert row["failure_class"] == "source-runtime-initialization-defect"
assert row["failure_variable"] == "GENERIC_KERNEL_LINK"
assert row["rerun_authorized"] == "false"
assert row["slackware_15_released"] == "false"
assert row["remediation_required"] == "true"
assert row["status"] == "accepted-failure-review"
assert binding["source_sha256"] == policy["source_sha256"]
assert binding["template_sha256"] == policy["template_sha256"]
assert binding["slackware_current"]["hostname_fqdn"] == policy["target"]["hostname_fqdn"]
assert binding["slackware_current"]["accepted_kernel"] == policy["target"]["running_kernel"]
assert binding["slackware_current"]["required_boot_profile"] == policy["target"]["boot_profile"]
assert binding["slackware_current"]["expected_root_device"] == policy["target"]["root_device"]
assert binding["slackware_15"]["execution_authorized"] is False
assert binding["slackware_15"]["authorization_consumable"] is False

classifier = re.search(r"classify_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", source, re.S)
probe = re.search(r"probe_direct_generic_boot_layout\(\) \{(?P<body>.*?)\n\}", source, re.S)
assert classifier is not None and probe is not None
assert "local generic_link=$4" in classifier.group("body")
assert "GENERIC_KERNEL_LINK=/boot/vmlinuz-generic" in classifier.group("body")
assert '"$GENERIC_KERNEL_LINK"' in probe.group("body")
assert "classify_direct_generic_boot_layout" in probe.group("body")
assert source.count("GENERIC_KERNEL_LINK=/boot/vmlinuz-generic") == 1
PY

printf '%s\n' \
    $'schema\t1' \
    $'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-failure-review' \
    $'evidence_archive_sha256\t78193b32b52094ec164a051f34589e33ca3918eb0a5bc0c0927033ea797840ed' \
    $'evidence_authenticated\ttrue' \
    $'target_characterization_accepted\ttrue' \
    $'execution_attempt_consumed\ttrue' \
    $'runtime_probe_completed\tfalse' \
    $'runtime_probe_accepted\tfalse' \
    $'system_state_preserved\ttrue' \
    $'failure_stage\tprobe_boot_module' \
    $'failure_function\tprobe_direct_generic_boot_layout' \
    $'failure_type\tunbound-shell-variable' \
    $'failure_variable\tGENERIC_KERNEL_LINK' \
    $'failure_classification\tsource-runtime-initialization-defect' \
    $'root_cause_confirmed\ttrue' \
    $'remediation_required\ttrue' \
    $'source_change_authorized\tfalse' \
    $'machine_execution_authorized\tfalse' \
    $'slackware_current_rerun_authorized\tfalse' \
    $'slackware_15_execution_released\tfalse' \
    $'slackware_15_execution_authorized\tfalse' \
    $'repository_refresh_required\tfalse' \
    $'slackware_repository_state_dependency\tfalse' \
    $'machine_action_required\tfalse' \
    $'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-design' \
    $'pause_safe\ttrue'
