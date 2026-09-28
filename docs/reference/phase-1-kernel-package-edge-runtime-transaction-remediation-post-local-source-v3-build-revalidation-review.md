# Phase 1 kernel-package-edge runtime-transaction remediation post-local-source-v3 build revalidation review

## Status

PASS — repository review only. This step consumes the accepted step-251 resume-planning boundary and opens exactly one bounded read-only observation on `vbox-slackcurrent.vbox-slackcurrent.org`.

## Purpose

The accepted `local-source-v3` build is already frozen at tree-manifest SHA-256 `8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b`, but the live target identity that preceded the step-250 strong safe pause is expired as future authority. Before executor-v2 implementation or any runtime use, the target and accepted v3 tree must be freshly revalidated.

## Authorized observation

Exactly one copy of the frozen probe may be transported to the Slackware-current VM and executed once through `sudo` with `--observe-post-v3-build-revalidation`. The repository itself is not required on the target.

The probe is read-only. It verifies the fresh boot ID, package-database manifest, installed header/generic records, Slackpkg configuration fingerprints, staged target bytes, preserved historical `local-source-v2`, accepted `local-source-v3`, and failed remediation evidence.

For `local-source-v3`, the manifest SHA-256 and sidecar must verify, the manifest must cover exactly the accepted regular-file set, the tree must match the manifest, ownership and modes must remain frozen, only the target package may be exposed, priority-tree metadata must remain valid, and `CHECKSUMS.md5.asc` must contain the exact Slackpkg compatibility marker `PGP compatibility marker for Slackpkg checkchangelog only.` while making no authenticity claim and containing no OpenPGP signature block.

The historical human-spaced Slackpkg failure prefix remains exactly `Error downloading from ` in the executor-v2 contract. The step-252 TSV stores that literal as hexadecimal `4572726f7220646f776e6c6f6164696e672066726f6d20` so the repository record contains no physical trailing whitespace.

## Closed authority

This step does not itself bind a candidate set or authorize executor-v2 implementation, transport, or runtime execution. Package mutation, Slackpkg mutation, repository refresh, external network access, boot action, reboot, evidence cleanup, persistent configuration changes, and Phase 2 remain closed.

The single observation authority is consumed when the probe starts. Any failure or drift requires a fresh review rather than a retry under the same authority.

## Next stage

A successful returned observation routes only to `phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v3-build-revalidation-freeze`, where the fresh target identity and accepted v3 tree observation can be consumed and frozen for later repository work.

`pause_safe=false` while this one-use observation authority remains open.
