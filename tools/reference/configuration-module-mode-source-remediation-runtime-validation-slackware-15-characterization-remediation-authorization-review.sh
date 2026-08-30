#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review.sh [--help]

Validate and report the repository-only step-153 authorization for implementing
the step-152 Slackware 15.0 characterization remediation as one new successor
execution harness. This command performs no source, configuration, package,
boot, repository, or machine mutation.
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
design="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design.tsv"
design_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design-policy.json"
design_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-design.md"
step150_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh"
step151_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-failure-review-policy.json"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
accepted_closure="$repo_root/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review-policy.json"
successor="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh"

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

require_regular_file "$design" "step-152 remediation design"
require_regular_file "$design_policy" "step-152 remediation-design policy"
require_regular_file "$design_doc" "step-152 reference document"
require_regular_file "$step150_harness" "consumed step-150 execution harness"
require_regular_file "$step151_policy" "step-151 failure-review policy"
require_regular_file "$binding_policy" "step-132 target-binding policy"
require_regular_file "$accepted_closure" "accepted Slackware 15.0 ELILO closure"
require_regular_file "$authorization" "step-153 authorization record"
require_regular_file "$policy" "step-153 authorization-review policy"

require_sha256 "$design" 0c0d509daa71fefd527e734c305bef18209e0a4ef157f59477d83e94febd0c89 "step-152 remediation design"
require_sha256 "$design_policy" 910a5842cadebc282163f1527c3ef1c370ecbe9913d9ed29f23b18b448838b06 "step-152 remediation-design policy"
require_sha256 "$design_doc" 28e82f7367428de987bfec1bcb160bd40d50d5ad72e595f79239960c760a1432 "step-152 reference document"
require_sha256 "$step150_harness" 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 "consumed step-150 execution harness"
require_sha256 "$step151_policy" d46131b85ba1857412890e0738487dc1c0df8a6406646d8f93758e6fc41c9791 "step-151 failure-review policy"
require_sha256 "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
require_sha256 "$accepted_closure" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "accepted Slackware 15.0 ELILO closure"

if [[ -e "$successor" || -L "$successor" ]]; then
    printf 'error: successor harness already exists before authorized implementation: %s\n' "$successor" >&2
    exit 1
fi

python3 - "$design" "$design_policy" "$authorization" "$policy" <<'PY'
import csv
import json
import sys

design_path, design_policy_path, authorization_path, policy_path = sys.argv[1:]
with open(design_path, encoding="utf-8", newline="") as handle:
    design_rows = list(csv.DictReader(handle, delimiter="\t"))
with open(design_policy_path, encoding="utf-8") as handle:
    design_policy = json.load(handle)
with open(authorization_path, encoding="utf-8", newline="") as handle:
    authorization_rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)

assert len(design_rows) == 1
assert len(authorization_rows) == 1
design = design_rows[0]
row = authorization_rows[0]
assert design["design_id"] == "slackware-15-characterization-remediation"
assert design["status"] == "design-frozen"
assert design["execution_harness_change_authorized"] == "false"
assert design["machine_execution_authorized"] == "false"
assert design_policy["next_stage"] == policy["scenario"]
assert design_policy["pause_safe"] is True
assert design_policy["designed_harness_remediation"]["successor_harness_required"] is True
assert design_policy["designed_harness_remediation"]["step150_harness_is_consumed_and_immutable"] is True
assert design_policy["unfrozen_capability_inputs"]["mkinitrd_config"]["future_pre_probe_identity_gate"] is False
assert design_policy["unfrozen_capability_inputs"]["grub_path"]["future_pre_probe_identity_gate"] is False
assert design_policy["future_runtime_acceptance_semantics"]["boot_initrd_available"] == "observed-not-predeclared"
assert design_policy["future_runtime_acceptance_semantics"]["boot_grub_available"] == "observed-not-predeclared"

change = policy["authorized_repository_change"]
semantics = policy["required_successor_harness_semantics"]
assert row["design_id"] == change["design_id"]
assert row["authorization_scope"] == change["scope"]
assert row["authorized_change"] == change["authorized_change"]
assert row["successor_harness_path"] == change["successor_harness_path"]
assert row["consumed_step150_harness_mutation"] == "false"
assert row["identity_gate_scope"] == semantics["frozen_identity_gate_scope"]
assert row["mkinitrd_pre_probe_gate"] == "false"
assert row["grub_pre_probe_gate"] == "false"
assert row["capability_bits_predeclared"] == "false"
assert row["runtime_acceptance_scope"] == semantics["runtime_acceptance_scope"]
assert row["source_change_authorized"] == "false"
assert row["configuration_template_change_authorized"] == "false"
assert row["contract_change_authorized"] == "false"
assert row["target_binding_change_authorized"] == "false"
assert row["execution_harness_change_authorized"] == "true"
assert row["machine_execution_authorized"] == "false"
assert row["status"] == "authorized-not-applied"
assert policy["execution_harness_change_authorized"] is True
assert policy["execution_harness_change_applied"] is False
assert policy["machine_execution_authorized"] is False
assert policy["slackware_15_rerun_authorized"] is False
assert policy["authorization_constraints"]["authorization_is_single_use_for_step154_implementation"] is True
PY

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review\n'
printf 'design_id\tslackware-15-characterization-remediation\n'
printf 'authorization_scope\tslackware-15-successor-execution-harness-only\n'
printf 'authorized_change\tcreate-new-successor-harness\n'
printf 'successor_harness_path\ttests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh\n'
printf 'step152_design_sha256\t0c0d509daa71fefd527e734c305bef18209e0a4ef157f59477d83e94febd0c89\n'
printf 'step150_harness_immutable\ttrue\n'
printf 'step149_authorization_reusable\tfalse\n'
printf 'identity_gate_scope\taccepted-elilo-core-identity-only\n'
printf 'mkinitrd_pre_probe_gate\tfalse\n'
printf 'grub_pre_probe_gate\tfalse\n'
printf 'mkinitrd_observation_preserved\ttrue\n'
printf 'grub_path_observation_preserved\ttrue\n'
printf 'runtime_capability_bits_predeclared\tfalse\n'
printf 'runtime_acceptance_scope\tauto-fail-closed-incomplete-layout-semantics\n'
printf 'execution_harness_change_applied\tfalse\n'
printf 'execution_harness_change_authorized\ttrue\n'
printf 'source_change_authorized\tfalse\n'
printf 'configuration_template_change_authorized\tfalse\n'
printf 'contract_change_authorized\tfalse\n'
printf 'target_binding_change_authorized\tfalse\n'
printf 'machine_execution_authorized\tfalse\n'
printf 'slackware_15_rerun_authorized\tfalse\n'
printf 'repository_refresh_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'future_work_requires_fresh_boundary\ttrue\n'
printf 'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation\n'
printf 'pause_safe\ttrue\n'
