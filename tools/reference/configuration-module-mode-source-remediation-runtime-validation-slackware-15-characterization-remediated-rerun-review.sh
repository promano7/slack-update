#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-review.sh [--help]

Validate and report the repository-only step-158 review of the accepted
Slackware 15.0 characterization-remediated rerun evidence. This command performs
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
step156_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization-review-policy.json"
step156_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-authorization.tsv"
step157_harness="$repo_root/tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh"
step155_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediation-implementation-review-policy.json"
step148_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review-policy.json"
step148_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-review.tsv"
review_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-review-policy.json"
review_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-review.tsv"

sha() { sha256sum -- "$1" | awk '{print $1}'; }
require_hash() {
    local path=$1 expected=$2 label=$3
    [[ -f $path && ! -L $path ]] || { printf 'error: unsafe or missing %s\n' "$label" >&2; exit 1; }
    [[ $(sha "$path") == "$expected" ]] || { printf 'error: %s SHA-256 mismatch\n' "$label" >&2; exit 1; }
}

require_hash "$source_file" aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7 'accepted remediated reference source'
require_hash "$template" 4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba 'configuration template'
require_hash "$step156_policy" a01459125e3928ff91c32add59261306041abeab4a4996fae7d58956e443b375 'step-156 authorization policy'
require_hash "$step156_record" 6957ebed516e70b3a502f36f4b5d7f2225c6b963aaf0830cc5212e3e34744017 'step-156 authorization record'
require_hash "$step157_harness" 6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7 'step-157 execution harness'
require_hash "$step155_policy" c8da64247cc5a6020a82876eac2617be6b34901e65241bec100993387c6a1945 'step-155 implementation-review policy'
require_hash "$step148_policy" de2813f328b1af80531d68a22c049f9c3be58b6a445398c5c3795b49036ead4b 'accepted Slackware-current review policy'
require_hash "$step148_record" 9f8c384d4709e8161ac2f6a3e928b7f3e7baea677e7d850c4c061c1aa4d71361 'accepted Slackware-current review record'
require_hash "$review_policy" 2ead4c6e4b144b7bc6c3f927eaeea8c46160cc8ebdf1054684046767444bd46a 'step-158 review policy'
require_hash "$review_record" dbeded2f525a52dd4155c41963d8e154b6a4e90917c994c4b4a993d81a1e0ba4 'step-158 review record'
python3 -m json.tool "$review_policy" >/dev/null

python3 - "$step156_policy" "$step155_policy" "$step148_policy" "$review_policy" "$review_record" <<'PY'
import csv
import json
import sys

step156_path, step155_path, step148_path, review_path, record_path = sys.argv[1:]
with open(step156_path, encoding='utf-8') as handle:
    step156 = json.load(handle)
with open(step155_path, encoding='utf-8') as handle:
    step155 = json.load(handle)
with open(step148_path, encoding='utf-8') as handle:
    step148 = json.load(handle)
with open(review_path, encoding='utf-8') as handle:
    review = json.load(handle)
with open(record_path, encoding='utf-8', newline='') as handle:
    rows = list(csv.DictReader(handle, delimiter='\t'))

assert step156['authorization']['execution_authorized'] is True
assert step156['authorization']['authorization_consumable'] is True
assert step156['authorization']['machine_execution_limit'] == 1
assert step156['authorization']['retry_authorized'] is False
assert step156['execution']['execution_harness_sha256'] == review['step157_execution_harness_sha256']
assert step155['review_verdict'] == 'accepted'
assert step155['reviewed_implementation']['historical_exact_capability_vector_required'] is False
assert step148['slackware_current']['runtime_validation_accepted'] is True
assert step148['slackware_current']['authorization_reusable'] is False

assert review['schema'] == 1
assert review['review_only'] is True
assert review['step158_review_record_sha256'] == 'dbeded2f525a52dd4155c41963d8e154b6a4e90917c994c4b4a993d81a1e0ba4'
assert review['evidence']['archive_sha256'] == '8a740eb47558c13fb418cb460c581ed45a7d2d3ad73f1e7b6f0b62560741ef4d'
assert review['evidence']['authenticated'] is True
assert review['evidence']['reviewed'] is True
assert review['evidence']['passes'] == 21
assert review['evidence']['failures'] == 0
assert review['evidence']['skips'] == 0
s15 = review['slackware_15']
assert s15['hostname_fqdn'] == 'vbox-slack15.vbox-slack15.org'
assert s15['running_kernel'] == '5.15.209'
assert s15['core_identity_match'] is True
assert s15['runtime_probe_invoked'] is True
assert s15['runtime_probe_accepted'] is True
assert s15['system_state_preserved'] is True
assert s15['authorization_consumed_by_execution'] is True
assert s15['authorization_reusable'] is False
assert s15['runtime_validation_accepted'] is True
verdict = s15['expected_runtime_verdict']
assert verdict['boot_mode'] == 'auto'
assert verdict['boot_module_state'] == 'unavailable'
assert verdict['boot_module_run'] == 0
assert verdict['boot_preparation_layout'] == 'unknown'
assert verdict['boot_initrd_available'] == 0
assert verdict['boot_grub_available'] == 1
assert verdict['boot_direct_generic_available'] == 0
remediation = review['characterization_remediation']
assert remediation['accepted_elilo_core_identity_only'] is True
assert remediation['historical_exact_capability_vector_required'] is False
assert remediation['runtime_capability_bits_observed_live'] is True
assert remediation['fail_closed_incomplete_layout_semantics_exercised'] is True
assert remediation['accepted'] is True
assert remediation['additional_harness_change_authorized'] is False
assert all(review['non_mutation_review'][key] for key in ('packages_preserved','slackpkg_metadata_preserved','boot_state_preserved','source_preserved','template_preserved'))
assert not any(review['non_mutation_review'][key] for key in ('repository_refresh_performed','package_mutation_performed','boot_mutation_performed','reboot_performed'))
cross = review['cross_target_runtime_validation']
assert cross['slackware_current_runtime_validation_accepted'] is True
assert cross['slackware_15_runtime_validation_accepted'] is True
assert cross['mandatory_targets_accepted'] is True
assert cross['runtime_validation_ready_for_closure_review'] is True
assert review['machine_execution_authorized'] is False
assert review['slackware_15_rerun_authorized'] is False
assert review['repository_refresh_required'] is False
assert review['slackware_repository_state_dependency'] is False
assert review['machine_action_required'] is False
assert review['future_work_requires_fresh_boundary'] is True
assert review['next_stage'] == 'phase-1-configuration-module-mode-source-remediation-runtime-validation-closure-review'
assert review['pause_safe'] is True

assert len(rows) == 1
row = rows[0]
assert row['evidence_sha256'] == review['evidence']['archive_sha256']
assert row['step156_authorization_policy_sha256'] == review['step156_authorization_policy_sha256']
assert row['execution_harness_sha256'] == review['step157_execution_harness_sha256']
assert row['runtime_probe_invoked'] == 'true'
assert row['runtime_probe_accepted'] == 'true'
assert row['boot_module_state'] == 'unavailable'
assert row['boot_module_run'] == '0'
assert row['system_state_preserved'] == 'true'
assert row['authorization_consumed'] == 'true'
assert row['authorization_reusable'] == 'false'
assert row['characterization_remediation_accepted'] == 'true'
assert row['slackware_15_validation_accepted'] == 'true'
assert row['slackware_current_validation_accepted'] == 'true'
assert row['mandatory_targets_accepted'] == 'true'
assert row['machine_action_required'] == 'false'
assert row['repository_refresh_required'] == 'false'
assert row['pause_safe'] == 'true'
assert row['status'] == 'accepted'
PY

printf 'schema\t1\n'
printf 'scenario\tphase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun-review\n'
printf 'evidence_archive_sha256\t8a740eb47558c13fb418cb460c581ed45a7d2d3ad73f1e7b6f0b62560741ef4d\n'
printf 'step156_authorization_policy_sha256\ta01459125e3928ff91c32add59261306041abeab4a4996fae7d58956e443b375\n'
printf 'step156_authorization_record_sha256\t6957ebed516e70b3a502f36f4b5d7f2225c6b963aaf0830cc5212e3e34744017\n'
printf 'step157_execution_harness_sha256\t6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7\n'
printf 'source_sha256\taeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7\n'
printf 'template_sha256\t4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba\n'
printf 'runtime_probe_invoked\ttrue\n'
printf 'runtime_probe_accepted\ttrue\n'
printf 'boot_module_state\tunavailable\n'
printf 'boot_module_run\t0\n'
printf 'boot_preparation_layout\tunknown\n'
printf 'system_state_preserved\ttrue\n'
printf 'authorization_consumed\ttrue\n'
printf 'authorization_reusable\tfalse\n'
printf 'characterization_remediation_accepted\ttrue\n'
printf 'slackware_15_runtime_validation_accepted\ttrue\n'
printf 'slackware_current_runtime_validation_accepted\ttrue\n'
printf 'mandatory_targets_accepted\ttrue\n'
printf 'machine_execution_authorized\tfalse\n'
printf 'repository_refresh_required\tfalse\n'
printf 'machine_action_required\tfalse\n'
printf 'future_work_requires_fresh_boundary\ttrue\n'
printf 'next_stage\tphase-1-configuration-module-mode-source-remediation-runtime-validation-closure-review\n'
printf 'pause_safe\ttrue\n'
