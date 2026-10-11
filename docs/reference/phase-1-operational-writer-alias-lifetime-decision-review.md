# Phase 1 step381: all-writer exclusion and object lifetimes

380 accepted at reported7820d1a:157 exact ordered PASS/zero failures, nine files,
3133 insertions/eight creates, exact message and successful b50554c..7820d1a push,
reported clean matching HEAD/origin. Complete uploaded UTF8 return14032bytes,
SHA256 ab434fdfa570b5cc5837a7a7b196a2f864c0b5740733dc858957f04f46ae6f79,
no normalization. Full commit unknown; no independent terminal/GitHub/native inspection.

## Original exclusion and lifetime question

The dossier retains whole original324 guard, baseline and interstage contracts,
all seven original writer-map rows, the whole372 writer blocker and377 conflict.
The whole324 document and every original320–327 contract remain normative via the
whole378 freeze. Primary focus is not a waiver of any other original requirement.
Before fresh original capture, every overlapping writer must follow an independently
established common compatible protocol or be prevented through proven controlled
entrypoints/enforcement. Unknown or nonparticipating writers block admission.

Actual guard object/API/range, open description, FD aliases, ancestors and mount
identities must remain protected through every real consumption, mutation, recovery,
restoration and target evidence. A distinct supervisor-owned guard is not reference
FD9 and must not leak an alias that a child can unlock. Owner exit is not child
quiescence. Exclusion must survive loss or independent prevention must stop every
surviving write; otherwise stop and pending. No force unlock, unlink/recreate,
reacquisition or rebinding. Known child/effect quiescence, exact original restoration,
full invariants and target evidence precede known guard release; no target writes
afterward. All recovery/evidence/publication effects keep their own original finite
live rights and prerequisites; this review grants none.

## Bounded candidate decisions

| Candidate as stated | Decision and unsatisfied obligation |
| --- | --- |
| advisory-with-unproven-participation | incompatible-as-stated: A writer with suitable permission can ignore the advisory protocol. A static inventory does not prove continuing universal participation. |
| supervisor-private-handle-only | incompatible-as-stated: When the sole open description loses its last reference, the guard can release while already admitted children still write. Protecting against child unlock does not settle owner loss. |
| pathname-lock-recreation | incompatible-as-stated: The old held object and the replacement object can differ; a second name-based acquisition does not restore the original lifetime and explicitly violates original no-reacquire/rebind requirements. |
| private-mount-shared-backing-only | incompatible-as-stated: Changing mount-list visibility and propagation does not deny writes through host aliases of the same writable backing objects. |
| pinned-lookup-and-hash-only | incompatible-as-stated: An overlapping writer may change the held object bytes or a later reopened path may resolve to another object. The candidate supplies neither writer exclusion nor checked-to-used identity continuity. |
| complete-cooperative-protocol-hypothesis | unresolved: No complete actual writer inventory, protocol/API/filesystem compatibility, enforcement of cooperation, privileged trust assumptions or independent lifetime evidence is selected. |
| complete-enforced-writer-policy-hypothesis | unresolved: No exact policy, enforcement boundary, kernel/administrator/device trust, alias topology, owner-loss behavior or two-platform native evidence is selected. |

Five incomplete compositions are incompatible as stated; two complete hypotheses
remain unresolved. No primitive is rejected in every possible composition, no
universal impossibility is proved and no actual native policy/guard is selected.
Both hypotheses need complete independent writer/lifetime evidence and compatibility
with every original privileged-writer obligation. A new trust assumption cannot erase
administrator, device, backing-storage or alias routes. Actual administrator/kernel/
device/storage/virtualization trust and original compatibility verdict remain null.

## Conditional schedules

- nonparticipant-write: known-wrapper-acquires-guard → uncoordinated-writer-ignores-protocol → overlapping-target-write. Assumes an advisory local guard and another writer with write permission; excludes no privileged/manual/scheduled writer by fiat.
- incompatible-lock-APIs: writer-A-uses-native-flock → writer-B-uses-noninteracting-fcntl → both-proceed. Conditional on the actual native Linux local-filesystem APIs not interacting; NFS/SMB emulation differs and is not assumed equivalent.
- leaked-guard-alias: supervisor-acquires-guard → guard-open-description-alias-leaks → alias-holder-unlocks → child-effect-continues. A dup/fork alias to the same flock description can unlock it. This conditional violates the candidate private-handle assumption and shows why that assumption itself requires independent evidence.
- owner-last-close: supervisor-only-guard-reference → child-without-guard-alias-remains-active → supervisor-dies-and-last-reference-closes → child-write. Conditional on the sole guard description closing and absent independent prevention. Parent death alone is not known child/effect drain; the child is not assumed to inherit the guard.
- split-lock-object: guard-object-A-held → lock-name-unlinked-and-recreated-as-B → second-writer-locks-B → both-effect-windows-overlap. Assumes allowed name replacement and compatible access. Neither stale name removal nor another acquisition establishes original continuous exclusion.
- shared-host-alias: worker-private-mount-view → host-retains-writable-shared-object-alias → host-write → worker-consumes-changed-bytes. Assumes shared backing storage and an uncontrolled authorized host writer; namespace view/propagation alone prevents neither that writer nor its alias.
- held-object-byte-drift: restricted-open-and-hash → other-writable-alias-modifies-same-object → held-read-FD-consumes-new-bytes. Conditional on mutable shared object bytes; a held read descriptor pins a reference but the candidate provides no independent content protection.
- checked-to-reopened-replacement: checked-object-A → uncontrolled-ancestor-or-name-replacement → consumer-reopens-name-as-B. Applies to later path reopening, not a claim that an existing FD is retargeted by rename. Every interpreter/loader/helper/archive consumer needs its actual identity bound.
- early-baseline-capture: stage0-preflight-capture → overlapping-writer-delta → outer-guard-acquired → stale-capture-proposed-as-original. Reject early preflight as original capture. Original stage1 traps then guard then fresh revalidation/in-memory original capture precede any stage2 owned writes.
- guard-released-before-target-evidence: children-or-inflight-state-unknown → guard-release → target-evidence-write-proposed. Known child/effect quiescence, exact restoration, full invariants and target evidence are required before known release; no target write after release.
- privileged-policy-bypass: policy-covers-worker-paths → unreviewed-privileged-or-device-route → overlapping-object-effect. Conditional on an available uncontrolled privileged/device route. Explicit trust assumptions cannot silently exclude any original writer/alias obligation.
- unknown-recovery-guard: owner-loss → original-guard-validity-unknown → recovery-or-publication-effect-proposed. Unknown remains pending; no force unlock/recreate/reacquire/rebind, foreign restoration or new grant. Recovery/publication need separately retained original finite live scopes and known prerequisites.

These are declarative schedules with explicit conditions, not executed native tests,
observed faults, selected injection points or exhaustive concurrency coverage. A
leaked guard alias violates the private-handle hypothesis; the owner-last-close case
instead assumes no such child alias. A rename does not retarget an existing FD:
same-object byte mutation and later path reopening are separate questions.

## Primary semantics and project inferences

The upstream [flock source](https://kernel.googlesource.com/pub/scm/docs/man-pages/man-pages/+/refs/heads/master/man/man2/flock.2)
binds native Linux locks to open descriptions: dup/fork aliases can unlock and last
close releases. Advisory cooperation differs from enforcement; network-filesystem
emulation and API interaction depend on actual configuration. Our inference is that
neither a protected descriptor nor a lock name alone proves whole writer coverage.
No uniform advisory semantics for every filesystem or flock/fcntl interaction is
asserted. Both current master and tagged upstream source pages were opened.

The tagged upstream [openat2 source](https://kernel.googlesource.com/pub/scm/docs/man-pages/man-pages/+/refs/tags/man-pages-6.12/man/man2/openat2.2)
documents restrictions on one lookup, including beneath-dirfd resolution and rejecting
mount crossings. Our inference is that lookup safety does not freeze consumed bytes
or prove a later interpreter/backend reopening consumes the checked object. Current
indexed excerpts were also retrieved; new flags are not selected or claimed absent.

The tagged upstream [mount namespace source](https://kernel.googlesource.com/pub/scm/docs/man-pages/man-pages/+/refs/tags/man-pages-6.12/man/man7/mount_namespaces.7)
and kernel [shared subtrees documentation](https://docs.kernel.org/filesystems/sharedsubtree.html)
describe mount views and propagation. Our inference is that private propagation alone
does not deny writes through an authorized host alias of shared backing storage.
Rendered manual direct opens failed; upstream source/kernel pages succeeded. The
register records focused semantics and retrieval limits, not original HTML/source
byte capture or installed-platform conformance. No actual Slackware probing occurred.

## Original resource map and independent platform unknowns

| Original domain | Required resource scope | Original writer examples |
| --- | --- | --- |
| package-database | /var/lib/pkgtools/packages;/var/log/packages | direct-pkgtools;Slackpkg;wrappers;manual-package-writes |
| Slackpkg-state | /var/lib/slackpkg;derived-TEMP-WORKDIR | refresh;check-updates;apply;scheduled-wrapper;state-cleanup |
| configuration-and-mirrors | /etc/slackpkg/mirrors;/etc/slackpkg/slackpkg.conf;derived-config | package-config-scripts;manual-editor;restore;configuration-manager |
| boot-and-GenInitrd | /boot;/etc/default/geninitrd | kernel-package-scripts;boot-tools;GenInitrd;manual-config;restore |
| source-and-archives | fresh-local-source-tree;manifest;target;predecessor;baseline-archives | builder;staging;cleanup;package-source-edit |
| backend-and-dependencies | approved-launcher-interpreter-backend-and-all-runtime-dependencies | platform-updater;package-replacement;manual-payload-edit |
| transaction-owned-state | owned-work-backup-binding-evidence-and-restore-paths | owned-supervisor;owned-adapters;owned-children;foreign-overlap |

These are the unchanged original required rows, not an observed exhaustive writer
inventory or a newly chosen target list. Their TSV path/hash is bound byte-exact.
Fourteen separate domain/platform rows retain actual inventories, object/ancestor/
mount aliases, guard API/filesystem semantics, owner-loss protocol and independent
evidence null. Distribution labels, historical fixtures or upstream docs discharge
none of these rows. The original full effect graph, publication/source/owned writers
and all privileged aliases remain required beyond these seven domain examples.

Stage0 preflight is not original baseline capture. Stage1 traps precede the outer
guard and fresh revalidation/in-memory capture, before stage2 owned writes; stage3
persists/verifies exact original backups before predecessor config/package writes.
No capture of current drift as new original, broad owned-subtree exclusion or foreign
restoration. Whole original baseline storage/durability and rights remain for383;
381 neither resolves nor narrows them.380 live revocation decisions remain whole.

## Evidence and next boundary

Eight independent criteria and six native boundary questions remain unresolved.
Complete378 freeze/all21 inherited inputs/whole379 plan/accepted380 dossier and source
register bind through25 byte+canonical inputs; four inert roots stay byte-exact and
unexecuted. Full eight contracts/16sections/16gaps/46proofs/52nativecases/12rawgroups/
1072ordered relations/all365 prerequisites/all372 blockers/all377 conflicts remain
normative. Whole stage12 is retained; the final receipt cannot observe its own final
hash/commit/durability. No shortening, renaming or resolution of that protocol.

Pure reviewer takes supplied bytes/data only, imports hashlib/json/re and has no
filesystem, clock, network, spawn, service or native dispatch. Harness checks all1969
accepted files except additive CHANGELOG, exact eight new Git-visible artifacts,
complete predecessor receipt and hostile mutations. Tracked ignored names remain
bound; local ignored outputs are preserved without any native absence inference.
Private Git delivery tests use a disclosed expected-prefix shim only, all other Git
operations real/local; no private push or independent user/GitHub/native acceptance.
README exact; actual host unobserved-not-claimed-absent/live bindings null/global
closure false/native proofs0/cases0. Phase1/kernel incomplete; v1schema/reference-v1/
C/Phase2/Production closed. Separate reviewed safe containment and a fresh explicit
bounded grant precede any future native experiment; passing that test cannot be its
own authorization prerequisite. Native composition remains BLOCKED.

381 prepared until complete user install/tests/exact commit/push/clean matching heads;
only then382 supervisor death, children, in-flight clock and drain review. Last
confirmed scoped pause378; conditional388 requires complete final receipt and all
nine original conditions then STOP/no automatic389. No new safe pause is claimed.
