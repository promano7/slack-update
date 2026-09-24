#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause.sh [--output-dir DIR] [--help]

Review the accepted kernel-package-edge local-source construction boundary and
emit a strong-safe-pause checkpoint. This helper is repository-only, preserves
the frozen package byte binding, expires the prior runtime target observation,
and grants no operational authority.
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
acc="$repo_root/tests/fixtures/reference/acceptance/phase-1"
step198_policy="$acc/phase-1-kernel-package-edge-local-source-construction-review-policy.json"
step198_record="$acc/phase-1-kernel-package-edge-local-source-construction-review.tsv"
step197_policy="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze-policy.json"
step197_record="$acc/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.tsv"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause.sh"
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

for required in "$step198_policy" "$step198_record" "$step197_policy" "$step197_record" "$helper_path"; do
    require_regular "$required"
done
check_hash "$step198_policy" 'd9625849f7254480495a6e749b1a07643f2504f169f54a40507fb26e84eddd70'
check_hash "$step198_record" '57fc3fa28b148850544a8610ebc9572bfed528bf7e5b3b3c7d1b244822aa7ed6'
check_hash "$step197_policy" '79c0841d604556960fef613b2d0e2c1ed54e2ae32cdac5ddef8b3787363a4d12'
check_hash "$step197_record" 'abcd032f614dc42e24f820fd8360f864b729897eba964c91d62a1171da0f9449'
[[ ! -e $builder_path ]] || { printf 'ERROR: local-source builder unexpectedly exists before continuation boundary: %s\n' "$builder_path" >&2; exit 5; }

if [[ -z $output_dir ]]; then
    output_dir=$acc
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 6; }

policy="$output_dir/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause-policy.json"
record="$output_dir/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step198_policy" "$step198_record" "$step197_policy" "$step197_record" "$policy" "$record" "$helper_sha" <<'PYGEN'
import csv
import hashlib
import json
import sys
from pathlib import Path

p198_path, r198_path, p197_path, r197_path, out_policy, out_record = map(Path, sys.argv[1:7])
helper_sha = sys.argv[7]
p198 = json.loads(p198_path.read_text(encoding='utf-8'))
p197 = json.loads(p197_path.read_text(encoding='utf-8'))
with r198_path.open(encoding='utf-8', newline='') as handle:
    r198 = dict(csv.reader(handle, delimiter='\t'))
with r197_path.open(encoding='utf-8', newline='') as handle:
    r197 = dict(csv.reader(handle, delimiter='\t'))

assert p198['scenario'] == 'phase-1-kernel-package-edge-local-source-construction-review'
assert p198['review_only'] is True
assert p198['strong_safe_pause_ready_for_review'] is True
assert p198['pause_safe'] is False
assert p198['machine_action_required'] is False
assert p198['controller_action_required'] is False
assert p198['construction_review']['builder_implementation_state'] == 'not-implemented'
assert p198['construction_review']['local_source_tree_built'] is False
assert p198['construction_review']['local_source_tree_manifest_bound'] is False
assert p198['construction_review']['fresh_target_revalidation_required_before_any_machine_action'] is True
assert p198['construction_review']['evidence_root_must_remain_unchanged'] is True
assert p198['construction_review']['later_slackware_current_publication_invalidates_review'] is False
assert p198['next_stage'] == 'phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause'
assert all(value is False for key, value in p198['authorization'].items() if key != 'strong_safe_pause_review_authorized_for_next_stage')
assert p198['authorization']['strong_safe_pause_review_authorized_for_next_stage'] is True
assert r198['strong_safe_pause_ready_for_review'] == 'yes'
assert r198['pause_safe'] == 'no'

binding = p197['artifact_byte_binding']
assert binding['state'] == 'accepted-byte-binding-frozen'
assert binding['observation_status'] == 'PASS'
assert binding['evidence_root_must_be_preserved_unchanged'] is True
assert binding['package_pair']['predecessor_signature_valid'] is True
assert binding['package_pair']['target_signature_valid'] is True
assert binding['later_archive_or_slackware_current_publication_invalidates_byte_binding'] is False
assert r197['artifact_byte_binding_state'] == 'accepted-byte-binding-frozen'
assert r197['controller_network_access_authorized'] == 'no'
assert r197['target_vm_action_authorized'] == 'no'

policy = {
  'schema': 1,
  'scenario': 'phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause',
  'review_only': True,
  'accepted_construction_review': {
    'step': 198,
    'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-review-policy.json',
    'policy_sha256': hashlib.sha256(p198_path.read_bytes()).hexdigest(),
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-review.tsv',
    'record_sha256': hashlib.sha256(r198_path.read_bytes()).hexdigest(),
    'state': p198['construction_review']['state'],
  },
  'accepted_artifact_byte_binding': {
    'step': 197,
    'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze-policy.json',
    'policy_sha256': hashlib.sha256(p197_path.read_bytes()).hexdigest(),
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.tsv',
    'record_sha256': hashlib.sha256(r197_path.read_bytes()).hexdigest(),
    'state': binding['state'],
    'evidence_root': binding['evidence_root'],
    'evidence_root_must_remain_unchanged': True,
    'binding_evidence_sha256': binding['binding_evidence_sha256'],
    'acquired_files_manifest_sha256': binding['acquired_files_manifest_sha256'],
    'signing_key_fingerprint': binding['signing_key']['fingerprint'],
    'predecessor_package_sha256': binding['package_pair']['predecessor_package_sha256'],
    'target_package_sha256': binding['package_pair']['target_package_sha256'],
    'survives_later_publication': True,
  },
  'selected_family': {
    'family': 'kernel-package-edge',
    'scenario_count': 1,
    'selected_scenario': 'Kernel headers update without a kernel image update.',
    'selection_preserved': True,
    'family_closed': False,
  },
  'deferred_local_source': {
    'builder_path': p198['construction_review']['planned_builder_path'],
    'builder_implementation_state': 'not-implemented',
    'local_source_tree_built': False,
    'local_source_tree_manifest_bound': False,
    'runtime_root': p198['construction_review']['runtime_root'],
    'runtime_mirror_uri': p198['construction_review']['runtime_mirror_uri'],
    'target_artifact': p198['construction_review']['target_artifact'],
    'target_package_sha256': p198['construction_review']['target_package_sha256'],
    'predecessor_artifact_must_not_be_exposed_by_local_source': True,
  },
  'runtime_boundary': {
    'prior_target_binding_reusable_after_pause': False,
    'fresh_target_revalidation_required_before_any_machine_action': True,
    'fresh_candidate_set_required_before_runtime': True,
    'runtime_network_access_forbidden': True,
    'package_action_authorized': False,
    'boot_action_authorized': False,
    'reboot_authorized': False,
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
    'future_work_requires_fresh_boundary': True,
    'future_machine_work_requires_fresh_target_revalidation': True,
  },
  'safe_pause': {
    'pause_safe': True,
    'strong_safe_pause': True,
    'machine_action_required': False,
    'controller_action_required': False,
    'no_open_operational_authorization': True,
    'later_slackware_current_publication_invalidates_checkpoint': False,
    'accepted_artifact_byte_binding_remains_valid_across_publication': True,
    'prior_runtime_target_observation_must_not_be_reused': True,
    'external_evidence_root_must_be_preserved': True,
  },
  'gates': {
    'acceptance_matrix_complete': False,
    'kernel_package_edge_family_closed': False,
    'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
    'c_port_status': 'blocked-by-phase-1-gate',
    'phase_2_start_authorized': False,
  },
  'continuation': {
    'next_stage': 'phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review',
    'selected_family_preserved': True,
    'builder_implementation_requires_fresh_boundary': True,
    'target_copy_requires_fresh_boundary': True,
    'target_revalidation_required_before_machine_action': True,
    'repository_or_network_refresh_requires_explicit_authorization': True,
    'no_runtime_candidate_set_is_bound': True,
  },
  'helper_path': 'tools/reference/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause.sh',
  'helper_sha256': helper_sha,
  'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause.tsv',
  'next_stage': 'phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review',
  'pause_safe': True,
}
out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')

rows = [
  ('pause_state','strong-safe-pause'),
  ('pause_safe','yes'),
  ('strong_safe_pause','yes'),
  ('selected_family','kernel-package-edge'),
  ('selected_scenario','Kernel headers update without a kernel image update.'),
  ('family_closed','no'),
  ('accepted_step_198_policy_sha256',hashlib.sha256(p198_path.read_bytes()).hexdigest()),
  ('accepted_step_198_record_sha256',hashlib.sha256(r198_path.read_bytes()).hexdigest()),
  ('artifact_byte_binding_state',binding['state']),
  ('evidence_root',binding['evidence_root']),
  ('evidence_root_must_remain_unchanged','yes'),
  ('binding_evidence_sha256',binding['binding_evidence_sha256']),
  ('acquired_files_manifest_sha256',binding['acquired_files_manifest_sha256']),
  ('predecessor_package_sha256',binding['package_pair']['predecessor_package_sha256']),
  ('target_package_sha256',binding['package_pair']['target_package_sha256']),
  ('artifact_binding_survives_later_publication','yes'),
  ('builder_implementation_state','not-implemented'),
  ('local_source_tree_built','no'),
  ('local_source_tree_manifest_bound','no'),
  ('prior_target_binding_reusable_after_pause','no'),
  ('fresh_target_revalidation_required_before_any_machine_action','yes'),
  ('fresh_candidate_set_required_before_runtime','yes'),
  ('source_change_authorized','no'),
  ('documentation_change_authorized','no'),
  ('controller_artifact_acquisition_authorized','no'),
  ('controller_network_access_authorized','no'),
  ('repository_refresh_authorized','no'),
  ('network_refresh_authorized','no'),
  ('target_vm_action_authorized','no'),
  ('target_vm_network_access_authorized','no'),
  ('target_artifact_copy_authorized','no'),
  ('local_source_build_authorized','no'),
  ('runtime_executor_implementation_authorized','no'),
  ('runtime_scenario_execution_authorized','no'),
  ('package_action_authorized','no'),
  ('boot_action_authorized','no'),
  ('reboot_authorized','no'),
  ('phase_2_start_authorized','no'),
  ('machine_action_required','no'),
  ('controller_action_required','no'),
  ('no_open_operational_authorization','yes'),
  ('later_slackware_current_publication_invalidates_checkpoint','no'),
  ('future_work_requires_fresh_boundary','yes'),
  ('acceptance_matrix_complete','no'),
  ('next_stage','phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review'),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PYGEN

printf 'Strong safe pause review completed successfully.\n'
printf 'policy\t%s\nrecord\t%s\n' "$policy" "$record"
