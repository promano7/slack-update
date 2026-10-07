#!/bin/bash
set -euo pipefail
export LC_ALL=C
root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 -B - "$root" <<'PYTEST'
from pathlib import Path
import ast,copy,dataclasses,hashlib,json,subprocess,sys,tempfile,types
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-target-publication-reducer-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1/';module_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-target-publication-reducer.py';recovery_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer.py';review_path=root/'tools/reference'/(base+'.py');passes=0
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
for label,path,digest in [('340 core',core_path,'94c8cc3dfdb0d813a6ec0d2f7c99e11f5866d8cf96b3ba53e852668eb9d03fb5'),('341 admission',admission_path,'1031e9e2099547def50ba1bdfb5fc8ff36fe94ef42540fbeef5c21509db72bed'),('342 bootstrap',bootstrap_path,'201636350a88c7562cad5cf04f71d5c582b7ea547c2e98b1f7a3751756b32e89'),('343 worker',worker_path,'2678499696ddc9293998dbcd5916aab29c028b045569ade416b38752629836a8'),('344 recovery',recovery_path,'8fa9dd38fd7affba5612f093667a118407fb8d8c96531943278b07180904af0a'),('345 finalization',module_path,'22fc51ade0c3a213b004b5b90a79fa7f9c5b2c2125748afbcf61b84aac369954'),('345 reviewer',review_path,'40760690c3b9c6b548fe1cac9d071d4441d246ee3afaca154bf0b055c6cfb8b4')]:check('exact SHA-pinned '+label,hashlib.sha256(path.read_bytes()).hexdigest()==digest)
c=module('slack_update_offline_core340',core_path);a=module('slack_update_offline_admission341',admission_path);b=module('slack_update_offline_bootstrap342',bootstrap_path);m=module('slack_update_offline_worker343',worker_path);rec=module('slack_update_offline_recovery344',recovery_path);fin=module('private345_finalization',module_path)
review={'__name__':'private345_review'};exec(compile(ast.parse(review_path.read_text()),str(review_path),'exec'),review)
history=review['verify'](root);mapping=load('-phase-map.json');contract=load('-contract.json');policy=load('-policy.json')
check('all1683 accepted344 bytes retained',len(history)==1683)
check('complete exact881 user return accepted',review['validate_return'](load('-checkpoint-confirmation.json'),load('-step344-user-acceptance.json'),policy))
check('full source323327 target publication contracts',review['validate_mapping'](mapping,contract,history))
tree=ast.parse(module_path.read_text());check('only pinned pure finalization imports',[(x.module,tuple(y.name for y in x.names)) for x in ast.walk(tree) if isinstance(x,ast.ImportFrom)]==[('dataclasses',('dataclass','fields','replace')),('types',('MappingProxyType',)),('slack_update_offline_core340',('ModelContext','ModelView','RightReport','RawStatus','CoreState','ModelEvent','RIGHTS_WINDOWS','MAX_RAW_STATUSES')),('slack_update_offline_recovery344',('RecoveryState',))] and not any(isinstance(x,ast.Import) for x in ast.walk(tree)))
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
recovery_mapping=json.loads((fixture/('phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer-review'+'-phase-map.json')).read_bytes())
workers=[m.start_worker(bootstrap,plan)]
for i in range(19):workers.append(m.reduce_worker(workers[-1],event(i),assessment(i,workers[-1])).state)
check('unchanged343 full worker prepared for finalization',workers[-1].ready_for_finalization and workers[-1].core.target=='known-changed')
recovery_plan=rec.RecoveryPlan(ctx,8,100,'model-original-scope',views['recovery-budget-view'])
ra=rec.RecoveryAssessment(ctx,live,'effect-report',recovery_plan.budget_view,recovery_plan.original_scope_symbol,elapsed_milliseconds=37,**{k:'reported-valid' for k in rec.COMMON_REPORTS+rec.ACTION_REPORTS})
backed=[('stop-forward-irreversibly','effect-report'),('drain-known-owned-children','spend-budget'),('drain-known-owned-children','effect-report'),('worker9-original-restoration','spend-budget'),('worker9-original-restoration','effect-report'),('worker10-original-verification','spend-budget'),('worker10-original-verification','effect-report')]
unchanged=[backed[0],backed[1],backed[2],backed[5],backed[6]]
def rev(i,seq=backed,outcome='known-success',missing=None,substitute=None,raw=None,context=ctx):
 phase,operation=seq[i];names=list(recovery_mapping['budget_positive_views' if operation=='spend-budget' else 'effect_positive_views'][phase])
 if missing is not None:names.remove(missing)
 vv=tuple(dataclasses.replace(views[k],context=context,**({'symbol':'model-wrong-view'} if k==substitute else {})) for k in names) if outcome=='known-success' else ()
 if raw is None:raw=() if outcome=='unattempted' else (c.RawStatus('model-recovery-'+str(i),0 if outcome=='known-success' else -9 if outcome=='known-failure' else None),)
 actor,window,_=c.PHASE_ROWS[phase];return c.ModelEvent(context,phase,actor,window,outcome,'phase-report',vv,raw)
def ras(i,seq=backed):return dataclasses.replace(ra,operation=seq[i][1])
def proj(s):return (s.completed,s.core.recovery_spent,s.core.children,s.core.target,s.reserved_phase,s.ready_for_target_evidence)
recovered=[rec.start_recovery(workers[-1],recovery_plan)]
for i in range(7):recovered.append(rec.reduce_recovery(recovered[-1],rev(i),ras(i)).state)
check('unchanged344 verified original with original budget3 of8',recovered[-1].ready_for_target_evidence and recovered[-1].core.recovery_spent==3)
fp=fin.FinalizationPlan(ctx,'model-recipient','model-captured-content',views['publication-record-view'].symbol,views['last-receipt-origin-view'].symbol,'model-handoff','model-publication-scope',120)
fa=fin.FinalizationAssessment(ctx,live,'effect-report',recovery_plan.budget_view,recovery_plan.original_scope_symbol,fp.publication_scope_symbol,fp.recipient_symbol,fp.content_symbol,fp.record_symbol,fp.receipt_origin_symbol,fp.handoff_symbol,recovery_elapsed_milliseconds=37,publication_elapsed_milliseconds=51,**{k:'reported-valid' for k in dict.fromkeys(fin.COMMON_REPORTS+fin.RECOVERY_REPORTS+fin.PUBLICATION_REPORTS+fin.ACTION_REPORTS)})
sequence=[('worker11-close-target-evidence','spend-budget'),('worker11-close-target-evidence','effect-report'),('release-target-control','spend-budget'),('release-target-control','effect-report'),('worker12-publication-controls','effect-report'),('worker12-publication-record','effect-report'),('worker12-last-receipt','effect-report'),('worker12-durable-handoff','effect-report')]
check('literal eight closure publication observations',tuple(sequence)==fin.SEQUENCE)
def fev(i,outcome='known-success',missing=None,substitute=None,raw=None,context=ctx):
 phase,operation=sequence[i];names=list(mapping['budget_positive_views' if operation=='spend-budget' else 'effect_positive_views'][phase])
 if missing is not None:names.remove(missing)
 vv=tuple(dataclasses.replace(views[k],context=context,**({'symbol':'model-substituted-view'} if k==substitute else {})) for k in names) if outcome=='known-success' else ()
 if raw is None:raw=() if outcome=='unattempted' else (c.RawStatus('model-finalization-'+str(i),0 if outcome=='known-success' else -11 if outcome=='known-failure' else None),)
 actor,window,_=c.PHASE_ROWS[phase];return c.ModelEvent(context,phase,actor,window,outcome,'phase-report',vv,raw)
def fas(i,s):return dataclasses.replace(fa,operation=sequence[i][1],captured=s.captured,receipt_record_view=s.record_view)
def project(s):return (s.completed,s.core.recovery_spent,s.target_control,s.core.guard,s.core.target,s.core.publication,s.handoff_complete)
expected=[(0,3,'held','continuous','verified-original','unattempted',False),(1,4,'held','continuous','verified-original','unattempted',False),(2,4,'held','continuous','verified-original','unattempted',False),(3,5,'held','continuous','verified-original','unattempted',False),(4,5,'reported-released','unobserved','unobserved','unattempted',False),(5,5,'reported-released','unobserved','unobserved','controls-reported',False),(6,5,'reported-released','unobserved','unobserved','record-reported',False),(7,5,'reported-released','unobserved','unobserved','receipt-reported',False),(8,5,'reported-released','unobserved','unobserved','handoff-reported',True)]
states=[fin.start_finalization(recovered[-1],fp)];check('literal initial verified target held',project(states[0])==expected[0])
for i in range(8):
 before=copy.deepcopy(states[-1]);q=fin.reduce_finalization(states[-1],fev(i),fas(i,states[-1]));states.append(q.state)
 check('literal finalization snapshot '+str(i),q.disposition=='model-advanced' and project(q.state)==expected[i+1])
 check('original verified prefix immutable '+str(i),states[-2]==before and q.state.prefix==recovered[-1] and q.state.core.forward=='stopped')
 check('no original grant pin or budget limit renewal '+str(i),q.state.core.claim=='consumed' and q.state.core.launch=='spent' and q.state.core.pin==workers[-1].core.pin and q.state.core.recovery_limit==8)
check('release stops current guard and target claims but preserves captured original',states[4].core.target=='unobserved' and states[4].core.guard=='unobserved' and states[4].captured.original_verification==recovered[-1].verification_view)
check('original captured failure outcome vector budget immutable',states[-1].captured.original_failure is None and states[-1].captured.original_forward_complete and states[-1].captured.original_raw==recovered[-1].core.raw_statuses and states[-1].captured.recovery_spent_at_capture==4 and states[-1].captured.captured_raw==states[2].core.raw_statuses)
check('record does not imply receipt or handoff',states[6].record_view is not None and states[6].receipt_view is None and not states[6].handoff_complete)
check('receipt does not imply durable handoff',states[7].receipt_view is not None and not states[7].handoff_complete)
check('no pair atomicity or actual host closure',not contract['actual_pair_atomicity_claimed'] and not contract['actual_global_host_closure_asserted'] and not states[-1].native_evidence and not states[-1].authority)
check('handoff complete rejects replay',fin.reduce_finalization(states[-1],fev(7),fas(7,states[-1])).reason=='terminal-prefix')
check('model duplicate evaluation not native once',fin.reduce_finalization(states[0],fev(0),fas(0,states[0]))==fin.reduce_finalization(states[0],fev(0),fas(0,states[0])))
for i in range(8):
 for outcome in ('known-failure','unknown','unattempted'):
  q=fin.reduce_finalization(states[i],fev(i,outcome),fas(i,states[i]));s=q.state
  if outcome=='unattempted':check('unattempted budget trace outputs unchanged '+str(i),s==states[i] and q.disposition=='model-unattempted');continue
  cost=states[i].core.recovery_spent+(sequence[i][1]=='spend-budget')
  check('unknown failure exact old budget no refill refund '+str(i)+'/'+outcome,s.halted and s.core.recovery_spent==cost and not s.handoff_complete)
  check('exact raw and sticky finalization failure '+str(i)+'/'+outcome,s.finalization_failure==fev(i,outcome).raw_statuses[0] and s.core.raw_statuses==states[i].core.raw_statuses+fev(i,outcome).raw_statuses)
  check('no retry republish target reacquire '+str(i)+'/'+outcome,fin.reduce_finalization(s,fev(i),fas(i,s)).reason=='terminal-prefix' and fin.reduce_finalization(s,fev(0),fas(0,s)).state==s)
  check('all prior outputs artifacts retained '+str(i)+'/'+outcome,s.captured==states[i].captured and s.release_view==states[i].release_view and s.record_view==states[i].record_view and s.receipt_view==states[i].receipt_view)
  if i>=4:check('publication failure separate captured target unaffected '+str(i)+'/'+outcome,s.publication_failure==s.finalization_failure and s.core.publication=='uncertain' and s.core.target=='unobserved' and s.core.guard=='unobserved')
  if outcome=='unknown' and i==3:check('unknown release never claims held or known released',s.target_control=='uncertain' and s.release_view is None and s.core.guard=='uncertain' and s.core.target=='uncertain')
  if outcome=='unknown' and i==1:check('unknown target capture cannot close evidence',s.captured is None and s.target_control=='held')
 for code in (None,-1,1,20,128,137,143):
  q=fin.reduce_finalization(states[i],fev(i,raw=(c.RawStatus('model-bad-finalization',code),)),fas(i,states[i]));check('positive cannot launder raw closure publication '+str(i)+'/'+str(code),q.state.halted and q.reason=='contradictory-positive-report' and q.state.finalization_failure.code==code)
 for j in range(8):
  if i==j:continue
  q=fin.reduce_finalization(states[i],fev(j),fas(j,states[i]));check('source spend record receipt handoff order '+str(i)+'/'+str(j),q.reason=='wrong-order' and q.state==states[i])
 q=fin.reduce_finalization(states[i],fev(i,context=other),fas(i,states[i]));check('cross original event leaves status budget unchanged '+str(i),q.reason=='wrong-original' and q.state==states[i])
 bad=dataclasses.replace(fas(i,states[i]),context=other,recovery_budget_view=dataclasses.replace(fa.recovery_budget_view,context=other),captured=None,receipt_record_view=None);q=fin.reduce_finalization(states[i],fev(i),bad);check('cross original assessment leaves prefix unchanged '+str(i),q.reason=='wrong-original' and q.state==states[i])
 q=fin.reduce_finalization(states[i],fev(i,raw=(c.RawStatus('model-admission-0',0),)),fas(i,states[i]));check('original raw call cannot duplicate '+str(i),q.reason=='duplicate-raw-call' and q.state==states[i])
 for name in mapping['budget_positive_views' if sequence[i][1]=='spend-budget' else 'effect_positive_views'][sequence[i][0]]:
  q=fin.reduce_finalization(states[i],fev(i,missing=name),fas(i,states[i]));check('every original phase type payload required '+str(i)+'/'+name,q.state.halted and q.reason=='contradictory-positive-report')
  if name not in ('closed-target-evidence-view','target-release-view','publication-control-view','publication-record-view','last-receipt-origin-view') or (name=='closed-target-evidence-view' and i>=2) or (name=='target-release-view' and i>=4) or (name=='publication-control-view' and i>=5) or (name=='publication-record-view' and i>=5) or (name=='last-receipt-origin-view' and i>=6):
   q=fin.reduce_finalization(states[i],fev(i,substitute=name),fas(i,states[i]));check('bound original captured or publication view cannot substitute '+str(i)+'/'+name,q.state.halted)
 for field in dict.fromkeys(fin.COMMON_REPORTS+(fin.RECOVERY_REPORTS if i<4 else fin.PUBLICATION_REPORTS)):
  for status in ('reported-invalid','unobserved'):
   q=fin.reduce_finalization(states[i],fev(i),dataclasses.replace(fas(i,states[i]),**{field:status}));check('all independent phase controls deny effect '+str(i)+'/'+field+'/'+status,q.reason=='gate-loss' and q.state.halted and q.state.core.recovery_spent==states[i].core.recovery_spent and q.state.core.raw_statuses==states[i].core.raw_statuses)
 window='recovery' if i<4 else 'publication'
 for status in ('inactive','expired','revoked','uncertain'):
  rights=tuple(c.RightReport(x.window,status if x.window==window else x.status) for x in live)
  q=fin.reduce_finalization(states[i],fev(i),dataclasses.replace(fas(i,states[i]),rights=rights));check('independent rights denied '+str(i)+'/'+status,q.reason=='gate-loss' and q.state.core.recovery_spent==states[i].core.recovery_spent)
 deadline=100 if i<4 else 120;clock='recovery_elapsed_milliseconds' if i<4 else 'publication_elapsed_milliseconds'
 for value in (None,deadline,deadline+1,2147483647):check('finite independent deadline strict '+str(i)+'/'+str(value),fin.reduce_finalization(states[i],fev(i),dataclasses.replace(fas(i,states[i]),**{clock:value})).reason=='gate-loss')
 last=states[i].last_recovery_elapsed_milliseconds if i<4 else states[i].last_publication_elapsed_milliseconds
 for value in (0 if last is None else last,deadline-1):check('within independent deadline '+str(i)+'/'+str(value),fin.reduce_finalization(states[i],fev(i),dataclasses.replace(fas(i,states[i]),**{clock:value})).disposition=='model-advanced')
 if last is not None:
  check('observed private clock rollback cannot authorize new action '+str(i),fin.reduce_finalization(states[i],fev(i),dataclasses.replace(fas(i,states[i]),**{clock:last-1})).reason=='gate-loss')
 for field in (('recovery_scope_symbol',) if i<4 else ('publication_scope_symbol','recipient_symbol','content_symbol','record_symbol','receipt_origin_symbol','handoff_symbol')):
  check('same original or independent publication identity '+str(i)+'/'+field,fin.reduce_finalization(states[i],fev(i),dataclasses.replace(fas(i,states[i]),**{field:'model-substituted'})).reason=='gate-loss')
 if i in (2,3) or i>=4:
  check('captured data cannot be omitted or supplied by new target '+str(i),fin.reduce_finalization(states[i],fev(i),dataclasses.replace(fas(i,states[i]),captured=None)).reason=='gate-loss')
for i in range(4):
 for status in ('reported-invalid','unobserved'):
  q=fin.reduce_finalization(states[i],fev(i),dataclasses.replace(fas(i,states[i]),guard_continuity=status));check('lost or unknown guard cannot claim current target '+str(i)+'/'+status,q.state.core.target=='uncertain' and q.state.core.guard in ('lost','uncertain') and q.state.captured==states[i].captured)
for i in range(1,9):check('successful private recovery time cannot disappear '+str(i),rejects(dataclasses.replace,states[i],last_recovery_elapsed_milliseconds=None))
for i in range(5,9):check('successful private publication time cannot disappear '+str(i),rejects(dataclasses.replace,states[i],last_publication_elapsed_milliseconds=None))
controls=[(0,'budget_durable'),(1,'target_evidence_complete'),(2,'budget_durable'),(2,'controller_obligations_known'),(3,'release_known'),(3,'controller_obligations_known'),(4,'publication_controls_known'),(5,'record_no_replace'),(5,'record_file_data_durable'),(5,'record_metadata_durable'),(5,'record_directory_storage_durable'),(6,'receipt_no_replace'),(6,'receipt_file_data_durable'),(6,'receipt_metadata_durable'),(6,'receipt_directory_storage_durable'),(6,'receipt_origin_known'),(7,'handoff_durable'),(7,'handoff_delivery_known')]
for i,field in controls:
 for status in ('reported-invalid','unobserved'):check('distinct durability origin and handoff control '+str(i)+'/'+field+'/'+status,fin.reduce_finalization(states[i],fev(i),dataclasses.replace(fas(i,states[i]),**{field:status})).state.halted)
for i in (6,7):
 for value in (None,dataclasses.replace(states[i].record_view,symbol='model-other-record')):check('receipt and handoff bind preceding record no self hash '+str(i)+'/'+str(value is None),fin.reduce_finalization(states[i],fev(i),dataclasses.replace(fas(i,states[i]),receipt_record_view=value)).state.halted)
for budget in range(3,9):
 p=dataclasses.replace(recovery_plan,budget_limit=budget);s=rec.start_recovery(workers[-1],p)
 for i in range(7):s=rec.reduce_recovery(s,rev(i),ras(i)).state
 f=fin.start_finalization(s,fp)
 for i in range(8):
  before=f;q=fin.reduce_finalization(f,fev(i),fas(i,f));f=q.state
  if q.reason=='budget-exhausted':check('no refill original budget at closure '+str(budget),f.core.recovery_spent==budget and f.attempts==before.attempts and f.core.raw_statuses==before.core.raw_statuses);break
 check('existing original budget literal total '+str(budget),f.handoff_complete==(budget>=5) and f.core.recovery_spent==min(budget,5))
# Known target verification does not waive pending controller artifacts.
pending_workers=[m.reduce_worker(workers[6],event(6,'unknown'),assessment(6)).state,m.reduce_worker(workers[12],event(12,'unknown'),assessment(12)).state,m.reduce_worker(workers[1],event(1,'unknown'),assessment(1)).state]
for index,worker in enumerate(pending_workers):
 s=rec.start_recovery(worker,recovery_plan);seq=backed if s.branch=='restore-original' else unchanged
 for i in range(len(seq)):s=rec.reduce_recovery(s,rev(i,seq),ras(i,seq)).state
 check('pending binding or backup still independently verified target '+str(index),s.ready_for_target_evidence)
 f=fin.start_finalization(s,fp)
 for i in range(2):f=fin.reduce_finalization(f,fev(i),fas(i,f)).state
 check('captured target data retains controller pending '+str(index),f.captured.artifacts_pending and f.captured.original_failure==worker.core.first_failure)
 q=fin.reduce_finalization(f,fev(2),fas(2,f));check('positive assertion cannot release pending controller '+str(index),q.reason=='controller-pending' and q.state.core.recovery_spent==f.core.recovery_spent and q.state.release_view is None and q.state.target_control=='held')
 check('cannot forge captured artifact absence '+str(index),rejects(dataclasses.replace,f,captured=dataclasses.replace(f.captured,artifacts_pending=False)))
# Failed forward execution can publish its unchanged failure result after safe closure.
for code in (None,-7,0,137):
 worker=m.reduce_worker(workers[15],event(15,'known-failure',raw=(c.RawStatus('model-original-forward-failure',code),)),assessment(15)).state;s=rec.start_recovery(worker,recovery_plan)
 for i in range(7):s=rec.reduce_recovery(s,rev(i),ras(i)).state
 f=fin.start_finalization(s,fp)
 for i in range(8):f=fin.reduce_finalization(f,fev(i),fas(i,f)).state
 check('publication retains original forward failure and no success conversion '+str(code),f.handoff_complete and f.captured.original_failure==worker.core.first_failure and f.core.first_failure==worker.core.first_failure and not f.captured.original_forward_complete)
 g=fin.start_finalization(s,fp)
 for i in range(5):g=fin.reduce_finalization(g,fev(i),fas(i,g)).state
 q=fin.reduce_finalization(g,fev(5,'unknown'),fas(5,g));check('publication first failure separate from original '+str(code),q.state.publication_failure==c.RawStatus('model-finalization-5',None) and q.state.core.first_failure==worker.core.first_failure)
for prefix in (workers[-1],recovered[0],recovered[5]):check('cannot finalize unverified earlier model '+type(prefix).__name__+'/'+str(getattr(prefix,'completed',None)),rejects(fin.start_finalization,prefix,fp))
# After release, independent publication may proceed despite expired target rights.
rights=tuple(c.RightReport(x.window,'reported-live' if x.window=='publication' else 'expired') for x in live)
f=states[4]
for i in range(4,8):f=fin.reduce_finalization(f,fev(i),dataclasses.replace(fas(i,f),rights=rights,recovery_elapsed_milliseconds=None,guard_continuity='unobserved')).state
check('captured data publication independent from expired target controls',f.handoff_complete and f.core.target=='unobserved' and f.core.guard=='unobserved')
for i in range(9):
 for field,value in [('forward','active'),('claim','known-unused'),('launch','unspent'),('bootstrap','uncertain'),('traps',False),('baseline','uncertain'),('backups','unobserved'),('pin','model-rebound'),('children','known-owned'),('owned','known-none'),('recovery_limit',7),('recovery_spent',0)]:check('no original field or budget reset '+str(i)+'/'+field,rejects(dataclasses.replace,states[i],core=dataclasses.replace(states[i].core,**{field:value})))
 if i>=4:
  for field,value in [('guard','continuous'),('target','verified-original')]:check('no current target revalidation or guard reacquire '+str(i)+'/'+field,rejects(dataclasses.replace,states[i],core=dataclasses.replace(states[i].core,**{field:value})))
for i,change in [(0,{'completed':True}),(0,{'handoff_complete':True}),(1,{'reserved_phase':None}),(2,{'captured':None}),(3,{'reserved_phase':None}),(4,{'release_view':None}),(4,{'target_control':'held'}),(5,{'controls_view':None}),(6,{'record_view':None}),(7,{'receipt_view':None}),(8,{'handoff_complete':False})]:check('impossible finalization semantic prefix '+str(i)+'/'+str(tuple(change)),rejects(dataclasses.replace,states[i],**change))
for field,value in [('content_symbol','model-other-content'),('original_verification',dataclasses.replace(states[2].captured.original_verification,symbol='model-other-verification')),('original_failure',c.RawStatus('model-invented-failure',-1)),('original_forward_complete',False),('artifacts_pending',True),('recovery_spent_at_capture',5),('original_raw',()),('captured_raw',states[0].core.raw_statuses)]:
 bad=dataclasses.replace(states[2].captured,**{field:value});check('immutable captured original cannot be forged '+field,rejects(dataclasses.replace,states[2],captured=bad))
full=dataclasses.replace(states[0],core=dataclasses.replace(states[0].core,raw_statuses=states[0].core.raw_statuses+tuple(c.RawStatus('model-cap-'+str(i),0) for i in range(4096-len(states[0].core.raw_statuses)))))
check('raw vector remains bounded before effect',fin.reduce_finalization(full,fev(0),fas(0,full)).reason=='resource-limit')
for field,value in [('publication_deadline_milliseconds',True),('publication_deadline_milliseconds',0),('publication_deadline_milliseconds',2147483648),('content_symbol',''),('recipient_symbol','native-user')]:check('strict independent plan shape '+field+'/'+repr(value),rejects(dataclasses.replace,fp,**{field:value}))
for field,values in [('recovery_elapsed_milliseconds',(True,-1,1.0,2147483648)),('publication_elapsed_milliseconds',(True,-1,1.0,2147483648)),('operation',('republish','')),('content_binding',('valid',True)),('rights',(list(live),live[:-1]))]:
 for value in values:check('strict assessment shape '+field+'/'+repr(value),rejects(dataclasses.replace,fa,**{field:value}))
for value in (fp,fa,states[2].captured,states[0],fin.FinalizationDecision(states[0],'model-unattempted','unattempted')):
 check('record frozen '+type(value).__name__,rejects(setattr,value,'authority',True))
 for field in ('authority','native_evidence'):check('private record cannot supply native evidence '+type(value).__name__+'/'+field,rejects(dataclasses.replace,value,**{field:True}))
check('phase types immutable',rejects(lambda:fin.EFFECT_VIEWS.__setitem__(fin.PHASES[0],())))
for phase,(actor,window,_) in c.PHASE_ROWS.items():
 if phase not in fin.PHASES:check('unsupported nonfinalization phase '+phase,fin.reduce_finalization(states[0],c.ModelEvent(ctx,phase,actor,window,'unknown'),fas(0,states[0])).reason=='unsupported-phase')
for argv in [[],['--bogus'],['--check'],['--check','']]:check('strict345 reviewer CLI '+repr(argv),run(['python3','-B',review_path,*argv]).returncode==2)
q=run(['python3','-B',review_path,'--check',root]);check('source-bound345 review entry',q.returncode==0 and 'step345_pure_target_publication_review_status\tPASS' in q.stdout)
with tempfile.TemporaryDirectory(prefix='step345-accepted-source-') as directory:
 snapshot=Path(directory)/'accepted344';snapshot.mkdir()
 for relative,raw in history.items():
  p=snapshot/relative;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
 q=run(['python3','-B',snapshot/policy['predecessor_verifier'],'--check',snapshot]);check('unchanged344 reviewer reruns exact accepted source',q.returncode==0 and 'step344_pure_retained_recovery_review_status\tPASS' in q.stdout)
 previous=Path(policy['predecessor_verifier']).stem;q=run(['bash',snapshot/'tests/reference'/('test-'+previous+'-harness.sh')])
 if q.returncode:sys.stderr.write(q.stdout[-3000:]+q.stderr)
 check('unchanged344 full881 suite reruns successfully',q.returncode==0 and q.stdout.splitlines().count('Result: PASS (881 passes, 0 failures)')==1)
 check('all881 prior labels exact to accepted user return in order',[x for x in q.stdout.splitlines() if x.startswith('PASS: ')]==policy['accepted_ordered344_labels'])
check('all accepted source bytes unchanged after pure finalization tests',review['verify'](root)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
