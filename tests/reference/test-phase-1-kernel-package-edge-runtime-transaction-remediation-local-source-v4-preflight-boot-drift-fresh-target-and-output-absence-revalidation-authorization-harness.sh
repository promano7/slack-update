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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization'
prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-probe-implementation-freeze'
next_stage = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization.md': '71d6b948bca89191b62ec92fca718cd003df05b8833714522850404ead4e7953', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization-policy.json': '469e3829e8164465d4b8c7083bb41e51b31476df02e937dcaec28d826aeadb41', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization.tsv': 'a0511fe1fafaff99d3e9de314dd2bcb0d8ee3f469f58fb596be1e318a88c5d5f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization-authorization.tsv': 'f674702d144474695ff8afc13126556fc9da694b6495c09d177b7a4feb68f54d', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization.sh': '0623c6f09a8c6dd8eba9e4cdeaac164e628aeb0a93b47e4b09d85e6b9241ba39'}
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
check('authorization identity follows accepted implementation freeze', policy['schema'] == 1 and policy['step'] == 285 and policy['scenario'] == base and policy['review_only'] and policy['review_status'] == 'PASS' and previous['next_stage'] == base)
check('confirmed48028a3 full129 user checkpoint', accepted['step'] == 284 and accepted['commit'] == '48028a3' and accepted['acceptance_result'] == 'PASS (129 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('complete-output prefix provenance without full object invention', accepted['commit_identity_scope'] == 'user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted and accepted['provenance'] == 'complete-user-returned-step284-application-acceptance-commit-push-clean-tree-2026-10-01')
for key in ['design','implementation','accepted_freeze_contract','immutable_implementation','accepted_authorization_closure','historical_observation','historical_returned_attempt','future_build_boundary','roadmap','strong_pause_completion_conditions']:
    check('exact accepted source/history/boundary preservation: '+key, policy[key] == previous[key])
check('accepted implementation freeze contract preserved', policy['accepted_implementation_freeze_contract'] == previous['freeze_contract'])
design = policy['design']; implementation = policy['implementation']
observation = policy['observation_authorization']; contract = policy['observation_return_contract']
check('whole implementation remains frozen and not production observed', implementation['state'] == 'implementation-frozen-not-production-observed' and not implementation['production_main_entered'] and not implementation['live_target_observation_performed'])
probe = root / implementation['probe_path']
check('actual frozen probe bytes exactly preserved', probe.is_file() and not probe.is_symlink() and hashlib.sha256(probe.read_bytes()).hexdigest() == implementation['probe_sha256'] == observation['probe_sha256'] == design['reviewed_derivation_sha256'])
check('one new authority tied to correct probe and exact CLI', observation['authority_id'] == 'phase-1-step285-fresh-boot-drift-read-only-observation' and observation['probe_path'] == implementation['probe_path'] and [observation['probe_switch']] == design['cli']['observation_argv'])
check('target identities remain frozen expected baseline', (observation['target_fqdn'],observation['target_architecture'],observation['expected_running_kernel'],observation['expected_slackware_version']) == ('vbox-slackcurrent.vbox-slackcurrent.org','x86_64','6.18.45','Slackware 15.0+'))
check('authorization pending actual user acceptance and observation', observation['state'] == 'authorized-pending-user-repository-acceptance-and-single-read-only-observation' and observation['authorization_effective_only_after_user_application_acceptance_commit_push_clean_tree'] and observation['accepted_implementation_freeze_required'])
check('exactly one invocation and no persistent enforcement claim', type(observation['invocation_limit']) is int and observation['invocation_limit'] == 1 and not observation['persistent_attempt_marker_added'] and observation['single_use_enforcement'] == 'controller-one-invocation-protocol-no-automatic-or-manual-retry')
for key in ['authority_consumed_on_invocation_even_on_failure','no_retry_after_success_or_failure','transport_only_frozen_probe','regular_non_symlink_copy_required','sha256_verified_on_arch_and_vm_before_invocation','complete_stdout_stderr_and_exit_status_required','no_probe_created_evidence_files','failure_or_incomplete_return_requires_stop_and_review','successful_observation_does_not_authorize_build','returned_observation_freeze_required_before_new_build_authorization','uninterrupted_vm_boot_required_between_observation_and_future_authorized_attempt','immediate_immutable_executor_preflight_required_for_future_attempt']:
    check('single observation invariant: '+key, observation[key] is True)
for key in ['surrounding_builder_or_executor_copy_required','chmod_required','production_library_only_opt_in_allowed','boot_id_argument_accepted','historical_uuid_substitution_allowed','historical_uuid_equality_alone_authorizes_or_disqualifies','machine_result_observed','authority_consumed_observed']:
    check('no unsupported machine action or evidence claim: '+key, observation[key] is False)
check('actual boot source, no known current boot or target state', observation['fresh_boot_id_source'] == '/proc/sys/kernel/random/boot_id' and observation['fresh_boot_id'] is None and policy['current_boot_id'] is None and not policy['current_target_or_output_preservation_independently_observed'])
check('expected return is not fabricated live evidence', contract['state'] == 'expected-return-contract-not-observed-evidence' and policy['evidence_scope'] == 'repository-authorization-reviewed-live-observation-pending')
check('exact ordered41 real-tab return contract preserved', contract['ordered_field_names'] == design['publication']['ordered_field_names'] and contract['field_count'] == len(contract['ordered_field_names']) == 41 and contract['real_tab_tsv'] and contract['no_duplicate_or_missing_fields'] and contract['no_partial_return_accepted_as_pass'])
check('new status and exact observed probe identity required', contract['required_status_field'] == contract['ordered_field_names'][0] == 'v4_preflight_boot_drift_fresh_target_and_output_absence_revalidation_status' and contract['required_status_value'] == 'PASS' and contract['required_probe_sha256'] == observation['probe_sha256'] and contract['fresh_boot_id_canonical_lowercase_uuid_required'])
check('fourteen positive preservation/absence fields required', len(contract['required_yes_fields']) == 14 and len(set(contract['required_yes_fields'])) == 14 and set(contract['required_yes_fields']) <= set(contract['ordered_field_names']))
check('ten no-effect/no-reuse fields required', len(contract['required_no_fields']) == 10 and len(set(contract['required_no_fields'])) == 10 and set(contract['required_no_fields']) <= set(contract['ordered_field_names']) and 'prior_runtime_binding_reused' in contract['required_no_fields'])
check('all other expectations preserved and builder identity contextual', contract['all_other_frozen_expectations_preserved'] and contract['frozen_builder_sha256_is_repository_context_not_transported_builder_observation'])
authorization = policy['authorization']
allowed = {'new_probe_transport_authorized','new_probe_execution_authorized','read_only_probe_transport_authorized','read_only_probe_execution_authorized','target_observation_authorized'}
check('only one new read-only probe handling scope open', {key for key,value in authorization.items() if value} == allowed)
check('previous repository authorization-review preparation permission consumed', not authorization['repository_only_fresh_revalidation_authorization_review_authorized'])
check('all builder/executor/build and other authority stays closed', all(value is False for key,value in authorization.items() if key not in allowed))
check('pending observation requires machine/controller action, no strong pause', policy['machine_action_required'] is True and policy['controller_action_required'] is True and policy['pause_safe'] is False and policy['strong_safe_pause'] is False)
check('successful return routes to planned286 with separate build review', policy['next_stage'] == observation['success_route'] == next_stage == previous['roadmap']['preferred_steps'][6]['stage'])
check('failure/incomplete route distinct and requires review', policy['failure_route'] == observation['failure_route'] == base.rsplit('-fresh-target-and-output-absence-revalidation-authorization',1)[0]+'-revalidation-failure-review' and policy['failure_route'] != next_stage)
check('repository acceptance does not enter production or infer machine state', policy['repository_acceptance_scope'] == {'full_accepted129_predecessor_suite_required':True,'all_step283_synthetic_implementation_cases_repeated_transitively':True,'production_main_entered':False,'production_builder_entered':False,'host_bound_guards_called':False,'live_target_observation_performed':False,'production_constants_modified':False,'new_probe_installed_or_modified':False})
inventory = policy['authorization_identity_inventory']
check('four distinct actual source inventory roles', [row['role'] for row in inventory] == ['authorized-read-only-probe','historical-probe-baseline','immutable-builder','immutable-executor'])
check('only new probe inventory opens single conditional invocation', inventory[0] == {'role':'authorized-read-only-probe','path':observation['probe_path'],'sha256':observation['probe_sha256'],'scope':'one-copy-one-invocation-after-user-repository-acceptance'})
for row in inventory:
    check('inventory exact bound source: '+row['role'], accepted['sha256_bindings'][row['path']] == row['sha256'])
with (fixture/(base+'-authorization.tsv')).open(newline='') as handle:
    inventory_rows = list(csv.DictReader(handle,delimiter='\t'))
check('authorization TSV exactly matches source inventory', inventory_rows == inventory)
rows = [line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines()]
check('strict unique real-tab authorization record', all(len(row)==2 and all(row) for row in rows) and len(rows)==len(dict(rows)))
record = dict(rows)
check('record accepted checkpoint and unchanged implementation state exact', record['step']=='285' and record['accepted_checkpoint_step']=='284' and record['accepted_checkpoint_commit']=='48028a3' and record['accepted_checkpoint_acceptance']==accepted['acceptance_result'] and record['implementation_state']==implementation['state'] and record['probe_sha256']==implementation['probe_sha256'])
check('record conditional invocation limit and consumed-on-attempt contract', record['observation_authorization_state']==observation['state'] and record['observation_invocation_limit']=='1' and record['authority_effective_after_user_repository_acceptance']=='yes' and record['authority_consumed_on_invocation_even_on_failure']=='yes')
check('record has no actual boot/target claim', record['machine_result_observed']=='no' and record['current_boot_id']=='not-observed' and record['current_target_or_output_preservation_independently_observed']=='no' and record['all_prior_operational_authority_revoked']=='yes')
check('record permissions/state/routes consistent', all(record[key]==('yes' if value else 'no') for key,value in authorization.items()) and all(record[key]==('yes' if policy[key] else 'no') for key in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']) and record['failure_route']==policy['failure_route'] and record['next_stage']==next_stage)
doc = (root/'docs/reference'/(base+'.md')).read_text()
commands = re.findall(r'```bash\n(.*?)```',doc,re.S)
check('one reviewable production command snippet, not executed', len(commands)==1 and run(['bash','-n','-c',commands[0]]).returncode==0)
check('snippet gates one sudo Bash invocation with SHA and prints exit', commands[0].count('sudo bash --')==1 and observation['probe_switch'] in commands[0] and observation['probe_sha256'] in commands[0] and 'sha256sum -c - &&' in commands[0] and 'observation_exit_status=$?' in commands[0] and 'printf' in commands[0])
check('snippet has regular non-symlink guard and no supplied UUID', '[[ -f "$PROBE" && ! -L "$PROBE" ]]' in commands[0] and '--authorization-boot-id' not in commands[0] and 'SLACK_UPDATE_' not in commands[0])
source = helper.read_text()
check('helper only invokes accepted predecessor suite', re.findall(r'(?m)^if ! bash -- "\$repo_root/([^\"]+)"', source) == ['tests/reference/test-' + prior + '-harness.sh'] and not re.search(r'(?m)^\s*(?:sudo|source|eval|ssh|scp|slackpkg|upgradepkg|reboot)\b', source))
for argv in [['--help'], ['--bogus'], [], ['--output-dir'], ['--output-dir', '']]:
    check('strict helper CLI ' + repr(argv), run(['bash', '--', helper, *argv]).returncode == (0 if argv == ['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step285-repository-') as directory:
    tmp = Path(directory); output = tmp / 'freeze output'; output.mkdir()
    result = run(['bash', '--', helper, '--output-dir', output])
    check('full129 freeze suite actually reruns with transitive synthetic cases', result.returncode == 0 and 'accepted_step284_revalidated\tPASS (129 passes, 0 failures)' in result.stdout)
    for suffix in ['-policy.json', '.tsv', '-authorization.tsv']:
        check('exact freeze publication ' + suffix, (output / (base + suffix)).read_bytes() == (fixture / (base + suffix)).read_bytes())
    check('publication authorizes only conditional single observation, no live result', 'observation_authority_effective_after_user_repository_acceptance\tyes' in result.stdout and 'observation_invocation_limit\t1' in result.stdout and 'live_target_observation_performed\tno' in result.stdout and ('next_stage\t'+next_stage) in result.stdout)
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
        ('authorization','builder_execution_authorized',True),
        ('authorization','network_access_authorized',True),
        ('observation_authorization','invocation_limit',2),
        ('observation_authorization','probe_sha256','0'*64),
        ('observation_authorization','boot_id_argument_accepted',True),
    ]:
        target = replica / policy_path.relative_to(root); original = target.read_bytes(); bad = json.loads(original); bad[section][key] = value; target.write_text(json.dumps(bad) + '\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed freeze or operational permission rejected: ' + key, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
for rel in list(own_hashes) + ['tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace: ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
changelog = (root / 'CHANGELOG.md').read_text()
check('CHANGELOG records accepted284 and bounded285 authorization', '## Phase 1 step 285 ' in changelog and '48028a3' in changelog and 'Granted one new read-only probe copy/invocation' in changelog and '## Phase 1 step 284 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST