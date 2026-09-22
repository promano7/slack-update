#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-execution-control-failure-paths-runtime-target-binding-review.sh [--output-dir DIR] [--help]

Freeze the read-only target-binding review contract for the selected Phase 1
execution-control failure-path family. This helper does not probe a live
machine and does not authorize the four runtime scenarios. It records the
expected VM identity, required read-only capability probe, source/configuration
identity inputs, and the next target-binding freeze gate.
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
design_policy="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-boundary-design-policy.json"
design_record="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-boundary-design.tsv"
helper_path="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-review.sh"
probe_path="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-probe.sh"

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
check_hash "$design_policy" '63a1605b36cddbc12fb3e0b3b68a349435f2230348bf3be76c71cd04e1c84cf1'
check_hash "$design_record" '0d4c3f5015da8f32bdb431d1246b5f670ace8cece2ccfc8331a69f73d87fcab1'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-execution-control-failure-paths-runtime-target-binding-review-policy.json"
record="$output_dir/phase-1-execution-control-failure-paths-runtime-target-binding-review.tsv"
design_policy_sha=$(sha256sum -- "$design_policy" | awk '{print $1}')
design_record_sha=$(sha256sum -- "$design_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')

python3 - "$design_policy" "$design_record" "$policy" "$record" \
    "$design_policy_sha" "$design_record_sha" "$helper_sha" "$probe_sha" <<'INNERPY'
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
assert design['scenario'] == 'phase-1-execution-control-failure-paths-runtime-boundary-design'
assert design['runtime_boundary_design']['state'] == 'frozen'
assert design['runtime_boundary_design']['target_binding_deferred'] is True
assert design['authorization']['target_binding_review_authorized_for_next_stage'] is True
assert design_record['selected_family'] == 'execution-control-failure-paths'
assert design_record['scenario_count'] == '4'

policy = {
    'schema': 1,
    'scenario': 'phase-1-execution-control-failure-paths-runtime-target-binding-review',
    'review_only': True,
    'accepted_runtime_boundary_design': {
        'step': 180,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-boundary-design-policy.json',
        'policy_sha256': design_policy_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-boundary-design.tsv',
        'record_sha256': design_record_sha,
        'family': 'execution-control-failure-paths',
        'scenario_count': 4,
    },
    'target_binding_review': {
        'state': 'runtime-observation-required',
        'target_class': 'slackware-current-runtime-validation-vm',
        'expected_hostname_fqdn': 'vbox-slackcurrent.vbox-slackcurrent.org',
        'binding_probe_path': 'tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-probe.sh',
        'binding_probe_sha256': probe_sha,
        'probe_execution': 'root-via-sudo',
        'probe_scope': 'read-only-target-observation-plus-ephemeral-network-namespace-capability-check',
        'repo_root_candidates': [
            '/home/promano/GitHub/slack-update',
            '/home/promano/Descargas/slack-update-main',
        ],
        'reference_script_path': 'tools/reference/slack-update-reference.sh',
        'effective_config_path': 'data/config/slack-update.conf',
        'required_binding_fields': [
            'hostname',
            'hostname-fqdn',
            'uname-release',
            'slackware-version',
            'boot-id',
            'repo-root',
            'reference-script-sha256',
            'effective-config-sha256',
            'probe-sha256',
        ],
        'required_capability_observations': [
            'bash', 'python3', 'sha256sum', 'tar', 'flock',
            'unshare-network-namespace', 'kill', 'ps', 'crontab', 'running-crond'
        ],
        'root_crontab_read_only_check': True,
        'network_namespace_check_command_semantics': 'create-ephemeral-network-namespace-run-true-exit-without-network-access',
        'successful_external_network_access_required': False,
        'repository_refresh_allowed': False,
        'package_mutation_allowed': False,
        'boot_mutation_allowed': False,
        'reboot_allowed': False,
        'persistent_system_configuration_change_allowed': False,
        'missing_capability_action': 'block-and-report-without-installing-or-changing-target',
        'binding_success_rule': 'expected-fqdn-all-required-files-and-capabilities-present-read-only-probe-pass',
        'binding_failure_rule': 'stop-before-executor-implementation-and-report-observation',
    },
    'gates': {
        'acceptance_matrix_complete': False,
        'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
        'c_port_status': 'blocked-by-phase-1-gate',
    },
    'authorization': {
        'runtime_target_observation_authorized': True,
        'target_binding_freeze_authorized_after_successful_observation': True,
        'runtime_executor_implementation_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'repository_refresh_authorized': False,
        'network_refresh_authorized': False,
        'package_action_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
    },
    'machine_action_required': True,
    'machine_action_type': 'read-only-target-binding-observation',
    'slackware_current_publication_invalidates_review': False,
    'helper_path': 'tools/reference/phase-1-execution-control-failure-paths-runtime-target-binding-review.sh',
    'helper_sha256': helper_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-target-binding-review.tsv',
    'next_stage': 'phase-1-execution-control-failure-paths-runtime-target-binding-freeze',
    'pause_safe': False,
}

record_rows = [
    ('check', 'value'),
    ('accepted_runtime_boundary_design_step', '180'),
    ('accepted_runtime_boundary_design_policy_sha256', design_policy_sha),
    ('accepted_runtime_boundary_design_record_sha256', design_record_sha),
    ('selected_family', 'execution-control-failure-paths'),
    ('scenario_count', '4'),
    ('target_binding_review_state', 'runtime-observation-required'),
    ('target_class', 'slackware-current-runtime-validation-vm'),
    ('expected_hostname_fqdn', 'vbox-slackcurrent.vbox-slackcurrent.org'),
    ('binding_probe_sha256', probe_sha),
    ('probe_execution', 'root-via-sudo'),
    ('reference_script_path', 'tools/reference/slack-update-reference.sh'),
    ('effective_config_path', 'data/config/slack-update.conf'),
    ('repository_refresh_allowed', 'no'),
    ('successful_external_network_access_required', 'no'),
    ('package_mutation_allowed', 'no'),
    ('boot_mutation_allowed', 'no'),
    ('reboot_allowed', 'no'),
    ('persistent_system_configuration_change_allowed', 'no'),
    ('runtime_target_observation_authorized', 'yes'),
    ('target_binding_freeze_authorized_after_successful_observation', 'yes'),
    ('runtime_executor_implementation_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('repository_refresh_authorized', 'no'),
    ('network_refresh_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'yes'),
    ('machine_action_type', 'read-only-target-binding-observation'),
    ('slackware_current_publication_invalidates_review', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-execution-control-failure-paths-runtime-target-binding-freeze'),
]
Path(out_policy).write_text(json.dumps(policy, indent=2) + '\n', encoding='utf-8')
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(record_rows)
INNERPY
cat "$record"
