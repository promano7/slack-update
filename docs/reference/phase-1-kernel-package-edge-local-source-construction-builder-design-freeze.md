# Phase 1 kernel-package-edge local-source construction builder design freeze

Step 204 consumes the accepted step-203 builder design review and freezes that design as the only contract eligible for implementation review.

## Accepted design

The builder remains `tools/reference/phase-1-kernel-package-edge-local-source-build.sh` and remains **not implemented** at this step. Its future execution target is the Slackware-current target VM under sudo with explicit acknowledgement `--build-local-source`.

The design accepts exactly one builder input: `kernel-headers-6.18.45-x86-1.txz`, SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`. The 6.18.44 predecessor remains excluded from the local source and reserved only for later staging.

The frozen source layout exposes exactly one package candidate at `slackware64/d/kernel-headers-6.18.45-x86-1.txz` and requires the deterministic top-level metadata `ChangeLog.txt`, `FILELIST.TXT`, `PACKAGES.TXT`, and `CHECKSUMS.md5`. `PACKAGES.TXT` contains exactly one stanza and obtains its description from `install/slack-desc` inside the bound target package.

Construction must be fail-closed in a builder-owned temporary tree. A pre-existing final tree must never be overwritten. No wall-clock time, hostname, or boot ID may be embedded. Promotion is permitted only after validation. The finalized tree must be `root:root`, directories mode `0555`, regular files mode `0444`, with an external sorted SHA-256 manifest and separate SHA-256 for that manifest.

The builder itself may not access the network, modify the external evidence root, package database, `slackpkg` configuration, boot state, or reboot the machine. Generated metadata is not treated as upstream-signed authenticity evidence; authenticity remains anchored in the accepted step-197 package/signature binding.

## Authorization boundary

This freeze does not implement the builder and does not authorize copying artifacts, constructing the local source, refreshing repositories/candidates, executing the runtime scenario, modifying packages/boot state, rebooting, or starting Phase 2. No machine action is required.

The only next authority is repository-only `phase-1-kernel-package-edge-local-source-construction-builder-implementation-review`. The active chain remains open and `pause_safe=false`.
