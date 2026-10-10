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

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-publication-and-last-receipt-comparison-review';oldbase='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-recovery-and-obligation-comparison-review';module='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-publication-receipt-comparator.py'
fixture=root/'tests/fixtures/reference/acceptance/phase-1';OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-publication-and-last-receipt-comparison-review.md': '5c5102b7460288a7cc850bb3397799b1cf846082c6235be375c22ca8aa7fcb15', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-publication-and-last-receipt-comparison-review-checkpoint-confirmation.json': '4ac74d9e3dcdc5ab000cd95f53d1e1069d3de629e7dffa9d295f6d1da30b24fd', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-publication-and-last-receipt-comparison-review-policy.json': '9bf8cef41f55669b6c91ba1db97bc9b1e53df356c44c8d0689ecea217e0df4c2', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-publication-and-last-receipt-comparison-review-comparison-contract.json': '928ac2454a47ff139441a7614f0abe0f11144a0d320b61e7337c3c06bf362446', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-publication-and-last-receipt-comparison-review-private-comparison-cases.json': 'c5431ccf15b149333e8fa84116967b937006c19006792b3ad7dc224d2be108eb', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-publication-and-last-receipt-comparison-review-retained-obligations.json': '5406520c44c70756a339a89ff3d7d48444017293e65fd63771b0afc2d11f2bec', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-publication-and-last-receipt-comparison-review-step354-user-acceptance.json': '3e29e544dd961ae9e2cf4479249d31b62abf58d2fee8336fa106de82ec6f5b52', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-publication-receipt-comparator.py': 'e55d5fae7a69414c6e7da8a4364d34ff522a2095807cc42cb5acfe0ad3af3b5d'};passes=0
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
    p=root/rel;check('exact current355 input '+p.name,p.is_file()and not p.is_symlink()and p.resolve()==p.absolute()and sha(p.read_bytes())==digest)
policy=load('policy');contract=load('comparison-contract');retained=load('retained-obligations');private=load('private-comparison-cases');receipt=load('step354-user-acceptance');confirmed=load('checkpoint-confirmation')
history={}
for rel,digest in policy['baseline_sha256_bindings'].items():
    p=root/rel
    if not p.is_file()or p.is_symlink()or p.resolve()!=p.absolute():raise ValueError('unsafe accepted source')
    raw=p.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size']:]
    if sha(raw)!=digest:raise ValueError('accepted354 source drift '+rel)
    history[rel]=raw
check('all1773 accepted354 bytes and exact historical CHANGELOG suffix',len(history)==1773)
raw=receipt['text'].encode();lines=receipt['text'].splitlines()
check('complete41095-byte original354 receipt retained without normalization',len(raw)==41095 and sha(raw)=='969b0b50a0ba3d58ebb08df9736ee79166396d8b12e11e718c48a1ef122179b7' and receipt['original_display_sha256']==sha(raw) and receipt['original_display_size_bytes']==len(raw) and receipt['ordered_output_normalization']=='none')
check('complete402 predecessor labels exactly match original receipt',[x for x in lines if x.startswith('PASS: ')]==policy['expected_predecessor_labels'] and lines.count('Result: PASS (402 passes, 0 failures)')==1)
check('reported2b6255c exact tenfiles25582 commit nine paths and successful push','[main 2b6255c] Phase 1 step 354: compare offline recovery and obligation vectors'in lines and ' 10 files changed, 25582 insertions(+)'in lines and set(x[len(' create mode 100644 '):]for x in lines if x.startswith(' create mode 100644 '))==set(policy['expected_predecessor_paths']) and '   72b1a4e..2b6255c  main -> main'in lines)
check('complete clean matching heads and full354 commit unknown',lines[-3:-1]==['2b6255c (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 354: compare offline recovery and obligation vectors']*2 and confirmed['commit_full']is None and confirmed['evidence_sha256']==sha(raw) and all(confirmed[k]is True for k in ['user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','complete_ordered_return_matches_prepared_and_installed']))
bindings=list(retained['source_bindings'].values())+list(retained['model_modules'].values())+list(retained['original_design_bindings'].values())+sum((list(retained[k].values())for k in ['accepted350_bindings','accepted351_bindings','accepted352_bindings','accepted353_bindings','accepted354_bindings']),[])+[retained['accepted349_plan_binding'],retained['schema_module_binding'],retained['expectation_module_binding'],retained['observation_module_binding'],retained['selector_comparator_module_binding'],retained['recovery_comparator_module_binding']]
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
check('four packets cover all21 publication slots exactly once',len(m.PACKET_SPECS)==4 and sorted(f for _,_,ss in m.PACKET_SPECS for f,_ in ss)==sorted(f for f,_ in m.FIELD_SPECS[2][1]))
check('record and receipt distinct logical packets share original evidence group',m.PACKET_SPECS[0][0]!=m.PACKET_SPECS[1][0]and m.PACKET_SPECS[0][1]==m.PACKET_SPECS[1][1]=='publication-last-receipt')
check('original twelve native groups exact and pending',m.NATIVE_GROUP_IDS==tuple(row['id']for row in oracle['evidence_groups']))
check('eighteen selector seventeen recovery slots shape only',len(m.FIELD_SPECS[0][1])==contract['untouched_selector_field_count']==18 and len(m.FIELD_SPECS[1][1])==contract['untouched_recovery_field_count']==17)
hb=retained['packet_helper_static_copy'];source=history[hb['path']].decode();segment=source[source.index(hb['start']):source.index(hb['end'])]
check('exact accepted353 pure packet helpers statically copied',sha(segment.encode())==hb['copied_segment_sha256']and len(segment.encode())==hb['copied_segment_size_bytes']and segment in (root/'tools/reference'/module).read_text())
check('nine explicit native publication proof categories pending',len(m.PENDING_NATIVE_PUBLICATION_REQUIREMENTS)==9 and list(m.PENDING_NATIVE_PUBLICATION_REQUIREMENTS)==contract['pending_native_publication_requirements'])
def wire(d):return(json.dumps(d,sort_keys=True,separators=(',',':'),ensure_ascii=True)+'\n').encode('ascii')
def packet(row,kind):
 ss=next(ss for v,_,ss in m.PACKET_SPECS if v==kind)
 return dict(schema_version=1,origin='captured-vector-unverified',case_id=row['expectations']['case_id'],identity=row['packet_identity'],vector_id=kind,fields=[dict(field_id=f,value=copy.deepcopy(row['observed_fields'][f]))for f,_ in ss])
def captures(row):
 result=[]
 for kind,group,_ in m.PACKET_SPECS:
  raw=wire(packet(row,kind));result.append(m.CapturedPacket(kind,group,'present-unverified',row['capture_state'],row['expectations']['case_id'],m.Identity(**row['expectations']['identity']),len(raw),sha(raw),True,sha(raw),raw))
 return tuple(result)
def compare_row(row):return m.compare(m.decode(wire(row['expectations'])),captures(row))
def codes(result):return {d.code for d in result.diagnostics}
def safe(result):return result.comparison_performed and result.captured_artifact_retention_required and not any([result.forward_failure_cleared,result.recovery_outcome_rewritten,result.publication_writes_allowed,result.republish_or_replay_allowed,result.new_target_grant_allowed,result.delete_retained_artifacts_allowed,result.pair_atomicity_proven,result.self_containing_receipt_authority,result.independence_verified,result.native_oracle_selected,result.native_conformance,result.runtime_authority])and result.native_cases_run==result.native_proofs_added==0 and result.pending_native_groups==m.NATIVE_GROUP_IDS and result.pending_native_publication_requirements==m.PENDING_NATIVE_PUBLICATION_REQUIREMENTS
check('private controls no native record receipt or case published',private['native_cases_run']==private['native_proofs_added']==0 and private['runtime_authority']is False)
for row in private['cases']:
 result=compare_row(row)
 check('independent literal publication diagnostics '+row['id'],result.agreement_state==row['expected_agreement']and set(row['required_diagnostic_codes'])<=codes(result))
 check('data result retains original publication states obligations no authority '+row['id'],safe(result)and len(result.fields)==21 and result.record_state==row['observed_fields']['record-state']and result.receipt_state==row['observed_fields']['receipt-state']and result.handoff_acknowledged==row['observed_fields']['handoff-acknowledged']and result.pending_publication_obligations==(None if row['observed_fields']['pending-publication-obligations']is None else tuple(row['observed_fields']['pending-publication-obligations'])))
base_row=copy.deepcopy(private['cases'][0]);e=m.decode(wire(base_row['expectations']));good=captures(base_row);baseline_result=m.compare(e,good)
check('all21 literal agreement never issues native publication or authority',baseline_result.agreement_state=='match'and all(f.state=='match'for f in baseline_result.fields)and safe(baseline_result))
check('raw captures and digest declarations retained verbatim',baseline_result.captures is good and all(c.raw_bytes==good[i].raw_bytes for i,c in enumerate(baseline_result.captures)))
for capture in good:
 p=m.decode_packet(capture.raw_bytes)
 check('canonical full publication packet roundtrip '+p.vector_id,m.encode_packet(p)==capture.raw_bytes)
 for field in p.fields:
  d=json.loads(capture.raw_bytes);d['fields']=[f for f in d['fields']if f['field_id']!=field.field_id]
  check('required publication observation field missing rejected '+field.field_id,fails(m.decode_packet,wire(d)))
for field_id,kind in m.FIELD_SPECS[2][1]:
 row=copy.deepcopy(base_row);row['observed_fields'][field_id]=None;result=compare_row(row)
 check('unknown observed publication remains pending '+field_id,result.agreement_state=='pending'and next(f for f in result.fields if f.field_id==field_id).state=='pending'and safe(result))
 row=copy.deepcopy(base_row)
 for f in row['expectations']['vectors'][2]['fields']:
  if f['field_id']==field_id:f['value']=None
 result=compare_row(row)
 check('unknown expected publication never wildcard '+field_id,result.agreement_state=='pending'and next(f for f in result.fields if f.field_id==field_id).state=='pending')
 row['observed_fields'][field_id]=None;result=compare_row(row)
 check('two unknown publication values never equality success '+field_id,next(f for f in result.fields if f.field_id==field_id).state=='pending'and safe(result))
for key in m.Identity.__dataclass_fields__:
 if key=='platform':continue
 row=copy.deepcopy(base_row);row['expectations']['identity'][key]=None;row['packet_identity'][key]=None;result=compare_row(row)
 check('nullable original publication identity stays pending '+key,result.agreement_state=='pending'and 'identity-pending'in codes(result))
 row=copy.deepcopy(base_row);row['packet_identity'][key]='f'*64 if key=='subject_source_sha256'else'foreign-'+key;result=compare_row(row)
 check('foreign original publication identity contradicts '+key,result.agreement_state=='mismatch'and 'identity-mismatch'in codes(result))
for key in ['platform','case_id']:
 cs=list(good)
 cs[0]=replace(cs[0],identity=replace(cs[0].identity,platform='Slackware-current'))if key=='platform'else replace(cs[0],case_id='unknown-publication');result=m.compare(e,tuple(cs))
 check('foreign capture publication case or platform rejected '+key,result.agreement_state=='mismatch'and ('identity-mismatch'if key=='platform'else'case-mismatch')in codes(result))
for state in ['missing','unknown']:
 cs=tuple(replace(c,declared_state=state,observation_state=state,raw_bytes=None,raw_complete=False,raw_sha256=None)for c in good);result=m.compare(e,cs)
 check('all unavailable publication captures stay pending '+state,result.agreement_state=='pending'and result.record_state is None and result.receipt_state is None and result.handoff_acknowledged is None and result.pending_publication_obligations is None and safe(result))
cs=tuple(replace(c,declared_state='unknown')for c in good);result=m.compare(e,cs)
check('matching raw bytes cannot clear unknown declared groups',result.agreement_state=='pending'and all(f.state=='match'for f in result.fields)and safe(result))
row=copy.deepcopy(base_row);row['observed_fields']['target-effects-after-release']=['forbidden-write'];cs=list(captures(row));cs[2]=replace(cs[2],observation_state='unknown',raw_bytes=None,raw_complete=False,raw_sha256=None);result=m.compare(e,tuple(cs))
check('known target effect mismatch survives unknown origin handoff peer',result.agreement_state=='mismatch'and 'target-effects-after-release-forbidden'in codes(result)and any(f.state=='pending'for f in result.fields))
cs=list(good);cs[1]=replace(cs[1],raw_complete=False,raw_sha256=None,raw_bytes=cs[1].raw_bytes[:30],observation_state='conflicting');result=m.compare(e,tuple(cs))
check('partial last receipt raw capture retained never parsed complete',result.agreement_state=='mismatch'and 'capture-conflict'in codes(result)and 'incomplete-raw-bytes'in codes(result)and result.receipt_state is None and result.captures[1].raw_bytes==good[1].raw_bytes[:30]and safe(result))
for name,changes,code in [('descriptor-hash',dict(declared_sha256='f'*64),'descriptor-bytes-conflict'),('raw-hash',dict(raw_sha256='f'*64),'raw-hash-declaration-conflict'),('missing-complete-hash',dict(raw_sha256=None),'raw-hash-declaration-conflict'),('declared-size',dict(declared_size_bytes=good[0].declared_size_bytes+1),'descriptor-bytes-conflict')]:
 cs=list(good);cs[0]=replace(cs[0],**changes);result=m.compare(e,tuple(cs))
 check('complete publication packet bytes recomputed despite '+name,result.agreement_state=='mismatch'and code in codes(result)and all(f.state=='match'for f in result.fields))
for name,raw in [('empty',b''),('script',b'#!/bin/sh\necho publish\n'),('archive',b'PK\x03\x04raw'),('selfreport',b'{"pair_atomicity_proven":true,"self_containing_receipt_authority":true}\n')]:
 cs=list(good);cs[1]=replace(cs[1],raw_bytes=raw,declared_size_bytes=len(raw),declared_sha256=sha(raw),raw_sha256=sha(raw));result=m.compare(e,tuple(cs))
 check('opaque payload never final receipt or pair proof '+name,result.agreement_state=='mismatch'and 'malformed-observation-packet'in codes(result)and safe(result))
cs=list(good);raw=good[1].raw_bytes;cs[0]=replace(cs[0],raw_bytes=raw,declared_size_bytes=len(raw),declared_sha256=sha(raw),raw_sha256=sha(raw));result=m.compare(e,tuple(cs))
check('record receipt packet roles cannot swap despite shared group',result.agreement_state=='mismatch'and 'packet-group-mismatch'in codes(result))
for name,raw in [('empty',b''),('bytearray',bytearray(good[0].raw_bytes)),('wire-bound',b' '*262145),('nonascii',b'\xff'),('depth-bound',b'['*13+b'0'+b']'*13),('duplicate-key',good[0].raw_bytes.replace(b'"schema_version":1',b'"schema_version":1,"schema_version":1')),('pretty',json.dumps(json.loads(good[0].raw_bytes),indent=2).encode()),('no-lf',good[0].raw_bytes[:-1]),('nan',good[0].raw_bytes.replace(b'"schema_version":1',b'"schema_version":NaN'))]:check('strict publication parser rejects '+name,fails(m.decode_packet,raw))
for name,change in [('extra-authority',lambda d:d.update(publication_writes_allowed=True)),('origin',lambda d:d.update(origin='trusted-native')),('version',lambda d:d.update(schema_version=True)),('extra-identity',lambda d:d['identity'].update(pair_atomicity=True)),('case',lambda d:d.update(case_id='invented-case')),('platform',lambda d:d['identity'].update(platform='other')),('swapped-fields',lambda d:d['fields'].reverse()),('duplicate-field',lambda d:d['fields'].__setitem__(1,d['fields'][0]))]:
 d=json.loads(good[0].raw_bytes);change(d);check('closed publication packet rejects '+name,fails(m.decode_packet,wire(d)))
for field_id,kind in m.FIELD_SPECS[2][1]:
 pk=next(v for v,_,ss in m.PACKET_SPECS if any(f==field_id for f,_ in ss));d=packet(base_row,pk);f=next(f for f in d['fields']if f['field_id']==field_id)
 f['value']={'digest':'A'*64,'bool':1,'labels':[None],'label':['durable']}[kind]
 check('exact publication observation type rejects '+field_id,fails(m.decode_packet,wire(d)))
for field_id,invalids,valids in [('record-state',['x'*129,' leading','bad\nlabel'],['x'*128]),('receipt-sha256',['f'*63,'F'*64,False],['0'*64]),('pending-publication-obligations',[[None],['x']*129],[[],['x']*128]),('control-raw-consequence-ids',[['bad\nlabel'],['x']*129],[[],['x']*128])]:
 pk=next(v for v,_,ss in m.PACKET_SPECS if any(f==field_id for f,_ in ss))
 for n,value in enumerate(invalids):
  d=packet(base_row,pk);next(f for f in d['fields']if f['field_id']==field_id)['value']=value
  check('observation publication bound rejects '+field_id+'/'+str(n),fails(m.decode_packet,wire(d)))
 for n,value in enumerate(valids):
  d=packet(base_row,pk);next(f for f in d['fields']if f['field_id']==field_id)['value']=value
  check('shape endpoint is data only '+field_id+'/'+str(n),m.encode_packet(m.decode_packet(wire(d)))==wire(d))
for name,cs in [('list',list(good)),('short',good[:3]),('lookalike',(dict(good[0].__dict__),)+good[1:]),('wrong-group',(replace(good[0],evidence_group='writer-child-lifetimes'),)+good[1:]),('duplicate-id',(replace(good[0],logical_id=good[1].logical_id),)+good[1:]),('unsafe-id',(replace(good[0],logical_id='../raw'),)+good[1:]),('complete-no-bytes',(replace(good[0],raw_bytes=None),)+good[1:]),('partial-fullhash',(replace(good[0],raw_complete=False),)+good[1:]),('unknown-with-bytes',(replace(good[0],observation_state='unknown'),)+good[1:]),('oversized',(replace(good[0],declared_size_bytes=67108865),)+good[1:]),('negative-size',(replace(good[0],declared_size_bytes=-1),)+good[1:]),('bool-size',(replace(good[0],declared_size_bytes=True),)+good[1:]),('mutable-bytes',(replace(good[0],raw_bytes=bytearray(good[0].raw_bytes)),)+good[1:]),('bytes-over-cap',(replace(good[0],declared_size_bytes=1),)+good[1:]),('aggregate-overflow',tuple(replace(c,declared_size_bytes=67108864)for c in good))]:check('malformed untrusted publication capture rejected '+name,fails(m.compare,e,cs))
swapped=m.compare(e,(good[1],good[0])+good[2:])
check('swapped same-group roles return retained mismatch diagnostics',swapped.agreement_state=='mismatch'and 'packet-group-mismatch'in codes(swapped)and swapped.captures==(good[1],good[0])+good[2:]and safe(swapped))
row=copy.deepcopy(base_row);row['observed_fields'].update({'receipt-state':'unknown','handoff-acknowledged':False,'pending-publication-obligations':['keep-raw-artifacts','unknown-controller-outcome','unknown-controller-outcome']})
for f in row['expectations']['vectors'][2]['fields']:f['value']=copy.deepcopy(row['observed_fields'][f['field_id']])
result=compare_row(row)
check('unknown last receipt retains exact duplicate obligations no replay',result.agreement_state=='pending'and result.pending_publication_obligations==('keep-raw-artifacts','unknown-controller-outcome','unknown-controller-outcome')and len(result.captures)==4 and safe(result))
row=copy.deepcopy(base_row);row['observed_fields']['receipt-sha256']=row['observed_fields']['record-sha256'];next(f for f in row['expectations']['vectors'][2]['fields']if f['field_id']=='receipt-sha256')['value']=row['observed_fields']['receipt-sha256'];result=compare_row(row)
check('same digest cannot prove object separation or self receipt authority',result.agreement_state=='match'and not result.pair_atomicity_proven and not result.self_containing_receipt_authority and 'distinct-last-receipt-object-and-native-file-metadata-directory-storage'in result.pending_native_publication_requirements and safe(result))
for vid,ss in m.FIELD_SPECS[:2]:
 d=copy.deepcopy(base_row['expectations'])
 for f,(_,kind)in zip(next(v['fields']for v in d['vectors']if v['vector_id']==vid),ss):f['value']={'status':7,'bool':False,'labels':['private-uninterpreted'],'statuses':[7],'label':'private-uninterpreted','digest':'e'*64,'time-ns':1,'budget':1}.get(kind)
 result=m.compare(m.decode(wire(d)),good)
 check('selector recovery fields cannot be rewritten by publication '+vid,result==baseline_result)
for obj in [e,e.identity,good[0],m.decode_packet(good[0].raw_bytes),baseline_result,baseline_result.fields[0]]:
 key=next(iter(obj.__dataclass_fields__))
 try:setattr(obj,key,None);frozen=False
 except FrozenInstanceError:frozen=True
 check('ordinary mutation denied '+type(obj).__name__,frozen)
reader=SimpleNamespace(**runpy.run_path(str(root/retained['observation_module_binding']['path'])))
with tempfile.TemporaryDirectory(prefix='step355-private352-integration-')as directory:
 folder=Path(directory);descriptors=[];locations=[]
 for c in good:
  file=folder/c.logical_id;file.write_bytes(c.raw_bytes);locations.append(reader.SourceLocation(c.logical_id,'file',str(file)))
  descriptors.append(dict(logical_id=c.logical_id,evidence_group=c.evidence_group,sha256=c.declared_sha256,size_bytes=c.declared_size_bytes,media_type='application/json',producer_role='unattributed',capture_stage='unspecified'))
 envelope=dict(schema_version=1,origin='private-fixture',case_id=e.case_id,identity=base_row['expectations']['identity'],artifacts=descriptors,groups=[dict(group_id=g,status='present-unverified'if any(c.evidence_group==g for c in good)else'missing',artifact_ids=[c.logical_id for c in good if c.evidence_group==g])for g in reader.GROUP_IDS])
 def project(index):return tuple(m.CapturedPacket(o.descriptor.logical_id,o.descriptor.evidence_group,next(g.declared_state for g in index.groups if g.group_id==o.descriptor.evidence_group),o.state,index.envelope.case_id,m.Identity(**{k:getattr(index.envelope.identity,k)for k in m.Identity.__dataclass_fields__}),o.descriptor.size_bytes,o.descriptor.sha256,o.raw_complete,o.raw_sha256,o.raw_bytes)for o in index.artifacts)
 index=reader.ingest(wire(envelope),tuple(locations));result=m.compare(e,project(index))
 check('four real352 private captures integrate with355 shared group',result==baseline_result and safe(result)and next(g.artifact_ids for g in index.groups if g.group_id=='publication-last-receipt')==('publication-record','receipt-last'))
 check('integration preserves four raw private files without publication',all((folder/c.logical_id).read_bytes()==c.raw_bytes for c in good))
 envelope['artifacts'][1]['sha256']='f'*64;index=reader.ingest(wire(envelope),tuple(locations));result=m.compare(e,project(index))
 check('real352 receipt packet hash conflict preserved by355',index.artifacts[1].state=='conflicting'and result.agreement_state=='mismatch'and 'capture-conflict'in codes(result)and 'descriptor-bytes-conflict'in codes(result))
 envelope['artifacts'][1]['sha256']=good[1].declared_sha256;ls=list(locations);ls[1]=reader.SourceLocation(good[1].logical_id,'unknown',None);index=reader.ingest(wire(envelope),tuple(ls));result=m.compare(e,project(index))
 check('real352 partial shared group remains pending last receipt',next(g.state for g in index.groups if g.group_id=='publication-last-receipt')=='unknown'and result.agreement_state=='pending'and result.receipt_state is None and safe(result))
# Independent frozen predecessors are invoked only in this repository harness,
# never imported/called by the pure355 comparator or used to derive its literals.
predecessors={binding:SimpleNamespace(**runpy.run_path(str(root/retained[binding]['path'])))for binding in ['selector_comparator_module_binding','recovery_comparator_module_binding']}
def predecessor_result(binding,fixture_binding,case_id,vector_index):
 predecessor=predecessors[binding];data=json.loads(history[retained[fixture_binding]['private-comparison-cases']['path']]);row=next(row for row in data['cases']if row['id']==case_id);cs=[]
 for kind,group,ss in predecessor.PACKET_SPECS:
  d=dict(schema_version=1,origin='captured-vector-unverified',case_id=row['expectations']['case_id'],identity=row['packet_identity'],vector_id=kind,fields=[dict(field_id=f,value=row['observed_fields'][f])for f,_ in ss]);raw=wire(d)
  cs.append(predecessor.CapturedPacket(kind,group,'present-unverified',row['capture_state'],row['expectations']['case_id'],predecessor.Identity(**row['expectations']['identity']),len(raw),sha(raw),True,sha(raw),raw))
 return predecessor.compare(predecessor.decode(wire(row['expectations'])),tuple(cs))
selector_before=predecessor_result('selector_comparator_module_binding','accepted353_bindings','failed-update-later-action/Slackware-15.0',0)
recovery_before=predecessor_result('recovery_comparator_module_binding','accepted354_bindings','verified-restoration-retains-original-seven/Slackware-15.0',1)
published=m.compare(e,good)
check('publication data cannot clear353 sticky forward failure',selector_before.agreement_state=='mismatch'and 'action-after-forward-failure'in {d.code for d in selector_before.diagnostics}and not published.forward_failure_cleared and predecessor_result('selector_comparator_module_binding','accepted353_bindings','failed-update-later-action/Slackware-15.0',0)==selector_before)
check('publication data cannot rewrite354 original seven or recovery obligations',recovery_before.original_forward_status==7 and recovery_before.original_forward_outcome=='failed'and not published.recovery_outcome_rewritten and predecessor_result('recovery_comparator_module_binding','accepted354_bindings','verified-restoration-retains-original-seven/Slackware-15.0',1)==recovery_before)
tree=ast.parse((root/'tools/reference'/module).read_text());imports={a.name for node in ast.walk(tree)if isinstance(node,ast.Import)for a in node.names}|{node.module for node in ast.walk(tree)if isinstance(node,ast.ImportFrom)}
check('pure publication comparator imports closed data libraries only',imports=={'dataclasses','json','re','hashlib'})
check('pure publication comparator has no I O callback issuer replay or dispatch',not any(token in (root/'tools/reference'/module).read_text()for token in ['open(', 'subprocess','os.', 'importlib', 'eval(', 'exec(', 'pickle', 'derive_expectations','socket','urllib']))
for args in [[],['--compare'],['--publish'],['--receipt'],['--republish'],['--delete'],['--refresh']]:
 p=subprocess.run([sys.executable,'-B',str(root/'tools/reference'/module)]+args,capture_output=True)
 check('import-only publication comparator denies CLI '+repr(args),p.returncode!=0 and p.stdout==b''and b'Import-only'in p.stderr)
check('actual native backend paths origin and selections remain null',all(contract[k]is None for k in ['actual_expected_vector_artifacts','actual_expectation_author','actual_independent_collector','actual_independent_verifier','actual_durability_backend','actual_publication_paths','actual_receipt_origin','actual_live_bindings'])and contract['actual_host_state']=='unobserved-not-claimed-absent'and contract['runtime_authority']is False and contract['native_cases_run']==contract['native_proofs_added']==0)
with tempfile.TemporaryDirectory(prefix='step355-exact-accepted354-')as directory:
 historical=Path(directory)
 for rel,data in history.items():p=historical/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
 result=subprocess.run(['bash',str(historical/'tests/reference'/('test-'+oldbase+'-harness.sh'))],capture_output=True,text=True)
 if result.returncode:raise AssertionError('unchanged354 acceptance failed: '+result.stderr[-3000:])
 check('full unchanged354402 passes on exact1773 snapshot',result.stdout.splitlines().count('Result: PASS (402 passes, 0 failures)')==1)
 check('all402 unchanged predecessor labels match complete user return',[x for x in result.stdout.splitlines()if x.startswith('PASS: ')]==policy['expected_predecessor_labels'])
check('prepared355 preserves348 pause and receipt gate for356',contract['strong_safe_pause']is False and contract['last_confirmed_strong_safe_pause_step']==348 and contract['current_user_acceptance_pending']is True and contract['user_step355_checkpoint_confirmed']is False and contract['next_stage_after_complete355_acceptance']==356)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
