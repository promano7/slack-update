#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import hashlib,json,re,shutil,subprocess,sys,tempfile
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-authorization-freeze'
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
helper=root/'tools/reference'/(base+'.sh')
policy=json.loads((fixture/(base+'-policy.json')).read_text())
previous=json.loads((fixture/(prior+'-policy.json')).read_text())
own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review.md': '7b797ef64b2115cc83d54344c6b2f2bc2abf5190aca8b9eb99680a298c02fd37', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review-policy.json': '608b26984130bb05bb74cc98489ca000a85db62084d20d0f9c1464a96c2caa9f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review.tsv': '26213a1611d9a96d9925dca04ce7be98706e07111f16138b55bd998e434d30d6', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review-observation.tsv': 'f6798e57d68940fa41c425a7b74d0d7598ff5e8835a614fe9d8642d7435bdfe6', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review.sh': 'c2274e43a22eca69454391750cc87ad43114a5462269e73d49f8253606e80010'}
passes=0
def check(label,value):
    global passes
    if not value:raise SystemExit('FAIL: '+label)
    passes+=1;print('PASS: '+label)
def run(args):return subprocess.run([str(x) for x in args],capture_output=True,text=True)
for rel,digest in (own_hashes|policy['accepted_checkpoint']['sha256_bindings']).items():
    p=root/rel;check('artifact binding: '+p.name,p.is_file() and not p.is_symlink() and hashlib.sha256(p.read_bytes()).hexdigest()==digest)
for path in [helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax: '+path.name,run(['bash','-n',path]).returncode==0)
a=policy['accepted_checkpoint'];r=policy['returned_attempt'];f=policy['failure_characterization'];e=policy['reviewed_effect_boundary'];c=policy['authorization_closure'];safe=policy['safe_pause']
check('stage identity and result-review PASS',policy['schema']==1 and policy['step']==279 and policy['scenario']==base and policy['review_status']=='PASS')
check('accepted user commit and complete137 acceptance',a['step']==278 and a['commit']=='b5782fd' and a['acceptance_result']=='PASS (137 passes, 0 failures)' and a['user_returned_application_commit_push_and_clean_tree'])
check('short commit prefix recorded without invented full SHA',a['commit_identity_scope']=='user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in a)
check('failure route matches consumed authorization',previous['failure_stage']==base)
check('immutable historical implementation preserved',policy['frozen_implementation']==previous['frozen_implementation'])
check('historical accepted observation unchanged',policy['historical_accepted_observation']==previous['accepted_observation'])
check('accepted historical execution contract unchanged',policy['accepted_execution_contract']==previous['single_build_authorization'])
check('exact one invocation recorded',r['invocation_count']==previous['single_build_authorization']['attempt_limit']==1 and r['state']=='preflight-rejected-before-builder-entry')
check('transport integrity verified in returned output',r['transported_executor_and_builder_sha_checks_passed'] and r['values']['executor_sha256_check']=='PASS' and r['values']['builder_sha256_check']=='PASS')
check('exact expected hashes retain controller provenance',r['values']['executor_sha256_expected_in_controller_command']==previous['single_build_authorization']['executor_sha256'] and r['values']['builder_sha256_expected_in_controller_command']==previous['single_build_authorization']['builder_sha256'])
check('complete semantic observation provenance','no-original-stdout-stderr-byte-identity-claim' in r['normalization'] and r['provenance']=='complete-user-returned-controller-command-and-output-2026-09-30')
obs=root/r['observation_path'];rows=[line.split('\t') for line in obs.read_text().splitlines()]
check('observation strict real-tab unique nonempty fields',all(len(row)==2 and all(row) for row in rows) and len(rows)==len(dict(rows))==r['field_count'])
check('observation matches frozen values and SHA',dict(rows)==r['values'] and hashlib.sha256(obs.read_bytes()).hexdigest()==r['normalized_observation_sha256'])
check('authorized boot bound to step278 contract',f['authorized_boot_id']==previous['single_build_authorization']['authorization_boot_id']==r['values']['authorization_boot_id_supplied']=='79a19518-0d0a-4c57-ac1f-679a39edefbd')
check('observed drift boot exactly returned',f['observed_boot_id']==r['values']['error_observed_boot_id']=='0b85f61f-21e8-4593-b473-043cb6a2beb7' and f['observed_boot_id']!=f['authorized_boot_id'])
for key in ['authorized_boot_id','observed_boot_id']:check('canonical '+key,re.fullmatch(r'[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}',f[key]) is not None)
check('terminal diagnostic and controller exit1 match',r['values']['executor_stderr']=='ERROR: authorization boot ID mismatch: '+f['observed_boot_id'] and r['values']['controller_observed_executor_exit_status']=='1' and f['executor_exit_status']==1)
check('exact new switch recorded',r['values']['executor_switch']=='--execute-authorized-local-source-v4-build-v2')
check('boot drift cause not inferred',r['boot_change_cause']=='not-determined-from-returned-output')
check('full preflight and builder not reached',not r['full_preflight_completed'] and not r['production_builder_entered'])
for key in ['preflight_PASS_line_present','authorized_builder_execution_starting_line_present','builder_build_PASS_line_present','executor_PASS_line_present']:check('returned output lacks '+key,r['values'][key]=='no')
check('failure class is preflight boot drift',f['class']=='fresh-authorization-boot-id-drift' and f['stage']=='executor-boot-identity-preflight-guard-before-builder-launch')
check('no builder or chmod fault falsely diagnosed',not f['builder_fault_claimed'] and not f['chmod_transport_fault_claimed'])
check('boot substitution and old binding forbidden',not f['new_boot_id_may_be_substituted_for_retry'] and not f['old_boot_binding_valid_for_future_machine_action'])
check('effects classified as source/output inference',e['evidence_kind']=='inference-from-exact-hash-bound-executor-control-flow-and-returned-terminal-error')
executor=root/previous['single_build_authorization']['executor_path'];source=executor.read_text()
main=source[source.index('\nmain() {\n')+1:source.index('\nif [[ ${SLACK_UPDATE_V4_BUILD_LAUNCH_LIBRARY_ONLY:')]
guard='    '+e['failed_guard_exact_source']+'\n'
check('exact unique rejected guard in immutable main',main.count(guard)==1 and guard.strip()=='[[ $boot_id == "$authorization_boot_id" ]] || fail "authorization boot ID mismatch: $boot_id"')
prefix=main[:main.index(guard)+len(guard)]
check('exact executed main prefix SHA',hashlib.sha256(prefix.encode()).hexdigest()==e['main_prefix_through_failed_guard_sha256'])
check('terminal fail body exact and exits1',e['fail_function_exact_source']==next(line for line in source.splitlines() if line.startswith('fail() {')) and e['fail_function_exact_source'].endswith('exit 1; }'))
check('boot guard before all mutation and success gates',all(main.index(guard)<main.index(token) for token in ['    verify_local_source_v3\n','    verify_failed_v2_evidence\n','    verify_v4_outputs_absent\n',"    printf 'v4_v2_authorized_build_preflight_status", "    printf 'authorized_builder_execution_starting",'    launch_verified_builder']))
check('no launch cleanup trap or output write in executed prefix',not re.search(r'(?m)^\s*(?:cp|mv|rm|mkdir|mktemp|chmod|chown|touch|trap|launch_verified_builder)\b',prefix) and 'bash -- ' not in prefix and not re.search(r'(?<![>&])>(?!&[12]|/dev/null)',prefix))
# Read-only called functions remain exactly covered by immutable executor SHA.
for name in e['early_execution_calls']:
    start=source.index('\n'+name+'() {')+1;end=source.find('\n}\n',start)
    if end==-1 or source[start:source.find('\n',start)].endswith(' }'):function=source[start:source.find('\n',start)]
    else:function=source[start:end+3]
    check('read-only prefix callee '+name,not re.search(r'(?m)^\s*(?:cp|mv|rm|mkdir|mktemp|chmod|chown|touch|trap|launch_verified_builder)\b',function) and '-delete' not in function and '>>' not in function)
for key in ['builder_launch_reached','builder_owned_temporary_creation_reached','executor_persistent_attempt_marker_exists','attempt_attributed_filesystem_writes','attempt_attributed_package_slackpkg_boot_network_mutation','deferred_transaction_or_cleanup_from_this_attempt','later_v3_failed_v2_boot_slackpkg_geninitrd_and_output_guards_reached']:
    check('reviewed effect boundary: '+key,e[key] is False)
check('no current output absence or full preservation overclaim',r['no_current_target_or_output_preservation_claim'] and not e['current_v4_output_absence_independently_observed'] and not e['current_v3_failed_v2_and_target_preservation_independently_observed'] and e['old_observation_is_historical_not_current'])
# Replay the exact guard with inert UUID variables through the immutable sourced fail function.
replay='SLACK_UPDATE_V4_BUILD_LAUNCH_LIBRARY_ONLY=1 source -- "$1"; authorization_boot_id=$2; boot_id=$3; '+e['failed_guard_exact_source']+'; printf "synthetic_after_boot_guard\\n"'
result=run(['bash','-c',replay,'guard-test',executor,f['authorized_boot_id'],f['observed_boot_id']])
check('actual terminal fail rejects changed UUID with exit1',result.returncode==1 and result.stderr.strip()==r['values']['executor_stderr'] and result.stdout=='')
match=run(['bash','-c',replay,'guard-test',executor,f['authorized_boot_id'],f['authorized_boot_id']])
check('synthetic unchanged UUID reaches sentinel only',match.returncode==0 and match.stdout=='synthetic_after_boot_guard\n' and not match.stderr)
check('matching synthetic guard is not a new live authorization',c['boot_argument_substitution_authorized'] is False and safe['future_machine_action_requires_new_explicit_authorization'])
for key in ['step278_build_authority_consumed','consumed_on_preflight_rejection','all_transport_build_probe_and_runtime_authority_revoked','step276_probe_authority_still_consumed','remaining_live_state_bindings_invalidated']:
    check('authority closure: '+key,c[key] is True)
for key in ['automatic_or_manual_retry_authorized','manual_builder_or_cleanup_authorized','boot_argument_substitution_authorized']:
    check('no retry workaround: '+key,c[key] is False)
check('only repository resume planning remains authorized',[k for k,v in policy['authorization'].items() if v]==['repository_only_resume_planning_boundary_review_authorized'])
check('historical operational flags all revoked',all(not policy['authorization'][k] for k in previous['authorization']))
for key in ['no_open_operational_authorization','no_required_machine_action','no_deferred_transaction_from_this_attempt','fresh_revalidation_required_before_any_future_machine_action','future_machine_action_requires_new_explicit_authorization','does_not_assert_current_output_absence_or_full_state_preservation']:
    check('strong-pause condition: '+key,safe[key] is True)
check('safe pause basis independent of live target refresh',safe['basis']=='reviewed-effect-free-pre-builder-rejection-and-complete-authority-revocation-independent-of-live-target-refresh')
check('strong pause and no required machine/controller action',policy['pause_safe'] and policy['strong_safe_pause'] and not policy['machine_action_required'] and not policy['controller_action_required'])
check('future stage is repository resume planning',policy['next_stage']=='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-resume-planning-boundary-review')
check('repository acceptance enters no production or live observation',policy['repository_acceptance_scope']=={'production_main_entered':False,'production_builder_entered':False,'live_target_observation_performed':False,'synthetic_guard_replay_only':True})
check('non-mutating help',run(['bash','--',helper,'--help']).returncode==0)
check('unknown option rejected',run(['bash','--',helper,'--bogus']).returncode==2)
with tempfile.TemporaryDirectory(prefix='step279-repository-') as d:
    tmp=Path(d);out=tmp/'review output';out.mkdir()
    result=run(['bash','--',helper,'--output-dir',out])
    check('complete137 predecessor acceptance reruns',result.returncode==0 and 'accepted_predecessor_revalidated\tyes' in result.stdout)
    for suffix in ['-policy.json','.tsv']:check('exact failed-result output '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
    check('closure publications explicit','all_operational_authority_revoked\tyes' in result.stdout and 'strong_safe_pause\tyes' in result.stdout and 'current_target_preservation_independently_observed\tno' in result.stdout)
    before={p.name:p.read_bytes() for p in out.iterdir()}
    check('existing outputs rejected unchanged',run(['bash','--',helper,'--output-dir',out]).returncode!=0 and {p.name:p.read_bytes() for p in out.iterdir()}==before)
    link=tmp/'output-link';link.symlink_to(out,target_is_directory=True)
    check('symlink output directory rejected',run(['bash','--',helper,'--output-dir',link]).returncode!=0)
    replica=tmp/'replica';shutil.copytree(root,replica);rejected=tmp/'rejected';rejected.mkdir()
    for rel in list(a['sha256_bindings'])+[k for k in own_hashes if k!=f'tools/reference/{base}.sh']:
        target=replica/rel;original=target.read_bytes();target.write_bytes(original+b'\n')
        rj=run(['bash','--',replica/'tools/reference'/(base+'.sh'),'--output-dir',rejected])
        check('changed artifact rejects before result publication: '+target.name,rj.returncode!=0 and not list(rejected.iterdir()))
        target.write_bytes(original)
    for category,key,value in [('authorization_closure','automatic_or_manual_retry_authorized',True),('reviewed_effect_boundary','current_v4_output_absence_independently_observed',True),('failure_characterization','observed_boot_id',f['authorized_boot_id'])]:
        target=replica/'tests/fixtures/reference/acceptance/phase-1'/(base+'-policy.json');original=target.read_bytes();bad=json.loads(original);bad[category][key]=value;target.write_text(json.dumps(bad)+'\n')
        rj=run(['bash','--',replica/'tools/reference'/(base+'.sh'),'--output-dir',rejected])
        check('changed closure or overclaim rejected: '+key,rj.returncode!=0 and not list(rejected.iterdir()))
        target.write_bytes(original)
record_rows=[line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines()]
check('record strict unique real-tab fields',all(len(row)==2 and all(row) for row in record_rows) and len(record_rows)==len(dict(record_rows)))
record=dict(record_rows)
check('record matches failure and boot identities',record['step']=='279' and record['review_status']=='PASS' and record['accepted_checkpoint_commit']=='b5782fd' and record['authorized_boot_id']==f['authorized_boot_id'] and record['observed_boot_id']==f['observed_boot_id'] and record['failure_class']==f['class'] and record['controller_observed_executor_exit_status']=='1')
check('record matches consumed single-attempt closure',record['invocation_count']=='1' and record['build_authority_consumed']=='yes' and record['all_operational_authority_revoked']=='yes' and record['retry_authorized']=='no' and record['probe_authority_consumed']=='yes')
check('record retains limitations',record['current_v4_output_absence_independently_observed']=='no' and record['current_full_state_preservation_independently_observed']=='no')
for key,value in policy['authorization'].items():check('record authority: '+key,record[key]==('yes' if value else 'no'))
for key in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']:
    check('record state: '+key,record[key]==('yes' if policy[key] else 'no'))
check('record next stage',record['next_stage']==policy['next_stage'])
for rel in list(own_hashes)+['tests/reference/test-'+base+'-harness.sh']:
    check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
log=(root/'CHANGELOG.md').read_text()
check('CHANGELOG records closure and stale-state limits','## Phase 1 step 279 ' in log and 'Current v4 output absence and full current v3/failed-v2/package/Slackpkg/boot/GenInitrd preservation are not independently observed or claimed' in log and '## Phase 1 step 278 ' in log)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
