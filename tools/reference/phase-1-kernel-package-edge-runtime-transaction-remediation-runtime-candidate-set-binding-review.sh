#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review.sh [--output-dir DIR] [--help]

Review the Phase 1 step-234 remediated runtime candidate-set binding contract
against the accepted step-233-r1 fresh runtime identity and local-source-v2.
This is repository-only review and grants no machine, package, Slackpkg,
network, boot, reboot, executor-remediation, or runtime-rerun authority.
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
step233_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze.sh"
step233_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze.md"
step233_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze-harness.sh"
step233_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze-policy.json"
step233_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze.tsv"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}
check_hash() {
    local file=$1 expected=$2 actual
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: accepted prerequisite SHA-256 mismatch: %s\nexpected: %s\nactual:   %s\n' "$file" "$expected" "$actual" >&2
        exit 4
    }
}

for required in "$step233_helper" "$step233_doc" "$step233_harness" "$step233_policy" "$step233_record" "$helper_path"; do
    require_regular "$required"
done
check_hash "$step233_helper" 'e0b4937cd3a1144c374d39e00e374c6744f061beee2a76e2aa3e01a4cc53ecb6'
check_hash "$step233_doc" '1a4e5b51176172dfcf6a43cfbb6ba2e545a2d049aa084224a3c813f93787b917'
check_hash "$step233_harness" '9e5b4dfa71bbdce733d249600f5ba75c99c08152a2f3bcb09a176bd540b8c7e9'
check_hash "$step233_policy" '154b4bb46612da3f3827a04d7cc1d61968fdf153170f2cba8a8acfaecf5b13c2'
check_hash "$step233_record" 'b6c5351f987c5b36a61cd284c07c0a1aaafb51610ed7f44857311541f67ba4c1'

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review.tsv"
step233_helper_sha=$(sha256sum -- "$step233_helper" | awk '{print $1}')
step233_doc_sha=$(sha256sum -- "$step233_doc" | awk '{print $1}')
step233_harness_sha=$(sha256sum -- "$step233_harness" | awk '{print $1}')
step233_policy_sha=$(sha256sum -- "$step233_policy" | awk '{print $1}')
step233_record_sha=$(sha256sum -- "$step233_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step233_policy" "$step233_record" "$policy" "$record" \
    "$step233_helper_sha" "$step233_doc_sha" "$step233_harness_sha" \
    "$step233_policy_sha" "$step233_record_sha" "$helper_sha" <<'PYREVIEW'
import csv
import json
import sys
from pathlib import Path

p233_path, r233_path, out_policy, out_record = map(Path, sys.argv[1:5])
h233_sha, d233_sha, t233_sha, p233_sha, r233_sha, helper_sha = sys.argv[5:11]
p233 = json.loads(p233_path.read_text(encoding='utf-8'))
with r233_path.open(encoding='utf-8', newline='') as handle:
    r233 = dict(csv.reader(handle, delimiter='\t'))

assert p233['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze'
assert p233['freeze_status'] == 'PASS'
assert p233['fresh_runtime_identity']['state'] == 'frozen'
assert p233['fresh_runtime_identity']['fresh_candidate_set_bound'] is False
assert p233['preserved_local_source_v2_binding']['state'] == 'revalidated-and-frozen'
assert p233['candidate_binding_boundary']['candidate_source_uri'] == 'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2'
assert p233['candidate_binding_boundary']['future_refresh_workdir_strategy'] == 'transaction-owned-new-empty-workdir'
assert p233['candidate_binding_boundary']['future_candidate_guard_scope'] == 'target-specific-not-global-pkglist-row-count'
assert p233['candidate_binding_boundary']['future_refresh_rejects_error_downloading_from_local_source'] is True
assert p233['authorization']['repository_only_candidate_binding_review_authorized'] is True
assert p233['authorization']['runtime_candidate_binding_authorized'] is False
assert r233['step'] == '233'
assert r233['revision'] == 'post-local-source-v2-build-revalidation-freeze-r1'
assert r233['fresh_candidate_set_bound'] == 'no'

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review',
    'step': 234,
    'review_only': True,
    'review_status': 'PASS',
    'accepted_step_233_r1': {
        'helper_sha256': h233_sha,
        'document_sha256': d233_sha,
        'harness_sha256': t233_sha,
        'policy_sha256': p233_sha,
        'record_sha256': r233_sha,
        'fresh_runtime_identity_consumed_for_repository_review_only': True,
        'no_machine_authority_inherited': True,
    },
    'frozen_runtime_identity': {
        'state': 'repository-review-input-only',
        'hostname': 'vbox-slackcurrent.vbox-slackcurrent.org',
        'boot_id': 'fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9',
        'uname_release': '6.18.45',
        'header_package_record': 'kernel-headers-6.18.45-x86-1',
        'kernel_generic_record': 'kernel-generic-6.18.45-x86_64-1',
        'package_database_manifest_sha256': '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
        'slackpkg_conf_sha256': 'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
        'slackpkg_mirrors_sha256': '71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
        'must_be_revalidated_if_state_changes_before_future_machine_action': True,
    },
    'local_source_v2_binding': {
        'state': 'accepted-read-only-runtime-source',
        'root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2',
        'mirror_uri': 'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2',
        'tree_manifest': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256',
        'tree_manifest_sha256': 'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
        'manifest_sidecar_must_verify': True,
        'exact_manifest_coverage_must_verify': True,
        'priority_tree_contract_must_verify': True,
        'compatibility_asc_role': 'slackpkg-local-refresh-compatibility-only',
        'temporary_CHECKGPG': 'off',
        'target_relative_path': 'slackware64/d/kernel-headers-6.18.45-x86-1.txz',
        'target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
        'predecessor_archive_must_remain_absent': True,
        'local_source_v1_must_remain_unchanged': True,
        'local_source_v2_must_remain_unchanged': True,
    },
    'candidate_binding_contract': {
        'candidate_set_state_at_step_234': 'not-bound',
        'truthful_pre_staging_upgrade_candidate_count': 0,
        'truthful_pre_staging_reason': 'target-header-is-already-installed',
        'predecessor_record': 'kernel-headers-6.18.44-x86-1',
        'target_record': 'kernel-headers-6.18.45-x86-1',
        'target_candidate_fullname': 'kernel-headers-6.18.45-x86-1',
        'target_candidate_filename': 'kernel-headers-6.18.45-x86-1.txz',
        'target_candidate_location': './slackware64/d',
        'binding_time': 'after-exact-predecessor-staging-and-guarded-local-refresh-before-reference-apply',
        'binding_lifetime': 'same-runtime-transaction-only',
        'durable_pre_staging_binding_forbidden': True,
        'binding_must_be_consumed_without_pause': True,
        'transaction_owned_new_empty_slackpkg_workdir_required': True,
        'pre_refresh_pkglist_must_be_absent_in_transaction_workdir': True,
        'post_refresh_pkglist_must_be_created_in_transaction_workdir': True,
        'preexisting_var_lib_slackpkg_pkglist_may_not_prove_refresh': True,
        'source_tree_manifest_must_verify_immediately_before_refresh': True,
        'source_transport': 'file-uri-only',
        'external_network_access_forbidden': True,
        'refresh_exit_status_must_be_zero': True,
        'refresh_output_must_not_contain_error_downloading_from_local_source': True,
        'global_pkglist_row_count_is_not_an_acceptance_guard': True,
        'candidate_guard_scope': 'target-specific',
        'expected_target_candidate_row_count': 1,
        'expected_upgrade_package': 'kernel-headers',
        'expected_upgrade_from': 'kernel-headers-6.18.44-x86-1',
        'expected_upgrade_to': 'kernel-headers-6.18.45-x86-1',
        'expected_install_new_candidate_count': 0,
        'expected_non_header_upgrade_candidate_count': 0,
        'expected_configured_boot_package_upgrade_candidate_count': 0,
        'target_source_binding_to_frozen_sha256_and_v2_manifest_required': True,
        'evidence_encoding': 'real-tab-tsv',
        'invalidated_by_boot_id_change': True,
        'invalidated_by_package_state_change': True,
        'invalidated_by_slackpkg_configuration_change': True,
        'invalidated_by_local_source_v2_change': True,
        'invalidated_by_transaction_workdir_replacement': True,
        'invalidated_by_refresh_reexecution': True,
    },
    'future_transaction_order': [
        'revalidate-frozen-runtime-and-v2-source-inputs',
        'verify-frozen-predecessor-bytes',
        'stage-only-kernel-headers-6.18.44-x86-1',
        'prove-header-only-package-delta-and-unchanged-boot-state',
        'create-new-empty-transaction-owned-slackpkg-workdir',
        'activate-bounded-local-only-slackpkg-configuration',
        'verify-v2-tree-immediately-before-refresh',
        'refresh-metadata-from-file-uri-under-network-isolation',
        'reject-nonzero-refresh-or-local-source-download-error',
        'prove-fresh-workdir-pkglist-and-bind-exact-target-candidate',
        'consume-binding-immediately-with-reference-apply-or-rollback',
        'restore-slackpkg-state-and-target-header-baseline',
        'publish-success-only-after-final-invariants-pass',
    ],
    'preservation_contract': {
        'failed_runtime_evidence_root_must_remain_preserved': True,
        'failed_success_result_must_remain_absent': True,
        'published_success_evidence_must_remain_absent_until_successful_rerun': True,
        'local_source_v1_must_remain_preserved': True,
        'local_source_v2_must_remain_preserved': True,
        'staged_target_must_remain_preserved': True,
    },
    'executor_remediation_boundary': {
        'executor_remediation_required': True,
        'executor_remediation_not_authorized_by_step_234': True,
        'runtime_rerun_not_authorized_by_step_234': True,
        'candidate_binding_contract_must_be_frozen_before_executor_remediation_design': True,
    },
    'authorization': {
        'repository_only_candidate_binding_freeze_authorized': True,
        'target_observation_authorized': False,
        'runtime_candidate_binding_authorized': False,
        'runtime_executor_remediation_authorized': False,
        'runtime_executor_transport_authorized': False,
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
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review.sh',
    'helper_sha256': helper_sha,
    'machine_action_required': False,
    'controller_action_required': False,
    'future_work_requires_explicit_authorization': True,
    'pause_safe': False,
    'strong_safe_pause': False,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze',
}

out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step','234'),
    ('revision','runtime-candidate-set-binding-review'),
    ('review_status','PASS'),
    ('accepted_step_233_r1','yes'),
    ('fresh_boot_id','fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9'),
    ('candidate_set_bound','no'),
    ('truthful_pre_staging_upgrade_candidate_count','0'),
    ('candidate_source_uri','file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2'),
    ('local_source_v2_tree_manifest_sha256','e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'),
    ('target_candidate_fullname','kernel-headers-6.18.45-x86-1'),
    ('target_candidate_location','./slackware64/d'),
    ('predecessor_record','kernel-headers-6.18.44-x86-1'),
    ('binding_lifetime','same-runtime-transaction-only'),
    ('workdir_strategy','transaction-owned-new-empty-workdir'),
    ('candidate_guard_scope','target-specific'),
    ('global_pkglist_row_count_guard','retired'),
    ('refresh_exit_status_zero_required','yes'),
    ('refresh_local_source_download_error_forbidden','yes'),
    ('expected_target_candidate_row_count','1'),
    ('expected_install_new_candidate_count','0'),
    ('expected_non_header_upgrade_candidate_count','0'),
    ('expected_configured_boot_package_upgrade_candidate_count','0'),
    ('evidence_encoding','real-tab-tsv'),
    ('repository_only_candidate_binding_freeze_authorized','yes'),
    ('runtime_candidate_binding_authorized','no'),
    ('runtime_executor_remediation_authorized','no'),
    ('runtime_rerun_authorized','no'),
    ('package_action_authorized','no'),
    ('slackpkg_mutation_authorized','no'),
    ('repository_refresh_authorized','no'),
    ('network_access_authorized','no'),
    ('boot_action_authorized','no'),
    ('reboot_authorized','no'),
    ('evidence_cleanup_authorized','no'),
    ('machine_action_required','no'),
    ('controller_action_required','no'),
    ('pause_safe','no'),
    ('strong_safe_pause','no'),
    ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze'),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)

for key, value in rows:
    print(f'{key}\t{value}')
PYREVIEW
