#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.sh [--output-dir DIR] [--help]

Freeze the exact byte identities produced by the accepted step-196 controller
artifact acquisition observation. This helper is repository-only and grants no
network, target-machine, package, boot, or reboot authorization.
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
review_policy="$acceptance_dir/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review-policy.json"
review_record="$acceptance_dir/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review.tsv"
probe_path="$repo_root/tools/reference/phase-1-kernel-package-edge-controller-artifact-acquisition-probe.sh"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.sh"

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

for path in "$review_policy" "$review_record" "$probe_path" "$helper_path"; do
    require_regular "$path"
done
check_hash "$review_policy" 'ba6fe4afb14cc5c7793c2ac610660706648eb2bbf5a8b95ea31199efe18cb03b'
check_hash "$review_record" '27c86a17e6f98984cb2101749d3fba21b14be697dca7382f9016ef90ef83df2a'
check_hash "$probe_path" '943af8b0995368b34c3fc79efaac09cbbdebebc1ea5929a4c566ccfd2ef1e586'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || {
    printf 'ERROR: output directory is unsafe\n' >&2
    exit 5
}

policy="$output_dir/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze-policy.json"
record="$output_dir/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.tsv"
review_policy_sha=$(sha256sum -- "$review_policy" | awk '{print $1}')
review_record_sha=$(sha256sum -- "$review_record" | awk '{print $1}')
probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$review_policy" "$review_record" "$policy" "$record" "$review_policy_sha" "$review_record_sha" "$probe_sha" "$helper_sha" <<'PY_INNER'
import csv
import json
import sys
from pathlib import Path

review_path, review_record_path, out_policy, out_record = map(Path, sys.argv[1:5])
review_sha, review_record_sha, probe_sha, helper_sha = sys.argv[5:9]
review = json.loads(review_path.read_text(encoding='utf-8'))
with review_record_path.open(encoding='utf-8', newline='') as handle:
    review_record = dict(csv.reader(handle, delimiter='\t'))

assert review['scenario'] == 'phase-1-kernel-package-edge-package-pair-and-local-source-binding-review'
assert review['artifact_binding_review']['state'] == 'frozen-awaiting-controller-acquisition-evidence'
assert review['authorization']['controller_artifact_acquisition_authorized'] is True
assert review_record['artifact_binding_review_state'] == 'frozen-awaiting-controller-acquisition-evidence'

frozen = {
    'state': 'accepted-byte-binding-frozen',
    'observation_status': 'PASS',
    'evidence_root': '/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts',
    'evidence_root_must_be_preserved_unchanged': True,
    'binding_evidence_sha256': 'dd3037a58a3a2455d5c4e960ac027bed3dc644a193c22e9ec806a43d91b2ae63',
    'acquired_files_manifest_sha256': '1292ade434fd52b90f4230955610d5a0ca70fb0c586a6a6488ecf912621cf86f',
    'signing_key': {
        'fingerprint': 'EC5649DA401E22ABFA6736EF6A4463C040102233',
        'file_sha256': '82af92f3a9abdae815534912e7c438f1bad50b8516bb8d75fe9e08444f727daf',
    },
    'package_pair': {
        'predecessor_record': 'kernel-headers-6.18.44-x86-1',
        'predecessor_artifact': 'kernel-headers-6.18.44-x86-1.txz',
        'predecessor_package_sha256': '3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d',
        'predecessor_signature': 'kernel-headers-6.18.44-x86-1.txz.asc',
        'predecessor_signature_sha256': 'e818c8b1c665aabc8724e8a301de5a711eb949bbf2dfd92dba8ce5ced7bdcf21',
        'predecessor_signature_valid': True,
        'target_record': 'kernel-headers-6.18.45-x86-1',
        'target_artifact': 'kernel-headers-6.18.45-x86-1.txz',
        'target_package_sha256': 'c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c',
        'target_signature': 'kernel-headers-6.18.45-x86-1.txz.asc',
        'target_signature_sha256': '66787e515d7d4420daab5aac412cd8ac5921a1dff037147b8216e1017ac1c801',
        'target_signature_valid': True,
    },
    'accepted_observation_side_effects': {
        'target_vm_network_access_performed': False,
        'target_vm_action_performed': False,
        'package_action_performed': False,
        'boot_action_performed': False,
        'reboot_performed': False,
    },
    'controller_redownload_requires_new_explicit_authorization': True,
    'later_archive_or_slackware_current_publication_invalidates_byte_binding': False,
    'local_source_tree_binding_state': 'not-built',
}

authorization = {
    'controller_artifact_acquisition_authorized': False,
    'controller_network_access_authorized': False,
    'target_vm_network_access_authorized': False,
    'target_vm_action_authorized': False,
    'target_artifact_copy_authorized': False,
    'package_action_authorized': False,
    'boot_action_authorized': False,
    'reboot_authorized': False,
    'local_source_build_authorized': False,
    'runtime_executor_implementation_authorized': False,
    'runtime_scenario_execution_authorized': False,
    'phase_2_start_authorized': False,
    'local_source_construction_review_authorized_for_next_stage': True,
}

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze',
    'freeze_only': True,
    'accepted_binding_review': {
        'step': 196,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review-policy.json',
        'policy_sha256': review_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review.tsv',
        'record_sha256': review_record_sha,
        'controller_probe_path': 'tools/reference/phase-1-kernel-package-edge-controller-artifact-acquisition-probe.sh',
        'controller_probe_sha256': probe_sha,
    },
    'artifact_byte_binding': frozen,
    'authorization': authorization,
    'machine_action_required': False,
    'controller_action_required': False,
    'pause_safe': False,
    'next_stage': 'phase-1-kernel-package-edge-local-source-construction-review',
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze.sh',
    'helper_sha256': helper_sha,
}

rows = [
    ('artifact_byte_binding_state', frozen['state']),
    ('observation_status', frozen['observation_status']),
    ('evidence_root', frozen['evidence_root']),
    ('evidence_root_must_be_preserved_unchanged', 'yes'),
    ('binding_evidence_sha256', frozen['binding_evidence_sha256']),
    ('acquired_files_manifest_sha256', frozen['acquired_files_manifest_sha256']),
    ('signing_key_fingerprint', frozen['signing_key']['fingerprint']),
    ('signing_key_sha256', frozen['signing_key']['file_sha256']),
    ('predecessor_record', frozen['package_pair']['predecessor_record']),
    ('predecessor_package_sha256', frozen['package_pair']['predecessor_package_sha256']),
    ('predecessor_signature_sha256', frozen['package_pair']['predecessor_signature_sha256']),
    ('predecessor_signature_valid', 'yes'),
    ('target_record', frozen['package_pair']['target_record']),
    ('target_package_sha256', frozen['package_pair']['target_package_sha256']),
    ('target_signature_sha256', frozen['package_pair']['target_signature_sha256']),
    ('target_signature_valid', 'yes'),
    ('target_vm_network_access_performed', 'no'),
    ('target_vm_action_performed', 'no'),
    ('package_action_performed', 'no'),
    ('boot_action_performed', 'no'),
    ('reboot_performed', 'no'),
    ('controller_artifact_acquisition_authorized', 'no'),
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
    ('next_stage', policy['next_stage']),
    ('pause_safe', 'no'),
]

Path(out_policy).write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
with Path(out_record).open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY_INNER

printf 'Step 197 package-pair/local-source byte binding freeze generated:\n'
printf 'policy\t%s\n' "$policy"
printf 'record\t%s\n' "$record"
