#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review.sh [--help]

Validate and report the repository-only step-149 fresh Slackware 15.0 runtime
validation authorization after the accepted Slackware-current post-recovery
rerun review. This command performs no source, configuration, package, boot,
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
step148_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review-policy.json"
step148_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review.tsv"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
old_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15.sh"
closure="$repo_root/tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review-policy.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization.tsv"
execution_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh"

expected_source_sha256=aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7
expected_template_sha256=4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba
expected_step148_policy_sha256=de2813f328b1af80531d68a22c049f9c3be58b6a445398c5c3795b49036ead4b
expected_step148_record_sha256=9f8c384d4709e8161ac2f6a3e928b7f3e7baea677e7d850c4c061c1aa4d71361
expected_binding_policy_sha256=97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6
expected_old_harness_sha256=0226e6d48483e0014c699e5affe224bceaa07f8d767673ba30700c7ee21b670c
expected_closure_sha256=7bd0a490df1b86ba83313dfba752c9d8aafc34ec93d2bff34505b79c36d0c635
expected_execution_harness_sha256=346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75
expected_authorization_sha256=7058af65141f55d664857ada09d1c29431012f78925c38d4af08d628478d0634
expected_policy_sha256=d2877fce33c417ff8318fbed3e64a0fe409786f475a1d25ccf97f712a159037f

sha() { sha256sum -- "$1" | awk '{print $1}'; }
require_hash() {
    local path=$1 expected=$2 label=$3
    [[ -f $path && ! -L $path ]] || { printf 'error: unsafe or missing %s\n' "$label" >&2; exit 1; }
    [[ $(sha "$path") == "$expected" ]] || { printf 'error: %s SHA-256 mismatch\n' "$label" >&2; exit 1; }
}

require_hash "$source_file" "$expected_source_sha256" 'accepted remediated reference source'
require_hash "$template" "$expected_template_sha256" 'configuration template'
require_hash "$step148_policy" "$expected_step148_policy_sha256" 'step-148 accepted review policy'
require_hash "$step148_record" "$expected_step148_record_sha256" 'step-148 accepted review record'
require_hash "$binding_policy" "$expected_binding_policy_sha256" 'step-132 target-binding policy'
require_hash "$old_harness" "$expected_old_harness_sha256" 'obsolete step-132 Slackware 15.0 execution harness'
require_hash "$closure" "$expected_closure_sha256" 'accepted Slackware 15.0 ELILO closure record'
require_hash "$execution_harness" "$expected_execution_harness_sha256" 'fresh Slackware 15.0 execution harness'
require_hash "$authorization" "$expected_authorization_sha256" 'step-149 authorization record'
require_hash "$policy" "$expected_policy_sha256" 'step-149 authorization policy'
python3 -m json.tool "$policy" >/dev/null

python3 - "$step148_policy" "$binding_policy" "$policy" <<'PY'
import json
import sys
with open(sys.argv[1], encoding='utf-8') as handle:
    step148 = json.load(handle)
with open(sys.argv[2], encoding='utf-8') as handle:
    binding = json.load(handle)
with open(sys.argv[3], encoding='utf-8') as handle:
    authorization = json.load(handle)
assert step148['source_remediation']['exercised'] is True
assert step148['source_remediation']['accepted'] is True
assert step148['slackware_current']['runtime_validation_accepted'] is True
assert step148['slackware_15']['released_to_fresh_authorization_review'] is True
assert step148['slackware_15']['execution_authorized'] is False
assert step148['slackware_15']['step132_slackware15_execution_harness_reusable'] is False
assert binding['source_sha256'] == authorization['step132_bound_source_sha256']
assert binding['source_sha256'] != authorization['accepted_source_sha256']
assert binding['slackware_15']['execution_harness_sha256'] == authorization['obsolete_step132_slackware15_harness_sha256']
assert authorization['authorization']['execution_authorized'] is True
assert authorization['authorization']['authorization_consumable'] is True
assert authorization['authorization']['machine_execution_limit'] == 1
assert authorization['authorization']['reboot_limit'] == 0
assert authorization['authorization']['repository_refresh_authorized'] is False
assert authorization['authorization']['package_mutation_authorized'] is False
assert authorization['authorization']['boot_mutation_authorized'] is False
assert authorization['authorization']['source_change_authorized'] is False
assert authorization['authorization']['configuration_template_change_authorized'] is False
assert authorization['authorization']['contract_change_authorized'] is False
assert authorization['authorization']['retry_authorized'] is False
assert authorization['pause_safe'] is True
PY

grep -Fqx $'1\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review\truntime-slackware-15-post-current-rerun\tde2813f328b1af80531d68a22c049f9c3be58b6a445398c5c3795b49036ead4b\t9f8c384d4709e8161ac2f6a3e928b7f3e7baea677e7d850c4c061c1aa4d71361\taeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7\t4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba\t97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6\t0226e6d48483e0014c699e5affe224bceaa07f8d767673ba30700c7ee21b670c\ttests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh\t346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75\tslackware-15.0\tvbox-slack15.vbox-slack15.org\telilo-generic-with-initrd\t5.15.209\ttrue\ttrue\t1\t0\tfalse\tfalse\tfalse\tfalse\tfalse\tfalse\tfalse\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-execution\ttrue' "$authorization" \
    || { printf 'error: step-149 authorization record is not exact\n' >&2; exit 1; }

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-authorization-review\n'
printf 'authorization_id\truntime-slackware-15-post-current-rerun\n'
printf 'step148_review_policy_sha256\t%s\n' "$expected_step148_policy_sha256"
printf 'step148_review_record_sha256\t%s\n' "$expected_step148_record_sha256"
printf 'source_sha256\t%s\n' "$expected_source_sha256"
printf 'template_sha256\t%s\n' "$expected_template_sha256"
printf 'target_binding_policy_sha256\t%s\n' "$expected_binding_policy_sha256"
printf 'obsolete_step132_slackware15_harness_sha256\t%s\n' "$expected_old_harness_sha256"
printf 'obsolete_step132_slackware15_harness_reusable\tfalse\n'
printf 'fresh_execution_harness_sha256\t%s\n' "$expected_execution_harness_sha256"
printf 'authorization_record_sha256\t%s\n' "$expected_authorization_sha256"
printf 'authorization_policy_sha256\t%s\n' "$expected_policy_sha256"
printf 'slackware_current_validation_accepted\ttrue\n'
printf 'source_remediation_exercised_and_accepted\ttrue\n'
printf 'fresh_slackware15_authorization_granted\ttrue\n'
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
printf 'retry_authorized\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-execution\n'
printf 'pause_safe\ttrue\n'
