#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review.sh [--help]

Validate and report the repository-only step-148 review of the accepted
Slackware-current post-recovery rerun evidence. This command performs no source,
configuration, package, boot, repository, or machine mutation.
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
step146_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization-review-policy.json"
step146_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization.tsv"
step147_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun.sh"
review_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review-policy.json"
review_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review.tsv"

expected_step146_policy_sha256=0a7959de44c4ca849d4f8064d1a6b58632f5735701d2cbf3de626648252bcc8d
expected_step146_record_sha256=200a798e369c5043147f34922a80785c27a73c1b3a21badce5d9bc6ed7205818
expected_step147_harness_sha256=60b126b458c69226b8353a13e91b5f3ce1ce0b5a83a00314ce51d2e0857de379
expected_review_policy_sha256=de2813f328b1af80531d68a22c049f9c3be58b6a445398c5c3795b49036ead4b
expected_review_record_sha256=9f8c384d4709e8161ac2f6a3e928b7f3e7baea677e7d850c4c061c1aa4d71361

sha() { sha256sum -- "$1" | awk '{print $1}'; }
require_hash() {
    local path=$1 expected=$2 label=$3
    [[ -f $path && ! -L $path ]] || { printf 'error: unsafe or missing %s\n' "$label" >&2; exit 1; }
    [[ $(sha "$path") == "$expected" ]] || { printf 'error: %s SHA-256 mismatch\n' "$label" >&2; exit 1; }
}

require_hash "$step146_policy" "$expected_step146_policy_sha256" 'step-146 authorization policy'
require_hash "$step146_record" "$expected_step146_record_sha256" 'step-146 authorization record'
require_hash "$step147_harness" "$expected_step147_harness_sha256" 'step-147 execution harness'
require_hash "$review_policy" "$expected_review_policy_sha256" 'step-148 review policy'
require_hash "$review_record" "$expected_review_record_sha256" 'step-148 review record'
python3 -m json.tool "$review_policy" >/dev/null

python3 - "$step146_policy" "$review_policy" <<'PY'
import json
import sys

step146_path, review_path = sys.argv[1:]
with open(step146_path, encoding="utf-8") as handle:
    step146 = json.load(handle)
with open(review_path, encoding="utf-8") as handle:
    review = json.load(handle)

assert step146["schema"] == 1
assert step146["authorization"]["authorization_id"] == "runtime-slackware-current-post-recovery-rerun"
assert step146["authorization"]["authorization_consumable"] is True
assert step146["authorization"]["machine_execution_limit_total"] == 1
assert step146["authorization"]["reboot_limit"] == 0
assert step146["slackware_current"]["expected_live_root_token"] == "/dev/sda2"

assert review["schema"] == 1
assert review["review_only"] is True
assert review["step146_authorization_policy_sha256"] == "0a7959de44c4ca849d4f8064d1a6b58632f5735701d2cbf3de626648252bcc8d"
assert review["step146_authorization_record_sha256"] == "200a798e369c5043147f34922a80785c27a73c1b3a21badce5d9bc6ed7205818"
assert review["step147_execution_harness_sha256"] == "60b126b458c69226b8353a13e91b5f3ce1ce0b5a83a00314ce51d2e0857de379"
assert review["evidence"]["archive_sha256"] == "cccabfa5e3258fee7485bab6cb6b5b0dbc687cf8850d0b96deb9e96854072a46"
assert review["evidence"]["authenticated"] is True
assert review["evidence"]["reviewed"] is True
assert review["slackware_current"]["runtime_probe_invoked"] is True
assert review["slackware_current"]["runtime_probe_accepted"] is True
assert review["slackware_current"]["system_state_preserved"] is True
assert review["slackware_current"]["authorization_consumed_by_execution"] is True
assert review["slackware_current"]["authorization_reusable"] is False
assert review["source_remediation"]["exercised"] is True
assert review["source_remediation"]["accepted"] is True
assert review["non_mutation_review"]["packages_preserved"] is True
assert review["non_mutation_review"]["slackpkg_metadata_preserved"] is True
assert review["non_mutation_review"]["boot_state_preserved"] is True
assert review["non_mutation_review"]["source_preserved"] is True
assert review["non_mutation_review"]["template_preserved"] is True
assert review["slackware_15"]["execution_authorized"] is False
assert review["slackware_15"]["released_to_fresh_authorization_review"] is True
assert review["slackware_15"]["fresh_authorization_required"] is True
assert review["slackware_15"]["fresh_execution_harness_required"] is True
assert review["slackware_15"]["step132_slackware15_execution_harness_reusable"] is False
assert review["machine_action_required"] is False
assert review["repository_refresh_required"] is False
assert review["slackware_repository_state_dependency"] is False
assert review["pause_safe"] is True
PY

printf 'scenario\t%s\n' 'phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review'
printf 'evidence_archive_sha256\t%s\n' 'cccabfa5e3258fee7485bab6cb6b5b0dbc687cf8850d0b96deb9e96854072a46'
printf 'step146_authorization_policy_sha256\t%s\n' "$expected_step146_policy_sha256"
printf 'step146_authorization_record_sha256\t%s\n' "$expected_step146_record_sha256"
printf 'step147_execution_harness_sha256\t%s\n' "$expected_step147_harness_sha256"
printf 'review_policy_sha256\t%s\n' "$expected_review_policy_sha256"
printf 'review_record_sha256\t%s\n' "$expected_review_record_sha256"
printf 'running_kernel\t%s\n' '6.18.45'
printf 'boot_image\t%s\n' '/boot/vmlinuz-generic'
printf 'live_root_token\t%s\n' '/dev/sda2'
printf 'mounted_root_device\t%s\n' '/dev/sda2'
printf 'boot_profile\t%s\n' 'grub-direct-generic-no-initrd'
printf 'runtime_probe_invoked\t%s\n' 'true'
printf 'runtime_probe_accepted\t%s\n' 'true'
printf 'system_state_preserved\t%s\n' 'true'
printf 'authorization_consumed\t%s\n' 'true'
printf 'authorization_reusable\t%s\n' 'false'
printf 'source_remediation_exercised\t%s\n' 'true'
printf 'source_remediation_accepted\t%s\n' 'true'
printf 'slackware_current_validation_accepted\t%s\n' 'true'
printf 'slackware_15_released_to_fresh_authorization_review\t%s\n' 'true'
printf 'slackware_15_execution_authorized\t%s\n' 'false'
printf 'step132_slackware15_harness_reusable\t%s\n' 'false'
printf 'machine_action_required\t%s\n' 'false'
printf 'repository_refresh_required\t%s\n' 'false'
printf 'slackware_repository_state_dependency\t%s\n' 'false'
printf 'next_stage\t%s\n' 'phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review'
printf 'pause_safe\t%s\n' 'true'
