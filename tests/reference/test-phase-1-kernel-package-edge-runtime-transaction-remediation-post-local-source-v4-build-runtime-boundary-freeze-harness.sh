#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import ast,copy,hashlib,json,re,shutil,subprocess,sys,tempfile
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review';own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze.md': '080bc1cd12411ce0f87e7bd26614c263ed3784f0626b28987388d27f875dd995', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze-policy.json': 'b467799112533335f1aa867d197c1d66db76fc41e5c7792111628bc1c3f5dfa2', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze.tsv': 'a9ce10a55a4c392fe93c4dc995e54818e845e7604e8a60650feb2bb35c4e231b', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze-boundary.json': '59907c7852b96de5be84f3358366971800d42ca2c8bd76ebb901738d12787931', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze.sh': '02177f332fd8f446ee1d0bc977859897920c72fb55fb970e91ded0a9b6515f30'}
fixture=root/'tests/fixtures/reference/acceptance/phase-1';policy_path=fixture/(base+'-policy.json');policy=json.loads(policy_path.read_text());previous=json.loads((fixture/(prior+'-policy.json')).read_text());accepted=policy['accepted_checkpoint'];helper=root/'tools/reference'/(base+'.sh');reviewed=policy['runtime_boundary_review'];frozen=policy['runtime_boundary_freeze'];executor=frozen['executor'];passes=0

def check(label,value):
 global passes
 if not value:raise SystemExit('FAIL: '+label)
 passes+=1;print('PASS: '+label,flush=True)
def run(args):return subprocess.run([str(x) for x in args],capture_output=True,text=True)
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def accepted_bytes(rel):
 p=root/rel
 if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):return None
 data=p.read_bytes()
 if rel=='CHANGELOG.md':
  position=data.find(b'## Phase 1 step 296 ')
  if position<0:return None
  data=data[position:]
 return data
bindings=accepted['sha256_bindings']
check('all1262 accepted bytes and safe paths plus exact CHANGELOG tail bound',len(bindings)==accepted['repository_file_count']==1262 and all((data:=accepted_bytes(rel)) is not None and hashlib.sha256(data).hexdigest()==sha for rel,sha in bindings.items()))
critical={rel:bindings[rel] for rel in ['docs/reference/'+prior+'.md','tests/fixtures/reference/acceptance/phase-1/'+prior+'-policy.json','tests/fixtures/reference/acceptance/phase-1/'+prior+'-boundary.json','tests/fixtures/reference/acceptance/phase-1/'+prior+'.tsv','tools/reference/'+prior+'.sh','tests/reference/test-'+prior+'-harness.sh',policy['implementation']['probe_path'],executor['historical_executor_path'],'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh','tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh',policy['revalidation_result']['observation_path'],policy['revalidation_result']['provenance_path'],policy['revalidation_result']['display_path']]}
for rel,sha in (critical|own_hashes).items():
 p=root/rel;check('exact regular artifact: '+p.name,p.is_file() and not p.is_symlink() and p.resolve()==p.absolute() and digest(p)==sha)
for p in [helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
check('freeze follows accepted boundary review',policy['schema']==1 and policy['step']==297 and policy['scenario']==previous['next_stage']==base and policy['review_only'] and policy['review_status']=='PASS')
check('confirmed 8962ebc complete252 predecessor',accepted['step']==296 and accepted['commit']=='8962ebc' and accepted['acceptance_result']=='PASS (252 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('prefix scope without invented full commit',accepted['commit_identity_scope']=='user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted)
for key in ['accepted_build_result','accepted_local_source_v4','accepted_authorization_closure','accepted_runtime_boundary_after_pause','historical_observation','accepted_step288_pause_remains_valid_as_historical_checkpoint','fresh_boundary','preservation','revalidation_boundary','future_runtime_boundary','roadmap','strong_pause_completion_conditions','design','design_path','implementation','implementation_path','observation_authorization','observation_authorization_path','accepted_implementation_freeze_delta','revalidation_result','observation_authority_closure','runtime_boundary_review','runtime_boundary_path']:check('unchanged accepted historical boundary: '+key,policy[key]==previous[key])
check('both whole boundary fixtures agree with policy',json.loads((root/policy['runtime_boundary_path']).read_text())==reviewed and json.loads((root/policy['runtime_boundary_freeze_path']).read_text())==frozen)
check('only exact three-field freeze delta',sorted(key for key in set(reviewed)|set(frozen) if reviewed.get(key)!=frozen.get(key))==policy['accepted_runtime_boundary_freeze_delta']['changed_boundary_keys']==['next_stage','state','step'])
for key in ['source','candidate','executor','accepted_observation_authority_closure','historical_failure','required_future_stage_order','repository_fixture_oracle_scope','no_runtime_attempt_planned_in_289_298_route']:check('exact reviewed contract preserved: '+key,frozen[key]==reviewed[key])
check('delta adds no authority implementation or changed contract',all(value is False for key,value in policy['accepted_runtime_boundary_freeze_delta'].items() if key!='changed_boundary_keys'))
check('only repository closure review open',[key for key,value in policy['authorization'].items() if value]==['repository_only_authority_effect_closure_and_strong_pause_review_authorized'])
check('next closure matches roadmap',policy['next_stage']==frozen['next_stage']==previous['roadmap']['preferred_steps'][9]['stage'])
for key in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']:check('pending closure state: '+key,policy[key] is False and frozen[key] is False)
check('consumed observation never grants a new operation',frozen['accepted_observation_authority_closure']['all_operational_authority_closed'] and not frozen['accepted_observation_authority_closure']['retry_authorized'] and policy['fresh_boundary']['current_boot_id'] is None and frozen['source']['observation_is_point_in_time_not_current_or_continuous'])
check('current pkglist count and binding remain unobserved',all(frozen['candidate'][key] is None for key in ['current_pkglist_path','current_pkglist_sha256','current_candidate_count']) and not frozen['candidate']['current_binding_created'] and not frozen['candidate']['observed_v4_pkglist_generation_success'])
check('future executor absent and no design implementation transport execution grant',not (root/executor['future_executor_path']).exists() and not (root/executor['future_executor_path']).is_symlink() and executor['future_executor_sha256'] is None and all(executor[key] is False for key in ['future_executor_installed','future_executor_design_implementation_authorized','future_executor_transport_authorized','future_executor_execution_authorized','historical_executor_rerun_authorized','consumed_step294_authority_reusable']))
for key in ['production_main_entered','production_builder_entered','production_host_guards_entered','production_constants_modified','live_target_observation_performed','historical_executor_sourced_or_executed','live_slackpkg_or_candidate_binding_performed']:check('acceptance excludes production action: '+key,policy['repository_acceptance_scope'][key] is False)
check('full252 complete1262 predecessor required',policy['repository_acceptance_scope']['accepted_predecessor_result']=='PASS (252 passes, 0 failures)' and policy['repository_acceptance_scope']['accepted_predecessor_complete_1262_file_bindings_required'])
python_source=helper.read_text().split("<<'PYFREEZE'\n",1)[1].rsplit('\nPYFREEZE',1)[0];nodes=[node for node in ast.parse(python_source).body if isinstance(node,ast.FunctionDef) and node.name=='validate_boundary_freeze']
check('one exact pure freeze validator extracted through AST',len(nodes)==1)
namespace={'json':json};exec(compile(ast.fix_missing_locations(ast.Module(body=nodes,type_ignores=[])),'exact-helper-freeze-validator','exec'),namespace);validate=namespace['validate_boundary_freeze'];expected_next=policy['next_stage']
before=(copy.deepcopy(reviewed),copy.deepcopy(frozen));check('actual pure validator accepts exact frozen boundary',validate(reviewed,frozen,expected_next) is True);check('pure validator preserves both inputs',(reviewed,frozen)==before)
def rejected(candidate,r=reviewed,next_value=expected_next):
 try:validate(r,candidate,next_value)
 except ValueError:return True
 return False
for key in frozen:
 bad=copy.deepcopy(frozen);bad.pop(key);check('actual validator rejects missing top-level field: '+key,rejected(bad))
 bad=copy.deepcopy(frozen);bad[key]='changed';check('actual validator rejects changed top-level field: '+key,rejected(bad))
for section in ['source','candidate','executor','accepted_observation_authority_closure','historical_failure']:
 for key,value in frozen[section].items():
  bad=copy.deepcopy(frozen);bad[section][key]=not value if isinstance(value,bool) else 'changed';check('actual validator rejects nested contract drift: '+section+'.'+key,rejected(bad))
for section,key,value in [('candidate','exact_target_candidate_count',True),('candidate','unexpected_header_candidate_count',False),('executor','future_executor_installed',0),('source','checksum_expected_row_count',9.0)]:
 bad=copy.deepcopy(frozen);bad[section][key]=value;check('actual validator rejects JSON type drift: '+section+'.'+key,rejected(bad))
check('actual validator rejects extra fields',rejected(frozen|{'extra':True}))
check('actual validator rejects wrong next-stage binding',rejected(frozen,next_value='wrong'))
for key,value in [('step',295),('state','wrong')]:check('actual validator requires reviewed checkpoint '+key,rejected(frozen,r=reviewed|{key:value}))
record_rows=[line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines()];record=dict(record_rows)
check('strict unique real-tab freeze record',all(len(row)==2 and all(row) for row in record_rows) and len(record_rows)==len(record))
check('record agrees with frozen boundary and accepted checkpoint',record['step']=='297' and record['accepted_checkpoint_commit']=='8962ebc' and record['boundary_state']==frozen['state'] and record['changed_boundary_keys']=='next_stage,state,step')
check('record authorizations consistent',all(record[key]==('yes' if value else 'no') for key,value in policy['authorization'].items()) and record['next_stage']==policy['next_stage'])
for args,expected_exit in [(['--help'],0),([],2),(['--bad'],2),(['--output-dir'],2),(['--output-dir',''],2),(['--help','extra'],2)]:check('strict freeze helper CLI '+repr(args),run(['bash',helper,*args]).returncode==expected_exit)
with tempfile.TemporaryDirectory(prefix='step297-freeze-') as directory:
 tmp=Path(directory);out=tmp/'output';out.mkdir();call=run(['bash',helper,'--output-dir',out])
 if call.returncode:print(call.stdout,call.stderr)
 check('full accepted252 suite succeeds before frozen boundary publication',call.returncode==0 and 'accepted_step296_revalidated\tPASS (252 passes, 0 failures)' in call.stdout)
 for suffix in ['-policy.json','.tsv','-boundary.json']:check('exact freeze publication '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
 check('helper reports preserved contracts no future executor and closed authority','source_candidate_executor_contracts_changed\tno' in call.stdout and 'future_executor_installed\tno' in call.stdout and 'all_operational_authority_closed\tyes' in call.stdout)
 before={p.name:p.read_bytes() for p in out.iterdir()};check('duplicate rejected without overwrite',run(['bash',helper,'--output-dir',out]).returncode!=0 and {p.name:p.read_bytes() for p in out.iterdir()}==before)
 link=tmp/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',helper,'--output-dir',link]).returncode!=0)
 nested=out/'nested';nested.mkdir();check('symlink ancestor rejected',run(['bash',helper,'--output-dir',link/'nested']).returncode!=0 and not list(nested.iterdir()))
 check('missing output directory rejected',run(['bash',helper,'--output-dir',tmp/'missing']).returncode!=0 and not (tmp/'missing').exists())
 replica=tmp/'replica';shutil.copytree(root,replica,ignore=shutil.ignore_patterns('.git'));rh=replica/helper.relative_to(root);rejected_out=tmp/'rejected';rejected_out.mkdir()
 for rel in list(critical)+[key for key in own_hashes if key!=helper.relative_to(root).as_posix()]+['README.md','data/config/slack-update.conf']:
  p=replica/rel;old=p.read_bytes();p.write_bytes(old+b'\n');call=run(['bash',rh,'--output-dir',rejected_out]);check('accepted/frozen byte drift rejected before publication: '+p.name,call.returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(old)
 p=replica/'CHANGELOG.md';old=p.read_bytes();p.write_bytes(old.replace(b'## Phase 1 step 296 ',b'## Phase 1 step 999 ',1));call=run(['bash',rh,'--output-dir',rejected_out]);check('changed accepted CHANGELOG history rejected',call.returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(old)
 p=replica/executor['future_executor_path'];p.write_text('#!/bin/bash\n');call=run(['bash',rh,'--output-dir',rejected_out]);check('unexpected future executor rejected before publication',call.returncode!=0 and not list(rejected_out.iterdir()));p.unlink()
 p.symlink_to(replica/executor['historical_executor_path']);call=run(['bash',rh,'--output-dir',rejected_out]);check('future executor symlink rejected before publication',call.returncode!=0 and not list(rejected_out.iterdir()));p.unlink()
check('actual immutable sources unchanged after acceptance',all(digest(root/rel)==sha for rel,sha in critical.items()) and not (root/executor['future_executor_path']).exists())
for rel in list(own_hashes)+['tests/reference/test-'+base+'-harness.sh']:check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
changelog=(root/'CHANGELOG.md').read_text();check('CHANGELOG confirms frozen boundary and pending closure','## Phase 1 step 297 ' in changelog and '8962ebc' in changelog and 'All operational authority remains closed' in changelog and '## Phase 1 step 296 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
