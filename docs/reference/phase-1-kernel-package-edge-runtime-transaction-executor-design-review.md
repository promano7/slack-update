# Phase 1 kernel-package-edge runtime transaction executor design review

Step 215 consumes the accepted step-214 same-transaction candidate-binding
contract and freezes the repository-side design for the executor that will
perform the isolated kernel-header transition. This step is design-only. It
does not build, transport, or execute the runtime payload and does not authorize
any package or Slackpkg mutation.

## Transaction shape

The executor will be a standalone root-run payload that does not require the
Git repository on `vbox-slackcurrent`. It will embed the exact frozen reference
script and effective configuration identities, while the already authenticated
6.18.44 predecessor package will be transported separately and verified again
by SHA-256 before any mutation.

Before the first mutation the executor must revalidate the fresh step-213
runtime identity: hostname, running kernel `6.18.45`, boot ID
`91901677-1dc3-4a39-a4b1-3f87e6875234`, package-database manifest, Slackpkg
configuration fingerprints, current `kernel-headers-6.18.45-x86-1`, configured
boot-package state, staged target package, and the complete read-only local
source tree. The predecessor transport copy must be a regular file with
SHA-256 `3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d`.
Any drift aborts before package or Slackpkg mutation.

## Runtime configuration isolation

The executor must derive its runtime configuration from the frozen effective
configuration SHA-256
`4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba`.
Only test-isolation overrides are permitted: private work/log/lock paths under
the evidence root and disabling the Flatpak, SBo, ELF, and Cinnamon modules.
The Slackware update settings and package classification remain unchanged, and
`boot.mode` remains `auto` so the real header-only boot decision is still
exercised. This prevents unrelated secondary modules from causing network or
build actions while preserving the behavior under test.

Candidate refresh and the reference apply run inside a network namespace with
no external interfaces. The immutable `file://` source remains locally
accessible, so any accidental external-network dependency fails closed.

## Slackpkg and package transaction

The executor must first back up `/etc/slackpkg/slackpkg.conf`,
`/etc/slackpkg/mirrors`, and `/var/lib/slackpkg` after verifying the two
configuration hashes against the frozen identity. The temporary mirrors file
contains exactly the local source URI. Metadata signature checking may be
disabled only for this generated local metadata; package authenticity remains
anchored in the previously accepted detached-signature byte binding.

The selected header package is then temporarily staged from
`kernel-headers-6.18.45-x86-1` down to
`kernel-headers-6.18.44-x86-1`. Immediately afterward, the executor must prove
that this is the only package delta and that the running kernel, configured
boot-package records, and boot artifacts are unchanged.

After a local-only Slackpkg metadata refresh, the live candidate binding must
contain exactly one upgrade: `kernel-headers-6.18.44-x86-1` to
`kernel-headers-6.18.45-x86-1`. `install-new` candidates, non-header upgrades,
and configured boot-package upgrades must all be zero. This binding exists only
inside the transaction and cannot cross a pause.

## Reference apply and required result

The tested transition is performed by the exact frozen
`tools/reference/slack-update-reference.sh --apply --json`, using the derived
runtime configuration. Success requires the reference operation to return zero,
restore `kernel-headers-6.18.45-x86-1`, report a kernel trigger, emit the
external-module warning for the header update, and perform no initrd or GRUB
update. No boot-preparation action, boot artifact change, boot-package change,
or reboot is allowed.

## Rollback and cleanup

A cleanup/rollback trap must be active before the predecessor is installed. On
any failure after that point, the executor must restore the bound 6.18.45 target
header from the already staged target artifact, restore the original Slackpkg
configuration and state byte-for-byte, restore any temporary GenInitrd policy
change to its original fingerprint, preserve evidence, and stop. Leaving the
6.18.44 predecessor installed is never an acceptable terminal state.

The successful terminal state has the same package-database manifest, running
kernel, boot ID, configured boot packages, boot artifacts, local source tree,
staged target bytes, Slackpkg configuration/state, and GenInitrd policy as the
accepted pre-transaction state, except for bounded evidence stored under the
runtime evidence root. The evidence archive is published only after that final
cleanup gate passes.

## Authorization boundary

Step 215 opens only repository-side implementation review for the executor and
builder. It does not authorize building or transporting the executor,
transporting or staging the predecessor, changing Slackpkg configuration,
refreshing metadata, binding live candidates, running the reference apply,
performing package/network/boot actions, rebooting, or starting Phase 2.

Next stage:
`phase-1-kernel-package-edge-runtime-transaction-executor-implementation-review`.
`pause_safe=false`.
