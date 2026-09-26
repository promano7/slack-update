#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review.sh [--output-dir DIR] [--help]

Open a fresh repository-only planning boundary after the accepted Phase 1
step-210 kernel-package-edge local-source build strong safe pause. Preserve the
frozen artifact bytes and built local-source evidence, keep the prior runtime
target binding expired, and grant no operational authorization.
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
step210_policy="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause-policy.json"
step210_record="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause.tsv"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review.sh"
builder_path="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
stager_path="$repo_root/tools/reference/phase-1-kernel-package-edge-target-artifact-stage.sh"

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

for required in "$step210_policy" "$step210_record" "$helper_path" "$builder_path" "$stager_path"; do
    require_regular "$required"
done
check_hash "$step210_policy" '14735ff6414e1014c804610dbd501518af49abd57001691d3124563e13164bc1'
check_hash "$step210_record" '616c6220bc5e98433ca45465e7a598e22d8286c24f34439e67725c372d3789dc'
check_hash "$builder_path" '59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92'
check_hash "$stager_path" 'a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review.tsv"
step210_policy_sha=$(sha256sum -- "$step210_policy" | awk '{print $1}')
step210_record_sha=$(sha256sum -- "$step210_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
builder_sha=$(sha256sum -- "$builder_path" | awk '{print $1}')
stager_sha=$(sha256sum -- "$stager_path" | awk '{print $1}')

python3 - "$step210_policy" "$step210_record" "$policy" "$record" \
    "$step210_policy_sha" "$step210_record_sha" "$helper_sha" "$builder_sha" "$stager_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p210_path = Path(sys.argv[1])
r210_path = Path(sys.argv[2])
out_policy = Path(sys.argv[3])
out_record = Path(sys.argv[4])
p210_sha, r210_sha, helper_sha, builder_sha, stager_sha = sys.argv[5:10]

p210 = json.loads(p210_path.read_text(encoding='utf-8'))
with r210_path.open(encoding='utf-8', newline='') as handle:
    r210 = dict(csv.reader(handle, delimiter='\t'))

assert p210['schema'] == 1
assert p210['scenario'] == 'phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause'
assert p210['review_only'] is True
assert p210['pause_safe'] is True
assert p210['safe_pause']['strong_safe_pause'] is True
assert p210['safe_pause']['no_open_operational_authorization'] is True
assert p210['safe_pause']['machine_action_required'] is False
assert p210['safe_pause']['controller_action_required'] is False
assert p210['local_source_build_result']['status'] == 'PASS'
assert p210['local_source_build_result']['local_source_tree_built'] is True
assert p210['local_source_build_result']['local_source_tree_manifest_bound'] is True
assert p210['local_source_build_result']['tree_manifest_sha256'] == '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'
assert p210['local_source_build_result']['target_sha256'] == 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert p210['builder_implementation']['builder_sha256'] == builder_sha
assert p210['stager_sha256'] == stager_sha
assert p210['continuation']['family_closed'] is False
assert p210['continuation']['selected_family_preserved'] is True
assert p210['continuation']['fresh_target_revalidation_required_before_any_machine_action'] is True
assert p210['continuation']['local_source_tree_revalidation_required_before_runtime'] is True
assert p210['continuation']['fresh_candidate_set_required_before_runtime'] is True
assert p210['continuation']['future_work_requires_fresh_boundary'] is True
assert p210['next_stage'] == 'phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review'
assert r210['step'] == '210'
assert r210['pause_safe'] == 'yes'
assert r210['strong_safe_pause'] == 'yes'
assert r210['selected_family'] == 'kernel-package-edge'
assert r210['family_closed'] == 'no'
assert r210['local_source_tree_built'] == 'yes'
assert r210['local_source_tree_manifest_bound'] == 'yes'
assert r210['prior_target_binding_reusable_after_pause'] == 'no'
assert r210['fresh_target_revalidation_required_before_any_machine_action'] == 'yes'
assert r210['local_source_tree_revalidation_required_before_runtime'] == 'yes'
assert r210['fresh_candidate_set_required_before_runtime'] == 'yes'
assert r210['no_open_operational_authorization'] == 'yes'

for key, value in p210['authorization'].items():
    assert value is False, (key, value)

artifact = p210['accepted_artifact_binding']
build = p210['local_source_build_result']
builder = p210['builder_implementation']

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review',
    'review_only': True,
    'accepted_checkpoint': {
        'step': 210,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause-policy.json',
        'policy_sha256': p210_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-build-result-review-and-strong-safe-pause.tsv',
        'record_sha256': r210_sha,
        'strong_safe_pause': True,
        'no_open_operational_authorization': True,
        'later_slackware_current_publication_invalidates_checkpoint': False,
    },
    'fresh_boundary': {
        'opened': True,
        'scope': 'phase-1-kernel-package-edge-post-local-source-build-resume-planning',
        'purpose': 'resume the selected kernel-package-edge family without inheriting pre-pause target identity or operational authorization',
        'selected_family_preserved': True,
        'live_runtime_chain_open': False,
        'runtime_candidate_set_bound': False,
        'prior_runtime_target_binding_reusable': False,
        'slackware_current_publication_invalidates_boundary': False,
    },
    'selected_family': {
        'family': 'kernel-package-edge',
        'family_closed': False,
        'scenario_count': 1,
        'selected_scenario': 'kernel-headers-update-without-kernel-boot-package-update',
    },
    'artifact_byte_binding': {
        'state': 'accepted-byte-binding-frozen',
        'binding_step': artifact['binding_step'],
        'evidence_root': artifact['evidence_root'],
        'evidence_root_must_remain_unchanged': True,
        'signing_key_fingerprint': artifact['signing_key_fingerprint'],
        'predecessor_artifact': artifact['predecessor_artifact'],
        'predecessor_sha256': artifact['predecessor_sha256'],
        'target_artifact': artifact['target_artifact'],
        'target_sha256': artifact['target_sha256'],
        'survives_later_publication': True,
        'controller_reacquisition_authorized': False,
    },
    'local_source_state': {
        'state': 'built-and-manifest-bound-preserved',
        'builder_path': builder['builder_path'],
        'builder_sha256': builder_sha,
        'local_source_root': build['local_source_root'],
        'runtime_mirror_uri': builder['runtime_mirror_uri'],
        'target_package': build['target_package'],
        'target_sha256': build['target_sha256'],
        'tree_manifest_path': build['tree_manifest'],
        'tree_manifest_sha256': build['tree_manifest_sha256'],
        'tree_manifest_sha256_path': build['tree_manifest_sha256_path'],
        'local_source_tree_built': True,
        'local_source_tree_manifest_bound': True,
        'single_candidate_contract_preserved': True,
        'predecessor_excluded_from_local_source': True,
        'built_tree_must_remain_unchanged': True,
        'tree_manifest_must_remain_unchanged': True,
        'revalidation_required_before_runtime': True,
        'revalidation_authorized_now': False,
        'builder_rerun_authorized': False,
    },
    'runtime_revalidation': {
        'prior_target_binding_reusable': False,
        'fresh_target_revalidation_required_before_any_machine_action': True,
        'fresh_target_observation_authorized_now': False,
        'local_source_tree_revalidation_required_before_runtime': True,
        'local_source_tree_revalidation_authorized_now': False,
        'fresh_candidate_set_required_before_runtime': True,
        'candidate_set_binding_authorized_now': False,
        'predecessor_package_staging_authorized_now': False,
    },
    'authorization': {
        'source_change_authorized': False,
        'documentation_change_authorized': False,
        'controller_artifact_acquisition_authorized': False,
        'controller_network_access_authorized': False,
        'repository_refresh_authorized': False,
        'network_refresh_authorized': False,
        'target_vm_action_authorized': False,
        'target_vm_network_access_authorized': False,
        'target_artifact_copy_authorized': False,
        'builder_execution_authorized': False,
        'local_source_build_authorized': False,
        'fresh_target_observation_authorized': False,
        'local_source_tree_revalidation_authorized': False,
        'predecessor_package_staging_authorized': False,
        'runtime_candidate_refresh_authorized': False,
        'runtime_candidate_binding_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'package_action_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
        'future_work_requires_explicit_authorization': True,
    },
    'gates': {
        'acceptance_matrix_complete': False,
        'kernel_package_edge_family_closed': False,
        'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
        'c_port_status': 'blocked-by-phase-1-gate',
    },
    'machine_action_required': False,
    'controller_action_required': False,
    'pause_safe': False,
    'strong_safe_pause': False,
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review.sh',
    'helper_sha256': helper_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review.tsv',
    'next_stage': 'phase-1-kernel-package-edge-post-local-source-build-revalidation-review',
}

out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step', '211'),
    ('accepted_checkpoint_step', '210'),
    ('accepted_checkpoint_policy_sha256', p210_sha),
    ('accepted_checkpoint_record_sha256', r210_sha),
    ('accepted_checkpoint_strong_safe_pause', 'yes'),
    ('fresh_boundary', 'yes'),
    ('boundary_scope', policy['fresh_boundary']['scope']),
    ('selected_family', 'kernel-package-edge'),
    ('selected_scenario', policy['selected_family']['selected_scenario']),
    ('family_closed', 'no'),
    ('artifact_byte_binding_state', 'accepted-byte-binding-frozen'),
    ('artifact_binding_survives_later_publication', 'yes'),
    ('controller_reacquisition_authorized', 'no'),
    ('local_source_state', 'built-and-manifest-bound-preserved'),
    ('local_source_tree_built', 'yes'),
    ('local_source_tree_manifest_bound', 'yes'),
    ('local_source_root', build['local_source_root']),
    ('tree_manifest_path', build['tree_manifest']),
    ('tree_manifest_sha256', build['tree_manifest_sha256']),
    ('built_tree_must_remain_unchanged', 'yes'),
    ('prior_target_binding_reusable', 'no'),
    ('fresh_target_revalidation_required_before_any_machine_action', 'yes'),
    ('fresh_target_observation_authorized_now', 'no'),
    ('local_source_tree_revalidation_required_before_runtime', 'yes'),
    ('local_source_tree_revalidation_authorized_now', 'no'),
    ('fresh_candidate_set_required_before_runtime', 'yes'),
    ('candidate_set_binding_authorized_now', 'no'),
    ('predecessor_package_staging_authorized_now', 'no'),
    ('builder_rerun_authorized', 'no'),
    ('repository_refresh_authorized', 'no'),
    ('network_refresh_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('controller_action_required', 'no'),
    ('acceptance_matrix_complete', 'no'),
    ('pause_safe', 'no'),
    ('strong_safe_pause', 'no'),
    ('next_stage', policy['next_stage']),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

printf 'boundary_review_status\tPASS\n'
printf 'accepted_checkpoint_step\t210\n'
printf 'fresh_boundary\tyes\n'
printf 'selected_family\tkernel-package-edge\n'
printf 'local_source_tree_built\tyes\n'
printf 'local_source_tree_manifest_bound\tyes\n'
printf 'prior_target_binding_reusable\tno\n'
printf 'fresh_target_observation_authorized_now\tno\n'
printf 'local_source_tree_revalidation_authorized_now\tno\n'
printf 'candidate_set_binding_authorized_now\tno\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-post-local-source-build-revalidation-review\n'
