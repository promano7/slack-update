#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze.sh [--output-dir DIR] [--help]

Consume the successful single-use Phase 1 step-232 post-local-source-v2-build
read-only observation and freeze the fresh target/local-source-v2 identity for
the subsequent repository-only candidate-set binding review. This helper does
not grant machine, package, Slackpkg, network, boot, reboot, or runtime-rerun
authority.
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
step232_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review-policy.json"
step232_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review.tsv"
step232_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review-probe.sh"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze.sh"

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
for required in "$step232_policy" "$step232_record" "$step232_probe" "$helper_path"; do
    require_regular "$required"
done
check_hash "$step232_policy" 'ef430d92d9163247c2ae9a7c6fd681eb5c032a8a4746702cd03d0645aa40e4e6'
check_hash "$step232_record" '7cd3736efb81ea4480e3f28a9c2c06e98690ad53762bfab39a4a5db614b4a0cc'
check_hash "$step232_probe" '227d00873ad0832a969ef04732f9336e5d5de879c46c43102dccb7f4d7339b69'

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze.tsv"
step232_policy_sha=$(sha256sum -- "$step232_policy" | awk '{print $1}')
step232_record_sha=$(sha256sum -- "$step232_record" | awk '{print $1}')
probe_sha=$(sha256sum -- "$step232_probe" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step232_policy" "$step232_record" "$policy" "$record" \
    "$step232_policy_sha" "$step232_record_sha" "$probe_sha" "$helper_sha" <<'PYFREEZE'
import csv
import json
import sys
from pathlib import Path

p232_path, r232_path, out_policy, out_record = map(Path, sys.argv[1:5])
p232_sha, r232_sha, probe_sha, helper_sha = sys.argv[5:9]
p232 = json.loads(p232_path.read_text(encoding='utf-8'))
with r232_path.open(encoding='utf-8', newline='') as handle:
    r232 = dict(csv.reader(handle, delimiter='\t'))

assert p232['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review'
assert p232['review_status'] == 'PASS'
assert p232['probe']['sha256'] == probe_sha
assert p232['authorization']['probe_execution_authorized'] is True
assert p232['authorization']['probe_execution_use_count'] == 1
assert p232['authorization']['target_observation_authorized'] is True
assert p232['authorization']['runtime_candidate_binding_authorized'] is False
assert p232['runtime_boundary']['fresh_candidate_set_bound_by_this_step'] is False
assert r232['step'] == '232'
assert r232['candidate_set_bound'] == 'no'
assert r232['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze'

accepted = {
    'status': 'PASS',
    'prior_runtime_binding_reused': False,
    'fresh_boot_id': 'fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9',
    'hostname_fqdn': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'uname_machine': 'x86_64',
    'uname_release': '6.18.45',
    'slackware_version': 'Slackware 15.0+',
    'package_database_manifest_sha256': '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
    'header_package_record': 'kernel-headers-6.18.45-x86-1',
    'kernel_generic_record': 'kernel-generic-6.18.45-x86_64-1',
    'kernel_huge_absent': True,
    'kernel_modules_absent': True,
    'slackpkg_conf_sha256': 'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
    'slackpkg_mirrors_sha256': '71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
    'staged_target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'local_source_v1_tree_verified': True,
    'local_source_v1_tree_manifest_sha256': '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e',
    'local_source_v2_tree_verified': True,
    'local_source_v2_tree_manifest_sha256': 'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
    'local_source_v2_tree_manifest_sidecar_verified': True,
    'local_source_v2_manifest_coverage_verified': True,
    'local_source_v2_priority_tree_contract_verified': True,
    'local_source_v2_compatibility_asc_verified': True,
    'local_source_v2_temporary_build_roots_absent': True,
    'failed_evidence_root_present': True,
    'failed_success_result_absent': True,
    'published_success_evidence_absent': True,
    'boot_artifacts_match_failed_preflight': True,
    'slackpkg_state_matches_failed_preflight': True,
    'geninitrd_policy_matches_failed_preflight': True,
    'probe_sha256': probe_sha,
    'candidate_set_bound': False,
    'runtime_executor_remediation_performed': False,
    'runtime_rerun_performed': False,
    'repository_refresh_performed': False,
    'network_access_performed': False,
    'package_action_performed': False,
    'slackpkg_mutation_performed': False,
    'boot_action_performed': False,
    'reboot_performed': False,
    'evidence_cleanup_performed': False,
    'persistent_configuration_change_performed': False,
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze',
    'review_only': True,
    'freeze_status': 'PASS',
    'accepted_step_232': {
        'policy_sha256': p232_sha,
        'record_sha256': r232_sha,
        'probe_sha256': probe_sha,
        'single_use_probe_result_consumed': True,
        'probe_authority_revoked': True,
    },
    'accepted_revalidation_evidence': accepted,
    'fresh_runtime_identity': {
        'state': 'frozen',
        'binding_origin': 'step-232-post-local-source-v2-build-read-only-revalidation',
        'historical_boot_id_reused': False,
        'boot_id': accepted['fresh_boot_id'],
        'package_database_manifest_sha256': accepted['package_database_manifest_sha256'],
        'header_package_record': accepted['header_package_record'],
        'kernel_generic_record': accepted['kernel_generic_record'],
        'slackpkg_conf_sha256': accepted['slackpkg_conf_sha256'],
        'slackpkg_mirrors_sha256': accepted['slackpkg_mirrors_sha256'],
        'valid_until_machine_package_slackpkg_boot_or_local_source_state_changes': True,
        'fresh_candidate_set_bound': False,
    },
    'preserved_local_source_v2_binding': {
        'state': 'revalidated-and-frozen',
        'root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2',
        'tree_manifest': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256',
        'tree_manifest_sha256': accepted['local_source_v2_tree_manifest_sha256'],
        'tree_manifest_sidecar_verified': True,
        'manifest_exact_coverage_verified': True,
        'priority_tree_contract_verified': True,
        'compatibility_asc_verified': True,
        'target_relative_path': 'slackware64/d/kernel-headers-6.18.45-x86-1.txz',
        'target_sha256': accepted['staged_target_sha256'],
        'predecessor_archive_absent': True,
        'rebuild_authorized': False,
    },
    'preserved_context': {
        'local_source_v1_state': 'preserved-and-revalidated',
        'local_source_v1_tree_manifest_sha256': accepted['local_source_v1_tree_manifest_sha256'],
        'failed_runtime_evidence_state': 'preserved-unchanged',
        'failed_evidence_root_present': True,
        'failed_success_result_absent': True,
        'published_success_evidence_absent': True,
        'boot_artifacts_match_failed_preflight': True,
        'slackpkg_state_matches_failed_preflight': True,
        'geninitrd_policy_matches_failed_preflight': True,
    },
    'candidate_binding_boundary': {
        'candidate_set_state': 'not-yet-bound',
        'fresh_same_transaction_candidate_binding_required': True,
        'candidate_source_uri': 'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2',
        'predecessor_record': 'kernel-headers-6.18.44-x86-1',
        'target_record': 'kernel-headers-6.18.45-x86-1',
        'target_candidate': 'kernel-headers-6.18.45-x86-1.txz',
        'target_candidate_sha256': accepted['staged_target_sha256'],
        'future_refresh_workdir_strategy': 'transaction-owned-new-empty-workdir',
        'future_candidate_guard_scope': 'target-specific-not-global-pkglist-row-count',
        'future_refresh_rejects_error_downloading_from_local_source': True,
        'future_evidence_encoding': 'real-tab-tsv',
        'candidate_binding_must_be_consumed_without_pause': True,
        'repository_only_candidate_binding_review_authorized': True,
    },
    'executor_remediation_boundary': {
        'runtime_executor_remediation_review_required_before_rerun': True,
        'runtime_executor_remediation_not_yet_authorized': True,
        'runtime_rerun_not_yet_authorized': True,
    },
    'authorization': {
        'target_observation_authorized': False,
        'probe_transport_copy_authorized': False,
        'probe_execution_authorized': False,
        'repository_only_candidate_binding_review_authorized': True,
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
    'future_work_requires_explicit_authorization': True,
    'machine_action_required': False,
    'controller_action_required': False,
    'pause_safe': False,
    'strong_safe_pause': False,
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze.sh',
    'helper_sha256': helper_sha,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review',
}

out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step','233'),
    ('revision','post-local-source-v2-build-revalidation-freeze-r1'),
    ('freeze_status','PASS'),
    ('accepted_step_232_policy_sha256',p232_sha),
    ('accepted_step_232_record_sha256',r232_sha),
    ('probe_sha256',probe_sha),
    ('step_232_probe_result_consumed','yes'),
    ('step_232_probe_authority_revoked','yes'),
    ('fresh_boot_id',accepted['fresh_boot_id']),
    ('hostname_fqdn',accepted['hostname_fqdn']),
    ('uname_release',accepted['uname_release']),
    ('uname_machine',accepted['uname_machine']),
    ('package_database_manifest_sha256',accepted['package_database_manifest_sha256']),
    ('header_package_record',accepted['header_package_record']),
    ('kernel_generic_record',accepted['kernel_generic_record']),
    ('slackpkg_conf_sha256',accepted['slackpkg_conf_sha256']),
    ('slackpkg_mirrors_sha256',accepted['slackpkg_mirrors_sha256']),
    ('staged_target_sha256',accepted['staged_target_sha256']),
    ('local_source_v1_tree_manifest_sha256',accepted['local_source_v1_tree_manifest_sha256']),
    ('local_source_v2_tree_manifest_sha256',accepted['local_source_v2_tree_manifest_sha256']),
    ('local_source_v2_tree_verified','yes'),
    ('local_source_v2_manifest_coverage_verified','yes'),
    ('local_source_v2_priority_tree_contract_verified','yes'),
    ('local_source_v2_compatibility_asc_verified','yes'),
    ('failed_runtime_evidence_preserved','yes'),
    ('fresh_runtime_identity','frozen'),
    ('fresh_candidate_set_bound','no'),
    ('candidate_source_uri','file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2'),
    ('fresh_same_transaction_candidate_binding_required','yes'),
    ('future_refresh_workdir_strategy','transaction-owned-new-empty-workdir'),
    ('future_candidate_guard_scope','target-specific-not-global-pkglist-row-count'),
    ('runtime_executor_remediation_review_required_before_rerun','yes'),
    ('repository_only_candidate_binding_review_authorized','yes'),
    ('target_observation_authorized','no'),
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
    ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review'),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    w=csv.writer(handle, delimiter='\t', lineterminator='\n')
    w.writerows(rows)

print('post_v2_build_revalidation_freeze_status\tPASS')
print('fresh_runtime_identity\tfrozen')
print('fresh_boot_id\t'+accepted['fresh_boot_id'])
print('local_source_v2_tree_manifest_sha256\t'+accepted['local_source_v2_tree_manifest_sha256'])
print('fresh_candidate_set_bound\tno')
print('repository_only_candidate_binding_review_authorized\tyes')
print('machine_action_required\tno')
print('next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-review')
PYFREEZE
