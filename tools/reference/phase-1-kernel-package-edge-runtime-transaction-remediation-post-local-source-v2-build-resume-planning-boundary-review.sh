#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review.sh [--output-dir DIR] [--help]

Open a fresh repository-only planning boundary after the accepted Phase 1
step-230 local-source-v2 build strong safe pause. Preserve the accepted v2
source and all historical evidence, expire the prior live target identity, and
grant no operational authority.
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
step230_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause.sh"
step230_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause.md"
step230_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause-harness.sh"
step230_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause-policy.json"
step230_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause.tsv"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review.sh"

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

for required in "$step230_helper" "$step230_doc" "$step230_harness" "$step230_policy" "$step230_record" "$helper_path"; do
    require_regular "$required"
done
check_hash "$step230_helper" '32fa3bac652bb7de985bfa675d9b03f7b25a2ee6cc84158fe0c0c230f211882b'
check_hash "$step230_doc" '4f4579e287135a6c66442c2416fa932a6a59c5fb030df03cec3c129043b9eaca'
check_hash "$step230_harness" 'ddcc0b383cba9e48eb059c6dd14c30f8fa3c0b7663889bad6322c3a329d1586e'
check_hash "$step230_policy" 'a65037c1da85360d7f9351c31a352f02208b72562ff3abc9c31ca399c8ef9beb'
check_hash "$step230_record" 'cec962a34963ea591f07edeff5f68065f9e9a258551028745bf92eaebc4f4898'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review.tsv"
step230_helper_sha=$(sha256sum -- "$step230_helper" | awk '{print $1}')
step230_doc_sha=$(sha256sum -- "$step230_doc" | awk '{print $1}')
step230_harness_sha=$(sha256sum -- "$step230_harness" | awk '{print $1}')
step230_policy_sha=$(sha256sum -- "$step230_policy" | awk '{print $1}')
step230_record_sha=$(sha256sum -- "$step230_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step230_policy" "$step230_record" "$policy" "$record" \
    "$step230_helper_sha" "$step230_doc_sha" "$step230_harness_sha" "$step230_policy_sha" "$step230_record_sha" "$helper_sha" <<'PY'
import csv
import copy
import json
import sys
from pathlib import Path

p230_path = Path(sys.argv[1])
r230_path = Path(sys.argv[2])
out_policy = Path(sys.argv[3])
out_record = Path(sys.argv[4])
helper230_sha, doc230_sha, harness230_sha, policy230_sha, record230_sha, helper_sha = sys.argv[5:11]

p230 = json.loads(p230_path.read_text(encoding='utf-8'))
with r230_path.open(encoding='utf-8', newline='') as handle:
    r230 = dict(csv.reader(handle, delimiter='\t'))

assert p230['schema'] == 1
assert p230['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build-result-review-and-strong-safe-pause'
assert p230['step'] == 230
assert p230['review_status'] == 'PASS'
assert p230['strong_safe_pause'] is True
assert p230['pause_safe'] is True
assert p230['safe_pause']['strong_safe_pause'] is True
assert p230['safe_pause']['no_open_operational_authorization'] is True
assert p230['accepted_local_source_v2']['state'] == 'built-accepted-preserve-unchanged'
assert p230['accepted_local_source_v2']['tree_manifest_sha256'] == 'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'
assert p230['accepted_local_source_v2']['target_sha256'] == 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert p230['runtime_boundary_after_pause']['fresh_target_revalidation_required_before_any_machine_action'] is True
assert p230['runtime_boundary_after_pause']['local_source_v2_tree_revalidation_required_before_runtime'] is True
assert p230['runtime_boundary_after_pause']['fresh_candidate_set_required_before_runtime'] is True
assert p230['runtime_boundary_after_pause']['runtime_executor_remediation_review_required_before_rerun'] is True
assert p230['runtime_boundary_after_pause']['prior_target_binding_reusable_after_pause'] is False
assert p230['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review'
assert r230['step'] == '230'
assert r230['strong_safe_pause'] == 'yes'
assert r230['pause_safe'] == 'yes'
assert r230['no_open_operational_authorization'] == 'yes'
assert r230['build_authority_consumed'] == 'yes'
assert r230['target_observation_authorized'] == 'no'
assert r230['runtime_rerun_authorized'] == 'no'

for key, value in p230['authorization'].items():
    assert value is False, (key, value)

accepted_v2 = copy.deepcopy(p230['accepted_local_source_v2'])
accepted_v2['state'] = 'built-accepted-preserve-unchanged-resume-boundary'

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review',
    'step': 231,
    'review_only': True,
    'review_status': 'PASS',
    'accepted_checkpoint': {
        'step': 230,
        'helper_sha256': helper230_sha,
        'document_sha256': doc230_sha,
        'harness_sha256': harness230_sha,
        'policy_sha256': policy230_sha,
        'record_sha256': record230_sha,
        'strong_safe_pause': True,
        'no_open_operational_authorization': True,
        'accepted_local_source_v2_tree_manifest_sha256': p230['accepted_local_source_v2']['tree_manifest_sha256'],
    },
    'fresh_boundary': {
        'opened': True,
        'scope': 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning',
        'purpose': 'resume after the accepted local-source-v2 build without inheriting the expired prebuild target identity or any consumed build authority',
        'kernel_package_edge_family_state': 'open-runtime-remediation-pending',
        'phase_1_acceptance_matrix_complete': False,
        'runtime_chain_open': False,
        'runtime_candidate_set_bound': False,
        'runtime_executor_v2_contract_frozen': False,
    },
    'accepted_local_source_v2': accepted_v2,
    'preservation_contract': copy.deepcopy(p230['preservation_contract']),
    'future_refresh_acceptance_contract': copy.deepcopy(p230['future_refresh_acceptance_contract']),
    'revalidation_boundary': {
        'fresh_target_revalidation_required_before_any_machine_action': True,
        'accepted_local_source_v2_tree_revalidation_required_before_runtime_use': True,
        'accepted_local_source_v2_tree_manifest_sha256_must_match': p230['accepted_local_source_v2']['tree_manifest_sha256'],
        'accepted_local_source_v2_tree_manifest_sidecar_must_verify': True,
        'accepted_local_source_v2_tree_contents_must_verify_against_manifest': True,
        'staged_target_sha256_must_match': p230['accepted_local_source_v2']['target_sha256'],
        'preserved_local_source_v1_must_remain_unchanged': True,
        'historical_failed_runtime_evidence_must_remain_unchanged': True,
        'prior_boot_id_reusable': False,
        'prior_package_database_manifest_reusable': False,
        'prior_prebuild_observation_reusable': False,
        'prior_candidate_binding_reusable': False,
        'prior_runtime_authorization_reusable': False,
        'prior_builder_authorization_reusable': False,
        'fresh_candidate_set_required_before_runtime_rerun': True,
        'runtime_executor_remediation_review_required_before_rerun': True,
        'target_observation_authorized_now': False,
        'revalidation_probe_design_authorized_now': False,
    },
    'runtime_executor_boundary': {
        'historical_executor_may_be_used_as_design_input': True,
        'historical_executor_runtime_authority_reusable': False,
        'must_use_local_source_v2': True,
        'transaction_owned_new_empty_slackpkg_workdir_required': True,
        'target_specific_candidate_guard_required': True,
        'real_tab_tsv_evidence_required': True,
        'refresh_exit_zero_alone_is_sufficient': False,
        'no_error_downloading_signal_required': True,
        'runtime_network_access_forbidden': True,
        'executor_remediation_not_yet_authorized': True,
    },
    'authorization': {
        'target_observation_authorized': False,
        'probe_transport_copy_authorized': False,
        'local_source_v2_builder_transport_authorized': False,
        'local_source_v2_builder_execution_authorized': False,
        'local_source_v2_build_authorized': False,
        'repository_refresh_authorized': False,
        'network_access_authorized': False,
        'runtime_candidate_binding_authorized': False,
        'runtime_executor_remediation_authorized': False,
        'runtime_executor_transport_authorized': False,
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
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review',
}

out_policy.write_text(json.dumps(policy, indent=2, sort_keys=False) + '\n', encoding='utf-8')
rows = [
    ('step', '231'),
    ('review_status', 'PASS'),
    ('accepted_checkpoint_step', '230'),
    ('accepted_checkpoint_strong_safe_pause', 'yes'),
    ('accepted_checkpoint_no_open_operational_authorization', 'yes'),
    ('fresh_boundary', 'yes'),
    ('boundary_scope', policy['fresh_boundary']['scope']),
    ('selected_family', 'kernel-package-edge'),
    ('family_state', 'open-runtime-remediation-pending'),
    ('acceptance_matrix_complete', 'no'),
    ('accepted_local_source_v2_preserve_unchanged', 'yes'),
    ('local_source_v2_tree_manifest_sha256', p230['accepted_local_source_v2']['tree_manifest_sha256']),
    ('staged_target_sha256', p230['accepted_local_source_v2']['target_sha256']),
    ('fresh_target_revalidation_required_before_any_machine_action', 'yes'),
    ('local_source_v2_tree_revalidation_required_before_runtime_use', 'yes'),
    ('local_source_v2_tree_manifest_sidecar_must_verify', 'yes'),
    ('local_source_v2_tree_contents_must_verify_against_manifest', 'yes'),
    ('prior_boot_id_reusable', 'no'),
    ('prior_package_database_manifest_reusable', 'no'),
    ('prior_prebuild_observation_reusable', 'no'),
    ('prior_candidate_binding_reusable', 'no'),
    ('prior_runtime_authorization_reusable', 'no'),
    ('prior_builder_authorization_reusable', 'no'),
    ('fresh_candidate_set_required_before_runtime_rerun', 'yes'),
    ('runtime_executor_remediation_review_required_before_rerun', 'yes'),
    ('target_observation_authorized', 'no'),
    ('probe_transport_copy_authorized', 'no'),
    ('runtime_executor_remediation_authorized', 'no'),
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
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

cat "$record"
