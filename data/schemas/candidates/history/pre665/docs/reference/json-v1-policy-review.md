# JSON v1 candidate policy review, steps 586-595

This is a revised **candidate**, prepared from published main
`59c5e00ae24ad27ad0faab64760fefb989d00a8c` (tree
`9181f3193243e2d84ea82d9db2df9e62937b89ee`). It resolves the bounded schema
questions below without switching the reference emitter, accepting schema1,
freezing reference-v1 or selecting A/R/D. Runtime still emits provisional v0.

The exact external 576-585 closure supplied for this block records acceptance
of that repository work and its one-file CHANGELOG repair. Historical preparation
flags in Git remain historical. Last accepted qualified STATIC pause is 575;
a later whole inherited-condition/original/new-effects review remains separate.

## Ten preparation steps

| Step | Concrete work |
| --- | --- |
| 586 | Reobserve main, verify the received closure and pin exact source/tree |
| 587 | Resolve version/family dispatch and exact producer compatibility rules |
| 588 | Choose opaque timestamp strings, including empty/failure values |
| 589 | Preserve open diagnostic labels and distinguish closed enums |
| 590 | Require final event code/state coherence in the candidate schema |
| 591 | Separate complete streams from explicitly offset supplied fragments |
| 592 | Define early-output absence and incomplete-stream handling |
| 593 | Add offline validation, policy controls and actual supplied v0 projections |
| 594 | Run the focused repository checks and preserve complete outputs/statuses |
| 595 | Package exact changes, preimages, execution instructions and pending pause conditions |

These are repository preparation steps, not accepted PC execution or native
case entries. No automatic step 596 follows this delivery.

## Proposed resolutions

| Question | Candidate rule | Compatibility consequence |
| --- | --- | --- |
| Version and family | Select result/event/stream/fragment explicitly, then accept only numeric schema_version 1 and status stable | No inference from fields, v0 adapter, silent fallback or producer switch |
| Numeric spelling | JSON Schema mathematical integers include 1.0; boolean true is distinct | Consumers must not require an undocumented lexical integer spelling |
| Timestamps | started_at, finished_at and event timestamp are opaque strings; empty and non-date text remain representable | No date format, calendar, monotonicity, duration or trusted-clock guarantee; adding one needs a reviewed contract change |
| Labels | Diagnostic text, activation_state and most module/action states remain open strings in their existing positions | New label text is compatible there; consumers must not parse it as a closed enum or executable instruction |
| Closed sets | Operation, event type, module mode, reboot and the explicitly constrained state/code fields remain closed | Adding a value to a closed set is a contract change requiring a reviewed version |
| Final event state | 0/4/5 map to success; 2 to warning; 1/3/6/7/8 to failed | The revised candidate rejects previously admitted inconsistent pairs; no stable published v1 interface exists to migrate |
| Arrays | Order and duplicate entries are retained | No sorting, deduplication or automatic counter/list equality |
| Exact producer fields | Required sets and additionalProperties false remain | Added/removed fields, changed types/null meanings or stable code meanings require a reviewed schema version |

The timestamp choice deliberately accepts even malformed date text. Producers
normally supply UTC text, but the current completion clock may fail and arbitrary
supplied helper state is representable. A schema PASS must never be reported as a
successful clock check. Module state strings and flags are reports, not evidence
of installed state, boot safety, containment, custody or native conformance.

Final-state coherence is a prospective constraint on serialized data. The shell
helper emits from supplied success/partial/boot flags; invoking it with inconsistent
flags could still produce an invalid candidate pair. This block changes neither
that helper nor its contract for arbitrary v0 supplied states. Raw action/module
codes, including 20, 100, negative values and null, retain their separate domain.
Original native install20 still requires empty AND no-effect; upgrade20 is failure.

## Complete streams and supplied fragments

The offline validator supports four explicit families:

```bash
python3 tools/reference/json_v1_candidate.py result tests/fixtures/reference/json-v1-candidate/check.json
python3 tools/reference/json_v1_candidate.py stream tests/fixtures/reference/json-v1-candidate/events.ndjson
```

`result` and `event` read one strict UTF-8 JSON object. `stream` reads nonempty
NDJSON with final LF (CRLF accepted), exactly one operation_started at the
beginning, exactly one operation_completed at the end, constant operation and
consecutive sequence values starting at 1. Duplicate object keys, non-JSON
constants, concatenated documents and blank lines are rejected.

`fragment` uses the same framing, one-start/one-final and consecutive-operation
rules but explicitly permits a positive initial sequence other than 1 for supplied
helper lifecycles. It does not accept arbitrary truncated middle segments. Offset
fragments must not be presented as complete operation captures. The older candidate
test retains its local weaker framing reader for historical coverage; this separate
validator defines and tests the new complete/fragment policy.

Neither profile proves all module/action pairs, cross-record semantic truth,
lossless delivery, durable recording, drain, terminal custody or no omitted effects.
An individually valid event is not a completed-stream certificate. Schema loading
permits only internal references, so no remote reference lookup is needed.

## Early output and rollout

Help can exit 0 without a final document. Argument/configuration errors (7),
privilege failures (8), lock refusal (6), and runtime/logging setup failures can
return before normal output setup. Their absence of JSON/NDJSON is permitted;
consumers must retain process status and stderr independently. A missing result
is not a fabricated failure envelope, and a partial stream remains incomplete.
The schema does not promise delivery after I/O failure or interruption.

Final result envelopes keep their existing code 0-5 projection. A supplied
operation_completed record can represent 6/7/8 with failed state; this is shape
coverage, not a claim that startup failures actually emit such a lifecycle.
No new early-output promise or serializer recovery is implemented.

The chosen migration direction is one later explicit, tested producer switch
with matching consumers and tests, after exact semantic acceptance. There is no
negotiation flag, adapter, mixed-version stream or dual-output mode here. Before
that switch, inventory actual consumers; review all preserved field/null/code/
array requirements, timestamp/open-label choices and early-output policy; then
accept the exact candidate explicitly. Actual emitted v1 records and a completed
stream must be tested after migration. Passing authored/projection data is not
producer migration, semantic approval, a release tag or a reference freeze.

## Verification and effects

The new policy driver checks all 27 final code/state pairs, timestamps, open and
closed labels, version/family refusal, exact fields, duplicate/order preservation,
complete/offset/duplicate-start streams, strict JSON and the read-only CLI. It also
calls the unchanged check serializer with ten independently authored existing
supplied states, compares actual v0 objects exactly, rejects them as v1, then
validates an in-memory copy with prospective metadata. Original captured objects
remain v0. These are helper projections, never captured v1 operations.

The original candidate driver retains all 75 positives and 69 negative controls.
Its nine final-record positives now explicitly set the independently specified
coherent state for each code. No negative control or old v0 test is removed or
relaxed. The original result schema, all candidate fixtures, field inventory,
runtime and every other pre-existing test remain byte unchanged.

The focused selection is syntax; both candidate tests; existing check, dry-run,
apply and event serializer regressions; CLI early exits; and main configuration
failures. The latter source the real parser/configuration prefix with later
operations prohibited and private supplied files; serializers use declarations,
supplied data and fixed-clock initialization where documented. Read their exact
scopes in the existing reference records. No actual package, network, boot or
native target workflow runs. Python3/jsonschema4.x is a development dependency.
No package installation is performed by application or validation scripts.

One out-of-inventory local input discovered during preparation is retained
byte-for-byte outside the candidate; its provenance remains unknown. It is not
installed by this overlay or classified as native evidence.

The new validator reads supplied input and two candidate schemas; it prints a
bounded status and performs no output-file, configuration, lock or workflow write.
Tests inherit the existing private temporary-file and normal cleanup limitations.
Known-call guards are not OS containment, and no global cleanup or host state is
claimed. The delivery runner retains its own logs outside the repository.

## Pause and retained gates

Local focused success can establish only candidate preparation. After PC checks,
review their complete raw return and exact committed paths/tree/modes/publication
before accepting execution. Only then consider a new qualified STATIC pause after
the complete applicable inherited header, each condition, every exact original
and all new effects/obligations/failures/cleanup assumptions have been reviewed.
The complete 571 baseline and original 572-575 material are separately retained;
this supplement does not claim to contain or reread them. If required originals
are unavailable, report the blocker and retain the last accepted pause 575.

All 13 findings, 16 native gaps, four inactive repairs and the original 1286 member,
46 proof, 52 case, 12 raw-group, 1072 proof-AND-case relation and 20 residual-scenario
requirements retain their full scopes and own-platform obligations. P0D's protected
admission/completion implementation remains unresolved. A/R/D remain unselected;
actual native/live fields remain null as supplied records, the host is unobserved
and global closure is false. Incomplete491 history, unknown extras, trust, custody,
recording, IO and cleanup qualifications persist. Phase1/kernel incomplete;
schema1/reference-v1 unaccepted/unfrozen; C/Phase2/production closed. STOP.
