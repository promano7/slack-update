"""Pure bounded worker bootstrap/traps/guard model. No native effects or authority.

The caller pins unchanged340/341 under fixed private dependency aliases. Counts,
times, views and positive reports are assumptions, not observed native resources.
"""
from dataclasses import dataclass, fields, replace
from slack_update_offline_core340 import ModelContext, ModelView, RightReport, RawStatus, CoreState, ModelEvent, RIGHTS_WINDOWS, MAX_RAW_STATUSES
from slack_update_offline_admission341 import AdmissionState

PHASES=('worker0-bounded-auth-read','worker0-close-bootstrap','worker0-readonly-preflight','worker1-arm-traps','interstage1-2-guard-freshoriginal')
MAX_BOOTSTRAP_BYTES=65536
BOOTSTRAP_DEADLINE_MS=10000
SYMBOLIC_READ_FD=3
REPORTS=('reported-valid','reported-invalid','unobserved')
COMMON_REPORTS=('original_context','independent_launch','same_scope_epoch','complete_closure','isolated_descriptors','no_worker_service_channel')
OTHER_REPORTS=('bootstrap_canonical','complete_eof','read_end_closed','readonly_observation','trusted_time','live_fence','traps_installed','known_child_control','all_writers_excluded','guard_identity','fresh_original_capture')
DISPOSITIONS=('model-advanced','model-stopped','model-rejected','model-unattempted','model-close-only')
REASONS=('advanced','unattempted','wrong-original','unsupported-phase','wrong-order','terminal-prefix','gate-loss','unknown-outcome','known-failure','contradictory-positive-report','duplicate-raw-call','resource-limit','closed-after-stop')

def _fail(label):raise ValueError(label)
def _false(value):
 if type(value) is not bool or value:_fail('no native authority/evidence')
def _view(value,name,context):
 if value is not None:
  if type(value) is not ModelView or value.name!=name or value.context!=context:_fail('exact original immutable nominal view required')
  value.__post_init__()

@dataclass(frozen=True,slots=True)
class BootstrapAssessment:
 context: ModelContext
 rights: tuple[RightReport,...]
 original_context: str='unobserved'
 independent_launch: str='unobserved'
 same_scope_epoch: str='unobserved'
 complete_closure: str='unobserved'
 isolated_descriptors: str='unobserved'
 no_worker_service_channel: str='unobserved'
 bootstrap_canonical: str='unobserved'
 complete_eof: str='unobserved'
 read_end_closed: str='unobserved'
 readonly_observation: str='unobserved'
 trusted_time: str='unobserved'
 live_fence: str='unobserved'
 traps_installed: str='unobserved'
 known_child_control: str='unobserved'
 all_writers_excluded: str='unobserved'
 guard_identity: str='unobserved'
 fresh_original_capture: str='unobserved'
 raw_bytes: int | None=None
 elapsed_milliseconds: int | None=None
 symbolic_read_fd: int | None=None
 authority: bool=False
 native_evidence: bool=False

 def __post_init__(self):
  if type(self.context) is not ModelContext:_fail('exact340 context required')
  self.context.__post_init__()
  if type(self.rights) is not tuple or len(self.rights)!=9 or tuple(x.window for x in self.rights if type(x) is RightReport)!=RIGHTS_WINDOWS:_fail('all nine ordered immutable original rights required')
  for x in self.rights:x.__post_init__()
  for k in COMMON_REPORTS+OTHER_REPORTS:
   x=getattr(self,k)
   if type(x) is not str or x not in REPORTS:_fail('closed private observation assumption')
  for k in ('raw_bytes','elapsed_milliseconds','symbolic_read_fd'):
   x=getattr(self,k)
   if x is not None and (type(x) is not int or not 0<=x<=2147483647):_fail('bounded exact integer accounting assumption')
  _false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class BootstrapState:
 admission: AdmissionState
 core: CoreState
 completed: int=0
 attempts: tuple[str,...]=()
 bootstrap_view: ModelView | None=None
 early_view: ModelView | None=None
 traps_view: ModelView | None=None
 children_view: ModelView | None=None
 fence_view: ModelView | None=None
 guard_view: ModelView | None=None
 baseline_view: ModelView | None=None
 close_known: bool=False
 stopped: bool=False
 ready_for_owned: bool=False
 authority: bool=False
 native_evidence: bool=False

 def __post_init__(self):
  if type(self.admission) is not AdmissionState or type(self.core) is not CoreState:_fail('exact pinned immutable prefix required')
  self.admission.__post_init__();self.core.__post_init__();a=self.admission;c=self.core
  if not a.handed_to_worker or a.quarantined:_fail('only known consumed/spent/owned single-worker341 handoff')
  if type(self.completed) is not int or not 0<=self.completed<=5:_fail('bounded exact successful prefix length')
  if type(self.attempts) is not tuple or any(type(x) is not str or x not in PHASES for x in self.attempts) or tuple(sorted(set(self.attempts),key=PHASES.index))!=self.attempts:_fail('unique ordered immutable attempts; no replay')
  if self.attempts[:self.completed]!=PHASES[:self.completed]:_fail('each completed phase was attempted in source order')
  for k in ('close_known','stopped','ready_for_owned'):
   if type(getattr(self,k)) is not bool:_fail('exact immutable prefix flags')
  _false(self.authority);_false(self.native_evidence)
  mutable=('phase','bootstrap','traps','guard','baseline','forward','rights','raw_statuses','first_failure')
  for f in fields(CoreState):
   if f.name not in mutable and getattr(c,f.name)!=getattr(a.core,f.name):_fail('no admission reset or premature owned/target/recovery/publication effects')
  if c.phase not in (a.core.phase,)+PHASES:_fail('only five bootstrap/guard source phases')
  if c.raw_statuses[:len(a.core.raw_statuses)]!=a.core.raw_statuses:_fail('original admission raw vector cannot be rewritten')
  for k,name in (('bootstrap_view','closed-bootstrap-view'),('early_view','early-observation-view'),('traps_view','armed-traps-view'),('children_view','known-child-set-view'),('fence_view','live-original-fence-view'),('guard_view','continuous-guard-view'),('baseline_view','original-baseline-view')):_view(getattr(self,k),name,c.context)
  if (self.early_view is not None)!=(self.completed>=3):_fail('readonly observation has its own successful prefix')
  if any((getattr(self,k) is not None)!=(self.completed>=4) for k in ('traps_view','children_view','fence_view')) or c.traps!=(self.completed>=4):_fail('traps/fence/child-control require known stage1 completion')
  if any((getattr(self,k) is not None)!=(self.completed==5) for k in ('guard_view','baseline_view')):_fail('fresh guarded original distinct from early preflight')
  if self.bootstrap_view is None and (self.completed>=1 or self.close_known):_fail('retained bootstrap view required')
  if self.bootstrap_view is not None and self.completed==0 and not self.close_known:_fail('no invented read authentication view')
  if self.close_known:
   if PHASES[1] not in self.attempts or c.bootstrap!='closed':_fail('known closure requires one close attempt')
  elif c.bootstrap=='closed' or self.completed>=2:_fail('no closure from uncertain acknowledgement')
  if self.stopped:
   if c.phase!=(self.attempts[-1] if self.attempts else a.core.phase):_fail('retain exact final attempted phase after stop')
   if c.guard!=c.baseline and (c.guard=='uncertain' or c.baseline=='uncertain'):_fail('uncertain guarded capture retains both obligations')
   if c.forward!='stopped' or c.first_failure is None or self.ready_for_owned or self.completed==5:_fail('sticky stopped original prefix; no worker advance')
   tail=self.attempts[self.completed:]
   allowed=[(),(PHASES[self.completed],)]
   if self.completed<=1:allowed.extend([(PHASES[1],),(PHASES[0],PHASES[1])])
   if tail not in allowed:_fail('only next failed phase and one pending read-close hygiene step')
   if c.bootstrap!=('closed' if self.close_known else 'uncertain'):_fail('stopped bootstrap closure pending unless independently reported closed')
   if c.guard not in ('unobserved','uncertain') or c.baseline not in ('unobserved','uncertain'):_fail('failed guard cannot become a fresh original or be reacquired')
   if (c.guard=='uncertain' or c.baseline=='uncertain') and PHASES[4] not in self.attempts:_fail('no guard/baseline uncertainty before any guard attempt')
  else:
   if self.attempts!=PHASES[:self.completed] or c.phase!=(a.core.phase if self.completed==0 else PHASES[self.completed-1]):_fail('exact successful source prefix')
   if c.first_failure is not None or any(x.code!=0 for x in c.raw_statuses):_fail('successful prefix cannot hide raw failure')
   if c.bootstrap!=('unattempted' if self.completed==0 else 'bounded-read' if self.completed==1 else 'closed') or self.close_known!=(self.completed>=2):_fail('read then known close before readonly preflight')
   if c.guard!=('continuous' if self.completed==5 else 'unobserved') or c.baseline!=('fresh-original' if self.completed==5 else 'unobserved'):_fail('traps precede fresh guarded capture')
   if self.completed:
    reports={x.window:x.status for x in c.rights};window='bootstrap' if self.completed<=3 else 'forward'
    if reports[window]!='reported-live':_fail('successful source rights window retained')
   if self.ready_for_owned!=(self.completed==5) or c.forward!=('active' if self.completed==5 else 'closed'):_fail('model forward opens only after all five prerequisites')

@dataclass(frozen=True,slots=True)
class BootstrapDecision:
 state: BootstrapState
 disposition: str
 reason: str
 authority: bool=False
 native_evidence: bool=False

 def __post_init__(self):
  if type(self.state) is not BootstrapState:_fail('exact immutable model successor required')
  self.state.__post_init__()
  if type(self.disposition) is not str or self.disposition not in DISPOSITIONS or type(self.reason) is not str or self.reason not in REASONS:_fail('closed private model decision')
  if self.disposition in ('model-stopped','model-close-only') and not self.state.stopped:_fail('failure/hygiene cannot reopen forward')
  if self.disposition=='model-advanced' and self.state.stopped:_fail('no forward advance after stop')
  if self.disposition=='model-close-only' and not self.state.close_known:_fail('hygiene success requires known closure')
  _false(self.authority);_false(self.native_evidence)

def start_bootstrap(admission):
 """Wrap already handed341 data; no real handoff or registry lookup."""
 return BootstrapState(admission,admission.core)
def _result(state,decision,reason):return BootstrapDecision(state,decision,reason)
def _failure(event):
 for x in event.raw_statuses:
  if x.code is None or x.code!=0:return x
 return event.raw_statuses[0] if event.raw_statuses else RawStatus('model-'+event.phase,None)
def _stop(state,event,assessment,raw,reason,closed_view=None):
 attempts=state.attempts+((event.phase,) if event.outcome!='unattempted' else ())
 changes={'rights':assessment.rights,'raw_statuses':raw,'first_failure':state.core.first_failure or _failure(event),'forward':'stopped','bootstrap':'closed' if state.close_known or closed_view is not None else 'uncertain'}
 wrapper={'stopped':True,'ready_for_owned':False,'attempts':attempts}
 if event.outcome!='unattempted':changes['phase']=event.phase
 if closed_view is not None:wrapper.update(close_known=True,bootstrap_view=closed_view)
 if event.phase==PHASES[4] and event.outcome!='unattempted':changes.update(guard='uncertain',baseline='uncertain')
 return _result(replace(state,core=replace(state.core,**changes),**wrapper),'model-stopped',reason)
def _original_views(state,views,include_spent=False):
 a=state.admission
 expected={'consumed-original-context':a.consumed_view,'dependency-closure-view':a.dependency_view,'source-closure-view':a.source_view}
 if include_spent:expected['spent-launch-view']=a.spent_view
 return all(views.get(k)==v for k,v in expected.items())
def _close_positive(state,event,assessment,views):
 return event.outcome=='known-success' and all(x.code==0 for x in event.raw_statuses) and _original_views(state,views,True) and 'closed-bootstrap-view' in views and (state.bootstrap_view is None or views['closed-bootstrap-view']==state.bootstrap_view) and assessment.read_end_closed=='reported-valid'

def reduce_bootstrap(state,event,assessment):
 """Interpret one model report, with one close-only hygiene path after failure."""
 if type(state) is not BootstrapState or type(event) is not ModelEvent or type(assessment) is not BootstrapAssessment:_fail('exact pinned immutable inputs required')
 state.__post_init__();event.__post_init__();assessment.__post_init__()
 if event.context!=state.core.context or assessment.context!=state.core.context:return _result(state,'model-rejected','wrong-original')
 hygiene=state.stopped and event.phase==PHASES[1] and not state.close_known and PHASES[1] not in state.attempts and state.completed<=1
 if state.ready_for_owned or (state.stopped and not hygiene):return _result(state,'model-rejected','terminal-prefix')
 if event.phase not in PHASES or event.operation!='phase-report':return _result(state,'model-rejected','unsupported-phase')
 if not hygiene and event.phase!=PHASES[state.completed]:return _result(state,'model-rejected','wrong-order')
 raw=state.core.raw_statuses+event.raw_statuses
 if len(raw)>MAX_RAW_STATUSES:return _result(state,'model-rejected','resource-limit')
 if len({x.call for x in raw})!=len(raw):return _result(state,'model-rejected','duplicate-raw-call')
 views={x.name:x for x in event.views}
 close_positive=event.phase==PHASES[1] and _close_positive(state,event,assessment,views)
 if hygiene:
  if event.outcome=='unattempted':return _result(state,'model-unattempted','unattempted')
  if close_positive:
   core=replace(state.core,phase=event.phase,bootstrap='closed',rights=assessment.rights,raw_statuses=raw)
   successor=replace(state,core=core,attempts=state.attempts+(event.phase,),bootstrap_view=views['closed-bootstrap-view'],close_known=True)
   return _result(successor,'model-close-only','closed-after-stop')
  reason='unknown-outcome' if event.outcome=='unknown' else 'known-failure' if event.outcome=='known-failure' else 'contradictory-positive-report'
  return _stop(state,event,assessment,raw,reason)
 reports={x.window:x.status for x in assessment.rights};window='bootstrap' if state.completed<3 else 'forward'
 gate=all(getattr(assessment,k)=='reported-valid' for k in COMMON_REPORTS) and reports[window]=='reported-live' and assessment.trusted_time=='reported-valid'
 if state.completed>=3:gate=gate and assessment.trusted_time=='reported-valid' and assessment.live_fence=='reported-valid'
 if not gate:return _stop(state,event,assessment,raw,'gate-loss',views['closed-bootstrap-view'] if close_positive else None)
 if event.outcome=='unattempted':return _result(state,'model-unattempted','unattempted')
 if event.outcome!='known-success':return _stop(state,event,assessment,raw,'unknown-outcome' if event.outcome=='unknown' else 'known-failure')
 positive=all(x.code==0 for x in event.raw_statuses) and _original_views(state,views,state.completed<2)
 if state.completed==0:
  positive=positive and 'closed-bootstrap-view' in views and assessment.bootstrap_canonical=='reported-valid' and assessment.complete_eof=='reported-valid' and assessment.raw_bytes is not None and 1<=assessment.raw_bytes<=MAX_BOOTSTRAP_BYTES and assessment.elapsed_milliseconds is not None and assessment.elapsed_milliseconds<BOOTSTRAP_DEADLINE_MS and assessment.symbolic_read_fd==SYMBOLIC_READ_FD
 elif state.completed==1:positive=positive and close_positive
 elif state.completed==2:positive=positive and views.get('closed-bootstrap-view')==state.bootstrap_view and 'early-observation-view' in views and assessment.readonly_observation=='reported-valid'
 elif state.completed==3:positive=positive and all(k in views for k in ('armed-traps-view','known-child-set-view','live-original-fence-view')) and assessment.traps_installed=='reported-valid' and assessment.known_child_control=='reported-valid'
 else:positive=positive and views.get('armed-traps-view')==state.traps_view and views.get('live-original-fence-view')==state.fence_view and all(k in views for k in ('continuous-guard-view','original-baseline-view')) and all(getattr(assessment,k)=='reported-valid' for k in ('all_writers_excluded','guard_identity','fresh_original_capture','known_child_control'))
 if not positive:return _stop(state,event,assessment,raw,'contradictory-positive-report')
 changes={'phase':event.phase,'rights':assessment.rights,'raw_statuses':raw};wrapper={'completed':state.completed+1,'attempts':state.attempts+(event.phase,)}
 if state.completed==0:changes['bootstrap']='bounded-read';wrapper['bootstrap_view']=views['closed-bootstrap-view']
 elif state.completed==1:changes['bootstrap']='closed';wrapper['close_known']=True
 elif state.completed==2:wrapper['early_view']=views['early-observation-view']
 elif state.completed==3:changes['traps']=True;wrapper.update(traps_view=views['armed-traps-view'],children_view=views['known-child-set-view'],fence_view=views['live-original-fence-view'])
 else:changes.update(guard='continuous',baseline='fresh-original',forward='active');wrapper.update(guard_view=views['continuous-guard-view'],baseline_view=views['original-baseline-view'],ready_for_owned=True)
 return _result(replace(state,core=replace(state.core,**changes),**wrapper),'model-advanced','advanced')
