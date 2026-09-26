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
step201_policy="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review-policy.json"
step201_record="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review.tsv"
probe="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-probe.sh"
helper="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-failure-review.sh"
[[ -f $step201_policy && ! -L $step201_policy ]] || exit 3
[[ -f $step201_record && ! -L $step201_record ]] || exit 3
[[ -f $probe && ! -L $probe ]] || exit 3
[[ $(sha256sum "$step201_policy" | awk '{print $1}') == 77aee964cbe04b9f7e49e4d5f9427b2d98aebf08b3fefe6074aae944220304fa ]] || exit 4
[[ $(sha256sum "$step201_record" | awk '{print $1}') == 1fbaf768672fd13b9f51ef65ebfdff4bef3a7c10958b42cae8ec1c3046dc1dd0 ]] || exit 4
[[ -z $output_dir ]] && output_dir=$acceptance_dir
mkdir -p "$output_dir"
policy="$output_dir/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-failure-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-failure-review.tsv"
probe_sha=$(sha256sum "$probe" | awk '{print $1}')
helper_sha=$(sha256sum "$helper" | awk '{print $1}')
python3 - "$policy" "$record" "$probe_sha" "$helper_sha" <<'PY'
import csv, json, sys
from pathlib import Path
policy_path, record_path = Path(sys.argv[1]), Path(sys.argv[2])
probe_sha, helper_sha = sys.argv[3:5]
policy = {
  'schema': 1,
  'scenario': 'phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-failure-review',
  'revision': 'r1-package-database-drift-characterization',
  'review_only': True,
  'accepted_step_201': {
    'policy_sha256': '77aee964cbe04b9f7e49e4d5f9427b2d98aebf08b3fefe6074aae944220304fa',
    'record_sha256': '1fbaf768672fd13b9f51ef65ebfdff4bef3a7c10958b42cae8ec1c3046dc1dd0',
    'probe_sha256': 'd8c0a9f73e99a228c75b58483d9c0ea4c777e2d41296a05a089c69635cc5b7e4'
  },
  'observed_failure': {
    'class': 'package-database-manifest-drift',
    'expected_manifest_sha256': '3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910',
    'actual_manifest_sha256': '726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',
    'step_201_failed_closed': True,
    'successful_revalidation_not_claimed': True
  },
  'characterization': {
    'state': 'read-only-characterization-authorized',
    'probe_path': 'tools/reference/phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-probe.sh',
    'probe_sha256': probe_sha,
    'baseline_observed_utc': '2026-09-24T16:18:07Z',
    'same_failed_manifest_required': True,
    'recent_installed_records_reported': True,
    'recent_removed_records_reported': True,
    'kernel_package_state_reported': True,
    'slackpkg_fingerprints_reported': True,
    'network_access_allowed': False,
    'package_mutation_allowed': False,
    'boot_mutation_allowed': False,
    'persistent_configuration_change_allowed': False,
    'reboot_allowed': False
  },
  'authorization': {
    'package_database_drift_characterization_authorized': True,
    'fresh_target_revalidation_freeze_authorized': False,
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
  'machine_action_type': 'read-only-package-database-drift-characterization',
  'pause_safe': False,
  'helper_path': 'tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-failure-review.sh',
  'helper_sha256': helper_sha,
  'next_stage': 'phase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review'
}
policy_path.write_text(json.dumps(policy, indent=2)+'\n', encoding='utf-8')
rows = [
 ('step','201-r1'),('revision','r1-package-database-drift-characterization'),
 ('failure_class','package-database-manifest-drift'),
 ('expected_manifest_sha256',policy['observed_failure']['expected_manifest_sha256']),
 ('actual_manifest_sha256',policy['observed_failure']['actual_manifest_sha256']),
 ('step_201_failed_closed','yes'),('successful_revalidation_claimed','no'),
 ('characterization_probe_sha256',probe_sha),('baseline_observed_utc','2026-09-24T16:18:07Z'),
 ('same_failed_manifest_required','yes'),('package_database_drift_characterization_authorized','yes'),
 ('fresh_target_revalidation_freeze_authorized','no'),('target_artifact_copy_authorized','no'),
 ('local_source_build_authorized','no'),('runtime_scenario_execution_authorized','no'),
 ('repository_refresh_authorized','no'),('network_refresh_authorized','no'),
 ('package_action_authorized','no'),('boot_action_authorized','no'),('reboot_authorized','no'),
 ('phase_2_start_authorized','no'),('machine_action_required','yes'),
 ('machine_action_type','read-only-package-database-drift-characterization'),('pause_safe','no'),
 ('next_stage',policy['next_stage'])]
with record_path.open('w',encoding='utf-8',newline='') as f: csv.writer(f,delimiter='\t',lineterminator='\n').writerows(rows)
PY
printf 'policy\t%s\nrecord\t%s\nprobe_sha256\t%s\nnext_stage\tphase-1-kernel-package-edge-local-source-construction-package-database-drift-characterization-review\n' "$policy" "$record" "$probe_sha"
