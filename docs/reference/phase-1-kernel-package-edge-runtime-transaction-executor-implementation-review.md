# Phase 1 kernel-package-edge runtime transaction executor implementation review

Step 216 implements and reviews the standalone runtime transaction designed in
step 215. This remains a repository-only step. It freezes the builder, executor
body, canonical generated payload, and repository acceptance harness, but does
not authorize building a transport copy, copying either runtime artifact to the
VM, staging the predecessor package, or executing the transaction.

## Reproducible standalone payload

The controller builder reads only the exact frozen
`tools/reference/slack-update-reference.sh`, `data/config/slack-update.conf`,
and reviewed executor body. It rejects any SHA-256 drift and generates a single
standalone runtime script. The canonical generated payload is committed and the
repository acceptance harness requires a fresh builder run to reproduce it
byte-for-byte.

The payload embeds the exact frozen reference script and effective
configuration. The separately transported predecessor remains outside the
payload and must match SHA-256
`3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d`
before any mutation.

## Runtime preflight and transaction

The executor requires the explicit `--execute-runtime-validation`
acknowledgement and root privilege. Before package or Slackpkg mutation it
revalidates the step-213 fresh target identity, package database manifest,
Slackpkg configuration hashes, installed kernel-package records, staged target,
read-only local-source tree, tree manifest, predecessor transport bytes, and
absence of prior runtime evidence.

After the preflight it extracts and rehashes the embedded reference and source
configuration, derives the bounded runtime configuration, fingerprints `/boot`,
Slackpkg state, and GenInitrd policy, and creates private backups before the
rollback trap is armed.

The transaction then stages only
`kernel-headers-6.18.44-x86-1`, proves that this is the sole package-record
delta, switches Slackpkg temporarily to the immutable local `file://` source,
and refreshes metadata inside a network namespace with no external interfaces.
The live candidate guard requires exactly one upgrade back to
`kernel-headers-6.18.45-x86-1`, with zero install-new, non-header, or configured
boot-package candidates.
The binding lifetime remains `same-runtime-transaction-only` and is consumed
without a pause by the immediately following reference apply.

## Reference apply and validation

The exact embedded reference script runs with `--apply --json` inside the same
network-isolated boundary and with the derived test configuration. The executor
requires a successful reference result, a kernel-change trigger, the
kernel-header external-module warning, and no initrd or GRUB action. Flatpak,
SBo, ELF, and Cinnamon remain disabled only in the derived runtime
configuration; Slackware update behavior, package classification, and
`boot.mode=auto` remain unchanged.

## Rollback and final gate

A cleanup trap is installed before the predecessor package is staged. Any
failure after that point attempts to restore the frozen 6.18.45 target header,
original Slackpkg configuration and state, and original GenInitrd policy. The
6.18.44 predecessor is never an acceptable terminal state.

Success additionally requires the final package-database manifest, running
kernel, boot ID, configured boot package records, `/boot` fingerprint, local
source, staged target, Slackpkg configuration/state, and GenInitrd policy to
match the accepted baseline. Evidence publication is allowed only after this
restoration gate passes.

## Repository acceptance

`tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-executor.sh`
performs repository-only acceptance. It verifies exact input identities,
syntax, explicit acknowledgement, deterministic generation, embedded payload
bytes, transaction ordering, candidate counts, network isolation, rollback
coverage, final-invariant guards, and the absence of controller-side package or
network execution.

The accepted repository result is `PASS (69 passes, 0 failures)`.

## Authorization boundary

Step 216 freezes an implemented and repository-reviewed payload only. Runtime
executor build/transport, predecessor transport, predecessor staging,
temporary Slackpkg mutation, metadata refresh, candidate binding, reference
apply, package mutation, boot action, reboot, and Phase 2 remain unauthorized.

The next stage is
`phase-1-kernel-package-edge-runtime-transaction-executor-runtime-authorization-review`.
`pause_safe=false`.
