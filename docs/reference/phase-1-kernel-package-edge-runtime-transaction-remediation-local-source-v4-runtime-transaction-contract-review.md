# Phase 1 step300 — transaction and restoration contract review

Consume confirmed299-r1, commit prefix435df6b, complete119 PASS, user application,
commit/push and empty short status. Preserve exact1282 accepted bytes and CHANGELOG
tail, original returned message as reversible UTF-8 JSON and its SHA/byte count.
Confirmation supersedes prepared299 wording without changing accepted artifacts.
No full commit ID or independent host/GitHub observation is invented. Historical
step298 pause stays valid; the reopened workstream is not a new strong pause.

## Future stage order and effects

| Index | Stage | Effect | Required guard |
| --- | --- | --- | --- |
| 0 | immediate-preflight | read-only | new grant, fresh target/source/artifact/predecessor binding and same grant boot; safe absent owned paths |
| 1 | arm-idempotent-traps | process-only | EXIT/HUP/INT/TERM cleanup registered before first filesystem mutation |
| 2 | initialize-owned-workspace | owned-files | create exclusive owned evidence/temp roots; record partial construction on failure |
| 3 | capture-verify-backups | owned-files | capture exact production baseline bytes, modes and owner before package/config writes |
| 4 | stage-exact-predecessor | package-state | use separately validated exact predecessor artifact; no unrelated package action |
| 5 | isolate-local-configuration | configuration-state | use reviewed local v4 URI and isolated state; forbid external network during refresh/apply |
| 6 | refresh-new-pkglist | owned-state | absent-before/fresh-regular-nonempty-after; exit0 plus both-stream download-error guard |
| 7 | bind-exact-candidate | read-only | one exact eight-field target row; same-transaction source/pkglist/archive hashes before apply |
| 8 | reference-apply | package-state | only reviewed exact payload, after target-only binding; no boot or unrelated candidates |
| 9 | restore-production-baseline | restoration | restore target baseline header, config/mirrors/state and owned temporary changes |
| 10 | verify-restoration-invariants | read-only | verify header names/content, unrelated package records, config/state/GenInitrd/boot and preserved inputs |
| 11 | capture-complete-evidence | owned-files | per-stage stdout/stderr/exit, original failure/signal and cleanup outcomes; preserve failure evidence |
| 12 | publish-reviewed-result | owned-files | success only after all guards/restoration/evidence; failure/none never success |

This is a future requirements contract, not an execution plan/grant. New design/
implementation review/freeze and fresh target/source/artifact/predecessor validation
precede any new single-attempt authorization. Immediate preflight and that grant's
uninterrupted boot must hold. Old UUID/grants/pkglist/v2 executor are design history
only. Keep frozen v4 identities, owner/modes, untagged checksums, non-authenticating
marker and exact eight-field candidate gate unchanged. Exit0 alone never proves
refresh; reject the human-spaced error signal in both stdout and stderr. No external
network during refresh/apply. Same-transaction source/pkglist/archive SHA binding
must precede reference apply and reject all unrelated candidates.

Traps precede the first filesystem mutation, including exclusive workspace creation.
Backups of original bytes/owner/modes must be verified before package/config writes.
Failure while creating workspace or backups may leave owned partial state, but may
not use unverified backups to modify production state. Later design must map each
logical category to exact safe paths, payload identities and restore/verify commands.
Unresolved executor/payload/config/work-root/grant/boot/availability slots are null;
no default or old value may satisfy a later operational gate.

## Restoration, failure and publication

Restore baseline kernel-headers6.18.45 with its exact accepted target SHA, including
verified header names/content; preserve unrelated package-record bytes. Verify
config/mirrors bytes/owner/modes, Slackpkg state, GenInitrd, boot, v4/v3/target/failed-v2
evidence and owned temporary-state restoration. Baselines for future use require
fresh validation; current preservation/availability is not observed here.

Cleanup must be idempotent, owned-only and never remove preserved source/evidence.
Keep the original failure/signal exit code; record cleanup failures separately.
Failed restoration leaves pending machine obligations. Missing complete evidence
leaves pending controller obligations. Even a restored failed attempt publishes
failure evidence only, consumes its single-use grant and does not permit retry.
Success requires all stages exit0, verified restoration and complete per-stage
stdout/stderr/exit plus cleanup evidence before publication. Failure of publication
requires separate review. No preflight-only success or automatic strong pause.

EXIT/HUP/INT/TERM are the catchable trap design boundary. SIGKILL, crash and power
loss cannot guarantee trap completion or atomic restoration; preserve evidence,
keep unobserved stage/cleanup exit statuses null, stop and require separate
result/effect review and recovery planning. No atime,
audit or continuous host-state immutability claim. This contract does not prove
real signal delivery, rollback commands or package/configuration behavior.

## Repository acceptance and next boundary

Rerun full119 accepted299 acceptance in an exact bound temporary snapshot; never
patch historical files or constants. The new pure trace oracle validates abstract
stage prefix/order, traps/backups/candidate gates, failure/interruption status,
cleanup obligations and conditional publication. It composes the exact pure
candidate oracle from accepted296 by AST, without executing its top level.
Synthetic fixtures are contract evidence only; no production executor is created,
sourced or run and no VM/Slackpkg/reference apply occurs. No live pkglist or
restoration proof is claimed.

Only repository contract freeze301 opens after user300 acceptance. Later design,
implementation, transport, live observation, runtime and Phase2 authority remain
closed. Preserve299–308 route and optional309–310 failure closure. Prepared300
requires user application/full tests/commit/push/clean tree; no machine/controller
action and pause_safe/strong_safe_pause false. Phase1/kernel-package-edge incomplete.
