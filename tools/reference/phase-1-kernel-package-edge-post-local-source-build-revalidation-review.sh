#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-post-local-source-build-revalidation-review.sh [--output-dir DIR] [--help]

Freeze the Phase 1 step-212 combined post-build revalidation gate. This helper
does not probe a live machine. It authorizes only the exact standalone
read-only probe that reobserves the target and verifies the preserved staged
target and local-source tree before candidate binding.
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
step211_policy="$acceptance_dir/phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review-policy.json"
step211_record="$acceptance_dir/phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review.tsv"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-review.sh"
probe_path="$repo_root/tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-probe.sh"
builder_path="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"
stager_path="$repo_root/tools/reference/phase-1-kernel-package-edge-target-artifact-stage.sh"

require_regular() {
    local file=$1
    [[ -f $file && ! -L $file ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$file" >&2; exit 3; }
}
check_hash() {
    local file=$1 expected=$2 actual
    actual=$(sha256sum -- "$file" | awk '{print $1}')
    [[ $actual == "$expected" ]] || { printf 'ERROR: accepted prerequisite SHA-256 mismatch: %s\nexpected: %s\nactual:   %s\n' "$file" "$expected" "$actual" >&2; exit 4; }
}
for required in "$step211_policy" "$step211_record" "$helper_path" "$probe_path" "$builder_path" "$stager_path"; do
    require_regular "$required"
done
check_hash "$step211_policy" '32ba643c74b1553531d35cdecc5106be5c5dac11b24f7c9a13e8607bb15fa5ca'
check_hash "$step211_record" '78bc6a56756819ba6e55c1ef6fd87625c4a4af9a7df50cfe858e3efc44166518'
check_hash "$probe_path" '44a68d5e63b873c5df836cccb4ffa525852e45a15fda0b332a7ee6ef56899383'
check_hash "$builder_path" '59a6a2bf27b7f48cecf8016c63205b8b6c558ed4a0b1bbd2b7523f0d6108ba92'
check_hash "$stager_path" 'a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb'

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-post-local-source-build-revalidation-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-post-local-source-build-revalidation-review.tsv"
step211_policy_sha=$(sha256sum -- "$step211_policy" | awk '{print $1}')
step211_record_sha=$(sha256sum -- "$step211_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')

python3 - "$step211_policy" "$step211_record" "$policy" "$record" "$step211_policy_sha" "$step211_record_sha" "$helper_sha" "$probe_sha" <<'PY'
import csv, json, sys
from pathlib import Path
p211_path, r211_path, out_policy, out_record = map(Path, sys.argv[1:5])
p211_sha, r211_sha, helper_sha, probe_sha = sys.argv[5:9]
p211 = json.loads(p211_path.read_text(encoding='utf-8'))
with r211_path.open(encoding='utf-8', newline='') as h:
    r211 = dict(csv.reader(h, delimiter='\t'))
assert p211['scenario'] == 'phase-1-kernel-package-edge-post-local-source-build-resume-planning-boundary-review'
assert p211['fresh_boundary']['opened'] is True
assert p211['runtime_revalidation']['prior_target_binding_reusable'] is False
assert p211['runtime_revalidation']['fresh_target_revalidation_required_before_any_machine_action'] is True
assert p211['runtime_revalidation']['local_source_tree_revalidation_required_before_runtime'] is True
assert p211['runtime_revalidation']['fresh_candidate_set_required_before_runtime'] is True
assert p211['local_source_state']['tree_manifest_sha256'] == '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'
assert r211['step'] == '211'
assert r211['prior_target_binding_reusable'] == 'no'
assert r211['fresh_target_observation_authorized_now'] == 'no'
assert r211['local_source_tree_revalidation_authorized_now'] == 'no'

policy = {
  'schema': 1,
  'scenario': 'phase-1-kernel-package-edge-post-local-source-build-revalidation-review',
  'review_only': True,
  'accepted_step_211': {
    'policy_sha256': p211_sha,
    'record_sha256': r211_sha,
    'fresh_boundary_preserved': True,
  },
  'probe': {
    'path': 'tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-probe.sh',
    'sha256': probe_sha,
    'execution_target': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'execution_acknowledgement': '--observe-post-build-revalidation',
    'exact_command': 'sudo bash phase-1-kernel-package-edge-post-local-source-build-revalidation-probe.sh --observe-post-build-revalidation',
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
  },
  'preserved_artifacts': {
    'predecessor_artifact': 'kernel-headers-6.18.44-x86-1.txz',
    'predecessor_sha256': '3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d',
    'target_artifact': 'kernel-headers-6.18.45-x86-1.txz',
    'target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'staged_target_path': '/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz',
    'staged_target_must_remain_unchanged': True,
  },
  'local_source_revalidation': {
    'local_source_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source',
    'tree_manifest_path': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256',
    'tree_manifest_sha256_path': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256.sha256',
    'tree_manifest_sha256': '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e',
    'target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'expected_candidate_count': 1,
    'predecessor_must_be_absent': True,
    'tree_read_only_contract_must_hold': True,
    'verification_authorized': True,
    'rebuild_authorized': False,
  },
  'authorization': {
    'probe_transport_copy_authorized': True,
    'fresh_target_observation_authorized': True,
    'local_source_tree_revalidation_authorized': True,
    'staged_target_revalidation_authorized': True,
    'controller_network_access_authorized': False,
    'target_vm_network_access_authorized': False,
    'repository_refresh_authorized': False,
    'network_refresh_authorized': False,
    'builder_execution_authorized': False,
    'local_source_build_authorized': False,
    'stager_execution_authorized': False,
    'target_artifact_copy_authorized': False,
    'predecessor_package_staging_authorized': False,
    'runtime_candidate_refresh_authorized': False,
    'runtime_candidate_binding_authorized': False,
    'runtime_scenario_execution_authorized': False,
    'package_action_authorized': False,
    'slackpkg_configuration_change_authorized': False,
    'boot_action_authorized': False,
    'reboot_authorized': False,
    'phase_2_start_authorized': False,
  },
  'result_contract': {
    'pass_marker': 'revalidation_status\tPASS',
    'full_probe_output_required_for_next_step': True,
    'any_drift_fails_closed': True,
    'successful_observation_does_not_bind_candidate_set': True,
    'successful_observation_requires_repository_review_before_more_machine_action': True,
  },
  'machine_action_required': True,
  'machine_action_type': 'read-only-fresh-target-and-preserved-local-source-revalidation',
  'controller_action_required': True,
  'pause_safe': False,
  'strong_safe_pause': False,
  'helper_path': 'tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-review.sh',
  'helper_sha256': helper_sha,
  'next_stage': 'phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze',
}
out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
 ('step','212'),
 ('revision','combined-read-only-post-build-revalidation-authorization'),
 ('accepted_step_211_policy_sha256',p211_sha),
 ('accepted_step_211_record_sha256',r211_sha),
 ('probe_sha256',probe_sha),
 ('prior_target_binding_reusable','no'),
 ('fresh_target_observation_authorized','yes'),
 ('local_source_tree_revalidation_authorized','yes'),
 ('staged_target_revalidation_authorized','yes'),
 ('probe_transport_copy_authorized','yes'),
 ('expected_package_database_manifest_sha256','726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6'),
 ('local_source_root','/var/tmp/slack-update-acceptance/kernel-package-edge/local-source'),
 ('tree_manifest_sha256','0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e'),
 ('fresh_candidate_set_required','yes'),
 ('candidate_set_binding_authorized','no'),
 ('predecessor_package_staging_authorized','no'),
 ('builder_execution_authorized','no'),
 ('repository_refresh_authorized','no'),
 ('network_refresh_authorized','no'),
 ('runtime_scenario_execution_authorized','no'),
 ('package_action_authorized','no'),
 ('boot_action_authorized','no'),
 ('reboot_authorized','no'),
 ('machine_action_required','yes'),
 ('controller_action_required','yes'),
 ('pause_safe','no'),
 ('strong_safe_pause','no'),
 ('next_stage',policy['next_stage']),
]
with out_record.open('w', encoding='utf-8', newline='') as h:
    csv.writer(h, delimiter='\t', lineterminator='\n').writerows(rows)
PY

printf 'revalidation_review_status\tPASS\n'
printf 'probe_sha256\t%s\n' "$probe_sha"
printf 'fresh_target_observation_authorized\tyes\n'
printf 'local_source_tree_revalidation_authorized\tyes\n'
printf 'candidate_set_binding_authorized\tno\n'
printf 'machine_action_required\tyes\n'
printf 'next_stage\tphase-1-kernel-package-edge-post-local-source-build-revalidation-freeze\n'
