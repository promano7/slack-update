#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review.sh [--output-dir DIR] [--help]

Open a fresh repository-only planning boundary after the accepted Phase 1
step-250 local-source-v3 build strong safe pause. Bind the already frozen
executor-v2 contract to the accepted v3 manifest identity, preserve all
accepted and historical evidence, expire prior live target identity, and grant
no operational authority.
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
step250_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause.sh"
step250_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause.md"
step250_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause-harness.sh"
step250_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause-policy.json"
step250_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause.tsv"
step246_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze-policy.json"
step246_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze.tsv"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}

check_hash() {
    local file=$1 expected=$2 actual
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: accepted prerequisite SHA-256 mismatch: %s\nexpected: %s\nactual:   %s\n' "$file" "$expected" "$actual" >&2
        exit 4
    }
}

for required in \
    "$step250_helper" "$step250_doc" "$step250_harness" "$step250_policy" "$step250_record" \
    "$step246_policy" "$step246_record" "$helper_path"; do
    require_regular "$required"
done

check_hash "$step250_helper" '42d9f34ab315435d121f2b03660330ffefc4620600af090ad16df557ab0da948'
check_hash "$step250_doc" '23f19c62e16624e077f01b892115c7549d5b4c64a9901bbeb37791490efaa1f6'
check_hash "$step250_harness" 'c82edeafd56a3e7f55d4ea65def0b60ae0469e93583266d5d62e128e82d53768'
check_hash "$step250_policy" '66cad52375c1d3945c90af3ece869dd5a3178a3a9e6875e0ba76bbf458a52a0c'
check_hash "$step250_record" '45a23c6f33a34d834dbfdb569045f33ea87e21cab04033579eaebe31303f4701'
check_hash "$step246_policy" 'cf32f3d6b5df64d176c154e506c356c53e63da794c961edbbcbf1557ecef25f0'
check_hash "$step246_record" '2f55b4a83a498fdf1c347ba2f35c25b5b0a3a87233f3df66f2362cfa12491071'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review.tsv"
step250_helper_sha=$(sha256sum -- "$step250_helper" | awk '{print $1}')
step250_doc_sha=$(sha256sum -- "$step250_doc" | awk '{print $1}')
step250_harness_sha=$(sha256sum -- "$step250_harness" | awk '{print $1}')
step250_policy_sha=$(sha256sum -- "$step250_policy" | awk '{print $1}')
step250_record_sha=$(sha256sum -- "$step250_record" | awk '{print $1}')
step246_policy_sha=$(sha256sum -- "$step246_policy" | awk '{print $1}')
step246_record_sha=$(sha256sum -- "$step246_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step250_policy" "$step250_record" "$step246_policy" "$step246_record" "$policy" "$record" \
    "$step250_helper_sha" "$step250_doc_sha" "$step250_harness_sha" "$step250_policy_sha" "$step250_record_sha" \
    "$step246_policy_sha" "$step246_record_sha" "$helper_sha" <<'PY'
import copy
import csv
import json
import sys
from pathlib import Path

p250_path = Path(sys.argv[1])
r250_path = Path(sys.argv[2])
p246_path = Path(sys.argv[3])
r246_path = Path(sys.argv[4])
out_policy = Path(sys.argv[5])
out_record = Path(sys.argv[6])
(
    helper250_sha,
    doc250_sha,
    harness250_sha,
    policy250_sha,
    record250_sha,
    policy246_sha,
    record246_sha,
    helper_sha,
) = sys.argv[7:15]

p250 = json.loads(p250_path.read_text(encoding='utf-8'))
p246 = json.loads(p246_path.read_text(encoding='utf-8'))
with r250_path.open(encoding='utf-8', newline='') as handle:
    r250 = dict(csv.reader(handle, delimiter='\t'))
with r246_path.open(encoding='utf-8', newline='') as handle:
    r246 = dict(csv.reader(handle, delimiter='\t'))

assert p250['schema'] == 1
assert p250['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause'
assert p250['step'] == 250
assert p250['review_status'] == 'PASS'
assert p250['strong_safe_pause'] is True
assert p250['pause_safe'] is True
assert p250['safe_pause']['strong_safe_pause'] is True
assert p250['safe_pause']['no_open_operational_authorization'] is True
assert p250['accepted_local_source_v3']['state'] == 'built-accepted-preserve-unchanged'
assert p250['accepted_local_source_v3']['tree_manifest_sha256'] == '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'
assert p250['accepted_local_source_v3']['target_sha256'] == 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert p250['builder_implementation']['builder_sha256'] == '80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30'
assert p250['runtime_boundary_after_pause']['fresh_target_revalidation_required_before_any_machine_action'] is True
assert p250['runtime_boundary_after_pause']['local_source_v3_tree_revalidation_required_before_executor_implementation_or_runtime_use'] is True
assert p250['runtime_boundary_after_pause']['accepted_v3_manifest_identity_required_before_executor_v2_implementation'] is True
assert p250['runtime_boundary_after_pause']['fresh_candidate_set_required_before_runtime'] is True
assert p250['future_executor_v2_state'] == 'reviewed-frozen-not-implemented'
assert p250['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review'
assert r250['step'] == '250'
assert r250['strong_safe_pause'] == 'yes'
assert r250['pause_safe'] == 'yes'
assert r250['no_open_operational_authorization'] == 'yes'
assert r250['build_authority_consumed'] == 'yes'
assert r250['target_observation_authorized'] == 'no'
assert r250['runtime_executor_v2_implementation_authorized'] == 'no'
assert r250['runtime_rerun_authorized'] == 'no'
for key, value in p250['authorization'].items():
    assert value is False, (key, value)

assert p246['schema'] == 1
assert p246['step'] == 246
assert p246['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze'
executor_contract = copy.deepcopy(p246['future_executor_v2_contract'])
assert executor_contract['state'] == 'reviewed-frozen-not-implemented'
assert executor_contract['source_generation'] == 'local-source-v3'
assert executor_contract['implementation_must_wait_for_accepted_v3_manifest_identity'] is True
assert executor_contract['refresh_success_contract']['human_spaced_error_prefix'] == 'Error downloading from '
assert executor_contract['refresh_success_contract']['hyphenated_literal_guard_forbidden'] is True
assert executor_contract['refresh_success_contract']['fresh_transaction_owned_pkglist_required'] is True
assert executor_contract['refresh_success_contract']['same_transaction_candidate_binding_required'] is True
assert r246['step'] == '246'

accepted_v3 = copy.deepcopy(p250['accepted_local_source_v3'])
accepted_v3['state'] = 'built-accepted-preserve-unchanged-resume-boundary'

executor_contract['accepted_local_source_v3_tree_manifest_sha256'] = p250['accepted_local_source_v3']['tree_manifest_sha256']
executor_contract['accepted_target_sha256'] = p250['accepted_local_source_v3']['target_sha256']
executor_contract['manifest_identity_binding_state'] = 'bound-for-future-implementation-after-fresh-revalidation'
executor_contract['implementation_authorized_now'] = False
executor_contract['runtime_authorized_now'] = False

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review',
    'step': 251,
    'review_only': True,
    'review_status': 'PASS',
    'accepted_checkpoint': {
        'step': 250,
        'helper_sha256': helper250_sha,
        'document_sha256': doc250_sha,
        'harness_sha256': harness250_sha,
        'policy_sha256': policy250_sha,
        'record_sha256': record250_sha,
        'strong_safe_pause': True,
        'no_open_operational_authorization': True,
        'accepted_local_source_v3_tree_manifest_sha256': p250['accepted_local_source_v3']['tree_manifest_sha256'],
        'accepted_target_sha256': p250['accepted_local_source_v3']['target_sha256'],
        'accepted_builder_r1_sha256': p250['builder_implementation']['builder_sha256'],
    },
    'frozen_executor_v2_contract_checkpoint': {
        'step': 246,
        'policy_sha256': policy246_sha,
        'record_sha256': record246_sha,
        'state': p246['future_executor_v2_contract']['state'],
        'source_generation': p246['future_executor_v2_contract']['source_generation'],
        'implementation_must_wait_for_accepted_v3_manifest_identity': p246['future_executor_v2_contract']['implementation_must_wait_for_accepted_v3_manifest_identity'],
    },
    'fresh_boundary': {
        'opened': True,
        'scope': 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning',
        'purpose': 'resume after the accepted local-source-v3 build without inheriting the expired prebuild target identity or any consumed build authority',
        'kernel_package_edge_family_state': 'open-runtime-remediation-v2-pending',
        'phase_1_acceptance_matrix_complete': False,
        'runtime_chain_open': False,
        'runtime_candidate_set_bound': False,
        'runtime_executor_v2_contract_frozen': True,
        'accepted_v3_manifest_bound_as_future_executor_input': True,
        'runtime_executor_v2_implementation_open': False,
    },
    'accepted_local_source_v3': accepted_v3,
    'preservation_contract': copy.deepcopy(p250['preservation_contract']),
    'future_executor_v2_contract': executor_contract,
    'revalidation_boundary': {
        'fresh_target_revalidation_required_before_any_machine_action': True,
        'accepted_local_source_v3_tree_revalidation_required_before_executor_implementation_or_runtime_use': True,
        'accepted_local_source_v3_tree_manifest_sha256_must_match': p250['accepted_local_source_v3']['tree_manifest_sha256'],
        'accepted_local_source_v3_tree_manifest_sidecar_must_verify': True,
        'accepted_local_source_v3_tree_contents_must_verify_against_manifest': True,
        'staged_target_sha256_must_match': p250['accepted_local_source_v3']['target_sha256'],
        'local_source_v2_historical_no_PGP_state_must_remain_unchanged': True,
        'historical_failed_runtime_and_remediation_evidence_must_remain_unchanged': True,
        'corrected_v3_builder_r1_must_remain_unchanged': True,
        'historical_unexecuted_v3_builder_must_remain_unchanged': True,
        'prior_boot_id_reusable': False,
        'prior_package_database_manifest_reusable': False,
        'prior_prebuild_observation_reusable': False,
        'prior_candidate_binding_reusable': False,
        'prior_runtime_authorization_reusable': False,
        'prior_builder_authorization_reusable': False,
        'fresh_candidate_set_required_before_runtime_rerun': True,
        'target_observation_authorized_now': False,
        'revalidation_probe_design_authorized_now': False,
        'runtime_executor_v2_implementation_authorized_now': False,
    },
    'runtime_executor_v2_boundary': {
        'contract_frozen': True,
        'accepted_v3_manifest_identity_bound': True,
        'implementation_state': 'closed-pending-fresh-target-and-v3-tree-revalidation',
        'implementation_may_use_only_bound_v3_manifest_identity': True,
        'historical_failed_executor_may_be_used_as_design_input_only': True,
        'historical_failed_executor_runtime_authority_reusable': False,
        'human_spaced_error_prefix_required': 'Error downloading from ',
        'hyphenated_error_literal_guard_forbidden': True,
        'fresh_transaction_owned_pkglist_required': True,
        'same_transaction_target_specific_candidate_binding_required': True,
        'runtime_network_access_forbidden': True,
    },
    'authorization': {
        'target_observation_authorized': False,
        'probe_transport_copy_authorized': False,
        'local_source_v3_builder_transport_authorized': False,
        'local_source_v3_builder_execution_authorized': False,
        'local_source_v3_build_authorized': False,
        'repository_refresh_authorized': False,
        'network_access_authorized': False,
        'runtime_candidate_binding_authorized': False,
        'runtime_executor_v2_implementation_authorized': False,
        'runtime_executor_v2_transport_authorized': False,
        'runtime_rerun_authorized': False,
        'package_action_authorized': False,
        'slackpkg_mutation_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'persistent_configuration_change_authorized': False,
        'evidence_cleanup_authorized': False,
        'phase_2_start_authorized': False,
    },
    'helper_sha256': helper_sha,
    'machine_action_required': False,
    'controller_action_required': False,
    'future_work_requires_explicit_authorization': True,
    'pause_safe': False,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review',
}

rows = [
    ('step', '251'),
    ('review_status', 'PASS'),
    ('accepted_checkpoint_step', '250'),
    ('accepted_checkpoint_strong_safe_pause', 'yes'),
    ('accepted_checkpoint_no_open_operational_authorization', 'yes'),
    ('fresh_boundary', 'yes'),
    ('boundary_scope', policy['fresh_boundary']['scope']),
    ('selected_family', 'kernel-package-edge'),
    ('family_state', policy['fresh_boundary']['kernel_package_edge_family_state']),
    ('acceptance_matrix_complete', 'no'),
    ('accepted_local_source_v3_preserve_unchanged', 'yes'),
    ('local_source_v3_tree_manifest_sha256', p250['accepted_local_source_v3']['tree_manifest_sha256']),
    ('staged_target_sha256', p250['accepted_local_source_v3']['target_sha256']),
    ('builder_r1_sha256', p250['builder_implementation']['builder_sha256']),
    ('executor_v2_contract_frozen', 'yes'),
    ('executor_v2_bound_to_accepted_v3_manifest', 'yes'),
    ('executor_v2_implementation_open', 'no'),
    ('fresh_target_revalidation_required_before_any_machine_action', 'yes'),
    ('local_source_v3_tree_revalidation_required_before_executor_implementation_or_runtime_use', 'yes'),
    ('local_source_v3_tree_manifest_sidecar_must_verify', 'yes'),
    ('local_source_v3_tree_contents_must_verify_against_manifest', 'yes'),
    ('prior_boot_id_reusable', 'no'),
    ('prior_package_database_manifest_reusable', 'no'),
    ('prior_prebuild_observation_reusable', 'no'),
    ('prior_candidate_binding_reusable', 'no'),
    ('prior_runtime_authorization_reusable', 'no'),
    ('prior_builder_authorization_reusable', 'no'),
    ('fresh_candidate_set_required_before_runtime_rerun', 'yes'),
    ('human_spaced_error_prefix_required', 'Error downloading from '),
    ('hyphenated_error_literal_guard_forbidden', 'yes'),
    ('fresh_transaction_owned_pkglist_required', 'yes'),
    ('target_observation_authorized', 'no'),
    ('probe_transport_copy_authorized', 'no'),
    ('runtime_executor_v2_implementation_authorized', 'no'),
    ('runtime_executor_v2_transport_authorized', 'no'),
    ('runtime_candidate_binding_authorized', 'no'),
    ('runtime_rerun_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('slackpkg_mutation_authorized', 'no'),
    ('repository_refresh_authorized', 'no'),
    ('network_access_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('evidence_cleanup_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('controller_action_required', 'no'),
    ('future_work_requires_explicit_authorization', 'yes'),
    ('pause_safe', 'no'),
    ('next_stage', policy['next_stage']),
]

out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

printf 'step\t251\n'
printf 'review_status\tPASS\n'
printf 'fresh_boundary\tyes\n'
printf 'accepted_v3_manifest_bound_as_future_executor_input\tyes\n'
printf 'runtime_executor_v2_implementation_authorized\tno\n'
printf 'machine_action_required\tno\n'
printf 'controller_action_required\tno\n'
printf 'pause_safe\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review\n'
