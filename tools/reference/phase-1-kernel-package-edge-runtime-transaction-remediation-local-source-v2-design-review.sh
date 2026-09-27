#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-review'
prev='phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze'
prev_helper="$repo_root/tools/reference/${prev}.sh"
prev_doc="$repo_root/docs/reference/${prev}.md"
prev_harness="$repo_root/tests/reference/test-${prev}-harness.sh"
prev_policy="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}-policy.json"
prev_record="$repo_root/tests/fixtures/reference/acceptance/phase-1/${prev}.tsv"

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-review.sh --output-dir DIR

Generate the repository-only step-224 local-source-v2 design-review policy and TSV record.
This helper performs no target-machine, package, Slackpkg, network, boot, or reboot action.
USAGE
}

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
sha() { sha256sum -- "$1" | awk '{print $1}'; }
regular() { [[ -f $1 && ! -L $1 ]]; }
require_hash() {
    local path=$1 expected=$2 label=$3 actual
    regular "$path" || fail "$label is missing or unsafe: $path"
    actual=$(sha "$path")
    [[ $actual == "$expected" ]] || fail "$label SHA-256 mismatch: $actual"
}

[[ ${1:-} == '--help' ]] && { usage; exit 0; }
[[ $# -eq 2 && $1 == '--output-dir' ]] || { usage >&2; exit 2; }
out_dir=$2
[[ -d $out_dir && ! -L $out_dir ]] || fail 'output directory must already exist and must not be a symlink'

require_hash "$prev_helper" '31dd91d1319fcd8c0a56a8580ae0665f2844dc02a5a3da39c80fb438681f20ae' 'accepted step-223 helper'
require_hash "$prev_doc" '4b75ab3018df982f4115d397824d65fffb33fd5cd38f08800de8d6158885a63c' 'accepted step-223 document'
require_hash "$prev_harness" '3b8c7760cdd82f3f8995e1190f8e69c80959aefc32ab1162f542d16c7c8ae388' 'accepted step-223 harness'
require_hash "$prev_policy" '7f8d68bce758482b9e96b42e9465d5574d37a0d6c0527508dfe66d44d18a75a3' 'accepted step-223 policy'
require_hash "$prev_record" '6394ab2be2e303d2e26851065034fc199840a4d701ba87d6b21eb891adc8fac5' 'accepted step-223 record'

helper_sha=$(sha "${BASH_SOURCE[0]}")
python3 - "$prev_policy" "$prev_record" "$out_dir/${base}-policy.json" "$out_dir/${base}.tsv" "$helper_sha" <<'PYGEN'
import json, pathlib, sys
prev_policy_path, prev_record_path, out_policy_path, out_record_path, helper_sha = sys.argv[1:]
p223 = json.load(open(prev_policy_path, encoding='utf-8'))
record = {}
for line in pathlib.Path(prev_record_path).read_text(encoding='utf-8').splitlines():
    if not line:
        continue
    k, v = line.split('\t', 1)
    record[k] = v
assert p223['step'] == 223
assert p223['review_status'] == 'PASS'
assert p223['fresh_runtime_identity']['boot_id'] == 'cd975bdc-a133-47d1-9e92-e9b51bef9d99'
assert p223['authorization']['repository_only_local_source_v2_design_review_authorized'] is True
assert p223['authorization']['local_source_v2_builder_implementation_authorized'] is False
assert p223['authorization']['local_source_v2_build_authorized'] is False
assert record['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-review'

priority_trees = ['patches', 'slackware64', 'extra', 'pasture', 'testing']
policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-review',
    'step': 224,
    'review_only': True,
    'review_status': 'PASS',
    'accepted_step_223': {
        'helper_sha256': '31dd91d1319fcd8c0a56a8580ae0665f2844dc02a5a3da39c80fb438681f20ae',
        'document_sha256': '4b75ab3018df982f4115d397824d65fffb33fd5cd38f08800de8d6158885a63c',
        'harness_sha256': '3b8c7760cdd82f3f8995e1190f8e69c80959aefc32ab1162f542d16c7c8ae388',
        'policy_sha256': '7f8d68bce758482b9e96b42e9465d5574d37a0d6c0527508dfe66d44d18a75a3',
        'record_sha256': '6394ab2be2e303d2e26851065034fc199840a4d701ba87d6b21eb891adc8fac5',
    },
    'frozen_runtime_identity': {
        'state': 'consumed-for-repository-only-v2-design',
        'boot_id': p223['fresh_runtime_identity']['boot_id'],
        'package_database_manifest_sha256': p223['fresh_runtime_identity']['package_database_manifest_sha256'],
        'header_package_record': p223['fresh_runtime_identity']['header_package_record'],
        'kernel_generic_record': p223['fresh_runtime_identity']['kernel_generic_record'],
        'slackpkg_conf_sha256': p223['fresh_runtime_identity']['slackpkg_conf_sha256'],
        'slackpkg_mirrors_sha256': p223['fresh_runtime_identity']['slackpkg_mirrors_sha256'],
        'must_be_revalidated_before_any_future_machine_action': True,
        'no_machine_authority_inherited': True,
    },
    'preservation_contract': p223['preservation_contract'],
    'local_source_v2_design': {
        'state': 'design-reviewed-not-implemented',
        'generation_name': 'local-source-v2',
        'root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2',
        'mirror_uri': 'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2/',
        'tree_manifest': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256',
        'tree_manifest_sha256_sidecar': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256.sha256',
        'target_input': '/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz',
        'target_filename': 'kernel-headers-6.18.45-x86-1.txz',
        'target_sha256': p223['preservation_contract']['staged_target_sha256'],
        'target_relative_path': 'slackware64/d/kernel-headers-6.18.45-x86-1.txz',
        'package_location': './slackware64/d',
        'predecessor_record': 'kernel-headers-6.18.44-x86-1',
        'predecessor_archive_must_be_absent_from_v2': True,
        'must_be_separate_from_local_source_v1': True,
        'v1_must_not_be_modified_or_rebuilt': True,
        'failed_runtime_evidence_must_not_be_modified': True,
        'build_fail_closed_if_any_v2_final_output_exists': True,
        'build_uses_temporary_sibling_then_atomic_final_publication': True,
        'generated_tree_owner': 'root:root',
        'generated_directory_mode': '0555',
        'generated_file_mode': '0444',
        'generated_mtime_epoch': 0,
        'exact_package_archive_count': 1,
        'top_level_metadata': ['ChangeLog.txt', 'FILELIST.TXT', 'PACKAGES.TXT', 'CHECKSUMS.md5', 'CHECKSUMS.md5.asc'],
        'CHECKSUMS_md5_asc': {
            'required': True,
            'role': 'slackpkg-local-refresh-compatibility-only',
            'cryptographic_authenticity_claim': False,
            'package_authenticity_remains_bound_by_target_sha256_and_tree_manifest': True,
            'future_refresh_requires_CHECKGPG_off': True,
            'content_must_be_deterministic_and_bounded': True,
        },
        'priority_tree_contract': {
            'required': True,
            'effective_x86_64_priority_trees': priority_trees,
            'PACKAGES_TXT_required_for_every_priority_tree': True,
            'target_stanza_tree': 'slackware64',
            'target_stanza_count_in_slackware64_PACKAGES_TXT': 1,
            'non_target_priority_PACKAGES_TXT_must_contain_zero_package_stanzas': True,
            'global_pkglist_row_count_is_not_an_acceptance_guard': True,
        },
        'metadata_binding': {
            'FILELIST_TXT_must_enumerate_complete_generated_tree': True,
            'CHECKSUMS_md5_must_bind_generated_regular_files_except_itself_and_compatibility_asc': True,
            'top_level_PACKAGES_TXT_must_contain_exactly_target_stanza': True,
            'slackware64_PACKAGES_TXT_must_contain_exactly_target_stanza': True,
            'tree_manifest_must_bind_every_generated_regular_file': True,
            'tree_manifest_sidecar_must_bind_tree_manifest': True,
        },
    },
    'future_refresh_acceptance_contract': {
        'not_authorized_by_step_224': True,
        'network_namespace': 'unshare-network-disabled',
        'source_transport': 'file-uri-only',
        'temporary_slackpkg_config_required': True,
        'temporary_CHECKGPG': 'off',
        'workdir_strategy': 'transaction-owned-new-empty-workdir',
        'pre_refresh_pkglist_must_be_absent': True,
        'post_refresh_pkglist_must_be_created_in_transaction_workdir': True,
        'workdir_must_not_reuse_var_lib_slackpkg_pkglist': True,
        'refresh_exit_status_must_be_zero': True,
        'stdout_stderr_must_not_contain_error_downloading_from_local_source': True,
        'source_tree_manifest_must_verify_immediately_before_refresh': True,
        'candidate_guard_scope': 'target-specific-not-global-pkglist-row-count',
        'target_candidate_row_count': 1,
        'target_candidate_fullname': 'kernel-headers-6.18.45-x86-1',
        'target_candidate_priority_tree': 'slackware64',
        'target_candidate_location': './slackware64/d',
        'predecessor_installed_required_at_binding_time': True,
        'predecessor_record': 'kernel-headers-6.18.44-x86-1',
        'target_source_binding_to_frozen_sha256_and_v2_tree_manifest_required': True,
        'install_new_candidate_count': 0,
        'non_header_upgrade_candidate_count': 0,
        'configured_boot_package_upgrade_candidate_count': 0,
        'candidate_binding_and_consumption_same_transaction_required': True,
        'evidence_encoding': 'real-tab-tsv',
    },
    'implementation_boundary': {
        'next_artifact': 'repository-only-v2-design-freeze',
        'builder_implementation_may_not_begin_until_design_freeze': True,
        'builder_execution_may_not_begin_until_later_explicit_authorization': True,
        'runtime_executor_remediation_may_not_begin_until_v2_build_is_frozen': True,
    },
    'authorization': {
        'repository_only_local_source_v2_design_review_authorized': False,
        'repository_only_local_source_v2_design_freeze_authorized': True,
        'local_source_v2_builder_implementation_authorized': False,
        'local_source_v2_build_authorized': False,
        'target_observation_authorized': False,
        'probe_transport_copy_authorized': False,
        'runtime_candidate_binding_authorized': False,
        'runtime_executor_remediation_authorized': False,
        'runtime_rerun_authorized': False,
        'package_action_authorized': False,
        'slackpkg_mutation_authorized': False,
        'repository_refresh_authorized': False,
        'network_access_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'persistent_configuration_change_authorized': False,
        'evidence_cleanup_authorized': False,
        'phase_2_start_authorized': False,
        'future_work_requires_explicit_authorization': True,
    },
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-review.sh',
    'helper_sha256': helper_sha,
    'machine_action_required': False,
    'controller_action_required': False,
    'pause_safe': False,
    'strong_safe_pause': False,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-freeze',
}
pathlib.Path(out_policy_path).write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')

def yn(v): return 'yes' if v else 'no'
rows = [
    ('step','224'), ('review_status','PASS'),
    ('accepted_step_223_policy_sha256', policy['accepted_step_223']['policy_sha256']),
    ('frozen_boot_id', policy['frozen_runtime_identity']['boot_id']),
    ('frozen_package_database_manifest_sha256', policy['frozen_runtime_identity']['package_database_manifest_sha256']),
    ('local_source_v1_must_be_preserved_unchanged', yn(policy['preservation_contract']['local_source_v1_must_be_preserved_unchanged'])),
    ('failed_runtime_evidence_root_must_be_preserved_unchanged', yn(policy['preservation_contract']['failed_runtime_evidence_root_must_be_preserved_unchanged'])),
    ('local_source_v2_design_state', policy['local_source_v2_design']['state']),
    ('local_source_v2_root', policy['local_source_v2_design']['root']),
    ('local_source_v2_mirror_uri', policy['local_source_v2_design']['mirror_uri']),
    ('local_source_v2_tree_manifest', policy['local_source_v2_design']['tree_manifest']),
    ('target_filename', policy['local_source_v2_design']['target_filename']),
    ('target_sha256', policy['local_source_v2_design']['target_sha256']),
    ('target_relative_path', policy['local_source_v2_design']['target_relative_path']),
    ('CHECKSUMS_md5_asc_required', 'yes'),
    ('CHECKSUMS_md5_asc_role', policy['local_source_v2_design']['CHECKSUMS_md5_asc']['role']),
    ('CHECKSUMS_md5_asc_authenticity_claim', 'no'),
    ('priority_trees', ','.join(priority_trees)),
    ('priority_PACKAGES_TXT_required', 'yes'),
    ('target_priority_tree', 'slackware64'),
    ('global_pkglist_row_count_guard_retired', 'yes'),
    ('refresh_workdir_strategy', policy['future_refresh_acceptance_contract']['workdir_strategy']),
    ('pre_refresh_pkglist_must_be_absent', 'yes'),
    ('refresh_exit_status_must_be_zero', 'yes'),
    ('refresh_error_downloading_signal_must_be_absent', 'yes'),
    ('candidate_guard_scope', policy['future_refresh_acceptance_contract']['candidate_guard_scope']),
    ('target_candidate_row_count', '1'),
    ('predecessor_installed_required_at_binding_time', 'yes'),
    ('predecessor_record', policy['future_refresh_acceptance_contract']['predecessor_record']),
    ('target_source_binding_required', 'yes'),
    ('candidate_binding_and_consumption_same_transaction_required', 'yes'),
    ('evidence_encoding', 'real-tab-tsv'),
    ('repository_only_local_source_v2_design_freeze_authorized', 'yes'),
    ('local_source_v2_builder_implementation_authorized', 'no'),
    ('local_source_v2_build_authorized', 'no'),
    ('runtime_executor_remediation_authorized', 'no'),
    ('runtime_rerun_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('slackpkg_mutation_authorized', 'no'),
    ('repository_refresh_authorized', 'no'),
    ('network_access_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('evidence_cleanup_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('controller_action_required', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', policy['next_stage']),
]
pathlib.Path(out_record_path).write_text(''.join(f'{k}\t{v}\n' for k,v in rows), encoding='utf-8')
PYGEN
