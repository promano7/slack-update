# Phase 1 kernel-package-edge local-source construction review

Step 198 consumes the accepted step-197 byte binding and the accepted step-195
local-source design. It reviews the construction contract for the isolated
`kernel-package-edge` source without copying artifacts to the Slackware-current
VM, building the source tree, refreshing metadata, mutating packages, or
opening a runtime execution boundary.

## Accepted immutable input

The complete step-196 evidence root remains external to the repository and must
be preserved unchanged:

`/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts`

The only package that a future local source may expose is the frozen target
artifact `kernel-headers-6.18.45-x86-1.txz`, whose accepted SHA-256 is
`c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`.
The predecessor artifact is staging input only and must never be exposed by the
local source as a candidate.

No re-download is authorized. A later Slackware-current publication does not
replace or invalidate these frozen bytes.

## Construction contract

The accepted design remains:

- runtime root: `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source`
- mirror URI: `file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source`
- target package path: `slackware64/d/kernel-headers-6.18.45-x86-1.txz`
- required metadata: `ChangeLog.txt`, `FILELIST.TXT`, `PACKAGES.TXT`, and
  `CHECKSUMS.md5`
- planned builder: `tools/reference/phase-1-kernel-package-edge-local-source-build.sh`

Step 198 deliberately does not implement or execute that builder. Before a
future builder may run, its exact implementation must be reviewed against the
actual `slackpkg` metadata contract and then explicitly authorized. The built
tree must contain only the bound target package as a package candidate, must be
made read-only, must receive a complete SHA-256 tree manifest, and must verify
unchanged both before and after the reference apply.

The header-only candidate guard remains unchanged: exactly one selected header
upgrade, zero `install-new` candidates, zero non-header upgrade candidates, and
zero configured kernel boot-package candidates. The tested transition remains
`tools/reference/slack-update-reference.sh --apply`. Runtime network access,
boot mutation, and reboot remain forbidden.

## Pause boundary

No controller network access, target-machine action, target copy, local-source
build, package action, boot action, reboot, runtime execution, or Phase 2 work
is authorized by step 198. Before any later machine action, the target must be
freshly revalidated because the historical step-194 boot/package binding is not
carried forward as an open execution authorization.

The next stage is
`phase-1-kernel-package-edge-local-source-construction-review-and-strong-safe-pause`.
That review may close the active chain as a strong safe pause while preserving
the frozen bytes and construction contract for a later fresh continuation.
