# Phase 1 kernel-package-edge local-source construction builder implementation review

Step 205 consumes the accepted step-204 frozen builder design and adds the first concrete implementation of `tools/reference/phase-1-kernel-package-edge-local-source-build.sh`. This step reviews the implementation in the controller repository only; it does not authorize copying artifacts to the target VM or executing the builder.

## Reviewed implementation

The production entry point accepts only `--build-local-source`, requires root, and uses the exact frozen `/var/tmp/slack-update-acceptance/kernel-package-edge` paths from step 204. It requires the exact target input `kernel-headers-6.18.45-x86-1.txz` and verifies SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c` before creating any output.

The builder rejects symlink inputs, filename drift, SHA drift, and any pre-existing final source or manifest path. Construction occurs only in a builder-owned temporary sibling directory. The 6.18.44 predecessor is never consumed by the builder and is never exposed as a local-source candidate.

The implementation creates exactly one package candidate plus `ChangeLog.txt`, `FILELIST.TXT`, `PACKAGES.TXT`, and `CHECKSUMS.md5`. `PACKAGES.TXT` receives its package description from `install/slack-desc` in the bound target package and records deterministic compressed/uncompressed KiB values. Generated mtimes are normalized to the Unix epoch so generation does not embed the wall clock.

Before publication, the temporary source is validated for the exact package set, metadata set, target SHA-256, `PACKAGES.TXT` single-stanza identity/location, and target MD5 binding. The source is then finalized as `root:root`, directories `0555`, regular files `0444`, and an external sorted SHA-256 tree manifest plus manifest SHA-256 are generated and verified. The source tree is promoted only after validation.

The builder contains no network client, `slackpkg`, package-install/removal, boot-configuration, reboot, or shutdown operation. Its failure trap removes only the builder-owned temporary directory and never overwrites a pre-existing final source.

## Repository-only test seam

For repository testing, setting `SLACK_UPDATE_LOCAL_SOURCE_BUILDER_LIBRARY_ONLY=1` while sourcing the script exposes its pure validation/render/manifest functions without invoking production `main`. This seam does not override the production constants or paths and is not an authorized runtime interface. The step-205 harness uses it with a temporary synthetic Slackware package to exercise valid input, wrong SHA, symlink rejection, pre-existing-output rejection, deterministic metadata generation, exact single-candidate validation, and manifest verification without requiring root.

## Authorization boundary

The implementation is recorded as `implemented-reviewed-awaiting-freeze`. Step 205 authorizes only the next repository-only builder implementation freeze. It does **not** authorize builder execution, target artifact copy, local-source construction on the VM, repository/candidate refresh, package action, boot action, reboot, runtime scenario execution, or Phase 2. No machine action is required and `pause_safe=false`.
