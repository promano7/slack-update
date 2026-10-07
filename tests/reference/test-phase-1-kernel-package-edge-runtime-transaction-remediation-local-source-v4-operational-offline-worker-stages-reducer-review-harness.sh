#!/bin/bash
set -euo pipefail
export LC_ALL=C
root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 -B - "$root" <<'PYTEST'
from pathlib import Path
import ast,copy,dataclasses,hashlib,json,subprocess,sys,tempfile,types
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-worker-stages-reducer-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1/';core_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core.py';admission_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer.py';bootstrap_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bootstrap-guard-reducer.py';module_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-worker-stages-reducer.py';review_path=root/'tools/reference'/(base+'.py')
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
 value=types.ModuleType(name);sys.modules[name]=value;exec(compile(ast.parse(path.read_text()),str(path),'exec'),value.__dict__);return value
for label,path,digest in [('340 core',core_path,'94c8cc3dfdb0d813a6ec0d2f7c99e11f5866d8cf96b3ba53e852668eb9d03fb5'),('341 admission',admission_path,'1031e9e2099547def50ba1bdfb5fc8ff36fe94ef42540fbeef5c21509db72bed'),('342 bootstrap',bootstrap_path,'201636350a88c7562cad5cf04f71d5c582b7ea547c2e98b1f7a3751756b32e89'),('343 worker',module_path,'2678499696ddc9293998dbcd5916aab29c028b045569ade416b38752629836a8'),('343 reviewer',review_path,'097c0bd733132ba1925be88e048ed832fa4f9eed397ae00932fab14340b7d072')]:check('exact SHA-pinned '+label,hashlib.sha256(path.read_bytes()).hexdigest()==digest)
c=module('slack_update_offline_core340',core_path);a=module('slack_update_offline_admission341',admission_path);b=module('slack_update_offline_bootstrap342',bootstrap_path);m=module('private343_worker',module_path)
review={'__name__':'private343_review'};exec(compile(ast.parse(review_path.read_text()),str(review_path),'exec'),review)
history=review['verify'](root);mapping=load('-phase-map.json');contract=load('-contract.json');policy=load('-policy.json')
check('all1665 accepted342 bytes retained',len(history)==1665)
check('complete exact599 user return accepted',review['validate_return'](load('-checkpoint-confirmation.json'),load('-step342-user-acceptance.json'),policy))
check('all source phases full322325 domains edges and pending native proofs',review['validate_mapping'](mapping,contract,history))
tree=ast.parse(module_path.read_text());check('only pinned pure imports',[(x.module,tuple(y.name for y in x.names)) for x in ast.walk(tree) if isinstance(x,ast.ImportFrom)]==[('dataclasses',('dataclass','fields','replace')),('types',('MappingProxyType',)),('slack_update_offline_core340',('ModelContext','ModelView','RightReport','RawStatus','CoreState','ModelEvent','RIGHTS_WINDOWS','MAX_RAW_STATUSES')),('slack_update_offline_bootstrap342',('BootstrapState',))] and not any(isinstance(x,ast.Import) for x in ast.walk(tree)))
check('no IO or dynamic operational execution',not any(isinstance(x,ast.Call) and isinstance(x.func,ast.Name) and x.func.id in ('open','exec','eval','compile','__import__','input','print') for x in ast.walk(tree)))
ctx=c.ModelContext('model-attempt-a','model-boot-a');other=c.ModelContext('model-attempt-b','model-boot-b');live=tuple(c.RightReport(w,'reported-live') for w in c.RIGHTS_WINDOWS)
views={name:c.ModelView(name,ctx,'model-view-'+str(i)) for i,name in enumerate(sorted(c.TYPE_NAMES))}
def typed_event(phase,outcome='known-success',names=(),raw=(),operation='phase-report',context=ctx):
 actor,window,_=c.PHASE_ROWS[phase];return c.ModelEvent(context,phase,actor,window,outcome,operation,tuple(views[k] for k in names),raw)
aa=a.AdmissionAssessment(ctx,live,*(['reported-valid']*7),claim_durability='reported-valid',launch_durability='reported-valid',handoff_prepared='reported-valid',handoff_delivery='reported-valid',child_observation='reported-owned')
admission=a.start_admission(ctx)
for i,names in enumerate([('authenticated-policy-view','issuer-policy-view','dependency-closure-view','source-closure-view'),('authenticated-policy-view','consumed-original-context','dependency-closure-view','source-closure-view'),('consumed-original-context','spent-launch-view','dependency-closure-view','source-closure-view'),('consumed-original-context','spent-launch-view','dependency-closure-view','source-closure-view')]):admission=a.reduce_admission(admission,typed_event(a.PHASES[i],names=names,raw=(c.RawStatus('model-admission-'+str(i),0),)),aa).state
bb=b.BootstrapAssessment(ctx,live,**{k:'reported-valid' for k in b.COMMON_REPORTS+b.OTHER_REPORTS},raw_bytes=1024,elapsed_milliseconds=37,symbolic_read_fd=3);bootstrap=b.start_bootstrap(admission)
common0=('consumed-original-context','dependency-closure-view','source-closure-view')
for i,names in enumerate([common0+('spent-launch-view','closed-bootstrap-view'),common0+('spent-launch-view','closed-bootstrap-view'),common0+('closed-bootstrap-view','early-observation-view'),common0+('armed-traps-view','known-child-set-view','live-original-fence-view'),common0+('armed-traps-view','live-original-fence-view','continuous-guard-view','original-baseline-view')]):bootstrap=b.reduce_bootstrap(bootstrap,typed_event(b.PHASES[i],names=names,raw=(c.RawStatus('model-bootstrap-'+str(i),0),)),bb).state
graph=m.GraphReport(ctx,views['complete-effect-graph-view'],'model-whole-entry',tuple(mapping['original_designed_domains']),tuple(tuple(x) for x in mapping['original_macro_relations']))
row=('model-target','model-version','model-architecture','model-build','model-repository','model-location','model-source-row','model-filter-row');plan=m.WorkerPlan(ctx,graph,'model-target','model-archive',row)
selector=m.SelectorReport(ctx,views['raw-pkglist-pin-view'],admission.source_view.symbol,views['isolated-config-view'].symbol,views['exact-predecessor-view'].symbol,'model-backend-version','model-selector-version','model-blacklist','model-priority','model-repository','model-architecture','model-filter','model-target',(),('model-target',))
candidate=m.CandidateReport(ctx,views['raw-pkglist-pin-view'],admission.source_view,views['exact-predecessor-view'],'model-archive',row)
wa=m.WorkerAssessment(ctx,live,graph,selector,candidate,**{k:'reported-valid' for k in m.COMMON_REPORTS+m.STAGE_REPORTS})
phases=['worker2-owned-workspace','worker3-original-backups','worker4-exact-predecessor','worker5-local-isolation','worker6-refresh-pin-once','worker7-validate-pinned-candidate']
micro=['validate-exact-inputs','register-owned-intent','create-exclusive-stage','write-complete-bytes','metadata-and-data-durable','revalidate-pinned-inputs','commit-no-replace','directory-durability-confirmed','stage-exit-evidence-complete']
steps=[(p,'phase-report','none') for p in phases]+[('worker7-owned-durable-commit',x,'none') for x in micro]+[('worker8-whole-successor-apply','phase-report',x) for x in ('nested-update','nested-install-new','nested-upgrade-all','whole-entry-complete')]
check('literal19 observations match exact source phase and micro ordering',tuple(steps)==m.SEQUENCE)
check('full original30 domains95 macro pairs retained',len(graph.domains)==30 and len(graph.relations)==95 and graph.domains==m.DOMAIN_IDS and graph.relations==m.MACRO_RELATIONS)
def event(i,outcome='known-success',missing=None,raw=None,substitute=None,context=ctx):
 phase,operation,_=steps[i];names=list(mapping['required_positive_views'][phase])
 if i in (15,16,17):names=[k for k in names if k not in ('whole-entry-result-view','contained-runtime-view','contained-snapshot-view','nested-call-result-view','package-effect-result-view')]
 if missing is not None:names.remove(missing)
 v=tuple(dataclasses.replace(views[k],symbol='model-substituted') if k==substitute else views[k] for k in names) if outcome=='known-success' else ()
 if raw is None:raw=() if outcome=='unattempted' else (c.RawStatus('model-worker-'+str(i),20 if i==16 and outcome=='known-success' else 0 if outcome=='known-success' else None if outcome=='unknown' else -7),)
 actor,window,_=c.PHASE_ROWS[phase];v=tuple(dataclasses.replace(x,context=context) for x in v)
 return c.ModelEvent(context,phase,actor,window,outcome,operation,v,raw)
def assessment(i,state=None):
 nested=() if i!=18 or state is None or any(x is None for x in (state.update_raw,state.install_raw,state.upgrade_raw)) else (state.update_raw,state.install_raw,state.upgrade_raw)
 return dataclasses.replace(wa,successor_observation=steps[i][2],nested_statuses=nested)
def projection(s):return (s.completed,s.core.owned,s.core.backups,s.core.target,s.core.stage7_completed,s.binding_status,s.ready_for_finalization)
# Independent literal expected snapshots; binding visibility never means durable exit.
expected=[
 (0,'unobserved','unobserved','unobserved',0,'unattempted',False),
 (1,'known-binding','unobserved','known-unchanged',0,'unattempted',False),
 (2,'known-binding','verified-original','known-unchanged',0,'unattempted',False),
 (3,'known-binding','verified-original','known-changed',0,'unattempted',False),
 (4,'known-binding','verified-original','known-changed',0,'unattempted',False),
 (5,'known-binding','verified-original','known-changed',0,'unattempted',False),
 (6,'known-binding','verified-original','known-changed',0,'unattempted',False),
 (7,'known-binding','verified-original','known-changed',1,'validated',False),
 (8,'known-binding','verified-original','known-changed',2,'intent-recorded',False),
 (9,'known-binding','verified-original','known-changed',3,'staged',False),
 (10,'known-binding','verified-original','known-changed',4,'bytes-written',False),
 (11,'known-binding','verified-original','known-changed',5,'file-durable',False),
 (12,'known-binding','verified-original','known-changed',6,'revalidated',False),
 (13,'known-binding','verified-original','known-changed',7,'visible',False),
 (14,'known-binding','verified-original','known-changed',8,'directory-durable',False),
 (15,'known-binding','verified-original','known-changed',9,'complete',False),
 (16,'known-binding','verified-original','known-changed',9,'complete',False),
 (17,'known-binding','verified-original','known-changed',9,'complete',False),
 (18,'known-binding','verified-original','known-changed',9,'complete',False),
 (19,'known-binding','verified-original','known-changed',9,'complete',True)]
states=[m.start_worker(bootstrap,plan)];check('literal post342 initial snapshot',projection(states[0])==expected[0])
for i in range(19):
 before=copy.deepcopy(states[-1]);r=m.reduce_worker(states[-1],event(i),assessment(i,states[-1]));states.append(r.state)
 check('literal worker prefix '+str(i),r.disposition=='model-advanced' and projection(r.state)==expected[i+1])
 check('input original bootstrap baseline traps and burned admission preserved '+str(i),states[-2]==before and r.state.bootstrap==bootstrap and r.state.core.baseline=='fresh-original' and r.state.core.traps and r.state.core.claim=='consumed' and r.state.core.launch=='spent')
 check('no native authority or readiness from model '+str(i),not r.authority and not r.native_evidence and not r.state.core.authority and not r.state.core.native_evidence)
 check('repeated immutable evaluation is equal data '+str(i),m.reduce_worker(states[i],event(i),assessment(i,states[i]))==r)
 check('valid unattempted adds no effects or attempt '+str(i),m.reduce_worker(states[i],event(i,'unattempted'),assessment(i,states[i]))==m.WorkerDecision(states[i],'model-unattempted','unattempted'))
 for outcome in ('known-failure','unknown'):
  failed=m.reduce_worker(states[i],event(i,outcome),assessment(i,states[i])).state
  check('failed or unknown observation stops permanently '+str(i)+'/'+outcome,failed.stopped and failed.completed==i and failed.core.forward=='stopped' and failed.core.first_failure==c.RawStatus('model-worker-'+str(i),-7 if outcome=='known-failure' else None) and not failed.ready_for_finalization)
  check('failure preserves completed microsteps original pin and raw prefix '+str(i)+'/'+outcome,failed.core.stage7_completed==states[i].core.stage7_completed and failed.core.pin==states[i].core.pin and failed.core.raw_statuses==states[i].core.raw_statuses+event(i,outcome).raw_statuses)
  for j in (0,5,6,12,14,15,16,17,18):
   replay=m.reduce_worker(failed,event(j),assessment(j,failed))
   check('stopped prefix cannot replay rebind overwrite or later call '+str(i)+'/'+outcome+'/'+str(j),replay.state==failed and replay.reason=='terminal-prefix')
 for name in [x.name for x in event(i).views]:
  r=m.reduce_worker(states[i],event(i,missing=name),assessment(i,states[i]))
  check('missing required source view stops '+str(i)+'/'+name,r.state.stopped and r.reason=='contradictory-positive-report')
 for field in ('same_original','guard_continuity','live_fence','fd_namespace_containment','complete_graph','full_effect_scope','no_forbidden_boot_optional_effects'):
  r=m.reduce_worker(states[i],event(i),dataclasses.replace(assessment(i,states[i]),**{field:'unobserved'}))
  check('unknown original guard fence containment graph scope stops '+str(i)+'/'+field,r.state.stopped and r.reason=='gate-loss')
 rights=tuple(c.RightReport(x.window,'revoked' if x.window=='forward' else x.status) for x in live)
 r=m.reduce_worker(states[i],event(i,'unattempted'),dataclasses.replace(assessment(i,states[i]),rights=rights))
 check('unattempted revocation stops without inventing attempt '+str(i),r.state.stopped and r.state.attempts==states[i].attempts and r.state.core.pin==states[i].core.pin)
 for j in (0,5,6,12,14,15,16,17,18):
  if i==j:continue
  r=m.reduce_worker(states[i],event(j),assessment(j,states[i]))
  check('source order and micro/nested order cannot be skipped '+str(i)+'/'+str(j),r.reason=='wrong-order' and r.state==states[i])
 r=m.reduce_worker(states[i],event(i,context=other),dataclasses.replace(assessment(i,states[i]),context=ctx))
 check('cross-original report leaves immutable prefix unchanged '+str(i),r.reason=='wrong-original' and r.state==states[i])
 r=m.reduce_worker(states[i],event(i,raw=(c.RawStatus('model-admission-0',0),)),assessment(i,states[i]))
 check('raw call cannot collide with original prefix '+str(i),r.reason=='duplicate-raw-call' and r.state==states[i])
# Independently specified phase and durable controls, beyond nominal payload presence.
controls=[(0,'original_capture_match'),(0,'owned_whitelist'),(0,'ancestor_alias_controls'),(1,'backups_verified'),(1,'original_capture_match'),(2,'predecessor_delta'),(2,'package_hooks_scope'),(3,'isolation_delta'),(5,'candidate_exact'),(6,'candidate_exact'),(7,'owned_whitelist'),(7,'ancestor_alias_controls'),(8,'exclusive_stage'),(8,'ancestor_alias_controls'),(9,'complete_bytes'),(10,'file_metadata_durable'),(11,'candidate_exact'),(12,'no_replace'),(12,'ancestor_alias_controls'),(13,'directory_storage_durable'),(14,'stage_exit_evidence'),(14,'file_metadata_durable'),(14,'directory_storage_durable')]
for i,field in controls:
 for status in ('reported-invalid','unobserved'):
  result=m.reduce_worker(states[i],event(i),dataclasses.replace(assessment(i,states[i]),**{field:status}))
  check('required phase or durable control cannot be skipped '+str(i)+'/'+field+'/'+status,result.state.stopped and not result.state.ready_for_finalization)
failed=m.reduce_worker(states[5],event(5,'unknown'),assessment(5)).state
for target in ('known-restored','verified-original'):
 check('failed worker cannot claim restored target '+target,rejects(dataclasses.replace,failed,core=dataclasses.replace(failed.core,target=target)))
for i in range(5,19):
 r=m.reduce_worker(states[i],event(i,substitute='raw-pkglist-pin-view'),assessment(i,states[i]))
 check('no raw pin substitution or logical rebind '+str(i),r.state.stopped)
for i in range(6,15):
 ev=dataclasses.replace(event(i),operation='phase-report');r=m.reduce_worker(states[i],ev,assessment(i,states[i]))
 check('aggregate phase7 cannot shortcut microstep '+str(i),r.reason=='wrong-order' and r.state==states[i])
for i in (4,15):
 for field in ('refresh_fresh_regular','refresh_nonempty','refresh_stdout_clean','refresh_stderr_clean'):
  r=m.reduce_worker(states[i],event(i),dataclasses.replace(assessment(i,states[i]),**{field:'reported-invalid'}))
  check('refresh exit0 does not waive stream object guards '+str(i)+'/'+field,r.state.stopped)
for i in range(15,19):
 for code in (None,-1,1,20,128,137,143):
  r=m.reduce_worker(states[i],event(i,raw=(c.RawStatus('model-nested-fault-'+str(i),code),)),assessment(i,states[i]))
  check('raw nested status rule '+str(i)+'/'+str(code),(r.disposition=='model-advanced')==(i==16 and code==20))
check('install-new raw20 preserved as20 not collapsed to0',states[17].install_raw==c.RawStatus('model-worker-16',20) and states[17].install_raw in states[17].core.raw_statuses)
r=m.reduce_worker(states[16],event(16),dataclasses.replace(assessment(16),install_new_no_effect='unobserved'))
check('raw20 requires independently known empty no-effect install-new',r.state.stopped and r.state.core.first_failure.code==20)
check('three successful nested calls do not complete whole successor',not states[18].ready_for_finalization and states[18].whole_view is None)
for field in ('whole_entry_equivalence','contained_runtime','contained_snapshots','package_hooks_scope','stage_exit_evidence'):
 r=m.reduce_worker(states[18],event(18),dataclasses.replace(assessment(18,states[18]),**{field:'unobserved'}))
 check('whole boundary separate required proof report '+field,r.state.stopped and not r.state.ready_for_finalization)
for name in ('contained-runtime-view','contained-snapshot-view','complete-effect-graph-view','whole-entry-result-view','nested-call-result-view'):
 r=m.reduce_worker(states[18],event(18,missing=name),assessment(18,states[18]))
 check('whole successor cannot be replaced by three nested calls '+name,r.state.stopped)
check('whole nested statuses cannot be self-laundered',m.reduce_worker(states[18],event(18),dataclasses.replace(assessment(18,states[18]),nested_statuses=())).state.stopped)
for field,new in [('install_new',('model-unrelated',)),('upgrade_all',()),('upgrade_all',('model-unrelated',)),('source_symbol','model-wrong-source'),('config_symbol','model-wrong-config'),('db_symbol','model-wrong-db'),('target_symbol','model-wrong-target')]:
 bad=dataclasses.replace(selector,**{field:new});r=m.reduce_worker(states[4],event(4),dataclasses.replace(assessment(4),selector=bad))
 check('full selector vector and original provenance bound '+field+'/'+repr(new),r.state.stopped)
check('duplicate selector vector members rejected',rejects(dataclasses.replace,selector,upgrade_all=('model-target','model-target')))
for index in range(8):
 badrow=tuple('model-wrong-field' if j==index else x for j,x in enumerate(row));bad=dataclasses.replace(candidate,row=badrow)
 check('candidate exact independent eight-field oracle '+str(index),m.reduce_worker(states[5],event(5),dataclasses.replace(assessment(5),candidate=bad)).state.stopped)
for field,new in [('archive_symbol','model-wrong-archive'),('pin',dataclasses.replace(candidate.pin,symbol='model-wrong-pin')),('predecessor',dataclasses.replace(candidate.predecessor,symbol='model-wrong-predecessor'))]:check('candidate original archive pin predecessor immutable '+field,m.reduce_worker(states[5],event(5),dataclasses.replace(assessment(5),candidate=dataclasses.replace(candidate,**{field:new}))).state.stopped)
for field,new in [('domains',graph.domains[:-1]),('relations',graph.relations[:-1]),('domains',tuple(reversed(graph.domains))),('relations',tuple(reversed(graph.relations)))]:check('all source graph declarations exact '+field+'/'+str(len(new)),rejects(dataclasses.replace,graph,**{field:new}))
check('phase type map immutable',rejects(lambda:m.REQUIRED_VIEWS.__setitem__('worker8-whole-successor-apply',())))
for field,new in [('baseline','uncertain'),('traps',False),('claim','known-unused'),('launch','unspent'),('spawn','unattempted'),('bootstrap','uncertain'),('children','drained'),('recovery_limit',1),('publication','record-reported')]:check('worker cannot rewrite original or advance recovery publication '+field,rejects(dataclasses.replace,states[10],core=dataclasses.replace(states[10].core,**{field:new})))
for i,change in [(0,{'completed':True}),(1,{'owned_view':None}),(2,{'backups_view':None}),(5,{'pin_view':None}),(6,{'candidate':None}),(13,{'binding_status':'complete'}),(14,{'binding_status':'complete'}),(18,{'ready_for_finalization':True}),(19,{'whole_view':None})]:check('impossible semantic prefix rejected '+str(i)+'/'+str(tuple(change)),rejects(dataclasses.replace,states[i],**change))
check('failed unknown binding remains uncertain without deleting original workspace',m.reduce_worker(states[12],event(12,'unknown'),assessment(12)).state.binding_status=='uncertain' and m.reduce_worker(states[12],event(12,'unknown'),assessment(12)).state.core.owned=='known-binding')
check('complete whole boundary is terminal for343',m.reduce_worker(states[19],event(18),assessment(18,states[19])).reason=='terminal-prefix')
full=dataclasses.replace(states[0],core=dataclasses.replace(states[0].core,raw_statuses=states[0].core.raw_statuses+tuple(c.RawStatus('model-cap-'+str(i),0) for i in range(4096-len(states[0].core.raw_statuses)))))
check('raw aggregate bounded before model advance',m.reduce_worker(full,event(0),assessment(0))==m.WorkerDecision(full,'model-rejected','resource-limit'))
for value in (graph,plan,selector,candidate,wa,states[0],m.WorkerDecision(states[0],'model-unattempted','unattempted')):
 check('record frozen '+type(value).__name__,rejects(setattr,value,'authority',True))
 for field in ('authority','native_evidence'):check('private record cannot supply native evidence '+type(value).__name__+'/'+field,rejects(dataclasses.replace,value,**{field:True}))
for phase,(actor,window,_) in c.PHASE_ROWS.items():
 if phase not in m.PHASES:check('unsupported nonworker phase '+phase,m.reduce_worker(states[0],c.ModelEvent(ctx,phase,actor,window,'unknown'),assessment(0)).reason=='unsupported-phase')
for argv in [[],['--bogus'],['--check'],['--check','']]:check('strict343 reviewer CLI '+repr(argv),run(['python3','-B',review_path,*argv]).returncode==2)
r=run(['python3','-B',review_path,'--check',root]);check('source-bound343 review entry',r.returncode==0 and 'step343_pure_worker_stages_review_status\tPASS' in r.stdout)
with tempfile.TemporaryDirectory(prefix='step343-accepted-source-') as directory:
 snapshot=Path(directory)/'accepted342';snapshot.mkdir()
 for relative,raw in history.items():
  p=snapshot/relative;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
 r=run(['python3','-B',snapshot/policy['predecessor_verifier'],'--check',snapshot]);check('unchanged342 reviewer reruns exact accepted source',r.returncode==0 and 'step342_pure_bootstrap_guard_review_status\tPASS' in r.stdout)
 previous=Path(policy['predecessor_verifier']).stem;r=run(['bash',snapshot/'tests/reference'/('test-'+previous+'-harness.sh')])
 if r.returncode:sys.stderr.write(r.stdout[-3000:]+r.stderr)
 check('unchanged342 full599 suite reruns successfully',r.returncode==0 and r.stdout.splitlines().count('Result: PASS (599 passes, 0 failures)')==1)
 check('all599 prior labels exact to accepted user return in order',[x for x in r.stdout.splitlines() if x.startswith('PASS: ')]==policy['accepted_ordered342_labels'])
check('all accepted source bytes unchanged after pure worker tests',review['verify'](root)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
