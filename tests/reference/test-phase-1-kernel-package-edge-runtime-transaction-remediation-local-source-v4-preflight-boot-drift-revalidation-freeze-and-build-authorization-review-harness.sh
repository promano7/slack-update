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
base = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review'
prior = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-authorization'
next_stage = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-build-authorization-freeze'
own_hashes = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review.md': '39ddf0974017337727ab404cf94a31596081b379e5858c4430bc35aa70c35f1b', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review-policy.json': '51e4b047cefd22871feab2b3df3525b5f400a970c47ae02a014c0f3d2868e3e1', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review.tsv': '7addffd57e960eb657cd096fb3dae49c89bd19f04869803bb248114787aefc10', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review-observation.tsv': 'e9be53e174808dfe9e9cdb6e35fcd4eccdbf7c220602cfc4f5cadf939c28a105', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-freeze-and-build-authorization-review.sh': '45da90ae509df8cd74b6d593bdc2d3283d4cf9978ab4c589876dd4fa7fbc679e'}
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
check('freeze/build review identity follows accepted285', policy['schema']==1 and policy['step']==286 and policy['scenario']==base and policy['review_only'] and policy['review_status']=='PASS' and previous['next_stage']==base)
check('confirmed0777e0d full132 user checkpoint', accepted['step']==285 and accepted['commit']=='0777e0d' and accepted['acceptance_result']=='PASS (132 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('complete prefix provenance without full object invention', accepted['commit_identity_scope']=='user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted and accepted['provenance']=='complete-user-returned-step285-application-acceptance-commit-push-clean-tree-2026-10-01')
for key in ['design','implementation','accepted_freeze_contract','accepted_implementation_freeze_contract','immutable_implementation','accepted_authorization_closure','historical_observation','historical_returned_attempt','future_build_boundary','roadmap','strong_pause_completion_conditions']:
    check('exact historical source/evidence/boundary preservation: '+key, policy[key]==previous[key])
check('accepted observation grant preserved as historical, not current', policy['accepted_observation_authorization']==previous['observation_authorization'])
check('expected observation return contract preserved', policy['accepted_observation_return_contract']==previous['observation_return_contract'])
design=policy['design'];implementation=policy['implementation'];observation=policy['accepted_observation'];contract=policy['accepted_observation_return_contract'];future=policy['future_authorization']
check('historical source-freeze state distinguished from observed state', implementation['state']=='implementation-frozen-not-production-observed' and policy['implementation_state_scope']=='inherited-accepted-step284-source-freeze-checkpoint-not-current-live-observation-state' and policy['current_probe_implementation_state']=='implementation-frozen-user-live-observation-reviewed')
check('actual source bytes preserved at authorized hash', hashlib.sha256((root/implementation['probe_path']).read_bytes()).hexdigest()==implementation['probe_sha256']==contract['required_probe_sha256'])
observation_path=root/observation['observation_path'];blob=observation_path.read_bytes()
rows=[line.split('\t') for line in blob.decode().splitlines()]
check('strict real-tab normalized unique observation', all(len(row)==2 and all(row) for row in rows) and len(rows)==len(dict(rows))==41)
values=dict(rows)
check('exact ordered 41 returned field values frozen', [key for key,value in rows]==contract['ordered_field_names'] and values==observation['values'] and observation['field_count']==41)
check('normalized observation exact SHA and provenance', hashlib.sha256(blob).hexdigest()==observation['normalized_observation_sha256'] and observation['provenance']=='complete-user-returned-step285-sha-verified-probe-transcript-and-exit-status-2026-10-01')
check('semantic transcription does not invent raw stdout identity', observation['normalization']=='real-tab-TSV-from-user-returned-display-values-no-original-output-byte-identity-claim')
check('separate exit0 and VM SHA gate reviewed', observation['vm_pre_invocation_sha_check_passed'] and type(observation['reported_exit_status']) is int and observation['reported_exit_status']==0 and observation['complete_stdout_stderr_and_exit_status_reviewed'] and not observation['stderr_error_text_present_in_return'] and 'observation_exit_status' not in values)
check('live PASS is new status and actual frozen probe identity', values[contract['required_status_field']]=='PASS' and values['probe_sha256']==implementation['probe_sha256'])
boot=values['fresh_boot_id']
check('fresh returned canonical UUID tied to current snapshot', boot==policy['current_boot_id']=='bcfac4fa-4e6e-450a-aa95-bd591a979b4e' and re.fullmatch(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',boot) is not None)
check('fresh read not historical/error substitution; no boot cause inference', observation['fresh_uuid_from_new_probe_not_error_or_historical_substitution'] and not observation['cause_or_time_of_prior_boot_changes_known'])
for key in contract['required_yes_fields']:
    check('returned preservation/output absence yes: '+key, values[key]=='yes')
for key in contract['required_no_fields']:
    check('returned no-effect/no-reuse field: '+key, values[key]=='no')
constants=dict(re.findall(r"(?m)^readonly ([A-Z0-9_]+)='([^']*)'$",(root/implementation['probe_path']).read_text()))
for field,constant in {'hostname_fqdn':'EXPECTED_FQDN','uname_machine':'EXPECTED_UNAME_MACHINE','uname_release':'EXPECTED_UNAME_RELEASE','slackware_version':'EXPECTED_SLACKWARE_VERSION','package_database_manifest_sha256':'EXPECTED_PACKAGE_DATABASE_MANIFEST_SHA256','header_package_record':'EXPECTED_HEADER_RECORD','kernel_generic_record':'EXPECTED_KERNEL_GENERIC_RECORD','slackpkg_conf_sha256':'EXPECTED_SLACKPKG_CONF_SHA256','slackpkg_mirrors_sha256':'EXPECTED_SLACKPKG_MIRRORS_SHA256','staged_target_sha256':'EXPECTED_TARGET_SHA256','local_source_v3_tree_manifest_sha256':'EXPECTED_V3_TREE_MANIFEST_SHA256','failed_v2_pkglist_sha256':'EXPECTED_EMPTY_SHA256','frozen_v4_builder_sha256':'EXPECTED_V4_BUILDER_SHA256'}.items():
    check('returned value matches immutable guarded expectation: '+field,values[field]==constants[constant])
check('returned failed pkglist size zero and builder SHA contextual', values['failed_v2_pkglist_size_bytes']=='0' and observation['frozen_builder_sha_is_repository_context_not_observed_transport'] and values['frozen_v4_builder_sha256']==policy['immutable_implementation']['builder_sha256'])
check('probe grant consumed/revoked without second observation', observation['probe_authority_consumed'] and not observation['probe_transport_or_execution_rerun_authorized'])
check('guarded live state claim applies only at invocation', policy['current_target_or_output_preservation_independently_observed'] and policy['current_state_claim_scope']==observation['state_claim_scope']=='user-returned-live-guarded-observation-at-that-invocation-not-continuous-state-assurance')
check('future attempt newly reviewed but no authority granted', future['state']=='single-build-contract-reviewed-not-authorized' and future['review_provenance']=='new-step286-review-bound-to-fresh-step285-observation-no-historical-authority-reuse' and not future['new_authority_granted'] and not future['transport_or_execution_authority_granted_by_this_review'])
check('future argv bound exclusively to accepted fresh UUID', future['authorization_boot_id']==boot and future['execution_argv']==['--execute-authorized-local-source-v4-build-v2','--authorization-boot-id',boot])
check('future reviewed observation binding exact', future['fresh_observation_path']==observation['observation_path'] and future['fresh_observation_sha256']==observation['normalized_observation_sha256'])
check('future exact executor/builder source pair', future['executor_path']==policy['immutable_implementation']['executor_path'] and future['executor_sha256']==policy['immutable_implementation']['executor_sha256'] and future['builder_path']==policy['immutable_implementation']['builder_path'] and future['builder_sha256']==policy['immutable_implementation']['builder_sha256'] and future['transport_artifact_paths']==[future['executor_path'],future['builder_path']])
check('exactly one future invocation including preflight failure', type(future['attempt_limit']) is int and future['attempt_limit']==1 and future['authority_consumed_on_attempt_even_on_failure'] and future['exact_single_invocation_even_on_preflight_failure'])
check('future continuity mandatory but not independently measured since probe', future['boot_continuity_required_from_observation_to_attempt'] and not future['boot_continuity_independently_observed_after_probe'] and policy['future_build_boundary']['same_boot_as_new_accepted_observation_required'])
check('all immediate guards and full return remain required', future['full_preflight_immediately_before_launch'] and future['reject_drift_before_launch'] and future['full_stdout_stderr_and_exit_status_required'])
check('only immutable executor can launch verified Bash builder', future['execute_only_through_new_executor'] and future['no_manual_builder_execution'] and not future['chmod_remediation_allowed'] and not future['old_executor_or_authorization_reuse_allowed'])
check('no retry/error substitution or second execution', future['no_retry_after_failure'] and not future['second_execution_after_success_or_failure_authorized'] and not future['boot_argument_from_error_substitution_allowed'])
check('reviewed effects restricted to existing immutable builder contract', future['permitted_output_paths']==['/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4','/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256','/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256.sha256'] and future['temporary_creation_scope']=='builder-owned-.local-source-v4.build.*-with-existing-builder-cleanup-contract')
check('success result route matches planned288 and failure differs', future['success_route']==policy['roadmap']['preferred_steps'][8]['stage'] and future['failure_route']!=future['success_route'] and future['failure_route'].endswith('-preflight-boot-drift-build-failure-result-review'))
authorization=policy['authorization']
check('only repository build-authorization freeze is open', {key for key,value in authorization.items() if value}=={'repository_only_build_authorization_freeze_authorized'})
check('every live probe transport/execution and build permission closed', all(value is False for key,value in authorization.items() if key!='repository_only_build_authorization_freeze_authorized'))
check('no current machine/controller action or strong pause', all(policy[key] is False for key in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']))
check('next stage matches planned287 authorization freeze', next_stage==policy['next_stage']==policy['roadmap']['preferred_steps'][7]['stage'])
check('repository freeze tests do not rerun live observation', policy['repository_acceptance_scope']=={'full_accepted132_predecessor_suite_required':True,'accepted_observation_values_reviewed_without_probe_rerun':True,'production_main_entered':False,'production_builder_entered':False,'host_bound_guards_called':False,'live_target_observation_performed':False,'production_constants_modified':False,'new_probe_installed_or_modified':False})
record_rows=[line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines()]
check('strict unique real-tab review record', all(len(row)==2 and all(row) for row in record_rows) and len(record_rows)==len(dict(record_rows)))
record=dict(record_rows)
check('record matches accepted checkpoint and normalized live evidence', record['step']=='286' and record['accepted_checkpoint_step']=='285' and record['accepted_checkpoint_commit']=='0777e0d' and record['accepted_checkpoint_acceptance']==accepted['acceptance_result'] and record['fresh_boot_id']==boot and record['normalized_observation_sha256']==observation['normalized_observation_sha256'] and record['observation_field_count']=='41' and record['reported_observation_exit_status']=='0')
check('record consumption and review-only build state exact', record['probe_authority_consumed']=='yes' and record['all_prior_operational_authority_revoked']=='yes' and record['current_target_or_output_preservation_independently_observed']=='yes' and record['post_observation_boot_continuity_independently_observed']=='no' and record['future_build_contract_state']==future['state'] and record['future_build_authority_granted']=='no' and record['current_probe_implementation_state']==policy['current_probe_implementation_state'])
check('record permissions/state/next stage consistent', all(record[key]==('yes' if value else 'no') for key,value in authorization.items()) and all(record[key]=='no' for key in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']) and record['next_stage']==next_stage)
source = helper.read_text()
check('helper only invokes accepted predecessor suite', re.findall(r'(?m)^if ! bash -- "\$repo_root/([^\"]+)"', source) == ['tests/reference/test-' + prior + '-harness.sh'] and not re.search(r'(?m)^\s*(?:sudo|source|eval|ssh|scp|slackpkg|upgradepkg|reboot)\b', source))
for argv in [['--help'], ['--bogus'], [], ['--output-dir'], ['--output-dir', '']]:
    check('strict helper CLI ' + repr(argv), run(['bash', '--', helper, *argv]).returncode == (0 if argv == ['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step286-repository-') as directory:
    tmp = Path(directory); output = tmp / 'freeze output'; output.mkdir()
    result = run(['bash', '--', helper, '--output-dir', output])
    check('full132 predecessor suite actually reruns without another live observation', result.returncode==0 and 'accepted_step285_revalidated\tPASS (132 passes, 0 failures)' in result.stdout)
    for suffix in ['-policy.json', '.tsv', '-observation.tsv']:
        check('exact freeze publication ' + suffix, (output / (base + suffix)).read_bytes() == (fixture / (base + suffix)).read_bytes())
    check('publication freezes accepted observation and grants no build', 'accepted_observation_frozen\tyes' in result.stdout and ('accepted_fresh_boot_id\t'+boot) in result.stdout and 'probe_authority_consumed\tyes' in result.stdout and 'future_build_authority_granted\tno' in result.stdout and 'live_target_observation_performed_by_this_helper\tno' in result.stdout and ('next_stage\t'+next_stage) in result.stdout)
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
        ('authorization','new_probe_execution_authorized',True),
        ('future_authorization','new_authority_granted',True),
        ('future_authorization','authorization_boot_id','79a19518-0d0a-4c57-ac1f-679a39edefbd'),
        ('accepted_observation','reported_exit_status',1),
    ]:
        target = replica / policy_path.relative_to(root); original = target.read_bytes(); bad = json.loads(original); bad[section][key] = value; target.write_text(json.dumps(bad) + '\n')
        result = run(['bash', '--', replica_helper, '--output-dir', rejected])
        check('changed freeze or operational permission rejected: ' + key, result.returncode != 0 and not list(rejected.iterdir()))
        target.write_bytes(original)
for rel in list(own_hashes) + ['tests/reference/test-' + base + '-harness.sh']:
    check('no trailing whitespace: ' + Path(rel).name, all(line == line.rstrip() for line in (root / rel).read_text().splitlines()))
changelog = (root / 'CHANGELOG.md').read_text()
check('CHANGELOG records accepted285, returned observation and reviewed286 boundary', '## Phase 1 step 286 ' in changelog and '0777e0d' in changelog and boot in changelog and 'Reviewed, without granting, one future immutable-executor/Bash-builder attempt' in changelog and '## Phase 1 step 285 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST