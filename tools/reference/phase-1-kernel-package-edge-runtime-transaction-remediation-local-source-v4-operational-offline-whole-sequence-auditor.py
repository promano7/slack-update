"""Finite pure composition audit; explicit model reports, never native dispatch.

The five unchanged reducers remain private-assumption interpreters. Model values can
be copied/reset/re-evaluated: neither this trace nor its digest is native once proof.
"""
from dataclasses import dataclass, replace
from slack_update_offline_core340 import ModelContext, CoreState, ModelEvent
from slack_update_offline_admission341 import AdmissionState, AdmissionAssessment, start_admission, reduce_admission
from slack_update_offline_bootstrap342 import BootstrapState, BootstrapAssessment, start_bootstrap, reduce_bootstrap
from slack_update_offline_worker343 import WorkerState, WorkerAssessment, WorkerPlan, start_worker, reduce_worker
from slack_update_offline_recovery344 import RecoveryState, RecoveryAssessment, RecoveryPlan, start_recovery, reduce_recovery
from slack_update_offline_finalization345 import FinalizationState, FinalizationAssessment, FinalizationPlan, start_finalization, reduce_finalization

FAMILIES=('admission','bootstrap','worker','recovery','finalization')
STATE_TYPES=(AdmissionState,BootstrapState,WorkerState,RecoveryState,FinalizationState)
ASSESSMENT_TYPES=(AdmissionAssessment,BootstrapAssessment,WorkerAssessment,RecoveryAssessment,FinalizationAssessment)
TRANSFERS=(('admission','bootstrap'),('bootstrap','worker'),('worker','recovery'),('recovery','finalization'))
MAX_OPERATIONS=128
DISPOSITIONS=('model-advanced','model-pending','model-stopped','model-quarantined','model-close-only','model-unattempted','model-rejected','model-transfer')

def _fail(label):raise ValueError(label)
def _false(x):
 if type(x) is not bool or x:_fail('no native evidence/authority')
def _context(x):
 if type(x) is not ModelContext:_fail('exact immutable340 original')
 x.__post_init__()
def _core(state):
 if type(state) not in STATE_TYPES:_fail('closed typed family state')
 state.__post_init__();return state.core
def _elapsed(x):
 if x is not None and (type(x) is not int or not 0<=x<=2147483647):_fail('bounded private elapsed time')

@dataclass(frozen=True,slots=True)
class WholePlan:
 context: ModelContext
 worker: WorkerPlan
 recovery: RecoveryPlan
 finalization: FinalizationPlan
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  _context(self.context)
  for value,cls in ((self.worker,WorkerPlan),(self.recovery,RecoveryPlan),(self.finalization,FinalizationPlan)):
   if type(value) is not cls or value.context!=self.context:_fail('same original fixed worker/recovery/publication plans')
   value.__post_init__()
  _false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class ReportOperation:
 event: ModelEvent
 assessment: AdmissionAssessment | BootstrapAssessment | WorkerAssessment | RecoveryAssessment | FinalizationAssessment
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  if type(self.event) is not ModelEvent or type(self.assessment) not in ASSESSMENT_TYPES:_fail('exact closed immutable report input')
  self.event.__post_init__();self.assessment.__post_init__();_false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class TransferOperation:
 context: ModelContext
 next_family: str
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  _context(self.context)
  if type(self.next_family) is not str or self.next_family not in FAMILIES:_fail('closed private transfer destination')
  _false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class AuditEntry:
 index: int
 kind: str
 family_before: str
 family_after: str
 before: CoreState
 after: CoreState
 disposition: str
 reason: str
 recovery_elapsed_before: int | None
 recovery_elapsed_after: int | None
 publication_elapsed_before: int | None
 publication_elapsed_after: int | None
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  if type(self.index) is not int or not 0<=self.index<MAX_OPERATIONS:_fail('bounded operation index')
  if type(self.kind) is not str or self.kind not in ('report','transfer','clock-denial'):_fail('closed audit operation kind')
  for value in (self.family_before,self.family_after):
   if type(value) is not str or value not in FAMILIES:_fail('closed typed family')
  if type(self.before) is not CoreState or type(self.after) is not CoreState:_fail('exact immutable core projections')
  self.before.__post_init__();self.after.__post_init__()
  if self.before.context!=self.after.context or self.after.raw_statuses[:len(self.before.raw_statuses)]!=self.before.raw_statuses:_fail('same original complete raw lineage')
  if self.before.first_failure is not None and self.after.first_failure!=self.before.first_failure:_fail('original first failure cannot disappear')
  if self.before.forward=='stopped' and self.after.forward!='stopped':_fail('no forward revival')
  if self.after.recovery_spent<self.before.recovery_spent:_fail('no budget refund')
  for old,new in ((self.recovery_elapsed_before,self.recovery_elapsed_after),(self.publication_elapsed_before,self.publication_elapsed_after)):
   _elapsed(old);_elapsed(new)
   if old is not None and (new is None or new<old):_fail('no clock rollback or erase in composed ledger')
  if type(self.disposition) is not str or self.disposition not in DISPOSITIONS or type(self.reason) is not str or not self.reason:_fail('closed decision/nonempty model reason')
  if self.disposition=='model-rejected' and (self.before!=self.after or self.family_before!=self.family_after or self.recovery_elapsed_before!=self.recovery_elapsed_after or self.publication_elapsed_before!=self.publication_elapsed_after):_fail('rejected operation cannot mutate inner model or time')
  _false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class SequenceAudit:
 plan: WholePlan
 operations: tuple[ReportOperation | TransferOperation,...]
 entries: tuple[AuditEntry,...]
 final_family: str
 final_state: AdmissionState | BootstrapState | WorkerState | RecoveryState | FinalizationState
 recovery_elapsed: int | None
 publication_elapsed: int | None
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  if type(self.plan) is not WholePlan:_fail('exact whole plan')
  self.plan.__post_init__()
  if type(self.operations) is not tuple or not 0<=len(self.operations)<=MAX_OPERATIONS or any(type(x) not in (ReportOperation,TransferOperation) for x in self.operations):_fail('finite immutable explicit operations')
  for x in self.operations:x.__post_init__()
  if type(self.entries) is not tuple or len(self.entries)!=len(self.operations):_fail('one audit entry per explicit private operation')
  core=start_admission(self.plan.context).core;family='admission';recovery=None;publication=None
  for i,entry in enumerate(self.entries):
   if type(entry) is not AuditEntry:_fail('exact immutable entry')
   entry.__post_init__()
   if entry.index!=i or entry.before!=core or entry.family_before!=family or entry.recovery_elapsed_before!=recovery or entry.publication_elapsed_before!=publication:_fail('complete ordered original core/time lineage')
   if entry.kind=='transfer' and type(self.operations[i]) is not TransferOperation:_fail('transfer only from explicit private operation')
   if entry.kind!='transfer' and type(self.operations[i]) is not ReportOperation:_fail('report only from typed private operation')
   core=entry.after;family=entry.family_after;recovery=entry.recovery_elapsed_after;publication=entry.publication_elapsed_after
  if type(self.final_family) is not str or self.final_family!=family or type(self.final_state) is not STATE_TYPES[FAMILIES.index(family)] or _core(self.final_state)!=core or core.context!=self.plan.context:_fail('exact final original typed projection')
  if self.recovery_elapsed!=recovery or self.publication_elapsed!=publication:_fail('retained final time ledger')
  for k in ('worker','recovery','finalization'):
   if FAMILIES.index(family)>=FAMILIES.index(k):
    value=self.final_state if family==k else self.final_state.prefix if (family,k) in (('recovery','worker'),('finalization','recovery')) else self.final_state.prefix.prefix
    if value.plan!=getattr(self.plan,k):_fail('unchanged original plans through typed transfers')
  _false(self.authority);_false(self.native_evidence)

def _transfer(plan,family,state,destination):
 if (family,destination) not in TRANSFERS:return state,family,'model-rejected','wrong-transfer-order'
 try:
  if destination=='bootstrap':after=start_bootstrap(state)
  elif destination=='worker':after=start_worker(state,plan.worker)
  elif destination=='recovery':after=start_recovery(state,plan.recovery)
  else:after=start_finalization(state,plan.finalization)
 except (ValueError,TypeError):return state,family,'model-rejected','transfer-gate-loss'
 return after,destination,'model-transfer','transferred'
def _reduce(family,state,event,assessment):
 if family=='admission':return reduce_admission(state,event,assessment)
 if family=='bootstrap':return reduce_bootstrap(state,event,assessment)
 if family=='worker':return reduce_worker(state,event,assessment)
 if family=='recovery':return reduce_recovery(state,event,assessment)
 return reduce_finalization(state,event,assessment)
def audit_sequence(plan,operations):
 """Evaluate bounded declared reports from fresh model data, never a native run."""
 if type(plan) is not WholePlan:_fail('exact fixed immutable whole plan')
 plan.__post_init__()
 if type(operations) is not tuple or len(operations)>MAX_OPERATIONS or any(type(x) not in (ReportOperation,TransferOperation) for x in operations):_fail('bounded explicit immutable operation vector')
 for x in operations:x.__post_init__()
 family='admission';state=start_admission(plan.context);entries=[];recovery=None;publication=None
 for i,operation in enumerate(operations):
  before=_core(state);old_family=family;old_recovery=recovery;old_publication=publication;kind='transfer' if type(operation) is TransferOperation else 'report'
  if type(operation) is TransferOperation:
   if operation.context!=plan.context:disposition='model-rejected';reason='wrong-original'
   else:state,family,disposition,reason=_transfer(plan,family,state,operation.next_family)
  elif type(operation.assessment) is not ASSESSMENT_TYPES[FAMILIES.index(family)]:disposition='model-rejected';reason='assessment-family'
  else:
   event=operation.event;assessment=operation.assessment;clock=None;clock_name=None;clock_field=None
   if family=='recovery':clock=assessment.elapsed_milliseconds;clock_name='recovery';clock_field='trusted_time'
   elif family=='finalization':
    if state.completed<4:clock=assessment.recovery_elapsed_milliseconds;clock_name='recovery';clock_field='trusted_time'
    else:clock=assessment.publication_elapsed_milliseconds;clock_name='publication';clock_field='publication_time'
   previous=recovery if clock_name=='recovery' else publication
   bound=event.context==plan.context and assessment.context==plan.context
   rollback=bound and clock is not None and previous is not None and clock<previous
   if rollback:
    assessment=replace(assessment,**{clock_field:'reported-invalid'});event=replace(event,outcome='unattempted',views=(),raw_statuses=())
   decision=_reduce(family,state,event,assessment);disposition=decision.disposition;reason=decision.reason
   if rollback and disposition in ('model-pending','model-stopped'):kind='clock-denial';reason='clock-rollback'
   if disposition!='model-rejected':
    state=decision.state
    if clock_name is not None and bound and not rollback and clock is not None and getattr(assessment,clock_field)=='reported-valid':
     if clock_name=='recovery':recovery=clock
     else:publication=clock
  entries.append(AuditEntry(i,kind,old_family,family,before,_core(state),disposition,reason,old_recovery,recovery,old_publication,publication))
 return SequenceAudit(plan,operations,tuple(entries),family,state,recovery,publication)
