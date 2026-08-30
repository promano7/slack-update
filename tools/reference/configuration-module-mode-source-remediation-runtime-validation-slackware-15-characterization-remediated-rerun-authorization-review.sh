#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review.sh [--help]

Validate and report the repository-only step-156 fresh authorization for one
non-mutating Slackware 15.0 characterization-remediated runtime-validation
execution. This command performs no source, configuration, package, boot,
repository, or machine mutation.
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
step155_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review-policy.json"
step155_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review.tsv"
step155_doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review.md"
implementation_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-policy.json"
step153_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-authorization-review-policy.json"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
accepted_closure="$repo_root/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
consumed_step150_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh"
execution_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review-policy.json"
doc="$repo_root/docs/reference/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review.md"

sha() { sha256sum -- "$1" | awk '{print $1}'; }
require_regular_file() {
    local path=$1 label=$2
    [[ -f "$path" && ! -L "$path" ]] || {
        printf 'error: %s is not a regular non-symlink file: %s\n' "$label" "$path" >&2
        exit 1
    }
}
require_hash() {
    local path=$1 expected=$2 label=$3 actual
    actual=$(sha "$path")
    [[ "$actual" == "$expected" ]] || {
        printf 'error: %s SHA-256 mismatch: expected %s, got %s\n' "$label" "$expected" "$actual" >&2
        exit 1
    }
}

for entry in \
    "$source_file|accepted remediated reference source" \
    "$template|configuration template" \
    "$step155_policy|step-155 implementation-review policy" \
    "$step155_record|step-155 implementation-review record" \
    "$step155_doc|step-155 reference document" \
    "$implementation_policy|step-154 implementation policy" \
    "$step153_policy|consumed step-153 authorization policy" \
    "$binding_policy|step-132 target-binding policy" \
    "$accepted_closure|accepted Slackware 15.0 ELILO closure" \
    "$consumed_step150_harness|consumed step-150 execution harness" \
    "$execution_harness|accepted successor execution harness" \
    "$authorization|step-156 authorization record" \
    "$policy|step-156 authorization policy" \
    "$doc|step-156 reference document"; do
    require_regular_file "${entry%%|*}" "${entry#*|}"
done

require_hash "$source_file" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 "accepted remediated reference source"
require_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba "configuration template"
require_hash "$step155_policy" c8da64247cc5a6020a82876eac2617be6b34901e65241bec100993387c6a1945 "step-155 implementation-review policy"
require_hash "$step155_record" d449e3d46ea3c3c42344df12176d637fe6879533012ad0994809b617bdbc4f65 "step-155 implementation-review record"
require_hash "$step155_doc" 2f8873922f294285706d89f61543dafdbe355ea62080268529c66cc9062173eb "step-155 reference document"
require_hash "$implementation_policy" 38e73937af376b9bf0a5f9378144b4ecb3c963e475707214e05e51df3495a9d7 "step-154 implementation policy"
require_hash "$step153_policy" a4192c8562b59110e60c99bd64be17b1459e1c2c210117a60e97b0609be20a4c "consumed step-153 authorization policy"
require_hash "$binding_policy" 97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6 "step-132 target-binding policy"
require_hash "$accepted_closure" 7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635 "accepted Slackware 15.0 ELILO closure"
require_hash "$consumed_step150_harness" 346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75 "consumed step-150 execution harness"
require_hash "$execution_harness" 6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7 "accepted successor execution harness"
require_hash "$authorization" 6957ebed516e70b3a502f36f4b5d7f2225c6b963aaf0830cc5212e3e34744017 "step-156 authorization record"
require_hash "$policy" a01459125e3928ff91c32add59261306041abeab4a4996fae7d58956e443b375 "step-156 authorization policy"
require_hash "$doc" 3c85259d59689f043fa34a07aded0d3555dabb74f41142711c08d84672465cee "step-156 reference document"
python3 -m json.tool "$policy" >/dev/null

python3 - "$step155_policy" "$implementation_policy" "$authorization" "$policy" <<'PY'
import csv
import json
import sys

step155_path, implementation_path, record_path, policy_path = sys.argv[1:]
with open(step155_path, encoding='utf-8') as handle:
    step155 = json.load(handle)
with open(implementation_path, encoding='utf-8') as handle:
    implementation = json.load(handle)
with open(record_path, encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))
with open(policy_path, encoding='utf-8') as handle:
    policy = json.load(handle)

assert step155['schema'] == 1
assert step155['review_verdict'] == 'accepted'
assert step155['reviewed_implementation']['implementation_locked'] is True
assert step155['reviewed_implementation']['successor_harness_sha256'] == policy['execution']['execution_harness_sha256']
assert step155['reviewed_implementation']['identity_gate_scope'] == policy['execution']['identity_gate_scope']
assert step155['reviewed_implementation']['runtime_capability_bits_from_probe'] is True
assert step155['reviewed_implementation']['historical_exact_capability_vector_required'] is False
assert step155['reviewed_implementation']['runtime_acceptance_scope'] == policy['execution']['runtime_acceptance_scope']
assert step155['authorization_state']['step149_machine_authorization_reusable'] is False
assert step155['authorization_state']['step153_repository_authorization_consumed'] is True
assert step155['authorization_state']['future_execution_authorization_policy_exists'] is False
assert step155['machine_execution_authorized'] is False
assert step155['slackware_15_rerun_authorized'] is False
assert step155['next_stage'] == policy['scenario']

assert implementation['implementation']['successor_harness_sha256'] == policy['execution']['execution_harness_sha256']
assert implementation['execution_hold']['step149_authorization_reusable'] is False
assert implementation['execution_hold']['future_execution_authorization_policy_exists'] is False

assert policy['schema'] == 1
assert policy['authorization_id'] == 'runtime-slackware-15-characterization-remediated-rerun'
assert policy['accepted_step155_scenario'] == step155['scenario']
assert policy['step155_review_policy_sha256'] == 'c8da64247cc5a6020a82876eac2617be6b34901e65241bec100993387c6a1945'
assert policy['step155_review_record_sha256'] == 'd449e3d46ea3c3c42344df12176d637fe6879533012ad0994809b617bdbc4f65'
assert policy['step155_reference_document_sha256'] == '2f8873922f294285706d89f61543dafdbe355ea62080268529c66cc9062173eb'
assert policy['implementation_policy_sha256'] == '38e73937af376b9bf0a5f9378144b4ecb3c963e475707214e05e51df3495a9d7'
assert policy['step153_authorization_policy_sha256'] == 'a4192c8562b59110e60c99bd64be17b1459e1c2c210117a60e97b0609be20a4c'
assert policy['step132_target_binding_policy_sha256'] == '97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6'
assert policy['accepted_elilo_closure_record_sha256'] == '7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635'
assert policy['consumed_step150_harness_sha256'] == '346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75'
assert policy['accepted_source_sha256'] == 'aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7'
assert policy['configuration_template_sha256'] == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
assert policy['execution']['execution_harness_path'].endswith('slackware-15-characterization-remediated-rerun.sh')
assert policy['execution']['execution_harness_sha256'] == '6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7'
assert policy['execution']['identity_gate_scope'] == 'accepted-elilo-core-identity-only'
assert policy['execution']['runtime_capability_bits_from_probe'] is True
assert policy['execution']['historical_exact_capability_vector_required'] is False
assert policy['execution']['runtime_acceptance_scope'] == 'auto-fail-closed-incomplete-layout-semantics'
assert policy['target']['target'] == 'slackware-15.0'
assert policy['target']['hostname_fqdn'] == 'vbox-slack15.vbox-slack15.org'
assert policy['target']['slackware_version'] == 'Slackware 15.0'
assert policy['target']['require_uefi'] is True
assert policy['target']['running_kernel'] == '5.15.209'
assert policy['target']['required_boot_image_suffix'] == '\\EFI\\Slackware\\vmlinuz-generic-5.15.209'
assert policy['target']['elilo_conf_sha256'] == '94b77b9f70a9d3b22d146c36af0ee6bbf09133d0b1931a2e731e881d3edc37f6'
auth = policy['authorization']
assert auth['execution_authorized'] is True
assert auth['authorization_consumable'] is True
assert auth['machine_execution_limit'] == 1
assert auth['reboot_limit'] == 0
for key in (
    'repository_refresh_authorized', 'package_mutation_authorized',
    'boot_mutation_authorized', 'source_change_authorized',
    'configuration_template_change_authorized', 'contract_change_authorized',
    'target_binding_change_authorized', 'execution_harness_change_authorized',
    'retry_authorized'):
    assert auth[key] is False
assert policy['prior_authorization_state']['step149_machine_authorization_reusable'] is False
assert policy['prior_authorization_state']['step153_repository_authorization_consumed'] is True
assert policy['prior_authorization_state']['step155_future_execution_policy_existed'] is False
assert policy['source_change_applied'] is False
assert policy['configuration_template_change_applied'] is False
assert policy['contract_change_applied'] is False
assert policy['target_binding_change_applied'] is False
assert policy['execution_harness_change_applied'] is False
assert policy['repository_refresh_required'] is False
assert policy['slackware_repository_state_dependency'] is False
assert policy['machine_action_required'] is False
assert policy['next_stage'].endswith('characterization-remediated-rerun-execution')
assert policy['pause_safe'] is True

assert len(rows) == 1
row = rows[0]
assert row['authorization_id'] == policy['authorization_id']
assert row['scenario'] == policy['scenario']
assert row['execution_harness_path'] == policy['execution']['execution_harness_path']
assert row['execution_harness_sha256'] == policy['execution']['execution_harness_sha256']
assert row['step155_review_policy_sha256'] == policy['step155_review_policy_sha256']
assert row['accepted_source_sha256'] == policy['accepted_source_sha256']
assert row['configuration_template_sha256'] == policy['configuration_template_sha256']
assert row['target_binding_policy_sha256'] == policy['step132_target_binding_policy_sha256']
assert row['accepted_elilo_closure_record_sha256'] == policy['accepted_elilo_closure_record_sha256']
assert row['target'] == policy['target']['target']
assert row['hostname_fqdn'] == policy['target']['hostname_fqdn']
assert row['running_kernel'] == policy['target']['running_kernel']
assert row['identity_gate_scope'] == policy['execution']['identity_gate_scope']
assert row['runtime_acceptance_scope'] == policy['execution']['runtime_acceptance_scope']
assert row['execution_authorized'] == 'true'
assert row['authorization_consumable'] == 'true'
assert row['machine_execution_limit'] == '1'
assert row['reboot_limit'] == '0'
assert row['repository_refresh_authorized'] == 'false'
assert row['package_mutation_authorized'] == 'false'
assert row['boot_mutation_authorized'] == 'false'
assert row['source_change_authorized'] == 'false'
assert row['configuration_template_change_authorized'] == 'false'
assert row['contract_change_authorized'] == 'false'
assert row['target_binding_change_authorized'] == 'false'
assert row['execution_harness_change_authorized'] == 'false'
assert row['retry_authorized'] == 'false'
assert row['status'] == 'authorized-unconsumed'
PY

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review\n'
printf 'authorization_id\truntime-slackware-15-characterization-remediated-rerun\n'
printf 'step155_review_policy_sha256\tc8da64247cc5a6020a82876eac2617be6b34901e65241bec100993387c6a1945\n'
printf 'step155_review_record_sha256\td449e3d46ea3c3c42344df12176d637fe6879533012ad0994809b617bdbc4f65\n'
printf 'source_sha256\taeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7\n'
printf 'template_sha256\t4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba\n'
printf 'target_binding_policy_sha256\t97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6\n'
printf 'accepted_elilo_closure_record_sha256\t7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635\n'
printf 'consumed_step150_harness_sha256\t346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75\n'
printf 'execution_harness_sha256\t6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7\n'
printf 'authorization_record_sha256\t6957ebed516e70b3a502f36f4b5d7f2225c6b963aaf0830cc5212e3e34744017\n'
printf 'authorization_policy_sha256\ta01459125e3928ff91c32add59261306041abeab4a4996fae7d58956e443b375\n'
printf 'identity_gate_scope\taccepted-elilo-core-identity-only\n'
printf 'runtime_capability_bits_from_probe\ttrue\n'
printf 'historical_exact_capability_vector_required\tfalse\n'
printf 'runtime_acceptance_scope\tauto-fail-closed-incomplete-layout-semantics\n'
printf 'step149_authorization_reusable\tfalse\n'
printf 'step153_authorization_consumed\ttrue\n'
printf 'machine_execution_authorized\ttrue\n'
printf 'authorization_consumable\ttrue\n'
printf 'machine_execution_limit\t1\n'
printf 'reboots_allowed\t0\n'
printf 'repository_refresh_allowed\tfalse\n'
printf 'package_mutation_allowed\tfalse\n'
printf 'boot_mutation_allowed\tfalse\n'
printf 'source_change_authorized\tfalse\n'
printf 'configuration_template_change_authorized\tfalse\n'
printf 'contract_change_authorized\tfalse\n'
printf 'target_binding_change_authorized\tfalse\n'
printf 'execution_harness_change_authorized\tfalse\n'
printf 'retry_authorized\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-execution\n'
printf 'pause_safe\ttrue\n'
