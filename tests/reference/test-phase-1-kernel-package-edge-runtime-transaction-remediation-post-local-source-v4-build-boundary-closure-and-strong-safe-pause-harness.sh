#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import ast,copy,hashlib,json,re,shutil,subprocess,sys,tempfile
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-freeze';own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause.md': '27177ec4720aaf1cad2e2dde91720edf4469ff226f6725f7c1a7ab204e48bf75', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause-policy.json': 'c033709d29dbced901c55faf33f9620e1ea52c9fa9ddb996cc9cd5577527ca1c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause.tsv': '55ae719ca25356182af33e4cd4007514fec864b958c7e812aa48a2dd6bb7dc81', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause-closure.json': '624c83e678102f92eb7859083c61a333015eca61a3676133a41ee709cdaf98f0', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-boundary-closure-and-strong-safe-pause.sh': '4fc04e4a7f7b87df40de0665aa0c4e9e9291d986762494e72b653e96b8a251ac'}
fixture=root/'tests/fixtures/reference/acceptance/phase-1';policy_path=fixture/(base+'-policy.json');policy=json.loads(policy_path.read_text());previous=json.loads((fixture/(prior+'-policy.json')).read_text());accepted=policy['accepted_checkpoint'];helper=root/'tools/reference'/(base+'.sh');reviewed=policy['runtime_boundary_review'];frozen=policy['runtime_boundary_freeze'];executor=frozen['executor'];closure=policy['boundary_closure'];passes=0

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
  position=data.find(b'## Phase 1 step 297 ')
  if position<0:return None
  data=data[position:]
 return data
bindings=accepted['sha256_bindings']
check('all1268 accepted bytes and safe paths plus exact CHANGELOG tail bound',len(bindings)==accepted['repository_file_count']==1268 and all((data:=accepted_bytes(rel)) is not None and hashlib.sha256(data).hexdigest()==sha for rel,sha in bindings.items()))
critical={rel:bindings[rel] for rel in ['docs/reference/'+prior+'.md','tests/fixtures/reference/acceptance/phase-1/'+prior+'-policy.json','tests/fixtures/reference/acceptance/phase-1/'+prior+'-boundary.json','tests/fixtures/reference/acceptance/phase-1/'+prior+'.tsv','tools/reference/'+prior+'.sh','tests/reference/test-'+prior+'-harness.sh',policy['implementation']['probe_path'],executor['historical_executor_path'],'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh','tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh',policy['revalidation_result']['observation_path'],policy['revalidation_result']['provenance_path'],policy['revalidation_result']['display_path']]}
for rel,sha in (critical|own_hashes).items():
 p=root/rel;check('exact regular artifact: '+p.name,p.is_file() and not p.is_symlink() and p.resolve()==p.absolute() and digest(p)==sha)
for p in [helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
check('freeze follows accepted boundary review',policy['schema']==1 and policy['step']==298 and policy['scenario']==previous['next_stage']==base and policy['review_only'] and policy['review_status']=='PASS')
check('confirmed 195d8dd complete308 predecessor',accepted['step']==297 and accepted['commit']=='195d8dd' and accepted['acceptance_result']=='PASS (308 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('prefix scope without invented full commit',accepted['commit_identity_scope']=='user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted)
for key in ['accepted_build_result','accepted_local_source_v4','accepted_authorization_closure','accepted_runtime_boundary_after_pause','historical_observation','accepted_step288_pause_remains_valid_as_historical_checkpoint','fresh_boundary','preservation','revalidation_boundary','future_runtime_boundary','roadmap','strong_pause_completion_conditions','design','design_path','implementation','implementation_path','observation_authorization','observation_authorization_path','accepted_implementation_freeze_delta','revalidation_result','observation_authority_closure','runtime_boundary_review','runtime_boundary_path','runtime_boundary_freeze','runtime_boundary_freeze_path','accepted_runtime_boundary_freeze_delta']:check('unchanged accepted historical boundary: '+key,policy[key]==previous[key])
check('both whole boundary fixtures agree with policy',json.loads((root/policy['runtime_boundary_path']).read_text())==reviewed and json.loads((root/policy['runtime_boundary_freeze_path']).read_text())==frozen)
check('only exact three-field freeze delta',sorted(key for key in set(reviewed)|set(frozen) if reviewed.get(key)!=frozen.get(key))==policy['accepted_runtime_boundary_freeze_delta']['changed_boundary_keys']==['next_stage','state','step'])
for key in ['source','candidate','executor','accepted_observation_authority_closure','historical_failure','required_future_stage_order','repository_fixture_oracle_scope','no_runtime_attempt_planned_in_289_298_route']:check('exact reviewed contract preserved: '+key,frozen[key]==reviewed[key])
check('delta adds no authority implementation or changed contract',all(value is False for key,value in policy['accepted_runtime_boundary_freeze_delta'].items() if key!='changed_boundary_keys'))
check('every current authority closed',policy['authorization']==closure['authorization'] and set(policy['authorization'])==set(previous['authorization']) and all(value is False for value in policy['authorization'].values()))
check('no automatic step or repository authority from future stage',policy['automatic_next_step_opened'] is False and policy['next_stage']==closure['resume']['next_repository_stage'] and closure['resume']['automatic_next_step_opened'] is False)
check('strong pause is reviewed eligibility with user confirmation pending',policy['pause_safe'] is True and policy['strong_safe_pause'] is True and policy['user_step298_checkpoint_confirmed'] is False and policy['strong_safe_pause_scope']=='reviewed-workstream-closure-eligibility-pending-user-step298-checkpoint-confirmation' and not closure['pause']['prepared_snapshot_is_confirmed_user_checkpoint'])
for key in ['machine_action_required','controller_action_required']:check('no machine/controller action: '+key,policy[key] is False and closure['pause'][key] is False)
check('whole closure fixture matches policy',json.loads((root/policy['boundary_closure_path']).read_text())==closure)
check('live bindings expired without current boot claim',policy['active_runtime_boundary_after_pause']['prior_target_binding_state']=='expired-at-workstream-closure' and policy['active_runtime_boundary_after_pause']['current_boot_id'] is None and policy['active_runtime_boundary_after_pause']['old_vm_boot_continuity_required_after_closure'] is False)
check('closure independent of later Slackware-current refresh',not closure['pause']['pause_depends_on_current_boot_or_mirror'] and not closure['pause']['later_slackware_current_publication_invalidates_completed_checkpoint'] and closure['pause']['later_publication_may_invalidate_live_state_for_future_work'] and closure['pause']['completed_checkpoint_is_historical_and_stable'])
check('no unfinished transaction or cleanup obligation',not any(closure['effects'][key] for key in ['production_transaction_in_flight','unresolved_transaction','unreviewed_partial_publication','required_production_cleanup','required_controller_cleanup','pending_machine_obligations','pending_controller_obligations']))
check('controller capture and failed evidence preserved as completed evidence',closure['effects']['controller_capture_preserved_no_cleanup_authorized'] and closure['effects']['historical_failed_v2_evidence_preserved_not_pending_transaction'] and closure['effects']['no_independent_post_return_host_inspection_claim'])
check('frozen boundary SHA remains exact',digest(root/closure['preservation']['frozen_boundary_path'])==closure['preservation']['frozen_boundary_sha256'])
check('not project or Phase2 acceptance',not any(closure['runtime'][key] for key in ['phase1_matrix_complete','kernel_package_edge_complete','phase2_authorized']) and not closure['pause']['project_acceptance_complete'])
check('consumed observation never grants a new operation',frozen['accepted_observation_authority_closure']['all_operational_authority_closed'] and not frozen['accepted_observation_authority_closure']['retry_authorized'] and policy['fresh_boundary']['current_boot_id'] is None and frozen['source']['observation_is_point_in_time_not_current_or_continuous'])
check('current pkglist count and binding remain unobserved',all(frozen['candidate'][key] is None for key in ['current_pkglist_path','current_pkglist_sha256','current_candidate_count']) and not frozen['candidate']['current_binding_created'] and not frozen['candidate']['observed_v4_pkglist_generation_success'])
check('future executor absent and no design implementation transport execution grant',not (root/executor['future_executor_path']).exists() and not (root/executor['future_executor_path']).is_symlink() and executor['future_executor_sha256'] is None and all(executor[key] is False for key in ['future_executor_installed','future_executor_design_implementation_authorized','future_executor_transport_authorized','future_executor_execution_authorized','historical_executor_rerun_authorized','consumed_step294_authority_reusable']))
for key in ['production_main_entered','production_builder_entered','production_host_guards_entered','production_constants_modified','live_target_observation_performed','historical_executor_sourced_or_executed','live_slackpkg_or_candidate_binding_performed']:check('acceptance excludes production action: '+key,policy['repository_acceptance_scope'][key] is False)
check('full308 complete1268 predecessor required',policy['repository_acceptance_scope']['accepted_predecessor_result']=='PASS (308 passes, 0 failures)' and policy['repository_acceptance_scope']['accepted_predecessor_complete_1268_file_bindings_required'])
python_source=helper.read_text().split("<<'PYFREEZE'\n",1)[1].rsplit('\nPYFREEZE',1)[0];nodes=[node for node in ast.parse(python_source).body if isinstance(node,ast.FunctionDef) and node.name=='validate_pause_closure']
check('one exact pure closure gate extracted through AST',len(nodes)==1)
namespace={'json':json};exec(compile(ast.fix_missing_locations(ast.Module(body=nodes,type_ignores=[])),'exact-helper-pause-closure-gate','exec'),namespace);validate=namespace['validate_pause_closure']
before=(copy.deepcopy(closure),copy.deepcopy(previous));check('actual pure gate accepts complete reviewed closure',validate(closure,previous) is True);check('pure validator preserves inputs',(closure,previous)==before)
def rejected(candidate,accepted_policy=previous):
 try:validate(candidate,accepted_policy)
 except (ValueError,KeyError):return True
 return False
for key in closure:
 bad=copy.deepcopy(closure);bad.pop(key);check('closure gate rejects missing top-level field: '+key,rejected(bad))
 bad=copy.deepcopy(closure);bad[key]='changed';check('closure gate rejects changed top-level field: '+key,rejected(bad))
for section in ['observation','effects','preservation','runtime','pause','resume']:
 for key,value in closure[section].items():
  bad=copy.deepcopy(closure);bad[section][key]=not value if isinstance(value,bool) else 'changed';check('closure gate rejects changed condition: '+section+'.'+key,rejected(bad))
for key in closure['authorization']:
 bad=copy.deepcopy(closure);bad['authorization'][key]=True;check('closure gate rejects reopened authority: '+key,rejected(bad))
for section,key,value in [('effects','required_production_cleanup',0),('observation','reviewed_invocations',True),('pause','strong_safe_pause',1),('observation','exit_status',False)]:
 bad=copy.deepcopy(closure);bad[section][key]=value;check('closure gate rejects JSON type drift: '+section+'.'+key,rejected(bad))
check('closure gate rejects extra top-level fields',rejected(closure|{'extra':True}))
for key,value in [('all_operational_authority_closed',False),('no_required_production_cleanup_identified',False)]:
 bad=copy.deepcopy(previous);bad['observation_authority_closure'][key]=value;check('closure gate requires accepted observation/effect closure: '+key,rejected(closure,bad))
for key,value in [('status','FAIL'),('probe_exit_status',1)]:
 bad=copy.deepcopy(previous);bad['revalidation_result'][key]=value;check('closure gate requires complete accepted result: '+key,rejected(closure,bad))
for key in previous['revalidation_result']['no_effect_fields']:
 bad=copy.deepcopy(previous);bad['revalidation_result']['fixed_return_values'][key]='yes';check('closure gate rejects accepted effect contradiction: '+key,rejected(closure,bad))
record_rows=[line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines()];record=dict(record_rows)
check('strict unique real-tab freeze record',all(len(row)==2 and all(row) for row in record_rows) and len(record_rows)==len(record))
check('record agrees with frozen boundary and accepted checkpoint',record['step']=='298' and record['accepted_checkpoint_commit']=='195d8dd' and record['closure_state']==closure['state'] and record['user_step298_checkpoint_confirmed']=='no')
check('record authorizations consistent',all(record[key]==('yes' if value else 'no') for key,value in policy['authorization'].items()) and record['next_stage']==policy['next_stage'])
for args,expected_exit in [(['--help'],0),([],2),(['--bad'],2),(['--output-dir'],2),(['--output-dir',''],2),(['--help','extra'],2)]:check('strict freeze helper CLI '+repr(args),run(['bash',helper,*args]).returncode==expected_exit)
with tempfile.TemporaryDirectory(prefix='step298-freeze-') as directory:
 tmp=Path(directory);out=tmp/'output';out.mkdir();call=run(['bash',helper,'--output-dir',out])
 if call.returncode:print(call.stdout,call.stderr)
 check('full accepted308 suite succeeds before frozen boundary publication',call.returncode==0 and 'accepted_step297_revalidated\tPASS (308 passes, 0 failures)' in call.stdout)
 for suffix in ['-policy.json','.tsv','-closure.json']:check('exact freeze publication '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
 check('helper reports preserved contracts no future executor and closed authority','user_step298_checkpoint_confirmed\tno' in call.stdout and 'all_authority_closed\tyes' in call.stdout and 'strong_safe_pause\tyes' in call.stdout)
 before={p.name:p.read_bytes() for p in out.iterdir()};check('duplicate rejected without overwrite',run(['bash',helper,'--output-dir',out]).returncode!=0 and {p.name:p.read_bytes() for p in out.iterdir()}==before)
 link=tmp/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',helper,'--output-dir',link]).returncode!=0)
 nested=out/'nested';nested.mkdir();check('symlink ancestor rejected',run(['bash',helper,'--output-dir',link/'nested']).returncode!=0 and not list(nested.iterdir()))
 check('missing output directory rejected',run(['bash',helper,'--output-dir',tmp/'missing']).returncode!=0 and not (tmp/'missing').exists())
 replica=tmp/'replica';shutil.copytree(root,replica,ignore=shutil.ignore_patterns('.git'));rh=replica/helper.relative_to(root);rejected_out=tmp/'rejected';rejected_out.mkdir()
 for rel in list(critical)+[key for key in own_hashes if key!=helper.relative_to(root).as_posix()]+['README.md','data/config/slack-update.conf']:
  p=replica/rel;old=p.read_bytes();p.write_bytes(old+b'\n');call=run(['bash',rh,'--output-dir',rejected_out]);check('accepted/frozen byte drift rejected before publication: '+p.name,call.returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(old)
 p=replica/'CHANGELOG.md';old=p.read_bytes();p.write_bytes(old.replace(b'## Phase 1 step 297 ',b'## Phase 1 step 999 ',1));call=run(['bash',rh,'--output-dir',rejected_out]);check('changed accepted CHANGELOG history rejected',call.returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(old)
 p=replica/executor['future_executor_path'];p.write_text('#!/bin/bash\n');call=run(['bash',rh,'--output-dir',rejected_out]);check('unexpected future executor rejected before publication',call.returncode!=0 and not list(rejected_out.iterdir()));p.unlink()
 p.symlink_to(replica/executor['historical_executor_path']);call=run(['bash',rh,'--output-dir',rejected_out]);check('future executor symlink rejected before publication',call.returncode!=0 and not list(rejected_out.iterdir()));p.unlink()
check('actual immutable sources unchanged after acceptance',all(digest(root/rel)==sha for rel,sha in critical.items()) and not (root/executor['future_executor_path']).exists())
for rel in list(own_hashes)+['tests/reference/test-'+base+'-harness.sh']:check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
changelog=(root/'CHANGELOG.md').read_text();check('CHANGELOG confirms conditional closure without premature user checkpoint','## Phase 1 step 298 ' in changelog and '195d8dd' in changelog and 'Every current authorization false' in changelog and '## Phase 1 step 297 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
