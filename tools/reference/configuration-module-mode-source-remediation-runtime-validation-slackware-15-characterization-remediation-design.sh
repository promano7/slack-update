#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design.sh [--help]

Validate and report the repository-only step-152 Slackware 15.0 target
characterization remediation design. This command performs no source,
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
step150_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh"
step151_review="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review.tsv"
step151_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review-policy.json"
step151_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review.md"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
accepted_closure="$repo_root/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design-policy.json"

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

require_regular_file "$step150_harness" "consumed step-150 execution harness"
require_regular_file "$step151_review" "step-151 failure-review record"
require_regular_file "$step151_policy" "step-151 failure-review policy"
require_regular_file "$step151_doc" "step-151 reference document"
require_regular_file "$binding_policy" "step-132 target-binding policy"
require_regular_file "$accepted_closure" "accepted Slackware 15.0 ELILO closure"
require_regular_file "$design" "step-152 remediation design"
require_regular_file "$policy" "step-152 remediation-design policy"

require_sha256 "$step150_harness" 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 "consumed step-150 execution harness"
require_sha256 "$step151_review" 5b3a30a73ba3596d2b6db4acef4b1198d541674824211d1c61d0f42c62e0b7d1 "step-151 failure-review record"
require_sha256 "$step151_policy" d46131b85ba1857412890e0738487dc1c0df8a6406646d8f93758e6fc41c9791 "step-151 failure-review policy"
require_sha256 "$step151_doc" 3f64d924825a2a5f52e5a62a79f8053f0d7ecc1ef61db436df52887e32d9eb86 "step-151 reference document"
require_sha256 "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
require_sha256 "$accepted_closure" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "accepted Slackware 15.0 ELILO closure"

python3 - "$step150_harness" "$step151_review" "$step151_policy" "$binding_policy" "$accepted_closure" "$design" "$policy" <<'PY'
import csv
import json
import sys

harness_path, review_path, review_policy_path, binding_path, closure_path, design_path, policy_path = sys.argv[1:]
with open(harness_path, encoding="utf-8") as handle:
    harness = handle.read()
with open(review_path, encoding="utf-8", newline="") as handle:
    review_rows = list(csv.DictReader(handle, delimiter="\t"))
with open(review_policy_path, encoding="utf-8") as handle:
    review_policy = json.load(handle)
with open(binding_path, encoding="utf-8") as handle:
    binding = json.load(handle)
with open(closure_path, encoding="utf-8") as handle:
    closure = json.load(handle)
with open(design_path, encoding="utf-8", newline="") as handle:
    design_rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(review_rows) == 1
review = review_rows[0]
assert review["failure_classification"] == "unfrozen-target-characterization-assumption-mismatch"
assert review["runtime_probe_invoked"] == "false"
assert review["system_state_preserved"] == "true"
assert review["rerun_authorized"] == "false"
assert review_policy["characterization_failure"]["harness_characterization_overconstrained_relative_to_accepted_evidence"] is True
assert review_policy["characterization_failure"]["mkinitrd_config"]["accepted_elilo_closure_froze_predicate"] is False
assert review_policy["characterization_failure"]["grub_path"]["accepted_elilo_closure_froze_predicate"] is False
assert review_policy["execution"]["attempt_consumed"] is True
assert review_policy["execution"]["runtime_probe_invoked"] is False
assert review_policy["execution"]["rerun_under_step149_authorization_permitted"] is False

mkinitrd_gate = "[[ -f /etc/mkinitrd.conf && ! -L /etc/mkinitrd.conf ]]"
grub_gate = "[[ ! -d /boot/grub && ! -L /boot/grub ]]"
assert mkinitrd_gate in harness
assert grub_gate in harness
assert "runtime probing is withheld because fail-closed target characterization failed" in harness
assert "mkinitrd_config_sha256=%s" in harness
assert "grub_directory_kind=" in harness

closure_text = json.dumps(closure, sort_keys=True).lower()
assert "mkinitrd" not in closure_text
assert "grub" not in closure_text
assert closure["stable_boot_identity_verified"] is True
assert closure["hostname_fqdn"] == "vbox-slack15.vbox-slack15.org"
assert closure["active_kernel"] == "5.15.209"
assert closure["elilo_conf_sha256"] == "94b77b9f70a9d3b22d146c36af0ee6bbf09133d0b1931a2e731e881d3edc37f6"

step132 = binding["slackware_15"]
assert step132["required_boot_profile"] == "elilo-generic-with-initrd"
assert step132["accepted_kernel"] == "5.15.209"
assert step132["accepted_closure_record_sha256"] == "7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635"
assert step132["expected_runtime_verdict"]["boot_initrd_available"] == 1
assert step132["expected_runtime_verdict"]["boot_grub_available"] == 0

assert len(design_rows) == 1
row = design_rows[0]
assert row == {
    "design_id": "slackware-15-characterization-remediation",
    "failure_classification": "unfrozen-target-characterization-assumption-mismatch",
    "identity_gate_scope": "accepted-elilo-core-identity-only",
    "unfrozen_mkinitrd_predicate": "evidence-only-not-pre-probe-gate",
    "unfrozen_grub_predicate": "evidence-only-not-pre-probe-gate",
    "capability_observation_scope": "probe-output-and-nonmutation-evidence",
    "runtime_acceptance_scope": "auto-fail-closed-incomplete-layout-semantics",
    "historical_target_binding_mutation": "false",
    "source_change": "false",
    "configuration_template_change": "false",
    "contract_change": "false",
    "execution_harness_change_authorized": "false",
    "machine_execution_authorized": "false",
    "status": "design-frozen",
}

assert policy["schema"] == 1
assert policy["scenario"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design"
assert policy["design_only"] is True
assert policy["accepted_source_sha256"] == review_policy["source_sha256"]
assert policy["configuration_template_sha256"] == review_policy["template_sha256"]
assert policy["failure_binding"]["classification"] == row["failure_classification"]
assert policy["failure_binding"]["step150_attempt_consumed"] is True
assert policy["failure_binding"]["runtime_probe_invoked"] is False
assert policy["failure_binding"]["step149_authorization_reusable"] is False
identity = policy["frozen_target_identity_gate"]
assert identity["scope"] == row["identity_gate_scope"]
assert identity["hostname_fqdn"] == closure["hostname_fqdn"]
assert identity["running_kernel"] == closure["active_kernel"]
assert identity["required_boot_image_suffix"] == closure["required_boot_image_suffix"]
assert identity["elilo_conf_sha256"] == closure["elilo_conf_sha256"]
inputs = policy["unfrozen_capability_inputs"]
assert inputs["mkinitrd_config"]["step150_observed"] == "absent"
assert inputs["mkinitrd_config"]["historical_closure_froze_predicate"] is False
assert inputs["mkinitrd_config"]["future_pre_probe_identity_gate"] is False
assert inputs["mkinitrd_config"]["preserve_as_evidence"] is True
assert inputs["grub_path"]["step150_observed"] == "directory"
assert inputs["grub_path"]["historical_closure_froze_predicate"] is False
assert inputs["grub_path"]["future_pre_probe_identity_gate"] is False
assert inputs["grub_path"]["preserve_as_evidence"] is True
remediation = policy["designed_harness_remediation"]
assert remediation["scope"] == "slackware-15-runtime-target-characterization-only"
assert remediation["successor_harness_required"] is True
assert remediation["step150_harness_is_consumed_and_immutable"] is True
assert remediation["remove_mkinitrd_regular_file_pre_probe_requirement"] is True
assert remediation["remove_grub_absence_pre_probe_requirement"] is True
assert remediation["preserve_mkinitrd_observation_in_boot_state_evidence"] is True
assert remediation["preserve_grub_path_observation_in_boot_state_evidence"] is True
assert remediation["runtime_probe_may_run_only_after_frozen_target_identity_gate_passes"] is True
assert remediation["runtime_capability_bits_are_probe_observations_not_historical_identity_predicates"] is True
assert remediation["do_not_reuse_step132_exact_capability_vector_as_fresh_target_identity"] is True
assert remediation["historical_step132_target_binding_remains_immutable"] is True
assert remediation["historical_step149_authorization_remains_consumed"] is True
runtime = policy["future_runtime_acceptance_semantics"]
assert runtime["boot_mode"] == "auto"
assert runtime["boot_module_state"] == "unavailable"
assert runtime["boot_module_run"] == 0
assert runtime["boot_preparation_layout"] == "unknown"
assert runtime["boot_module_reason"] == "no supported initrd or GRUB preparation path was detected"
assert runtime["boot_direct_generic_available"] == 0
assert runtime["boot_initrd_available"] == "observed-not-predeclared"
assert runtime["boot_grub_available"] == "observed-not-predeclared"
assert runtime["require_fail_closed_incomplete_layout_semantics"] is True
assert all(policy["planned_regression_boundary"].values())
assert policy["source_change_authorized"] is False
assert policy["configuration_template_change_authorized"] is False
assert policy["contract_change_authorized"] is False
assert policy["target_binding_change_authorized"] is False
assert policy["execution_harness_change_authorized"] is False
assert policy["machine_execution_authorized"] is False
assert policy["slackware_15_rerun_authorized"] is False
assert policy["repository_refresh_required"] is False
assert policy["slackware_repository_state_dependency"] is False
assert policy["machine_action_required"] is False
assert policy["future_work_requires_fresh_boundary"] is True
assert policy["next_stage"] == "phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review"
assert policy["pause_safe"] is True
PY

printf '%s\n' \
    $'schema\t1' \
    $'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design' \
    $'failure_classification\tunfrozen-target-characterization-assumption-mismatch' \
    $'identity_gate_scope\taccepted-elilo-core-identity-only' \
    $'mkinitrd_future_pre_probe_gate\tfalse' \
    $'grub_path_future_pre_probe_gate\tfalse' \
    $'mkinitrd_observation_preserved\ttrue' \
    $'grub_path_observation_preserved\ttrue' \
    $'runtime_capability_bits_predeclared\tfalse' \
    $'runtime_acceptance_scope\tauto-fail-closed-incomplete-layout-semantics' \
    $'step150_harness_immutable\ttrue' \
    $'step149_authorization_reusable\tfalse' \
    $'historical_target_binding_mutation\tfalse' \
    $'source_change_authorized\tfalse' \
    $'configuration_template_change_authorized\tfalse' \
    $'contract_change_authorized\tfalse' \
    $'execution_harness_change_authorized\tfalse' \
    $'machine_execution_authorized\tfalse' \
    $'slackware_15_rerun_authorized\tfalse' \
    $'repository_refresh_required\tfalse' \
    $'slackware_repository_state_dependency\tfalse' \
    $'machine_action_required\tfalse' \
    $'future_work_requires_fresh_boundary\ttrue' \
    $'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review' \
    $'pause_safe\ttrue'
