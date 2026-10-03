#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import ast,copy,hashlib,json,re,shutil,subprocess,sys,tempfile
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-closure-resume-planning-boundary-review';own={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review.md': '927a846704d3cb45e562ad0eba58987aca0189bc14107f669c14153c71175cd4', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review-contract.json': 'f341e76a83148ec8ee3a438cf8a82f469490bd8b9aed82afda97c9cddc12f291', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review-policy.json': 'c234a649f26f2ef83e18ca92d74b6f7b0c66e095d2f21c4ed8eda8a7a545c6da', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review-step299-user-acceptance.json': '0f89aac6e6d2a511f444410c08d8c5446a3e646caf3d95353869524c03a5eb53', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review.tsv': 'db5fa42e32ba08264edfaf1099262e0e01b3491dadbc77c1125e386108a32186', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-transaction-contract-review.sh': '87bf6e535c4253afb17fd4a3c13165946ffa2f839acfda708244a7fca51b262f'}
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
policy=json.loads((fixture/(base+'-policy.json')).read_text());accepted=policy['accepted_checkpoint']
contract=json.loads((root/policy['contract_path']).read_text());helper=root/'tools/reference'/(base+'.sh')
passes=0
def check(label,value):
 global passes
 if not value:raise SystemExit('FAIL: '+label)
 passes+=1;print('PASS: '+label)
def run(args):return subprocess.run([str(x) for x in args],capture_output=True,text=True)
def history_valid():
 for rel,digest in accepted['sha256_bindings'].items():
  p=root/rel
  if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute():return False
  data=p.read_bytes()
  if rel=='CHANGELOG.md':data=data[-accepted['changelog_size_bytes']:]
  if hashlib.sha256(data).hexdigest()!=digest:return False
 return len(accepted['sha256_bindings'])==1282
check('all1282 exact safe predecessor artifacts and CHANGELOG suffix',history_valid())
for rel,digest in own.items():
 p=root/rel;check('exact review input: '+p.name,p.is_file() and not p.is_symlink() and p.resolve()==p.absolute() and hashlib.sha256(p.read_bytes()).hexdigest()==digest)
for p in [helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
def extract_functions(script,delimiter,names,scope):
 text=script.read_text().split("<<'"+delimiter+"'\n",1)[1].rsplit('\n'+delimiter,1)[0]
 nodes=[n for n in ast.parse(text).body if isinstance(n,ast.FunctionDef) and n.name in names]
 check('exact pure AST seam: '+','.join(names),sorted(n.name for n in nodes)==sorted(names))
 exec(compile(ast.fix_missing_locations(ast.Module(body=nodes,type_ignores=[])),'<exact-pure-contract-oracle>','exec'),scope)
scope={'json':json,'re':re,'hashlib':hashlib}
extract_functions(helper,'PYREVIEW',['validate_transaction_contract','validate_transaction_trace'],scope)
old_gate=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review.sh'
extract_functions(old_gate,'PYFREEZE',['validate_runtime_boundary_fixture'],scope)
validate=scope['validate_transaction_contract'];oracle=scope['validate_transaction_trace'];candidate_gate=scope['validate_runtime_boundary_fixture']
check('complete reviewed contract passes pure gate',validate(contract) is True)
previous=json.loads((fixture/(prior+'-policy.json')).read_text())
check('exact frozen source candidate executor retained',contract['frozen_source_candidate_executor']==previous['accepted_runtime_boundary'])
check('accepted user299-r1 confirms119 commit push clean tree',accepted['step']==299 and accepted['delivery_revision']=='r1' and accepted['commit_prefix']=='435df6b' and accepted['commit_full'] is None and all(accepted[k] is True for k in ['user_application_completed','user_commit_and_push_completed','user_worktree_clean']))
receipt=json.loads((root/accepted['evidence_path']).read_text());raw=receipt['text'].encode('utf-8')
check('exact reversible complete user evidence',hashlib.sha256(raw).hexdigest()==accepted['evidence_sha256']==receipt['original_display_sha256'] and len(raw)==receipt['original_display_size_bytes'] and len([x for x in raw.decode().splitlines() if x.startswith('PASS: ')])==119)
check('confirmed299 does not imply new strong pause or host state',policy['accepted299_prepared_confirmation_satisfied'] is True and policy['accepted299_reopened_workstream_strong_pause'] is False and policy['historical_step298_strong_pause_remains_valid'] is True and policy['current_state']['current_boot_id'] is None)
check('only next contract freeze authority open',[k for k,v in policy['authorization'].items() if v]==['repository_only_transaction_contract_freeze_authorized'])
check('roadmap exactly preserved with no runtime or live observation',policy['roadmap']==previous['roadmap'] and policy['next_stage']==policy['roadmap']['preferred_steps'][2]['stage'])
source=contract['frozen_source_candidate_executor']['source'];candidate=contract['frozen_source_candidate_executor']['candidate']
row=' '.join(candidate['expected_target_fields'])+'\n'
binding=dict(source_manifest_sha256=source['manifest_sha256'],source_target_sha256=source['target_sha256'],source_checksum_format=source['checksum_representation'],
 source_preserved=True,fresh_transaction=True,pre_refresh_pkglist_absent=True,post_refresh_pkglist_regular=True,post_refresh_pkglist_non_symlink=True,
 refresh_exit=0,same_transaction_binding=True,all_unexpected_candidate_counts_zero=True,pkglist_text=row,
 bound_pkglist_sha256=hashlib.sha256(row.encode()).hexdigest(),refresh_stdout='',refresh_stderr='')
context=dict(new_grant=True,fresh_target_source_artifact_and_predecessor_validation=True,same_boot_of_new_grant=True,
 reviewed_executor_payload_and_configuration=True,exclusive_work_temp_absent=True,source_manifest_sha256=source['manifest_sha256'],
 source_target_sha256=source['target_sha256'],predecessor_sha256=contract['restoration_contract']['predecessor_sha256'])
def trace(fault=None,outcome='FAIL',signal=None,restore=True,complete=True):
 stages=contract['phases'];count=len(stages) if fault is None else fault+1
 events=[dict(stage=r['stage'],outcome='PASS',exit=0,signal=None) for r in stages[:count]]
 code=0
 if fault is not None:
  code=42 if outcome=='FAIL' else None if outcome=='LOST' else {'HUP':129,'INT':130,'TERM':143}[signal]
  events[-1].update(outcome=outcome,exit=code,signal=signal)
 touched=count>2;lost=outcome=='LOST' and fault is not None
 if lost:complete=False;restore=not touched
 if not touched:restore=True
 publication_failed=fault==len(stages)-1
 bound=count>7 and events[7]['outcome']=='PASS'
 return dict(context=copy.deepcopy(context),events=events,verified_backups=count>4,candidate_fixture=copy.deepcopy(binding) if bound else None,
  cleanup=dict(armed=count>2,required=touched,invoked=touched and not lost,restoration_verified=restore,exit=None if not touched or lost else 0 if restore else 73),
  evidence=dict(complete=complete,streams_and_exits_captured=complete,original_status_recorded=complete,cleanup_recorded=complete,owned_only=True,preserved_inputs=True),
  publication='success' if fault is None else 'none' if not complete or publication_failed else 'failure',final_exit=code,grant_consumed=True,
  pending_machine_obligations=touched and not restore,pending_controller_obligations=not complete or publication_failed)
def classify(value):return oracle(value,contract,candidate_gate)
def rejected(value):
 try:classify(value)
 except (ValueError,KeyError,TypeError):return True
 return False
happy=trace()
check('full ordered restored complete success fixture',classify(happy)=='success-eligible-fixture')
for index,phase in enumerate(contract['phases']):
 value=trace(index);expected='failed-incomplete-fixture' if index==12 else 'failed-restored-fixture'
 check('failed stage preserves original status and forbids success: '+phase['stage'],classify(value)==expected and value['final_exit']==42 and value['publication']!='success')
 for signal in ['HUP','INT','TERM']:
  value=trace(index,'INTERRUPTED',signal)
  check('catchable '+signal+' at '+phase['stage'],classify(value)==expected and value['final_exit']=={'HUP':129,'INT':130,'TERM':143}[signal])
 for signal in ['KILL','CRASH','POWERLOSS']:
  value=trace(index,'LOST',signal)
  check('uncatchable '+signal+' requires incomplete review: '+phase['stage'],classify(value)=='failed-incomplete-fixture' and not value['evidence']['complete'] and value['publication']=='none' and value['final_exit'] is None and value['cleanup']['exit'] is None)
 if index>=2:
  value=trace(index,restore=False)
  check('restoration failure recorded separately without masking status: '+phase['stage'],classify(value)=='failed-incomplete-fixture' and value['final_exit']==42 and value['cleanup']['exit']==73 and value['pending_machine_obligations'])
 value=trace(index,complete=False)
 check('incomplete evidence prevents closure: '+phase['stage'],classify(value)=='failed-incomplete-fixture' and value['pending_controller_obligations'] and value['publication']=='none')
mutations=[(['context','new_grant'],False),(['context','same_boot_of_new_grant'],False),
 (['context','fresh_target_source_artifact_and_predecessor_validation'],False),(['context','reviewed_executor_payload_and_configuration'],False),
 (['context','exclusive_work_temp_absent'],False),(['context','source_manifest_sha256'],'0'*64),(['context','predecessor_sha256'],'0'*64),
 (['verified_backups'],False),(['verified_backups'],1),(['candidate_fixture'],None),
 (['cleanup','armed'],False),(['cleanup','invoked'],False),(['cleanup','restoration_verified'],False),(['cleanup','restoration_verified'],1),
 (['cleanup','exit'],True),(['evidence','complete'],False),(['evidence','complete'],1),(['evidence','preserved_inputs'],False),
 (['evidence','owned_only'],False),(['evidence','streams_and_exits_captured'],False),
 (['publication'],'failure'),(['final_exit'],42),(['final_exit'],False),(['grant_consumed'],False),(['grant_consumed'],1),
 (['pending_machine_obligations'],True),(['pending_controller_obligations'],True),
 (['events',0,'exit'],False),(['events',0,'signal'],'INT'),(['events',0,'outcome'],'UNKNOWN'),
 (['events',2,'stage'],'reference-apply'),(['events',3,'stage'],'stage-exact-predecessor')]
for keys,value in mutations:
 bad=copy.deepcopy(happy);node=bad
 for key in keys[:-1]:node=node[key]
 node[keys[-1]]=value
 check('trace gate rejects '+'.'.join(str(k) for k in keys),rejected(bad))
bad=copy.deepcopy(happy);bad['events'].pop(1);check('cannot skip trap registration before mutation',rejected(bad))
bad=copy.deepcopy(happy);bad['events'].pop(3);check('cannot skip verified backups before package stage',rejected(bad))
bad=copy.deepcopy(happy);bad['events']=bad['events'][:8];check('preflight or prefix alone cannot publish success',rejected(bad))
bad=trace(6);bad['events'].append(copy.deepcopy(happy['events'][7]));check('failed refresh cannot continue to binding',rejected(bad))
bad=trace(8);bad['publication']='success';check('restored failed apply is never successful',rejected(bad))
bad=trace(8,restore=False);bad['final_exit']=73;check('cleanup failure cannot mask original apply failure',rejected(bad))
bad=trace(8,'INTERRUPTED','TERM');bad['final_exit']=73;check('cleanup cannot mask original signal',rejected(bad))
bad=trace(8,'LOST','KILL');bad['cleanup']['restoration_verified']=True;bad['cleanup']['exit']=0;bad['pending_machine_obligations']=False
check('uncatchable loss cannot claim trap restoration',rejected(bad))
bad=trace(8,'LOST','KILL');bad['events'][-1]['exit']=137;bad['final_exit']=137
check('uncatchable loss cannot invent a known stage status',rejected(bad))
bad=trace(8,'LOST','KILL');bad['cleanup']['exit']=73
check('uninvoked cleanup cannot invent a status',rejected(bad))
bad=trace(12);bad['pending_controller_obligations']=False;check('failed publication cannot claim closed controller obligations',rejected(bad))
bad=copy.deepcopy(happy);bad['machine_authority']=True;check('extra trace authority fields rejected',rejected(bad))
for key in ['source_preserved','fresh_transaction','pre_refresh_pkglist_absent','post_refresh_pkglist_regular','post_refresh_pkglist_non_symlink','same_transaction_binding','all_unexpected_candidate_counts_zero']:
 bad=copy.deepcopy(happy);bad['candidate_fixture'][key]=False
 check('exact accepted candidate oracle rejects '+key,rejected(bad))
for text in ['',row+row,row+'slackware64 other 1 x86 1 other-1-x86-1 ./slackware64/d txz\n',row.replace('./slackware64/d','../slackware64/d'),row.replace(' txz',' txz extra')]:
 bad=copy.deepcopy(happy);bad['candidate_fixture']['pkglist_text']=text;bad['candidate_fixture']['bound_pkglist_sha256']=hashlib.sha256(text.encode()).hexdigest()
 check('candidate oracle rejects empty duplicate extra traversal malformed '+str(len(text)),rejected(bad))
for key,value in [('refresh_exit',1),('refresh_exit',True),('bound_pkglist_sha256','0'*64),('source_checksum_format','GNU-tagged-MD5'),('source_target_sha256','0'*64)]:
 bad=copy.deepcopy(happy);bad['candidate_fixture'][key]=value;check('candidate oracle rejects '+key,rejected(bad))
for stream in ['refresh_stdout','refresh_stderr']:
 bad=copy.deepcopy(happy);bad['candidate_fixture'][stream]='eRrOr dOwNlOaDiNg FrOm file:///fixture/\n'
 check('exit0 with human-spaced mixed-case error in '+stream+' rejected',rejected(bad))
contract_mutations=[(['first_filesystem_mutation_index'],0),(['first_package_mutation_index'],3),(['apply_index'],7),
 (['restoration_contract','catchable_traps'],['EXIT','HUP','INT','TERM','KILL']),
 (['restoration_contract','SIGKILL_crash_power_loss_atomic_restoration_guaranteed'],True),
 (['restoration_contract','original_failure_or_signal_status_preserved'],False),
 (['restoration_contract','success_publication_after_restoration_and_complete_evidence_only'],False),
 (['publication_contract','success_requires_restoration_invariants'],False),
 (['unresolved_execution_bindings','new_grant_id'],'old-grant'),
 (['unresolved_execution_bindings','current_boot_id'],'a5430a61-c988-4d52-9d5c-f20bb0a04016'),
 (['runtime_attempt_planned'],True),(['strong_safe_pause'],True),(['schema'],True),
 (['frozen_source_candidate_executor','candidate','exact_target_candidate_count'],2)]
for keys,value in contract_mutations:
 bad=copy.deepcopy(contract);node=bad
 for key in keys[:-1]:node=node[key]
 node[keys[-1]]=value
 try:validate(bad);denied=False
 except ValueError:denied=True
 check('contract identity/type gate rejects '+'.'.join(keys),denied)
record_rows=[line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines()]
check('strict unique real-tab review record',all(len(r)==2 and all(r) for r in record_rows) and len(record_rows)==len(dict(record_rows)))
record=dict(record_rows)
check('record agrees with checkpoint authority and next stage',record['accepted_checkpoint_commit']=='435df6b' and record['next_stage']==policy['next_stage'] and all(record[k]==('yes' if v else 'no') for k,v in policy['authorization'].items()))
for args in [[],['--help'],['--bogus'],['--output-dir'],['--output-dir',''],['--output-dir','x','extra']]:
 check('strict CLI '+repr(args),run(['bash',helper,*args]).returncode==(0 if args==['--help'] else 2))
with tempfile.TemporaryDirectory(prefix='step300-review-tests-') as directory:
 tmp=Path(directory);out=tmp/'review with spaces';out.mkdir()
 call=run(['bash',helper,'--output-dir',out])
 check('full119 exact predecessor acceptance reruns before review publication',call.returncode==0 and 'accepted_step299_revalidated\tPASS (119 passes, 0 failures)' in call.stdout)
 for suffix in ['-policy.json','-contract.json','-step299-user-acceptance.json','.tsv']:
  check('exact repository publication '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
 before={p.name:p.read_bytes() for p in out.iterdir()}
 check('existing review output rejected without overwrite',run(['bash',helper,'--output-dir',out]).returncode!=0 and before=={p.name:p.read_bytes() for p in out.iterdir()})
 link=tmp/'output-link';link.symlink_to(out,target_is_directory=True)
 check('symlink output rejected',run(['bash',helper,'--output-dir',link]).returncode!=0)
 nested=out/'nested';nested.mkdir()
 check('symlink output ancestor rejected',run(['bash',helper,'--output-dir',link/'nested']).returncode!=0 and not list(nested.iterdir()))
 check('missing output rejected',run(['bash',helper,'--output-dir',tmp/'missing']).returncode!=0 and not (tmp/'missing').exists())
 replica=tmp/'replica';shutil.copytree(root,replica,ignore=shutil.ignore_patterns('.git'));rh=replica/helper.relative_to(root)
 rejected_out=tmp/'rejected';rejected_out.mkdir()
 targets=['CHANGELOG.md',old_gate.relative_to(root).as_posix(),contract['frozen_source_candidate_executor']['executor']['historical_executor_path'],
  'tests/fixtures/reference/acceptance/phase-1/'+prior+'-policy.json']+[rel for rel in own if rel!=helper.relative_to(root).as_posix()]
 for rel in targets:
  p=replica/rel;data=p.read_bytes();p.write_bytes(data+b'\n')
  check('changed bound input rejected before publication: '+p.name,run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and not list(rejected_out.iterdir()))
  p.write_bytes(data)
 p=replica/old_gate.relative_to(root);data=p.read_bytes();p.unlink();p.symlink_to(old_gate)
 check('same-content historical candidate-source symlink rejected',run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and not list(rejected_out.iterdir()))
 p.unlink();p.write_bytes(data)
future=root/contract['frozen_source_candidate_executor']['executor']['future_executor_path']
check('no production executor created and accepted history preserved',not future.exists() and not future.is_symlink() and history_valid())
for rel in list(own)+['tests/reference/test-'+base+'-harness.sh']:
 check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
changelog=(root/'CHANGELOG.md').read_text()
check('CHANGELOG confirms299 and prepares300', '## Phase 1 step300 ' in changelog and '435df6b' in changelog and 'pause_safe=false/strong_safe_pause=false' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
