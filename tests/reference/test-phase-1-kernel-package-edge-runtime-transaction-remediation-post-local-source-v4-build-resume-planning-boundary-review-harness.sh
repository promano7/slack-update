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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-resume-planning-boundary-review'
prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-resume-planning-boundary-review.md': '56754704d9a8cf2d773631766cbd57e81d6ba3319910de4b4b9771495a5f4b0e', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-resume-planning-boundary-review-policy.json': 'd32140a1f849d39bfec460690264e3d674104dc66ad809d03aa37081f658f312', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-resume-planning-boundary-review.tsv': '64b4657057f0d55376aa06a0769a0f5c9b1c1a2b9622593bdcff93d7dfa587fe', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-resume-planning-boundary-review-roadmap.tsv': 'b053f9296c9e2c735da5f37b5fc95d719642aae49ec318c70462ffa5c1c91e80', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-resume-planning-boundary-review.sh': 'fea673e03fd15ef3588447678f72e06aba40b131a4a38e9dc3976f7c4e0a50b0'}
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
policy_path = fixture / (base + '-policy.json')
policy = json.loads(policy_path.read_text())
previous = json.loads((fixture / (prior + '-policy.json')).read_text())
helper = root / 'tools/reference' / (base + '.sh')
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
    check('exact regular artifact: ' + path.name, path.is_file() and not path.is_symlink() and hashlib.sha256(path.read_bytes()).hexdigest() == digest)
for path in [helper, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax: ' + path.name, run(['bash', '-n', path]).returncode == 0)
check('review follows the accepted future explicit resume stage', policy['schema'] == 1 and policy['step'] == 289 and policy['scenario'] == previous['next_stage'] == base and policy['review_only'] and policy['review_status'] == 'PASS')
check('confirmed step288 complete152 checkpoint', accepted['step'] == 288 and accepted['commit'] == '7df17a9' and accepted['acceptance_result'] == 'PASS (152 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'] and accepted['strong_safe_pause'] and accepted['no_open_operational_authorization'])
check('commit prefix provenance without invented full ID', accepted['commit_identity_scope'] == 'user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted)
for current, old in [('accepted_build_result', 'accepted_build_result'), ('accepted_local_source_v4', 'accepted_local_source_v4'), ('accepted_authorization_closure', 'authorization_closure'), ('accepted_runtime_boundary_after_pause', 'runtime_boundary_after_pause'), ('historical_observation', 'accepted_observation')]:
    check('exact accepted evidence boundary: ' + current, policy[current] == previous[old])
check('accepted actual build includes exit0 and consumed single-use authority', policy['accepted_build_result']['reported_exit_status'] == 0 and policy['accepted_build_result']['authority_consumed'] and policy['accepted_build_result']['authorization_use_count'] == 1 and not policy['accepted_build_result']['second_execution_authorized'])
check('v4 actual manifest identity retained', policy['accepted_local_source_v4']['tree_manifest_sha256'] == 'a4b0fc122c6274c7fdf70907661511bcf6ba475a2aa3bc46b96e5bcbf6ed3db8')
check('accepted historical pause remains valid', policy['accepted_step288_pause_remains_valid_as_historical_checkpoint'])
boundary = policy['fresh_boundary']
check('fresh planning only with no inherited permission', boundary['scope'] == 'repository-only-resume-planning-after-accepted-local-source-v4-build' and boundary['no_operational_authority_inherited'])
check('no current boot or independent postbuild preservation claim', boundary['current_boot_id'] is None and not boundary['current_target_or_output_preservation_independently_observed'] and boundary['no_current_machine_state_claim'])
check('old binding remains expired without old boot continuity', not boundary['prior_live_binding_reusable'] and not boundary['old_vm_boot_continuity_required'])
check('Phase1 incomplete and Phase2 closed', not boundary['phase_1_acceptance_matrix_complete'] and not boundary['kernel_package_edge_complete'] and not boundary['phase_2_open'])
for key, value in policy['preservation'].items():
    check('preservation requirement: ' + key, value is True)
revalidation = policy['revalidation_boundary']
check('only next design review, no implemented probe claim', revalidation['state'] == 'design-review-next-not-designed-implemented-or-authorized-by-step289' and revalidation['new_separately_named_read_only_probe_required'])
check('old absence probe cannot observe built v4', revalidation['old_output_absence_probe_not_applicable_to_built_v4'] and revalidation['historical_probe_is_immutable_design_input_only'])
check('historical probe bound as immutable design input', revalidation['historical_probe_baseline_path'] in accepted['sha256_bindings'])
expected_guards = [
    'root-and-required-read-only-commands', 'canonical-package-database-and-compatibility-symlink',
    'fresh-canonical-boot-uuid', 'fqdn-architecture-running-kernel-slackware-release',
    'package-database-manifest-and-installed-header-generic-records', 'no-huge-modules-or-predecessor-records',
    'slackpkg-configuration-and-mirrors', 'staged-target-exact-sha256',
    'accepted-v3-tree-manifest-sidecar-and-contents', 'preserved-failed-v2-evidence-and-empty-pkglist',
    'unchanged-boot-slackpkg-state-and-geninitrd-fingerprints',
    'accepted-v4-root-manifest-sidecar-and-exact-manifest-identity',
    'v4-safe-paths-exact-tree-inventory-content-ownership-and-modes',
    'v4-five-priority-trees-and-non-authenticating-compatibility-marker',
    'v4-builder-owned-temporary-output-absence',
]
check('postbuild guard inventory replaces only inapplicable absence boundary', revalidation['required_guard_inventory'] == expected_guards)
for key in ['current_uuid_freshly_observed_not_supplied', 'fresh_observation_may_equal_historical_uuid_without_reusing_authority', 'complete_stdout_stderr_and_exit_status_required', 'one_invocation_consumed_on_failure_or_interruption', 'drift_stops_for_separate_review']:
    check('future observation requirement: ' + key, revalidation[key] is True)
check('no live observation or constant patching now', not revalidation['constants_patching_or_baseline_replacement_allowed'] and not revalidation['observation_authorized_now'])
runtime = policy['future_runtime_boundary']
check('separate runtime boundary required', runtime['state'] == 'separate-source-candidate-executor-review-required-not-authorized' and runtime['accepted_v4_manifest_sha256'] == policy['accepted_local_source_v4']['tree_manifest_sha256'])
check('historical v2 immutable design input only', runtime['historical_v2_executor_is_immutable_design_input_only'] and runtime['historical_v2_executor_path'] in accepted['sha256_bindings'] and not runtime['historical_v2_executor_rerun_authorized'])
for key in ['new_executor_implementation_authorized', 'new_runtime_attempt_authorized', 'persistent_slackpkg_configuration_change_authorized', 'network_access_authorized']:
    check('runtime permission closed: ' + key, runtime[key] is False)
for key in ['no_runtime_attempt_planned_in_preferred_route', 'new_fresh_target_and_source_revalidation_before_later_runtime', 'same_uninterrupted_boot_for_future_observation_to_authorized_runtime', 'immediate_preflight_before_future_runtime_required', 'transaction_owned_workdir_and_temp_required', 'pre_refresh_pkglist_absent_required', 'slackpkg_exit0_is_necessary_not_sufficient', 'fresh_transaction_owned_pkglist_required', 'exact_target_only_candidate_binding_in_same_transaction_required', 'compatibility_asc_is_not_openpgp_signature']:
    check('future runtime contract: ' + key, runtime[key] is True)
source = (root / runtime['historical_v2_executor_path']).read_text()
check('human-spaced error signal retained from actual source', runtime['human_spaced_download_error_signal'] == 'Error downloading from ' and "grep -Fqi 'Error downloading from '" in source)
roadmap = policy['roadmap']; preferred = roadmap['preferred_steps']
check('ten preferred steps and two optional steps', roadmap['preferred_step_count'] == len(preferred) == 10 and [p['step'] for p in preferred] == list(range(289, 299)) and roadmap['maximum_planned_step_count'] == 12 and [p['step'] for p in roadmap['optional_failure_steps']] == [299, 300])
check('only complete closure is preferred conditional pause candidate', [p['step'] for p in preferred if p['conditional_pause_candidate']] == [298])
check('observation has separate future permission gate', preferred[5]['scope'] == 'one-read-only-observation' and preferred[5]['future_gate'] == 'new-single-use-probe-authorization')
check('no promised pause or roadmap execution grant', not roadmap['pause_by_step298_or300_guaranteed'] and not roadmap['roadmap_grants_machine_authority'] and roadmap['incomplete_output_is_not_success_or_strong_pause'] and roadmap['can_stop_earlier_on_reviewed_effect_free_rejection'])
for key, value in policy['strong_pause_completion_conditions'].items():
    check('strong pause condition: ' + key, value is True)
authorization = policy['authorization']
check('only repository revalidation design review open', [k for k, v in authorization.items() if v] == ['repository_only_revalidation_design_review_authorized'])
check('all prior operational permissions stay closed', all(not v for v in previous['authorization'].values()) and all(not authorization[k] for k in previous['authorization'] if k != 'repository_only_revalidation_design_review_authorized'))
for key in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']:
    check('current planning state: ' + key, policy[key] is False)
check('only next repository design stage', policy['next_stage'] == preferred[1]['stage'] == base.replace('resume-planning-boundary-review', 'revalidation-design-review'))
check('acceptance performs no machine entry', policy['repository_acceptance_scope'] == dict(accepted_predecessor_full_repository_acceptance_required=True, production_main_entered=False, production_builder_entered=False, live_target_observation_performed=False))
helper_source = helper.read_text()
check('helper invokes only full accepted predecessor suite', re.findall(r'(?m)^if ! bash -- "\$repo_root/([^\"]+)"', helper_source) == ['tests/reference/test-' + prior + '-harness.sh'])
check('helper has no production command or transport', not re.search(r'(?m)^\s*(?:sudo|scp|sftp|ssh|slackpkg|upgradepkg|installpkg|removepkg|reboot|eval|source)\b', helper_source))
rows = [line.split('\t') for line in (fixture / (base + '.tsv')).read_text().splitlines()]
check('strict real-tab unique nonempty record', all(len(row) == 2 and all(row) for row in rows) and len(rows) == len(dict(rows)))
record = dict(rows)
check('record checkpoint and fresh/current separation', record['step'] == '289' and record['accepted_checkpoint_commit'] == '7df17a9' and record['accepted_checkpoint_acceptance'] == accepted['acceptance_result'] and record['current_boot_id'] == 'not-observed' and record['prior_live_binding_reusable'] == 'no' and record['current_preservation_independently_observed'] == 'no')
check('record no runtime grant and exact v4 identity', record['roadmap_is_execution_authority'] == record['runtime_attempt_planned'] == 'no' and record['accepted_v4_manifest_sha256'] == runtime['accepted_v4_manifest_sha256'])
check('record complete permission/state consistency', all(record[k] == ('yes' if v else 'no') for k, v in authorization.items()) and all(record[k] == ('yes' if policy[k] else 'no') for k in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']) and record['next_stage'] == policy['next_stage'])
with (fixture / (base + '-roadmap.tsv')).open(newline='') as handle:
    roadmap_rows = list(csv.DictReader(handle, delimiter='\t'))
check('TSV roadmap exactly matches JSON gates', roadmap_rows == [{k: ('yes' if v else 'no') if isinstance(v, bool) else str(v) for k, v in p.items()} for p in preferred])
for argv in [['--help'], ['--bogus'], [], ['--output-dir'], ['--output-dir', '']]:
    result = run(['bash', '--', helper, *argv])
    check('strict CLI ' + repr(argv), result.returncode == (0 if argv == ['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step289-repository-') as directory:
    tmp = Path(directory); output = tmp / 'planning output'; output.mkdir()
    result = run(['bash', '--', helper, '--output-dir', output])
    check('complete accepted152 predecessor actually reruns', result.returncode == 0 and 'accepted_step288_revalidated\tPASS (152 passes, 0 failures)' in result.stdout)
    for suffix in ['-policy.json', '.tsv', '-roadmap.tsv']:
        check('exact planning publication ' + suffix, (output / (base + suffix)).read_bytes() == (fixture / (base + suffix)).read_bytes())
    check('helper reports no live observation or runtime authority', 'live_target_observation_performed\tno' in result.stdout and 'runtime_attempt_authorized\tno' in result.stdout and 'strong_safe_pause\tno' in result.stdout)
    before = {p.name: p.read_bytes() for p in output.iterdir()}
    result = run(['bash', '--', helper, '--output-dir', output])
    check('duplicate rejected without overwrite', result.returncode != 0 and {p.name: p.read_bytes() for p in output.iterdir()} == before)
    link = tmp / 'output-link'; link.symlink_to(output, target_is_directory=True)
    check('output symlink rejected', run(['bash', '--', helper, '--output-dir', link]).returncode != 0)
    nested = output / 'nested'; nested.mkdir()
    check('output symlink ancestor rejected', run(['bash', '--', helper, '--output-dir', link / 'nested']).returncode != 0 and not list(nested.iterdir()))
    check('missing output directory rejected', run(['bash', '--', helper, '--output-dir', tmp / 'missing']).returncode != 0 and not (tmp / 'missing').exists())
    replica = tmp / 'replica'; shutil.copytree(root, replica, ignore=shutil.ignore_patterns('.git'))
    rejected = tmp / 'rejected'; rejected.mkdir(); replica_helper = replica / helper.relative_to(root)
    for rel in list(accepted['sha256_bindings']) + [k for k in own_hashes if k != helper.relative_to(root).as_posix()]:
        target = replica / rel; original = target.read_bytes(); target.write_bytes(original + b'\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed bound input rejected before publication: ' + target.name, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
    historical_target = replica / runtime['historical_v2_executor_path']; original = historical_target.read_bytes()
    historical_target.unlink(); historical_target.symlink_to(root / runtime['historical_v2_executor_path'])
    result = run(['bash', '--', replica_helper, '--output-dir', rejected])
    check('same-content historical symlink rejected', result.returncode != 0 and not list(rejected.iterdir()))
    historical_target.unlink(); historical_target.write_bytes(original)
    for section, key, value in [
        ('authorization', 'new_probe_execution_authorized', True),
        ('authorization', 'runtime_executor_rerun_authorized', True),
        ('fresh_boundary', 'current_boot_id', 'bcfac4fa-4e6e-450a-aa95-bd591a979b4e'),
        ('fresh_boundary', 'current_target_or_output_preservation_independently_observed', True),
        ('future_runtime_boundary', 'new_runtime_attempt_authorized', True),
        ('roadmap', 'pause_by_step298_or300_guaranteed', True),
    ]:
        target = replica / policy_path.relative_to(root); original = target.read_bytes(); bad = json.loads(original)
        bad[section][key] = value; target.write_text(json.dumps(bad) + '\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('permission or state overclaim rejected: ' + key, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
for rel in list(own_hashes) + ['tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace: ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
changelog = (root / 'CHANGELOG.md').read_text()
check('CHANGELOG confirms predecessor and reopens planning', '## Phase 1 step 289 ' in changelog and '7df17a9' in changelog and 'Step 288 remains the accepted historical strong-pause checkpoint' in changelog and '## Phase 1 step 288 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
