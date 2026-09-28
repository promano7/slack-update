# Phase 1 step 256 — runtime executor-v2 authorization review

## Status

PASS. Step 256 consumes the accepted step-255 implementation freeze and reviews the exact contract for one future bounded executor-v2 runtime transaction. This step is repository-only and grants no controller or target-machine authority.

## Exact future payload and transport boundary

The only executor eligible for a later single-use authorization is `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh`, SHA-256 `deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d`. Its future target path is `/home/promano/Descargas/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh`. Rebuilding before transport is not part of the reviewed runtime contract; the frozen bytes must be verified on the target before execution.

The only predecessor eligible for temporary staging is `kernel-headers-6.18.44-x86-1.txz`, SHA-256 `3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d`, from preserved controller source `/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts/kernel-headers-6.18.44-x86-1.txz`. Redownload remains forbidden. A later authorization may copy these exact bytes only if needed, with controller and target hashes verified before runtime start.

## Fresh-state and fail-closed boundary

The future authorization remains bound to `vbox-slackcurrent.vbox-slackcurrent.org`, running kernel `6.18.45`, boot ID `047e744d-d2ea-4d9a-8746-7734b58db3b2`, package-database manifest `726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6`, the frozen Slackpkg fingerprints, staged target SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`, and accepted `local-source-v3` manifest SHA-256 `8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b`.

Before its first mutation the executor must revalidate the complete v3 manifest and sidecar, exact coverage, priority-tree structure, exact `PGP compatibility marker for Slackpkg checkchangelog only.` marker, absence of OpenPGP-signature impersonation, preserved historical failed evidence, unchanged historical `local-source-v2`, and absence of the new v2 evidence destinations.

Any drift in executor or predecessor bytes, host/kernel/boot identity, package database, Slackpkg fingerprints, staged target, `local-source-v3`, historical evidence, historical `local-source-v2`, or v2 evidence-destination absence invalidates the future authorization and requires fresh revalidation before mutation.

## Bounded future transaction

If the next step freezes this reviewed contract as a single-use authority, the exact runtime command will be:

```bash
sudo bash phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh \
  --execute-runtime-remediation-v2-validation
```

The authority will be consumed when runtime execution starts. Candidate binding remains `same-runtime-transaction-only`. A fresh transaction-owned Slackpkg `pkglist` is mandatory, and the exact human-spaced `Error downloading from ` signal remains fail-closed even when Slackpkg exits zero.

The only bounded package transition is `kernel-headers 6.18.45 -> 6.18.44 -> 6.18.45`. Temporary Slackpkg configuration, local file-source metadata refresh, target-specific source-backed candidate binding and the frozen reference apply may occur only inside that future single-use transaction. External network access, boot action, reboot, persistent configuration changes and evidence cleanup remain forbidden.

The required terminal state restores `kernel-headers-6.18.45-x86-1`, the accepted package-database manifest, Slackpkg configuration/state, GenInitrd policy, boot artifacts, running kernel and boot ID. A successful run must publish `/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-v2-evidence.tar.gz` and its SHA-256 sidecar for result review before any further machine action.

## Current authorization boundary

Step 256 itself authorizes no transport, predecessor staging, Slackpkg mutation, metadata refresh, candidate binding, package action, runtime execution, external network, boot/reboot action, cleanup or Phase 2. It opens only repository-side `phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-runtime-authorization-freeze`.

No machine or controller action is required by this step. `pause_safe=false`.
