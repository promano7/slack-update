#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review.sh [--output-dir DIR] [--help]

Consume the accepted Phase 1 step-251 repository-only resume boundary and open
exactly one read-only post-v3-build target revalidation. The authorized probe
verifies fresh target state plus the accepted local-source-v3 manifest, sidecar,
tree, staged target, preserved v2 historical source, and failed-remediation
evidence. It authorizes no package, Slackpkg, repository/network, executor,
runtime, boot, reboot, cleanup, or persistent configuration action.
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
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review.sh"
probe_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review-probe.sh"
step251_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review.sh"
step251_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review.md"
step251_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review-harness.sh"
step251_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review-policy.json"
step251_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review.tsv"

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

for required in "$helper_path" "$probe_path" "$step251_helper" "$step251_doc" "$step251_harness" "$step251_policy" "$step251_record"; do
    require_regular "$required"
done
check_hash "$step251_helper" '4f1313ecdfb852e055c7c316cdfa0d88343f7553c8cb44dd7b4980175a09163d'
check_hash "$step251_doc" '30fb7202fa0142c3ce308b4c6071c84128bfcd791207858c1d9cb6a7d4c198fc'
check_hash "$step251_harness" '07c41402c26335f6f36607993a84c1460f7a66648ceb5d4e19fae327a2aee2e4'
check_hash "$step251_policy" '8bf9a935033695491467abb1bc24af4437a3dcb454e25914094c4d0f2c222cba'
check_hash "$step251_record" '50fa21c28ac444ef7edbe379cb204f6d649d4e78bd64480df1b0fe6f568309c6'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')
step251_policy_sha=$(sha256sum -- "$step251_policy" | awk '{print $1}')
step251_record_sha=$(sha256sum -- "$step251_record" | awk '{print $1}')

python3 - "$step251_policy" "$step251_record" "$policy" "$record" "$helper_sha" "$probe_sha" "$step251_policy_sha" "$step251_record_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p251_path, r251_path, out_policy_path, out_record_path = map(Path, sys.argv[1:5])
helper_sha, probe_sha, p251_sha, r251_sha = sys.argv[5:9]
p251 = json.loads(p251_path.read_text(encoding='utf-8'))
with r251_path.open(encoding='utf-8', newline='') as handle:
    r251 = dict(csv.reader(handle, delimiter='\t'))

assert p251['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-resume-planning-boundary-review'
assert p251['step'] == 251 and p251['review_status'] == 'PASS'
assert p251['fresh_boundary']['opened'] is True
assert p251['accepted_local_source_v3']['tree_manifest_sha256'] == '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'
assert p251['revalidation_boundary']['fresh_target_revalidation_required_before_any_machine_action'] is True
assert p251['revalidation_boundary']['accepted_local_source_v3_tree_revalidation_required_before_executor_implementation_or_runtime_use'] is True
assert p251['revalidation_boundary']['target_observation_authorized_now'] is False
assert p251['runtime_executor_v2_boundary']['human_spaced_error_prefix_required'] == 'Error downloading from '
assert p251['runtime_executor_v2_boundary']['hyphenated_error_literal_guard_forbidden'] is True
assert p251['authorization']['runtime_executor_v2_implementation_authorized'] is False
assert p251['authorization']['runtime_rerun_authorized'] is False
assert r251['step'] == '251'
assert r251['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review'

policy = {
  'schema': 1,
  'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review',
  'step': 252,
  'review_only': True,
  'review_status': 'PASS',
  'accepted_step_251': {
    'policy_sha256': p251_sha,
    'record_sha256': r251_sha,
    'fresh_boundary_preserved': True,
    'accepted_v3_manifest_binding_preserved': True,
    'prior_machine_authority_reused': False,
  },
  'probe': {
    'path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review-probe.sh',
    'sha256': probe_sha,
    'execution_target': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'execution_acknowledgement': '--observe-post-v3-build-revalidation',
    'exact_command': 'sudo bash phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-review-probe.sh --observe-post-v3-build-revalidation',
    'repository_on_target_required': False,
    'privilege_boundary': 'root-via-sudo',
    'read_only': True,
    'network_access_allowed': False,
    'repository_refresh_allowed': False,
    'authorization_use_count': 1,
  },
  'expected_target_baseline': {
    'fqdn': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'uname_machine': 'x86_64',
    'uname_release': '6.18.45',
    'slackware_version': 'Slackware 15.0+',
    'package_database_manifest_sha256': '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
    'header_package_record': 'kernel-headers-6.18.45-x86-1',
    'kernel_generic_record': 'kernel-generic-6.18.45-x86_64-1',
    'kernel_huge_absent': True,
    'kernel_modules_absent': True,
    'slackpkg_conf_sha256': 'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
    'slackpkg_mirrors_sha256': '71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
    'historical_boot_id_reusable': False,
    'fresh_boot_id_must_be_observed': True,
    'fresh_boot_id_may_equal_prior_observed_boot_id': True,
  },
  'preservation_contract': {
    'staged_target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'staged_target_must_be_preserved_unchanged': True,
    'local_source_v2_tree_manifest_sha256': 'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
    'local_source_v2_historical_no_PGP_state_must_be_preserved': True,
    'failed_remediation_evidence_root_must_be_preserved_unchanged': True,
    'failed_remediation_success_result_must_remain_absent': True,
    'published_remediation_success_evidence_must_remain_absent': True,
    'local_source_v3_temporary_build_roots_must_be_absent': True,
  },
  'accepted_local_source_v3': {
    'root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3',
    'tree_manifest': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256',
    'tree_manifest_sha256': '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b',
    'tree_manifest_sha256_sidecar': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256.sha256',
    'target_package': 'kernel-headers-6.18.45-x86-1.txz',
    'target_relative_path': 'slackware64/d/kernel-headers-6.18.45-x86-1.txz',
    'target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'priority_trees': ['patches', 'slackware64', 'extra', 'pasture', 'testing'],
    'compatibility_asc_required': True,
    'compatibility_PGP_marker': 'PGP compatibility marker for Slackpkg checkchangelog only.',
    'compatibility_asc_must_not_claim_authenticity': True,
    'openpgp_signature_block_forbidden': True,
    'manifest_sidecar_must_verify': True,
    'tree_contents_must_verify_against_manifest': True,
    'manifest_must_cover_exact_regular_file_set': True,
    'exact_generated_regular_file_count': 11,
    'unexpected_symlinks_or_other_nodes_allowed': False,
    'final_tree_owner': 'root:root',
    'final_directory_mode': '0555',
    'final_regular_file_mode': '0444',
    'predecessor_archive_must_be_absent': True,
    'target_package_archive_count': 1,
    'priority_tree_contract_must_verify': True,
  },
  'executor_v2_boundary': {
    'contract_frozen_and_bound_to_v3_manifest': True,
    'implementation_performed_by_this_step': False,
    'implementation_authorized': False,
    'transport_authorized': False,
    'runtime_authorized': False,
    'human_spaced_error_prefix': 'Error downloading from ',
    'human_spaced_error_prefix_record_encoding': 'hex:4572726f7220646f776e6c6f6164696e672066726f6d20',
    'hyphenated_literal_guard_forbidden': True,
    'fresh_transaction_owned_pkglist_required': True,
    'same_transaction_candidate_binding_required': True,
    'fresh_candidate_set_bound_by_this_step': False,
  },
  'authorization': {
    'target_observation_authorized': True,
    'probe_transport_copy_authorized': True,
    'probe_execution_authorized': True,
    'probe_execution_use_count': 1,
    'local_source_v3_tree_revalidation_authorized_as_probe_read_only_operation': True,
    'runtime_executor_v2_implementation_authorized': False,
    'runtime_executor_v2_transport_authorized': False,
    'runtime_candidate_binding_authorized': False,
    'runtime_rerun_authorized': False,
    'package_action_authorized': False,
    'slackpkg_mutation_authorized': False,
    'repository_refresh_authorized': False,
    'network_access_authorized': False,
    'boot_action_authorized': False,
    'reboot_authorized': False,
    'evidence_cleanup_authorized': False,
    'persistent_configuration_change_authorized': False,
    'phase_2_start_authorized': False,
  },
  'machine_action_required': True,
  'controller_action_required': True,
  'future_work_requires_explicit_authorization': True,
  'pause_safe': False,
  'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze',
  'helper_sha256': helper_sha,
}

record_rows = [
    ('step', '252'),
    ('review_status', 'PASS'),
    ('accepted_step_251', 'yes'),
    ('fresh_boundary_preserved', 'yes'),
    ('accepted_v3_manifest_binding_preserved', 'yes'),
    ('prior_machine_authority_reused', 'no'),
    ('probe_sha256', probe_sha),
    ('probe_transport_copy_authorized', 'yes'),
    ('target_observation_authorized', 'yes'),
    ('probe_execution_authorized', 'yes'),
    ('probe_execution_use_count', '1'),
    ('fresh_boot_id_must_be_observed', 'yes'),
    ('historical_boot_id_reusable', 'no'),
    ('package_database_manifest_expected', '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'),
    ('staged_target_sha256', 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'),
    ('local_source_v2_tree_manifest_sha256', 'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'),
    ('local_source_v2_historical_no_PGP_state_preserved', 'yes'),
    ('local_source_v3_tree_manifest_sha256', '8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b'),
    ('local_source_v3_tree_manifest_sidecar_must_verify', 'yes'),
    ('local_source_v3_manifest_exact_coverage_required', 'yes'),
    ('local_source_v3_priority_tree_contract_must_verify', 'yes'),
    ('local_source_v3_compatibility_PGP_marker_must_verify', 'yes'),
    ('human_spaced_error_prefix_hex', '4572726f7220646f776e6c6f6164696e672066726f6d20'),
    ('hyphenated_error_literal_guard_forbidden', 'yes'),
    ('failed_remediation_evidence_must_remain_unchanged', 'yes'),
    ('candidate_set_bound', 'no'),
    ('runtime_executor_v2_implementation_authorized', 'no'),
    ('runtime_executor_v2_transport_authorized', 'no'),
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
    ('controller_action_required', 'yes'),
    ('future_work_requires_explicit_authorization', 'yes'),
    ('pause_safe', 'no'),
    ('next_stage', 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze'),
]

out_policy_path.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
with out_record_path.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(record_rows)
PY
