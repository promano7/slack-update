#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-freeze';own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization.md': '425d89f501909b1292ea7204afaa6aef02ac756b92f93b14843fd6303abbf950', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization-policy.json': '844f8bc58c71088ed949abb28fcd9f56fddaa99c28c99c4d95f93c632da33b47', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization.tsv': '8fd86c655751c487b827ade2de9e569d303f67c0284c0b37353b01988b5f4dc0', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization-authorization.json': '765b0f387b41810a27e196dbcbd0331b9bd28b0b63771a2a4ec0dd5df4e5c25d', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization.sh': '1b06f2c9471d81db17e5bf0ccfbc9cdacdc7806f85c18718d58331a970226835'}
fixture=root/'tests/fixtures/reference/acceptance/phase-1';policy_path=fixture/(base+'-policy.json');policy=json.loads(policy_path.read_text());previous=json.loads((fixture/(prior+'-policy.json')).read_text());contract=json.loads((fixture/(base+'-authorization.json')).read_text());accepted=policy['accepted_checkpoint'];design=policy['design'];implementation=policy['implementation'];helper=root/'tools/reference'/(base+'.sh');probe=root/implementation['probe_path'];passes=0

def check(label,value):
 global passes
 if not value:raise SystemExit('FAIL: '+label)
 passes+=1;print('PASS: '+label,flush=True)
def run(args,**kwargs):return subprocess.run([str(x) for x in args],capture_output=True,text=True,**kwargs)
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def accepted_bytes(rel):
 p=root/rel
 if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):return None
 data=p.read_bytes()
 if rel=='CHANGELOG.md':
  position=data.find(b'## Phase 1 step 293 ')
  if position<0:return None
  data=data[position:]
 return data
bindings=accepted['sha256_bindings']
check('all1242 accepted bytes/safe paths and exact CHANGELOG history bound',len(bindings)==accepted['repository_file_count']==1242 and all((data:=accepted_bytes(rel)) is not None and hashlib.sha256(data).hexdigest()==sha for rel,sha in bindings.items()))
critical={rel:bindings[rel] for rel in ['docs/reference/'+prior+'.md','tests/fixtures/reference/acceptance/phase-1/'+prior+'-policy.json','tests/fixtures/reference/acceptance/phase-1/'+prior+'-implementation.json','tests/fixtures/reference/acceptance/phase-1/'+prior+'.tsv','tools/reference/'+prior+'.sh','tests/reference/test-'+prior+'-harness.sh',implementation['probe_path'],design['historical_baseline_path'], 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh','tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh','tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh']}
for rel,sha in (critical|own_hashes).items():
 p=root/rel;check('exact regular artifact: '+p.name,p.is_file() and not p.is_symlink() and p.resolve()==p.absolute() and digest(p)==sha)
for p in [probe,helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
check('authorization follows accepted implementation freeze',policy['schema']==1 and policy['step']==294 and policy['scenario']==previous['next_stage']==base and policy['review_only'] and policy['review_status']=='PASS')
check('confirmedc1482cb complete232 predecessor',accepted['step']==293 and accepted['commit']=='c1482cb' and accepted['acceptance_result']=='PASS (232 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('prefix scope without invented full commit',accepted['commit_identity_scope']=='user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted)
for key in ['accepted_build_result','accepted_local_source_v4','accepted_authorization_closure','accepted_runtime_boundary_after_pause','historical_observation','accepted_step288_pause_remains_valid_as_historical_checkpoint','fresh_boundary','preservation','revalidation_boundary','future_runtime_boundary','roadmap','strong_pause_completion_conditions','design','design_path','implementation','implementation_path']:
 check('unchanged accepted boundary: '+key,policy[key]==previous[key])
check('accepted implementation freeze delta separately retained',policy['accepted_implementation_freeze_delta']==previous['freeze_delta'] and 'freeze_delta' not in policy)
check('whole frozen implementation fixture unchanged',json.loads((root/policy['implementation_path']).read_text())==implementation and implementation['state']=='implementation-frozen-not-observation-authorized')
check('whole frozen design fixture unchanged',json.loads((root/policy['design_path']).read_text())==design)
check('contract fixture exact identity',policy['observation_authorization']==contract and policy['observation_authorization_path']=='tests/fixtures/reference/acceptance/phase-1/'+base+'-authorization.json')
check('new authority is conditional and distinct',contract['schema']==1 and contract['step']==294 and contract['authority_id']=='phase1-step294-post-v4-build-read-only-observation-once' and contract['grant_is_new_not_reuse'] and contract['state']=='conditional-single-use-observation-granted-pending-user-repository-acceptance-and-controller-release')
gate=contract['repository_acceptance_gate']
for key in ['overlay_applied','full_step294_harness_passed','step294_commit_and_push_completed','user_worktree_clean','complete_return_reviewed_before_controller_release']:check('required release gate: '+key,gate[key] is True)
check('no controller release issued or machine observation claimed',not gate['controller_release_issued'] and contract['attempt']['invocations_issued']==0 and policy['fresh_boundary']['current_boot_id'] is None and not implementation['live_target_observation_performed'])
check('conditional grants limited to transport/read-only observation',contract['conditional_grants']==dict(new_probe_transport=True,new_probe_read_only_execution=True,target_observation=True))
target=contract['target']
for key,value in dict(hostname_fqdn='vbox-slackcurrent.vbox-slackcurrent.org',uname_machine='x86_64',uname_release='6.18.45',slackware_version='Slackware 15.0+',package_database_manifest_sha256='726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6',header_package_record='kernel-headers-6.18.45-x86-1',kernel_generic_record='kernel-generic-6.18.45-x86_64-1').items():check('frozen target binding: '+key,target[key]==value)
check('fresh kernel UUID not supplied or historical authority',target['current_boot_id'] is None and target['current_boot_id_source']=='/proc/sys/kernel/random/boot_id' and target['authorization_boot_argument'] is None and target['canonical_fresh_uuid_required'] and not target['historical_boot_binding_reusable'] and target['fresh_uuid_may_equal_historical_without_reusing_authority'])
cp=contract['probe']
check('frozen probe exact source/path/hash',cp['path']==implementation['probe_path']==design['future_probe_path'] and cp['basename']==probe.name and cp['sha256']==digest(probe)==implementation['probe_sha256']==design['expected_derivation_sha256']=='4d1bc852cf0bfea9b5131687bbe5cf70703cae04ae73a342a4afc7192a8440db')
check('only one transported probe and no chmod/source modification',cp['transport_artifact_count']==1 and cp['transport_destination']=='bound-vbox-slackcurrent-user-Downloads' and cp['regular_non_symlink_required'] and cp['sha256_required_on_arch_and_vm'] and not cp['chmod_required'] and not cp['source_modification_allowed'])
check('exact single CLI without boot override or target library mode',cp['cli_arguments']==[design['cli_switch']] and cp['library_mode_not_authorized_for_target_execution'] and '--authorization-boot-id' not in contract['vm_command_block'] and design['library_only_mode_requires_sourcing'])
for key in ['consumed_on_sudo_failure_preflight_rejection_probe_failure_or_interruption','success_does_not_preserve_retry_authority','hash_transport_failure_stops_for_review']:check('single-use lifecycle: '+key,contract['attempt'][key] is True)
check('one invocation maximum including rejection no retry/marker',contract['attempt']['maximum_invocations']==1 and contract['attempt']['invocations_issued']==0 and not contract['attempt']['automatic_or_manual_retry_authorized'] and not contract['attempt']['persistent_attempt_marker_added'] and contract['attempt']['single_use_enforcement']=='controller-protocol-no-target-attempt-marker')
effects=contract['production_effects']
check('probe read-only and no production writes',effects['probe_operation']=='read-only' and effects['production_writes_authorized']==[] and effects['no_preserved_source_evidence_or_system_configuration_write'])
check('controller capture explicitly outside preserved trees',effects['controller_probe_transport_outside_acceptance_root'] and effects['controller_capture_is_outside_acceptance_root'] and effects['controller_capture_is_not_production_probe_effect'] and effects['controller_capture_directory_template']=='$PWD/slack-update-step294-observation.XXXXXXXX' and effects['controller_capture_files']==['probe.stdout','probe.stderr','probe.exit-code'])
check('no cleanup/chmod/build and no atime/audit overclaim',effects['no_cleanup_chmod_rebuild_or_overwrite'] and effects['atime_sudo_audit_and_controller_capture_not_asserted_unchanged'])
check('one-probe user transfer grants no production network',effects['transport_network_scope']=='user-mediated-transfer-of-one-probe-only-no-package-or-repository-network' and not effects['production_probe_network_access_authorized'] and not policy['authorization']['network_access_authorized'])
check('preservation and all guard inventory unchanged',contract['preservation']==previous['preservation'] and contract['required_guard_inventory']==previous['revalidation_boundary']['required_guard_inventory'])
check('closed action inventory exact',contract['scope_closed']==['historical-probe-rerun','builder-transport-or-execution','local-source-build','runtime-executor-transport-or-execution','package-action','Slackpkg-refresh-or-mutation','package-or-repository-network','persistent-configuration-change','boot-action','reboot','source-or-evidence-cleanup','chmod-remediation','Phase2'])
ret=contract['return_contract']
for key in ['full_stdout_file_required','full_stderr_file_required_even_when_empty','exact_decimal_exit_code_file_required','terminal_display_includes_complete_captured_streams_and_explicit_exit','terminal_display_is_not_original_interleaving','success_requires_exit0_empty_stderr_and_exact_50_unique_ordered_real_tab_fields','last_nine_no_effect_fields_required','probe_sha256_must_match_grant','builder_sha_field_is_repository_frozen_context_not_transport_evidence','interruption_or_missing_exit_is_incomplete_not_success','returned_probe_is_point_in_time_not_continuous_or_atomic_snapshot','all_available_files_preserved_on_failure_or_interruption']:check('complete return boundary: '+key,ret[key] is True)
check('absent PASS never retains authority',ret['no_pass_or_partial_output_preserves_authority'] is False)
check('exact fifty-field frozen return contract',ret['ordered_probe_fields']==design['ordered_publication_fields'] and len(set(ret['ordered_probe_fields']))==ret['field_count']==50)
check('success route matches provisional roadmap',policy['next_stage']==contract['review_and_closure']['success_next_stage']==previous['roadmap']['preferred_steps'][6]['stage'])
check('failure/interruption separate review no retry',policy['failure_next_stage']==contract['review_and_closure']['failure_or_interruption_next_stage']==base.replace('fresh-target-and-source-revalidation-authorization','revalidation-failure-result-review'))
for key in ['complete_result_and_effect_review_before_any_boundary_freeze','consume_probe_execution_authority_on_attempt','revoke_remaining_transport_and_operational_authority_after_return','no_runtime_authority_from_probe_success','no_repair_to_obtain_pass','strong_pause_requires_effect_review_and_all_authority_closed','attempt_success_or_preflight_alone_is_not_strong_pause']:check('effect review/closure gate: '+key,contract['review_and_closure'][key] is True)
expected_flags=['new_probe_transport_authorized','new_probe_execution_authorized','read_only_probe_transport_authorized','read_only_probe_execution_authorized','target_observation_authorized','repository_only_revalidation_result_review_authorized']
check('only exact conditional observation/result-review flags open',set(k for k,v in policy['authorization'].items() if v)==set(expected_flags) and policy['authorization_scope']=='conditional-on-complete-user-step294-repository-acceptance-and-explicit-controller-release-no-invocation-issued')
check('previous repository authorization-review grant consumed',previous['authorization']['repository_only_fresh_revalidation_authorization_review_authorized'] and not policy['authorization']['repository_only_fresh_revalidation_authorization_review_authorized'])
check('conditional machine/controller pending; reopened pause false',policy['machine_action_required'] and policy['controller_action_required'] and not policy['pause_safe'] and not policy['strong_safe_pause'])
for key in ['production_main_entered','production_builder_entered','production_host_guards_entered','production_constants_modified','live_target_observation_performed']:check('repository acceptance excludes production action: '+key,policy['repository_acceptance_scope'][key] is False)
check('full232 accepted1242-byte predecessor acceptance required',policy['repository_acceptance_scope']['accepted_predecessor_result']=='PASS (232 passes, 0 failures)' and policy['repository_acceptance_scope']['accepted_predecessor_complete_1242_file_bindings_required'])
vm=contract['vm_command_block'];vm_body=contract['synthetic_vm_body_after_cd'];arch=contract['arch_transport_command_block']
check('VM test body exact after fixed physical Downloads cd',vm=='(\n    cd -P -- ~/Descargas || exit\n'+vm_body+')\n' and hashlib.sha256(vm_body.encode()).hexdigest()==contract['synthetic_vm_body_sha256'])
check('one sudo invocation and direct exit capture with separate streams',vm.count('sudo bash --')==1 and 'if sudo bash -- "$PROBE" '+design['cli_switch']+' > "$observation_return_dir/probe.stdout" 2> "$observation_return_dir/probe.stderr"' in vm and 'observation_attempt_exit_status=$?' in vm and 'printf \'%s\\n\' "$observation_attempt_exit_status" > "$observation_return_dir/probe.exit-code"' in vm and ret['exit_envelope_key'] in vm)
check('capture directory disclosed before invocation',vm.index('observation_return_directory')<vm.index('if sudo bash --') and 'mktemp -d "$PWD/slack-update-step294-observation.XXXXXXXX"' in vm)
check('Arch verifies clean tree/hash and refuses destination overwrite',arch.count('cp --')==1 and 'git status --porcelain --untracked-files=all' in arch and 'sha256sum -c -' in arch and '[[ ! -e "/home/promano/Descargas/$PROBE" && ! -L "/home/promano/Descargas/$PROBE" ]]' in arch)
check('transport and invocation do not mention builder/executor',all(x not in arch+vm for x in ['build.sh','executor.sh','chmod ','rm ','slackpkg ','--authorization-boot-id']))
check('command blocks syntax valid without execution',all(run(['bash','-n'],input=block).returncode==0 for block in [arch,vm]))
# Exercise only the byte-bound VM body after cd; sudo is a fixture-only stand-in.
for case,exit_code,stdout,stderr in [('success',0,'synthetic successful observation\n',''),('preflight-rejection',1,'','ERROR: synthetic preflight rejection\n'),('sudo-failure',1,'','sudo: synthetic failure\n'),('exit-two',2,'synthetic partial output\n','synthetic usage rejection\n'),('interrupted',130,'synthetic partial output\n','synthetic interruption\n')]:
 with tempfile.TemporaryDirectory(prefix='step294-command-') as directory:
  tmp=Path(directory);fprobe=tmp/probe.name;fprobe.write_bytes(probe.read_bytes());bin_dir=tmp/'bin';bin_dir.mkdir();calls=tmp/'sudo.calls';stub=bin_dir/'sudo'
  stub.write_text('#!/usr/bin/python3\nimport json,os,sys\nfrom pathlib import Path\np=Path(os.environ["SYNTHETIC_SUDO_CALLS"]);p.write_text((p.read_text() if p.exists() else "")+json.dumps(sys.argv[1:])+"\\n")\nsys.stdout.write(os.environ["SYNTHETIC_STDOUT"])\nsys.stderr.write(os.environ["SYNTHETIC_STDERR"])\nsys.exit(int(os.environ["SYNTHETIC_EXIT"]))\n');stub.chmod(0o755)
  env=os.environ|{'PATH':str(bin_dir)+os.pathsep+os.environ['PATH'],'SYNTHETIC_SUDO_CALLS':str(calls),'SYNTHETIC_STDOUT':stdout,'SYNTHETIC_STDERR':stderr,'SYNTHETIC_EXIT':str(exit_code)}
  before=fprobe.read_bytes();result=run(['bash','-c',vm_body],cwd=tmp,env=env);outputs=list(tmp.glob('slack-update-step294-observation.*'))
  check('exact controller body captures synthetic outcome: '+case,result.returncode==0 and len(outputs)==1 and calls.read_text().count('\n')==1 and json.loads(calls.read_text())==['bash','--',probe.name,design['cli_switch']])
  out=outputs[0]
  check('all three exact return files and explicit probe exit: '+case,set(p.name for p in out.iterdir())==set(effects['controller_capture_files']) and (out/'probe.stdout').read_text()==stdout and (out/'probe.stderr').read_text()==stderr and (out/'probe.exit-code').read_text()==str(exit_code)+'\n' and ret['exit_envelope_key']+'\t'+str(exit_code) in result.stdout and stderr==result.stderr)
  check('source unchanged and no retry in synthetic procedure: '+case,fprobe.read_bytes()==before and calls.read_text().count('\n')==1)
for case in ['missing','changed','symlink']:
 with tempfile.TemporaryDirectory(prefix='step294-precheck-') as directory:
  tmp=Path(directory);fprobe=tmp/probe.name
  if case=='changed':fprobe.write_bytes(probe.read_bytes()+b'\n')
  elif case=='symlink':target=tmp/'target';target.write_bytes(probe.read_bytes());fprobe.symlink_to(target)
  bin_dir=tmp/'bin';bin_dir.mkdir();calls=tmp/'unexpected-sudo';stub=bin_dir/'sudo';stub.write_text('#!/bin/bash\nprintf unexpected > "$SYNTHETIC_SUDO_CALLS"\nexit 99\n');stub.chmod(0o755)
  env=os.environ|{'PATH':str(bin_dir)+os.pathsep+os.environ['PATH'],'SYNTHETIC_SUDO_CALLS':str(calls)};result=run(['bash','-c',vm_body],cwd=tmp,env=env)
  check('type/hash failure stops before sudo or capture creation: '+case,result.returncode!=0 and not calls.exists() and not list(tmp.glob('slack-update-step294-observation.*')))
rows=[line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines()];record=dict(rows)
check('strict unique real-tab authorization record',all(len(row)==2 and all(row) for row in rows) and len(rows)==len(record))
check('record confirms contingent one-invocation grant and no execution',record['step']=='294' and record['accepted_checkpoint_commit']=='c1482cb' and record['authorization_state']==contract['state'] and record['controller_release_issued']=='no' and record['probe_invocations_issued']=='0' and record['maximum_probe_invocations']=='1' and record['probe_sha256']==cp['sha256'] and record['probe_transported']==record['probe_observed_on_target']=='no')
check('record flags/next routes consistent',all(record[k]==('yes' if v else 'no') for k,v in policy['authorization'].items()) and record['next_stage']==policy['next_stage'] and record['failure_next_stage']==policy['failure_next_stage'])
for args,expected in [(['--help'],0),([],2),(['--bad'],2),(['--output-dir'],2),(['--output-dir',''],2),(['--help','extra'],2)]:check('strict authorization helper CLI '+repr(args),run(['bash',helper,*args]).returncode==expected)
with tempfile.TemporaryDirectory(prefix='step294-review-') as directory:
 tmp=Path(directory);out=tmp/'output';out.mkdir();source_before=probe.read_bytes();result=run(['bash',helper,'--output-dir',out])
 check('full accepted232 suite succeeds before authorization publication',result.returncode==0 and 'accepted_step293_revalidated\tPASS (232 passes, 0 failures)' in result.stdout)
 for suffix in ['-policy.json','.tsv','-authorization.json']:check('exact authorization publication '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
 check('helper reports no release/invocation/transport/live action','controller_release_issued\tno' in result.stdout and 'probe_invocations_issued\t0' in result.stdout and 'probe_transported\tno' in result.stdout and 'live_target_observation_performed\tno' in result.stdout)
 check('actual probe unchanged after acceptance',probe.read_bytes()==source_before)
 before={p.name:p.read_bytes() for p in out.iterdir()};check('duplicate rejected without overwrite',run(['bash',helper,'--output-dir',out]).returncode!=0 and {p.name:p.read_bytes() for p in out.iterdir()}==before)
 link=tmp/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',helper,'--output-dir',link]).returncode!=0)
 nested=out/'nested';nested.mkdir();check('symlink output ancestor rejected',run(['bash',helper,'--output-dir',link/'nested']).returncode!=0 and not list(nested.iterdir()))
 check('missing output directory rejected',run(['bash',helper,'--output-dir',tmp/'missing']).returncode!=0 and not (tmp/'missing').exists())
 replica=tmp/'replica';shutil.copytree(root,replica,ignore=shutil.ignore_patterns('.git'));rh=replica/helper.relative_to(root);rejected=tmp/'rejected';rejected.mkdir()
 for rel in list(critical)+[k for k in own_hashes if k!=helper.relative_to(root).as_posix()]+['README.md','data/config/slack-update.conf']:
  p=replica/rel;old=p.read_bytes();p.write_bytes(old+b'\n');result=run(['bash',rh,'--output-dir',rejected]);check('accepted/authorization byte drift rejected before publication: '+p.name,result.returncode!=0 and not list(rejected.iterdir()));p.write_bytes(old)
 p=replica/'CHANGELOG.md';old=p.read_bytes();p.write_bytes(old.replace(b'## Phase 1 step 293 ',b'## Phase 1 step 999 ',1));result=run(['bash',rh,'--output-dir',rejected]);check('changed accepted CHANGELOG history rejected',result.returncode!=0 and not list(rejected.iterdir()));p.write_bytes(old)
 for section,key,value in [('authorization','builder_execution_authorized',True),('authorization','new_probe_execution_authorized',False),('fresh_boundary','current_boot_id','bcfac4fa-4e6e-450a-aa95-bd591a979b4e'),('observation_authorization','state','released'),('observation_authorization','vm_command_block',vm+vm),('implementation','probe_sha256','0'*64),('design','production_expected_uid_gid','1000:1000')]:
  p=replica/policy_path.relative_to(root);old=p.read_bytes();bad=json.loads(old);bad[section][key]=value;p.write_text(json.dumps(bad)+'\n');result=run(['bash',rh,'--output-dir',rejected]);check('scope/release/command/binding drift rejected: '+key,result.returncode!=0 and not list(rejected.iterdir()));p.write_bytes(old)
check('repository acceptance never issues target invocation',not contract['repository_acceptance_gate']['controller_release_issued'] and contract['attempt']['invocations_issued']==0 and digest(probe)==cp['sha256'])
for rel in list(own_hashes)+['tests/reference/test-'+base+'-harness.sh']:check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
changelog=(root/'CHANGELOG.md').read_text();check('CHANGELOG confirms accepted freeze and conditional grant','## Phase 1 step 294 ' in changelog and 'c1482cb' in changelog and 'controller release' in changelog and '## Phase 1 step 293 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
