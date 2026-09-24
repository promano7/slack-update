# Phase 1 kernel-package-edge package-pair and local-source binding design

Step 195 consumes the accepted step-194 runtime target binding and the accepted
step-192 runtime-boundary strategy. It freezes the package-pair and immutable
local-source **design** for the single `kernel-package-edge` scenario without
binding artifact bytes, download origins, signatures, a source-tree manifest,
or a live candidate set. This is a repository-only step.

## Proposed logical package pair

The target logical identity is already fixed by the accepted VM observation:
`kernel-headers-6.18.45-x86-1`. Therefore the expected target artifact is
`kernel-headers-6.18.45-x86-1.txz` with its detached `.asc` signature.

The proposed predecessor identity is `kernel-headers-6.18.44-x86-1`, the
immediately prior `kernel-headers` release before the bound 6.18.45 target in
the cumulative Slackware-current package history. The expected predecessor
artifact is `kernel-headers-6.18.44-x86-1.txz`, also with its detached `.asc`
signature.

This step does **not** accept either artifact yet. A later binding gate must
freeze the exact acquisition origin, package SHA-256, signature SHA-256, and
trusted signing-key identity, and must verify both detached signatures before
any local source is built or anything is copied to the target VM. The pair must
share package name, package architecture, and package build, while the
predecessor must compare older than the target and the target must match the
step-194 installed record exactly.

## Controller acquisition boundary

Artifact acquisition is designed as a controller-side operation only and is
not authorized by step 195. The target VM must never download either package or
its signature. A later explicit gate may authorize acquisition of the two
package files and two detached signatures on the controller, after which their
exact byte identities must be frozen before any target copy is allowed.

A later Slackware-current publication does not replace the already bound
6.18.45 target identity. The point of this test is to reproduce the accepted
header-only transition, not to chase the newest repository state.

## Minimal local source design

The runtime source will be generated deterministically from the **verified
bound target artifact** and placed at:

`/var/tmp/slack-update-acceptance/kernel-package-edge/local-source`

The mirror URI will be:

`file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source`

The target package will appear at:

`slackware64/d/kernel-headers-6.18.45-x86-1.txz`

The minimal generated source must contain the metadata required by the target
`slackpkg` workflow, including `ChangeLog.txt`, `FILELIST.TXT`, `PACKAGES.TXT`,
and `CHECKSUMS.md5`. Only the bound target package may be exposed as a package
candidate by this source.

Because this metadata is generated specifically for the isolated test, it is
not upstream Slackware-signed metadata. Artifact authenticity must therefore be
established independently **before** source generation by the later frozen
package/signature binding. A temporary runtime configuration may disable the
metadata-signature check only inside the bound local-source transaction; it may
not weaken the independent package/signature verification contract.

After generation the local source must be made read-only, its complete file
SHA-256 set and tree-manifest SHA-256 must be frozen, and that tree must verify
unchanged before and after the reference apply. Runtime network access remains
forbidden.

The planned deterministic builder path is
`tools/reference/phase-1-kernel-package-edge-local-source-build.sh`. The builder
itself is not implemented or authorized by this step.

## Candidate and target guards

The step-192 candidate guard remains unchanged: after the local-source metadata
refresh there must be exactly one upgrade candidate and it must be the selected
`kernel-headers` package. `install-new` candidates, non-header upgrade
candidates, and configured kernel boot-package candidates must all remain zero.

The tested transition must still be performed by
`tools/reference/slack-update-reference.sh --apply`. Boot mutation, boot
configuration mutation, unrelated package mutation, and reboot remain
forbidden.

Before any later target copy or staging action, the step-194 target binding must
still be valid. A target reboot, package-database drift, running-kernel drift,
or controller reference/effective-configuration drift returns the chain to the
target-binding review before any package action can occur.

## Authorization boundary

Step 195 authorizes only the next repository gate:
`phase-1-kernel-package-edge-package-pair-and-local-source-binding-review`.

It does not authorize controller artifact acquisition, target artifact copy,
package-pair binding, local-source binding/build, runtime-executor
implementation, runtime scenario execution, repository/network refresh,
machine execution, package or boot action, reboot, or Phase 2.

The acceptance matrix remains incomplete. This step is not a strong safe pause,
so `pause_safe=false`.

Frozen helper SHA-256: `9dff053b5f8c4beeb78e3c827b241f7dafc9604a397b3caeda64a2348151f8b7`.  
Frozen policy SHA-256: `ce33fc2ead2335c50cd9e47146f8d1d818a49e1cb3169b06fe9a983af60f6015`.  
Frozen record SHA-256: `aa37378cc4e3af31fc37a0a111b9ab0e39f3bf784e011168f962e165927a01a5`.
