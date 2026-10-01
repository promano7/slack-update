#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import csv
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-resume-planning-boundary-review'
prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review'
next_stage = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-review'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-resume-planning-boundary-review.md': '15fea852d27825050ef8ac7b7cc4b274b6e12da93ca2bfef0b448df69d2d60c7', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-resume-planning-boundary-review-policy.json': 'dcda6e412022074aa86a352810623e46dfcf1b148213480ac0e9db9fde56ec76', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-resume-planning-boundary-review.tsv': 'f7dd72d31e92e59b1e44b16f15256baca6c51a2e50592242a47b66bf147c89c9', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-resume-planning-boundary-review-roadmap.tsv': '6e8ef4d23b2522c73a9b009d989d3710221556fe20292adbc5d32fc206a52407', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-resume-planning-boundary-review.sh': '75c0382007484393b0694b19a5976a71ebb8ef15288366c7fa279d091efadd12'}
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
helper = root / 'tools/reference' / (base + '.sh')
policy_path = fixture / (base + '-policy.json')
policy = json.loads(policy_path.read_text())
previous = json.loads((fixture / (prior + '-policy.json')).read_text())
passes = 0

def check(label, value):
    global passes
    if not value:
        raise SystemExit('FAIL: ' + label)
    passes += 1
    print('PASS: ' + label)

def run(args):
    return subprocess.run([str(x) for x in args], capture_output=True, text=True)

accepted = policy['accepted_checkpoint']
for rel, digest in (accepted['sha256_bindings'] | own_hashes).items():
    path = root / rel
    check('exact regular artifact: ' + path.name,
          path.is_file() and not path.is_symlink() and hashlib.sha256(path.read_bytes()).hexdigest() == digest)
for path in [helper, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax: ' + path.name, run(['bash', '-n', path]).returncode == 0)

check('review stage identity', policy['schema'] == 1 and policy['step'] == 280 and policy['scenario'] == base and policy['review_only'] and policy['review_status'] == 'PASS')
check('consumes accepted predecessor next stage', previous['next_stage'] == base)
check('confirmed user checkpoint', accepted['step'] == 279 and accepted['commit'] == '3031f09' and accepted['acceptance_result'] == 'PASS (145 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('commit prefix provenance without invented full object', accepted['commit_identity_scope'] == 'user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted and accepted['provenance'].startswith('confirmed-step279-continuation-'))
check('historical strong pause retained', accepted['strong_safe_pause'] and accepted['no_open_operational_authorization'] and previous['pause_safe'] and previous['strong_safe_pause'] and policy['accepted_step279_pause_remains_valid_as_historical_checkpoint'])
for current, old in [
    ('accepted_failure_characterization', 'failure_characterization'),
    ('accepted_reviewed_effect_boundary', 'reviewed_effect_boundary'),
    ('accepted_authorization_closure', 'authorization_closure'),
    ('historical_observation', 'historical_accepted_observation'),
    ('historical_returned_attempt', 'returned_attempt'),
]:
    check('exact predecessor semantics preserved: ' + old, policy[current] == previous[old])
check('single build attempt remains consumed', policy['accepted_authorization_closure']['step278_build_authority_consumed'] and policy['accepted_authorization_closure']['consumed_on_preflight_rejection'])
check('probe authority remains consumed', policy['historical_observation']['probe_authority_consumed'] and not policy['historical_observation']['probe_rerun_authorized'])
check('no boot-change cause invented', policy['historical_returned_attempt']['boot_change_cause'] == 'not-determined-from-returned-output')

boundary = policy['fresh_boundary']
check('fresh boundary only opens repository planning', boundary['scope'] == 'repository-only-resume-planning-after-consumed-preflight-boot-drift-attempt' and boundary['no_operational_authority_inherited'])
check('no current boot seed', boundary['current_boot_id'] is None)
check('no current preservation overclaim', boundary['no_current_machine_state_claim'] and not boundary['current_target_or_output_preservation_independently_observed'])
check('acceptance matrix and Phase 2 remain open and closed respectively', not boundary['phase_1_kernel_package_edge_runtime_acceptance_complete'] and not boundary['phase_2_open'])
immutable = policy['immutable_implementation']
for name in ['builder', 'executor']:
    check('immutable future input ' + name,
          immutable[name + '_path'] == previous['frozen_implementation'][name + '_path'] and immutable[name + '_sha256'] == previous['frozen_implementation'][name + '_sha256'])
check('no immutable implementation edit or consumed authorization reuse', not immutable['modification_authorized'] and not immutable['consumed_step278_authorization_reusable'] and not immutable['step267_failed_executor_runtime_reusable'])
check('new authority required for immutable executor selection', immutable['reuse_only_under_new_authorization_after_fresh_observation'])

revalidation = policy['revalidation_boundary']
check('new probe remains at future design review', revalidation['state'] == 'design-review-next-not-designed-implemented-or-authorized-by-step280' and revalidation['new_separately_named_probe_required'] and revalidation['historical_probe_is_immutable_design_input_only'])
check('historical immutable probe exact baseline', revalidation['historical_probe_baseline_sha256'] == '3bd3db28f483e9ff842a4f6899ace758acadfc96a92ee2fe55bb5a2fe36577a2' and accepted['sha256_bindings'][revalidation['historical_probe_baseline_path']] == revalidation['historical_probe_baseline_sha256'])
check('immutable executor guard inventory preserved', revalidation['immutable_executor_guard_inventory'] == previous['frozen_implementation']['frozen_design']['preflight_guard_inventory'])
probe_source = (root / revalidation['historical_probe_baseline_path']).read_text()
probe_guards = {
    'root-and-required-read-only-commands': "[[ ${EUID:-$(id -u)} -eq 0 ]]",
    'canonical-package-database-and-compatibility-symlink': 'compatibility package database symlink target drift',
    'fresh-canonical-boot-uuid': 'boot_id=$(cat /proc/sys/kernel/random/boot_id)',
    'fqdn-architecture-running-kernel-slackware-release': 'EXPECTED_SLACKWARE_VERSION',
    'package-database-manifest-and-installed-header-generic-records': 'EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256',
    'no-huge-modules-or-predecessor-records': 'kernel-modules',
    'slackpkg-configuration-and-mirrors': 'EXPECTED_SLACKPKG_MIRRORS_SHA256',
    'staged-target-exact-sha256': 'EXPECTED_TARGET_SHA256',
    'accepted-v3-tree-manifest-sidecar-and-contents': 'verify_local_source_v3',
    'preserved-failed-v2-evidence-and-empty-pkglist': 'verify_failed_v2_evidence',
    'unchanged-boot-slackpkg-state-and-geninitrd-fingerprints': 'GenInitrd policy differs from failed v2 preflight fingerprint',
    'all-v4-final-and-temporary-outputs-absent': 'verify_v4_outputs_absent',
}
check('complete applicable probe inventory', revalidation['required_probe_guard_inventory'] == list(probe_guards))
for label, token in probe_guards.items():
    check('planned guard present in exact baseline: ' + label, token in probe_source)
for key in [
    'complete_existing_non_boot_target_and_output_guards_required',
    'fresh_canonical_boot_uuid_must_be_observed_not_seeded',
    'fresh_observation_may_equal_historical_uuid_without_reusing_authority',
    'full_returned_observation_required_before_freeze_or_build_authorization',
    'any_target_or_output_drift_requires_stop_and_separate_review',
    'observation_and_authorization_must_be_from_same_uninterrupted_boot',
    'immediate_immutable_executor_preflight_still_required',
    'no_reboot_or_vm_restart_between_observation_and_attempt',
    'failure_or_interruption_consumes_each_future_single_use_authorization',
]:
    check('future revalidation requirement: ' + key, revalidation[key] is True)
for key in ['patching_constants_or_deleting_outputs_to_force_pass_allowed', 'observation_authorized_now', 'historical_live_binding_reusable']:
    check('revalidation permission remains closed: ' + key, revalidation[key] is False)
build = policy['future_build_boundary']
for key in ['new_authorization_required', 'immutable_executor_and_builder_sha256_required', 'same_boot_as_new_accepted_observation_required', 'exact_single_invocation_even_on_preflight_failure', 'full_stdout_stderr_and_exit_status_required']:
    check('future build gate: ' + key, build[key] is True)
for key in ['automatic_or_manual_retry_allowed', 'boot_argument_from_error_substitution_allowed', 'authorization_granted_by_roadmap']:
    check('no future build shortcut: ' + key, build[key] is False)

roadmap = policy['roadmap']
preferred = roadmap['preferred_steps']
check('provisional nine-step route', roadmap['state'] == 'provisional-dependent-on-returned-evidence-not-execution-authority' and roadmap['preferred_step_count'] == len(preferred) == 9 and [p['step'] for p in preferred] == list(range(280, 289)))
check('three optional steps within requested twelve-step budget', roadmap['maximum_planned_step_count'] == 12 and [p['step'] for p in roadmap['optional_failure_steps']] == [289, 290, 291])
check('only actual result review is preferred pause candidate', [p['step'] for p in preferred if p['conditional_pause_candidate']] == [288])
check('new observation and build have distinct future permission gates', preferred[5]['future_gate'] == 'new-single-use-probe-authorization-required' and preferred[7]['future_gate'] == 'new-single-use-build-authorization-required')
check('no promised pause by arbitrary step number', not roadmap['pause_by_step288_or291_guaranteed'] and roadmap['can_stop_earlier_on_reviewed_effect_free_rejection'])
check('failure and incomplete output require review', roadmap['failed_probe_must_be_reviewed_before_build_authority'] and roadmap['incomplete_output_is_not_success_or_strong_pause'])
for key, value in policy['strong_pause_completion_conditions'].items():
    check('conditional strong-pause completion: ' + key, value is True)
authorization = policy['authorization']
check('only repository design review is open', [k for k, v in authorization.items() if v] == ['repository_only_revalidation_design_review_authorized'])
for key in previous['authorization']:
    check('prior permission not inherited: ' + key, authorization[key] is False)
for key in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']:
    check('reopened workstream state: ' + key, policy[key] is False)
check('next stage is repository design review', policy['next_stage'] == next_stage == preferred[1]['stage'])
check('acceptance no production or live entry', policy['repository_acceptance_scope'] == {
    'production_main_entered': False, 'production_builder_entered': False,
    'live_target_observation_performed': False, 'accepted_predecessor_full_repository_acceptance_required': True,
})
helper_source = helper.read_text()
check('helper invokes only predecessor acceptance', re.findall(r'(?m)^if ! bash -- "\$repo_root/([^\"]+)"', helper_source) == ['tests/reference/test-' + prior + '-harness.sh'])
check('helper never enters production or transport', not re.search(r'(?m)^\s*(?:sudo|scp|sftp|ssh|slackpkg|upgradepkg|installpkg|removepkg|reboot|eval|source)\b', helper_source) and '--execute-authorized' not in helper_source and '--observe-v4-' not in helper_source)

record_rows = [line.split('\t') for line in (fixture / (base + '.tsv')).read_text().splitlines()]
check('strict real-tab unique record', all(len(row) == 2 and all(row) for row in record_rows) and len(record_rows) == len(dict(record_rows)))
record = dict(record_rows)
check('record confirmed checkpoint and no current boot', record['step'] == '280' and record['accepted_checkpoint_commit'] == '3031f09' and record['accepted_checkpoint_acceptance'] == accepted['acceptance_result'] and record['current_boot_id'] == 'not-observed')
check('record preserves historical UUIDs only', record['historical_authorized_boot_id'] == previous['failure_characterization']['authorized_boot_id'] and record['historical_error_observed_boot_id'] == previous['failure_characterization']['observed_boot_id'] and record['historical_live_binding_reusable'] == 'no')
check('record no current preservation claim or roadmap authority', record['current_full_state_preservation_independently_observed'] == record['current_v4_output_absence_independently_observed'] == record['roadmap_is_execution_authority'] == 'no')
check('record complete permission and state consistency', all(record[k] == ('yes' if v else 'no') for k, v in authorization.items()) and all(record[k] == ('yes' if policy[k] else 'no') for k in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']) and record['next_stage'] == next_stage)
with (fixture / (base + '-roadmap.tsv')).open(newline='') as handle:
    roadmap_rows = list(csv.DictReader(handle, delimiter='\t'))
check('roadmap TSV exactly matches JSON gates', roadmap_rows == [{k: ('yes' if v else 'no') if isinstance(v, bool) else str(v) for k, v in p.items()} for p in preferred])

for argv in [['--help'], ['--bogus'], [], ['--output-dir'], ['--output-dir', '']]:
    result = run(['bash', '--', helper, *argv])
    check('strict CLI ' + repr(argv), result.returncode == (0 if argv == ['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step280-repository-') as directory:
    tmp = Path(directory)
    output = tmp / 'planning output'
    output.mkdir()
    result = run(['bash', '--', helper, '--output-dir', output])
    check('full accepted 145-pass suite actually reruns', result.returncode == 0 and 'accepted_step279_revalidated\tPASS (145 passes, 0 failures)' in result.stdout)
    for suffix in ['-policy.json', '.tsv', '-roadmap.tsv']:
        check('exact planning output ' + suffix, (output / (base + suffix)).read_bytes() == (fixture / (base + suffix)).read_bytes())
    check('helper publishes closed machine state', 'all_prior_operational_authority_revoked\tyes' in result.stdout and 'live_target_observation_performed\tno' in result.stdout and 'strong_safe_pause\tno' in result.stdout and 'next_stage\t' + next_stage in result.stdout)
    before = {p.name: p.read_bytes() for p in output.iterdir()}
    result = run(['bash', '--', helper, '--output-dir', output])
    check('duplicate output rejected without overwrite', result.returncode != 0 and {p.name: p.read_bytes() for p in output.iterdir()} == before)
    link = tmp / 'output-link'
    link.symlink_to(output, target_is_directory=True)
    check('symlink output rejected', run(['bash', '--', helper, '--output-dir', link]).returncode != 0)
    nested = output / 'nested'
    nested.mkdir()
    check('symlink output ancestor rejected', run(['bash', '--', helper, '--output-dir', link / 'nested']).returncode != 0 and not list(nested.iterdir()))
    check('missing output directory rejected', run(['bash', '--', helper, '--output-dir', tmp / 'missing']).returncode != 0 and not (tmp / 'missing').exists())
    replica = tmp / 'replica'
    shutil.copytree(root, replica, ignore=shutil.ignore_patterns('.git'))
    rejected = tmp / 'rejected'
    rejected.mkdir()
    replica_helper = replica / 'tools/reference' / (base + '.sh')
    for rel in list(accepted['sha256_bindings']) + [k for k in own_hashes if k != f'tools/reference/{base}.sh']:
        target = replica / rel
        original = target.read_bytes()
        target.write_bytes(original + b'\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed input rejected before publication: ' + target.name, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
    historical_target = replica / immutable['executor_path']
    original = historical_target.read_bytes()
    historical_target.unlink()
    historical_target.symlink_to(root / immutable['executor_path'])
    result = run(['bash', '--', replica_helper, '--output-dir', rejected])
    check('same-content symlink predecessor rejected', result.returncode != 0 and not list(rejected.iterdir()))
    historical_target.unlink()
    historical_target.write_bytes(original)
    for section, key, value in [
        ('authorization', 'new_probe_execution_authorized', True),
        ('authorization', 'boot_argument_substitution_authorized', True),
        ('fresh_boundary', 'current_boot_id', previous['failure_characterization']['observed_boot_id']),
        ('fresh_boundary', 'current_target_or_output_preservation_independently_observed', True),
        ('roadmap', 'pause_by_step288_or291_guaranteed', True),
    ]:
        target = replica / policy_path.relative_to(root)
        original = target.read_bytes()
        bad = json.loads(original)
        bad[section][key] = value
        target.write_text(json.dumps(bad) + '\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed permission or overclaim rejected: ' + key, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)

for rel in list(own_hashes) + ['tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace: ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
changelog = (root / 'CHANGELOG.md').read_text()
check('CHANGELOG confirms predecessor and distinguishes current workstream', '## Phase 1 step 280 ' in changelog and '3031f09' in changelog and 'Step 279 remains the accepted historical strong-pause checkpoint' in changelog and '## Phase 1 step 279 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
