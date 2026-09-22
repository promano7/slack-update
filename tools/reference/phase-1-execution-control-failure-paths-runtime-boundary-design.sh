#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-execution-control-failure-paths-runtime-boundary-design.sh [--output-dir DIR] [--help]

Freeze the non-mutating runtime-boundary design for the selected Phase 1
execution-control failure-path acceptance family. This helper does not bind a
machine or authorize runtime execution. It only records the target class,
required capabilities, scenario isolation methods, evidence contract, and the
next explicit target-binding review gate.
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
contract_policy="$acceptance_dir/phase-1-execution-control-failure-paths-contract-freeze-policy.json"
contract_record="$acceptance_dir/phase-1-execution-control-failure-paths-contract-freeze.tsv"
helper_path="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-boundary-design.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}
for required in "$contract_policy" "$contract_record" "$helper_path"; do
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
check_hash "$contract_policy" '5ea897b193250dd99d9f7ac988cdd2fc95f1bc48df41c8d6189b6a689e1c1dd9'
check_hash "$contract_record" '7a6ed7b1342f8d741debdc40de7d39bf1063fb84cb0e57e6f60f8e42db9f4bd6'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-execution-control-failure-paths-runtime-boundary-design-policy.json"
record="$output_dir/phase-1-execution-control-failure-paths-runtime-boundary-design.tsv"
contract_policy_sha=$(sha256sum -- "$contract_policy" | awk '{print $1}')
contract_record_sha=$(sha256sum -- "$contract_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$contract_policy" "$contract_record" "$policy" "$record" \
    "$contract_policy_sha" "$contract_record_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

contract_policy_path, contract_record_path, out_policy, out_record = map(Path, sys.argv[1:5])
contract_policy_sha, contract_record_sha, helper_sha = sys.argv[5:8]
contract = json.loads(contract_policy_path.read_text(encoding='utf-8'))
with contract_record_path.open(encoding='utf-8', newline='') as handle:
    contract_record = dict(csv.reader(handle, delimiter='\t'))

assert contract['schema'] == 1
assert contract['scenario'] == 'phase-1-execution-control-failure-paths-contract-freeze'
assert contract['contract']['state'] == 'frozen'
assert contract['contract']['family'] == 'execution-control-failure-paths'
assert contract['contract']['scenario_count'] == 4
assert contract['contract']['target_class'] == 'slackware-current-runtime-validation-vm'
assert contract['contract']['target_binding_deferred'] is True
assert contract['contract']['package_mutation_allowed'] is False
assert contract['contract']['boot_mutation_allowed'] is False
assert contract['contract']['reboot_required'] is False
assert contract_record['selected_family'] == 'execution-control-failure-paths'
assert contract_record['scenario_count'] == '4'
assert contract_record['contract_state'] == 'frozen'

scenario_designs = [
    {
        'id': 'network-failure-before-repository-synchronization',
        'method': 'run-the-reference-check-inside-a-temporary-network-namespace-with-no-usable-external-interface',
        'host_network_configuration_change': False,
        'successful_repository_synchronization_allowed': False,
        'required_observation': 'network-or-repository-stage-fails-before-any-successful-synchronization-and-control-state-is-clean',
    },
    {
        'id': 'simultaneous-execution-attempt',
        'method': 'start-a-real-reference-process-at-a-safe-check-path-observe-lock-acquisition-stop-it-temporarily-then-start-a-second-real-attempt',
        'first_process_package_or_boot_mutation_allowed': False,
        'second_process_may_acquire_execution_lock': False,
        'required_observation': 'second-attempt-is-rejected-while-first-lock-is-live-and-final-lock-state-is-clean',
    },
    {
        'id': 'signals-during-safe-test-operations',
        'method': 'for-each-required-signal-start-a-real-safe-check-process-observe-lock-acquisition-and-deliver-the-signal-before-any-mutating-stage',
        'signals': ['SIGINT', 'SIGTERM', 'SIGHUP'],
        'expected_statuses': {'SIGINT': 130, 'SIGTERM': 143, 'SIGHUP': 129},
        'one_signal_per_run': True,
        'required_observation': 'signal-status-is-observable-lock-is-released-and-temporary-control-state-is-clean',
    },
    {
        'id': 'cron-without-interactive-terminal',
        'method': 'install-one-temporary-root-crontab-entry-that-launches-the-bounded-safe-check-wrapper-with-no-terminal-wait-for-one-run-then-restore-the-exact-prior-crontab',
        'real_cron_required': True,
        'existing_root_crontab_must_be_backed_up_and_restored_exactly': True,
        'persistent_cron_entry_allowed_after_test': False,
        'required_observation': 'cron-run-has-no-interactive-terminal-produces-deterministic-evidence-and-leaves-the-original-crontab-exactly-restored',
    },
]

policy = {
    'schema': 1,
    'scenario': 'phase-1-execution-control-failure-paths-runtime-boundary-design',
    'review_only': True,
    'accepted_contract': {
        'step': 179,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-contract-freeze-policy.json',
        'policy_sha256': contract_policy_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-contract-freeze.tsv',
        'record_sha256': contract_record_sha,
        'family': 'execution-control-failure-paths',
        'scenario_count': 4,
    },
    'runtime_boundary_design': {
        'state': 'frozen',
        'target_class': 'slackware-current-runtime-validation-vm',
        'target_binding_deferred': True,
        'target_binding_must_record': [
            'hostname',
            'hostname-fqdn',
            'uname-release',
            'slackware-version',
            'boot-id',
            'reference-script-sha256',
            'effective-config-sha256',
        ],
        'planned_acceptance_executor_path': 'tests/acceptance/reference/test-execution-control-failure-paths.sh',
        'planned_execution_acknowledgement': '--execute-runtime-validation',
        'privilege_boundary': 'root-via-sudo',
        'runtime_evidence_root': '/var/tmp/slack-update-acceptance/execution-control-failure-paths',
        'published_archive_path': '/home/promano/slack-update-phase-1-execution-control-failure-paths-evidence.tar.gz',
        'published_sha256_path': '/home/promano/slack-update-phase-1-execution-control-failure-paths-evidence.tar.gz.sha256',
        'published_owner': 'promano:users',
        'published_mode': '0600',
        'required_capabilities': [
            'bash',
            'python3',
            'sha256sum',
            'tar',
            'flock',
            'unshare-network-namespace',
            'kill',
            'ps',
            'crontab',
            'running-crond',
        ],
        'missing_capability_action': 'block-without-installing-or-changing-the-target',
        'repository_refresh_allowed': False,
        'successful_network_access_allowed': False,
        'package_mutation_allowed': False,
        'boot_mutation_allowed': False,
        'reboot_allowed': False,
        'source_change_allowed_on_target': False,
        'persistent_system_configuration_change_allowed': False,
        'scenario_designs': scenario_designs,
        'pre_post_evidence': [
            'installed-package-database-manifest',
            'running-kernel-and-command-line',
            'boot-artifact-fingerprint-set',
            'execution-lock-state',
            'runtime-work-and-log-state',
            'root-crontab-byte-state',
        ],
        'cleanup_requirements': [
            'no-live-test-process',
            'execution-lock-released',
            'temporary-network-namespace-gone',
            'temporary-cron-entry-gone',
            'original-root-crontab-restored-byte-for-byte',
            'temporary-acceptance-runtime-files-removed-or-contained-in-root-only-evidence',
        ],
        'success_rule': 'all-four-scenarios-and-all-three-signal-runs-pass-with-identical-package-and-boot-state-and-clean-control-state',
        'failure_rule': 'stop-the-chain-preserve-evidence-clean-temporary-control-state-and-do-not-proceed-to-family-closure',
    },
    'gates': {
        'acceptance_matrix_complete': False,
        'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
        'c_port_status': 'blocked-by-phase-1-gate',
    },
    'authorization': {
        'target_binding_review_authorized_for_next_stage': True,
        'runtime_executor_implementation_authorized': False,
        'runtime_execution_authorized': False,
        'repository_refresh_authorized': False,
        'network_refresh_authorized': False,
        'package_action_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
    },
    'machine_action_required': False,
    'slackware_current_publication_invalidates_design': False,
    'helper_path': 'tools/reference/phase-1-execution-control-failure-paths-runtime-boundary-design.sh',
    'helper_sha256': helper_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-boundary-design.tsv',
    'next_stage': 'phase-1-execution-control-failure-paths-runtime-target-binding-review',
    'pause_safe': False,
}
Path(out_policy).write_text(json.dumps(policy, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
rows = [
    ('check', 'value'),
    ('accepted_contract_step', '179'),
    ('accepted_contract_policy_sha256', contract_policy_sha),
    ('accepted_contract_record_sha256', contract_record_sha),
    ('selected_family', 'execution-control-failure-paths'),
    ('scenario_count', '4'),
    ('runtime_boundary_design_state', 'frozen'),
    ('target_class', 'slackware-current-runtime-validation-vm'),
    ('target_binding_deferred', 'yes'),
    ('planned_acceptance_executor_path', 'tests/acceptance/reference/test-execution-control-failure-paths.sh'),
    ('planned_execution_acknowledgement', '--execute-runtime-validation'),
    ('privilege_boundary', 'root-via-sudo'),
    ('runtime_evidence_root', '/var/tmp/slack-update-acceptance/execution-control-failure-paths'),
    ('published_archive_path', '/home/promano/slack-update-phase-1-execution-control-failure-paths-evidence.tar.gz'),
    ('published_sha256_path', '/home/promano/slack-update-phase-1-execution-control-failure-paths-evidence.tar.gz.sha256'),
    ('required_network_isolation', 'temporary-network-namespace'),
    ('missing_capability_action', 'block-without-installing-or-changing-the-target'),
    ('repository_refresh_allowed', 'no'),
    ('successful_network_access_allowed', 'no'),
    ('package_mutation_allowed', 'no'),
    ('boot_mutation_allowed', 'no'),
    ('reboot_allowed', 'no'),
    ('source_change_allowed_on_target', 'no'),
    ('persistent_system_configuration_change_allowed', 'no'),
    ('signal_set', 'SIGINT,SIGTERM,SIGHUP'),
    ('signal_expected_statuses', 'SIGINT=130,SIGTERM=143,SIGHUP=129'),
    ('real_cron_required', 'yes'),
    ('root_crontab_exact_restore_required', 'yes'),
    ('acceptance_matrix_complete', 'no'),
    ('target_binding_review_authorized_for_next_stage', 'yes'),
    ('runtime_executor_implementation_authorized', 'no'),
    ('runtime_execution_authorized', 'no'),
    ('repository_refresh_authorized', 'no'),
    ('network_refresh_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('slackware_current_publication_invalidates_design', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-execution-control-failure-paths-runtime-target-binding-review'),
]
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

cat -- "$record"
