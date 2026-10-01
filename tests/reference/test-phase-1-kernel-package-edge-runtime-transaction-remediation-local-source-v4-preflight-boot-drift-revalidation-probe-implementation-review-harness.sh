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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review'
prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze'
next_stage = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review.md': 'c5a5a6c33ce361cbb1405911359d242be114e2e397936c727a072277dc01918f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review-policy.json': 'babfb8e7acf5cd11f75e4dc566757fad69deda53f0aca2a51547c6b1fd1ae039', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review.tsv': '7b902e4068e37d52b0014ca866308a4d9c0b7b10799ecd7d906151f561c7d76d', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review-implementation.tsv': 'd82f24218ebf448af92a23dab4fe68a2bcf830d3b457e140c43ac56115a66a48', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-probe.sh': 'fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-review.sh': '70401fa4fbfb276971797837e47986367cecc9a9bfa45ea2450f517af84c5762'}
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

def function_body(text, name):
    start = text.index('\n' + name + '() {') + 1
    first_end = text.index('\n', start)
    if text[start:first_end].endswith(' }'):
        return text[start:first_end] + '\n'
    return text[start:text.index('\n}\n', start) + 3]

accepted = policy['accepted_checkpoint']
for rel, digest in (accepted['sha256_bindings'] | own_hashes).items():
    path = root / rel
    check('exact regular artifact: ' + path.name, path.is_file() and not path.is_symlink() and hashlib.sha256(path.read_bytes()).hexdigest() == digest)
implementation = policy['implementation']
design = policy['design']
probe = root / implementation['probe_path']
for path in [helper, probe, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax: ' + path.name, run(['bash', '-n', path]).returncode == 0)
check('implementation stage identity and prior next stage', policy['schema'] == 1 and policy['step'] == 283 and policy['scenario'] == base and policy['review_status'] == 'PASS' and policy['review_only'] and previous['next_stage'] == base)
check('confirmed b60caa2 full110 accepted checkpoint', accepted['step'] == 282 and accepted['commit'] == 'b60caa2' and accepted['acceptance_result'] == 'PASS (110 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('complete-output prefix provenance without full object invention', accepted['commit_identity_scope'] == 'user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted and accepted['provenance'] == 'complete-user-returned-step282-application-acceptance-commit-push-clean-tree-2026-10-01')
check('frozen design preserved as historical checkpoint', design == previous['design'] and implementation['frozen_design_is_historical_checkpoint_not_current_implementation_state'])
check('implementation permission was explicitly open at accepted freeze', previous['authorization']['new_probe_implementation_authorized'] and previous['authorization']['repository_only_revalidation_probe_implementation_review_authorized'])
check('actual repository implementation path and expected SHA exact', implementation['probe_path'] == design['future_probe_path'] and implementation['probe_sha256'] == design['reviewed_derivation_sha256'] == 'fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b')
check('reviewed implementation not production-observed', implementation['state'] == 'implementation-reviewed-not-production-observed' and implementation['exact_frozen_derivation_applied'])
source = probe.read_text()
baseline = (root / design['baseline_path']).read_text()
derived = baseline
for item in design['ordered_exact_replacements']:
    check('frozen replacement occurrence count: ' + item['label'], derived.count(item['before']) == item['occurrences'])
    derived = derived.replace(item['before'], item['after'])
check('actual source equals exact frozen ordered derivation', source == derived and hashlib.sha256(source.encode()).hexdigest() == implementation['probe_sha256'])
check('all readonly constants unchanged', [line for line in source.splitlines() if line.startswith('readonly ')] == design['preserved_readonly_constant_lines'] == [line for line in baseline.splitlines() if line.startswith('readonly ')])
for name, digest in design['preserved_guard_function_sha256'].items():
    check('exact unchanged guard body: ' + name, function_body(source, name) == function_body(baseline, name) and hashlib.sha256(function_body(source, name).encode()).hexdigest() == digest)
check('pure validator exact frozen source', function_body(source, 'validate_fresh_boot_id') == design['pure_validator_design_source'])
check('boot read remains fresh with no supplied boot or historical default', source.count('boot_id=$(cat /proc/sys/kernel/random/boot_id)') == 1 and '--authorization-boot-id' not in source and '79a19518-0d0a-4c57-ac1f-679a39edefbd' not in source and '0b85f61f-21e8-4593-b473-043cb6a2beb7' not in source)
for key in ['production_main_entered', 'live_target_observation_performed', 'host_bound_guard_functions_called_in_repository_tests', 'production_builder_entered', 'production_constants_modified_for_tests']:
    check('implementation acceptance effect remains closed: ' + key, implementation[key] is False)
check('only actual synthetic callable functions are selected', implementation['synthetic_callable_functions'] == ['validate_fresh_boot_id', 'regular_sha256'])
marker = implementation['library_only_variable']
check('actual exact library-only tail and sourcing contract', marker == design['library_only_seam']['variable'] == 'SLACK_UPDATE_V4_BOOT_DRIFT_REVALIDATION_LIBRARY_ONLY' and source.endswith(design['ordered_exact_replacements'][-1]['after']) and implementation['library_mode_requires_sourcing'] and implementation['direct_library_mode_rejected_before_main'] and implementation['normal_direct_main_dispatch_preserved_not_entered_in_acceptance'])
library_prefix = marker + '=1 source -- "$1"; '
loaded = run(['bash', '-c', library_prefix + 'printf "synthetic_library_loaded\n"', 'actual-library-test', probe])
check('actual library loads without main or output', loaded.returncode == 0 and loaded.stdout == 'synthetic_library_loaded\n' and not loaded.stderr)
direct = run(['env', marker + '=1', 'bash', '--', probe, design['future_probe_switch']])
check('actual direct library-mode execution rejects before main', direct.returncode == 2 and not direct.stdout and direct.stderr == 'ERROR: library-only mode requires sourcing\n')

for label, argv, expected in [
    ('canonical new UUID', ['01234567-89ab-cdef-0123-456789abcdef'], 0),
    ('inert historical authorization UUID', ['79a19518-0d0a-4c57-ac1f-679a39edefbd'], 0),
    ('inert historical error UUID', ['0b85f61f-21e8-4593-b473-043cb6a2beb7'], 0),
    ('missing argument', [], 1), ('empty argument', [''], 1),
    ('uppercase UUID', ['01234567-89AB-cdef-0123-456789abcdef'], 1),
    ('short UUID', ['01234567-89ab-cdef-0123-456789abcde'], 1),
    ('non-hex UUID', ['g1234567-89ab-cdef-0123-456789abcdef'], 1),
    ('whitespace suffix', ['01234567-89ab-cdef-0123-456789abcdef '], 1),
    ('extra argument', ['01234567-89ab-cdef-0123-456789abcdef', 'extra'], 1),
    ('literal shell data', ['$(printf injected)'], 1),
]:
    result = run(['bash', '-c', library_prefix + 'shift; validate_fresh_boot_id "$@"', 'actual-uuid-test', probe, *argv])
    check('actual implemented UUID validator: ' + label, result.returncode == expected and not result.stdout and result.stderr == ('' if expected == 0 else 'ERROR: fresh boot ID is not a canonical lowercase UUID\n'))

main_start = source.index('\nmain() {\n') + 1
root_guard = source.index('    [[ ${EUID:-$(id -u)} -eq 0 ]]', main_start)
cli_prefix = source[main_start:root_guard]
check('isolated CLI prefix exact SHA and source', cli_prefix == implementation['synthetic_cli_prefix_source'] and hashlib.sha256(cli_prefix.encode()).hexdigest() == implementation['synthetic_cli_prefix_sha256'])
check('CLI prefix ends before root and all live reads', implementation['synthetic_cli_prefix_stops_before_root_and_all_live_reads'] and implementation['synthetic_cli_sentinel_is_not_observation_pass'] and not re.search(r'\b(?:hostname|uname|cat|find|stat|regular_sha256|verify_local_source_v3|verify_failed_v2_evidence|verify_v4_outputs_absent)\b', cli_prefix))
# Replay only the exact parser prefix in a new synthetic function; main is untouched.
cli_replay = library_prefix + 'shift; synthetic_cli_prefix() {\n' + cli_prefix.removeprefix('main() {\n') + '    printf "synthetic_cli_valid\n"\n}\nsynthetic_cli_prefix "$@"\n'
for label, argv, expected, kind in [
    ('one new observation argument', [design['future_probe_switch']], 0, 'sentinel'),
    ('long help', ['--help'], 0, 'help'), ('short help', ['-h'], 0, 'help'),
    ('missing argument', [], 2, 'reject'), ('unknown argument', ['--bogus'], 2, 'reject'),
    ('old observation switch', ['--observe-v4-launch-remediation-fresh-target-and-output-absence-revalidation'], 2, 'reject'),
    ('duplicate observation argument', [design['future_probe_switch']] * 2, 2, 'reject'),
    ('extra argument', [design['future_probe_switch'], 'extra'], 2, 'reject'),
    ('supplied boot UUID', [design['future_probe_switch'], '--authorization-boot-id', '01234567-89ab-cdef-0123-456789abcdef'], 2, 'reject'),
    ('help with extra data', ['--help', 'extra'], 2, 'reject'),
]:
    result = run(['bash', '-c', cli_replay, 'isolated-cli-test', probe, *argv])
    valid = result.returncode == expected and '\tPASS' not in result.stdout
    if kind == 'sentinel':
        valid = valid and result.stdout == 'synthetic_cli_valid\n' and not result.stderr
    elif kind == 'help':
        valid = valid and 'Usage: ' in result.stdout and design['future_probe_switch'] in result.stdout and 'synthetic_cli_valid' not in result.stdout and not result.stderr
    else:
        valid = valid and not result.stdout and 'Usage: ' in result.stderr and 'synthetic_cli_valid' not in result.stderr
    check('exact isolated actual CLI prefix: ' + label, valid)
main = source[main_start:source.index('\nif [[ ${SLACK_UPDATE_V4_BOOT_DRIFT_REVALIDATION_LIBRARY_ONLY:')]
fields = re.findall(r"^    printf '([^'\\]+)\\t", main, re.M)
check('exact41 publication fields in actual implemented main', fields == design['publication']['ordered_field_names'] and len(fields) == 41)
status_index = main.index("    printf '" + design['future_status_field'])
check('all major guards before actual PASS publication', all(main.index('    ' + name + '\n') < status_index for name in ['verify_local_source_v3', 'verify_failed_v2_evidence', 'verify_v4_outputs_absent']))
check('actual prefix retains canonical UUID validation before target/output guards', main.index('    validate_fresh_boot_id "$boot_id"\n') < main.index('    verify_local_source_v3\n'))

for key in ['immutable_implementation', 'accepted_authorization_closure', 'historical_observation', 'historical_returned_attempt', 'future_build_boundary', 'roadmap', 'strong_pause_completion_conditions']:
    check('exact historical preservation and future contract: ' + key, policy[key] == previous[key])
check('accepted freeze contract remains unchanged', policy['accepted_freeze_contract'] == previous['freeze_contract'])
check('no current boot or target/output preservation claim', policy['current_boot_id'] is None and not policy['current_target_or_output_preservation_independently_observed'])
authorization = policy['authorization']
check('only repository implementation freeze is open', [key for key, value in authorization.items() if value] == ['repository_only_revalidation_probe_implementation_freeze_authorized'])
check('repository implementation/review permission consumed', not authorization['new_probe_implementation_authorized'] and not authorization['repository_only_revalidation_probe_implementation_review_authorized'])
check('no machine/controller action or new pause', all(policy[key] is False for key in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']))
check('next stage matches planned step284', policy['next_stage'] == next_stage == previous['roadmap']['preferred_steps'][4]['stage'])
check('full non-production actual-function acceptance scope', policy['repository_acceptance_scope'] == {'full_accepted110_predecessor_suite_required': True, 'actual_probe_sourced_with_explicit_library_only_mode': True, 'actual_pure_uuid_and_regular_sha256_functions_on_synthetic_inputs': True, 'exact_main_cli_prefix_replayed_in_separate_synthetic_function': True, 'actual_direct_library_only_rejection_checked': True, 'production_main_entered': False, 'live_target_observation_performed': False, 'host_bound_guards_called': False, 'production_builder_entered': False, 'production_constants_modified': False})
rows = [line.split('\t') for line in (fixture / (base + '.tsv')).read_text().splitlines()]
check('strict real-tab unique record', all(len(row) == 2 and all(row) for row in rows) and len(rows) == len(dict(rows)))
record = dict(rows)
check('record actual implementation identity and accepted checkpoint', record['step'] == '283' and record['accepted_checkpoint_commit'] == 'b60caa2' and record['implementation_state'] == implementation['state'] and record['probe_path'] == implementation['probe_path'] and record['probe_sha256'] == implementation['probe_sha256'] and record['current_boot_id'] == 'not-observed')
check('record permissions and effects consistent', all(record[key] == ('yes' if value else 'no') for key, value in authorization.items()) and all(record[key] == 'no' for key in ['production_main_entered', 'live_target_observation_performed', 'production_constants_modified_for_tests', 'host_bound_guards_called', 'machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']) and record['next_stage'] == next_stage)
with (fixture / (base + '-implementation.tsv')).open(newline='') as handle:
    inventory = list(csv.DictReader(handle, delimiter='\t'))
check('implementation TSV distinguishes installed probe from historical input', inventory == [{'role': 'implemented-probe', 'path': implementation['probe_path'], 'sha256': implementation['probe_sha256'], 'state': implementation['state']}, {'role': 'historical-baseline', 'path': design['baseline_path'], 'sha256': design['baseline_sha256'], 'state': 'immutable-preserve'}])
helper_source = helper.read_text()
check('helper never invokes production probe or transport', re.findall(r'(?m)^if ! bash -- "\$repo_root/([^\"]+)"', helper_source) == ['tests/reference/test-' + prior + '-harness.sh'] and not re.search(r'(?m)^\s*(?:sudo|source|eval|ssh|scp|slackpkg|upgradepkg|reboot)\b', helper_source))
for argv in [['--help'], ['--bogus'], [], ['--output-dir'], ['--output-dir', '']]:
    check('strict helper CLI ' + repr(argv), run(['bash', '--', helper, *argv]).returncode == (0 if argv == ['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step283-repository-') as directory:
    tmp = Path(directory)
    synthetic = tmp / 'synthetic file with spaces'; synthetic.write_bytes(b'synthetic content\n'); synthetic.chmod(0o644)
    expected = hashlib.sha256(synthetic.read_bytes()).hexdigest()
    hash_replay = library_prefix + 'regular_sha256 "$2"'
    result = run(['bash', '-c', hash_replay, 'actual-sha-test', probe, synthetic])
    check('actual regular SHA accepts spaced mode0644 synthetic path', result.returncode == 0 and result.stdout.strip() == expected and not result.stderr)
    bound_hash_replay = library_prefix + 'actual=$(regular_sha256 "$2"); [[ $actual == "$3" ]] || fail "synthetic expected SHA mismatch"; printf "synthetic_hash_bound\n"'
    result = run(['bash', '-c', bound_hash_replay, 'synthetic-hash-bound-test', probe, synthetic, expected])
    check('actual hash matches inert expected digest', result.returncode == 0 and result.stdout == 'synthetic_hash_bound\n' and not result.stderr)
    synthetic.write_bytes(b'changed synthetic content\n')
    result = run(['bash', '-c', hash_replay, 'actual-sha-test', probe, synthetic])
    check('actual SHA detects changed synthetic content', result.returncode == 0 and result.stdout.strip() == hashlib.sha256(synthetic.read_bytes()).hexdigest() != expected and not result.stderr)
    result = run(['bash', '-c', bound_hash_replay, 'synthetic-hash-bound-test', probe, synthetic, expected])
    check('changed actual SHA rejects inert expected binding before sentinel', result.returncode == 1 and not result.stdout and result.stderr == 'ERROR: synthetic expected SHA mismatch\n')
    symlink = tmp / 'file-link'; symlink.symlink_to(synthetic)
    broken = tmp / 'broken-link'; broken.symlink_to(tmp / 'missing')
    for label, path in [('missing', tmp / 'missing'), ('symlink', symlink), ('broken symlink', broken), ('directory', tmp)]:
        result = run(['bash', '-c', hash_replay, 'actual-sha-test', probe, path])
        check('actual regular SHA rejects ' + label, result.returncode == 1 and not result.stdout and 'required regular non-symlink file missing:' in result.stderr)
    output = tmp / 'review output'; output.mkdir()
    result = run(['bash', '--', helper, '--output-dir', output])
    check('full110 accepted freeze suite actually reruns', result.returncode == 0 and 'accepted_step282_revalidated\tPASS (110 passes, 0 failures)' in result.stdout)
    for suffix in ['-policy.json', '.tsv', '-implementation.tsv']:
        check('exact implementation review output ' + suffix, (output / (base + suffix)).read_bytes() == (fixture / (base + suffix)).read_bytes())
    check('helper publishes implementation SHA and no live entry', 'implemented_probe_sha256\t' + implementation['probe_sha256'] in result.stdout and 'production_main_entered\tno' in result.stdout and 'live_target_observation_performed\tno' in result.stdout)
    before = {path.name: path.read_bytes() for path in output.iterdir()}
    check('duplicate publication rejects unchanged', run(['bash', '--', helper, '--output-dir', output]).returncode != 0 and {path.name: path.read_bytes() for path in output.iterdir()} == before)
    output_link = tmp / 'output-link'; output_link.symlink_to(output, target_is_directory=True)
    check('symlink output rejected', run(['bash', '--', helper, '--output-dir', output_link]).returncode != 0)
    nested = output / 'nested'; nested.mkdir()
    check('symlink output ancestor rejected', run(['bash', '--', helper, '--output-dir', output_link / 'nested']).returncode != 0 and not list(nested.iterdir()))
    check('missing output rejected without creation', run(['bash', '--', helper, '--output-dir', tmp / 'missing-output']).returncode != 0 and not (tmp / 'missing-output').exists())
    replica = tmp / 'replica'; shutil.copytree(root, replica, ignore=shutil.ignore_patterns('.git'))
    rejected = tmp / 'rejected'; rejected.mkdir()
    replica_helper = replica / 'tools/reference' / (base + '.sh')
    for rel in list(accepted['sha256_bindings']) + [key for key in own_hashes if key != f'tools/reference/{base}.sh']:
        target = replica / rel; original = target.read_bytes(); target.write_bytes(original + b'\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed input rejects before implementation publication: ' + target.name, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
    target = replica / implementation['probe_path']; original = target.read_bytes(); target.unlink(); target.symlink_to(probe)
    result = run(['bash', '--', replica_helper, '--output-dir', rejected])
    check('same-content symlink implemented probe rejected', result.returncode != 0 and not list(rejected.iterdir()))
    target.unlink(); target.write_bytes(original)
    for section, key, value in [
        ('authorization', 'new_probe_execution_authorized', True),
        ('implementation', 'production_main_entered', True),
        ('implementation', 'production_constants_modified_for_tests', True),
    ]:
        target = replica / policy_path.relative_to(root); original = target.read_bytes(); bad = json.loads(original); bad[section][key] = value; target.write_text(json.dumps(bad) + '\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed permission or implementation claim rejected: ' + key, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
for rel in list(own_hashes) + ['tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace: ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
changelog = (root / 'CHANGELOG.md').read_text()
check('CHANGELOG records accepted282 and actual synthetic283 boundary', '## Phase 1 step 283 ' in changelog and 'b60caa2' in changelog and 'production main and host-bound guards were never called' in changelog and '## Phase 1 step 282 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
