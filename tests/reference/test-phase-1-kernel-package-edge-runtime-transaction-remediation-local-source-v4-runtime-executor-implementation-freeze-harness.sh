#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import ast,copy,hashlib,json,subprocess,sys,tempfile
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-implementation-freeze';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-review';own={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-implementation-freeze.md': '971b3ee1319b68d38b63531009b8e413b2ec2e47ea823064c9240b3d656801a1', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-implementation-freeze-freeze.json': '3b1c489d903fabe66e14acd43416eae075feb44923a1314a316e7a2c38997f41', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-implementation-freeze-policy.json': '746ac177f859e20253973fc045183f10373ef6f6e512bd7592148ead6084c7fb', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-implementation-freeze-step305-user-acceptance.json': 'f3d85c855d5cddfd6550d5b0830cd80cd641c3921e8f7cde334855d770c6612c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-implementation-freeze.tsv': '5c6837601791a5931e969dae53c86d9c9c8e93ec04ed0b0d6f872a159bdec675', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-implementation-freeze.sh': '0f8159abc9c8a5cafb956bfca05ae3cdd1963e7f6503293b006ac82b87a0bba0'};fixture=root/'tests/fixtures/reference/acceptance/phase-1';helper=root/'tools/reference'/(base+'.sh');passes=0
policy=json.loads((fixture/(base+'-policy.json')).read_text());accepted=policy['accepted_checkpoint'];freeze=json.loads((root/policy['freeze_path']).read_text());review=json.loads((root/policy['review_path']).read_text());previous=json.loads((fixture/(prior+'-policy.json')).read_text())
def check(label,ok):
 global passes
 if not ok:raise SystemExit('FAIL: '+label)
 passes+=1;print('PASS: '+label,flush=True)
def run(args):return subprocess.run([str(x) for x in args],capture_output=True,text=True)
def accepted_data(rel):
 p=root/rel;data=p.read_bytes()
 return data[-accepted['changelog_size_bytes']:] if rel=='CHANGELOG.md' else data
def history_valid():
 return len(accepted['sha256_bindings'])==1330 and all((root/p).is_file() and not (root/p).is_symlink() and (root/p).resolve()==(root/p).absolute() and hashlib.sha256(accepted_data(p)).hexdigest()==d for p,d in accepted['sha256_bindings'].items())
check('all1330 safe exact accepted artifacts and historical CHANGELOG suffix',history_valid())
for rel,digest in own.items():
 p=root/rel;check('exact private-freeze input: '+p.name,p.is_file() and not p.is_symlink() and p.resolve()==p.absolute() and hashlib.sha256(p.read_bytes()).hexdigest()==digest)
for p in [helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
text=helper.read_text().split("<<'PYFREEZE'\n",1)[1].rsplit('\nPYFREEZE',1)[0];names=['validate_private_freeze','validate_freeze_policy','validate_user_receipt'];nodes=[n for n in ast.parse(text).body if isinstance(n,ast.FunctionDef) and n.name in names]
check('pure freeze policy and receipt seams without top-level execution',sorted(n.name for n in nodes)==sorted(names));scope={'json':json,'hashlib':hashlib};exec(compile(ast.fix_missing_locations(ast.Module(body=nodes,type_ignores=[])),'<pure-private-freeze>','exec'),scope);validate=scope[names[0]];validate_policy=scope[names[1]];validate_receipt=scope[names[2]];digest=hashlib.sha256((root/policy['review_path']).read_bytes()).hexdigest()
check('exact closed private freeze accepted',validate(freeze,review,digest) is True);check('repository closure-only policy accepted',validate_policy(policy) is True)
receipt=json.loads((root/accepted['evidence_path']).read_text());check('complete420 receipt with SSH retry and separate clean status accepted',validate_receipt(receipt,accepted) is True)
check('confirmed305 prefix only no invented full commit',accepted['step']==305 and accepted['commit_prefix']=='024c820' and accepted['commit_full'] is None and accepted['acceptance_result']=='PASS (420 passes, 0 failures)' and all(accepted[k] is True for k in ['user_application_completed','user_commit_and_push_completed','user_worktree_clean']))
check('transport retry does not imply runtime retry',accepted['push_first_attempt_failed'] is True and accepted['push_retry_succeeded'] is True and accepted['push_failure_scope']=='SSH-transport-only-not-executor-runtime-retry' and freeze['runtime_attempt_planned'] is False)
check('prepared305 superseded by external confirmation without rewriting it',previous['user_step305_checkpoint_confirmed'] is False and policy['accepted305_prepared_confirmation_satisfied'] is True and review['implementation_frozen'] is False and freeze['implementation_frozen'] is True)
check('exact raw305 review SHA externally frozen',digest==freeze['reviewed_private_review_sha256']==accepted['sha256_bindings'][policy['review_path']])
for key,count in [('reviewed_artifact_sha256_bindings',6),('candidate_sha256_bindings',3),('predecessor_candidate_sha256_bindings',3),('supporting_artifact_sha256_bindings',7)]:
 check('exact bound identity set: '+key,len(freeze[key])==count and all(accepted['sha256_bindings'][p]==d for p,d in freeze[key].items()))
check('reviewed historical state stays immutable',review['state']=='closed-private-candidate-failure-coverage-reviewed-not-frozen' and freeze['reviewed_private_state_is_historical'] is True and freeze['freeze_status_external_to_immutable_review'] is True)
for key,value in freeze['frozen_implementation_specification'].items():check('exact frozen implementation section: '+key,value==review['frozen_implementation_specification'][key])
check('thirteen private functions and stage order unchanged',len(freeze['frozen_stage_order'])==13 and freeze['frozen_stage_order']==review['stage_order'] and freeze['frozen_function_order']==review['implemented_private_functions'])
check('mandatory private coverage names and executed coverage unchanged',freeze['mandatory_tests']==review['mandatory_tests'] and freeze['private_coverage']==review['coverage'] and freeze['coverage_complete'] is True and freeze['coverage_complete_scope']=='mandatory-private-synthetic-control-and-failure-tests-only')
check('closed repository-only freeze never operational conformance',policy['implementation_freeze_scope']==freeze['implementation_freeze_scope']=='exact-closed-repository-candidate-and-private-acceptance-only' and all(freeze[k] is False for k in ['operational_implementation_complete','operational_readiness','operational_conformance','production_backend_implemented','actual_reference_payload_executed']) and freeze['production_entry_closed'] is True and freeze['operational_executor_sha256'] is None)
check('seven unresolved operational components and null bindings unchanged',len(freeze['unresolved_operational_components'])==7 and freeze['unresolved_operational_components']==review['unresolved_operational_components'] and freeze['operational_bindings']==review['operational_bindings'] and all(v is None for k,v in freeze['operational_bindings'].items() if k!='resolution_required_in_later_design_revalidation_and_authorization'))
check('separate operational review fresh grant revalidation preflight required',freeze['operational_components_require_separate_review_before_use'] is True and freeze['separate_fresh_revalidation_grant_and_immediate_preflight_required'] is True and freeze['no_authority_from_candidate_hashes'] is True)
check('only repository closure307 after user306 checkpoint',[k for k,v in policy['authorization'].items() if v]==['repository_only_runtime_implementation_effect_and_authority_closure_review_authorized'] and policy['next_stage']==policy['roadmap']['preferred_steps'][8]['stage'] and policy['user_step306_checkpoint_confirmed'] is False)
check('roadmap preservation obligations current state unchanged',all(policy[k]==previous[k] for k in ['roadmap','preservation','strong_pause_completion_conditions','current_state']))
check('no premature pause Phase1 completion Phase2 or operational binding',policy['historical_step298_strong_pause_remains_valid'] is True and all(policy[k] is False for k in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']) and policy['current_state']['phase2_open'] is False and policy['current_state']['phase1_matrix_complete'] is False and policy['current_state']['kernel_package_edge_complete'] is False)
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
for key,val in freeze.items():
 bad=copy.deepcopy(freeze);bad[key]=alternative(val);check('freeze rejects changed typed field: '+key,rejected(validate,[bad,review,digest]))
for key in freeze['frozen_implementation_specification']:
 bad=copy.deepcopy(freeze);bad['frozen_implementation_specification'][key]={};check('freeze rejects weakened specification: '+key,rejected(validate,[bad,review,digest]))
for a,b in [(1,2),(3,4),(7,8),(10,12)]:
 bad=copy.deepcopy(freeze);bad['frozen_stage_order'][a],bad['frozen_stage_order'][b]=bad['frozen_stage_order'][b],bad['frozen_stage_order'][a];check('freeze rejects reordered stages '+str((a,b)),rejected(validate,[bad,review,digest]))
check('freeze rejects same semantic review with changed raw hash',rejected(validate,[freeze,review,'0'*64]))
for key in ['candidate_sha256_bindings','mandatory_tests','coverage_complete_scope','unresolved_operational_components','operational_bindings','production_entry_closed','operational_implementation_complete']:
 bad=copy.deepcopy(review);bad[key]=alternative(bad[key]);check('freeze rejects altered private review: '+key,rejected(validate,[freeze,bad,digest]))
for key in policy['authorization']:
 bad=copy.deepcopy(policy);bad['authorization'][key]=not bad['authorization'][key];check('policy rejects authority toggle: '+key,rejected(validate_policy,[bad]))
for key in ['accepted_checkpoint','schema','step','implementation_freeze_scope','production_entry_closed','operational_readiness','operational_conformance','operational_executor_sha256','user_step306_checkpoint_confirmed','pause_safe','strong_safe_pause','next_stage']:
 bad=copy.deepcopy(policy);bad[key]=alternative(bad[key]);check('policy rejects changed typed field: '+key,rejected(validate_policy,[bad]))
bad=copy.deepcopy(policy);bad['unreviewed_grant']=True;check('policy rejects extra authority',rejected(validate_policy,[bad]))
raw=receipt['text'].encode();check('reversible original305 receipt hash and size',len(raw)==36273==receipt['original_display_size_bytes'] and hashlib.sha256(raw).hexdigest()==accepted['evidence_sha256']==receipt['original_display_sha256'])
for old,new,label in [('Result: PASS (420 passes, 0 failures)','Result: PASS (419 passes, 0 failures)','incomplete acceptance'),('   a8bc533..024c820  main -> main','missing-push','missing successful push'),('git log -1 --oneline\n024c820','git log -1 --oneline\n M README.md\n024c820','nonempty short status'),('origin/main, origin/HEAD','origin/stale, origin/HEAD','mismatched remote HEAD'),('fatal: No se pudo leer del repositorio remoto.','hidden SSH failure','erased original failure'),(':( $ git push',':( $ echo skip','missing explicit retry')]:
 bad=copy.deepcopy(receipt);bad['text']=bad['text'].replace(old,new);encoded=bad['text'].encode();bad['original_display_sha256']=hashlib.sha256(encoded).hexdigest();bad['original_display_size_bytes']=len(encoded);badaccepted=copy.deepcopy(accepted);badaccepted['evidence_sha256']=bad['original_display_sha256'];check('receipt rejects '+label,rejected(validate_receipt,[bad,badaccepted]))
rows=(fixture/(base+'.tsv')).read_text().splitlines();check('unique real-tab record exactly matches closed freeze',all(l.count('\t')==1 for l in rows) and len({l.split('\t')[0] for l in rows})==len(rows) and dict(l.split('\t') for l in rows)=={'step': '306', 'freeze_status': 'PASS', 'accepted_checkpoint_commit': '024c820', 'accepted_checkpoint_acceptance': 'PASS (420 passes, 0 failures)', 'push_retry_succeeded': 'yes', 'reviewed_private_review_sha256': '0960e85113a76daa3bddaa98a902bc03a77bb797d9b5f0c426c7029e73987946', 'implementation_frozen': 'yes', 'implementation_freeze_scope': 'exact-closed-repository-candidate-and-private-acceptance-only', 'operational_readiness': 'no', 'operational_conformance': 'no', 'production_entry_closed': 'yes', 'operational_executor_sha256': 'null', 'runtime_attempt_authorized': 'no', 'machine_action_required': 'no', 'controller_action_required': 'no', 'pause_safe': 'no', 'strong_safe_pause': 'no', 'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-implementation-effect-and-authority-closure-review', 'boot_action_authorized': 'no', 'boot_argument_substitution_authorized': 'no', 'builder_execution_authorized': 'no', 'builder_transport_authorized': 'no', 'chmod_remediation_authorized': 'no', 'evidence_cleanup_authorized': 'no', 'historical_probe_rerun_authorized': 'no', 'immutable_builder_modification_authorized': 'no', 'immutable_executor_modification_authorized': 'no', 'local_source_v4_build_authorized': 'no', 'manual_builder_execution_authorized': 'no', 'network_access_authorized': 'no', 'new_executor_execution_authorized': 'no', 'new_executor_transport_authorized': 'no', 'new_probe_execution_authorized': 'no', 'new_probe_implementation_authorized': 'no', 'new_probe_transport_authorized': 'no', 'package_action_authorized': 'no', 'persistent_configuration_change_authorized': 'no', 'phase_2_start_authorized': 'no', 'read_only_probe_execution_authorized': 'no', 'read_only_probe_transport_authorized': 'no', 'reboot_authorized': 'no', 'remediation_implementation_authorized': 'no', 'repository_only_authority_effect_closure_and_strong_pause_review_authorized': 'no', 'repository_only_build_authorization_freeze_authorized': 'no', 'repository_only_fresh_revalidation_authorization_review_authorized': 'no', 'repository_only_resume_planning_boundary_review_authorized': 'no', 'repository_only_revalidation_design_freeze_authorized': 'no', 'repository_only_revalidation_design_review_authorized': 'no', 'repository_only_revalidation_probe_implementation_freeze_authorized': 'no', 'repository_only_revalidation_probe_implementation_review_authorized': 'no', 'repository_only_revalidation_result_review_authorized': 'no', 'repository_only_runtime_boundary_freeze_authorized': 'no', 'repository_only_runtime_boundary_review_authorized': 'no', 'repository_only_runtime_executor_design_freeze_authorized': 'no', 'repository_only_runtime_executor_design_review_authorized': 'no', 'repository_only_runtime_executor_implementation_failure_coverage_authorized': 'no', 'repository_only_runtime_executor_implementation_freeze_authorized': 'no', 'repository_only_runtime_executor_implementation_review_authorized': 'no', 'repository_only_transaction_contract_freeze_authorized': 'no', 'repository_only_transaction_contract_review_authorized': 'no', 'runtime_executor_rerun_authorized': 'no', 'slackpkg_mutation_authorized': 'no', 'step267_executor_rerun_authorized': 'no', 'target_observation_authorized': 'no', 'repository_only_runtime_implementation_effect_and_authority_closure_review_authorized': 'yes'})
with tempfile.TemporaryDirectory(prefix='step306-harness-') as directory:
 tmp=Path(directory)
 for args,success in [([],False),(['--help'],True),(['--bogus'],False),(['--output-dir'],False),(['--output-dir',''],False),(['--output-dir','x','extra'],False)]:check('strict freeze CLI '+repr(args),(run(['bash',helper,*args]).returncode==0)==success)
 out=tmp/'published';out.mkdir();call=run(['bash',helper,'--output-dir',out]);check('full420 exact historical acceptance including285 private before freeze publication',call.returncode==0 and 'accepted_step305_revalidated\tPASS (420 passes, 0 failures)' in call.stdout)
 if call.returncode:print(call.stdout+call.stderr,flush=True)
 for suffix in ['-policy.json','-freeze.json','-step305-user-acceptance.json','.tsv']:
  p=out/(base+suffix);check('exact freeze publication '+suffix,p.is_file() and p.read_bytes()==(fixture/p.name).read_bytes())
 before={p.name:p.read_bytes() for p in out.iterdir()};check('republication rejects without overwrite',run(['bash',helper,'--output-dir',out]).returncode!=0 and {p.name:p.read_bytes() for p in out.iterdir()}==before)
 link=tmp/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejects',run(['bash',helper,'--output-dir',link]).returncode!=0)
 alias=tmp/'ancestor';alias.symlink_to(tmp,target_is_directory=True);check('symlink output ancestor rejects',run(['bash',helper,'--output-dir',alias/'published']).returncode!=0)
 check('missing output rejects without creation',run(['bash',helper,'--output-dir',tmp/'missing']).returncode!=0 and not (tmp/'missing').exists())
 # Copy only bound files. Ignored logs, caches, symlinks and .git are never copied.
 replica=tmp/'replica'
 for rel in list(accepted['sha256_bindings'])+list(own)+['tests/reference/test-'+base+'-harness.sh']:
  p=replica/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes((root/rel).read_bytes())
 rh=replica/helper.relative_to(root);rejected_out=tmp/'rejected';rejected_out.mkdir()
 targets=list(dict.fromkeys(['CHANGELOG.md']+list(freeze['reviewed_artifact_sha256_bindings'])+list(freeze['candidate_sha256_bindings'])+list(freeze['predecessor_candidate_sha256_bindings'])+list(freeze['supporting_artifact_sha256_bindings'])+[rel for rel in own if rel!=helper.relative_to(root).as_posix()]))
 for rel in targets:
  p=replica/rel;data=p.read_bytes();p.write_bytes(data+b'\n');check('changed bound input rejects before publication: '+p.name,run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(data)
 for rel in [policy['review_path'],policy['candidate_executor_path']]:
  p=replica/rel;data=p.read_bytes();p.unlink();p.symlink_to(root/rel);check('same-content symlink rejects: '+p.name,run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and not list(rejected_out.iterdir()));p.unlink();p.write_bytes(data)
 for suffix in ['-policy.json','-freeze.json','-step305-user-acceptance.json','.tsv']:
  p=rejected_out/(base+suffix);p.write_bytes(b'preserved output\n');check('occupied publication rejects: '+suffix,run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and p.read_bytes()==b'preserved output\n' and len(list(rejected_out.iterdir()))==1);p.unlink()
check('accepted history and candidate bytes preserved by tests',history_valid())
for rel in list(own)+['tests/reference/test-'+base+'-harness.sh']:check('no trailing whitespace: '+Path(rel).name,all(l==l.rstrip() for l in (root/rel).read_text().splitlines()))
check('CHANGELOG confirms305 prepares306 with closed private scope','## Phase 1 step306 ' in (root/'CHANGELOG.md').read_text() and '024c820' in (root/'CHANGELOG.md').read_text() and 'pause_safe=false/strong_safe_pause=false' in (root/'CHANGELOG.md').read_text())
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
