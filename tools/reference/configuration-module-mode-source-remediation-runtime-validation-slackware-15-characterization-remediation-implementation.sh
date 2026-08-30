#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation.sh [--help]

Validate and report the repository-only step-154 implementation of the new
Slackware 15.0 characterization-remediated successor execution harness. This
command performs no machine execution and no source, configuration, package,
boot, repository, or target-binding mutation.
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
step153_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review-policy.json"
step153_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization.tsv"
step153_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review.md"
step150_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
accepted_closure="$repo_root/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
successor="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh"
record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation.md"
future_execution_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review-policy.json"

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

require_regular_file "$step153_policy" "step-153 authorization policy"
require_regular_file "$step153_record" "step-153 authorization record"
require_regular_file "$step153_doc" "step-153 reference document"
require_regular_file "$step150_harness" "consumed step-150 execution harness"
require_regular_file "$binding_policy" "step-132 target-binding policy"
require_regular_file "$accepted_closure" "accepted Slackware 15.0 ELILO closure"
require_regular_file "$successor" "step-154 successor execution harness"
require_regular_file "$record" "step-154 implementation record"
require_regular_file "$policy" "step-154 implementation policy"
require_regular_file "$doc" "step-154 reference document"

require_sha256 "$step153_policy" a4192c8562b59110e60c99bd64be17b1459e1c2c210117a60e97b0609be20a4c "step-153 authorization policy"
require_sha256 "$step153_record" b91241cb0ea5432d0f88a8824d2a6261b189b6440a6d4f176dca806f68d58ba8 "step-153 authorization record"
require_sha256 "$step153_doc" 9b4029a3e49b7d1f37fca086c2879edcee88e114174891c8ec14db515bfc7c38 "step-153 reference document"
require_sha256 "$step150_harness" 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 "consumed step-150 execution harness"
require_sha256 "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
require_sha256 "$accepted_closure" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "accepted Slackware 15.0 ELILO closure"
require_sha256 "$successor" 6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7 "step-154 successor execution harness"
require_sha256 "$record" caf14634fc170cfd638b6a678d13943748c13ee75bcb501f2b09ffcca0a218d9 "step-154 implementation record"
require_sha256 "$policy" 38e73937af376b9bf0a5f9378144b4ecb3c963e475707214e05e51df3495a9d7 "step-154 implementation policy"
require_sha256 "$doc" db36c2fbd3750081eb1b7582ed24c22e1929f28c1f46a6244de3bf52241f3e34 "step-154 reference document"

if [[ -e "$future_execution_policy" || -L "$future_execution_policy" ]]; then
    printf 'error: future machine-execution authorization unexpectedly exists: %s\n' "$future_execution_policy" >&2
    exit 1
fi

bash -n "$successor"

python3 - "$step153_policy" "$record" "$policy" "$successor" <<'PY'
import csv
import hashlib
import json
import pathlib
import sys

step153_path, record_path, policy_path, successor_path = sys.argv[1:]
with open(step153_path, encoding="utf-8") as handle:
    step153 = json.load(handle)
with open(record_path, encoding="utf-8", newline="") as handle:
    rows = list(csv.DictReader(handle, delimiter="\t"))
with open(policy_path, encoding="utf-8") as handle:
    policy = json.load(handle)
assert len(rows) == 1
row = rows[0]
successor_sha = hashlib.sha256(pathlib.Path(successor_path).read_bytes()).hexdigest()
change = step153["authorized_repository_change"]
assert change["authorized_change"] == "create-new-successor-harness"
assert change["successor_harness_path"] == policy["implementation"]["successor_harness_path"]
assert step153["authorization_constraints"]["authorization_is_single_use_for_step154_implementation"] is True
assert step153["machine_execution_authorized"] is False
assert row["implementation_id"] == "slackware-15-characterization-remediation"
assert row["authorized_change"] == "create-new-successor-harness"
assert row["successor_harness_sha256"] == successor_sha
assert row["identity_gate_scope"] == "accepted-elilo-core-identity-only"
assert row["mkinitrd_pre_probe_gate"] == "false"
assert row["grub_pre_probe_gate"] == "false"
assert row["capability_bits_predeclared"] == "false"
assert row["future_execution_policy_required"] == "true"
assert row["machine_execution_authorized"] == "false"
assert row["status"] == "implemented-awaiting-review"
assert policy["implementation"]["successor_harness_sha256"] == successor_sha
assert policy["implementation"]["step153_repository_authorization_consumed"] is True
assert policy["implementation"]["further_execution_harness_change_authorized"] is False
assert policy["implemented_semantics"]["mkinitrd_regular_file_pre_probe_requirement"] is False
assert policy["implemented_semantics"]["grub_absence_pre_probe_requirement"] is False
assert policy["implemented_semantics"]["runtime_capability_bits_from_probe"] is True
assert policy["implemented_semantics"]["historical_exact_capability_vector_required"] is False
assert policy["execution_hold"]["future_execution_authorization_policy_exists"] is False
assert policy["execution_hold"]["successor_harness_refuses_missing_future_authorization"] is True
assert policy["machine_execution_authorized"] is False
assert policy["slackware_15_rerun_authorized"] is False
assert policy["pause_safe"] is True
PY

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation\n'
printf 'implementation_id\tslackware-15-characterization-remediation\n'
printf 'authorized_change\tcreate-new-successor-harness\n'
printf 'successor_harness_path\ttests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh\n'
printf 'successor_harness_sha256\t6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7\n'
printf 'step153_authorization_consumed\ttrue\n'
printf 'step150_harness_immutable\ttrue\n'
printf 'identity_gate_scope\taccepted-elilo-core-identity-only\n'
printf 'mkinitrd_pre_probe_gate\tfalse\n'
printf 'grub_pre_probe_gate\tfalse\n'
printf 'mkinitrd_observation_preserved\ttrue\n'
printf 'grub_path_observation_preserved\ttrue\n'
printf 'runtime_capability_bits_predeclared\tfalse\n'
printf 'runtime_acceptance_scope\tauto-fail-closed-incomplete-layout-semantics\n'
printf 'future_execution_policy_required\ttrue\n'
printf 'future_execution_policy_exists\tfalse\n'
printf 'execution_harness_change_applied\ttrue\n'
printf 'further_execution_harness_change_authorized\tfalse\n'
printf 'source_change_applied\tfalse\n'
printf 'configuration_template_change_applied\tfalse\n'
printf 'contract_change_applied\tfalse\n'
printf 'target_binding_change_applied\tfalse\n'
printf 'machine_execution_authorized\tfalse\n'
printf 'slackware_15_rerun_authorized\tfalse\n'
printf 'repository_refresh_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'future_work_requires_fresh_boundary\ttrue\n'
printf 'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review\n'
printf 'pause_safe\ttrue\n'
