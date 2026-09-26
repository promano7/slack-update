#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review.sh [--output-dir DIR] [--help]

Generate the Phase 1 step-217 repository-only runtime authorization review for
the exact reviewed kernel-package-edge transaction executor. This helper does
not copy artifacts, execute the runtime transaction, mutate packages or
Slackpkg state, access the network, modify boot state, or reboot.
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
step216_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review-policy.json"
step216_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.tsv"
step216_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.sh"
step216_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.md"
step216_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review-harness.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-executor.sh"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review.sh"

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

for required in "$step216_policy" "$step216_record" "$step216_helper" "$step216_doc" "$step216_harness" "$executor" "$builder" "$acceptance_harness" "$helper_path"; do
    require_regular "$required"
done
check_hash "$step216_policy" 'ee0901faf8adf44cc0eb3d54b7e2711e6e02c55c2b83a651beee824b342d837a'
check_hash "$step216_record" 'ae9a83777002c8392d7d38f3fab7c82cd20b87a4d7c835d23fe8f428e8b080e7'
check_hash "$step216_helper" '2fa4d0bf124935180bff3ab88dc0c27204c03e05096b3809804d022169b11224'
check_hash "$step216_doc" 'f12ff624f98b052246803bd336bafde63f368a78373269ced11f6af6cec050e5'
check_hash "$step216_harness" '068c232265a10efaae255de13d932e9c49fff2b5ac964e2647b400ef9bd58ac0'
check_hash "$executor" '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300'
check_hash "$builder" '348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea'
check_hash "$acceptance_harness" 'c9c15fbccd07ec3f74bb29784eff06092ca4fd501d5236996e2c21d6c34ec577'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step216_policy" "$step216_record" "$policy" "$record" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p216_path, r216_path, out_policy, out_record = map(Path, sys.argv[1:5])
helper_sha = sys.argv[5]
p216 = json.loads(p216_path.read_text(encoding='utf-8'))
with r216_path.open(encoding='utf-8', newline='') as handle:
    r216 = dict(csv.reader(handle, delimiter='\t'))

assert p216['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review'
assert p216['implementation']['state'] == 'implemented-reviewed-awaiting-runtime-authorization'
assert p216['implementation']['canonical_executor_sha256'] == '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300'
assert p216['implementation']['repository_acceptance_result'] == 'PASS (69 passes, 0 failures)'
assert p216['authorization']['repository_only_runtime_authorization_review_authorized'] is True
assert p216['authorization']['runtime_scenario_execution_authorized'] is False
assert r216['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review'

impl = p216['implementation']
guards = p216['reviewed_runtime_guards']
policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review',
    'review_only': True,
    'accepted_step_216': {
        'policy_sha256': 'ee0901faf8adf44cc0eb3d54b7e2711e6e02c55c2b83a651beee824b342d837a',
        'record_sha256': 'ae9a83777002c8392d7d38f3fab7c82cd20b87a4d7c835d23fe8f428e8b080e7',
        'helper_sha256': '2fa4d0bf124935180bff3ab88dc0c27204c03e05096b3809804d022169b11224',
        'document_sha256': 'f12ff624f98b052246803bd336bafde63f368a78373269ced11f6af6cec050e5',
        'review_harness_sha256': '068c232265a10efaae255de13d932e9c49fff2b5ac964e2647b400ef9bd58ac0',
        'repository_acceptance_harness_sha256': impl['repository_acceptance_harness_sha256'],
        'repository_acceptance_result': impl['repository_acceptance_result'],
    },
    'runtime_authorization': {
        'state': 'accepted-single-runtime-transaction-pending-execution',
        'authorization_scope': 'single-bounded-kernel-header-edge-runtime-transaction',
        'execution_target': 'vbox-slackcurrent.vbox-slackcurrent.org',
        'required_running_kernel': '6.18.45',
        'required_boot_id': impl['boot_id'],
        'required_package_database_manifest_sha256': impl['package_database_manifest_sha256'],
        'executor': {
            'repository_path': impl['canonical_executor_path'],
            'sha256': impl['canonical_executor_sha256'],
            'target_transport_path': '/home/promano/Descargas/phase-1-kernel-package-edge-runtime-transaction-executor.sh',
            'must_be_regular_non_symlink': True,
            'target_hash_verification_required_before_execution': True,
            'rebuild_before_transport_authorized': False,
        },
        'predecessor': {
            'artifact': 'kernel-headers-6.18.44-x86-1.txz',
            'record': impl['predecessor_record'],
            'sha256': impl['predecessor_sha256'],
            'controller_source': '/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts/kernel-headers-6.18.44-x86-1.txz',
            'target_transport_path': '/home/promano/Descargas/kernel-headers-6.18.44-x86-1.txz',
            'must_be_regular_non_symlink': True,
            'controller_hash_verification_required_before_transport': True,
            'target_hash_verification_required_before_execution': True,
            'redownload_authorized': False,
        },
        'exact_execution_command': 'sudo bash phase-1-kernel-package-edge-runtime-transaction-executor.sh --execute-runtime-validation',
        'runtime_acknowledgement': impl['runtime_acknowledgement'],
        'transaction_lifetime': 'single-execution-authority-consumed-on-runtime-start',
        'candidate_binding_lifetime': guards['candidate_binding_lifetime'],
        'preflight_must_complete_before_first_mutation': True,
        'drift_action': 'abort-before-first-mutation-and-return-to-revalidation-review',
        'authorization_invalidated_by': [
            'executor-byte-drift',
            'predecessor-byte-drift',
            'fqdn-drift',
            'running-kernel-drift',
            'boot-id-drift',
            'package-database-manifest-drift',
            'slackpkg-configuration-drift',
            'staged-target-drift',
            'local-source-tree-drift',
            'preexisting-runtime-evidence-root',
        ],
        'bounded_mutation': {
            'temporary_predecessor_staging_authorized': True,
            'temporary_slackpkg_configuration_authorized': True,
            'local_file_source_metadata_refresh_authorized': True,
            'single_candidate_binding_authorized': True,
            'frozen_reference_apply_authorized': True,
            'package_mutation_scope': 'kernel-headers-6.18.45-to-6.18.44-to-6.18.45-only',
            'external_network_access_authorized': False,
            'boot_action_authorized': False,
            'reboot_authorized': False,
            'persistent_configuration_change_authorized': False,
        },
        'required_final_state': {
            'header_record': impl['target_record'],
            'package_database_manifest_sha256': impl['package_database_manifest_sha256'],
            'boot_id': impl['boot_id'],
            'running_kernel': '6.18.45',
            'local_source_tree_manifest_sha256': impl['local_source_tree_manifest_sha256'],
            'predecessor_terminal_state_forbidden': True,
            'slackpkg_configuration_and_state_restored': True,
            'geninitrd_policy_restored': True,
            'boot_artifacts_unchanged': True,
            'reboot_performed': False,
        },
        'evidence': {
            'published_archive': '/home/promano/slack-update-phase-1-kernel-package-edge-runtime-evidence.tar.gz',
            'published_sha256': '/home/promano/slack-update-phase-1-kernel-package-edge-runtime-evidence.tar.gz.sha256',
            'publication_required_for_result_review': True,
            'result_review_required_before_any_further_machine_action': True,
        },
    },
    'authorization': {
        'runtime_executor_build_authorized': False,
        'runtime_executor_transport_authorized': True,
        'predecessor_package_transport_authorized': True,
        'predecessor_package_redownload_authorized': False,
        'predecessor_package_staging_authorized': True,
        'temporary_slackpkg_configuration_authorized': True,
        'local_source_metadata_refresh_authorized': True,
        'runtime_candidate_binding_authorized': True,
        'reference_apply_authorized': True,
        'runtime_scenario_execution_authorized': True,
        'package_action_authorized': True,
        'generic_repository_refresh_authorized': False,
        'external_network_access_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
    },
    'machine_action_required': True,
    'controller_action_required': True,
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review.sh',
    'helper_sha256': helper_sha,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-validation-result-review',
    'pause_safe': False,
    'strong_safe_pause': False,
}
Path(out_policy).write_text(json.dumps(policy, indent=2) + '\n', encoding='utf-8')
rows = [
    ('step','217'),
    ('revision','runtime-transaction-executor-runtime-authorization-review'),
    ('accepted_step_216_policy_sha256',policy['accepted_step_216']['policy_sha256']),
    ('accepted_step_216_record_sha256',policy['accepted_step_216']['record_sha256']),
    ('repository_acceptance_result',impl['repository_acceptance_result']),
    ('runtime_authorization_state',policy['runtime_authorization']['state']),
    ('runtime_authorization_scope',policy['runtime_authorization']['authorization_scope']),
    ('target_hostname',policy['runtime_authorization']['execution_target']),
    ('required_running_kernel','6.18.45'),
    ('required_boot_id',impl['boot_id']),
    ('canonical_executor_sha256',impl['canonical_executor_sha256']),
    ('executor_target_transport_path',policy['runtime_authorization']['executor']['target_transport_path']),
    ('predecessor_record',impl['predecessor_record']),
    ('predecessor_sha256',impl['predecessor_sha256']),
    ('predecessor_target_transport_path',policy['runtime_authorization']['predecessor']['target_transport_path']),
    ('runtime_acknowledgement',impl['runtime_acknowledgement']),
    ('candidate_binding_lifetime',guards['candidate_binding_lifetime']),
    ('runtime_executor_build_authorized','no'),
    ('runtime_executor_transport_authorized','yes'),
    ('predecessor_package_transport_authorized','yes'),
    ('predecessor_package_staging_authorized','yes'),
    ('runtime_candidate_binding_authorized','yes'),
    ('reference_apply_authorized','yes'),
    ('runtime_scenario_execution_authorized','yes'),
    ('package_action_authorized','yes-bounded-header-transition-only'),
    ('external_network_access_authorized','no'),
    ('boot_action_authorized','no'),
    ('reboot_authorized','no'),
    ('machine_action_required','yes'),
    ('controller_action_required','yes'),
    ('pause_safe','no'),
    ('strong_safe_pause','no'),
    ('next_stage','phase-1-kernel-package-edge-runtime-transaction-validation-result-review'),
]
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

printf 'Step 217 runtime transaction executor authorization review completed successfully\n'
