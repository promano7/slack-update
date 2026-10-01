#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import copy
import csv
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile

root = Path(sys.argv[1])
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze'
prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review'
next_stage = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze.md': '6d9432e9b42ade09eadf2b19ddf1f2814679410002192eafff8262759daf4690', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze-policy.json': '321bd93e1ab0ecb39f3a32296f4cea899cfd0d4207e9b318b5933377ce203a2c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze.tsv': '05e8b8aa9e28acef2aeff24c115f6ded9971cfbffffe6071b5a00fca7240cc00', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze-freeze.tsv': '2bb3ff796d045b1e5cee34dddecd672417345899b16e44f63965f85ea8f71c2a', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze.sh': '7e2ae2c4cff20ceaf9dbd125f0154ca84a55865795785000ff34da616f928bf7'}
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
    check('exact regular artifact: ' + path.name, path.is_file() and not path.is_symlink() and hashlib.sha256(path.read_bytes()).hexdigest() == digest)
for path in [helper, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax: ' + path.name, run(['bash', '-n', path]).returncode == 0)
check('freeze identity and accepted next stage', policy['schema'] == 1 and policy['step'] == 284 and policy['scenario'] == base and policy['review_status'] == 'PASS' and policy['review_only'] and previous['next_stage'] == base)
check('confirmed9cde0f1 full150 user checkpoint', accepted['step'] == 283 and accepted['commit'] == '9cde0f1' and accepted['acceptance_result'] == 'PASS (150 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('complete-output prefix provenance without full object invention', accepted['commit_identity_scope'] == 'user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted and accepted['provenance'] == 'complete-user-returned-step283-application-acceptance-commit-push-clean-tree-2026-10-01')
design = policy['design']
implementation = policy['implementation']
expected = copy.deepcopy(previous['implementation'])
expected['state'] = 'implementation-frozen-not-production-observed'
check('whole accepted implementation frozen with only state change', implementation == expected)
for key in previous['implementation']:
    if key != 'state':
        check('exact frozen implementation field: ' + key, implementation[key] == previous['implementation'][key])
for key in ['design', 'accepted_freeze_contract', 'immutable_implementation', 'accepted_authorization_closure', 'historical_observation', 'historical_returned_attempt', 'future_build_boundary', 'roadmap', 'strong_pause_completion_conditions']:
    check('historical preservation and future boundary: ' + key, policy[key] == previous[key])
probe = root / implementation['probe_path']
check('existing actual probe has accepted frozen bytes', probe.is_file() and not probe.is_symlink() and hashlib.sha256(probe.read_bytes()).hexdigest() == implementation['probe_sha256'] == design['reviewed_derivation_sha256'] == 'fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b')
check('historical design explicitly distinguished from present implementation', design['state'] == 'design-frozen-not-implemented-not-observation-authorized' and implementation['frozen_design_is_historical_checkpoint_not_current_implementation_state'])
freeze = policy['freeze_contract']
for key in ['implementation_is_exact_step283_except_state', 'whole_probe_bytes_and_sha256_frozen', 'all_six_ordered_replacements_frozen', 'all_nine_guard_function_hashes_and_readonly_constants_frozen', 'cli_uuid_library_seam_publication_and_effect_contract_frozen', 'full_accepted150_synthetic_implementation_suite_required', 'probe_already_present_from_accepted_step283', 'separate_fresh_observation_authorization_required']:
    check('freeze invariant: ' + key, freeze[key] is True)
for key in ['new_probe_installed_or_modified_by_this_step', 'observation_authorization_granted_by_freeze', 'build_authorization_granted_by_freeze', 'historical_live_binding_reusable']:
    check('freeze grants no machine effect: ' + key, freeze[key] is False)
check('current boot/target/output state remains unobserved', policy['current_boot_id'] is None and not policy['current_target_or_output_preservation_independently_observed'])
boundary = policy['next_authorization_review_boundary']
check('only separate fresh observation authorization review may be prepared', boundary['only_fresh_read_only_observation_authorization_review_may_be_prepared'] and boundary['frozen_probe_path'] == implementation['probe_path'] and boundary['frozen_probe_sha256'] == implementation['probe_sha256'])
check('next review cannot patch source or grant current observation', not boundary['probe_modification_allowed'] and not boundary['immutable_builder_or_executor_modification_allowed'] and not boundary['transport_or_live_observation_granted_by_this_freeze'])
check('fresh evidence precedes new build authorization', boundary['one_observation_requires_separate_explicit_authorization'] and boundary['observation_evidence_must_be_returned_and_frozen_before_build_authorization'] and not boundary['current_boot_or_target_preservation_inferred_from_synthetic_acceptance'])
authorization = policy['authorization']
check('only repository fresh authorization review is open', {key for key,value in authorization.items() if value} == {'repository_only_fresh_revalidation_authorization_review_authorized'})
check('previous implementation freeze permission consumed; no authority inherited', all(authorization[key] is False for key in previous['authorization']))
check('no machine/controller action or new strong pause', all(policy[key] is False for key in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']))
check('next stage matches planned step285', policy['next_stage'] == next_stage == previous['roadmap']['preferred_steps'][5]['stage'])
check('repository acceptance scope is synthetic-only implementation freeze', policy['repository_acceptance_scope'] == {'full_accepted150_predecessor_suite_required': True, 'actual_step283_synthetic_library_uuid_sha_and_cli_cases_repeated': True, 'production_main_entered': False, 'production_builder_entered': False, 'host_bound_guards_called': False, 'live_target_observation_performed': False, 'production_constants_modified': False, 'new_probe_installed_or_modified': False})
inventory = policy['frozen_identity_inventory']
check('four distinct frozen actual source roles', [row['role'] for row in inventory] == ['frozen-new-probe-implementation', 'historical-probe-baseline', 'immutable-builder', 'immutable-executor'])
check('new probe inventory describes actual existing implementation', inventory[0] == {'role':'frozen-new-probe-implementation','path':implementation['probe_path'],'sha256':implementation['probe_sha256'],'state':'repository-implementation-frozen-not-production-observed'})
for row in inventory:
    check('frozen actual input identity: ' + row['role'], accepted['sha256_bindings'][row['path']] == row['sha256'])
with (fixture / (base + '-freeze.tsv')).open(newline='') as handle:
    inventory_rows = list(csv.DictReader(handle, delimiter='\t'))
check('freeze TSV exactly matches identity inventory', inventory_rows == inventory)
rows = [line.split('\t') for line in (fixture / (base + '.tsv')).read_text().splitlines()]
check('strict real-tab unique record', all(len(row) == 2 and all(row) for row in rows) and len(rows) == len(dict(rows)))
record = dict(rows)
check('record matches accepted checkpoint and frozen implementation', record['step'] == '284' and record['accepted_checkpoint_step'] == '283' and record['accepted_checkpoint_commit'] == '9cde0f1' and record['accepted_checkpoint_acceptance'] == accepted['acceptance_result'] and record['implementation_state'] == implementation['state'] and record['probe_sha256'] == implementation['probe_sha256'])
check('record exact frozen counts and no current machine claim', record['frozen_replacement_count'] == str(len(design['ordered_exact_replacements'])) == '6' and record['frozen_guard_function_count'] == str(len(design['preserved_guard_function_sha256'])) == '9' and record['current_boot_id'] == 'not-observed' and record['probe_already_present_from_accepted_step283'] == 'yes' and record['new_probe_installed_or_modified_by_this_step'] == 'no')
check('record permissions and state consistent', all(record[key] == ('yes' if value else 'no') for key, value in authorization.items()) and all(record[key] == 'no' for key in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']) and record['next_stage'] == next_stage)
source = helper.read_text()
check('helper only invokes accepted predecessor suite', re.findall(r'(?m)^if ! bash -- "\$repo_root/([^\"]+)"', source) == ['tests/reference/test-' + prior + '-harness.sh'] and not re.search(r'(?m)^\s*(?:sudo|source|eval|ssh|scp|slackpkg|upgradepkg|reboot)\b', source))
for argv in [['--help'], ['--bogus'], [], ['--output-dir'], ['--output-dir', '']]:
    check('strict helper CLI ' + repr(argv), run(['bash', '--', helper, *argv]).returncode == (0 if argv == ['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step284-repository-') as directory:
    tmp = Path(directory); output = tmp / 'freeze output'; output.mkdir()
    result = run(['bash', '--', helper, '--output-dir', output])
    check('full150 synthetic implementation suite actually reruns', result.returncode == 0 and 'accepted_step283_revalidated\tPASS (150 passes, 0 failures)' in result.stdout)
    for suffix in ['-policy.json', '.tsv', '-freeze.tsv']:
        check('exact freeze publication ' + suffix, (output / (base + suffix)).read_bytes() == (fixture / (base + suffix)).read_bytes())
    check('publication says implementation frozen, unmodified and no observation', 'implementation_frozen\tyes' in result.stdout and 'probe_already_present_from_accepted_step283\tyes' in result.stdout and 'probe_modified_by_this_step\tno' in result.stdout and 'live_target_observation_performed\tno' in result.stdout and ('next_stage\t' + next_stage) in result.stdout)
    before = {path.name: path.read_bytes() for path in output.iterdir()}
    check('duplicate outputs rejected unchanged', run(['bash', '--', helper, '--output-dir', output]).returncode != 0 and {path.name: path.read_bytes() for path in output.iterdir()} == before)
    link = tmp / 'link'; link.symlink_to(output, target_is_directory=True)
    check('symlink output rejected', run(['bash', '--', helper, '--output-dir', link]).returncode != 0)
    nested = output / 'nested'; nested.mkdir()
    check('symlink output ancestor rejected', run(['bash', '--', helper, '--output-dir', link / 'nested']).returncode != 0 and not list(nested.iterdir()))
    check('missing output rejected without creation', run(['bash', '--', helper, '--output-dir', tmp / 'missing']).returncode != 0 and not (tmp / 'missing').exists())
    replica = tmp / 'replica'; shutil.copytree(root, replica, ignore=shutil.ignore_patterns('.git'))
    rejected = tmp / 'rejected'; rejected.mkdir()
    replica_helper = replica / 'tools/reference' / (base + '.sh')
    for rel in list(accepted['sha256_bindings']) + [key for key in own_hashes if key != f'tools/reference/{base}.sh']:
        target = replica / rel; original = target.read_bytes(); target.write_bytes(original + b'\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed input rejects before freeze publication: ' + target.name, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
    target = replica / design['baseline_path']; original = target.read_bytes(); target.unlink(); target.symlink_to(root / design['baseline_path'])
    result = run(['bash', '--', replica_helper, '--output-dir', rejected])
    check('same-content symlink baseline rejected', result.returncode != 0 and not list(rejected.iterdir()))
    target.unlink(); target.write_bytes(original)
    for section, key, value in [
        ('authorization', 'new_probe_execution_authorized', True),
        ('authorization', 'new_probe_transport_authorized', True),
        ('freeze_contract', 'new_probe_installed_or_modified_by_this_step', True),
        ('implementation', 'probe_sha256', '0' * 64),
    ]:
        target = replica / policy_path.relative_to(root); original = target.read_bytes(); bad = json.loads(original); bad[section][key] = value; target.write_text(json.dumps(bad) + '\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed freeze or operational permission rejected: ' + key, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
for rel in list(own_hashes) + ['tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace: ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
changelog = (root / 'CHANGELOG.md').read_text()
check('CHANGELOG records accepted283 and exact frozen284 boundary', '## Phase 1 step 284 ' in changelog and '9cde0f1' in changelog and 'Froze the whole accepted implementation object with only state changed' in changelog and '## Phase 1 step 283 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST