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
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-authorization';own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze.md': '2837b4feb553b487985d9d06d21a8a63a0c84e858b271490ec3f074dde57b735', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze-policy.json': '7ca69d1a95bcfa2258a2588f04c75c8ef35d7776d92517342bd4039fe69efd05', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze.tsv': 'a5527f85203e1808a746cc49c1d61fe0e13d5584c27422aecce6619d9eb0d4e8', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze-observation.tsv': '68efaab51288791ddcd515e7438dab6db7cbbe25be750549ce0b0cacf55db832', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze-provenance.json': '91c68d091af1a17b635144ebca0cd513a54034f704e02ad3d47cf98431e6647f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze-returned-display.txt': 'fd0f4746fe4d06d4423bfbcd453c2c6ef3ff3889894b3f1d44e0a39e8c13425e', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-freeze.sh': '5087005f4ed348fdac898527a62cdd96918c07303d5e6e902dd0192a778dc793'}
fixture=root/'tests/fixtures/reference/acceptance/phase-1';policy_path=fixture/(base+'-policy.json');policy=json.loads(policy_path.read_text());previous=json.loads((fixture/(prior+'-policy.json')).read_text());accepted=policy['accepted_checkpoint'];design=policy['design'];implementation=policy['implementation'];helper=root/'tools/reference'/(base+'.sh');probe=root/implementation['probe_path'];result=policy['revalidation_result'];closure=policy['observation_authority_closure'];passes=0

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
  position=data.find(b'## Phase 1 step 294 ')
  if position<0:return None
  data=data[position:]
 return data
bindings=accepted['sha256_bindings']
check('all1248 accepted bytes and safe paths plus exact CHANGELOG tail bound',len(bindings)==accepted['repository_file_count']==1248 and all((data:=accepted_bytes(rel)) is not None and hashlib.sha256(data).hexdigest()==sha for rel,sha in bindings.items()))
critical={rel:bindings[rel] for rel in ['docs/reference/'+prior+'.md','tests/fixtures/reference/acceptance/phase-1/'+prior+'-policy.json','tests/fixtures/reference/acceptance/phase-1/'+prior+'-authorization.json','tests/fixtures/reference/acceptance/phase-1/'+prior+'.tsv','tools/reference/'+prior+'.sh','tests/reference/test-'+prior+'-harness.sh',implementation['probe_path'],design['historical_baseline_path'],'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh','tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh','tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh']}
for rel,sha in (critical|own_hashes).items():
 p=root/rel;check('exact regular artifact: '+p.name,p.is_file() and not p.is_symlink() and p.resolve()==p.absolute() and digest(p)==sha)
for p in [probe,helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
check('freeze follows accepted authorization success stage',policy['schema']==1 and policy['step']==295 and policy['scenario']==previous['next_stage']==base and policy['review_only'] and policy['review_status']=='PASS')
check('confirmed5d25edd complete180 predecessor',accepted['step']==294 and accepted['commit']=='5d25edd' and accepted['acceptance_result']=='PASS (180 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('prefix scope without invented full commit',accepted['commit_identity_scope']=='user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted)
for key in ['accepted_build_result','accepted_local_source_v4','accepted_authorization_closure','accepted_runtime_boundary_after_pause','historical_observation','accepted_step288_pause_remains_valid_as_historical_checkpoint','fresh_boundary','preservation','revalidation_boundary','future_runtime_boundary','roadmap','strong_pause_completion_conditions','design','design_path','implementation','implementation_path','observation_authorization','observation_authorization_path','accepted_implementation_freeze_delta']:check('unchanged accepted historical boundary: '+key,policy[key]==previous[key])
check('frozen source identity remains exact',digest(probe)==implementation['probe_sha256']==design['expected_derivation_sha256']=='4d1bc852cf0bfea9b5131687bbe5cf70703cae04ae73a342a4afc7192a8440db')
check('whole design and implementation fixtures preserved',json.loads((root/policy['design_path']).read_text())==design and json.loads((root/policy['implementation_path']).read_text())==implementation)
text=(root/result['observation_path']).read_text();provenance=json.loads((root/result['provenance_path']).read_text());display=(root/result['display_path']).read_text();fields=design['ordered_publication_fields'];expected=result['fixed_return_values']|{'fresh_boot_id':result['fresh_boot_id']}
check('reviewed frozen result/status/field identities',result['state']=='reviewed-and-frozen-point-in-time-observation' and result['status']=='PASS' and result['field_count']==50 and digest(root/result['observation_path'])==result['observation_sha256']==provenance['normalized_observation_sha256']=='68efaab51288791ddcd515e7438dab6db7cbbe25be750549ce0b0cacf55db832')
check('fifty ordered distinct fields and49 fixed expected values',len(fields)==len(set(fields))==50 and len(result['fixed_return_values'])==49 and set(expected)==set(fields))
# Compile only the exact pure validator AST; no helper module action is executed.
helper_source=helper.read_text();python_source=helper_source.split("<<'PYFREEZE'\n",1)[1].rsplit('\nPYFREEZE',1)[0];module=ast.parse(python_source);nodes=[node for node in module.body if isinstance(node,ast.FunctionDef) and node.name=='validate_observation_text']
check('one exact pure validator extracted without module execution',len(nodes)==1)
namespace={'re':re};exec(compile(ast.fix_missing_locations(ast.Module(body=nodes,type_ignores=[])),'exact-helper-pure-validator','exec'),namespace);validate=namespace['validate_observation_text']
observation=validate(text,fields,expected)
check('actual helper pure validator accepts complete frozen record',list(observation)==fields and len(observation)==50)
for key,value in result['fixed_return_values'].items():check('exact returned frozen value: '+key,observation[key]==value)
check('canonical freshly observed UUID and exit0',observation['fresh_boot_id']==result['fresh_boot_id']==provenance['boot_id']=='a5430a61-c988-4d52-9d5c-f20bb0a04016' and bool(re.fullmatch(r'[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}',observation['fresh_boot_id'])) and result['probe_exit_status']==provenance['exit_status']==0)
sidecar=hashlib.sha256((observation['local_source_v4_tree_manifest_sha256']+'  local-source-v4.tree.sha256\n').encode()).hexdigest()
check('sidecar SHA independently derived from exact canonical bytes',observation['local_source_v4_tree_manifest_sidecar_sha256']==sidecar=='7cd7b99c730f388ddc949d22ad5ed98da703ea8050dfa31dc11456683f2176fc')
check('probe SHA and target digest match accepted source',observation['probe_sha256']==digest(probe) and observation['staged_target_sha256']==observation['local_source_v4_target_sha256']=='c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c')
check('nine no-effect fields exact and all no',result['no_effect_fields']==provenance['nine_no_effect_fields_reviewed']==fields[-9:] and all(observation[key]=='no' for key in fields[-9:]))
check('compatibility marker non-authenticating',observation['local_source_v4_compatibility_asc_marker_verified']=='yes' and observation['local_source_v4_compatibility_asc_is_openpgp_signature']=='no')
check('semantic display provenance without original-byte claim',provenance['kind']==result['provenance_kind']=='semantic-transcription-of-user-returned-terminal-display' and not result['original_stream_bytes_claimed'] and not provenance['original_stream_byte_identity_claimed'] and not provenance['original_stream_interleaving_claimed'])
for key in ['original_stdout_file_bytes_supplied','original_stderr_file_bytes_supplied','original_exit_code_file_bytes_supplied','arch_transport_verification_output_supplied']:check('no invented original/transport evidence: '+key,provenance[key] is False)
check('explicit exit and semantic stderr provenance',provenance['exit_status_provenance']=='explicit-controller-envelope-in-user-returned-complete-display' and result['stderr_review_basis']==provenance['stderr_empty_basis']=='semantic-user-return-of-complete-issued-controller-display-not-independent-file-byte-inspection')
check('original capture path retained outside acceptance root',provenance['controller_capture_directory']=='/home/promano/Descargas/slack-update-step294-observation.JyZLmaXI' and not provenance['controller_capture_directory'].startswith('/var/tmp/slack-update-acceptance'))
check('display section transcription scope and digest explicit',provenance['display_section_sha256']==digest(root/result['display_path']) and provenance['preserved_display_scope']=='manually-preserved-output-section-with-insignificant-terminal-whitespace-normalized-not-full-message-bytes')
lines=display.splitlines();start=next(i for i,line in enumerate(lines) if line.startswith(fields[0]+' '));display_rows=[re.split(r'\s+',line.strip(),maxsplit=1) for line in lines[start:start+50]]
check('display semantic transcription exactly matches normalized fields',[row[0] for row in display_rows]==fields and dict(display_rows)==observation)
check('complete display ends with explicit exit0 and no displayed probe error',lines[start+50]=='post_v4_revalidation_attempt_exit_status        0' and lines[start+51]=='bash-5.3$' and len(lines)==start+52 and lines[0]==probe.name+': OK' and 'ERROR:' not in display)
check('builder SHA context not builder transport/execution claim',result['builder_sha_is_repository_context'] and provenance['builder_sha256_role']=='frozen-repository-context-not-transport-or-builder-execution-evidence' and observation['frozen_v4_builder_sha256']=='38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7')
check('point-in-time observation never current boot continuity',not result['current_boot_continuity_asserted'] and not closure['current_boot_continuity_asserted'] and policy['fresh_boundary']['current_boot_id'] is None and provenance['boot_id_scope']=='freshly-read-at-returned-invocation-not-current-or-continuously-preserved')
check('one reviewed invocation consumes correct grant',closure['authority_id']==previous['observation_authorization']['authority_id'] and closure['reviewed_invocation_count']==1 and closure['controller_release_issued'] and closure['state']=='one-observation-consumed-remaining-transport-and-operational-authority-revoked-after-return-review')
for key in ['probe_execution_authority_consumed','probe_transport_authority_revoked','remaining_observation_authority_revoked','all_operational_authority_closed','observation_success_accepted','no_required_production_cleanup_identified','controller_capture_preserved_no_cleanup_authorized','no_runtime_authority_from_success','original_grant_unchanged_as_historical_input']:check('reviewed closure member: '+key,closure[key] is True)
check('no retry or additional target observation',not closure['retry_authorized'] and not closure['additional_target_observation_authorized'])
check('only repository runtime boundary review open',[key for key,value in policy['authorization'].items() if value]==['repository_only_runtime_boundary_review_authorized'] and policy['authorization_scope']=='all-observation-transport-execution-and-runtime-authority-closed-repository-boundary-review-only')
check('conditional observation flags all closed after review',all(not policy['authorization'][key] for key in ['new_probe_transport_authorized','new_probe_execution_authorized','read_only_probe_transport_authorized','read_only_probe_execution_authorized','target_observation_authorized','repository_only_revalidation_result_review_authorized']))
check('next repository boundary matches roadmap',policy['next_stage']==previous['roadmap']['preferred_steps'][7]['stage'])
for key in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']:check('reopened workstream state: '+key,policy[key] is False)
for key in ['production_main_entered','production_builder_entered','production_host_guards_entered','production_constants_modified','live_target_observation_performed']:check('acceptance excludes production action: '+key,policy['repository_acceptance_scope'][key] is False)
check('full180 complete1248-byte predecessor acceptance required',policy['repository_acceptance_scope']['accepted_predecessor_result']=='PASS (180 passes, 0 failures)' and policy['repository_acceptance_scope']['accepted_predecessor_complete_1248_file_bindings_required'])
def rejected(candidate,order=fields,values=expected):
 try:validate(candidate,order,values)
 except ValueError:return True
 return False
rows=text.splitlines()
for key in fields:
 altered=''.join(k+'\t'+('changed' if k==key else observation[k])+'\n' for k in fields);check('actual pure validator rejects changed returned field: '+key,rejected(altered))
for label,candidate in [('missing','\n'.join(rows[:-1])+'\n'),('extra',text+rows[-1]+'\n'),('duplicate','\n'.join([rows[0],rows[0],*rows[2:]])+'\n'),('unsorted','\n'.join(reversed(rows))+'\n'),('spaces',text.replace('\t',' ',1)),('second-tab',text.replace('\t','\t\t',1)),('CRLF',text.replace('\n','\r\n')),('missing-final-LF',text[:-1]),('extra-final-LF',text+'\n'),('blank-value',text.replace('\tPASS\n','\t\n',1)),('missing-key',text.replace(fields[0],'',1))]:check('actual pure validator rejects malformed record: '+label,rejected(candidate))
bad=expected|{'fresh_boot_id':'BCFAC4FA-4E6E-450A-AA95-BD591A979B4E'};uppercase=''.join(key+'\t'+bad[key]+'\n' for key in fields)
check('UUID canonical guard rejects even if expected map changed',rejected(uppercase,fields,bad))
check('expected bindings must cover every field',rejected(text,fields,{key:value for key,value in expected.items() if key!='probe_sha256'}))
check('expected field-order cannot contain duplicate keys',rejected(text,[fields[0],fields[0],*fields[2:]],expected))
record_rows=[line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines()];record=dict(record_rows)
check('strict unique real-tab freeze record',all(len(row)==2 and all(row) for row in record_rows) and len(record_rows)==len(record))
check('record agrees with result/closure',record['step']=='295' and record['accepted_checkpoint_commit']=='5d25edd' and record['observed_boot_id']==observation['fresh_boot_id'] and record['probe_exit_status']=='0' and record['observation_sha256']==result['observation_sha256'] and record['all_operational_authority_closed']=='yes')
check('record authorizations consistent',all(record[key]==('yes' if value else 'no') for key,value in policy['authorization'].items()) and record['next_stage']==policy['next_stage'])
for args,expected_exit in [(['--help'],0),([],2),(['--bad'],2),(['--output-dir'],2),(['--output-dir',''],2),(['--help','extra'],2)]:check('strict freeze helper CLI '+repr(args),run(['bash',helper,*args]).returncode==expected_exit)
with tempfile.TemporaryDirectory(prefix='step295-freeze-') as directory:
 tmp=Path(directory);out=tmp/'output';out.mkdir();source_before=probe.read_bytes();call=run(['bash',helper,'--output-dir',out])
 check('full accepted180 suite succeeds before frozen result publication',call.returncode==0 and 'accepted_step294_revalidated\tPASS (180 passes, 0 failures)' in call.stdout)
 for suffix in ['-policy.json','.tsv','-observation.tsv','-provenance.json','-returned-display.txt']:check('exact freeze publication '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
 check('helper reports consumed/revoked authority and no machine work','probe_execution_authority_consumed\tyes' in call.stdout and 'probe_transport_authority_revoked\tyes' in call.stdout and 'all_operational_authority_closed\tyes' in call.stdout and 'machine_action_required\tno' in call.stdout)
 check('actual probe unchanged after acceptance',probe.read_bytes()==source_before)
 before={p.name:p.read_bytes() for p in out.iterdir()};check('duplicate rejected without overwrite',run(['bash',helper,'--output-dir',out]).returncode!=0 and {p.name:p.read_bytes() for p in out.iterdir()}==before)
 link=tmp/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',helper,'--output-dir',link]).returncode!=0)
 nested=out/'nested';nested.mkdir();check('symlink output ancestor rejected',run(['bash',helper,'--output-dir',link/'nested']).returncode!=0 and not list(nested.iterdir()))
 check('missing output directory rejected',run(['bash',helper,'--output-dir',tmp/'missing']).returncode!=0 and not (tmp/'missing').exists())
 replica=tmp/'replica';shutil.copytree(root,replica,ignore=shutil.ignore_patterns('.git'));rh=replica/helper.relative_to(root);rejected_out=tmp/'rejected';rejected_out.mkdir()
 for rel in list(critical)+[key for key in own_hashes if key!=helper.relative_to(root).as_posix()]+['README.md','data/config/slack-update.conf']:
  p=replica/rel;old=p.read_bytes();p.write_bytes(old+b'\n');call=run(['bash',rh,'--output-dir',rejected_out]);check('accepted/result/provenance byte drift rejected before publication: '+p.name,call.returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(old)
 p=replica/'CHANGELOG.md';old=p.read_bytes();p.write_bytes(old.replace(b'## Phase 1 step 294 ',b'## Phase 1 step 999 ',1));call=run(['bash',rh,'--output-dir',rejected_out]);check('changed accepted CHANGELOG history rejected',call.returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(old)
 for section,key,value in [('authorization','new_probe_execution_authorized',True),('authorization','new_probe_transport_authorized',True),('authorization','builder_execution_authorized',True),('revalidation_result','probe_exit_status',1),('revalidation_result','original_stream_bytes_claimed',True),('observation_authority_closure','all_operational_authority_closed',False),('observation_authority_closure','retry_authorized',True),('fresh_boundary','current_boot_id',observation['fresh_boot_id'])]:
  p=replica/policy_path.relative_to(root);old=p.read_bytes();bad=json.loads(old);bad[section][key]=value;p.write_text(json.dumps(bad)+'\n');call=run(['bash',rh,'--output-dir',rejected_out]);check('unauthorized result/provenance/closure drift rejected: '+key,call.returncode!=0 and not list(rejected_out.iterdir()));p.write_bytes(old)
check('no new target instruction or source mutation from acceptance',digest(probe)==implementation['probe_sha256'] and closure['all_operational_authority_closed'])
for rel in list(own_hashes)+['tests/reference/test-'+base+'-harness.sh']:check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
changelog=(root/'CHANGELOG.md').read_text();check('CHANGELOG confirms accepted grant, returned UUID and closure','## Phase 1 step 295 ' in changelog and '5d25edd' in changelog and observation['fresh_boot_id'] in changelog and 'All operational authority closed' in changelog and '## Phase 1 step 294 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
