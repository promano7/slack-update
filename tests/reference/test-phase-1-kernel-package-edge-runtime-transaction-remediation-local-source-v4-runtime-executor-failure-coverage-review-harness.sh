#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import ast,copy,hashlib,json,subprocess,sys,tempfile
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-review';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-implementation-review';own={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-review.md': 'e50dd7655df12c381f00b3929f59d9e478c31bd9f3bfa5887849f20e1484fd86', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-review-coverage.json': '0960e85113a76daa3bddaa98a902bc03a77bb797d9b5f0c426c7029e73987946', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-review-policy.json': '7a5ce800e4e04a62f0c23ace7ace48b7bc0877eda71690d48863648f418fb787', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-review-step304-user-acceptance.json': '14260b7a92138f679aef3ca1b63de1305ffe65c9ed60f095d9a38fa06d7bfeff', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-review.tsv': '6fcfb1994fa1fef9b16077b389b178d6dde8ac2c80eb004713d2693b40dac8e9', 'tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-review-private.py': '04782004cb683563a9a7ca8522d808686db359f7117e0c9355de189b088c39a4', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-candidate-private.py': '9c6bf6d82a15eef3eb74ae8e3aa7ccfbff46af07ec0c105f6c2db4fa5402d7e4', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-candidate.sh': 'd861b551c1197b3d83c3535741d8cca5011294b5ea0c8a27d80fd686aa489939', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-review.sh': '23d17390b5be5e65519a4fc21f77e630b974fd87be04f60cdcd5498e8db9d085'};fixture=root/'tests/fixtures/reference/acceptance/phase-1'
helper=root/'tools/reference'/(base+'.sh');policy=json.loads((fixture/(base+'-policy.json')).read_text())
review=json.loads((root/policy['review_path']).read_text());accepted=policy['accepted_checkpoint'];passes=0
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
 return len(accepted['sha256_bindings'])==1320
check('all1320 exact safe accepted304 artifacts and CHANGELOG suffix',history_valid())
for rel,digest in own.items():
 p=root/rel;check('exact implementation input: '+p.name,p.is_file() and not p.is_symlink() and p.resolve()==p.absolute() and hashlib.sha256(p.read_bytes()).hexdigest()==digest)
for p in [helper,root/policy['candidate_executor_path'],root/'tests/reference'/('test-'+base+'-harness.sh')]:
 if p.suffix=='.sh':check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
text=helper.read_text().split("<<'PYREVIEW'\n",1)[1].rsplit('\nPYREVIEW',1)[0]
names=['validate_implementation_policy','validate_implementation_review'];nodes=[n for n in ast.parse(text).body if isinstance(n,ast.FunctionDef) and n.name in names];scope={'json':json}
check('pure policy/review AST seams without top-level execution',sorted(n.name for n in nodes)==sorted(names))
exec(compile(ast.fix_missing_locations(ast.Module(body=nodes,type_ignores=[])),'<pure-implementation>','exec'),scope)
check('exact private-only complete closed candidate policy accepted',scope[names[0]](policy) is True)
check('exact private candidate review accepted',scope[names[1]](review) is True)
freeze=json.loads((root/policy['freeze_path']).read_text());previous=json.loads((fixture/(prior+'-policy.json')).read_text())
check('all eleven frozen implementation sections carried unchanged',review['frozen_implementation_specification']==freeze['frozen_implementation_specification'])
check('actual candidate SHA separate from unresolved operational SHA',policy['candidate_executor_sha256']==review['candidate_sha256_bindings'][policy['candidate_executor_path']] and policy['operational_executor_sha256'] is None and policy['current_state']['executor_sha256'] is None)
check('mandatory private coverage complete without weakening',review['mandatory_tests']==freeze['frozen_implementation_specification']['implementation_test_design']['mandatory_tests'] and review['mandatory_tests_may_not_be_weakened'] is True and review['coverage_complete'] is True and len(review['coverage']['pending305'])==0)
check('executed child/loss coverage separate from unresolved operational components',review['actual_private_Python_children_executed'] is True and review['operational_implementation_complete'] is False and len(review['unresolved_operational_components'])==7 and review['actual_reference_payload_executed'] is False)
check('only repository failure coverage305 after user304 checkpoint',[k for k,v in policy['authorization'].items() if v]==['repository_only_runtime_executor_implementation_freeze_authorized'] and policy['user_step305_checkpoint_confirmed'] is False and policy['next_stage']==policy['roadmap']['preferred_steps'][7]['stage'])
check('accepted304 original prefix279 push clean tree only user scope',accepted['commit_prefix']=='a8bc533' and accepted['commit_full'] is None and accepted['acceptance_result']=='PASS (279 passes, 0 failures)' and all(accepted[k] for k in ['user_application_completed','user_commit_and_push_completed','user_worktree_clean']))
receipt=json.loads((root/accepted['evidence_path']).read_text());raw=receipt['text'].encode()
check('complete original303 receipt reversible exact SHA size',hashlib.sha256(raw).hexdigest()==accepted['evidence_sha256']==receipt['original_display_sha256'] and len(raw)==receipt['original_display_size_bytes'] and len([x for x in raw.decode().splitlines() if x.startswith('PASS: ')])==279)
check('current state roadmap preservation and closure carried unchanged',all(policy[k]==previous[k] for k in ['current_state','roadmap','preservation','strong_pause_completion_conditions']))
def rejected(fn,value):
 try:fn(value)
 except (ValueError,TypeError,KeyError):return True
 return False
for fn,value,cases in [
 (scope[names[0]],policy,[(('schema',),True),(('coverage_complete',),False),(('implementation_frozen',),True),(('operational_executor_sha256',),'0'*64),(('production_entry_closed',),False),(('strong_safe_pause',),True),(('accepted_checkpoint','commit_full'),'a8bc533'+'0'*33),(('user_step305_checkpoint_confirmed',),True)]),
 (scope[names[1]],review,[(('schema',),True),(('coverage_complete',),False),(('production_backend_implemented',),True),(('actual_reference_payload_executed',),True),(('host_commands_executed',),True),(('coverage','executed_private'),[]),(('mandatory_tests',),[]),(('private_hashes_separate_from_historical_real_source_anchors',),False),(('implementation_frozen',),True),(('operational_bindings','current_boot_id'),'old-boot')])]:
 for path,val in cases:
  bad=copy.deepcopy(value);p=bad
  for k in path[:-1]:p=p[k]
  p[path[-1]]=val;check('typed review/policy rejects drift '+'.'.join(path),rejected(fn,bad))
for key in policy['authorization']:
 bad=copy.deepcopy(policy);bad['authorization'][key]=not bad['authorization'][key];check('authority rejects toggle: '+key,rejected(scope[names[0]],bad))
for rel in review['candidate_sha256_bindings']:
 p=root/rel
 if p.suffix=='.py':check('Python syntax without pycache: '+p.name,compile(p.read_text(),str(p),'exec') is not None)
private=run([sys.executable,'-I',root/'tests/reference/test-phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-review-private.py',root])
if private.returncode:raise SystemExit(private.stdout+private.stderr)
for line in private.stdout.splitlines():
 if line.startswith('PASS: '):check(line[6:],True)
check('private executed suite terminates with full result',private.stdout.rstrip().endswith('checks, 0 failures)'))
rows=(fixture/(base+'.tsv')).read_text().splitlines();check('strict unique tab record',all(x.count('\t')==1 for x in rows) and dict(x.split('\t') for x in rows)=={'step': '305', 'implementation_review_status': 'PASS', 'accepted_checkpoint_commit': 'a8bc533', 'accepted_checkpoint_acceptance': 'PASS (279 passes, 0 failures)', 'candidate_executor_path': 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-failure-coverage-candidate.sh', 'candidate_executor_sha256': 'd861b551c1197b3d83c3535741d8cca5011294b5ea0c8a27d80fd686aa489939', 'production_entry_closed': 'yes', 'real_reference_executed': 'no', 'mandatory_coverage_complete': 'yes-private-only', 'implementation_frozen': 'no', 'operational_executor_sha256': 'unresolved', 'current_boot_id': 'not-observed', 'machine_action_required': 'no', 'controller_action_required': 'no', 'pause_safe': 'no', 'strong_safe_pause': 'no', 'next_stage': 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-runtime-executor-implementation-freeze', 'boot_action_authorized': 'no', 'boot_argument_substitution_authorized': 'no', 'builder_execution_authorized': 'no', 'builder_transport_authorized': 'no', 'chmod_remediation_authorized': 'no', 'evidence_cleanup_authorized': 'no', 'historical_probe_rerun_authorized': 'no', 'immutable_builder_modification_authorized': 'no', 'immutable_executor_modification_authorized': 'no', 'local_source_v4_build_authorized': 'no', 'manual_builder_execution_authorized': 'no', 'network_access_authorized': 'no', 'new_executor_execution_authorized': 'no', 'new_executor_transport_authorized': 'no', 'new_probe_execution_authorized': 'no', 'new_probe_implementation_authorized': 'no', 'new_probe_transport_authorized': 'no', 'package_action_authorized': 'no', 'persistent_configuration_change_authorized': 'no', 'phase_2_start_authorized': 'no', 'read_only_probe_execution_authorized': 'no', 'read_only_probe_transport_authorized': 'no', 'reboot_authorized': 'no', 'remediation_implementation_authorized': 'no', 'repository_only_authority_effect_closure_and_strong_pause_review_authorized': 'no', 'repository_only_build_authorization_freeze_authorized': 'no', 'repository_only_fresh_revalidation_authorization_review_authorized': 'no', 'repository_only_resume_planning_boundary_review_authorized': 'no', 'repository_only_revalidation_design_freeze_authorized': 'no', 'repository_only_revalidation_design_review_authorized': 'no', 'repository_only_revalidation_probe_implementation_freeze_authorized': 'no', 'repository_only_revalidation_probe_implementation_review_authorized': 'no', 'repository_only_revalidation_result_review_authorized': 'no', 'repository_only_runtime_boundary_freeze_authorized': 'no', 'repository_only_runtime_boundary_review_authorized': 'no', 'repository_only_runtime_executor_design_freeze_authorized': 'no', 'repository_only_runtime_executor_design_review_authorized': 'no', 'repository_only_runtime_executor_implementation_failure_coverage_authorized': 'no', 'repository_only_runtime_executor_implementation_review_authorized': 'no', 'repository_only_transaction_contract_freeze_authorized': 'no', 'repository_only_transaction_contract_review_authorized': 'no', 'runtime_executor_rerun_authorized': 'no', 'slackpkg_mutation_authorized': 'no', 'step267_executor_rerun_authorized': 'no', 'target_observation_authorized': 'no', 'repository_only_runtime_executor_implementation_freeze_authorized': 'yes'} and len({x.split('\t')[0] for x in rows})==len(rows))
with tempfile.TemporaryDirectory(prefix='step305-review-') as directory:
 tmp=Path(directory)
 for args,ok in [([],False),(['--help'],True),(['--bogus'],False),(['--output-dir'],False),(['--output-dir',''],False),(['--output-dir','x','extra'],False)]:check('strict review CLI '+repr(args),(run(['bash',helper,*args]).returncode==0)==ok)
 out=tmp/'published';out.mkdir();call=run(['bash',helper,'--output-dir',out])
 check('full279 predecessor exact snapshot and private implementation before publish',call.returncode==0 and 'accepted_step304_revalidated\tPASS (279 passes, 0 failures)' in call.stdout)
 for suffix in ['-policy.json','-coverage.json','-step304-user-acceptance.json','.tsv']:
  check('exact review output '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
 before={p.name:p.read_bytes() for p in out.iterdir()}
 check('republication rejected without overwrites',run(['bash',helper,'--output-dir',out]).returncode!=0 and {p.name:p.read_bytes() for p in out.iterdir()}==before)
 link=tmp/'alias';link.symlink_to(out,target_is_directory=True)
 check('symlink output rejected',run(['bash',helper,'--output-dir',link]).returncode!=0)
 check('missing output rejected without creation',run(['bash',helper,'--output-dir',tmp/'absent']).returncode!=0 and not (tmp/'absent').exists())
 replica=tmp/'replica';replica.mkdir()
 for rel in sorted(set(accepted['sha256_bindings'])|set(own)|{'tests/reference/test-'+base+'-harness.sh'}):
  p=replica/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes((root/rel).read_bytes())
 rh=replica/helper.relative_to(root);rejected_out=tmp/'reject';rejected_out.mkdir()
 targets=[policy['freeze_path'],policy['design_path'],policy['contract_path'],'CHANGELOG.md']+list(own)
 for rel in targets:
  if rel==helper.relative_to(root).as_posix():continue
  p=replica/rel;data=p.read_bytes();p.write_bytes(data+b'\n');check('bound drift rejected before publish: '+p.name,run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(data)
 p=replica/policy['candidate_executor_path'];data=p.read_bytes();p.unlink();p.symlink_to(root/policy['candidate_executor_path'])
 check('same bytes executor symlink rejected before publish',run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and not list(rejected_out.iterdir()));p.unlink();p.write_bytes(data)
 for suffix in ['-policy.json','-coverage.json','-step304-user-acceptance.json','.tsv']:
  p=rejected_out/(base+suffix);p.write_bytes(b'preserved\n');check('occupied review output rejects '+suffix,run(['bash',rh,'--output-dir',rejected_out]).returncode!=0 and p.read_bytes()==b'preserved\n' and len(list(rejected_out.iterdir()))==1);p.unlink()
check('historical bytes preserved after executed private tests',history_valid())
for rel in list(own)+['tests/reference/test-'+base+'-harness.sh']:
 check('no trailing whitespace: '+Path(rel).name,all(x==x.rstrip() for x in (root/rel).read_text().splitlines()))
check('CHANGELOG confirms304 prepares305 without freeze or pause','## Phase 1 step305 ' in (root/'CHANGELOG.md').read_text() and 'a8bc533' in (root/'CHANGELOG.md').read_text() and 'pause_safe=false/strong_safe_pause=false' in (root/'CHANGELOG.md').read_text())
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
