#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import ast,copy,hashlib,json,shutil,subprocess,sys,tempfile
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-freeze';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review';own={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-freeze.md': '3613325d74331ff646bda91dfb9ce0a7dcfa58da0647bcf7b99a3ff89ffdcf1c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-freeze-freeze.json': '91eba578026d6bb807f2b318e9db94b236e2ee8d378692b5469e1d8088070219', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-freeze-policy.json': '7d98db1fd55e27730bf5251ae892f1e9bf3c5eb004db04bd5bbe09f7b8a3f778', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-freeze-step300-user-acceptance.json': 'f8b108256967f36fce2d84be451ae3d66116c1a29c50a693446affb21a91e864', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-freeze.tsv': '8f0cfd706df2655c7b910a10a26aa2915cf42f598e6050b8b1ead0bbfcf91f42', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-freeze.sh': '708f35abe9b0cadfa92917248333e9eaf2b87edc96c1b600d65ea93fb7b13b0f'}
fixture=root/'tests/fixtures/reference/acceptance/phase-1';helper=root/'tools/reference'/(base+'.sh')
policy=json.loads((fixture/(base+'-policy.json')).read_text());accepted=policy['accepted_checkpoint'];freeze=json.loads((root/policy['freeze_path']).read_text());contract=json.loads((root/policy['contract_path']).read_text())
passes=0
def check(label,ok):
 global passes
 if not ok:raise SystemExit('FAIL: '+label)
 passes+=1;print('PASS: '+label,flush=True)
def run(args):return subprocess.run([str(x) for x in args],capture_output=True,text=True)
def history_valid():
 for rel,digest in accepted['sha256_bindings'].items():
  p=root/rel
  if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute():return False
  data=p.read_bytes()
  if rel=='CHANGELOG.md':data=data[-accepted['changelog_size_bytes']:]
  if hashlib.sha256(data).hexdigest()!=digest:return False
 return len(accepted['sha256_bindings'])==1289
check('all1289 safe exact historical artifacts and CHANGELOG suffix',history_valid())
for rel,digest in own.items():
 p=root/rel;check('exact freeze input: '+p.name,p.is_file() and not p.is_symlink() and p.resolve()==p.absolute() and hashlib.sha256(p.read_bytes()).hexdigest()==digest)
for p in [helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
text=helper.read_text().split("<<'PYFREEZE'\n",1)[1].rsplit('\nPYFREEZE',1)[0]
names=['validate_contract_freeze','validate_freeze_policy'];nodes=[n for n in ast.parse(text).body if isinstance(n,ast.FunctionDef) and n.name in names]
check('pure freeze and policy functions extracted without top-level execution',sorted(n.name for n in nodes)==sorted(names))
scope={'json':json};exec(compile(ast.fix_missing_locations(ast.Module(body=nodes,type_ignores=[])),'<pure-contract-freeze>','exec'),scope)
validate=scope[names[0]];validate_policy=scope[names[1]];digest=hashlib.sha256((root/policy['contract_path']).read_bytes()).hexdigest()
check('complete exact reviewed contract freeze accepted',validate(freeze,contract,digest) is True)
check('complete next-design-only policy accepted',validate_policy(policy) is True)
previous=json.loads((fixture/(prior+'-policy.json')).read_text())
check('300 confirmation does not rewrite historical prepared state',previous['user_step300_checkpoint_confirmed'] is False and policy['accepted300_prepared_confirmation_satisfied'] is True)
check('full247 application commit push and clean tree accepted with prefix only',accepted['step']==300 and accepted['commit_prefix']=='20599ff' and accepted['commit_full'] is None and accepted['acceptance_result']=='PASS (247 passes, 0 failures)' and all(accepted[k] is True for k in ['user_application_completed','user_commit_and_push_completed','user_worktree_clean']))
receipt=json.loads((root/accepted['evidence_path']).read_text());raw=receipt['text'].encode('utf-8')
check('reversible complete user return SHA and size preserved',hashlib.sha256(raw).hexdigest()==accepted['evidence_sha256']==receipt['original_display_sha256'] and len(raw)==receipt['original_display_size_bytes'] and len([l for l in raw.decode().splitlines() if l.startswith('PASS: ')])==247)
check('raw contract identity binds exact accepted bytes',digest==policy['contract_sha256']==freeze['reviewed_contract_sha256']==accepted['sha256_bindings'][policy['contract_path']])
check('six review artifacts frozen to accepted identities',len(freeze['reviewed_artifact_sha256_bindings'])==6 and all(accepted['sha256_bindings'][p]==d for p,d in freeze['reviewed_artifact_sha256_bindings'].items()))
check('immutable reviewed contract state retained under separate freeze',contract['state']=='transaction-contract-reviewed-not-frozen-not-implemented-not-authorized' and freeze['state']=='transaction-contract-frozen-for-repository-design-only' and freeze['reviewed_contract_state_is_historical'] is True)
check('source candidate executor and restoration invariants unchanged',all(freeze[k]==contract[k] for k in ['frozen_source_candidate_executor','restoration_contract','publication_contract','future_authorization_requirements','unresolved_execution_bindings','fixture_oracle_scope']))
check('thirteen stage order and mutation boundaries frozen',freeze['frozen_phase_order']==[p['stage'] for p in contract['phases']] and freeze['frozen_mutation_boundaries']=={k:contract[k] for k in ['first_filesystem_mutation_index','first_package_mutation_index','candidate_binding_index','apply_index']})
check('only repository executor design review302 opens after301', [k for k,v in policy['authorization'].items() if v]==['repository_only_runtime_executor_design_review_authorized'] and policy['next_stage']==policy['roadmap']['preferred_steps'][3]['stage'] and policy['user_step301_checkpoint_confirmed'] is False)
check('roadmap preservation and closure conditions carried forward',all(policy[k]==previous[k] for k in ['roadmap','preservation','strong_pause_completion_conditions','current_state']))
check('historic298 pause retained without new pause or host observation',policy['historical_step298_strong_pause_remains_valid'] is True and policy['accepted300_reopened_workstream_strong_pause'] is False and all(policy['current_state'][k] is None for k in ['current_boot_id','current_pkglist_sha256','current_candidate_count','executor_sha256']))
def replace(value,path,new):
 p=value
 for k in path[:-1]:p=p[k]
 p[path[-1]]=new

def rejected(fn,args):
 try:fn(*args)
 except (ValueError,TypeError,KeyError,IndexError):return True
 return False
freeze_cases=[
 (['reviewed_contract_sha256'],'0'*64,'different contract SHA'),
 (['reviewed_contract_path'],'../unbound.json','unbound contract path'),
 (['reviewed_contract_bytes_unchanged'],False,'historical rewrite'),
 (['reviewed_contract_bytes_unchanged'],1,'integer flag substituted for boolean'),
 (['reviewed_artifact_sha256_bindings'],{},'missing reviewed oracle identities'),
 (['frozen_mutation_boundaries','first_filesystem_mutation_index'],1,'mutation before traps'),
 (['frozen_mutation_boundaries','first_package_mutation_index'],3,'package mutation before verified backups'),
 (['frozen_mutation_boundaries','candidate_binding_index'],8,'binding after apply'),
 (['frozen_source_candidate_executor','source','manifest_sha256'],'0'*64,'source manifest rebinding'),
 (['restoration_contract','cleanup_idempotent_and_owned_only'],False,'unowned cleanup'),
 (['restoration_contract','original_failure_or_signal_status_preserved'],False,'masked original status'),
 (['restoration_contract','SIGKILL_crash_power_loss_atomic_restoration_guaranteed'],True,'uncatchable restoration guarantee'),
 (['restoration_contract','uncatchable_exit_and_cleanup_status_remain_unknown'],False,'invented unobserved status'),
 (['publication_contract','success_requires_restoration_invariants'],False,'success without restoration'),
 (['publication_contract','success_requires_complete_evidence'],False,'success without evidence'),
 (['future_authorization_requirements','new_single_attempt_grant_consumed_on_invocation'],False,'old or reusable grant'),
 (['unresolved_execution_bindings','current_boot_id'],'expired-boot','old boot rebound'),
 (['unresolved_execution_bindings','reference_payload_sha256'],'0'*64,'unreviewed payload binding'),
 (['executor_implemented'],True,'implementation claim before design'),
 (['runtime_attempt_planned'],True,'runtime authority'),
 (['strong_safe_pause'],True,'premature strong pause'),
 (['next_stage'],'runtime-execution','design boundary skipped')]
for path,new,label in freeze_cases:
 bad=copy.deepcopy(freeze);replace(bad,path,new);check('freeze rejects '+label,rejected(validate,[bad,contract,digest]))
for a,b,label in [(1,2,'workspace before traps'),(3,4,'package stage before backups'),(7,8,'apply before exact candidate binding'),(10,12,'publication before verified restoration')]:
 bad=copy.deepcopy(freeze);bad['frozen_phase_order'][a],bad['frozen_phase_order'][b]=bad['frozen_phase_order'][b],bad['frozen_phase_order'][a]
 check('freeze rejects '+label,rejected(validate,[bad,contract,digest]))
check('freeze rejects semantically equal contract with different raw hash',rejected(validate,[freeze,contract,'0'*64]))
for path,new,label in [(['phases'],[],'missing transaction stages'),(['restoration_contract','catchable_traps'],['EXIT'],'missing catchable traps'),(['publication_contract','failure_evidence_is_not_success'],False,'failed attempt promoted'),(['unresolved_execution_bindings','executor_sha256'],'0'*64,'unreviewed executor')]:
 bad=copy.deepcopy(contract);replace(bad,path,new);check('freeze rejects changed reviewed contract '+label,rejected(validate,[freeze,bad,digest]))
for key in policy['authorization']:
 bad=copy.deepcopy(policy);bad['authorization'][key]=not bad['authorization'][key]
 check('authority gate rejects toggle: '+key,rejected(validate_policy,[bad]))
for path,new,label in [(['accepted_checkpoint','commit_full'],'20599ff'+'0'*33,'invented full object ID'),(['accepted_checkpoint','user_worktree_clean'],False,'unaccepted dirty checkout'),(['accepted_checkpoint','acceptance_result'],'PASS','incomplete acceptance'),(['accepted_checkpoint','evidence_sha256'],'0'*64,'changed receipt identity'),(['current_state','current_boot_id'],'expired-boot','current boot invented'),(['current_state','phase2_open'],True,'Phase2 opened'),(['current_state','executor_installed'],True,'executor installed'),(['user_step301_checkpoint_confirmed'],True,'prepared301 called accepted'),(['pause_safe'],True,'new safe pause'),(['schema'],True,'boolean schema'),(['next_stage'],'runtime','next gate skipped')]:
 bad=copy.deepcopy(policy);replace(bad,path,new);check('policy rejects '+label,rejected(validate_policy,[bad]))
bad=copy.deepcopy(policy);bad['unreviewed_authority']=True;check('policy rejects extra authority fields',rejected(validate_policy,[bad]))
record=(fixture/(base+'.tsv')).read_text();rows=record.splitlines();check('strict unique real-tab freeze record',all(l.count('\t')==1 for l in rows) and len({l.split('\t')[0] for l in rows})==len(rows) and dict(l.split('\t') for l in rows)=={'step': '301', 'freeze_status': 'PASS', 'accepted_checkpoint_commit': '20599ff', 'accepted_checkpoint_acceptance': 'PASS (247 passes, 0 failures)', 'contract_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review-contract.json', 'contract_sha256': 'f341e76a83148ec8ee3a438cf8a82f469490bd8b9aed82afda97c9cddc12f291', 'contract_bytes_unchanged': 'yes', 'current_boot_id': 'not-observed', 'executor_installed': 'no', 'runtime_attempt_authorized': 'no', 'machine_action_required': 'no', 'controller_action_required': 'no', 'pause_safe': 'no', 'strong_safe_pause': 'no', 'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-design-review', 'boot_action_authorized': 'no', 'boot_argument_substitution_authorized': 'no', 'builder_execution_authorized': 'no', 'builder_transport_authorized': 'no', 'chmod_remediation_authorized': 'no', 'evidence_cleanup_authorized': 'no', 'historical_probe_rerun_authorized': 'no', 'immutable_builder_modification_authorized': 'no', 'immutable_executor_modification_authorized': 'no', 'local_source_v4_build_authorized': 'no', 'manual_builder_execution_authorized': 'no', 'network_access_authorized': 'no', 'new_executor_execution_authorized': 'no', 'new_executor_transport_authorized': 'no', 'new_probe_execution_authorized': 'no', 'new_probe_implementation_authorized': 'no', 'new_probe_transport_authorized': 'no', 'package_action_authorized': 'no', 'persistent_configuration_change_authorized': 'no', 'phase_2_start_authorized': 'no', 'read_only_probe_execution_authorized': 'no', 'read_only_probe_transport_authorized': 'no', 'reboot_authorized': 'no', 'remediation_implementation_authorized': 'no', 'repository_only_authority_effect_closure_and_strong_pause_review_authorized': 'no', 'repository_only_build_authorization_freeze_authorized': 'no', 'repository_only_fresh_revalidation_authorization_review_authorized': 'no', 'repository_only_resume_planning_boundary_review_authorized': 'no', 'repository_only_revalidation_design_freeze_authorized': 'no', 'repository_only_revalidation_design_review_authorized': 'no', 'repository_only_revalidation_probe_implementation_freeze_authorized': 'no', 'repository_only_revalidation_probe_implementation_review_authorized': 'no', 'repository_only_revalidation_result_review_authorized': 'no', 'repository_only_runtime_boundary_freeze_authorized': 'no', 'repository_only_runtime_boundary_review_authorized': 'no', 'repository_only_transaction_contract_freeze_authorized': 'no', 'repository_only_transaction_contract_review_authorized': 'no', 'runtime_executor_rerun_authorized': 'no', 'slackpkg_mutation_authorized': 'no', 'step267_executor_rerun_authorized': 'no', 'target_observation_authorized': 'no', 'repository_only_runtime_executor_design_review_authorized': 'yes'})
with tempfile.TemporaryDirectory(prefix='step301-harness-') as directory:
 tmp=Path(directory)
 for args,success in [([],False),(['--help'],True),(['--bogus'],False),(['--output-dir'],False),(['--output-dir',''],False),(['--output-dir','x','extra'],False)]:check('strict CLI '+repr(args),(run(['bash',helper,*args]).returncode==0)==success)
 out=tmp/'published';out.mkdir();call=run(['bash',helper,'--output-dir',out]);check('full247 exact historical acceptance precedes freeze publication',call.returncode==0 and 'accepted_step300_revalidated\tPASS (247 passes, 0 failures)' in call.stdout)
 for suffix in ['-policy.json','-freeze.json','-step300-user-acceptance.json','.tsv']:
  p=out/(base+suffix);check('exact freeze publication '+suffix,p.is_file() and p.read_bytes()==(fixture/p.name).read_bytes())
 before={p.name:p.read_bytes() for p in out.iterdir()};check('republication rejected without overwrite',run(['bash',helper,'--output-dir',out]).returncode!=0 and {p.name:p.read_bytes() for p in out.iterdir()}==before)
 link=tmp/'output-link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',helper,'--output-dir',link]).returncode!=0)
 alias=tmp/'ancestor-link';alias.symlink_to(tmp,target_is_directory=True);check('symlink output ancestor rejected',run(['bash',helper,'--output-dir',alias/'published']).returncode!=0)
 check('missing output rejected without creation',run(['bash',helper,'--output-dir',tmp/'missing']).returncode!=0 and not (tmp/'missing').exists())
 replica=tmp/'replica';shutil.copytree(root,replica,ignore=shutil.ignore_patterns('.git'));rh=replica/helper.relative_to(root);rejected_out=tmp/'rejected';rejected_out.mkdir()
 targets=['CHANGELOG.md','README.md']+list(freeze['reviewed_artifact_sha256_bindings'])+[rel for rel in own if rel!=helper.relative_to(root).as_posix()]
 for rel in targets:
  p=replica/rel;data=p.read_bytes();p.write_bytes(data+b'\n');check('changed bound input rejected before publication: '+p.name,run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(data)
 p=replica/policy['contract_path'];data=p.read_bytes();p.unlink();p.symlink_to(root/policy['contract_path']);check('same-content contract symlink rejected',run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and not list(rejected_out.iterdir()));p.unlink();p.write_bytes(data)
 future=replica/contract['frozen_source_candidate_executor']['executor']['future_executor_path'];future.write_text('unreviewed executor fixture\n');check('unexpected reserved production executor rejected',run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and not list(rejected_out.iterdir()));future.unlink()
 for suffix in ['-policy.json','-freeze.json','-step300-user-acceptance.json','.tsv']:
  p=rejected_out/(base+suffix);p.write_bytes(b'preserved output\n');check('occupied publication destination rejected: '+suffix,run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and p.read_bytes()==b'preserved output\n' and len(list(rejected_out.iterdir()))==1);p.unlink()
future=root/contract['frozen_source_candidate_executor']['executor']['future_executor_path'];check('accepted bytes and absent production executor preserved by tests',history_valid() and not future.exists() and not future.is_symlink())
for rel in list(own)+['tests/reference/test-'+base+'-harness.sh']:check('no trailing whitespace: '+Path(rel).name,all(l==l.rstrip() for l in (root/rel).read_text().splitlines()))
check('CHANGELOG confirms300 and prepares301 without pause claim','## Phase 1 step301 ' in (root/'CHANGELOG.md').read_text() and '20599ff' in (root/'CHANGELOG.md').read_text() and 'pause_safe=false/strong_safe_pause=false' in (root/'CHANGELOG.md').read_text())
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
