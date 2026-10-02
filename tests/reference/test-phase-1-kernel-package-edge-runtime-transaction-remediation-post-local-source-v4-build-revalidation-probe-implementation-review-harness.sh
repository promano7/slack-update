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
import os
import re
import shutil
import stat
import subprocess
import sys
import tempfile
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-review';prior='phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-design-freeze';own_hashes={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-review.md': 'd5b84acdab3b8d8586814ded2359a136df57387a3c4b53d2c675fd364f186ffe', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-review-policy.json': '89881e1bf0c8f34fa69cb3e3ffad837da12c81ca629bd2e0dc8753ea714516e8', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-review.tsv': 'edaeb92566c7a755b5c72de272241021de0abaff115f1f07148109433f69db74', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-review-predecessor-manifest.json': '725a8113ae1191b40c8127d6cc29eba11eeafd00c446b155b6c5048f7cd245ce', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-fresh-target-and-source-revalidation-probe.sh': '4d1bc852cf0bfea9b5131687bbe5cf70703cae04ae73a342a4afc7192a8440db', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v4-build-revalidation-probe-implementation-review.sh': '3a13a0bde402115ab00230a006ae1d91f95ea6807d10b46de4d1fabddc1e5f40'}
fixture=root/'tests/fixtures/reference/acceptance/phase-1'
policy_path=fixture/(base+'-policy.json');policy=json.loads(policy_path.read_text())
previous=json.loads((fixture/(prior+'-policy.json')).read_text());design=policy['design'];implementation=policy['implementation']
helper=root/'tools/reference'/(base+'.sh');probe=root/implementation['probe_path'];source=probe.read_text();passes=0

def check(label,value):
 global passes
 if not value:raise SystemExit('FAIL: '+label)
 passes+=1;print('PASS: '+label,flush=True)
def run(args,env=None):return subprocess.run([str(x) for x in args],capture_output=True,text=True,env=env)
def function(src,name):
 if name=='tsv_value':return re.search(r'(?m)^tsv_value\(\).*$',src).group(0)
 return re.search(r'(?ms)^'+re.escape(name)+r'\(\) \{\n.*?^\}',src).group(0)
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
accepted=policy['accepted_checkpoint']
for rel,expected in (accepted['sha256_bindings']|own_hashes).items():
 p=root/rel;check('exact regular artifact: '+p.name,p.is_file() and not p.is_symlink() and digest(p)==expected)
for p in [probe,helper,root/'tests/reference'/('test-'+base+'-harness.sh')]:check('Bash syntax: '+p.name,run(['bash','-n',p]).returncode==0)
check('implementation follows frozen next stage',policy['schema']==1 and policy['step']==292 and policy['scenario']==previous['next_stage']==base and policy['review_only'] and policy['review_status']=='PASS')
check('confirmedad984db complete206 predecessor',accepted['step']==291 and accepted['commit']=='ad984db' and accepted['acceptance_result']=='PASS (206 passes, 0 failures)' and accepted['user_commit_and_push_completed'] and accepted['user_worktree_clean'])
check('only supplied commit prefix recorded',accepted['commit_identity_scope']=='user-returned-seven-character-prefix-full-object-id-not-supplied' and 'commit_full' not in accepted)
for key in ['design','accepted_build_result','accepted_local_source_v4','accepted_authorization_closure','accepted_runtime_boundary_after_pause','historical_observation','fresh_boundary','preservation','revalidation_boundary','future_runtime_boundary','roadmap','strong_pause_completion_conditions']:
 check('exact accepted boundary: '+key,policy[key]==previous[key])
original=(root/design['historical_baseline_path']).read_text();planned=original
for c in design['replacements']:
 check('unique frozen replacement: '+c['label'],planned.count(c['old'])==1);planned=planned.replace(c['old'],c['new'],1)
check('implemented source is exact frozen derivation',source==planned and digest(probe)==implementation['probe_sha256']==design['expected_derivation_sha256']=='4d1bc852cf0bfea9b5131687bbe5cf70703cae04ae73a342a4afc7192a8440db')
for name,expected in design['preserved_guard_function_sha256'].items():check('actual historical function retained: '+name,function(source,name)==function(original,name) and hashlib.sha256(function(source,name).encode()).hexdigest()==expected)
for name,expected in design['new_guard_function_sha256'].items():check('actual postbuild function retained: '+name,hashlib.sha256(function(source,name).encode()).hexdigest()==expected)
check('all production readonly constants exact', [line for line in re.findall(r'(?m)^readonly .*$',source) if line!=design['new_readonly_manifest_declaration']]==design['preserved_readonly_declarations'])
check('actual fifty-field publication remains frozen',re.findall(r"(?m)^    printf '([A-Za-z0-9_]+)\\t",source)==design['ordered_publication_fields'] and design['publication_field_count']==50)
check('production adapter uses frozen paths and owner0:0', '"$EXPECTED_V4_TREE_MANIFEST_SHA256" "$EXPECTED_TARGET_SHA256" \'0:0\'' in function(source,'verify_local_source_v4'))
check('review state has no observation or transport',implementation['state']=='implemented-reviewed-not-frozen-not-observation-authorized' and implementation['exact_frozen_derivation'] and not implementation['live_target_observation_performed'] and not implementation['probe_transport_performed'] and not implementation['probe_execution_on_target_performed'])
check('only implementation freeze open',[k for k,v in policy['authorization'].items() if v]==['repository_only_revalidation_probe_implementation_freeze_authorized'])
check('prior repository implementation review grant consumed',not policy['authorization']['repository_only_revalidation_probe_implementation_review_authorized'])
for key in ['machine_action_required','controller_action_required','pause_safe','strong_safe_pause']:check('current reopened state: '+key,policy[key] is False)
check('next stage matches roadmap',policy['next_stage']==previous['roadmap']['preferred_steps'][4]['stage'])
check('library seam remains sourced-only',design['library_only_mode_requires_sourcing'] and '[[ ${BASH_SOURCE[0]} != "$0" ]]' in source)
env=os.environ|{design['library_only_environment']:'1'}
result=run(['bash',probe],env);check('direct library-only execution rejected before main',result.returncode==2 and 'requires sourcing' in result.stderr)
library_script='set -euo pipefail\nexport '+design['library_only_environment']+'=1\nsource "$1"\nshift\n"$@"\n'
def library_call(name,*args):return run(['bash','-c',library_script,'actual-library-test',probe,name,*args])
check('actual sourced file inventory exact',library_call('v4_expected_files').stdout.splitlines()==design['expected_regular_files'])
rows=[hashlib.sha256(('fixture:'+rel).encode()).hexdigest()+'  '+rel for rel in design['expected_regular_files']];valid='\n'.join(rows)
for label,text,success in [('valid manifest',valid,True),('missing row','\n'.join(rows[:-1]),False),('extra row',valid+'\n'+rows[-1],False),('duplicate row','\n'.join([rows[0],rows[0],*rows[2:]]),False),('unsorted','\n'.join(reversed(rows)),False),('absolute',valid.replace('./CHECKSUMS.md5','/CHECKSUMS.md5',1),False),('traversal',valid.replace('./CHECKSUMS.md5','./../CHECKSUMS.md5',1),False),('dot traversal',valid.replace('./CHECKSUMS.md5','././CHECKSUMS.md5',1),False),('binary marker',valid.replace('  ./CHECKSUMS.md5',' *./CHECKSUMS.md5',1),False),('one space',valid.replace('  ./CHECKSUMS.md5',' ./CHECKSUMS.md5',1),False),('tab separator',valid.replace('  ./CHECKSUMS.md5','\t./CHECKSUMS.md5',1),False),('uppercase hash',rows[0][:64].upper()+valid[64:],False),('short hash',valid[1:],False),('escaped record','\\'+valid,False),('blank record',valid.replace('\n','\n\n',1),False),('empty','',False)]:
 check('actual pure manifest validator: '+label,(library_call('validate_v4_manifest_text',text).returncode==0)==success)
for label,args,success in [('canonical',['bcfac4fa-4e6e-450a-aa95-bd591a979b4e'],True),('uppercase',['BCFAC4FA-4E6E-450A-AA95-BD591A979B4E'],False),('space',['bcfac4fa-4e6e-450a-aa95-bd591a979b4e '],False),('missing',[],False),('extra',['bcfac4fa-4e6e-450a-aa95-bd591a979b4e','extra'],False)]:
 check('actual pure UUID validator: '+label,(library_call('validate_fresh_boot_id',*args).returncode==0)==success)
cli_prefix=source[source.index('main() {'):source.index('    [[ ${EUID',source.index('main() {'))]
check('synthetic CLI prefix byte bound before root guard',hashlib.sha256(cli_prefix.encode()).hexdigest()==implementation['synthetic_cli_prefix_sha256'])
cli_script='set -euo pipefail\n'+function(source,'usage')+'\n'+cli_prefix.replace('main() {','synthetic_cli_prefix() {',1)+'}\nsynthetic_cli_prefix "$@"\n'
for args,expected in [([],2),(['--help'],0),(['-h'],0),(['--help','extra'],2),(['--bad'],2),([design['cli_switch']],0),([design['cli_switch'],'extra'],2),([design['cli_switch'],'--authorization-boot-id','old'],2)]:check('exact isolated CLI '+repr(args),run(['bash','-c',cli_script,'synthetic-cli',*args]).returncode==expected)

def make_fixture(parent):
 r=parent/'source';r.mkdir();m=parent/'local-source-v4.tree.sha256';s=parent/'local-source-v4.tree.sha256.sha256'
 for rel in design['expected_directories']:(r/rel).mkdir(exist_ok=True)
 for rel in design['expected_regular_files']:(r/rel[2:]).write_text('fixture data '+rel+'\n')
 (r/'FILELIST.TXT').write_text('\n'.join(design['expected_regular_files'])+'\n')
 (r/'CHECKSUMS.md5.asc').write_text('PGP compatibility marker for Slackpkg checkchangelog only.\nNo cryptographic authenticity claim is made by this file.\nThis file is not an OpenPGP signature.\n')
 m.write_text(''.join(digest(r/rel[2:])+'  '+rel+'\n' for rel in design['expected_regular_files']));s.write_text(digest(m)+'  '+m.name+'\n')
 for p in [*(r/rel[2:] for rel in design['expected_regular_files']),m,s]:p.chmod(0o444)
 for rel in reversed(design['expected_directories']):(r/rel).chmod(0o555)
 r.chmod(0o555)
 return dict(root=r,manifest=m,sidecar=s,manifest_sha=digest(m),target_sha=digest(r/'slackware64/d/kernel-headers-6.18.45-x86-1.txz'),owner=f'{r.stat().st_uid}:{r.stat().st_gid}')
def write_fixture(p,data):
 p.chmod(0o644);p.write_bytes(data);p.chmod(0o444)
def rebind(f):
 r=f['root'];m=f['manifest'];s=f['sidecar']
 write_fixture(m,(''.join(digest(r/rel[2:])+'  '+rel+'\n' for rel in design['expected_regular_files'])).encode());f['manifest_sha']=digest(m)
 write_fixture(s,(f['manifest_sha']+'  '+m.name+'\n').encode())
def fingerprint(parent):
 result={}
 for p in parent.rglob('*'):
  info=p.lstat();key=p.relative_to(parent).as_posix();value=[info.st_mode,info.st_uid,info.st_gid]
  if stat.S_ISREG(info.st_mode):value.append(p.read_bytes())
  elif stat.S_ISLNK(info.st_mode):value.append(os.readlink(p))
  result[key]=value
 return result
owner_script="""set -euo pipefail
export LIBRARY_ENV=1
source "$1"
shift
SYNTHETIC_OWNER_PATH=$1
shift
stat() {
    if [[ ${@: -1} == "$SYNTHETIC_OWNER_PATH" && ${2:-} == '%u:%g:%a' ]]; then
        printf '99999:99999:%s\n' "$(command stat -c '%a' -- "$SYNTHETIC_OWNER_PATH")"
    else
        command stat "$@"
    fi
}
verify_v4_tree_at "$@"
""".replace('LIBRARY_ENV',design['library_only_environment'])
# Every fixture is unrelated to frozen /var/tmp production paths.
fixture_cases=['valid','root-mode','directory-mode','file-mode','manifest-mode','sidecar-mode','root-owner','directory-owner','file-owner','manifest-owner','sidecar-owner','root-symlink','ancestor-symlink','file-symlink','directory-symlink','manifest-symlink','sidecar-symlink','extra-file','hidden-file','newline-file','extra-directory','extra-symlink','extra-fifo','missing-file','missing-directory','changed-content','wrong-target-sha','wrong-manifest-sha','wrong-sidecar-sha','sidecar-extra-newline','sidecar-path-injection','manifest-traversal','manifest-absolute','manifest-duplicate','manifest-unsorted','manifest-binary-marker','manifest-missing','manifest-extra','wrong-filelist','missing-PGP-marker','signature-marker']
for case in fixture_cases:
 with tempfile.TemporaryDirectory(prefix='step292-fixture-') as directory:
  parent=Path(directory).resolve();f=make_fixture(parent);r=f['root'];m=f['manifest'];s=f['sidecar'];owner_path=None
  selections={'root':r,'directory':r/'extra','file':r/'PACKAGES.TXT','manifest':m,'sidecar':s}
  if case.endswith('-mode'):selections[case[:-5]].chmod(0o755 if case[:-5] in ['root','directory'] else 0o644)
  elif case.endswith('-owner'):owner_path=selections[case[:-6]]
  elif case=='root-symlink':p=parent/'source-link';p.symlink_to(r,target_is_directory=True);f['root']=p
  elif case=='ancestor-symlink':p=parent/'ancestor-link';p.symlink_to(parent,target_is_directory=True);f['root']=p/'source';f['manifest']=p/m.name;f['sidecar']=p/s.name
  elif case in ['file-symlink','directory-symlink','manifest-symlink','sidecar-symlink']:
   kind=case[:-8];p=selections[kind];p.parent.chmod(0o755)
   destination=parent/('outside-'+kind)
   if p.is_dir():p.chmod(0o755);shutil.move(p,destination);p.symlink_to(destination,target_is_directory=True)
   else:shutil.copy2(p,destination);p.unlink();p.symlink_to(destination)
   if p.parent==r or p.parent.is_relative_to(r):p.parent.chmod(0o555)
  elif case.startswith('extra-') or case in ['hidden-file','newline-file']:
   r.chmod(0o755);p=r/('.hidden' if case=='hidden-file' else 'unexpected\nname' if case=='newline-file' else 'unexpected')
   if case=='extra-directory':p.mkdir()
   elif case=='extra-symlink':p.symlink_to(r/'PACKAGES.TXT')
   elif case=='extra-fifo':os.mkfifo(p)
   else:p.write_text('extra\n')
   r.chmod(0o555)
  elif case=='missing-file':r.chmod(0o755);(r/'PACKAGES.TXT').unlink();r.chmod(0o555)
  elif case=='missing-directory':r.chmod(0o755);(r/'extra').chmod(0o755);shutil.rmtree(r/'extra');r.chmod(0o555)
  elif case=='changed-content':write_fixture(r/'PACKAGES.TXT',b'changed\n')
  elif case=='wrong-target-sha':f['target_sha']='0'*64
  elif case=='wrong-manifest-sha':f['manifest_sha']='0'*64
  elif case=='wrong-sidecar-sha':write_fixture(s,('0'*64+'  '+m.name+'\n').encode())
  elif case=='sidecar-extra-newline':write_fixture(s,s.read_bytes()+b'\n')
  elif case=='sidecar-path-injection':write_fixture(s,(f['manifest_sha']+'  ../'+m.name+'\n').encode())
  elif case.startswith('manifest-'):
   lines=m.read_text().splitlines()
   if case=='manifest-traversal':lines[0]=lines[0].replace('./CHECKSUMS.md5','./../CHECKSUMS.md5')
   elif case=='manifest-absolute':lines[0]=lines[0].replace('./CHECKSUMS.md5','/CHECKSUMS.md5')
   elif case=='manifest-duplicate':lines[1]=lines[0]
   elif case=='manifest-unsorted':lines.reverse()
   elif case=='manifest-binary-marker':lines[0]=lines[0].replace('  ./',' *./')
   elif case=='manifest-missing':lines.pop()
   elif case=='manifest-extra':lines.append(lines[-1])
   write_fixture(m,('\n'.join(lines)+'\n').encode());f['manifest_sha']=digest(m);write_fixture(s,(f['manifest_sha']+'  '+m.name+'\n').encode())
  elif case in ['wrong-filelist','missing-PGP-marker','signature-marker']:
   p=r/'FILELIST.TXT' if case=='wrong-filelist' else r/'CHECKSUMS.md5.asc'
   data=b'wrong inventory\n' if case=='wrong-filelist' else b'No cryptographic authenticity claim is made by this file.\n' if case=='missing-PGP-marker' else p.read_bytes()+b'BEGIN PGP SIGNATURE\n'
   write_fixture(p,data);rebind(f)
  args=[f['root'],f['manifest'],f['sidecar'],f['manifest_sha'],f['target_sha'],f['owner']]
  before=fingerprint(parent)
  result=run(['bash','-c',owner_script,'synthetic-owner-case',probe,owner_path,*args]) if owner_path else library_call('verify_v4_tree_at',*args)
  check('actual generic tree validator fixture: '+case,(result.returncode==0)==(case=='valid'))
  check('fixture validator leaves bytes/types/owner/modes unchanged: '+case,fingerprint(parent)==before)
  # Restore traversal/write permissions solely to remove disposable fixtures.
  for p in parent.rglob('*'):
   if p.is_dir() and not p.is_symlink():p.chmod(0o755)
with tempfile.TemporaryDirectory(prefix='step292-temp-guard-') as directory:
 parent=Path(directory).resolve()
 temp_script='set -euo pipefail\n'+re.search(r'(?m)^fail\(\).*$',source).group(0)+'\nreadonly ACCEPTANCE_ROOT="$1"\nreadonly V4_TEMP_GLOB=\'.local-source-v4.build.*\'\n'+function(source,'verify_v4_temporary_outputs_absent').replace('verify_v4_temporary_outputs_absent() {','synthetic_temp_guard() {',1)+'\nsynthetic_temp_guard\n'
 check('exact isolated temporary guard passes empty fixture',run(['bash','-c',temp_script,'synthetic-temp',parent]).returncode==0)
 (parent/'.local-source-v4.build.fixture').mkdir()
 check('exact isolated temporary guard rejects leftover output',run(['bash','-c',temp_script,'synthetic-temp',parent]).returncode!=0)
manifest=json.loads((root/implementation['accepted_predecessor_snapshot_path']).read_text())
check('complete1229 accepted snapshot includes accepted CHANGELOG',len(manifest)==implementation['accepted_predecessor_snapshot_file_count']==1229 and manifest['CHANGELOG.md']==implementation['accepted_predecessor_snapshot_changelog_sha256'])
check('new probe excluded only from historical beforeimage',implementation['probe_path'] not in manifest and probe.is_file())
check('accepted beforeimage protocol never mutates current source',implementation['predecessor_view_is_temporary_and_does_not_mutate_current_repository'] and implementation['complete_predecessor_206_pass_suite_required'])
rows=[line.split('\t') for line in (fixture/(base+'.tsv')).read_text().splitlines()];check('strict unique real-tab record',all(len(row)==2 and all(row) for row in rows) and len(rows)==len(dict(rows)));record=dict(rows)
check('record implementation and no target observation',record['step']=='292' and record['accepted_checkpoint_commit']=='ad984db' and record['probe_sha256']==implementation['probe_sha256'] and record['probe_installed_in_repository']=='yes' and record['probe_transported']==record['probe_observed_on_target']=='no')
check('record permission consistency',all(record[k]==('yes' if v else 'no') for k,v in policy['authorization'].items()) and record['next_stage']==policy['next_stage'])
for args,expected in [(['--help'],0),([],2),(['--bad'],2),(['--output-dir'],2),(['--output-dir',''],2)]:check('strict review helper CLI '+repr(args),run(['bash',helper,*args]).returncode==expected)
with tempfile.TemporaryDirectory(prefix='step292-review-') as directory:
 tmp=Path(directory);out=tmp/'output';out.mkdir();source_before=probe.read_bytes();result=run(['bash',helper,'--output-dir',out])
 check('full accepted206 beforeimage acceptance succeeds with current new probe present',result.returncode==0 and 'accepted_step291_revalidated\tPASS (206 passes, 0 failures)' in result.stdout)
 check('current new probe byte-identical after historical acceptance',probe.read_bytes()==source_before)
 for suffix in ['-policy.json','.tsv','-predecessor-manifest.json']:check('exact review publication '+suffix,(out/(base+suffix)).read_bytes()==(fixture/(base+suffix)).read_bytes())
 before={p.name:p.read_bytes() for p in out.iterdir()};check('duplicate rejected without overwrite',run(['bash',helper,'--output-dir',out]).returncode!=0 and {p.name:p.read_bytes() for p in out.iterdir()}==before)
 link=tmp/'link';link.symlink_to(out,target_is_directory=True);check('symlink output rejected',run(['bash',helper,'--output-dir',link]).returncode!=0)
 check('missing output rejected',run(['bash',helper,'--output-dir',tmp/'missing']).returncode!=0)
 replica=tmp/'replica';shutil.copytree(root,replica,ignore=shutil.ignore_patterns('.git'));rh=replica/helper.relative_to(root);rejected=tmp/'rejected';rejected.mkdir()
 for rel in list(own_hashes)+['README.md','data/config/slack-update.conf','tools/reference/'+prior+'.sh']:
  if rel==helper.relative_to(root).as_posix():continue
  p=replica/rel;old=p.read_bytes();p.write_bytes(old+b'\n');result=run(['bash',rh,'--output-dir',rejected]);check('changed new/historical input rejected before publication: '+p.name,result.returncode!=0 and not list(rejected.iterdir()));p.write_bytes(old)
 p=replica/'CHANGELOG.md';old=p.read_bytes();p.write_bytes(old.replace(b'## Phase 1 step 291 ',b'## Phase 1 step 999 ',1));result=run(['bash',rh,'--output-dir',rejected]);check('changed accepted CHANGELOG history rejected',result.returncode!=0 and not list(rejected.iterdir()));p.write_bytes(old)
check('current boot unobserved and historical binding expired',policy['fresh_boundary']['current_boot_id'] is None and not policy['fresh_boundary']['prior_live_binding_reusable'])
for rel in list(own_hashes)+['tests/reference/test-'+base+'-harness.sh']:check('no trailing whitespace: '+Path(rel).name,all(line==line.rstrip() for line in (root/rel).read_text().splitlines()))
check('CHANGELOG confirms predecessor and implementation scope','## Phase 1 step 292 ' in (root/'CHANGELOG.md').read_text() and 'ad984db' in (root/'CHANGELOG.md').read_text())
print(f'Result: PASS ({passes} passes, 0 failures)')
PYTEST
