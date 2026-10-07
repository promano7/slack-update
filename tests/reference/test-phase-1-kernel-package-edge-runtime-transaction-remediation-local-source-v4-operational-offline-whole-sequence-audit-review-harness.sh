#!/bin/bash
set -euo pipefail
export LC_ALL=C
root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
python3 -B - "$root" <<'PYTEST'
from pathlib import Path
import ast,copy,dataclasses,hashlib,json,subprocess,sys,tempfile,types
root=Path(sys.argv[1]);base='phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-whole-sequence-audit-review';fixture=root/'tests/fixtures/reference/acceptance/phase-1/';module_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-whole-sequence-auditor.py';recovery_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-retained-recovery-reducer.py';finalization_path=root/'tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-target-publication-reducer.py';review_path=root/'tools/reference'/(base+'.py');passes=0
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
for label,path,digest in [('340 core',core_path,'94c8cc3dfdb0d813a6ec0d2f7c99e11f5866d8cf96b3ba53e852668eb9d03fb5'),('341 admission',admission_path,'1031e9e2099547def50ba1bdfb5fc8ff36fe94ef42540fbeef5c21509db72bed'),('342 bootstrap',bootstrap_path,'201636350a88c7562cad5cf04f71d5c582b7ea547c2e98b1f7a3751756b32e89'),('343 worker',worker_path,'2678499696ddc9293998dbcd5916aab29c028b045569ade416b38752629836a8'),('344 recovery',recovery_path,'8fa9dd38fd7affba5612f093667a118407fb8d8c96531943278b07180904af0a'),('345 finalization',finalization_path,'22fc51ade0c3a213b004b5b90a79fa7f9c5b2c2125748afbcf61b84aac369954'),('346 auditor',module_path,'f22c34c50f622812b4b5793bff33094560797af4c45f9bf87257f352af0bee26'),('346 reviewer',review_path,'7debf7fcc684a34bc3722f1c47367a704b663ecae5b5d78b1d8f1e030861ef3e')]:check('exact SHA-pinned '+label,hashlib.sha256(path.read_bytes()).hexdigest()==digest)
c=module('slack_update_offline_core340',core_path);a=module('slack_update_offline_admission341',admission_path);b=module('slack_update_offline_bootstrap342',bootstrap_path);m=module('slack_update_offline_worker343',worker_path);rec=module('slack_update_offline_recovery344',recovery_path);fin=module('slack_update_offline_finalization345',finalization_path);aud=module('private346_auditor',module_path)
review={'__name__':'private346_review'};exec(compile(ast.parse(review_path.read_text()),str(review_path),'exec'),review)
history=review['verify'](root);mapping=load('-phase-map.json');contract=load('-contract.json');policy=load('-policy.json')
check('all1692 accepted345 bytes retained',len(history)==1692)
check('complete exact1041 user return accepted',review['validate_return'](load('-checkpoint-confirmation.json'),load('-step345-user-acceptance.json'),policy))
check('full source326327 composition contracts',review['validate_mapping'](mapping,contract,history))
tree=ast.parse(module_path.read_text());check('only pinned pure composition imports',[(x.module,tuple(y.name for y in x.names)) for x in ast.walk(tree) if isinstance(x,ast.ImportFrom)]==[('dataclasses',('dataclass','replace')),('slack_update_offline_core340',('ModelContext','CoreState','ModelEvent')),('slack_update_offline_admission341',('AdmissionState','AdmissionAssessment','start_admission','reduce_admission')),('slack_update_offline_bootstrap342',('BootstrapState','BootstrapAssessment','start_bootstrap','reduce_bootstrap')),('slack_update_offline_worker343',('WorkerState','WorkerAssessment','WorkerPlan','start_worker','reduce_worker')),('slack_update_offline_recovery344',('RecoveryState','RecoveryAssessment','RecoveryPlan','start_recovery','reduce_recovery')),('slack_update_offline_finalization345',('FinalizationState','FinalizationAssessment','FinalizationPlan','start_finalization','reduce_finalization'))] and not any(isinstance(x,ast.Import) for x in ast.walk(tree)))
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
fin_mapping=json.loads((fixture/('phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-offline-target-publication-reducer-review'+'-phase-map.json')).read_bytes())
recovered=[rec.start_recovery(workers[-1],recovery_plan)]
for i in range(7):recovered.append(rec.reduce_recovery(recovered[-1],rev(i),ras(i)).state)
check('unchanged344 verified original with original budget3 of8',recovered[-1].ready_for_target_evidence and recovered[-1].core.recovery_spent==3)
fp=fin.FinalizationPlan(ctx,'model-recipient','model-captured-content',views['publication-record-view'].symbol,views['last-receipt-origin-view'].symbol,'model-handoff','model-publication-scope',120)
fa=fin.FinalizationAssessment(ctx,live,'effect-report',recovery_plan.budget_view,recovery_plan.original_scope_symbol,fp.publication_scope_symbol,fp.recipient_symbol,fp.content_symbol,fp.record_symbol,fp.receipt_origin_symbol,fp.handoff_symbol,recovery_elapsed_milliseconds=37,publication_elapsed_milliseconds=51,**{k:'reported-valid' for k in dict.fromkeys(fin.COMMON_REPORTS+fin.RECOVERY_REPORTS+fin.PUBLICATION_REPORTS+fin.ACTION_REPORTS)})
sequence=[('worker11-close-target-evidence','spend-budget'),('worker11-close-target-evidence','effect-report'),('release-target-control','spend-budget'),('release-target-control','effect-report'),('worker12-publication-controls','effect-report'),('worker12-publication-record','effect-report'),('worker12-last-receipt','effect-report'),('worker12-durable-handoff','effect-report')]
check('literal eight closure publication observations',tuple(sequence)==fin.SEQUENCE)
def fev(i,outcome='known-success',missing=None,substitute=None,raw=None,context=ctx):
 phase,operation=sequence[i];names=list(fin_mapping['budget_positive_views' if operation=='spend-budget' else 'effect_positive_views'][phase])
 if missing is not None:names.remove(missing)
 vv=tuple(dataclasses.replace(views[k],context=context,**({'symbol':'model-substituted-view'} if k==substitute else {})) for k in names) if outcome=='known-success' else ()
 if raw is None:raw=() if outcome=='unattempted' else (c.RawStatus('model-finalization-'+str(i),0 if outcome=='known-success' else -11 if outcome=='known-failure' else None),)
 actor,window,_=c.PHASE_ROWS[phase];return c.ModelEvent(context,phase,actor,window,outcome,'phase-report',vv,raw)
def fas(i,s):return dataclasses.replace(fa,operation=sequence[i][1],captured=s.captured,receipt_record_view=s.record_view)
final_states=[fin.start_finalization(recovered[-1],fp)]
for i in range(8):final_states.append(fin.reduce_finalization(final_states[-1],fev(i),fas(i,final_states[-1])).state)
whole=aud.WholePlan(ctx,plan,recovery_plan,fp);operations=[]
admission_names=[('authenticated-policy-view','issuer-policy-view','dependency-closure-view','source-closure-view'),('authenticated-policy-view','consumed-original-context','dependency-closure-view','source-closure-view'),('consumed-original-context','spent-launch-view','dependency-closure-view','source-closure-view'),('consumed-original-context','spent-launch-view','dependency-closure-view','source-closure-view')]
for i,names in enumerate(admission_names):operations.append(aud.ReportOperation(typed_event(a.PHASES[i],names=names,raw=(c.RawStatus('model-admission-'+str(i),0),)),aa))
operations.append(aud.TransferOperation(ctx,'bootstrap'))
bootstrap_names=[common0+('spent-launch-view','closed-bootstrap-view'),common0+('spent-launch-view','closed-bootstrap-view'),common0+('closed-bootstrap-view','early-observation-view'),common0+('armed-traps-view','known-child-set-view','live-original-fence-view'),common0+('armed-traps-view','live-original-fence-view','continuous-guard-view','original-baseline-view')]
for i,names in enumerate(bootstrap_names):operations.append(aud.ReportOperation(typed_event(b.PHASES[i],names=names,raw=(c.RawStatus('model-bootstrap-'+str(i),0),)),bb))
operations.append(aud.TransferOperation(ctx,'worker'))
for i in range(19):operations.append(aud.ReportOperation(event(i),assessment(i,workers[i])))
operations.append(aud.TransferOperation(ctx,'recovery'))
for i in range(7):operations.append(aud.ReportOperation(rev(i),ras(i)))
operations.append(aud.TransferOperation(ctx,'finalization'))
for i in range(8):operations.append(aud.ReportOperation(fev(i),fas(i,final_states[i])))
operations=tuple(operations);result=aud.audit_sequence(whole,operations)
check('literal47 original27-phase composed observations',len(operations)==47 and len(result.entries)==47 and len([x for x in operations if type(x) is aud.ReportOperation])==43)
check('all27 original phases represented in source order',list(dict.fromkeys(x.event.phase for x in operations if type(x) is aud.ReportOperation))==[k for k,v in sorted(mapping['phase_rows'].items(),key=lambda item:item[1]['position'])])
check('literal final original status budget and publication',result.final_family=='finalization' and result.final_state.handoff_complete and result.final_state.core.claim=='consumed' and result.final_state.core.launch=='spent' and result.final_state.core.forward=='stopped' and result.final_state.core.recovery_limit==8 and result.final_state.core.recovery_spent==5 and result.final_state.core.guard=='unobserved' and result.final_state.core.target=='unobserved' and result.final_state.core.publication=='handoff-reported' and result.final_state.core.first_failure is None)
check('literal43 unique raw results preserve empty install20',len(result.final_state.core.raw_statuses)==43 and sum(x.code==20 for x in result.final_state.core.raw_statuses)==1 and all(x.code in (0,20) for x in result.final_state.core.raw_statuses))
check('separate private clocks carried through344345',result.recovery_elapsed==37 and result.publication_elapsed==51)
check('all transfers explicitly declared and gated',[(x.family_before,x.family_after) for x in result.entries if x.kind=='transfer']==[('admission','bootstrap'),('bootstrap','worker'),('worker','recovery'),('recovery','finalization')])
for index,entry in enumerate(result.entries):
 check('whole raw original and finite budget lineage '+str(index),entry.after.raw_statuses[:len(entry.before.raw_statuses)]==entry.before.raw_statuses and entry.after.context==ctx and entry.after.recovery_spent>=entry.before.recovery_spent)
 check('no native authority evidence from whole operation '+str(index),not entry.authority and not entry.native_evidence and not result.authority and not result.native_evidence)
check('pure model duplicate evaluation never global once proof',aud.audit_sequence(whole,operations)==result)
report_indices=[i for i,x in enumerate(operations) if type(x) is aud.ReportOperation]
for index in report_indices:
 op=operations[index]
 for outcome,code in [('known-failure',-31),('unknown',None)]:
  fault=dataclasses.replace(op,event=dataclasses.replace(op.event,outcome=outcome,views=(),raw_statuses=(c.RawStatus('model-whole-fault-'+str(index),code),)))
  case=operations[:index]+(fault,)+operations[index+1:];q=aud.audit_sequence(whole,case);cut=q.entries[index]
  check('composed declared fault halts first family '+str(index)+'/'+outcome,cut.disposition in ('model-stopped','model-pending','model-quarantined') and cut.after.first_failure==c.RawStatus('model-whole-fault-'+str(index),code))
  check('composed fault status never converted to success '+str(index)+'/'+outcome,q.final_state.core.first_failure==cut.after.first_failure and not (q.final_family=='finalization' and q.final_state.handoff_complete))
  check('composed original raw and spent budget retained after fault '+str(index)+'/'+outcome,all(e.after.raw_statuses[:len(e.before.raw_statuses)]==e.before.raw_statuses and e.after.recovery_spent>=e.before.recovery_spent for e in q.entries[index:]))
  if index<10:check('early unknown cannot acquire worker recovery guard '+str(index)+'/'+outcome,q.final_family in ('admission','bootstrap') and q.final_state.core.target=='unobserved' and q.final_state.core.recovery_spent==0)
  if index>=44:check('publication fault retains preceding artifacts and no replay '+str(index)+'/'+outcome,q.final_state.captured==result.final_state.captured and q.final_state.release_view==result.final_state.release_view and q.final_state.core.target=='unobserved' and q.final_state.publication_failure==cut.after.first_failure)
 # Shape-valid wrong original is ignored before any time/budget update.
 foreign=dataclasses.replace(op,event=dataclasses.replace(op.event,context=other,views=tuple(dataclasses.replace(v,context=other) for v in op.event.views)))
 q=aud.audit_sequence(whole,operations[:index]+(foreign,)+operations[index+1:]);check('foreign report preserves composed inner state '+str(index),q.entries[index].disposition=='model-rejected' and q.entries[index].before==q.entries[index].after)
 q=aud.audit_sequence(whole,operations[:index]+(dataclasses.replace(op,assessment=aa if type(op.assessment) is not a.AdmissionAssessment else bb),)+operations[index+1:]);check('wrong typed assessment family cannot advance '+str(index),q.entries[index].reason=='assessment-family' and q.entries[index].before==q.entries[index].after)
 if index:
  duplicate=dataclasses.replace(op,event=dataclasses.replace(op.event,raw_statuses=(c.RawStatus('model-admission-0',0),)))
  q=aud.audit_sequence(whole,operations[:index]+(duplicate,)+operations[index+1:]);check('whole duplicate raw cannot hide original call '+str(index),q.entries[index].reason=='duplicate-raw-call' and q.entries[index].before==q.entries[index].after)
for index in (4,10,30,38):
 for destination in aud.FAMILIES:
  if destination==operations[index].next_family:continue
  q=aud.audit_sequence(whole,operations[:index]+(aud.TransferOperation(ctx,destination),)+operations[index+1:]);check('whole transfer cannot skip reset or reopen '+str(index)+'/'+destination,q.entries[index].disposition=='model-rejected' and q.entries[index].before==q.entries[index].after)
 q=aud.audit_sequence(whole,operations[:index]+(aud.TransferOperation(other,operations[index].next_family),)+operations[index+1:]);check('foreign transfer cannot enter another attempt '+str(index),q.entries[index].reason=='wrong-original' and q.entries[index].before==q.entries[index].after)
# Rejected first wrong-order bridge followed by correct vector remains recoverable data.
q=aud.audit_sequence(whole,(aud.TransferOperation(ctx,'recovery'),)+operations)
check('rejected nonexistent early recovery never gains authority',q.entries[0].reason=='wrong-transfer-order' and q.final_state.handoff_complete and q.final_state.core.recovery_spent==5)
for budget in range(9):
 q=aud.audit_sequence(dataclasses.replace(whole,recovery=dataclasses.replace(recovery_plan,budget_limit=budget)),operations)
 check('whole finite original budget oracle0..8 '+str(budget),q.final_state.core.recovery_limit==budget and q.final_state.core.recovery_spent==min(budget,5) and (q.final_family=='finalization' and q.final_state.handoff_complete)==(budget>=5))
for index in (32,39,44):
 op=operations[index];field='elapsed_milliseconds' if index==32 else 'recovery_elapsed_milliseconds' if index==39 else 'publication_elapsed_milliseconds';value=36 if index in (32,39) else 50
 fault=dataclasses.replace(op,assessment=dataclasses.replace(op.assessment,**{field:value}));q=aud.audit_sequence(whole,operations[:index]+(fault,)+operations[index+1:]);e=q.entries[index]
 check('composed clock rollback denies without action or spend '+str(index),e.kind=='clock-denial' and e.reason=='clock-rollback' and e.after.recovery_spent==e.before.recovery_spent and e.after.raw_statuses==e.before.raw_statuses and e.disposition=='model-pending')
 check('clock ledger cannot rollback or authorize later finalization '+str(index),q.recovery_elapsed==37 and (q.publication_elapsed==51 if index==44 else q.publication_elapsed is None) and not (q.final_family=='finalization' and q.final_state.handoff_complete))
check('unchanged345 local first timestamp lacks344 history but whole audit covers it',fin.reduce_finalization(final_states[0],fev(0),dataclasses.replace(fas(0,final_states[0]),recovery_elapsed_milliseconds=36)).disposition=='model-advanced')
for index in (32,39):
 op=operations[index];rights=tuple(c.RightReport(x.window,'revoked' if x.window=='recovery' else x.status) for x in live);fault=dataclasses.replace(op,assessment=dataclasses.replace(op.assessment,rights=rights));q=aud.audit_sequence(whole,operations[:index]+(fault,)+operations[index+1:]);check('whole original recovery revocation no budget renewal '+str(index),q.entries[index].reason=='gate-loss' and q.entries[index].after.recovery_spent==q.entries[index].before.recovery_spent and not (q.final_family=='finalization' and q.final_state.handoff_complete))
for index in (17,23):
 op=operations[index];fault=dataclasses.replace(op,event=dataclasses.replace(op.event,outcome='unknown',views=(),raw_statuses=(c.RawStatus('model-unknown-binding',None),)));q=aud.audit_sequence(whole,operations[:index]+(fault,)+operations[index+1:]);check('unknown owned binding safe recovery but release pending '+str(index),q.final_family=='finalization' and q.final_state.captured.artifacts_pending and q.final_state.core.target=='verified-original' and q.final_state.release_view is None and q.entries[41].reason=='controller-pending')
index=13;op=operations[index];fault=dataclasses.replace(op,event=dataclasses.replace(op.event,outcome='unknown',views=(),raw_statuses=(c.RawStatus('model-unknown-target',None),)));q=aud.audit_sequence(whole,operations[:index]+(fault,)+operations[index+1:]);check('unknown target never restores verifies or releases in whole trace',q.final_family=='recovery' and q.final_state.branch=='blocked' and q.final_state.core.target=='uncertain' and not q.final_state.ready_for_target_evidence)
# Independently unchanged path after an unattempted forward revocation; no backup invented.
rights=tuple(c.RightReport(x.window,'revoked' if x.window=='forward' else x.status) for x in live)
stop_assessment=dataclasses.replace(assessment(0),rights=rights);stop_event=event(0,'unattempted');worker=m.reduce_worker(workers[0],stop_event,stop_assessment).state
case=list(operations[:11])+[aud.ReportOperation(stop_event,stop_assessment),aud.TransferOperation(ctx,'recovery')];s=rec.start_recovery(worker,recovery_plan)
for i in range(5):
 ev=rev(i,unchanged);aa2=dataclasses.replace(ras(i,unchanged),rights=rights);case.append(aud.ReportOperation(ev,aa2));s=rec.reduce_recovery(s,ev,aa2).state
case.append(aud.TransferOperation(ctx,'finalization'));f=fin.start_finalization(s,fp)
for i in range(8):
 ev=fev(i);aa2=dataclasses.replace(fas(i,f),rights=rights);case.append(aud.ReportOperation(ev,aa2));f=fin.reduce_finalization(f,ev,aa2).state
q=aud.audit_sequence(whole,tuple(case));check('forward-only revocation retained finite unchanged recovery and failure publication',q.final_state.handoff_complete and q.final_state.core.forward=='stopped' and q.final_state.core.recovery_spent==4 and q.final_state.core.backups=='unobserved' and q.final_state.prefix.restoration_view is None and not q.final_state.captured.original_forward_complete and q.final_state.core.first_failure==worker.core.first_failure)
for index in (43,44,45,46):
 op=operations[index];rights2=tuple(c.RightReport(x.window,'uncertain' if x.window=='publication' else x.status) for x in live);fault=dataclasses.replace(op,assessment=dataclasses.replace(op.assessment,rights=rights2));q=aud.audit_sequence(whole,operations[:index]+(fault,)+operations[index+1:]);check('publication controls remain independently required through last handoff '+str(index),q.entries[index].reason=='gate-loss' and q.final_state.core.target=='unobserved' and not q.final_state.handoff_complete)
empty=aud.audit_sequence(whole,());check('empty audit no native launch grant or effect',empty.final_family=='admission' and empty.final_state.core.claim=='known-unused' and empty.final_state.core.spawn=='unattempted')
bounded=tuple(aud.TransferOperation(other,'bootstrap') for i in range(128));q=aud.audit_sequence(whole,bounded);check('128 explicit bounded rejections preserve complete initial model',len(q.entries)==128 and q.final_state==empty.final_state)
check('129 operations rejected before model dispatch',rejects(aud.audit_sequence,whole,bounded+(bounded[0],)))
check('mutable operation list rejected',rejects(aud.audit_sequence,whole,list(operations)))
for value in (whole,operations[0],operations[4],result.entries[0],result):
 check('composed private record frozen '+type(value).__name__,rejects(setattr,value,'authority',True))
 for field in ('authority','native_evidence'):check('whole private record cannot supply native evidence '+type(value).__name__+'/'+field,rejects(dataclasses.replace,value,**{field:True}))
for field,value in [('final_family','worker'),('final_state',workers[-1]),('recovery_elapsed',None),('publication_elapsed',0),('entries',result.entries[:-1]),('operations',operations[:-1])]:check('audit ordered lineage cannot forge final projection '+field,rejects(dataclasses.replace,result,**{field:value}))
for field,value in [('index',True),('index',128),('kind','native-run'),('after',dataclasses.replace(result.entries[0].after,context=other)),('recovery_elapsed_before',-1)]:check('closed audit entry shape lineage '+field,rejects(dataclasses.replace,result.entries[0],**{field:value}))
check('no native concurrency or host claim',not contract['actual_concurrency_exhaustive'] and not contract['actual_global_host_closure_asserted'] and contract['native_cases_run']==0 and contract['native_proofs_added']==0)
for argv in [[],['--bogus'],['--check'],['--check','']]:check('strict346 reviewer CLI '+repr(argv),run(['python3','-B',review_path,*argv]).returncode==2)
q=run(['python3','-B',review_path,'--check',root]);check('source-bound346 review entry',q.returncode==0 and 'step346_pure_whole_sequence_audit_review_status\tPASS' in q.stdout)
with tempfile.TemporaryDirectory(prefix='step346-accepted-source-') as directory:
 snapshot=Path(directory)/'accepted345';snapshot.mkdir()
 for relative,raw in history.items():
  p=snapshot/relative;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(raw)
 q=run(['python3','-B',snapshot/policy['predecessor_verifier'],'--check',snapshot]);check('unchanged345 reviewer reruns exact accepted source',q.returncode==0 and 'step345_pure_target_publication_review_status\tPASS' in q.stdout)
 previous=Path(policy['predecessor_verifier']).stem;q=run(['bash',snapshot/'tests/reference'/('test-'+previous+'-harness.sh')])
 if q.returncode:sys.stderr.write(q.stdout[-3000:]+q.stderr)
 check('unchanged345 full1041 suite reruns successfully',q.returncode==0 and q.stdout.splitlines().count('Result: PASS (1041 passes, 0 failures)')==1)
 check('all1041 prior labels exact to accepted user return in order',[x for x in q.stdout.splitlines() if x.startswith('PASS: ')]==policy['accepted_ordered345_labels'])
check('all accepted source bytes unchanged after pure composition tests',review['verify'](root)==history)
print('Result: PASS ('+str(passes)+' passes, 0 failures)')
PYTEST
