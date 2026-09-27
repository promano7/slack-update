# Phase 1 step 246: kernel-package-edge runtime-transaction second remediation implementation-contract freeze

Step 246 consumes the accepted step-245 repository-only implementation-contract
review and freezes the exact `local-source-v3` builder implementation without
executing it. It also freezes the reviewed future executor-v2 contract while
keeping that executor deliberately unimplemented until an accepted v3 tree
manifest exists.

## Frozen local-source-v3 builder

The execution identity is the exact repository file `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh` at SHA-256
`56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582`. The production acknowledgement remains
`--build-local-source-v3`; the repository library seam is test-only and cannot
be used as production authority.

The frozen builder consumes only the staged
`kernel-headers-6.18.45-x86-1.txz` at SHA-256
`c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`.
It must publish a previously absent `local-source-v3` through a validated
temporary sibling, with deterministic epoch-zero metadata, the five-tree
Slackpkg layout, exactly one target package, an external SHA-256 tree manifest
and sidecar, and no mutation of `local-source-v2` or prior failed evidence.

The compatibility `CHECKSUMS.md5.asc` contract is frozen exactly. It must
contain `PGP compatibility marker for Slackpkg checkchangelog only.`, must
state that it provides no cryptographic authenticity, and must never contain
`BEGIN PGP SIGNATURE`.

## Frozen future executor-v2 contract

The future executor-v2 remains **not implemented**. Its implementation must
wait until the v3 build result has been accepted so it can bind the exact
accepted v3 manifest SHA-256. The human-spaced `Error downloading from ` guard,
fresh transaction-owned `pkglist` proof, target-specific same-transaction
candidate binding, isolated WORKDIR/TEMP, no external network, rollback,
restoration invariants, real-tab evidence, and no reboot remain mandatory.
The old hyphenated-literal guard remains forbidden.

## Reacceptance at freeze

The step-246 harness rechecks the exact builder SHA and exercises the frozen
builder through its repository-only library seam using a synthetic package. It
reproves deterministic rendering, the exact PGP compatibility marker, absence
of an OpenPGP signature block, one target package, predecessor absence, and
fail-closed rejection of a pre-existing final v3 output path.

## Freshness boundary

No machine authority is inherited from earlier observations. Before the
builder may be transported or executed on `vbox-slackcurrent`, the staged
target and relevant baseline state must be freshly revalidated again and the
absence of all final v3 output paths must be observed. Step 246 authorizes only
the repository-side design/review of that bounded pre-build revalidation; the
observation itself remains closed.

Next stage: `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review`. `machine_action_required=false`,
`controller_action_required=false`, and `pause_safe=false`.
