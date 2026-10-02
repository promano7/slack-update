#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 - "$repo_root" <<'PYTEST'
from pathlib import Path
import copy
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-freeze';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-review';own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-freeze.md': 'b5dfe2a4463768fcd901ce8db40c6ccf9621e34504f87c528ec340bdc4d81534', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-freeze-policy.json': '082209e2c57d10cdc981f82b8417df9d2b686a45df52836089bcf7d9b4304b75', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-freeze.tsv': 'ada8fa20bb762476434e906c6970eaae481ffd876c7dbc316d33d24e852022d6', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-freeze-implementation.json': '29faa6336b722bf5926e6dabcfbb01c8f932e050354186829a9da3e0a93abc81', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-freeze.sh': 'bd0116b01b2e32196206a267632f36d9ad2d34809ffb457a56faa521b8f6a7a0'}
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
policy_path=fixture/(base+'-policy.json');policy=json.loads(policy_path.read_text())
previous=json.loads((fixture/(prior+'-policy.json')).read_text());implementation=json.loads((fixture/(base+'-implementation.json')).read_text());design=policy['design'];accepted=policy['accepted_checkpoint'];helper=root/'tools/reference'/(base+'.sh');probe=root/implementation['probe_path'];source=probe.read_text();passes=0

def check(label,value):
 global passes
 if not value:raise SystemExit('FAIL: '+label)
 passes+=1;print('PASS: '+label,flush=True)
def run(args):return subprocess.run([str(x) for x in args],capture_output=True,text=True)
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def function(src,name):
 if name=='tsv_value':return re.search(r'(?m)^tsv_value\(\).*$',src).group(0)
 return re.search(r'(?ms)^'+re.escape(name)+r'\(\) \{\n.*?^\}',src).group(0)
def accepted_bytes(rel):
 p=root/rel
 if not p.is_file() or p.is_symlink() or p.resolve()!=p.absolute() or not p.resolve().is_relative_to(root):return None
 data=p.read_bytes()
 if rel=='CHANGELOG.md':
  position=data.find(b'## Phase 1 step 292 ')
  if position<0:return None
  data=data[position:]
 return data
bindings=accepted['sha256_bindings']
check('all1236 accepted bytes and safe paths bound including exact CHANGELOG tail',len(bindings)==accepted['repository_file_count']==1236 and all((data:=accepted_bytes(rel)) is not None and hashlib.sha256(data).hexdigest()==sha for rel,sha in bindings.items()))
critical=dict(previous['accepted_checkpoint']['sha256_bindings'])
for path in ['docs/reference/'+prior+'.md','tests/fixtures/reference/acceptance/phase-1/'+prior+'-policy.json','tests/fixtures/reference/acceptance/phase-1/'+prior+'.tsv','tests/fixtures/reference/acceptance/phase-1/'+prior+'-predecessor-manifest.json','tools/reference/'+prior+'.sh','tests/reference/test-'+prior+'-harness.sh',implementation['probe_path']]:critical[path]=bindings[path]
for rel,sha in (critical|own_hashes).items():
 p=root/rel;check('exact regular artifact: '+p.name,p.is_file() and not p.is_symlink() and p.resolve()==p.absolute() and digest(p)==sha)
for p in [probe,helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
check('freeze follows accepted implementation review',policy['schema']==1 and policy['step']==293 and policy['scenario']==previous['next_stage']==base and policy['review_only'] and policy['review_status']=='PASS')
check('confirmed59da9e4 complete250 predecessor',accepted['step']==292 and accepted['commit']=='59da9e4' and accepted['acceptance_result']=='PASS (250 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('prefix scope with no invented full commit',accepted['commit_identity_scope']=='user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted)
for key in ['accepted_build_result','accepted_local_source_v4','accepted_authorization_closure','accepted_runtime_boundary_after_pause','historical_observation','accepted_step288_pause_remains_valid_as_historical_checkpoint','fresh_boundary','preservation','revalidation_boundary','future_runtime_boundary','roadmap','strong_pause_completion_conditions','design','design_path']:check('unchanged accepted boundary: '+key,policy[key]==previous[key])
expected=copy.deepcopy(previous['implementation']);expected['state']='implementation-frozen-not-observation-authorized'
check('entire implementation frozen with state-only delta',policy['implementation']==implementation==expected and policy['accepted_implementation_review_state']==previous['implementation']['state'])
check('implementation fixture identity',policy['implementation_path']=='tests/fixtures/reference/acceptance/phase-1/'+base+'-implementation.json')
for key in previous['implementation']:
 if key!='state':check('exact frozen implementation member: '+key,implementation[key]==previous['implementation'][key])
check('no source/design/hash/transport/target-execution delta',policy['freeze_delta']==dict(changed_implementation_keys=['state'],source_bytes_changed=False,design_changed=False,probe_sha256_changed=False,probe_already_installed_in_repository=True,probe_transport_performed=False,probe_execution_on_target_performed=False))
check('whole frozen design fixture preserved',json.loads((root/policy['design_path']).read_text())==design and design['state']=='design-frozen-not-implemented-not-observation-authorized')
original=(root/design['historical_baseline_path']).read_text();planned=original
for change in design['replacements']:
 check('unique frozen replacement: '+change['label'],planned.count(change['old'])==1);planned=planned.replace(change['old'],change['new'],1)
check('installed probe remains exact complete derivation',source==planned and digest(probe)==implementation['probe_sha256']==design['expected_derivation_sha256']=='4d1bc852cf0bfea9b5131687bbe5cf70703cae04ae73a342a4afc7192a8440db')
check('historical probe SHA remains immutable',hashlib.sha256(original.encode()).hexdigest()==design['historical_baseline_sha256']=='fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b')
for name,sha in design['preserved_guard_function_sha256'].items():check('historical guard unchanged: '+name,function(source,name)==function(original,name) and hashlib.sha256(function(source,name).encode()).hexdigest()==sha)
for name,sha in design['new_guard_function_sha256'].items():check('postbuild guard unchanged: '+name,hashlib.sha256(function(source,name).encode()).hexdigest()==sha)
check('production constants unchanged',re.findall(r'(?m)^readonly .*$',original)==design['preserved_readonly_declarations'] and [x for x in re.findall(r'(?m)^readonly .*$',source) if x!=design['new_readonly_manifest_declaration']]==design['preserved_readonly_declarations'])
check('fifty unique ordered real-tab publication fields unchanged',re.findall(r"(?m)^    printf '([A-Za-z0-9_]+)\\t",source)==design['ordered_publication_fields'] and len(set(design['ordered_publication_fields']))==50)
check('strict CLI and sourced-only seam unchanged',design['cli_accepts_only_one_switch_and_help'] and not design['cli_accepts_boot_argument_or_path_override'] and design['library_only_mode_requires_sourcing'] and implementation['production_adapter_and_main_not_entered'])
check('production inventory modes/owner and compatibility boundary unchanged',len(design['expected_regular_files'])==11 and len(design['expected_directories'])==6 and design['expected_non_root_tree_entry_count']==17 and design['production_expected_uid_gid']=='0:0' and design['regular_file_mode']=='444' and design['directory_mode']=='555' and design['compatibility_marker_is_not_openpgp_signature'])
check('synthetic fixture acceptance retained without target inference',implementation['all_frozen_fixture_categories_required'] and implementation['synthetic_tests_source_actual_probe_through_sourced_only_library_seam'] and not implementation['live_target_observation_performed'])
check('point-in-time observation contract unchanged',design['observation_provenance_scope']=='point-in-time-guarded-observation-not-atomic-snapshot-or-continuous-preservation')
check('historical full206 beforeimage protocol unchanged',implementation['complete_predecessor_206_pass_suite_required'] and implementation['predecessor_view_is_temporary_and_does_not_mutate_current_repository'] and implementation['predecessor_acceptance_view']=='exact-manifest-listed-step291-bytes-only-before-new-probe-existed')
check('full accepted repository acceptance required before publication',policy['repository_acceptance_scope']['accepted_predecessor_result']=='PASS (250 passes, 0 failures)' and policy['repository_acceptance_scope']['accepted_predecessor_complete_1236_file_bindings_required'] and policy['repository_acceptance_scope']['state_only_implementation_transition_verified'])
for key in ['production_main_entered','production_builder_entered','production_host_guards_entered','production_constants_modified','live_target_observation_performed']:check('acceptance excludes production action: '+key,policy['repository_acceptance_scope'][key] is False)
check('only repository fresh-authorization review is open',[k for k,v in policy['authorization'].items() if v]==['repository_only_fresh_revalidation_authorization_review_authorized'])
check('implementation freeze grant consumed',previous['authorization']['repository_only_revalidation_probe_implementation_freeze_authorized'] and not policy['authorization']['repository_only_revalidation_probe_implementation_freeze_authorized'])
for key in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']:check('reopened workstream state: '+key,policy[key] is False)
check('next authorization stage matches roadmap',policy['next_stage']==previous['roadmap']['preferred_steps'][5]['stage'])
check('fresh boot unknown and old binding expired',policy['fresh_boundary']['current_boot_id'] is None and not policy['fresh_boundary']['prior_live_binding_reusable'])
rows=[line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines()];record=dict(rows)
check('strict unique real-tab record',all(len(row)==2 and all(row) for row in rows) and len(rows)==len(record))
check('record confirms only state delta',record['step']=='293' and record['accepted_checkpoint_commit']=='59da9e4' and record['implementation_state']==implementation['state'] and record['implementation_changed_keys']=='state' and record['probe_sha256']==implementation['probe_sha256'] and record['design_changed']==record['production_source_bytes_changed']=='no')
check('record distinguishes repository probe from target observation',record['probe_installed_in_repository']=='yes' and record['probe_transported']==record['probe_observed_on_target']=='no')
check('record authorization consistency',all(record[k]==('yes' if v else 'no') for k,v in policy['authorization'].items()) and record['next_stage']==policy['next_stage'])
for args,expected in [(['--help'],0),([],2),(['--bad'],2),(['--output-dir'],2),(['--output-dir',''],2),(['--help','extra'],2),(['--output-dir','x','extra'],2)]:check('strict freeze helper CLI '+repr(args),run(['bash',helper,*args]).returncode==expected)
with tempfile.TemporaryDirectory(prefix='step293-freeze-') as directory:
 tmp=Path(directory);out=tmp/'output';out.mkdir();source_before=probe.read_bytes();result=run(['bash',helper,'--output-dir',out])
 check('full accepted250 synthetic suite succeeds before publication',result.returncode==0 and 'accepted_step292_revalidated\tPASS (250 passes, 0 failures)' in result.stdout)
 for suffix in ['-policy.json','.tsv','-implementation.json']:check('exact freeze publication '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
 check('helper reports state-only freeze and no target action','implementation_changed_keys\tstate' in result.stdout and 'production_source_bytes_changed\tno' in result.stdout and 'probe_transported\tno' in result.stdout and 'live_target_observation_performed\tno' in result.stdout)
 check('actual probe unchanged after full synthetic acceptance',probe.read_bytes()==source_before)
 before={p.name:p.read_bytes() for p in out.iterdir()};check('duplicate rejected without overwrite',run(['bash',helper,'--output-dir',out]).returncode!=0 and {p.name:p.read_bytes() for p in out.iterdir()}==before)
 link=tmp/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',helper,'--output-dir',link]).returncode!=0)
 nested=out/'nested';nested.mkdir();check('symlink output ancestor rejected',run(['bash',helper,'--output-dir',link/'nested']).returncode!=0 and not list(nested.iterdir()))
 check('missing output directory rejected',run(['bash',helper,'--output-dir',tmp/'missing']).returncode!=0 and not (tmp/'missing').exists())
 replica=tmp/'replica';shutil.copytree(root,replica,ignore=shutil.ignore_patterns('.git'));rh=replica/helper.relative_to(root);rejected=tmp/'rejected';rejected.mkdir()
 for rel in list(critical)+[k for k in own_hashes if k!=helper.relative_to(root).as_posix()]+['README.md','data/config/slack-update.conf']:
  p=replica/rel;old=p.read_bytes();p.write_bytes(old+b'\n');result=run(['bash',rh,'--output-dir',rejected]);check('accepted/freeze byte drift rejected before publication: '+p.name,result.returncode!=0 and not list(rejected.iterdir()));p.write_bytes(old)
 p=replica/'CHANGELOG.md';old=p.read_bytes();p.write_bytes(old.replace(b'## Phase 1 step 292 ',b'## Phase 1 step 999 ',1));result=run(['bash',rh,'--output-dir',rejected]);check('changed accepted CHANGELOG history rejected before publication',result.returncode!=0 and not list(rejected.iterdir()));p.write_bytes(old)
 p=replica/implementation['probe_path'];old=p.read_bytes();outside=tmp/'same-probe';outside.write_bytes(old);p.unlink();p.symlink_to(outside);result=run(['bash',rh,'--output-dir',rejected]);check('same-byte symlink probe rejected before publication',result.returncode!=0 and not list(rejected.iterdir()));p.unlink();p.write_bytes(old)
 for section,key,value in [('authorization','new_probe_execution_authorized',True),('authorization','new_probe_transport_authorized',True),('authorization','repository_only_fresh_revalidation_authorization_review_authorized',False),('fresh_boundary','current_boot_id','bcfac4fa-4e6e-450a-aa95-bd591a979b4e'),('implementation','probe_sha256','0'*64),('implementation','state','observation-authorized'),('design','production_expected_uid_gid','1000:1000'),('freeze_delta','source_bytes_changed',True)]:
  p=replica/policy_path.relative_to(root);old=p.read_bytes();bad=json.loads(old);bad[section][key]=value;p.write_text(json.dumps(bad)+'\n');result=run(['bash',rh,'--output-dir',rejected]);check('unauthorized state/binding drift rejected: '+key,result.returncode!=0 and not list(rejected.iterdir()));p.write_bytes(old)
check('frozen installed source remains byte-identical after acceptance',digest(probe)==implementation['probe_sha256'])
for rel in list(own_hashes)+['tests/reference/test-'+base+'-harness.sh']:check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
changelog=(root/'CHANGELOG.md').read_text();check('CHANGELOG confirms accepted predecessor and exact freeze','## Phase 1 step 293 ' in changelog and '59da9e4' in changelog and 'implementation-frozen-not-observation-authorized' in changelog and '## Phase 1 step 292 ' in changelog)
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
