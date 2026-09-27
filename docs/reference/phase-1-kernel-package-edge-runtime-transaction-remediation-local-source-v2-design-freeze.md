# Phase 1 step 225: kernel-package-edge runtime-transaction remediation local-source-v2 design freeze

Step 225 consumes the accepted step-224 repository-only design review and freezes that design without changing its semantics. No target-machine authority is inherited or opened. The frozen runtime identity remains historical input only and must be freshly revalidated before any later machine action.

## Frozen local-source-v2 contract

The only accepted remediation source remains `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2`, separate from immutable `local-source-v1`, with mirror URI `file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2/`, external tree manifest, and manifest SHA-256 sidecar. The preserved failed-runtime evidence, staged target, and v1 tree remain unchanged.

The frozen package payload is exactly `kernel-headers-6.18.45-x86-1.txz`, SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`, at `slackware64/d/kernel-headers-6.18.45-x86-1.txz`. The 6.18.44 predecessor must remain absent from v2.

The deterministic top-level metadata set remains `ChangeLog.txt`, `FILELIST.TXT`, `PACKAGES.TXT`, `CHECKSUMS.md5`, and `CHECKSUMS.md5.asc`. `CHECKSUMS.md5.asc` remains a Slackpkg local-refresh compatibility artifact only and makes no authenticity claim. Any later local refresh must use `CHECKGPG=off` only inside its bounded temporary Slackpkg configuration.

The priority-tree contract is frozen exactly as reviewed: `patches`, `slackware64`, `extra`, `pasture`, and `testing` each require `PACKAGES.TXT`; only `slackware64/PACKAGES.TXT` may contain the single target stanza, while the non-target priority indexes contain zero package stanzas. The global `pkglist` row-count requirement remains retired.

Final publication remains fail-closed: final v2 paths must not pre-exist, construction must occur in a builder-owned temporary sibling, generated files and directories are normalized and made read-only, exactly one package archive is present, and the external tree manifest plus sidecar bind the published result.

## Frozen future refresh contract

A later remediated transaction must use a transaction-owned new empty Slackpkg workdir. `pkglist` must be absent before refresh and created in that workdir by the guarded local refresh. `/var/lib/slackpkg/pkglist` may not be reused as proof of refresh.

The same transaction must verify the v2 tree immediately before refresh, use only the file URI under network isolation, require refresh exit status zero and no local-source download error signal, and then bind exactly one target-specific `kernel-headers-6.18.45-x86-1` candidate from `./slackware64/d` while the 6.18.44 predecessor is installed. Candidate source binding must trace back to the frozen target SHA-256 and v2 tree manifest. `install-new`, non-header upgrade, and configured boot-package upgrade candidate counts remain zero. Candidate binding and consumption remain inseparable, and TSV evidence must use real tab characters.

## Authorization boundary

This step freezes design only. It does not implement or execute the builder, construct v2, copy artifacts to the VM, refresh Slackpkg, bind candidates, remediate or rerun the executor, mutate packages, access network repositories, modify boot state, reboot, clean evidence, or start Phase 2.

The only new authority is repository-only `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review`. That implementation review may create source code and acceptance fixtures in the repository, but it may not execute the builder on the target or authorize a v2 build.

Next stage: `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-review`. The remediation chain remains active, so `pause_safe=false`.
