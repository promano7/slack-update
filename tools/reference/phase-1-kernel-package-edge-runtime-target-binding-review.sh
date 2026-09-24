#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-target-binding-review.sh [--output-dir DIR] [--help]

Freeze the step-193 read-only target-binding observation gate for the selected
kernel-package-edge scenario. This helper does not probe a live machine and does
not bind a predecessor/target package pair or local source. It authorizes only
the standalone read-only target observation required before a later binding
freeze.
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
design_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-boundary-design-policy.json"
design_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-boundary-design.tsv"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-target-binding-review.sh"
probe_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-target-binding-probe.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}
for required in "$design_policy" "$design_record" "$helper_path" "$probe_path"; do
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
check_hash "$design_policy" 'a8e20a7a76b3c3b959ec8a2375c1d2c96cf11cbbdc0dfbd56cdfa3ac2696330a'
check_hash "$design_record" 'e244ecf5286a9b9e4f448151c1926469bb5c8b892091ea26e52b61c85c8e1d9e'
check_hash "$probe_path" 'da2540ccf76749d625721529c660f57861720f3f0e70814ae6fd9865123ea5b6'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-target-binding-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-target-binding-review.tsv"
design_policy_sha=$(sha256sum -- "$design_policy" | awk '{print $1}')
design_record_sha=$(sha256sum -- "$design_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')

python3 - "$design_policy" "$design_record" "$policy" "$record" \
    "$design_policy_sha" "$design_record_sha" "$helper_sha" "$probe_sha" <<'PY_INNER'
import csv
import json
import sys
from pathlib import Path

design_policy_path, design_record_path, out_policy, out_record = map(Path, sys.argv[1:5])
design_policy_sha, design_record_sha, helper_sha, probe_sha = sys.argv[5:9]

design = json.loads(design_policy_path.read_text(encoding='utf-8'))
with design_record_path.open(encoding='utf-8', newline='') as handle:
    design_record = dict(csv.reader(handle, delimiter='\t'))

assert design['schema'] == 1
assert design['scenario'] == 'phase-1-kernel-package-edge-runtime-boundary-design'
assert design['runtime_boundary_design']['state'] == 'frozen'
assert design['runtime_boundary_design']['target_class'] == 'slackware-current-runtime-validation-vm'
assert design['runtime_boundary_design']['target_binding_deferred'] is True
assert design['runtime_boundary_design']['package_pair_binding_deferred'] is True
assert design['runtime_boundary_design']['local_source_binding_deferred'] is True
assert design['authorization']['target_binding_review_authorized_for_next_stage'] is True
assert design_record['selected_family'] == 'kernel-package-edge'
assert design_record['scenario_count'] == '1'

binding = {
    'state': 'runtime-observation-required',
    'target_class': 'slackware-current-runtime-validation-vm',
    'expected_hostname_fqdn': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'binding_probe_path': 'tools/reference/phase-1-kernel-package-edge-runtime-target-binding-probe.sh',
    'binding_probe_sha256': probe_sha,
    'probe_execution': 'root-via-sudo',
    'probe_scope': 'standalone-read-only-target-identity-package-state-and-capability-observation',
    'target_repository_required': False,
    'source_identity_origin': 'controller-repo-frozen-at-step-193',
    'reference_script_path_on_controller': 'tools/reference/slack-update-reference.sh',
    'reference_script_sha256': '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415',
    'effective_config_path_on_controller': 'data/config/slack-update.conf',
    'effective_config_sha256': '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba',
    'configured_kernel_headers': ['kernel-headers'],
    'configured_kernel_boot': ['kernel-generic', 'kernel-huge', 'kernel-modules'],
    'package_database': '/var/log/packages',
    'package_database_canonical': '/var/lib/pkgtools/packages',
    'successful_observation_requires_exact_package_database_resolution': True,
    'required_binding_fields': [
        'target-hostname',
        'hostname-fqdn',
        'uname-release',
        'uname-machine',
        'slackware-version',
        'boot-id',
        'reference-script-sha256',
        'effective-config-sha256',
        'package-database-manifest-sha256',
        'package-database-canonical',
        'package-database-resolved',
        'header-package-record',
        'configured-boot-package-records',
        'slackpkg-config-fingerprints',
        'probe-sha256',
    ],
    'required_capability_observations': [
        'bash',
        'python3',
        'sha256sum',
        'tar',
        'flock',
        'slackpkg',
        'upgradepkg',
        'pkgtools-package-database',
        'pkgtools-package-database-layout',
    ],
    'successful_observation_requires_exact_fqdn': True,
    'successful_observation_requires_one_header_record': True,
    'successful_observation_requires_complete_boot_records': True,
    'successful_observation_requires_all_capabilities': True,
    'repository_refresh_allowed': False,
    'network_access_allowed': False,
    'package_mutation_allowed': False,
    'boot_mutation_allowed': False,
    'persistent_system_configuration_change_allowed': False,
    'reboot_allowed': False,
    'package_pair_binding_deferred': True,
    'local_source_binding_deferred': True,
    'live_candidate_set_bound': False,
    'live_runtime_chain_open': False,
    'observation_output_must_be_returned_for_next_gate': True,
    'target_reboot_invalidates_observation': True,
    'slackware_current_publication_invalidates_review': False,
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-target-binding-review',
    'review_only': True,
    'accepted_runtime_boundary_design': {
        'step': 192,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-boundary-design-policy.json',
        'policy_sha256': design_policy_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-boundary-design.tsv',
        'record_sha256': design_record_sha,
        'family': 'kernel-package-edge',
        'scenario_count': 1,
    },
    'target_binding_review': binding,
    'authorization': {
        'runtime_target_observation_authorized': True,
        'target_binding_freeze_authorized_after_successful_observation': True,
        'package_pair_binding_authorized': False,
        'local_source_binding_authorized': False,
        'runtime_executor_implementation_authorized': False,
        'runtime_execution_authorized': False,
        'repository_refresh_authorized': False,
        'network_refresh_authorized': False,
        'package_action_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
    },
    'machine_action_required': True,
    'machine_action_type': 'read-only-target-binding-observation',
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-target-binding-review.sh',
    'helper_sha256': helper_sha,
    'probe_path': binding['binding_probe_path'],
    'probe_sha256': probe_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-target-binding-review.tsv',
    'next_stage': 'phase-1-kernel-package-edge-runtime-target-binding-freeze',
    'pause_safe': False,
}
out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')

rows = [
    ('check', 'value'),
    ('accepted_runtime_boundary_design_step', '192'),
    ('accepted_design_policy_sha256', design_policy_sha),
    ('accepted_design_record_sha256', design_record_sha),
    ('selected_family', 'kernel-package-edge'),
    ('scenario_count', '1'),
    ('target_binding_review_state', binding['state']),
    ('target_class', binding['target_class']),
    ('expected_hostname_fqdn', binding['expected_hostname_fqdn']),
    ('binding_probe_path', binding['binding_probe_path']),
    ('binding_probe_sha256', probe_sha),
    ('probe_execution', binding['probe_execution']),
    ('probe_scope', binding['probe_scope']),
    ('target_repository_required', 'no'),
    ('source_identity_origin', binding['source_identity_origin']),
    ('reference_script_sha256', binding['reference_script_sha256']),
    ('effective_config_sha256', binding['effective_config_sha256']),
    ('configured_kernel_headers', 'kernel-headers'),
    ('configured_kernel_boot', 'kernel-generic kernel-huge kernel-modules'),
    ('package_database', binding['package_database']),
    ('package_database_canonical', binding['package_database_canonical']),
    ('package_database_resolution_required', 'yes'),
    ('repository_refresh_allowed', 'no'),
    ('network_access_allowed', 'no'),
    ('package_mutation_allowed', 'no'),
    ('boot_mutation_allowed', 'no'),
    ('persistent_system_configuration_change_allowed', 'no'),
    ('reboot_allowed', 'no'),
    ('package_pair_binding_deferred', 'yes'),
    ('local_source_binding_deferred', 'yes'),
    ('live_candidate_set_bound', 'no'),
    ('live_runtime_chain_open', 'no'),
    ('observation_output_must_be_returned_for_next_gate', 'yes'),
    ('target_reboot_invalidates_observation', 'yes'),
    ('slackware_current_publication_invalidates_review', 'no'),
    ('runtime_target_observation_authorized', 'yes'),
    ('target_binding_freeze_authorized_after_successful_observation', 'yes'),
    ('package_pair_binding_authorized', 'no'),
    ('local_source_binding_authorized', 'no'),
    ('runtime_executor_implementation_authorized', 'no'),
    ('runtime_execution_authorized', 'no'),
    ('repository_refresh_authorized', 'no'),
    ('network_refresh_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'yes'),
    ('machine_action_type', 'read-only-target-binding-observation'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-kernel-package-edge-runtime-target-binding-freeze'),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY_INNER

cat -- "$record"
