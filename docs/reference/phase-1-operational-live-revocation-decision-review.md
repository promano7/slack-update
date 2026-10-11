# Phase 1 step380: live revocation enforcement and counterexamples

379-r1 accepted at reported b50554c:155exactorderedPASS/zero failures,9files4018
insertions/eightcreates, exactcommitmessage/successfulc3a141c..b50554c push and reported
clean matchingHEADorigin. UploadedUTF8return11499bytes/SHA256
37ed7b5f6ad71aea9e195fee4463deb89c4c1658d1b65e57c43c33e5c4d7f28b, no normalization.
Fullcommitunknown; not independent terminal/GitHub/native inspection. Original379
failed physical inventory is historical; accepted379-r1 uses Git-visible scope and
preserves ignored local outputs, never asserting their native absence or closure.

## Exact enforcement question

Whole original323fence/forward clauses and377conflict are retained in the dossier.
Trusted external original-attempt validity must span every actual permitted effect
without worker-held service/broker/control capabilities. A revocation receipt, an
admission acknowledgement, an actual effect admission, a stopping boundary and known
storage/child/effect completion are distinct events. Their native linearization and
failure relationships are unselected. This review neither requires the impossible
undoing of all earlier effects nor assumes that sending a kill cancels admitted work.
Original in-flight effects remain obligations; absence of independently known safe
stop/drain keeps their outcomes pending. Forward stop is absorbing, recovery uses
only explicitly retained original finite live rights, evidence/publication retain
their separate original scopes. No retry/refund/reacquire/rebind/deadline renewal.

## Candidate-specific decisions

| Candidate as stated | Disposition and precise shortfall |
| --- | --- |
| offline-lease-or-poll-only | incompatible-as-stated: Revocation can occur after the last accepted observation and before the next actual effect. Signature authenticity and expiry limits do not serialize that interval. |
| backend-macro-check-only | incompatible-as-stated: Revocation between two internal backend effects remains unmediated even when the backend macro admission was valid. |
| static-syscall-allowlist-only | incompatible-as-stated: Allowed syscall metadata alone does not observe a later change in external original authority, nor cover all target objects, asynchronous work and writers. |
| freeze-or-kill-as-live-fence | incompatible-as-stated: A task may act before freeze completion; already admitted effects and external writers remain obligations. Process-status evidence cannot by itself settle storage and effect uncertainty. |
| inspect-and-CONTINUE-only | incompatible-as-stated: A peer may change pointer bytes before kernel consumption; authority may change after response and before a later actual effect. A valid notification ID does not authenticate original rights or freeze arguments. |
| complete-external-effect-gate-hypothesis | unresolved: No exact native enforcer, source graph, primitive, protocol, platform support, failure behavior or independent conformance is selected. Naming a gate is not its implementation. |

Each disposition applies only to the described incomplete candidate and assumptions,
not every possible use of that primitive or every conceivable native composition.
The complete external-gate hypothesis remains unresolved, not selected or proven
compatible. A constituent that helps with containment need not implement the fence.
No guarantee is weakened and no universal impossibility theorem is claimed.

## Adversarial schedules and assumptions

- lease-gap: authority-observed-valid → external-revocation → worker-actual-effect. The candidate has no intervening live effect gate. A later expiry or poll cannot authorize the intervening effect.
- macro-internal-gap: macro-admission-valid → first-internal-effect → external-revocation → second-internal-effect. Macro admission is not continuous admission for subsequent real nested effects.
- static-policy-gap: static-filter-allows-write-class → external-revocation → permitted-write-attempt. The static rule contains no original live-authority serialization; hypothetical additional enforcement is outside this candidate.
- freeze-delay: external-revocation → freeze-request → task-effect-before-freeze-complete → freeze-complete. Request acknowledgement is not completion. Even completion alone is not independently proven full effect/storage drain.
- continued-pointer-race: notifier-inspects-pointer → notifier-responds-CONTINUE → peer-rewrites-pointed-bytes → kernel-consumes-changed-bytes. Assumes a mutable shared pointer buffer and no independent argument protection; rejects only this unprotected composition.
- continued-authority-gap: notifier-observes-authority-valid → notifier-responds-CONTINUE → external-revocation → later-real-effect-boundary. A notification response is not a proven gate spanning the later actual effect boundary.
- admitted-inflight-uncertainty: actual-effect-admitted-while-valid → external-revocation → inflight-completion-unknown. Earlier admission is not erased. Identify actual safe stopping boundaries and independently retain/drain obligations; do not assert all previously admitted effects are atomically undone.
- unknown-gate-outcome: original-budget-spent → admission-outcome-lost → effect-occurrence-unknown. Unknown stays pending with rights consumed; no retry, refund, renewed deadline, rebind or second launch.
- recovery-scope-split: forward-only-revocation → recovery-validity-unknown → recovery-effect-proposed. Forward-only revocation is not proof of retained recovery validity; recovery needs original explicit finite live scope and known prerequisites.
- observer-own-effects: evidence-writer-observes-validity → external-all-scope-revocation → evidence-own-write-proposed. Collector/injector/evidence/publication own writes require their own original scoped gates; observation roles confer no exemption.

These are declarative conditional schedules, not executed native tests, observed
failures, selected injection points or exhaustive concurrency coverage. In particular,
the pointer schedule assumes mutable shared memory and absent independent protection;
it does not reject a separately protected composition. The in-flight schedule retains
previously admitted obligations rather than inventing atomic rollback or zero effects.
Collector/injector own writes are effects too. No stage12shortening/renaming/receipt
self-observation or operational publication is opened by these questions.

## Verified primary semantics and explicit design inferences

The kernel [seccomp documentation](https://docs.kernel.org/userspace-api/seccomp_filter.html)
describes metadata-only BPF filtering and distinguishes filtering from complete
sandbox policy. Notification listeners belong to filters and can receive descendant
notifications. Our inference: these mechanisms alone do not establish the original
whole-effect graph, a live authority fence or no-worker-channel compatibility.

The [seccomp_unotify manual](https://www.man7.org/linux/man-pages/man2/seccomp_unotify.2.html)
describes CONTINUE and races with mutable pointer contents; notification ID validity
is not argument immutability. Our inference: inspect-and-CONTINUE without independent
protection and effect gating cannot discharge this guarantee. Primary indexed excerpts
were retrieved; direct full-page opens failed. No whole-page byte capture is claimed.
Emerging proposed changes are not selected or asserted absent from actual platforms.

The kernel [cgroup-v2 documentation](https://docs.kernel.org/admin-guide/cgroup-v2.html)
describes asynchronous freeze completion and migration behavior; kill handles concurrent
forks and migration for that kill operation. Our inference: a request or process-state
observation alone is not a whole storage/effect drain receipt or original live fence.
No weakening of the documented kill semantics is needed for that distinction.

Full primary-source register/retrieval limitations are bound by the policy. Docs were
verified in this review; no actual Slackware platform probing occurred. Each of the
six candidates has a separate15.0/current row with actual kernel/source/configuration/
authority/evidence null and no borrowed results. Twelve unknown rows are not platform
support, native proof, feasibility by distribution name, or an exhaustive support map.

## Resolution criteria and whole retained scope

The seven dossier criteria require original issuer/time/finite rights, complete
actual effects and all writers/aliases, actual revocation/effect serialization and
known stopping/drain, complete321offline-bootstrap/FD/channel compatibility, owner
loss/unknown outcome handling, independent two-platform full-vector conformance and
separate safe test entry. The six enforcer boundary questions stay null. Future native
tests need independently reviewed containment then a fresh explicit bounded grant;
successful results of that same future test are not its own permission prerequisite.

The complete378freeze/all21inheritedinputs/whole379plan and four inert source roots
remain byte+canonical bound. All8originalcontracts/16sections/16gaps/46proofs/52native
cases/12rawgroups/1072orderedrelations/all365prerequisites/all372blockers/all377conflicts
and whole stage12 remain normative. Counts, this stage's primary conflict and ten
authored schedules never limit original scope or discharge any row. Source bytes are
never executed/decoded; independent expectations/fault controls remain unobserved.

## Verification and next boundary

Pure reviewer accepts supplied bytes/data only; imports hashlib/json/re and has no
filesystem, clock, network, spawn, crypto, service, runner, collector or injector channel.
Harness checks full accepted1961-file bytes except additiveCHANGELOG, Git-visible scope
including tracked ignored names, whole inputs, receipt, decisions and hostile mutations.
Ignored local outputs are retained, not native absence evidence. Private localGit delivery
tests use a disclosed shortprefixshim only; no independent user/native/GitHub acceptance.
README remains exact. Actual host unobserved-not-claimed-absent, livebindingsnull,
globalclosurefalse; no native run/proof/component/authority. Phase1/kernel incomplete;
v1schema/reference-v1/C/Phase2/Productionclosed. Native composition remains BLOCKED.
380prepared until complete user overlay/tests/exactcommit/push/cleanmatchingheads;
only then381writer-alias-lifetime review. Last confirmed scopedpause378; conditional
pause388 requires complete finalreceipt/allnine original conditions thenSTOP/noautomatic389.
