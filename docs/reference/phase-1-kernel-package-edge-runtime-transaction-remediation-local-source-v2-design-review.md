# Phase 1 step 224: kernel-package-edge runtime-transaction remediation local-source-v2 design review

Step 224 consumes the accepted step-223 fresh remediation identity only as repository-side design input. It performs no target-machine action and grants no inherited authority from the read-only observation. The frozen boot ID remains `cd975bdc-a133-47d1-9e92-e9b51bef9d99`, but any later machine action must explicitly revalidate that identity before use.

## Preserved evidence

`local-source-v1`, its external manifest, the staged 6.18.45 target, and the contained-failure runtime evidence remain immutable historical evidence. v1 is not patched in place. The remediation uses a separately named root `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2` with independent external tree manifest and sidecar.

The staged target remains `kernel-headers-6.18.45-x86-1.txz` at SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`. v2 must expose exactly that package archive at `slackware64/d/kernel-headers-6.18.45-x86-1.txz` and must not expose the 6.18.44 predecessor archive.

## Slackpkg-compatible v2 layout

The design requires deterministic top-level metadata `ChangeLog.txt`, `FILELIST.TXT`, `PACKAGES.TXT`, `CHECKSUMS.md5`, and `CHECKSUMS.md5.asc`. The `.asc` file is a bounded local-refresh compatibility artifact only. It makes no cryptographic authenticity claim; the package remains authenticated by the frozen target SHA-256 plus the v2 tree manifest, and any future local refresh must explicitly use `CHECKGPG=off` inside its temporary Slackpkg configuration.

To match the priority-tree lookup model used by Slackpkg on x86_64, v2 provides a `PACKAGES.TXT` under each designed priority tree: `patches`, `slackware64`, `extra`, `pasture`, and `testing`. Only `slackware64/PACKAGES.TXT` may contain a package stanza, and it must contain exactly the frozen target stanza. The other priority-tree package indexes contain zero package stanzas. The top-level `PACKAGES.TXT` also contains exactly the target stanza as deterministic compatibility metadata.

The generated tree is immutable after publication: root-owned directories mode `0555`, regular files mode `0444`, normalized generated mtimes at epoch zero, exactly one `.txz`, a complete `FILELIST.TXT`, deterministic MD5 compatibility metadata, and an external SHA-256 tree manifest plus sidecar. The final v2 paths must not pre-exist; a future builder must construct a temporary sibling tree and publish only after full validation.

## Fresh Slackpkg work metadata contract

The earlier failed executor accepted a zero refresh exit status while stale `/var/lib/slackpkg/pkglist` data survived. Step 224 therefore retires reuse of that work metadata. A future remediated transaction must use a newly created transaction-owned empty Slackpkg workdir. `pkglist` must be absent before refresh and created inside that workdir by the guarded local refresh. The transaction may not treat the existing `/var/lib/slackpkg/pkglist` as refresh evidence.

Refresh acceptance requires all of the following in the same guarded transaction: verified v2 tree manifest immediately before refresh; file-URI source only under network isolation; refresh exit status zero; no `error-downloading-from-local-source` signal in captured output; a fresh transaction-owned `pkglist`; and target-specific candidate binding. The global `pkglist` row-count requirement remains retired.

The candidate guard must identify exactly one `kernel-headers-6.18.45-x86-1` target row from the `slackware64` source location, require `kernel-headers-6.18.44-x86-1` to be installed at binding time, bind the target source back to the frozen SHA-256 and v2 tree manifest, and keep `install-new`, non-header upgrade, and configured boot-package upgrade candidate counts at zero. Binding and consumption remain one transaction. TSV evidence uses real tab characters.

## Authorization boundary

This step completes design review only. It does not implement or execute a v2 builder, copy files to the VM, refresh Slackpkg, bind runtime candidates, remediate or run the executor, modify packages, access a network repository, change boot state, reboot, clean evidence, or start Phase 2. The only next authority is repository-only design freeze.

Next stage: `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-design-freeze`. The active remediation chain remains open, so `pause_safe=false`.
