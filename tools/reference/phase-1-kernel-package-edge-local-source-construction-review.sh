#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-local-source-construction-review.sh [--output-dir DIR] [--help]

Review and freeze the local-source construction contract after the accepted
step-197 byte binding. This helper is repository-only and authorizes no target
copy, local-source build, package action, boot action, network access, or reboot.
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
freeze_policy="$acceptance_dir/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze-policy.json"
freeze_record="$acceptance_dir/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.tsv"
design_policy="$acceptance_dir/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design-policy.json"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-review.sh"

require_regular() {
    local path=$1
    [[ -f $path && ! -L $path ]] || {
        printf 'ERROR: required regular file missing or unsafe: %s\n' "$path" >&2
        exit 3
    }
}

check_hash() {
    local path=$1 expected=$2 actual
    actual=$(sha256sum -- "$path" | awk '{print $1}')
    [[ $actual == "$expected" ]] || {
        printf 'ERROR: prerequisite SHA-256 mismatch: %s\nexpected: %s\nactual:   %s\n' "$path" "$expected" "$actual" >&2
        exit 4
    }
}

for path in "$freeze_policy" "$freeze_record" "$design_policy" "$helper_path"; do
    require_regular "$path"
done
check_hash "$freeze_policy" '79c0841d604556960fef613b2d0e2c1ed54e2ae32cdac5ddef8b3787363a4d12'
check_hash "$freeze_record" 'abcd032f614dc42e24f820fd8360f864b729897eba964c91d62a1171da0f9449'
check_hash "$design_policy" 'ce33fc2ead2335c50cd9e47146f8d1d818a49e1cb3169b06fe9a983af60f6015'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || {
    printf 'ERROR: output directory is unsafe\n' >&2
    exit 5
}

policy="$output_dir/phase-1-kernel-package-edge-local-source-construction-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-local-source-construction-review.tsv"
freeze_policy_sha=$(sha256sum -- "$freeze_policy" | awk '{print $1}')
freeze_record_sha=$(sha256sum -- "$freeze_record" | awk '{print $1}')
design_policy_sha=$(sha256sum -- "$design_policy" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$freeze_policy" "$freeze_record" "$design_policy" "$policy" "$record" "$freeze_policy_sha" "$freeze_record_sha" "$design_policy_sha" "$helper_sha" <<'PY_INNER'
import csv
import json
import sys
from pathlib import Path

freeze_path, freeze_record_path, design_path, out_policy, out_record = map(Path, sys.argv[1:6])
freeze_sha, freeze_record_sha, design_sha, helper_sha = sys.argv[6:10]
freeze = json.loads(freeze_path.read_text(encoding='utf-8'))
design = json.loads(design_path.read_text(encoding='utf-8'))
with freeze_record_path.open(encoding='utf-8', newline='') as handle:
    freeze_record = dict(csv.reader(handle, delimiter='\t'))

assert freeze['scenario'] == 'phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze'
assert freeze['artifact_byte_binding']['state'] == 'accepted-byte-binding-frozen'
assert freeze['artifact_byte_binding']['observation_status'] == 'PASS'
assert freeze_record['artifact_byte_binding_state'] == 'accepted-byte-binding-frozen'
assert design['scenario'] == 'phase-1-kernel-package-edge-package-pair-and-local-source-binding-design'

byte_binding = freeze['artifact_byte_binding']
source_design = design['binding_design']['local_source']
pair = byte_binding['package_pair']

review = {
    'state': 'reviewed-awaiting-fresh-construction-boundary',
    'input_byte_binding_state': byte_binding['state'],
    'evidence_root': byte_binding['evidence_root'],
    'evidence_root_must_remain_unchanged': True,
    'target_artifact': pair['target_artifact'],
    'target_package_sha256': pair['target_package_sha256'],
    'predecessor_artifact_must_not_be_exposed_by_local_source': True,
    'runtime_root': source_design['runtime_root'],
    'runtime_mirror_uri': source_design['runtime_mirror_uri'],
    'target_relative_path': source_design['target_package_relative_path'],
    'required_metadata_files': source_design['required_metadata_files'],
    'planned_builder_path': source_design['planned_builder_path'],
    'builder_implementation_state': 'not-implemented',
    'builder_execution_authorized': False,
    'target_copy_authorized': False,
    'local_source_tree_built': False,
    'local_source_tree_manifest_bound': False,
    'tree_must_be_read_only_before_runtime': True,
    'tree_must_verify_unchanged_before_and_after_reference_apply': True,
    'runtime_network_access_forbidden': True,
    'candidate_guard_preserved': design['binding_design']['candidate_guard_preserved'],
    'reference_transition_preserved': design['binding_design']['reference_apply_path'] + ' ' + design['binding_design']['reference_apply_mode'],
    'boot_mutation_forbidden': True,
    'reboot_forbidden': True,
    'fresh_target_revalidation_required_before_any_machine_action': True,
    'fresh_explicit_authorization_required_before_target_copy_or_build': True,
    'later_slackware_current_publication_invalidates_review': False,
}

authorization = {
    'controller_network_access_authorized': False,
    'controller_artifact_acquisition_authorized': False,
    'target_vm_network_access_authorized': False,
    'target_vm_action_authorized': False,
    'target_artifact_copy_authorized': False,
    'local_source_build_authorized': False,
    'runtime_executor_implementation_authorized': False,
    'runtime_scenario_execution_authorized': False,
    'package_action_authorized': False,
    'boot_action_authorized': False,
    'reboot_authorized': False,
    'phase_2_start_authorized': False,
    'strong_safe_pause_review_authorized_for_next_stage': True,
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-local-source-construction-review',
    'review_only': True,
    'accepted_byte_binding': {
        'step': 197,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze-policy.json',
        'policy_sha256': freeze_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.tsv',
        'record_sha256': freeze_record_sha,
    },
    'accepted_local_source_design': {
        'step': 195,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design-policy.json',
        'policy_sha256': design_sha,
    },
    'construction_review': review,
    'authorization': authorization,
    'machine_action_required': False,
    'controller_action_required': False,
    'pause_safe': False,
    'strong_safe_pause_ready_for_review': True,
    'next_stage': 'phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause',
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-local-source-construction-review.sh',
    'helper_sha256': helper_sha,
}

rows = [
    ('construction_review_state', review['state']),
    ('input_byte_binding_state', review['input_byte_binding_state']),
    ('evidence_root', review['evidence_root']),
    ('evidence_root_must_remain_unchanged', 'yes'),
    ('target_artifact', review['target_artifact']),
    ('target_package_sha256', review['target_package_sha256']),
    ('predecessor_artifact_must_not_be_exposed_by_local_source', 'yes'),
    ('runtime_root', review['runtime_root']),
    ('runtime_mirror_uri', review['runtime_mirror_uri']),
    ('target_relative_path', review['target_relative_path']),
    ('required_metadata_files', ' '.join(review['required_metadata_files'])),
    ('planned_builder_path', review['planned_builder_path']),
    ('builder_implementation_state', review['builder_implementation_state']),
    ('local_source_tree_built', 'no'),
    ('local_source_tree_manifest_bound', 'no'),
    ('tree_must_be_read_only_before_runtime', 'yes'),
    ('tree_must_verify_unchanged_before_and_after_reference_apply', 'yes'),
    ('runtime_network_access_forbidden', 'yes'),
    ('fresh_target_revalidation_required_before_any_machine_action', 'yes'),
    ('fresh_explicit_authorization_required_before_target_copy_or_build', 'yes'),
    ('controller_network_access_authorized', 'no'),
    ('target_vm_action_authorized', 'no'),
    ('target_artifact_copy_authorized', 'no'),
    ('local_source_build_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('controller_action_required', 'no'),
    ('later_slackware_current_publication_invalidates_review', 'no'),
    ('strong_safe_pause_ready_for_review', 'yes'),
    ('next_stage', policy['next_stage']),
    ('pause_safe', 'no'),
]

Path(out_policy).write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY_INNER

printf 'Step 198 local-source construction review generated:\n'
printf 'policy\t%s\n' "$policy"
printf 'record\t%s\n' "$record"
