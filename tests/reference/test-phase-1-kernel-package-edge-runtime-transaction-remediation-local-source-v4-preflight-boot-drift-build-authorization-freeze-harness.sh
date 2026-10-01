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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze'
prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review'
next_stage = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-result-review-and-strong-safe-pause'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze.md': 'fc4697bd52f835002e2e340f3931b8e37ebf2047c61b1d85f7838675dba3dfa8', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze-policy.json': '2c317d04d9d295f5ef012d9ccb42c8d9e022332f23bb3e298c86b8dfb67d33a7', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze.tsv': '33873839b1253bddaf292d49ea40dda548659aafefc1a9a9373393f496d09d63', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze-authorization.tsv': '2844aab2cc35b5d8d2c87a70b5215a482936b31fafef35cd9039f2c4a1283842', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze.sh': '083b9447c899b7f02293ee484713db4f46d525d096e3aaaf13cb6ea82380d843'}
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
check('new authorization freeze follows accepted286 review', policy['schema']==1 and policy['step']==287 and policy['scenario']==base and not policy['review_only'] and policy['review_status']=='PASS' and previous['next_stage']==base)
check('confirmed159f85a full149 user checkpoint', accepted['step']==286 and accepted['commit']=='159f85a' and accepted['acceptance_result']=='PASS (149 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('complete prefix provenance without full object invention', accepted['commit_identity_scope']=='user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted and accepted['provenance']=='complete-user-returned-step286-application-acceptance-commit-push-clean-tree-2026-10-01')
for key in ['design','implementation','implementation_state_scope','current_probe_implementation_state','accepted_freeze_contract','accepted_implementation_freeze_contract','immutable_implementation','accepted_authorization_closure','historical_observation','historical_returned_attempt','future_build_boundary','roadmap','strong_pause_completion_conditions','accepted_observation_authorization','accepted_observation_return_contract','accepted_observation','current_boot_id','current_target_or_output_preservation_independently_observed','current_state_claim_scope']:
    check('exact accepted source/evidence/binding preservation: '+key,policy[key]==previous[key])
design=policy['design'];implementation=policy['implementation'];observation=policy['accepted_observation'];single=policy['single_build_authorization'];controller=policy['controller_protocol'];boot=observation['values']['fresh_boot_id']
check('accepted build review preserved exactly',policy['accepted_build_authorization_review']==previous['future_authorization'])
expected=copy.deepcopy(previous['future_authorization']);expected.update(state='single-build-contract-frozen-and-authorized',new_authority_granted=True,transport_or_execution_authority_granted_by_this_review=True)
check('whole build contract frozen with only state and two grant changes',single==expected)
check('only the three declared contract fields differ',{k for k in single if single[k]!=previous['future_authorization'][k]}=={'state','new_authority_granted','transport_or_execution_authority_granted_by_this_review'})
for key in ['authorization_boot_id','execution_argv','attempt_limit','authority_consumed_on_attempt_even_on_failure','executor_path','executor_sha256','builder_path','builder_sha256','transport_artifact_paths','permitted_output_paths','temporary_creation_scope','fresh_observation_path','fresh_observation_sha256','full_preflight_immediately_before_launch','reject_drift_before_launch','no_manual_builder_execution','no_retry_after_failure','old_executor_or_authorization_reuse_allowed','boot_continuity_required_from_observation_to_attempt','exact_single_invocation_even_on_preflight_failure','full_stdout_stderr_and_exit_status_required','second_execution_after_success_or_failure_authorized','boot_argument_from_error_substitution_allowed']:
    check('frozen single-build invariant: '+key,single[key]==previous['future_authorization'][key])
check('exact fresh UUID, mandatory argv and one-invocation limit',single['authorization_boot_id']==boot==policy['current_boot_id']=='bcfac4fa-4e6e-450a-aa95-bd591a979b4e' and single['execution_argv']==['--execute-authorized-local-source-v4-build-v2','--authorization-boot-id',boot] and type(single['attempt_limit']) is int and single['attempt_limit']==1)
check('fresh observation SHA and consumed probe authority retained',single['fresh_observation_path']==observation['observation_path'] and single['fresh_observation_sha256']==observation['normalized_observation_sha256'] and observation['probe_authority_consumed'] and not observation['probe_transport_or_execution_rerun_authorized'])
check('new authority identity is not historical reuse',controller['new_authority_id']=='phase-1-step287-single-fresh-boot-drift-build-attempt' and not single['old_executor_or_authorization_reuse_allowed'])
for key in ['authorization_effective_only_after_user_application_acceptance_commit_push_clean_tree','accepted_step287_commit_and_clean_tree_required_before_transport','accepted_contract_changed_only_state_and_two_grant_fields','transport_exact_executor_and_builder_together','regular_non_symlink_files_required_on_arch_and_vm','sha256_verification_on_arch_and_vm_before_invocation_required','unchanged_observation_to_attempt_boot_required','full_immediate_executor_preflight_required','consume_on_executor_invocation_even_preflight_failure_sudo_failure_or_interruption','no_manual_builder_chmod_or_external_cleanup','halt_transport_hash_or_boot_drift_for_review','complete_stdout_stderr_and_exit_status_required','returned_actual_result_and_remaining_effects_review_required_before_pause','closure_revokes_remaining_build_and_transport_authority','future_runtime_requires_fresh_revalidation_and_new_authorization']:
    check('controller invariant: '+key,controller[key] is True)
for key in ['transported_builder_executable_bit_required','second_invocation_after_success_or_failure_authorized','boot_argument_from_error_substitution_allowed','persistent_attempt_marker_added','production_executor_invocation_observed','production_builder_entry_observed','build_result_observed']:
    check('no unsupported requirement/effect/evidence claim: '+key,controller[key] is False)
check('single use explicitly controller-enforced without marker',controller['single_use_enforcement']=='controller-one-attempt-authorization-protocol-no-automatic-or-manual-retry')
authorization=policy['authorization'];allowed={'builder_execution_authorized','builder_transport_authorized','local_source_v4_build_authorized','new_executor_execution_authorized','new_executor_transport_authorized'}
check('only exact executor/builder pair and through-executor build opened',{k for k,v in authorization.items() if v}==allowed)
check('repository freeze preparation consumed; no probe or other authority open',not authorization['repository_only_build_authorization_freeze_authorized'] and all(v is False for k,v in authorization.items() if k not in allowed))
check('pending actual attempt/review requires machine/controller, no pause',policy['machine_action_required'] is True and policy['controller_action_required'] is True and policy['pause_safe'] is False and policy['strong_safe_pause'] is False)
check('success next stage matches planned288; failure route preserved',policy['next_stage']==next_stage==single['success_route']==policy['roadmap']['preferred_steps'][8]['stage'] and policy['failure_stage']==single['failure_route'] and policy['failure_stage']!=next_stage)
check('repository tests enter no production executor/probe or builder',policy['repository_acceptance_scope']=={'full_accepted149_predecessor_suite_required':True,'new_executor_builder_or_probe_bytes_modified':False,'production_executor_main_entered':False,'production_probe_main_entered':False,'production_builder_entered':False,'host_bound_guards_called':False,'live_target_observation_performed':False,'production_constants_modified':False})
inventory=policy['authorization_identity_inventory']
check('two exact transport inventory roles',[row['role'] for row in inventory]==['authorized-immutable-executor','authorized-immutable-builder'])
check('executor conditional single-invocation inventory',inventory[0]=={'role':'authorized-immutable-executor','path':single['executor_path'],'sha256':single['executor_sha256'],'scope':'single-invocation-only-after-user-repository-acceptance'})
check('builder through-executor-only inventory',inventory[1]=={'role':'authorized-immutable-builder','path':single['builder_path'],'sha256':single['builder_sha256'],'scope':'transport-with-executor-execution-only-through-verified-executor'})
for row in inventory:
    check('exact existing bound source: '+row['role'],accepted['sha256_bindings'][row['path']]==row['sha256'])
with (fixture/(base+'-authorization.tsv')).open(newline='') as handle:inventory_rows=list(csv.DictReader(handle,delimiter='\t'))
check('authorization TSV exactly matches inventory',inventory_rows==inventory)
record_rows=[l.split('\t') for l in (fixture/(base+'.tsv')).read_text().splitlines()]
check('strict unique real-tab freeze record',all(len(row)==2 and all(row) for row in record_rows) and len(record_rows)==len(dict(record_rows)))
record=dict(record_rows)
check('record accepted checkpoint and frozen grant binding exact',record['step']=='287' and record['accepted_checkpoint_step']=='286' and record['accepted_checkpoint_commit']=='159f85a' and record['accepted_checkpoint_acceptance']==accepted['acceptance_result'] and record['fresh_authorization_boot_id']==boot and record['accepted_observation_sha256']==observation['normalized_observation_sha256'] and record['single_build_authorization_state']==single['state'] and record['attempt_limit']=='1')
check('record conditional gate, consumption and no actual attempt claim',record['authority_effective_after_user_repository_acceptance']=='yes' and record['consume_on_executor_invocation_even_preflight_failure']=='yes' and all(record[k]=='no' for k in ['production_executor_invocation_observed','production_builder_entry_observed','build_result_observed']) and record['probe_authority_consumed']=='yes' and record['all_prior_operational_authority_revoked']=='yes')
check('record permissions/state/result routes consistent',all(record[k]==('yes' if v else 'no') for k,v in authorization.items()) and all(record[k]==('yes' if policy[k] else 'no') for k in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']) and record['failure_stage']==policy['failure_stage'] and record['next_stage']==next_stage)
doc=(root/'docs/reference'/(base+'.md')).read_text();commands=re.findall(r'```bash\n(.*?)```',doc,re.S)
check('one reviewable attempt snippet syntax only, never executed',len(commands)==1 and run(['bash','-n','-c',commands[0]]).returncode==0)
check('snippet verifies both hashes and gates one sudo Bash executor invocation',commands[0].count('sudo bash --')==1 and single['executor_sha256'] in commands[0] and single['builder_sha256'] in commands[0] and 'sha256sum -c - &&' in commands[0] and ('--execute-authorized-local-source-v4-build-v2 --authorization-boot-id '+boot) in commands[0] and 'build_attempt_exit_status=$?' in commands[0])
check('snippet requires regular non-symlink pair and no manual build launch','[[ -f "$EXECUTOR" && ! -L "$EXECUTOR" && -f "$BUILDER" && ! -L "$BUILDER" ]]' in commands[0] and 'sudo bash -- "$BUILDER"' not in commands[0] and 'chmod' not in commands[0] and 'SLACK_UPDATE_' not in commands[0])
source = helper.read_text()
check('helper only invokes accepted predecessor suite', re.findall(r'(?m)^if ! bash -- "\$repo_root/([^\"]+)"', source) == ['tests/reference/test-' + prior + '-harness.sh'] and not re.search(r'(?m)^\s*(?:sudo|source|eval|ssh|scp|slackpkg|upgradepkg|reboot)\b', source))
for argv in [['--help'], ['--bogus'], [], ['--output-dir'], ['--output-dir', '']]:
    check('strict helper CLI ' + repr(argv), run(['bash', '--', helper, *argv]).returncode == (0 if argv == ['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step287-repository-') as directory:
    tmp = Path(directory); output = tmp / 'freeze output'; output.mkdir()
    result = run(['bash', '--', helper, '--output-dir', output])
    check('full149 review suite actually reruns without production attempt',result.returncode==0 and 'accepted_step286_revalidated\tPASS (149 passes, 0 failures)' in result.stdout)
    for suffix in ['-policy.json', '.tsv', '-authorization.tsv']:
        check('exact freeze publication ' + suffix, (output / (base + suffix)).read_bytes() == (fixture / (base + suffix)).read_bytes())
    check('publication says conditional single attempt pending and no production entry', 'build_authority_effective_after_user_repository_acceptance\tyes' in result.stdout and ('authorization_boot_id\t'+boot) in result.stdout and 'executor_invocation_limit\t1' in result.stdout and 'production_executor_or_builder_entered_by_this_helper\tno' in result.stdout and 'probe_rerun_authorized\tno' in result.stdout and ('next_stage\t'+next_stage) in result.stdout)
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
        ('authorization','new_probe_execution_authorized',True),
        ('authorization','manual_builder_execution_authorized',True),
        ('single_build_authorization','attempt_limit',2),
        ('single_build_authorization','authorization_boot_id','79a19518-0d0a-4c57-ac1f-679a39edefbd'),
        ('controller_protocol','production_builder_entry_observed',True),
    ]:
        target = replica / policy_path.relative_to(root); original = target.read_bytes(); bad = json.loads(original); bad[section][key] = value; target.write_text(json.dumps(bad) + '\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed freeze or operational permission rejected: ' + key, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
for rel in list(own_hashes) + ['tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace: ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
changelog = (root / 'CHANGELOG.md').read_text()
check('CHANGELOG records accepted286 and exact conditional287 freeze', '## Phase 1 step 287 ' in changelog and '159f85a' in changelog and boot in changelog and 'Froze the exact reviewed single-build contract, changing only state and two grant fields' in changelog and '## Phase 1 step 286 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST