#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.sh [--output-dir DIR] [--help]

Consume the single authorized step-257 executor-v2 runtime attempt as a fail-closed
result, freeze the observed empty transaction pkglist and verified rollback state,
revoke all machine authority, and establish a strong safe pause before any
repository-only remediation planning.
USAGE
}

output_dir=
while (($#)); do
    case "$1" in
        --output-dir)
            (($# >= 2)) || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }
            output_dir=$2
            shift 2
            ;;
        --help)
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

helper_path=$(readlink -f -- "${BASH_SOURCE[0]}")
repo_root=$(CDPATH= cd -- "$(dirname -- "$helper_path")/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze.tsv"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"

[[ -f $prior_policy && ! -L $prior_policy ]] || { printf 'ERROR: accepted step-257 policy missing or unsafe\n' >&2; exit 3; }
[[ -f $prior_record && ! -L $prior_record ]] || { printf 'ERROR: accepted step-257 record missing or unsafe\n' >&2; exit 3; }
[[ -f $executor && ! -L $executor ]] || { printf 'ERROR: frozen executor-v2 missing or unsafe\n' >&2; exit 3; }
[[ $(sha256sum -- "$prior_policy" | awk '{print $1}') == 'adb641120d073e8ccef80ce9b3fcaddf7095a88575827d4ff7c2d43b5fa68e0b' ]] || { printf 'ERROR: accepted step-257 policy SHA-256 drift\n' >&2; exit 4; }
[[ $(sha256sum -- "$prior_record" | awk '{print $1}') == '310e711e59e9039238dc6d428dbeb61977e8e4632a153a98a92c918ebb637ae3' ]] || { printf 'ERROR: accepted step-257 record SHA-256 drift\n' >&2; exit 4; }
[[ $(sha256sum -- "$executor" | awk '{print $1}') == 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d' ]] || { printf 'ERROR: frozen executor-v2 SHA-256 drift\n' >&2; exit 4; }

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$prior_policy" "$prior_record" "$policy" "$record" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

prior_policy_path, prior_record_path, out_policy_path, out_record_path = map(Path, sys.argv[1:5])
helper_sha = sys.argv[5]
prior = json.loads(prior_policy_path.read_text(encoding='utf-8'))
with prior_record_path.open(encoding='utf-8', newline='') as handle:
    prior_record = dict(csv.reader(handle, delimiter='\t'))

assert prior['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze'
assert prior['step'] == 257
assert prior['freeze_status'] == 'PASS'
assert prior['frozen_runtime_authorization']['execution_use_count'] == 1
assert prior['frozen_runtime_authorization']['authorization_consumed_when'] == 'executor-runtime-command-starts'
assert prior['frozen_runtime_authorization']['rerun_after_any_exit_authorized'] is False
assert prior['authorization']['runtime_scenario_execution_authorized'] is True
assert prior_record['step'] == '257'
assert prior_record['execution_use_count'] == '1'

observed = {
    'runtime_result': 'FAIL_CLOSED',
    'authorization_use_consumed': True,
    'executor_started': True,
    'terminal_error': 'ERROR: fresh pkglist exposes 0 exact target candidates instead of one',
    'failure_stage': 'candidate-binding-after-local-refresh-before-reference-apply',
    'evidence_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation-v2',
    'evidence_root_present': True,
    'result_tsv_present': False,
    'candidate_binding_tsv_present': False,
    'slackpkg_refresh': {
        'refresh_status': 'PASS',
        'exit_code': 0,
        'human_spaced_error_signal': 'absent',
        'pre_refresh_pkglist_state': 'absent',
        'post_refresh_pkglist_state': 'present-regular',
        'pkglist_sha256': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        'pkglist_size_bytes': 0,
        'kernel_headers_rows': 0,
        'first_twenty_rows': 0,
    },
    'cleanup': {
        'cleanup_triggered': True,
        'rollback_header_from': 'kernel-headers-6.18.44-x86-1',
        'cleanup_stderr_empty': True,
    },
    'post_failure_read_only_observation': {
        'kernel_headers_record': 'kernel-headers-6.18.45-x86-1',
        'slackpkg_conf_sha256': 'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
        'slackpkg_mirrors_sha256': '71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
    },
    'control_flow': {
        'predecessor_staging_reached': True,
        'temporary_slackpkg_configuration_reached': True,
        'local_metadata_refresh_reached': True,
        'candidate_binding_completed': False,
        'reference_apply_reached': False,
        'success_publication_reached': False,
        'cleanup_trap_reached': True,
    },
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause',
    'step': 258,
    'review_status': 'PASS',
    'runtime_result': 'FAIL_CLOSED',
    'strong_safe_pause': True,
    'accepted_step_257': {
        'helper_sha256': '43b63cf06bbc9b8de03fdca51e8d694b2c45132f46e1e77037a8ea8f51f98793',
        'document_sha256': 'c254030cb9c0c81b2bc05efde66197a976385f4eccb9d3e1bac71483e195136b',
        'harness_sha256': 'ef507545d94a54bb99ba1e54dde7ed4acabb80f1ba6a1b8169210cba9ab637d0',
        'policy_sha256': 'adb641120d073e8ccef80ce9b3fcaddf7095a88575827d4ff7c2d43b5fa68e0b',
        'record_sha256': '310e711e59e9039238dc6d428dbeb61977e8e4632a153a98a92c918ebb637ae3',
        'single_use_authorization_was_valid': True,
        'single_use_authorization_consumed': True,
        'rerun_authority_revoked': True,
    },
    'observed_runtime_result': observed,
    'failure_characterization': {
        'class': 'empty-fresh-slackpkg-pkglist-after-successful-local-refresh',
        'primary_observation': 'fresh transaction-owned pkglist is a zero-byte regular file',
        'candidate_count': 0,
        'not_a_row_matching_mismatch': True,
        'slackpkg_exit_zero_did_not_establish_candidate_availability': True,
        'human_spaced_download_error_not_observed': True,
        'root_cause_not_yet_frozen': True,
        'next_root_cause_focus': 'Slackpkg FILELIST/pkglist metadata-generation compatibility for local-source-v3',
    },
    'restoration_assessment': {
        'bounded_mutation_started': True,
        'only_pre_reference_package_mutation': 'kernel-headers-6.18.45-to-6.18.44',
        'cleanup_triggered': True,
        'target_header_record_restored': True,
        'slackpkg_configuration_restored': True,
        'slackpkg_mirrors_restored': True,
        'reference_apply_not_reached': True,
        'boot_mutation_path_not_reached': True,
        'success_publication_not_reached': True,
        'failed_v2_evidence_must_be_preserved': True,
    },
    'preservation_contract': {
        'failed_v2_evidence_root': observed['evidence_root'],
        'failed_v2_evidence_must_be_preserved_unchanged': True,
        'accepted_local_source_v3_must_be_preserved_unchanged': True,
        'accepted_local_source_v3_manifest_sha256': prior['frozen_runtime_authorization']['local_source_v3']['tree_manifest_sha256'],
        'historical_local_source_v2_must_be_preserved_unchanged': True,
        'historical_failed_evidence_must_be_preserved_unchanged': True,
        'canonical_executor_v2_sha256': prior['frozen_runtime_authorization']['executor']['sha256'],
        'executor_v2_must_not_be_rerun': True,
    },
    'authorization': {
        'target_observation_authorized': False,
        'probe_transport_copy_authorized': False,
        'runtime_executor_v2_build_authorized': False,
        'runtime_executor_v2_transport_authorized': False,
        'predecessor_package_transport_authorized': False,
        'predecessor_package_staging_authorized': False,
        'temporary_slackpkg_configuration_authorized': False,
        'local_source_metadata_refresh_authorized': False,
        'repository_refresh_authorized': False,
        'runtime_candidate_binding_authorized': False,
        'reference_apply_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'runtime_rerun_authorized': False,
        'package_action_authorized': False,
        'slackpkg_mutation_authorized': False,
        'network_access_authorized': False,
        'persistent_configuration_change_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'evidence_cleanup_authorized': False,
        'phase_2_start_authorized': False,
        'repository_only_root_cause_review_authorized': True,
    },
    'safe_pause': {
        'strong_safe_pause': True,
        'pause_safe': True,
        'no_open_operational_authorization': True,
        'machine_action_required': False,
        'controller_action_required': False,
        'runtime_authorization_consumed': True,
        'runtime_rerun_forbidden': True,
        'failed_evidence_preservation_required': True,
        'fresh_revalidation_required_before_any_future_machine_action': True,
    },
    'machine_action_required': False,
    'controller_action_required': False,
    'future_work_requires_explicit_authorization': True,
    'future_work_requires_fresh_boundary': True,
    'pause_safe': True,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review',
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-failed-result-review-and-strong-safe-pause.sh',
    'helper_sha256': helper_sha,
}

out_policy_path.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step', '258'),
    ('revision', 'runtime-executor-v2-failed-result-review-and-strong-safe-pause'),
    ('review_status', 'PASS'),
    ('runtime_result', 'FAIL_CLOSED'),
    ('accepted_step_257', 'yes'),
    ('step_257_authorization_consumed', 'yes'),
    ('runtime_rerun_authorized', 'no'),
    ('terminal_error', observed['terminal_error']),
    ('failure_stage', observed['failure_stage']),
    ('slackpkg_refresh_status', 'PASS'),
    ('slackpkg_refresh_exit_code', '0'),
    ('human_spaced_error_signal', 'absent'),
    ('fresh_pkglist_state', 'present-regular-empty'),
    ('fresh_pkglist_sha256', observed['slackpkg_refresh']['pkglist_sha256']),
    ('fresh_pkglist_size_bytes', '0'),
    ('kernel_headers_rows', '0'),
    ('candidate_binding_completed', 'no'),
    ('reference_apply_reached', 'no'),
    ('cleanup_triggered', 'yes'),
    ('rollback_header_from', 'kernel-headers-6.18.44-x86-1'),
    ('post_failure_header_record', 'kernel-headers-6.18.45-x86-1'),
    ('post_failure_slackpkg_conf_sha256', observed['post_failure_read_only_observation']['slackpkg_conf_sha256']),
    ('post_failure_slackpkg_mirrors_sha256', observed['post_failure_read_only_observation']['slackpkg_mirrors_sha256']),
    ('result_tsv_present', 'no'),
    ('failure_class', policy['failure_characterization']['class']),
    ('root_cause_frozen', 'no'),
    ('machine_action_required', 'no'),
    ('controller_action_required', 'no'),
    ('pause_safe', 'yes'),
    ('strong_safe_pause', 'yes'),
    ('next_stage', policy['next_stage']),
]
with out_record_path.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

printf 'failed_result_review_status\tPASS\n'
printf 'runtime_result\tFAIL_CLOSED\n'
printf 'fresh_pkglist_state\tpresent-regular-empty\n'
printf 'fresh_pkglist_sha256\te3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855\n'
printf 'reference_apply_reached\tno\n'
printf 'runtime_rerun_authorized\tno\n'
printf 'strong_safe_pause\tyes\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-review\n'
