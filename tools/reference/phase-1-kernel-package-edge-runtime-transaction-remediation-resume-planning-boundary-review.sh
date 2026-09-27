#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review.sh [--output-dir DIR] [--help]

Open a fresh repository-only planning boundary after the accepted Phase 1
step-220 strong safe pause. Preserve the contained-failure evidence and the
local-source-v2 remediation contract while granting no operational authority.
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
step220_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause.sh"
step220_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause.md"
step220_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause-harness.sh"
step220_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause-policy.json"
step220_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause.tsv"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review.sh"

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

for required in "$step220_helper" "$step220_doc" "$step220_harness" "$step220_policy" "$step220_record" "$helper_path"; do
    require_regular "$required"
done
check_hash "$step220_helper" '3d3002f5eb5063d7ac92a84dced9884953f0a4ee31d29c34fc395cd55a99191c'
check_hash "$step220_doc" '94cc57bac133a42ffcfe7bd234f279bae42cc9d69928945fabdfc076b87227a4'
check_hash "$step220_harness" 'b07d1a41b774be3edc891af0db4fd970d26e3ef04f498004f30b894362844dd6'
check_hash "$step220_policy" 'f52b276f8c93d4e939b7093be95236ba719039dbb5d8d2fae850f3ac810a49a4'
check_hash "$step220_record" 'a91b731dcd27be6c57bfbca62c660bb92e3d75a94ba8e37e1f8d2d94fdbc68fe'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review.tsv"
step220_helper_sha=$(sha256sum -- "$step220_helper" | awk '{print $1}')
step220_doc_sha=$(sha256sum -- "$step220_doc" | awk '{print $1}')
step220_harness_sha=$(sha256sum -- "$step220_harness" | awk '{print $1}')
step220_policy_sha=$(sha256sum -- "$step220_policy" | awk '{print $1}')
step220_record_sha=$(sha256sum -- "$step220_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step220_policy" "$step220_record" "$policy" "$record" \
    "$step220_helper_sha" "$step220_doc_sha" "$step220_harness_sha" "$step220_policy_sha" "$step220_record_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p220_path = Path(sys.argv[1])
r220_path = Path(sys.argv[2])
out_policy = Path(sys.argv[3])
out_record = Path(sys.argv[4])
helper220_sha, doc220_sha, harness220_sha, policy220_sha, record220_sha, helper_sha = sys.argv[5:11]

p220 = json.loads(p220_path.read_text(encoding='utf-8'))
with r220_path.open(encoding='utf-8', newline='') as handle:
    r220 = dict(csv.reader(handle, delimiter='\t'))

assert p220['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-boundary-review-and-strong-safe-pause'
assert p220['step'] == 220
assert p220['review_status'] == 'PASS'
assert p220['kernel_package_edge_family_state'] == 'open-remediation-pending'
assert p220['phase_1_acceptance_matrix_complete'] is False
assert p220['safe_pause']['strong_safe_pause'] is True
assert p220['safe_pause']['pause_safe'] is True
assert p220['safe_pause']['no_open_operational_authorization'] is True
assert p220['machine_action_required'] is False
assert p220['controller_action_required'] is False
assert p220['resume_boundary']['fresh_resume_planning_boundary_required'] is True
assert p220['resume_boundary']['fresh_target_revalidation_required_before_any_machine_action'] is True
assert p220['resume_boundary']['prior_runtime_authorization_reusable'] is False
assert p220['resume_boundary']['prior_candidate_binding_reusable'] is False
assert p220['resume_boundary']['prior_failed_executor_authorization_reusable'] is False
assert p220['remediation_contract']['new_local_source_generation_name'] == 'local-source-v2'
assert p220['remediation_contract']['remediation_must_be_revalidated_before_package_mutation'] is True
assert p220['preservation_contract']['local_source_v1_must_be_preserved_unchanged'] is True
assert p220['preservation_contract']['failed_runtime_evidence_root_must_be_preserved_unchanged'] is True
assert p220['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review'
assert r220['strong_safe_pause'] == 'yes'
assert r220['pause_safe'] == 'yes'
assert r220['runtime_rerun_authorized'] == 'no'
assert r220['package_action_authorized'] == 'no'

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review',
    'step': 221,
    'review_only': True,
    'review_status': 'PASS',
    'accepted_checkpoint': {
        'step': 220,
        'helper_sha256': helper220_sha,
        'document_sha256': doc220_sha,
        'harness_sha256': harness220_sha,
        'policy_sha256': policy220_sha,
        'record_sha256': record220_sha,
        'strong_safe_pause': True,
        'no_open_operational_authorization': True,
    },
    'fresh_boundary': {
        'opened': True,
        'scope': 'phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning',
        'purpose': 'resume local-source-v2 remediation planning without inheriting any prior runtime or operational authorization',
        'kernel_package_edge_family_state': 'open-remediation-pending',
        'phase_1_acceptance_matrix_complete': False,
        'runtime_chain_open': False,
        'runtime_candidate_set_bound': False,
    },
    'preservation_contract': dict(p220['preservation_contract']),
    'remediation_contract': {
        **p220['remediation_contract'],
        'design_authorized_now': False,
        'build_authorized_now': False,
        'runtime_validation_authorized_now': False,
    },
    'runtime_revalidation': {
        'fresh_target_revalidation_required_before_any_machine_action': True,
        'target_observation_authorized_now': False,
        'prior_target_binding_reusable': False,
        'prior_runtime_authorization_reusable': False,
        'prior_candidate_binding_reusable': False,
        'prior_failed_executor_authorization_reusable': False,
        'fresh_candidate_binding_required_before_runtime_rerun': True,
        'later_slackware_current_publication_requires_live_target_revalidation': True,
    },
    'authorization': {
        'target_observation_authorized': False,
        'controller_transport_authorized': False,
        'local_source_v2_design_authorized': False,
        'local_source_v2_build_authorized': False,
        'runtime_executor_build_authorized': False,
        'runtime_executor_transport_authorized': False,
        'runtime_rerun_authorized': False,
        'package_action_authorized': False,
        'slackpkg_mutation_authorized': False,
        'repository_refresh_authorized': False,
        'network_access_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'persistent_configuration_change_authorized': False,
        'evidence_cleanup_authorized': False,
        'phase_2_start_authorized': False,
        'future_work_requires_explicit_authorization': True,
    },
    'helper_sha256': helper_sha,
    'machine_action_required': False,
    'controller_action_required': False,
    'pause_safe': False,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review',
}

out_policy.write_text(json.dumps(policy, indent=2, sort_keys=False) + '\n', encoding='utf-8')
rows = [
    ('step', '221'),
    ('review_status', 'PASS'),
    ('accepted_checkpoint_step', '220'),
    ('accepted_checkpoint_strong_safe_pause', 'yes'),
    ('fresh_boundary', 'yes'),
    ('boundary_scope', policy['fresh_boundary']['scope']),
    ('kernel_package_edge_family_state', 'open-remediation-pending'),
    ('phase_1_acceptance_matrix_complete', 'no'),
    ('local_source_v1_must_be_preserved_unchanged', 'yes'),
    ('failed_runtime_evidence_root_must_be_preserved_unchanged', 'yes'),
    ('new_local_source_generation_required', 'yes'),
    ('new_local_source_generation_name', 'local-source-v2'),
    ('local_source_v2_design_authorized', 'no'),
    ('local_source_v2_build_authorized', 'no'),
    ('remediation_must_be_revalidated_before_package_mutation', 'yes'),
    ('fresh_target_revalidation_required_before_any_machine_action', 'yes'),
    ('target_observation_authorized_now', 'no'),
    ('prior_target_binding_reusable', 'no'),
    ('prior_runtime_authorization_reusable', 'no'),
    ('prior_candidate_binding_reusable', 'no'),
    ('prior_failed_executor_authorization_reusable', 'no'),
    ('fresh_candidate_binding_required_before_runtime_rerun', 'yes'),
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
