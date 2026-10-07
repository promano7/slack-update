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

root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bootstrap-guard-reducer-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1/';core_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core.py';admission_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer.py';module_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bootstrap-guard-reducer.py';review_path=root/'tools/reference'/(base+'.py')
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
check('exact unchanged341 admission reducer SHA',hashlib.sha256(admission_path.read_bytes()).hexdigest()=='1031e9e2099547def50ba1bdfb5fc8ff36fe94ef42540fbeef5c21509db72bed')
check('exact342 bootstrap reducer SHA',hashlib.sha256(module_path.read_bytes()).hexdigest()=='201636350a88c7562cad5cf04f71d5c582b7ea547c2e98b1f7a3751756b32e89')
check('exact342 source reviewer SHA',hashlib.sha256(review_path.read_bytes()).hexdigest()=='f214617ef98e631aabcbe043e419e8beb43b097e9d7846b8f92fc224dbdb7883')
c=module('slack_update_offline_core340',core_path);a=module('slack_update_offline_admission341',admission_path);m=module('private342_bootstrap',module_path)
review={'__name__':'private342_review'};exec(compile(ast.parse(review_path.read_text()),str(review_path),'exec'),review)
history=review['verify'](root);mapping=load('-phase-map.json');contract=load('-contract.json');policy=load('-policy.json')
check('all1656 accepted341 source bytes preserved',len(history)==1656)
check('full exact462 user return accepted without normalization',review['validate_return'](load('-checkpoint-confirmation.json'),load('-step341-user-acceptance.json'),policy))
check('five source phases original321 limits and complete native gaps retained',review['validate_mapping'](mapping,contract,history))
check('exact source321 bounded byte deadline and descriptor constants',(m.MAX_BOOTSTRAP_BYTES,m.BOOTSTRAP_DEADLINE_MS,m.SYMBOLIC_READ_FD)==(65536,10000,3))
tree=ast.parse(module_path.read_text());imports=[(x.module,tuple(y.name for y in x.names)) for x in ast.walk(tree) if isinstance(x,ast.ImportFrom)]
check('reducer imports only immutable helpers and fixed private340341 classes',imports==[('dataclasses',('dataclass','fields','replace')),('slack_update_offline_core340',('ModelContext','ModelView','RightReport','RawStatus','CoreState','ModelEvent','RIGHTS_WINDOWS','MAX_RAW_STATUSES')),('slack_update_offline_admission341',('AdmissionState',))] and not any(isinstance(x,ast.Import) for x in ast.walk(tree)))
check('no IO native dispatch or dynamic execution in reducer',not any(isinstance(x,ast.Call) and isinstance(x.func,ast.Name) and x.func.id in ('open','exec','eval','compile','__import__','print','input') for x in ast.walk(tree)))
ctx=c.ModelContext('model-attempt-a','model-boot-a');other=c.ModelContext('model-attempt-b','model-boot-b')
live=tuple(c.RightReport(w,'reported-live') for w in c.RIGHTS_WINDOWS)
names=('authenticated-policy-view','issuer-policy-view','dependency-closure-view','source-closure-view','consumed-original-context','spent-launch-view','closed-bootstrap-view','early-observation-view','armed-traps-view','known-child-set-view','live-original-fence-view','continuous-guard-view','original-baseline-view')
views={name:c.ModelView(name,ctx,'model-view-'+str(i)) for i,name in enumerate(names)}
assessment=a.AdmissionAssessment(ctx,live,*(['reported-valid']*7),claim_durability='reported-valid',launch_durability='reported-valid',handoff_prepared='reported-valid',handoff_delivery='reported-valid',child_observation='reported-owned')
admissions=[a.start_admission(ctx)]
admission_names=((names[0],names[1],names[2],names[3]),(names[0],names[4],names[2],names[3]),(names[4],names[5],names[2],names[3]),(names[4],names[5],names[2],names[3]))
for i in range(4):
 phase=a.PHASES[i];actor,window,_=c.PHASE_ROWS[phase]
 ev=c.ModelEvent(ctx,phase,actor,window,'known-success',views=tuple(views[k] for k in admission_names[i]),raw_statuses=(c.RawStatus('model-admission-'+str(i),0),))
 admissions.append(a.reduce_admission(admissions[-1],ev,assessment).state)
b=m.BootstrapAssessment(ctx,live,**{k:'reported-valid' for k in m.COMMON_REPORTS+m.OTHER_REPORTS},raw_bytes=1024,elapsed_milliseconds=37,symbolic_read_fd=3)
common=(names[4],names[2],names[3])
bootstrap_names=(common+(names[5],names[6]),common+(names[5],names[6]),common+(names[6],names[7]),common+(names[8],names[9],names[10]),common+(names[8],names[10],names[11],names[12]))
def event(i,outcome='known-success',v=None,raw=None,context=ctx):
 phase=m.PHASES[i];actor,window,_=c.PHASE_ROWS[phase]
 if v is None:v=tuple(views[k] for k in bootstrap_names[i]) if outcome=='known-success' else ()
 if raw is None:raw=() if outcome=='unattempted' else (c.RawStatus('model-bootstrap-'+str(i),0 if outcome=='known-success' else None if outcome=='unknown' else 143),)
 return c.ModelEvent(context,phase,actor,window,outcome,views=v,raw_statuses=raw)
def projection(s):
 q=s.core
 return (s.completed,q.phase,q.bootstrap,q.traps,q.guard,q.baseline,q.forward,s.close_known,s.stopped,s.ready_for_owned,q.claim,q.launch,q.spawn,q.children,q.owned,q.backups,q.pin,q.stage7_completed,q.target,q.publication)
# Independently written literal trace: early observation never becomes original baseline.
expected=[
 (0,'service-single-worker-spawn','unattempted',False,'unobserved','unobserved','closed',False,False,False,'consumed','spent','known-owned','known-owned','unobserved','unobserved',None,0,'unobserved','unattempted'),
 (1,'worker0-bounded-auth-read','bounded-read',False,'unobserved','unobserved','closed',False,False,False,'consumed','spent','known-owned','known-owned','unobserved','unobserved',None,0,'unobserved','unattempted'),
 (2,'worker0-close-bootstrap','closed',False,'unobserved','unobserved','closed',True,False,False,'consumed','spent','known-owned','known-owned','unobserved','unobserved',None,0,'unobserved','unattempted'),
 (3,'worker0-readonly-preflight','closed',False,'unobserved','unobserved','closed',True,False,False,'consumed','spent','known-owned','known-owned','unobserved','unobserved',None,0,'unobserved','unattempted'),
 (4,'worker1-arm-traps','closed',True,'unobserved','unobserved','closed',True,False,False,'consumed','spent','known-owned','known-owned','unobserved','unobserved',None,0,'unobserved','unattempted'),
 (5,'interstage1-2-guard-freshoriginal','closed',True,'continuous','fresh-original','active',True,False,True,'consumed','spent','known-owned','known-owned','unobserved','unobserved',None,0,'unobserved','unattempted')]
states=[m.start_bootstrap(admissions[4])];check('literal post341 consumed spent owned handoff snapshot',projection(states[0])==expected[0])
for i in range(5):
 before=copy.deepcopy(states[-1]);r=m.reduce_bootstrap(states[-1],event(i),b);states.append(r.state)
 check('literal successful five-phase prefix '+str(i),r.disposition=='model-advanced' and r.reason=='advanced' and projection(r.state)==expected[i+1])
 check('input immutable and original341 handoff unchanged '+str(i),states[-2]==before and r.state.admission==admissions[4])
 check('append exact successful raw vector '+str(i),r.state.core.raw_statuses==admissions[4].core.raw_statuses+tuple(c.RawStatus('model-bootstrap-'+str(j),0) for j in range(i+1)))
 check('private result never native proof or authority '+str(i),not r.authority and not r.native_evidence and not r.state.core.authority and not r.state.core.native_evidence)
 check('same immutable prefix repeated gives equal data '+str(i),m.reduce_bootstrap(states[i],event(i),b)==r)
 check('valid unattempted report adds no attempt '+str(i),m.reduce_bootstrap(states[i],event(i,'unattempted'),b)==m.BootstrapDecision(states[i],'model-unattempted','unattempted'))
 for outcome in ('known-failure','unknown'):
  r=m.reduce_bootstrap(states[i],event(i,outcome),b)
  check('failure or unknown stops exact phase '+str(i)+'/'+outcome,r.disposition=='model-stopped' and r.state.stopped and not r.state.ready_for_owned and r.state.core.forward=='stopped')
  check('raw first failure exact with no burned claim refund '+str(i)+'/'+outcome,r.state.core.first_failure==c.RawStatus('model-bootstrap-'+str(i),143 if outcome=='known-failure' else None) and r.state.core.claim=='consumed' and r.state.core.launch=='spent' and r.state.admission==admissions[4])
  check('closure pending only until independently known close '+str(i)+'/'+outcome,r.state.close_known==(i>=2) and r.state.core.bootstrap==('closed' if i>=2 else 'uncertain'))
  for j in range(5):
   if i==0 and j==1:continue
   replay=m.reduce_bootstrap(r.state,event(j),b)
   check('stopped prefix cannot replay worker phase '+str(i)+'/'+outcome+'/'+str(j),replay.state==r.state and replay.reason=='terminal-prefix')
  if i==0:
   first=r.state.core.first_failure;closed=m.reduce_bootstrap(r.state,event(1),b)
   check('known close after '+outcome+' read is hygiene only',closed.disposition=='model-close-only' and closed.state.close_known and closed.state.stopped and closed.state.completed==0 and closed.state.core.first_failure==first and closed.state.core.forward=='stopped')
   check('closed failed read cannot become authenticated worker',closed.state.early_view is None and closed.state.traps_view is None and closed.state.baseline_view is None and not closed.state.ready_for_owned)
   check('close after read failure cannot be repeated',m.reduce_bootstrap(closed.state,event(1),b).state==closed.state and m.reduce_bootstrap(closed.state,event(1),b).reason=='terminal-prefix')
   for close_outcome in ('known-failure','unknown'):
    failed=m.reduce_bootstrap(r.state,event(1,close_outcome),b)
    check('failed hygiene close retains earliest failure '+outcome+'/'+close_outcome,failed.state.core.first_failure==first and not failed.state.close_known and failed.state.core.bootstrap=='uncertain')
    check('unknown or failed hygiene close not retried '+outcome+'/'+close_outcome,m.reduce_bootstrap(failed.state,event(1),b).state==failed.state and m.reduce_bootstrap(failed.state,event(1),b).reason=='terminal-prefix')
 for omitted in range(len(event(i).views)):
  v=event(i).views[:omitted]+event(i).views[omitted+1:];r=m.reduce_bootstrap(states[i],event(i,v=v),b)
  check('missing positive nominal view stops '+str(i)+'/'+event(i).views[omitted].name,r.state.stopped and r.reason=='contradictory-positive-report')
 for name in common+((names[5],) if i<2 else ()) + ((names[6],) if i in (1,2) else ()) + ((names[8],names[10]) if i==4 else ()):
  v=tuple(dataclasses.replace(x,symbol='model-substitute') if x.name==name else x for x in event(i).views);r=m.reduce_bootstrap(states[i],event(i,v=v),b)
  check('same-context original token substitution stops '+str(i)+'/'+name,r.state.stopped and r.reason=='contradictory-positive-report')
 for code in (None,-2147483648,-1,1,20,128,137,143,2147483647):
  r=m.reduce_bootstrap(states[i],event(i,raw=(c.RawStatus('model-fault-'+str(i),code),)),b)
  check('raw unknown signed signal or nonzero cannot imply success '+str(i)+'/'+str(code),r.state.stopped and r.state.core.first_failure==c.RawStatus('model-fault-'+str(i),code))
 required=m.COMMON_REPORTS+('trusted_time',)+(('live_fence',) if i>=3 else ())
 extra=(('bootstrap_canonical','complete_eof'),('read_end_closed',),('readonly_observation',),('traps_installed','known_child_control'),('all_writers_excluded','guard_identity','fresh_original_capture','known_child_control'))[i]
 for field in required+extra:
  for value in ('reported-invalid','unobserved'):
   r=m.reduce_bootstrap(states[i],event(i),dataclasses.replace(b,**{field:value}))
   check('missing authentication containment time fence or phase gate '+str(i)+'/'+field+'/'+value,r.state.stopped and not r.state.ready_for_owned and r.state.core.first_failure is not None)
 window='bootstrap' if i<3 else 'forward'
 for status in ('inactive','expired','revoked','uncertain'):
  rights=tuple(c.RightReport(x.window,status if x.window==window else x.status) for x in live);bad=dataclasses.replace(b,rights=rights)
  r=m.reduce_bootstrap(states[i],event(i),bad)
  check('source rights loss always stops '+str(i)+'/'+status,r.state.stopped and r.state.core.rights==rights and r.reason=='gate-loss')
  if i==1:check('rights loss still records known close as hygiene '+status,r.state.close_known and r.state.core.bootstrap=='closed' and r.state.core.forward=='stopped')
  r=m.reduce_bootstrap(states[i],event(i,'unattempted'),bad)
  check('unattempted rights loss does not invent phase attempt '+str(i)+'/'+status,r.state.stopped and r.state.attempts==states[i].attempts and r.state.core.first_failure is not None)
 for j in range(5):
  if i==j:continue
  r=m.reduce_bootstrap(states[i],event(j),b)
  check('source order cannot be skipped '+str(i)+'/'+str(j),r.reason=='wrong-order' and r.state==states[i])
 r=m.reduce_bootstrap(states[i],event(i,context=other,v=()),b)
 check('cross-original event leaves prefix unchanged '+str(i),r.reason=='wrong-original' and r.state==states[i])
 r=m.reduce_bootstrap(states[i],event(i),dataclasses.replace(b,context=other))
 check('cross-original assessment leaves prefix unchanged '+str(i),r.reason=='wrong-original' and r.state==states[i])
for field,cases in [('raw_bytes',[(None,False),(0,False),(1,True),(65535,True),(65536,True),(65537,False),(2147483647,False)]),('elapsed_milliseconds',[(None,False),(0,True),(9999,True),(10000,False),(10001,False),(2147483647,False)]),('symbolic_read_fd',[(None,False),(0,False),(2,False),(3,True),(4,False),(2147483647,False)])]:
 for value,accepted in cases:
  r=m.reduce_bootstrap(states[0],event(0),dataclasses.replace(b,**{field:value}))
  check('literal bounded bootstrap accounting '+field+'/'+repr(value),(r.disposition=='model-advanced')==accepted)
 for value in (-1,True,1.5,'3',2147483648):check('accounting shape exact bounded integer '+field+'/'+repr(value),rejects(dataclasses.replace,b,**{field:value}))
stopped=m.reduce_bootstrap(states[0],event(0,'unknown'),b).state
bad=dataclasses.replace(b,rights=tuple(c.RightReport(x.window,'revoked') for x in live),**{k:'unobserved' for k in m.COMMON_REPORTS},trusted_time='unobserved',live_fence='unobserved')
r=m.reduce_bootstrap(stopped,event(1),bad)
check('close-only hygiene needs no renewed rights or online service',r.disposition=='model-close-only' and r.state.close_known and r.state.core.first_failure==stopped.core.first_failure and r.state.core.forward=='stopped')
check('unattempted hygiene close preserves obligation without spending',m.reduce_bootstrap(stopped,event(1,'unattempted'),bad)==m.BootstrapDecision(stopped,'model-unattempted','unattempted'))
stopped0=m.reduce_bootstrap(states[0],event(0,'unattempted'),dataclasses.replace(b,independent_launch='unobserved')).state
r=m.reduce_bootstrap(stopped0,event(1),bad)
check('close after gate loss without read never authenticates input',r.state.completed==0 and r.state.attempts==('worker0-close-bootstrap',) and r.state.close_known and r.state.stopped and not r.state.ready_for_owned)
check('early preflight cannot be supplied as original baseline type',rejects(c.ModelEvent,ctx,m.PHASES[4],'supervisor','forward','known-success',views=(views[names[7]],)))
check('no baseline stored from early readonly preflight',states[3].early_view==views[names[7]] and states[3].baseline_view is None and states[3].core.baseline=='unobserved')
check('fresh original is separately captured after traps',states[5].baseline_view==views[names[12]] and states[5].baseline_view!=states[5].early_view and states[5].traps_view==states[4].traps_view and states[5].fence_view==states[4].fence_view)
check('uncertain guard cannot be reacquired',m.reduce_bootstrap(m.reduce_bootstrap(states[4],event(4,'unknown'),b).state,event(4),b).reason=='terminal-prefix')
check('successful ready-for-owned prefix is terminal for342',m.reduce_bootstrap(states[5],event(4),b)==m.BootstrapDecision(states[5],'model-rejected','terminal-prefix'))
r=m.reduce_bootstrap(states[2],event(2,raw=(c.RawStatus('model-raw-zero',0),c.RawStatus('model-raw-negative',-7),c.RawStatus('model-raw-null',None))),b)
check('first nonzero raw failure before later null retained',r.state.core.first_failure==c.RawStatus('model-raw-negative',-7))
r=m.reduce_bootstrap(states[4],event(4),dataclasses.replace(b,fresh_original_capture='unobserved'))
check('zero raw status retained on semantic guarded-capture failure',r.state.core.first_failure==c.RawStatus('model-bootstrap-4',0) and r.state.core.guard=='uncertain' and r.state.core.baseline=='uncertain')
for i in range(5):
 r=m.reduce_bootstrap(states[i],event(i,raw=(c.RawStatus('model-admission-0',0),)),b)
 check('duplicate admission raw label cannot be hidden '+str(i),r.reason=='duplicate-raw-call' and r.state==states[i])
full=dataclasses.replace(states[0],core=dataclasses.replace(states[0].core,raw_statuses=states[0].core.raw_statuses+tuple(c.RawStatus('model-cap-'+str(i),0) for i in range(4092))))
check('aggregate raw vector bounded before any advance',m.reduce_bootstrap(full,event(0),b)==m.BootstrapDecision(full,'model-rejected','resource-limit'))
for phase,(actor,window,_) in c.PHASE_ROWS.items():
 if phase not in m.PHASES:
  ev=c.ModelEvent(ctx,phase,actor,window,'unknown');r=m.reduce_bootstrap(states[2],ev,b)
  check('unsupported admission owned recovery or publication phase '+phase,r.reason=='unsupported-phase' and r.state==states[2])
for prefix in admissions[:4]:check('bootstrap cannot precede consumed spent known worker '+str(prefix.core.phase),rejects(m.start_bootstrap,prefix))
for field,new in [('claim','known-unused'),('launch','unspent'),('spawn','known-absent'),('owned','known-binding'),('backups','verified-original'),('pin','model-raw-pin'),('stage7_completed',1),('target','known-changed'),('recovery_limit',1),('publication','record-reported')]:
 check('bootstrap cannot reset admission or advance later field '+field,rejects(dataclasses.replace,states[3],core=dataclasses.replace(states[3].core,**{field:new})))
for i,changes in [(0,{'completed':True}),(0,{'attempts':list()}),(0,{'attempts':(m.PHASES[1],)}),(1,{'close_known':True}),(2,{'close_known':False}),(3,{'early_view':None}),(3,{'baseline_view':views[names[12]]}),(4,{'traps_view':None}),(4,{'fence_view':None}),(5,{'baseline_view':None}),(5,{'guard_view':None}),(5,{'ready_for_owned':False})]:
 check('impossible semantic prefix wrapper rejected '+str(i)+'/'+str(tuple(changes)),rejects(dataclasses.replace,states[i],**changes))
for i,changes in [(0,{'bootstrap':'closed'}),(1,{'bootstrap':'closed'}),(2,{'bootstrap':'uncertain'}),(3,{'traps':True}),(4,{'guard':'continuous'}),(4,{'baseline':'fresh-original'}),(5,{'forward':'closed'}),(5,{'traps':False})]:
 check('impossible core prerequisite combination rejected '+str(i)+'/'+str(tuple(changes)),rejects(dataclasses.replace,states[i],core=dataclasses.replace(states[i].core,**changes)))
for value in [b,states[0],states[5],m.BootstrapDecision(states[5],'model-advanced','advanced')]:
 check('immutable record '+type(value).__name__,rejects(setattr,value,'authority',True))
 for field in ('authority','native_evidence'):
  for wrong in (True,0,None):check('no native promotion '+type(value).__name__+'/'+field+'/'+repr(wrong),rejects(dataclasses.replace,value,**{field:wrong}))
for field in m.COMMON_REPORTS+m.OTHER_REPORTS:
 for wrong in ('native-proof',True,None):check('closed symbolic assessment '+field+'/'+repr(wrong),rejects(dataclasses.replace,b,**{field:wrong}))
check('rights tuple immutable exact full order',rejects(dataclasses.replace,b,rights=list(live)) and rejects(dataclasses.replace,b,rights=tuple(reversed(live))))
for key,new in [('user_worktree_clean',False),('runtime_authority',True),('strong_safe_pause',True),('commit_prefix','fffffff')]:
 bad=copy.deepcopy(load('-checkpoint-confirmation.json'));bad[key]=new
 check('forged341 acceptance rejected '+key,rejects(review['validate_return'],bad,load('-step341-user-acceptance.json'),policy))
for key,new in [('phase_rows',{}),('required_positive_views',{}),('bootstrap_limits',{'maximum_raw_bytes':65537,'deadline_seconds':11,'symbolic_read_fd':4}),('source321_contract',{}),('native_authority',True)]:
 bad=copy.deepcopy(mapping);bad[key]=new
 check('source and limits cannot be waived '+key,rejects(review['validate_mapping'],bad,contract,history))
for argv in [[],['--bogus'],['--check'],['--check','']]:check('strict342 reviewer CLI '+repr(argv),run(['python3','-B',review_path,*argv]).returncode==2)
r=run(['python3','-B',review_path,'--check',root]);check('actual source-bound342 review entry',r.returncode==0 and 'step342_pure_bootstrap_guard_review_status\tPASS' in r.stdout)
with tempfile.TemporaryDirectory(prefix='step342-accepted-source-') as directory:
 snapshot=Path(directory)/'accepted341';snapshot.mkdir()
 for relative,raw in history.items():
  p=snapshot/relative;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
 r=run(['python3','-B',snapshot/policy['predecessor_verifier'],'--check',snapshot])
 if r.returncode:sys.stderr.write(r.stdout+r.stderr)
 check('unchanged341 reviewer reruns on exact accepted snapshot',r.returncode==0 and 'step341_pure_admission_launch_review_status\tPASS' in r.stdout)
 previous=Path(policy['predecessor_verifier']).stem;r=run(['bash',snapshot/'tests/reference'/('test-'+previous+'-harness.sh')])
 if r.returncode:sys.stderr.write(r.stdout[-3000:]+r.stderr)
 check('full unchanged341462 checks rerun successfully',r.returncode==0 and r.stdout.splitlines().count('Result: PASS (462 passes, 0 failures)')==1)
 check('all462 rerun labels match accepted341 full return in order',[x for x in r.stdout.splitlines() if x.startswith('PASS: ')]==policy['accepted_ordered341_labels'])
check('all accepted bytes unchanged after pure bootstrap tests',review['verify'](root)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
