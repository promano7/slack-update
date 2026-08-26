#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization-review.sh [--help]

Validate and report the repository-only step-146 fresh Slackware-current rerun
authorization after the accepted boot-selection recovery review. This command
performs no source, configuration, package, boot, repository, or machine
mutation.
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
step145_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review-policy.json"
step145_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-manual-review.tsv"
binding_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-target-binding-policy.json"
policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization-review-policy.json"
authorization="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization.tsv"
rerun_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun.sh"

expected_source_sha256=aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7
expected_template_sha256=4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba
expected_step145_policy_sha256=f0976658c0c1a9ffbdb21bc3ec7a6f9157204f7642469488f515d136ff983e90
expected_step145_record_sha256=4dd611a3fdb2f35724ba5ad4da3305d6ac8c26889baa346ee838d51662bb1bc3
expected_binding_policy_sha256=97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6
expected_rerun_harness_sha256=60b126b458c69226b8353a13e91b5f3ce1ce0b5a83a00314ce51d2e0857de379

sha() { sha256sum -- "$1" | awk '{print $1}'; }
require_hash() {
    local path=$1 expected=$2 label=$3
    [[ -f $path && ! -L $path ]] || { printf 'error: unsafe or missing %s\n' "$label" >&2; exit 1; }
    [[ $(sha "$path") == "$expected" ]] || { printf 'error: %s SHA-256 mismatch\n' "$label" >&2; exit 1; }
}

require_hash "$source_file" "$expected_source_sha256" 'accepted reference source'
require_hash "$template" "$expected_template_sha256" 'configuration template'
require_hash "$step145_policy" "$expected_step145_policy_sha256" 'step-145 manual-review policy'
require_hash "$step145_record" "$expected_step145_record_sha256" 'step-145 manual-review record'
require_hash "$binding_policy" "$expected_binding_policy_sha256" 'step-132 target-binding policy'
require_hash "$rerun_harness" "$expected_rerun_harness_sha256" 'step-147 rerun execution harness'
[[ -f $policy && ! -L $policy ]] || { printf 'error: unsafe or missing step-146 authorization policy\n' >&2; exit 1; }
[[ -f $authorization && ! -L $authorization ]] || { printf 'error: unsafe or missing step-146 authorization record\n' >&2; exit 1; }
python3 -m json.tool "$policy" >/dev/null

grep -Fqx $'current-boot-selection-recovery-manual-review\tslackware-current\t7779072439d48eaace4b3a5b468647887fe89ca173eb78b1cdb0cb5876d9f60f\t0356cb5ac64e8a560b132c61d0c9df3228de1a74af2cd32fef9323850c4b5eb9\t9d3a00371ef60a1bcd0a399feba31004a98ba807fbd6445de574bd94f9a48cd7\ttrue\ttrue\tUUID=d1a09d24-cdbf-41cd-8cd6-2faff4d72863\t/dev/sda2\t/dev/sda2\ttrue\tfalse\tfalse\ttrue\tfalse\taccepted-manual-review\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-rerun-authorization-review' "$step145_record" \
    || { printf 'error: step-145 accepted recovery record is not exact\n' >&2; exit 1; }

policy_sha256=$(sha "$policy")

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-authorization-review\n'
printf 'authorization_id\truntime-slackware-current-post-recovery-rerun\n'
printf 'step145_manual_review_policy_sha256\t%s\n' "$expected_step145_policy_sha256"
printf 'step145_manual_review_record_sha256\t%s\n' "$expected_step145_record_sha256"
printf 'source_sha256\t%s\n' "$expected_source_sha256"
printf 'template_sha256\t%s\n' "$expected_template_sha256"
printf 'target_binding_policy_sha256\t%s\n' "$expected_binding_policy_sha256"
printf 'rerun_execution_harness_sha256\t%s\n' "$expected_rerun_harness_sha256"
printf 'authorization_policy_sha256\t%s\n' "$policy_sha256"
printf 'recovery_review_accepted\ttrue\n'
printf 'recovered_live_root_token\t/dev/sda2\n'
printf 'source_remediation_exercised\tfalse\n'
printf 'step139_authorization_reused\tfalse\n'
printf 'step143_authorization_reused\tfalse\n'
printf 'fresh_rerun_authorization_granted\ttrue\n'
printf 'runtime_probe_authorized\ttrue\n'
printf 'machine_execution_authorized\ttrue\n'
printf 'authorization_consumable\ttrue\n'
printf 'machine_execution_limit\t1\n'
printf 'reboots_allowed\t0\n'
printf 'repository_refresh_allowed\tfalse\n'
printf 'package_mutation_allowed\tfalse\n'
printf 'boot_mutation_allowed\tfalse\n'
printf 'source_change_authorized\tfalse\n'
printf 'slackware_15_execution_released\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'slackware_repository_state_dependency\tfalse\n'
printf 'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-execution\n'
printf 'pause_safe\ttrue\n'
