#!/bin/bash
set -euo pipefail
export LC_ALL=C
root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 -B - "$root" <<'PYTEST'
from pathlib import Path
import ast
import copy
import dataclasses
import hashlib
import json
import subprocess
import sys
import tempfile
import types

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1/';core_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core.py';module_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer.py';review_path=root/'tools/reference'/(base+'.py')
passes=0
def check(label,value):
 global passes
 if not value:raise SystemExit('FAIL: '+label)
 passes+=1;print('PASS: '+label,flush=True)
def rejects(fn,*args,**kwargs):
 try:fn(*args,**kwargs)
 except (ValueError,TypeError,KeyError,AttributeError,dataclasses.FrozenInstanceError):return True
 return False
def load(suffix):return json.loads((fixture/(base+suffix)).read_bytes())
def run(argv):return subprocess.run([str(x) for x in argv],capture_output=True,text=True)
def module(name,path):
 value=types.ModuleType(name);sys.modules[name]=value
 exec(compile(ast.parse(path.read_text()),str(path),'exec'),value.__dict__);return value
check('exact unchanged340 core source SHA',hashlib.sha256(core_path.read_bytes()).hexdigest()=='94c8cc3dfdb0d813a6ec0d2f7c99e11f5866d8cf96b3ba53e852668eb9d03fb5')
check('exact341 admission reducer source SHA',hashlib.sha256(module_path.read_bytes()).hexdigest()=='1031e9e2099547def50ba1bdfb5fc8ff36fe94ef42540fbeef5c21509db72bed')
check('exact341 reviewer source SHA',hashlib.sha256(review_path.read_bytes()).hexdigest()=='0ba0737b38b9bf10874b8bff16df4f4421576088f072c23d41940a6f5b11079d')
c=module('slack_update_offline_core340',core_path);m=module('private341_admission',module_path)
review={'__name__':'private341_review'};exec(compile(ast.parse(review_path.read_text()),str(review_path),'exec'),review)
history=review['verify'](root);mapping=load('-phase-map.json');contract=load('-contract.json');policy=load('-policy.json')
check('all1647 accepted340 source bytes preserved',len(history)==1647)
check('complete exact624 user acceptance no normalization',review['validate_return'](load('-checkpoint-confirmation.json'),load('-step340-user-acceptance.json'),policy))
check('four source phases full original view contracts and pending native obligations',review['validate_mapping'](mapping,contract,history))
check('source phase order exact',m.PHASES==('service-barrier-authentication','service-original-durable-claim','service-durable-launch-spend','service-single-worker-spawn'))
check('reducer imports only dataclass helpers and fixed private340 classes',[(x.module,tuple(y.name for y in x.names)) for x in ast.walk(ast.parse(module_path.read_text())) if isinstance(x,ast.ImportFrom)]==[('dataclasses',('dataclass','fields','replace')),('slack_update_offline_core340',('ModelContext','ModelView','RightReport','RawStatus','CoreState','ModelEvent','initial_state','RIGHTS_WINDOWS','MAX_RAW_STATUSES'))] and not any(isinstance(x,ast.Import) for x in ast.walk(ast.parse(module_path.read_text()))))
check('no effect or dynamic dispatch call in reducer',not any(isinstance(x,ast.Call) and isinstance(x.func,ast.Name) and x.func.id in ('open','exec','eval','compile','__import__','print','input') for x in ast.walk(ast.parse(module_path.read_text()))))
ctx=c.ModelContext('model-attempt-a','model-boot-a');other=c.ModelContext('model-attempt-b','model-boot-b')
names=('authenticated-policy-view','issuer-policy-view','dependency-closure-view','source-closure-view','consumed-original-context','spent-launch-view')
views={name:c.ModelView(name,ctx,'model-view-'+str(i)) for i,name in enumerate(names)}
live=tuple(c.RightReport(w,'reported-live') for w in c.RIGHTS_WINDOWS)
a=m.AdmissionAssessment(ctx,live,*(['reported-valid']*7),claim_durability='reported-valid',launch_durability='reported-valid',handoff_prepared='reported-valid',handoff_delivery='reported-valid',child_observation='reported-owned')
def event(i,outcome='known-success',v=None,raw=None,context=ctx):
 phase=m.PHASES[i];actor,window,_=c.PHASE_ROWS[phase]
 expected=((names[0],names[1],names[2],names[3]),(names[0],names[4],names[2],names[3]),(names[4],names[5],names[2],names[3]),(names[4],names[5],names[2],names[3]))[i]
 if v is None:v=tuple(views[k] for k in expected) if outcome=='known-success' else ()
 if raw is None:raw=() if outcome=='unattempted' else (c.RawStatus('model-call-'+str(i),0 if outcome=='known-success' else None if outcome=='unknown' else -17),)
 return c.ModelEvent(context,phase,actor,window,outcome,views=v,raw_statuses=raw)
def projection(s):
 q=s.core
 return (q.phase,q.claim,q.launch,q.spawn,q.children,s.claim_attempted,s.launch_attempted,s.spawn_attempted,s.quarantined,s.handed_to_worker,q.forward,q.bootstrap,q.traps,q.guard,q.baseline,q.backups,q.pin,q.stage7_completed,q.owned,q.target,q.publication)
# Literal expected trace written independently of reducer branches.
expected=[
 (None,'known-unused','unspent','unattempted','unobserved',False,False,False,False,False,'closed','unattempted',False,'unobserved','unobserved','unobserved',None,0,'unobserved','unobserved','unattempted'),
 ('service-barrier-authentication','known-unused','unspent','unattempted','unobserved',False,False,False,False,False,'closed','unattempted',False,'unobserved','unobserved','unobserved',None,0,'unobserved','unobserved','unattempted'),
 ('service-original-durable-claim','consumed','unspent','unattempted','unobserved',True,False,False,False,False,'closed','unattempted',False,'unobserved','unobserved','unobserved',None,0,'unobserved','unobserved','unattempted'),
 ('service-durable-launch-spend','consumed','spent','unattempted','unobserved',True,True,False,False,False,'closed','unattempted',False,'unobserved','unobserved','unobserved',None,0,'unobserved','unobserved','unattempted'),
 ('service-single-worker-spawn','consumed','spent','known-owned','known-owned',True,True,True,False,True,'closed','unattempted',False,'unobserved','unobserved','unobserved',None,0,'unobserved','unobserved','unattempted')]
states=[m.start_admission(ctx)];check('literal pristine admission snapshot',projection(states[0])==expected[0])
for i in range(4):
 before=copy.deepcopy(states[-1]);r=m.reduce_admission(states[-1],event(i),a);states.append(r.state)
 check('literal successful prefix '+str(i),r.disposition=='model-advanced' and r.reason=='advanced' and projection(r.state)==expected[i+1])
 check('immutable original input preserved '+str(i),states[-2]==before)
 check('exact append-only successful raw vector '+str(i),r.state.core.raw_statuses==tuple(c.RawStatus('model-call-'+str(j),0) for j in range(i+1)))
 check('all original closure identities retained '+str(i),r.state.policy_view==views[names[0]] and r.state.issuer_view==views[names[1]] and r.state.dependency_view==views[names[2]] and r.state.source_view==views[names[3]])
 check('no native authority evidence or target side effect '+str(i),not r.authority and not r.native_evidence and r.state.core.target=='unobserved' and r.state.core.recovery_spent==0)
 check('same immutable prefix repeated gives equal data '+str(i),m.reduce_admission(states[-2],event(i),a)==r)
 check('valid unattempted reports do not advance or retry '+str(i),m.reduce_admission(states[-2],event(i,'unattempted'),a)==m.AdmissionDecision(states[-2],'model-unattempted','unattempted'))
 for outcome in ('known-failure','unknown'):
  r=m.reduce_admission(states[i],event(i,outcome),a)
  check('attempted '+outcome+' quarantines phase '+str(i),r.disposition=='model-quarantined' and r.state.quarantined and r.state.core.forward=='stopped' and not r.state.handed_to_worker)
  check('first raw failure preserved '+outcome+' phase '+str(i),r.state.core.first_failure==c.RawStatus('model-call-'+str(i),-17 if outcome=='known-failure' else None) and r.state.core.raw_statuses==states[i].core.raw_statuses+event(i,outcome).raw_statuses)
  check('attempt bits cannot reset '+outcome+' phase '+str(i),(r.state.claim_attempted,r.state.launch_attempted,r.state.spawn_attempted)==((False,False,False),(True,False,False),(True,True,False),(True,True,True))[i])
  for j in range(4):
   replay=m.reduce_admission(r.state,event(j),a)
   check('terminal failure replay retains first failure '+outcome+'/'+str(i)+'/'+str(j),replay.state==r.state and replay.disposition=='model-rejected' and replay.reason=='terminal-prefix')
 for omitted in range(len(event(i).views)):
  ev=event(i,v=event(i).views[:omitted]+event(i).views[omitted+1:]);r=m.reduce_admission(states[i],ev,a)
  check('missing positive source view stops '+str(i)+'/'+event(i).views[omitted].name,r.disposition=='model-quarantined' and r.reason=='contradictory-positive-report')
 for code in (None,-2147483648,-1,1,2147483647):
  r=m.reduce_admission(states[i],event(i,raw=(c.RawStatus('model-raw-'+str(i),code),)),a)
  check('raw nonzero or unknown cannot masquerade as success '+str(i)+'/'+str(code),r.disposition=='model-quarantined' and r.state.core.first_failure.code==code)
 for window in ('service','policy' if i==0 else 'admission' if i==1 else 'launch'):
  for status in ('inactive','expired','revoked','uncertain'):
   rights=tuple(c.RightReport(x.window,status if x.window==window else x.status) for x in live)
   r=m.reduce_admission(states[i],event(i),dataclasses.replace(a,rights=rights))
   check('distinct right gate loss '+str(i)+'/'+window+'/'+status,r.disposition=='model-quarantined' and r.reason=='gate-loss' and r.state.core.rights==rights)
   r=m.reduce_admission(states[i],event(i,'unattempted'),dataclasses.replace(a,rights=rights))
   check('unattempted gate loss adds no attempt '+str(i)+'/'+window+'/'+status,r.disposition=='model-quarantined' and (r.state.claim_attempted,r.state.launch_attempted,r.state.spawn_attempted)==(states[i].claim_attempted,states[i].launch_attempted,states[i].spawn_attempted) and r.state.core.claim==states[i].core.claim and r.state.core.launch==states[i].core.launch and r.state.core.spawn==states[i].core.spawn)
 for field in ('service_barrier',)+m.IDENTITY_FIELDS:
  for value in ('reported-invalid','unobserved'):
   r=m.reduce_admission(states[i],event(i),dataclasses.replace(a,**{field:value}))
   untouched=i==0 and field!='service_barrier'
   check('authenticated original gate '+str(i)+'/'+field+'/'+value,(r.disposition,r.reason)==(('model-rejected','identity-not-authenticated') if untouched else ('model-quarantined','gate-loss')) and (not untouched or r.state==states[0]))
 for j in range(4):
  if i!=j:
   r=m.reduce_admission(states[i],event(j),a)
   check('out of order report leaves prefix unchanged '+str(i)+'/'+str(j),r.disposition=='model-rejected' and r.reason=='wrong-order' and r.state==states[i])
 r=m.reduce_admission(states[i],event(i,context=other,v=()),a)
 check('cross-original event leaves prefix unchanged '+str(i),r.reason=='wrong-original' and r.state==states[i])
 r=m.reduce_admission(states[i],event(i),dataclasses.replace(a,context=other))
 check('cross-original assessment leaves prefix unchanged '+str(i),r.reason=='wrong-original' and r.state==states[i])
for i in (1,2,3):
 for name in (names[2],names[3])+((names[0],) if i==1 else (names[4],))+((names[5],) if i==3 else ()):
  v=tuple(dataclasses.replace(x,symbol='model-substituted-view') if x.name==name else x for x in event(i).views)
  r=m.reduce_admission(states[i],event(i,v=v),a)
  check('same-context closure or consumed token substitution stops '+str(i)+'/'+name,r.reason=='contradictory-positive-report' and r.state.quarantined)
for i,field in ((1,'claim_durability'),(2,'launch_durability'),(3,'handoff_delivery'),(3,'handoff_prepared')):
 for value in ('unobserved','reported-invalid'):
  r=m.reduce_admission(states[i],event(i),dataclasses.replace(a,**{field:value}))
  check('missing durable or bounded handoff report stops '+field+'/'+value,r.state.quarantined and not r.state.handed_to_worker)
for child in ('reported-none','reported-owned','unobserved','uncertain'):
 for outcome in ('known-failure','unknown','known-success'):
  r=m.reduce_admission(states[3],event(3,outcome),dataclasses.replace(a,child_observation=child))
  spawn_expected='known-owned' if child=='reported-owned' and outcome in ('known-failure','known-success') else 'known-absent' if child=='reported-none' and outcome=='known-failure' else 'uncertain'
  children_expected='known-owned' if child=='reported-owned' else 'known-none' if child=='reported-none' and outcome=='known-failure' else 'uncertain'
  check('owned child knowledge distinct from launch ACK '+child+'/'+outcome,r.state.core.spawn==spawn_expected and r.state.core.children==children_expected and r.state.handed_to_worker==(outcome=='known-success' and child=='reported-owned'))
check('known failed spend retains unspent value but burns attempt',m.reduce_admission(states[2],event(2,'known-failure'),a).state.core.launch=='unspent' and m.reduce_admission(states[2],event(2,'known-failure'),a).state.launch_attempted)
check('known failed claim cannot become known-unused',m.reduce_admission(states[1],event(1,'known-failure'),a).state.core.claim=='known-rejected')
check('unknown spend cannot dispatch or refund',m.reduce_admission(states[2],event(2,'unknown'),a).state.core.launch=='uncertain')
r=m.reduce_admission(states[1],event(1,raw=(c.RawStatus('model-zero-semantic-failure',0),)),dataclasses.replace(a,claim_durability='unobserved'))
check('raw zero retained as first semantic failure without proving success',r.state.core.first_failure==c.RawStatus('model-zero-semantic-failure',0) and r.state.quarantined)
r=m.reduce_admission(states[1],event(1,'unknown',raw=(c.RawStatus('model-call-zero',0),c.RawStatus('model-call-negative',-9),c.RawStatus('model-call-null',None))),a)
check('first nonzero raw status selected before later null',r.state.core.first_failure==c.RawStatus('model-call-negative',-9))
r=m.reduce_admission(states[0],event(0,'unknown',raw=()),a)
check('failure without raw report remains explicitly unknown',r.state.core.first_failure==c.RawStatus('model-service-barrier-authentication',None))
for i in range(1,4):
 r=m.reduce_admission(states[i],event(i,raw=(c.RawStatus('model-call-0',0),)),a)
 check('duplicate raw-call label rejected without transition '+str(i),r.state==states[i] and r.reason=='duplicate-raw-call')
full=dataclasses.replace(states[1],core=dataclasses.replace(states[1].core,raw_statuses=tuple(c.RawStatus('model-cap-'+str(i),0) for i in range(4096))))
check('bounded accumulated raw statuses reject overflow before progress',m.reduce_admission(full,event(1),a)==m.AdmissionDecision(full,'model-rejected','resource-limit'))
for phase,(actor,window,_) in c.PHASE_ROWS.items():
 if phase not in m.PHASES:
  ev=c.ModelEvent(ctx,phase,actor,window,'unknown');r=m.reduce_admission(states[2],ev,a)
  check('later native-model phase is unsupported here '+phase,r.reason=='unsupported-phase' and r.state==states[2])
check('handed prefix cannot launch again',m.reduce_admission(states[4],event(3),a)==m.AdmissionDecision(states[4],'model-rejected','terminal-prefix'))
for field,new in [('bootstrap','closed'),('traps',True),('guard','continuous'),('baseline','fresh-original'),('backups','verified-original'),('pin','model-pin-a'),('stage7_completed',1),('owned','known-binding'),('target','known-changed'),('recovery_limit',1),('publication','receipt-reported'),('forward','active')]:
 check('service wrapper rejects premature worker field '+field,rejects(dataclasses.replace,states[2],core=dataclasses.replace(states[2].core,**{field:new})))
for i,changes in [(0,{'claim_attempted':True}),(0,{'launch_attempted':True}),(0,{'spawn_attempted':True}),(0,{'policy_view':views[names[0]]}),(1,{'policy_view':None}),(1,{'issuer_view':None}),(1,{'dependency_view':None}),(1,{'source_view':None}),(2,{'claim_attempted':False}),(2,{'consumed_view':None}),(3,{'launch_attempted':False}),(3,{'spent_view':None}),(4,{'spawn_attempted':False}),(4,{'handed_to_worker':False}),(4,{'quarantined':True})]:
 check('impossible prefix view or attempt flags rejected '+str(i)+'/'+str(tuple(changes)),rejects(dataclasses.replace,states[i],**changes))
for i,changes in [(0,{'claim':'consumed'}),(1,{'launch':'spent'}),(2,{'claim':'known-unused'}),(3,{'launch':'unspent'}),(3,{'spawn':'known-owned'}),(4,{'children':'known-none'}),(4,{'first_failure':c.RawStatus('model-forged-failure',0)})]:
 check('impossible core prefix rejected '+str(i)+'/'+str(tuple(changes)),rejects(dataclasses.replace,states[i],core=dataclasses.replace(states[i].core,**changes)))
for value in [a,states[0],states[4],m.AdmissionDecision(states[4],'model-advanced','advanced')]:
 check('frozen exact record '+type(value).__name__,rejects(setattr,value,'authority',True))
 for field in ('authority','native_evidence'):
  for wrong in (True,0,1,None):check('record cannot promote native authority '+type(value).__name__+'/'+field+'/'+repr(wrong),rejects(dataclasses.replace,value,**{field:wrong}))
for field in ('claim_attempted','launch_attempted','spawn_attempted','quarantined','handed_to_worker'):
 check('boolean attempt flag cannot be integer '+field,rejects(dataclasses.replace,states[0],**{field:0}))
for field in ('service_barrier',)+m.IDENTITY_FIELDS+('claim_durability','launch_durability','handoff_prepared','handoff_delivery'):
 for wrong in ('native-proof',True,None):check('closed symbolic report '+field+'/'+repr(wrong),rejects(dataclasses.replace,a,**{field:wrong}))
check('all rights must be deeply immutable',rejects(dataclasses.replace,a,rights=list(live)))
check('all nine original rights ordered exactly',rejects(dataclasses.replace,a,rights=tuple(reversed(live))))
check('no preflight or requested-match admission parameter',rejects(dataclasses.replace,a,requested_match=True) and rejects(dataclasses.replace,a,preflight=True))
for key,new in [('user_worktree_clean',False),('runtime_authority',True),('strong_safe_pause',True),('commit_prefix','fffffff')]:
 bad=copy.deepcopy(load('-checkpoint-confirmation.json'));bad[key]=new
 check('predecessor confirmation cannot be forged '+key,rejects(review['validate_return'],bad,load('-step340-user-acceptance.json'),policy))
for key,new in [('phase_rows',{}),('phase_view_types',{}),('required_positive_views',{}),('native_authority',True)]:
 bad=copy.deepcopy(mapping);bad[key]=new
 check('source mapping or native scope cannot be waived '+key,rejects(review['validate_mapping'],bad,contract,history))
for argv in [[],['--bogus'],['--check'],['--check','']]:
 check('strict341 reviewer CLI '+repr(argv),run(['python3','-B',review_path,*argv]).returncode==2)
r=run(['python3','-B',review_path,'--check',root]);check('actual source-bound341 review entry',r.returncode==0 and 'step341_pure_admission_launch_review_status\tPASS' in r.stdout)
with tempfile.TemporaryDirectory(prefix='step341-accepted-source-') as directory:
 snapshot=Path(directory)/'accepted340';snapshot.mkdir()
 for relative,raw in history.items():
  p=snapshot/relative;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
 r=run(['python3','-B',snapshot/policy['predecessor_verifier'],'--check',snapshot])
 if r.returncode:sys.stderr.write(r.stdout+r.stderr)
 check('unchanged340 reviewer reruns on exact accepted snapshot',r.returncode==0 and 'step340_offline_schema_review_status\tPASS' in r.stdout)
 previous=Path(policy['predecessor_verifier']).stem
 r=run(['bash',snapshot/'tests/reference'/('test-'+previous+'-harness.sh')])
 if r.returncode:sys.stderr.write(r.stdout[-3000:]+r.stderr)
 check('unchanged340 full624 schema checks rerun successfully',r.returncode==0 and r.stdout.splitlines().count('Result: PASS (624 passes, 0 failures)')==1)
 check('all624 rerun labels equal accepted user return in exact order',[x for x in r.stdout.splitlines() if x.startswith('PASS: ')]==policy['accepted_ordered340_labels'])
check('all accepted sources unchanged after reducer tests',review['verify'](root)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
