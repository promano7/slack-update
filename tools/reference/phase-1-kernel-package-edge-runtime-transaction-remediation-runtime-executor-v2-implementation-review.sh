#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze.tsv"
contract_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze-policy.json"
contract_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze.tsv"
historical_body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh"
historical_builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh"
historical_executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
reference_file="$repo_root/tools/reference/slack-update-reference.sh"
config_file="$repo_root/data/config/slack-update.conf"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review.sh"
output_dir=''

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review.sh [--output-dir DIR] [--help]

Review the repository-only executor-v2 implementation bound to the accepted
local-source-v3 manifest and the fresh step-253 target identity. This review
creates no machine authority and grants no executor transport, candidate binding,
package, Slackpkg, network, boot, reboot, cleanup, or runtime-rerun authority.
USAGE
}

while (($#)); do
    case "$1" in
        --output-dir)
            [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }
            output_dir=$2
            shift 2
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            printf 'ERROR: unknown option: %s\n' "$1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

for path in "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" \
            "$contract_policy" "$contract_record" "$historical_body" "$historical_builder" \
            "$historical_executor" "$body" "$builder" "$executor" "$acceptance_harness" \
            "$reference_file" "$config_file" "$helper_path"; do
    [[ -f $path && ! -L $path ]] || { printf 'ERROR: required repository input is missing or unsafe: %s\n' "$path" >&2; exit 3; }
done

check_hash() {
    local path=$1 expected=$2 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: frozen input SHA-256 drift: %s\nexpected: %s\nactual:   %s\n' "$path" "$expected" "$actual" >&2
        exit 4
    }
}

check_hash "$prior_helper" '8c54917fbfdafafc6e1aa698a5395bee64fe684f4dcf7705b3cbbc77bab1166c'
check_hash "$prior_doc" '6dc6db58fc8d03f346bb6b8d59ce5aae9503bd19a450a6633004fcd60dc8553e'
check_hash "$prior_harness" 'b85b8fd0d29a63490b400b152df2c147a49a47d7b324f7e050b725d38780c8ef'
check_hash "$prior_policy" 'af5a87022c2379ede9d7c6ec4fae4d15fc86bf08b491b3ea21082bebe5ff8d84'
check_hash "$prior_record" 'ec9b98e3b48fcc35c02d9e3fa50b9cba2b23e051e46af0e957519dd67ec56b97'
check_hash "$contract_policy" 'cf32f3d6b5df64d176c154e506c356c53e63da794c961edbbcbf1557ecef25f0'
check_hash "$contract_record" '2f55b4a83a498fdf1c347ba2f35c25b5b0a3a87233f3df66f2362cfa12491071'
check_hash "$historical_body" 'ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b'
check_hash "$historical_builder" 'a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379'
check_hash "$historical_executor" '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c'
check_hash "$body" 'c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68'
check_hash "$builder" '43c858e351d32c4ed2c28c687ccc9a06a1fc78f77032eaf20fb3d40a3ff197da'
check_hash "$executor" 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d'
check_hash "$acceptance_harness" '86fcfd31ebe023d6fdfe3ec0c0c6bebaac3a17fd47202de43ffa3afe89854eef'
check_hash "$reference_file" '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
check_hash "$config_file" '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'

work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
rebuilt="$work/v2-executor.sh"
"$builder" --repo-root "$repo_root" --output "$rebuilt" > "$work/builder.out"
cmp -s -- "$rebuilt" "$executor" || { printf 'ERROR: rebuilt v2 executor differs from canonical executor\n' >&2; exit 5; }
[[ $(sha256sum -- "$rebuilt" | awk '{print $1}') == 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d' ]] || { printf 'ERROR: rebuilt v2 executor hash mismatch\n' >&2; exit 5; }
if ! "$acceptance_harness" > "$work/acceptance.out" 2>&1; then
    cat -- "$work/acceptance.out" >&2
    printf 'ERROR: executor-v2 repository acceptance failed\n' >&2
    exit 6
fi
grep -Fqx 'Result: PASS (94 passes, 0 failures)' "$work/acceptance.out" || {
    cat -- "$work/acceptance.out" >&2
    printf 'ERROR: unexpected executor-v2 repository acceptance result\n' >&2
    exit 6
}

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 7; }
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$prior_policy" "$prior_record" "$contract_policy" "$contract_record" "$policy" "$record" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

prior_path, prior_record_path, contract_path, contract_record_path, out_policy, out_record = map(Path, sys.argv[1:7])
helper_sha = sys.argv[7]
prior = json.loads(prior_path.read_text(encoding='utf-8'))
contract = json.loads(contract_path.read_text(encoding='utf-8'))
with prior_record_path.open(encoding='utf-8', newline='') as handle:
    prior_record = dict(csv.reader(handle, delimiter='\t'))
with contract_record_path.open(encoding='utf-8', newline='') as handle:
    contract_record = dict(csv.reader(handle, delimiter='\t'))

assert prior['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze'
assert prior['freeze_status'] == 'PASS'
assert prior_record['step'] == '253'
assert prior['fresh_runtime_identity']['boot_id'] == '047e744d-d2ea-4d9a-8746-7734b58db3b2'
assert prior['preserved_local_source_v3_binding']['tree_manifest_sha256'] == '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'
assert prior['authorization']['repository_only_executor_v2_implementation_review_authorized'] is True
assert prior['authorization']['runtime_executor_v2_transport_authorized'] is False
assert prior['authorization']['runtime_candidate_binding_authorized'] is False
assert prior_record['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review'
assert contract['step'] == 246
assert contract['freeze_status'] == 'PASS'
assert contract['future_executor_v2_contract']['state'] == 'reviewed-frozen-not-implemented'
assert contract['future_executor_v2_contract']['refresh_success_contract']['human_spaced_error_prefix'] == 'Error downloading from '
assert contract['future_executor_v2_contract']['refresh_success_contract']['hyphenated_literal_guard_forbidden'] is True
assert contract_record['future_executor_v2_state'] == 'reviewed-frozen-not-implemented'

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review',
    'step': 254,
    'review_only': True,
    'review_status': 'PASS',
    'accepted_step_253': {
        'helper_sha256': '8c54917fbfdafafc6e1aa698a5395bee64fe684f4dcf7705b3cbbc77bab1166c',
        'document_sha256': '6dc6db58fc8d03f346bb6b8d59ce5aae9503bd19a450a6633004fcd60dc8553e',
        'harness_sha256': 'b85b8fd0d29a63490b400b152df2c147a49a47d7b324f7e050b725d38780c8ef',
        'policy_sha256': 'af5a87022c2379ede9d7c6ec4fae4d15fc86bf08b491b3ea21082bebe5ff8d84',
        'record_sha256': 'ec9b98e3b48fcc35c02d9e3fa50b9cba2b23e051e46af0e957519dd67ec56b97',
        'freeze_status': 'PASS',
        'fresh_identity_consumed_without_machine_action': True,
    },
    'accepted_step_246_contract': {
        'policy_sha256': 'cf32f3d6b5df64d176c154e506c356c53e63da794c961edbbcbf1557ecef25f0',
        'record_sha256': '2f55b4a83a498fdf1c347ba2f35c25b5b0a3a87233f3df66f2362cfa12491071',
        'contract_state': 'reviewed-frozen-consumed-by-v2-implementation',
    },
    'historical_failed_remediation_executor': {
        'body_sha256': 'ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b',
        'builder_sha256': 'a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379',
        'executor_sha256': '9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c',
        'preserved_unchanged': True,
        'runtime_authorization_reusable': False,
    },
    'executor_v2_implementation': {
        'state': 'implemented-reviewed-awaiting-freeze',
        'body_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh',
        'body_sha256': 'c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68',
        'builder_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh',
        'builder_sha256': '43c858e351d32c4ed2c28c687ccc9a06a1fc78f77032eaf20fb3d40a3ff197da',
        'executor_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh',
        'executor_sha256': 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d',
        'repository_acceptance_harness_path': 'tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh',
        'repository_acceptance_harness_sha256': '86fcfd31ebe023d6fdfe3ec0c0c6bebaac3a17fd47202de43ffa3afe89854eef',
        'repository_acceptance_result': 'PASS (94 passes, 0 failures)',
        'payload_reproducibility': 'builder-output-matches-canonical-executor-byte-for-byte',
        'runtime_acknowledgement': '--execute-runtime-remediation-v2-validation',
        'boot_id': '047e744d-d2ea-4d9a-8746-7734b58db3b2',
        'local_source_generation': 'local-source-v3',
        'local_source_v3_tree_manifest_sha256': '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b',
        'target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
        'runtime_evidence_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation-v2',
        'published_archive_path': '/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-v2-evidence.tar.gz',
    },
    'reviewed_contract': {
        'slackpkg_exit_zero_required': True,
        'slackpkg_exit_zero_sufficient': False,
        'stdout_and_stderr_capture_required': True,
        'human_spaced_error_prefix': 'Error downloading from ',
        'human_spaced_error_prefix_hex': '4572726f7220646f776e6c6f6164696e672066726f6d20',
        'human_spaced_error_must_fail_closed': True,
        'hyphenated_literal_guard_forbidden': True,
        'fresh_transaction_owned_pkglist_required': True,
        'pre_refresh_pkglist_must_be_absent': True,
        'same_transaction_candidate_binding_required': True,
        'target_specific_candidate_guard_required': True,
        'exact_target_candidate_row_count': 1,
        'source_backing_required_for_candidate_classification': True,
        'v3_compatibility_PGP_marker_exact': 'PGP compatibility marker for Slackpkg checkchangelog only.',
        'v3_openpgp_signature_impersonation_forbidden': True,
        'historical_local_source_v2_no_PGP_state_preserved': True,
        'failed_remediation_evidence_preserved': True,
        'rollback_on_any_failure_after_mutation': True,
        'slackpkg_state_restored': True,
        'geninitrd_policy_restored': True,
        'boot_artifacts_unchanged': True,
        'external_network_forbidden': True,
        'no_reboot': True,
        'real_tab_tsv_evidence': True,
    },
    'authorization': {
        'repository_only_executor_v2_implementation_freeze_authorized': True,
        'runtime_executor_v2_implementation_authorized': False,
        'runtime_executor_v2_transport_authorized': False,
        'runtime_candidate_binding_authorized': False,
        'runtime_rerun_authorized': False,
        'package_action_authorized': False,
        'slackpkg_mutation_authorized': False,
        'repository_refresh_authorized': False,
        'network_access_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'evidence_cleanup_authorized': False,
        'persistent_configuration_change_authorized': False,
        'phase_2_start_authorized': False,
    },
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review.sh',
    'helper_sha256': helper_sha,
    'machine_action_required': False,
    'controller_action_required': False,
    'future_work_requires_explicit_authorization': True,
    'pause_safe': False,
    'strong_safe_pause': False,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze',
}
out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step','254'),
    ('revision','runtime-executor-v2-implementation-review'),
    ('review_status','PASS'),
    ('accepted_step_253','yes'),
    ('accepted_step_246_contract','yes'),
    ('historical_failed_remediation_executor_preserved','yes'),
    ('executor_v2_state','implemented-reviewed-awaiting-freeze'),
    ('executor_v2_body_sha256','c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68'),
    ('executor_v2_builder_sha256','43c858e351d32c4ed2c28c687ccc9a06a1fc78f77032eaf20fb3d40a3ff197da'),
    ('executor_v2_sha256','deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d'),
    ('repository_acceptance_harness_sha256','86fcfd31ebe023d6fdfe3ec0c0c6bebaac3a17fd47202de43ffa3afe89854eef'),
    ('repository_acceptance_result','PASS (94 passes, 0 failures)'),
    ('builder_reproduces_canonical_executor','yes'),
    ('fresh_boot_id','047e744d-d2ea-4d9a-8746-7734b58db3b2'),
    ('local_source_generation','local-source-v3'),
    ('local_source_v3_tree_manifest_sha256','8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'),
    ('human_spaced_error_prefix_hex','4572726f7220646f776e6c6f6164696e672066726f6d20'),
    ('hyphenated_literal_guard','forbidden'),
    ('slackpkg_exit_zero_sufficient','no'),
    ('fresh_transaction_owned_pkglist_required','yes'),
    ('same_transaction_candidate_binding_required','yes'),
    ('candidate_set_bound','no'),
    ('runtime_executor_v2_transport_authorized','no'),
    ('runtime_rerun_authorized','no'),
    ('package_action_authorized','no'),
    ('slackpkg_mutation_authorized','no'),
    ('network_access_authorized','no'),
    ('boot_action_authorized','no'),
    ('reboot_authorized','no'),
    ('machine_action_required','no'),
    ('controller_action_required','no'),
    ('pause_safe','no'),
    ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze'),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    csv.writer(handle, delimiter='\t', lineterminator='\n').writerows(rows)
PY

printf 'implementation_review_status\tPASS\n'
printf 'executor_v2_state\timplemented-reviewed-awaiting-freeze\n'
printf 'repository_acceptance_result\tPASS (94 passes, 0 failures)\n'
printf 'builder_reproduces_canonical_executor\tyes\n'
printf 'runtime_executor_v2_transport_authorized\tno\n'
printf 'runtime_rerun_authorized\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze\n'
