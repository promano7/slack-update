#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import ast
import copy
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze';own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review.md': '7a125a35305954cc8ffabba1152ca9c90b3a5f1b4ef84c8cf7713369c6887dab', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review-policy.json': 'ddce16fe5615349fac0d415a4a0ddf529ce64d3786a6861386131ce00a1b5d7f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review.tsv': '284c078f2cf383a2935820dfabd8aa2e3dbdac6109012198d943227d44f3bd34', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review-boundary.json': 'ae5dfd645b38120b645b8461f611a3c2bc50f57c05c3d125a64b3141f8ea832a', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-runtime-boundary-review.sh': '746bfa5cbfb762ff8a95bbd0bc1e64dbc61165cf32f501dadd45390f66fba68d'}
fixture=root/'tests/fixtures/reference/acceptance/phase-1';policy_path=fixture/(base+'-policy.json');policy=json.loads(policy_path.read_text());previous=json.loads((fixture/(prior+'-policy.json')).read_text());accepted=policy['accepted_checkpoint'];design=policy['design'];implementation=policy['implementation'];helper=root/'tools/reference'/(base+'.sh');probe=root/implementation['probe_path'];boundary=policy['runtime_boundary_review'];source=boundary['source'];candidate=boundary['candidate'];executor=boundary['executor'];passes=0

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
  position=data.find(b'## Phase 1 step 295 ')
  if position<0:return None
  data=data[position:]
 return data
bindings=accepted['sha256_bindings']
check('all1256 accepted bytes and safe paths plus exact CHANGELOG tail bound',len(bindings)==accepted['repository_file_count']==1256 and all((data:=accepted_bytes(rel)) is not None and hashlib.sha256(data).hexdigest()==sha for rel,sha in bindings.items()))
critical={rel:bindings[rel] for rel in ['docs/reference/'+prior+'.md','tests/fixtures/reference/acceptance/phase-1/'+prior+'-policy.json','tests/fixtures/reference/acceptance/phase-1/'+prior+'-observation.tsv','tests/fixtures/reference/acceptance/phase-1/'+prior+'-provenance.json','tests/fixtures/reference/acceptance/phase-1/'+prior+'-returned-display.txt','tests/fixtures/reference/acceptance/phase-1/'+prior+'.tsv','tools/reference/'+prior+'.sh','tests/reference/test-'+prior+'-harness.sh',implementation['probe_path'],design['historical_baseline_path'],'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh','tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh',executor['historical_executor_path']]}
for rel,sha in (critical|own_hashes).items():
 p=root/rel;check('exact regular artifact: '+p.name,p.is_file() and not p.is_symlink() and p.resolve()==p.absolute() and digest(p)==sha)
for p in [probe,helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
check('review follows accepted observation freeze',policy['schema']==1 and policy['step']==296 and policy['scenario']==previous['next_stage']==base and policy['review_only'] and policy['review_status']=='PASS')
check('confirmed eac059c complete263 predecessor',accepted['step']==295 and accepted['commit']=='eac059c' and accepted['acceptance_result']=='PASS (263 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('prefix scope without invented full commit',accepted['commit_identity_scope']=='user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted)
for key in ['accepted_build_result','accepted_local_source_v4','accepted_authorization_closure','accepted_runtime_boundary_after_pause','historical_observation','accepted_step288_pause_remains_valid_as_historical_checkpoint','fresh_boundary','preservation','revalidation_boundary','future_runtime_boundary','roadmap','strong_pause_completion_conditions','design','design_path','implementation','implementation_path','observation_authorization','observation_authorization_path','accepted_implementation_freeze_delta','revalidation_result','observation_authority_closure']:check('unchanged accepted historical boundary: '+key,policy[key]==previous[key])
check('whole reviewed boundary fixture exact',json.loads((root/policy['runtime_boundary_path']).read_text())==boundary)
check('review state is neither implementation nor authorization',boundary['state']=='runtime-boundary-reviewed-not-frozen-not-implemented-not-authorized' and boundary['scope']=='repository-only-source-candidate-executor-boundary-review')
check('only repository boundary freeze open',[key for key,value in policy['authorization'].items() if value]==['repository_only_runtime_boundary_freeze_authorized'] and policy['authorization_scope']=='repository-runtime-boundary-freeze-only-all-operational-authority-closed')
for key in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']:check('reopened workstream state: '+key,policy[key] is False and boundary[key] is False)
check('no runtime planned in route',boundary['no_runtime_attempt_planned_in_289_298_route'] and boundary['current_operational_authority_closed'] and boundary['order_is_future_requirements_not_current_execution_plan'])
check('next freeze matches roadmap',policy['next_stage']==boundary['next_stage']==previous['roadmap']['preferred_steps'][8]['stage'])
for key in ['production_main_entered','production_builder_entered','production_host_guards_entered','production_constants_modified','live_target_observation_performed','historical_executor_sourced_or_executed','live_slackpkg_or_candidate_binding_performed']:check('acceptance excludes production action: '+key,policy['repository_acceptance_scope'][key] is False)
check('full263 complete1256 predecessor and synthetic oracle scope',policy['repository_acceptance_scope']['accepted_predecessor_result']=='PASS (263 passes, 0 failures)' and policy['repository_acceptance_scope']['accepted_predecessor_complete_1256_file_bindings_required'] and policy['repository_acceptance_scope']['synthetic_contract_oracle_only'] and boundary['repository_fixture_oracle_scope']=='text-and-contract-state-synthetic-review-only-not-production-selector-or-live-Slackpkg-proof')
check('source root URI exact',source['root']=='/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4' and source['uri']=='file://'+source['root']+'/')
check('manifest and target remain accepted anchors',source['manifest_sha256']==previous['accepted_local_source_v4']['tree_manifest_sha256']=='a4b0fc122c6274c7fdf70907661511bcf6ba475a2aa3bc46b96e5bcbf6ed3db8' and source['target_sha256']==candidate['expected_target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c')
check('canonical sidecar SHA independently derived',source['sidecar_sha256']==hashlib.sha256((source['manifest_sha256']+'  local-source-v4.tree.sha256\n').encode()).hexdigest()=='7cd7b99c730f388ddc949d22ad5ed98da703ea8050dfa31dc11456683f2176fc')
check('exact file directory inventory and owner modes',source['regular_files']==design['expected_regular_files'] and source['directories']==design['expected_directories'] and len(source['regular_files'])==11 and len(source['directories'])==6 and source['non_root_entry_count']==17 and source['owner_uid_gid']=='0:0' and source['regular_file_mode']=='444' and source['directory_mode']=='555')
check('priority trees and target path exact',source['priority_trees']==['patches','slackware64','extra','pasture','testing'] and source['target_relative_path']=='./slackware64/d/kernel-headers-6.18.45-x86-1.txz')
check('untagged nine-row path-last-field checksum contract',source['checksum_representation']=='untagged-gnu-md5sum-32-lowercase-hex-two-spaces-relative-path-last-field' and source['checksum_expected_row_count']==9)
for key in ['tagged_md5_records_forbidden','one_exact_binding_per_eligible_generated_file','checksum_package_line_ends_in_txz','external_sha256_manifest_and_target_sha_are_identity_anchors','compatibility_asc_non_authenticating','openpgp_signature_marker_forbidden','source_is_preserved_read_only_input','observation_is_point_in_time_not_current_or_continuous']:check('source contract member: '+key,source[key] is True)
check('no source mutation granted',source['source_edit_chmod_rebuild_or_overwrite_authorized'] is False)
check('accepted semantic observation is point in time',source['observation_path']==previous['revalidation_result']['observation_path'] and digest(root/source['observation_path'])==source['observation_sha256']=='68efaab51288791ddcd515e7438dab6db7cbbe25be750549ce0b0cacf55db832' and source['observed_boot_id']=='a5430a61-c988-4d52-9d5c-f20bb0a04016' and source['observation_provenance']=='semantic-transcription-of-user-returned-terminal-display' and policy['fresh_boundary']['current_boot_id'] is None)
check('accepted closure preserved',boundary['accepted_observation_authority_closure']==previous['observation_authority_closure'] and boundary['accepted_observation_authority_closure']['all_operational_authority_closed'])
expected_row=['slackware64','kernel-headers','6.18.45','x86','1','kernel-headers-6.18.45-x86-1','./slackware64/d','txz']
check('future exact eight target fields',candidate['expected_target_fields']==expected_row and candidate['row_field_names']==['priority_tree','name','version','arch','build','fullname','location','extension'])
check('future target-only counts exact',candidate['exact_target_candidate_count']==1 and all(candidate[key]==0 for key in ['unexpected_header_candidate_count','install_new_candidate_count','non_header_upgrade_candidate_count','configured_boot_upgrade_candidate_count']))
check('human-spaced download signal checks both streams',candidate['stdout_and_stderr_error_signal']=='Error downloading from ' and candidate['error_signal_case_insensitive'] and candidate['no_hyphenated_error_literal_substitution'])
for key in ['transaction_owned_workdir_and_temp_required','pkglist_absent_before_refresh_required','pkglist_regular_non_symlink_after_refresh_required','pkglist_nonempty_required','pkglist_generated_fresh_in_same_transaction_required','refresh_exit0_required','refresh_exit0_is_not_sufficient','pkglist_sha256_bound_before_apply_required','all_nonblank_rows_must_match_exact_safe_target_fields','missing_duplicate_extra_malformed_or_traversal_rows_rejected','archive_sha256_reverified_before_binding_and_apply','empty_historical_v2_pkglist_must_not_be_reused','metadata_formatter_remediation_is_not_runtime_generation_proof']:check('future candidate gate: '+key,candidate[key] is True)
check('no current pkglist count or binding invented',candidate['state']=='future-same-transaction-binding-required-not-observed' and candidate['binding_lifetime']=='same-future-runtime-transaction-only' and all(candidate[key] is None for key in ['current_pkglist_path','current_pkglist_sha256','current_candidate_count']) and not candidate['current_binding_created'] and not candidate['observed_v4_pkglist_generation_success'])
check('historical failure is zero-byte pkglist before apply',boundary['historical_failure']['fresh_pkglist_size_bytes']==0 and boundary['historical_failure']['fresh_pkglist_sha256']==hashlib.sha256(b'').hexdigest() and boundary['historical_failure']['exact_target_candidates']==0 and not boundary['historical_failure']['reference_apply_reached'] and not boundary['historical_failure']['v4_runtime_refresh_observed'])
check('future executor remains absent and has no hash',not (root/executor['future_executor_path']).exists() and not (root/executor['future_executor_path']).is_symlink() and executor['future_executor_sha256'] is None and not executor['future_executor_installed'])
check('historical executor immutable v3 old-boot design input',digest(root/executor['historical_executor_path'])==executor['historical_executor_sha256']=='deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d' and executor['historical_source_root'].endswith('/local-source-v3') and executor['historical_boot_argument']=='047e744d-d2ea-4d9a-8746-7734b58db3b2')
for key,value in executor.items():
 if isinstance(value,bool):check('executor boundary boolean: '+key,value is (key not in ['historical_executor_rerun_authorized','future_executor_installed','future_executor_design_implementation_authorized','future_executor_transport_authorized','future_executor_execution_authorized','consumed_step294_authority_reusable','predecessor_availability_independently_observed_now']))
old_executor=(root/executor['historical_executor_path']).read_text()
check('historical code contains old source identity',executor['historical_source_root'] in old_executor and executor['historical_source_manifest_sha256'] in old_executor and executor['historical_boot_argument'] in old_executor)
check('historical code checks human error text and candidate-before-apply', 'Error downloading from ' in old_executor and old_executor.index('\n    bind_candidate_set\n')<old_executor.index('\n    run_reference_apply\n'))
# Only extract this exact pure function; do not execute helper top-level or source an executor.
python_source=helper.read_text().split("<<'PYFREEZE'\n",1)[1].rsplit('\nPYFREEZE',1)[0];nodes=[node for node in ast.parse(python_source).body if isinstance(node,ast.FunctionDef) and node.name=='validate_runtime_boundary_fixture']
check('one exact pure review oracle extracted through AST',len(nodes)==1)
namespace={'re':re,'hashlib':hashlib};exec(compile(ast.fix_missing_locations(ast.Module(body=nodes,type_ignores=[])),'exact-helper-synthetic-review-oracle','exec'),namespace);validate=namespace['validate_runtime_boundary_fixture']
text=' '.join(expected_row)+'\n';valid=dict(source_manifest_sha256=source['manifest_sha256'],source_target_sha256=source['target_sha256'],source_checksum_format=source['checksum_representation'],source_preserved=True,fresh_transaction=True,pre_refresh_pkglist_absent=True,post_refresh_pkglist_regular=True,post_refresh_pkglist_non_symlink=True,refresh_exit=0,same_transaction_binding=True,all_unexpected_candidate_counts_zero=True,pkglist_text=text,bound_pkglist_sha256=hashlib.sha256(text.encode()).hexdigest(),refresh_stdout='',refresh_stderr='')
original=copy.deepcopy(valid);boundary_original=copy.deepcopy(boundary)
check('actual pure review oracle accepts exact synthetic fixture',validate(valid,boundary) is True)
check('pure oracle preserves both input objects',valid==original and boundary==boundary_original)
def rejected(f):
 try:validate(f,boundary)
 except ValueError:return True
 return False
for key in ['source_manifest_sha256','source_target_sha256','source_checksum_format','source_preserved','fresh_transaction','pre_refresh_pkglist_absent','post_refresh_pkglist_regular','post_refresh_pkglist_non_symlink','refresh_exit','same_transaction_binding','all_unexpected_candidate_counts_zero']:
 value=valid[key];bad=valid|{key:False if isinstance(value,bool) else 1 if isinstance(value,int) else 'changed'};check('oracle rejects changed future gate: '+key,rejected(bad));bad=valid.copy();bad.pop(key);check('oracle rejects missing future gate: '+key,rejected(bad))
for key in ['source_preserved','fresh_transaction','pre_refresh_pkglist_absent','post_refresh_pkglist_regular','post_refresh_pkglist_non_symlink','same_transaction_binding','all_unexpected_candidate_counts_zero']:check('oracle rejects integer as boolean: '+key,rejected(valid|{key:1}))
check('oracle rejects bool as refresh exit',rejected(valid|{'refresh_exit':False}))
malformed=[('empty',''),('whitespace',' \n\t\n'),('duplicate',text*2),('extra-ninth-field',text.rstrip()+' extra\n'),('missing-eighth-field',' '.join(expected_row[:-1])+'\n'),('tagged-MD5','MD5 (./slackware64/d/kernel-headers-6.18.45-x86-1.txz) = '+'0'*32+'\n')]
for i in range(8):
 row=expected_row.copy();row[i]='wrong';malformed.append(('wrong-field-'+str(i),' '.join(row)+'\n'))
for label,row in [('other-header',['slackware64','kernel-headers','6.18.44','x86','1','kernel-headers-6.18.44-x86-1','./slackware64/d','txz']),('boot-generic',['slackware64','kernel-generic','6.18.45','x86_64','1','kernel-generic-6.18.45-x86_64-1','./slackware64/a','txz']),('install-new',['extra','new-package','1','x86','1','new-package-1-x86-1','./extra','txz'])]:malformed.append((label,text+' '.join(row)+'\n'))
for location in ['../slackware64/d','./slackware64/../d','/slackware64/d']:
 row=expected_row.copy();row[6]=location;malformed.append(('unsafe-location-'+location,' '.join(row)+'\n'))
for label,text_bad in malformed:check('oracle rejects pkglist shape with matching synthetic SHA: '+label,rejected(valid|{'pkglist_text':text_bad,'bound_pkglist_sha256':hashlib.sha256(text_bad.encode()).hexdigest()}))
for stream in ['refresh_stdout','refresh_stderr']:
 for signal in ['Error downloading from file://source/','ERROR DOWNLOADING FROM file://source/','prefix error Downloading From file://source/ suffix']:check('oracle rejects '+stream+' human download error: '+signal,rejected(valid|{stream:signal}))
for value in ['0'*64,valid['bound_pkglist_sha256'][:-1],valid['bound_pkglist_sha256'].upper(),'not-a-sha']:check('oracle rejects invalid or mismatched pkglist binding '+value[:8],rejected(valid|{'bound_pkglist_sha256':value}))
check('oracle rejects pkglist byte drift even with valid row',rejected(valid|{'pkglist_text':text+'\n'}))
space_text='\n  '+'\t'.join(expected_row)+'  \n\n';check('oracle accepts ordinary whitespace and blank rows when bytes bound',validate(valid|{'pkglist_text':space_text,'bound_pkglist_sha256':hashlib.sha256(space_text.encode()).hexdigest()},boundary))
record_rows=[line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines()];record=dict(record_rows)
check('strict unique real-tab review record',all(len(row)==2 and all(row) for row in record_rows) and len(record_rows)==len(record))
check('record agrees with unobserved runtime boundary',record['step']=='296' and record['accepted_checkpoint_commit']=='eac059c' and record['v4_runtime_pkglist_generation_observed']==record['candidate_binding_created']==record['future_executor_installed']=='no' and record['all_operational_authority_closed']=='yes')
check('record authorizations consistent',all(record[key]==('yes' if value else 'no') for key,value in policy['authorization'].items()) and record['next_stage']==policy['next_stage'])
for args,expected_exit in [(['--help'],0),([],2),(['--bad'],2),(['--output-dir'],2),(['--output-dir',''],2),(['--help','extra'],2)]:check('strict review helper CLI '+repr(args),run(['bash',helper,*args]).returncode==expected_exit)
with tempfile.TemporaryDirectory(prefix='step296-review-') as directory:
 tmp=Path(directory);out=tmp/'output';out.mkdir();source_before=probe.read_bytes();call=run(['bash',helper,'--output-dir',out])
 if call.returncode:print(call.stdout,call.stderr)
 check('full accepted263 suite succeeds before boundary publication',call.returncode==0 and 'accepted_step295_revalidated\tPASS (263 passes, 0 failures)' in call.stdout)
 for suffix in ['-policy.json','.tsv','-boundary.json']:check('exact review publication '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
 check('helper reports no runtime and all operational authority closed','current_candidate_binding_created\tno' in call.stdout and 'future_executor_installed\tno' in call.stdout and 'all_operational_authority_closed\tyes' in call.stdout and 'machine_action_required\tno' in call.stdout)
 check('actual probe unchanged after acceptance',probe.read_bytes()==source_before)
 before={p.name:p.read_bytes() for p in out.iterdir()};check('duplicate rejected without overwrite',run(['bash',helper,'--output-dir',out]).returncode!=0 and {p.name:p.read_bytes() for p in out.iterdir()}==before)
 link=tmp/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',helper,'--output-dir',link]).returncode!=0)
 nested=out/'nested';nested.mkdir();check('symlink output ancestor rejected',run(['bash',helper,'--output-dir',link/'nested']).returncode!=0 and not list(nested.iterdir()))
 check('missing output directory rejected',run(['bash',helper,'--output-dir',tmp/'missing']).returncode!=0 and not (tmp/'missing').exists())
 replica=tmp/'replica';shutil.copytree(root,replica,ignore=shutil.ignore_patterns('.git'));rh=replica/helper.relative_to(root);rejected_out=tmp/'rejected';rejected_out.mkdir()
 for rel in list(critical)+[key for key in own_hashes if key!=helper.relative_to(root).as_posix()]+['README.md','data/config/slack-update.conf']:
  p=replica/rel;old=p.read_bytes();p.write_bytes(old+b'\n');call=run(['bash',rh,'--output-dir',rejected_out]);check('accepted/boundary byte drift rejected before publication: '+p.name,call.returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(old)
 p=replica/'CHANGELOG.md';old=p.read_bytes();p.write_bytes(old.replace(b'## Phase 1 step 295 ',b'## Phase 1 step 999 ',1));call=run(['bash',rh,'--output-dir',rejected_out]);check('changed accepted CHANGELOG history rejected',call.returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(old)
 for section,key,value in [('authorization','new_probe_execution_authorized',True),('authorization','runtime_attempt_authorized',True),('observation_authority_closure','retry_authorized',True),('fresh_boundary','current_boot_id',source['observed_boot_id'])]:
  p=replica/policy_path.relative_to(root);old=p.read_bytes();bad=json.loads(old);bad[section][key]=value;p.write_text(json.dumps(bad)+'\n');call=run(['bash',rh,'--output-dir',rejected_out]);check('unauthorized runtime/closure drift rejected: '+key,call.returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(old)
check('no future executor created during acceptance',not (root/executor['future_executor_path']).exists() and digest(root/executor['historical_executor_path'])==executor['historical_executor_sha256'])
for rel in list(own_hashes)+['tests/reference/test-'+base+'-harness.sh']:check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
changelog=(root/'CHANGELOG.md').read_text();check('CHANGELOG confirms accepted freeze and pending boundary closure','## Phase 1 step 296 ' in changelog and 'eac059c' in changelog and 'All operational authority remains closed' in changelog and '## Phase 1 step 295 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
