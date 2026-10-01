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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze'
prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-review'
next_stage = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze.md': 'd45a4177811285201c1396b3d9efc5cfc82f1ac81e08462ba95bb2428faa7dd0', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze-policy.json': '2ec01bc01e3d55e35001fdbc170331f3978d02baddc4f4f86f9c0c1f3cf82de5', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze.tsv': '596dd44d0b0d2d98525e58c9abb8ebeb71f435c77e58228f30645d99f6ac9795', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze-freeze.tsv': '515dcecd3bf8b27672085aa4380943599ffe033256be906ac48c9e0bdb19211e', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze.sh': 'c0483260b9609542259b2bcb64ebd1c9f38afd8f4955c3b6164508e30314b3d2'}
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
check('freeze stage identity and accepted next stage', policy['schema'] == 1 and policy['step'] == 282 and policy['scenario'] == base and policy['review_status'] == 'PASS' and policy['review_only'] and previous['next_stage'] == base)
check('confirmed69e6c2c full137 user checkpoint', accepted['step'] == 281 and accepted['commit'] == '69e6c2c' and accepted['acceptance_result'] == 'PASS (137 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('complete-output prefix provenance without full object invention', accepted['commit_identity_scope'] == 'user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted and accepted['provenance'] == 'complete-user-returned-step281-application-acceptance-commit-push-clean-tree-2026-10-01')
design = policy['design']
expected = copy.deepcopy(previous['design'])
expected['state'] = 'design-frozen-not-implemented-not-observation-authorized'
check('whole design frozen with only state change', design == expected)
for key in ['ordered_exact_replacements', 'preserved_guard_function_sha256', 'preserved_readonly_constant_lines', 'cli', 'library_only_seam', 'publication', 'effect_boundary', 'future_implementation_acceptance_required']:
    check('exact frozen design section: ' + key, design[key] == previous['design'][key])
check('expected derivation SHA remains exact and uninstalled', design['reviewed_derivation_sha256'] == previous['design']['reviewed_derivation_sha256'] == 'fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b' and not design['reviewed_derivation_is_installed_implementation'] and not design['reviewed_derivation_production_execution_performed'])
freeze = policy['freeze_contract']
for key in ['design_is_exact_step281_except_state', 'reviewed_derivation_sha256_frozen', 'all_six_ordered_replacements_frozen', 'all_nine_guard_function_hashes_and_readonly_constants_frozen', 'cli_uuid_library_seam_publication_and_effect_contract_frozen', 'implementation_requires_exact_reviewed_derivation', 'implementation_review_and_freeze_before_new_observation_authorization']:
    check('freeze invariant: ' + key, freeze[key] is True)
for key in ['new_probe_installed_by_this_step', 'observation_authorization_granted_by_freeze', 'build_authorization_granted_by_freeze', 'historical_live_binding_reusable']:
    check('freeze grants no machine effect: ' + key, freeze[key] is False)
for key in ['immutable_implementation', 'accepted_authorization_closure', 'historical_observation', 'historical_returned_attempt', 'future_build_boundary', 'roadmap', 'strong_pause_completion_conditions']:
    check('historical preservation and future boundary: ' + key, policy[key] == previous[key])
check('current boot/target/output state remains unobserved', policy['current_boot_id'] is None and not policy['current_target_or_output_preservation_independently_observed'])
implementation = policy['repository_implementation_boundary']
check('only new path and exact derivation may be implemented', implementation['only_new_separately_named_probe_path_may_be_implemented'] == design['future_probe_path'] and implementation['exact_reviewed_derivation_sha256_required'] == design['reviewed_derivation_sha256'])
check('implementation permission cannot patch history or grant observation', not implementation['accepted_design_or_baseline_modification_allowed'] and not implementation['immutable_builder_or_executor_modification_allowed'] and not implementation['transport_or_live_observation_granted_by_implementation_permission'])
check('frozen synthetic implementation acceptance required', implementation['synthetic_function_acceptance_required'] == design['future_implementation_acceptance_required'])
authorization = policy['authorization']
check('only repository implementation and review are open', {key for key, value in authorization.items() if value} == {'new_probe_implementation_authorized', 'repository_only_revalidation_probe_implementation_review_authorized'})
check('previous design-freeze permission consumed; no operational permission inherited', all(value == (key == 'new_probe_implementation_authorized') for key, value in authorization.items() if key in previous['authorization']))
check('no machine/controller action or new strong pause', all(policy[key] is False for key in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']))
check('next stage matches planned step283', policy['next_stage'] == next_stage == previous['roadmap']['preferred_steps'][3]['stage'])
check('repository acceptance scope is non-production freeze', policy['repository_acceptance_scope'] == {'full_accepted137_predecessor_suite_required': True, 'production_main_entered': False, 'production_builder_entered': False, 'live_target_observation_performed': False, 'new_probe_installed': False})
inventory = policy['frozen_identity_inventory']
check('four distinct frozen identity roles', [row['role'] for row in inventory] == ['historical-probe-baseline', 'future-probe-derivation', 'immutable-builder', 'immutable-executor'])
check('future probe identity explicitly uninstalled design', inventory[1] == {'role': 'future-probe-derivation', 'path': design['future_probe_path'], 'sha256': design['reviewed_derivation_sha256'], 'state': 'frozen-design-expected-bytes-not-installed'})
for row in [inventory[0], inventory[2], inventory[3]]:
    check('frozen actual input identity: ' + row['role'], accepted['sha256_bindings'][row['path']] == row['sha256'])
with (fixture / (base + '-freeze.tsv')).open(newline='') as handle:
    inventory_rows = list(csv.DictReader(handle, delimiter='\t'))
check('freeze TSV exactly matches identity inventory', inventory_rows == inventory)
rows = [line.split('\t') for line in (fixture / (base + '.tsv')).read_text().splitlines()]
check('strict real-tab unique record', all(len(row) == 2 and all(row) for row in rows) and len(rows) == len(dict(rows)))
record = dict(rows)
check('record matches accepted checkpoint and frozen state', record['step'] == '282' and record['accepted_checkpoint_commit'] == '69e6c2c' and record['accepted_checkpoint_acceptance'] == accepted['acceptance_result'] and record['design_state'] == design['state'] and record['reviewed_derivation_sha256'] == design['reviewed_derivation_sha256'])
check('record exact frozen counts and no current machine claim', record['frozen_replacement_count'] == str(len(design['ordered_exact_replacements'])) == '6' and record['frozen_guard_function_count'] == str(len(design['preserved_guard_function_sha256'])) == '9' and record['current_boot_id'] == 'not-observed' and record['new_probe_installed_by_this_step'] == 'no')
check('record permissions and state consistent', all(record[key] == ('yes' if value else 'no') for key, value in authorization.items()) and all(record[key] == 'no' for key in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']) and record['next_stage'] == next_stage)
source = helper.read_text()
check('helper only invokes accepted predecessor suite', re.findall(r'(?m)^if ! bash -- "\$repo_root/([^\"]+)"', source) == ['tests/reference/test-' + prior + '-harness.sh'] and not re.search(r'(?m)^\s*(?:sudo|source|eval|ssh|scp|slackpkg|upgradepkg|reboot)\b', source))
for argv in [['--help'], ['--bogus'], [], ['--output-dir'], ['--output-dir', '']]:
    check('strict helper CLI ' + repr(argv), run(['bash', '--', helper, *argv]).returncode == (0 if argv == ['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step282-repository-') as directory:
    tmp = Path(directory); output = tmp / 'freeze output'; output.mkdir()
    result = run(['bash', '--', helper, '--output-dir', output])
    check('full137 design suite actually reruns', result.returncode == 0 and 'accepted_step281_revalidated\tPASS (137 passes, 0 failures)' in result.stdout)
    for suffix in ['-policy.json', '.tsv', '-freeze.tsv']:
        check('exact freeze publication ' + suffix, (output / (base + suffix)).read_bytes() == (fixture / (base + suffix)).read_bytes())
    check('publication says frozen, unimplemented and no observation', 'design_frozen\tyes' in result.stdout and 'future_probe_implemented\tno' in result.stdout and 'live_target_observation_performed\tno' in result.stdout)
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
        ('freeze_contract', 'new_probe_installed_by_this_step', True),
        ('design', 'reviewed_derivation_sha256', '0' * 64),
    ]:
        target = replica / policy_path.relative_to(root); original = target.read_bytes(); bad = json.loads(original); bad[section][key] = value; target.write_text(json.dumps(bad) + '\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed freeze or operational permission rejected: ' + key, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
for rel in list(own_hashes) + ['tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace: ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
changelog = (root / 'CHANGELOG.md').read_text()
check('CHANGELOG records accepted281 and exact frozen282 boundary', '## Phase 1 step 282 ' in changelog and '69e6c2c' in changelog and 'Froze the exact accepted design with only state changed' in changelog and '## Phase 1 step 281 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
