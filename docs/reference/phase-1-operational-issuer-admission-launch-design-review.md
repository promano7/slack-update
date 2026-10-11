# Phase 1 step 371: issuer, admission and launch design

370 accepted at reported607d43c:133 exact ordered PASS,zero failures,exact8file5173
insertion/seven-addition commit,successful3a99d10..607d43c main push and reported clean
matching heads. Complete uploaded UTF8 return10516bytes retained without normalization;
SHA27156413aa4287550d74bab8dfb548c7c1a8cdd98238a1b8a21b15d5620bcc00. It is not
independent original terminal capture,checkout/GitHub/native inspection. FullIDunknown.
Historical prepared370 files stay immutable. Last confirmed scoped strong pause368.

## Concrete proposed protocol responsibilities

This draft makes the original320/321 requirements reviewable as ten protocol
responsibilities, five trust boundaries and explicit failure-cut questions. It
selects no actual issuer,service,ledger engine,key algorithm,verifier,parser,
pipe/timer,spawn or supervision primitive. The external admission protocol and
one-way anonymous bootstrap were already selected symbolically by320/321; they
are retained exactly, not replaced with a new operational implementation.
No service,worker,crypto routine,ledger file,wire parser or native runner is added.

| Boundary | Required proposed behavior |
| --- | --- |
| Service before own effects | Independent service error/obligation handling ready before ledger/log/receipt writes. Its dependencies,writers and crash cuts stay in the full graph. Worker traps are separate. |
| Authentication before burn | Independently authenticate issuer,principal and original known grant/service epoch. Unknown or forged victim ID cannot burn a grant. UUID/hash/path/env/self-signature supplies no authority. |
| Original durable claim | One linearizable irreversible crash-durable unused→consumed-active claim before worker stage0 or requested binding/preflight validation. A mismatch or failed preflight cannot return unused. |
| Claim uncertainty | Unknown consumption remains null; lost ACK never creates permission. Stop dispatch,retain controller obligations and effective global no-reuse quarantine. Separately reviewed reconciliation cannot reopen launch. |
| Original single launch | Durably pre-spend exactly the original launch slot before one actual spawn. No race loser,restart,unknown spend or unknown spawn may retry or renew. |
| Authenticated memory bootstrap | Original producer after consumption/spend sends one bounded canonical authenticated original context through one-way anonymous bootstrap,not an admission socket or online worker RPC. |
| Worker stage0 | One memory-only read/authentication within original bound and EOF deadline; reject malformed/lost context,close read end on every success/failure/timeout/signal before child exec. Writer end never inherited. |
| Worker stage1 and baseline | Worker traps before filesystem lock/log/owned writes,then original continuous guard and fresh original memory baseline before owned backup or target mutation. Early preflight is not that baseline. |
| Every descendant | Full inherited FD/object/alias/environment/cwd/mount/process/namespace/service reachability review across logging,nested backend and recovery paths; reviewed transport and no host fallback. |
| Loss and finite continuation | Original failure status,known/unknown outcomes,controller/possible machine obligations and full child drain retained. Same consumed-active attempt;no fresh grant per nested call or implicit recovery exemption. |

Moving ledger/log writes outside worker does not hide their effects or let them
precede the service's own handling. Conversely,external controller writes before
stage0 do not grant a local worker ledger/log before traps. Whole320 stage mapping
and321 lifecycle are carried unchanged; this table does not redefine original stages.

## Trust and authenticated context

Independent issuer/principal/key provisioning and original grant ownership must
be reviewed separately from worker-controlled source/files/environment. Receiver
verifier/trust-root/code provenance and one-shot launch origin must be independently
bound. The receipt cannot supply its own expected identity,scope,boot,launch or trust
root. Ledger/quarantine state is outside worker ownership/capability domains with
all native storage/writer semantics due. Supervisor/descendant identities and raw
collector/expectation provenance remain independent requirements,not trusted labels.

All14 original authenticated fields remain in their exact order:protocol,purpose,
issuer,service_identity,service_epoch,grant_id,attempt_id,launch_slot,launch_instance,
grant_state,launch_state,boot_binding,worker_identity,scope_bindings. Authenticate
the complete original canonical context together with domain/version/purpose/key
and compare it to independently reviewed original launch/grant bindings. Missing,
extra,duplicate,wrongly typed or noncanonical fields cannot become an accepted prefix.
The original domain is slack-update/successor-admission-context-only. A receipt is
neither bearer dispatch permission nor fresh target/storage proof. Actual signature
algorithm,coding,provisioning,protection,epoch handling and verification remain absent.

Whole original321 bootstrap retains maximum65536rawbytes,10seconddeadline,symbolic
readFD3,one canonicalUTF8JSON envelope thenEOF,ASCII-escaped sorted compact version-
bound form with no trailing bytes. These are original symbolic limits,not verified
native pipe capacity,timer/signal effectiveness or an actual descriptor binding.
The draft does not implement canonicalization/cryptography or run a pipe experiment.
Timeout,unknownEOF,invalid/lost receipt and optional lostACK preserve the already
consumed grant/slot and original evidence. No reread,rebinding,new launch or fresh
admission is inferred. Authentication does not exempt boot/expiry/revocation fences.

## Failure-cut design table

All ten complete original320 failure cases are carried,including their original
modeled consumption/invocation/quarantine/pending flags. A separate proposed review
decision links each to required native observations. No original modeled flag is
rewritten into actual consumption or spawned/no-child evidence:all actual fields
are null,native proof/run false. This is a review matrix,not an executable state
machine or an independently verified crash schedule.

| Original case | Required disposition to prove later |
| --- | --- |
| Unauthenticated request | No victim burn or worker dispatch; independent negative authentication/no-write evidence. |
| Authenticated binding mismatch | Known authenticated grant consumed before mismatch; no worker dispatch or unused reset. |
| Claim durability unknown | Consumption null/unknown,no spawn,no-reuse quarantine/controller obligations pending. |
| Committed claim ACK lost | Known consumption retained,no new admission/launch from lostACK,quarantine pending. |
| Launch spend durability unknown | Grant burned,no spawn/retry from unknown slot state. |
| Slot spent,crash before spawn | Slot stays spent even when no spawn known;restart never launches again. |
| Spawn outcome unknown | Possible machine/child effects and controller obligations pending;no absence/closure or retry claim. |
| Worker preflight failed | Grant remains burned,original failure retained,stage0 no owned writes;actual later state still independently observed. |
| Worker stage0 passed | Bootstrap success proves no fresh baseline,target,storage or additional authority. |
| Worker stage1 traps armed | Traps are not writer exclusion,baseline capture or durable storage proof. |

Eight additional authored fault-design questions require independent controls for
forged/unknown victim identity,concurrent claim winner/losers,malformed/duplicate
envelope,bootstrap-writer/FD leaks,lostEOF/timeout/signal,descendant-held channels,
stale/wrong-boot/revoked context and service log/storage commit loss. These do not
extend,run,replace or tick the52 original native cases. At376 map actual micro-event
cuts to every original full proof/case row; at375 review origin/expected-vector and
positive/negative injection effectiveness before any later explicit native authority.

## FD isolation,supervision and unresolved feasibility

Carry full original321 FD policy,including exact reviewed roles/object kinds/origins/
aliases/lifetimes for required stdin/stdout/stderr streams;numeric standardFD3,
mode/name/namespace labels and close-on-exec alone prove no safety. Denied bootstrap
writer/input,admissionSocket/RPC,ledger/trustkey,hostDirectory,pid/namespaceHandle and
unknown/aliased resources must not reach any backend via FD,mount,path,network,cwd,
environment or process handles. Retained code is allowed only under separately
reviewed read-only provenance/alias/interpreter consumption/close phases;no unreviewed
helper inherits retained code or bootstrap. No actual FD inventory is invented.

Every original descendant and stream must have exact native origin/status/identity/
lifetime and bounded supervision,including parent crash,logging and rollback
backend launches. Parent exit,one PID/status,flags or stdout does not prove whole
drain. Unknown closure stays pending; no cleanup signal or implicit fresh launch
is authorized by this design. Full live forward/recovery/publication fences,finite
original budgets and original baseline/approved deltas remain required across loss.
Guard loss and uncertain claim/spend/spawn/ownedcommit/target/publication/handoff
cannot authorize reset,replay,reacquire,rebind,deadline renewal or uncertain republish.

Two distinct platform readiness rows keep every service,storage,key/verifier/parser,
launch,bootstrap,timer,FD/descendant,freshauthority and independent evidence input
null for Slackware15.0/current. Generic primitive names do not prove support or
properties. All twelve original320/321 future proof obligations and their complete
cross obligations remain normative/pending. At372 compare concrete candidate
mechanisms per platform and record blockers/alternatives if original guarantees
cannot be met. A design question is never a feasible implementation or permission.

## Verification and continuation

Pure reviewer imports onlyhashlib/json/re and validates supplied JSON/sourcebytes;
no filesystem/native lookup,service/crypto/ledger/storage/pipe/clock/process/network
operation or command dispatcher. Private harness loads trusted fixtures/reviewer,
checks exact whole320/321 contracts and field/bootstrap/FD/lifecycle/failurecut/proof
views,all source/input/predecessor bindings,native nulls,hostile mutations and report
detachment. Offline PASS is review validation,not authentication,durability,launch,
FD,quarantine or nativeconformance proof. No actual runner or C development.

All1896 accepted370files exact except additiveCHANGELOG;README stays exact pending377.
Full370roles/interfaces,369plan,original source/context/dependency/effect/prerequisite/
freeze/pause/gap/control inputs bound. Full8contracts320–327,16normative347sections,
16gaps,46proofs,52two-platformcases,12rawgroups and1072proofcaseedges still normative
pending;primary371threegap assignments do not restrict them. Actualhostunobserved-
not-claimed-absent,livebindingsnull,globalhostclosurefalse. Runtime/native grant and
machine/controller actions absent;Phase1/kernelincomplete,reference-v1/v1schema/C/
Phase2/Productionclosed. Historical361socketEPERM/modeled/injecteddrift and370private
workspace/symlinkcontrol limitations retained,never promoted to native fault evidence.

371prepared untilcompleteuseroverlay/tests/exactcommit/push/cleanmatchingheads;372
waits for acceptance. Finite372–378 roadmap unchanged,README377,conditional scoped
pause378,noautomatic379. Latercurrentrefresh doesnotinvalidate repositorywork or
allowhistorybinding/consumedgrant reuse. Lastconfirmedscopedpause368;371notnewpause.
