# Phase 1 step302 — v4 runtime executor design review

Confirmed301:7226226 (prefix only), full152 PASS, overlay/commit/push and empty short
status by complete user return; no independent host/GitHub inspection. Preserve1296
accepted artifacts and exact CHANGELOG tail. Contract300 and freeze301 remain exact.
This design is reviewed only, not frozen, implemented, transported or executable.

## Stage mapping

| Index | Stage | Function seam | Effect |
| --- | --- | --- | --- |
| 0 | immediate-preflight | verify_immediate_preflight | read-only |
| 1 | arm-idempotent-traps | arm_cleanup_traps | process-only |
| 2 | initialize-owned-workspace | create_owned_workspace | owned-files |
| 3 | capture-verify-backups | capture_and_verify_baseline | owned-files |
| 4 | stage-exact-predecessor | stage_exact_predecessor | package-state |
| 5 | isolate-local-configuration | configure_local_isolation | configuration-state |
| 6 | refresh-new-pkglist | refresh_and_validate_pkglist | owned-state |
| 7 | bind-exact-candidate | bind_exact_candidate | read-only |
| 8 | reference-apply | run_guarded_reference | package-state |
| 9 | restore-production-baseline | restore_baseline | restoration |
| 10 | verify-restoration-invariants | verify_restoration | read-only |
| 11 | capture-complete-evidence | finalize_stage_evidence | owned-files |
| 12 | publish-reviewed-result | publish_evidence_and_receipt | owned-files |

Every stage maps to a guard, operation, stdout/stderr/status files, failure boundary
and implementation test seams in the design JSON. Preflight/trap-registration
streams are buffered in bounded process memory before first filesystem mutation;
overflow fails closed without complete-evidence claims. Register traps before mkdir
or filesystem locks. Set owned-root-created immediately after exclusive creation.
Capture and compare backup bytes/owner/modes and original fingerprints before any
production write. Partial construction is owned, preserved and reviewed on failure.

## Paths, payloads and nested calls

Symbolic attempt-token paths share one exclusive0700 transaction root under the
kernel-package-edge parent; work/cache/log/private-reference-lock/payload/backup and
evidence roles are distinct. Token is a future new-grant value, never an old boot.
Actual roots, backend identities, grant/boot and platform serialization lock bindings
remain null. Existing ancestors require canonical no-symlink checks; all final and
temporary publication destinations must be absent. A private reference lock cannot
prove exclusion of other package/config writers. Later grant/platform lock review
must exclude concurrent writers before production mutation; no current lock proof.

Bind exact immutable repository reference and source config SHA, checked against
historical v2 embedded bytes by static decoding only. Never source/run v2. Derived
config is parsed as data, has exact unique overrides and disables optional modules;
production Slackpkg config temporarily uses exact v4 file URI, owned WORKDIR/TEMP,
CHECKGPG=off, then restores original metadata. No source edits or v3 tagged parser.

The reference performs its own update/install-new/upgrade-all calls. A new guarded
Slackpkg adapter is therefore part of the design: exact argv allowlist, direct
reviewed real-backend resolution (no recursive PATH), namespace inherited throughout,
new-grant boot/source/archive/pkglist recheck before every nested action. Internal
update exit0 is insufficient: both-stream error guard, exact fresh regular pkglist
and unchanged binding hash are rechecked after it. Drift stops before package action.
install-new has zero candidates; upgrade-all has one exact target and verified
predecessor. Nested command streams/exits are separate evidence. This pure design
admission oracle does not prove the actual production selector or adapter behavior.

## Cleanup, evidence and publication

Track owned child groups, forward signals only to them, wait for child quiescence
and drain streams before recording a known exit or starting restore. A child that
remains active leaves machine obligations pending; never race rollback against it.
Dispatcher states unarmed/armed/running/completed/failed latch original error or
signal before disabling recursive traps. Separate cleanup status never replaces
original failure. Catchable HUP129/INT130/TERM143; unknown KILL/crash/power-loss exits
stay null. Repeated verified cleanup is a no-op. Unverified backups, changed boot or
unsafe restore keep machine obligations pending instead of forcing mutation.
Restore whitelisted canonical entries only: target header bytes/names, config/mirror
metadata, state manifest, GenInitrd presence, then owned mutable work/cache/lock.
No blind recursive removal of production Slackpkg state or accepted history. Keep
backups/evidence for review/recovery; success flag only after every baseline match.

Publication uses exclusive archive/sidecar creation without overwrite. The archive
contains stages0–11, cleanup and publication preparation; last-stage stdout/stderr/
exit are in a separately completed external publication receipt committed last.
Do not claim a self-containing archive or atomic archive/sidecar pair. Missing
archive, sidecar or final receipt means pending controller obligation and no success.
Restored failed attempts retain failure evidence and consumed authority, never retry.

## Acceptance and next gate

Full152 predecessor acceptance reruns in an exact bound historical snapshot, keeping
constants/inputs unchanged. New pure tests validate path derivation, nested command
admission, design identity/type/authority and guarded publication. No production
executor, adapter or host package/network command is created or run. Implementation
must later test injected private-temp backends, real catchable signal delivery,
mid-stage/cleanup failures, original status, repeated cleanup and partial publication.
Current tests are not those future runtime/implementation proofs.

After user302 checkpoint, only repository design freeze303. Implementation/live/
transport/runtime/Phase2 closed. Route299–308/reserve309–310 retained. No machine/
controller action, new pause or current boot/pkglist/predecessor-availability claim.
Historical298 pause remains valid; Phase1/kernel-package-edge remain incomplete.
