# Current check-coherence revision, steps665–672

The owner selected J03-2. Read [the exact amendment and impact](json-v1-check-coherence.md)
and the rebound machine dossier. Check/result code0 now requires raw0/100 AND
empty errors in the prepared candidate. J11's bounded owner statement is received;
no other consumers are known within the described use, with no global absence
claim. Whole independent contract acceptance and producer migration remain pending.
Runtime remains0/provisional. The text below is retained historical preparation:
its earlier unchanged-schema, unknown-owner-answer and input-count statements
describe their original blocks. Exact pre665 copies are preserved separately.

# Candidate JSON v1 contract: results and events

This is a **prepared proposal**, not an accepted schema, a release or a change
to the running interface. The reference still emits `schema_version: 0` and
`schema_status: "provisional"`. Candidate examples use prospective version1 and
status `stable` to describe what a separately accepted future producer would
emit. Do not rewrite current output metadata and call it an observed v1 result.

The [closure backlog](phase-1-closure-backlog.md#final-validation-and-release-gates)
allows schema design before completion of unrelated native work. This block
selects no A/R/D option, amends no native contract and freezes neither schema1 nor
`reference-v1`. C, Phase2 and production remain blocked.

## Later candidate policy review

The [586-595 policy review](json-v1-policy-review.md) resolves the previously open
timestamp, label, early-output and compatibility questions as proposed rules. It
tightens final event code/state coherence and separates complete streams (initial
sequence1) from explicitly offset supplied fragments. Use that review and the new
offline validator for the revised candidate; the original preparation narrative
below records the earlier proposal. Runtime remains v0; semantic acceptance and
emitter migration remain pending. No schema/reference freeze is claimed.

## Prepared steps576-585

The later [596-605 consumer review](json-v1-consumer-review.md) inventories bounded
source references, validates prospective copies of actual supplied serializers
and characterizes current acceptance-consumer refusal. It preserves the candidate
schemas and runtime metadata; semantic acceptance and migration remain pending.

| Step | Completed preparation |
| --- | --- |
| 576 | Pin main commit/tree and review contributing and continuity scope |
| 577 | Inventory selected current serializer fields and original expected data |
| 578 | Separate one final JSON document from individually framed NDJSON records |
| 579 | Specify required fields, scalar types, nulls and operation-specific module shapes |
| 580 | Specify prospective v0/v1 dispatch and compatibility rules |
| 581 | Author two machine-readable candidate schemas |
| 582 | Prepare three result examples and a supplied event stream from authored data |
| 583 | Check schemas, original expected-state projections and negative controls |
| 584 | Document scope, dependencies, migration questions and pending gates |
| 585 | Package the candidate, preimages, focused checks and exact application/commit instructions |

These are preparation steps. PC application, complete actual return acceptance,
publication and any later separate qualified STATIC pause remain pending. Last
accepted qualified STATIC pause575 is imported, not repeated here.

## Files and dialect

- [Final result candidate](../../data/schemas/candidates/result-v1.schema.json)
- [Single event candidate](../../data/schemas/candidates/event-v1.schema.json)
- [Selected literal field inventory](../../data/schemas/candidates/source-field-inventory.json)
- [Authored candidate fixtures](../../tests/fixtures/reference/json-v1-candidate/)
- [Focused schema test](../../tests/reference/test-json-v1-candidate.py)

Both documents use [JSON Schema Draft2020-12](https://json-schema.org/draft/2020-12).
Their URN identifiers name local candidates, not published stable APIs. All `$ref`
links are internal. Tests use the explicitly selected validator and its packaged
metaschema; no remote resolution or network lookup is needed.

`required` and `additionalProperties: false` define exact producer field sets at
the root, module and build-option object levels. No field defaults are inserted.
The `integer` type has JSON Schema's mathematical meaning: `1.0` is an integer
value; booleans remain distinct. The existing v0 serializer regressions also
check the exact Python decoded types of current output. Their stronger source
formatting expectations are preserved rather than silently reinterpreted.

## Final result envelope

All17 fields remain required. Object key order and insignificant JSON whitespace
are not significant. Array order and duplicates remain significant data; consumers
must not sort or deduplicate queues, options, warnings, errors or object lists.

| Field | Proposed type and meaning |
| --- | --- |
| `schema_version`, `schema_status` | Prospective constants1 and `stable`; not emitted by this delivery |
| `operation` | `check`, `dry-run` or `apply` |
| `success`, `partial`, `boot_safe` | Boolean result-calculation reports; no independent native safety assertion |
| `reboot` | `none`, `recommended`, `required` or `unsafe` |
| `exit_code` | Stable final result code; distinct from serializer process status and raw command statuses |
| `exit_code_meaning` | Current English stable-code description, checked against the code |
| `exit_code_stable` | Constant true for this stable-code namespace |
| `started_at`, `finished_at` | Strings; normally producer UTC timestamps, potentially empty on failure; no format, elapsed-time or trusted-clock proof |
| `log_path`, `config_path` | Reported strings, potentially empty; no existence, ownership, canonicalization or safe-to-open guarantee |
| `modules` | Exact operation-specific object described below |
| `warnings`, `errors` | Ordered string arrays; empty arrays remain distinct from null or omitted fields |

The candidate describes JSON after result calculation, not every possible
process exit. Current `main` returns before output setup for some argument,
configuration, privilege or lock failures. Codes6/7/8 remain stable process codes;
this candidate neither manufactures a result envelope for them nor promises one.
Help and other early exits likewise need not produce a final result document.

| Final result code | Required aggregate projection |
| --- | --- |
| 0 | success, nonpartial, reported boot-safe, reboot none |
| 1 | check/dry-run failure, nonpartial, reported boot-safe, reboot none |
| 2 | apply failure, partial, reported boot-safe; reboot none/recommended/required |
| 3 | apply failure, partial, reported boot-unsafe; reboot unsafe |
| 4 | apply success, nonpartial, reported boot-safe; reboot recommended |
| 5 | apply success, nonpartial, reported boot-safe; reboot required |

These constraints preserve the current result mapper. They do not certify that
reported flags match actual installed state. A headers-only broad `kernel_changes`
indicator does not itself mean boot preparation or code5. Module state and raw
status also need not equal aggregate outcome: a raw-success check can coexist
with aggregate failure because of an independent workflow error.

## Module shapes and values

`check` contains only `modules.slackware`, with exactly `state`, `check_exit_code`
and `updates_available`. Raw0 maps to success/false; raw100 to success/true; other
raw integers to failed/null. Null does not mean no updates.

`dry-run` and `apply` contain exactly six modules: `slackware`, `flatpak`, `sbo`,
`elf`, `cinnamon` and `boot`. Their complete individual field sets and types are
in the candidate schema and selected source inventory. Dry-run plans/capabilities
and apply statuses/metadata are different objects and cannot be interchanged.
Strings carrying commands are descriptive data, never instructions to evaluate.

Module modes are `auto`, `enabled` or `disabled`. Activation and most module-state
labels remain strings: this proposal does not silently turn every incidental
diagnostic label into a closed stable vocabulary. Check and Slackware apply
success/failure projections retain their narrower enums. Constant source reports
such as `executes_inspected_objects: false`, queue isolation and atomic GRUB
replacement remain typed declarations, not native proof of those mechanisms.

Counters are nonnegative integers. Nullable action/validation statuses are null
when not run/unavailable as represented by the current serializer; integer0 is
a known reported status, not null. The raw check code remains an integer, and
intermediate event codes retain their own raw domain. No shared global errno
interpretation or automatic count/list equality is imposed: counters and arrays
can describe different stages and validity cuts.

Build-option items contain exactly string `target` and string `options`. This
is a JSON projection, not an options grammar validator. Original native
install20 still needs empty AND no-effect evidence; native upgrade20 is failure.
Representing raw20 in a schema or retaining the current shell reference's code0
projection does not amend those distinct original contracts.

## Single events and completed-stream profile

An event has exactly11 required fields: version/status, positive integer sequence,
timestamp string, operation, type, nullable string module/action/state, message
string and nullable integer exit_code. Supported types are the eight existing
operation/module/action start/completion and warning/error wrappers.

Intermediate event exit codes may be negative, nonzero or null; raw100 and20
are not final success/failure classifications. `operation_completed` instead has
a stable code0-8, null module/action and success/warning/failed state. Accepting
a supplied final record with6/7/8 proves shape only: current early exits are not
claimed to emit that lifecycle. Cross-field native truth, complete module/action
pairing and terminal custody are not supplied by the single-record schema.

The separate completed-stream profile requires:

1. UTF-8 strict JSON, one nonempty object per line, final LF; CRLF is accepted.
2. No duplicate JSON object keys, NaN, Infinity or concatenated JSON documents.
3. An initial operation_started and exactly one operation_completed at the end.
4. A constant operation and consecutive sequence values within the supplied
   stream. A nonzero initial sequence is allowed for supplied helper fragments;
   ordinary complete runtime starts from the initialized sequence.

The test's framing reader checks this limited profile. An empty, partial or
truncated stream is not a completed result. Absence of a stream during an early
exit is not itself a new runtime defect. Sequence numbers and LF framing prove
neither lossless delivery, clock validity, durable recording nor full drain.

## Compatibility and future migration

Consumers must dispatch by integer schema_version and by stream/result family;
they must not infer a version from available fields. V0 remains provisional and
is outside the candidate v1 validator. An implementation that supports only v0
must reject v1 as unsupported; a v1-only consumer must not silently accept v0.
No adapter, negotiation flag, fallback or dual-output mode is introduced here.

The proposed v1 producer field sets and enum values are fixed. Adding/removing
fields, changing types/null meaning, array meaning, stable code meaning or a
closed enum would require an explicitly reviewed new schema version. Changes
to free diagnostic/path/state string values may remain compatible; consumers
must not parse such text as commands or infer unpromised fixed labels. The
English exit_code_meaning is tied to code in this proposal; localization there
would need an explicit contract change rather than a silent string replacement.

Before a real v1 switch, separately review consumer expectations and these open
decisions: final acceptance of exact fields and compatibility policy; timestamp
and open-state-label policy; any stronger semantic/cross-field assertions; early
failure delivery requirements; emitter/test migration and rollout. Then implement
and test an explicit switch. A tag, schema freeze, successful native run or
Phase1 completion does not follow from committing this candidate.

## Verification and PC execution boundary

New schema tests need Python3 and `jsonschema`4.x; the prepared run used4.23.0.
This is a development-test dependency, not a runtime dependency of the shell
reference. The delivery checks availability before changing any repository file.
It does not install packages, run pip, use sudo or contact the network on the PC.
If the dependency is absent, stop and report the diagnostic before applying.

The focused selection is shell syntax, the new schema test, and the four existing
check/dry-run/apply/event regressions. The new test validates75 positive cases
and69 negative controls, including48 projections of unchanged independently
authored v0 expectations with only prospective metadata substituted. Examples
are authored data, never captured subject output. Literal field inventory checks
are lexical correspondence, not a shell graph or reachability proof.

The schema check imports existing expected-data Python definitions and creates
owned temporary data files. It does not invoke their shell runners. The separate
unchanged regressions source Bash declarations and call supplied-state helpers;
apply uses a fixed clock with state initialization, not runtime initialization.
They do not enter `main`, load configuration, acquire locks, probe mirrors or
run package/boot workflows. Their own documented private-file and cleanup limits
remain. No full111 integration or native acceptance is claimed by this selection.

All original operational findings, native gaps, proof/case/raw/relationship
criteria, separate platform evidence and inherited history qualifications remain
open/binding in their recorded scopes. Project source and all existing tests are
byte unchanged. Preparation and PC acceptance remain separate from a later whole
inherited-condition review required for any new qualified STATIC pause.
