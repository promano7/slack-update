#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-boundary-design.sh [--output-dir DIR] [--help]

Freeze the non-mutating runtime-boundary design for the selected Phase 1
kernel-package-edge acceptance scenario. This helper does not bind a machine,
package pair, or repository snapshot and does not authorize runtime execution.
It records the controlled header-only transition strategy, candidate guard,
evidence contract, rollback requirements, and next target-binding review gate.
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
contract_policy="$acceptance_dir/phase-1-kernel-package-edge-contract-freeze-policy.json"
contract_record="$acceptance_dir/phase-1-kernel-package-edge-contract-freeze.tsv"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-boundary-design.sh"

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
check_hash "$contract_policy" '95f065e015106467e25f81d1cb9c4199967edd51aee821ed70d3001c301a35fc'
check_hash "$contract_record" 'ab90fa4f61dd5de7db5fe76cebcd72adfe7d25c95d6925aeb1c67bd09db7f28d'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-boundary-design-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-boundary-design.tsv"
contract_policy_sha=$(sha256sum -- "$contract_policy" | awk '{print $1}')
contract_record_sha=$(sha256sum -- "$contract_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$contract_policy" "$contract_record" "$policy" "$record" \
    "$contract_policy_sha" "$contract_record_sha" "$helper_sha" <<'PY_INNER'
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
assert contract['scenario'] == 'phase-1-kernel-package-edge-contract-freeze'
assert contract['contract']['state'] == 'frozen'
assert contract['contract']['family'] == 'kernel-package-edge'
assert contract['contract']['scenario_count'] == 1
assert contract['contract']['scenario']['id'] == 'kernel-headers-update-without-kernel-boot-package-update'
assert contract['contract']['scenario']['kernel_trigger_expected'] is True
assert contract['contract']['scenario']['initrd_update_expected'] is False
assert contract['contract']['scenario']['grub_update_expected'] is False
assert contract['contract']['target_binding_deferred'] is True
assert contract['contract']['package_source_binding_deferred'] is True
assert contract_record['selected_family'] == 'kernel-package-edge'
assert contract_record['scenario_count'] == '1'
assert contract_record['contract_state'] == 'frozen'

transition = {
    'strategy': 'controlled-predecessor-stage-then-reference-upgrade-against-immutable-local-slackpkg-source',
    'official_package_artifacts_required': True,
    'predecessor_artifact_role': 'temporarily-stage-only-the-selected-configured-kernel-header-package-behind-the-bound-target-version',
    'target_artifact_role': 'provide-the-bound-official-header-package-version-returned-by-the-reference-apply',
    'exact_package_pair_binding_deferred': True,
    'package_pair_must_share_slackware_package_name': True,
    'predecessor_must_differ_from_target': True,
    'boot_packages_must_already_match_target_source_before-staging': True,
    'staging_package_mutation_must_touch_only_selected_header_package': True,
    'tested_transition_must_be_performed_by_reference_apply': True,
    'reference_apply_path': 'tools/reference/slack-update-reference.sh',
    'reference_apply_mode': '--apply',
    'source_strategy': 'immutable-local-slackpkg-compatible-source',
    'source_must_be_network-independent_during-runtime': True,
    'source_metadata_and_target_package_must_be_hash-bound': True,
    'candidate_guard': 'after-local-source-refresh-exactly-one-upgrade-candidate-and-it-is-the-selected-kernel-header-package',
    'install_new_candidate_count_required': 0,
    'non_header_upgrade_candidate_count_required': 0,
    'kernel_boot_upgrade_candidate_count_required': 0,
    'candidate_guard_failure_action': 'abort-before-reference-apply-and-restore-pre-test-state',
}

evidence = {
    'pre_baseline': [
        'target-identity-and-boot-id',
        'reference-script-sha256-and-effective-configuration-sha256',
        'configured-kernel-header-and-kernel-boot-package-sets',
        'installed-package-snapshot',
        'running-kernel',
        'boot-artifact-fingerprint-set',
        'slackpkg-configuration-and-state-fingerprints',
    ],
    'bound_source': [
        'predecessor-package-filename-version-and-sha256',
        'target-package-filename-version-and-sha256',
        'local-source-metadata-sha256-set',
        'proof-both-package-artifacts-are-official-slackware-current-packages',
    ],
    'staged_precondition': [
        'only-selected-header-package-differs-from-baseline',
        'all-configured-kernel-boot-packages-still-match-baseline',
        'candidate-guard-exactly-one-header-upgrade',
        'running-kernel-unchanged',
        'boot-artifact-fingerprints-unchanged',
    ],
    'reference_transition': [
        'reference-standard-output-and-standard-error',
        'reference-exit-status',
        'before-and-after-package-snapshots',
        'kernel-trigger-equals-one',
        'initrd-update-equals-zero',
        'grub-update-equals-zero',
        'external-module-warning-observed',
        'no-boot-preparation-action-observed',
    ],
    'final_state': [
        'selected-header-package-restored-to-bound-target-version',
        'zero-configured-kernel-boot-package-delta',
        'running-kernel-unchanged',
        'boot-artifact-fingerprints-unchanged',
        'original-slackpkg-configuration-restored-byte-for-byte',
        'temporary-source-and-runtime-artifacts-clean-or-contained-in-evidence',
        'final-package-state-coherent',
    ],
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-boundary-design',
    'review_only': True,
    'accepted_contract': {
        'step': 191,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-contract-freeze-policy.json',
        'policy_sha256': contract_policy_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-contract-freeze.tsv',
        'record_sha256': contract_record_sha,
        'family': 'kernel-package-edge',
        'scenario_count': 1,
    },
    'runtime_boundary_design': {
        'state': 'frozen',
        'target_class': 'slackware-current-runtime-validation-vm',
        'target_binding_deferred': True,
        'package_pair_binding_deferred': True,
        'local_source_binding_deferred': True,
        'live_candidate_set_bound': False,
        'live_runtime_chain_open': False,
        'planned_acceptance_executor_path': 'tests/acceptance/reference/test-kernel-package-edge.sh',
        'planned_execution_acknowledgement': '--execute-runtime-validation',
        'privilege_boundary': 'root-via-sudo',
        'runtime_evidence_root': '/var/tmp/slack-update-acceptance/kernel-package-edge',
        'published_archive_path': '/home/promano/slack-update-phase-1-kernel-package-edge-evidence.tar.gz',
        'published_sha256_path': '/home/promano/slack-update-phase-1-kernel-package-edge-evidence.tar.gz.sha256',
        'published_owner': 'promano:users',
        'published_mode': '0600',
        'required_capabilities': [
            'bash',
            'python3',
            'sha256sum',
            'tar',
            'flock',
            'slackpkg',
            'upgradepkg',
            'pkgtools-package-database',
        ],
        'missing_capability_action': 'block-without-installing-or-changing-the-target',
        'transition': transition,
        'evidence': evidence,
        'configuration_restore_rule': 'all-temporary-slackpkg-configuration-changes-must-be-restored-byte-for-byte',
        'boot_mutation_allowed': False,
        'boot_configuration_mutation_allowed': False,
        'reboot_allowed': False,
        'network_access_during_runtime_allowed': False,
        'unrelated_package_mutation_allowed': False,
        'setup_header_package_mutation_may_be_authorized_later': True,
        'reference_header_package_mutation_may_be_authorized_later': True,
        'rollback_rule': 'on-any-failure-restore-bound-target-header-package-and-original-slackpkg-configuration-preserve-evidence-and-stop-the-chain',
        'success_rule': 'reference-apply-observes-exact-header-only-delta-with-kernel-trigger-one-initrd-zero-grub-zero-and-identical-boot-state',
    },
    'gates': {
        'acceptance_matrix_complete': False,
        'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
        'c_port_status': 'blocked-by-phase-1-gate',
    },
    'authorization': {
        'target_binding_review_authorized_for_next_stage': True,
        'package_pair_binding_authorized': False,
        'local_source_binding_authorized': False,
        'runtime_executor_implementation_authorized': False,
        'runtime_execution_authorized': False,
        'repository_refresh_authorized': False,
        'network_refresh_authorized': False,
        'machine_execution_authorized': False,
        'package_action_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
    },
    'machine_action_required': False,
    'slackware_current_publication_invalidates_design': False,
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-boundary-design.sh',
    'helper_sha256': helper_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-boundary-design.tsv',
    'next_stage': 'phase-1-kernel-package-edge-runtime-target-binding-review',
    'pause_safe': False,
}

Path(out_policy).write_text(json.dumps(policy, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
rows = [
    ('check', 'value'),
    ('accepted_contract_step', '191'),
    ('accepted_contract_policy_sha256', contract_policy_sha),
    ('accepted_contract_record_sha256', contract_record_sha),
    ('selected_family', 'kernel-package-edge'),
    ('scenario_count', '1'),
    ('runtime_boundary_design_state', 'frozen'),
    ('target_class', 'slackware-current-runtime-validation-vm'),
    ('target_binding_deferred', 'yes'),
    ('package_pair_binding_deferred', 'yes'),
    ('local_source_binding_deferred', 'yes'),
    ('live_candidate_set_bound', 'no'),
    ('live_runtime_chain_open', 'no'),
    ('transition_strategy', transition['strategy']),
    ('source_strategy', transition['source_strategy']),
    ('network_access_during_runtime_allowed', 'no'),
    ('official_package_artifacts_required', 'yes'),
    ('staging_mutation_scope', 'selected-configured-kernel-header-package-only'),
    ('tested_transition_performed_by_reference_apply', 'yes'),
    ('reference_apply_path', transition['reference_apply_path']),
    ('reference_apply_mode', transition['reference_apply_mode']),
    ('candidate_guard', transition['candidate_guard']),
    ('install_new_candidate_count_required', '0'),
    ('non_header_upgrade_candidate_count_required', '0'),
    ('kernel_boot_upgrade_candidate_count_required', '0'),
    ('candidate_guard_failure_action', transition['candidate_guard_failure_action']),
    ('boot_mutation_allowed', 'no'),
    ('boot_configuration_mutation_allowed', 'no'),
    ('reboot_allowed', 'no'),
    ('unrelated_package_mutation_allowed', 'no'),
    ('configuration_restore_rule', 'byte-for-byte'),
    ('planned_acceptance_executor_path', 'tests/acceptance/reference/test-kernel-package-edge.sh'),
    ('planned_execution_acknowledgement', '--execute-runtime-validation'),
    ('runtime_evidence_root', '/var/tmp/slack-update-acceptance/kernel-package-edge'),
    ('published_archive_path', '/home/promano/slack-update-phase-1-kernel-package-edge-evidence.tar.gz'),
    ('rollback_rule', 'restore-target-header-and-original-slackpkg-configuration-preserve-evidence-stop'),
    ('acceptance_matrix_complete', 'no'),
    ('target_binding_review_authorized_for_next_stage', 'yes'),
    ('package_pair_binding_authorized', 'no'),
    ('local_source_binding_authorized', 'no'),
    ('runtime_executor_implementation_authorized', 'no'),
    ('runtime_execution_authorized', 'no'),
    ('repository_refresh_authorized', 'no'),
    ('network_refresh_authorized', 'no'),
    ('machine_execution_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('slackware_current_publication_invalidates_design', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-kernel-package-edge-runtime-target-binding-review'),
]
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY_INNER

cat -- "$record"
