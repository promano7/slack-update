# Phase 1 step 372: native platform primitive feasibility design

371 accepted at reported e6d341f: 151 exact ordered PASS, zero failures, exact
8-file/4114-insertion/seven-addition commit, successful607d43c..e6d341f main push,
reported clean matching HEAD/origin. Full commit ID remains unknown. The complete
uploaded return is preserved unchanged; this is user-reported acceptance, not
independent terminal/checkout/GitHub/native inspection. Historical371 artifacts
remain immutable; external confirmation supersedes their prepared-state interpretation.

Complete uploaded371 return: 11007 UTF8 bytes, SHA256 fef789295e2ad9d8bb2d2f035e009c4879a61610a1e659a39257417c01868b29, no normalization.

## Result and scope

Native readiness remains BLOCKED. Ten candidate mechanism families are compared
through twenty distinct platform assessments and fourteen writer-domain records.
No mechanism, component, service, syscall flag, kernel version, filesystem, clock,
writer guard, backend, cryptographic verifier or test authority is selected or
observed on either Slackware15.0 or Slackware-current. Generic upstream semantics
are useful design constraints, not evidence of installed support or full guarantees.
Architecture blockers remain for live external revocation at every effect boundary
and continuous exclusion of all writers/aliases, including privileged/manual writers
and supervisor loss with surviving descendants. No requirement is relaxed to make
a candidate appear feasible. Primary assignments retain three whole original gaps;
all original contracts320–327 and full347/348 requirements remain normative.

## Compared candidates and their unresolved guarantees

| Family | Candidate composition | Decision and required distinction |
| --- | --- | --- |
| bounded-offline-bootstrap | Anonymous one-way bootstrap with one memory-only framing reader, producer closure and original hard byte/deadline limits. | blocked-until-bounded-reader-closure-and-authentication-refinement. A byte stream or successful write is not a complete canonical authenticated envelope/EOF. Pipe capacity is not the65536byte application limit; no write-all-before-reader assumption. Retained/duplicated writers can delay EOF. |
| descriptor-capability-closure | Reviewed FD allowlist plus close_range/UNSHARE or an independently race-safe closure design before every child. | blocked-until-complete-object-inventory-and-close-phase-proof. CLOEXEC is delayed until exec and numeric ranges do not identify object origin,alias,peer or lifetime. Immediate closure also needs code/interpreter/stdstream exceptions under the original policy. |
| namespace-and-syscall-containment | Separate reviewed mount/network/PID/capability boundaries with syscall policy, exact private paths and no worker broker reachability. | blocked-until-full-reachability-and-backend-compatibility-proof. Namespaces and seccomp isolate different surfaces. Neither their names nor a syscall allowlist prove all FD/path/cwd/env/process/alias routes or prevent external privileged writers. |
| whole-descendant-supervision | Supervisor-owned non-worker-mutable cgroup lifecycle plus origin-bound process descriptors/status streams and protected membership. | blocked-until-origin-membership-and-known-inflight-drain-proof. A pidfd tracks one process. Empty/populated/frozen/kill or one exit status alone is not full effect,FD,storage or stream closure; migration,spawn races,supervisor loss and uninterruptible activity need explicit handling. |
| trusted-finite-time | External trusted clock mapping and absolute original phase deadlines using a separately evaluated suspend-aware clock/timer composition. | blocked-until-trusted-clock-mapping-and-loss-policy-proof. A local timer or BOOTTIME value supplies no issuer provenance,original boot mapping,VM rollback/clock-namespace trust,revocation serialization or durable recovery budget. |
| external-live-revocation | Proposed external native authority gate controls every original phase effect boundary while the worker receives only the original offline bootstrap. | architecture-blocked-no-reviewed-whole-effect-revocation-mechanism. No cited generic mechanism establishes this composition. A signed offline receipt,finite lease,periodic polling,kill-on-expiry or seccomp name cannot establish atomic revocation versus every new/in-flight package/config effect. |
| writer-object-alias-exclusion | Compare supervisor-owned advisory coordination under proven universal cooperation with controlled-entrypoint prevention or independently enforced writer policy. | architecture-blocked-no-complete-privileged-writer-and-owner-loss-coverage. Advisory flock alone is insufficient for manual/scheduled/privileged nonparticipants. A protected supervisor FD avoids child-unlock only if no aliases leak; owner death can release it while children still write. Private mounts do not exclude host writers to shared backing objects. |
| canonical-resolution-and-consumption | Pinned reviewed directory/object handles with explicit resolution restrictions for each actual consumer and mutation. | blocked-until-consumed-byte-and-lifetime-writer-proof. Resolution flags constrain one lookup; a retained read FD/hash does not freeze bytes against aliases or writers and cannot prove a later shell/interpreter/library/archive path consumes those exact bytes. |
| owned-storage-and-no-replace | Candidate exclusive staging plus no-replace namespace commit and separately reviewed file/metadata/directory/storage ordering; service ledger requires its own linearizable transaction protocol. | blocked-until-separate-native-storage-and-transaction-refinement. No-replace is not persistence or grant CAS. File and directory durability are separate; supported syscall/filesystem labels or exit0 do not establish the entire device/cache/VM persistence chain. Archive/checksum commits remain separate. |
| checked-code-and-backend-graph | Exact future source/interpreter/loader/helper/pkgtools/config/archive graph with protected bytes and a narrow backend-compatible entry. | blocked-until-full-source-selection-and-independent-native-equivalence. A syscall primitive cannot prove pkgtools selectors,hooks,raw statuses,sticky failure or boot/GenInitrd/optional-effect exclusions. Original363 dependency names/126slots and364 source anchors remain unresolved requirements. |

The machine-readable design gives each family exact original qualified obligations,
required future native evidence and a specific alternative review without contract
relaxation. Each family has its own Slackware15.0 and Slackware-current row with
unbound API/configuration, component bytes, aliases/writers/lifetimes, independent
positive/negative observations and cross-contract refinement. No row can borrow
another platform's support or evidence. Distribution labels and historical observed
kernels/build artifacts do not bind the current installed versions. New current
refresh requires fresh future native bindings; repository design work remains valid.

## Upstream sources and limits

The following primary documentation was checked on2026-10-11UTC. Summaries below
are upstream observations; limitations in the candidate table are design inferences
against the full original contracts. Search-rendered manual excerpts are disclosed
where direct page opens timed out. No complete original webpage byte capture or
native platform inspection is claimed. Documentation versions/URLs may change;
a later native selection must bind the supported implementation and actual source.

- [Linux man-pages pipe(7)](https://www.man7.org/linux/man-pages/man7/pipe.7.html) (`pipe`): Pipes provide byte streams, not application message framing. Retrieval: Indexed primary manual excerpt; direct open timed out.
- [Michael Kerrisk Linux System Programming Fundamentals](https://man7.org/training/download/Linux_System_Programming-man7.org-mkerrisk-NDC-TechTown-2020.pdf) (`pipe-closure`): EOF requires all writer descriptors closed; reader or writer blockage can persist when opposite ends remain open. Retrieval: Primary author training PDF search excerpt; no whole PDF capture claimed.
- [Linux man-pages close_range(2)](https://www.man7.org/linux/man-pages/man2/close_range.2.html) (`close-range`): Linux5.9/glibc2.34 interface closes ranges; UNSHARE addresses shared-table races; CLOEXEC fromLinux5.11 marks for exec rather than immediate closure. Individual close errors are ignored. Retrieval: Indexed primary full manual returned; no original HTML byte capture claimed.
- [Linux man-pages namespaces(7)](https://man7.org/linux/man-pages/man7/namespaces.7.html) (`namespaces`): Each namespace abstracts particular global resources. Retrieval: Indexed primary manual excerpt; direct open timed out.
- [Linux kernel Seccomp BPF documentation](https://docs.kernel.org/userspace-api/seccomp_filter.html) (`seccomp`): Filters inspect syscall numbers and argument values without dereferencing pointers; filtering alone is not a sandbox. Architecture checks matter; inherited child filters do not constitute full information-flow policy. Retrieval: Primary documentation opened successfully; no original HTML byte capture claimed.
- [Linux kernel Control Group v2 documentation](https://docs.kernel.org/admin-guide/cgroup-v2.html) (`cgroup`): Fork inherits current cgroup membership; processes can migrate. Freezing is asynchronous and status is reported in cgroup.events. cgroup.kill targets the descendant tree with SIGKILL. Retrieval: Primary documentation opened successfully; no original HTML byte capture claimed.
- [Linux man-pages pidfd_open(2)](https://www.man7.org/linux/man-pages/man2/pidfd_open.2.html) (`pidfd`): A PID descriptor can be polled for the referenced process exit. Retrieval: Indexed primary manual excerpt; direct open timed out.
- [Linux man-pages timerfd_create(2)](https://man7.org/linux/man-pages/man2/timerfd_create.2.html) (`timerfd`): CLOCK_BOOTTIME timerfd support fromLinux3.15 includes suspend time; CLOCK_MONOTONIC excludes it. CLOCK_REALTIME is affected by discontinuous clock changes. Retrieval: Indexed primary manual excerpt; direct open timed out.
- [Linux man-pages flock(2)](https://man7.org/linux/man-pages/man2/flock.2.html) (`flock`): Local advisory flock can be ignored by a writer with access. Duplicates share the open-file-description lock and can unlock it; final closure releases it. Remote filesystem semantics differ. Retrieval: Indexed primary manual excerpt; direct open timed out.
- [Linux man-pages openat2(2)](https://man7.org/linux/man-pages/man2/openat2.2.html) (`openat2`): Linux5.6 resolution flags can reject beneath-root escapes, magic links and mount crossings. Explicit NO_MAGICLINKS avoids reliance on current BENEATH side effects. Retrieval: Indexed primary manual excerpt; direct open timed out.
- [Linux man-pages fsync(2)](https://man7.org/linux/man-pages/man2/fsync.2.html) (`fsync`): File fsync flushes data and metadata but does not by itself persist the containing directory entry; explicit directory fsync is also needed. Errors include EIO and ENOSPC. Retrieval: Indexed primary full manual returned; no original HTML byte capture claimed.
- [Linux man-pages rename(2)](https://man7.org/linux/man-pages/man2/renameat2.2.html) (`rename-no-replace`): RENAME_NOREPLACE rejects an existing destination and requires filesystem support; ext4 support startsLinux3.15, btrfs/tmpfs/cifs3.17, xfs4.0, several others4.9. Retrieval: Indexed primary manual excerpt; direct open timed out.

## Required composition across contracts

Carry whole321 anonymous one-way bootstrap,14 authenticated fields,65536rawbyte and
10second symbolic limits,FD3 symbol,canonical envelope/EOF and complete FD/lifecycle
policy unchanged. Bootstrap authentication and one-shot closure before commands
remain separate from containment. The external320 service has its own handling
before its own writes; durable consumption/launch pre-spend and all failure-cut
unknowns from accepted371 remain immutable. No worker admission RPC/ledger,receipt
bearer dispatch,unknown-consumption inference or restart/relaunch permission.

Carry whole323 split finite forward/recovery/publication rights,clock/fence/recovery/
closure contracts. No local timer,deadline,signature or lease replaces the external
trusted live gate. A gate must serialize original phase action admission against
revocation/expiry,prevent new effects on uncertainty,and account for all admitted
in-flight effects and descendants. Worker/nested commands must retain no service
capability. Enforcing every real backend micro-effect without a worker control
channel is an unresolved architecture requirement. Notification mediation is not
selected or asserted to meet it. Missing gate outcome retains original consumption,
launch slot,budget and possible effects as pending; never renew/rebind/retry.

Carry whole324 guard,interstage fresh-original capture,baseline/approved-delta,
raw-pkglist,all writer domains,recovery/publication contracts. Original seven domains
are package database,Slackpkg state,configuration/mirrors,boot/GenInitrd,source/
archives,backend/dependencies and transaction-owned state. Both platforms have
separate unbound writer/alias/prevention/owner-loss records for each. The whole
writer map must include manual,scheduler,helper,nested,privileged and all aliases.
A process scan or cooperative lock without complete participation cannot close it.
Either prove a common compatible protocol or controlled prevention for every writer;
unknown/nonparticipating writers block admission. No threat assumption is silently
changed to exclude administrator/device access. Any proposed trust boundary must
be stated and reviewed against the original full contract before later selection.

Exclusion starts before fresh original memory capture after worker traps, before
owned effects/backups, and remains continuous through all consumers,restoration,
full target evidence and known release. Stable supervisor-owned handles are not
child-unlockable; owner death must either retain exclusion or independently prevent
surviving writes. Guard loss or replacement is absorbing stop/pending, never force
unlock,unlink/recreate,reacquire or rebind. A private mount or read-only pathname
cannot assert external alias writers are absent. Actual host remains unobserved,
not claimed absent; livebindingsnull,globalhostclosurefalse.

Owned staging,no-replace namespace changes,file/metadata/directory persistence and
linearizable service ledger/budget transactions are separate compositions. A syscall
return/error/ACK does not eliminate uncertain persistence. Full intent/staging/bytes/
metadata/data/commit/directory/exit-evidence cuts remain due at373/374/376. Unknown
claim/spend/commit never refund,replay or allocate another launch; uncertain record,
archive/checksum/final receipt publication remains separate and never republished.
Same original finite recovery rights and independently known children/target state
are required; mechanism names grant no implicit cleanup/restoration rights.

Source/interpreter/loader/library/pkgtools/config/archive identity and every helper
must remain bound through actual consumption. A pinned handle/hash or lookup flag
cannot prove immutable bytes or a shell's later reopen. Exact original363 dependency
families/126slots,364effects/anchors,370roles/interfaces and371admission design remain
whole frozen inputs. No optional/boot/GenInitrd/network/historical main branch is
called or accepted as excluded by its name. Exact selectors,status/effect vectors,
sticky failure,no-op/unexpected behavior still need independent native conformance.

## Verification and continuation

Pure reviewer receives JSON and source bytes,imports onlyhashlib/json/re,and never
probes host features,executes syscalls/crypto/services or dispatches commands. Private
harness binds all1903accepted371 files (CHANGELOG additive only),whole inputs and
README,primary source summaries,ten families,twenty platform rows,fourteen writer
domains,full321/323/324 contracts and three whole primary gap rows. Hostile mutation
controls reject support/authority/native proof promotion,contract relaxation and
cross-platform evidence borrowing. Offline PASS is review-integrity validation.
Full8contracts,16normative sections,16gaps,46proofs,52unrun native cases,12independent
raw groups and1072proof-case edges remain normative and pending. Historical361 and
private370/371delivery limitations remain exact; no symlink/fault/native claims added.

372 is prepared until complete user application,ordered harness,exact commit/push
and reported clean matching heads are accepted. Then373 reviews original baseline,
owned effects and finite recovery;374closure/publication,375independent oracle,
376micro-event/case design,377readiness/future prerequisites without grant plus README,
378freeze and conditional repository-scoped pause after complete receipt then STOP.
Last confirmed scoped strong pause368,not372;noautomatic379. No actual machine or
controller action,native proof/test,C development or runtime grant. Phase1/kernel
incomplete,reference-v1/v1schema/C/Phase2/Production gates remain closed.
