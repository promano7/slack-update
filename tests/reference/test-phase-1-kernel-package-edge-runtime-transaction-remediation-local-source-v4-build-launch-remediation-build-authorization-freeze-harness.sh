#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import copy,hashlib,json,re,shutil,subprocess,sys,tempfile
root=Path(sys.argv[1])
base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-authorization-freeze'
prior='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-revalidation-freeze-and-build-authorization-review'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
helper=root/'tools/reference'/(base+'.sh')
policy=json.loads((fixture/(base+'-policy.json')).read_text())
previous=json.loads((fixture/(prior+'-policy.json')).read_text())
own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-authorization-freeze.md': '89c0ba1418f3bc6df7c5b9a60b64634aacea34a2a036a38f77045de6fbfadb2c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-authorization-freeze-policy.json': 'f986e83287281f80ebf160680e1673b3bd03c17f74db2a2c9a90adc135554b5d', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-authorization-freeze.tsv': '224b0fbec5f2fe5023d47a35b21b46dc277533270d7c018e95b165920268ab3c', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-authorization-freeze.sh': 'f2820a8897f70dc218d0248576d4dd0f970f8f2a77ba5a1c1afd3305fb5a4c09'}
passes=0
def check(label,value):
    global passes
    if not value:raise SystemExit('FAIL: '+label)
    passes+=1
    print('PASS: '+label)
def run(args,env=None):return subprocess.run([str(x) for x in args],capture_output=True,text=True,env=env)
for rel,digest in (own_hashes|policy['accepted_checkpoint']['sha256_bindings']).items():
    p=root/rel
    check('artifact binding: '+p.name,p.is_file() and not p.is_symlink() and hashlib.sha256(p.read_bytes()).hexdigest()==digest)
for p in [helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:
    check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
a=policy['accepted_checkpoint'];o=policy['accepted_observation'];s=policy['single_build_authorization'];c=policy['controller_protocol']
check('step identity and frozen result',policy['schema']==1 and policy['scenario']==base and policy['step']==278 and policy['review_status']=='PASS' and not policy['review_only'])
check('accepted step277 full identity and acceptance',a['step']==277 and a['commit']=='d19a209' and a['commit_full']=='d19a209126623ba1cab591bf8c9972a0dba6d65d' and a['acceptance_result']=='PASS (112 passes, 0 failures)')
check('predecessor opens this freeze only',previous['next_stage']==base and [k for k,v in previous['authorization'].items() if v]==['repository_only_build_authorization_freeze_authorized'])
check('complete accepted observation preserved',o==previous['accepted_observation'])
check('consumed observation authority stays revoked',o['probe_authority_consumed'] and not o['probe_rerun_authorized'] and o['state']=='fresh-read-only-observation-accepted-frozen-authority-consumed')
check('complete frozen implementation preserved',policy['frozen_implementation']==previous['frozen_implementation'])
check('historical preservation contract unchanged',policy['preservation']==previous['preservation'])
check('new build authority is granted',s['new_authority_granted'] and s['state']=='single-build-contract-frozen-and-authorized')
expected=copy.deepcopy(previous['future_authorization'])
expected.update(state='single-build-contract-frozen-and-authorized',new_authority_granted=True)
check('only two reviewed contract fields transition',s==expected)
check('one attempt even if preflight fails',s['attempt_limit']==1 and s['authority_consumed_on_attempt_even_on_failure'] and c['consume_authority_on_executor_invocation_even_preflight_failure'])
check('failure or interruption consumes authority',c['consume_authority_on_builder_failure_or_interruption'])
check('no automatic manual or failure retry',s['no_retry_after_failure'] and c['enforcement']=='controller-one-attempt-authorization-protocol-no-automatic-or-manual-retry')
check('exact fresh boot argument preserved',s['authorization_boot_id']==o['values']['fresh_boot_id']=='79a19518-0d0a-4c57-ac1f-679a39edefbd' and s['execution_argv']==['--execute-authorized-local-source-v4-build-v2','--authorization-boot-id',o['values']['fresh_boot_id']])
check('boot drift cannot change accepted argument',c['do_not_replace_boot_argument_after_drift'])
check('executor and builder identities unchanged',s['executor_sha256']==policy['frozen_implementation']['executor_sha256']=='43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d' and s['builder_sha256']==policy['frozen_implementation']['builder_sha256']=='38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7')
check('transport permits exactly immutable pair',s['transport_artifact_paths']==[s['executor_path'],s['builder_path']] and c['transport_exact_artifacts_together'])
check('transport regular files SHA and no executable-bit dependency',c['transported_files_must_be_regular_non_symlink'] and c['transported_sha256_verification_required_before_invocation'] and not c['transported_builder_executable_bit_required'])
check('commit and clean tree required before transport',c['accepted_step278_commit_and_clean_tree_required_before_transport'])
check('transport or SHA failure halts for review',c['halt_transport_or_hash_failure_for_repository_review'])
check('complete stdout stderr exit status required',c['complete_stdout_stderr_and_exit_status_required_for_review'])
check('immediate full preflight and fail closed drift',s['full_preflight_immediately_before_launch'] and s['reject_drift_before_launch'])
check('no old executor manual builder or chmod',s['execute_only_through_new_executor'] and s['no_manual_builder_execution'] and not s['chmod_remediation_allowed'] and not s['old_executor_or_authorization_reuse_allowed'] and not c['manual_chmod_or_cleanup_remediation_allowed'])
check('outputs bounded to reviewed v4 root and manifest pair',s['permitted_output_paths']==previous['future_authorization']['permitted_output_paths'] and len(s['permitted_output_paths'])==3)
check('temporary writes and cleanup retain reviewed builder scope',s['temporary_creation_scope']=='builder-owned-.local-source-v4.build.*-with-existing-builder-cleanup-contract')
check('no new persistent attempt marker',not c['persistent_attempt_marker_added'] and not policy['frozen_implementation']['frozen_design']['persistent_attempt_marker_added'])
allowed={'builder_transport_authorized','builder_execution_authorized','local_source_v4_build_authorized','new_executor_transport_authorized','new_executor_execution_authorized'}
check('only exact pair transport and one production build authorized',{k for k,v in policy['authorization'].items() if v}==allowed)
check('probe execution transport and independent observation closed',not policy['authorization']['read_only_probe_execution_authorized'] and not policy['authorization']['read_only_probe_transport_authorized'] and not policy['authorization']['target_observation_authorized'])
check('historical executor and runtime reruns remain forbidden',not policy['authorization']['step267_executor_rerun_authorized'] and not policy['authorization']['runtime_executor_rerun_authorized'])
for key in ['package_action_authorized','slackpkg_mutation_authorized','network_access_authorized','persistent_configuration_change_authorized','boot_action_authorized','reboot_authorized','evidence_cleanup_authorized','phase_2_start_authorized','remediation_implementation_authorized','repository_only_build_authorization_freeze_authorized']:
    check('closed action: '+key,not policy['authorization'][key])
check('repository-only acceptance never enters production or host observation',not policy['production_main_entered'] and not policy['production_builder_entered'] and not policy['live_target_observation_performed'] and policy['evidence_scope']=='repository-only-authorization-freeze-no-live-observation-or-production-execution')
check('action pending with no premature safe pause',policy['machine_action_required'] and policy['controller_action_required'] and not policy['pause_safe'] and not policy['strong_safe_pause'])
check('success route agrees with reviewed contract',policy['next_stage']==s['success_route']==previous['future_authorization']['success_route'])
check('failure route agrees with reviewed contract',policy['failure_stage']==s['failure_route']==previous['future_authorization']['failure_route'])
check('both routes require result review before strong pause',c['success_or_failure_result_review_required_before_pause'] and c['closure_revokes_remaining_build_and_transport_authority'])
check('future runtime requires fresh authorization',c['future_runtime_work_requires_fresh_revalidation_and_new_authorization'])
# Test the immutable parser through its explicit sourced seam, never production main.
executor=root/s['executor_path']
parser='SLACK_UPDATE_V4_BUILD_LAUNCH_LIBRARY_ONLY=1 source -- "$1"; shift; parse_authorization_boot_id "$@"'
parsed=run(['bash','-c',parser,'parser-test',executor,*s['execution_argv']])
check('actual immutable parser accepts exact newly authorized argv',parsed.returncode==0 and parsed.stdout.strip()==s['authorization_boot_id'])
for label,args in [('old switch',['--execute-authorized-local-source-v4-build']),('missing boot',s['execution_argv'][:1]),('extra argument',s['execution_argv']+['extra']),('duplicate boot',s['execution_argv']+s['execution_argv'][1:]),('noncanonical UUID',[*s['execution_argv'][:2],s['authorization_boot_id'].upper()]),('shell syntax as data',[*s['execution_argv'][:2],'$(exit 0)'])]:
    r=run(['bash','-c',parser,'parser-test',executor,*args])
    check('actual parser rejects '+label,r.returncode==2 and 'authorization_consumed' not in r.stdout)
check('non-mutating help',run(['bash','--',helper,'--help']).returncode==0)
for args in [[],['--bogus'],['--help','extra'],['--output-dir'],['--output-dir','unused','extra']]:
    check('strict repository helper CLI '+repr(args),run(['bash','--',helper,*args]).returncode==2)
with tempfile.TemporaryDirectory(prefix='step278-repository-') as tmp:
    tmp=Path(tmp);out=tmp/'freeze output';out.mkdir()
    result=run(['bash','--',helper,'--output-dir',out])
    check('full 112-pass predecessor acceptance reruns',result.returncode==0 and 'accepted_predecessor_revalidated\tyes' in result.stdout)
    for suffix in ['-policy.json','.tsv']:
        check('exact freeze publication '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('published state distinguishes grant from execution','local_source_v4_build_authorized\tyes' in result.stdout and 'production_main_entered\tno' in result.stdout and 'strong_safe_pause\tno' in result.stdout)
    before={p.name:p.read_bytes() for p in out.iterdir()}
    check('existing output rejected unchanged',run(['bash','--',helper,'--output-dir',out]).returncode!=0 and {p.name:p.read_bytes() for p in out.iterdir()}==before)
    link=tmp/'output-link';link.symlink_to(out,target_is_directory=True)
    check('symlink output directory rejected',run(['bash','--',helper,'--output-dir',link]).returncode!=0)
    check('missing output directory rejected',run(['bash','--',helper,'--output-dir',tmp/'missing']).returncode!=0)
    badout=tmp/'dangling-output';badout.mkdir();(badout/(base+'.tsv')).symlink_to(tmp/'absent')
    check('dangling output record symlink rejects before publication',run(['bash','--',helper,'--output-dir',badout]).returncode!=0 and not (badout/(base+'-policy.json')).exists())
    replica=tmp/'replica';shutil.copytree(root,replica)
    reject=tmp/'rejected';reject.mkdir()
    def reject_changed(label,rel,transform=lambda data:data+b'\n'):
        target=replica/rel;original=target.read_bytes();target.write_bytes(transform(original))
        r=run(['bash','--',replica/'tools/reference'/(base+'.sh'),'--output-dir',reject])
        check(label,r.returncode!=0 and not list(reject.iterdir()))
        target.write_bytes(original)
    for rel in a['sha256_bindings']:
        reject_changed('changed accepted artifact rejected before publication: '+Path(rel).name,rel)
    for rel in own_hashes:
        if rel!=f'tools/reference/{base}.sh':
            reject_changed('changed frozen artifact rejected before publication: '+Path(rel).name,rel)
    def mutate_policy(key,value):
        def transform(data):
            changed=json.loads(data);changed['single_build_authorization'][key]=value
            return (json.dumps(changed,indent=2,sort_keys=True)+'\n').encode()
        return transform
    for key,value in [('attempt_limit',2),('authorization_boot_id','d34855ae-e039-4005-a842-1bef51082195'),('new_authority_granted',False),('no_retry_after_failure',False)]:
        reject_changed('altered authority rejected before publication: '+key,f'tests/fixtures/reference/acceptance/phase-1/{base}-policy.json',mutate_policy(key,value))
    for rel in [s['executor_path'],s['builder_path']]:
        target=replica/rel;original=target.read_bytes();target.unlink()
        r=run(['bash','--',replica/'tools/reference'/(base+'.sh'),'--output-dir',reject])
        check('missing transport artifact rejected: '+target.name,r.returncode!=0 and not list(reject.iterdir()))
        target.symlink_to(root/rel)
        r=run(['bash','--',replica/'tools/reference'/(base+'.sh'),'--output-dir',reject])
        check('symlink transport artifact rejected: '+target.name,r.returncode!=0 and not list(reject.iterdir()))
        target.unlink();target.write_bytes(original)
rows=[line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines()]
check('record strict real-tab unique fields',all(len(row)==2 and all(row) for row in rows) and len(rows)==len(dict(rows)))
record=dict(rows)
check('record matches identities grant and routes',record['step']=='278' and record['review_status']=='PASS' and record['accepted_checkpoint_commit']==a['commit'] and record['single_build_authorization_state']==s['state'] and record['attempt_limit']=='1' and record['authorization_boot_id']==s['authorization_boot_id'] and record['frozen_executor_sha256']==s['executor_sha256'] and record['frozen_builder_sha256']==s['builder_sha256'] and record['next_stage']==policy['next_stage'] and record['failure_stage']==policy['failure_stage'])
for key,value in policy['authorization'].items():check('record authority: '+key,record[key]==('yes' if value else 'no'))
for key in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause','production_main_entered','production_builder_entered','live_target_observation_performed']:
    check('record state: '+key,record[key]==('yes' if policy[key] else 'no'))
check('record consumes observation and forbids repeated execution',record['probe_authority_consumed']=='yes' and record['probe_rerun_authorized']=='no' and record['second_execution_authorized']=='no' and record['rerun_after_failure_authorized']=='no')
for rel in list(own_hashes)+['tests/reference/test-'+base+'-harness.sh']:
    check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
log=(root/'CHANGELOG.md').read_text()
check('CHANGELOG records pending action and result review','## Phase 1 step 278 ' in log and 'No VM build result or safe-pause outcome is claimed by this snapshot.' in log and '## Phase 1 step 277 ' in log)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
