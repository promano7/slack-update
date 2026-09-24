#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-package-pair-and-local-source-binding-review.sh [--output-dir DIR] [--help]

Freeze the controller-only acquisition review gate for the selected Phase 1
kernel-package-edge package pair. The helper itself is non-mutating and grants
only the exact unprivileged acquisition probe as the next controller action.
USAGE
}

output_dir=
while (($#)); do
    case "$1" in
        --output-dir)
            [[ $# -ge 2 ]] || { printf 'ERROR: --output-dir requires a value\n' >&2; exit 2; }
            output_dir=$2; shift 2 ;;
        --help) usage; exit 0 ;;
        *) printf 'ERROR: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
design_policy="$acceptance_dir/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design-policy.json"
design_record="$acceptance_dir/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design.tsv"
probe_path="$repo_root/tools/reference/phase-1-kernel-package-edge-controller-artifact-acquisition-probe.sh"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review.sh"

require_regular() { local f=$1; [[ -f $f && ! -L $f ]] || { printf 'ERROR: required regular file missing or unsafe: %s\n' "$f" >&2; exit 3; }; }
for f in "$design_policy" "$design_record" "$probe_path" "$helper_path"; do require_regular "$f"; done
check_hash() { local f=$1 e=$2 a; a=$(sha256sum -- "$f" | awk '{print $1}'); [[ $a == "$e" ]] || { printf 'ERROR: prerequisite SHA-256 mismatch: %s\n' "$f" >&2; exit 4; }; }
check_hash "$design_policy" 'ce33fc2ead2335c50cd9e47146f8d1d818a49e1cb3169b06fe9a983af60f6015'
check_hash "$design_record" 'aa37378cc4e3af31fc37a0a111b9ab0e39f3bf784e011168f962e165927a01a5'
check_hash "$probe_path" '943af8b0995368b34c3fc79efaac09cbbdebebc1ea5929a4c566ccfd2ef1e586'

if [[ -z $output_dir ]]; then output_dir=$acceptance_dir; fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }
policy="$output_dir/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review.tsv"
design_policy_sha=$(sha256sum -- "$design_policy" | awk '{print $1}')
design_record_sha=$(sha256sum -- "$design_record" | awk '{print $1}')
probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$design_policy" "$design_record" "$policy" "$record" "$design_policy_sha" "$design_record_sha" "$probe_sha" "$helper_sha" <<'PY_INNER'
import csv, json, sys
from pathlib import Path

design_path, record_path, out_policy, out_record = map(Path, sys.argv[1:5])
design_sha, design_record_sha, probe_sha, helper_sha = sys.argv[5:9]
design = json.loads(design_path.read_text(encoding='utf-8'))
with record_path.open(encoding='utf-8', newline='') as h:
    design_record = dict(csv.reader(h, delimiter='\t'))
assert design['scenario'] == 'phase-1-kernel-package-edge-package-pair-and-local-source-binding-design'
assert design['binding_design']['package_pair']['target_installed_record'] == 'kernel-headers-6.18.45-x86-1'
assert design['binding_design']['package_pair']['predecessor_candidate_record'] == 'kernel-headers-6.18.44-x86-1'
assert design_record['binding_design_state'] == 'frozen'

base = 'https://slackware.uk/cumulative/slackware64-current/slackware64/d'
key_url = 'https://mirrors.slackware.com/slackware/slackware-current/GPG-KEY'
expected_fpr = 'EC5649DA401E22ABFA6736EF6A4463C040102233'
expected_keyid = '6A4463C040102233'
uid = 'Slackware Linux Project <security@slackware.com>'
pre_pkg = 'kernel-headers-6.18.44-x86-1.txz'
pre_sig = pre_pkg + '.asc'
tgt_pkg = 'kernel-headers-6.18.45-x86-1.txz'
tgt_sig = tgt_pkg + '.asc'

review = {
  'state': 'frozen-awaiting-controller-acquisition-evidence',
  'controller_probe_path': 'tools/reference/phase-1-kernel-package-edge-controller-artifact-acquisition-probe.sh',
  'controller_probe_sha256': probe_sha,
  'controller_probe_must_run_unprivileged': True,
  'output_directory_must_be_new': True,
  'transport': 'https-only',
  'signing_key': {
    'url': key_url,
    'expected_primary_fingerprint': expected_fpr,
    'expected_long_key_id': expected_keyid,
    'expected_uid': uid,
    'key_file_sha256_binding_deferred_to_probe': True,
  },
  'artifact_origins': {
    'predecessor_package_url': f'{base}/{pre_pkg}',
    'predecessor_signature_url': f'{base}/{pre_sig}',
    'target_package_url': f'{base}/{tgt_pkg}',
    'target_signature_url': f'{base}/{tgt_sig}',
  },
  'pair_history_review': {
    'predecessor_record': 'kernel-headers-6.18.44-x86-1',
    'predecessor_archive_timestamp': '2026-08-10 03:40',
    'target_record': 'kernel-headers-6.18.45-x86-1',
    'target_archive_timestamp': '2026-08-20 05:19',
    'consecutive_in_cumulative_archive': True,
  },
  'required_probe_evidence': [
    'signing_key_fingerprint', 'signing_key_sha256',
    'predecessor_package_sha256', 'predecessor_signature_sha256',
    'target_package_sha256', 'target_signature_sha256',
    'predecessor_signature_valid', 'target_signature_valid',
    'binding_evidence_sha256', 'acquired_files_manifest_sha256',
  ],
  'package_and_signature_sha256_binding_deferred_to_next_freeze': True,
  'target_vm_must_remain_offline': True,
  'target_vm_action_allowed': False,
  'package_action_allowed': False,
  'boot_action_allowed': False,
  'reboot_allowed': False,
}

auth = {
  'controller_artifact_acquisition_authorized': True,
  'controller_network_access_authorized_only_for_frozen_probe_urls': True,
  'target_vm_network_access_authorized': False,
  'target_vm_action_authorized': False,
  'target_artifact_copy_authorized': False,
  'package_pair_binding_authorized': False,
  'local_source_binding_authorized': False,
  'local_source_build_authorized': False,
  'runtime_executor_implementation_authorized': False,
  'runtime_scenario_execution_authorized': False,
  'package_action_authorized': False,
  'boot_action_authorized': False,
  'reboot_authorized': False,
  'phase_2_start_authorized': False,
}

policy = {
  'schema': 1,
  'scenario': 'phase-1-kernel-package-edge-package-pair-and-local-source-binding-review',
  'review_only': True,
  'accepted_binding_design': {
    'step': 195,
    'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design-policy.json',
    'policy_sha256': design_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-package-pair-and-local-source-binding-design.tsv',
    'record_sha256': design_record_sha,
  },
  'artifact_binding_review': review,
  'authorization': auth,
  'machine_action_required': False,
  'controller_action_required': True,
  'pause_safe': False,
  'next_stage': 'phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze',
  'helper_path': 'tools/reference/phase-1-kernel-package-edge-package-pair-and-local-source-binding-review.sh',
  'helper_sha256': helper_sha,
}

rows = [
 ('artifact_binding_review_state', review['state']),
 ('controller_probe_path', review['controller_probe_path']),
 ('controller_probe_sha256', probe_sha),
 ('controller_probe_must_run_unprivileged', 'yes'),
 ('signing_key_url', key_url),
 ('signing_key_expected_fingerprint', expected_fpr),
 ('signing_key_expected_long_id', expected_keyid),
 ('signing_key_expected_uid', uid),
 ('predecessor_package_url', review['artifact_origins']['predecessor_package_url']),
 ('predecessor_signature_url', review['artifact_origins']['predecessor_signature_url']),
 ('target_package_url', review['artifact_origins']['target_package_url']),
 ('target_signature_url', review['artifact_origins']['target_signature_url']),
 ('predecessor_archive_timestamp', '2026-08-10 03:40'),
 ('target_archive_timestamp', '2026-08-20 05:19'),
 ('pair_consecutive_in_cumulative_archive', 'yes'),
 ('package_and_signature_sha256_binding_deferred_to_next_freeze', 'yes'),
 ('controller_artifact_acquisition_authorized', 'yes'),
 ('controller_network_access_authorized_only_for_frozen_probe_urls', 'yes'),
 ('target_vm_network_access_authorized', 'no'),
 ('target_vm_action_authorized', 'no'),
 ('target_artifact_copy_authorized', 'no'),
 ('package_pair_binding_authorized', 'no'),
 ('local_source_binding_authorized', 'no'),
 ('local_source_build_authorized', 'no'),
 ('runtime_scenario_execution_authorized', 'no'),
 ('package_action_authorized', 'no'),
 ('boot_action_authorized', 'no'),
 ('reboot_authorized', 'no'),
 ('phase_2_start_authorized', 'no'),
 ('controller_action_required', 'yes'),
 ('machine_action_required', 'no'),
 ('next_stage', policy['next_stage']),
 ('pause_safe', 'no'),
]
Path(out_policy).write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')
with Path(out_record).open('w', encoding='utf-8', newline='') as h:
    w = csv.writer(h, delimiter='\t', lineterminator='\n')
    w.writerows(rows)
PY_INNER

printf 'Step 196 package-pair/local-source binding review generated:\n'
printf 'policy\t%s\n' "$policy"
printf 'record\t%s\n' "$record"
