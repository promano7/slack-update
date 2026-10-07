"""Pure worker stages and whole-successor reports. Never native effects/authority.

Caller SHA-pins unchanged340/341/342. Full graph/selector/effect fields are private
assumptions; static model coverage is never native dynamic graph conformance.
"""
from dataclasses import dataclass, fields, replace
from types import MappingProxyType
from slack_update_offline_core340 import ModelContext, ModelView, RightReport, RawStatus, CoreState, ModelEvent, RIGHTS_WINDOWS, MAX_RAW_STATUSES
from slack_update_offline_bootstrap342 import BootstrapState

PHASES=('worker2-owned-workspace', 'worker3-original-backups', 'worker4-exact-predecessor', 'worker5-local-isolation', 'worker6-refresh-pin-once', 'worker7-validate-pinned-candidate', 'worker7-owned-durable-commit', 'worker8-whole-successor-apply')
MICROSTEPS=('validate-exact-inputs', 'register-owned-intent', 'create-exclusive-stage', 'write-complete-bytes', 'metadata-and-data-durable', 'revalidate-pinned-inputs', 'commit-no-replace', 'directory-durability-confirmed', 'stage-exit-evidence-complete')
DOMAIN_IDS=('issuer-policy-and-key-provisioning', 'durable-admission-claim', 'durable-single-launch-slot', 'offline-bootstrap-context', 'trusted-time-and-revocation-fence', 'worker-readonly-preflight', 'worker-traps-and-child-control', 'outer-writer-guard-and-original-baseline', 'owned-runtime-and-original-backups', 'predecessor-and-local-isolation', 'stage7-owned-binding', 'whole-reference-entry', 'reference-lock-runtime-logs', 'reference-snapshots-and-config-scan', 'reference-GenInitrd-mutation', 'reference-optional-module-mutation', 'reference-boot-mutation', 'nested-call-adapter', 'real-backend-and-selector', 'package-tools-and-install-hooks', 'source-and-archive-consumption', 'interpreter-helper-dependency-consumption', 'owned-child-quiescence', 'same-attempt-original-restoration', 'target-evidence-closure', 'target-control-release', 'publication-controls', 'publication-record', 'publication-last-receipt', 'unresolved-dynamic-helpers-and-dependencies')
MACRO_RELATIONS=(('durable-admission-claim', 'durable-single-launch-slot'), ('durable-single-launch-slot', 'offline-bootstrap-context'), ('offline-bootstrap-context', 'worker-readonly-preflight'), ('worker-readonly-preflight', 'worker-traps-and-child-control'), ('worker-traps-and-child-control', 'outer-writer-guard-and-original-baseline'), ('outer-writer-guard-and-original-baseline', 'owned-runtime-and-original-backups'), ('owned-runtime-and-original-backups', 'predecessor-and-local-isolation'), ('predecessor-and-local-isolation', 'stage7-owned-binding'), ('stage7-owned-binding', 'whole-reference-entry'), ('whole-reference-entry', 'reference-lock-runtime-logs'), ('whole-reference-entry', 'reference-snapshots-and-config-scan'), ('whole-reference-entry', 'reference-GenInitrd-mutation'), ('whole-reference-entry', 'reference-optional-module-mutation'), ('whole-reference-entry', 'reference-boot-mutation'), ('whole-reference-entry', 'nested-call-adapter'), ('nested-call-adapter', 'real-backend-and-selector'), ('real-backend-and-selector', 'package-tools-and-install-hooks'), ('package-tools-and-install-hooks', 'source-and-archive-consumption'), ('package-tools-and-install-hooks', 'interpreter-helper-dependency-consumption'), ('whole-reference-entry', 'owned-child-quiescence'), ('owned-child-quiescence', 'same-attempt-original-restoration'), ('same-attempt-original-restoration', 'target-evidence-closure'), ('target-evidence-closure', 'target-control-release'), ('target-control-release', 'publication-controls'), ('publication-controls', 'publication-record'), ('publication-record', 'publication-last-receipt'), ('issuer-policy-and-key-provisioning', 'unresolved-dynamic-helpers-and-dependencies'), ('durable-admission-claim', 'unresolved-dynamic-helpers-and-dependencies'), ('durable-single-launch-slot', 'issuer-policy-and-key-provisioning'), ('durable-single-launch-slot', 'unresolved-dynamic-helpers-and-dependencies'), ('offline-bootstrap-context', 'issuer-policy-and-key-provisioning'), ('offline-bootstrap-context', 'unresolved-dynamic-helpers-and-dependencies'), ('trusted-time-and-revocation-fence', 'unresolved-dynamic-helpers-and-dependencies'), ('worker-readonly-preflight', 'issuer-policy-and-key-provisioning'), ('worker-readonly-preflight', 'unresolved-dynamic-helpers-and-dependencies'), ('worker-traps-and-child-control', 'issuer-policy-and-key-provisioning'), ('worker-traps-and-child-control', 'trusted-time-and-revocation-fence'), ('worker-traps-and-child-control', 'unresolved-dynamic-helpers-and-dependencies'), ('outer-writer-guard-and-original-baseline', 'issuer-policy-and-key-provisioning'), ('outer-writer-guard-and-original-baseline', 'trusted-time-and-revocation-fence'), ('outer-writer-guard-and-original-baseline', 'unresolved-dynamic-helpers-and-dependencies'), ('owned-runtime-and-original-backups', 'issuer-policy-and-key-provisioning'), ('owned-runtime-and-original-backups', 'trusted-time-and-revocation-fence'), ('owned-runtime-and-original-backups', 'unresolved-dynamic-helpers-and-dependencies'), ('predecessor-and-local-isolation', 'issuer-policy-and-key-provisioning'), ('predecessor-and-local-isolation', 'trusted-time-and-revocation-fence'), ('predecessor-and-local-isolation', 'unresolved-dynamic-helpers-and-dependencies'), ('stage7-owned-binding', 'issuer-policy-and-key-provisioning'), ('stage7-owned-binding', 'trusted-time-and-revocation-fence'), ('stage7-owned-binding', 'unresolved-dynamic-helpers-and-dependencies'), ('whole-reference-entry', 'issuer-policy-and-key-provisioning'), ('whole-reference-entry', 'trusted-time-and-revocation-fence'), ('whole-reference-entry', 'unresolved-dynamic-helpers-and-dependencies'), ('reference-lock-runtime-logs', 'issuer-policy-and-key-provisioning'), ('reference-lock-runtime-logs', 'trusted-time-and-revocation-fence'), ('reference-lock-runtime-logs', 'unresolved-dynamic-helpers-and-dependencies'), ('reference-snapshots-and-config-scan', 'issuer-policy-and-key-provisioning'), ('reference-snapshots-and-config-scan', 'trusted-time-and-revocation-fence'), ('reference-snapshots-and-config-scan', 'unresolved-dynamic-helpers-and-dependencies'), ('reference-GenInitrd-mutation', 'unresolved-dynamic-helpers-and-dependencies'), ('reference-optional-module-mutation', 'unresolved-dynamic-helpers-and-dependencies'), ('reference-boot-mutation', 'unresolved-dynamic-helpers-and-dependencies'), ('nested-call-adapter', 'issuer-policy-and-key-provisioning'), ('nested-call-adapter', 'trusted-time-and-revocation-fence'), ('nested-call-adapter', 'unresolved-dynamic-helpers-and-dependencies'), ('real-backend-and-selector', 'issuer-policy-and-key-provisioning'), ('real-backend-and-selector', 'trusted-time-and-revocation-fence'), ('real-backend-and-selector', 'unresolved-dynamic-helpers-and-dependencies'), ('package-tools-and-install-hooks', 'issuer-policy-and-key-provisioning'), ('package-tools-and-install-hooks', 'trusted-time-and-revocation-fence'), ('package-tools-and-install-hooks', 'unresolved-dynamic-helpers-and-dependencies'), ('source-and-archive-consumption', 'issuer-policy-and-key-provisioning'), ('source-and-archive-consumption', 'trusted-time-and-revocation-fence'), ('source-and-archive-consumption', 'unresolved-dynamic-helpers-and-dependencies'), ('interpreter-helper-dependency-consumption', 'issuer-policy-and-key-provisioning'), ('interpreter-helper-dependency-consumption', 'trusted-time-and-revocation-fence'), ('interpreter-helper-dependency-consumption', 'unresolved-dynamic-helpers-and-dependencies'), ('owned-child-quiescence', 'issuer-policy-and-key-provisioning'), ('owned-child-quiescence', 'trusted-time-and-revocation-fence'), ('owned-child-quiescence', 'unresolved-dynamic-helpers-and-dependencies'), ('same-attempt-original-restoration', 'issuer-policy-and-key-provisioning'), ('same-attempt-original-restoration', 'trusted-time-and-revocation-fence'), ('same-attempt-original-restoration', 'unresolved-dynamic-helpers-and-dependencies'), ('target-evidence-closure', 'issuer-policy-and-key-provisioning'), ('target-evidence-closure', 'trusted-time-and-revocation-fence'), ('target-evidence-closure', 'unresolved-dynamic-helpers-and-dependencies'), ('target-control-release', 'issuer-policy-and-key-provisioning'), ('target-control-release', 'trusted-time-and-revocation-fence'), ('target-control-release', 'unresolved-dynamic-helpers-and-dependencies'), ('publication-controls', 'issuer-policy-and-key-provisioning'), ('publication-controls', 'unresolved-dynamic-helpers-and-dependencies'), ('publication-record', 'issuer-policy-and-key-provisioning'), ('publication-record', 'unresolved-dynamic-helpers-and-dependencies'), ('publication-last-receipt', 'issuer-policy-and-key-provisioning'), ('publication-last-receipt', 'unresolved-dynamic-helpers-and-dependencies'))
REQUIRED_VIEWS=MappingProxyType({'worker2-owned-workspace': ('consumed-original-context', 'continuous-guard-view', 'live-original-fence-view', 'dependency-closure-view', 'source-closure-view', 'original-baseline-view', 'owned-path-set-view'), 'worker3-original-backups': ('consumed-original-context', 'continuous-guard-view', 'live-original-fence-view', 'dependency-closure-view', 'source-closure-view', 'original-baseline-view', 'owned-path-set-view', 'original-backups-view'), 'worker4-exact-predecessor': ('consumed-original-context', 'continuous-guard-view', 'live-original-fence-view', 'dependency-closure-view', 'source-closure-view', 'original-backups-view', 'exact-predecessor-view', 'complete-effect-graph-view', 'package-effect-result-view'), 'worker5-local-isolation': ('consumed-original-context', 'continuous-guard-view', 'live-original-fence-view', 'dependency-closure-view', 'source-closure-view', 'original-backups-view', 'exact-predecessor-view', 'isolated-config-view'), 'worker6-refresh-pin-once': ('consumed-original-context', 'continuous-guard-view', 'live-original-fence-view', 'dependency-closure-view', 'source-closure-view', 'original-backups-view', 'exact-predecessor-view', 'isolated-config-view', 'complete-effect-graph-view', 'raw-pkglist-pin-view', 'full-selector-vector-view'), 'worker7-owned-durable-commit': ('consumed-original-context', 'continuous-guard-view', 'live-original-fence-view', 'dependency-closure-view', 'source-closure-view', 'raw-pkglist-pin-view', 'candidate-binding-view'), 'worker7-validate-pinned-candidate': ('consumed-original-context', 'continuous-guard-view', 'live-original-fence-view', 'dependency-closure-view', 'source-closure-view', 'raw-pkglist-pin-view', 'candidate-binding-view'), 'worker8-whole-successor-apply': ('candidate-binding-view', 'complete-effect-graph-view', 'consumed-original-context', 'contained-runtime-view', 'contained-snapshot-view', 'continuous-guard-view', 'dependency-closure-view', 'full-selector-vector-view', 'live-original-fence-view', 'nested-call-result-view', 'original-baseline-view', 'owned-path-set-view', 'package-effect-result-view', 'raw-pkglist-pin-view', 'source-closure-view', 'whole-entry-result-view')})
WHOLE_OBSERVATIONS=('nested-update','nested-install-new','nested-upgrade-all','whole-entry-complete')
SEQUENCE=tuple((p,'phase-report','none') for p in PHASES[:6])+tuple((PHASES[6],m,'none') for m in MICROSTEPS)+tuple((PHASES[7],'phase-report',m) for m in WHOLE_OBSERVATIONS)
BINDING_STATES=('unattempted','validated','intent-recorded','staged','bytes-written','file-durable','revalidated','visible','directory-durable','complete')
REPORTS=('reported-valid','reported-invalid','unobserved')
COMMON_REPORTS=('same_original','same_scope_epoch','complete_closure','guard_continuity','trusted_time','live_fence','known_child_control','fd_namespace_containment','no_worker_service_channel','complete_graph','full_effect_scope','original_approved_delta','source_archive_consumption','backend_selector_provenance','no_forbidden_boot_optional_effects','retained_interpreter_consumption')
STAGE_REPORTS=('original_capture_match','owned_whitelist','backups_verified','predecessor_delta','isolation_delta','refresh_fresh_regular','refresh_nonempty','refresh_stdout_clean','refresh_stderr_clean','candidate_exact','ancestor_alias_controls','exclusive_stage','complete_bytes','file_metadata_durable','directory_storage_durable','no_replace','stage_exit_evidence','whole_entry_equivalence','contained_runtime','contained_snapshots','forward_latch','install_new_no_effect','package_hooks_scope')
DISPOSITIONS=('model-advanced','model-stopped','model-rejected','model-unattempted')
REASONS=('advanced','unattempted','wrong-original','unsupported-phase','wrong-order','terminal-prefix','gate-loss','unknown-outcome','known-failure','contradictory-positive-report','duplicate-raw-call','resource-limit')

def _fail(label):raise ValueError(label)
def _false(x):
 if type(x) is not bool or x:_fail('no native authority/evidence')
def _context(x):
 if type(x) is not ModelContext:_fail('exact340 immutable context')
 x.__post_init__()
def _symbol(x):ModelContext(x,'model-symbol-check').__post_init__()
def _view(x,name,context):
 if type(x) is not ModelView or x.name!=name or x.context!=context:_fail('exact original immutable nominal view')
 x.__post_init__()
def _vector(x):
 if type(x) is not tuple or len(x)>4096:_fail('bounded immutable complete vector')
 for v in x:_symbol(v)
 if len(set(x))!=len(x):_fail('selector cannot hide duplicate targets')

@dataclass(frozen=True,slots=True)
class GraphReport:
 context: ModelContext
 view: ModelView
 entry_symbol: str
 domains: tuple[str,...]
 relations: tuple[tuple[str,str],...]
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  _context(self.context);_view(self.view,'complete-effect-graph-view',self.context);_symbol(self.entry_symbol)
  if type(self.domains) is not tuple or any(type(x) is not str for x in self.domains) or self.domains!=DOMAIN_IDS:_fail('all original30 designed domains in source order')
  if type(self.relations) is not tuple or any(type(x) is not tuple or len(x)!=2 or any(type(y) is not str for y in x) for x in self.relations) or self.relations!=MACRO_RELATIONS:_fail('all original95 macro relations; not native call edges')
  _false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class WorkerPlan:
 context: ModelContext
 graph: GraphReport
 target_symbol: str
 archive_symbol: str
 expected_row: tuple[str,...]
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  _context(self.context)
  if type(self.graph) is not GraphReport or self.graph.context!=self.context:_fail('same original full declared graph')
  self.graph.__post_init__();_symbol(self.target_symbol);_symbol(self.archive_symbol)
  if type(self.expected_row) is not tuple or len(self.expected_row)!=8:_fail('independent original eight-field expected row')
  for x in self.expected_row:_symbol(x)
  if self.expected_row[0]!=self.target_symbol:_fail('private row target bound to original plan')
  _false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class SelectorReport:
 context: ModelContext
 pin: ModelView
 source_symbol: str
 config_symbol: str
 db_symbol: str
 backend_version: str
 selector_version: str
 blacklist_symbol: str
 priority_symbol: str
 repository_symbol: str
 architecture_symbol: str
 filter_symbol: str
 target_symbol: str
 install_new: tuple[str,...]
 upgrade_all: tuple[str,...]
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  _context(self.context);_view(self.pin,'raw-pkglist-pin-view',self.context)
  for k in ('source_symbol','config_symbol','db_symbol','backend_version','selector_version','blacklist_symbol','priority_symbol','repository_symbol','architecture_symbol','filter_symbol','target_symbol'):_symbol(getattr(self,k))
  _vector(self.install_new);_vector(self.upgrade_all);_false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class CandidateReport:
 context: ModelContext
 pin: ModelView
 source: ModelView
 predecessor: ModelView
 archive_symbol: str
 row: tuple[str,...]
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  _context(self.context);_view(self.pin,'raw-pkglist-pin-view',self.context);_view(self.source,'source-closure-view',self.context);_view(self.predecessor,'exact-predecessor-view',self.context);_symbol(self.archive_symbol)
  if type(self.row) is not tuple or len(self.row)!=8:_fail('complete exact eight-field candidate report')
  for x in self.row:_symbol(x)
  _false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class WorkerAssessment:
 context: ModelContext
 rights: tuple[RightReport,...]
 graph: GraphReport | None=None
 selector: SelectorReport | None=None
 candidate: CandidateReport | None=None
 successor_observation: str='none'
 nested_statuses: tuple[RawStatus,...]=()
 same_original: str='unobserved'
 same_scope_epoch: str='unobserved'
 complete_closure: str='unobserved'
 guard_continuity: str='unobserved'
 trusted_time: str='unobserved'
 live_fence: str='unobserved'
 known_child_control: str='unobserved'
 fd_namespace_containment: str='unobserved'
 no_worker_service_channel: str='unobserved'
 complete_graph: str='unobserved'
 full_effect_scope: str='unobserved'
 original_approved_delta: str='unobserved'
 source_archive_consumption: str='unobserved'
 backend_selector_provenance: str='unobserved'
 no_forbidden_boot_optional_effects: str='unobserved'
 retained_interpreter_consumption: str='unobserved'
 original_capture_match: str='unobserved'
 owned_whitelist: str='unobserved'
 backups_verified: str='unobserved'
 predecessor_delta: str='unobserved'
 isolation_delta: str='unobserved'
 refresh_fresh_regular: str='unobserved'
 refresh_nonempty: str='unobserved'
 refresh_stdout_clean: str='unobserved'
 refresh_stderr_clean: str='unobserved'
 candidate_exact: str='unobserved'
 ancestor_alias_controls: str='unobserved'
 exclusive_stage: str='unobserved'
 complete_bytes: str='unobserved'
 file_metadata_durable: str='unobserved'
 directory_storage_durable: str='unobserved'
 no_replace: str='unobserved'
 stage_exit_evidence: str='unobserved'
 whole_entry_equivalence: str='unobserved'
 contained_runtime: str='unobserved'
 contained_snapshots: str='unobserved'
 forward_latch: str='unobserved'
 install_new_no_effect: str='unobserved'
 package_hooks_scope: str='unobserved'
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  _context(self.context)
  if type(self.rights) is not tuple or len(self.rights)!=9 or tuple(x.window for x in self.rights if type(x) is RightReport)!=RIGHTS_WINDOWS:_fail('all nine ordered immutable rights')
  for x in self.rights:x.__post_init__()
  for k,t in (('graph',GraphReport),('selector',SelectorReport),('candidate',CandidateReport)):
   v=getattr(self,k)
   if v is not None:
    if type(v) is not t or v.context!=self.context:_fail('bound exact immutable declaration')
    v.__post_init__()
  if type(self.successor_observation) is not str or self.successor_observation not in ('none',)+WHOLE_OBSERVATIONS:_fail('closed private observations within original worker8 phase')
  if type(self.nested_statuses) is not tuple or len(self.nested_statuses)>3 or any(type(x) is not RawStatus for x in self.nested_statuses):_fail('exact immutable nested raw reports')
  for x in self.nested_statuses:x.__post_init__()
  for k in COMMON_REPORTS+STAGE_REPORTS:
   v=getattr(self,k)
   if type(v) is not str or v not in REPORTS:_fail('closed private report assumption')
  _false(self.authority);_false(self.native_evidence)

@dataclass(frozen=True,slots=True)
class WorkerState:
 bootstrap: BootstrapState
 plan: WorkerPlan
 core: CoreState
 completed: int=0
 attempts: tuple[tuple[str,str,str],...]=()
 owned_view: ModelView | None=None
 backups_view: ModelView | None=None
 predecessor_view: ModelView | None=None
 isolation_view: ModelView | None=None
 pin_view: ModelView | None=None
 selector_view: ModelView | None=None
 selector: SelectorReport | None=None
 candidate_view: ModelView | None=None
 candidate: CandidateReport | None=None
 whole_view: ModelView | None=None
 update_raw: RawStatus | None=None
 install_raw: RawStatus | None=None
 upgrade_raw: RawStatus | None=None
 binding_status: str='unattempted'
 stopped: bool=False
 ready_for_finalization: bool=False
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  if type(self.bootstrap) is not BootstrapState or type(self.plan) is not WorkerPlan or type(self.core) is not CoreState:_fail('pinned immutable bootstrap/plan/core')
  self.bootstrap.__post_init__();self.plan.__post_init__();self.core.__post_init__();b=self.bootstrap;c=self.core
  if not b.ready_for_owned or b.stopped or self.plan.context!=c.context:_fail('same known five-phase342 ready original')
  if type(self.completed) is not int or not 0<=self.completed<=len(SEQUENCE):_fail('bounded exact successful worker prefix')
  if type(self.attempts) is not tuple or self.attempts not in (SEQUENCE[:self.completed],SEQUENCE[:self.completed+1]):_fail('only source-ordered successful prefix and one failed next attempt')
  for k in ('stopped','ready_for_finalization'):
   if type(getattr(self,k)) is not bool:_fail('exact immutable prefix flag')
  _false(self.authority);_false(self.native_evidence)
  mutable=('phase','guard','backups','pin','stage7_completed','forward','owned','target','rights','raw_statuses','first_failure')
  for f in fields(CoreState):
   if f.name not in mutable and getattr(c,f.name)!=getattr(b.core,f.name):_fail('no bootstrap/admission/baseline/traps/children/recovery/publication reset')
  if c.raw_statuses[:len(b.core.raw_statuses)]!=b.core.raw_statuses:_fail('original raw prefix cannot be erased')
  for k,name,rank in (('owned_view','owned-path-set-view',1),('backups_view','original-backups-view',2),('predecessor_view','exact-predecessor-view',3),('isolation_view','isolated-config-view',4),('pin_view','raw-pkglist-pin-view',5),('selector_view','full-selector-vector-view',5),('candidate_view','candidate-binding-view',6),('whole_view','whole-entry-result-view',19)):
   v=getattr(self,k)
   if (v is not None)!=(self.completed>=rank):_fail('outputs only from known complete original phase')
   if v is not None:_view(v,name,c.context)
  if (self.selector is not None)!=(self.completed>=5) or (self.candidate is not None)!=(self.completed>=6):_fail('pin and candidate declarations have exact source prefixes')
  if self.selector is not None:
   if type(self.selector) is not SelectorReport:_fail('exact immutable full selector')
   self.selector.__post_init__()
   if self.selector.context!=c.context or self.selector.pin!=self.pin_view or self.selector.source_symbol!=b.admission.source_view.symbol or self.selector.config_symbol!=self.isolation_view.symbol or self.selector.db_symbol!=self.predecessor_view.symbol or self.selector.target_symbol!=self.plan.target_symbol or self.selector.install_new!=() or self.selector.upgrade_all!=(self.plan.target_symbol,):_fail('full original selector basis/vectors immutable')
  if self.candidate is not None:
   if type(self.candidate) is not CandidateReport:_fail('exact immutable candidate')
   self.candidate.__post_init__()
   if self.candidate.context!=c.context or self.candidate.pin!=self.pin_view or self.candidate.source!=b.admission.source_view or self.candidate.predecessor!=self.predecessor_view or self.candidate.archive_symbol!=self.plan.archive_symbol or self.candidate.row!=self.plan.expected_row:_fail('candidate cannot define its own expected original')
  if c.pin!=(None if self.pin_view is None else self.pin_view.symbol):_fail('one raw pin retained; no rehash/rebind')
  micro=max(0,min(9,self.completed-6))
  if c.stage7_completed!=micro or type(self.binding_status) is not str or self.binding_status not in BINDING_STATES+('uncertain',):_fail('exact successful durable microstep count')
  expected_binding=BINDING_STATES[micro]
  if self.binding_status!=expected_binding and not (self.stopped and self.binding_status=='uncertain' and len(self.attempts)>self.completed and self.attempts[-1][0]==PHASES[6]):_fail('visible/partial/unknown binding is not durable completion')
  for k,rank,codes in (('update_raw',16,(0,)),('install_raw',17,(0,20)),('upgrade_raw',18,(0,))):
   v=getattr(self,k)
   if (v is not None)!=(self.completed>=rank):_fail('nested result only from exact known attempted prefix')
   if v is not None:
    if type(v) is not RawStatus or v.code not in codes or v not in c.raw_statuses:_fail('preserve exact successful nested raw0/20 rules')
    v.__post_init__()
  phase=b.core.phase if not self.attempts else self.attempts[-1][0]
  if c.phase!=phase:_fail('exact last attempted source phase')
  if self.stopped:
   if c.forward!='stopped' or c.first_failure is None or self.ready_for_finalization or self.completed==19:_fail('sticky stop; no worker relaunch/retry or finalization success')
   if c.guard not in ('continuous','lost','uncertain'):_fail('guard loss remains pending without reacquire')
   owned_values=('unobserved','known-none','uncertain') if self.completed==0 else ('known-binding',)
   if self.completed==0 and c.owned!='unobserved' and (not self.attempts or self.attempts[-1][0]!=PHASES[0]):_fail('workspace knowledge requires an attempted workspace phase')
   targets=('unobserved','uncertain') if self.completed==0 else ('known-unchanged','uncertain') if self.completed<3 else ('known-changed','uncertain')
   if c.target not in targets:_fail('worker failure cannot invent original restoration or verification')
   if c.backups=='uncertain' and (not self.attempts or self.attempts[-1][0]!=PHASES[1] or self.completed!=1):_fail('backup uncertainty requires its own attempted original backup phase')
   if c.owned not in owned_values:_fail('preserve known/possible owned workspace')
   if c.backups not in (('unobserved','uncertain') if self.completed<2 else ('verified-original',)):_fail('never invent verified original backup')
  else:
   if self.attempts!=SEQUENCE[:self.completed] or c.first_failure is not None or c.guard!='continuous':_fail('successful linear prefix with continuous original guard')
   if any(x.code!=0 and x!=self.install_raw for x in c.raw_statuses):_fail('success cannot launder raw failure;20 only stored empty install-new')
   if c.owned!=('unobserved' if self.completed==0 else 'known-binding') or c.backups!=('unobserved' if self.completed<2 else 'verified-original'):_fail('workspace then verified original backup')
   if c.target!=('unobserved' if self.completed==0 else 'known-unchanged' if self.completed<3 else 'known-changed'):_fail('only approved original-to-predecessor/config/target deltas')
   if c.forward!='active' or self.ready_for_finalization!=(self.completed==19):_fail('final whole completion separate from mere nested calls')
   if self.completed and next(x.status for x in c.rights if x.window=='forward')!='reported-live':_fail('original forward rights retained')

@dataclass(frozen=True,slots=True)
class WorkerDecision:
 state: WorkerState
 disposition: str
 reason: str
 authority: bool=False
 native_evidence: bool=False
 def __post_init__(self):
  if type(self.state) is not WorkerState:_fail('exact immutable worker successor')
  self.state.__post_init__()
  if type(self.disposition) is not str or self.disposition not in DISPOSITIONS or type(self.reason) is not str or self.reason not in REASONS:_fail('closed model decision')
  if self.disposition=='model-stopped' and not self.state.stopped:_fail('stopped result must retain stop')
  if self.disposition=='model-advanced' and self.state.stopped:_fail('no success from stopped prefix')
  _false(self.authority);_false(self.native_evidence)

def start_worker(bootstrap,plan):return WorkerState(bootstrap,plan,bootstrap.core)
def _result(s,d,r):return WorkerDecision(s,d,r)
def _failure(event):
 for x in event.raw_statuses:
  if x.code is None or x.code!=0:return x
 return event.raw_statuses[0] if event.raw_statuses else RawStatus('model-worker-failure',None)
def _stop(state,event,assessment,raw,reason):
 attempted=event.outcome!='unattempted';token=SEQUENCE[state.completed]
 changes={'rights':assessment.rights,'raw_statuses':raw,'first_failure':state.core.first_failure or _failure(event),'forward':'stopped'}
 wrapper={'stopped':True,'ready_for_finalization':False,'attempts':state.attempts+((token,) if attempted else ())}
 if attempted:changes['phase']=event.phase
 if assessment.guard_continuity!='reported-valid':changes['guard']='lost' if assessment.guard_continuity=='reported-invalid' else 'uncertain'
 if attempted and event.phase==PHASES[0]:changes['owned']='known-none' if event.outcome=='known-failure' else 'uncertain'
 if attempted and event.phase==PHASES[1] and event.outcome!='known-failure':changes['backups']='uncertain'
 if attempted and event.outcome!='known-failure' and (event.phase in (PHASES[0],PHASES[2],PHASES[3],PHASES[4],PHASES[7]) or assessment.original_approved_delta!='reported-valid'):changes['target']='uncertain'
 if attempted and event.phase==PHASES[6] and event.outcome!='known-failure':wrapper['binding_status']='uncertain'
 return _result(replace(state,core=replace(state.core,**changes),**wrapper),'model-stopped',reason)
def _inputs(state,views,required):
 b=state.bootstrap;a=b.admission
 stored={'consumed-original-context':a.consumed_view,'dependency-closure-view':a.dependency_view,'source-closure-view':a.source_view,'continuous-guard-view':b.guard_view,'live-original-fence-view':b.fence_view,'original-baseline-view':b.baseline_view,'owned-path-set-view':state.owned_view,'original-backups-view':state.backups_view,'exact-predecessor-view':state.predecessor_view,'isolated-config-view':state.isolation_view,'raw-pkglist-pin-view':state.pin_view,'full-selector-vector-view':state.selector_view,'candidate-binding-view':state.candidate_view,'complete-effect-graph-view':state.plan.graph.view}
 return all(k in views for k in required) and all(views[k]==stored[k] for k in required if k in stored and stored[k] is not None)
def _selector_ok(state,value,pin):
 return value is not None and value.context==state.core.context and value.pin==pin and value.source_symbol==state.bootstrap.admission.source_view.symbol and value.config_symbol==state.isolation_view.symbol and value.db_symbol==state.predecessor_view.symbol and value.target_symbol==state.plan.target_symbol and value.install_new==() and value.upgrade_all==(state.plan.target_symbol,)
def _candidate_ok(state,value):
 return value is not None and value.pin==state.pin_view and value.source==state.bootstrap.admission.source_view and value.predecessor==state.predecessor_view and value.archive_symbol==state.plan.archive_symbol and value.row==state.plan.expected_row

def reduce_worker(state,event,assessment):
 """One immutable report in19 private observations over eight source phases."""
 if type(state) is not WorkerState or type(event) is not ModelEvent or type(assessment) is not WorkerAssessment:_fail('exact pinned immutable inputs')
 state.__post_init__();event.__post_init__();assessment.__post_init__()
 if event.context!=state.core.context or assessment.context!=state.core.context:return _result(state,'model-rejected','wrong-original')
 if state.stopped or state.ready_for_finalization:return _result(state,'model-rejected','terminal-prefix')
 if event.phase not in PHASES:return _result(state,'model-rejected','unsupported-phase')
 token=(event.phase,event.operation,assessment.successor_observation)
 if token!=SEQUENCE[state.completed]:return _result(state,'model-rejected','wrong-order')
 raw=state.core.raw_statuses+event.raw_statuses
 if len(raw)>MAX_RAW_STATUSES:return _result(state,'model-rejected','resource-limit')
 if len({x.call for x in raw})!=len(raw):return _result(state,'model-rejected','duplicate-raw-call')
 gate=all(getattr(assessment,k)=='reported-valid' for k in COMMON_REPORTS) and next(x.status for x in assessment.rights if x.window=='forward')=='reported-live' and assessment.graph==state.plan.graph
 if state.completed>=2:gate=gate and assessment.backups_verified=='reported-valid'
 if not gate:return _stop(state,event,assessment,raw,'gate-loss')
 if event.outcome=='unattempted':return _result(state,'model-unattempted','unattempted')
 if event.outcome!='known-success':return _stop(state,event,assessment,raw,'unknown-outcome' if event.outcome=='unknown' else 'known-failure')
 views={x.name:x for x in event.views};required=REQUIRED_VIEWS[event.phase]
 if event.phase==PHASES[7] and state.completed<18:required=tuple(k for k in required if k not in ('whole-entry-result-view','contained-runtime-view','contained-snapshot-view','nested-call-result-view','package-effect-result-view'))
 positive=bool(event.raw_statuses) and _inputs(state,views,required)
 nested_install=state.completed==16
 positive=positive and all(x.code==0 or (nested_install and x.code==20) for x in event.raw_statuses)
 needed=()
 if state.completed==0:needed=('original_capture_match','owned_whitelist','ancestor_alias_controls')
 elif state.completed==1:needed=('backups_verified','original_capture_match','owned_whitelist')
 elif state.completed==2:needed=('predecessor_delta','backups_verified','package_hooks_scope')
 elif state.completed==3:needed=('isolation_delta','backups_verified')
 elif state.completed==4:
  needed=('refresh_fresh_regular','refresh_nonempty','refresh_stdout_clean','refresh_stderr_clean','forward_latch')
  positive=positive and _selector_ok(state,assessment.selector,views.get('raw-pkglist-pin-view'))
 elif state.completed==5:needed=('candidate_exact',);positive=positive and _candidate_ok(state,assessment.candidate)
 elif state.completed<15:
  needed=(('candidate_exact',),('owned_whitelist','ancestor_alias_controls'),('exclusive_stage','ancestor_alias_controls'),('complete_bytes',),('file_metadata_durable',),('candidate_exact','original_approved_delta'),('no_replace','ancestor_alias_controls'),('directory_storage_durable',),('stage_exit_evidence','file_metadata_durable','directory_storage_durable'))[state.completed-6]
  positive=positive and assessment.candidate==state.candidate and assessment.selector==state.selector
 else:
  positive=positive and assessment.selector==state.selector and assessment.candidate==state.candidate and state.binding_status=='complete' and state.core.stage7_completed==9
  needed=('forward_latch','package_hooks_scope')
  if state.completed==15:needed+=('refresh_fresh_regular','refresh_nonempty','refresh_stdout_clean','refresh_stderr_clean');positive=positive and len(event.raw_statuses)==1
  elif state.completed==16:needed+=('install_new_no_effect',);positive=positive and len(event.raw_statuses)==1 and event.raw_statuses[0].code in (0,20)
  elif state.completed==17:positive=positive and len(event.raw_statuses)==1 and event.raw_statuses[0].code==0
  else:
   needed+=('whole_entry_equivalence','contained_runtime','contained_snapshots','stage_exit_evidence')
   positive=positive and assessment.nested_statuses==(state.update_raw,state.install_raw,state.upgrade_raw)
 positive=positive and all(getattr(assessment,k)=='reported-valid' for k in needed)
 if not positive:return _stop(state,event,assessment,raw,'contradictory-positive-report')
 changes={'phase':event.phase,'rights':assessment.rights,'raw_statuses':raw};wrapper={'completed':state.completed+1,'attempts':state.attempts+(token,)}
 if state.completed==0:changes.update(owned='known-binding',target='known-unchanged');wrapper['owned_view']=views['owned-path-set-view']
 elif state.completed==1:changes['backups']='verified-original';wrapper['backups_view']=views['original-backups-view']
 elif state.completed==2:changes['target']='known-changed';wrapper['predecessor_view']=views['exact-predecessor-view']
 elif state.completed==3:wrapper['isolation_view']=views['isolated-config-view']
 elif state.completed==4:changes['pin']=views['raw-pkglist-pin-view'].symbol;wrapper.update(pin_view=views['raw-pkglist-pin-view'],selector_view=views['full-selector-vector-view'],selector=assessment.selector)
 elif state.completed==5:wrapper.update(candidate_view=views['candidate-binding-view'],candidate=assessment.candidate)
 elif state.completed<15:changes['stage7_completed']=state.completed-5;wrapper['binding_status']=BINDING_STATES[state.completed-5]
 elif state.completed==15:wrapper['update_raw']=event.raw_statuses[0]
 elif state.completed==16:wrapper['install_raw']=event.raw_statuses[0]
 elif state.completed==17:wrapper['upgrade_raw']=event.raw_statuses[0]
 else:wrapper.update(whole_view=views['whole-entry-result-view'],ready_for_finalization=True)
 return _result(replace(state,core=replace(state.core,**changes),**wrapper),'model-advanced','advanced')
