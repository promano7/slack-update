#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import copy
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
root = Path(sys.argv[1])
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-freeze'
prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-review'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-freeze.md': '362384d1c56eba9c1bcfd639d1922a1b245f15cb44446a19c4c51264c83effbb', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-freeze-policy.json': '694ac9a2a5f9b0811940fc86cb4e333ba047cdc5de2330522d3c8042e29f4a98', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-freeze.tsv': '42aed340554805c1b9e553d3accdc7e50de471068546c5b77e64785d5d8f31fc', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-freeze-design.json': 'cde2cf457484f706b09c2c801aace70964f5cd4730663f87802def0090179230', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-freeze.sh': '3f993eeb7c2af157b21976a81dfc39bc424c2c7fc9d2ee6773842d037bdfc846'}
fixture = root / 'tests/fixtures/reference/acceptance/phase-1'
policy_path = fixture / (base + '-policy.json')
policy = json.loads(policy_path.read_text())
previous = json.loads((fixture / (prior + '-policy.json')).read_text())
helper = root / 'tools/reference' / (base + '.sh')
design = json.loads((fixture / (base + '-design.json')).read_text())
passes = 0

def check(label, value):
    global passes
    if not value:
        raise SystemExit('FAIL: ' + label)
    passes += 1
    print('PASS: ' + label)

def run(args):
    return subprocess.run([str(x) for x in args], capture_output=True, text=True)

def function(src, name):
    if name == 'tsv_value':
        return re.search(r'(?m)^tsv_value\(\).*$', src).group(0)
    return re.search(r'(?ms)^' + re.escape(name) + r'\(\) \{\n.*?^\}', src).group(0)

accepted = policy['accepted_checkpoint']
for rel, digest in (accepted['sha256_bindings'] | own_hashes).items():
    path = root / rel
    check('exact regular artifact: ' + path.name, path.is_file() and not path.is_symlink() and hashlib.sha256(path.read_bytes()).hexdigest() == digest)
for path in [helper, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax: ' + path.name, run(['bash', '-n', path]).returncode == 0)
check('freeze follows accepted design review next stage', policy['schema'] == 1 and policy['step'] == 291 and policy['scenario'] == previous['next_stage'] == base and policy['review_only'] and policy['review_status'] == 'PASS')
check('confirmed2571e24 complete199 predecessor', accepted['step'] == 290 and accepted['commit'] == '2571e24' and accepted['acceptance_result'] == 'PASS (199 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('prefix provenance without invented full commit', accepted['commit_identity_scope'] == 'user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted)
for key in ['accepted_build_result', 'accepted_local_source_v4', 'accepted_authorization_closure', 'accepted_runtime_boundary_after_pause', 'historical_observation', 'accepted_step288_pause_remains_valid_as_historical_checkpoint', 'fresh_boundary', 'preservation', 'revalidation_boundary', 'future_runtime_boundary', 'roadmap', 'strong_pause_completion_conditions']:
    check('unchanged accepted boundary: ' + key, policy[key] == previous[key])
expected = copy.deepcopy(previous['design']); expected['state'] = 'design-frozen-not-implemented-not-observation-authorized'
check('entire design frozen with state-only delta', policy['design'] == design == expected and policy['accepted_design_review_state'] == previous['design']['state'])
check('no changed source, derivation or installed/executed probe', policy['freeze_delta'] == dict(changed_design_keys=['state'], source_bytes_changed=False, derivation_sha256_changed=False, new_probe_installed=False, production_execution_performed=False))
for key in previous['design']:
    if key != 'state':
        check('exact frozen design member: ' + key, design[key] == previous['design'][key])
check('design fixture exact identity', policy['design_path'] == 'tests/fixtures/reference/acceptance/phase-1/' + base + '-design.json')
check('future source remains uninstalled at this freeze', not (root / design['future_probe_path']).exists())
original = (root / design['historical_baseline_path']).read_text()
check('immutable historical probe exact', hashlib.sha256(original.encode()).hexdigest() == design['historical_baseline_sha256'] == 'fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b')
planned = original
for change in design['replacements']:
    check('unique frozen replacement: ' + change['label'], planned.count(change['old']) == 1)
    planned = planned.replace(change['old'], change['new'], 1)
check('frozen future derivation SHA identical', hashlib.sha256(planned.encode()).hexdigest() == design['expected_derivation_sha256'] == '4d1bc852cf0bfea9b5131687bbe5cf70703cae04ae73a342a4afc7192a8440db')
for name, digest in design['preserved_guard_function_sha256'].items():
    check('exact historical guard preserved: ' + name, function(planned, name) == function(original, name) and hashlib.sha256(function(planned, name).encode()).hexdigest() == digest)
for name, digest in design['new_guard_function_sha256'].items():
    check('exact future postbuild guard frozen: ' + name, hashlib.sha256(function(planned, name).encode()).hexdigest() == digest)
check('readonly declarations unchanged apart from frozen v4 manifest addition', re.findall(r'(?m)^readonly .*$', original) == design['preserved_readonly_declarations'] and [line for line in re.findall(r'(?m)^readonly .*$', planned) if line != design['new_readonly_manifest_declaration']] == design['preserved_readonly_declarations'])
check('fifty unique ordered publication fields frozen', re.findall(r"(?m)^    printf '([A-Za-z0-9_]+)\\t", planned) == design['ordered_publication_fields'] and len(set(design['ordered_publication_fields'])) == design['publication_field_count'] == 50)
check('safe complete inventory and production ownership frozen', len(design['expected_regular_files']) == 11 and len(design['expected_directories']) == 6 and design['expected_non_root_tree_entry_count'] == 17 and design['production_expected_uid_gid'] == '0:0' and design['regular_file_mode'] == '444' and design['directory_mode'] == '555')
check('separate strict CLI and no supplied boot/path override', design['cli_accepts_only_one_switch_and_help'] and not design['cli_accepts_boot_argument_or_path_override'] and design['library_only_mode_requires_sourcing'])
check('compatibility marker non-authenticating and drift stops for review', design['compatibility_marker_is_not_openpgp_signature'] and design['drift_stops_for_separate_review'] and design['no_historical_probe_rerun_or_immutable_source_edit'])
check('required implementation fixture acceptance retained', len(design['acceptance_cases_required_before_implementation_freeze']) == 10 and design['generic_tree_validator_accepts_explicit_fixture_bindings_for_later_tests'] and design['production_adapter_passes_frozen_paths_sha_and_uid0_gid0'])
check('no continuous preservation or transport overclaim', design['derivation_is_repository_design_not_transport_or_execution_evidence'] and design['observation_provenance_scope'] == 'point-in-time-guarded-observation-not-atomic-snapshot-or-continuous-preservation')
authorization = policy['authorization']
check('only repository implementation review is open', [k for k, v in authorization.items() if v] == ['repository_only_revalidation_probe_implementation_review_authorized'])
check('design freeze grant consumed; no new operational grant', previous['authorization']['repository_only_revalidation_design_freeze_authorized'] and not authorization['repository_only_revalidation_design_freeze_authorized'] and not authorization['new_probe_implementation_authorized'] and not authorization['new_probe_execution_authorized'] and not authorization['new_probe_transport_authorized'])
for key in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']:
    check('current reopened workstream state: ' + key, policy[key] is False)
check('implementation review next stage matches roadmap', policy['next_stage'] == previous['roadmap']['preferred_steps'][3]['stage'] == base.replace('design-freeze', 'probe-implementation-review'))
check('acceptance excludes production host entry and constants modification', policy['repository_acceptance_scope'] == dict(accepted_predecessor_full_repository_acceptance_required=True, production_main_entered=False, production_builder_entered=False, live_target_observation_performed=False, production_host_guards_entered=False, production_constants_modified=False, full_future_probe_installed=False, design_only_state_transition_verified=True))
helper_source = helper.read_text()
check('helper invokes only full accepted predecessor acceptance', re.findall(r'(?m)^if ! bash -- "\$repo_root/([^\"]+)"', helper_source) == ['tests/reference/test-' + prior + '-harness.sh'])
check('helper has no production command or transport', not re.search(r'(?m)^\s*(?:sudo|scp|sftp|ssh|slackpkg|upgradepkg|installpkg|removepkg|reboot|eval|source)\b', helper_source))
rows = [line.split('\t') for line in (fixture / (base + '.tsv')).read_text().splitlines()]
check('strict unique real-tab record', all(len(row) == 2 and all(row) for row in rows) and len(rows) == len(dict(rows)))
record = dict(rows)
check('record predecessor and state-only design identity', record['step'] == '291' and record['accepted_checkpoint_commit'] == '2571e24' and record['accepted_checkpoint_acceptance'] == accepted['acceptance_result'] and record['design_changed_keys'] == 'state' and record['expected_future_probe_sha256'] == design['expected_derivation_sha256'] and record['design_state'] == design['state'])
check('record current state unknown and no source/probe/runtime overclaim', record['current_boot_id'] == 'not-observed' and record['future_probe_installed'] == record['production_source_bytes_changed'] == record['prior_live_binding_reusable'] == record['runtime_attempt_authorized'] == 'no')
check('record permission and state consistency', all(record[k] == ('yes' if v else 'no') for k, v in authorization.items()) and all(record[k] == ('yes' if policy[k] else 'no') for k in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']) and record['next_stage'] == policy['next_stage'])
for argv in [['--help'], ['--bogus'], [], ['--output-dir'], ['--output-dir', '']]:
    result = run(['bash', '--', helper, *argv])
    check('strict helper CLI ' + repr(argv), result.returncode == (0 if argv == ['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step291-freeze-') as directory:
    tmp = Path(directory); planned_path = tmp / 'frozen-design-only-bash-syntax.sh'; planned_path.write_text(planned)
    check('frozen planned source Bash syntax without execution', run(['bash', '-n', planned_path]).returncode == 0)
    output = tmp / 'freeze output'; output.mkdir()
    result = run(['bash', '--', helper, '--output-dir', output])
    check('complete accepted199 predecessor actually reruns', result.returncode == 0 and 'accepted_step290_revalidated\tPASS (199 passes, 0 failures)' in result.stdout)
    for suffix in ['-policy.json', '.tsv', '-design.json']:
        check('exact freeze publication ' + suffix, (output / (base + suffix)).read_bytes() == (fixture / (base + suffix)).read_bytes())
    check('helper reports state-only freeze and no installed/live probe', 'design_changed_keys\tstate' in result.stdout and 'future_probe_installed\tno' in result.stdout and 'live_target_observation_performed\tno' in result.stdout)
    before = {p.name: p.read_bytes() for p in output.iterdir()}
    check('duplicate rejected without overwrite', run(['bash', '--', helper, '--output-dir', output]).returncode != 0 and {p.name: p.read_bytes() for p in output.iterdir()} == before)
    link = tmp / 'output-link'; link.symlink_to(output, target_is_directory=True)
    check('symlink output rejected', run(['bash', '--', helper, '--output-dir', link]).returncode != 0)
    nested = output / 'nested'; nested.mkdir()
    check('symlink ancestor rejected', run(['bash', '--', helper, '--output-dir', link / 'nested']).returncode != 0 and not list(nested.iterdir()))
    check('missing output directory rejected', run(['bash', '--', helper, '--output-dir', tmp / 'missing']).returncode != 0 and not (tmp / 'missing').exists())
    replica = tmp / 'replica'; shutil.copytree(root, replica, ignore=shutil.ignore_patterns('.git'))
    rejected = tmp / 'rejected'; rejected.mkdir(); replica_helper = replica / helper.relative_to(root)
    for rel in list(accepted['sha256_bindings']) + [k for k in own_hashes if k != helper.relative_to(root).as_posix()]:
        target = replica / rel; original_bytes = target.read_bytes(); target.write_bytes(original_bytes + b'\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed accepted or freeze input rejected: ' + target.name, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original_bytes)
    for section, key, value in [
        ('authorization', 'new_probe_execution_authorized', True),
        ('authorization', 'new_probe_transport_authorized', True),
        ('fresh_boundary', 'current_boot_id', 'bcfac4fa-4e6e-450a-aa95-bd591a979b4e'),
        ('design', 'production_expected_uid_gid', '1000:1000'),
        ('design', 'expected_derivation_sha256', '0' * 64),
        ('freeze_delta', 'source_bytes_changed', True),
    ]:
        target = replica / policy_path.relative_to(root); original_bytes = target.read_bytes(); bad = json.loads(original_bytes)
        bad[section][key] = value; target.write_text(json.dumps(bad) + '\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('permission, source or frozen-binding drift rejected: ' + key, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original_bytes)
check('future production probe remains absent after freeze acceptance', not (root / design['future_probe_path']).exists())
for rel in list(own_hashes) + ['tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace: ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
changelog = (root / 'CHANGELOG.md').read_text()
check('CHANGELOG confirms predecessor and frozen state', '## Phase 1 step 291 ' in changelog and '2571e24' in changelog and 'Step 288 remains the accepted historical strong-pause checkpoint' in changelog and '## Phase 1 step 290 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
