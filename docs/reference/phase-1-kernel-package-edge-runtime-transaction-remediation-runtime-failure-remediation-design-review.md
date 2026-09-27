# Phase 1 kernel-package-edge runtime transaction remediation failure remediation design review

Step 243 consumes the accepted step-242 failure-characterization freeze and reviews the second remediation design. It is repository-only. No machine, package, Slackpkg, network, boot, reboot, cleanup, build, transport, candidate-binding, or runtime-rerun authority is granted.

## Frozen failure input

The rollback baseline is `PASS`; the target is restored to `kernel-headers-6.18.45-x86-1`; canonical Slackpkg state, GenInitrd policy and boot artifacts are restored; and the single-use step-240 runtime authority remains consumed. The confirmed failure mechanism is `compatibility-asc-pgp-marker-rejection-plus-error-signal-guard-mismatch`.

The installed Slackpkg emitted the human-spaced message prefix `Error downloading from ` while returning exit code `0`. No transaction-owned `pkglist` was created. The accepted local-source-v2 compatibility `CHECKSUMS.md5.asc` contains no literal `PGP` marker, while the installed Slackpkg implementation requires that marker before continuing to package-list generation. The failed executor searched for the unrelated hyphenated literal `error-downloading-from-local-source`.

## Historical preservation boundary

`local-source-v2`, its accepted manifest identity, the failed remediation executor body/builder/payload, and the failed runtime evidence remain historical inputs and MUST NOT be modified in place. The second remediation therefore uses new-generation artifacts.

## Local-source-v3 design

The next source generation is `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3`. It retains the accepted target bytes, priority-tree layout and metadata semantics of v2, but its compatibility `CHECKSUMS.md5.asc` must satisfy the observed Slackpkg marker gate without making a cryptographic claim.

The compatibility file MUST contain the literal line `PGP compatibility marker for Slackpkg checkchangelog only.` and MUST explicitly state that no cryptographic authenticity claim is made. It MUST NOT contain `BEGIN PGP SIGNATURE` and MUST NOT impersonate an upstream signature. Runtime Slackpkg remains configured with `CHECKGPG=off`; the marker exists only to satisfy the observed installed `checkchangelog` gate.

The v3 tree, external manifest and manifest sidecar are new immutable outputs. v3 must be absent before its future builder is authorized, and its final exact manifest identity must be frozen before any runtime executor can bind to it.

## Future executor generation

The failed remediation executor generation remains immutable. A later implementation must create new files named `phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh`, `...-v2-executor-build.sh`, and `...-v2-executor.sh`.

The future executor must consume only local-source-v3 and must bind to the exact post-build v3 manifest identity. `slackpkg update` returning zero is never sufficient proof of refresh success. stdout and stderr remain captured and the actual human-spaced `Error downloading from ` signal must cause an immediate fail-closed abort. The old hyphenated-literal guard is retired. Creation of a regular transaction-owned `pkglist` remains a separate mandatory freshness proof.

All previously accepted invariants remain in force: isolated transaction-owned `WORKDIR` and `TEMP`, no external network access, target-specific candidate guard, same-transaction candidate binding, real-tab TSV evidence, exact predecessor/target bytes, header-only staging, automatic rollback after any post-mutation failure, restoration of Slackpkg and GenInitrd state, unchanged boot artifacts and no reboot.

## Continuation

This review opens only repository-side design freeze. No implementation or machine action is authorized. The next stage is `phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-freeze`.
