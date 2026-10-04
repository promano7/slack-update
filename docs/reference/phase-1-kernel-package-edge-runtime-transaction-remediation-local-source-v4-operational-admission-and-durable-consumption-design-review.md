# Step 320: external admission and durable single-use consumption design

Confirmed319 is ef0a34b (prefix only), complete547 PASS, first push success, clean
tree and matching HEAD/origin logs. Its original return is bound without rewriting
prepared319.318 remains the confirmed strong pause. The new319–328 route continues;
this stage selects an admission protocol contract, with actual implementation,
storage/launch primitive selection and independent conformance still blocked.

The successor entry is an explicitly versioned external admission service plus
worker envelope. Its invocation begins with an authenticated known-grant request,
before worker stage0. This is a proposed successor integration boundary, not a
silent reinterpretation or execution of frozen v2. The old worker stage0 stays
read-only and memory-buffer-only; stage1 installs worker traps before any worker
filesystem lock, log, ledger, backup or mutation. The external service has its own
error/obligation handling ready before its ledger/log writes and its own separately
reviewed controller scope. No service effect is hidden inside a read-only worker
stage or exempted from the full dependency/writer/effect graph.

Authenticate issuer, principal and a known grant before accepting its invocation;
an unauthenticated or unknown-grant request cannot burn another principal's grant.
After that boundary, irreversibly consume the original grant before any worker
preflight or request-binding preflight. A known authenticated invocation with wrong
requested bindings consumes and denies launch. A real worker preflight failure
also consumes the grant. Original sealed issuer scope/attempt/input bindings cannot
be changed to match drift. UUID, SHA or an unused text label do not authenticate.

The claim contract requires one linearizable durable compare-and-set from unused
to consumed-active. The same consumed-active attempt covers its later approved
stages and nested calls, not a fresh grant per command. It never rolls back to
unused, reissues, retries or renews this attempt. Before invoking the worker once,
durably spend its single launch slot. A crash after spend but before spawn burns
the opportunity; restart cannot replay it. A spawn syscall with unknown outcome
is never repeated. A receipt or identifier is not a relaunch capability.

This deliberately prefers a burned attempt with no worker over duplicate work.
The model does not prove the actual storage transaction, process launch or crash
semantics. Concrete supported storage and launch mechanisms remain unselected.
They require independent proof on Slackware15.0 and current, including service
restart, concurrent clients, file/metadata/directory/storage durability, supported
versions and authentic issuer scope. Failure to prove any of these blocks enablement.

If claim durability is uncertain, consumed state is null, not false or true. No
forward dispatch/replay occurs; the grant must be effectively quarantined against
every consumer/restart, with pending controller obligations. This global quarantine
is a future proof obligation, not guaranteed by a local failure return. Even a
later observation of an unused ledger row cannot automatically reopen this
invocation. Independently authorized reconciliation must preserve no-reuse and
pending evidence. Launch-slot uncertainty likewise stops; unknown spawn may leave
machine obligations and child status unknown. No actual empty-host claim is made.

321 must specify authenticated bounded handoff, worker/service/epoch/attempt binding,
lost acknowledgements and exclusion of every admission socket/service/descriptor
from the isolated backend. This stage chooses no handoff transport. An inherited
receipt/FD alone is not proof. Worker stage0 cannot be promoted to a guarded baseline;
after stage1 traps,324 must integrate continuous writer exclusion and fresh original
baseline before owned backup or target mutation.322 must classify persisted stage7
binding in a successor effect map.323 selects expiry/revocation and bounded recovery;
no recovery exception is granted by consumption.325 covers all service initialization,
helpers, callbacks, dependencies, writers and publication effects, target closure,
separate publication controls and the external last receipt.

The finite models cover two racing claimants, durable launch-slot ordering, loss,
crashes and failed worker preflight. Every real authority/conformance/pause result
remains false. These are typed in-memory contract events, not actual concurrency,
storage, broker, process, FD, reference main or host operations. All seven exact
requirements and ten cross obligations stay required-not-proven; the selected
protocol is a design review, not an operational freeze or completeness claim.

Only320 overlay/tests/exact commit/user push/return is currently deliverable.321
preparation follows complete320 acceptance; the roadmap grants no later/runtime
rights and329–330 stay optional/ungranted.320 is not a strong pause. Production and
Phase2 stay closed, Phase1/kernel edge incomplete. No new machine/controller cleanup
is required by this repository-only stage; actual host obligations/live bindings
remain unobserved/null. Historical v2 and prior grants/boots/bindings are not reused.
