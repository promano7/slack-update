#!/bin/bash
set -euo pipefail
export LC_ALL=C
root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 -B - "$root" <<'PYTEST'
from pathlib import Path
import ast,copy,dataclasses,hashlib,json,subprocess,sys,tempfile,types
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1/';module_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer.py';review_path=root/'tools/reference'/(base+'.py');passes=0
core_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-transition-core.py';admission_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-admission-launch-reducer.py';bootstrap_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-bootstrap-guard-reducer.py';worker_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-worker-stages-reducer.py'
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
for label,path,digest in [('340 core',core_path,'94c8cc3dfdb0d813a6ec0d2f7c99e11f5866d8cf96b3ba53e852668eb9d03fb5'),('341 admission',admission_path,'1031e9e2099547def50ba1bdfb5fc8ff36fe94ef42540fbeef5c21509db72bed'),('342 bootstrap',bootstrap_path,'201636350a88c7562cad5cf04f71d5c582b7ea547c2e98b1f7a3751756b32e89'),('343 worker',worker_path,'2678499696ddc9293998dbcd5916aab29c028b045569ade416b38752629836a8'),('344 recovery',module_path,'8fa9dd38fd7affba5612f093667a118407fb8d8c96531943278b07180904af0a'),('344 reviewer',review_path,'1dfed0121e880d483dad79e447e1126bd34610b16c26ecd6b03ef32a757a1b00')]:check('exact SHA-pinned '+label,hashlib.sha256(path.read_bytes()).hexdigest()==digest)
c=module('slack_update_offline_core340',core_path);a=module('slack_update_offline_admission341',admission_path);b=module('slack_update_offline_bootstrap342',bootstrap_path);m=module('slack_update_offline_worker343',worker_path);rec=module('private344_recovery',module_path)
review={'__name__':'private344_review'};exec(compile(ast.parse(review_path.read_text()),str(review_path),'exec'),review)
history=review['verify'](root);mapping=load('-phase-map.json');contract=load('-contract.json');policy=load('-policy.json')
check('all1674 accepted343 bytes retained',len(history)==1674)
check('complete exact1255 user return accepted',review['validate_return'](load('-checkpoint-confirmation.json'),load('-step343-user-acceptance.json'),policy))
check('full source323326 guard baseline finite recovery contracts',review['validate_mapping'](mapping,contract,history))
tree=ast.parse(module_path.read_text());check('only pinned pure recovery imports',[(x.module,tuple(y.name for y in x.names)) for x in ast.walk(tree) if isinstance(x,ast.ImportFrom)]==[('dataclasses',('dataclass','fields','replace')),('types',('MappingProxyType',)),('slack_update_offline_core340',('ModelContext','ModelView','RightReport','RawStatus','CoreState','ModelEvent','RIGHTS_WINDOWS','MAX_RAW_STATUSES')),('slack_update_offline_worker343',('WorkerState',))] and not any(isinstance(x,ast.Import) for x in ast.walk(tree)))
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
worker_mapping=json.loads((fixture/('phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-worker-stages-reducer-review'+'-phase-map.json')).read_bytes())
graph=m.GraphReport(ctx,views['complete-effect-graph-view'],'model-whole-entry',tuple(worker_mapping['original_designed_domains']),tuple(tuple(x) for x in worker_mapping['original_macro_relations']))
row=('model-target','model-version','model-architecture','model-build','model-repository','model-location','model-source-row','model-filter-row');plan=m.WorkerPlan(ctx,graph,'model-target','model-archive',row)
selector=m.SelectorReport(ctx,views['raw-pkglist-pin-view'],admission.source_view.symbol,views['isolated-config-view'].symbol,views['exact-predecessor-view'].symbol,'model-backend-version','model-selector-version','model-blacklist','model-priority','model-repository','model-architecture','model-filter','model-target',(),('model-target',))
candidate=m.CandidateReport(ctx,views['raw-pkglist-pin-view'],admission.source_view,views['exact-predecessor-view'],'model-archive',row)
wa=m.WorkerAssessment(ctx,live,graph,selector,candidate,**{k:'reported-valid' for k in m.COMMON_REPORTS+m.STAGE_REPORTS})
phases=['worker2-owned-workspace','worker3-original-backups','worker4-exact-predecessor','worker5-local-isolation','worker6-refresh-pin-once','worker7-validate-pinned-candidate']
micro=['validate-exact-inputs','register-owned-intent','create-exclusive-stage','write-complete-bytes','metadata-and-data-durable','revalidate-pinned-inputs','commit-no-replace','directory-durability-confirmed','stage-exit-evidence-complete']
steps=[(p,'phase-report','none') for p in phases]+[('worker7-owned-durable-commit',x,'none') for x in micro]+[('worker8-whole-successor-apply','phase-report',x) for x in ('nested-update','nested-install-new','nested-upgrade-all','whole-entry-complete')]
check('unchanged343 source19-observation setup',tuple(steps)==m.SEQUENCE)
check('full original30 domains95 macro pairs retained',len(graph.domains)==30 and len(graph.relations)==95 and graph.domains==m.DOMAIN_IDS and graph.relations==m.MACRO_RELATIONS)
def event(i,outcome='known-success',missing=None,raw=None,substitute=None,context=ctx):
 phase,operation,_=steps[i];names=list(worker_mapping['required_positive_views'][phase])
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
workers=[m.start_worker(bootstrap,plan)]
for i in range(19):workers.append(m.reduce_worker(workers[-1],event(i),assessment(i,workers[-1])).state)
check('unchanged343 full worker prepared for finalization',workers[-1].ready_for_finalization and workers[-1].core.target=='known-changed')
recovery_plan=rec.RecoveryPlan(ctx,8,100,'model-original-scope',views['recovery-budget-view'])
ra=rec.RecoveryAssessment(ctx,live,'effect-report',recovery_plan.budget_view,recovery_plan.original_scope_symbol,elapsed_milliseconds=37,**{k:'reported-valid' for k in rec.COMMON_REPORTS+rec.ACTION_REPORTS})
backed=[('stop-forward-irreversibly','effect-report'),('drain-known-owned-children','spend-budget'),('drain-known-owned-children','effect-report'),('worker9-original-restoration','spend-budget'),('worker9-original-restoration','effect-report'),('worker10-original-verification','spend-budget'),('worker10-original-verification','effect-report')]
unchanged=[backed[0],backed[1],backed[2],backed[5],backed[6]]
def rev(i,seq=backed,outcome='known-success',missing=None,substitute=None,raw=None,context=ctx):
 phase,operation=seq[i];names=list(mapping['budget_positive_views' if operation=='spend-budget' else 'effect_positive_views'][phase])
 if missing is not None:names.remove(missing)
 vv=tuple(dataclasses.replace(views[k],context=context,**({'symbol':'model-wrong-view'} if k==substitute else {})) for k in names) if outcome=='known-success' else ()
 if raw is None:raw=() if outcome=='unattempted' else (c.RawStatus('model-recovery-'+str(i),0 if outcome=='known-success' else -9 if outcome=='known-failure' else None),)
 actor,window,_=c.PHASE_ROWS[phase];return c.ModelEvent(context,phase,actor,window,outcome,'phase-report',vv,raw)
def ras(i,seq=backed):return dataclasses.replace(ra,operation=seq[i][1])
def proj(s):return (s.completed,s.core.recovery_spent,s.core.children,s.core.target,s.reserved_phase,s.ready_for_target_evidence)
expected=[(0,0,'known-owned','known-changed',None,False),(1,0,'known-owned','known-changed',None,False),(2,1,'known-owned','known-changed','drain-known-owned-children',False),(3,1,'drained','known-changed',None,False),(4,2,'drained','known-changed','worker9-original-restoration',False),(5,2,'drained','known-restored',None,False),(6,3,'drained','known-restored','worker10-original-verification',False),(7,3,'drained','verified-original',None,True)]
states=[rec.start_recovery(workers[-1],recovery_plan)]
check('literal initial finalization forward permanently stopped',proj(states[0])==expected[0] and states[0].core.forward=='stopped' and workers[-1].core.forward=='active')
for i in range(7):
 before=copy.deepcopy(states[-1]);q=rec.reduce_recovery(states[-1],rev(i),ras(i));states.append(q.state)
 check('literal recovery snapshot '+str(i),q.disposition=='model-advanced' and proj(q.state)==expected[i+1])
 check('immutable retained prefix '+str(i),states[-2]==before and q.state.prefix==workers[-1] and q.state.core.forward=='stopped')
 check('budget admission launch original source data retained '+str(i),q.state.core.claim=='consumed' and q.state.core.launch=='spent' and q.state.core.pin==workers[-1].core.pin and q.state.core.backups=='verified-original' and q.state.core.owned==workers[-1].core.owned)
check('target verified but guard not released and publication unattempted',states[-1].core.guard=='continuous' and states[-1].core.publication=='unattempted' and states[-1].core.phase=='worker10-original-verification')
check('target verification does not assert native evidence authority or host closure',not states[-1].native_evidence and not states[-1].authority and not contract['actual_global_host_closure_asserted'])
check('complete recovery rejects repetition',rec.reduce_recovery(states[-1],rev(6),ras(6)).reason=='terminal-prefix')
check('pure duplicate evaluation is equality only not native once',rec.reduce_recovery(states[0],rev(0),ras(0))==rec.reduce_recovery(states[0],rev(0),ras(0)))
for i in range(7):
 for outcome in ('known-failure','unknown','unattempted'):
  q=rec.reduce_recovery(states[i],rev(i,outcome=outcome),ras(i));s=q.state
  if outcome=='unattempted':check('unattempted leaves trace and budget unchanged '+str(i),s==states[i] and q.disposition=='model-unattempted');continue
  cost=states[i].core.recovery_spent+(backed[i][1]=='spend-budget')
  check('failed or unknown exact budget no refund '+str(i)+'/'+outcome,s.halted and s.core.recovery_spent==cost and not s.ready_for_target_evidence and s.core.forward=='stopped')
  check('raw failure separate and exact '+str(i)+'/'+outcome,s.recovery_failure==rev(i,outcome=outcome).raw_statuses[0] and s.core.raw_statuses==states[i].core.raw_statuses+rev(i,outcome=outcome).raw_statuses)
  check('halted trace cannot retry spend or action '+str(i)+'/'+outcome,rec.reduce_recovery(s,rev(i),ras(i)).state==s and rec.reduce_recovery(s,rev(i),ras(i)).reason=='terminal-prefix')
  if outcome=='unknown' and backed[i][1]=='spend-budget':check('unknown durable spend never yields effect reservation '+str(i),s.reserved_phase is None and s.core.target==states[i].core.target and s.core.children==states[i].core.children)
  if outcome=='unknown' and i==2:check('unknown drain blocks target restoration',s.core.children=='uncertain' and s.restoration_view is None)
  if outcome=='unknown' and i in (4,6):check('unknown target operation cannot imply restored original '+str(i),s.core.target=='uncertain')
 for code in (None,-1,1,20,128,137,143):
  q=rec.reduce_recovery(states[i],rev(i,raw=(c.RawStatus('model-bad-raw',code),)),ras(i))
  check('positive recovery cannot launder raw status '+str(i)+'/'+str(code),q.state.halted and q.reason=='contradictory-positive-report' and q.state.recovery_failure.code==code)
 for j in range(7):
  if i==j:continue
  q=rec.reduce_recovery(states[i],rev(j),ras(j));check('spend effect source ordering '+str(i)+'/'+str(j),q.reason=='wrong-order' and q.state==states[i])
 q=rec.reduce_recovery(states[i],rev(i,context=other),ras(i));check('wrong original cannot spend '+str(i),q.reason=='wrong-original' and q.state==states[i])
 q=rec.reduce_recovery(states[i],rev(i),dataclasses.replace(ras(i),context=other,budget_view=dataclasses.replace(ra.budget_view,context=other)));check('wrong assessment original cannot spend '+str(i),q.reason=='wrong-original' and q.state==states[i])
 q=rec.reduce_recovery(states[i],rev(i,raw=(c.RawStatus('model-admission-0',0),)),ras(i));check('duplicate original raw call rejected '+str(i),q.reason=='duplicate-raw-call' and q.state==states[i])
 names=mapping['budget_positive_views' if backed[i][1]=='spend-budget' else 'effect_positive_views'][backed[i][0]]
 for name in names:
  q=rec.reduce_recovery(states[i],rev(i,missing=name),ras(i));check('all recovery nominal inputs and outputs required '+str(i)+'/'+name,q.state.halted and q.reason=='contradictory-positive-report')
  if name not in ('quiescent-child-view','original-restoration-result-view','original-verification-view','package-effect-result-view') or (name=='quiescent-child-view' and i>2):
   q=rec.reduce_recovery(states[i],rev(i,substitute=name),ras(i));check('stored original recovery view cannot substitute '+str(i)+'/'+name,q.state.halted)
 for field in rec.COMMON_REPORTS:
  for status in ('reported-invalid','unobserved'):
   q=rec.reduce_recovery(states[i],rev(i),dataclasses.replace(ras(i),**{field:status}))
   check('recovery gate denial preserves budget and target '+str(i)+'/'+field+'/'+status,q.state.halted and q.reason=='gate-loss' and q.state.core.recovery_spent==states[i].core.recovery_spent and q.state.core.target==states[i].core.target)
 if i:
  for status in ('inactive','expired','revoked','uncertain'):
   rights=tuple(c.RightReport(x.window,status if x.window=='recovery' else x.status) for x in live)
   q=rec.reduce_recovery(states[i],rev(i),dataclasses.replace(ras(i),rights=rights));check('original recovery rights denied no new spend '+str(i)+'/'+status,q.state.halted and q.state.core.recovery_spent==states[i].core.recovery_spent)
  for elapsed in (None,100,101,2147483647):
   q=rec.reduce_recovery(states[i],rev(i),dataclasses.replace(ras(i),elapsed_milliseconds=elapsed));check('strict finite deadline boundary '+str(i)+'/'+str(elapsed),q.reason=='gate-loss' and q.state.core.recovery_spent==states[i].core.recovery_spent)
  for elapsed in (0,99):check('inside original finite deadline '+str(i)+'/'+str(elapsed),rec.reduce_recovery(states[i],rev(i),dataclasses.replace(ras(i),elapsed_milliseconds=elapsed)).disposition=='model-advanced')
  for field,val in [('original_scope_symbol','model-other-scope'),('budget_view',dataclasses.replace(ra.budget_view,symbol='model-other-budget'))]:check('same retained original scope and budget '+str(i)+'/'+field,rec.reduce_recovery(states[i],rev(i),dataclasses.replace(ras(i),**{field:val})).reason=='gate-loss')
for i,field in [(1,'budget_durable'),(2,'quiescence_known'),(3,'budget_durable'),(4,'restoration_exact'),(5,'budget_durable'),(6,'full_original_invariants')]:
 for status in ('reported-invalid','unobserved'):check('phase-specific positive recovery assumption '+str(i)+'/'+field+'/'+status,rec.reduce_recovery(states[i],rev(i),dataclasses.replace(ras(i),**{field:status})).state.halted)
for i in (3,4):check('verified original backup required before restoration '+str(i),rec.reduce_recovery(states[i],rev(i),dataclasses.replace(ras(i),backups_verified='unobserved')).reason=='gate-loss')
# Literal budget oracle: stop cost0, drain/restore/verify cost1 each, no refund.
for budget in range(9):
 s=rec.start_recovery(workers[-1],dataclasses.replace(recovery_plan,budget_limit=budget))
 for i in range(7):
  before=s;q=rec.reduce_recovery(s,rev(i),ras(i));s=q.state
  if q.reason=='budget-exhausted':
   check('budget exhaustion consumes no phantom action '+str(budget),s.core.recovery_spent==budget and s.attempts==before.attempts and s.core.raw_statuses==before.core.raw_statuses);break
 check('finite budget literal result '+str(budget),s.ready_for_target_evidence==(budget>=3) and s.core.recovery_spent==min(budget,3))
for original_status in (None,-7,0,137):
 failing=m.reduce_worker(workers[6],event(6,'unknown' if original_status is None else 'known-failure',raw=(c.RawStatus('model-original-first',original_status),)),assessment(6)).state
 s=rec.start_recovery(failing,recovery_plan)
 for i in range(7):s=rec.reduce_recovery(s,rev(i),ras(i)).state
 check('safe restoration keeps exact original failure '+str(original_status),s.ready_for_target_evidence and s.prefix.stopped and not s.prefix.ready_for_finalization and s.core.first_failure==failing.core.first_failure and s.binding_pending==(original_status is None))
 q=rec.reduce_recovery(rec.start_recovery(failing,recovery_plan),rev(0,outcome='known-failure'),ras(0))
 check('recovery failure separate from sticky original '+str(original_status),q.state.core.first_failure==failing.core.first_failure and q.state.recovery_failure==c.RawStatus('model-recovery-0',-9))
# No never-created backups or restoration writes in unchanged branch.
for rank in (0,1,2):
 s=rec.start_recovery(workers[rank],recovery_plan);check('unchanged branch selected before target mutation '+str(rank),s.branch=='verify-unchanged')
 for i in range(5):s=rec.reduce_recovery(s,rev(i,unchanged),ras(i,unchanged)).state
 check('independent original verification without restoration '+str(rank),s.ready_for_target_evidence and s.restoration_view is None and s.core.target=='verified-original' and s.core.recovery_spent==2 and s.core.backups==workers[rank].core.backups)
 nochange=rec.start_recovery(workers[rank],recovery_plan)
 for i in range(4):nochange=rec.reduce_recovery(nochange,rev(i,unchanged),ras(i,unchanged)).state
 for field in ('target_known_unchanged','full_original_invariants'):
  check('unchanged verify requires independent fresh original '+str(rank)+'/'+field,rec.reduce_recovery(nochange,rev(4,unchanged),dataclasses.replace(ras(4,unchanged),**{field:'unobserved'})).state.halted)
check('early admission cannot acquire recovery guard',rejects(rec.start_recovery,admission,recovery_plan))
check('early bootstrap cannot acquire recovery guard',rejects(rec.start_recovery,bootstrap,recovery_plan))
for rank in (0,2,3,4,15):
 fail=m.reduce_worker(workers[rank],event(rank,'unknown'),assessment(rank,workers[rank])).state;s=rec.start_recovery(fail,recovery_plan)
 check('unknown target stays blocked '+str(rank),s.branch=='blocked' and s.core.target=='uncertain')
 for i in range(3):s=rec.reduce_recovery(s,rev(i),ras(i)).state
 check('blocked target never restored after known drain '+str(rank),not s.ready_for_target_evidence and s.core.target=='uncertain' and rec.reduce_recovery(s,rev(3),ras(3)).reason=='terminal-prefix')
for rank in (1,5,12):
 fail=m.reduce_worker(workers[rank],event(rank),dataclasses.replace(assessment(rank,workers[rank]),guard_continuity='reported-invalid')).state;s=rec.start_recovery(fail,recovery_plan)
 check('lost original guard branch blocked '+str(rank),s.branch=='blocked' and s.core.guard=='lost')
 s=rec.reduce_recovery(s,rev(0),ras(0)).state;q=rec.reduce_recovery(s,rev(1),ras(1));check('recovery cannot reacquire lost guard '+str(rank),q.reason=='gate-loss' and q.state.core.guard=='lost' and q.state.core.recovery_spent==0)
# Stop remains a barrier after rights expiry; unsafe identity/clock reports halt pending.
for field in ('safe_boot','same_original','trusted_time','guard_continuity'):
 q=rec.reduce_recovery(states[0],rev(0),dataclasses.replace(ras(0),**{field:'unobserved'}));check('stop observation cannot forget prior unsafe original '+field,q.state.halted and rec.reduce_recovery(q.state,rev(1),ras(1)).reason=='terminal-prefix')
expired=tuple(c.RightReport(x.window,'expired') for x in live)
check('stop barrier can be retained with all rights expired',rec.reduce_recovery(states[0],rev(0),dataclasses.replace(ras(0),rights=expired,elapsed_milliseconds=None)).disposition=='model-advanced')
rights=tuple(c.RightReport(x.window,'expired' if x.window=='forward' else x.status) for x in live)
s=rec.start_recovery(workers[-1],recovery_plan)
for i in range(7):s=rec.reduce_recovery(s,rev(i),dataclasses.replace(ras(i),rights=rights)).state
check('forward expiry does not waive independent retained recovery controls',s.ready_for_target_evidence and s.core.forward=='stopped' and s.core.recovery_spent==3)
q=rec.reduce_recovery(states[2],rev(2),dataclasses.replace(ras(2),rights=tuple(c.RightReport(x.window,'revoked' if x.window=='recovery' else x.status) for x in live)))
check('late revocation after durable reservation has no refund or effect',q.state.halted and q.state.core.recovery_spent==1 and q.state.core.children=='known-owned' and q.state.reserved_phase is None)
for i,changes in [(0,{'completed':True}),(0,{'branch':'verify-unchanged'}),(0,{'ready_for_target_evidence':True}),(0,{'reserved_phase':rec.PHASES[1]}),(0,{'binding_pending':True}),(2,{'reserved_phase':None}),(3,{'quiescent_view':None}),(5,{'restoration_view':None}),(7,{'verification_view':None})]:check('impossible recovery prefix rejected '+str(i)+'/'+str(tuple(changes)),rejects(dataclasses.replace,states[i],**changes))
for i in range(8):
 for field,value in [('forward','active'),('claim','known-unused'),('launch','unspent'),('bootstrap','uncertain'),('traps',False),('baseline','uncertain'),('backups','unobserved'),('pin','model-rebound-pin'),('stage7_completed',0),('owned','known-none'),('publication','record-reported'),('recovery_limit',7),('recovery_spent',8)]:check('immutable original or budget cannot reset '+str(i)+'/'+field,rejects(dataclasses.replace,states[i],core=dataclasses.replace(states[i].core,**{field:value})))
 if i<7:check('no forged original verification '+str(i),rejects(dataclasses.replace,states[i],core=dataclasses.replace(states[i].core,target='verified-original')))
check('recovery type maps immutable',rejects(lambda:rec.EFFECT_VIEWS.__setitem__(rec.PHASES[0],())))
full=dataclasses.replace(states[0],core=dataclasses.replace(states[0].core,raw_statuses=states[0].core.raw_statuses+tuple(c.RawStatus('model-cap-'+str(i),0) for i in range(4096-len(states[0].core.raw_statuses)))))
check('raw report aggregate remains bounded',rec.reduce_recovery(full,rev(0),ras(0)).reason=='resource-limit')
for field,values in [('budget_limit',(True,-1,9,1.0)),('deadline_milliseconds',(True,0,-1,2147483648,1.0)),('original_scope_symbol',('', 'ordinary-native-scope')),('budget_view',(None,views['original-baseline-view']))]:
 for value in values:check('strict immutable finite plan '+field+'/'+repr(value),rejects(dataclasses.replace,recovery_plan,**{field:value}))
for field,values in [('elapsed_milliseconds',(True,-1,1.0,2147483648)),('operation',('restore','')),('same_original',(True,'valid')),('rights',(list(live),live[:-1]))]:
 for value in values:check('strict assessment shape '+field+'/'+repr(value),rejects(dataclasses.replace,ra,**{field:value}))
for value in (recovery_plan,ra,states[0],rec.RecoveryDecision(states[0],'model-unattempted','unattempted')):
 check('record frozen '+type(value).__name__,rejects(setattr,value,'authority',True))
 for field in ('authority','native_evidence'):check('private record cannot supply native evidence '+type(value).__name__+'/'+field,rejects(dataclasses.replace,value,**{field:True}))
for phase,(actor,window,_) in c.PHASE_ROWS.items():
 if phase not in rec.PHASES:check('unsupported nonrecovery phase '+phase,rec.reduce_recovery(states[0],c.ModelEvent(ctx,phase,actor,window,'unknown'),ras(0)).reason=='unsupported-phase')
for argv in [[],['--bogus'],['--check'],['--check','']]:check('strict344 reviewer CLI '+repr(argv),run(['python3','-B',review_path,*argv]).returncode==2)
q=run(['python3','-B',review_path,'--check',root]);check('source-bound344 review entry',q.returncode==0 and 'step344_pure_retained_recovery_review_status\tPASS' in q.stdout)
with tempfile.TemporaryDirectory(prefix='step344-accepted-source-') as directory:
 snapshot=Path(directory)/'accepted343';snapshot.mkdir()
 for relative,raw in history.items():
  p=snapshot/relative;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
 q=run(['python3','-B',snapshot/policy['predecessor_verifier'],'--check',snapshot]);check('unchanged343 reviewer reruns exact accepted source',q.returncode==0 and 'step343_pure_worker_stages_review_status\tPASS' in q.stdout)
 previous=Path(policy['predecessor_verifier']).stem;q=run(['bash',snapshot/'tests/reference'/('test-'+previous+'-harness.sh')])
 if q.returncode:sys.stderr.write(q.stdout[-3000:]+q.stderr)
 check('unchanged343 full1255 suite reruns successfully',q.returncode==0 and q.stdout.splitlines().count('Result: PASS (1255 passes, 0 failures)')==1)
 check('all1255 prior labels exact to accepted user return in order',[x for x in q.stdout.splitlines() if x.startswith('PASS: ')]==policy['accepted_ordered343_labels'])
check('all accepted source bytes unchanged after pure recovery tests',review['verify'](root)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
