#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review.sh [--output-dir DIR] [--help]

Consume the accepted Phase 1 step-221 repository-only planning boundary and
open exactly one read-only fresh target revalidation observation. No package,
Slackpkg, network, boot, reboot, evidence cleanup, or remediation build action
is authorized by this review.
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
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review.sh"
probe_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review-probe.sh"
step221_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review.sh"
step221_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review.md"
step221_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review-harness.sh"
step221_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review-policy.json"
step221_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review.tsv"
step213_policy="$acceptance_dir/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze-policy.json"
step217_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review-policy.json"
step219_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-failure-characterization-freeze-and-remediation-boundary-review-policy.json"

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

for required in "$helper_path" "$probe_path" "$step221_helper" "$step221_doc" "$step221_harness" "$step221_policy" "$step221_record" "$step213_policy" "$step217_policy" "$step219_policy"; do
    require_regular "$required"
done
check_hash "$step221_helper" '8efa5d798e28b42bbb8aa6adea08e6a35c0e462e549149cc836e3aff54f12bc6'
check_hash "$step221_doc" '373ebbd547cfa2ad2565c1aad1ac03d8566f3ee8c4e7509639278122fa0d34c0'
check_hash "$step221_harness" '25de59dcb66a29f477e074d91266855c334d508cbda3d86e89c92f171528e47d'
check_hash "$step221_policy" '692b37f0694e25dbed809d44a1abfa478d9deb14c769cd8d9834dba110747de4'
check_hash "$step221_record" '497100fe5e6a6838cce16ea6688e57abdb7dc8f152f3bf127c63bcbb4755a25b'
check_hash "$step213_policy" 'ae790c0b857f64961ed267c19b7db58f33f447c260e0f6659217ddeba32c18eb'
check_hash "$step217_policy" 'ac49b4b12a9478351761f948d66cca7afaa225a18a2e1e4a7834ed84bfd8bdec'
check_hash "$step219_policy" '6a55e2e600dbb192cb7e14e9d3514a9a6dd7ab2ac019fd7478f84d631c670d75'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')

python3 - "$step221_policy" "$step221_record" "$step213_policy" "$step217_policy" "$step219_policy" "$policy" "$record" "$helper_sha" "$probe_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p221_path, r221_path, p213_path, p217_path, p219_path, out_policy_path, out_record_path = map(Path, sys.argv[1:8])
helper_sha, probe_sha = sys.argv[8:10]

p221 = json.loads(p221_path.read_text(encoding='utf-8'))
p213 = json.loads(p213_path.read_text(encoding='utf-8'))
p217 = json.loads(p217_path.read_text(encoding='utf-8'))
p219 = json.loads(p219_path.read_text(encoding='utf-8'))
with r221_path.open(encoding='utf-8', newline='') as handle:
    r221 = dict(csv.reader(handle, delimiter='\t'))

assert p221['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-resume-planning-boundary-review'
assert p221['step'] == 221 and p221['review_status'] == 'PASS'
assert p221['fresh_boundary']['opened'] is True
assert p221['runtime_revalidation']['fresh_target_revalidation_required_before_any_machine_action'] is True
assert p221['runtime_revalidation']['target_observation_authorized_now'] is False
assert p221['runtime_revalidation']['prior_target_binding_reusable'] is False
assert p221['runtime_revalidation']['prior_runtime_authorization_reusable'] is False
assert p221['remediation_contract']['new_local_source_generation_name'] == 'local-source-v2'
assert p221['preservation_contract']['local_source_v1_must_be_preserved_unchanged'] is True
assert p221['preservation_contract']['failed_runtime_evidence_root_must_be_preserved_unchanged'] is True
assert p221['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review'
assert r221['target_observation_authorized_now'] == 'no'
assert r221['runtime_rerun_authorized'] == 'no'

accepted213 = p213['accepted_revalidation_evidence']
assert accepted213['status'] == 'PASS'
assert accepted213['package_database_manifest_sha256'] == '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'
assert accepted213['header_package_record'] == 'kernel-headers-6.18.45-x86-1'
assert accepted213['local_source_tree_verified'] is True
assert accepted213['tree_manifest_sha256'] == '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'
assert accepted213['staged_target_sha256'] == 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'
assert p217['runtime_authorization']['required_package_database_manifest_sha256'] == accepted213['package_database_manifest_sha256']
assert p217['runtime_authorization']['required_final_state']['package_database_manifest_sha256'] == accepted213['package_database_manifest_sha256']
assert p219['failure_characterization_status'] == 'PASS'
assert p219['cleanup_triggered'] is True
assert p219['header_restored'] is True
assert p219['package_database_restored'] is True
assert p219['slackpkg_configuration_restored'] is True
assert p219['slackpkg_state_restored'] is True
assert p219['geninitrd_policy_restored'] is True
assert p219['boot_artifacts_unchanged'] is True
assert p219['published_success_evidence_absent'] is True

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review',
    'step': 222,
    'review_only': True,
    'review_status': 'PASS',
    'accepted_resume_boundary': {
        'step': 221,
        'helper_sha256': '8efa5d798e28b42bbb8aa6adea08e6a35c0e462e549149cc836e3aff54f12bc6',
        'document_sha256': '373ebbd547cfa2ad2565c1aad1ac03d8566f3ee8c4e7509639278122fa0d34c0',
        'harness_sha256': '25de59dcb66a29f477e074d91266855c334d508cbda3d86e89c92f171528e47d',
        'policy_sha256': '692b37f0694e25dbed809d44a1abfa478d9deb14c769cd8d9834dba110747de4',
        'record_sha256': '497100fe5e6a6838cce16ea6688e57abdb7dc8f152f3bf127c63bcbb4755a25b',
        'strong_safe_pause_origin_step': 220,
        'prior_target_binding_reusable': False,
        'prior_runtime_authorization_reusable': False,
        'prior_candidate_binding_reusable': False,
    },
    'historical_restored_baseline': {
        'post_local_source_revalidation_step': 213,
        'failed_runtime_characterization_step': 219,
        'historical_runtime_authorization_step': 217,
        'historical_runtime_authorization_reusable': False,
        'expected_hostname_fqdn': 'vbox-slackcurrent.vbox-slackcurrent.org',
        'expected_uname_machine': 'x86_64',
        'expected_uname_release': '6.18.45',
        'expected_slackware_version': 'Slackware 15.0+',
        'expected_package_database_manifest_sha256': accepted213['package_database_manifest_sha256'],
        'expected_header_package_record': accepted213['header_package_record'],
        'expected_kernel_generic_record': accepted213['kernel_generic_record'],
        'expected_kernel_huge_status': 'absent',
        'expected_kernel_modules_status': 'absent',
        'expected_slackpkg_conf_sha256': accepted213['slackpkg_conf_sha256'],
        'expected_slackpkg_mirrors_sha256': accepted213['slackpkg_mirrors_sha256'],
        'expected_staged_target_sha256': accepted213['staged_target_sha256'],
        'expected_local_source_v1_tree_manifest_sha256': accepted213['tree_manifest_sha256'],
        'failed_transaction_cleanup_accepted': True,
        'failed_transaction_success_evidence_must_remain_absent': True,
    },
    'preservation_contract': dict(p221['preservation_contract']),
    'remediation_contract': {
        **p221['remediation_contract'],
        'design_authorized_now': False,
        'build_authorized_now': False,
        'runtime_validation_authorized_now': False,
    },
    'fresh_target_revalidation': {
        'state': 'read-only-observation-authorized',
        'probe_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review-probe.sh',
        'probe_sha256': probe_sha,
        'probe_execution': 'root-via-sudo',
        'acknowledgement': '--observe-fresh-target-revalidation',
        'probe_scope': 'standalone-read-only-restored-target-and-preserved-evidence-revalidation',
        'fresh_boot_id_required': True,
        'previous_boot_id_match_required': False,
        'previous_boot_id_must_not_be_used_as_binding': True,
        'package_database_compatibility_path_required': True,
        'local_source_v1_tree_verification_required': True,
        'local_source_v1_CHECKSUMS_md5_asc_must_remain_absent': True,
        'staged_target_verification_required': True,
        'failed_evidence_root_presence_required': True,
        'failed_success_result_must_remain_absent': True,
        'published_success_evidence_must_remain_absent': True,
        'boot_artifacts_must_match_failed_preflight': True,
        'slackpkg_state_must_match_failed_preflight': True,
        'geninitrd_policy_must_match_failed_preflight': True,
        'observation_output_must_be_returned_for_freeze': True,
        'live_candidate_set_bound': False,
        'repository_refresh_allowed': False,
        'network_access_allowed': False,
        'package_mutation_allowed': False,
        'slackpkg_mutation_allowed': False,
        'boot_mutation_allowed': False,
        'persistent_configuration_change_allowed': False,
        'reboot_allowed': False,
    },
    'authorization': {
        'target_observation_authorized': True,
        'fresh_target_revalidation_freeze_authorized_after_successful_observation': True,
        'probe_transport_copy_authorized': True,
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
    'machine_action_required': True,
    'machine_action_type': 'read-only-fresh-target-revalidation-observation',
    'controller_action_required': True,
    'controller_action_type': 'copy-exact-probe-to-target-and-verify-sha256',
    'pause_safe': False,
    'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze',
}

out_policy_path.write_text(json.dumps(policy, indent=2, sort_keys=False) + '\n', encoding='utf-8')
rows = [
    ('step', '222'),
    ('review_status', 'PASS'),
    ('accepted_resume_boundary_step', '221'),
    ('strong_safe_pause_origin_step', '220'),
    ('prior_target_binding_reusable', 'no'),
    ('prior_runtime_authorization_reusable', 'no'),
    ('prior_candidate_binding_reusable', 'no'),
    ('fresh_target_revalidation_state', 'read-only-observation-authorized'),
    ('revalidation_probe_path', policy['fresh_target_revalidation']['probe_path']),
    ('revalidation_probe_sha256', probe_sha),
    ('probe_execution', 'root-via-sudo'),
    ('runtime_acknowledgement', '--observe-fresh-target-revalidation'),
    ('expected_hostname_fqdn', 'vbox-slackcurrent.vbox-slackcurrent.org'),
    ('expected_uname_machine', 'x86_64'),
    ('expected_uname_release', '6.18.45'),
    ('expected_slackware_version', 'Slackware 15.0+'),
    ('expected_package_database_manifest_sha256', accepted213['package_database_manifest_sha256']),
    ('expected_header_package_record', accepted213['header_package_record']),
    ('expected_kernel_generic_record', accepted213['kernel_generic_record']),
    ('expected_slackpkg_conf_sha256', accepted213['slackpkg_conf_sha256']),
    ('expected_slackpkg_mirrors_sha256', accepted213['slackpkg_mirrors_sha256']),
    ('expected_staged_target_sha256', accepted213['staged_target_sha256']),
    ('expected_local_source_v1_tree_manifest_sha256', accepted213['tree_manifest_sha256']),
    ('fresh_boot_id_required', 'yes'),
    ('previous_boot_id_match_required', 'no'),
    ('local_source_v1_must_be_preserved_unchanged', 'yes'),
    ('failed_runtime_evidence_root_must_be_preserved_unchanged', 'yes'),
    ('local_source_v1_CHECKSUMS_md5_asc_must_remain_absent', 'yes'),
    ('failed_success_result_must_remain_absent', 'yes'),
    ('target_observation_authorized', 'yes'),
    ('probe_transport_copy_authorized', 'yes'),
    ('fresh_target_revalidation_freeze_authorized_after_successful_observation', 'yes'),
    ('local_source_v2_design_authorized', 'no'),
    ('local_source_v2_build_authorized', 'no'),
    ('runtime_rerun_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('slackpkg_mutation_authorized', 'no'),
    ('repository_refresh_authorized', 'no'),
    ('network_access_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('evidence_cleanup_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'yes'),
    ('machine_action_type', 'read-only-fresh-target-revalidation-observation'),
    ('controller_action_required', 'yes'),
    ('controller_action_type', 'copy-exact-probe-to-target-and-verify-sha256'),
    ('future_work_requires_explicit_authorization', 'yes'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze'),
]
with out_record_path.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

cat "$record"
