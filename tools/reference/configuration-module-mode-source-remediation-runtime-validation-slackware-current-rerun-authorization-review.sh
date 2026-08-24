#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review.sh [--help]

Validate and report the repository-only step-139 Slackware-current rerun
authorization review after the accepted direct-generic initialization
remediation. This command performs no source, configuration, package, boot,
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
contract="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-contract.tsv"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
old_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current.sh"
regression="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.tsv"
regression_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review-policy.json"
regression_helper="$repo_root/tools/reference/configuration-module-mode-source-remediation-runtime-validation-direct-generic-initialization-remediation-regression-review.sh"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization.tsv"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review-policy.json"
rerun_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun.sh"

expected_source_sha256=aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7
expected_template_sha256=4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba
expected_contract_sha256=f97ee5aa941b94f64570bd119b4870a4a85c8affde3212395ee09e8c44ff5eb9
expected_binding_policy_sha256=97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6
expected_old_harness_sha256=9f54d2c7d27f46e7d522a8046274d67860a5a59f455e796e467b7f6d23961d62
expected_regression_sha256=18de033bdde24bf7c1072314cded46e134cee06aac8434f47f3318e97995d30d
expected_regression_policy_sha256=43c7b538d06e142180aa343bc743ab11c341e71a4ace6ea0909efac1be90f4ac
expected_regression_helper_sha256=791199d3f3967e87a610aed86bcaf62ef48e1d78f8941e398e0a962261066f97
expected_authorization_sha256=db55dd0eb7349790fa79cc8a1261075d59397e4c9b7a4d24120733093248d651
expected_policy_sha256=5d0dc91852d8efe5ff203be68468ca5db4cfb6c718e1f4430caf4bf75550a6ba
expected_rerun_harness_sha256=0099213437acb8184019dd4f98f63de8f1c6821924ad08f93e8ff85f4288b120

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

for entry in \
    "$source_file|accepted remediated reference implementation" \
    "$template|configuration template" \
    "$contract|optional-module contract" \
    "$binding_policy|accepted step-132 target-binding policy" \
    "$old_harness|consumed step-133 execution harness" \
    "$regression|accepted step-138 regression record" \
    "$regression_policy|accepted step-138 regression policy" \
    "$regression_helper|corrected step-138 regression helper" \
    "$authorization|step-139 rerun authorization record" \
    "$policy|step-139 rerun authorization policy" \
    "$rerun_harness|step-139 rerun execution harness"; do
    require_regular_file "${entry%%|*}" "${entry#*|}"
done

require_sha256 "$source_file" "$expected_source_sha256" "accepted remediated reference implementation"
require_sha256 "$template" "$expected_template_sha256" "configuration template"
require_sha256 "$contract" "$expected_contract_sha256" "optional-module contract"
require_sha256 "$binding_policy" "$expected_binding_policy_sha256" "accepted step-132 target-binding policy"
require_sha256 "$old_harness" "$expected_old_harness_sha256" "consumed step-133 execution harness"
require_sha256 "$regression" "$expected_regression_sha256" "accepted step-138 regression record"
require_sha256 "$regression_policy" "$expected_regression_policy_sha256" "accepted step-138 regression policy"
require_sha256 "$regression_helper" "$expected_regression_helper_sha256" "corrected step-138 regression helper"
require_sha256 "$authorization" "$expected_authorization_sha256" "step-139 rerun authorization record"
require_sha256 "$policy" "$expected_policy_sha256" "step-139 rerun authorization policy"
require_sha256 "$rerun_harness" "$expected_rerun_harness_sha256" "step-139 rerun execution harness"

bash -n "$rerun_harness"
"$rerun_harness" --help >/dev/null

python3 - "$regression" "$regression_policy" "$authorization" "$policy" "$rerun_harness" <<'PY2'
import csv
import hashlib
import json
import sys
from pathlib import Path

regression_path, regression_policy_path, auth_path, policy_path, harness_path = sys.argv[1:]
with open(regression_path, encoding='utf-8', newline='') as handle:
    regression = list(csv.DictReader(handle, delimiter='\t'))
with open(regression_policy_path, encoding='utf-8') as handle:
    regression_policy = json.load(handle)
with open(auth_path, encoding='utf-8', newline='') as handle:
    auth = list(csv.DictReader(handle, delimiter='\t'))
with open(policy_path, encoding='utf-8') as handle:
    policy = json.load(handle)
assert len(regression) == 1 and len(auth) == 1
reg = regression[0]
row = auth[0]
assert reg['source_sha256'] == policy['source_sha256'] == row['source_sha256']
assert reg['exact_delta_revalidated'] == 'true'
assert reg['historical_unset_fixture_detected'] == 'true'
assert reg['remediated_probe_fixture_passed'] == 'true'
assert reg['machine_execution_authorized'] == 'false'
assert reg['slackware_current_rerun_authorized'] == 'false'
assert reg['pause_safe'] == 'true'
assert regression_policy['source_sha256'] == policy['source_sha256']
assert regression_policy['runtime_machine_validation_still_required'] is True
assert policy['schema'] == 1
assert row['schema'] == '1'
assert row['scenario'] == policy['scenario']
assert row['authorization_id'] == policy['authorization_id']
assert row['target_binding_policy_sha256'] == policy['accepted_step132_target_binding_policy_sha256']
assert row['rerun_execution_harness'] == policy['slackware_current']['execution_harness']
harness_sha = hashlib.sha256(Path(harness_path).read_bytes()).hexdigest()
assert row['rerun_execution_harness_sha256'] == harness_sha == policy['slackware_current']['execution_harness_sha256']
assert policy['runtime_validation_scope_authorized'] is True
assert policy['runtime_machine_validation_still_required'] is True
assert policy['machine_execution_authorized'] is True
assert policy['authorization_consumable'] is True
assert policy['machine_execution_limit_total'] == 1
assert policy['reboot_limit'] == 0
assert policy['repository_refresh_required'] is False
assert policy['slackware_repository_state_dependency'] is False
assert policy['package_mutation_authorized'] is False
assert policy['boot_mutation_authorized'] is False
assert policy['source_change_authorized'] is False
assert policy['configuration_template_change_authorized'] is False
assert policy['contract_change_authorized'] is False
assert policy['machine_action_required_in_step139'] is False
assert policy['future_machine_action_required'] is True
assert policy['slackware_current']['execution_authorized'] is True
assert policy['slackware_current']['authorization_consumable'] is True
assert policy['slackware_current']['machine_execution_limit'] == 1
assert policy['slackware_current']['reboot_limit'] == 0
assert policy['slackware_15']['execution_authorized'] is False
assert policy['slackware_15']['authorization_consumable'] is False
assert policy['next_stage'] == 'phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-execution'
assert policy['pause_safe'] is True
for key in ('execution_authorized','authorization_consumable','pause_safe'):
    assert row[key] == 'true'
for key in ('repository_refresh_allowed','package_mutation_allowed','boot_mutation_allowed','source_change_authorized','slackware_15_execution_released','machine_action_required'):
    assert row[key] == 'false'
assert row['machine_execution_limit'] == '1'
assert row['reboots_allowed'] == '0'
assert row['next_stage'] == policy['next_stage']
PY2

cat <<'EOF'
schema	1
scenario	phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review
source_sha256	aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7
target_binding_policy_sha256	97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6
rerun_execution_harness_sha256	0099213437acb8184019dd4f98f63de8f1c6821924ad08f93e8ff85f4288b120
step138_regression_accepted	true
target_binding_preserved	true
consumed_step133_authorization_reused	false
fresh_rerun_authorization_granted	true
machine_execution_authorized	true
authorization_consumable	true
machine_execution_limit	1
reboots_allowed	0
repository_refresh_allowed	false
package_mutation_allowed	false
boot_mutation_allowed	false
source_change_authorized	false
slackware_15_execution_released	false
machine_action_required	false
slackware_repository_state_dependency	false
next_stage	phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-execution
pause_safe	true
EOF
