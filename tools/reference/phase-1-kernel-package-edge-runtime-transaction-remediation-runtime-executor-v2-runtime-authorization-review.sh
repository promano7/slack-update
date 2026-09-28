#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review.sh"
prior_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze.sh"
prior_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze.md"
prior_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze-harness.sh"
prior_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze-policy.json"
prior_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze.tsv"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh"
output_dir=''

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review.sh [--output-dir DIR] [--help]

Review the exact future single-use runtime authorization contract for the frozen
executor-v2. This step is repository-only: it records transport, preflight,
invalidation, bounded mutation and evidence requirements while granting no
controller or target-machine authority.
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

for f in "$prior_helper" "$prior_doc" "$prior_harness" "$prior_policy" "$prior_record" "$executor" "$acceptance_harness" "$helper_path"; do
    [[ -f $f && ! -L $f ]] || { printf 'ERROR: required repository input missing or unsafe: %s\n' "$f" >&2; exit 3; }
done

check_hash() {
    local path=$1 expected=$2 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: frozen input SHA-256 drift: %s\nexpected: %s\nactual:   %s\n' "$path" "$expected" "$actual" >&2
        exit 4
    }
}

check_hash "$prior_helper" 'b0aabffa761c374efabac2f687c87bb3d6acc99094e532c347033032b07c6d08'
check_hash "$prior_doc" '4d55dbea026f59411a1afad7a60aaf3e937d9255dc8c6089dc8310b8ba952356'
check_hash "$prior_harness" '5fec4c3bffaceb6fea5f24f012639533ffff0f45985b89452330a2a681b3bd0a'
check_hash "$prior_policy" '416bbd6b33ce08f87e952b76036239352067e72002759d4fd3bbbea9dae6c25b'
check_hash "$prior_record" '97afc879507953d875367173349c0574d180611642d6ffec0493840c05ad8f13'
check_hash "$executor" 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d'
check_hash "$acceptance_harness" '86fcfd31ebe023d6fdfe3ec0c0c6bebaac3a17fd47202de43ffa3afe89854eef'

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }
policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$prior_policy" "$prior_record" "$policy" "$record" "$helper_sha" <<'PYREVIEW'
import csv
import json
import sys
from pathlib import Path

ppath, rpath, outp, outr = map(Path, sys.argv[1:5])
helper_sha = sys.argv[5]
p = json.loads(ppath.read_text(encoding='utf-8'))
with rpath.open(encoding='utf-8', newline='') as handle:
    r = dict(csv.reader(handle, delimiter='\t'))
assert p['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze'
assert p['step'] == 255 and p['freeze_status'] == 'PASS'
assert p['frozen_executor_v2']['state'] == 'implementation-frozen-awaiting-runtime-authorization-review'
assert p['authorization']['repository_only_executor_v2_runtime_authorization_review_authorized'] is True
assert p['authorization']['runtime_executor_v2_transport_authorized'] is False
assert r['step'] == '255' and r['freeze_status'] == 'PASS'

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review',
    'step': 256,
    'review_only': True,
    'review_status': 'PASS',
    'accepted_step_255': {
        'helper_sha256': 'b0aabffa761c374efabac2f687c87bb3d6acc99094e532c347033032b07c6d08',
        'document_sha256': '4d55dbea026f59411a1afad7a60aaf3e937d9255dc8c6089dc8310b8ba952356',
        'harness_sha256': '5fec4c3bffaceb6fea5f24f012639533ffff0f45985b89452330a2a681b3bd0a',
        'policy_sha256': '416bbd6b33ce08f87e952b76036239352067e72002759d4fd3bbbea9dae6c25b',
        'record_sha256': '97afc879507953d875367173349c0574d180611642d6ffec0493840c05ad8f13',
        'freeze_status': 'PASS',
        'semantics_consumed_without_change': True,
        'no_machine_authority_inherited': True,
    },
    'reviewed_runtime_authorization_contract': {
        'state': 'reviewed-awaiting-single-use-authorization-freeze-v2',
        'authorization_scope': 'single-bounded-kernel-header-edge-runtime-remediation-v2-transaction',
        'execution_target': 'vbox-slackcurrent.vbox-slackcurrent.org',
        'required_running_kernel': '6.18.45',
        'required_boot_id': '047e744d-d2ea-4d9a-8746-7734b58db3b2',
        'required_package_database_manifest_sha256': '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
        'required_slackpkg_conf_sha256': 'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
        'required_slackpkg_mirrors_sha256': '71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
        'executor': {
            'repository_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh',
            'sha256': 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d',
            'target_transport_path': '/home/promano/Descargas/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh',
            'must_be_regular_non_symlink': True,
            'target_hash_verification_required_before_execution': True,
            'rebuild_before_transport_authorized': False,
        },
        'predecessor': {
            'artifact': 'kernel-headers-6.18.44-x86-1.txz',
            'record': 'kernel-headers-6.18.44-x86-1',
            'sha256': '3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d',
            'controller_source': '/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts/kernel-headers-6.18.44-x86-1.txz',
            'target_transport_path': '/home/promano/Descargas/kernel-headers-6.18.44-x86-1.txz',
            'must_be_regular_non_symlink': True,
            'controller_hash_verification_required_before_transport': True,
            'target_hash_verification_required_before_execution': True,
            'redownload_authorized': False,
        },
        'staged_target': {
            'path': '/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz',
            'sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
        },
        'local_source_v3': {
            'root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3',
            'tree_manifest': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256',
            'tree_manifest_sha256': '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b',
            'manifest_sidecar_verification_required': True,
            'exact_coverage_required': True,
            'priority_tree_contract_required': True,
            'compatibility_PGP_marker_exact': 'PGP compatibility marker for Slackpkg checkchangelog only.',
            'openpgp_signature_impersonation_forbidden': True,
        },
        'historical_state': {
            'failed_runtime_evidence_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction',
            'failed_remediation_evidence_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation',
            'failed_evidence_must_remain_present': True,
            'local_source_v2_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2',
            'local_source_v2_must_remain_unchanged': True,
            'local_source_v2_manifest_sha256': 'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
        },
        'new_evidence': {
            'runtime_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation-v2',
            'runtime_root_must_be_absent_before_start': True,
            'published_archive': '/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-v2-evidence.tar.gz',
            'published_sha256': '/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-v2-evidence.tar.gz.sha256',
            'published_outputs_must_be_absent_before_start': True,
            'publication_required_for_result_review': True,
            'result_review_required_before_any_further_machine_action': True,
        },
        'exact_execution_command': 'sudo bash phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh --execute-runtime-remediation-v2-validation',
        'runtime_acknowledgement': '--execute-runtime-remediation-v2-validation',
        'transaction_lifetime': 'single-execution-authority-consumed-on-runtime-start',
        'candidate_binding_lifetime': 'same-runtime-transaction-only',
        'preflight_must_complete_before_first_mutation': True,
        'drift_action': 'abort-before-first-mutation-and-return-to-fresh-revalidation-review',
        'authorization_invalidated_by': [
            'executor-byte-drift', 'predecessor-byte-drift', 'fqdn-drift', 'running-kernel-drift', 'boot-id-drift',
            'package-database-manifest-drift', 'slackpkg-configuration-drift', 'slackpkg-mirrors-drift', 'staged-target-drift',
            'local-source-v3-tree-drift', 'local-source-v3-manifest-sidecar-failure', 'local-source-v3-coverage-drift',
            'local-source-v3-priority-contract-drift', 'local-source-v3-PGP-marker-drift', 'local-source-v3-openpgp-impersonation',
            'historical-failed-evidence-loss', 'historical-local-source-v2-drift', 'preexisting-v2-remediation-evidence-root',
            'preexisting-v2-remediation-published-output'
        ],
        'bounded_mutation': {
            'temporary_predecessor_staging_authorized_in_future_single_use_freeze': True,
            'temporary_slackpkg_configuration_authorized_in_future_single_use_freeze': True,
            'local_file_source_metadata_refresh_authorized_in_future_single_use_freeze': True,
            'single_target_specific_candidate_binding_authorized_in_future_single_use_freeze': True,
            'frozen_reference_apply_authorized_in_future_single_use_freeze': True,
            'fresh_transaction_owned_pkglist_required': True,
            'human_spaced_error_must_fail_closed': True,
            'slackpkg_exit_zero_sufficient': False,
            'package_mutation_scope': 'kernel-headers-6.18.45-to-6.18.44-to-6.18.45-only',
            'external_network_access_authorized': False,
            'boot_action_authorized': False,
            'reboot_authorized': False,
            'persistent_configuration_change_authorized': False,
        },
        'required_final_state': {
            'header_record': 'kernel-headers-6.18.45-x86-1',
            'package_database_manifest_sha256': '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
            'boot_id': '047e744d-d2ea-4d9a-8746-7734b58db3b2',
            'running_kernel': '6.18.45',
            'local_source_v3_tree_manifest_sha256': '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b',
            'predecessor_terminal_state_forbidden': True,
            'slackpkg_configuration_and_state_restored': True,
            'geninitrd_policy_restored': True,
            'boot_artifacts_unchanged': True,
            'reboot_performed': False,
        },
    },
    'authorization': {
        'repository_only_runtime_authorization_freeze_authorized': True,
        'runtime_executor_v2_build_authorized': False,
        'runtime_executor_v2_transport_authorized': False,
        'predecessor_package_transport_authorized': False,
        'predecessor_package_redownload_authorized': False,
        'predecessor_package_staging_authorized': False,
        'temporary_slackpkg_configuration_authorized': False,
        'local_source_metadata_refresh_authorized': False,
        'runtime_candidate_binding_authorized': False,
        'reference_apply_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'runtime_rerun_authorized': False,
        'package_action_authorized': False,
        'repository_refresh_authorized': False,
        'slackpkg_mutation_authorized': False,
        'network_access_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'evidence_cleanup_authorized': False,
        'persistent_configuration_change_authorized': False,
        'phase_2_start_authorized': False,
    },
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-review.sh',
    'helper_sha256': helper_sha,
    'machine_action_required': False,
    'controller_action_required': False,
    'future_work_requires_explicit_authorization': True,
    'pause_safe': False,
    'strong_safe_pause': False,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze',
}
outp.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step', '256'),
    ('revision', 'runtime-executor-v2-runtime-authorization-review'),
    ('review_status', 'PASS'),
    ('accepted_step_255', 'yes'),
    ('runtime_authorization_contract_state', 'reviewed-awaiting-single-use-authorization-freeze-v2'),
    ('authorization_scope', 'single-bounded-kernel-header-edge-runtime-remediation-v2-transaction'),
    ('target_hostname', 'vbox-slackcurrent.vbox-slackcurrent.org'),
    ('required_running_kernel', '6.18.45'),
    ('required_boot_id', '047e744d-d2ea-4d9a-8746-7734b58db3b2'),
    ('required_package_database_manifest_sha256', '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'),
    ('canonical_executor_v2_sha256', 'deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d'),
    ('executor_target_transport_path', '/home/promano/Descargas/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh'),
    ('predecessor_record', 'kernel-headers-6.18.44-x86-1'),
    ('predecessor_sha256', '3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d'),
    ('local_source_v3_tree_manifest_sha256', '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'),
    ('runtime_acknowledgement', '--execute-runtime-remediation-v2-validation'),
    ('candidate_binding_lifetime', 'same-runtime-transaction-only'),
    ('repository_only_runtime_authorization_freeze_authorized', 'yes'),
    ('runtime_executor_v2_transport_authorized', 'no'),
    ('predecessor_package_transport_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('runtime_rerun_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('slackpkg_mutation_authorized', 'no'),
    ('network_access_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('controller_action_required', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze'),
]
with outr.open('w', encoding='utf-8', newline='') as handle:
    csv.writer(handle, delimiter='\t', lineterminator='\n').writerows(rows)
PYREVIEW

printf 'runtime_authorization_review_status\tPASS\n'
printf 'runtime_authorization_contract_state\treviewed-awaiting-single-use-authorization-freeze-v2\n'
printf 'runtime_executor_v2_transport_authorized\tno\n'
printf 'runtime_rerun_authorized\tno\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze\n'
