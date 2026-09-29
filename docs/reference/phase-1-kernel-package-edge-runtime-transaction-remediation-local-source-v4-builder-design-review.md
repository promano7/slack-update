# Phase 1 step 261 — local-source-v4 builder design review

## Status

PASS. Step 261 consumes the accepted step-260 remediation boundary and freezes the repository-only design for a new `local-source-v4` builder. No builder implementation is created by this step, no production builder is executed, and no machine or controller action is authorized.

## Design baseline

The accepted `local-source-v3` builder at SHA-256 `80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30` is the immutable implementation baseline and historical evidence. It must not be edited in place. The v4 implementation is to be a separately named mechanical derivative whose functional delta is limited to the checksum representation defect accepted in steps 259–260.

The frozen target remains `kernel-headers-6.18.45-x86-1.txz` at SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`, located at `slackware64/d/kernel-headers-6.18.45-x86-1.txz`. The predecessor `kernel-headers-6.18.44-x86-1.txz` remains forbidden from the generated source.

## Required v4 identity changes

The production builder will be `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh`, invoked only through `--build-local-source-v4`. It will publish to `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4` with external manifest `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256` and sidecar `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256.sha256`.

The temporary build prefix, usage text, revision labels, emitted status keys, and library-only harness seam may change mechanically from v3 to v4. The library-only seam is `SLACK_UPDATE_LOCAL_SOURCE_V4_BUILDER_LIBRARY_ONLY`.

## CHECKSUMS.md5 writer design

`write_checksums_md5` continues to enumerate the sorted generated regular-file set and excludes `./CHECKSUMS.md5` and `./CHECKSUMS.md5.asc`. For every other regular file it must execute ordinary GNU `md5sum -- "$rel"`, producing exactly the untagged path-final representation:

`<32-lowercase-hex-md5>  ./relative/path`

GNU tagged records of the form `MD5 (...) = ...` are forbidden. For the target package, the filename must therefore be the final whitespace-delimited field and the line must end in `.txz`, satisfying the Slackpkg terminal-extension filter identified by the accepted root-cause review.

## CHECKSUMS.md5 validator design

Validation must calculate the expected number of bindings as the generated regular-file count minus the checksum file itself and its compatibility `.asc` file. `CHECKSUMS.md5` must contain exactly that many lines and zero tagged records.

For each eligible generated file, the validator must independently calculate its MD5 and require exactly one exact `<md5>  <relative-path>` line. The combination of exact total line count and exactly one exact binding for every expected file rejects missing, duplicate, malformed, binary-marker, and extra bindings. A tagged v3-style binding must fail validation.

## Behavior that remains unchanged

The v4 implementation must preserve v3 input validation and frozen target SHA-256 binding; output-path absence checks; package-description extraction; package stanza generation; priority trees `patches`, `slackware64`, `extra`, `pasture`, and `testing`; exactly one target package archive; predecessor exclusion; `FILELIST.TXT`; compatibility `CHECKSUMS.md5.asc` semantics; deterministic mtimes; root ownership and final `0555`/`0444` permissions; external SHA-256 tree manifest and sidecar; temporary sibling construction followed by publication; post-publication manifest verification; and root-only production execution.

The builder remains local-only. It must not add network access, package operations, Slackpkg mutation, persistent configuration change, boot action, or reboot.

## Implementation-review requirements

A later implementation review must prove that the v3 baseline hash still matches and that the v4 source diff is confined to the authorized revision-identity substitutions plus the checksum writer/validator correction. Its repository harness must source the library-only seam and exercise synthetic source trees that prove valid untagged bindings pass and tagged, missing, duplicate, malformed, or extra bindings fail. Production execution is forbidden during implementation review.

## Authorization boundary

This step performs design review only. v4 builder implementation, v4 build, target observation, transport, Slackpkg refresh/configuration, runtime candidate binding, reference apply, runtime execution/rerun, package mutation, network access, boot/reboot, evidence cleanup, and Phase 2 remain forbidden.

The only next authority is repository-only `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-freeze`. `machine_action_required=false`, `controller_action_required=false`, `pause_safe=false`, and `strong_safe_pause=false`.
