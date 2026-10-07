"""Pure target closure and publication reports. No IO/native effect or authority.

Separate record/receipt/handoff observations are not pair atomicity or authenticity.
After release, only immutable captured original data remains, never current host proof.
"""
from dataclasses import dataclass, fields, replace
from types import MappingProxyType
from slack_update_offline_core340 import ModelContext, ModelView, RightReport, RawStatus, CoreState, ModelEvent, RIGHTS_WINDOWS, MAX_RAW_STATUSES
from slack_update_offline_recovery344 import RecoveryState

PHASES=('worker11-close-target-evidence', 'release-target-control', 'worker12-publication-controls', 'worker12-publication-record', 'worker12-last-receipt', 'worker12-durable-handoff')
BUDGET_VIEWS=MappingProxyType({'release-target-control': ('armed-traps-view', 'consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'live-original-fence-view', 'original-baseline-view', 'original-verification-view', 'quiescent-child-view', 'source-closure-view', 'closed-target-evidence-view'), 'worker11-close-target-evidence': ('consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'live-original-fence-view', 'original-baseline-view', 'original-verification-view', 'quiescent-child-view', 'source-closure-view')})
EFFECT_VIEWS=MappingProxyType({'release-target-control': ('armed-traps-view', 'closed-target-evidence-view', 'consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'live-original-fence-view', 'original-baseline-view', 'original-verification-view', 'quiescent-child-view', 'source-closure-view', 'target-release-view'), 'worker11-close-target-evidence': ('closed-target-evidence-view', 'consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'live-original-fence-view', 'original-baseline-view', 'original-verification-view', 'quiescent-child-view', 'source-closure-view'), 'worker12-durable-handoff': ('closed-target-evidence-view', 'dependency-closure-view', 'last-receipt-origin-view', 'publication-control-view', 'publication-record-view', 'source-closure-view', 'target-release-view'), 'worker12-last-receipt': ('dependency-closure-view', 'last-receipt-origin-view', 'publication-control-view', 'publication-record-view', 'source-closure-view'), 'worker12-publication-controls': ('closed-target-evidence-view', 'dependency-closure-view', 'publication-control-view', 'source-closure-view', 'target-release-view'), 'worker12-publication-record': ('closed-target-evidence-view', 'dependency-closure-view', 'publication-control-view', 'publication-record-view', 'source-closure-view', 'target-release-view')})
SEQUENCE=((PHASES[0],'spend-budget'),(PHASES[0],'effect-report'),(PHASES[1],'spend-budget'),(PHASES[1],'effect-report'))+tuple((p,'effect-report') for p in PHASES[2:])
REPORTS=('reported-valid','reported-invalid','unobserved')
COMMON_REPORTS=('same_original','source_closure','no_target_refresh','preserve_artifacts')
RECOVERY_REPORTS=('original_scope','safe_boot','safe_phase','trusted_time','guard_continuity','live_recovery_fence','quiescence_known','original_memory_baseline','owned_canonical_paths','all_writers_excluded','approved_original_deltas','no_worker_service_channel')
PUBLICATION_REPORTS=('captured_data_only','publication_scope','publication_time','publication_fence','recipient_ancestry','recipient_alias','recipient_owner','content_binding','exclusive_writer','no_worker_service_channel')
ACTION_REPORTS=('budget_durable','target_evidence_complete','controller_obligations_known','release_known','publication_controls_known','record_no_replace','record_file_data_durable','record_metadata_durable','record_directory_storage_durable','receipt_no_replace','receipt_file_data_durable','receipt_metadata_durable','receipt_directory_storage_durable','receipt_origin_known','handoff_durable','handoff_delivery_known')
DISPOSITIONS=('model-advanced','model-pending','model-rejected','model-unattempted')
REASONS=('advanced','unattempted','wrong-original','unsupported-phase','wrong-order','terminal-prefix','gate-loss','budget-exhausted','controller-pending','unknown-outcome','known-failure','contradictory-positive-report','duplicate-raw-call','resource-limit')

def _fail(label):raise ValueError(label)
def _false(x):
 if type(x) is not bool or x:_fail('no native authority/evidence')
def _context(x):
 if type(x) is not ModelContext:_fail('exact340 context')
 x.__post_init__()
def _symbol(x):ModelContext(x,'model-symbol-check').__post_init__()
def _view(x,name,context):
 if type(x) is not ModelView or x.name!=name or x.context!=context:_fail('exact immutable nominal original view')
 x.__post_init__()
def _raw(x):
 if type(x) is not tuple or len(x)>MAX_RAW_STATUSES or any(type(v) is not RawStatus for v in x):_fail('bounded exact immutable raw vector')
 for v in x:v.__post_init__()
 if len({v.call for v in x})!=len(x):_fail('distinct raw calls')
def _artifact_pending(prefix):
 w=prefix.prefix
 return prefix.binding_pending or w.core.owned=='uncertain' or w.core.backups=='uncertain'

@dataclass(frozen=True,slots=True)
class FinalizationPlan:
 context: ModelContext
 recipient_symbol: str
 content_symbol: str
 record_symbol: str
 receipt_origin_symbol: str
 handoff_symbol: str
 publication_scope_symbol: str
 publication_deadline_milliseconds: int
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  _context(self.context)
  for k in ('recipient_symbol','content_symbol','record_symbol','receipt_origin_symbol','handoff_symbol','publication_scope_symbol'):_symbol(getattr(self,k))
  if type(self.publication_deadline_milliseconds) is not int or not 1<=self.publication_deadline_milliseconds<=2147483647:_fail('finite independent publication deadline assumption')
  _false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class CapturedTargetData:
 context: ModelContext
 view: ModelView
 content_symbol: str
 original_verification: ModelView
 original_raw: tuple[RawStatus,...]
 captured_raw: tuple[RawStatus,...]
 original_failure: RawStatus | None
 original_forward_complete: bool
 artifacts_pending: bool
 recovery_spent_at_capture: int
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  _context(self.context);_view(self.view,'closed-target-evidence-view',self.context);_view(self.original_verification,'original-verification-view',self.context);_symbol(self.content_symbol);_raw(self.original_raw);_raw(self.captured_raw)
  if self.captured_raw[:len(self.original_raw)]!=self.original_raw:_fail('capture retains original raw prefix')
  if self.original_failure is not None:
   if type(self.original_failure) is not RawStatus:_fail('exact original failure')
   self.original_failure.__post_init__()
  if type(self.original_forward_complete) is not bool or type(self.artifacts_pending) is not bool:_fail('exact captured outcomes')
  if type(self.recovery_spent_at_capture) is not int or not 0<=self.recovery_spent_at_capture<=8:_fail('private finite original budget snapshot')
  _false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class FinalizationAssessment:
 context: ModelContext
 rights: tuple[RightReport,...]
 operation: str
 recovery_budget_view: ModelView
 recovery_scope_symbol: str
 publication_scope_symbol: str
 recipient_symbol: str
 content_symbol: str
 record_symbol: str
 receipt_origin_symbol: str
 handoff_symbol: str
 recovery_elapsed_milliseconds: int | None=None
 publication_elapsed_milliseconds: int | None=None
 captured: CapturedTargetData | None=None
 receipt_record_view: ModelView | None=None
 same_original: str='unobserved'
 source_closure: str='unobserved'
 no_target_refresh: str='unobserved'
 preserve_artifacts: str='unobserved'
 original_scope: str='unobserved'
 safe_boot: str='unobserved'
 safe_phase: str='unobserved'
 trusted_time: str='unobserved'
 guard_continuity: str='unobserved'
 live_recovery_fence: str='unobserved'
 quiescence_known: str='unobserved'
 original_memory_baseline: str='unobserved'
 owned_canonical_paths: str='unobserved'
 all_writers_excluded: str='unobserved'
 approved_original_deltas: str='unobserved'
 no_worker_service_channel: str='unobserved'
 captured_data_only: str='unobserved'
 publication_scope: str='unobserved'
 publication_time: str='unobserved'
 publication_fence: str='unobserved'
 recipient_ancestry: str='unobserved'
 recipient_alias: str='unobserved'
 recipient_owner: str='unobserved'
 content_binding: str='unobserved'
 exclusive_writer: str='unobserved'
 budget_durable: str='unobserved'
 target_evidence_complete: str='unobserved'
 controller_obligations_known: str='unobserved'
 release_known: str='unobserved'
 publication_controls_known: str='unobserved'
 record_no_replace: str='unobserved'
 record_file_data_durable: str='unobserved'
 record_metadata_durable: str='unobserved'
 record_directory_storage_durable: str='unobserved'
 receipt_no_replace: str='unobserved'
 receipt_file_data_durable: str='unobserved'
 receipt_metadata_durable: str='unobserved'
 receipt_directory_storage_durable: str='unobserved'
 receipt_origin_known: str='unobserved'
 handoff_durable: str='unobserved'
 handoff_delivery_known: str='unobserved'
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  _context(self.context);_view(self.recovery_budget_view,'recovery-budget-view',self.context)
  for k in ('recovery_scope_symbol','publication_scope_symbol','recipient_symbol','content_symbol','record_symbol','receipt_origin_symbol','handoff_symbol'):_symbol(getattr(self,k))
  if type(self.rights) is not tuple or len(self.rights)!=9 or tuple(x.window for x in self.rights if type(x) is RightReport)!=RIGHTS_WINDOWS:_fail('all nine ordered exact rights')
  for x in self.rights:x.__post_init__()
  if type(self.operation) is not str or self.operation not in ('spend-budget','effect-report'):_fail('private spend/effect observations within original source phase')
  for k in ('recovery_elapsed_milliseconds','publication_elapsed_milliseconds'):
   v=getattr(self,k)
   if v is not None and (type(v) is not int or not 0<=v<=2147483647):_fail('bounded exact private time or unobserved')
  if self.captured is not None:
   if type(self.captured) is not CapturedTargetData or self.captured.context!=self.context:_fail('exact immutable same-original captured data')
   self.captured.__post_init__()
  if self.receipt_record_view is not None:_view(self.receipt_record_view,'publication-record-view',self.context)
  for k in tuple(dict.fromkeys(COMMON_REPORTS+RECOVERY_REPORTS+PUBLICATION_REPORTS+ACTION_REPORTS)):
   if type(getattr(self,k)) is not str or getattr(self,k) not in REPORTS:_fail('closed private report assumption')
  _false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class FinalizationState:
 prefix: RecoveryState
 plan: FinalizationPlan
 core: CoreState
 completed: int=0
 attempts: tuple[tuple[str,str],...]=()
 reserved_phase: str | None=None
 captured: CapturedTargetData | None=None
 release_view: ModelView | None=None
 controls_view: ModelView | None=None
 record_view: ModelView | None=None
 receipt_view: ModelView | None=None
 last_recovery_elapsed_milliseconds: int | None=None
 last_publication_elapsed_milliseconds: int | None=None
 target_control: str='held'
 finalization_failure: RawStatus | None=None
 publication_failure: RawStatus | None=None
 halted: bool=False
 handoff_complete: bool=False
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  if type(self.prefix) is not RecoveryState or type(self.plan) is not FinalizationPlan or type(self.core) is not CoreState:_fail('exact verified recovery/plan/core')
  self.prefix.__post_init__();self.plan.__post_init__();self.core.__post_init__();p=self.prefix;c=self.core
  if p.halted or not p.ready_for_target_evidence or p.core.target!='verified-original' or p.core.children!='drained' or p.core.guard!='continuous':_fail('known original verification and child drain under original guard')
  if self.plan.context!=p.core.context or c.context!=p.core.context:_fail('same original context')
  if type(self.completed) is not int or not 0<=self.completed<=len(SEQUENCE):_fail('bounded known finalization prefix')
  if type(self.attempts) is not tuple or self.attempts not in (SEQUENCE[:self.completed],SEQUENCE[:self.completed+1]):_fail('exact source/spend/effect prefix plus one failed report')
  for k in ('halted','handoff_complete'):
   if type(getattr(self,k)) is not bool:_fail('exact immutable model flag')
  _false(self.authority);_false(self.native_evidence)
  mutable=('phase','guard','target','rights','raw_statuses','first_failure','recovery_spent','publication')
  for f in fields(CoreState):
   if f.name not in mutable and getattr(c,f.name)!=getattr(p.core,f.name):_fail('no original forward/claim/launch/pin/baseline/budget-limit/children reset')
  if c.recovery_spent!=p.core.recovery_spent+sum(o=='spend-budget' for _,o in self.attempts):_fail('existing finite original budget, no refill/refund')
  if c.raw_statuses[:len(p.core.raw_statuses)]!=p.core.raw_statuses:_fail('exact original raw prefix')
  if c.phase!=(p.core.phase if not self.attempts else self.attempts[-1][0]):_fail('last attempted source phase')
  for k in ('finalization_failure','publication_failure'):
   v=getattr(self,k)
   if v is not None:
    if type(v) is not RawStatus:_fail('exact separate sticky failure')
    v.__post_init__()
  if self.halted!=(self.finalization_failure is not None):_fail('sticky pending halt')
  if c.first_failure!=(p.core.first_failure if p.core.first_failure is not None else self.finalization_failure):_fail('original failure wins over later closure/publication')
  if self.publication_failure is not None and (not self.halted or self.completed<4 or self.publication_failure!=self.finalization_failure):_fail('separate publication failure only after target release')
  if self.halted and self.completed>=4 and self.publication_failure!=self.finalization_failure:_fail('publication failure retained even denied/unattempted')
  if not self.halted and self.attempts!=SEQUENCE[:self.completed]:_fail('no failed attempted report in successful prefix')
  expected_reservation=SEQUENCE[self.completed-1][0] if self.completed and SEQUENCE[self.completed-1][1]=='spend-budget' and not self.halted else None
  if self.reserved_phase!=expected_reservation:_fail('one durable reservation consumed by its single exact effect')
  if (self.captured is not None)!=(self.completed>=2):_fail('target evidence only after known capture')
  if self.captured is not None:
   if type(self.captured) is not CapturedTargetData:_fail('exact captured data')
   self.captured.__post_init__();x=self.captured;w=p.prefix
   if len(x.captured_raw)!=len(p.core.raw_statuses)+2 or any(v.code!=0 for v in x.captured_raw[-2:]):_fail('complete successful spend and capture raw observations')
   if x.context!=c.context or x.content_symbol!=self.plan.content_symbol or x.original_verification!=p.verification_view or x.original_raw!=p.core.raw_statuses or x.original_failure!=p.core.first_failure or x.original_forward_complete!=(w.ready_for_finalization and not w.stopped) or x.artifacts_pending!=_artifact_pending(p) or x.recovery_spent_at_capture!=p.core.recovery_spent+1 or c.raw_statuses[:len(x.captured_raw)]!=x.captured_raw:_fail('capture cannot invent original status/evidence/budget/content or waive artifacts')
  for k,name,rank in (('release_view','target-release-view',4),('controls_view','publication-control-view',5),('record_view','publication-record-view',6),('receipt_view','last-receipt-origin-view',7)):
   v=getattr(self,k)
   if (v is not None)!=(self.completed>=rank):_fail('source outputs only from known complete original phase')
   if v is not None:_view(v,name,c.context)
  if self.record_view is not None and self.record_view.symbol!=self.plan.record_symbol:_fail('record origin bound independent plan')
  if self.receipt_view is not None and self.receipt_view.symbol!=self.plan.receipt_origin_symbol:_fail('receipt origin bound independent plan')
  if type(self.target_control) is not str or self.target_control not in ('held','reported-released','uncertain'):_fail('closed model target control')
  uncertain_release=self.halted and len(self.attempts)>self.completed and self.attempts[-1]==(PHASES[1],'effect-report')
  expected_control='reported-released' if self.completed>=4 else 'held'
  if self.target_control!=expected_control and not (uncertain_release and self.target_control=='uncertain'):_fail('known release is separate from captured evidence')
  for k,required,limit in (('last_recovery_elapsed_milliseconds',self.completed>=1,p.plan.deadline_milliseconds),('last_publication_elapsed_milliseconds',self.completed>=5,self.plan.publication_deadline_milliseconds)):
   v=getattr(self,k)
   if required and (type(v) is not int or not 0<=v<limit):_fail('known finite private timestamp required for successful phase prefix')
   if not required and v is not None:_fail('no invented successful time before phase')
  if self.completed>=4:
   if self.captured is None or self.captured.artifacts_pending:_fail('unknown controller/binding/backup obligation blocks release')
   if c.guard!='unobserved' or c.target!='unobserved':_fail('after release no current guard/target knowledge or reacquire')
  elif self.target_control=='uncertain':
   if c.guard!='uncertain' or c.target!='uncertain':_fail('unknown release remains pending')
  elif self.halted:
   if c.guard not in ('continuous','lost','uncertain') or c.target!=('verified-original' if c.guard=='continuous' else 'uncertain'):_fail('lost guard cannot assert current original target; captured snapshot retained')
  elif c.guard!='continuous' or c.target!='verified-original':_fail('original guard retained through complete target capture')
  expected_pub='unattempted' if self.completed<5 else ('controls-reported','record-reported','receipt-reported','handoff-reported')[min(self.completed-5,3)]
  if self.publication_failure is not None:expected_pub='uncertain'
  if c.publication!=expected_pub or self.handoff_complete!=(self.completed==8 and not self.halted):_fail('record/receipt/handoff separate; unknown never replay')

@dataclass(frozen=True,slots=True)
class FinalizationDecision:
 state: FinalizationState
 disposition: str
 reason: str
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  if type(self.state) is not FinalizationState:_fail('exact immutable successor')
  self.state.__post_init__()
  if type(self.disposition) is not str or self.disposition not in DISPOSITIONS or type(self.reason) is not str or self.reason not in REASONS:_fail('closed model decision')
  if self.disposition=='model-advanced' and self.state.halted:_fail('no successful halted result')
  _false(self.authority);_false(self.native_evidence)

def start_finalization(prefix,plan):
 if type(prefix) is not RecoveryState or type(plan) is not FinalizationPlan:_fail('verified guarded344 only')
 return FinalizationState(prefix,plan,prefix.core)
def _result(s,d,r):return FinalizationDecision(s,d,r)
def _failure(event):
 for x in event.raw_statuses:
  if x.code is None or x.code!=0:return x
 return event.raw_statuses[0] if event.raw_statuses else RawStatus('model-finalization-failure',None)
def _pending(state,event,assessment,raw,reason):
 attempted=event.outcome!='unattempted';failure=state.finalization_failure or _failure(event);changes={'rights':assessment.rights,'raw_statuses':raw,'first_failure':state.core.first_failure if state.core.first_failure is not None else failure};wrapper={'halted':True,'finalization_failure':failure,'reserved_phase':None,'attempts':state.attempts+(((event.phase,assessment.operation),) if attempted else ())}
 if attempted:
  changes['phase']=event.phase
  if assessment.operation=='spend-budget':changes['recovery_spent']=state.core.recovery_spent+1
  elif event.phase==PHASES[1] and event.outcome!='known-failure':changes.update(guard='uncertain',target='uncertain');wrapper['target_control']='uncertain'
 if state.completed>=4:changes['publication']='uncertain';wrapper['publication_failure']=failure
 elif wrapper.get('target_control')!='uncertain' and assessment.guard_continuity!='reported-valid':changes.update(guard='lost' if assessment.guard_continuity=='reported-invalid' else 'uncertain',target='uncertain')
 return _result(replace(state,core=replace(state.core,**changes),**wrapper),'model-pending',reason)
def _inputs(state,views,required):
 p=state.prefix;w=p.prefix;b=w.bootstrap;a=b.admission
 stored={'consumed-original-context':a.consumed_view,'continuous-guard-view':b.guard_view,'live-original-fence-view':b.fence_view,'dependency-closure-view':a.dependency_view,'source-closure-view':a.source_view,'original-baseline-view':b.baseline_view,'original-verification-view':p.verification_view,'quiescent-child-view':p.quiescent_view,'armed-traps-view':b.traps_view,'closed-target-evidence-view':None if state.captured is None else state.captured.view,'target-release-view':state.release_view,'publication-control-view':state.controls_view,'publication-record-view':state.record_view,'last-receipt-origin-view':state.receipt_view}
 return all(k in views for k in required) and all(views[k]==stored[k] for k in required if k in stored and stored[k] is not None)
def reduce_finalization(state,event,assessment):
 """Original budget capture/release, then independently controlled captured data."""
 if type(state) is not FinalizationState or type(event) is not ModelEvent or type(assessment) is not FinalizationAssessment:_fail('exact pinned immutable inputs')
 state.__post_init__();event.__post_init__();assessment.__post_init__()
 if event.context!=state.core.context or assessment.context!=state.core.context:return _result(state,'model-rejected','wrong-original')
 if state.halted or state.handoff_complete:return _result(state,'model-rejected','terminal-prefix')
 if event.phase not in PHASES:return _result(state,'model-rejected','unsupported-phase')
 if event.operation!='phase-report' or (event.phase,assessment.operation)!=SEQUENCE[state.completed]:return _result(state,'model-rejected','wrong-order')
 raw=state.core.raw_statuses+event.raw_statuses
 if len(raw)>MAX_RAW_STATUSES:return _result(state,'model-rejected','resource-limit')
 if len({r.call for r in raw})!=len(raw):return _result(state,'model-rejected','duplicate-raw-call')
 def denied(reason):return _pending(state,replace(event,outcome='unattempted',views=(),raw_statuses=()),assessment,state.core.raw_statuses,reason)
 if assessment.operation=='spend-budget' and state.core.recovery_spent>=state.core.recovery_limit:return denied('budget-exhausted')
 if event.phase==PHASES[1] and _artifact_pending(state.prefix):return denied('controller-pending')
 gate=all(getattr(assessment,k)=='reported-valid' for k in COMMON_REPORTS)
 if state.completed<4:
  p=state.prefix.plan
  gate=gate and all(getattr(assessment,k)=='reported-valid' for k in RECOVERY_REPORTS) and state.core.guard=='continuous' and state.core.target=='verified-original' and state.core.children=='drained' and next(x.status for x in assessment.rights if x.window=='recovery')=='reported-live' and assessment.recovery_scope_symbol==p.original_scope_symbol and assessment.recovery_budget_view==p.budget_view and assessment.recovery_elapsed_milliseconds is not None and assessment.recovery_elapsed_milliseconds<p.deadline_milliseconds and (state.last_recovery_elapsed_milliseconds is None or assessment.recovery_elapsed_milliseconds>=state.last_recovery_elapsed_milliseconds)
  if event.phase==PHASES[1]:gate=gate and assessment.controller_obligations_known=='reported-valid' and assessment.captured==state.captured
 else:
  p=state.plan
  gate=gate and all(getattr(assessment,k)=='reported-valid' for k in PUBLICATION_REPORTS) and state.target_control=='reported-released' and assessment.captured==state.captured and next(x.status for x in assessment.rights if x.window=='publication')=='reported-live' and assessment.publication_scope_symbol==p.publication_scope_symbol and assessment.publication_elapsed_milliseconds is not None and assessment.publication_elapsed_milliseconds<p.publication_deadline_milliseconds and (state.last_publication_elapsed_milliseconds is None or assessment.publication_elapsed_milliseconds>=state.last_publication_elapsed_milliseconds)
  gate=gate and all(getattr(assessment,k)==getattr(p,k) for k in ('recipient_symbol','content_symbol','record_symbol','receipt_origin_symbol','handoff_symbol'))
 if not gate:return denied('gate-loss')
 if event.outcome=='unattempted':return _result(state,'model-unattempted','unattempted')
 if event.outcome!='known-success':return _pending(state,event,assessment,raw,'unknown-outcome' if event.outcome=='unknown' else 'known-failure')
 views={x.name:x for x in event.views};required=BUDGET_VIEWS[event.phase] if assessment.operation=='spend-budget' else EFFECT_VIEWS[event.phase]
 positive=len(event.raw_statuses)==1 and event.raw_statuses[0].code==0 and _inputs(state,views,required)
 needed=()
 if assessment.operation=='spend-budget':needed=('budget_durable',)
 elif state.completed==1:needed=('target_evidence_complete',);positive=positive and state.reserved_phase==event.phase
 elif state.completed==3:needed=('release_known','controller_obligations_known');positive=positive and state.reserved_phase==event.phase
 elif state.completed==4:needed=('publication_controls_known',)
 elif state.completed==5:needed=('record_no_replace','record_file_data_durable','record_metadata_durable','record_directory_storage_durable');positive=positive and views.get('publication-record-view') is not None and views['publication-record-view'].symbol==state.plan.record_symbol
 elif state.completed==6:needed=('receipt_no_replace','receipt_file_data_durable','receipt_metadata_durable','receipt_directory_storage_durable','receipt_origin_known');positive=positive and assessment.receipt_record_view==state.record_view and views.get('last-receipt-origin-view') is not None and views['last-receipt-origin-view'].symbol==state.plan.receipt_origin_symbol
 elif state.completed==7:needed=('handoff_durable','handoff_delivery_known');positive=positive and assessment.receipt_record_view==state.record_view
 positive=positive and all(getattr(assessment,k)=='reported-valid' for k in needed)
 if not positive:return _pending(state,event,assessment,raw,'contradictory-positive-report')
 changes={'phase':event.phase,'rights':assessment.rights,'raw_statuses':raw};wrapper={'completed':state.completed+1,'attempts':state.attempts+((event.phase,assessment.operation),)}
 wrapper['last_recovery_elapsed_milliseconds' if state.completed<4 else 'last_publication_elapsed_milliseconds']=assessment.recovery_elapsed_milliseconds if state.completed<4 else assessment.publication_elapsed_milliseconds
 if assessment.operation=='spend-budget':changes['recovery_spent']=state.core.recovery_spent+1;wrapper['reserved_phase']=event.phase
 else:
  wrapper['reserved_phase']=None
  if state.completed==1:
   p=state.prefix;w=p.prefix;wrapper['captured']=CapturedTargetData(state.core.context,views['closed-target-evidence-view'],state.plan.content_symbol,p.verification_view,p.core.raw_statuses,raw,p.core.first_failure,w.ready_for_finalization and not w.stopped,_artifact_pending(p),state.core.recovery_spent)
  elif state.completed==3:changes.update(guard='unobserved',target='unobserved');wrapper.update(release_view=views['target-release-view'],target_control='reported-released')
  elif state.completed==4:changes['publication']='controls-reported';wrapper['controls_view']=views['publication-control-view']
  elif state.completed==5:changes['publication']='record-reported';wrapper['record_view']=views['publication-record-view']
  elif state.completed==6:changes['publication']='receipt-reported';wrapper['receipt_view']=views['last-receipt-origin-view']
  elif state.completed==7:changes['publication']='handoff-reported';wrapper['handoff_complete']=True
 return _result(replace(state,core=replace(state.core,**changes),**wrapper),'model-advanced','advanced')
