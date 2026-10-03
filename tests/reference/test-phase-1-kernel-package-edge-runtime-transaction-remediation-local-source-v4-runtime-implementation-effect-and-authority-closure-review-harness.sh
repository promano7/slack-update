#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import ast,copy,hashlib,json,subprocess,sys,tempfile
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-effect-and-authority-closure-review';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-implementation-freeze';own={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-effect-and-authority-closure-review.md': 'de1f8c80c1a3844be20cfbe666f5efc4db3515d35f916fcbdb91087d8de6da19', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-effect-and-authority-closure-review-policy.json': '7564a289e6ee63762e13ac7dc95eed23aa17a196ba6307c2594a0ae6c514a891', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-effect-and-authority-closure-review-review.json': '1cb2ab29be2354c11e7dd595531124dbc3bc1d206bb27f22fdd510c7594f8c55', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-effect-and-authority-closure-review-step306-user-acceptance.json': '2cc194a2f4df88da7e038f1c9b16a380a75edf24315689900946634df4382126', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-effect-and-authority-closure-review.tsv': 'fc8bf6890f68fe10f51b0523faead6b9461f37fab84a48008ebb06d21b79533e', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-effect-and-authority-closure-review.sh': '949d30fb12726fe84bacb3a3bc234b3e0255de652747156f35a70e6a23faa05d'};fixture=root/'tests/fixtures/reference/acceptance/phase-1';helper=root/'tools/reference'/(base+'.sh');passes=0
policy=json.loads((fixture/(base+'-policy.json')).read_text());accepted=policy['accepted_checkpoint'];review=json.loads((root/policy['review_path']).read_text());private_freeze=json.loads((root/policy['private_freeze_path']).read_text());previous=json.loads((fixture/(prior+'-policy.json')).read_text())
def check(label,ok):
 global passes
 if not ok:raise SystemExit('FAIL: '+label)
 passes+=1;print('PASS: '+label,flush=True)
def run(args):return subprocess.run([str(x) for x in args],capture_output=True,text=True)
def accepted_data(rel):
 data=(root/rel).read_bytes()
 return data[-accepted['changelog_size_bytes']:] if rel=='CHANGELOG.md' else data
def history_valid():
 return len(accepted['sha256_bindings'])==1337 and all((root/p).is_file() and not (root/p).is_symlink() and (root/p).resolve()==(root/p).absolute() and hashlib.sha256(accepted_data(p)).hexdigest()==d for p,d in accepted['sha256_bindings'].items())
check('all1337 exact accepted artifacts and historical CHANGELOG suffix',history_valid())
for rel,digest in own.items():
 p=root/rel;check('exact effect-authority review input: '+p.name,p.is_file() and not p.is_symlink() and p.resolve()==p.absolute() and hashlib.sha256(p.read_bytes()).hexdigest()==digest)
for p in [helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
text=helper.read_text().split("<<'PYFREEZE'\n",1)[1].rsplit('\nPYFREEZE',1)[0];names=['validate_closure_review','derive_effect_ledger','validate_freeze_policy','validate_user_receipt'];nodes=[n for n in ast.parse(text).body if isinstance(n,ast.FunctionDef) and n.name in names]
check('pure review ledger policy receipt seams without top-level execution',sorted(n.name for n in nodes)==sorted(names));scope={'json':json,'hashlib':hashlib};exec(compile(ast.fix_missing_locations(ast.Module(body=nodes,type_ignores=[])),'<pure-effect-authority-review>','exec'),scope);validate=scope[names[0]];derive=scope[names[1]];validate_policy=scope[names[2]];validate_receipt=scope[names[3]];digest=hashlib.sha256((root/policy['private_freeze_path']).read_bytes()).hexdigest()
check('complete repository effect-authority review accepted',validate(review,private_freeze,digest) is True);check('conditional-final-closure-only policy accepted',validate_policy(policy) is True)
receipt=json.loads((root/accepted['evidence_path']).read_text());check('complete232 receipt with SSH retry and separate clean status accepted',validate_receipt(receipt,accepted) is True)
check('confirmed306 prefix only no invented full commit',accepted['step']==306 and accepted['commit_prefix']=='51d3641' and accepted['commit_full'] is None and accepted['acceptance_result']=='PASS (232 passes, 0 failures)' and all(accepted[k] is True for k in ['user_application_completed','user_commit_and_push_completed','user_worktree_clean']))
check('transport retry no runtime retry and exact original evidence',accepted['push_first_attempt_failed'] is True and accepted['push_retry_succeeded'] is True and accepted['push_failure_scope']=='SSH-transport-only-not-executor-runtime-retry' and len(receipt['text'].encode())==23025 and hashlib.sha256(receipt['text'].encode()).hexdigest()==accepted['evidence_sha256']==receipt['original_display_sha256'])
check('confirmed306 without rewriting prepared historical policy',previous['user_step306_checkpoint_confirmed'] is False and policy['accepted306_prepared_confirmation_satisfied'] is True and private_freeze['implementation_frozen'] is True)
policies={row['step']:(row['policy_path'],json.loads((root/row['policy_path']).read_text())) for row in review['repository_effect_ledger']['rows']};changelog=accepted_data('CHANGELOG.md');ledger=derive(policies,accepted,accepted['sha256_bindings'],changelog)
check('derived eight-step effect ledger equals reviewed ledger',json.dumps(ledger,sort_keys=True)==json.dumps(review['repository_effect_ledger'],sort_keys=True))
check('confirmed block1274 to1337 with exactly63 additive artifacts',ledger['baseline_repository_file_count']==1274 and ledger['accepted_repository_file_count']==1337 and ledger['new_repository_artifact_count']==63 and len(ledger['new_artifact_sha256_bindings'])==63)
for row in ledger['rows']:
 check('accepted effect row exact inventory and no live rights: '+str(row['step']),row['new_repository_artifact_count']=={299:8,300:7,301:7,302:7,303:7,304:10,305:10,306:7}[row['step']] and row['repository_file_count_after']-row['repository_file_count_before']==row['new_repository_artifact_count'] and row['changed_existing_repository_paths']==['CHANGELOG.md'] and row['operational_rights_granted'] is False)
 check('stage-right disposition confirmed or pending correctly: '+str(row['step']),row['next_repository_checkpoint_confirmed']==(row['step']<306) and row['stage_right_disposition']==('consumed-by-confirmed-next-repository-checkpoint' if row['step']<306 else 'used-for-prepared307-review-user307-consumption-checkpoint-pending'))
for key,count in [('reviewed_freeze_artifact_sha256_bindings',6),('candidate_sha256_bindings',3),('predecessor_candidate_sha256_bindings',3),('supporting_artifact_sha256_bindings',7)]:check('exact accepted identity set: '+key,len(review[key])==count and all(accepted['sha256_bindings'][p]==d for p,d in review[key].items()))
for key in ['frozen_function_order','frozen_stage_order','frozen_implementation_specification','mandatory_tests','private_coverage','coverage_complete_scope','implementation_freeze_scope','unresolved_operational_components','operational_bindings']:check('private frozen scope carried exactly: '+key,review[key]==private_freeze[key])
check('operational entry and conformance remain closed',all(review[k] is False for k in ['operational_implementation_complete','operational_readiness','operational_conformance','production_backend_implemented','actual_reference_payload_executed']) and review['production_entry_closed'] is True and review['operational_executor_sha256'] is None)
obligations=review['obligations_review'];deferred=obligations['deferred_operational_capabilities']
check('no new real attempt or partial publication in repository scope',obligations['scope']=='repository-delivery-and-owned-private-fixtures-not-current-host-observation' and all(obligations[k] is False for k in ['new_real_transaction_started_in_block','new_real_partial_publication_started_in_block','required_repository_delivery_machine_cleanup','required_repository_delivery_controller_cleanup']))
check('seven deferred closed capabilities retained with no resolution claim',[r['component'] for r in deferred]==private_freeze['unresolved_operational_components'] and all(r['resolution_evidence'] is None and r['must_resolve_before_operational_use'] is True and all(r[k] is False for k in ['current_authority','current_machine_action_required','current_controller_action_required','blocks_repository_only_pause']) for r in deferred))
check('private failure obligations never live cleanup rights',obligations['private_failure_obligation_states']=='synthetic-test-outcomes-only-not-live-target-cleanup-or-rollback-authority' and obligations['live_target_pending_obligations']=='not-observed-no-new-real-attempt-in-this-repository-only-block')
check('strong-pause conditions assessed but final308 remains pending',set(review['strong_pause_condition_review'])==set(policy['strong_pause_completion_conditions']) and all(row['required'] is True and 'pending' in row['state'] for row in review['strong_pause_condition_review'].values()) and review['authority_review']['final_closure_complete'] is False and review['not_based_on_preflight_alone'] is True)
check('only repository final closure308 after complete user307',[k for k,v in policy['authorization'].items() if v]==['repository_only_runtime_implementation_closure_and_strong_pause_authorized'] and policy['next_stage']==policy['roadmap']['preferred_steps'][9]['stage'] and policy['user_step307_checkpoint_confirmed'] is False)
check('roadmap preservation completion requirements current state exact',all(policy[k]==previous[k] for k in ['roadmap','preservation','strong_pause_completion_conditions','current_state']))
check('no premature pause phase completion or Phase2',policy['historical_step298_strong_pause_remains_valid'] is True and all(review[k] is False for k in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause','phase1_matrix_complete','kernel_package_edge_complete','phase2_open']) and policy['final_closure_complete'] is False)
def rejected(fn,args):
 try:fn(*args)
 except (ValueError,TypeError,KeyError,IndexError):return True
 return False
def alternative(value):
 if value is None:return 'unreviewed-binding'
 if type(value) is bool:return int(value)
 if type(value) is int:return True
 if isinstance(value,str):return value+'-drift'
 if isinstance(value,list):return [] if value else ['unreviewed']
 if isinstance(value,dict):return {}
 raise TypeError(value)
for key,val in review.items():
 bad=copy.deepcopy(review);bad[key]=alternative(val);check('review rejects changed typed field: '+key,rejected(validate,[bad,private_freeze,digest]))
for key,val in review['authority_review'].items():
 bad=copy.deepcopy(review);bad['authority_review'][key]=alternative(val);check('review rejects widened or premature authority: '+key,rejected(validate,[bad,private_freeze,digest]))
for key in review['frozen_implementation_specification']:
 bad=copy.deepcopy(review);bad['frozen_implementation_specification'][key]={};check('review rejects weakened frozen specification: '+key,rejected(validate,[bad,private_freeze,digest]))
for key in policy['authorization']:
 bad=copy.deepcopy(policy);bad['authorization'][key]=not bad['authorization'][key];check('policy rejects authority toggle: '+key,rejected(validate_policy,[bad]))
for key in ['accepted_checkpoint','schema','step','implementation_freeze_scope','production_entry_closed','operational_readiness','operational_conformance','operational_executor_sha256','user_step307_checkpoint_confirmed','pause_safe','strong_safe_pause','final_closure_complete','next_stage']:
 bad=copy.deepcopy(policy);bad[key]=alternative(bad[key]);check('policy rejects changed typed field: '+key,rejected(validate_policy,[bad]))
check('review rejects same semantic freeze with altered raw SHA',rejected(validate,[review,private_freeze,'0'*64]))
for key in ['candidate_sha256_bindings','coverage_complete_scope','mandatory_tests','operational_bindings','implementation_freeze_scope','production_entry_closed']:
 bad=copy.deepcopy(private_freeze);bad[key]=alternative(bad[key]);check('review rejects changed accepted private freeze: '+key,rejected(validate,[review,bad,digest]))
def bad_policy(step,path,value,label):
 bad=copy.deepcopy(policies);p=bad[step][1]
 for k in path[:-1]:p=p[k]
 p[path[-1]]=value;check('derived ledger rejects '+label,rejected(derive,[bad,accepted,accepted['sha256_bindings'],changelog]))
bad_policy(301,['accepted_checkpoint','commit_full'],'20599ff'+'0'*33,'invented full commit')
bad_policy(302,['accepted_checkpoint','user_worktree_clean'],False,'dirty historical checkpoint')
bad_policy(303,['accepted_checkpoint','repository_file_count'],1304,'incorrect inventory count')
bad_policy(304,['accepted_checkpoint','acceptance_result'],'PASS','incomplete historical acceptance')
bad_policy(305,['accepted_checkpoint','sha256_bindings','README.md'],'0'*64,'rewritten accepted bytes')
bad_policy(300,['authorization','package_action_authorized'],True,'package authority')
bad_policy(301,['authorization','phase_2_start_authorized'],True,'Phase2 authority')
bad_policy(303,['scenario'],'skipped-stage','stage-chain discontinuity')
bad_policy(304,['accepted_checkpoint','step'],302,'checkpoint discontinuity')
bad_policy(306,['accepted_checkpoint','changelog_size_bytes'],1,'historical CHANGELOG mismatch')
bad=copy.deepcopy(policies);del bad[300];check('derived ledger rejects missing lineage step',rejected(derive,[bad,accepted,accepted['sha256_bindings'],changelog]))
bad=copy.deepcopy(accepted['sha256_bindings']);bad[policy['candidate_executor_path']]='0'*64;check('derived ledger rejects latest candidate divergence',rejected(derive,[policies,accepted,bad,changelog]))
check('derived ledger rejects changed historical CHANGELOG',rejected(derive,[policies,accepted,accepted['sha256_bindings'],changelog+b'\n']))
for old,new,label in [('Result: PASS (232 passes, 0 failures)','Result: PASS (231 passes, 0 failures)','incomplete acceptance'),('   024c820..51d3641  main -> main','missing-push','missing successful push'),('git log -1 --oneline\n51d3641','git log -1 --oneline\n M README.md\n51d3641','nonempty short status'),('origin/main, origin/HEAD','origin/stale, origin/HEAD','mismatched remote HEAD'),('fatal: No se pudo leer del repositorio remoto.','hidden SSH failure','erased original failure'),(':( $ git push',':( $ echo skip','missing explicit retry')]:
 bad=copy.deepcopy(receipt);bad['text']=bad['text'].replace(old,new);encoded=bad['text'].encode();bad['original_display_sha256']=hashlib.sha256(encoded).hexdigest();bad['original_display_size_bytes']=len(encoded);badaccepted=copy.deepcopy(accepted);badaccepted['evidence_sha256']=bad['original_display_sha256'];check('receipt rejects '+label,rejected(validate_receipt,[bad,badaccepted]))
rows=(fixture/(base+'.tsv')).read_text().splitlines();check('strict unique real-tab review record',all(l.count('\t')==1 for l in rows) and len({l.split('\t')[0] for l in rows})==len(rows) and dict(l.split('\t') for l in rows)=={'step': '307', 'review_status': 'PASS', 'accepted_checkpoint_commit': '51d3641', 'accepted_checkpoint_acceptance': 'PASS (232 passes, 0 failures)', 'push_retry_succeeded': 'yes', 'confirmed_block_new_artifacts': '63', 'accepted_repository_file_count': '1337', 'final_closure_complete': 'no', 'production_entry_closed': 'yes', 'operational_readiness': 'no', 'operational_conformance': 'no', 'operational_executor_sha256': 'null', 'runtime_attempt_authorized': 'no', 'machine_action_required': 'no', 'controller_action_required': 'no', 'pause_safe': 'no', 'strong_safe_pause': 'no', 'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-closure-and-strong-safe-pause', 'boot_action_authorized': 'no', 'boot_argument_substitution_authorized': 'no', 'builder_execution_authorized': 'no', 'builder_transport_authorized': 'no', 'chmod_remediation_authorized': 'no', 'evidence_cleanup_authorized': 'no', 'historical_probe_rerun_authorized': 'no', 'immutable_builder_modification_authorized': 'no', 'immutable_executor_modification_authorized': 'no', 'local_source_v4_build_authorized': 'no', 'manual_builder_execution_authorized': 'no', 'network_access_authorized': 'no', 'new_executor_execution_authorized': 'no', 'new_executor_transport_authorized': 'no', 'new_probe_execution_authorized': 'no', 'new_probe_implementation_authorized': 'no', 'new_probe_transport_authorized': 'no', 'package_action_authorized': 'no', 'persistent_configuration_change_authorized': 'no', 'phase_2_start_authorized': 'no', 'read_only_probe_execution_authorized': 'no', 'read_only_probe_transport_authorized': 'no', 'reboot_authorized': 'no', 'remediation_implementation_authorized': 'no', 'repository_only_authority_effect_closure_and_strong_pause_review_authorized': 'no', 'repository_only_build_authorization_freeze_authorized': 'no', 'repository_only_fresh_revalidation_authorization_review_authorized': 'no', 'repository_only_resume_planning_boundary_review_authorized': 'no', 'repository_only_revalidation_design_freeze_authorized': 'no', 'repository_only_revalidation_design_review_authorized': 'no', 'repository_only_revalidation_probe_implementation_freeze_authorized': 'no', 'repository_only_revalidation_probe_implementation_review_authorized': 'no', 'repository_only_revalidation_result_review_authorized': 'no', 'repository_only_runtime_boundary_freeze_authorized': 'no', 'repository_only_runtime_boundary_review_authorized': 'no', 'repository_only_runtime_executor_design_freeze_authorized': 'no', 'repository_only_runtime_executor_design_review_authorized': 'no', 'repository_only_runtime_executor_implementation_failure_coverage_authorized': 'no', 'repository_only_runtime_executor_implementation_freeze_authorized': 'no', 'repository_only_runtime_executor_implementation_review_authorized': 'no', 'repository_only_runtime_implementation_effect_and_authority_closure_review_authorized': 'no', 'repository_only_transaction_contract_freeze_authorized': 'no', 'repository_only_transaction_contract_review_authorized': 'no', 'runtime_executor_rerun_authorized': 'no', 'slackpkg_mutation_authorized': 'no', 'step267_executor_rerun_authorized': 'no', 'target_observation_authorized': 'no', 'repository_only_runtime_implementation_closure_and_strong_pause_authorized': 'yes'})
with tempfile.TemporaryDirectory(prefix='step307-harness-') as directory:
 tmp=Path(directory)
 for args,success in [([],False),(['--help'],True),(['--bogus'],False),(['--output-dir'],False),(['--output-dir',''],False),(['--output-dir','x','extra'],False)]:check('strict review CLI '+repr(args),(run(['bash',helper,*args]).returncode==0)==success)
 out=tmp/'published';out.mkdir();call=run(['bash',helper,'--output-dir',out]);
 if call.returncode:print(call.stdout+call.stderr,flush=True)
 check('full232 exact historical acceptance recursively including420/285 before review publication',call.returncode==0 and 'accepted_step306_revalidated\tPASS (232 passes, 0 failures)' in call.stdout)
 for suffix in ['-policy.json','-review.json','-step306-user-acceptance.json','.tsv']:
  p=out/(base+suffix);check('exact review publication '+suffix,p.is_file() and p.read_bytes()==(fixture/p.name).read_bytes())
 before={p.name:p.read_bytes() for p in out.iterdir()};check('republication rejects without overwrite',run(['bash',helper,'--output-dir',out]).returncode!=0 and {p.name:p.read_bytes() for p in out.iterdir()}==before)
 link=tmp/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejects',run(['bash',helper,'--output-dir',link]).returncode!=0)
 alias=tmp/'ancestor';alias.symlink_to(tmp,target_is_directory=True);check('symlink output ancestor rejects',run(['bash',helper,'--output-dir',alias/'published']).returncode!=0)
 check('missing output rejects without creation',run(['bash',helper,'--output-dir',tmp/'missing']).returncode!=0 and not (tmp/'missing').exists())
 replica=tmp/'replica'
 for rel in list(accepted['sha256_bindings'])+list(own)+['tests/reference/test-'+base+'-harness.sh']:
  p=replica/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes((root/rel).read_bytes())
 rh=replica/helper.relative_to(root);rejected_out=tmp/'rejected';rejected_out.mkdir()
 targets=list(dict.fromkeys(['CHANGELOG.md']+list(review['reviewed_freeze_artifact_sha256_bindings'])+list(review['candidate_sha256_bindings'])+list(review['predecessor_candidate_sha256_bindings'])+list(review['supporting_artifact_sha256_bindings'])+[r['policy_path'] for r in ledger['rows']]+[rel for rel in own if rel!=helper.relative_to(root).as_posix()]))
 for rel in targets:
  p=replica/rel;data=p.read_bytes();p.write_bytes(data+b'\n');check('changed bound input rejects before publication: '+p.name,run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(data)
 for rel in [policy['private_freeze_path'],policy['candidate_executor_path']]:
  p=replica/rel;data=p.read_bytes();p.unlink();p.symlink_to(root/rel);check('same-content symlink rejects: '+p.name,run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and not list(rejected_out.iterdir()));p.unlink();p.write_bytes(data)
 for suffix in ['-policy.json','-review.json','-step306-user-acceptance.json','.tsv']:
  p=rejected_out/(base+suffix);p.write_bytes(b'preserved output\n');check('occupied publication rejects: '+suffix,run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and p.read_bytes()==b'preserved output\n' and len(list(rejected_out.iterdir()))==1);p.unlink()
check('all accepted history and candidate bytes preserved by tests',history_valid())
for rel in list(own)+['tests/reference/test-'+base+'-harness.sh']:check('no trailing whitespace: '+Path(rel).name,all(l==l.rstrip() for l in (root/rel).read_text().splitlines()))
check('CHANGELOG confirms306 prepares307 without final pause','## Phase 1 step307 ' in (root/'CHANGELOG.md').read_text() and '51d3641' in (root/'CHANGELOG.md').read_text() and 'pause_safe=false/strong_safe_pause=false' in (root/'CHANGELOG.md').read_text())
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
