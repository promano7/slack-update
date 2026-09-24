#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-target-binding-freeze.sh [--output-dir DIR] [--help]

Generate the step-194 target-binding freeze policy and record from the accepted
step-193-r2 review and the successful standalone Slackware-current VM
observation. This helper is repository-only; it does not probe or modify a live
machine.
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
review_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-target-binding-review-policy.json"
review_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-target-binding-review.tsv"
review_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-target-binding-probe.sh"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-target-binding-freeze.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}
for required in "$review_policy" "$review_record" "$review_probe" "$helper_path"; do
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
check_hash "$review_policy" '834276083c8e4d50c2c5510e10c21c512bb10ee85a88b70baeebf7a494d5f7a1'
check_hash "$review_record" '6fc9cc61a4ac84eff07f2cf273aabda043f13115b53f35fdfa670c7a64815160'
check_hash "$review_probe" 'bda22255aaa1db2dad4f8a28ed89719ddc89dbb03989fa3facd0a19c6d65ac6f'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-target-binding-freeze-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-target-binding-freeze.tsv"
review_policy_sha=$(sha256sum -- "$review_policy" | awk '{print $1}')
review_record_sha=$(sha256sum -- "$review_record" | awk '{print $1}')
review_probe_sha=$(sha256sum -- "$review_probe" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$review_policy" "$review_record" "$policy" "$record" "$review_policy_sha" "$review_record_sha" "$review_probe_sha" "$helper_sha" <<'INNERPY'
import csv
import json
import sys
from pathlib import Path

review_policy_path, review_record_path, out_policy, out_record = map(Path, sys.argv[1:5])
review_policy_sha, review_record_sha, review_probe_sha, helper_sha = sys.argv[5:9]
review = json.loads(review_policy_path.read_text(encoding='utf-8'))
with review_record_path.open(encoding='utf-8', newline='') as handle:
    review_record = dict(csv.reader(handle, delimiter='\t'))

assert review['schema'] == 1
assert review['scenario'] == 'phase-1-kernel-package-edge-runtime-target-binding-review'
assert review['target_binding_review']['expected_hostname_fqdn'] == 'vbox-slackcurrent.vbox-slackcurrent.org'
assert review['target_binding_review']['binding_probe_sha256'] == review_probe_sha
assert review['target_binding_review']['reference_script_sha256'] == '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
assert review['target_binding_review']['effective_config_sha256'] == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
assert review['target_binding_review']['configured_kernel_headers'] == ['kernel-headers']
assert review['target_binding_review']['configured_kernel_boot'] == ['kernel-generic', 'kernel-huge', 'kernel-modules']
assert review['target_binding_review']['package_database'] == '/var/log/packages'
assert review['target_binding_review']['package_database_canonical'] == '/var/lib/pkgtools/packages'
assert review_record['target_binding_freeze_authorized_after_successful_observation'] == 'yes'

binding = {
    'observation_status': 'PASS',
    'target_hostname': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'hostname_fqdn': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'uname_release': '6.18.45',
    'uname_machine': 'x86_64',
    'slackware_version': 'Slackware 15.0+',
    'boot_id': '5e79b100-55a8-415d-a6ea-1cb8c568c2eb',
    'reference_script_sha256': '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415',
    'effective_config_sha256': '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba',
    'configured_kernel_headers': ['kernel-headers'],
    'configured_kernel_boot': ['kernel-generic', 'kernel-huge', 'kernel-modules'],
    'package_database': '/var/log/packages',
    'package_database_canonical': '/var/lib/pkgtools/packages',
    'package_database_resolved': '/var/lib/pkgtools/packages',
    'package_database_manifest_sha256': '3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910',
    'header_package_record_count': 1,
    'header_package_record': 'kernel-headers-6.18.45-x86-1',
    'boot_package_records_unambiguous': True,
    'installed_boot_package_count': 1,
    'boot_package_observations': [
        {'name': 'kernel-generic', 'record_count': 1, 'status': 'installed', 'record': 'kernel-generic-6.18.45-x86_64-1'},
        {'name': 'kernel-huge', 'record_count': 0, 'status': 'absent', 'record': None},
        {'name': 'kernel-modules', 'record_count': 0, 'status': 'absent', 'record': None},
    ],
    'slackpkg_conf_sha256': 'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
    'slackpkg_mirrors_sha256': '71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
    'probe_sha256': review_probe_sha,
    'source_identity_origin': 'controller-repo-frozen-at-step-193',
    'target_repository_required': False,
    'repository_refresh_performed': False,
    'network_access_performed': False,
    'package_action_performed': False,
    'boot_action_performed': False,
    'persistent_configuration_change_performed': False,
    'reboot_performed': False,
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-target-binding-freeze',
    'review_only': True,
    'accepted_target_binding_review': {
        'step': 193,
        'revision': 'r2-boot-package-observation',
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-target-binding-review-policy.json',
        'policy_sha256': review_policy_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-target-binding-review.tsv',
        'record_sha256': review_record_sha,
        'probe_path': 'tools/reference/phase-1-kernel-package-edge-runtime-target-binding-probe.sh',
        'probe_sha256': review_probe_sha,
    },
    'runtime_target_binding': {
        'state': 'frozen',
        'target_class': 'slackware-current-runtime-validation-vm',
        **binding,
        'validity_requirements': {
            'same_hostname_fqdn_required': True,
            'same_boot_id_required_before_staging': True,
            'same_running_kernel_required_before_staging': True,
            'same_uname_machine_required': True,
            'same_reference_script_sha256_required': True,
            'same_effective_config_sha256_required': True,
            'same_package_database_layout_required': True,
            'same_package_database_manifest_sha256_required_before_staging': True,
            'same_header_package_record_required_before_staging': True,
            'same_boot_package_observations_required_before_staging': True,
            'same_slackpkg_conf_sha256_required_before_source_binding': True,
            'same_slackpkg_mirrors_sha256_required_before_source_binding': True,
            'same_probe_sha256_required_for_binding_reproduction': True,
            'later_slackware_current_publication_invalidates_binding': False,
            'target_reboot_invalidates_binding': True,
            'running_kernel_change_invalidates_binding': True,
            'package_database_drift_invalidates_pre_staging_binding': True,
            'slackpkg_configuration_drift_invalidates_source_binding': True,
            'controller_reference_or_config_change_invalidates_binding': True,
            'binding_drift_action': 'stop-before-package-staging-and-return-to-target-binding-review',
        },
    },
    'gates': {
        'acceptance_matrix_complete': False,
        'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
        'c_port_status': 'blocked-by-phase-1-gate',
    },
    'authorization': {
        'package_pair_and_local_source_binding_design_authorized_for_next_stage': True,
        'package_pair_binding_authorized': False,
        'local_source_binding_authorized': False,
        'runtime_executor_implementation_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'repository_refresh_authorized': False,
        'network_refresh_authorized': False,
        'package_action_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
    },
    'machine_action_required': False,
    'slackware_current_publication_invalidates_binding': False,
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-target-binding-freeze.sh',
    'helper_sha256': helper_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-target-binding-freeze.tsv',
    'next_stage': 'phase-1-kernel-package-edge-package-pair-and-local-source-binding-design',
    'pause_safe': False,
}

rows = [
    ('check', 'value'),
    ('accepted_target_binding_review_step', '193'),
    ('accepted_target_binding_review_revision', 'r2-boot-package-observation'),
    ('accepted_target_binding_review_policy_sha256', review_policy_sha),
    ('accepted_target_binding_review_record_sha256', review_record_sha),
    ('accepted_target_binding_probe_sha256', review_probe_sha),
    ('selected_family', 'kernel-package-edge'),
    ('scenario_count', '1'),
    ('runtime_target_binding_state', 'frozen'),
    ('observation_status', binding['observation_status']),
    ('target_hostname', binding['target_hostname']),
    ('hostname_fqdn', binding['hostname_fqdn']),
    ('uname_release', binding['uname_release']),
    ('uname_machine', binding['uname_machine']),
    ('slackware_version', binding['slackware_version']),
    ('boot_id', binding['boot_id']),
    ('reference_script_sha256', binding['reference_script_sha256']),
    ('effective_config_sha256', binding['effective_config_sha256']),
    ('configured_kernel_headers', ' '.join(binding['configured_kernel_headers'])),
    ('configured_kernel_boot', ' '.join(binding['configured_kernel_boot'])),
    ('package_database', binding['package_database']),
    ('package_database_canonical', binding['package_database_canonical']),
    ('package_database_resolved', binding['package_database_resolved']),
    ('package_database_manifest_sha256', binding['package_database_manifest_sha256']),
    ('header_package_record_count', str(binding['header_package_record_count'])),
    ('header_package_record', binding['header_package_record']),
    ('boot_package_records_unambiguous', 'yes'),
    ('installed_boot_package_count', str(binding['installed_boot_package_count'])),
]
for item in binding['boot_package_observations']:
    name = item['name']
    rows.extend([
        (f'boot_package_record_count_{name}', str(item['record_count'])),
        (f'boot_package_record_status_{name}', item['status']),
    ])
    if item['record'] is not None:
        rows.append((f'boot_package_record_{name}', item['record']))
rows.extend([
    ('slackpkg_conf_sha256', binding['slackpkg_conf_sha256']),
    ('slackpkg_mirrors_sha256', binding['slackpkg_mirrors_sha256']),
    ('probe_sha256', binding['probe_sha256']),
    ('source_identity_origin', binding['source_identity_origin']),
    ('target_repository_required', 'no'),
    ('repository_refresh_performed', 'no'),
    ('network_access_performed', 'no'),
    ('package_action_performed', 'no'),
    ('boot_action_performed', 'no'),
    ('persistent_configuration_change_performed', 'no'),
    ('reboot_performed', 'no'),
    ('same_boot_id_required_before_staging', 'yes'),
    ('same_running_kernel_required_before_staging', 'yes'),
    ('same_package_database_manifest_sha256_required_before_staging', 'yes'),
    ('same_header_package_record_required_before_staging', 'yes'),
    ('same_boot_package_observations_required_before_staging', 'yes'),
    ('same_slackpkg_conf_sha256_required_before_source_binding', 'yes'),
    ('same_slackpkg_mirrors_sha256_required_before_source_binding', 'yes'),
    ('target_reboot_invalidates_binding', 'yes'),
    ('package_database_drift_invalidates_pre_staging_binding', 'yes'),
    ('slackpkg_configuration_drift_invalidates_source_binding', 'yes'),
    ('later_slackware_current_publication_invalidates_binding', 'no'),
    ('package_pair_and_local_source_binding_design_authorized_for_next_stage', 'yes'),
    ('package_pair_binding_authorized', 'no'),
    ('local_source_binding_authorized', 'no'),
    ('runtime_executor_implementation_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('repository_refresh_authorized', 'no'),
    ('network_refresh_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-kernel-package-edge-package-pair-and-local-source-binding-design'),
])

out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
INNERPY

printf 'Step 194 kernel-package-edge runtime target-binding freeze generated successfully.\n'
