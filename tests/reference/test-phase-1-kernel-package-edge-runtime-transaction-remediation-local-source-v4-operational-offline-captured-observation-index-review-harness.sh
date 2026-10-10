#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
python3 -B - "$repo_root" <<'PYTEST'
from pathlib import Path
from dataclasses import FrozenInstanceError, replace
from types import SimpleNamespace
from unittest.mock import patch
import ast
import copy
import hashlib
import json
import os
import runpy
import subprocess
import sys
import tempfile

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-captured-observation-index-review';oldbase='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-independent-expectation-contract-review';module='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-observation-index.py'
fixture=root/'tests/fixtures/reference/acceptance/phase-1';OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-captured-observation-index-review.md': 'd1c95ec7bbce20493a20932a029e92b639bbc1e4cead74e5d9363d4fe16b73fd', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-captured-observation-index-review-checkpoint-confirmation.json': 'd09d72353bb54c96cbd9545aa320df6e69f5ada7fdf72a5e1f3f80df069d16b8', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-captured-observation-index-review-policy.json': '10625de2bb7e1cba934133baf6ad9e720de25f1489a5ddd5067dfb65f8aec56b', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-captured-observation-index-review-ingestion-contract.json': 'a4c98386ba83b38362606d2b307c36dff56b60219a6eb8903417e344197b89bf', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-captured-observation-index-review-private-inputs.json': '63b0ff2ac9985d3ba3ab8cfd269af42fff522b22076064e7c4a19b6a576beb27', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-captured-observation-index-review-retained-obligations.json': '9bdc7163c42b9b01fbe4c736ea0e6dd00ce55938fdd40b6d13382df992d9202b', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-captured-observation-index-review-step351-user-acceptance.json': '33c4f66fed739c5b23851fc0a82b898db51789f7450f75a512237d2833a49402', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-observation-index.py': 'cd8b7cd2dd0bde53254e66027f034b22aca75e40ce7a1475501a3ca258612a30'};passes=0
def check(label,condition):
    global passes
    if not condition:raise AssertionError(label)
    passes+=1;print('PASS: '+label,flush=True)
def sha(raw):return hashlib.sha256(raw).hexdigest()
def load(tail):return json.loads((fixture/(base+'-'+tail+'.json')).read_bytes())
def fails(fn,*args):
    try:fn(*args)
    except ValueError:return True
    return False
for rel,digest in OWN_HASHES.items():
    p=root/rel;check('exact current352 input '+p.name,p.is_file()and not p.is_symlink()and p.resolve()==p.absolute()and sha(p.read_bytes())==digest)
policy=load('policy');contract=load('ingestion-contract');retained=load('retained-obligations');private=load('private-inputs');receipt=load('step351-user-acceptance');confirmed=load('checkpoint-confirmation')
history={}
for rel,digest in policy['baseline_sha256_bindings'].items():
    p=root/rel
    if not p.is_file()or p.is_symlink()or p.resolve()!=p.absolute():raise ValueError('unsafe accepted source')
    raw=p.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size']:]
    if sha(raw)!=digest:raise ValueError('accepted351 source drift '+rel)
    history[rel]=raw
check('all1746 accepted351 bytes and exact historical CHANGELOG suffix',len(history)==1746)
raw=receipt['text'].encode();lines=receipt['text'].splitlines()
check('complete24990-byte original351 receipt retained without normalization',len(raw)==24990 and sha(raw)=='df3ae85af58c2b1d199be03eb77e01b07b045e8d2ad4829bbdbfc8a21629af27' and receipt['original_display_sha256']==sha(raw) and receipt['original_display_size_bytes']==len(raw) and receipt['ordered_output_normalization']=='none')
check('complete246 predecessor labels exactly match original receipt',[x for x in lines if x.startswith('PASS: ')]==policy['expected_predecessor_labels'] and lines.count('Result: PASS (246 passes, 0 failures)')==1)
check('reported149fd78 exact tenfiles6344 commit nine paths and successful push','[main 149fd78] Phase 1 step 351: define independent literal expectation contract'in lines and ' 10 files changed, 6344 insertions(+)'in lines and set(x[len(' create mode 100644 '):]for x in lines if x.startswith(' create mode 100644 '))==set(policy['expected_predecessor_paths']) and '   922d639..149fd78  main -> main'in lines)
check('complete clean matching heads and full351 commit unknown',lines[-3:-1]==['149fd78 (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 351: define independent literal expectation contract']*2 and confirmed['commit_full']is None and confirmed['evidence_sha256']==sha(raw) and all(confirmed[k]is True for k in ['user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','complete_ordered_return_matches_prepared_and_installed']))
bindings=list(retained['source_bindings'].values())+list(retained['model_modules'].values())+list(retained['original_design_bindings'].values())+list(retained['accepted350_bindings'].values())+list(retained['accepted351_bindings'].values())+[retained['accepted349_plan_binding'],retained['schema_module_binding'],retained['expectation_module_binding']]
for binding in bindings:check('source-bound unchanged inherited '+Path(binding['path']).name,sha(history[binding['path']])==binding['sha256'])
oracle=json.loads(history[retained['source_bindings']['oracle335']['path']])
check('full twelve original native evidence group rows retained',retained['original_evidence_group_rows']==oracle['evidence_groups'])
check('all eight full original320-327 contracts retained',set(retained['original_design_bindings'])==set(str(i)for i in range(320,328)))
check('all52 source-bound native cases still unrun',len(retained['original_case_row_sha256'])==len(oracle['cases'])==52 and all(row['status']=='required-not-run'and row['sha256']==sha(json.dumps(original,sort_keys=True,separators=(',',':')).encode())for row,original in zip(retained['original_case_row_sha256'],oracle['cases'])))
check('all46 proofs52 cases16 gaps retained',[retained['counts'][k]for k in ['native_proofs','native_cases','native_gaps']]==[46,52,16])
check('seven frozen modules nine original pause conditions retained',len(retained['model_modules'])==7 and len(retained['original_pause_conditions'])==9)
copied=retained['codec_static_copy'];original=history[copied['path']].decode();prefix=original[:original.index("\n\nif __name__ == '__main__':")]
check('static350 data codec copy exact without dynamic import',sha(original.encode())==copied['full_source_sha256']and sha(prefix.encode())==copied['copied_prefix_sha256']and (root/'tools/reference'/module).read_text().startswith(prefix+'\n'))
m=SimpleNamespace(**runpy.run_path(str(root/'tools/reference'/module)))
check('original26 case IDs and twelve group universe exact',m.CASE_IDS==tuple(dict.fromkeys(row['case_id']for row in oracle['cases'])) and m.GROUP_IDS==tuple(row['id']for row in oracle['evidence_groups']))
check('reader limits bound path chunk and raw retained bytes',m.CHUNK_BYTES==65536 and m.MAX_PATH_CHARS==4096 and m.MAX_COMPONENT_CHARS==255 and m.MAX_ARTIFACT_BYTES==67108864 and m.MAX_TOTAL_ARTIFACT_BYTES==134217728)
check('private input fixture scope cannot claim native evidence',private['native_cases_run']==private['native_proofs_added']==0 and private['runtime_authority']is False)
def wire(data):return(json.dumps(data,sort_keys=True,separators=(',',':'),ensure_ascii=True)+'\n').encode('ascii')
def empty_envelope(platform='Slackware-15.0',case='actual-selector'):
    return dict(schema_version=1,origin='private-fixture',case_id=case,identity=dict(platform=platform,platform_version=None,boot_id=None,source_epoch=None,original_attempt=None,test_run_id=None,subject_source_sha256=None),artifacts=[],groups=[dict(group_id=g,status='missing',artifact_ids=[])for g in m.GROUP_IDS])
def descriptor(logical='raw',group=0,raw=b'raw',size=None,digest=None):
    return dict(logical_id=logical,evidence_group=m.GROUP_IDS[group],sha256=sha(raw)if digest is None else digest,size_bytes=len(raw)if size is None else size,media_type='application/octet-stream',producer_role='unattributed',capture_stage='unspecified')
def envelope(descriptors,status='present-unverified'):
    data=empty_envelope();data['artifacts']=descriptors
    for row in descriptors:
        group=next(g for g in data['groups']if g['group_id']==row['evidence_group']);group['status']=status;group['artifact_ids'].append(row['logical_id'])
    return data
def no_native(index):return not any([index.provenance_verified,index.native_conformance,index.runtime_authority,index.comparison_performed])and index.native_cases_run==index.native_proofs_added==0
index=m.ingest(wire(empty_envelope()),())
check('empty inventory reads no default file and retains all missing data states',index.artifacts==()and all(g.state=='missing'for g in index.groups)and index.retained_raw_bytes==0 and no_native(index))
with tempfile.TemporaryDirectory(prefix='step352-private-reader-')as directory:
    folder=Path(directory)
    for row in private['fixtures']:
        content=bytes.fromhex(row['raw_hex']);file=folder/row['logical_id'];file.write_bytes(content);before=file.stat()
        data=envelope([descriptor(row['logical_id'],raw=content)])
        location=m.SourceLocation(row['logical_id'],'file',str(file))
        index=m.ingest(wire(data),(location,));o=index.artifacts[0]
        check('opaque raw bytes retained exactly '+row['logical_id'],o.state=='captured-unverified'and o.raw_bytes==content and o.raw_complete and o.raw_sha256==sha(content)and o.declared_bytes_match and index.retained_raw_bytes==len(content))
        check('reader preserves file contents inode mtime and metadata '+row['logical_id'],file.read_bytes()==content and file.stat().st_ino==before.st_ino and file.stat().st_mtime_ns==before.st_mtime_ns and file.stat().st_mode==before.st_mode)
        check('opaque payload zero native proof or authority '+row['logical_id'],no_native(index)and not(folder/'NEVER_EXECUTE_RAW_CONTENT').exists())
    good=folder/'text';data=envelope([descriptor()]);location=m.SourceLocation('raw','file',str(good))
    for source,state in [('missing','missing'),('unknown','unknown')]:
        index=m.ingest(wire(data),(m.SourceLocation('raw',source,None),))
        check('explicit '+source+' has no path lookup or absence-of-effects inference',index.artifacts[0].state==state and index.artifacts[0].raw_bytes is None and index.groups[0].state==state and no_native(index))
    index=m.ingest(wire(data),(m.SourceLocation('raw','file',str(folder/'missing')),))
    check('nonexistent explicit file is missing data only',index.artifacts[0].state=='missing'and index.groups[0].state=='missing'and no_native(index))
    unknown=envelope([descriptor()],status='unknown');index=m.ingest(wire(unknown),(location,))
    check('declared unknown stays unknown despite captured matching raw bytes',index.artifacts[0].state=='captured-unverified'and index.groups[0].declared_state==index.groups[0].state=='unknown')
    conflict=envelope([descriptor()],status='conflicting');index=m.ingest(wire(conflict),(m.SourceLocation('raw','unknown',None),))
    check('declared conflict remains visible alongside unknown raw data',index.groups[0].state=='conflicting'and index.artifacts[0].state=='unknown')
    bad=envelope([descriptor(digest='0'*64)]);index=m.ingest(wire(bad),(location,));o=index.artifacts[0]
    check('hash mismatch retains complete contradictory bytes and actual digest',o.state=='conflicting'and o.raw_bytes==b'raw'and o.raw_complete and o.raw_sha256==sha(b'raw')and not o.declared_bytes_match and index.groups[0].state=='conflicting')
    shorter=envelope([descriptor(size=4)]);index=m.ingest(wire(shorter),(location,))
    check('shorter raw file retains complete bytes with size contradiction',index.artifacts[0].state=='conflicting'and index.artifacts[0].raw_bytes==b'raw'and index.artifacts[0].raw_complete)
    larger=envelope([descriptor(size=2)])
    with patch('os.read',side_effect=AssertionError('oversized input must not be read')):
        index=m.ingest(wire(larger),(location,))
    check('larger file rejected against declared cap before first read',index.artifacts[0].state=='conflicting'and index.artifacts[0].raw_bytes is None and index.retained_raw_bytes==0)
    mixed=envelope([descriptor(),descriptor('peer',raw=b'x')]);locations=(location,m.SourceLocation('peer','missing',None));index=m.ingest(wire(mixed),locations)
    check('mixed captured missing group remains partial unknown',index.groups[0].state=='unknown'and index.artifacts[0].state=='captured-unverified'and index.artifacts[1].state=='missing')
    mixed['artifacts'][0]['sha256']='0'*64;index=m.ingest(wire(mixed),locations)
    check('observed mismatch not hidden by missing peer',index.groups[0].state=='conflicting'and index.artifacts[1].state=='missing')
    for case in oracle['cases']:
        d=copy.deepcopy(data);d['identity']['platform']=case['platform'];d['case_id']=case['case_id'];i=m.ingest(wire(d),(location,))
        check('private captured bytes never run native '+case['platform']+'/'+case['case_id'],i.envelope.identity.platform==case['platform']and i.envelope.case_id==case['case_id']and no_native(i))
    full=[];full_locations=[]
    for n in range(12):
        file=folder/('group-'+str(n));file.write_bytes(b'x');full.append(descriptor('group-'+str(n),group=n,raw=b'x'));full_locations.append(m.SourceLocation('group-'+str(n),'file',str(file)))
    d=envelope(full);d['origin']='captured-data-unverified';d['identity'].update(boot_id='declared-old-boot',source_epoch='declared-old-epoch')
    index=m.ingest(wire(d),tuple(full_locations))
    check('all twelve captured groups still zero native proof and fresh authority',all(g.state=='captured-unverified'for g in index.groups)and no_native(index)and index.envelope.identity.boot_id=='declared-old-boot')
    for obj in [index,index.envelope,index.envelope.identity,index.artifacts[0],index.artifacts[0].location,index.artifacts[0].before,index.groups[0]]:
        key=next(iter(obj.__dataclass_fields__))
        try:setattr(obj,key,None);frozen=False
        except FrozenInstanceError:frozen=True
        check('index record ordinary mutation rejected '+type(obj).__name__,frozen)
    check('all index containers and raw bytes immutable',type(index.artifacts)is tuple and type(index.groups)is tuple and type(index.artifacts[0].raw_bytes)is bytes)
    for description,locations in [('list',[location]),('missing',()),('lookalike',({'logical_id':'raw','state':'file','absolute_path':str(good)},)),('foreign-id',(m.SourceLocation('other','file',str(good)),)),('foreign-state',(m.SourceLocation('raw','captured',None),)),('unknown-with-path',(m.SourceLocation('raw','unknown',str(good)),))]:
        check('malformed source locations rejected '+description,fails(m.ingest,wire(data),locations))
    duplicate=envelope([descriptor(),descriptor('peer')]);duplicate_locations=(location,m.SourceLocation('peer','file',str(good)))
    check('duplicate explicit file cannot supply two logical artifacts',fails(m.ingest,wire(duplicate),duplicate_locations))
    for name,p in [('relative','raw'),('root','/'),('dot',str(folder)+'/./text'),('dotdot',str(folder)+'/../text'),('double-slash',str(folder)+'//text'),('backslash',str(folder)+'/raw\\name'),('control',str(folder)+'/raw\nname'),('component-overflow',str(folder)+'/'+'x'*256),('total-overflow','/'+'a/'*2049),('bytes',b'/tmp/raw')]:
        check('unsafe explicit path rejected '+name,fails(m.ingest,wire(data),(m.SourceLocation('raw','file',p),)))
    link=folder/'leaf-link';link.symlink_to(good)
    linked=folder/'ancestor-link';linked.symlink_to(folder,target_is_directory=True)
    subdir=folder/'dir';subdir.mkdir()
    fifo=folder/'fifo';os.mkfifo(fifo)
    alias=folder/'hardlink';os.link(good,alias)
    for name,p in [('leaf-symlink',link),('ancestor-symlink',linked/'text'),('directory',subdir),('FIFO',fifo),('multi-link-regular',good)]:
        with patch('os.read',side_effect=AssertionError('unsafe input must not be read')):
            check('unsafe raw type rejected before read '+name,fails(m.ingest,wire(data),(m.SourceLocation('raw','file',str(p)),)))
    alias.unlink()
    # Deterministic private fault controls alter only files created in this test.
    real_read=os.read
    race=folder/'race';race.write_bytes(b'raw');race_location=m.SourceLocation('raw','file',str(race));done=[False]
    def grow(fd,count):
        if not done[0]:done[0]=True;race.write_bytes(b'rawX')
        return real_read(fd,count)
    with patch('os.read',side_effect=grow):index=m.ingest(wire(data),(race_location,))
    check('growth during read preserves bounded partial data no full hash',index.artifacts[0].state=='conflicting'and index.artifacts[0].raw_bytes==b'raw'and not index.artifacts[0].raw_complete and index.artifacts[0].raw_sha256 is None and index.retained_raw_bytes==3)
    race.write_bytes(b'raw');replacement=folder/'replacement';replacement.write_bytes(b'raw');done=[False]
    def replace_leaf(fd,count):
        if not done[0]:done[0]=True;os.replace(replacement,race)
        return real_read(fd,count)
    with patch('os.read',side_effect=replace_leaf):index=m.ingest(wire(data),(race_location,))
    check('same bytes replacement inode conflict remains visible',index.artifacts[0].state=='conflicting'and index.artifacts[0].raw_sha256 is None)
    race.write_bytes(b'raw');done=[False]
    def disappear(fd,count):
        if not done[0]:done[0]=True;race.unlink()
        return real_read(fd,count)
    with patch('os.read',side_effect=disappear):index=m.ingest(wire(data),(race_location,))
    check('path disappearance after binding is conflict not absent effects',index.artifacts[0].state=='conflicting'and index.artifacts[0].raw_bytes==b'raw'and index.artifacts[0].raw_sha256 is None)
    directory_race=folder/'race-dir';directory_race.mkdir();(directory_race/'raw').write_bytes(b'raw');done=[False]
    def move_directory(fd,count):
        if not done[0]:
            done[0]=True;directory_race.rename(folder/'old-race-dir');directory_race.mkdir();(directory_race/'raw').write_bytes(b'raw')
        return real_read(fd,count)
    with patch('os.read',side_effect=move_directory):index=m.ingest(wire(data),(m.SourceLocation('raw','file',str(directory_race/'raw')),))
    check('ancestor replacement detected even old opened leaf stays unchanged',index.artifacts[0].state=='conflicting'and not index.artifacts[0].declared_bytes_match)
    large=folder/'chunked';content=b'x'*(65536+7);large.write_bytes(content);large_data=envelope([descriptor(raw=content)]);calls=[]
    def record_reads(fd,count):calls.append(count);return real_read(fd,count)
    with patch('os.read',side_effect=record_reads):index=m.ingest(wire(large_data),(m.SourceLocation('raw','file',str(large)),))
    check('chunked read count capped and raw bytes exact',max(calls)<=65536 and len(calls)>=2 and index.artifacts[0].raw_bytes==content and index.artifacts[0].state=='captured-unverified')
    count=[0]
    def fail_after_chunk(fd,size):
        count[0]+=1
        if count[0]>1:raise OSError('private injected read failure')
        return real_read(fd,size)
    with patch('os.read',side_effect=fail_after_chunk):index=m.ingest(wire(large_data),(m.SourceLocation('raw','file',str(large)),))
    check('read error keeps partial bytes contradiction and no full digest',index.artifacts[0].state=='conflicting'and index.artifacts[0].raw_bytes==content[:65536]and not index.artifacts[0].raw_complete and index.artifacts[0].raw_sha256 is None)
    real_open=os.open;real_close=os.close;opened=[];closed=[]
    def track_open(*args,**kwargs):fd=real_open(*args,**kwargs);opened.append(fd);return fd
    def track_close(fd):closed.append(fd);return real_close(fd)
    with patch('os.open',side_effect=track_open),patch('os.close',side_effect=track_close):m.ingest(wire(data),(location,))
    check('all opened file ancestor descriptors closed after success',len(opened)==len(closed)and sorted(opened)==sorted(closed))
    opened.clear();closed.clear()
    with patch('os.open',side_effect=track_open),patch('os.close',side_effect=track_close):
        check('unsafe leaf rejection retains no index',fails(m.ingest,wire(data),(m.SourceLocation('raw','file',str(link)),)))
    check('all ancestor descriptors closed after unsafe rejection',len(opened)==len(closed)and sorted(opened)==sorted(closed))
    opened.clear();closed.clear()
    with patch('os.open',side_effect=track_open),patch('os.close',side_effect=track_close),patch('os.read',side_effect=OSError('private injected IO failure')):index=m.ingest(wire(data),(location,))
    check('all file ancestor descriptors closed after read failure',index.artifacts[0].state=='conflicting'and len(opened)==len(closed)and sorted(opened)==sorted(closed))
    with patch('os.open',side_effect=PermissionError('private denied read')):index=m.ingest(wire(data),(location,))
    check('unavailable explicit file remains unknown no fallback',index.artifacts[0].state=='unknown'and index.groups[0].state=='unknown'and index.artifacts[0].raw_bytes is None)

for bad in [b'',bytearray(wire(empty_envelope())),b'PK\x03\x04archive',b' '*262145,b'['*13+b'0'+b']'*13]:check('envelope input rejects malformed unsafe wire before locations',fails(m.ingest,bad,()))
tree=ast.parse((root/'tools/reference'/module).read_text())
imports={alias.name for node in ast.walk(tree)if isinstance(node,ast.Import)for alias in node.names}|{node.module for node in ast.walk(tree)if isinstance(node,ast.ImportFrom)}
check('reader imports only closed codec and POSIX read metadata libraries',imports=={'dataclasses','hashlib','json','re','os','stat'})
calls={node.func.attr for node in ast.walk(tree)if isinstance(node,ast.Call)and isinstance(node.func,ast.Attribute)and isinstance(node.func.value,ast.Name)and node.func.value.id=='os'}
check('OS calls restricted to explicit descriptor read metadata close',calls=={'open','stat','fstat','read','close'})
check('reader source contains no write open flags or process discovery APIs',not any(hasattr(m,name)for name in ['compare','collect','derive_expectations'])and not any(token in (root/'tools/reference'/module).read_text()for token in ['O_WRONLY','O_RDWR','O_CREAT','O_TRUNC','os.listdir','os.walk','subprocess','pickle','importlib','eval(']))
for arguments in [[],['--collect'],['--compare'],['--execute'],['--read','/etc/slackpkg']]:
    result=subprocess.run([sys.executable,'-B',str(root/'tools/reference'/module)]+arguments,capture_output=True)
    check('import-only reader denies command entry '+repr(arguments),result.returncode!=0 and result.stdout==b''and b'Import-only'in result.stderr)
check('native selections host and authority remain unknown and ungranted',all(contract[k]is None for k in ['actual_expected_vector_artifacts','actual_expectation_author','actual_independent_collector','actual_independent_verifier','actual_live_bindings'])and contract['actual_host_state']=='unobserved-not-claimed-absent'and contract['runtime_authority']is False and contract['native_cases_run']==contract['native_proofs_added']==0)
with tempfile.TemporaryDirectory(prefix='step352-exact-accepted351-')as directory:
    historical=Path(directory)
    for rel,data in history.items():p=historical/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
    result=subprocess.run(['bash',str(historical/'tests/reference'/('test-'+oldbase+'-harness.sh'))],capture_output=True,text=True)
    if result.returncode:raise AssertionError('unchanged351 acceptance failed: '+result.stderr[-3000:])
    check('full unchanged351246 passes on exact1746 snapshot',result.stdout.splitlines().count('Result: PASS (246 passes, 0 failures)')==1)
    check('all246 unchanged predecessor labels match complete user return',[x for x in result.stdout.splitlines()if x.startswith('PASS: ')]==policy['expected_predecessor_labels'])
check('prepared352 retains last confirmed348 pause and next353 receipt gate',contract['strong_safe_pause']is False and contract['last_confirmed_strong_safe_pause_step']==348 and contract['current_user_acceptance_pending']is True and contract['user_step352_checkpoint_confirmed']is False and contract['next_stage_after_complete352_acceptance']==353)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
