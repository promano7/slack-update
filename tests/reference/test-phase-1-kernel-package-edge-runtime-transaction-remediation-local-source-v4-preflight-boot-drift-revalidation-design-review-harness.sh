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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-review'
prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-resume-planning-boundary-review'
next_stage = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-review.md': '02e0a1c6fe58e5987ba3ae6081ee2fa3136df06aced7824b5e42acf68ca87ad3', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-review-policy.json': 'c5e40fc67655066a7f1d77aedb02c7793900d76576d8df3aafc5423a4f7825a1', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-review.tsv': 'a675447b492a50ecb1e7a1f3758b303cffe78496855756f2b10875e6e8d7e83f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-review-derivation.tsv': '84c26f6705740930e2325f16601d3e5a81dc27e74b95a2c4d1baeeb9b367ea47', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-review.sh': '7110256ef9e8707c538770e20b1c11399be3944424d2d24b2d4fd503e8e64580'}
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
    check('exact regular artifact: ' + path.name,
          path.is_file() and not path.is_symlink() and hashlib.sha256(path.read_bytes()).hexdigest() == digest)
for path in [helper, root / 'tests/reference' / ('test-' + base + '-harness.sh')]:
    check('Bash syntax: ' + path.name, run(['bash', '-n', path]).returncode == 0)
check('review identity and predecessor route', policy['schema'] == 1 and policy['step'] == 281 and policy['scenario'] == base and policy['review_status'] == 'PASS' and policy['review_only'] and previous['next_stage'] == base)
check('confirmed e24690d user checkpoint', accepted['step'] == 280 and accepted['commit'] == 'e24690d' and accepted['acceptance_result'] == 'PASS (165 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('returned prefix has complete-output provenance and no invented full SHA', accepted['commit_identity_scope'] == 'user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted and accepted['provenance'] == 'complete-user-returned-step280-application-acceptance-commit-push-clean-tree-2026-10-01')
for key in ['accepted_authorization_closure', 'accepted_failure_characterization', 'accepted_reviewed_effect_boundary', 'historical_observation', 'historical_returned_attempt', 'immutable_implementation', 'future_build_boundary', 'roadmap', 'strong_pause_completion_conditions']:
    check('exact accepted semantics preserved: ' + key, policy[key] == previous[key])
check('revalidation boundary remains historical future planning input', policy['future_revalidation_boundary'] == previous['revalidation_boundary'])
check('no current boot or target/output preservation claim', policy['current_boot_id'] is None and not policy['current_target_or_output_preservation_independently_observed'])
design = policy['design']
check('design reviewed without freeze implementation or authority', design['state'] == 'reviewed-not-frozen-not-implemented-not-authorized' and not design['reviewed_derivation_is_installed_implementation'] and not design['reviewed_derivation_production_execution_performed'])
check('exact immutable baseline SHA', design['baseline_path'] == previous['revalidation_boundary']['historical_probe_baseline_path'] and design['baseline_sha256'] == previous['revalidation_boundary']['historical_probe_baseline_sha256'] == '3bd3db28f483e9ff842a4f6899ace758acadfc96a92ee2fe55bb5a2fe36577a2')
check('future probe is separately named', design['future_probe_path'].startswith('tools/reference/') and design['future_probe_path'] != design['baseline_path'] and Path(design['future_probe_path']).name.endswith('-preflight-boot-drift-fresh-target-and-output-absence-revalidation-probe.sh'))
check('future exact switch and status identity', design['future_probe_switch'] == '--observe-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation' and design['future_status_field'] == 'v4_preflight_boot_drift_fresh_target_and_output_absence_revalidation_status')
source = (root / design['baseline_path']).read_text()
candidate = source
replacement_labels = ['new-probe-basename-in-help-only', 'new-single-observation-switch', 'new-observation-status-field', 'isolate-equivalent-canonical-uuid-validation', 'call-equivalent-canonical-uuid-validator', 'explicit-sourced-library-only-test-seam']
check('six ordered allowlisted replacement identities', [item['label'] for item in design['ordered_exact_replacements']] == replacement_labels)
for item in design['ordered_exact_replacements']:
    check('exact replacement occurrence count: ' + item['label'], candidate.count(item['before']) == item['occurrences'])
    candidate = candidate.replace(item['before'], item['after'])
check('exact reviewed in-memory derivation SHA', hashlib.sha256(candidate.encode()).hexdigest() == design['reviewed_derivation_sha256'] == 'fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b')
check('in-memory derivation has valid Bash syntax', subprocess.run(['bash', '-n'], input=candidate, text=True, capture_output=True).returncode == 0)
constants = [line for line in source.splitlines() if line.startswith('readonly ')]
check('all readonly constants preserved exactly', constants == design['preserved_readonly_constant_lines'] == [line for line in candidate.splitlines() if line.startswith('readonly ')])
check('no boot-binding constant or historical default', not design['new_historical_boot_constant_or_default_allowed'] and all('BOOT_ID' not in line for line in constants) and '79a19518-0d0a-4c57-ac1f-679a39edefbd' not in candidate and '0b85f61f-21e8-4593-b473-043cb6a2beb7' not in candidate)
check('exact nine guard functions required', set(design['preserved_guard_function_sha256']) == {'regular_sha256', 'package_records', 'package_database_manifest_hash', 'path_fingerprint', 'tree_fingerprint', 'tsv_value', 'verify_local_source_v3', 'verify_failed_v2_evidence', 'verify_v4_outputs_absent'})
for name, digest in design['preserved_guard_function_sha256'].items():
    check('unchanged guard body and SHA: ' + name, function_body(source, name) == function_body(candidate, name) and hashlib.sha256(function_body(source, name).encode()).hexdigest() == digest)
check('full applicable probe guard inventory unchanged', design['complete_existing_non_boot_target_and_output_guards_required'] and design['required_probe_guard_inventory'] == previous['revalidation_boundary']['required_probe_guard_inventory'])
check('current UUID still comes from actual boot read', candidate.count('boot_id=$(cat /proc/sys/kernel/random/boot_id)') == 1 and design['boot_uuid_source'].startswith('cat /proc/sys/kernel/random/boot_id'))
check('canonical UUID semantics without historical equality gate', design['uuid_format'] == 'canonical-lowercase-8-4-4-4-12-hex-uuid' and design['uuid_validator_is_pure_no_live_reads_or_writes'] and design['historical_uuid_may_be_equal_if_freshly_observed'] and design['no_uuid_equality_test_against_history'] and not design['historical_authority_or_error_uuid_substitution_allowed'])
validator = design['pure_validator_design_source']
check('pure UUID validator matches reviewed derivation', function_body(candidate, 'validate_fresh_boot_id') == validator and not re.search(r'\b(?:cat|sudo|source|eval|cp|mv|rm|touch|mkdir|readlink)\b', validator))
check('historical terminal fail function preserved', design['historical_fail_function_source'] == next(line for line in source.splitlines() if line.startswith('fail() {')) == next(line for line in candidate.splitlines() if line.startswith('fail() {')))
uuid_replay = design['historical_fail_function_source'] + '\n' + validator + '\nvalidate_fresh_boot_id "$@"\n'
for label, argv, expected in [
    ('new canonical UUID', ['01234567-89ab-cdef-0123-456789abcdef'], 0),
    ('fresh reading may equal historical authorization UUID', ['79a19518-0d0a-4c57-ac1f-679a39edefbd'], 0),
    ('fresh reading may equal historical error UUID', ['0b85f61f-21e8-4593-b473-043cb6a2beb7'], 0),
    ('empty input', [''], 1), ('missing input', [], 1),
    ('uppercase input', ['01234567-89AB-cdef-0123-456789abcdef'], 1),
    ('short input', ['01234567-89ab-cdef-0123-456789abcde'], 1),
    ('non-hex input', ['g1234567-89ab-cdef-0123-456789abcdef'], 1),
    ('whitespace suffix', ['01234567-89ab-cdef-0123-456789abcdef '], 1),
    ('extra argument', ['01234567-89ab-cdef-0123-456789abcdef', 'extra'], 1),
    ('literal shell text remains data', ['$(printf injected)'], 1),
]:
    result = run(['bash', '-c', uuid_replay, 'pure-design-replay', *argv])
    check('pure design replay: ' + label, result.returncode == expected and not result.stdout and result.stderr == ('' if expected == 0 else 'ERROR: fresh boot ID is not a canonical lowercase UUID\n'))
cli = design['cli']
check('exact observation CLI, help and no boot argument', cli['observation_argv'] == [design['future_probe_switch']] and cli['help_argv'] == [['--help'], ['-h']] and cli['missing_unknown_duplicate_or_extra_arguments_rejected'] and cli['old_observation_switch_rejected'] and not cli['boot_argument_accepted'] and cli['observation_requires_root'])
main = candidate[candidate.index('\nmain() {\n') + 1:candidate.index('\nif [[ ${SLACK_UPDATE_V4_BOOT_DRIFT_REVALIDATION_LIBRARY_ONLY:')]
check('reviewed main retains exact one-argument observation gate', '[[ $# -eq 1 && $1 == \'' + design['future_probe_switch'] + "' ]]" in main and "--observe-v4-launch-remediation-fresh-target-and-output-absence-revalidation" not in main)
check('reviewed main calls pure validator before remaining guards', main.count('    validate_fresh_boot_id "$boot_id"\n') == 1 and main.index('validate_fresh_boot_id') < main.index('    verify_local_source_v3\n'))
seam = design['library_only_seam']
check('explicit sourced-only library seam contract', seam['variable'] == 'SLACK_UPDATE_V4_BOOT_DRIFT_REVALIDATION_LIBRARY_ONLY' and seam['explicit_value'] == '1' and all(seam[k] for k in ['requires_sourcing', 'default_direct_execution_enters_main', 'sourced_library_mode_never_enters_main', 'direct_library_mode_rejected', 'tests_must_not_modify_frozen_production_constants', 'tests_must_not_call_host_bound_guards']))
check('reviewed library tail is exact last allowlisted replacement', candidate.endswith(design['ordered_exact_replacements'][-1]['after']) and '[[ ${BASH_SOURCE[0]} != "$0" ]]' in candidate)
publication = design['publication']
fields = re.findall(r"^    printf '([^'\\]+)\\t", main, re.M)
check('all41 ordered real-tab publication fields', publication['real_tab_tsv'] and publication['field_count'] == len(fields) == len(set(fields)) == 41 and publication['ordered_field_names'] == fields and fields[0] == design['future_status_field'])
original_publication = [line for line in source.splitlines() if line.startswith("    printf '")]
reviewed_publication = [line for line in main.splitlines() if line.startswith("    printf '")]
check('every observation value contract preserved except renamed status', reviewed_publication == [line.replace('v4_launch_remediation_fresh_target_and_output_absence_revalidation_status', design['future_status_field']) for line in original_publication])
status_index = main.index("    printf '" + design['future_status_field'])
check('all major guard calls precede PASS publication', publication['status_only_after_all_guard_success'] and all(main.index('    ' + name + '\n') < status_index for name in ['verify_local_source_v3', 'verify_failed_v2_evidence', 'verify_v4_outputs_absent']))
check('self SHA is actual probe identity and builder SHA is context', publication['probe_sha256_from_actual_executed_file'] and 'probe_sha=$(sha256sum -- "$probe_path"' in main and publication['builder_sha256_is_repository_context_not_transport_observation'])
check('complete return required; partial output is not success', publication['no_partial_observation_accepted_as_pass'] and publication['complete_stdout_stderr_and_exit_status_required'])
effects = design['effect_boundary']
check('future observation requires separate authorization', effects['live_observation_only_after_new_step285_authorization'])
check('no new transport execution write or cleanup effect', not any(effects[k] for k in ['builder_or_executor_transport_required_for_observation', 'builder_or_executor_entered', 'package_slackpkg_network_boot_reboot_configuration_or_cleanup_allowed', 'result_file_or_persistent_attempt_marker_added']))
check('future implementation acceptance covers exact code and isolated behavior', len(design['future_implementation_acceptance_required']) == 8 and 'explicit-sourced-library-mode-no-host-main-entry' in design['future_implementation_acceptance_required'] and 'no-production-constant-edit-host-guard-call-or-machine-write-in-tests' in design['future_implementation_acceptance_required'])
authorization = policy['authorization']
check('only repository design freeze permission is open', [k for k, v in authorization.items() if v] == ['repository_only_revalidation_design_freeze_authorized'])
check('all prior permissions remain closed', all(authorization[k] is False for k in previous['authorization']))
check('all planning machine/pause state remains false', all(policy[k] is False for k in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']))
check('next stage is unchanged planned step282', policy['next_stage'] == next_stage == previous['roadmap']['preferred_steps'][2]['stage'])
scope = policy['repository_acceptance_scope']
check('design-only acceptance scope', scope == {'full_accepted165_predecessor_suite_required': True, 'design_derivation_reconstructed_in_memory_only': True, 'pure_uuid_validator_design_replay_only': True, 'future_probe_installed_by_this_step': False, 'production_main_entered': False, 'production_builder_entered': False, 'live_target_observation_performed': False})
rows = [line.split('\t') for line in (fixture / (base + '.tsv')).read_text().splitlines()]
check('strict real-tab unique record', all(len(row) == 2 and all(row) for row in rows) and len(rows) == len(dict(rows)))
record = dict(rows)
check('record matches checkpoint and design identity', record['step'] == '281' and record['accepted_checkpoint_commit'] == 'e24690d' and record['design_state'] == design['state'] and record['reviewed_derivation_sha256'] == design['reviewed_derivation_sha256'] and record['current_boot_id'] == 'not-observed' and record['future_probe_switch'] == design['future_probe_switch'])
check('record authority and state matches policy', all(record[k] == ('yes' if v else 'no') for k, v in authorization.items()) and all(record[k] == 'no' for k in ['machine_action_required', 'controller_action_required', 'pause_safe', 'strong_safe_pause']) and record['next_stage'] == next_stage)
with (fixture / (base + '-derivation.tsv')).open(newline='') as handle:
    derivation_rows = list(csv.DictReader(handle, delimiter='\t'))
check('derivation TSV exact ordered labels and before/after hashes', derivation_rows == [dict(order=str(n), label=item['label'], occurrences=str(item['occurrences']), before_sha256=hashlib.sha256(item['before'].encode()).hexdigest(), after_sha256=hashlib.sha256(item['after'].encode()).hexdigest()) for n, item in enumerate(design['ordered_exact_replacements'], 1)])
helper_source = helper.read_text()
check('helper only invokes predecessor acceptance', re.findall(r'(?m)^if ! bash -- "\$repo_root/([^\"]+)"', helper_source) == ['tests/reference/test-' + prior + '-harness.sh'] and not re.search(r'(?m)^\s*(?:sudo|source|eval|ssh|scp|slackpkg|upgradepkg|reboot)\b', helper_source))
for argv in [['--help'], ['--bogus'], [], ['--output-dir'], ['--output-dir', '']]:
    check('strict helper CLI ' + repr(argv), run(['bash', '--', helper, *argv]).returncode == (0 if argv == ['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step281-repository-') as directory:
    tmp = Path(directory); output = tmp / 'review output'; output.mkdir()
    result = run(['bash', '--', helper, '--output-dir', output])
    check('full165 predecessor suite actually reruns', result.returncode == 0 and 'accepted_step280_revalidated\tPASS (165 passes, 0 failures)' in result.stdout)
    for suffix in ['-policy.json', '.tsv', '-derivation.tsv']:
        check('exact design review output ' + suffix, (output / (base + suffix)).read_bytes() == (fixture / (base + suffix)).read_bytes())
    check('helper reports no implementation or live observation', 'future_probe_implemented\tno' in result.stdout and 'live_target_observation_performed\tno' in result.stdout and 'all_prior_operational_authority_revoked\tyes' in result.stdout)
    before = {p.name: p.read_bytes() for p in output.iterdir()}
    check('duplicate outputs rejected unchanged', run(['bash', '--', helper, '--output-dir', output]).returncode != 0 and {p.name: p.read_bytes() for p in output.iterdir()} == before)
    link = tmp / 'output-link'; link.symlink_to(output, target_is_directory=True)
    check('symlink output rejected', run(['bash', '--', helper, '--output-dir', link]).returncode != 0)
    nested = output / 'nested'; nested.mkdir()
    check('symlink output ancestor rejected', run(['bash', '--', helper, '--output-dir', link / 'nested']).returncode != 0 and not list(nested.iterdir()))
    check('missing output rejected without creation', run(['bash', '--', helper, '--output-dir', tmp / 'missing']).returncode != 0 and not (tmp / 'missing').exists())
    replica = tmp / 'replica'; shutil.copytree(root, replica, ignore=shutil.ignore_patterns('.git'))
    rejected = tmp / 'rejected'; rejected.mkdir()
    replica_helper = replica / 'tools/reference' / (base + '.sh')
    for rel in list(accepted['sha256_bindings']) + [k for k in own_hashes if k != f'tools/reference/{base}.sh']:
        target = replica / rel; original = target.read_bytes(); target.write_bytes(original + b'\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed input rejects before publication: ' + target.name, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
    target = replica / design['baseline_path']; original = target.read_bytes(); target.unlink(); target.symlink_to(root / design['baseline_path'])
    result = run(['bash', '--', replica_helper, '--output-dir', rejected])
    check('same-content symlink baseline rejected', result.returncode != 0 and not list(rejected.iterdir()))
    target.unlink(); target.write_bytes(original)
    for section, key, value in [
        ('authorization', 'new_probe_execution_authorized', True),
        ('authorization', 'new_probe_implementation_authorized', True),
        ('design', 'new_historical_boot_constant_or_default_allowed', True),
        ('design', 'reviewed_derivation_is_installed_implementation', True),
    ]:
        target = replica / policy_path.relative_to(root); original = target.read_bytes(); bad = json.loads(original); bad[section][key] = value; target.write_text(json.dumps(bad) + '\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed permission or design overclaim rejected: ' + key, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
for rel in list(own_hashes) + ['tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace: ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
changelog = (root / 'CHANGELOG.md').read_text()
check('CHANGELOG records accepted280 and reviewed-only281 boundary', '## Phase 1 step 281 ' in changelog and 'e24690d' in changelog and 'without installing or invoking a production probe' in changelog and '## Phase 1 step 280 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
