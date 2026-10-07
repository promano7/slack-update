"""Pure four-phase model reducer. No ledger, authority, launch or service effects.

The caller SHA-pins unchanged340 under the fixed private dependency alias.
All assessment/view values are assumptions. Repeated evaluation is deterministic,
not global at-most-once execution or real authentication/durability evidence.
"""
from dataclasses import dataclass, fields, replace
from slack_update_offline_core340 import ModelContext, ModelView, RightReport, RawStatus, CoreState, ModelEvent, initial_state, RIGHTS_WINDOWS, MAX_RAW_STATUSES

PHASES = ('service-barrier-authentication', 'service-original-durable-claim', 'service-durable-launch-spend', 'service-single-worker-spawn')
REPORTS = ('reported-valid', 'reported-invalid', 'unobserved')
CHILD_REPORTS = ('unobserved', 'reported-none', 'reported-owned', 'uncertain')
DISPOSITIONS = ('model-advanced', 'model-quarantined', 'model-rejected', 'model-unattempted')
IDENTITY_FIELDS = ('issuer', 'principal', 'known_original', 'original_scope_epoch', 'finite_original_rights', 'dependency_source_closure')
REASONS = ('advanced', 'unattempted', 'wrong-original', 'unsupported-phase', 'wrong-order', 'terminal-prefix', 'identity-not-authenticated', 'gate-loss', 'unknown-outcome', 'known-failure', 'contradictory-positive-report', 'duplicate-raw-call', 'resource-limit')


def _fail(label):raise ValueError(label)
def _false(value):
    if type(value) is not bool or value:_fail('no native authority or evidence')
def _context(value):
    if type(value) is not ModelContext:_fail('exact340 symbolic context required')
    value.__post_init__()
def _report(value):
    if type(value) is not str or value not in REPORTS:_fail('closed symbolic assessment report')
def _view(value, name, context):
    if value is not None:
        if type(value) is not ModelView or value.name != name or value.context != context:_fail('bound immutable original view required')
        value.__post_init__()


@dataclass(frozen=True, slots=True)
class AdmissionAssessment:
    context: ModelContext
    rights: tuple[RightReport, ...]
    service_barrier: str
    issuer: str
    principal: str
    known_original: str
    original_scope_epoch: str
    finite_original_rights: str
    dependency_source_closure: str
    claim_durability: str = 'unobserved'
    launch_durability: str = 'unobserved'
    handoff_prepared: str = 'unobserved'
    handoff_delivery: str = 'unobserved'
    child_observation: str = 'unobserved'
    authority: bool = False
    native_evidence: bool = False

    def __post_init__(self):
        _context(self.context)
        if type(self.rights) is not tuple or tuple(x.window for x in self.rights if type(x) is RightReport) != RIGHTS_WINDOWS or len(self.rights) != 9:
            _fail('all exact original immutable rights reports required')
        for x in self.rights:x.__post_init__()
        for k in ('service_barrier',) + IDENTITY_FIELDS + ('claim_durability', 'launch_durability', 'handoff_prepared', 'handoff_delivery'):_report(getattr(self,k))
        if type(self.child_observation) is not str or self.child_observation not in CHILD_REPORTS:_fail('closed owned-child report')
        _false(self.authority);_false(self.native_evidence)


@dataclass(frozen=True, slots=True)
class AdmissionState:
    core: CoreState
    policy_view: ModelView | None = None
    issuer_view: ModelView | None = None
    dependency_view: ModelView | None = None
    source_view: ModelView | None = None
    consumed_view: ModelView | None = None
    spent_view: ModelView | None = None
    claim_attempted: bool = False
    launch_attempted: bool = False
    spawn_attempted: bool = False
    quarantined: bool = False
    handed_to_worker: bool = False
    authority: bool = False
    native_evidence: bool = False

    def __post_init__(self):
        if type(self.core) is not CoreState:_fail('unchanged340 immutable core required')
        self.core.__post_init__();c=self.core
        for k in ('claim_attempted','launch_attempted','spawn_attempted','quarantined','handed_to_worker'):
            if type(getattr(self,k)) is not bool:_fail('typed irreversible prefix flags')
        _false(self.authority);_false(self.native_evidence)
        _view(self.policy_view,'authenticated-policy-view',c.context)
        _view(self.issuer_view,'issuer-policy-view',c.context)
        _view(self.dependency_view,'dependency-closure-view',c.context)
        _view(self.source_view,'source-closure-view',c.context)
        originals=(self.policy_view,self.issuer_view,self.dependency_view,self.source_view)
        if any(x is not None for x in originals) and not all(x is not None for x in originals):_fail('complete stored service original closure required')
        _view(self.consumed_view,'consumed-original-context',c.context)
        _view(self.spent_view,'spent-launch-view',c.context)
        original=initial_state(c.context)
        mutable=('phase','claim','launch','spawn','children','forward','rights','raw_statuses','first_failure')
        for f in fields(CoreState):
            if f.name not in mutable and getattr(c,f.name)!=getattr(original,f.name):_fail('service prefix cannot acquire worker/target/publication state')
        if c.phase is not None and c.phase not in PHASES:_fail('only four source service phases')
        rank=0 if c.phase is None else PHASES.index(c.phase)+1
        if self.claim_attempted:
            if rank<2 or self.policy_view is None or c.claim not in ('consumed','known-rejected','uncertain'):_fail('irreversible claim prefix')
        elif c.claim!='known-unused' or self.consumed_view is not None or self.launch_attempted:_fail('no premature claim/output/launch')
        if (self.consumed_view is not None)!=(c.claim=='consumed'):_fail('consumed view only from known successful claim')
        if self.launch_attempted:
            if rank<3 or c.claim!='consumed' or self.consumed_view is None:_fail('launch follows original consumption')
        elif c.launch!='unspent' or self.spent_view is not None or self.spawn_attempted:_fail('no premature slot/output/spawn')
        if (self.spent_view is not None)!=(c.launch=='spent'):_fail('spent view only from known durable launch spend')
        if self.spawn_attempted:
            if rank!=4 or c.launch!='spent' or self.spent_view is None or c.spawn not in ('known-owned','known-absent','uncertain'):_fail('one spawn follows known slot spend')
            expected={'known-owned':('known-owned',),'known-absent':('known-none',),'uncertain':('uncertain','known-owned')}[c.spawn]
            if c.children not in expected:_fail('preserve known/possible owned children without promoting unknown spawn ACK')
        elif c.spawn!='unattempted' or c.children!='unobserved' or self.handed_to_worker:_fail('no invented worker/child ownership')
        if rank>=2 and not self.claim_attempted:_fail('claim phase cannot omit attempt')
        if rank>=3 and not self.launch_attempted:_fail('launch phase cannot omit attempt')
        if rank>=4 and not self.spawn_attempted:_fail('spawn phase cannot omit attempt')
        if self.quarantined:
            if c.forward!='stopped' or c.first_failure is None or self.handed_to_worker:_fail('quarantine sticky stop/no handoff')
        else:
            if c.forward!='closed' or c.first_failure is not None:_fail('worker forward stays closed; failure cannot be cleared')
            if any(x.code!=0 for x in c.raw_statuses):_fail('successful prefix cannot erase raw uncertainty/failure')
            if rank:
                reports={x.window:x.status for x in c.rights}
                window='policy' if rank==1 else 'admission' if rank==2 else 'launch'
                if reports[window]!='reported-live' or reports['service']!='reported-live':_fail('successful source window gates retained')
            if rank>=1 and self.policy_view is None:_fail('successful own barrier before claim')
            if self.claim_attempted and c.claim!='consumed':_fail('uncertain/failed claim is terminal')
            if self.launch_attempted and c.launch!='spent':_fail('uncertain/failed spend is terminal')
            if self.spawn_attempted and (c.spawn!='known-owned' or not self.handed_to_worker):_fail('worker handoff requires known ownership')
        if rank==0 and (self.policy_view is not None or self.quarantined or c.raw_statuses or c.rights!=original.rights):_fail('pristine original entry required')


@dataclass(frozen=True, slots=True)
class AdmissionDecision:
    state: AdmissionState
    disposition: str
    reason: str
    authority: bool = False
    native_evidence: bool = False

    def __post_init__(self):
        if type(self.state) is not AdmissionState:_fail('immutable prefix result required')
        self.state.__post_init__()
        if type(self.disposition) is not str or self.disposition not in DISPOSITIONS or type(self.reason) is not str or self.reason not in REASONS:_fail('closed model result')
        if self.disposition=='model-quarantined' and not self.state.quarantined:_fail('quarantine result requires stopped prefix')
        if self.disposition=='model-advanced' and self.state.quarantined:_fail('quarantine cannot claim model advance')
        _false(self.authority);_false(self.native_evidence)


def start_admission(context):
    """Fresh symbolic data only; no grant registry, renewal or real unused proof."""
    return AdmissionState(initial_state(context))


def _result(state,disposition,reason):return AdmissionDecision(state,disposition,reason)
def _next_phase(state):
    return PHASES[0] if state.core.phase is None else PHASES[PHASES.index(state.core.phase)+1] if state.core.phase!=PHASES[-1] else None

def _first_failure(event):
    for raw in event.raw_statuses:
        if raw.code is None or raw.code!=0:return raw
    if event.raw_statuses:return event.raw_statuses[0]
    return RawStatus('model-'+event.phase,None)

def _append_raw(state,event):
    raw=state.core.raw_statuses+event.raw_statuses
    if len({x.call for x in raw})!=len(raw):return None
    return raw


def _quarantine(state,event,assessment,raw,reason,known_failure=False):
    changes={'rights':assessment.rights,'raw_statuses':raw,'first_failure':state.core.first_failure or _first_failure(event),'forward':'stopped'}
    wrapper={'quarantined':True,'handed_to_worker':False}
    # An unattempted report never manufactures a claim/spawn attempt. Loss is terminal.
    if event.outcome!='unattempted':
        changes['phase']=event.phase
        if event.phase==PHASES[1]:
            wrapper['claim_attempted']=True;changes['claim']='known-rejected' if known_failure else 'uncertain'
        elif event.phase==PHASES[2]:
            wrapper['launch_attempted']=True;changes['launch']='unspent' if known_failure else 'uncertain'
        elif event.phase==PHASES[3]:
            wrapper['spawn_attempted']=True
            if known_failure and assessment.child_observation=='reported-none':changes.update(spawn='known-absent',children='known-none')
            elif known_failure and assessment.child_observation=='reported-owned':changes.update(spawn='known-owned',children='known-owned')
            else:changes.update(spawn='uncertain',children='known-owned' if assessment.child_observation=='reported-owned' else 'uncertain')
    elif state.core.phase is None:
        changes['phase']=PHASES[0]
    return _result(replace(state,core=replace(state.core,**changes),**wrapper),'model-quarantined',reason)


def reduce_admission(state,event,assessment):
    """Interpret one declared model report. Return data only; never perform it."""
    if type(state) is not AdmissionState or type(event) is not ModelEvent or type(assessment) is not AdmissionAssessment:_fail('exact pinned immutable inputs required')
    state.__post_init__();event.__post_init__();assessment.__post_init__()
    if event.context!=state.core.context or assessment.context!=state.core.context:return _result(state,'model-rejected','wrong-original')
    if state.quarantined or state.handed_to_worker:return _result(state,'model-rejected','terminal-prefix')
    if event.phase not in PHASES or event.operation!='phase-report':return _result(state,'model-rejected','unsupported-phase')
    if event.phase!=_next_phase(state):return _result(state,'model-rejected','wrong-order')
    if len(state.core.raw_statuses)+len(event.raw_statuses)>MAX_RAW_STATUSES:return _result(state,'model-rejected','resource-limit')
    raw=_append_raw(state,event)
    if raw is None:return _result(state,'model-rejected','duplicate-raw-call')
    identity_valid=all(getattr(assessment,k)=='reported-valid' for k in IDENTITY_FIELDS)
    if not identity_valid and state.core.phase is None:
        # Unauthenticated/unknown entry cannot consume a victim's original grant.
        return _result(state,'model-rejected','identity-not-authenticated')
    required_windows=('service', 'policy' if event.phase==PHASES[0] else 'admission' if event.phase==PHASES[1] else 'launch')
    reports={x.window:x.status for x in assessment.rights}
    gate=identity_valid and assessment.service_barrier=='reported-valid' and all(reports[x]=='reported-live' for x in required_windows)
    if event.phase==PHASES[3]:gate=gate and assessment.handoff_prepared=='reported-valid'
    if not gate:return _quarantine(state,event,assessment,raw,'gate-loss')
    if event.outcome=='unattempted':return _result(state,'model-unattempted','unattempted')
    if event.outcome=='known-failure':return _quarantine(state,event,assessment,raw,'known-failure',known_failure=True)
    if event.outcome=='unknown':return _quarantine(state,event,assessment,raw,'unknown-outcome')
    views={x.name:x for x in event.views}
    expected=(('authenticated-policy-view',),('authenticated-policy-view','consumed-original-context'),('consumed-original-context','spent-launch-view'),('consumed-original-context','spent-launch-view'))[PHASES.index(event.phase)]
    expected=expected+('dependency-closure-view','source-closure-view')+(('issuer-policy-view',) if event.phase==PHASES[0] else ())
    positive=all(k in views for k in expected) and all(x.code==0 for x in event.raw_statuses)
    if event.phase!=PHASES[0]:positive=positive and views.get('dependency-closure-view')==state.dependency_view and views.get('source-closure-view')==state.source_view
    if event.phase==PHASES[1]:positive=positive and views.get('authenticated-policy-view')==state.policy_view and assessment.claim_durability=='reported-valid'
    if event.phase==PHASES[2]:positive=positive and views.get('consumed-original-context')==state.consumed_view and assessment.launch_durability=='reported-valid'
    if event.phase==PHASES[3]:positive=positive and views.get('consumed-original-context')==state.consumed_view and views.get('spent-launch-view')==state.spent_view and assessment.child_observation=='reported-owned' and assessment.handoff_delivery=='reported-valid'
    if not positive:return _quarantine(state,event,assessment,raw,'contradictory-positive-report')
    changes={'phase':event.phase,'rights':assessment.rights,'raw_statuses':raw};wrapper={}
    if event.phase==PHASES[0]:wrapper.update(policy_view=views['authenticated-policy-view'],issuer_view=views['issuer-policy-view'],dependency_view=views['dependency-closure-view'],source_view=views['source-closure-view'])
    elif event.phase==PHASES[1]:changes['claim']='consumed';wrapper.update(claim_attempted=True,consumed_view=views['consumed-original-context'])
    elif event.phase==PHASES[2]:changes['launch']='spent';wrapper.update(launch_attempted=True,spent_view=views['spent-launch-view'])
    else:changes.update(spawn='known-owned',children='known-owned');wrapper.update(spawn_attempted=True,handed_to_worker=True)
    return _result(replace(state,core=replace(state.core,**changes),**wrapper),'model-advanced','advanced')
