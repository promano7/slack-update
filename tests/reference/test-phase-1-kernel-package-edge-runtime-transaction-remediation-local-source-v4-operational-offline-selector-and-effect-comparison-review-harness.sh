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

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-selector-and-effect-comparison-review';oldbase='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-captured-observation-index-review';module='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-selector-effect-comparator.py'
fixture=root/'tests/fixtures/reference/acceptance/phase-1';OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-selector-and-effect-comparison-review.md': '9c93a916105d6562f02ab7e467ea8d2d44b5e1a8cff4e1a4c87c233009bc0eba', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-selector-and-effect-comparison-review-checkpoint-confirmation.json': '344d2ec1ad122a4aa6a75c2fb15c70e4f81a74f7684b7d2dfd0ab573bd5503d2', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-selector-and-effect-comparison-review-policy.json': 'cda388182fe12bf552817fd0df7bc35c478d78962241893f59396e26cd6fdfc7', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-selector-and-effect-comparison-review-comparison-contract.json': '52cdcb1b91803d34c13fb36614d1e6dc0d16b9c2768026155237c95e929952d8', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-selector-and-effect-comparison-review-private-comparison-cases.json': '17cc747f3c46bae53d5f0d3a759ec435380d0f1bc37e70eef88f6c654a8458a9', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-selector-and-effect-comparison-review-retained-obligations.json': 'df8b09722125a907e4dd09246f90ffe16e6635803ca9c758bd7d30a78fe9291c', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-selector-and-effect-comparison-review-step352-user-acceptance.json': '2cee007800509e9c5f15ad18a963ec95370e0d05faed6c6078ee394b3870a03c', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-selector-effect-comparator.py': '65b4f29977d6a8de97fda141e266f34a015d3eb9f71e8df63ba10ee52a3e6372'};passes=0
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
    p=root/rel;check('exact current353 input '+p.name,p.is_file()and not p.is_symlink()and p.resolve()==p.absolute()and sha(p.read_bytes())==digest)
policy=load('policy');contract=load('comparison-contract');retained=load('retained-obligations');private=load('private-comparison-cases');receipt=load('step352-user-acceptance');confirmed=load('checkpoint-confirmation')
history={}
for rel,digest in policy['baseline_sha256_bindings'].items():
    p=root/rel
    if not p.is_file()or p.is_symlink()or p.resolve()!=p.absolute():raise ValueError('unsafe accepted source')
    raw=p.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size']:]
    if sha(raw)!=digest:raise ValueError('accepted352 source drift '+rel)
    history[rel]=raw
check('all1755 accepted352 bytes and exact historical CHANGELOG suffix',len(history)==1755)
raw=receipt['text'].encode();lines=receipt['text'].splitlines()
check('complete20418-byte original352 receipt retained without normalization',len(raw)==20418 and sha(raw)=='17210838f58607a55e6dc79963d5c9d49ab59159d2a4607ad9705f4e3ca2a7ca' and receipt['original_display_sha256']==sha(raw) and receipt['original_display_size_bytes']==len(raw) and receipt['ordered_output_normalization']=='none')
check('complete187 predecessor labels exactly match original receipt',[x for x in lines if x.startswith('PASS: ')]==policy['expected_predecessor_labels'] and lines.count('Result: PASS (187 passes, 0 failures)')==1)
check('reportedfbacbbb exact tenfiles3501 commit nine paths and successful push','[main fbacbbb] Phase 1 step 352: implement bounded read-only observation index'in lines and ' 10 files changed, 3501 insertions(+)'in lines and set(x[len(' create mode 100644 '):]for x in lines if x.startswith(' create mode 100644 '))==set(policy['expected_predecessor_paths']) and '   149fd78..fbacbbb  main -> main'in lines)
check('complete clean matching heads and full352 commit unknown',lines[-3:-1]==['fbacbbb (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 352: implement bounded read-only observation index']*2 and confirmed['commit_full']is None and confirmed['evidence_sha256']==sha(raw) and all(confirmed[k]is True for k in ['user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','complete_ordered_return_matches_prepared_and_installed']))
bindings=list(retained['source_bindings'].values())+list(retained['model_modules'].values())+list(retained['original_design_bindings'].values())+list(retained['accepted351_bindings'].values())+list(retained['accepted351_bindings'].values())+list(retained['accepted352_bindings'].values())+[retained['accepted349_plan_binding'],retained['schema_module_binding'],retained['expectation_module_binding'],retained['observation_module_binding']]
for binding in bindings:check('source-bound unchanged inherited '+Path(binding['path']).name,sha(history[binding['path']])==binding['sha256'])
oracle=json.loads(history[retained['source_bindings']['oracle335']['path']])
check('full twelve original native evidence group rows retained',retained['original_evidence_group_rows']==oracle['evidence_groups'])
check('all eight full original320-327 contracts retained',set(retained['original_design_bindings'])==set(str(i)for i in range(320,328)))
check('all52 source-bound native cases still unrun',len(retained['original_case_row_sha256'])==len(oracle['cases'])==52 and all(row['status']=='required-not-run'and row['sha256']==sha(json.dumps(original,sort_keys=True,separators=(',',':')).encode())for row,original in zip(retained['original_case_row_sha256'],oracle['cases'])))
check('all46 proofs52 cases16 gaps retained',[retained['counts'][k]for k in ['native_proofs','native_cases','native_gaps']]==[46,52,16])
check('seven frozen modules nine original pause conditions retained',len(retained['model_modules'])==7 and len(retained['original_pause_conditions'])==9)
copied=retained['codec_static_copy'];original=history[copied['path']].decode();prefix=original[:original.index("\n\nif __name__ == '__main__':")]
check('static351 data codec copy exact without dynamic import',sha(original.encode())==copied['full_source_sha256']and sha(prefix.encode())==copied['copied_prefix_sha256']and (root/'tools/reference'/module).read_text().startswith(prefix+'\n'))
m=SimpleNamespace(**runpy.run_path(str(root/'tools/reference'/module)))
check('two packet kinds cover all18 slots once and preserve full order',len(m.PACKET_SPECS)==2 and sorted(f for _,_,ss in m.PACKET_SPECS for f,_ in ss)==sorted(f for f,_ in m.FIELD_SPECS[0][1]))
check('all twelve original native groups retained pending',m.NATIVE_GROUP_IDS==tuple(row['id']for row in oracle['evidence_groups']))
check('all38 recovery publication slots untouched at353',sum(len(ss)for _,ss in m.FIELD_SPECS[1:])==contract['untouched_later_field_count']==38)
def wire(d):return(json.dumps(d,sort_keys=True,separators=(',',':'),ensure_ascii=True)+'\n').encode('ascii')
def packet(row,kind):
 specs=next(ss for v,_,ss in m.PACKET_SPECS if v==kind)
 return dict(schema_version=1,origin='captured-vector-unverified',case_id=row['expectations']['case_id'],identity=row['packet_identity'],vector_id=kind,fields=[dict(field_id=f,value=copy.deepcopy(row['observed_fields'][f]))for f,_ in specs])
def captures(row):
 result=[]
 for kind,group,_ in m.PACKET_SPECS:
  raw=wire(packet(row,kind));result.append(m.CapturedPacket(kind,group,'present-unverified',row['capture_state'],row['expectations']['case_id'],m.Identity(**row['expectations']['identity']),len(raw),sha(raw),True,sha(raw),raw))
 return tuple(result)
def compare_row(row):return m.compare(m.decode(wire(row['expectations'])),captures(row))
def codes(result):return {d.code for d in result.diagnostics}
def safe(result):return result.comparison_performed and not any([result.independence_verified,result.native_oracle_selected,result.native_conformance,result.runtime_authority])and result.native_cases_run==result.native_proofs_added==0 and result.pending_native_groups==m.NATIVE_GROUP_IDS
check('private fixtures cannot claim native proof or authority',private['native_cases_run']==private['native_proofs_added']==0 and private['runtime_authority']is False)
for row in private['cases']:
 result=compare_row(row)
 check('independent literal diagnostics '+row['id'],result.agreement_state==row['expected_agreement']and set(row['required_diagnostic_codes'])<=codes(result))
 check('zero native authority despite private data result '+row['id'],safe(result)and len(result.fields)==18)
base_row=copy.deepcopy(private['cases'][0]);e=m.decode(wire(base_row['expectations']));good=captures(base_row);baseline_result=m.compare(e,good)
check('full known18 literal agreement never native conformance',baseline_result.agreement_state=='match'and all(f.state=='match'for f in baseline_result.fields)and safe(baseline_result))
for n,capture in enumerate(good):
 p=m.decode_packet(capture.raw_bytes)
 check('canonical full packet roundtrip '+p.vector_id,m.encode_packet(p)==capture.raw_bytes)
 for field in p.fields:
  bad=json.loads(capture.raw_bytes);bad['fields']=[x for x in bad['fields']if x['field_id']!=field.field_id]
  check('every required observation slot missing rejected '+field.field_id,fails(m.decode_packet,wire(bad)))
for field_id,kind in m.FIELD_SPECS[0][1]:
 row=copy.deepcopy(base_row);row['observed_fields'][field_id]=None;result=compare_row(row)
 check('unknown observed never equals known empty success '+field_id,result.agreement_state=='pending'and next(f for f in result.fields if f.field_id==field_id).state=='pending'and safe(result))
 row=copy.deepcopy(base_row)
 for f in row['expectations']['vectors'][0]['fields']:
  if f['field_id']==field_id:f['value']=None
 result=compare_row(row)
 check('unknown expectation never a wildcard '+field_id,result.agreement_state=='pending'and next(f for f in result.fields if f.field_id==field_id).state=='pending')
 row['observed_fields'][field_id]=None;result=compare_row(row)
 check('two unknown declarations cannot manufacture equality '+field_id,next(f for f in result.fields if f.field_id==field_id).state=='pending')
for key in m.Identity.__dataclass_fields__:
 if key=='platform':continue
 row=copy.deepcopy(base_row);row['expectations']['identity'][key]=None;row['packet_identity'][key]=None
 result=compare_row(row)
 check('nullable identity stays pending '+key,result.agreement_state=='pending'and 'identity-pending'in codes(result))
 row=copy.deepcopy(base_row);row['packet_identity'][key]='f'*64 if key=='subject_source_sha256'else'foreign-'+key
 result=compare_row(row)
 check('known identity contradiction retained '+key,result.agreement_state=='mismatch'and 'identity-mismatch'in codes(result))
row=copy.deepcopy(base_row);row['observed_fields']['upgrade-all-selector']=['wrong-target'];cs=captures(row)
cs=(cs[0],replace(cs[1],observation_state='unknown',raw_bytes=None,raw_complete=False,raw_sha256=None))
result=m.compare(e,cs)
check('known selector mismatch remains visible with unknown effects',result.agreement_state=='mismatch'and any(f.state=='mismatch'for f in result.fields)and any(f.state=='pending'for f in result.fields))
for state in ['missing','unknown']:
 cs=tuple(replace(c,observation_state=state,declared_state=state,raw_bytes=None,raw_complete=False,raw_sha256=None)for c in good);result=m.compare(e,cs)
 check('unavailable packets stay pending '+state,result.agreement_state=='pending'and all(f.observed is None for f in result.fields)and safe(result))
cs=tuple(replace(c,declared_state='unknown')for c in good);result=m.compare(e,cs)
check('matching bytes cannot clear unknown declared groups',result.agreement_state=='pending'and all(f.state=='match'for f in result.fields)and 'capture-pending'in codes(result))
cs=(replace(good[0],raw_complete=False,raw_sha256=None,raw_bytes=good[0].raw_bytes[:30],observation_state='conflicting'),good[1]);result=m.compare(e,cs)
check('partial contradictory bytes retained pending never parsed',result.agreement_state=='mismatch'and 'capture-conflict'in codes(result)and 'incomplete-raw-bytes'in codes(result)and all(f.observed is None for f in result.fields if f.field_id not in m.EFFECT_IDS))
for name,changes,code in [('declared-hash',dict(declared_sha256='f'*64),'descriptor-bytes-conflict'),('raw-hash',dict(raw_sha256='f'*64),'raw-hash-declaration-conflict'),('missing-complete-hash',dict(raw_sha256=None),'raw-hash-declaration-conflict'),('declared-size',dict(declared_size_bytes=good[0].declared_size_bytes+1),'descriptor-bytes-conflict')]:
 result=m.compare(e,(replace(good[0],**changes),good[1]))
 check('complete bytes recomputed despite '+name,result.agreement_state=='mismatch'and code in codes(result)and all(f.state=='match'for f in result.fields))
for name,raw in [('empty',b''),('script',b'#!/bin/sh\necho native-proof\n'),('archive',b'PK\x03\x04raw'),('selfreport',b'{"native_conformance":true}\n')]:
 c=replace(good[0],raw_bytes=raw,declared_size_bytes=len(raw),declared_sha256=sha(raw),raw_sha256=sha(raw));result=m.compare(e,(c,good[1]))
 check('opaque malformed payload cannot supply packet data '+name,result.agreement_state=='mismatch'and 'malformed-observation-packet'in codes(result)and safe(result))
raw=good[1].raw_bytes;c=replace(good[0],raw_bytes=raw,declared_size_bytes=len(raw),declared_sha256=sha(raw),raw_sha256=sha(raw));result=m.compare(e,(c,good[1]))
check('packet cannot cross evidence group binding',result.agreement_state=='mismatch'and 'packet-group-mismatch'in codes(result))
for name,raw in [('empty',b''),('bytearray',bytearray(good[0].raw_bytes)),('oversized',b' '*262145),('nonascii',b'\xff'),('depth',b'['*13+b'0'+b']'*13),('duplicate-key',good[0].raw_bytes.replace(b'"schema_version":1',b'"schema_version":1,"schema_version":1')),('pretty',json.dumps(json.loads(good[0].raw_bytes),indent=2).encode()),('no-lf',good[0].raw_bytes[:-1]),('nan',good[0].raw_bytes.replace(b'"schema_version":1',b'"schema_version":NaN'))]:
 check('strict bounded packet parser rejects '+name,fails(m.decode_packet,raw))
for name,change in [('extra',lambda d:d.update(native_conformance=True)),('origin',lambda d:d.update(origin='verified-native')),('wrong-version',lambda d:d.update(schema_version=True)),('extra-identity',lambda d:d['identity'].update(authority=True)),('wrong-case',lambda d:d.update(case_id='invented-case')),('foreign-platform',lambda d:d['identity'].update(platform='other')),('swapped-fields',lambda d:d['fields'].reverse()),('duplicate-field',lambda d:d['fields'].__setitem__(1,d['fields'][0]))]:
 d=json.loads(good[0].raw_bytes);change(d);check('closed observation packet rejects '+name,fails(m.decode_packet,wire(d)))
for field_id,kind in m.FIELD_SPECS[0][1]:
 packet_kind=next(v for v,_,ss in m.PACKET_SPECS if any(f==field_id for f,_ in ss));d=packet(base_row,packet_kind);f=next(f for f in d['fields']if f['field_id']==field_id)
 f['value']={'status':True,'digest':'A'*64,'bool':1,'labels':[None],'statuses':[True]}[kind]
 check('exact observation field type rejects '+field_id,fails(m.decode_packet,wire(d)))
for name,cs in [('list',list(good)),('short',good[:1]),('lookalike',(dict(good[0].__dict__),good[1])),('swapped',tuple(reversed(good))),('duplicate-id',(good[0],replace(good[1],logical_id=good[0].logical_id))),('unsafe-id',(replace(good[0],logical_id='../raw'),good[1])),('complete-no-bytes',(replace(good[0],raw_bytes=None),good[1])),('partial-fullhash',(replace(good[0],raw_complete=False),good[1])),('unknown-with-bytes',(replace(good[0],observation_state='unknown'),good[1])),('oversized-declaration',(replace(good[0],declared_size_bytes=67108865),good[1])),('negative-size',(replace(good[0],declared_size_bytes=-1),good[1])),('bool-size',(replace(good[0],declared_size_bytes=True),good[1])),('mutable-bytes',(replace(good[0],raw_bytes=bytearray(good[0].raw_bytes)),good[1])),('bytes-over-cap',(replace(good[0],declared_size_bytes=1),good[1]))]:
 check('malformed untrusted capture projection rejected '+name,fails(m.compare,e,cs))
row=copy.deepcopy(base_row);row['observed_fields'].update({'update-raw-status':7,'install-new-raw-status':-1,'upgrade-all-raw-status':-1,'upgrade-all-selector':[],'upgrade-all-target-effects':[],'upgrade-all-owned-effects':[],'full-forward-raw-status-vector':[7,-1,-1]});result=compare_row(row)
check('stopped forward path retains7 and minusone never success',result.agreement_state=='mismatch'and 'action-after-forward-failure'not in codes(result)and [next(f.observed for f in result.fields if f.field_id==k+'-raw-status')for k in ['update','install-new','upgrade-all']]==[7,-1,-1])
row=copy.deepcopy(base_row);row['observed_fields'].update({'forward-stage-ids':['prefix','update','install-new','upgrade-all','suffix'],'full-forward-raw-status-vector':[0,0,0,0,0]})
for field in row['expectations']['vectors'][0]['fields']:
 if field['field_id'] in ['forward-stage-ids','full-forward-raw-status-vector']:field['value']=copy.deepcopy(row['observed_fields'][field['field_id']])
result=compare_row(row)
check('extra forward stages preserved full literal equality not discarded',result.agreement_state=='match'and next(f.observed for f in result.fields if f.field_id=='forward-stage-ids')==('prefix','update','install-new','upgrade-all','suffix')and safe(result))
for vid,ss in m.FIELD_SPECS[1:]:
 d=copy.deepcopy(base_row['expectations'])
 for f,(_,kind)in zip(next(v['fields']for v in d['vectors']if v['vector_id']==vid),ss):
  f['value']={'status':7,'bool':False,'labels':['private-uninterpreted'],'label':'private-uninterpreted','digest':'e'*64,'time':1,'budget':1}.get(kind)
 result=m.compare(m.decode(wire(d)),good)
 check('later vector never erases forward comparison '+vid,result==baseline_result)
for obj in [e,e.identity,good[0],m.decode_packet(good[0].raw_bytes),baseline_result,baseline_result.fields[0]]:
 key=next(iter(obj.__dataclass_fields__))
 try:setattr(obj,key,None);frozen=False
 except FrozenInstanceError:frozen=True
 check('ordinary mutation denied '+type(obj).__name__,frozen)
# Integration uses unchanged352 on two private files, then explicitly transcribes
# the immutable observations into353 classes. No callback enters the comparator.
reader=SimpleNamespace(**runpy.run_path(str(root/retained['observation_module_binding']['path'])))
with tempfile.TemporaryDirectory(prefix='step353-private352-integration-')as directory:
 folder=Path(directory);descriptors=[];locations=[]
 for c in good:
  file=folder/c.logical_id;file.write_bytes(c.raw_bytes);locations.append(reader.SourceLocation(c.logical_id,'file',str(file)))
  descriptors.append(dict(logical_id=c.logical_id,evidence_group=c.evidence_group,sha256=c.declared_sha256,size_bytes=c.declared_size_bytes,media_type='application/json',producer_role='unattributed',capture_stage='unspecified'))
 envelope=dict(schema_version=1,origin='private-fixture',case_id=e.case_id,identity=base_row['expectations']['identity'],artifacts=descriptors,groups=[dict(group_id=g,status='present-unverified'if any(c.evidence_group==g for c in good)else'missing',artifact_ids=[c.logical_id for c in good if c.evidence_group==g])for g in reader.GROUP_IDS])
 index=reader.ingest(wire(envelope),tuple(locations))
 def project(index):
  return tuple(m.CapturedPacket(o.descriptor.logical_id,o.descriptor.evidence_group,next(g.declared_state for g in index.groups if g.group_id==o.descriptor.evidence_group),o.state,index.envelope.case_id,m.Identity(**{k:getattr(index.envelope.identity,k)for k in m.Identity.__dataclass_fields__}),o.descriptor.size_bytes,o.descriptor.sha256,o.raw_complete,o.raw_sha256,o.raw_bytes)for o in index.artifacts)
 result=m.compare(e,project(index))
 check('unchanged352 raw ingestion feeds353 exact explicit projection',result==baseline_result and all(o.state=='captured-unverified'for o in index.artifacts)and safe(result))
 check('integration reads only private immutable source files',all((folder/c.logical_id).read_bytes()==c.raw_bytes for c in good))
 envelope['artifacts'][0]['sha256']='f'*64;index=reader.ingest(wire(envelope),tuple(locations));result=m.compare(e,project(index))
 check('real352 captured hash conflict survives353 known field matches',index.artifacts[0].state=='conflicting'and result.agreement_state=='mismatch'and 'capture-conflict'in codes(result)and 'descriptor-bytes-conflict'in codes(result))
 envelope['artifacts'][0]['sha256']=good[0].declared_sha256;index=reader.ingest(wire(envelope),(locations[0],reader.SourceLocation(good[1].logical_id,'unknown',None)));result=m.compare(e,project(index))
 check('real352 unknown effect capture remains pending in353',result.agreement_state=='pending'and 'capture-pending'in codes(result)and safe(result))
tree=ast.parse((root/'tools/reference'/module).read_text());imports={a.name for node in ast.walk(tree)if isinstance(node,ast.Import)for a in node.names}|{node.module for node in ast.walk(tree)if isinstance(node,ast.ImportFrom)}
check('pure comparator imports only closed data libraries',imports=={'dataclasses','json','re','hashlib'})
check('pure comparator has no I O callback collector dispatch or model import',not any(token in (root/'tools/reference'/module).read_text()for token in ['open(', 'subprocess','os.', 'importlib', 'eval(', 'exec(', 'pickle', 'derive_expectations','socket','urllib']))
for args in [[],['--compare'],['--collect'],['--execute'],['--recover']]:
 p=subprocess.run([sys.executable,'-B',str(root/'tools/reference'/module)]+args,capture_output=True)
 check('import-only comparator denies CLI '+repr(args),p.returncode!=0 and p.stdout==b''and b'Import-only'in p.stderr)
check('native selections and actual host remain unknown no authority',all(contract[k]is None for k in ['actual_expected_vector_artifacts','actual_expectation_author','actual_independent_collector','actual_independent_verifier','actual_live_bindings'])and contract['actual_host_state']=='unobserved-not-claimed-absent'and contract['runtime_authority']is False and contract['native_cases_run']==contract['native_proofs_added']==0)
with tempfile.TemporaryDirectory(prefix='step353-exact-accepted352-')as directory:
 historical=Path(directory)
 for rel,data in history.items():p=historical/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
 result=subprocess.run(['bash',str(historical/'tests/reference'/('test-'+oldbase+'-harness.sh'))],capture_output=True,text=True)
 if result.returncode:raise AssertionError('unchanged352 acceptance failed: '+result.stderr[-3000:])
 check('full unchanged352187 passes on exact1755 snapshot',result.stdout.splitlines().count('Result: PASS (187 passes, 0 failures)')==1)
 check('all187 unchanged predecessor labels match complete user return',[x for x in result.stdout.splitlines()if x.startswith('PASS: ')]==policy['expected_predecessor_labels'])
check('prepared353 preserves348 pause and receipt gate for354',contract['strong_safe_pause']is False and contract['last_confirmed_strong_safe_pause_step']==348 and contract['current_user_acceptance_pending']is True and contract['user_step353_checkpoint_confirmed']is False and contract['next_stage_after_complete353_acceptance']==354)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
