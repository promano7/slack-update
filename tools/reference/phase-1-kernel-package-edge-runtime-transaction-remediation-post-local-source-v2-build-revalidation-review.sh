#!/bin/bash
set -euo pipefail
IFS=$'\n\t'
export LC_ALL=C

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review.sh [--output-dir DIR] [--help]

Consume the accepted Phase 1 step-231 repository-only resume boundary and open
exactly one read-only post-v2-build target revalidation. The authorized probe
verifies fresh target state plus the accepted local-source-v2 manifest, sidecar,
tree, staged target, preserved v1 source, and failed-run evidence. It authorizes
no package, Slackpkg, repository/network, runtime, boot, reboot, or cleanup action.
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
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review.sh"
probe_path="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review-probe.sh"
step231_helper="$repo_root/tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review.sh"
step231_doc="$repo_root/docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review.md"
step231_harness="$repo_root/tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review-harness.sh"
step231_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review-policy.json"
step231_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review.tsv"

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

for required in "$helper_path" "$probe_path" "$step231_helper" "$step231_doc" "$step231_harness" "$step231_policy" "$step231_record"; do
    require_regular "$required"
done
check_hash "$step231_helper" '82a5fd1a4d0e8407484e406b5e337761967a5f8ea97e1a85ddde69d544516f4b'
check_hash "$step231_doc" 'c7173fadb533dafa895056733e175f096fdf100b79832d9803551d2b3ee01fb4'
check_hash "$step231_harness" 'eceb685682ceaa37323acb471bea59edc741badaba785a99978512f8e0ecdecf'
check_hash "$step231_policy" 'cbdf94615bd349cc5196297dec52338638fcc5aa3f1200ae674e7fc2fc04ec0d'
check_hash "$step231_record" 'cd0175b12d697d51eef5e7916438f1d3ec72db891375d47588cff445d9d65e76'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')
step231_policy_sha=$(sha256sum -- "$step231_policy" | awk '{print $1}')
step231_record_sha=$(sha256sum -- "$step231_record" | awk '{print $1}')

python3 - "$step231_policy" "$step231_record" "$policy" "$record" "$helper_sha" "$probe_sha" "$step231_policy_sha" "$step231_record_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p231_path, r231_path, out_policy_path, out_record_path = map(Path, sys.argv[1:5])
helper_sha, probe_sha, p231_sha, r231_sha = sys.argv[5:9]
p231 = json.loads(p231_path.read_text(encoding='utf-8'))
with r231_path.open(encoding='utf-8', newline='') as handle:
    r231 = dict(csv.reader(handle, delimiter='\t'))

assert p231['scenario'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-resume-planning-boundary-review'
assert p231['step'] == 231 and p231['review_status'] == 'PASS'
assert p231['fresh_boundary']['opened'] is True
assert p231['accepted_local_source_v2']['tree_manifest_sha256'] == 'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'
assert p231['revalidation_boundary']['fresh_target_revalidation_required_before_any_machine_action'] is True
assert p231['revalidation_boundary']['accepted_local_source_v2_tree_revalidation_required_before_runtime_use'] is True
assert p231['revalidation_boundary']['target_observation_authorized_now'] is False
assert p231['authorization']['package_action_authorized'] is False
assert p231['authorization']['runtime_rerun_authorized'] is False
assert r231['step'] == '231'
assert r231['next_stage'] == 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review'

policy = {
  'schema': 1,
  'scenario': 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review',
  'step': 232,
  'review_only': True,
  'review_status': 'PASS',
  'accepted_step_231': {
    'policy_sha256': p231_sha,
    'record_sha256': r231_sha,
    'fresh_boundary_preserved': True,
    'prior_machine_authority_reused': False,
  },
  'probe': {
    'path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review-probe.sh',
    'sha256': probe_sha,
    'execution_target': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'execution_acknowledgement': '--observe-post-v2-build-revalidation',
    'exact_command': 'sudo bash phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review-probe.sh --observe-post-v2-build-revalidation',
    'repository_on_target_required': False,
    'privilege_boundary': 'root-via-sudo',
    'read_only': True,
    'network_access_allowed': False,
    'repository_refresh_allowed': False,
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
    'local_source_v1_tree_manifest_sha256': '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e',
    'local_source_v1_must_be_preserved_unchanged': True,
    'failed_runtime_evidence_root_must_be_preserved_unchanged': True,
    'failed_success_result_must_remain_absent': True,
    'published_success_evidence_must_remain_absent': True,
    'local_source_v2_temporary_build_roots_must_be_absent': True,
  },
  'accepted_local_source_v2': {
    'root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2',
    'tree_manifest': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256',
    'tree_manifest_sha256': 'e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945',
    'tree_manifest_sha256_sidecar': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2.tree.sha256.sha256',
    'target_package': 'kernel-headers-6.18.45-x86-1.txz',
    'target_relative_path': 'slackware64/d/kernel-headers-6.18.45-x86-1.txz',
    'target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'priority_trees': ['patches', 'slackware64', 'extra', 'pasture', 'testing'],
    'compatibility_asc_required': True,
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
    'compatibility_asc_must_not_claim_authenticity': True,
  },
  'runtime_boundary': {
    'fresh_candidate_set_bound_by_this_step': False,
    'runtime_executor_remediation_performed_by_this_step': False,
    'runtime_executor_remediation_review_required_before_rerun': True,
    'runtime_rerun_authorized': False,
    'future_refresh_must_use_v2': True,
    'future_refresh_workdir_strategy': 'transaction-owned-new-empty-workdir',
    'future_candidate_guard_scope': 'target-specific-not-global-pkglist-row-count',
    'future_evidence_encoding': 'real-tab-tsv',
  },
  'authorization': {
    'target_observation_authorized': True,
    'probe_transport_copy_authorized': True,
    'probe_execution_authorized': True,
    'probe_execution_use_count': 1,
    'local_source_v2_tree_revalidation_authorized_as_probe_read_only_operation': True,
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
  'machine_action_required': True,
  'controller_action_required': True,
  'future_work_requires_explicit_authorization': True,
  'pause_safe': False,
  'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze',
}

record_rows = [
 ('step','232'),
 ('review_status','PASS'),
 ('accepted_step_231','yes'),
 ('fresh_boundary_preserved','yes'),
 ('prior_machine_authority_reused','no'),
 ('probe_sha256',probe_sha),
 ('probe_transport_copy_authorized','yes'),
 ('target_observation_authorized','yes'),
 ('probe_execution_authorized','yes'),
 ('probe_execution_use_count','1'),
 ('fresh_boot_id_must_be_observed','yes'),
 ('historical_boot_id_reusable','no'),
 ('package_database_manifest_expected','726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'),
 ('staged_target_sha256','c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c'),
 ('local_source_v1_tree_manifest_sha256','0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'),
 ('local_source_v2_tree_manifest_sha256','e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945'),
 ('local_source_v2_tree_manifest_sidecar_must_verify','yes'),
 ('local_source_v2_manifest_exact_coverage_required','yes'),
 ('local_source_v2_priority_tree_contract_must_verify','yes'),
 ('local_source_v2_compatibility_asc_must_verify','yes'),
 ('failed_runtime_evidence_must_remain_unchanged','yes'),
 ('candidate_set_bound','no'),
 ('runtime_executor_remediation_authorized','no'),
 ('runtime_rerun_authorized','no'),
 ('package_action_authorized','no'),
 ('slackpkg_mutation_authorized','no'),
 ('repository_refresh_authorized','no'),
 ('network_access_authorized','no'),
 ('boot_action_authorized','no'),
 ('reboot_authorized','no'),
 ('evidence_cleanup_authorized','no'),
 ('phase_2_start_authorized','no'),
 ('machine_action_required','yes'),
 ('controller_action_required','yes'),
 ('future_work_requires_explicit_authorization','yes'),
 ('pause_safe','no'),
 ('next_stage','phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze'),
]
out_policy_path.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
with out_record_path.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(record_rows)
PY
