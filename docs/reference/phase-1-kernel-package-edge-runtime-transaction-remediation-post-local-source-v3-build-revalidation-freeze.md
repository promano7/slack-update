# Phase 1 step 253 — post-local-source-v3-build revalidation freeze

## Status

PASS. Step 253 consumes the successful single-use read-only observation authorized by step 252 and freezes it as the fresh target identity for subsequent repository-only executor-v2 implementation review. No target-machine action is performed by this step.

## Accepted fresh observation

The returned observation is accepted with fresh boot ID `047e744d-d2ea-4d9a-8746-7734b58db3b2`. The target remains `vbox-slackcurrent.vbox-slackcurrent.org`, `x86_64`, kernel `6.18.45`, with package-database manifest SHA-256 `726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6`, installed `kernel-headers-6.18.45-x86-1` and `kernel-generic-6.18.45-x86_64-1`, and the expected Slackpkg configuration fingerprints.

The step-252 probe authority is consumed and revoked. This frozen identity remains usable only while boot, package database, Slackpkg configuration, staged target and local-source state remain unchanged.

## Frozen local-source-v3 identity

The staged target remains SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`. The accepted `local-source-v3` remains rooted at `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3` and is revalidated and frozen at external tree-manifest SHA-256 `8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b`.

The manifest sidecar, exact manifest coverage, priority-tree contract, exact target bytes, immutable tree state, and exact compatibility marker `PGP compatibility marker for Slackpkg checkchangelog only.` are accepted. The compatibility artifact remains non-authenticating and contains no OpenPGP signature block. Temporary v3 build roots remain absent.

Historical `local-source-v2` remains preserved and revalidated at manifest SHA-256 `e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945`, including its historical no-`PGP` compatibility state. Failed remediation evidence remains present and unchanged; success evidence and the failed transaction `pkglist` remain absent, while the human-spaced Slackpkg failure evidence is preserved.

## Executor-v2 implementation boundary

The executor-v2 contract frozen by step 246 is now bound to the accepted v3 manifest identity. The reserved repository paths remain:

- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh`;
- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh`;
- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh`.

The implementation review must preserve the exact human-spaced `Error downloading from ` refresh guard; the earlier hyphenated synthetic literal remains forbidden. Slackpkg exit zero is necessary but not sufficient: stdout/stderr capture, a fresh transaction-owned `pkglist`, and target-specific same-transaction candidate binding remain mandatory. Transaction-owned `WORKDIR` and `TEMP`, no external network, rollback on post-mutation failure, restored Slackpkg and GenInitrd state, unchanged boot artifacts, real-tab TSV evidence, and no reboot remain mandatory.

Step 253 authorizes only repository-side executor-v2 implementation review. It does not authorize implementation as machine-side work, transport, candidate binding, runtime execution, package/Slackpkg mutation, repository refresh, external network, boot/reboot, cleanup, persistent configuration change, or Phase 2.

## Next stage

The next stage is `phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-review`. `machine_action_required=false`, `controller_action_required=false`, and `pause_safe=false` while this repository workstream remains active.
