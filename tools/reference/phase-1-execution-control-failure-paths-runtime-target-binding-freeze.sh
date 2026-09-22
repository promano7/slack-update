#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-execution-control-failure-paths-runtime-target-binding-freeze.sh [--output-dir DIR] [--help]

Generate the step-182 target-binding freeze policy and record from the accepted
step-181-r1 review and the successful standalone VM observation. This helper is
repository-only; it does not probe or modify a live machine.
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
review_policy="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-target-binding-review-policy.json"
review_record="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-target-binding-review.tsv"
helper_path="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-freeze.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}
for required in "$review_policy" "$review_record" "$helper_path"; do
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
check_hash "$review_policy" '2a5f0289be049539de65ab08a0a8a585717ec0f79cc830872074e20cc86f4e48'
check_hash "$review_record" 'ce7ab5b5ded166bb8b56ffbfe72901acfa22f1cb86130b42b536e1f68c25c3bf'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-execution-control-failure-paths-runtime-target-binding-freeze-policy.json"
record="$output_dir/phase-1-execution-control-failure-paths-runtime-target-binding-freeze.tsv"
review_policy_sha=$(sha256sum -- "$review_policy" | awk '{print $1}')
review_record_sha=$(sha256sum -- "$review_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$review_policy" "$review_record" "$policy" "$record" "$review_policy_sha" "$review_record_sha" "$helper_sha" <<'INNERPY'
import csv
import json
import sys
from pathlib import Path

review_policy_path, review_record_path, out_policy, out_record = map(Path, sys.argv[1:5])
review_policy_sha, review_record_sha, helper_sha = sys.argv[5:8]
review = json.loads(review_policy_path.read_text(encoding='utf-8'))
with review_record_path.open(encoding='utf-8', newline='') as handle:
    review_record = dict(csv.reader(handle, delimiter='\t'))

assert review['schema'] == 1
assert review['scenario'] == 'phase-1-execution-control-failure-paths-runtime-target-binding-review'
assert review['revision'] == 'r1-standalone-probe'
assert review['target_binding_review']['expected_hostname_fqdn'] == 'vbox-slackcurrent.vbox-slackcurrent.org'
assert review['target_binding_review']['binding_probe_sha256'] == 'fbf840f19c51aaa29c3d6fb1eb00d6ca87bf2b594b91cb4524d31e4853fbc82b'
assert review['target_binding_review']['reference_script_sha256'] == '086b28b42be3135ebf47a28c1fcd2e5652f8fdd261e696ad48e612a241edf4ea'
assert review['target_binding_review']['effective_config_sha256'] == '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'
assert review_record['target_binding_freeze_authorized_after_successful_observation'] == 'yes'

binding = {
    'observation_status': 'PASS',
    'hostname': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'hostname_fqdn': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'uname_release': '6.18.45',
    'slackware_version': 'Slackware 15.0+',
    'boot_id': 'cb85100b-9993-4876-ab32-b2457ed0ac6d',
    'reference_script_sha256': '086b28b42be3135ebf47a28c1fcd2e5652f8fdd261e696ad48e612a241edf4ea',
    'effective_config_sha256': '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba',
    'source_identity_origin': 'controller-repo-frozen-at-step-181-r1',
    'target_repository_required': False,
    'probe_sha256': 'fbf840f19c51aaa29c3d6fb1eb00d6ca87bf2b594b91cb4524d31e4853fbc82b',
    'capabilities': {
        'bash': 'PASS',
        'python3': 'PASS',
        'sha256sum': 'PASS',
        'tar': 'PASS',
        'flock': 'PASS',
        'unshare-network-namespace': 'PASS',
        'kill': 'PASS',
        'ps': 'PASS',
        'crontab': 'PASS',
        'running-crond': 'PASS',
        'root-crontab-read-only-check': 'PASS',
    },
    'repository_refresh_performed': False,
    'external_network_access_performed': False,
    'package_mutation_performed': False,
    'boot_mutation_performed': False,
    'system_restart_performed': False,
    'persistent_configuration_change_performed': False,
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-execution-control-failure-paths-runtime-target-binding-freeze',
    'review_only': True,
    'accepted_target_binding_review': {
        'step': 181,
        'revision': 'r1-standalone-probe',
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-target-binding-review-policy.json',
        'policy_sha256': review_policy_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-target-binding-review.tsv',
        'record_sha256': review_record_sha,
        'probe_sha256': 'fbf840f19c51aaa29c3d6fb1eb00d6ca87bf2b594b91cb4524d31e4853fbc82b',
    },
    'runtime_target_binding': {
        'state': 'frozen',
        'target_class': 'slackware-current-runtime-validation-vm',
        **binding,
        'validity_requirements': {
            'same_hostname_fqdn_required': True,
            'same_boot_id_required_before_runtime_execution': True,
            'same_running_kernel_required_before_runtime_execution': True,
            'same_reference_script_sha256_required': True,
            'same_effective_config_sha256_required': True,
            'same_probe_sha256_required_for_binding_reproduction': True,
            'later_slackware_current_publication_invalidates_binding': False,
            'target_reboot_invalidates_binding': True,
            'running_kernel_change_invalidates_binding': True,
            'controller_reference_or_config_change_invalidates_binding': True,
            'binding_drift_action': 'stop-before-runtime-execution-and-return-to-target-binding-review',
        },
    },
    'gates': {
        'acceptance_matrix_complete': False,
        'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
        'c_port_status': 'blocked-by-phase-1-gate',
    },
    'authorization': {
        'runtime_executor_implementation_design_authorized_for_next_stage': True,
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
    'helper_path': 'tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-freeze.sh',
    'helper_sha256': helper_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-target-binding-freeze.tsv',
    'next_stage': 'phase-1-execution-control-failure-paths-runtime-executor-implementation-design',
    'pause_safe': False,
}

rows = [
    ('check', 'value'),
    ('accepted_target_binding_review_step', '181'),
    ('accepted_target_binding_review_revision', 'r1-standalone-probe'),
    ('accepted_target_binding_review_policy_sha256', review_policy_sha),
    ('accepted_target_binding_review_record_sha256', review_record_sha),
    ('selected_family', 'execution-control-failure-paths'),
    ('scenario_count', '4'),
    ('runtime_target_binding_state', 'frozen'),
    ('observation_status', 'PASS'),
    ('hostname', binding['hostname']),
    ('hostname_fqdn', binding['hostname_fqdn']),
    ('uname_release', binding['uname_release']),
    ('slackware_version', binding['slackware_version']),
    ('boot_id', binding['boot_id']),
    ('reference_script_sha256', binding['reference_script_sha256']),
    ('effective_config_sha256', binding['effective_config_sha256']),
    ('source_identity_origin', binding['source_identity_origin']),
    ('target_repository_required', 'no'),
    ('probe_sha256', binding['probe_sha256']),
    ('capability_bash', 'PASS'),
    ('capability_python3', 'PASS'),
    ('capability_sha256sum', 'PASS'),
    ('capability_tar', 'PASS'),
    ('capability_flock', 'PASS'),
    ('capability_unshare_network_namespace', 'PASS'),
    ('capability_kill', 'PASS'),
    ('capability_ps', 'PASS'),
    ('capability_crontab', 'PASS'),
    ('capability_running_crond', 'PASS'),
    ('root_crontab_read_only_check', 'PASS'),
    ('repository_refresh_performed', 'no'),
    ('external_network_access_performed', 'no'),
    ('package_mutation_performed', 'no'),
    ('boot_mutation_performed', 'no'),
    ('system_restart_performed', 'no'),
    ('persistent_configuration_change_performed', 'no'),
    ('same_boot_id_required_before_runtime_execution', 'yes'),
    ('same_running_kernel_required_before_runtime_execution', 'yes'),
    ('later_slackware_current_publication_invalidates_binding', 'no'),
    ('target_reboot_invalidates_binding', 'yes'),
    ('running_kernel_change_invalidates_binding', 'yes'),
    ('controller_reference_or_config_change_invalidates_binding', 'yes'),
    ('runtime_executor_implementation_design_authorized_for_next_stage', 'yes'),
    ('runtime_executor_implementation_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('repository_refresh_authorized', 'no'),
    ('network_refresh_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('slackware_current_publication_invalidates_binding', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-execution-control-failure-paths-runtime-executor-implementation-design'),
]
Path(out_policy).write_text(json.dumps(policy, indent=2) + '\n', encoding='utf-8')
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    csv.writer(handle, delimiter='\t', lineterminator='\n').writerows(rows)
INNERPY
cat "$record"
