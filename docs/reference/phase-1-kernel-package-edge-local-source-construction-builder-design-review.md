# Phase 1 kernel-package-edge local-source construction builder design review

Step 203 consumes the accepted step-202 fresh post-pause target binding and the frozen step-197 package bytes. It reviews the exact contract for `tools/reference/phase-1-kernel-package-edge-local-source-build.sh` without implementing or executing the builder and without opening target-copy, package, boot, reboot, repository-refresh, or runtime-execution authority.

## Builder inputs and isolation

The builder is designed to execute only on the bound Slackware-current target VM under `root-via-sudo`, after a later gate has copied the frozen target package into `/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz`. The builder accepts exactly that one package as source input and must verify its SHA-256 as `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c` before generating anything.

The frozen predecessor `kernel-headers-6.18.44-x86-1.txz` is explicitly not builder input. It remains a later staging-only artifact and must never appear as a package candidate in the generated source. The external controller evidence root remains immutable and is never modified by the builder.

## Deterministic minimal Slackpkg source

The final source root remains `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source` and the runtime mirror remains `file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source`. Exactly one package archive may be exposed: `slackware64/d/kernel-headers-6.18.45-x86-1.txz`.

The builder must generate the accepted top-level metadata set: `ChangeLog.txt`, `FILELIST.TXT`, `PACKAGES.TXT`, and `CHECKSUMS.md5`. `PACKAGES.TXT` must contain exactly one package stanza for the target package at `./slackware64/d`, with compressed/uncompressed KiB values and the package description derived from `install/slack-desc` inside the bound target package. `FILELIST.TXT` must enumerate the canonical target package path and may not expose a second package archive. `CHECKSUMS.md5` must bind the target package bytes. `ChangeLog.txt` must be non-empty and deterministic.

Generated metadata is intentionally not upstream-signed. Package authenticity therefore continues to come from the already accepted step-197 package/signature binding; a later runtime configuration may disable metadata-signature checking only within the separately bound local-source transaction. Runtime network access remains forbidden.

## Construction safety and finalization

The builder must construct a temporary sibling tree first and promote it only after all input, file-set, metadata, and checksum validations pass. It may not overwrite a pre-existing final source tree. It may clean only a temporary tree that it created itself and must preserve staging inputs on every failure.

The generated tree must not embed wall-clock time, hostname, or boot ID. Generation uses locale `C`, umask `022`, and sorted relative paths for the SHA-256 tree manifest. The manifest is stored outside the source tree at `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256`, with its own SHA-256 recorded beside it, avoiding a self-referential manifest.

After validation, all source directories become mode `0555`, all regular source files become `0444`, and ownership is `root:root`. The completed tree must verify unchanged immediately after finalization, before the later reference apply, and again after the reference apply.

The builder itself must not mutate the package database, Slackpkg configuration, boot state, or reboot state and must perform no network access.

## Authorization boundary

Step 203 is design review only. `tools/reference/phase-1-kernel-package-edge-local-source-build.sh` remains absent. No target artifact copy, local-source build, candidate refresh, package action, boot action, reboot, runtime scenario execution, repository/network refresh, or Phase 2 work is authorized.

The only continuation opened is `phase-1-kernel-package-edge-local-source-construction-builder-design-freeze`. This checkpoint remains inside the active chain (`pause_safe=false`).
