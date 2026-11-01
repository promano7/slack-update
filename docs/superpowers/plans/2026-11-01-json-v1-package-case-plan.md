# JSON v1 Package Case Assessor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. The execution method and plan review remain pending; do not implement before the handoff decision. Steps use checkbox syntax for tracking.

**Goal:** Add the approved import-only offline package-case assessor, authored prospective fixtures, tests and documentation.

**Architecture:** Keep complete candidate shape validation separate from scoped data relations and literal expectation agreement. Compare only supplied immutable records; preserve mismatches and unknowns simultaneously, with no command dispatch or native evidence collection. Existing producer, schema, frozen original modules and v0 oracles remain unchanged.

**Tech Stack:** Existing project Python3, unittest, frozen dataclasses, hashlib, the current jsonschema4.x development environment and unchanged exact Draft202012 candidate reader. Introduce no newer Python syntax/version floor; use typing.Optional/Tuple where needed.

**Spec:** proposal/PACKAGE-CASE-DESIGN.md, SHA256 `6db49bd51fd5dd3d82c9d0dedb453d6dce4f1527acc4888f03e0b014f5e05926`; proposal/CASE-MATRIX.json, SHA256 `3e72589b251a16e6419078debc4f55eb09ddd135ccd2f5d03c978ec9a09faee4`. The owner's exact approval is retained in OWNER-DESIGN-APPROVAL.json. These files travel with the plan; read both spec and matrix.

## Global Constraints

- Base: commit95b3901905d4399fb767d275fc6d7581f12396d0/tree8622a4d5b825c61aac6d9135ea17432ef9935a21;2597 canonical files. Refresh main before execution and stop on unexpected base changes rather than silently applying this plan.
- Scope: offline assessor/authored fixtures/tests/docs only. No producer/event/result-schema/validator behavior change, version switch, collector, native/VM/package/boot action or new operational right.
- Preserve every original v0 oracle/capture and frozen native module byte-for-byte. Native install20 still needs genuinely empty stdout AND no effects plus all original applicable criteria; mandatory native upgrade20 remains failure.
- Private records are frozen and recursively validated; tuple vectors retain order/duplicates, unknown is not empty, bool is not integer. No public wire schema/adapter/fallback is added.
- Always return native_acceptance=false, independence_verified=false, runtime_authority=false and phase1_complete=false. Matching private data cannot discharge original native obligations.
- The28 matrix cases are currently definitions, not executed tests. Expected objects must be authored before subject observations and never generated from assessor/producer output.
- Existing schema files may be read only through the unchanged CandidateValidator. No caller-supplied path/config/command is read or executed. File IO in test loaders is separate and explicit.
- All source/comments in English. The assistant prepares reviewable changes; the owner performs the final project commit/push. Per-task checkpoints do not authorize assistant commits or remote changes.
- No implementation has started. Review this concrete plan and choose an execution method first, as required by writing-plans.

## Review Focus

- Invalid private record shapes versus valid unknown fields: reject mutable/wrong-typed inputs, including bool statuses and None inside complete effect vectors (Task1).
- Complete/incomplete/not-produced streams: preserve b'' versus b'\n', declared size/hash conflicts and unknown error-free facts without inferring native truth (Task2).
- Missing applicability/config/run identity: never infer disabled from null; retain identity conflict with pending evidence (Tasks2/3).
- Wrong result family/duplicate keys/integral numeric spelling and absent early output: use the full strict reader, respect mathematical integers and separate actual-operation status from serializer status (Task3).
- Hidden execution or stale bindings during integration: keep capabilities absent, imports inert, previous bytes exact and inventory/dossier dependencies acyclic (Tasks1/4).

---

## File responsibilities

| File | Responsibility |
| --- | --- |
| tools/reference/json_v1_package_case.py | Frozen private records, input validation and assess_package_case; no CLI or registration |
| tests/reference/test-json-v1-package-case.py | unittest entry point, test-only fixture loader, full expected-assessment comparison and capability guards |
| tests/fixtures/reference/json-v1-package-case/ | P01-P28 complete authored result bytes, private supplied data and literal expected assessments; explicit absence in P24 |
| data/schemas/candidates/package-case-inputs.json | Exact acyclic bindings for new module/test/fixtures/spec/plan/guide, excluding itself and files that bind it |
| docs/reference/json-v1-package-case.md | API, scope, case semantics, execution commands and historical/native limits |
| docs/superpowers/specs/2026-11-01-json-v1-package-case-design.md | Exact approved design, copied without rewriting its historical proposed-status text; separate approval record governs |
| docs/superpowers/plans/2026-11-01-json-v1-package-case-plan.md | This plan after handoff approval |
| Existing candidate inventory/migration/dossier and CHANGELOG/docs navigation | Register the new bounded consumer/inputs and implementation status, retaining exact preimages under history/pre771 |

## Shared private interface

Record names/field choices below are implementation decisions within the approved design. All records are frozen; exact types/tuple shapes are checked at assess entry. Input contradictions that are valid data produce diagnostics; structurally invalid private inputs raise ValueError. Unknown components are permitted only where explicitly Optional.

| Record | Fields |
| --- | --- |
| CaseIdentity | case_id, platform, platform_version, source_epoch, boot_id, attempt_id, run_id: Optional[str] |
| ConfigurationFacts | identity: Optional[str]; install_new, upgrade_all: Optional[bool] |
| ByteCapture | state: complete/incomplete/unknown/not-produced; data: Optional[bytes]; declared_size: Optional[int]; declared_sha256: Optional[str] |
| ActionRule | name: update/install-new/upgrade-all; applicability: required/disabled/blocked/unknown; criterion: original-update/empty-install20/mandatory-upgrade/no-action/unknown |
| ActionFacts | name; raw_status: Optional[int] with exact domain-1..255; stdout, stderr: ByteCapture; selector, target_effects, owned_effects, unexpected_effects: Optional[Tuple[str,...]] |
| ProcessFacts | origin: authored-fixture/serializer-helper/captured-operation/unknown; status: Optional[int]0..255; stdout, stderr: ByteCapture |
| CaseProfile | identity: CaseIdentity; configuration: ConfigurationFacts; actions: exact ordered three ActionRule records; boot_unsafe: Optional[bool] |
| CaseEvidence | identity; configuration; actions: exact ordered three ActionFacts records; update_streams_error_free: Optional[bool]; raw_pkglist: ByteCapture; pin_identity: CaseIdentity; pin_artifact_id: Optional[str]; process: ProcessFacts |
| CaseExpectations | evidence: CaseEvidence; result_bytes: Optional[bytes]; outcome: success/failure/absence/unknown; forward_failure_expected: Optional[bool] |
| Check | key: str; state: match/mismatch/pending; detail: str; all strings are data, not diagnostic grammar promises |
| Assessment | shape: valid/invalid/absent; checks, matched_checks, mismatched_checks, pending_checks: Tuple[Check,...]; forward_failure_known: bool; outcome_agreement: match/mismatch/pending; data_disposition: match/mismatch/pending; the four authority flags fixed False; outstanding_native_obligations: Tuple[str,...] |

Public function:

`assess_package_case(result_bytes: Optional[bytes], profile: CaseProfile, expectations: CaseExpectations, observations: CaseEvidence) -> Assessment`

Internal validation entry point for Task1:

`validate_case_inputs(profile: CaseProfile, expectations: CaseExpectations, observations: CaseEvidence) -> None`

ByteCapture complete requires actual bytes; unknown/not-produced require data=None and no invented observed hash/size; incomplete may carry a prefix, never a complete observed digest. Keep invalid shapes distinct from complete known data with a size/hash mismatch. SHA declarations are lowercase64-hex or unknown. A declared size is an exact nonnegative int, never bool. For not-produced, no complete command stdout is fabricated. Whole vectors may be None; vector elements may not.

CaseIdentity components and the separate pin_artifact_id compare component-wise. Configuration identities and requested flags must agree before classifying a known disabled action. Declared identity equality is only a data relation, never native same-object protection/provenance.

The assessor's outstanding obligation labels preserve the original12 evidence groups from the unchanged original comparator; the complete original bodies remain binding. They are not a new abbreviated acceptance contract.

Test-only interfaces in tests/reference/test-json-v1-package-case.py:
`load_case(case_id: str)` returns result_bytes, profile, expectations, observations
and a separately authored wanted Assessment from that case's fixture files.
`case(case_id: str) -> Assessment` calls the public assessor, compares its complete
result against that wanted assessment with exact private record types, then returns
the observed assessment for the short assertions below. Neither helper derives a
wanted value from the subject, its reducers, or a previous observation.

## Task1: Validated immutable inputs and inert loading

**Files:** Create tools/reference/json_v1_package_case.py; create tests/reference/test-json-v1-package-case.py.

**Interfaces:** Produces the records and validate_case_inputs above. It loads the existing candidate-reader declarations without running main; construction of its validator remains explicit at assessment time. Test-only loaders remain in the test file.

- [ ] Establish an isolated execution checkout per using-git-worktrees. Confirm exact base/status. Keep original source/evidence untouched; record any unexpected extra separately, never delete it.
- [ ] Preflight the chosen development interpreter with `python -c 'import jsonschema; from importlib.metadata import version; print(version("jsonschema"))'`; require existing4.x. If absent, prepare a separate dev environment using the established dependency workflow, retaining failures; no native installation or weakened reader. Missing setup is not credited as a TDD RED.
- [ ] Write RecordValidation tests first: valid frozen records; wrong action order/name; mutable list/effect payload; bool raw/size; unknown whole vector versus None element; complete-without-bytes; explicit not-produced; capability-free import. The missing module/entry point must produce an intentional test assertion, not be mistaken for a dependency error.

```python
with self.assertRaises(ValueError):
    validate_case_inputs(profile_with_raw_bool, expected, observed)
with self.assertRaises(ValueError):
    validate_case_inputs(profile, expected, observed_with_mutable_effects)
```

- [ ] Run `python -B tests/reference/test-json-v1-package-case.py RecordValidation -v`; retain stdout/stderr/status. Expected RED is the named missing record validation or failed behavior assertion.
- [ ] Implement the frozen records and validate_case_inputs only. Avoid test convenience methods on production records.
- [ ] Run the same command; expected all RecordValidation tests pass. Record the RED/GREEN evidence and a task diff checkpoint. No assistant commit/push.

## Task2: Exact observation relations and original install20

**Files:** Modify the two Task1 files; create authored fixture triples for P01-P08, P20, P25 and the full baseline v1 object in tests/fixtures/reference/json-v1-package-case/.

**Interfaces:** Consumes validated records. Produces assess_package_case and the Assessment/Check records above, initially covering identity/config/complete-byte/update/install20 relations. Later task adds remaining action/result relations; do not release a partial assessor.

- [ ] Author complete prospective result bytes and literal expected Assessment objects for these cases before subject observation. Test loader translates fixture-only byte encodings into bytes; expected assessments never call the subject or its mapping helpers.
- [ ] Write tests for exact expected/observed identity, ordered selectors/effects, update stdout/stderr and raw-pkglist bytes, size/hash declarations and separate error-free fact. Add incomplete update pin, missing error-free fact and matching digests with missing raw bytes as pending controls; byte/hash conflicts remain known mismatches. Do not infer actual pin continuity.

```python
self.assertEqual(case('P01').data_disposition, 'match')
self.assertEqual(case('P02').data_disposition, 'mismatch')
self.assertEqual(case('P06').data_disposition, 'pending')
self.assertTrue(case('P08').mismatched_checks)
self.assertTrue(case('P08').pending_checks)
```

- [ ] Run `python -B tests/reference/test-json-v1-package-case.py EvidenceRelations -v`; expected RED for the specific missing byte/unknown/install rule, not bad fixture shape. Keep the complete failed observations.
- [ ] Implement exact byte/tuple and component comparisons; require complete b'' stdout and empty complete selector/target/owned/unexpected vectors in the original install20 case. Keep nonempty stderr separate; no inferred universal stderr-empty rule. Track update error-free and pin data without claiming actual source protection.
- [ ] Run RecordValidation and EvidenceRelations together. Expected all pass; full expected Assessment comparisons preserve both conflict/pending sets, order/duplicates and fixed-False authority flags. Record checkpoint without committing.

## Task3: Complete result shape, action applicability and failure coherence

**Files:** Modify module/test; create remaining fixture triples so P01-P28 are independently identified and complete except explicit absence/invalid controls.

**Interfaces:** Consumes Task2 assessor and record types; completes all approved assessment behavior. Existing CandidateValidator/decode APIs remain unchanged.

- [ ] Author remaining result/data/expected triples before running the subject. Use desired prospective failed result2/3 where appropriate, not metadata-only conversion of historical success output. Preserve the old reference-no-match fixture and factory exactly.
- [ ] Write ActionCoherence tests for required/disabled/blocked/unknown; original upgrade20 failure; unattempted-1 versus unknown None; raw0 versus result null; update42 absorbing forward failure versus observed later execution; exact approved upgrade target/effects. Unknown applicability or configuration keeps the relevant classification pending even when a declared result raw is null.
- [ ] Write ResultShape tests using the complete exact reader: bool raw refusal, v0/wrong-family refusal, malformed/duplicate-key/NaN/second-document refusal; integral numeric spellings1.0/1e2 remain mathematical integers. Present shape-invalid yields mismatch; P24 absent/early status7 remains pending with no fabricated JSON.
- [ ] Pin numeric result comparison: after strict shape validation, compare candidate numeric values mathematically while keeping booleans distinct. Do not apply the old v0 decoded-int-only oracle to valid candidate1.0/1e2. Private observed OS statuses still require exact Python integers-1..255 and retain their separate domain.
- [ ] Write all CaseMatrix test_P01 through test_P28 assertions as complete assessment comparisons. Add direct controls for serializer process0 versus modeled failed JSON2 and for captured-operation process/JSON disagreement; match process to its separately authored origin/expectation rather than equating every process status with JSON.

```python
self.assertEqual(case('P12').data_disposition, 'match')
self.assertTrue(case('P12').forward_failure_known)
self.assertEqual(case('P27').data_disposition, 'mismatch')
self.assertEqual(case('P28').data_disposition, 'mismatch')
self.assertFalse(case('P15').native_acceptance)
```

- [ ] Run the named new classes first; retain intended RED assertions. Implement the missing rules without changing fixtures to fit observations. Known required-package failure requires Slackware failed plus success=false/partial=true and case-justified2/3, even if an unrelated module already caused aggregate failure. Compare complete ordered case-local errors/warnings; do not add global diagnostic enums or every-failure errors-nonempty.
- [ ] Complete expected-outcome agreement independently of forward failure. Outcome match cannot clear forward_failure_known. Compute scoped disposition mismatch before pending before match, retaining all checks. On malformed result, do not trust its decoded fields; independent observation conflicts can still be reported.
- [ ] Run `python -B tests/reference/test-json-v1-package-case.py -v`; expect all28 named matrix cases and additional guard/type/byte controls pass. Counts are reported by domain, never as native cases. Record RED/GREEN and no-release checkpoint.

## Task4: Integration, bounded regressions and reviewable delivery

**Files:** Create the guide, exact input manifest, copied approved design/approval/plan paths listed above. Modify only required candidate inventory/migration/dossier bindings, CHANGELOG and relevant docs navigation/roadmap; retain their complete preimages under data/schemas/candidates/history/pre771/.

**Interfaces:** Consumes the complete tested assessor. Produces an exact bounded consumer registration and full reviewed repository overlay, never a producer/native change.

- [ ] Write integration tests first for inert import/assessment: deny execution-capability calls in a confined test process and assess supplied data; an attempted command must fail the guard. Allow only the unchanged reader's two repository schema reads; strings resembling paths/commands stay inert. Report this as a tested boundary, not OS containment or a complete dynamic graph.
- [ ] Write identity tests for unchanged producer/result-schema/event-schema/reader/v0 fixtures and frozen native modules. Tests also verify exact new fixture ID set P01-P28 and literal complete expected assessments; source mutants that trim stdout, collapse null, ignore module state or discard pending facts must be rejected in disposable copies.
- [ ] Implement documentation and acyclic bindings. package-case-inputs.json binds new code/test/fixtures/guide/spec/plan; it never hashes itself or the dossier that binds it. Refresh literal metadata discovery honestly and register additional semantic consumer/dependency roles even where schema_version is not lexically present. Dossier adds only the exact offline design approval; original whole-contract dispositions remain unchanged/pending.
- [ ] Run the new full suite and the seven unchanged focused drivers below using the same verified4.x interpreter. Retain complete command/status/stdout/stderr. Do not execute native/acceptance scripts or a blanket dispatcher. There is no safe universal project command that overrides the separately authorized native suites.

```bash
python -B tests/reference/test-json-v1-candidate.py
python -B tests/reference/test-json-v1-policy.py
python -B tests/reference/test-json-v1-consumer-inventory.py
python -B tests/reference/test-json-v1-serializer-compatibility.py
python -B tests/reference/test-json-v1-numeric-exactness.py
python -B tests/reference/test-json-v1-check-coherence.py
python -B tests/reference/test-json-v1-success-coherence.py
python -B tests/reference/test-json-v1-package-case.py -v
```

- [ ] Run git diff --check and compare the complete changed-path/old-new mode inventory against the exact base. Obtain a fresh-context whole-change code review; fix material findings with their own RED/GREEN checks. Resolve and record every declined scope judgment without implying native/oracle independence.
- [ ] Prepare a guarded PC application package: exact-base/clean tracked-index checks, new-path/symlink collision refusal, isolated candidate tests before changes, explicit changed-path-only writes and retained originals/outputs. Rehearse success and refusal cases only in owned disposable local copies. Do not commit/push or enter a native workflow.
- [ ] Deliver full source/overlay/manifest/verifier/checksum, updated roadmap/state and exact git add/commit commands for the owner. Keep application/publication/new full pause review pending until the actual owner return; do not promote local preparation into repository or native acceptance.

Suggested eventual owner commit message: `Add offline prospective package-case assessment and authored coherence tests`.
The final git add list is generated from the reviewed exact changed-path manifest, not guessed now.

## Plan self-review

- Spec coverage: input/unknown/byte/profile obligations map to Tasks1/2; complete result/action/expected-failure behavior and all28 cases to Task3; unchanged history, no-dispatch, current exact consumer registration, review and delivery to Task4.
- Step scan: tests precede implementation; explicit commands and expected RED/GREEN are stated; dependency failure is not a behavior RED. Names/fields/signatures above are consistent across tasks.
- Review Focus: all five input classes have explicit tests in their owning tasks. No native capture, operator grant, new schema or producer switch is planned.
- Proportion: four tasks share one tightly coupled private API; this plan specifies interfaces/checks instead of function bodies. Execution details not fixed by the spec remain ordinary builder choices, recorded as rulings if material.

## Handoff decision

The design is approved; this concrete plan has not yet been reviewed by the owner,
and no execution method was supplied. Recommend direct execution in this session
with TDD, a decision ledger and one fresh-context whole-change reviewer: the tasks
share a single private API and fixture model, so this avoids repeated interface
handoffs. Subagent-driven execution remains an alternative with per-task fresh
implementer/reviewer gates. Neither method establishes native-oracle independence.

Follow writing-plans: ask the owner to review this plan and choose direct versus
subagent-driven execution before implementation. No product code, new fixtures,
development setup or tests have been written/run at this planning handoff.
