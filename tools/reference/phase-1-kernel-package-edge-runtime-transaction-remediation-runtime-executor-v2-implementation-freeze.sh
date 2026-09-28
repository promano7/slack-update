#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze.sh"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review.tsv"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
output_dir=''

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze.sh [--output-dir DIR] [--help]

Consume the accepted Phase 1 step-254 repository-only executor-v2 implementation
review, reprove deterministic generation and repository acceptance, and freeze
the exact v2 body, builder, canonical executor and acceptance harness. This
helper grants no transport, candidate-binding, package, Slackpkg, network, boot,
restart or runtime-execution authority.
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

for f in "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" \
         "$body" "$builder" "$executor" "$acceptance_harness" "$helper_path"; do
    [[ -f $f && ! -L $f ]] || {
        printf 'ERROR: required repository input is missing or unsafe: %s\n' "$f" >&2
        exit 3
    }
done

check_hash() {
    local path=$1 expected=$2 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: frozen input SHA-256 drift: %s\nexpected: %s\nactual:   %s\n' "$path" "$expected" "$actual" >&2
        exit 4
    }
}

check_hash "$prior_helper" '40a8c9eb74607c9edd05607896acc61425f5c1b74aa33ecba5acba140c93e6bf'
check_hash "$prior_doc" '65de7659747f947bf9299a75d801d0f913939c563b56fb06586c4ae2453d5936'
check_hash "$prior_harness" 'd5784fd853414d1129cf662b859ec37df53d338212cae65a0524cec480f83f7b'
check_hash "$prior_policy" 'ac95d38ea65cb8911c09c93ca5cd33d106e016347cfc906ca329b106cfdaa537'
check_hash "$prior_record" '21003cc3cf68ea8996578e9b132ccbde615ef4b91958471857a10557d1802cde'
check_hash "$body" 'c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68'
check_hash "$builder" '43c858e351d32c4ed2c28c687ccc9a06a1fc78f77032eaf20fb3d40a3ff197da'
check_hash "$executor" 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d'
check_hash "$acceptance_harness" '86fcfd31ebe023d6fdfe3ec0c0c6bebaac3a17fd47202de43ffa3afe89854eef'

work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
rebuilt="$work/executor-v2.sh"
"$builder" --repo-root "$repo_root" --output "$rebuilt" >"$work/builder.out"
cmp -s -- "$rebuilt" "$executor" || {
    printf 'ERROR: rebuilt executor-v2 differs from canonical executor-v2\n' >&2
    exit 5
}
rebuilt_sha=$(sha256sum -- "$rebuilt" | awk '{print $1}')
[[ $rebuilt_sha == 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d' ]] || {
    printf 'ERROR: rebuilt executor-v2 SHA-256 mismatch\n' >&2
    exit 5
}
if ! "$acceptance_harness" >"$work/acceptance.out" 2>&1; then
    cat -- "$work/acceptance.out" >&2
    printf 'ERROR: executor-v2 repository acceptance failed\n' >&2
    exit 6
fi
grep -Fqx 'Result: PASS (94 passes, 0 failures)' "$work/acceptance.out" || {
    cat -- "$work/acceptance.out" >&2
    printf 'ERROR: unexpected executor-v2 repository acceptance result\n' >&2
    exit 6
}

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || {
    printf 'ERROR: output directory is unsafe\n' >&2
    exit 7
}
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$prior_policy" "$prior_record" "$policy" "$record" "$helper_sha" <<'PYFREEZE'
import csv
import json
import sys
from pathlib import Path

prior_policy_path, prior_record_path, out_policy_path, out_record_path = map(Path, sys.argv[1:5])
helper_sha = sys.argv[5]
prior = json.loads(prior_policy_path.read_text(encoding='utf-8'))
with prior_record_path.open(encoding='utf-8', newline='') as handle:
    record = dict(csv.reader(handle, delimiter='\t'))

assert prior['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review'
assert prior['step'] == 254
assert prior['review_status'] == 'PASS'
assert prior['executor_v2_implementation']['state'] == 'implemented-reviewed-awaiting-freeze'
assert prior['executor_v2_implementation']['repository_acceptance_result'] == 'PASS (94 passes, 0 failures)'
assert prior['authorization']['repository_only_executor_v2_implementation_freeze_authorized'] is True
assert prior['authorization']['runtime_executor_v2_transport_authorized'] is False
assert record['step'] == '254'
assert record['review_status'] == 'PASS'

impl = prior['executor_v2_implementation']
contract = prior['reviewed_contract']
policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze',
    'step': 255,
    'review_only': True,
    'freeze_status': 'PASS',
    'accepted_step_254': {
        'helper_sha256': '40a8c9eb74607c9edd05607896acc61425f5c1b74aa33ecba5acba140c93e6bf',
        'document_sha256': '65de7659747f947bf9299a75d801d0f913939c563b56fb06586c4ae2453d5936',
        'harness_sha256': 'd5784fd853414d1129cf662b859ec37df53d338212cae65a0524cec480f83f7b',
        'policy_sha256': 'ac95d38ea65cb8911c09c93ca5cd33d106e016347cfc906ca329b106cfdaa537',
        'record_sha256': '21003cc3cf68ea8996578e9b132ccbde615ef4b91958471857a10557d1802cde',
        'review_status': 'PASS',
        'semantics_consumed_without_change': True,
        'no_machine_authority_inherited': True,
    },
    'accepted_step_246_contract': prior['accepted_step_246_contract'],
    'accepted_step_253': prior['accepted_step_253'],
    'historical_failed_remediation_executor': dict(
        prior['historical_failed_remediation_executor'],
        state='historical-evidence-preserved',
    ),
    'frozen_executor_v2': {
        'state': 'implementation-frozen-awaiting-runtime-authorization-review',
        'body_path': impl['body_path'],
        'body_sha256': impl['body_sha256'],
        'builder_path': impl['builder_path'],
        'builder_sha256': impl['builder_sha256'],
        'executor_path': impl['executor_path'],
        'executor_sha256': impl['executor_sha256'],
        'repository_acceptance_harness_path': impl['repository_acceptance_harness_path'],
        'repository_acceptance_harness_sha256': impl['repository_acceptance_harness_sha256'],
        'repository_acceptance_result': 'PASS (94 passes, 0 failures)',
        'builder_reproducibility_reverified': True,
        'canonical_executor_rebuilt_byte_for_byte': True,
        'runtime_acknowledgement': impl['runtime_acknowledgement'],
        'boot_id': impl['boot_id'],
        'target_sha256': impl['target_sha256'],
        'local_source_generation': impl['local_source_generation'],
        'local_source_v3_tree_manifest_sha256': impl['local_source_v3_tree_manifest_sha256'],
        'runtime_evidence_root': impl['runtime_evidence_root'],
        'published_archive_path': impl['published_archive_path'],
    },
    'frozen_runtime_contract': {
        'stdout_and_stderr_capture_required': contract['stdout_and_stderr_capture_required'],
        'slackpkg_exit_zero_required': contract['slackpkg_exit_zero_required'],
        'slackpkg_exit_zero_sufficient': contract['slackpkg_exit_zero_sufficient'],
        'human_spaced_error_must_fail_closed': contract['human_spaced_error_must_fail_closed'],
        'human_spaced_error_prefix': contract['human_spaced_error_prefix'],
        'human_spaced_error_prefix_hex': contract['human_spaced_error_prefix_hex'],
        'hyphenated_literal_guard_forbidden': contract['hyphenated_literal_guard_forbidden'],
        'pre_refresh_pkglist_must_be_absent': contract['pre_refresh_pkglist_must_be_absent'],
        'fresh_transaction_owned_pkglist_required': contract['fresh_transaction_owned_pkglist_required'],
        'same_transaction_candidate_binding_required': contract['same_transaction_candidate_binding_required'],
        'target_specific_candidate_guard_required': contract['target_specific_candidate_guard_required'],
        'source_backing_required_for_candidate_classification': contract['source_backing_required_for_candidate_classification'],
        'exact_target_candidate_row_count': contract['exact_target_candidate_row_count'],
        'v3_compatibility_PGP_marker_exact': contract['v3_compatibility_PGP_marker_exact'],
        'v3_openpgp_signature_impersonation_forbidden': contract['v3_openpgp_signature_impersonation_forbidden'],
        'rollback_on_any_failure_after_mutation': contract['rollback_on_any_failure_after_mutation'],
        'slackpkg_state_restored': contract['slackpkg_state_restored'],
        'geninitrd_policy_restored': contract['geninitrd_policy_restored'],
        'boot_artifacts_unchanged': contract['boot_artifacts_unchanged'],
        'external_network_forbidden': contract['external_network_forbidden'],
        'no_reboot': contract['no_reboot'],
        'failed_remediation_evidence_preserved': contract['failed_remediation_evidence_preserved'],
        'historical_local_source_v2_no_PGP_state_preserved': contract['historical_local_source_v2_no_PGP_state_preserved'],
        'real_tab_tsv_evidence': contract['real_tab_tsv_evidence'],
    },
    'authorization': {
        'repository_only_executor_v2_runtime_authorization_review_authorized': True,
        'runtime_executor_v2_build_authorized': False,
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
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze.sh',
    'helper_sha256': helper_sha,
    'future_work_requires_explicit_authorization': True,
    'machine_action_required': False,
    'controller_action_required': False,
    'pause_safe': False,
    'strong_safe_pause': False,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review',
}

out_policy_path.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step', '255'),
    ('revision', 'runtime-executor-v2-implementation-freeze'),
    ('freeze_status', 'PASS'),
    ('accepted_step_254', 'yes'),
    ('implementation_frozen', 'yes'),
    ('historical_failed_remediation_executor_preserved', 'yes'),
    ('executor_v2_body_sha256', impl['body_sha256']),
    ('executor_v2_builder_sha256', impl['builder_sha256']),
    ('executor_v2_sha256', impl['executor_sha256']),
    ('repository_acceptance_harness_sha256', impl['repository_acceptance_harness_sha256']),
    ('repository_acceptance_result', 'PASS (94 passes, 0 failures)'),
    ('builder_reproducibility_reverified', 'yes'),
    ('canonical_executor_rebuilt_byte_for_byte', 'yes'),
    ('fresh_boot_id', impl['boot_id']),
    ('local_source_generation', impl['local_source_generation']),
    ('local_source_v3_tree_manifest_sha256', impl['local_source_v3_tree_manifest_sha256']),
    ('human_spaced_error_prefix_hex', contract['human_spaced_error_prefix_hex']),
    ('slackpkg_exit_zero_sufficient', 'no'),
    ('fresh_transaction_owned_pkglist_required', 'yes'),
    ('same_transaction_candidate_binding_required', 'yes'),
    ('candidate_set_bound', 'no'),
    ('repository_only_executor_v2_runtime_authorization_review_authorized', 'yes'),
    ('runtime_executor_v2_transport_authorized', 'no'),
    ('runtime_rerun_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('slackpkg_mutation_authorized', 'no'),
    ('network_access_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('controller_action_required', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review'),
]
with out_record_path.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PYFREEZE

printf 'implementation_freeze_status\tPASS\n'
printf 'implementation_frozen\tyes\n'
printf 'repository_acceptance_result\tPASS (94 passes, 0 failures)\n'
printf 'builder_reproducibility_reverified\tyes\n'
printf 'runtime_executor_v2_transport_authorized\tno\n'
printf 'runtime_rerun_authorized\tno\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review\n'
