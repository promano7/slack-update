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

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-recovery-and-obligation-comparison-review';oldbase='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-selector-and-effect-comparison-review';module='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-recovery-obligation-comparator.py'
fixture=root/'tests/fixtures/reference/acceptance/phase-1';OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-recovery-and-obligation-comparison-review.md': '06d4804b4d8a4111bb201426cd4e18b3940e63083f1288e67a96aadfa50ac28f', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-recovery-and-obligation-comparison-review-checkpoint-confirmation.json': 'd567c6ff39bbe149ac2c40f9ca0288d3bb110a0c14a9c13f3c8db434936e67e0', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-recovery-and-obligation-comparison-review-policy.json': 'd8a55f9b5f8086839a8f46c593ad07422f728157224a275fd034df84b6a1ec93', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-recovery-and-obligation-comparison-review-comparison-contract.json': '94bc14bb97d5f837fec348942b30ffcf0223ea81d95bffc708863a31e02bf031', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-recovery-and-obligation-comparison-review-private-comparison-cases.json': 'c30c92a6a93094301976088c8ff806714c8a5f3d865b871142a45a2a961ef197', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-recovery-and-obligation-comparison-review-retained-obligations.json': 'b6aec90467803818ba63af726befee18667420eb81992f45ea72b0ace2a9463d', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-recovery-and-obligation-comparison-review-step353-user-acceptance.json': 'fde2ea1ee0ebc310050e8311cc98270ed9aa2c3a05ee4e4924bb7150625ecf68', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-recovery-obligation-comparator.py': '0aea9dbe37f1b3e1ea3f4b03bd3535adf2ed1763ba97b75b6cbf976d0fe1aacb'};passes=0
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
    p=root/rel;check('exact current354 input '+p.name,p.is_file()and not p.is_symlink()and p.resolve()==p.absolute()and sha(p.read_bytes())==digest)
policy=load('policy');contract=load('comparison-contract');retained=load('retained-obligations');private=load('private-comparison-cases');receipt=load('step353-user-acceptance');confirmed=load('checkpoint-confirmation')
history={}
for rel,digest in policy['baseline_sha256_bindings'].items():
    p=root/rel
    if not p.is_file()or p.is_symlink()or p.resolve()!=p.absolute():raise ValueError('unsafe accepted source')
    raw=p.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size']:]
    if sha(raw)!=digest:raise ValueError('accepted353 source drift '+rel)
    history[rel]=raw
check('all1764 accepted353 bytes and exact historical CHANGELOG suffix',len(history)==1764)
raw=receipt['text'].encode();lines=receipt['text'].splitlines()
check('complete32782-byte original353 receipt retained without normalization',len(raw)==32782 and sha(raw)=='ee38c978996afc192896c97647ddccc43a3182713fe7e6783c692249cc6a9ab4' and receipt['original_display_sha256']==sha(raw) and receipt['original_display_size_bytes']==len(raw) and receipt['ordered_output_normalization']=='none')
check('complete330 predecessor labels exactly match original receipt',[x for x in lines if x.startswith('PASS: ')]==policy['expected_predecessor_labels'] and lines.count('Result: PASS (330 passes, 0 failures)')==1)
check('reported72b1a4e exact tenfiles20257 commit nine paths and successful push','[main 72b1a4e] Phase 1 step 353: compare offline selector status and effect vectors'in lines and ' 10 files changed, 20257 insertions(+)'in lines and set(x[len(' create mode 100644 '):]for x in lines if x.startswith(' create mode 100644 '))==set(policy['expected_predecessor_paths']) and '   fbacbbb..72b1a4e  main -> main'in lines)
check('complete clean matching heads and full353 commit unknown',lines[-3:-1]==['72b1a4e (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 353: compare offline selector status and effect vectors']*2 and confirmed['commit_full']is None and confirmed['evidence_sha256']==sha(raw) and all(confirmed[k]is True for k in ['user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','complete_ordered_return_matches_prepared_and_installed']))
bindings=list(retained['source_bindings'].values())+list(retained['model_modules'].values())+list(retained['original_design_bindings'].values())+sum((list(retained[k].values())for k in ['accepted350_bindings','accepted351_bindings','accepted352_bindings','accepted353_bindings']),[])+[retained['accepted349_plan_binding'],retained['schema_module_binding'],retained['expectation_module_binding'],retained['observation_module_binding'],retained['selector_comparator_module_binding']]
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
check('five packets cover all17 recovery fields exactly once',len(m.PACKET_SPECS)==5 and sorted(f for _,_,ss in m.PACKET_SPECS for f,_ in ss)==sorted(f for f,_ in m.FIELD_SPECS[1][1]))
check('original group IDs exact and twelve native groups pending',m.NATIVE_GROUP_IDS==tuple(row['id']for row in oracle['evidence_groups']))
check('eighteen selector twentyone publication slots shape only',len(m.FIELD_SPECS[0][1])==contract['untouched_selector_field_count']==18 and len(m.FIELD_SPECS[2][1])==contract['untouched_publication_field_count']==21)
helper_binding=retained['packet_helper_static_copy'];accepted_helpers=history[helper_binding['path']].decode();segment=accepted_helpers[accepted_helpers.index(helper_binding['start']):accepted_helpers.index(helper_binding['end'])]
check('exact accepted353 pure helper segment statically copied',sha(segment.encode())==helper_binding['copied_segment_sha256']and len(segment.encode())==helper_binding['copied_segment_size_bytes']and segment in (root/'tools/reference'/module).read_text())
check('all ten native recovery proof categories always pending',len(m.PENDING_NATIVE_RECOVERY_REQUIREMENTS)==10 and list(m.PENDING_NATIVE_RECOVERY_REQUIREMENTS)==contract['pending_native_recovery_requirements'])
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
def safe(result):return result.comparison_performed and not any([result.forward_failure_cleared,result.recovery_writes_allowed,result.target_release_allowed,result.retry_or_new_grant_allowed,result.independence_verified,result.native_oracle_selected,result.native_conformance,result.runtime_authority])and result.native_cases_run==result.native_proofs_added==0 and result.pending_native_groups==m.NATIVE_GROUP_IDS and result.pending_native_recovery_requirements==m.PENDING_NATIVE_RECOVERY_REQUIREMENTS
check('private literal controls never native cases or authority',private['native_cases_run']==private['native_proofs_added']==0 and private['runtime_authority']is False)
for row in private['cases']:
 result=compare_row(row)
 check('independent literal recovery diagnostics '+row['id'],result.agreement_state==row['expected_agreement']and set(row['required_diagnostic_codes'])<=codes(result))
 check('data result retains status obligations and zero authority '+row['id'],safe(result)and len(result.fields)==17 and result.original_forward_status==row['observed_fields']['original-forward-status']and result.pending_target_obligations==(None if row['observed_fields']['pending-target-obligations']is None else tuple(row['observed_fields']['pending-target-obligations']))and result.pending_owned_obligations==(None if row['observed_fields']['pending-owned-obligations']is None else tuple(row['observed_fields']['pending-owned-obligations'])))
base_row=copy.deepcopy(private['cases'][0]);e=m.decode(wire(base_row['expectations']));good=captures(base_row);baseline_result=m.compare(e,good)
check('verified restoration data retains original failure7',baseline_result.agreement_state=='match'and baseline_result.original_forward_status==7 and baseline_result.original_forward_outcome=='failed'and safe(baseline_result))
check('all raw captures retained without normalizing bytes or declarations',baseline_result.captures is good and all(c.raw_bytes==good[i].raw_bytes for i,c in enumerate(baseline_result.captures)))
for capture in good:
 p=m.decode_packet(capture.raw_bytes)
 check('canonical bounded recovery packet roundtrip '+p.vector_id,m.encode_packet(p)==capture.raw_bytes)
 for field in p.fields:
  d=json.loads(capture.raw_bytes);d['fields']=[x for x in d['fields']if x['field_id']!=field.field_id]
  check('every required recovery observation slot missing rejected '+field.field_id,fails(m.decode_packet,wire(d)))
for field_id,kind in m.FIELD_SPECS[1][1]:
 row=copy.deepcopy(base_row);row['observed_fields'][field_id]=None;result=compare_row(row)
 check('unknown observed recovery stays pending '+field_id,result.agreement_state=='pending'and next(f for f in result.fields if f.field_id==field_id).state=='pending'and safe(result))
 row=copy.deepcopy(base_row)
 for f in row['expectations']['vectors'][1]['fields']:
  if f['field_id']==field_id:f['value']=None
 result=compare_row(row)
 check('unknown expected recovery never wildcard '+field_id,result.agreement_state=='pending'and next(f for f in result.fields if f.field_id==field_id).state=='pending')
 row['observed_fields'][field_id]=None;result=compare_row(row)
 check('two unknown recovery fields cannot make success '+field_id,next(f for f in result.fields if f.field_id==field_id).state=='pending'and safe(result))
for key in m.Identity.__dataclass_fields__:
 if key=='platform':continue
 row=copy.deepcopy(base_row);row['expectations']['identity'][key]=None;row['packet_identity'][key]=None;result=compare_row(row)
 check('nullable full original identity remains pending '+key,result.agreement_state=='pending'and 'identity-pending'in codes(result))
 row=copy.deepcopy(base_row);row['packet_identity'][key]='f'*64 if key=='subject_source_sha256'else'foreign-'+key;result=compare_row(row)
 check('foreign original recovery identity contradicts '+key,result.agreement_state=='mismatch'and 'identity-mismatch'in codes(result))
for key in ['platform','case_id']:
 cs=list(good)
 if key=='platform':cs[0]=replace(cs[0],identity=replace(cs[0].identity,platform='Slackware-current'))
 else:cs[0]=replace(cs[0],case_id='actual-selector')
 result=m.compare(e,tuple(cs))
 check('foreign capture case platform cannot restore current attempt '+key,result.agreement_state=='mismatch'and ('identity-mismatch'if key=='platform'else'case-mismatch')in codes(result))
for state in ['missing','unknown']:
 cs=tuple(replace(c,declared_state=state,observation_state=state,raw_bytes=None,raw_complete=False,raw_sha256=None)for c in good);result=m.compare(e,cs)
 check('all unavailable recovery captures stay pending '+state,result.agreement_state=='pending'and result.original_forward_status is None and result.original_forward_outcome=='unknown'and result.pending_target_obligations is None and result.pending_owned_obligations is None and safe(result))
cs=tuple(replace(c,declared_state='unknown')for c in good);result=m.compare(e,cs)
check('matching recovery bytes cannot close unknown group declarations',result.agreement_state=='pending'and all(f.state=='match'for f in result.fields)and safe(result))
row=copy.deepcopy(base_row);row['observed_fields']['recovery-fence-valid']=False;cs=list(captures(row));cs[1]=replace(cs[1],observation_state='unknown',raw_bytes=None,raw_complete=False,raw_sha256=None);result=m.compare(e,tuple(cs))
check('known invalid recovery fence remains mismatch with unknown children',result.agreement_state=='mismatch'and 'valid-recovery-fence-required'in codes(result)and any(f.state=='pending'for f in result.fields))
cs=list(good);cs[3]=replace(cs[3],raw_complete=False,raw_sha256=None,raw_bytes=cs[3].raw_bytes[:30],observation_state='conflicting');result=m.compare(e,tuple(cs))
check('partial restoration capture retains contradiction no complete parsing',result.agreement_state=='mismatch'and 'capture-conflict'in codes(result)and 'incomplete-raw-bytes'in codes(result)and next(f.observed for f in result.fields if f.field_id=='original-restoration-state')is None and result.captures[3].raw_bytes==good[3].raw_bytes[:30])
for name,changes,code in [('descriptor-hash',dict(declared_sha256='f'*64),'descriptor-bytes-conflict'),('raw-hash',dict(raw_sha256='f'*64),'raw-hash-declaration-conflict'),('missing-complete-hash',dict(raw_sha256=None),'raw-hash-declaration-conflict'),('declared-size',dict(declared_size_bytes=good[0].declared_size_bytes+1),'descriptor-bytes-conflict')]:
 cs=list(good);cs[0]=replace(cs[0],**changes);result=m.compare(e,tuple(cs))
 check('complete recovery bytes recomputed despite '+name,result.agreement_state=='mismatch'and code in codes(result)and all(f.state=='match'for f in result.fields)and result.original_forward_status==7)
for name,raw in [('empty',b''),('script',b'#!/bin/sh\necho restore\n'),('archive',b'PK\x03\x04raw'),('selfreport',b'{"restoration_verified":true,"runtime_authority":true}\n')]:
 cs=list(good);cs[3]=replace(cs[3],raw_bytes=raw,declared_size_bytes=len(raw),declared_sha256=sha(raw),raw_sha256=sha(raw));result=m.compare(e,tuple(cs))
 check('opaque raw payload never restoration proof '+name,result.agreement_state=='mismatch'and 'malformed-observation-packet'in codes(result)and safe(result))
cs=list(good);raw=good[3].raw_bytes;cs[0]=replace(cs[0],raw_bytes=raw,declared_size_bytes=len(raw),declared_sha256=sha(raw),raw_sha256=sha(raw));result=m.compare(e,tuple(cs))
check('packet cannot cross native evidence group binding',result.agreement_state=='mismatch'and 'packet-group-mismatch'in codes(result))
for name,raw in [('empty',b''),('bytearray',bytearray(good[0].raw_bytes)),('wire-bound',b' '*262145),('nonascii',b'\xff'),('depth-bound',b'['*13+b'0'+b']'*13),('duplicate-key',good[0].raw_bytes.replace(b'"schema_version":1',b'"schema_version":1,"schema_version":1')),('pretty',json.dumps(json.loads(good[0].raw_bytes),indent=2).encode()),('no-lf',good[0].raw_bytes[:-1]),('nan',good[0].raw_bytes.replace(b'"schema_version":1',b'"schema_version":NaN'))]:check('strict recovery packet parser rejects '+name,fails(m.decode_packet,raw))
for name,change in [('extra',lambda d:d.update(recovery_writes_allowed=True)),('origin',lambda d:d.update(origin='trusted-native')),('version',lambda d:d.update(schema_version=True)),('extra-identity',lambda d:d['identity'].update(authority=True)),('case',lambda d:d.update(case_id='invented-case')),('platform',lambda d:d['identity'].update(platform='other')),('swapped-fields',lambda d:d['fields'].reverse()),('duplicate-field',lambda d:d['fields'].__setitem__(1,d['fields'][0]))]:
 d=json.loads(good[0].raw_bytes);change(d);check('closed recovery packet rejects '+name,fails(m.decode_packet,wire(d)))
for field_id,kind in m.FIELD_SPECS[1][1]:
 pk=next(v for v,_,ss in m.PACKET_SPECS if any(f==field_id for f,_ in ss));d=packet(base_row,pk);f=next(f for f in d['fields']if f['field_id']==field_id)
 f['value']={'status':True,'bool':1,'labels':[None],'label':['restored'],'time-ns':True,'budget':True}[kind]
 check('exact recovery observation field type rejects '+field_id,fails(m.decode_packet,wire(d)))
# Numeric and full-vector bounds at the actual observation parser boundary.
for field_id,invalids,valids in [('original-forward-status',[-2,256],[-1,255]),('recovery-deadline-ns',[-1,9223372036854775808],[0,9223372036854775807]),('recovery-budget-remaining',[-1,65536],[0,65535]),('owned-child-identities',[[None],['x']*129],[[],['x']*128]),('original-restoration-state',['x'*129,' leading','bad\nlabel'],['x'*128])]:
 pk=next(v for v,_,ss in m.PACKET_SPECS if any(f==field_id for f,_ in ss))
 for n,value in enumerate(invalids):
  d=packet(base_row,pk);next(f for f in d['fields']if f['field_id']==field_id)['value']=value
  check('observation field bound rejects '+field_id+'/'+str(n),fails(m.decode_packet,wire(d)))
 for n,value in enumerate(valids):
  d=packet(base_row,pk);next(f for f in d['fields']if f['field_id']==field_id)['value']=value
  check('observation shape bound accepts data only '+field_id+'/'+str(n),m.encode_packet(m.decode_packet(wire(d)))==wire(d))
for name,cs in [('list',list(good)),('short',good[:4]),('lookalike',(dict(good[0].__dict__),)+good[1:]),('swapped',tuple(reversed(good))),('duplicate-id',(replace(good[0],logical_id=good[1].logical_id),)+good[1:]),('unsafe-id',(replace(good[0],logical_id='../raw'),)+good[1:]),('complete-no-bytes',(replace(good[0],raw_bytes=None),)+good[1:]),('partial-fullhash',(replace(good[0],raw_complete=False),)+good[1:]),('unknown-with-bytes',(replace(good[0],observation_state='unknown'),)+good[1:]),('oversized',(replace(good[0],declared_size_bytes=67108865),)+good[1:]),('negative-size',(replace(good[0],declared_size_bytes=-1),)+good[1:]),('bool-size',(replace(good[0],declared_size_bytes=True),)+good[1:]),('mutable-bytes',(replace(good[0],raw_bytes=bytearray(good[0].raw_bytes)),)+good[1:]),('bytes-over-cap',(replace(good[0],declared_size_bytes=1),)+good[1:]),('aggregate-overflow',tuple(replace(c,declared_size_bytes=67108864)for c in good))]:check('malformed untrusted recovery capture rejected '+name,fails(m.compare,e,cs))
row=copy.deepcopy(base_row);row['observed_fields'].update({'target-control-released':False,'target-evidence-closed':False,'original-restoration-state':'partial','original-full-invariants-verified':False,'pending-target-obligations':['unknown-package-outcome','unknown-package-outcome'],'pending-owned-obligations':['keep-original-backups','keep-raw-artifacts']})
for f in row['expectations']['vectors'][1]['fields']:f['value']=copy.deepcopy(row['observed_fields'][f['field_id']])
result=compare_row(row)
check('partial held state preserves duplicate ordered obligations and raw artifacts',result.agreement_state=='pending'and result.pending_target_obligations==('unknown-package-outcome','unknown-package-outcome')and result.pending_owned_obligations==('keep-original-backups','keep-raw-artifacts')and len(result.captures)==5 and result.original_forward_status==7 and safe(result))
for deadline in [0,140,9223372036854775807]:
 row=copy.deepcopy(base_row);row['observed_fields']['recovery-deadline-ns']=deadline
 next(f for f in row['expectations']['vectors'][1]['fields']if f['field_id']=='recovery-deadline-ns')['value']=deadline
 result=compare_row(row)
 check('bare finite deadline never proves trusted validity '+str(deadline),result.agreement_state=='match'and 'trusted-clock-deadline-suspend-rollback-and-live-recovery-fence'in result.pending_native_recovery_requirements and safe(result))
for vid,ss in [m.FIELD_SPECS[0],m.FIELD_SPECS[2]]:
 d=copy.deepcopy(base_row['expectations'])
 for f,(_,kind)in zip(next(v['fields']for v in d['vectors']if v['vector_id']==vid),ss):f['value']={'status':7,'bool':False,'labels':['private-uninterpreted'],'statuses':[7],'label':'private-uninterpreted','digest':'e'*64}.get(kind)
 result=m.compare(m.decode(wire(d)),good)
 check('other vector cannot rewrite recovery result '+vid,result==baseline_result)
for obj in [e,e.identity,good[0],m.decode_packet(good[0].raw_bytes),baseline_result,baseline_result.fields[0]]:
 key=next(iter(obj.__dataclass_fields__))
 try:setattr(obj,key,None);frozen=False
 except FrozenInstanceError:frozen=True
 check('ordinary mutation denied '+type(obj).__name__,frozen)
# Real352 private-file ingestion feeds five explicit projections;353 failure data
# stays separate and immutable, never used to generate354 expected restoration.
reader=SimpleNamespace(**runpy.run_path(str(root/retained['observation_module_binding']['path'])))
with tempfile.TemporaryDirectory(prefix='step354-private352-integration-')as directory:
 folder=Path(directory);descriptors=[];locations=[]
 for c in good:
  file=folder/c.logical_id;file.write_bytes(c.raw_bytes);locations.append(reader.SourceLocation(c.logical_id,'file',str(file)))
  descriptors.append(dict(logical_id=c.logical_id,evidence_group=c.evidence_group,sha256=c.declared_sha256,size_bytes=c.declared_size_bytes,media_type='application/json',producer_role='unattributed',capture_stage='unspecified'))
 envelope=dict(schema_version=1,origin='private-fixture',case_id=e.case_id,identity=base_row['expectations']['identity'],artifacts=descriptors,groups=[dict(group_id=g,status='present-unverified'if any(c.evidence_group==g for c in good)else'missing',artifact_ids=[c.logical_id for c in good if c.evidence_group==g])for g in reader.GROUP_IDS])
 def project(index):return tuple(m.CapturedPacket(o.descriptor.logical_id,o.descriptor.evidence_group,next(g.declared_state for g in index.groups if g.group_id==o.descriptor.evidence_group),o.state,index.envelope.case_id,m.Identity(**{k:getattr(index.envelope.identity,k)for k in m.Identity.__dataclass_fields__}),o.descriptor.size_bytes,o.descriptor.sha256,o.raw_complete,o.raw_sha256,o.raw_bytes)for o in index.artifacts)
 index=reader.ingest(wire(envelope),tuple(locations));result=m.compare(e,project(index))
 check('five real352 private captures integrate with354',result==baseline_result and safe(result)and result.original_forward_outcome=='failed')
 check('integration preserves all private captured file bytes',all((folder/c.logical_id).read_bytes()==c.raw_bytes for c in good))
 envelope['artifacts'][3]['sha256']='f'*64;index=reader.ingest(wire(envelope),tuple(locations));result=m.compare(e,project(index))
 check('real352 original restoration raw hash conflict survives354',index.artifacts[3].state=='conflicting'and result.agreement_state=='mismatch'and 'capture-conflict'in codes(result)and 'descriptor-bytes-conflict'in codes(result))
 envelope['artifacts'][3]['sha256']=good[3].declared_sha256;ls=list(locations);ls[4]=reader.SourceLocation(good[4].logical_id,'unknown',None);index=reader.ingest(wire(envelope),tuple(ls));result=m.compare(e,project(index))
 check('real352 missing closure remains unknown retained obligations',result.agreement_state=='pending'and result.pending_target_obligations is None and result.pending_owned_obligations is None and safe(result))
selector=SimpleNamespace(**runpy.run_path(str(root/retained['selector_comparator_module_binding']['path'])))
selector_cases=json.loads(history[retained['accepted353_bindings']['private-comparison-cases']['path']])
srow=next(row for row in selector_cases['cases']if row['id']=='failed-update-later-action/Slackware-15.0')
scaptures=[]
for kind,group,ss in selector.PACKET_SPECS:
 data=dict(schema_version=1,origin='captured-vector-unverified',case_id=srow['expectations']['case_id'],identity=srow['packet_identity'],vector_id=kind,fields=[dict(field_id=f,value=srow['observed_fields'][f])for f,_ in ss]);raw=wire(data)
 scaptures.append(selector.CapturedPacket(kind,group,'present-unverified','captured-unverified',srow['expectations']['case_id'],selector.Identity(**srow['expectations']['identity']),len(raw),sha(raw),True,sha(raw),raw))
prior=selector.compare(selector.decode(wire(srow['expectations'])),tuple(scaptures));recovery=m.compare(e,good)
check('verified restoration cannot change353 failed selector latch',prior.agreement_state=='mismatch'and 'action-after-forward-failure'in {d.code for d in prior.diagnostics}and recovery.original_forward_status==7 and recovery.original_forward_outcome=='failed'and not recovery.forward_failure_cleared and selector.compare(selector.decode(wire(srow['expectations'])),tuple(scaptures))==prior)
tree=ast.parse((root/'tools/reference'/module).read_text());imports={a.name for node in ast.walk(tree)if isinstance(node,ast.Import)for a in node.names}|{node.module for node in ast.walk(tree)if isinstance(node,ast.ImportFrom)}
check('pure recovery comparator imports closed data libraries only',imports=={'dataclasses','json','re','hashlib'})
check('pure recovery comparator has no I O callback native replay or dispatch',not any(token in (root/'tools/reference'/module).read_text()for token in ['open(', 'subprocess','os.', 'importlib', 'eval(', 'exec(', 'pickle', 'derive_expectations','socket','urllib']))
for args in [[],['--compare'],['--restore'],['--release'],['--retry'],['--renew']]:
 p=subprocess.run([sys.executable,'-B',str(root/'tools/reference'/module)]+args,capture_output=True)
 check('import-only recovery comparator denies CLI '+repr(args),p.returncode!=0 and p.stdout==b''and b'Import-only'in p.stderr)
check('native selections host and authority stay unobserved and ungranted',all(contract[k]is None for k in ['actual_expected_vector_artifacts','actual_expectation_author','actual_independent_collector','actual_independent_verifier','actual_live_bindings'])and contract['actual_host_state']=='unobserved-not-claimed-absent'and contract['runtime_authority']is False and contract['native_cases_run']==contract['native_proofs_added']==0)
with tempfile.TemporaryDirectory(prefix='step354-exact-accepted353-')as directory:
 historical=Path(directory)
 for rel,data in history.items():p=historical/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
 result=subprocess.run(['bash',str(historical/'tests/reference'/('test-'+oldbase+'-harness.sh'))],capture_output=True,text=True)
 if result.returncode:raise AssertionError('unchanged353 acceptance failed: '+result.stderr[-3000:])
 check('full unchanged353330 passes on exact1764 snapshot',result.stdout.splitlines().count('Result: PASS (330 passes, 0 failures)')==1)
 check('all330 unchanged predecessor labels match complete user return',[x for x in result.stdout.splitlines()if x.startswith('PASS: ')]==policy['expected_predecessor_labels'])
check('prepared354 preserves348 pause and receipt gate for355',contract['strong_safe_pause']is False and contract['last_confirmed_strong_safe_pause_step']==348 and contract['current_user_acceptance_pending']is True and contract['user_step354_checkpoint_confirmed']is False and contract['next_stage_after_complete354_acceptance']==355)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
