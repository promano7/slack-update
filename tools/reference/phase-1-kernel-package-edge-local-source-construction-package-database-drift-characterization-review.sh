#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

output_dir=
while (($#)); do
    case "$1" in
        --output-dir) output_dir=${2:?}; shift 2 ;;
        --help|-h) printf 'Usage: %s [--output-dir DIR]\n' "${0##*/}"; exit 0 ;;
        *) printf 'ERROR: unknown option: %s\n' "$1" >&2; exit 2 ;;
    esac
done

script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
acceptance_dir="$repo_root/tests/fixtures/reference/acceptance/phase-1"
step201r1_policy="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-failure-review-policy.json"
step201r1_record="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-failure-review.tsv"
characterization_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-probe.sh"
rerun_probe="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-r2-probe.sh"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review.sh"

[[ -f $step201r1_policy && ! -L $step201r1_policy ]] || exit 3
[[ -f $step201r1_record && ! -L $step201r1_record ]] || exit 3
[[ -f $characterization_probe && ! -L $characterization_probe ]] || exit 3
[[ -f $rerun_probe && ! -L $rerun_probe ]] || exit 3
[[ $(sha256sum "$step201r1_policy" | awk '{print $1}') == 698b7127fd2922046a2a9a633fd9371291962b0b535563b766ba835cfcdd162d ]] || exit 4
[[ $(sha256sum "$step201r1_record" | awk '{print $1}') == edac5ba6521c71f05605aacf8b32ae144d4d1a9846d249f14821af05e3b3a5d9 ]] || exit 4
[[ $(sha256sum "$characterization_probe" | awk '{print $1}') == 523decebbbda74069ebdd97e3ed8c3465514eee65f3ce673c4d845eb8d9098f2 ]] || exit 4

[[ -z $output_dir ]] && output_dir=$acceptance_dir
mkdir -p "$output_dir"
policy="$output_dir/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review.tsv"
rerun_probe_sha=$(sha256sum "$rerun_probe" | awk '{print $1}')
helper_sha=$(sha256sum "$helper" | awk '{print $1}')

python3 - "$policy" "$record" "$rerun_probe_sha" "$helper_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

policy_path = Path(sys.argv[1])
record_path = Path(sys.argv[2])
rerun_probe_sha = sys.argv[3]
helper_sha = sys.argv[4]

policy = {
  'schema': 1,
  'scenario': 'phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review',
  'revision': 'r2-drift-isolation-and-revalidation-rerun',
  'review_only': True,
  'accepted_step_201_r1': {
    'policy_sha256': '698b7127fd2922046a2a9a633fd9371291962b0b535563b766ba835cfcdd162d',
    'record_sha256': 'edac5ba6521c71f05605aacf8b32ae144d4d1a9846d249f14821af05e3b3a5d9',
    'characterization_probe_sha256': '523decebbbda74069ebdd97e3ed8c3465514eee65f3ce673c4d845eb8d9098f2'
  },
  'characterization_evidence': {
    'status': 'PASS',
    'hostname_fqdn': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'uname_release': '6.18.45',
    'uname_machine': 'x86_64',
    'slackware_version': 'Slackware 15.0+',
    'boot_id': 'd767c4ed-b21f-4c6f-9a1e-db7948c285cf',
    'baseline_observed_utc': '2026-09-24T16:18:07Z',
    'baseline_package_database_manifest_sha256': '3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910',
    'characterized_package_database_manifest_sha256': '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
    'header_package_record': 'kernel-headers-6.18.45-x86-1',
    'header_package_record_baseline_match': True,
    'kernel_generic_record': 'kernel-generic-6.18.45-x86_64-1',
    'kernel_generic_record_baseline_match': True,
    'kernel_huge_absent': True,
    'kernel_modules_absent': True,
    'slackpkg_conf_sha256': 'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4',
    'slackpkg_conf_baseline_match': True,
    'slackpkg_mirrors_sha256': '71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12',
    'slackpkg_mirrors_baseline_match': True,
    'recent_installed_record_count': 1,
    'recent_installed_records': ['pCloudDrive-2.3.0-x86_64-1_SBo'],
    'recent_removed_record_count': 0,
    'network_access_performed': False,
    'repository_refresh_performed': False,
    'package_action_performed': False,
    'boot_action_performed': False,
    'persistent_configuration_change_performed': False,
    'reboot_performed': False
  },
  'review_decision': {
    'drift_class': 'out-of-scenario-third-party-package-record',
    'scenario_critical_state_unchanged': True,
    'historical_manifest_remains_historical': True,
    'characterized_manifest_may_be_used_only_for_corrected_revalidation': True,
    'direct_target_binding_freeze_authorized': False,
    'additional_drift_fails_closed': True
  },
  'corrected_revalidation': {
    'state': 'read-only-rerun-authorized',
    'probe_path': 'tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-r2-probe.sh',
    'probe_sha256': rerun_probe_sha,
    'expected_boot_id': 'd767c4ed-b21f-4c6f-9a1e-db7948c285cf',
    'expected_package_database_manifest_sha256': '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
    'expected_characterized_record': 'pCloudDrive-2.3.0-x86_64-1_SBo',
    'expected_recent_installed_record_count': 1,
    'expected_recent_removed_record_count': 0,
    'same_scenario_critical_kernel_state_required': True,
    'same_slackpkg_fingerprints_required': True,
    'network_access_allowed': False,
    'repository_refresh_allowed': False,
    'package_mutation_allowed': False,
    'boot_mutation_allowed': False,
    'persistent_configuration_change_allowed': False,
    'reboot_allowed': False
  },
  'authorization': {
    'corrected_fresh_target_revalidation_rerun_authorized': True,
    'fresh_target_revalidation_freeze_authorized_after_pass': True,
    'target_artifact_copy_authorized': False,
    'local_source_build_authorized': False,
    'runtime_scenario_execution_authorized': False,
    'repository_refresh_authorized': False,
    'network_refresh_authorized': False,
    'package_action_authorized': False,
    'boot_action_authorized': False,
    'reboot_authorized': False,
    'phase_2_start_authorized': False
  },
  'machine_action_required': True,
  'machine_action_type': 'read-only-fresh-target-revalidation-r2',
  'pause_safe': False,
  'helper_path': 'tools/reference/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review.sh',
  'helper_sha256': helper_sha,
  'next_stage': 'phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze'
}

policy_path.write_text(json.dumps(policy, indent=2) + '\n', encoding='utf-8')
rows = [
  ('step', '201-r2'),
  ('revision', policy['revision']),
  ('characterization_status', 'PASS'),
  ('drift_class', policy['review_decision']['drift_class']),
  ('scenario_critical_state_unchanged', 'yes'),
  ('hostname_fqdn', policy['characterization_evidence']['hostname_fqdn']),
  ('uname_release', policy['characterization_evidence']['uname_release']),
  ('uname_machine', policy['characterization_evidence']['uname_machine']),
  ('slackware_version', policy['characterization_evidence']['slackware_version']),
  ('characterization_boot_id', policy['characterization_evidence']['boot_id']),
  ('baseline_package_database_manifest_sha256', policy['characterization_evidence']['baseline_package_database_manifest_sha256']),
  ('characterized_package_database_manifest_sha256', policy['characterization_evidence']['characterized_package_database_manifest_sha256']),
  ('recent_installed_record_count', '1'),
  ('recent_installed_record', 'pCloudDrive-2.3.0-x86_64-1_SBo'),
  ('recent_removed_record_count', '0'),
  ('header_package_record', 'kernel-headers-6.18.45-x86-1'),
  ('kernel_generic_record', 'kernel-generic-6.18.45-x86_64-1'),
  ('kernel_huge_absent', 'yes'),
  ('kernel_modules_absent', 'yes'),
  ('slackpkg_conf_baseline_match', 'yes'),
  ('slackpkg_mirrors_baseline_match', 'yes'),
  ('corrected_revalidation_probe_sha256', rerun_probe_sha),
  ('corrected_fresh_target_revalidation_rerun_authorized', 'yes'),
  ('fresh_target_revalidation_freeze_authorized_after_pass', 'yes'),
  ('target_artifact_copy_authorized', 'no'),
  ('local_source_build_authorized', 'no'),
  ('runtime_scenario_execution_authorized', 'no'),
  ('repository_refresh_authorized', 'no'),
  ('network_refresh_authorized', 'no'),
  ('package_action_authorized', 'no'),
  ('boot_action_authorized', 'no'),
  ('reboot_authorized', 'no'),
  ('phase_2_start_authorized', 'no'),
  ('machine_action_required', 'yes'),
  ('machine_action_type', policy['machine_action_type']),
  ('pause_safe', 'no'),
  ('next_stage', policy['next_stage'])
]
with record_path.open('w', encoding='utf-8', newline='') as handle:
    csv.writer(handle, delimiter='\t', lineterminator='\n').writerows(rows)
PY

printf 'policy\t%s\nrecord\t%s\nprobe_sha256\t%s\nnext_stage\tphase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze\n' \
    "$policy" "$record" "$rerun_probe_sha"
