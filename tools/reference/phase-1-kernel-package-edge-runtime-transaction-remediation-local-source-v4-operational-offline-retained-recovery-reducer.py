"""Pure retained-recovery reports over guarded worker343 values; never effects.

Original scope/time/budget durability and positive payloads are private assumptions.
Copying or resetting model values cannot establish native at-most-once behavior.
"""
from dataclasses import dataclass, fields, replace
from types import MappingProxyType
from slack_update_offline_core340 import ModelContext, ModelView, RightReport, RawStatus, CoreState, ModelEvent, RIGHTS_WINDOWS, MAX_RAW_STATUSES
from slack_update_offline_worker343 import WorkerState

PHASES=('stop-forward-irreversibly', 'drain-known-owned-children', 'worker9-original-restoration', 'worker10-original-verification')
BUDGET_VIEWS=MappingProxyType({'drain-known-owned-children': ('consumed-original-context', 'continuous-guard-view', 'live-original-fence-view', 'dependency-closure-view', 'source-closure-view', 'armed-traps-view', 'known-child-set-view'), 'stop-forward-irreversibly': ('consumed-original-context', 'dependency-closure-view', 'live-original-fence-view', 'source-closure-view'), 'worker10-original-verification': ('consumed-original-context', 'continuous-guard-view', 'live-original-fence-view', 'dependency-closure-view', 'source-closure-view', 'original-baseline-view', 'quiescent-child-view'), 'worker9-original-restoration': ('consumed-original-context', 'continuous-guard-view', 'live-original-fence-view', 'dependency-closure-view', 'source-closure-view', 'original-baseline-view', 'quiescent-child-view', 'complete-effect-graph-view', 'recovery-budget-view')})
EFFECT_VIEWS=MappingProxyType({'drain-known-owned-children': ('consumed-original-context', 'continuous-guard-view', 'live-original-fence-view', 'dependency-closure-view', 'source-closure-view', 'armed-traps-view', 'known-child-set-view', 'quiescent-child-view'), 'stop-forward-irreversibly': ('consumed-original-context', 'dependency-closure-view', 'live-original-fence-view', 'source-closure-view'), 'worker10-original-verification': ('consumed-original-context', 'continuous-guard-view', 'live-original-fence-view', 'dependency-closure-view', 'source-closure-view', 'original-baseline-view', 'quiescent-child-view', 'original-verification-view'), 'worker9-original-restoration': ('consumed-original-context', 'continuous-guard-view', 'live-original-fence-view', 'dependency-closure-view', 'source-closure-view', 'original-baseline-view', 'quiescent-child-view', 'complete-effect-graph-view', 'recovery-budget-view', 'original-restoration-result-view', 'package-effect-result-view')})
REPORTS=('reported-valid','reported-invalid','unobserved')
COMMON_REPORTS=('same_original','original_scope','safe_boot','safe_phase','known_earlier_outcomes','guard_continuity','live_recovery_fence','trusted_time','known_owned_children','source_closure','original_memory_baseline','no_worker_service_channel','persistent_stop','preserve_owned_artifacts','owned_canonical_paths','all_writers_excluded','approved_original_deltas')
ACTION_REPORTS=('budget_durable','quiescence_known','backups_verified','restoration_exact','full_original_invariants','target_known_unchanged')
DISPOSITIONS=('model-advanced','model-pending','model-rejected','model-unattempted')
REASONS=('advanced','unattempted','wrong-original','unsupported-phase','wrong-order','terminal-prefix','gate-loss','budget-exhausted','blocked-target','unknown-outcome','known-failure','contradictory-positive-report','duplicate-raw-call','resource-limit')

def _fail(label):raise ValueError(label)
def _false(x):
 if type(x) is not bool or x:_fail('no native authority/evidence')
def _context(x):
 if type(x) is not ModelContext:_fail('exact340 immutable context')
 x.__post_init__()
def _view(x,name,context):
 if type(x) is not ModelView or x.name!=name or x.context!=context:_fail('exact original immutable nominal view')
 x.__post_init__()
def _branch(prefix):
 c=prefix.core
 if c.guard!='continuous' or c.baseline!='fresh-original' or not c.traps or c.bootstrap!='closed':return 'blocked'
 if c.target=='known-changed' and c.backups=='verified-original':return 'restore-original'
 if c.target=='known-unchanged' or (c.target=='unobserved' and prefix.completed==0):return 'verify-unchanged'
 return 'blocked'
def _sequence(branch):
 phases=(PHASES[1],PHASES[2],PHASES[3]) if branch=='restore-original' else (PHASES[1],PHASES[3]) if branch=='verify-unchanged' else (PHASES[1],)
 return ((PHASES[0],'effect-report'),)+tuple((p,o) for p in phases for o in ('spend-budget','effect-report'))

@dataclass(frozen=True,slots=True)
class RecoveryPlan:
 context: ModelContext
 budget_limit: int
 deadline_milliseconds: int
 original_scope_symbol: str
 budget_view: ModelView
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  _context(self.context);_view(self.budget_view,'recovery-budget-view',self.context)
  if type(self.budget_limit) is not int or not 0<=self.budget_limit<=8:_fail('private fixture finite original budget0..8')
  if type(self.deadline_milliseconds) is not int or not 1<=self.deadline_milliseconds<=2147483647:_fail('finite private original deadline')
  ModelContext(self.original_scope_symbol,'model-scope-check').__post_init__();_false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class RecoveryAssessment:
 context: ModelContext
 rights: tuple[RightReport,...]
 operation: str
 budget_view: ModelView
 original_scope_symbol: str
 elapsed_milliseconds: int | None=None
 same_original: str='unobserved'
 original_scope: str='unobserved'
 safe_boot: str='unobserved'
 safe_phase: str='unobserved'
 known_earlier_outcomes: str='unobserved'
 guard_continuity: str='unobserved'
 live_recovery_fence: str='unobserved'
 trusted_time: str='unobserved'
 known_owned_children: str='unobserved'
 source_closure: str='unobserved'
 original_memory_baseline: str='unobserved'
 no_worker_service_channel: str='unobserved'
 persistent_stop: str='unobserved'
 preserve_owned_artifacts: str='unobserved'
 owned_canonical_paths: str='unobserved'
 all_writers_excluded: str='unobserved'
 approved_original_deltas: str='unobserved'
 budget_durable: str='unobserved'
 quiescence_known: str='unobserved'
 backups_verified: str='unobserved'
 restoration_exact: str='unobserved'
 full_original_invariants: str='unobserved'
 target_known_unchanged: str='unobserved'
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  _context(self.context);_view(self.budget_view,'recovery-budget-view',self.context)
  ModelContext(self.original_scope_symbol,'model-scope-check').__post_init__()
  if type(self.rights) is not tuple or len(self.rights)!=9 or tuple(x.window for x in self.rights if type(x) is RightReport)!=RIGHTS_WINDOWS:_fail('all nine exact ordered rights')
  for x in self.rights:x.__post_init__()
  if type(self.operation) is not str or self.operation not in ('spend-budget','effect-report'):_fail('private observation within unchanged source phase')
  if self.elapsed_milliseconds is not None and (type(self.elapsed_milliseconds) is not int or not 0<=self.elapsed_milliseconds<=2147483647):_fail('exact bounded private elapsed time or unobserved')
  for k in COMMON_REPORTS+ACTION_REPORTS:
   if type(getattr(self,k)) is not str or getattr(self,k) not in REPORTS:_fail('closed report assumption')
  _false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class RecoveryState:
 prefix: WorkerState
 plan: RecoveryPlan
 core: CoreState
 branch: str
 completed: int=0
 attempts: tuple[tuple[str,str],...]=()
 reserved_phase: str | None=None
 quiescent_view: ModelView | None=None
 restoration_view: ModelView | None=None
 verification_view: ModelView | None=None
 recovery_failure: RawStatus | None=None
 halted: bool=False
 ready_for_target_evidence: bool=False
 binding_pending: bool=False
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  if type(self.prefix) is not WorkerState or type(self.plan) is not RecoveryPlan or type(self.core) is not CoreState:_fail('exact guarded worker/plan/core')
  self.prefix.__post_init__();self.plan.__post_init__();self.core.__post_init__();p=self.prefix.core;c=self.core
  if self.plan.context!=p.context or c.context!=p.context:_fail('same immutable original')
  if type(self.branch) is not str or self.branch!=_branch(self.prefix):_fail('branch derived only from original guarded prefix')
  seq=_sequence(self.branch)
  if type(self.completed) is not int or not 0<=self.completed<=len(seq):_fail('bounded known recovery prefix')
  if type(self.attempts) is not tuple or self.attempts not in (seq[:self.completed],seq[:self.completed+1]):_fail('exact ordered successes plus at most one failed report')
  for k in ('halted','ready_for_target_evidence','binding_pending'):
   if type(getattr(self,k)) is not bool:_fail('exact model flags')
  _false(self.authority);_false(self.native_evidence)
  if c.forward!='stopped':_fail('irreversible model forward stop')
  mutable=('phase','forward','guard','children','target','recovery_limit','recovery_spent','rights','raw_statuses','first_failure')
  for f in fields(CoreState):
   if f.name not in mutable and getattr(c,f.name)!=getattr(p,f.name):_fail('no admission/launch/pin/baseline/backup/owned/publication reset')
  if c.recovery_limit!=self.plan.budget_limit or c.recovery_spent!=sum(o=='spend-budget' for _,o in self.attempts):_fail('all attempted spends burnt exactly once, never refunded')
  if c.raw_statuses[:len(p.raw_statuses)]!=p.raw_statuses:_fail('immutable complete original raw vector')
  if self.recovery_failure is not None:
   if type(self.recovery_failure) is not RawStatus:_fail('exact separate recovery failure')
   self.recovery_failure.__post_init__()
  if c.first_failure!=(p.first_failure if p.first_failure is not None else self.recovery_failure):_fail('first original failure cannot be laundered by recovery')
  if self.halted!=(self.recovery_failure is not None):_fail('sticky separate recovery failure and pending halt')
  if not self.halted and self.attempts!=seq[:self.completed]:_fail('no failed attempted report in successful prefix')
  expected_reservation=seq[self.completed-1][0] if self.completed and seq[self.completed-1][1]=='spend-budget' and not self.halted else None
  if self.reserved_phase!=expected_reservation:_fail('spend must precede its single phase effect; no reuse')
  phase=p.phase if not self.attempts else self.attempts[-1][0]
  if c.phase!=phase:_fail('last attempted source phase retained')
  for field,name,phase_name in (('quiescent_view','quiescent-child-view',PHASES[1]),('restoration_view','original-restoration-result-view',PHASES[2]),('verification_view','original-verification-view',PHASES[3])):
   present=(phase_name,'effect-report') in seq[:self.completed]
   v=getattr(self,field)
   if (v is not None)!=present:_fail('only exact known successful original outputs')
   if v is not None:_view(v,name,c.context)
  verified=self.verification_view is not None
  if self.ready_for_target_evidence!=(verified and not self.halted):_fail('verified original only prepares next target evidence module')
  if self.binding_pending!=(self.prefix.binding_status not in ('unattempted','complete')):_fail('partial or unknown binding obligations independently retained')
  expected_children='drained' if self.quiescent_view is not None else p.children
  allowed_children=(expected_children,'uncertain') if self.halted and len(self.attempts)>self.completed and self.attempts[-1]==(PHASES[1],'effect-report') else (expected_children,)
  if c.children not in allowed_children:_fail('known drain before restoration/verification')
  expected_target='verified-original' if verified else 'known-restored' if self.restoration_view is not None else p.target
  affected=self.halted and len(self.attempts)>self.completed and self.attempts[-1][1]=='effect-report' and self.attempts[-1][0] in PHASES[2:]
  if c.target not in ((expected_target,'uncertain') if affected else (expected_target,)):_fail('no invented original restoration/verification')
  if c.guard!=p.guard and not (self.halted and c.guard in ('lost','uncertain')):_fail('no guard reacquire or release')
  if verified and (c.children!='drained' or c.guard!='continuous' or self.branch=='blocked'):_fail('full original verification under original guard and known quiescence')
  if self.restoration_view is not None and (self.branch!='restore-original' or p.backups!='verified-original'):_fail('never require/invent backup for unchanged verification')

@dataclass(frozen=True,slots=True)
class RecoveryDecision:
 state: RecoveryState
 disposition: str
 reason: str
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  if type(self.state) is not RecoveryState:_fail('exact immutable recovery successor')
  self.state.__post_init__()
  if type(self.disposition) is not str or self.disposition not in DISPOSITIONS or type(self.reason) is not str or self.reason not in REASONS:_fail('closed model decision')
  if self.disposition=='model-advanced' and self.state.halted:_fail('no successful halted prefix')
  _false(self.authority);_false(self.native_evidence)

def start_recovery(prefix,plan):
 if type(prefix) is not WorkerState or type(plan) is not RecoveryPlan:_fail('guarded343 prefix only; no early guard acquisition')
 prefix.__post_init__();plan.__post_init__()
 return RecoveryState(prefix,plan,replace(prefix.core,forward='stopped',recovery_limit=plan.budget_limit),_branch(prefix),binding_pending=prefix.binding_status not in ('unattempted','complete'))
def _result(state,disposition,reason):return RecoveryDecision(state,disposition,reason)
def _failure(event):
 for raw in event.raw_statuses:
  if raw.code is None or raw.code!=0:return raw
 return event.raw_statuses[0] if event.raw_statuses else RawStatus('model-recovery-failure',None)
def _pending(state,event,assessment,raw,reason):
 attempted=event.outcome!='unattempted';token=(event.phase,assessment.operation);failure=state.recovery_failure or _failure(event)
 changes={'rights':assessment.rights,'raw_statuses':raw,'first_failure':state.core.first_failure if state.core.first_failure is not None else failure}
 wrapper={'halted':True,'recovery_failure':failure,'reserved_phase':None,'attempts':state.attempts+((token,) if attempted else ())}
 if attempted:
  changes['phase']=event.phase
  if assessment.operation=='spend-budget':changes['recovery_spent']=state.core.recovery_spent+1
  elif event.phase==PHASES[1] and event.outcome!='known-failure':changes['children']='uncertain'
  elif event.phase in PHASES[2:] and event.outcome!='known-failure':changes['target']='uncertain'
 if assessment.guard_continuity!='reported-valid':changes['guard']='lost' if assessment.guard_continuity=='reported-invalid' else 'uncertain'
 return _result(replace(state,core=replace(state.core,**changes),**wrapper),'model-pending',reason)
def _inputs(state,views,required):
 w=state.prefix;b=w.bootstrap;a=b.admission
 stored={'consumed-original-context':a.consumed_view,'dependency-closure-view':a.dependency_view,'source-closure-view':a.source_view,'continuous-guard-view':b.guard_view,'live-original-fence-view':b.fence_view,'armed-traps-view':b.traps_view,'known-child-set-view':b.children_view,'original-baseline-view':b.baseline_view,'quiescent-child-view':state.quiescent_view,'complete-effect-graph-view':w.plan.graph.view,'recovery-budget-view':state.plan.budget_view}
 return all(k in views for k in required) and all(views[k]==stored[k] for k in required if k in stored and stored[k] is not None)
def reduce_recovery(state,event,assessment):
 """One private spend/effect observation, with no native dispatch or new rights."""
 if type(state) is not RecoveryState or type(event) is not ModelEvent or type(assessment) is not RecoveryAssessment:_fail('exact pinned immutable inputs')
 state.__post_init__();event.__post_init__();assessment.__post_init__()
 if event.context!=state.core.context or assessment.context!=state.core.context:return _result(state,'model-rejected','wrong-original')
 seq=_sequence(state.branch)
 if state.halted or state.completed==len(seq):return _result(state,'model-rejected','terminal-prefix')
 if event.phase not in PHASES:return _result(state,'model-rejected','unsupported-phase')
 if event.operation!='phase-report' or (event.phase,assessment.operation)!=seq[state.completed]:return _result(state,'model-rejected','wrong-order')
 raw=state.core.raw_statuses+event.raw_statuses
 if len(raw)>MAX_RAW_STATUSES:return _result(state,'model-rejected','resource-limit')
 if len({r.call for r in raw})!=len(raw):return _result(state,'model-rejected','duplicate-raw-call')
 # Budget exhaustion denies a spend; do not ingest a purported attempted action.
 if assessment.operation=='spend-budget' and state.core.recovery_spent>=state.plan.budget_limit:
  empty=replace(event,outcome='unattempted',views=(),raw_statuses=())
  return _pending(state,empty,assessment,state.core.raw_statuses,'budget-exhausted')
 gate=all(getattr(assessment,k)=='reported-valid' for k in COMMON_REPORTS)
 if event.phase!=PHASES[0]:
  gate=gate and all(getattr(assessment,k)=='reported-valid' for k in COMMON_REPORTS) and next(x.status for x in assessment.rights if x.window=='recovery')=='reported-live' and state.core.guard=='continuous' and state.core.traps and state.core.baseline=='fresh-original' and state.core.bootstrap=='closed' and state.core.children in ('known-owned','drained') and assessment.budget_view==state.plan.budget_view and assessment.original_scope_symbol==state.plan.original_scope_symbol and assessment.elapsed_milliseconds is not None and assessment.elapsed_milliseconds<state.plan.deadline_milliseconds
  if event.phase==PHASES[2]:gate=gate and state.branch=='restore-original' and state.core.backups=='verified-original' and state.core.target=='known-changed' and state.core.children=='drained' and assessment.backups_verified=='reported-valid'
  if event.phase==PHASES[3]:gate=gate and state.branch!='blocked' and state.core.children=='drained' and state.core.target==('known-restored' if state.branch=='restore-original' else state.prefix.core.target)
 if not gate:
  # Denied gates cannot burn a new spend; a prior reservation remains burned.
  denied=replace(event,outcome='unattempted',views=(),raw_statuses=())
  return _pending(state,denied,assessment,state.core.raw_statuses,'gate-loss')
 if event.outcome=='unattempted':return _result(state,'model-unattempted','unattempted')
 if event.outcome!='known-success':return _pending(state,event,assessment,raw,'unknown-outcome' if event.outcome=='unknown' else 'known-failure')
 required=BUDGET_VIEWS[event.phase] if assessment.operation=='spend-budget' else EFFECT_VIEWS[event.phase]
 positive=len(event.raw_statuses)==1 and event.raw_statuses[0].code==0 and _inputs(state,{v.name:v for v in event.views},required)
 if assessment.operation=='spend-budget':positive=positive and assessment.budget_durable=='reported-valid'
 elif event.phase==PHASES[1]:positive=positive and assessment.quiescence_known=='reported-valid' and state.reserved_phase==event.phase
 elif event.phase==PHASES[2]:positive=positive and assessment.restoration_exact=='reported-valid' and state.reserved_phase==event.phase
 elif event.phase==PHASES[3]:positive=positive and assessment.full_original_invariants=='reported-valid' and state.reserved_phase==event.phase and (state.branch!='verify-unchanged' or assessment.target_known_unchanged=='reported-valid')
 if not positive:return _pending(state,event,assessment,raw,'contradictory-positive-report')
 changes={'phase':event.phase,'rights':assessment.rights,'raw_statuses':raw};wrapper={'completed':state.completed+1,'attempts':state.attempts+((event.phase,assessment.operation),)}
 if assessment.operation=='spend-budget':changes['recovery_spent']=state.core.recovery_spent+1;wrapper['reserved_phase']=event.phase
 else:
  wrapper['reserved_phase']=None;views={v.name:v for v in event.views}
  if event.phase==PHASES[1]:changes['children']='drained';wrapper['quiescent_view']=views['quiescent-child-view']
  elif event.phase==PHASES[2]:changes['target']='known-restored';wrapper['restoration_view']=views['original-restoration-result-view']
  elif event.phase==PHASES[3]:changes['target']='verified-original';wrapper.update(verification_view=views['original-verification-view'],ready_for_target_evidence=True)
 return _result(replace(state,core=replace(state.core,**changes),**wrapper),'model-advanced','advanced')
