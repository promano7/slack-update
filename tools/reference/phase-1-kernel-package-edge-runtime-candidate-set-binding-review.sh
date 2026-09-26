#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-candidate-set-binding-review.sh [--output-dir DIR] [--help]

Freeze the Phase 1 step-214 runtime candidate-set binding contract against the
accepted step-213-r1 fresh runtime identity. This is a repository-only review;
it authorizes no machine, package, Slackpkg, boot, reboot, or network action.
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
step213_policy="$acceptance_dir/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze-policy.json"
step213_record="$acceptance_dir/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze.tsv"
step213_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze.sh"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-candidate-set-binding-review.sh"

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

for required in "$step213_policy" "$step213_record" "$step213_helper" "$helper_path"; do
    require_regular "$required"
done
check_hash "$step213_policy" 'ae790c0b857f64961ed267c19b7db58f33f447c260e0f6659217ddeba32c18eb'
check_hash "$step213_record" 'cad59ab48ed5ea697b130ed084c42c68e51b7ec71212806e24fd33b09ce8ab45'
check_hash "$step213_helper" '7326d5b02b40a2df25ab5b2967fba59405de910075b6febb3422aaceda9b1aa6'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-candidate-set-binding-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-candidate-set-binding-review.tsv"
step213_policy_sha=$(sha256sum -- "$step213_policy" | awk '{print $1}')
step213_record_sha=$(sha256sum -- "$step213_record" | awk '{print $1}')
step213_helper_sha=$(sha256sum -- "$step213_helper" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step213_policy" "$step213_record" "$policy" "$record" \
    "$step213_policy_sha" "$step213_record_sha" "$step213_helper_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p213_path, r213_path, out_policy, out_record = map(Path, sys.argv[1:5])
p213_sha, r213_sha, h213_sha, helper_sha = sys.argv[5:9]
p213 = json.loads(p213_path.read_text(encoding='utf-8'))
with r213_path.open(encoding='utf-8', newline='') as handle:
    r213 = dict(csv.reader(handle, delimiter='\t'))

assert p213['scenario'] == 'phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze'
assert p213['fresh_runtime_identity']['state'] == 'frozen'
assert p213['fresh_runtime_identity']['fresh_candidate_set_bound'] is False
assert p213['candidate_binding_boundary']['predecessor_record'] == 'kernel-headers-6.18.44-x86-1'
assert p213['candidate_binding_boundary']['target_candidate'] == 'kernel-headers-6.18.45-x86-1.txz'
assert p213['authorization']['repository_only_candidate_binding_review_authorized'] is True
assert p213['authorization']['runtime_candidate_binding_authorized'] is False
assert r213['revision'] == 'post-build-revalidation-result-freeze-r1'
assert r213['fresh_candidate_set_bound'] == 'no'

runtime_identity = {
    'target_hostname': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'boot_id': '91901677-1dc3-4a39-a4b1-3f87e6875234',
    'pre_staging_header_record': 'kernel-headers-6.18.45-x86-1',
    'predecessor_record': 'kernel-headers-6.18.44-x86-1',
    'target_record': 'kernel-headers-6.18.45-x86-1',
    'package_database_manifest_sha256': '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
    'slackpkg_conf_sha256': 'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
    'slackpkg_mirrors_sha256': '71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
}

candidate_contract = {
    'binding_time': 'after-predecessor-staging-and-before-reference-apply',
    'binding_lifetime': 'same-runtime-transaction-only',
    'durable_pre_staging_binding_forbidden': True,
    'reason': 'target-is-already-installed-before-staging',
    'expected_upgrade_count': 1,
    'expected_upgrade_package': 'kernel-headers',
    'expected_upgrade_from': 'kernel-headers-6.18.44-x86-1',
    'expected_upgrade_to': 'kernel-headers-6.18.45-x86-1',
    'expected_install_new_count': 0,
    'expected_non_header_upgrade_count': 0,
    'expected_configured_boot_upgrade_count': 0,
    'candidate_source_uri': 'file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source',
    'local_source_target': 'kernel-headers-6.18.45-x86-1.txz',
    'local_source_target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'local_source_tree_manifest_sha256': '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e',
    'runtime_network_access_allowed': False,
}

transaction_contract = {
    'required_order': [
        'revalidate-frozen-runtime-identity',
        'verify-local-source-tree',
        'verify-predecessor-bytes',
        'stage-predecessor-header-only',
        'verify-header-only-package-delta',
        'activate-temporary-local-slackpkg-configuration',
        'refresh-local-source-metadata-only',
        'bind-exact-candidate-set',
        'consume-candidate-set-with-reference-apply-or-rollback',
        'restore-slackpkg-configuration-byte-for-byte',
        'verify-final-target-and-boot-invariants',
    ],
    'candidate_binding_must_be_consumed_without_pause': True,
    'candidate_binding_invalidated_by_any_package_change': True,
    'candidate_binding_invalidated_by_boot_id_change': True,
    'candidate_binding_invalidated_by_local_source_change': True,
    'candidate_binding_invalidated_by_slackpkg_configuration_change': True,
    'predecessor_state_may_not_be_left_as_success_terminal_state': True,
    'failure_requires_target_header_restore': True,
    'boot_package_mutation_allowed': False,
    'boot_configuration_mutation_allowed': False,
    'reboot_allowed': False,
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-candidate-set-binding-review',
    'review_only': True,
    'accepted_step_213_r1': {
        'policy_sha256': p213_sha,
        'record_sha256': r213_sha,
        'helper_sha256': h213_sha,
        'predecessor_record_remediation_consumed': True,
    },
    'frozen_runtime_identity': runtime_identity,
    'candidate_binding_contract': candidate_contract,
    'runtime_transaction_contract': transaction_contract,
    'authorization': {
        'repository_only_runtime_transaction_executor_design_review_authorized': True,
        'runtime_candidate_binding_authorized': False,
        'predecessor_package_transport_authorized': False,
        'predecessor_package_staging_authorized': False,
        'temporary_slackpkg_configuration_authorized': False,
        'local_source_metadata_refresh_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'reference_apply_authorized': False,
        'package_action_authorized': False,
        'network_access_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
    },
    'machine_action_required': False,
    'controller_action_required': False,
    'pause_safe': False,
    'strong_safe_pause': False,
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-runtime-candidate-set-binding-review.sh',
    'helper_sha256': helper_sha,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-executor-design-review',
}

out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step', '214'),
    ('revision', 'runtime-candidate-set-binding-review'),
    ('accepted_step_213_r1_policy_sha256', p213_sha),
    ('accepted_step_213_r1_record_sha256', r213_sha),
    ('fresh_boot_id', runtime_identity['boot_id']),
    ('pre_staging_header_record', runtime_identity['pre_staging_header_record']),
    ('predecessor_record', runtime_identity['predecessor_record']),
    ('target_record', runtime_identity['target_record']),
    ('candidate_binding_time', candidate_contract['binding_time']),
    ('candidate_binding_lifetime', candidate_contract['binding_lifetime']),
    ('durable_pre_staging_binding_forbidden', 'yes'),
    ('expected_upgrade_count', '1'),
    ('expected_upgrade_package', 'kernel-headers'),
    ('expected_upgrade_from', candidate_contract['expected_upgrade_from']),
    ('expected_upgrade_to', candidate_contract['expected_upgrade_to']),
    ('expected_install_new_count', '0'),
    ('expected_non_header_upgrade_count', '0'),
    ('expected_configured_boot_upgrade_count', '0'),
    ('candidate_source_uri', candidate_contract['candidate_source_uri']),
    ('local_source_tree_manifest_sha256', candidate_contract['local_source_tree_manifest_sha256']),
    ('candidate_binding_must_be_consumed_without_pause', 'yes'),
    ('predecessor_state_may_not_be_left_as_success_terminal_state', 'yes'),
    ('repository_only_runtime_transaction_executor_design_review_authorized', 'yes'),
    ('runtime_candidate_binding_authorized', 'no'),
    ('predecessor_package_staging_authorized', 'no'),
    ('temporary_slackpkg_configuration_authorized', 'no'),
    ('local_source_metadata_refresh_authorized', 'no'),
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
with out_record.open('w', encoding='utf-8', newline='') as handle:
    csv.writer(handle, delimiter='\t', lineterminator='\n').writerows(rows)
PY

printf 'candidate_binding_review_status\tPASS\n'
printf 'candidate_binding_time\tafter-predecessor-staging-and-before-reference-apply\n'
printf 'candidate_binding_lifetime\tsame-runtime-transaction-only\n'
printf 'expected_upgrade_count\t1\n'
printf 'runtime_candidate_binding_authorized\tno\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-executor-design-review\n'
