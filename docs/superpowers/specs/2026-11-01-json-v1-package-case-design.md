# Prospective package-case assessment design

Status: proposed for owner review; not adopted, implemented or independently
accepted. Prepared in steps763-770 after qualified STATIC762. Exact project base:
commit95b3901905d4399fb767d275fc6d7581f12396d0,
tree8622a4d5b825c61aac6d9135ea17432ef9935a21. The canonical2597 files stay exact.

## Intent and authority

The owner's stability-first goal and the original operational criteria govern
this proposal. Current supplied serializers/consumers can admit upgrade20 success;
original mandatory native upgrade20 remains failure. Install20 still requires
genuine empty stdout AND no effects, together with complete original selector,
source, identity, capture and independent-expectation obligations. A declaration
of success or an empty errors array cannot establish those facts.

This design specifies the next small deliverable: an **import-only, offline
prospective case assessor with authored test data**. It makes the producer's
eventual obligations and the consumer's checks explicit together. Approval of
this document would authorize preparation of that offline deliverable and its
tests/documentation only. It would not authorize a producer change, metadata
switch, native collector, VM/package/boot action, native grant, schema amendment,
contract freeze, or whole independent semantic/native acceptance.

The concrete implementation plan comes after owner approval. This document is
external review material; it is not an overlay to apply to the project now.

## Approaches and recommendation

| Approach | Consequence | Disposition |
| --- | --- | --- |
| Add a global schema raw20/null rule | Cannot observe stdout/effects or tell disabled from blocked/unattempted; install20 and mandatory upgrade20 have different rules | Rejected as an adequate solution |
| Change the running producer and old native validators immediately | Would enter separately gated migration/native work before prospective expectations and compatibility are ready | Deferred behind those existing gates |
| Add a separate offline case assessor and full authored prospective cases | Exposes missing observations and contradictions while retaining exact v0 oracles and current candidate; establishes a reviewable consumer target | Assistant recommendation, not a new owner adoption |

The existing source and constraints leave the third approach as the proposed
next implementable increment. The owner has requested continuation; that does
not supply an approval of this newly written exact design.

## Observed current boundaries

1. update_slackware_system always attempts update when entered, then uses separate
   SLACKWARE_INSTALL_NEW/SLACKWARE_UPGRADE_ALL configuration booleans. Initial raw
   statuses are-1. The current function does not stop the later calls merely
   because update failed. That is source inspection, not a native execution result.
2. slackpkg_apply_action_failed sees only action/status. It accepts update0,
   install0/20, upgrade0/20 and-1 as nonfailure. Diagnostics and Slackware result
   state reuse it. json_nullable_status renders negative statuses as null.
3. The result reports raw nullable statuses but no action-specific applicability,
   requested/attempted/blocking reason, native command streams, full selectors or
   complete effect vectors. Snapshot record counts are not effect observations.
4. The candidate reader strictly validates result shape/version but neither runs
   an operation nor proves native truth. S1-S3 are declaration coherence rules.
5. Frozen original351/353 declarations/comparator have18 selector/effect slots,
   including update stream digests but no dedicated install stdout slot. Their
   existing comparison cannot alone establish install20 stdout emptiness. They
   remain exact historical inputs, not an API to weaken, patch or replace here.

Bindings for selected source inputs are in evidence/DESIGN-INPUTS.json. This is
not a complete dynamic graph or a claim to reread all original native code.

## Goals, non-goals and failure conditions

The assessor must distinguish valid candidate shape, scoped declaration/evidence
relations, unknown observations, known forward failure and case expectation
agreement. It must preserve every known mismatch even when other data is unknown.
It must never derive expectations from the output being checked.

It must not accept arbitrary apply combinations as a native scenario, convert v0
to v1, collect evidence, load paths/configuration on demand, dispatch commands,
change the public candidate fields, edit frozen original codecs/criteria, or
reclassify an original forward failure after restoration/publication.

Failure would include treating null as0/empty, trimming newline stdout, inferring
no effects from equal counts, selecting a native option, claiming independent
oracles because of roles/hashes/review, or coupling old tests to changed expected
values until the original discrepancy disappears.

## Data interface

Proposed module: tools/reference/json_v1_package_case.py. It is import-only,
without a CLI or runtime registration. Proposed function name:
assess_package_case(result_bytes, profile, expectations, observations).
Return a frozen data assessment; no callbacks, file paths to read, or execution
hooks are accepted. All command-like strings are inert data.

The function uses the existing exact CandidateValidator/decoder for complete
prospective result shape when result_bytes is present. Imports must not run main.
The existing jsonschema4.x development dependency is reused; its absence is a
setup limitation, never a reason to skip or weaken shape validation. No new
dependency, installation or product scaffold is authorized by this design draft.

The new profile/expectation/observation values are private Python frozen records
and tuples, not a second public wire schema, negotiated version, adapter or fallback.
The implementation plan must enumerate their exact field names from the table
below. Naming and code layout may be settled by the builder; semantics may not.

| Input component | Exact meaning and required distinction |
| --- | --- |
| Profile identity | Declared case/platform/platform-version/source/boot/attempt/run identity; each unknown component stays unknown. Private fixtures use explicit fictitious labels; no real binding is invented |
| Profile configuration | Separately supplied expected configuration identity and per-action applicability. Equality of declared identities is a data check, not continuous native identity/protection proof |
| Action applicability | required, disabled, blocked, or unknown for each of update/install-new/upgrade-all. It comes from the case declaration and bound configuration/precedence data, never from JSON null alone |
| Expected outcome | Independently authored literal expected success/failure/absence facts for the scoped case. Author/provenance declarations retained; this module cannot verify independence |
| Result/process | result_bytes or None; separate captured process status/stdout/stderr and completeness/knownness. Serializer process0 is not an apply process0; supplied fixtures must label origin |
| Per-action raw | Original observed integer-1..255 or None. -1 means known not attempted; None means unknown. Candidate mathematical integers retain their own schema domain, including integral decimal spelling; a wire integer is not an OS observation |
| Per-action streams | Complete raw bytes or unknown, separate stdout/stderr and completeness facts. Empty bytes differ from newline/whitespace and unknown. For a known unattempted command, streams may be not-produced explicitly, never an invented empty capture |
| Selectors/effects | Complete ordered tuples or unknown, separate selector/target effects/owned effects/unexpected effects. No sorting, deduplication, count/sample/hash substitution or actual source lookup |
| Precedence | Complete declared ordered action/raw observations; known upstream failure and blocked later actions remain distinct from disabled actions. Unknowns cannot establish successful forward admission |
| Provenance | Exact original references/declarations for expected and observed data; no identity, collector, trusted-origin, custody or independent-source proof is inferred from them |

For the original update row, the selected private data fields are specifically:
expected and observed complete update stdout bytes; expected and observed complete
update stderr bytes; separately declared expected/observed update-streams-error-free
boolean or unknown; expected and observed complete original raw-pkglist bytes;
their completeness facts and declared SHA256 values; and expected/observed declared
original pin identity tuples. The pin identity tuple has the same ordered
case/platform/platform-version/source-epoch/boot/attempt/run components as profile
identity, plus an opaque original artifact identifier. Unknown whole bytes or an
unknown tuple component stays pending. An explicitly incomplete capture cannot
establish a complete byte relation.

Compare complete expected/observed bytes exactly, check supplied size/digest
declarations against those bytes and compare the declared pin identity components.
Require observed update raw0 and error-free=true in the original required update
profile. The error-free declaration is not derived by searching diagnostics or
assuming nonempty stderr is erroneous. A missing error-free fact stays pending
even when bytes match. Same regular object, actual fresh pin, continuous protection,
source closure and absence of rebinding remain original native obligations outside
these selected data checks; a matching declared tuple cannot establish them.
Do not add a filesystem lookup, parser for a live pkglist or collector to fill gaps.

Do not coerce booleans into integer statuses. Reject invalid private record shapes
explicitly. Unknown is permitted only at documented whole fields, not as a nullable
element inside a supposedly complete vector. Candidate wire numbers must use the
existing exact-number policy rather than the old v0 Python-type oracle.

The selected observations do not replace the original56 slots,12 raw groups,
complete original bodies or their proof/case/source/custody obligations. The new
module must explicitly label all other native requirements outside its scope.

## Scoped checks

Apply these checks only to the declared case profile; unknown applicability yields
a pending classification, never an inferred disabled action. Conflicting known
case/config/run identities are mismatches and do not erase other pending checks.

| Case guard | Required scoped relation |
| --- | --- |
| Known required action with raw-1/result null | Required action absent is a known mismatch; do not infer native success |
| Known disabled action | It is not attempted; retained result raw is null; known action selector/effect vectors are empty; no command stream is fabricated. Unknown evidence stays pending where required to establish the non-execution relation |
| Known blocked action after an upstream failure | It remains unattempted; later forward effects are conflicts; preserve original failure and supplied raw evidence. A known upstream failure does not rewrite an actually observed later raw code to-1 |
| Original required update case | raw0 and original error-free streams/raw-pkglist pin/source requirements remain. A digest alone cannot satisfy the missing complete original evidence |
| Original empty install20 case | raw20, genuinely complete stdout b'', independently known complete empty selector and no required target/owned/unexpected effects; unknown parts remain pending. No automatic empty-stderr rule is invented |
| Original mandatory upgrade case with raw20 | Record known original action failure. A candidate result0/4/5 with Slackware success is a conflict even if its shape passes |
| Original mandatory upgrade case with raw0 | Exact ordered approved single-target selector and complete expected effects must agree; len1 or raw0 alone cannot satisfy them |
| Known package failure plus ordinary reboot recommendation/requirement | A supplied desired failed result preserves ordinary aggregate2; supplied critical boot failure preserves3. Codes4/5 cannot turn the known failure into success. This is a desired case-data relation, not a new native execution |
| Result absent/incomplete | Keep absence and process/stderr separately. Do not manufacture a JSON result, infer module completion, or convert an early status7 into a package result. Package checks remain pending if the required result is unavailable |
| Known mismatch plus unknown evidence | Keep both mismatch and pending sets; mismatch has aggregate data priority |
| Expected failure scenario matches its literal oracle | Case expectation agreement may be match while forward_failure_known remains true; matching a failure does not make the forward action successful |

For the declared original required-package profile, a known update/install/upgrade
failure must agree with modules.slackware.state=failed, success=false, partial=true
and final result2 or3. Aggregate2/3 alone is insufficient if Slackware still says
success. The complete candidate already constrains aggregate booleans, but the
case assessor must add this action-to-module relation. Code3 applies only when
the separately supplied case boot-unsafe flags and complete result justify it;
otherwise the scoped expected ordinary failed result is2. Reboot fields keep the
existing complete candidate mapping and the case's exact supplied precedence.

Errors and warnings remain ordered literal case expectations. This design adds
no global rule requiring errors nonempty on every failure and no public diagnostic
grammar. The authored package-failure fixtures will include the applicable exact
failure diagnostic (for example the ordinary upgrade20 failure message proposed
for its future producer target), and compare the full array. A consumer may not
invent missing diagnostics or use errors=[] as evidence of success. None of this
rewrites the current producer or changes existing admissible schema shapes.

Install0 is not automatically assigned all install20 stdout requirements by this
increment. Any install0 case must state its complete original applicable criteria
explicitly before it can be added. Optional actions do not inherit mandatory-kernel
rules merely because they appear under apply. No generic raw-code success policy
is introduced for optional actions whose exact semantics remain undecided.

## Returned assessment and claim limits

Return these independent data facts: shape valid/invalid/absent; ordered matched,
mismatched and pending scoped checks; known forward failure; agreement with the
literal expected outcome; and a scoped data disposition of mismatch/pending/match.
Data disposition is mismatch if any known scoped conflict exists, otherwise
pending if any scoped check is pending, otherwise match. Always retain both sets.
Malformed/wrong-family/v0 result is an explicit shape refusal, not a conversion;
known independent observation conflicts may still be reported without asserting
that malformed result fields were trusted.
For this interface a present but shape-invalid/malformed/wrong-family/v0 result
adds a shape-refusal mismatch and gives data_disposition=mismatch; P22/P23 exercise
that rule. An absent result instead has shape=absent and required package checks
pending, as in P24. This difference must not be collapsed into a generic decoder
failure or a fabricated result.

The result must always declare native_acceptance=false, independence_verified=false,
runtime_authority=false, phase1_complete=false, and the outstanding original native
obligations. Even complete, matching private data does not prove collection,
containment, continuous source identity, before-use review, native effects, absence,
recovery, own-platform conformance or operational eligibility.

No new generic log grammar is frozen. Exact diagnostic text used in authored
fixture expectations is case-local; it does not become a public diagnostic enum.

## Joint producer and consumer migration boundary

The future consumer needs explicit applicability/configuration/attempt/stream and
effect facts from a reviewed case dossier; the present result JSON cannot supply
them by itself. The offline assessor therefore takes separate supplied data, with
unverified provenance made visible. It is not a native collector or protocol.

A future producer design must first resolve how those observations are safely
obtained/bound under the actual original source/effect/clock/recovery/finite-right
contracts. Adding internal counters or self-report fields is insufficient. Any
proposal to add public JSON fields must undergo a separate exact candidate/schema
and compatibility decision; this design authorizes none. No output version switch
is implemented until full applicable R2/R3 and the separately approved joint R4
plan, actual emissions/absence/composition tests and native gates are satisfied.

Retain all current v0 fixtures/tests/captures and history byte-for-byte. Add
separately named complete authored prospective v1 result objects and their own
expected relations; do not patch the old reference-no-match expectation. The two
old native consumer heredocs remain historical inputs. No test imports the new
assessor in place of its old oracle. New cases are not actual v1 emissions.

Proposed later files after approval: tools/reference/json_v1_package_case.py;
tests/reference/test-json-v1-package-case.py; tests/fixtures/reference/json-v1-package-case/;
docs/reference/json-v1-package-case.md. Any eventual binding/dossier/inventory or
CHANGELOG/roadmap updates need exact preimages and source refresh in that later
implementation delivery, reviewed before PC application. The owner commits/pushes.

## Verification design, not execution results

CASE-MATRIX.json specifies28 data scenarios. Every positive/negative fixture is
authored before observation and uses complete candidate results where applicable.
Include full expected assessment objects and unknown/mismatch dual controls.
Shape controls use the complete strict reader and exact bytes; the native rules
have independent literal expectations rather than calling subject mapping helpers.
Preserve array order/duplicates and raw stream bytes. A separately reviewed
expectation source is still needed before claiming independent native oracles.

Run the current seven candidate drivers plus the new offline suite in the approved
development environment during later implementation; no old native acceptance
script, workflow, main, platform probe, collector or package/boot command is run.
Apply source-mutant controls only in owned disposable copies and record failures;
do not mutate historical files. None of those tests has been newly run by this
design-only batch, and28 scenario definitions are not28 passing tests/native runs.

## Decisions and handoff

The assistant recommends the separate offline increment. The owner has not yet
approved this document or new profile/assessment behavior. Preserve all previously
received principles/A-F/J01-J12/J03-2/J11/S1-S3 with their original provenance;
this document neither requests them again nor upgrades their acceptance scope.

Remaining later gates include exact whole semantic/compatibility/independence
acceptance, prospective complete expectations, actual producer plan/emissions,
A/R/D unselected, P0D unresolved,13 findings,16 gaps/four inactive repairs,
five residual families containing20 scenarios, separate own-platform conformance and phase1/kernel/
schema1/reference-v1 closure. No live binding or consumed right is revived.

At the end of this batch: stop safely with the design reviewed and exact source
unchanged. Ask only whether the owner approves this exact offline increment.
Approval would trigger writing-plans before implementation in a subsequent task;
it does not select a native option or authorize native work.
