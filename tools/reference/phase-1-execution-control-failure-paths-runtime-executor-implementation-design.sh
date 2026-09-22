#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-execution-control-failure-paths-runtime-executor-implementation-design.sh [--output-dir DIR] [--help]

Generate the step-183 repository-only runtime-executor implementation design
from the accepted step-182 target binding. This helper does not execute or
modify the runtime target.
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
binding_policy="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-target-binding-freeze-policy.json"
binding_record="$acceptance_dir/phase-1-execution-control-failure-paths-runtime-target-binding-freeze.tsv"
helper_path="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-design.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}
for required in "$binding_policy" "$binding_record" "$helper_path"; do
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
check_hash "$binding_policy" '2d14aef443f78ac3982538dc6cdb53d844cb987459ee824db4cf8d7b3c77f092'
check_hash "$binding_record" 'ca54d25b07938c9dfc9240f670fa0a5d03b47c35dd3e133e0a7fe8305eea2f49'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-execution-control-failure-paths-runtime-executor-implementation-design-policy.json"
record="$output_dir/phase-1-execution-control-failure-paths-runtime-executor-implementation-design.tsv"
binding_policy_sha=$(sha256sum -- "$binding_policy" | awk '{print $1}')
binding_record_sha=$(sha256sum -- "$binding_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$binding_policy" "$binding_record" "$policy" "$record" "$binding_policy_sha" "$binding_record_sha" "$helper_sha" <<'INNERPY'
import csv
import json
import sys
from pathlib import Path

binding_policy_path, binding_record_path, out_policy, out_record = map(Path, sys.argv[1:5])
binding_policy_sha, binding_record_sha, helper_sha = sys.argv[5:8]
binding_policy = json.loads(binding_policy_path.read_text(encoding='utf-8'))
with binding_record_path.open(encoding='utf-8', newline='') as handle:
    binding_record = dict(csv.reader(handle, delimiter='\t'))

assert binding_policy['schema'] == 1
assert binding_policy['scenario'] == 'phase-1-execution-control-failure-paths-runtime-target-binding-freeze'
assert binding_policy['runtime_target_binding']['state'] == 'frozen'
assert binding_policy['runtime_target_binding']['observation_status'] == 'PASS'
assert binding_record['runtime_target_binding_state'] == 'frozen'
assert binding_record['runtime_scenario_execution_authorized'] == 'no'

binding = binding_policy['runtime_target_binding']
policy = {
    'schema': 1,
    'scenario': 'phase-1-execution-control-failure-paths-runtime-executor-implementation-design',
    'review_only': True,
    'accepted_target_binding': {
        'step': 182,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-target-binding-freeze-policy.json',
        'policy_sha256': binding_policy_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-target-binding-freeze.tsv',
        'record_sha256': binding_record_sha,
        'hostname_fqdn': binding['hostname_fqdn'],
        'uname_release': binding['uname_release'],
        'boot_id': binding['boot_id'],
        'reference_script_sha256': binding['reference_script_sha256'],
        'effective_config_sha256': binding['effective_config_sha256'],
    },
    'runtime_executor_implementation_design': {
        'state': 'frozen',
        'family': 'execution-control-failure-paths',
        'scenario_count': 4,
        'controller_builder_path': 'tools/reference/phase-1-execution-control-failure-paths-runtime-executor-build.sh',
        'standalone_executor_path': 'tools/reference/phase-1-execution-control-failure-paths-runtime-executor.sh',
        'repository_acceptance_harness_path': 'tests/acceptance/reference/test-execution-control-failure-paths.sh',
        'target_requires_repository': False,
        'payload_form': 'single-self-contained-shell-script',
        'payload_generation': 'controller-generated-from-frozen-reference-script-and-effective-config',
        'embedded_reference_script_sha256': binding['reference_script_sha256'],
        'embedded_effective_config_sha256': binding['effective_config_sha256'],
        'runtime_acknowledgement': '--execute-runtime-validation',
        'privilege_boundary': 'root-via-sudo',
        'pre_execution_binding_gate': {
            'same_hostname_fqdn_required': True,
            'same_uname_release_required': True,
            'same_boot_id_required': True,
            'embedded_reference_script_sha256_required': True,
            'embedded_effective_config_sha256_required': True,
            'drift_action': 'stop-before-any-scenario-and-return-to-target-binding-review',
        },
        'runtime_evidence_root': '/var/tmp/slack-update-acceptance/execution-control-failure-paths',
        'published_archive_path': '/home/promano/slack-update-phase-1-execution-control-failure-paths-evidence.tar.gz',
        'published_sha256_path': '/home/promano/slack-update-phase-1-execution-control-failure-paths-evidence.tar.gz.sha256',
        'published_owner': 'promano:users',
        'published_mode': '0600',
        'runtime_config_derivation': {
            'source_must_match_frozen_effective_config_sha256': True,
            'allowed_overrides': ['core.work_dir', 'core.log_dir', 'core.lock_file'],
            'override_scope': 'root-owned-temporary-evidence-tree-only',
            'all_other_configuration_values_must_remain_identical': True,
            'derived_config_sha256_must_be_recorded': True,
        },
        'reference_driver_design': {
            'mode': 'source-exact-frozen-reference-script-with-main-guard-inactive',
            'functions_used_for-safe-control-tests': [
                'initialize_execution_environment',
                'load_configuration',
                'require_root',
                'acquire_instance_lock',
                'install_runtime_traps',
                'release_instance_lock',
            ],
            'package_or_boot_workflow_may_run': False,
            'safe_hold_mechanism': 'executor-owned-fifo-after-real-reference-lock-acquisition',
        },
        'scenario_implementations': [
            {
                'id': 'network-failure-before-repository-synchronization',
                'execution': 'run-the-exact-frozen-reference-script-with---check-inside-an-ephemeral-network-namespace-using-the-derived-runtime-config',
                'successful_external_network_access_allowed': False,
                'required_result': 'reference-check-fails-before-successful-repository-synchronization-and-control-state-is-clean',
            },
            {
                'id': 'simultaneous-execution-attempt',
                'execution': 'start-safe-reference-driver-hold-after-real-lock-acquisition-then-start-a-second-safe-reference-driver-against-the-same-lock',
                'expected_second_exit_code': 6,
                'required_result': 'second-attempt-rejected-while-first-lock-is-live-then-first-process-released-and-lock-clean',
            },
            {
                'id': 'signals-during-safe-test-operations',
                'execution': 'for-each-signal-start-safe-reference-driver-hold-after-real-lock-acquisition-deliver-signal-and-observe-cleanup',
                'signals': {'SIGINT': 130, 'SIGTERM': 143, 'SIGHUP': 129},
                'required_result': 'each-signal-exit-code-observed-and-lock-clean-after-each-run',
            },
            {
                'id': 'cron-without-interactive-terminal',
                'execution': 'install-one-temporary-root-crontab-entry-that-runs-the-safe-reference-driver-wrapper-records-no-tty-state-and-completion-then-restore-the-prior-root-crontab',
                'real_running_crond_required': True,
                'maximum_wait_seconds': 90,
                'required_result': 'one-real-cron-run-completes-without-interactive-terminal-and-prior-root-crontab-is-restored-exactly',
            },
        ],
        'pre_post_fingerprints': [
            'package-database-content-manifest',
            'running-kernel',
            'proc-cmdline',
            'boot-artifact-content-and-symlink-manifest',
            'execution-lock-state',
            'runtime-work-and-log-state',
            'root-crontab-state',
        ],
        'global_mutation_guards': {
            'repository_refresh_allowed': False,
            'successful_external_network_access_allowed': False,
            'package_mutation_allowed': False,
            'boot_mutation_allowed': False,
            'reboot_allowed': False,
            'persistent_configuration_change_allowed': False,
            'target_source_installation_allowed': False,
        },
        'cleanup_gate': [
            'no-live-test-process',
            'reference-lock-released',
            'temporary-network-namespace-gone',
            'temporary-cron-entry-gone',
            'prior-root-crontab-restored-exactly',
            'runtime-files-contained-under-evidence-root',
        ],
        'evidence_archive_rule': 'publish-only-after-cleanup-gate-and-post-fingerprint-capture',
        'failure_rule': 'preserve-evidence-at-current-stage-clean-temporary-control-state-stop-chain-and-do-not-run-later-scenarios',
        'success_rule': 'all-four-scenarios-and-three-signal-runs-pass-with-identical-package-and-boot-fingerprints-and-clean-control-state',
    },
    'gates': {
        'acceptance_matrix_complete': False,
        'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
        'c_port_status': 'blocked-by-phase-1-gate',
    },
    'authorization': {
        'runtime_executor_implementation_authorization_review_authorized_for_next_stage': True,
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
    'slackware_current_publication_invalidates_design': False,
    'helper_path': 'tools/reference/phase-1-execution-control-failure-paths-runtime-executor-implementation-design.sh',
    'helper_sha256': helper_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-executor-implementation-design.tsv',
    'next_stage': 'phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review',
    'pause_safe': False,
}

rows = [
    ('check', 'value'),
    ('accepted_target_binding_step', '182'),
    ('accepted_target_binding_policy_sha256', binding_policy_sha),
    ('accepted_target_binding_record_sha256', binding_record_sha),
    ('selected_family', 'execution-control-failure-paths'),
    ('scenario_count', '4'),
    ('runtime_executor_implementation_design_state', 'frozen'),
    ('target_requires_repository', 'no'),
    ('payload_form', 'single-self-contained-shell-script'),
    ('runtime_acknowledgement', '--execute-runtime-validation'),
    ('hostname_fqdn', binding['hostname_fqdn']),
    ('uname_release', binding['uname_release']),
    ('boot_id', binding['boot_id']),
    ('embedded_reference_script_sha256', binding['reference_script_sha256']),
    ('embedded_effective_config_sha256', binding['effective_config_sha256']),
    ('runtime_config_override_count', '3'),
    ('runtime_config_allowed_overrides', 'core.work_dir,core.log_dir,core.lock_file'),
    ('simultaneous_second_exit_code', '6'),
    ('signal_sigint_exit_code', '130'),
    ('signal_sigterm_exit_code', '143'),
    ('signal_sighup_exit_code', '129'),
    ('cron_real_context_required', 'yes'),
    ('cron_maximum_wait_seconds', '90'),
    ('repository_refresh_authorized', 'no'),
    ('network_refresh_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('runtime_executor_implementation_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('slackware_current_publication_invalidates_design', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review'),
]

Path(out_policy).write_text(json.dumps(policy, indent=2) + '\n', encoding='utf-8')
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
INNERPY

printf 'Step 183 runtime-executor implementation design generated successfully\n'
