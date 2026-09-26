#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze.sh [--output-dir DIR] [--help]

Freeze the accepted Phase 1 step-212 post-build revalidation result as the
fresh target/local-source identity for subsequent candidate-set binding work.
This helper is repository-only and grants no machine or package authority.
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
step212_policy="$acceptance_dir/phase-1-kernel-package-edge-post-local-source-build-revalidation-review-policy.json"
step212_record="$acceptance_dir/phase-1-kernel-package-edge-post-local-source-build-revalidation-review.tsv"
step212_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-probe.sh"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze.sh"

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
for required in "$step212_policy" "$step212_record" "$step212_probe" "$helper_path"; do
    require_regular "$required"
done
check_hash "$step212_policy" 'ac920048e3b245ce032edc519521c9aee34f8254b1ccf530837cd4cd57d1028e'
check_hash "$step212_record" 'b1ce8d28abb4c72a548c6ac036f8a78b0c1915490c9930ebf646b9dee9fddff0'
check_hash "$step212_probe" '44a68d5e63b873c5df836cccb4ffa525852e45a15fda0b332a7ee6ef56899383'

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze-policy.json"
record="$output_dir/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze.tsv"
step212_policy_sha=$(sha256sum -- "$step212_policy" | awk '{print $1}')
step212_record_sha=$(sha256sum -- "$step212_record" | awk '{print $1}')
probe_sha=$(sha256sum -- "$step212_probe" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step212_policy" "$step212_record" "$policy" "$record" \
    "$step212_policy_sha" "$step212_record_sha" "$probe_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p212_path, r212_path, out_policy, out_record = map(Path, sys.argv[1:5])
p212_sha, r212_sha, probe_sha, helper_sha = sys.argv[5:9]
p212 = json.loads(p212_path.read_text(encoding='utf-8'))
with r212_path.open(encoding='utf-8', newline='') as handle:
    r212 = dict(csv.reader(handle, delimiter='\t'))

assert p212['scenario'] == 'phase-1-kernel-package-edge-post-local-source-build-revalidation-review'
assert p212['probe']['sha256'] == probe_sha
assert p212['authorization']['fresh_target_observation_authorized'] is True
assert p212['authorization']['local_source_tree_revalidation_authorized'] is True
assert p212['authorization']['runtime_candidate_binding_authorized'] is False
assert r212['step'] == '212'
assert r212['candidate_set_binding_authorized'] == 'no'

accepted = {
    'status': 'PASS',
    'target_hostname': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'hostname_fqdn': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'uname_release': '6.18.45',
    'uname_machine': 'x86_64',
    'slackware_version': 'Slackware 15.0+',
    'fresh_boot_id': '91901677-1dc3-4a39-a4b1-3f87e6875234',
    'package_database_manifest_sha256': '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
    'header_package_record': 'kernel-headers-6.18.45-x86-1',
    'kernel_generic_record': 'kernel-generic-6.18.45-x86_64-1',
    'kernel_huge_absent': True,
    'kernel_modules_absent': True,
    'slackpkg_conf_sha256': 'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
    'slackpkg_mirrors_sha256': '71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
    'staged_target': '/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz',
    'staged_target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'local_source_root': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source',
    'local_source_target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'tree_manifest': '/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256',
    'tree_manifest_sha256': '0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e',
    'tree_manifest_sidecar_verified': True,
    'local_source_tree_verified': True,
    'single_candidate_contract_verified': True,
    'predecessor_excluded_from_local_source': True,
    'frozen_predecessor_artifact': 'kernel-headers-6.18.44-x86-1.txz',
    'frozen_predecessor_sha256': '3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d',
    'frozen_target_artifact': 'kernel-headers-6.18.45-x86-1.txz',
    'frozen_target_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
    'probe_sha256': probe_sha,
    'prior_target_binding_reused': False,
    'candidate_set_bound': False,
    'repository_refresh_performed': False,
    'network_access_performed': False,
    'package_action_performed': False,
    'slackpkg_configuration_change_performed': False,
    'boot_action_performed': False,
    'persistent_configuration_change_performed': False,
    'reboot_performed': False,
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze',
    'review_only': True,
    'accepted_step_212': {
        'policy_sha256': p212_sha,
        'record_sha256': r212_sha,
        'probe_sha256': probe_sha,
        'returned_probe_result_consumed': True,
    },
    'accepted_revalidation_evidence': accepted,
    'fresh_runtime_identity': {
        'state': 'frozen',
        'binding_origin': 'step-212-post-local-source-build-read-only-revalidation',
        'historical_step_202_binding_reused': False,
        'boot_id': accepted['fresh_boot_id'],
        'package_database_manifest_sha256': accepted['package_database_manifest_sha256'],
        'slackpkg_conf_sha256': accepted['slackpkg_conf_sha256'],
        'slackpkg_mirrors_sha256': accepted['slackpkg_mirrors_sha256'],
        'valid_until_machine_or_package_state_changes': True,
        'fresh_candidate_set_bound': False,
    },
    'preserved_local_source_binding': {
        'state': 'revalidated-and-frozen',
        'root': accepted['local_source_root'],
        'tree_manifest': accepted['tree_manifest'],
        'tree_manifest_sha256': accepted['tree_manifest_sha256'],
        'target_artifact': accepted['frozen_target_artifact'],
        'target_sha256': accepted['frozen_target_sha256'],
        'expected_candidate_count': 1,
        'predecessor_excluded': True,
        'rebuild_authorized': False,
    },
    'candidate_binding_boundary': {
        'candidate_set_state': 'not-yet-bound',
        'fresh_candidate_binding_required': True,
        'candidate_binding_must_consume_frozen_step_213_identity': True,
        'predecessor_record': 'kernel-headers-6.18.44-x86-1',
        'predecessor_record_source': 'frozen-predecessor-artifact',
        'target_candidate': 'kernel-headers-6.18.45-x86-1.txz',
        'target_candidate_sha256': accepted['frozen_target_sha256'],
        'repository_only_candidate_binding_review_authorized': True,
    },
    'authorization': {
        'fresh_target_observation_authorized': False,
        'local_source_tree_revalidation_authorized': False,
        'probe_transport_copy_authorized': False,
        'repository_only_candidate_binding_review_authorized': True,
        'runtime_candidate_binding_authorized': False,
        'predecessor_package_staging_authorized': False,
        'repository_refresh_authorized': False,
        'network_refresh_authorized': False,
        'builder_execution_authorized': False,
        'stager_execution_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'package_action_authorized': False,
        'slackpkg_configuration_change_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
    },
    'machine_action_required': False,
    'controller_action_required': False,
    'pause_safe': False,
    'strong_safe_pause': False,
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze.sh',
    'helper_sha256': helper_sha,
    'next_stage': 'phase-1-kernel-package-edge-runtime-candidate-set-binding-review',
}

out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
rows = [
    ('step','213'),
    ('revision','post-build-revalidation-result-freeze-r1'),
    ('revalidation_status','PASS'),
    ('accepted_step_212_policy_sha256',p212_sha),
    ('accepted_step_212_record_sha256',r212_sha),
    ('probe_sha256',probe_sha),
    ('target_hostname',accepted['target_hostname']),
    ('uname_release',accepted['uname_release']),
    ('uname_machine',accepted['uname_machine']),
    ('fresh_boot_id',accepted['fresh_boot_id']),
    ('package_database_manifest_sha256',accepted['package_database_manifest_sha256']),
    ('header_package_record',accepted['header_package_record']),
    ('kernel_generic_record',accepted['kernel_generic_record']),
    ('kernel_huge_absent','yes'),
    ('kernel_modules_absent','yes'),
    ('slackpkg_conf_sha256',accepted['slackpkg_conf_sha256']),
    ('slackpkg_mirrors_sha256',accepted['slackpkg_mirrors_sha256']),
    ('staged_target_sha256',accepted['staged_target_sha256']),
    ('local_source_tree_verified','yes'),
    ('tree_manifest_sha256',accepted['tree_manifest_sha256']),
    ('single_candidate_contract_verified','yes'),
    ('predecessor_excluded_from_local_source','yes'),
    ('fresh_runtime_identity','frozen'),
    ('historical_step_202_binding_reused','no'),
    ('predecessor_record','kernel-headers-6.18.44-x86-1'),
    ('fresh_candidate_set_bound','no'),
    ('repository_only_candidate_binding_review_authorized','yes'),
    ('runtime_candidate_binding_authorized','no'),
    ('predecessor_package_staging_authorized','no'),
    ('repository_refresh_authorized','no'),
    ('network_refresh_authorized','no'),
    ('runtime_scenario_execution_authorized','no'),
    ('package_action_authorized','no'),
    ('boot_action_authorized','no'),
    ('reboot_authorized','no'),
    ('machine_action_required','no'),
    ('controller_action_required','no'),
    ('pause_safe','no'),
    ('strong_safe_pause','no'),
    ('next_stage',policy['next_stage']),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    csv.writer(handle, delimiter='\t', lineterminator='\n').writerows(rows)
PY

printf 'revalidation_freeze_status\tPASS\n'
printf 'fresh_runtime_identity\tfrozen\n'
printf 'fresh_boot_id\t91901677-1dc3-4a39-a4b1-3f87e6875234\n'
printf 'local_source_binding\trevalidated-and-frozen\n'
printf 'fresh_candidate_set_bound\tno\n'
printf 'repository_only_candidate_binding_review_authorized\tyes\n'
printf 'machine_action_required\tno\n'
printf 'next_stage\tphase-1-kernel-package-edge-runtime-candidate-set-binding-review\n'
