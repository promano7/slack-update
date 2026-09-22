#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.sh [--output-dir DIR] [--help]

Review the accepted Phase 1 execution-control runtime validation, close the
four-scenario execution-control-failure-paths family, derive the residual
five-family / twenty-scenario acceptance inventory, and emit a strong-safe-
pause checkpoint. This helper is repository-only and grants no operational
authority.
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
step175_policy="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory-policy.json"
step175_record="$acceptance_dir/phase-1-acceptance-matrix-remainder-inventory.tsv"
r187_policy="$acceptance_dir/phase-1-execution-control-failure-paths-network-failure-remediation-policy.json"
r187_record="$acceptance_dir/phase-1-execution-control-failure-paths-network-failure-remediation.tsv"
r187_harness="$repo_root/tests/reference/test-phase-1-execution-control-failure-paths-network-failure-remediation-harness.sh"
r187_doc="$repo_root/docs/reference/phase-1-execution-control-failure-paths-network-failure-remediation.md"
step186_harness="$repo_root/tests/reference/test-phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization-harness.sh"
reference_script="$repo_root/tools/reference/slack-update-reference.sh"
executor="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-executor.sh"
acceptance_harness="$repo_root/tests/acceptance/reference/test-execution-control-failure-paths.sh"
helper_path="$repo_root/tools/reference/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.sh"

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

for required in "$step175_policy" "$step175_record" "$r187_policy" "$r187_record" "$r187_harness" "$r187_doc" "$step186_harness" "$reference_script" "$executor" "$acceptance_harness" "$helper_path"; do
    require_regular "$required"
done
check_hash "$step175_policy" '819a5696fb9854f64a012ba6091750b40c1d658e5edd61a93c0c1e03264b16fe'
check_hash "$step175_record" 'ad4697b230ab2b22a6d3cdf2e4cc2c74a61e469b9d70da11e7f25082265dd5ff'
check_hash "$r187_policy" 'b4f09cafce7b2e6f4fc45b451f010b7ff683be259fab8a3872b3a7c3e3bdb569'
check_hash "$r187_record" 'efc3f04b821f40b388935870c458b34ca7407aef66af91328e7953ad086caa16'
check_hash "$r187_harness" 'fbd6ca7ce54eb7e5bbf8c3c2ad2c7c5f2a8a8a2ea2666aa088a99f1cf3da460c'
check_hash "$r187_doc" '4fc23c5eb11268c1b41a3ec2ebb9061d37a4ec7dcdaef1bfc140f35454e0fba5'
check_hash "$step186_harness" '6ff46b710f58769a20a8261ed7d085828516608f135a76223d19bc64a83abc19'
check_hash "$reference_script" '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
check_hash "$executor" '262ce8667437ed9de94682ec31773094409e286cd721d4a351963cd59b59fecc'
check_hash "$acceptance_harness" '0ce04751466f0c31cd55f96f8e3d79e41153655c65b14bf54ee42aa80b18268f'

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 5; }

policy="$output_dir/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause-policy.json"
record="$output_dir/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.tsv"
remaining="$output_dir/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv"
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')

python3 - "$step175_policy" "$step175_record" "$r187_policy" "$r187_record" "$policy" "$record" "$remaining" "$helper_sha" <<'PYGEN'
import csv
import hashlib
import json
import sys
from pathlib import Path

p175_path, r175_path, p187_path, r187_path, out_policy, out_record, out_remaining = map(Path, sys.argv[1:8])
helper_sha = sys.argv[8]
p175 = json.loads(p175_path.read_text(encoding='utf-8'))
p187 = json.loads(p187_path.read_text(encoding='utf-8'))
with r175_path.open(encoding='utf-8', newline='') as handle:
    inventory_rows = list(csv.DictReader(handle, delimiter='\t'))
with r187_path.open(encoding='utf-8') as handle:
    r187 = dict(line.rstrip('\n').split('\t', 1) for line in handle if line.strip())

assert p175['scenario'] == 'phase-1-acceptance-matrix-remainder-inventory'
assert p175['inventory']['family_count'] == 6
assert p175['inventory']['scenario_count'] == 24
assert len(inventory_rows) == 6
assert p187['scenario'] == 'phase-1-execution-control-failure-paths-network-failure-remediation-and-runtime-reauthorization'
assert p187['remediation']['review_revision'] == '187-r3'
assert p187['remediation']['reference_script_sha256'] == '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'
assert p187['remediation']['executor_sha256'] == '262ce8667437ed9de94682ec31773094409e286cd721d4a351963cd59b59fecc'
assert p187['runtime_binding']['hostname_fqdn'] == 'vbox-slackcurrent.vbox-slackcurrent.org'
assert p187['runtime_binding']['uname_release'] == '6.18.45'
assert p187['runtime_binding']['boot_id'] == 'cb85100b-9993-4876-ab32-b2457ed0ac6d'
assert p187['authorization']['runtime_scenario_execution_authorized'] is True
assert r187['runtime_scenario_execution_authorized'] == 'yes'
assert r187['pause_safe'] == 'no'

closed = [row for row in inventory_rows if row['family'] == 'execution-control-failure-paths']
assert len(closed) == 1 and int(closed[0]['scenario_count']) == 4
remaining_rows = [row for row in inventory_rows if row['family'] != 'execution-control-failure-paths']
assert len(remaining_rows) == 5
assert sum(int(row['scenario_count']) for row in remaining_rows) == 20

with out_remaining.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.DictWriter(handle, fieldnames=inventory_rows[0].keys(), delimiter='\t', lineterminator='\n')
    writer.writeheader()
    writer.writerows(remaining_rows)
remaining_sha = hashlib.sha256(out_remaining.read_bytes()).hexdigest()

policy = {
  'schema': 1,
  'scenario': 'phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause',
  'review_only': True,
  'accepted_source_remediation': {
    'review_revision': '187-r3',
    'reference_script_sha256': '1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415',
    'effective_config_sha256': '4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba',
    'builder_sha256': '1fd71518ac2fcd4033e6768326959ec49ccc7d61acc096566862ba17bfbaca6b',
    'executor_sha256': '262ce8667437ed9de94682ec31773094409e286cd721d4a351963cd59b59fecc',
    'acceptance_harness_sha256': '0ce04751466f0c31cd55f96f8e3d79e41153655c65b14bf54ee42aa80b18268f',
    'network_failure_defect_classification': 'reference-check-fail-open-on-unreachable-mirror',
    'remediation_state': 'accepted',
  },
  'accepted_runtime_validation': {
    'step': 187,
    'rerun_status': 'PASS',
    'hostname_fqdn': 'vbox-slackcurrent.vbox-slackcurrent.org',
    'uname_release': '6.18.45',
    'boot_id': 'cb85100b-9993-4876-ab32-b2457ed0ac6d',
    'derived_config_sha256': '5ce1ae35abe6c9f1fd92ef1d7f2fa2c6d31215f0a97c675e71a3a8a8f79cf79a',
    'evidence_archive_path': '/home/promano/slack-update-phase-1-execution-control-failure-paths-evidence.tar.gz',
    'evidence_archive_sha256': 'da2f111515e9b7ddc322ca4403cfa543b5710c1c05b94c6fa7dca2a5c336290d',
    'evidence_sha256_file_path': '/home/promano/slack-update-phase-1-execution-control-failure-paths-evidence.tar.gz.sha256',
    'evidence_sha256_file_sha256': 'd8c78699ded46b642ff2eb1bf0c4ad349ed23b2febbc12fd6cd8751ee711aa05',
    'published_owner': 'promano:users',
    'published_mode': '0600',
    'scenario_results': {
      'network_failure': {'status':'PASS','reference_exit_code':1,'fail_closed':True},
      'simultaneous_execution': {'status':'PASS','first_exit_code':0,'second_exit_code':6},
      'signal_SIGINT': {'status':'PASS','exit_code':130},
      'signal_SIGTERM': {'status':'PASS','exit_code':143},
      'signal_SIGHUP': {'status':'PASS','exit_code':129},
      'cron_without_interactive_terminal': {'status':'PASS','tty_state':'absent','driver_state':'completed'},
    },
    'safety_results': {
      'package_database_unchanged': True,
      'slackpkg_state_unchanged': True,
      'boot_artifacts_unchanged': True,
      'root_crontab_restored_exactly': True,
      'lock_clean': True,
      'runtime_binding_preserved': True,
    },
  },
  'closed_family': {
    'family': 'execution-control-failure-paths',
    'scenario_count': 4,
    'closure_status': 'accepted',
    'replay_required_by_default': False,
  },
  'remaining_inventory': {
    'source_inventory_step': 175,
    'family_count': 5,
    'scenario_count': 20,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv',
    'record_sha256': remaining_sha,
    'contains_machine_work': True,
    'machine_work_authorized': False,
    'candidate_set_bound': False,
  },
  'gates': {
    'acceptance_matrix_complete': False,
    'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
    'c_port_status': 'blocked-by-phase-1-gate',
    'phase_2_start_authorized': False,
  },
  'authorization': {
    'source_change_authorized': False,
    'documentation_change_authorized': False,
    'repository_refresh_authorized': False,
    'network_refresh_authorized': False,
    'machine_execution_authorized': False,
    'runtime_scenario_execution_authorized': False,
    'package_action_authorized': False,
    'boot_action_authorized': False,
    'reboot_authorized': False,
    'phase_2_start_authorized': False,
    'future_work_requires_explicit_authorization': True,
    'future_work_requires_fresh_boundary': True,
  },
  'safe_pause': {
    'pause_safe': True,
    'strong_safe_pause': True,
    'machine_action_required': False,
    'no_open_operational_authorization': True,
    'slackware_current_publication_invalidates_checkpoint': False,
    'accepted_runtime_closure_remains_valid_across_publication': True,
  },
  'continuation': {
    'next_family_selection_required': True,
    'selection_must_occur_after_fresh_boundary': True,
    'repository_refresh_must_be_justified_by_selected_scenario': True,
    'no_runtime_family_preselected': True,
  },
  'evidence': {
    'review_helper_sha256': helper_sha,
    'step_175_policy_sha256': hashlib.sha256(p175_path.read_bytes()).hexdigest(),
    'step_175_record_sha256': hashlib.sha256(r175_path.read_bytes()).hexdigest(),
    'step_187_r3_policy_sha256': hashlib.sha256(p187_path.read_bytes()).hexdigest(),
    'step_187_r3_record_sha256': hashlib.sha256(r187_path.read_bytes()).hexdigest(),
  },
  'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.tsv',
  'next_stage': 'phase-1-acceptance-matrix-remainder-resume-planning',
}
out_policy.write_text(json.dumps(policy, indent=2, sort_keys=True) + '\n', encoding='utf-8')

record_rows = [
  ('check','value'),
  ('closed_family','execution-control-failure-paths'),
  ('closed_scenario_count','4'),
  ('runtime_validation_status','PASS'),
  ('evidence_archive_sha256','da2f111515e9b7ddc322ca4403cfa543b5710c1c05b94c6fa7dca2a5c336290d'),
  ('reference_script_sha256','1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415'),
  ('executor_sha256','262ce8667437ed9de94682ec31773094409e286cd721d4a351963cd59b59fecc'),
  ('runtime_hostname_fqdn','vbox-slackcurrent.vbox-slackcurrent.org'),
  ('runtime_uname_release','6.18.45'),
  ('runtime_boot_id','cb85100b-9993-4876-ab32-b2457ed0ac6d'),
  ('network_failure','PASS'),
  ('network_failure_exit_code','1'),
  ('simultaneous_execution','PASS'),
  ('simultaneous_second_exit_code','6'),
  ('signal_SIGINT','PASS:130'),
  ('signal_SIGTERM','PASS:143'),
  ('signal_SIGHUP','PASS:129'),
  ('cron_without_interactive_terminal','PASS'),
  ('package_database_unchanged','yes'),
  ('slackpkg_state_unchanged','yes'),
  ('boot_artifacts_unchanged','yes'),
  ('root_crontab_restored_exactly','yes'),
  ('lock_clean','yes'),
  ('runtime_binding_preserved','yes'),
  ('remaining_inventory_family_count','5'),
  ('remaining_inventory_scenario_count','20'),
  ('family_selected_for_execution','no'),
  ('live_runtime_chain_open','no'),
  ('acceptance_matrix_complete','no'),
  ('runtime_scenario_execution_authorized','no'),
  ('machine_action_required','no'),
  ('no_open_operational_authorization','yes'),
  ('pause_safe','yes'),
  ('strong_safe_pause','yes'),
  ('future_work_requires_fresh_boundary','yes'),
  ('no_runtime_family_preselected','yes'),
  ('next_stage','phase-1-acceptance-matrix-remainder-resume-planning'),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(record_rows)
PYGEN

printf 'Phase 1 execution-control runtime validation review completed successfully.\n'
printf 'Execution-control family closed; strong safe pause established with 5 families / 20 scenarios remaining.\n'
