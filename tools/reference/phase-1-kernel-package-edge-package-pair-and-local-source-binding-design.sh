#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-package-pair-and-local-source-binding-design.sh [--output-dir DIR] [--help]

Freeze the non-mutating package-pair and immutable local-source binding design
for the selected Phase 1 kernel-package-edge acceptance scenario. This helper
binds no artifact bytes, download URL, signature, source tree, or live candidate
set and authorizes no machine or package action.
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
        --help)
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
target_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-target-binding-freeze-policy.json"
target_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-target-binding-freeze.tsv"
runtime_design_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-boundary-design-policy.json"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}
for required in "$target_policy" "$target_record" "$runtime_design_policy" "$helper_path"; do
    require_regular "$required"
done

check_hash() {
    local file=$1 expected=$2 actual
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: accepted prerequisite SHA-256 mismatch: %s\nexpected: %s\nactual:   %s\n' "$file" "$expected" "$actual" >&2
        exit 4
    }
}
check_hash "$target_policy" '0db70e4cbeba69a607a372181745ef936bcc693cfe11eb8aebf2c3f764c29621'
check_hash "$target_record" 'd2bbc87628a78d79077ecf51732a63dcbec55fc136b3d47ae2702c96867b09c6'
check_hash "$runtime_design_policy" 'a8e20a7a76b3c3b959ec8a2375c1d2c96cf11cbbdc0dfbd56cdfa3ac2696330a'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design-policy.json"
record="$output_dir/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design.tsv"
target_policy_sha=$(sha256sum -- "$target_policy" | awk '{print $1}')
target_record_sha=$(sha256sum -- "$target_record" | awk '{print $1}')
runtime_design_policy_sha=$(sha256sum -- "$runtime_design_policy" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$target_policy" "$target_record" "$runtime_design_policy" "$policy" "$record" \
    "$target_policy_sha" "$target_record_sha" "$runtime_design_policy_sha" "$helper_sha" <<'PY_INNER'
import csv
import json
import sys
from pathlib import Path

(target_policy_path, target_record_path, runtime_design_path,
 out_policy, out_record) = map(Path, sys.argv[1:6])
target_policy_sha, target_record_sha, runtime_design_sha, helper_sha = sys.argv[6:10]

target = json.loads(target_policy_path.read_text(encoding='utf-8'))
runtime_design = json.loads(runtime_design_path.read_text(encoding='utf-8'))
with target_record_path.open(encoding='utf-8', newline='') as handle:
    target_record = dict(csv.reader(handle, delimiter='\t'))

assert target['schema'] == 1
assert target['scenario'] == 'phase-1-kernel-package-edge-runtime-target-binding-freeze'
assert target['runtime_target_binding']['state'] == 'frozen'
assert target['runtime_target_binding']['observation_status'] == 'PASS'
assert target['runtime_target_binding']['header_package_record'] == 'kernel-headers-6.18.45-x86-1'
assert target_record['runtime_target_binding_state'] == 'frozen'
assert target_record['header_package_record'] == 'kernel-headers-6.18.45-x86-1'
assert runtime_design['schema'] == 1
assert runtime_design['scenario'] == 'phase-1-kernel-package-edge-runtime-boundary-design'
transition = runtime_design['runtime_boundary_design']['transition']
assert transition['source_strategy'] == 'immutable-local-slackpkg-compatible-source'
assert transition['package_pair_must_share_slackware_package_name'] is True
assert transition['predecessor_must_differ_from_target'] is True
assert transition['source_must_be_network-independent_during-runtime'] is True
assert transition['source_metadata_and_target_package_must_be_hash-bound'] is True

pair = {
    'state': 'design-frozen-artifacts-unbound',
    'package_name': 'kernel-headers',
    'target_installed_record': 'kernel-headers-6.18.45-x86-1',
    'target_artifact_filename_expected': 'kernel-headers-6.18.45-x86-1.txz',
    'target_signature_filename_expected': 'kernel-headers-6.18.45-x86-1.txz.asc',
    'predecessor_candidate_record': 'kernel-headers-6.18.44-x86-1',
    'predecessor_artifact_filename_expected': 'kernel-headers-6.18.44-x86-1.txz',
    'predecessor_signature_filename_expected': 'kernel-headers-6.18.44-x86-1.txz.asc',
    'predecessor_selection_rule': 'immediate-prior-kernel-headers-release-before-bound-target-in-cumulative-slackware-current-history',
    'same_package_name_required': True,
    'same_package_arch_required': True,
    'same_package_build_required': True,
    'predecessor_must_compare_older_than_target': True,
    'target_must_match_frozen_installed_record': True,
    'artifact_sha256_binding_deferred': True,
    'signature_sha256_binding_deferred': True,
    'exact_download_origin_binding_deferred': True,
    'trusted_signing_key_binding_deferred': True,
    'detached_signature_verification_required_before_source_build': True,
    'artifact_sha256_verification_required_before_source_build': True,
}

source = {
    'state': 'design-frozen-source-bytes-unbound',
    'strategy': 'deterministically-generated-minimal-file-mirror-from-bound-target-artifact',
    'planned_builder_path': 'tools/reference/phase-1-kernel-package-edge-local-source-build.sh',
    'runtime_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source',
    'runtime_mirror_uri': 'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source',
    'target_package_relative_path': 'slackware64/d/kernel-headers-6.18.45-x86-1.txz',
    'required_metadata_files': ['ChangeLog.txt', 'FILELIST.TXT', 'PACKAGES.TXT', 'CHECKSUMS.md5'],
    'target_package_only_exposed': True,
    'generated_metadata_is_upstream_signed': False,
    'artifact_authenticity_must_be_verified_before_source_build': True,
    'runtime_must_not_depend_on_generated_metadata_for_artifact_authenticity': True,
    'temporary_generated_metadata_signature_check_may_be_disabled_only_inside_bound_runtime_configuration': True,
    'source_tree_manifest_sha256_binding_deferred': True,
    'source_file_sha256_set_binding_deferred': True,
    'source_tree_must_be_read_only_after_build': True,
    'source_tree_must_be_hash_verified_before_and_after_reference_apply': True,
    'runtime_network_access_allowed': False,
    'target_vm_artifact_download_allowed': False,
}

acquisition = {
    'state': 'not-authorized',
    'controller_only_when_later_authorized': True,
    'target_vm_network_access_forbidden': True,
    'predecessor_and_target_package_bytes_required': True,
    'predecessor_and_target_detached_signatures_required': True,
    'exact_origin_and_hashes_must_be_frozen_before_target_copy': True,
    'no_target_copy_authorized_by_this_step': True,
}

validity = {
    'target_binding_from_step_194_must_remain_valid_before_any_target_copy': True,
    'target_reboot_or_package_drift_requires_return_to_target_binding_review': True,
    'controller_reference_or_effective_configuration_drift_requires_return_to_target_binding_review': True,
    'later_slackware_current_publication_invalidates_this_design': False,
    'later_publication_must_not_replace_the_bound_6_18_45_target_identity': True,
    'artifact_binding_failure_action': 'stop-before-target-copy-or-package-staging',
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-package-pair-and-local-source-binding-design',
    'review_only': True,
    'accepted_target_binding': {
        'step': 194,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-target-binding-freeze-policy.json',
        'policy_sha256': target_policy_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-target-binding-freeze.tsv',
        'record_sha256': target_record_sha,
        'target_hostname': target['runtime_target_binding']['hostname_fqdn'],
        'boot_id': target['runtime_target_binding']['boot_id'],
        'header_package_record': target['runtime_target_binding']['header_package_record'],
    },
    'accepted_runtime_boundary_design': {
        'step': 192,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-boundary-design-policy.json',
        'policy_sha256': runtime_design_sha,
        'source_strategy': transition['source_strategy'],
    },
    'binding_design': {
        'state': 'frozen',
        'package_pair': pair,
        'artifact_acquisition': acquisition,
        'local_source': source,
        'candidate_guard_preserved': transition['candidate_guard'],
        'install_new_candidate_count_required': 0,
        'non_header_upgrade_candidate_count_required': 0,
        'kernel_boot_upgrade_candidate_count_required': 0,
        'reference_apply_path': transition['reference_apply_path'],
        'reference_apply_mode': transition['reference_apply_mode'],
        'tested_transition_must_be_performed_by_reference_apply': True,
        'boot_mutation_allowed': False,
        'boot_configuration_mutation_allowed': False,
        'reboot_allowed': False,
        'unrelated_package_mutation_allowed': False,
        'live_candidate_set_bound': False,
        'live_runtime_chain_open': False,
        'validity': validity,
    },
    'authorization': {
        'package_pair_and_local_source_binding_review_authorized_for_next_stage': True,
        'controller_artifact_acquisition_authorized': False,
        'target_artifact_copy_authorized': False,
        'package_pair_binding_authorized': False,
        'local_source_binding_authorized': False,
        'runtime_executor_implementation_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'repository_refresh_authorized': False,
        'network_refresh_authorized': False,
        'machine_execution_authorized': False,
        'package_action_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
    },
    'gates': {
        'acceptance_matrix_complete': False,
        'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
        'c_port_status': 'blocked-by-phase-1-gate',
    },
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design.sh',
    'helper_sha256': helper_sha,
    'machine_action_required': False,
    'slackware_current_publication_invalidates_design': False,
    'next_stage': 'phase-1-kernel-package-edge-package-pair-and-local-source-binding-review',
    'pause_safe': False,
}

rows = [
    ('binding_design_state', 'frozen'),
    ('selected_package_name', pair['package_name']),
    ('target_installed_record', pair['target_installed_record']),
    ('target_artifact_filename_expected', pair['target_artifact_filename_expected']),
    ('predecessor_candidate_record', pair['predecessor_candidate_record']),
    ('predecessor_artifact_filename_expected', pair['predecessor_artifact_filename_expected']),
    ('predecessor_selection_rule', pair['predecessor_selection_rule']),
    ('artifact_sha256_binding_deferred', 'yes'),
    ('signature_sha256_binding_deferred', 'yes'),
    ('exact_download_origin_binding_deferred', 'yes'),
    ('detached_signature_verification_required_before_source_build', 'yes'),
    ('local_source_strategy', source['strategy']),
    ('local_source_builder_path', source['planned_builder_path']),
    ('local_source_runtime_root', source['runtime_root']),
    ('local_source_mirror_uri', source['runtime_mirror_uri']),
    ('local_source_target_package_relative_path', source['target_package_relative_path']),
    ('local_source_required_metadata_files', ' '.join(source['required_metadata_files'])),
    ('local_source_target_package_only_exposed', 'yes'),
    ('local_source_tree_manifest_binding_deferred', 'yes'),
    ('runtime_network_access_allowed', 'no'),
    ('target_vm_artifact_download_allowed', 'no'),
    ('candidate_guard', transition['candidate_guard']),
    ('install_new_candidate_count_required', '0'),
    ('non_header_upgrade_candidate_count_required', '0'),
    ('kernel_boot_upgrade_candidate_count_required', '0'),
    ('live_candidate_set_bound', 'no'),
    ('live_runtime_chain_open', 'no'),
    ('controller_artifact_acquisition_authorized', 'no'),
    ('target_artifact_copy_authorized', 'no'),
    ('package_pair_binding_authorized', 'no'),
    ('local_source_binding_authorized', 'no'),
    ('runtime_executor_implementation_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('machine_execution_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('slackware_current_publication_invalidates_design', 'no'),
    ('next_stage', policy['next_stage']),
    ('pause_safe', 'no'),
]

Path(out_policy).write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY_INNER

printf 'Package-pair and local-source binding design frozen.\n'
printf 'Policy: %s\n' "$policy"
printf 'Record: %s\n' "$record"
