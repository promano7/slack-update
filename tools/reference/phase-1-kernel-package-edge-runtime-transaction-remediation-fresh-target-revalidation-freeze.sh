#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze.sh [--output-dir DIR] [--help]

Freeze the accepted Phase 1 step-222 read-only remediation target observation.
This helper is repository-only. It grants no package, Slackpkg, network, boot,
reboot, runtime-rerun, or local-source-v2 build authority.
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
step222_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review-policy.json"
step222_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review.tsv"
step222_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review-probe.sh"
step220_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause-policy.json"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze.sh"

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

for required in "$step222_policy" "$step222_record" "$step222_probe" "$step220_policy" "$helper_path"; do
    require_regular "$required"
done
check_hash "$step222_policy" '13d81956392eaab84c73af1700d6382712fcb7b93e28fcfa8cf59be8b03ecd85'
check_hash "$step222_record" 'e537a55ede741f2689e85bb4207f6bae5390f8ce6e6a675524c764d8f9830891'
check_hash "$step222_probe" 'e4b90b4379405e08fd05234c24736fc3ac498ddc5d37c57f9a573c15b8cc0c4a'
check_hash "$step220_policy" 'f52b276f8c93d4e939b7093be95236ba719039dbb5d8d2fae850f3ac810a49a4'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze.tsv"
step222_policy_sha=$(sha256sum -- "$step222_policy" | awk '{print $1}')
step222_record_sha=$(sha256sum -- "$step222_record" | awk '{print $1}')
probe_sha=$(sha256sum -- "$step222_probe" | awk '{print $1}')
step220_policy_sha=$(sha256sum -- "$step220_policy" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step222_policy" "$step222_record" "$step220_policy" "$policy" "$record" \
    "$step222_policy_sha" "$step222_record_sha" "$probe_sha" "$step220_policy_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p222_path, r222_path, p220_path, out_policy, out_record = map(Path, sys.argv[1:6])
p222_sha, r222_sha, probe_sha, p220_sha, helper_sha = sys.argv[6:11]
p222 = json.loads(p222_path.read_text(encoding='utf-8'))
p220 = json.loads(p220_path.read_text(encoding='utf-8'))
with r222_path.open(encoding='utf-8', newline='') as handle:
    r222 = dict(csv.reader(handle, delimiter='\t'))

assert p222['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review'
assert p222['step'] == 222
assert p222['fresh_target_revalidation']['probe_sha256'] == probe_sha
assert p222['authorization']['target_observation_authorized'] is True
assert p222['authorization']['fresh_target_revalidation_freeze_authorized_after_successful_observation'] is True
assert p222['authorization']['runtime_rerun_authorized'] is False
assert p222['authorization']['package_action_authorized'] is False
assert r222['step'] == '222'
assert r222['fresh_target_revalidation_freeze_authorized_after_successful_observation'] == 'yes'
assert p220['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause'
assert p220['remediation_contract']['new_local_source_generation_name'] == 'local-source-v2'
assert p220['preservation_contract']['local_source_v1_must_be_preserved_unchanged'] is True

accepted = {
    'revalidation_status': 'PASS',
    'prior_target_binding_reused': False,
    'fresh_boot_id': 'cd975bdc-a133-47d1-9e92-e9b51bef9d99',
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
    'local_source_v1_CHECKSUMS_md5_asc_absent': True,
    'failed_evidence_root_present': True,
    'failed_success_result_absent': True,
    'published_success_evidence_absent': True,
    'boot_artifacts_match_failed_preflight': True,
    'slackpkg_state_matches_failed_preflight': True,
    'geninitrd_policy_matches_failed_preflight': True,
    'repository_refresh_performed': False,
    'network_access_performed': False,
    'package_action_performed': False,
    'slackpkg_mutation_performed': False,
    'boot_action_performed': False,
    'reboot_performed': False,
    'persistent_configuration_change_performed': False,
    'candidate_set_bound': False,
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze',
    'step': 223,
    'review_only': True,
    'review_status': 'PASS',
    'accepted_step_222': {
        'policy_sha256': p222_sha,
        'record_sha256': r222_sha,
        'probe_sha256': probe_sha,
        'returned_probe_result_consumed': True,
        'single_use_observation_authority_consumed': True,
    },
    'remediation_origin': {
        'strong_safe_pause_step': 220,
        'policy_sha256': p220_sha,
        'preservation_contract': p220['preservation_contract'],
        'remediation_contract': p220['remediation_contract'],
    },
    'accepted_fresh_target_evidence': accepted,
    'fresh_runtime_identity': {
        'state': 'frozen-for-remediation-design',
        'binding_origin': 'step-222-read-only-remediation-target-revalidation',
        'boot_id': accepted['fresh_boot_id'],
        'package_database_manifest_sha256': accepted['package_database_manifest_sha256'],
        'header_package_record': accepted['header_package_record'],
        'kernel_generic_record': accepted['kernel_generic_record'],
        'slackpkg_conf_sha256': accepted['slackpkg_conf_sha256'],
        'slackpkg_mirrors_sha256': accepted['slackpkg_mirrors_sha256'],
        'historical_step_213_boot_binding_reused': False,
        'historical_step_217_runtime_authorization_reused': False,
        'valid_until_target_machine_or_package_state_changes': True,
        'target_reboot_invalidates_binding': True,
        'package_state_change_invalidates_binding': True,
        'slackpkg_state_change_invalidates_binding': True,
        'fresh_candidate_set_bound': False,
    },
    'preservation_contract': {
        **p220['preservation_contract'],
        'local_source_v1_tree_manifest_sha256': accepted['local_source_v1_tree_manifest_sha256'],
        'staged_target_sha256': accepted['staged_target_sha256'],
        'failed_evidence_root_present_at_freeze': True,
        'failed_success_result_absent_at_freeze': True,
        'published_success_evidence_absent_at_freeze': True,
    },
    'local_source_v2_design_boundary': {
        'state': 'repository-only-design-review-authorized',
        'generation_name': 'local-source-v2',
        'must_be_separate_from_local_source_v1': True,
        'must_consume_frozen_step_223_runtime_identity': True,
        'slackpkg_refresh_compatibility_metadata_required': True,
        'CHECKSUMS_md5_asc_compatibility_artifact_required': True,
        'priority_tree_metadata_required': True,
        'refresh_success_requires_exit_zero': True,
        'refresh_success_requires_no_error_downloading_signal': True,
        'refresh_success_requires_workdir_metadata_freshness_proof': True,
        'candidate_guard_scope': 'target-specific-not-global-pkglist-row-count',
        'candidate_guard_requires_exactly_one_target_row': True,
        'candidate_guard_requires_predecessor_installed': True,
        'candidate_guard_requires_target_source_binding': True,
        'evidence_encoding': 'real-tab-tsv',
        'remediation_must_be_revalidated_before_package_mutation': True,
        'builder_implementation_authorized': False,
        'builder_execution_authorized': False,
        'target_copy_authorized': False,
        'runtime_rerun_authorized': False,
    },
    'authorization': {
        'target_observation_authorized': False,
        'probe_transport_copy_authorized': False,
        'repository_only_local_source_v2_design_review_authorized': True,
        'local_source_v2_builder_implementation_authorized': False,
        'local_source_v2_build_authorized': False,
        'runtime_candidate_binding_authorized': False,
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
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze.sh',
    'helper_sha256': helper_sha,
    'machine_action_required': False,
    'controller_action_required': False,
    'pause_safe': False,
    'strong_safe_pause': False,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-review',
}

out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step', '223'),
    ('review_status', 'PASS'),
    ('accepted_step_222_policy_sha256', p222_sha),
    ('accepted_step_222_record_sha256', r222_sha),
    ('accepted_step_222_probe_sha256', probe_sha),
    ('returned_probe_result_consumed', 'yes'),
    ('single_use_observation_authority_consumed', 'yes'),
    ('revalidation_status', 'PASS'),
    ('fresh_runtime_identity', 'frozen-for-remediation-design'),
    ('fresh_boot_id', accepted['fresh_boot_id']),
    ('target_hostname', accepted['hostname_fqdn']),
    ('uname_machine', accepted['uname_machine']),
    ('uname_release', accepted['uname_release']),
    ('slackware_version', accepted['slackware_version']),
    ('package_database_manifest_sha256', accepted['package_database_manifest_sha256']),
    ('header_package_record', accepted['header_package_record']),
    ('kernel_generic_record', accepted['kernel_generic_record']),
    ('kernel_huge_absent', 'yes'),
    ('kernel_modules_absent', 'yes'),
    ('slackpkg_conf_sha256', accepted['slackpkg_conf_sha256']),
    ('slackpkg_mirrors_sha256', accepted['slackpkg_mirrors_sha256']),
    ('staged_target_sha256', accepted['staged_target_sha256']),
    ('local_source_v1_tree_verified', 'yes'),
    ('local_source_v1_tree_manifest_sha256', accepted['local_source_v1_tree_manifest_sha256']),
    ('local_source_v1_CHECKSUMS_md5_asc_absent', 'yes'),
    ('failed_evidence_root_present', 'yes'),
    ('failed_success_result_absent', 'yes'),
    ('published_success_evidence_absent', 'yes'),
    ('boot_artifacts_match_failed_preflight', 'yes'),
    ('slackpkg_state_matches_failed_preflight', 'yes'),
    ('geninitrd_policy_matches_failed_preflight', 'yes'),
    ('repository_refresh_performed', 'no'),
    ('network_access_performed', 'no'),
    ('package_action_performed', 'no'),
    ('slackpkg_mutation_performed', 'no'),
    ('boot_action_performed', 'no'),
    ('reboot_performed', 'no'),
    ('persistent_configuration_change_performed', 'no'),
    ('candidate_set_bound', 'no'),
    ('historical_step_213_boot_binding_reused', 'no'),
    ('historical_step_217_runtime_authorization_reused', 'no'),
    ('local_source_v1_must_be_preserved_unchanged', 'yes'),
    ('failed_runtime_evidence_root_must_be_preserved_unchanged', 'yes'),
    ('new_local_source_generation_name', 'local-source-v2'),
    ('repository_only_local_source_v2_design_review_authorized', 'yes'),
    ('local_source_v2_builder_implementation_authorized', 'no'),
    ('local_source_v2_build_authorized', 'no'),
    ('runtime_candidate_binding_authorized', 'no'),
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
    ('strong_safe_pause', 'no'),
    ('next_stage', 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-review'),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY
