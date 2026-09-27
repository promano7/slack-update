# Phase 1 kernel-package-edge runtime transaction remediation runtime failure characterization freeze

Step 242 consumes the accepted step-241 read-only characterization result and freezes the second remediated runtime attempt as a contained failure with a fully restored runtime baseline. The single-use step-240 executor authority remains consumed and a second executor execution remains forbidden.

The characterization observation returned `runtime_failure_characterization_status=PASS`. It proved that `kernel-headers-6.18.45-x86-1`, the package database manifest, Slackpkg configuration and mirrors, canonical Slackpkg state, GenInitrd policy, `/boot`, and boot ID all match the accepted baseline after automatic cleanup. No success archive or `result.tsv` was published.

## Probe invocation irregularity

Two probe invocations were observed. The first invocation aborted at a read-only precondition because the preserved executor file was not available at its expected `~/Descargas` path. It produced no accepted characterization result and performed no package, Slackpkg, boot, network, cleanup, or configuration mutation. A later invocation of the same frozen probe SHA-256 `bdb06d4a10ef6ef5994f49078beb70c2b2d9b02e7775ad7d9fac66664802f22a` completed successfully and produced the accepted characterization evidence. Step 242 freezes this irregularity explicitly rather than treating the first abort as an accepted observation. The step-241 observation authority is now consumed and closed; no further probe execution is authorized.

## Confirmed failure mechanism

The mechanism is frozen as `compatibility-asc-pgp-marker-rejection-plus-error-signal-guard-mismatch`.

The preserved transaction evidence records Slackpkg update exit status `0`, but its output contains the human-form line `Error downloading from //var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2/.`. The transaction-owned workdir contains only `CHECKSUMS.md5.asc` and `ChangeLog.txt`; no fresh `pkglist` exists. The accepted `local-source-v2` compatibility `.asc` does not contain a `PGP` marker, while the installed Slackpkg implementation requires that marker in this path. The failed remediated executor searched instead for the unrelated hyphenated literal `error-downloading-from-local-source`, so exit status zero plus the mismatched output guard allowed execution to reach the later missing-`pkglist` failure.

Neither accepted `local-source-v2` nor the failed remediated executor generation may be changed in place. Both remain historical evidence. The next design must satisfy the installed Slackpkg marker gate without claiming cryptographic authenticity for the compatibility artifact, match the actual human-form download-error signal, retain transaction-owned workdir freshness proof and target-specific candidate binding, and preserve the existing rollback, external-network, boot, and no-reboot constraints.

## Authority boundary

Step 242 is repository-only. Probe transport/execution, runtime executor transport/execution, package actions, Slackpkg mutation or refresh, external network, boot action, reboot, evidence cleanup, and Phase 2 are all closed. The only newly opened work is repository-side `phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-design-review`. This is not a pause-safe boundary.

Frozen step-241 helper SHA-256: `df6bf05be7cdca8bb6bbbb38d1a20e1edf1ee5bd4a0f37ca270a6fea0077bb72`.
Frozen step-241 probe SHA-256: `bdb06d4a10ef6ef5994f49078beb70c2b2d9b02e7775ad7d9fac66664802f22a`.
Frozen step-241 policy SHA-256: `8eaf56961ff91db699b6de1b066a71736f8abf23c462142d4c4929e4e124c778`.
Frozen step-241 record SHA-256: `537d87de8c81f3677ddfc49d922dd94efd6d04551ddfb9d5c306e0729f506985`.
