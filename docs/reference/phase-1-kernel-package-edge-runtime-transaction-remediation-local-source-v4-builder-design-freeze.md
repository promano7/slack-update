# Phase 1 step 262 — local-source-v4 builder design freeze

## Purpose

Freeze the accepted step-261 repository-only `local-source-v4` builder design before any implementation artifact is created or reviewed. This step creates no machine authority and executes no builder.

## Accepted inputs

- Step-261 helper SHA-256: `6768757c0eb8524a7b5e75ff71281f1614f2d3a04103825d3f662c5a44c50393`.
- Step-261 document SHA-256: `d90684734c2de428d84ae0bf01c34c62c78ba234cb59598cb47ceeb910516da7`.
- Step-261 harness SHA-256: `161a00c3552bcc2cec52446a239490140df80989885ce53984c4211355b57874`.
- Step-261 policy SHA-256: `db11a25f28cd9a61779fff20c49dc7800a747b2c7b745dc3c164051c2fad73ef`.
- Step-261 record SHA-256: `b733228aeca5be7055cb84dff306744fb41f49f13c7cc8c1d57bed7401c94981`.
- Accepted immutable v3-r1 builder SHA-256: `80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30`.

## Frozen design

The step-261 design is now `design-frozen-not-implemented`. The production artifact remains reserved as `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh`, with switch `--build-local-source-v4` and library-only seam `SLACK_UPDATE_LOCAL_SOURCE_V4_BUILDER_LIBRARY_ONLY`.

The functional remediation scope remains **only** `CHECKSUMS.md5` record representation. The writer must use ordinary untagged GNU `md5sum` output so each eligible line has the exact shape `<32-lowercase-hex-md5><two spaces>./relative/path`; the relative path is the final whitespace-delimited field. GNU tagged `MD5 (...) = digest` records remain forbidden.

The validator must require exactly one exact binding for every eligible generated regular file and reject missing, duplicate, tagged, malformed, binary-marker, or extra bindings. The target package bytes, target SHA-256, package path, predecessor exclusion, priority trees, package stanzas, `FILELIST.TXT`, compatibility `.asc` semantics, deterministic metadata, external SHA-256 tree manifest, output-absence preflight, local-only behavior, and fail-closed publication remain unchanged from the accepted design.

## Implementation-review gate

The next repository-only implementation review may create the separate v4 builder artifact, but it must prove all of the following without production execution:

- the accepted v3-r1 builder still has SHA-256 `80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30`;
- the v4 source is a mechanical derivative whose diff is confined to the frozen v3→v4 identity substitutions and checksum writer/validator correction;
- the library-only seam can be sourced by a synthetic harness;
- valid untagged bindings pass;
- tagged, missing, duplicate, malformed/binary-marker, and extra bindings fail;
- no target-machine, package, Slackpkg, network, boot, reboot, or persistent-configuration action is introduced.

## Authorization boundary

This step revokes the design-review/freeze authority after use and opens only repository-side `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-review`. Builder production execution and the v4 build remain forbidden. Fresh target observation, transport, Slackpkg refresh/configuration, candidate binding, reference apply, runtime rerun, package mutation, external network, boot/reboot, cleanup, and Phase 2 remain closed.

`machine_action_required=false`, `controller_action_required=false`, `pause_safe=false`, and `strong_safe_pause=false`.
