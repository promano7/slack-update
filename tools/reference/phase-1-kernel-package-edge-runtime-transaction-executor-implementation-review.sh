#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.sh [--output-dir DIR] [--help]

Freeze the Phase 1 step-216 repository implementation review for the
kernel-package-edge runtime transaction executor. This helper performs no
runtime build, transport, package, Slackpkg, network, boot, or reboot action.
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
step215_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-design-review-policy.json"
step215_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-design-review.tsv"
step215_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-design-review.sh"
builder="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh"
body="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh"
executor="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-executor.sh"
doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.md"
reference="$repo_root/tools/reference/slack-update-reference.sh"
config="$repo_root/data/config/slack-update.conf"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.sh"

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
        printf 'ERROR: reviewed SHA-256 mismatch: %s\nexpected: %s\nactual:   %s\n' \
            "$file" "$expected" "$actual" >&2
        exit 4
    }
}

for required in "$step215_policy" "$step215_record" "$step215_helper" "$builder" "$body" "$executor" "$acceptance_harness" "$doc" "$reference" "$config" "$helper_path"; do
    require_regular "$required"
done
check_hash "$step215_policy" '7744fd2e3c55af9d9903a6d3e5000d2447342d05b0a3dec6b582c5544973e0e6'
check_hash "$step215_record" 'cf2ad02bc99f8b51e8589a8f02a693e87b2d4317afb14ae6395baf90d07fc732'
check_hash "$step215_helper" 'f49db1dd4e7406a53d10ae2ffe6fd7c15249f4f91565af136772ff7c049d28e7'
check_hash "$builder" '348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea'
check_hash "$body" '47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581'
check_hash "$executor" '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300'
check_hash "$acceptance_harness" 'c9c15fbccd07ec3f74bb29784eff06092ca4fd501d5236996e2c21d6c34ec577'
check_hash "$doc" 'f12ff624f98b052246803bd336bafde63f368a78373269ced11f6af6cec050e5'
check_hash "$reference" '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
check_hash "$config" '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step215_policy" "$step215_record" "$policy" "$record" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p215_path, r215_path, out_policy, out_record = map(Path, sys.argv[1:5])
helper_sha = sys.argv[5]
p215 = json.loads(p215_path.read_text(encoding='utf-8'))
with r215_path.open(encoding='utf-8', newline='') as handle:
    r215 = dict(csv.reader(handle, delimiter='\t'))

assert p215['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-executor-design-review'
assert p215['runtime_transaction_executor_design']['state'] == 'reviewed'
assert p215['authorization']['repository_only_runtime_transaction_executor_implementation_review_authorized'] is True
assert p215['authorization']['runtime_scenario_execution_authorized'] is False
assert r215['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review'

design = p215['runtime_transaction_executor_design']
policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review',
    'review_only': True,
    'accepted_step_215': {
        'policy_sha256': '7744fd2e3c55af9d9903a6d3e5000d2447342d05b0a3dec6b582c5544973e0e6',
        'record_sha256': 'cf2ad02bc99f8b51e8589a8f02a693e87b2d4317afb14ae6395baf90d07fc732',
        'helper_sha256': 'f49db1dd4e7406a53d10ae2ffe6fd7c15249f4f91565af136772ff7c049d28e7',
        'design_state': design['state'],
        'same_transaction_candidate_lifetime': design['candidate_guard']['binding_lifetime'],
    },
    'implementation': {
        'state': 'implemented-reviewed-awaiting-runtime-authorization',
        'family': 'kernel-package-edge',
        'builder_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-build.sh',
        'builder_sha256': '348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea',
        'executor_body_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-body.sh',
        'executor_body_sha256': '47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581',
        'canonical_executor_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh',
        'canonical_executor_sha256': '09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300',
        'repository_acceptance_harness_path': 'tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-executor.sh',
        'repository_acceptance_harness_sha256': 'c9c15fbccd07ec3f74bb29784eff06092ca4fd501d5236996e2c21d6c34ec577',
        'repository_acceptance_result': 'PASS (69 passes, 0 failures)',
        'reference_script_sha256': '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415',
        'effective_config_sha256': '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba',
        'target_requires_repository': False,
        'runtime_acknowledgement': '--execute-runtime-validation',
        'payload_reproducibility': 'builder-output-must-match-canonical-executor-byte-for-byte',
        'predecessor_transport_separate': True,
        'predecessor_record': 'kernel-headers-6.18.44-x86-1',
        'predecessor_sha256': '3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d',
        'target_record': 'kernel-headers-6.18.45-x86-1',
        'target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
        'boot_id': '91901677-1dc3-4a39-a4b1-3f87e6875234',
        'package_database_manifest_sha256': '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
        'local_source_tree_manifest_sha256': '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e',
    },
    'reviewed_runtime_guards': {
        'preflight_before_package_or_slackpkg_mutation': True,
        'cleanup_trap_before_predecessor_staging': True,
        'header_only_staging_delta_required': True,
        'secondary_modules_disabled_only_in_derived_config': True,
        'boot_mode_preserved_auto': True,
        'candidate_refresh_in_network_namespace': True,
        'reference_apply_in_network_namespace': True,
        'external_network_access_allowed': False,
        'candidate_binding_lifetime': 'same-runtime-transaction-only',
        'expected_upgrade_count': 1,
        'expected_install_new_count': 0,
        'expected_non_header_upgrade_count': 0,
        'expected_configured_boot_upgrade_count': 0,
        'reference_kernel_trigger_required': True,
        'reference_external_module_warning_required': True,
        'reference_grub_action_forbidden': True,
        'reference_initrd_action_forbidden': True,
        'failure_restores_target_header': True,
        'slackpkg_configuration_and_state_restore_required': True,
        'geninitrd_policy_restore_required': True,
        'boot_artifact_fingerprint_must_be_unchanged': True,
        'final_package_database_manifest_must_match_frozen_baseline': True,
        'evidence_publication_only_after_final_restoration_gate': True,
        'predecessor_terminal_state_forbidden': True,
        'reboot_forbidden': True,
    },
    'authorization': {
        'repository_only_runtime_authorization_review_authorized': True,
        'runtime_executor_build_authorized': False,
        'runtime_executor_transport_authorized': False,
        'predecessor_package_transport_authorized': False,
        'predecessor_package_staging_authorized': False,
        'temporary_slackpkg_configuration_authorized': False,
        'local_source_metadata_refresh_authorized': False,
        'runtime_candidate_binding_authorized': False,
        'reference_apply_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'package_action_authorized': False,
        'network_access_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
    },
    'machine_action_required': False,
    'controller_action_required': False,
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review.sh',
    'helper_sha256': helper_sha,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review',
    'pause_safe': False,
    'strong_safe_pause': False,
}
Path(out_policy).write_text(json.dumps(policy, indent=2) + '\n', encoding='utf-8')
rows = [
    ('step', '216'),
    ('revision', 'runtime-transaction-executor-implementation-review'),
    ('accepted_step_215_policy_sha256', policy['accepted_step_215']['policy_sha256']),
    ('accepted_step_215_record_sha256', policy['accepted_step_215']['record_sha256']),
    ('accepted_step_215_helper_sha256', policy['accepted_step_215']['helper_sha256']),
    ('implementation_state', policy['implementation']['state']),
    ('builder_sha256', policy['implementation']['builder_sha256']),
    ('executor_body_sha256', policy['implementation']['executor_body_sha256']),
    ('canonical_executor_sha256', policy['implementation']['canonical_executor_sha256']),
    ('repository_acceptance_harness_sha256', policy['implementation']['repository_acceptance_harness_sha256']),
    ('repository_acceptance_result', policy['implementation']['repository_acceptance_result']),
    ('reference_script_sha256', policy['implementation']['reference_script_sha256']),
    ('effective_config_sha256', policy['implementation']['effective_config_sha256']),
    ('fresh_boot_id', policy['implementation']['boot_id']),
    ('predecessor_record', policy['implementation']['predecessor_record']),
    ('target_record', policy['implementation']['target_record']),
    ('payload_reproducible', 'yes'),
    ('target_requires_repository', 'no'),
    ('candidate_binding_lifetime', 'same-runtime-transaction-only'),
    ('expected_upgrade_count', '1'),
    ('expected_install_new_count', '0'),
    ('expected_non_header_upgrade_count', '0'),
    ('expected_configured_boot_upgrade_count', '0'),
    ('rollback_guard_reviewed', 'yes'),
    ('network_namespace_reviewed', 'yes'),
    ('runtime_executor_build_authorized', 'no'),
    ('runtime_executor_transport_authorized', 'no'),
    ('predecessor_package_transport_authorized', 'no'),
    ('predecessor_package_staging_authorized', 'no'),
    ('runtime_candidate_binding_authorized', 'no'),
    ('reference_apply_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('network_access_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('controller_action_required', 'no'),
    ('pause_safe', 'no'),
    ('strong_safe_pause', 'no'),
    ('next_stage', policy['next_stage']),
]
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    csv.writer(handle, delimiter='\t', lineterminator='\n').writerows(rows)
PY

printf 'Step 216 runtime transaction executor implementation review completed successfully\n'
