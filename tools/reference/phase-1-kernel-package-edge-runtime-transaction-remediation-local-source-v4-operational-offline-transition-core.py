"""Versioned immutable private model data. No transitions or operational effects.

A valid shape does not establish authenticity, history, order, authority or native
facts. Frozen dataclasses provide ordinary API immutability, not tamper resistance.
"""
from dataclasses import dataclass, field
import json
import re
from types import MappingProxyType

SCHEMA_VERSION = 1
ORIGIN = 'synthetic-private-fixture'
SCOPE = 'offline-transition-core-shape-only'
MAX_WIRE_BYTES = 65536
MAX_DEPTH = 32
MAX_RAW_STATUSES = 4096
MAX_INTEGER = 2147483647
MIN_INTEGER = -2147483648
PHASE_ROWS = MappingProxyType({'drain-known-owned-children': ('supervisor', 'recovery', 18), 'interstage1-2-guard-freshoriginal': ('supervisor', 'forward', 8), 'release-target-control': ('supervisor', 'recovery', 22), 'service-barrier-authentication': ('service', 'policy', 0), 'service-durable-launch-spend': ('service', 'launch', 2), 'service-original-durable-claim': ('service', 'admission', 1), 'service-single-worker-spawn': ('service', 'launch', 3), 'stop-forward-irreversibly': ('supervisor', 'recovery', 17), 'worker0-bounded-auth-read': ('worker', 'bootstrap', 4), 'worker0-close-bootstrap': ('worker', 'bootstrap', 5), 'worker0-readonly-preflight': ('worker', 'bootstrap', 6), 'worker1-arm-traps': ('worker', 'forward', 7), 'worker10-original-verification': ('worker', 'recovery', 20), 'worker11-close-target-evidence': ('worker', 'recovery', 21), 'worker12-durable-handoff': ('publisher', 'publication', 26), 'worker12-last-receipt': ('publisher', 'publication', 25), 'worker12-publication-controls': ('publisher', 'publication', 23), 'worker12-publication-record': ('publisher', 'publication', 24), 'worker2-owned-workspace': ('worker', 'forward', 9), 'worker3-original-backups': ('worker', 'forward', 10), 'worker4-exact-predecessor': ('worker', 'forward', 11), 'worker5-local-isolation': ('worker', 'forward', 12), 'worker6-refresh-pin-once': ('worker', 'forward', 13), 'worker7-owned-durable-commit': ('worker', 'forward', 15), 'worker7-validate-pinned-candidate': ('worker', 'forward', 14), 'worker8-whole-successor-apply': ('worker', 'forward', 16), 'worker9-original-restoration': ('worker', 'recovery', 19)})
PHASE_VIEWS = MappingProxyType({k: frozenset(v) for k, v in {'drain-known-owned-children': ['armed-traps-view', 'consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'known-child-set-view', 'live-original-fence-view', 'quiescent-child-view', 'source-closure-view'], 'interstage1-2-guard-freshoriginal': ['armed-traps-view', 'consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'live-original-fence-view', 'original-baseline-view', 'source-closure-view'], 'release-target-control': ['armed-traps-view', 'closed-target-evidence-view', 'consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'live-original-fence-view', 'original-baseline-view', 'original-verification-view', 'quiescent-child-view', 'source-closure-view', 'target-release-view'], 'service-barrier-authentication': ['authenticated-policy-view', 'dependency-closure-view', 'issuer-policy-view', 'source-closure-view'], 'service-durable-launch-spend': ['consumed-original-context', 'dependency-closure-view', 'source-closure-view', 'spent-launch-view'], 'service-original-durable-claim': ['authenticated-policy-view', 'consumed-original-context', 'dependency-closure-view', 'source-closure-view'], 'service-single-worker-spawn': ['consumed-original-context', 'dependency-closure-view', 'source-closure-view', 'spent-launch-view'], 'stop-forward-irreversibly': ['consumed-original-context', 'dependency-closure-view', 'live-original-fence-view', 'source-closure-view'], 'worker0-bounded-auth-read': ['closed-bootstrap-view', 'consumed-original-context', 'dependency-closure-view', 'source-closure-view', 'spent-launch-view'], 'worker0-close-bootstrap': ['closed-bootstrap-view', 'consumed-original-context', 'dependency-closure-view', 'source-closure-view', 'spent-launch-view'], 'worker0-readonly-preflight': ['closed-bootstrap-view', 'consumed-original-context', 'dependency-closure-view', 'early-observation-view', 'source-closure-view'], 'worker1-arm-traps': ['armed-traps-view', 'consumed-original-context', 'dependency-closure-view', 'known-child-set-view', 'live-original-fence-view', 'source-closure-view'], 'worker10-original-verification': ['closed-target-evidence-view', 'consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'live-original-fence-view', 'original-baseline-view', 'original-verification-view', 'quiescent-child-view', 'source-closure-view'], 'worker11-close-target-evidence': ['closed-target-evidence-view', 'consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'live-original-fence-view', 'original-baseline-view', 'original-verification-view', 'quiescent-child-view', 'source-closure-view'], 'worker12-durable-handoff': ['closed-target-evidence-view', 'dependency-closure-view', 'last-receipt-origin-view', 'publication-control-view', 'publication-record-view', 'source-closure-view', 'target-release-view'], 'worker12-last-receipt': ['dependency-closure-view', 'last-receipt-origin-view', 'publication-control-view', 'publication-record-view', 'source-closure-view'], 'worker12-publication-controls': ['closed-target-evidence-view', 'dependency-closure-view', 'publication-control-view', 'source-closure-view', 'target-release-view'], 'worker12-publication-record': ['closed-target-evidence-view', 'dependency-closure-view', 'publication-control-view', 'publication-record-view', 'source-closure-view', 'target-release-view'], 'worker2-owned-workspace': ['consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'live-original-fence-view', 'original-backups-view', 'original-baseline-view', 'owned-path-set-view', 'source-closure-view'], 'worker3-original-backups': ['consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'live-original-fence-view', 'original-backups-view', 'original-baseline-view', 'owned-path-set-view', 'source-closure-view'], 'worker4-exact-predecessor': ['complete-effect-graph-view', 'consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'exact-predecessor-view', 'isolated-config-view', 'live-original-fence-view', 'original-backups-view', 'package-effect-result-view', 'raw-pkglist-pin-view', 'source-closure-view'], 'worker5-local-isolation': ['consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'exact-predecessor-view', 'isolated-config-view', 'live-original-fence-view', 'original-backups-view', 'raw-pkglist-pin-view', 'source-closure-view'], 'worker6-refresh-pin-once': ['complete-effect-graph-view', 'consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'exact-predecessor-view', 'full-selector-vector-view', 'isolated-config-view', 'live-original-fence-view', 'original-backups-view', 'raw-pkglist-pin-view', 'source-closure-view'], 'worker7-owned-durable-commit': ['candidate-binding-view', 'consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'live-original-fence-view', 'raw-pkglist-pin-view', 'source-closure-view'], 'worker7-validate-pinned-candidate': ['candidate-binding-view', 'consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'live-original-fence-view', 'raw-pkglist-pin-view', 'source-closure-view'], 'worker8-whole-successor-apply': ['candidate-binding-view', 'complete-effect-graph-view', 'consumed-original-context', 'contained-runtime-view', 'contained-snapshot-view', 'continuous-guard-view', 'dependency-closure-view', 'full-selector-vector-view', 'live-original-fence-view', 'nested-call-result-view', 'original-baseline-view', 'owned-path-set-view', 'package-effect-result-view', 'raw-pkglist-pin-view', 'source-closure-view', 'whole-entry-result-view'], 'worker9-original-restoration': ['complete-effect-graph-view', 'consumed-original-context', 'continuous-guard-view', 'dependency-closure-view', 'live-original-fence-view', 'original-baseline-view', 'original-restoration-result-view', 'package-effect-result-view', 'quiescent-child-view', 'recovery-budget-view', 'source-closure-view']}.items()})
TYPE_NAMES = frozenset(['armed-traps-view', 'authenticated-policy-view', 'candidate-binding-view', 'closed-bootstrap-view', 'closed-target-evidence-view', 'complete-effect-graph-view', 'consumed-original-context', 'contained-runtime-view', 'contained-snapshot-view', 'continuous-guard-view', 'dependency-closure-view', 'early-observation-view', 'exact-predecessor-view', 'full-selector-vector-view', 'isolated-config-view', 'issuer-policy-view', 'known-child-set-view', 'last-receipt-origin-view', 'live-original-fence-view', 'nested-call-result-view', 'original-backups-view', 'original-baseline-view', 'original-restoration-result-view', 'original-verification-view', 'owned-path-set-view', 'package-effect-result-view', 'publication-control-view', 'publication-record-view', 'quiescent-child-view', 'raw-pkglist-pin-view', 'recovery-budget-view', 'source-closure-view', 'spent-launch-view', 'target-release-view', 'whole-entry-result-view'])
RIGHTS_WINDOWS = tuple(['policy', 'admission', 'launch', 'bootstrap', 'service', 'forward', 'recovery', 'publication', 'forbidden'])
STATE_ENUMS = MappingProxyType({
    'claim': ('known-unused', 'consumed', 'uncertain', 'known-rejected'),
    'launch': ('unspent', 'spent', 'uncertain'),
    'spawn': ('unattempted', 'known-absent', 'known-owned', 'uncertain'),
    'bootstrap': ('unattempted', 'bounded-read', 'closed', 'uncertain'),
    'guard': ('unobserved', 'continuous', 'lost', 'uncertain'),
    'baseline': ('unobserved', 'fresh-original', 'uncertain'),
    'backups': ('unobserved', 'verified-original', 'uncertain'),
    'forward': ('closed', 'active', 'stopped'),
    'children': ('unobserved', 'known-none', 'known-owned', 'drained', 'uncertain'),
    'owned': ('unobserved', 'known-none', 'known-binding', 'uncertain'),
    'target': ('unobserved', 'known-unchanged', 'known-changed', 'known-restored', 'verified-original', 'uncertain'),
    'publication': ('unattempted', 'controls-reported', 'record-reported', 'receipt-reported', 'handoff-reported', 'uncertain'),
})
RIGHT_STATUSES = ('inactive', 'reported-live', 'expired', 'revoked', 'uncertain')
OUTCOMES = ('known-success', 'known-failure', 'unknown', 'unattempted')
DECISIONS = ('accepted-shape', 'rejected', 'pending')
REASONS = ('valid-shape', 'rule-rejected', 'unknown-observation', 'transition-not-implemented')
OPERATIONS = tuple(['validate-exact-inputs', 'register-owned-intent', 'create-exclusive-stage', 'write-complete-bytes', 'metadata-and-data-durable', 'revalidate-pinned-inputs', 'commit-no-replace', 'directory-durability-confirmed', 'stage-exit-evidence-complete'])


def _error(label):
    raise ValueError(label)


def _closed(value, keys):
    if type(value) is not dict or set(value) != set(keys):
        _error('closed object fields required')


def _integer(value, low=0, high=MAX_INTEGER):
    if type(value) is not int or not low <= value <= high:
        _error('bounded integer required; bool is not an integer')


def _symbol(value):
    if type(value) is not str or len(value) > 96 or re.fullmatch(r'model-[a-z0-9]+(?:-[a-z0-9]+)*', value) is None:
        _error('bounded model symbol required; no native identity or path')


def _choice(value, choices):
    if type(value) is not str or value not in choices:
        _error('unknown symbolic enumeration')


def _false(value):
    if type(value) is not bool or value:
        _error('private model never supplies authority or native evidence')


def _context(value):
    if type(value) is not ModelContext:
        _error('immutable symbolic original context required')
    value.__post_init__()


def _tuple(value, member, maximum):
    if type(value) is not tuple or len(value) > maximum:
        _error('bounded immutable tuple required')
    for item in value:
        if type(item) is not member:
            _error('wrong immutable tuple member')
        item.__post_init__()


@dataclass(frozen=True, slots=True)
class ModelContext:
    attempt: str
    boot: str

    def __post_init__(self):
        _symbol(self.attempt); _symbol(self.boot)


@dataclass(frozen=True, slots=True)
class ModelView:
    name: str
    context: ModelContext
    symbol: str
    authority: bool = False
    native_evidence: bool = False

    def __post_init__(self):
        _choice(self.name, TYPE_NAMES); _context(self.context); _symbol(self.symbol)
        _false(self.authority); _false(self.native_evidence)


@dataclass(frozen=True, slots=True)
class RightReport:
    window: str
    status: str = 'inactive'

    def __post_init__(self):
        _choice(self.window, RIGHTS_WINDOWS); _choice(self.status, RIGHT_STATUSES)


@dataclass(frozen=True, slots=True)
class RawStatus:
    call: str
    code: int | None

    def __post_init__(self):
        _symbol(self.call)
        if self.code is not None:
            _integer(self.code, MIN_INTEGER)


def _raw_statuses(value):
    _tuple(value, RawStatus, MAX_RAW_STATUSES)
    if len({v.call for v in value}) != len(value):
        _error('raw call labels must be unique; unknown is not exit zero')


@dataclass(frozen=True, slots=True)
class CoreState:
    context: ModelContext
    phase: str | None = None
    claim: str = 'known-unused'
    launch: str = 'unspent'
    spawn: str = 'unattempted'
    bootstrap: str = 'unattempted'
    traps: bool = False
    guard: str = 'unobserved'
    baseline: str = 'unobserved'
    backups: str = 'unobserved'
    pin: str | None = None
    stage7_completed: int = 0
    forward: str = 'closed'
    children: str = 'unobserved'
    owned: str = 'unobserved'
    target: str = 'unobserved'
    recovery_limit: int = 0
    recovery_spent: int = 0
    rights: tuple[RightReport, ...] = field(default_factory=lambda: tuple(RightReport(w) for w in RIGHTS_WINDOWS))
    raw_statuses: tuple[RawStatus, ...] = ()
    first_failure: RawStatus | None = None
    publication: str = 'unattempted'
    authority: bool = False
    native_evidence: bool = False

    def __post_init__(self):
        _context(self.context)
        if self.phase is not None:
            _choice(self.phase, PHASE_ROWS)
        for name, choices in STATE_ENUMS.items():
            _choice(getattr(self, name), choices)
        if type(self.traps) is not bool:
            _error('typed symbolic traps report required')
        if self.pin is not None:
            _symbol(self.pin)
        _integer(self.stage7_completed, 0, len(OPERATIONS))
        _integer(self.recovery_limit); _integer(self.recovery_spent, 0, self.recovery_limit)
        _tuple(self.rights, RightReport, len(RIGHTS_WINDOWS))
        if tuple(x.window for x in self.rights) != RIGHTS_WINDOWS:
            _error('all nine original rights windows required in source order')
        _raw_statuses(self.raw_statuses)
        if self.first_failure is not None:
            if type(self.first_failure) is not RawStatus:
                _error('immutable raw original failure required')
            self.first_failure.__post_init__()
        _false(self.authority); _false(self.native_evidence)


@dataclass(frozen=True, slots=True)
class ModelEvent:
    context: ModelContext
    phase: str
    actor: str
    window: str
    outcome: str
    operation: str = 'phase-report'
    views: tuple[ModelView, ...] = ()
    raw_statuses: tuple[RawStatus, ...] = ()
    authority: bool = False
    native_evidence: bool = False

    def __post_init__(self):
        _context(self.context); _choice(self.phase, PHASE_ROWS); _choice(self.outcome, OUTCOMES)
        row = PHASE_ROWS[self.phase]
        if type(self.actor) is not str or self.actor != row[0] or type(self.window) is not str or self.window != row[1]:
            _error('source-bound phase actor and rights window required')
        _choice(self.operation, ('phase-report',) + OPERATIONS)
        if self.operation != 'phase-report' and self.phase != 'worker7-owned-durable-commit':
            _error('owned microstep only within original stage7 phase')
        _tuple(self.views, ModelView, len(TYPE_NAMES)); _raw_statuses(self.raw_statuses)
        if len({v.name for v in self.views}) != len(self.views):
            _error('one whole symbolic view per nominal type')
        for view in self.views:
            if view.context != self.context or view.name not in PHASE_VIEWS[self.phase]:
                _error('view must use same symbolic original and original phase type')
        if self.outcome != 'known-success' and self.views:
            _error('no success payload from failure, unknown or unattempted report')
        if self.outcome == 'unattempted' and self.raw_statuses:
            _error('unattempted report cannot contain attempted raw statuses')
        _false(self.authority); _false(self.native_evidence)


@dataclass(frozen=True, slots=True)
class ModelResult:
    context: ModelContext
    decision: str
    reason: str
    successor: CoreState | None = None
    authority: bool = False
    native_evidence: bool = False

    def __post_init__(self):
        _context(self.context); _choice(self.decision, DECISIONS); _choice(self.reason, REASONS)
        if self.successor is not None:
            if type(self.successor) is not CoreState or self.successor.context != self.context:
                _error('successor must retain same immutable symbolic original')
            self.successor.__post_init__()
        if self.decision == 'accepted-shape' and (self.successor is None or self.reason != 'valid-shape'):
            _error('accepted shape requires shape-only successor; not transition acceptance')
        if self.decision == 'rejected' and (self.successor is not None or self.reason != 'rule-rejected'):
            _error('rejection never invents a successor')
        if self.decision == 'pending' and self.reason not in ('unknown-observation', 'transition-not-implemented'):
            _error('pending is not success or native closure')
        _false(self.authority); _false(self.native_evidence)


def initial_state(context):
    """Create an offline initial data value, never an issuer grant or claim."""
    return CoreState(context)


def _context_wire(value):
    _context(value)
    return {'attempt': value.attempt, 'boot': value.boot}


def _view_wire(value):
    value.__post_init__()
    return {'name': value.name, 'context': _context_wire(value.context), 'symbol': value.symbol, 'authority': False, 'native_evidence': False}


def _status_wire(value):
    value.__post_init__()
    return {'call': value.call, 'code': value.code}


def to_wire(value):
    """Return detached JSON data; mutation of it cannot mutate the frozen value."""
    if type(value) not in (CoreState, ModelEvent, ModelResult):
        _error('only closed model state/event/result values can be encoded')
    value.__post_init__()
    result = {'schema': SCHEMA_VERSION, 'origin': ORIGIN, 'scope': SCOPE, 'context': _context_wire(value.context), 'authority': False, 'native_evidence': False}
    if type(value) is CoreState:
        result.update(kind='state', phase=value.phase, traps=value.traps, pin=value.pin, stage7_completed=value.stage7_completed,
                      recovery_limit=value.recovery_limit, recovery_spent=value.recovery_spent,
                      rights=[{'window': x.window, 'status': x.status} for x in value.rights],
                      raw_statuses=[_status_wire(x) for x in value.raw_statuses],
                      first_failure=None if value.first_failure is None else _status_wire(value.first_failure))
        result.update({k: getattr(value, k) for k in STATE_ENUMS})
    elif type(value) is ModelEvent:
        result.update(kind='event', phase=value.phase, actor=value.actor, window=value.window, outcome=value.outcome,
                      operation=value.operation, views=[_view_wire(x) for x in value.views], raw_statuses=[_status_wire(x) for x in value.raw_statuses])
    else:
        result.update(kind='result', decision=value.decision, reason=value.reason, successor=None if value.successor is None else to_wire(value.successor))
    return result


def _read_context(value):
    _closed(value, ('attempt', 'boot')); return ModelContext(**value)


def _read_view(value):
    _closed(value, ('name', 'context', 'symbol', 'authority', 'native_evidence'))
    return ModelView(value['name'], _read_context(value['context']), value['symbol'], value['authority'], value['native_evidence'])


def _read_status(value):
    _closed(value, ('call', 'code')); return RawStatus(**value)


def _read_list(value, reader, maximum):
    if type(value) is not list or len(value) > maximum:
        _error('bounded JSON array required')
    return tuple(reader(x) for x in value)


def from_wire(value):
    """Check shape only; no reducer, history interpretation or operational action."""
    if type(value) is not dict:
        _error('closed root object required')
    metadata = ('kind', 'schema', 'origin', 'scope', 'context', 'authority', 'native_evidence')
    kind = value.get('kind')
    _choice(kind, ('state', 'event', 'result'))
    if kind == 'state':
        extra = tuple(STATE_ENUMS) + ('phase', 'traps', 'pin', 'stage7_completed', 'recovery_limit', 'recovery_spent', 'rights', 'raw_statuses', 'first_failure')
    elif kind == 'event':
        extra = ('phase', 'actor', 'window', 'outcome', 'operation', 'views', 'raw_statuses')
    elif kind == 'result':
        extra = ('decision', 'reason', 'successor')
    else:
        _error('unknown model record kind')
    _closed(value, metadata + extra)
    if type(value['schema']) is not int or value['schema'] != SCHEMA_VERSION or type(value['origin']) is not str or value['origin'] != ORIGIN or type(value['scope']) is not str or value['scope'] != SCOPE:
        _error('exact private version/origin/scope required')
    _false(value['authority']); _false(value['native_evidence'])
    context = _read_context(value['context'])
    if kind == 'state':
        kwargs = {k: value[k] for k in STATE_ENUMS}
        kwargs.update({k: value[k] for k in ('phase', 'traps', 'pin', 'stage7_completed', 'recovery_limit', 'recovery_spent')})
        def right(x):
            _closed(x, ('window', 'status')); return RightReport(**x)
        kwargs.update(rights=_read_list(value['rights'], right, len(RIGHTS_WINDOWS)),
                      raw_statuses=_read_list(value['raw_statuses'], _read_status, MAX_RAW_STATUSES),
                      first_failure=None if value['first_failure'] is None else _read_status(value['first_failure']))
        return CoreState(context, **kwargs)
    if kind == 'event':
        return ModelEvent(context, value['phase'], value['actor'], value['window'], value['outcome'], value['operation'],
                          _read_list(value['views'], _read_view, len(TYPE_NAMES)), _read_list(value['raw_statuses'], _read_status, MAX_RAW_STATUSES))
    successor = value['successor']
    if successor is not None:
        if type(successor) is not dict or successor.get('kind') != 'state':
            _error('result successor must have state shape before recursive decoding')
        successor = from_wire(successor)
        if type(successor) is not CoreState:
            _error('result successor must be a state, never a nested event/result')
    return ModelResult(context, value['decision'], value['reason'], successor)


def encode(value):
    raw = json.dumps(to_wire(value), sort_keys=True, separators=(',', ':'), ensure_ascii=True, allow_nan=False).encode('ascii')
    if len(raw) > MAX_WIRE_BYTES:
        _error('model wire exceeds private resource limit')
    return raw


def _pairs(pairs):
    value = {}
    for key, item in pairs:
        if key in value:
            _error('duplicate JSON field')
        value[key] = item
    return value


def _constant(_):
    _error('nonfinite JSON value')


def decode(raw):
    if type(raw) is not bytes or not raw or len(raw) > MAX_WIRE_BYTES:
        _error('bounded canonical bytes required')
    try:
        value = json.loads(raw.decode('ascii'), object_pairs_hook=_pairs, parse_constant=_constant)
        stack = [(value, 0)]
        while stack:
            item, depth = stack.pop()
            if depth > MAX_DEPTH:
                _error('bounded JSON depth required')
            if type(item) is dict:
                stack.extend((v, depth + 1) for v in item.values())
            elif type(item) is list:
                stack.extend((v, depth + 1) for v in item)
        canonical = json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=True, allow_nan=False).encode('ascii')
        if canonical != raw:
            _error('noncanonical or trailing JSON bytes')
        return from_wire(value)
    except (UnicodeError, json.JSONDecodeError, RecursionError, OverflowError) as error:
        raise ValueError('invalid bounded model JSON') from error
