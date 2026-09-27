# Phase 1 kernel-package-edge runtime transaction remediation executor design review

Step 236 consumes the accepted step-235 candidate-binding freeze and defines the repository-only design for a new remediated runtime executor generation. It does not modify the failed executor in place and grants no machine or runtime authority.

## Historical executor boundary

The first executor remains immutable historical evidence. Its body SHA-256 is `47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581`, builder SHA-256 is `348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea`, and standalone executor SHA-256 is `09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300`. Its former runtime authorization is not reusable. The preserved failure remains the evidence for two retired assumptions: a zero Slackpkg refresh exit status was not sufficient when `error-downloading-from-local-source` was also emitted, and the total row count of `pkglist` was not a valid candidate guard.

The remediated implementation must therefore create a separately named body, builder, and standalone payload. The historical files must remain byte-for-byte unchanged.

## Frozen runtime and source inputs

The design remains bound to `vbox-slackcurrent.vbox-slackcurrent.org`, boot ID `fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9`, running kernel `6.18.45`, the frozen package and Slackpkg fingerprints, predecessor `kernel-headers-6.18.44-x86-1`, target `kernel-headers-6.18.45-x86-1`, and staged target SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`.

Only `local-source-v2` may be used by the remediated transaction. Its tree manifest SHA-256 is `e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945`. Before a future refresh the executor must verify the manifest sidecar, exact manifest coverage, priority-tree contract, compatibility `CHECKSUMS.md5.asc`, target SHA-256, and absence of the predecessor archive. The accepted v1 tree and the failed runtime evidence remain preservation-only inputs.

## Slackpkg freshness design

The remediated executor must derive a temporary Slackpkg configuration that keeps `CHECKGPG=off` for the bounded local compatibility source and rewrites Slackpkg `WORKDIR` to a new transaction-owned directory below the new runtime evidence root. The workdir must start empty and its `pkglist` must be absent before refresh. The same temporary configuration also redirects Slackpkg `TEMP` to a transaction-owned cache so the bounded transaction does not use the host package cache as transaction evidence.

The pre-existing `/var/lib/slackpkg/pkglist` is never evidence of the new refresh. The canonical `/var/lib/slackpkg` state must retain its frozen fingerprint after the transaction, while the newly created workdir `pkglist` is the only admissible refresh metadata for candidate binding.

The local refresh remains network-isolated. Acceptance requires exit status zero **and** captured stdout/stderr without `error-downloading-from-local-source`. The v2 tree must be reverified immediately before refresh. Any failure in those guards aborts before candidate binding and therefore before reference apply.

## Candidate binding design

The global `pkglist` row-count guard is permanently retired and is forbidden in the remediated implementation. Candidate binding is target-specific: with `kernel-headers-6.18.44-x86-1` installed, the fresh transaction-owned `pkglist` must contain exactly one target candidate for `kernel-headers-6.18.45-x86-1` at `./slackware64/d`, with zero install-new, non-header upgrade, and configured boot-package upgrade candidates.

The candidate must remain bound to the frozen target SHA-256 and v2 manifest and may exist only inside the same runtime transaction. It must be consumed immediately by the frozen reference apply or invalidated by rollback; it may not be carried across a pause.

## Evidence remediation

All new TSV evidence must contain real tab characters. Literal `\t` separators in preflight or candidate-binding evidence are forbidden. The implementation must use the existing `record_kv` pattern or `printf` with real tabs. Refresh stdout, stderr, exit status, transaction workdir path, pre/post `pkglist` state, and fresh `pkglist` SHA-256 must be preserved in the runtime evidence.

The new runtime evidence root is `/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation`, deliberately separate from the preserved failed root. Successful evidence may be published only after final restoration and invariant verification.

## Semantics that do not change

The executor still stages only the frozen 6.18.44 predecessor, proves a header-only package delta and unchanged boot state, runs the exact frozen reference script with the bounded derived configuration, restores the 6.18.45 target on failure, restores Slackpkg configuration and GenInitrd policy, requires unchanged boot artifacts and no reboot, and publishes success evidence only after all final invariants pass.

## Authorization boundary

Step 236 authorizes only repository-side `runtime-executor-implementation-review`. That review may create the separately named implementation files and build a canonical payload for repository acceptance, but it may not transport or execute that payload. Package action, Slackpkg mutation, live candidate binding, repository/network access, boot action, reboot, evidence cleanup, persistent configuration change, runtime rerun, and Phase 2 remain forbidden.

Frozen helper SHA-256: `f76b7e618c879565cc9e8483a7db435eb16826d39d96506702ed0ab63c9e94cb`.
Frozen policy SHA-256: `0a861ac5ca77f427664ae521245d91cf209bfc92099a7cedb2f47cb250d7a559`.
Frozen record SHA-256: `68fe35a6d3ae05325307033178d7cf0f151cf1f2d1d56058c46c71162dcb6269`.

Next stage: `phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-review`.
