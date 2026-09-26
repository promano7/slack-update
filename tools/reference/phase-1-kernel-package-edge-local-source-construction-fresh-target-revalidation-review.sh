#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
    cat <<'USAGE'
Usage: phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review.sh [--output-dir DIR] [--help]

Freeze the Phase 1 step-201 fresh target revalidation gate. This helper does
not probe a live machine. It authorizes only the standalone read-only probe
required to establish a new post-pause target observation while preserving the
frozen artifact byte binding and keeping all mutation paths closed.
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
step200_policy="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review-policy.json"
step200_record="$acceptance_dir/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review.tsv"
step194_policy="$acceptance_dir/phase-1-kernel-package-edge-runtime-target-binding-freeze-policy.json"
step194_record="$acceptance_dir/phase-1-kernel-package-edge-runtime-target-binding-freeze.tsv"
helper_path="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review.sh"
probe_path="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-probe.sh"
builder_path="$repo_root/tools/reference/phase-1-kernel-package-edge-local-source-build.sh"

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

for required in "$step200_policy" "$step200_record" "$step194_policy" "$step194_record" "$helper_path" "$probe_path"; do
    require_regular "$required"
done
check_hash "$step200_policy" '801fb952679b8e32847b027c52a05c73b1af33b981e52925d8df0bf8dc38b945'
check_hash "$step200_record" '55e78ed7aafc384f48b6e3ed7952f6b8389aa92afdecf171f70550b0c0ac63ca'
check_hash "$step194_policy" '0db70e4cbeba69a607a372181745ef936bcc693cfe11eb8aebf2c3f764c29621'
check_hash "$step194_record" 'd2bbc87628a78d79077ecf51732a63dcbec55fc136b3d47ae2702c96867b09c6'
[[ ! -e $builder_path ]] || { printf 'ERROR: local-source builder unexpectedly exists before step 201: %s\n' "$builder_path" >&2; exit 5; }

if [[ -z $output_dir ]]; then
    output_dir=$acceptance_dir
fi
mkdir -p -- "$output_dir"
[[ -d $output_dir && ! -L $output_dir ]] || { printf 'ERROR: output directory is unsafe\n' >&2; exit 6; }

policy="$output_dir/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review-policy.json"
record="$output_dir/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review.tsv"
step200_policy_sha=$(sha256sum -- "$step200_policy" | awk '{print $1}')
step200_record_sha=$(sha256sum -- "$step200_record" | awk '{print $1}')
step194_policy_sha=$(sha256sum -- "$step194_policy" | awk '{print $1}')
step194_record_sha=$(sha256sum -- "$step194_record" | awk '{print $1}')
helper_sha=$(sha256sum -- "$helper_path" | awk '{print $1}')
probe_sha=$(sha256sum -- "$probe_path" | awk '{print $1}')

python3 - "$step200_policy" "$step200_record" "$step194_policy" "$step194_record" "$policy" "$record" \
    "$step200_policy_sha" "$step200_record_sha" "$step194_policy_sha" "$step194_record_sha" "$helper_sha" "$probe_sha" <<'PY'
import csv
import json
import sys
from pathlib import Path

p200_path = Path(sys.argv[1])
r200_path = Path(sys.argv[2])
p194_path = Path(sys.argv[3])
r194_path = Path(sys.argv[4])
out_policy = Path(sys.argv[5])
out_record = Path(sys.argv[6])
p200_sha, r200_sha, p194_sha, r194_sha, helper_sha, probe_sha = sys.argv[7:13]

p200 = json.loads(p200_path.read_text(encoding='utf-8'))
p194 = json.loads(p194_path.read_text(encoding='utf-8'))
with r200_path.open(encoding='utf-8', newline='') as handle:
    r200 = dict(csv.reader(handle, delimiter='\t'))
with r194_path.open(encoding='utf-8', newline='') as handle:
    r194 = dict(csv.reader(handle, delimiter='\t'))

assert p200['schema'] == 1
assert p200['scenario'] == 'phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review'
assert p200['fresh_boundary']['opened'] is True
assert p200['selected_family']['family'] == 'kernel-package-edge'
assert p200['selected_family']['family_closed'] is False
assert p200['artifact_byte_binding']['state'] == 'accepted-byte-binding-frozen'
assert p200['artifact_byte_binding']['evidence_root_must_remain_unchanged'] is True
assert p200['runtime_revalidation']['prior_target_binding_reusable'] is False
assert p200['runtime_revalidation']['fresh_target_revalidation_required_before_machine_action'] is True
assert p200['runtime_revalidation']['fresh_candidate_set_required_before_runtime'] is True
assert p200['runtime_revalidation']['target_observation_authorized_now'] is False
assert p200['local_source_state']['builder_implementation_state'] == 'not-implemented'
assert p200['local_source_state']['local_source_tree_built'] is False
assert p200['next_stage'] == 'phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review'
assert r200['prior_target_binding_reusable'] == 'no'
assert r200['fresh_target_revalidation_required_before_machine_action'] == 'yes'
assert r200['target_observation_authorized_now'] == 'no'

assert p194['schema'] == 1
assert p194['scenario'] == 'phase-1-kernel-package-edge-runtime-target-binding-freeze'
baseline = p194['runtime_target_binding']
assert baseline['state'] == 'frozen'
assert baseline['observation_status'] == 'PASS'
assert baseline['hostname_fqdn'] == 'vbox-slackcurrent.vbox-slackcurrent.org'
assert baseline['uname_machine'] == 'x86_64'
assert baseline['uname_release'] == '6.18.45'
assert baseline['slackware_version'] == 'Slackware 15.0+'
assert baseline['header_package_record'] == 'kernel-headers-6.18.45-x86-1'
assert baseline['package_database_manifest_sha256'] == '3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910'
assert baseline['slackpkg_conf_sha256'] == 'f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4'
assert baseline['slackpkg_mirrors_sha256'] == '71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12'
assert r194['boot_package_record_status_kernel-generic'] == 'installed'
assert r194['boot_package_record_kernel-generic'] == 'kernel-generic-6.18.45-x86_64-1'
assert r194['boot_package_record_status_kernel-huge'] == 'absent'
assert r194['boot_package_record_status_kernel-modules'] == 'absent'

binding = p200['artifact_byte_binding']
local_source = p200['local_source_state']
selected = p200['selected_family']

policy = {
    'schema': 1,
    'scenario': 'phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review',
    'review_only': True,
    'accepted_resume_boundary': {
        'step': 200,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review-policy.json',
        'policy_sha256': p200_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-resume-planning-boundary-review.tsv',
        'record_sha256': r200_sha,
        'prior_target_binding_reusable': False,
    },
    'historical_target_baseline': {
        'step': 194,
        'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-target-binding-freeze-policy.json',
        'policy_sha256': p194_sha,
        'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-target-binding-freeze.tsv',
        'record_sha256': r194_sha,
        'binding_reusable': False,
        'purpose': 'expected-pre-staging-state-only',
        'previous_boot_id_is_not_reused': True,
    },
    'selected_family': {
        'family': selected['family'],
        'family_closed': False,
        'scenario_count': selected['scenario_count'],
        'selected_scenario': selected['selected_scenario'],
    },
    'artifact_byte_binding': {
        'state': binding['state'],
        'evidence_root': binding['evidence_root'],
        'evidence_root_must_remain_unchanged': True,
        'signing_key_fingerprint': binding['signing_key_fingerprint'],
        'predecessor_artifact': 'kernel-headers-6.18.44-x86-1.txz',
        'predecessor_package_sha256': binding['predecessor_package_sha256'],
        'target_artifact': 'kernel-headers-6.18.45-x86-1.txz',
        'target_package_sha256': binding['target_package_sha256'],
        'survives_later_publication': True,
        'controller_reacquisition_authorized': False,
    },
    'fresh_target_revalidation': {
        'state': 'read-only-observation-authorized',
        'probe_path': 'tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-probe.sh',
        'probe_sha256': probe_sha,
        'probe_execution': 'root-via-sudo',
        'probe_scope': 'standalone-read-only-fresh-target-identity-and-pre-staging-state-revalidation',
        'expected_hostname_fqdn': baseline['hostname_fqdn'],
        'expected_uname_machine': baseline['uname_machine'],
        'expected_uname_release': baseline['uname_release'],
        'expected_slackware_version': baseline['slackware_version'],
        'expected_reference_script_sha256': baseline['reference_script_sha256'],
        'expected_effective_config_sha256': baseline['effective_config_sha256'],
        'expected_package_database': baseline['package_database'],
        'expected_package_database_canonical': baseline['package_database_canonical'],
        'expected_package_database_manifest_sha256': baseline['package_database_manifest_sha256'],
        'expected_header_package_record': baseline['header_package_record'],
        'expected_kernel_generic_record': r194['boot_package_record_kernel-generic'],
        'expected_kernel_huge_status': 'absent',
        'expected_kernel_modules_status': 'absent',
        'expected_slackpkg_conf_sha256': baseline['slackpkg_conf_sha256'],
        'expected_slackpkg_mirrors_sha256': baseline['slackpkg_mirrors_sha256'],
        'fresh_boot_id_required': True,
        'previous_boot_id_match_required': False,
        'previous_boot_id_must_not_be_used_as_binding': True,
        'target_repository_required': False,
        'repository_refresh_allowed': False,
        'network_access_allowed': False,
        'package_mutation_allowed': False,
        'boot_mutation_allowed': False,
        'persistent_system_configuration_change_allowed': False,
        'reboot_allowed': False,
        'observation_output_must_be_returned_for_next_gate': True,
        'live_candidate_set_bound': False,
        'slackware_current_publication_invalidates_review': False,
    },
    'local_source_state': {
        'builder_path': local_source['builder_path'],
        'builder_implementation_state': 'not-implemented',
        'local_source_tree_built': False,
        'local_source_tree_manifest_bound': False,
        'target_artifact_copy_authorized': False,
        'local_source_build_authorized': False,
    },
    'authorization': {
        'runtime_target_revalidation_observation_authorized': True,
        'fresh_target_revalidation_freeze_authorized_after_successful_observation': True,
        'controller_artifact_acquisition_authorized': False,
        'controller_network_access_authorized': False,
        'repository_refresh_authorized': False,
        'network_refresh_authorized': False,
        'target_vm_network_access_authorized': False,
        'target_artifact_copy_authorized': False,
        'local_source_build_authorized': False,
        'runtime_executor_implementation_authorized': False,
        'runtime_scenario_execution_authorized': False,
        'package_action_authorized': False,
        'boot_action_authorized': False,
        'reboot_authorized': False,
        'phase_2_start_authorized': False,
    },
    'gates': {
        'acceptance_matrix_complete': False,
        'kernel_package_edge_family_closed': False,
        'reference_freeze_status': 'blocked-behind-remaining-acceptance-work',
        'c_port_status': 'blocked-by-phase-1-gate',
    },
    'machine_action_required': True,
    'machine_action_type': 'read-only-fresh-target-revalidation-observation',
    'controller_action_required': False,
    'pause_safe': False,
    'helper_path': 'tools/reference/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review.sh',
    'helper_sha256': helper_sha,
    'record_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-review.tsv',
    'next_stage': 'phase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze',
}

out_policy.write_text(json.dumps(policy, indent=2) + '\n', encoding='utf-8')
rows = [
    ('accepted_resume_boundary_step', '200'),
    ('accepted_resume_boundary_policy_sha256', p200_sha),
    ('accepted_resume_boundary_record_sha256', r200_sha),
    ('historical_target_baseline_step', '194'),
    ('historical_target_baseline_policy_sha256', p194_sha),
    ('historical_target_baseline_record_sha256', r194_sha),
    ('prior_target_binding_reusable', 'no'),
    ('historical_baseline_purpose', 'expected-pre-staging-state-only'),
    ('previous_boot_id_match_required', 'no'),
    ('selected_family', selected['family']),
    ('selected_scenario', selected['selected_scenario']),
    ('family_closed', 'no'),
    ('artifact_byte_binding_state', binding['state']),
    ('evidence_root', binding['evidence_root']),
    ('evidence_root_must_remain_unchanged', 'yes'),
    ('frozen_predecessor_artifact', 'kernel-headers-6.18.44-x86-1.txz'),
    ('frozen_predecessor_sha256', binding['predecessor_package_sha256']),
    ('frozen_target_artifact', 'kernel-headers-6.18.45-x86-1.txz'),
    ('frozen_target_sha256', binding['target_package_sha256']),
    ('fresh_target_revalidation_state', 'read-only-observation-authorized'),
    ('revalidation_probe_path', policy['fresh_target_revalidation']['probe_path']),
    ('revalidation_probe_sha256', probe_sha),
    ('probe_execution', 'root-via-sudo'),
    ('expected_hostname_fqdn', baseline['hostname_fqdn']),
    ('expected_uname_machine', baseline['uname_machine']),
    ('expected_uname_release', baseline['uname_release']),
    ('expected_slackware_version', baseline['slackware_version']),
    ('expected_package_database_manifest_sha256', baseline['package_database_manifest_sha256']),
    ('expected_header_package_record', baseline['header_package_record']),
    ('expected_kernel_generic_record', r194['boot_package_record_kernel-generic']),
    ('expected_kernel_huge_status', 'absent'),
    ('expected_kernel_modules_status', 'absent'),
    ('expected_slackpkg_conf_sha256', baseline['slackpkg_conf_sha256']),
    ('expected_slackpkg_mirrors_sha256', baseline['slackpkg_mirrors_sha256']),
    ('fresh_boot_id_required', 'yes'),
    ('target_repository_required', 'no'),
    ('repository_refresh_allowed', 'no'),
    ('network_access_allowed', 'no'),
    ('package_mutation_allowed', 'no'),
    ('boot_mutation_allowed', 'no'),
    ('persistent_system_configuration_change_allowed', 'no'),
    ('reboot_allowed', 'no'),
    ('observation_output_must_be_returned_for_next_gate', 'yes'),
    ('live_candidate_set_bound', 'no'),
    ('runtime_target_revalidation_observation_authorized', 'yes'),
    ('fresh_target_revalidation_freeze_authorized_after_successful_observation', 'yes'),
    ('target_vm_network_access_authorized', 'no'),
    ('target_artifact_copy_authorized', 'no'),
    ('local_source_build_authorized', 'no'),
    ('runtime_scenario_execution_authorized', 'no'),
    ('package_action_authorized', 'no'),
    ('boot_action_authorized', 'no'),
    ('reboot_authorized', 'no'),
    ('phase_2_start_authorized', 'no'),
    ('machine_action_required', 'yes'),
    ('machine_action_type', 'read-only-fresh-target-revalidation-observation'),
    ('controller_action_required', 'no'),
    ('pause_safe', 'no'),
    ('next_stage', policy['next_stage']),
]
with out_record.open('w', encoding='utf-8', newline='') as handle:
    writer = csv.writer(handle, delimiter='\t', lineterminator='\n')
    writer.writerows(rows)
PY

printf 'policy\t%s\n' "$policy"
printf 'record\t%s\n' "$record"
printf 'probe_sha256\t%s\n' "$probe_sha"
printf 'next_stage\tphase-1-kernel-package-edge-local-source-construction-fresh-target-revalidation-freeze\n'
