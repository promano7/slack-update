#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-executor-design-review.sh [--output-dir DIR] [--help]

Freeze the Phase 1 step-215 repository-only runtime transaction executor design
for the accepted kernel-package-edge scenario. This helper authorizes no target
machine, package, Slackpkg, network, boot, reboot, or runtime execution action.
USAGE
}

output_dir=
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
            exit 2
            ;;
    esac
done

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
step214_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-candidate-set-binding-review-policy.json"
step214_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-candidate-set-binding-review.tsv"
step214_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-candidate-set-binding-review.sh"
reference_script="$repo_root/tools/reference/slack-update-reference.sh"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-design-review.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || {
        printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2
        exit 3
    }
}
check_hash() {
    local file=$1 expected=$2 actual
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: accepted prerequisite SHA-256 mismatch: %s\nexpected: %s\nactual:   %s\n' \
            "$file" "$expected" "$actual" >&2
        exit 4
    }
}

for required in "$step214_policy" "$step214_record" "$step214_helper" "$reference_script" "$helper_path"; do
    require_regular "$required"
done
check_hash "$step214_policy" 'c5fcead64abd1c2d4136c754da6bcca56e2ec5ed16ba1e7193d55c8dceff21aa'
check_hash "$step214_record" 'fd76bd3d83f50e71210bc7b38f2604eb119432ec716af64f0b8608c440228007'
check_hash "$step214_helper" '6bbc9e32e52163025a8947e0a8cb172c8a710ab91dc8420c9a940b9186a325e2'
check_hash "$reference_script" '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-executor-design-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-executor-design-review.tsv"
step214_policy_sha=$(sha256sum -- "$step214_policy" | awk '{print $1}')
step214_record_sha=$(sha256sum -- "$step214_record" | awk '{print $1}')
step214_helper_sha=$(sha256sum -- "$step214_helper" | awk '{print $1}')
reference_sha=$(sha256sum -- "$reference_script" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step214_policy" "$step214_record" "$policy" "$record" \
    "$step214_policy_sha" "$step214_record_sha" "$step214_helper_sha" "$reference_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p214_path, r214_path, out_policy, out_record = map(Path, sys.argv[1:5])
p214_sha, r214_sha, h214_sha, reference_sha, helper_sha = sys.argv[5:10]
p214 = json.loads(p214_path.read_text(encoding='utf-8'))
with r214_path.open(encoding='utf-8', newline='') as handle:
    r214 = dict(csv.reader(handle, delimiter='\t'))

assert p214['scenario'] == 'phase-1-kernel-package-edge-runtime-candidate-set-binding-review'
assert p214['candidate_binding_contract']['binding_lifetime'] == 'same-runtime-transaction-only'
assert p214['runtime_transaction_contract']['candidate_binding_must_be_consumed_without_pause'] is True
assert p214['authorization']['repository_only_runtime_transaction_executor_design_review_authorized'] is True
assert p214['authorization']['runtime_scenario_execution_authorized'] is False
assert r214['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-executor-design-review'

frozen_inputs = {
    'target_hostname': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'running_kernel': '6.18.45',
    'boot_id': '91901677-1dc3-4a39-a4b1-3f87e6875234',
    'package_database_manifest_sha256': '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
    'slackpkg_conf_sha256': 'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
    'slackpkg_mirrors_sha256': '71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
    'reference_script_sha256': reference_sha,
    'effective_config_sha256': '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba',
    'predecessor_artifact': 'kernel-headers-6.18.44-x86-1.txz',
    'predecessor_record': 'kernel-headers-6.18.44-x86-1',
    'predecessor_sha256': '3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d',
    'predecessor_transport_path': '/home/promano/Descargas/kernel-headers-6.18.44-x86-1.txz',
    'target_artifact': 'kernel-headers-6.18.45-x86-1.txz',
    'target_record': 'kernel-headers-6.18.45-x86-1',
    'target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'staged_target_path': '/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz',
    'local_source_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source',
    'local_source_uri': 'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source',
    'local_source_tree_manifest': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256',
    'local_source_tree_manifest_sha256': '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e',
}

executor_design = {
    'state': 'reviewed',
    'family': 'kernel-package-edge',
    'controller_builder_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh',
    'standalone_executor_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh',
    'target_requires_repository': False,
    'payload_form': 'single-self-contained-shell-script-plus-separately-transported-frozen-predecessor-package',
    'runtime_acknowledgement': '--execute-runtime-validation',
    'privilege_boundary': 'root-via-sudo',
    'runtime_evidence_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction',
    'published_archive_path': '/home/promano/slack-update-phase-1-kernel-package-edge-runtime-evidence.tar.gz',
    'published_sha256_path': '/home/promano/slack-update-phase-1-kernel-package-edge-runtime-evidence.tar.gz.sha256',
    'published_owner': 'promano:users',
    'published_mode': '0600',
    'pre_execution_gate': {
        'same_hostname_required': True,
        'same_running_kernel_required': True,
        'same_boot_id_required': True,
        'same_package_database_manifest_required': True,
        'same_slackpkg_configuration_fingerprints_required': True,
        'same_reference_script_sha256_required': True,
        'same_effective_config_sha256_required': True,
        'local_source_tree_must_verify': True,
        'staged_target_sha256_must_match': True,
        'predecessor_transport_sha256_must_match': True,
        'header_must_start_at_target_record': True,
        'boot_package_records_must_match_frozen_baseline': True,
        'runtime_evidence_root_must_be_absent': True,
        'drift_action': 'abort-before-any-package-or-slackpkg-mutation-and-return-to-revalidation-review',
    },
    'runtime_config_derivation': {
        'source_effective_config_sha256': '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba',
        'allowed_overrides': {
            'core.work_dir': 'runtime-evidence-owned-work-directory',
            'core.log_dir': 'runtime-evidence-owned-log-directory',
            'core.lock_file': 'runtime-evidence-owned-lock-file',
            'flatpak.mode': 'disabled',
            'sbo.mode': 'disabled',
            'elf.mode': 'disabled',
            'cinnamon.mode': 'disabled',
        },
        'boot.mode_must_remain': 'auto',
        'slackware.install_new_must_remain': True,
        'slackware.upgrade_all_must_remain': True,
        'package_classification_must_remain_unchanged': True,
        'derived_config_sha256_must_be_recorded': True,
        'reason': 'isolate-the-kernel-header-acceptance-transition-from-unrelated-secondary-module-network-or-build-actions',
    },
    'network_boundary': {
        'external_network_access_allowed': False,
        'candidate_refresh_and_reference_apply_run_in_network_namespace': True,
        'network_namespace_has_no_external_interfaces': True,
        'local_file_source_remains_accessible': True,
    },
    'slackpkg_transaction': {
        'configuration_files': ['/etc/slackpkg/slackpkg.conf', '/etc/slackpkg/mirrors'],
        'state_root': '/var/lib/slackpkg',
        'backup_before_mutation_required': True,
        'original_configuration_hashes_must_match_frozen_identity': True,
        'temporary_mirror_exact_value': 'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source/',
        'temporary_checkgpg_value': 'off',
        'generated_metadata_authenticity_is_not_trusted': True,
        'package_authenticity_source': 'frozen-step-197-detached-signature-byte-binding',
        'local_metadata_refresh_only': True,
        'configuration_restore_byte_for_byte_required': True,
        'state_restore_byte_for_byte_required': True,
    },
    'package_transition': {
        'stage_command_role': 'upgradepkg-downgrade-selected-header-only',
        'predecessor_transport_path': frozen_inputs['predecessor_transport_path'],
        'predecessor_sha256': frozen_inputs['predecessor_sha256'],
        'after_staging_required_header_record': frozen_inputs['predecessor_record'],
        'staging_may_change_only_selected_header_package': True,
        'running_kernel_must_not_change': True,
        'boot_artifacts_must_not_change': True,
        'configured_boot_package_records_must_not_change': True,
    },
    'candidate_guard': {
        'binding_time': 'after-predecessor-staging-and-local-metadata-refresh-before-reference-apply',
        'binding_lifetime': 'same-runtime-transaction-only',
        'expected_upgrade_count': 1,
        'expected_upgrade_package': 'kernel-headers',
        'expected_upgrade_from': frozen_inputs['predecessor_record'],
        'expected_upgrade_to': frozen_inputs['target_record'],
        'expected_install_new_count': 0,
        'expected_non_header_upgrade_count': 0,
        'expected_configured_boot_upgrade_count': 0,
        'binding_evidence_must_include_refreshed_slackpkg_state': True,
        'must_be_consumed_without_pause': True,
    },
    'reference_apply': {
        'path': 'tools/reference/slack-update-reference.sh',
        'sha256': reference_sha,
        'mode': '--apply',
        'structured_output': '--json',
        'must_use_derived_runtime_config': True,
        'expected_exit_code': 0,
        'expected_kernel_trigger': 1,
        'expected_initrd_update': 0,
        'expected_grub_update': 0,
        'external_module_warning_required': True,
        'boot_preparation_action_forbidden': True,
        'expected_final_header_record': frozen_inputs['target_record'],
    },
    'rollback_and_cleanup': {
        'cleanup_trap_installed_before_first_mutation': True,
        'on_any_failure_restore_target_header_from_staged_target': True,
        'staged_target_path': frozen_inputs['staged_target_path'],
        'staged_target_sha256': frozen_inputs['target_sha256'],
        'restore_slackpkg_configuration_byte_for_byte': True,
        'restore_slackpkg_state_byte_for_byte': True,
        'restore_geninitrd_policy_to_original_fingerprint': True,
        'predecessor_may_not_be_left_installed_as_terminal_state': True,
        'preserve_runtime_evidence': True,
        'no_reboot': True,
    },
    'final_invariants': {
        'header_record': frozen_inputs['target_record'],
        'package_database_manifest_sha256': frozen_inputs['package_database_manifest_sha256'],
        'running_kernel': frozen_inputs['running_kernel'],
        'boot_id': frozen_inputs['boot_id'],
        'boot_package_records_unchanged': True,
        'boot_artifact_fingerprints_unchanged': True,
        'local_source_tree_unchanged': True,
        'staged_target_unchanged': True,
        'slackpkg_configuration_restored': True,
        'slackpkg_state_restored': True,
        'geninitrd_policy_restored': True,
        'no_reboot': True,
    },
    'evidence_contract': [
        'preflight-binding-and-capabilities',
        'pre-mutation-package-and-boot-fingerprints',
        'predecessor-transport-sha256',
        'post-staging-header-only-delta',
        'temporary-slackpkg-configuration-fingerprints',
        'local-metadata-refresh-result',
        'exact-candidate-binding',
        'reference-stdout-stderr-json-and-exit-status',
        'reference-kernel-trigger-initrd-grub-and-warning-observation',
        'rollback-or-success-restoration-actions',
        'post-transaction-package-boot-source-and-configuration-fingerprints',
        'cleanup-gate-and-published-archive-sha256',
    ],
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-executor-design-review',
    'review_only': True,
    'accepted_step_214': {
        'policy_sha256': p214_sha,
        'record_sha256': r214_sha,
        'helper_sha256': h214_sha,
        'same_transaction_candidate_contract_consumed': True,
    },
    'frozen_inputs': frozen_inputs,
    'runtime_transaction_executor_design': executor_design,
    'authorization': {
        'repository_only_runtime_transaction_executor_implementation_review_authorized': True,
        'runtime_executor_build_authorized': False,
        'runtime_executor_transport_authorized': False,
        'predecessor_package_transport_authorized': False,
        'predecessor_package_staging_authorized': False,
        'temporary_slackpkg_configuration_authorized': False,
        'local_source_metadata_refresh_authorized': False,
        'runtime_candidate_binding_authorized': False,
        'reference_apply_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'package_action_authorized': False,
        'network_access_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
    },
    'machine_action_required': False,
    'controller_action_required': False,
    'pause_safe': False,
    'strong_safe_pause': False,
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-design-review.sh',
    'helper_sha256': helper_sha,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review',
}

out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step', '215'),
    ('revision', 'runtime-transaction-executor-design-review'),
    ('accepted_step_214_policy_sha256', p214_sha),
    ('accepted_step_214_record_sha256', r214_sha),
    ('accepted_step_214_helper_sha256', h214_sha),
    ('reference_script_sha256', reference_sha),
    ('effective_config_sha256', frozen_inputs['effective_config_sha256']),
    ('fresh_boot_id', frozen_inputs['boot_id']),
    ('predecessor_record', frozen_inputs['predecessor_record']),
    ('predecessor_sha256', frozen_inputs['predecessor_sha256']),
    ('target_record', frozen_inputs['target_record']),
    ('target_sha256', frozen_inputs['target_sha256']),
    ('local_source_tree_manifest_sha256', frozen_inputs['local_source_tree_manifest_sha256']),
    ('executor_design_state', 'reviewed'),
    ('target_requires_repository', 'no'),
    ('runtime_acknowledgement', '--execute-runtime-validation'),
    ('secondary_modules_disabled_in_derived_config', 'yes'),
    ('boot_mode_preserved_auto', 'yes'),
    ('network_namespace_required', 'yes'),
    ('runtime_external_network_access_allowed', 'no'),
    ('slackpkg_configuration_restore_required', 'yes'),
    ('slackpkg_state_restore_required', 'yes'),
    ('candidate_binding_lifetime', 'same-runtime-transaction-only'),
    ('expected_upgrade_count', '1'),
    ('expected_upgrade_package', 'kernel-headers'),
    ('expected_install_new_count', '0'),
    ('expected_non_header_upgrade_count', '0'),
    ('expected_configured_boot_upgrade_count', '0'),
    ('reference_apply_expected_kernel_trigger', '1'),
    ('reference_apply_expected_initrd_update', '0'),
    ('reference_apply_expected_grub_update', '0'),
    ('failure_restores_target_header', 'yes'),
    ('predecessor_terminal_state_forbidden', 'yes'),
    ('repository_only_runtime_transaction_executor_implementation_review_authorized', 'yes'),
    ('runtime_executor_build_authorized', 'no'),
    ('runtime_executor_transport_authorized', 'no'),
    ('predecessor_package_transport_authorized', 'no'),
    ('predecessor_package_staging_authorized', 'no'),
    ('runtime_candidate_binding_authorized', 'no'),
    ('reference_apply_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('network_access_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('controller_action_required', 'no'),
    ('pause_safe', 'no'),
    ('strong_safe_pause', 'no'),
    ('next_stage', 'phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review'),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

printf 'executor_design_review_status\tPASS\n'
printf 'executor_design_state\treviewed\n'
printf 'candidate_binding_lifetime\tsame-runtime-transaction-only\n'
printf 'runtime_external_network_access_allowed\tno\n'
printf 'runtime_scenario_execution_authorized\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-executor-implementation-review\n'
