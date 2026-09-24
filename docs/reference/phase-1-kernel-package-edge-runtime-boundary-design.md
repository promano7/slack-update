# Phase 1 kernel-package-edge runtime-boundary design

Step 192 consumes the accepted step-191 `kernel-package-edge` contract and
freezes a reproducible runtime-boundary design for the single scenario
**“Kernel headers update without a kernel image update.”** This remains a
repository-only design step. It does not bind a VM, package pair, local source,
or live candidate set and it authorizes no machine or package action.

## Controlled header-only transition

The later runtime chain must not depend on a coincidental Slackware-current
publication. Instead, it will bind two genuine Slackware-current artifacts for
one configured kernel-header package: a predecessor package used only to stage
the precondition and a target package exposed by an immutable local
`slackpkg`-compatible source. The package pair must share the same Slackware
package name and have different versions/build identities.

Before staging, the validation VM must be coherent and all configured kernel
boot packages must already match the bound target source. The setup phase may
later be explicitly authorized to replace **only** the selected header package
with its bound predecessor. No boot package may change during setup.

The immutable local source then exposes the target header package and its
hash-bound metadata without requiring network access during the actual runtime.
After a local-source metadata refresh, a mandatory candidate guard must prove
that the exact candidate set contains one upgrade only: the selected configured
kernel-header package. `install-new` candidates, non-header upgrade candidates,
and configured kernel-boot upgrade candidates must all be zero. Any mismatch
stops the chain before the reference apply and restores the pre-test state.

The tested transition itself must be performed by
`tools/reference/slack-update-reference.sh --apply`, not by the staging helper.
That apply must return the selected header package to the bound target version
and demonstrate `KERNEL_TRIGGER=1`, `INITRD_UPDATE=0`, `GRUB_UPDATE=0`, the
external-module warning, and no boot-preparation action.

## Evidence and rollback

Evidence must bind the target identity and boot ID, reference/configuration
hashes, configured header/boot package sets, the predecessor and target package
filenames/versions/SHA-256 values, local-source metadata hashes, package
snapshots, candidate guard, reference output/status, running-kernel identity,
boot-artifact fingerprints, and the final cleanup state.

Temporary `slackpkg` configuration changes must be restored byte for byte. The
running kernel and boot artifacts must be identical before staging, after
staging, and after the reference transition. No reboot or boot configuration
mutation is allowed.

On any failure, the later executor must restore the bound target header package,
restore the original `slackpkg` configuration, preserve evidence, and stop the
chain. On success, the selected header package is back at the bound target
version, configured boot packages have zero delta, and the final package state
is coherent.

Evidence is planned under `/var/tmp/slack-update-acceptance/kernel-package-edge`
and published as a private archive and SHA-256 sidecar in `/home/promano`, owned
by `promano:users` with mode `0600`.

## Authorization boundary

Step 192 authorizes only the next target-binding review. It does **not**
authorize package-pair/source binding, runtime-executor implementation, runtime
execution, repository/network refresh, machine execution, package mutation,
boot mutation, reboot, or Phase 2.

A later Slackware-current publication does not invalidate this design because
the exact target, predecessor/target package pair, local source, and candidate
set remain unbound. Those live identities must be established by later explicit
gates.

The acceptance matrix remains incomplete; `reference-v1` and the C port remain
behind their existing Phase 1 gates.

Frozen helper SHA-256: `6d60eab66bf569832f6998193629ec04993e22554b792e1ceae37076241bd7c8`.  
Frozen policy SHA-256: `a8e20a7a76b3c3b959ec8a2375c1d2c96cf11cbbdc0dfbd56cdfa3ac2696330a`.  
Frozen record SHA-256: `e244ecf5286a9b9e4f448151c1926469bb5c8b892091ea26e52b61c85c8e1d9e`.

The next stage is `phase-1-kernel-package-edge-runtime-target-binding-review`.
Step 192 is not the requested end-of-session strong safe pause, so
`pause_safe=false`.
