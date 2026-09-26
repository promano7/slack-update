#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review.sh [--output-dir DIR] [--help]

Open the fresh repository-only planning boundary after the accepted Phase 1
step-199 kernel-package-edge strong safe pause. Preserve the frozen signed
artifact byte binding, keep the previous runtime target binding expired, and
grant no operational authorization.
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
step199_policy="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause-policy.json"
step199_record="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause.tsv"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review.sh"
builder_path="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"

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

for required in "$step199_policy" "$step199_record" "$helper_path"; do
    require_regular "$required"
done
check_hash "$step199_policy" '6577709a7fc3b822a9e7e6bcf4f94c973d0a12d829b3a65efc7da4a5038d6a43'
check_hash "$step199_record" '4bd523d8f5958f6227ef6ee48f208e8253a06a2c7f9d9a1b6664286286fda8a1'
[[ ! -e $builder_path ]] || { printf 'ERROR: local-source builder unexpectedly exists at resume boundary: %s\n' "$builder_path" >&2; exit 5; }

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 6; }

policy="$output_dir/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review.tsv"
step199_policy_sha=$(sha256sum -- "$step199_policy" | awk '{print $1}')
step199_record_sha=$(sha256sum -- "$step199_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step199_policy" "$step199_record" "$policy" "$record" "$step199_policy_sha" "$step199_record_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p199_path = Path(sys.argv[1])
r199_path = Path(sys.argv[2])
out_policy = Path(sys.argv[3])
out_record = Path(sys.argv[4])
p199_sha, r199_sha, helper_sha = sys.argv[5:8]

p199 = json.loads(p199_path.read_text(encoding='utf-8'))
with r199_path.open(encoding='utf-8', newline='') as handle:
    r199 = dict(csv.reader(handle, delimiter='\t'))

assert p199['schema'] == 1
assert p199['scenario'] == 'phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause'
assert p199['review_only'] is True
assert p199['pause_safe'] is True
assert p199['safe_pause']['strong_safe_pause'] is True
assert p199['safe_pause']['no_open_operational_authorization'] is True
assert p199['safe_pause']['machine_action_required'] is False
assert p199['safe_pause']['controller_action_required'] is False
assert p199['selected_family']['family'] == 'kernel-package-edge'
assert p199['selected_family']['family_closed'] is False
assert p199['selected_family']['scenario_count'] == 1
assert p199['continuation']['selected_family_preserved'] is True
assert p199['continuation']['target_revalidation_required_before_machine_action'] is True
assert p199['continuation']['no_runtime_candidate_set_is_bound'] is True
assert p199['runtime_boundary']['prior_target_binding_reusable_after_pause'] is False
assert p199['runtime_boundary']['fresh_target_revalidation_required_before_any_machine_action'] is True
assert p199['runtime_boundary']['fresh_candidate_set_required_before_runtime'] is True
assert p199['accepted_artifact_byte_binding']['state'] == 'accepted-byte-binding-frozen'
assert p199['accepted_artifact_byte_binding']['evidence_root_must_remain_unchanged'] is True
assert p199['accepted_artifact_byte_binding']['survives_later_publication'] is True
assert p199['deferred_local_source']['builder_implementation_state'] == 'not-implemented'
assert p199['deferred_local_source']['local_source_tree_built'] is False
assert p199['deferred_local_source']['local_source_tree_manifest_bound'] is False
assert p199['next_stage'] == 'phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review'
assert r199['pause_safe'] == 'yes'
assert r199['strong_safe_pause'] == 'yes'
assert r199['family_closed'] == 'no'
assert r199['prior_target_binding_reusable_after_pause'] == 'no'
assert r199['fresh_target_revalidation_required_before_any_machine_action'] == 'yes'
assert r199['fresh_candidate_set_required_before_runtime'] == 'yes'
assert r199['no_open_operational_authorization'] == 'yes'

for key, value in p199['authorization'].items():
    if key in {'future_machine_work_requires_fresh_target_revalidation', 'future_work_requires_fresh_boundary'}:
        assert value is True
    else:
        assert value is False

binding = p199['accepted_artifact_byte_binding']
local_source = p199['deferred_local_source']
selected = p199['selected_family']

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review',
    'review_only': True,
    'accepted_checkpoint': {
        'step': 199,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause-policy.json',
        'policy_sha256': p199_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause.tsv',
        'record_sha256': r199_sha,
        'strong_safe_pause': True,
        'no_open_operational_authorization': True,
        'later_slackware_current_publication_invalidates_checkpoint': False,
    },
    'fresh_boundary': {
        'opened': True,
        'scope': 'phase-1-kernel-package-edge-local-source-construction-resume-planning',
        'purpose': 'resume the selected kernel-package-edge family without inheriting any pre-pause runtime or operational authorization',
        'selected_family_preserved': True,
        'live_runtime_chain_open': False,
        'runtime_candidate_set_bound': False,
        'slackware_current_publication_invalidates_boundary': False,
    },
    'selected_family': {
        'family': selected['family'],
        'family_closed': False,
        'scenario_count': selected['scenario_count'],
        'selected_scenario': selected['selected_scenario'],
    },
    'artifact_byte_binding': {
        'state': binding['state'],
        'evidence_root': binding['evidence_root'],
        'evidence_root_must_remain_unchanged': True,
        'signing_key_fingerprint': binding['signing_key_fingerprint'],
        'predecessor_package_sha256': binding['predecessor_package_sha256'],
        'target_package_sha256': binding['target_package_sha256'],
        'binding_evidence_sha256': binding['binding_evidence_sha256'],
        'acquired_files_manifest_sha256': binding['acquired_files_manifest_sha256'],
        'survives_later_publication': True,
        'controller_reacquisition_authorized': False,
    },
    'local_source_state': {
        'builder_path': local_source['builder_path'],
        'builder_implementation_state': 'not-implemented',
        'local_source_tree_built': False,
        'local_source_tree_manifest_bound': False,
        'runtime_root': local_source['runtime_root'],
        'runtime_mirror_uri': local_source['runtime_mirror_uri'],
        'target_artifact': local_source['target_artifact'],
        'predecessor_artifact_must_not_be_exposed_by_local_source': True,
    },
    'runtime_revalidation': {
        'prior_target_binding_reusable': False,
        'fresh_target_revalidation_required_before_machine_action': True,
        'fresh_candidate_set_required_before_runtime': True,
        'target_observation_authorized_now': False,
        'target_copy_authorized_now': False,
        'target_network_access_authorized_now': False,
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
        'local_source_build_authorized': False,
        'runtime_executor_implementation_authorized': False,
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
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review.sh',
    'helper_sha256': helper_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review.tsv',
    'next_stage': 'phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review',
}

out_policy.write_text(json.dumps(policy, indent=2) + '\n', encoding='utf-8')
rows = [
    ('accepted_checkpoint_step', '199'),
    ('accepted_checkpoint_policy_sha256', p199_sha),
    ('accepted_checkpoint_record_sha256', r199_sha),
    ('accepted_checkpoint_strong_safe_pause', 'yes'),
    ('fresh_boundary', 'yes'),
    ('boundary_scope', policy['fresh_boundary']['scope']),
    ('selected_family', selected['family']),
    ('selected_scenario', selected['selected_scenario']),
    ('family_closed', 'no'),
    ('artifact_byte_binding_state', binding['state']),
    ('evidence_root', binding['evidence_root']),
    ('evidence_root_must_remain_unchanged', 'yes'),
    ('artifact_binding_survives_later_publication', 'yes'),
    ('controller_reacquisition_authorized', 'no'),
    ('builder_implementation_state', 'not-implemented'),
    ('local_source_tree_built', 'no'),
    ('local_source_tree_manifest_bound', 'no'),
    ('prior_target_binding_reusable', 'no'),
    ('fresh_target_revalidation_required_before_machine_action', 'yes'),
    ('fresh_candidate_set_required_before_runtime', 'yes'),
    ('target_observation_authorized_now', 'no'),
    ('target_vm_action_authorized', 'no'),
    ('target_vm_network_access_authorized', 'no'),
    ('target_artifact_copy_authorized', 'no'),
    ('local_source_build_authorized', 'no'),
    ('runtime_executor_implementation_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'no'),
    ('controller_action_required', 'no'),
    ('future_work_requires_explicit_authorization', 'yes'),
    ('slackware_current_publication_invalidates_boundary', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', policy['next_stage']),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

printf 'resume_planning_boundary_status\tPASS\n'
printf 'selected_family\tkernel-package-edge\n'
printf 'fresh_target_revalidation_required\tyes\n'
printf 'machine_action_authorized\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review\n'
printf 'pause_safe\tno\n'
