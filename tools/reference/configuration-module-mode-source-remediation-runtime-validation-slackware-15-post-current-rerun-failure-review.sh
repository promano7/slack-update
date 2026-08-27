#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review.sh [--help]

Validate and report the repository-only step-151 review of the consumed,
fail-closed Slackware 15.0 post-current-rerun execution. This command performs
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
authorization_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review-policy.json"
authorization_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization.tsv"
execution_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
accepted_closure="$repo_root/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review-policy.json"

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

require_regular_file "$source_file" "accepted remediated reference implementation"
require_regular_file "$template" "frozen configuration template"
require_regular_file "$authorization_policy" "step-149 authorization policy"
require_regular_file "$authorization_record" "step-149 authorization record"
require_regular_file "$execution_harness" "step-150 execution harness"
require_regular_file "$binding_policy" "step-132 target-binding policy"
require_regular_file "$accepted_closure" "accepted Slackware 15.0 ELILO closure"
require_regular_file "$review" "step-151 failure-review record"
require_regular_file "$policy" "step-151 failure-review policy"

require_sha256 "$source_file" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 "accepted remediated reference implementation"
require_sha256 "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "frozen configuration template"
require_sha256 "$authorization_policy" d2877fce33c417ff8318fbed3e64a0fe409786f475a1d25ccf97f712a159037f "step-149 authorization policy"
require_sha256 "$authorization_record" 7058af65141f55d664857ada09d1c29431012f78925c38d4af08d628478d0634 "step-149 authorization record"
require_sha256 "$execution_harness" 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 "step-150 execution harness"
require_sha256 "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
require_sha256 "$accepted_closure" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "accepted Slackware 15.0 ELILO closure"

python3 - "$authorization_policy" "$execution_harness" "$binding_policy" "$accepted_closure" "$review" "$policy" <<'PY'
import csv
import json
import sys

auth_path, harness_path, binding_path, closure_path, review_path, policy_path = sys.argv[1:]
with open(auth_path, encoding="utf-8") as handle:
    auth = json.load(handle)
with open(harness_path, encoding="utf-8") as handle:
    harness = handle.read()
with open(binding_path, encoding="utf-8") as handle:
    binding = json.load(handle)
with open(closure_path, encoding="utf-8") as handle:
    closure = json.load(handle)
with open(review_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(rows) == 1
row = rows[0]
assert policy["schema"] == 1
assert policy["review_only"] is True
assert policy["step150_evidence"]["archive_sha256"] == row["evidence_sha256"]
assert policy["step150_evidence"]["archive_sha256"] == "72d62a7b12f95674eefe31fd6b9698519c717d8a0a4d36a90270e62024e5cb78"
assert policy["step150_evidence"]["authenticated"] is True
assert policy["step150_evidence"]["passes"] == 19
assert policy["step150_evidence"]["failures"] == 2
assert policy["step150_evidence"]["skips"] == 2
assert policy["target"]["hostname_fqdn"] == "vbox-slack15.vbox-slack15.org"
assert policy["target"]["running_kernel"] == "5.15.209"
assert policy["target"]["required_boot_profile"] == "elilo-generic-with-initrd"
assert policy["target"]["accepted_elilo_core_identity_match"] is True
assert policy["execution"]["attempt_consumed"] is True
assert policy["execution"]["runtime_probe_invoked"] is False
assert policy["execution"]["runtime_probe_accepted"] is False
assert policy["execution"]["rerun_under_step149_authorization_permitted"] is False
assert all(policy["non_mutation"].values())
assert policy["characterization_failure"]["mkinitrd_config"]["observed"] == "absent"
assert policy["characterization_failure"]["mkinitrd_config"]["accepted_elilo_closure_froze_predicate"] is False
assert policy["characterization_failure"]["grub_path"]["observed"] == "directory"
assert policy["characterization_failure"]["grub_path"]["accepted_elilo_closure_froze_predicate"] is False
assert policy["characterization_failure"]["runtime_probe_withheld_fail_closed"] is True
assert policy["characterization_failure"]["classification"] == "unfrozen-target-characterization-assumption-mismatch"
assert policy["characterization_failure"]["boot_regression_confirmed"] is False
assert policy["characterization_failure"]["source_runtime_defect_confirmed"] is False
assert policy["characterization_failure"]["harness_characterization_overconstrained_relative_to_accepted_evidence"] is True
assert policy["remediation_design_required"] is True
assert policy["execution_harness_change_authorized"] is False
assert policy["machine_execution_authorized"] is False
assert policy["slackware_15_rerun_authorized"] is False
assert policy["repository_refresh_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["machine_action_required"] is False
assert policy["future_work_requires_fresh_boundary"] is True
assert policy["pause_safe"] is True
assert row["execution_attempt_consumed"] == "true"
assert row["runtime_probe_invoked"] == "false"
assert row["runtime_probe_accepted"] == "false"
assert row["system_state_preserved"] == "true"
assert row["mkinitrd_observed"] == "absent"
assert row["grub_path_observed"] == "directory"
assert row["accepted_closure_froze_failed_predicates"] == "false"
assert row["failure_classification"] == "unfrozen-target-characterization-assumption-mismatch"
assert row["boot_regression_confirmed"] == "false"
assert row["rerun_authorized"] == "false"
assert row["status"] == "accepted-failure-review"

assert auth["authorization"]["authorization_consumed_on_execution_attempt"] is True
assert auth["authorization"]["retry_authorized"] is False
assert auth["target"]["accepted_kernel"] == policy["target"]["running_kernel"]
assert auth["target"]["elilo_conf_sha256"] == policy["target"]["elilo_conf_sha256"]
assert binding["slackware_15"]["required_boot_profile"] == policy["target"]["required_boot_profile"]
assert closure["stable_boot_identity_verified"] is True
assert closure["active_kernel"] == policy["target"]["running_kernel"]
assert closure["elilo_conf_sha256"] == policy["target"]["elilo_conf_sha256"]

# The accepted ELILO closure does not freeze either predicate that failed in step 150.
closure_text = json.dumps(closure, sort_keys=True).lower()
assert "mkinitrd" not in closure_text
assert "grub" not in closure_text

# Step 150 added both fail-closed predicates independently of the accepted closure record.
assert "[[ -f /etc/mkinitrd.conf && ! -L /etc/mkinitrd.conf ]]" in harness
assert "[[ ! -d /boot/grub && ! -L /boot/grub ]]" in harness
assert "runtime probing is withheld because fail-closed target characterization failed" in harness
PY

printf '%s\n' \
    $'schema\t1' \
    $'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review' \
    $'evidence_archive_sha256\t72d62a7b12f95674eefe31fd6b9698519c717d8a0a4d36a90270e62024e5cb78' \
    $'evidence_authenticated\ttrue' \
    $'accepted_elilo_core_identity_match\ttrue' \
    $'execution_attempt_consumed\ttrue' \
    $'runtime_probe_invoked\tfalse' \
    $'runtime_probe_accepted\tfalse' \
    $'system_state_preserved\ttrue' \
    $'mkinitrd_config_observed\tabsent' \
    $'grub_path_observed\tdirectory' \
    $'accepted_closure_froze_failed_predicates\tfalse' \
    $'failure_classification\tunfrozen-target-characterization-assumption-mismatch' \
    $'boot_regression_confirmed\tfalse' \
    $'source_runtime_defect_confirmed\tfalse' \
    $'harness_characterization_overconstrained\ttrue' \
    $'remediation_design_required\ttrue' \
    $'execution_harness_change_authorized\tfalse' \
    $'machine_execution_authorized\tfalse' \
    $'slackware_15_rerun_authorized\tfalse' \
    $'repository_refresh_required\tfalse' \
    $'slackware_repository_state_dependency\tfalse' \
    $'machine_action_required\tfalse' \
    $'future_work_requires_fresh_boundary\ttrue' \
    $'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design' \
    $'pause_safe\ttrue'
