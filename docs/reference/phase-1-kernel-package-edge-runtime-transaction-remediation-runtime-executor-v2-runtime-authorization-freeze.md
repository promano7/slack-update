# Phase 1 step 257 — runtime executor-v2 authorization freeze

## Status

PASS. Step 257 consumes the accepted step-256 repository-only authorization review, revalidates the frozen executor-v2 repository acceptance at `PASS (94 passes, 0 failures)`, and freezes exactly one runtime use of the reviewed bounded remediation transaction.

## Single-use authority

The authorization is bound to `vbox-slackcurrent.vbox-slackcurrent.org`, running kernel `6.18.45`, boot ID `047e744d-d2ea-4d9a-8746-7734b58db3b2`, package-database manifest SHA-256 `726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6`, the frozen Slackpkg fingerprints, staged target SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`, and accepted `local-source-v3` manifest SHA-256 `8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b`.

The only authorized executor is `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh`, SHA-256 `deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d`. The only authorized predecessor is `kernel-headers-6.18.44-x86-1.txz`, SHA-256 `3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d`. Rebuilding the executor or redownloading the predecessor is not authorized.

The exact executor and predecessor bytes may be transported to `/home/promano/Descargas/` only after their controller hashes are verified. Their target hashes must be verified again before runtime start.

## Runtime boundary

The exact command authorized once is:

```bash
sudo bash phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh \
  --execute-runtime-remediation-v2-validation
```

Starting that command consumes the authorization regardless of its exit status. A second invocation is not authorized. Any failure or drift must be returned for result review or a fresh revalidation/authorization chain before another runtime attempt.

Before the first mutation the executor must revalidate the complete frozen target state, historical evidence, historical `local-source-v2`, accepted `local-source-v3`, its manifest sidecar and exact coverage, the exact `PGP compatibility marker for Slackpkg checkchangelog only.` marker, absence of OpenPGP-signature impersonation, and absence of all new v2 evidence destinations.

Inside this single transaction only, the reviewed bounded operations are authorized: temporary staging of `kernel-headers-6.18.44`, temporary Slackpkg configuration, local `file://` metadata refresh, fresh transaction-owned `pkglist`, same-transaction target-specific candidate binding, frozen reference apply, restoration to `kernel-headers-6.18.45`, and publication of the v2 evidence archive. The exact human-spaced `Error downloading from ` signal remains fail-closed even if Slackpkg exits zero.

External network access, predecessor redownload, persistent configuration changes, boot changes, reboot, evidence cleanup and Phase 2 remain forbidden.

## Required result boundary

The required successful terminal state restores `kernel-headers-6.18.45-x86-1`, package-database manifest SHA-256 `726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6`, Slackpkg state/configuration, GenInitrd policy, boot artifacts, running kernel and boot ID. Success must publish `/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-v2-evidence.tar.gz` and its `.sha256` sidecar.

No further target-machine action is authorized after the executor exits. The next stage is repository/controller result review: `phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-result-review`. `pause_safe=false`.
