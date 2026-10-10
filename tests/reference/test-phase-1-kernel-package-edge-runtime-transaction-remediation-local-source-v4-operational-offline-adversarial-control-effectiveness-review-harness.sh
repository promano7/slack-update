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

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-adversarial-control-effectiveness-review';oldbase='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-publication-and-last-receipt-comparison-review';module='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-private-control-assessment.py'
fixture=root/'tests/fixtures/reference/acceptance/phase-1';OWN_HASHES={'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-adversarial-control-effectiveness-review.md': 'ae5f3c4f261a6bf9c212a87badaba2cdef7f3a1236ab7b5edea9a6948b68cba3', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-adversarial-control-effectiveness-review-checkpoint-confirmation.json': '511259c61917b287d5d6a6490d9cc49b06f82b790432f8c6dc07de6c65f7935d', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-adversarial-control-effectiveness-review-policy.json': '0586f8642eae874956d6fddd7066040daa30ebb35d395d857c6a20799d81659e', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-adversarial-control-effectiveness-review-comparison-contract.json': '5be109f4c2ef56c2d6c655cc8550f248e7e60d694a5231e7448eedfd13fba7c2', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-adversarial-control-effectiveness-review-private-comparison-cases.json': '1021c5c4e7a17c0cbac7b91f06c298e0518a369d8d7c71330a3ef16b0eb3340e', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-adversarial-control-effectiveness-review-retained-obligations.json': 'e176ce975f02a7c4e85e6ab7a6ac822f9bb72c029755a18452de3ac8a8033afd', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-adversarial-control-effectiveness-review-step355-user-acceptance.json': '993381111c648db3a3b493a858b3fdd6da4c0d8b2f6da0a7d057ad693f609313', 'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-private-control-assessment.py': '27ac22255c4e58e6cec6d17a703b2acec34c9fd198557b6860a270e1dd5ecd2f'};passes=0
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
    p=root/rel;check('exact current356 input '+p.name,p.is_file()and not p.is_symlink()and p.resolve()==p.absolute()and sha(p.read_bytes())==digest)
policy=load('policy');contract=load('comparison-contract');retained=load('retained-obligations');private=load('private-comparison-cases');receipt=load('step355-user-acceptance');confirmed=load('checkpoint-confirmation')
history={}
for rel,digest in policy['baseline_sha256_bindings'].items():
    p=root/rel
    if not p.is_file()or p.is_symlink()or p.resolve()!=p.absolute():raise ValueError('unsafe accepted source')
    raw=p.read_bytes()
    if rel=='CHANGELOG.md':raw=raw[-policy['accepted_changelog_size']:]
    if sha(raw)!=digest:raise ValueError('accepted355 source drift '+rel)
    history[rel]=raw
check('all1782 accepted355 bytes and exact historical CHANGELOG suffix',len(history)==1782)
raw=receipt['text'].encode();lines=receipt['text'].splitlines()
check('complete48990-byte original355 receipt retained without normalization',len(raw)==48990 and sha(raw)=='f5010743a92ca475fee7968ed11a48115679a33ebf35c777347cdce34d9ac621' and receipt['original_display_sha256']==sha(raw) and receipt['original_display_size_bytes']==len(raw) and receipt['ordered_output_normalization']=='none')
check('complete463 predecessor labels exactly match original receipt',[x for x in lines if x.startswith('PASS: ')]==policy['expected_predecessor_labels'] and lines.count('Result: PASS (463 passes, 0 failures)')==1)
check('reported8307f71 exact tenfiles31948 commit nine paths and successful push','[main 8307f71] Phase 1 step 355: compare offline publication and last receipt vectors'in lines and ' 10 files changed, 31948 insertions(+)'in lines and set(x[len(' create mode 100644 '):]for x in lines if x.startswith(' create mode 100644 '))==set(policy['expected_predecessor_paths']) and '   2b6255c..8307f71  main -> main'in lines)
check('complete clean matching heads and full355 commit unknown',lines[-3:-1]==['8307f71 (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 355: compare offline publication and last receipt vectors']*2 and confirmed['commit_full']is None and confirmed['evidence_sha256']==sha(raw) and all(confirmed[k]is True for k in ['user_application_completed','user_harness_completed','user_commit_and_push_completed','user_head_matches_origin','user_worktree_clean','complete_ordered_return_matches_prepared_and_installed']))
bindings=list(retained['source_bindings'].values())+list(retained['model_modules'].values())+list(retained['original_design_bindings'].values())+sum((list(retained[k].values())for k in ['accepted350_bindings','accepted351_bindings','accepted352_bindings','accepted353_bindings','accepted354_bindings','accepted355_bindings']),[])+[retained['accepted349_plan_binding'],retained['schema_module_binding'],retained['expectation_module_binding'],retained['observation_module_binding'],retained['selector_comparator_module_binding'],retained['recovery_comparator_module_binding'],retained['publication_comparator_module_binding']]
for binding in bindings:check('source-bound unchanged inherited '+Path(binding['path']).name,sha(history[binding['path']])==binding['sha256'])
oracle=json.loads(history[retained['source_bindings']['oracle335']['path']])
check('full twelve original native evidence group rows retained',retained['original_evidence_group_rows']==oracle['evidence_groups'])
check('all eight full original320-327 contracts retained',set(retained['original_design_bindings'])==set(str(i)for i in range(320,328)))
check('all52 source-bound native cases still unrun',len(retained['original_case_row_sha256'])==len(oracle['cases'])==52 and all(row['status']=='required-not-run'and row['sha256']==sha(json.dumps(original,sort_keys=True,separators=(',',':')).encode())for row,original in zip(retained['original_case_row_sha256'],oracle['cases'])))
check('all46 proofs52 cases16 gaps retained',[retained['counts'][k]for k in ['native_proofs','native_cases','native_gaps']]==[46,52,16])
check('seven frozen modules nine original pause conditions retained',len(retained['model_modules'])==7 and len(retained['original_pause_conditions'])==9)
m=SimpleNamespace(**runpy.run_path(str(root/'tools/reference'/module)))
reader=SimpleNamespace(**runpy.run_path(str(root/retained['observation_module_binding']['path'])))
engines={name:SimpleNamespace(**runpy.run_path(str(root/info['module_binding']['path'])))for name,info in private['engines'].items()}
def wire(d):return(json.dumps(d,sort_keys=True,separators=(',',':'),ensure_ascii=True)+'\n').encode('ascii')
def codes(result):return tuple(d.code for d in result.diagnostics)
def authority_safe(result):
 return not any(getattr(result,key,False)for key in ['native_injection_effectiveness_proven','independence_verified','native_oracle_selected','native_conformance','runtime_authority','forward_failure_cleared','recovery_outcome_rewritten','publication_writes_allowed','republish_or_replay_allowed','new_target_grant_allowed','delete_retained_artifacts_allowed','pair_atomicity_proven','self_containing_receipt_authority','recovery_writes_allowed','target_release_allowed'])and result.native_cases_run==result.native_proofs_added==0
def packets(engine,row):
 return tuple(wire(dict(schema_version=1,origin='captured-vector-unverified',case_id=row['expectations']['case_id'],identity=row['packet_identity'],vector_id=kind,fields=[dict(field_id=f,value=copy.deepcopy(row['observed_fields'][f]))for f,_ in ss]))for kind,group,ss in engine.PACKET_SPECS)
def envelope_for(engine,row,raws):
 ds=[dict(logical_id=kind,evidence_group=group,sha256=sha(raw),size_bytes=len(raw),media_type='application/json',producer_role='unattributed',capture_stage='unspecified')for(kind,group,_),raw in zip(engine.PACKET_SPECS,raws)]
 return dict(schema_version=1,origin='private-fixture',case_id=row['expectations']['case_id'],identity=row['expectations']['identity'],artifacts=ds,groups=[dict(group_id=g,status='present-unverified'if any(d['evidence_group']==g for d in ds)else'missing',artifact_ids=[d['logical_id']for d in ds if d['evidence_group']==g])for g in reader.GROUP_IDS])
def project(engine,index):
 return tuple(engine.CapturedPacket(o.descriptor.logical_id,o.descriptor.evidence_group,next(g.declared_state for g in index.groups if g.group_id==o.descriptor.evidence_group),o.state,index.envelope.case_id,engine.Identity(**{k:getattr(index.envelope.identity,k)for k in engine.Identity.__dataclass_fields__}),o.descriptor.size_bytes,o.descriptor.sha256,o.raw_complete,o.raw_sha256,o.raw_bytes)for o in index.artifacts)
def captures(engine,row,raws):
 return tuple(engine.CapturedPacket(kind,group,'present-unverified','captured-unverified',row['expectations']['case_id'],engine.Identity(**row['expectations']['identity']),len(raw),sha(raw),True,sha(raw),raw)for(kind,group,_),raw in zip(engine.PACKET_SPECS,raws))
check('three unchanged comparators and66 independent literal control profiles',len(engines)==3 and len(private['cases'])==66)
for name,info in private['engines'].items():
 original=json.loads(history[info['private_fixture_binding']['path']])
 check('accepted independent literal baselines source-bound '+name,all(row in original['cases']for row in info['baseline_profiles'].values()))
for item in private['cases']:
 engine=engines[item['engine']];row=copy.deepcopy(private['engines'][item['engine']]['baseline_profiles'][item['platform']]);expected=engine.decode(wire(row['expectations']));before=packets(engine,row)
 with tempfile.TemporaryDirectory(prefix='step356-private-control-')as directory:
  folder=Path(directory);locations=[]
  for(kind,_,_),raw in zip(engine.PACKET_SPECS,before):
   p=folder/kind;p.write_bytes(raw);locations.append(reader.SourceLocation(kind,'file',str(p)))
  env=envelope_for(engine,row,before);first=reader.ingest(wire(env),tuple(locations));initial=engine.compare(expected,project(engine,first))
  check('private352 baseline match '+item['id']+'/'+item['platform'],initial.agreement_state=='match'and authority_safe(initial)and tuple(o.raw_bytes for o in first.artifacts)==before)
  if item['role']=='negative':row['observed_fields'][item['field_id']]=copy.deepcopy(item['value'])
  after=packets(engine,row)
  for(kind,_,_),raw in zip(engine.PACKET_SPECS,after):(folder/kind).write_bytes(raw)
  observed=reader.ingest(wire(envelope_for(engine,row,after)),tuple(locations));cs=project(engine,observed);result=engine.compare(expected,cs)
  check('actual raw one-field consequence '+item['id']+'/'+item['platform'],sum(a!=b for a,b in zip(before,after))==(item['role']=='negative')and tuple(o.raw_bytes for o in observed.artifacts)==after and all(o.state=='captured-unverified'for o in observed.artifacts))
  check('independent required comparator response '+item['id']+'/'+item['platform'],result.agreement_state==item['expected_state']and set(item['required_diagnostic_codes'])<=set(codes(result))and result.pending_native_groups==engine.NATIVE_GROUP_IDS and authority_safe(result))
  observation=m.ControlObservation(item['id'],item['role'],before,after,initial.agreement_state,result.agreement_state,item['expected_state'],tuple(item['required_diagnostic_codes']),codes(result));assessment=m.assess(observation)
  check('measured private control effective without native promotion '+item['id']+'/'+item['platform'],assessment.private_control_effective and assessment.raw_change_observed==(item['role']=='negative')and assessment.before_sha256==tuple(map(sha,before))and assessment.after_sha256==tuple(map(sha,after))and assessment.raw_artifact_retention_required and authority_safe(assessment))
  check('private input expectations and disk artifacts retained '+item['id']+'/'+item['platform'],engine.encode(expected)==wire(private['engines'][item['engine']]['baseline_profiles'][item['platform']]['expectations'])and all((folder/kind).read_bytes()==raw for(kind,_,_),raw in zip(engine.PACKET_SPECS,after)))
  if item['role']=='negative':
   stale=reader.ingest(wire(env),tuple(locations));stale_result=engine.compare(expected,project(engine,stale))
   check('stale descriptor actual byte conflict retained '+item['id']+'/'+item['platform'],any(o.state=='conflicting'for o in stale.artifacts)and stale_result.agreement_state=='mismatch'and 'capture-conflict'in codes(stale_result)and authority_safe(stale_result))
good=m.ControlObservation('private-negative','negative',(b'original',),(b'mutated',),'match','mismatch','mismatch',('literal-field-mismatch',),('literal-field-mismatch',))
check('literal private assessment baseline works',m.assess(good).private_control_effective)
for label,changes in [('no-op-injection',dict(after_raw=good.before_raw)),('wrong-response',dict(observed_state='match')),('missing-consequence',dict(observed_diagnostic_codes=())),('fault-label-only',dict(required_diagnostic_codes=())),('failed-positive-baseline',dict(baseline_state='mismatch')),('negative-match-claim',dict(observed_state='match',expected_state='match')),('unknown-baseline',dict(baseline_state='pending'))]:
 result=m.assess(replace(good,**changes));check('ineffective private control denied '+label,result.state=='ineffective-private-data-control'and not result.private_control_effective and authority_safe(result))
for before,after in [((None,),(None,)),((b'original',),(None,)),((None,),(b'mutated',))]:
 result=m.assess(replace(good,before_raw=before,after_raw=after));check('unknown raw is pending never equality control '+repr((before,after)),result.state=='pending-raw-control-evidence'and result.raw_change_observed is None and not result.private_control_effective and authority_safe(result))
for label,changes in [('mutable-before',dict(before_raw=[b'original'])),('mutable-bytes',dict(after_raw=(bytearray(b'mutated'),))),('oversize',dict(after_raw=(b'x'*262145,))),('too-many',dict(before_raw=(b'x',)*17,after_raw=(b'y',)*17)),('empty',dict(before_raw=(),after_raw=())),('unpaired',dict(after_raw=(b'x',b'y'))),('wrong-role',dict(role='native')),('invented-state',dict(observed_state='native-pass')),('bad-id',dict(control_id='../native')),('mutable-codes',dict(observed_diagnostic_codes=['literal-field-mismatch'])),('bad-code',dict(required_diagnostic_codes=('execute --publish',))),('too-many-codes',dict(observed_diagnostic_codes=('literal-field-mismatch',)*129))]:
 check('malformed bounded private control rejected '+label,fails(m.assess,replace(good,**changes)))
check('lookalike control declaration rejected',fails(m.assess,good.__dict__))
class RoleLookalike(str):pass
check('role string subclass cannot substitute exact scalar',fails(m.assess,replace(good,role=RoleLookalike('negative'))))
for role in ['positive','negative']:
 result=m.assess(replace(good,role=role,before_raw=(b'x'*262144,)*16,after_raw=((b'x'if role=='positive'else b'y')*262144,)*16,observed_state='match'if role=='positive'else'mismatch',expected_state='match'if role=='positive'else'mismatch'))
 check('maximum bounded raw endpoints are private data only '+role,result.private_control_effective and authority_safe(result))
result=m.assess(replace(good,required_diagnostic_codes=('literal-field-mismatch',)*2,observed_diagnostic_codes=('literal-field-mismatch',)*2))
check('ordered duplicate diagnostic input not normalized',good.required_diagnostic_codes==('literal-field-mismatch',)and result.private_control_effective)
for name,engine in engines.items():
 row=copy.deepcopy(private['engines'][name]['baseline_profiles']['Slackware-15.0']);e=engine.decode(wire(row['expectations']));raws=packets(engine,row);cs=captures(engine,row,raws)
 for payload_name,raw in [('script',b'#!/bin/sh\necho native-pass\n'),('selfreport',b'{"native_conformance":true,"runtime_authority":true}\n'),('partial',raws[0][:24])]:
  changed=list(cs);changed[0]=replace(changed[0],raw_bytes=raw,declared_size_bytes=len(raw),declared_sha256=sha(raw),raw_sha256=sha(raw));result=engine.compare(e,tuple(changed))
  check('opaque altered data cannot dispatch '+name+'/'+payload_name,result.agreement_state=='mismatch'and 'malformed-observation-packet'in codes(result)and changed[0].raw_bytes==raw and authority_safe(result))
 changed=list(cs);changed[0]=replace(changed[0],identity=replace(changed[0].identity,test_run_id='foreign-run'));result=engine.compare(e,tuple(changed))
 check('cross-run capture conflict retained '+name,result.agreement_state=='mismatch'and 'identity-mismatch'in codes(result)and authority_safe(result))
 unknown=list(cs);unknown[-1]=replace(unknown[-1],raw_bytes=None,raw_sha256=None,raw_complete=False,observation_state='unknown');unknown[0]=replace(unknown[0],declared_sha256='f'*64);result=engine.compare(e,tuple(unknown))
 check('known raw contradiction absorbs unknown peer '+name,result.agreement_state=='mismatch'and 'descriptor-bytes-conflict'in codes(result)and any(f.state=='pending'for f in result.fields)and authority_safe(result))
 partial=list(cs);partial[0]=replace(partial[0],raw_bytes=raws[0][:24],raw_sha256=None,raw_complete=False,observation_state='conflicting');result=engine.compare(e,tuple(partial))
 check('incomplete captured bytes remain unparsed '+name,result.agreement_state=='mismatch'and 'incomplete-raw-bytes'in codes(result)and authority_safe(result))
 before=engine.compare(e,cs);m.assess(good);after=engine.compare(e,cs)
 check('private controls never rewrite predecessor outcome '+name,before==after and authority_safe(after))
 for args in [['--inject'],['--publish'],['--refresh'],['--cleanup']]:
  p=subprocess.run([sys.executable,'-B',str(root/private['engines'][name]['module_binding']['path'])]+args,capture_output=True)
  check('unchanged comparator dispatch rejected '+name+'/'+args[0],p.returncode!=0 and p.stdout==b''and b'Import-only'in p.stderr)
for obj in [good,m.assess(good)]:
 try:setattr(obj,next(iter(obj.__dataclass_fields__)),None);frozen=False
 except FrozenInstanceError:frozen=True
 check('ordinary private control mutation denied '+type(obj).__name__,frozen)
tree=ast.parse((root/'tools/reference'/module).read_text());imports={a.name for node in ast.walk(tree)if isinstance(node,ast.Import)for a in node.names}|{node.module for node in ast.walk(tree)if isinstance(node,ast.ImportFrom)}
check('control assessment imports pure data libraries only',imports=={'dataclasses','hashlib','re'})
check('control assessment no file injector callback network or dispatcher',not any(token in (root/'tools/reference'/module).read_text()for token in ['open(', 'subprocess','os.', 'importlib', 'eval(', 'exec(', 'pickle','socket','urllib']))
for args in [[],['--inject'],['--publish'],['--refresh'],['--cleanup']]:
 p=subprocess.run([sys.executable,'-B',str(root/'tools/reference'/module)]+args,capture_output=True)
 check('import-only control assessment rejects CLI '+repr(args),p.returncode!=0 and p.stdout==b''and b'Import-only'in p.stderr)
check('actual native fault injector and selections remain null',all(contract[k]is None for k in ['actual_expected_vector_artifacts','actual_expectation_author','actual_independent_collector','actual_independent_verifier','actual_native_fault_injector','actual_live_bindings'])and contract['actual_host_state']=='unobserved-not-claimed-absent'and contract['runtime_authority']is False and contract['native_cases_run']==contract['native_proofs_added']==0)
with tempfile.TemporaryDirectory(prefix='step356-exact-accepted355-')as directory:
 historical=Path(directory)
 for rel,data in history.items():p=historical/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
 result=subprocess.run(['bash',str(historical/'tests/reference'/('test-'+oldbase+'-harness.sh'))],capture_output=True,text=True)
 if result.returncode:raise AssertionError('unchanged355 acceptance failed: '+result.stderr[-3000:])
 check('full unchanged355463 passes on exact1782 snapshot',result.stdout.splitlines().count('Result: PASS (463 passes, 0 failures)')==1)
 check('all463 unchanged predecessor labels match complete user return',[x for x in result.stdout.splitlines()if x.startswith('PASS: ')]==policy['expected_predecessor_labels'])
check('prepared356 preserves348 pause and receipt gate for357',contract['strong_safe_pause']is False and contract['last_confirmed_strong_safe_pause_step']==348 and contract['current_user_acceptance_pending']is True and contract['user_step356_checkpoint_confirmed']is False and contract['next_stage_after_complete356_acceptance']==357)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
