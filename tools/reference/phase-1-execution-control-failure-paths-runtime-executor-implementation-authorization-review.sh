#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review.sh [--output-dir DIR] [--help]

Generate the step-184 repository-only authorization review for implementation
of the bounded runtime executor. This helper does not implement the executor and
does not execute or modify the runtime target.
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
design_policy="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-executor-implementation-design-policy.json"
design_record="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-executor-implementation-design.tsv"
helper_path="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}
for required in "$design_policy" "$design_record" "$helper_path"; do
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
check_hash "$design_policy" 'f651e072223868a8eda3339834d18e51884e95faf9db92dafb5c203ee9fc90f5'
check_hash "$design_record" 'a8a4539fb9cb37f1350e8cf79d65469350283e00c968e0691172453cc9bd6a96'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review-policy.json"
record="$output_dir/phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review.tsv"
design_policy_sha=$(sha256sum -- "$design_policy" | awk '{print $1}')
design_record_sha=$(sha256sum -- "$design_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$design_policy" "$design_record" "$policy" "$record" "$design_policy_sha" "$design_record_sha" "$helper_sha" <<'INNERPY'
import csv
import json
import sys
from pathlib import Path

design_policy_path, design_record_path, out_policy, out_record = map(Path, sys.argv[1:5])
design_policy_sha, design_record_sha, helper_sha = sys.argv[5:8]
design = json.loads(design_policy_path.read_text(encoding='utf-8'))
with design_record_path.open(encoding='utf-8', newline='') as handle:
    record = dict(csv.reader(handle, delimiter='\t'))

assert design['schema'] == 1
assert design['scenario'] == 'phase-1-execution-control-failure-paths-runtime-executor-implementation-design'
assert design['runtime_executor_implementation_design']['state'] == 'frozen'
assert design['authorization']['runtime_executor_implementation_authorized'] is False
assert design['authorization']['runtime_scenario_execution_authorized'] is False
assert record['runtime_executor_implementation_design_state'] == 'frozen'
assert record['next_stage'] == 'phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review'

d = design['runtime_executor_implementation_design']
b = design['accepted_target_binding']
policy = {
    'schema': 1,
    'scenario': 'phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review',
    'review_only': True,
    'accepted_implementation_design': {
        'step': 183,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-design-policy.json',
        'policy_sha256': design_policy_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-design.tsv',
        'record_sha256': design_record_sha,
        'family': d['family'],
        'scenario_count': d['scenario_count'],
        'payload_form': d['payload_form'],
        'runtime_acknowledgement': d['runtime_acknowledgement'],
    },
    'accepted_target_binding': {
        'hostname_fqdn': b['hostname_fqdn'],
        'uname_release': b['uname_release'],
        'boot_id': b['boot_id'],
        'reference_script_sha256': b['reference_script_sha256'],
        'effective_config_sha256': b['effective_config_sha256'],
    },
    'implementation_authorization_review': {
        'state': 'accepted',
        'scope': 'controller-repository-only',
        'authorized_outputs': [
            d['controller_builder_path'],
            d['standalone_executor_path'],
            d['repository_acceptance_harness_path'],
            'docs/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation.md',
            'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-policy.json',
            'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation.tsv',
        ],
        'implementation_requirements': {
            'derive_only_from_step_183_frozen_design': True,
            'builder_must_verify_frozen_reference_script_sha256': b['reference_script_sha256'],
            'builder_must_verify_frozen_effective_config_sha256': b['effective_config_sha256'],
            'generated_executor_must_be_single_self_contained_shell_script': True,
            'generated_executor_must_require_explicit_runtime_acknowledgement': d['runtime_acknowledgement'],
            'generated_executor_must_revalidate_fqdn_kernel_and_boot_id_before_any_scenario': True,
            'generated_executor_must_not_require_target_repository': True,
            'repository_harness_may_use_static_and_isolated_fixture_tests_only': True,
            'repository_harness_must_not_contact_external_network': True,
            'repository_harness_must_not_mutate_packages_or_boot': True,
            'implementation_review_required_before_runtime_authorization': True,
        },
        'identity_freeze_rule': 'builder-and-generated-executor-identities-are-frozen-only-by-the-post-implementation-review',
        'runtime_copy_to_target_authorized': False,
        'runtime_execution_authorized': False,
    },
    'gates': {
        'acceptance_matrix_complete': False,
        'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
        'c_port_status': 'blocked-by-phase-1-gate',
    },
    'authorization': {
        'runtime_executor_implementation_authorized': True,
        'repository_acceptance_harness_implementation_authorized': True,
        'runtime_executor_implementation_review_authorized_for_next_stage': True,
        'copy_executor_to_runtime_target_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'repository_refresh_authorized': False,
        'network_refresh_authorized': False,
        'package_action_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
    },
    'machine_action_required': False,
    'target_must_remain_on_frozen_boot_id': b['boot_id'],
    'slackware_current_publication_invalidates_authorization_review': False,
    'helper_path': 'tools/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review.sh',
    'helper_sha256': helper_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review.tsv',
    'next_stage': 'phase-1-execution-control-failure-paths-runtime-executor-implementation',
    'pause_safe': False,
}
Path(out_policy).write_text(json.dumps(policy, indent=2) + '\n', encoding='utf-8')
rows = [
    ('check','value'),
    ('accepted_implementation_design_step','183'),
    ('accepted_implementation_design_policy_sha256',design_policy_sha),
    ('accepted_implementation_design_record_sha256',design_record_sha),
    ('selected_family',d['family']),
    ('scenario_count',str(d['scenario_count'])),
    ('implementation_authorization_review_state','accepted'),
    ('authorization_scope','controller-repository-only'),
    ('payload_form',d['payload_form']),
    ('runtime_acknowledgement',d['runtime_acknowledgement']),
    ('hostname_fqdn',b['hostname_fqdn']),
    ('uname_release',b['uname_release']),
    ('boot_id',b['boot_id']),
    ('reference_script_sha256',b['reference_script_sha256']),
    ('effective_config_sha256',b['effective_config_sha256']),
    ('runtime_executor_implementation_authorized','yes'),
    ('repository_acceptance_harness_implementation_authorized','yes'),
    ('copy_executor_to_runtime_target_authorized','no'),
    ('runtime_scenario_execution_authorized','no'),
    ('repository_refresh_authorized','no'),
    ('network_refresh_authorized','no'),
    ('package_action_authorized','no'),
    ('boot_action_authorized','no'),
    ('reboot_authorized','no'),
    ('machine_action_required','no'),
    ('slackware_current_publication_invalidates_authorization_review','no'),
    ('pause_safe','no'),
    ('next_stage','phase-1-execution-control-failure-paths-runtime-executor-implementation'),
]
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
INNERPY

printf 'Step 184 runtime-executor implementation authorization review completed successfully\n'
