# Phase 1 step 263 — local-source-v4 builder implementation review

## Purpose

Implement and review the separate repository-side `local-source-v4` builder under the exact step-262 frozen design, without executing the production builder or opening any target-machine authority.

## Accepted inputs

- Step-262 helper SHA-256: `a8e6e5980edcf9550bc4ab7999b4452899b45e0e29c4e62039b9045916573b2f`.
- Step-262 document SHA-256: `29da67295aba1d65de381901031048691940ac8729b57846c51d20c318ac04e5`.
- Step-262 harness SHA-256: `f5da26f955ded2eec9a70eb5035f9d06fa299476aa1414ad7a82ffd40ab98961`.
- Step-262 policy SHA-256: `9359949c6dfd9ac7476b1b4f3053dbd2859022feab6d90e7baafcafb5a07b425`.
- Step-262 record SHA-256: `fff8563425ff16f64935e94d99d6e8709554941aac55bc7e40917a04fb39d6e3`.
- Accepted immutable v3-r1 builder SHA-256: `80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30`.

## Reviewed implementation

The new production artifact is `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh` at SHA-256 `38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7`. It is a mechanical derivative of the accepted v3-r1 builder. The only permitted revision changes are the frozen v3→v4 identity substitutions plus the `CHECKSUMS.md5` writer/validator correction.

The writer now uses ordinary GNU `md5sum -- "$rel"`, producing the exact text-mode shape `<32-lowercase-hex-md5><two spaces>./relative/path`. The path is therefore the final whitespace-delimited field and package checksum rows end in the package filename rather than the digest. GNU tagged `MD5 (...) = digest` output is not used.

The validator requires the checksum file line count to equal the number of eligible generated regular files, rejects any tagged record, and requires exactly one exact `<md5><two spaces><relative-path>` binding for every eligible file. This jointly rejects missing, duplicate, tagged, malformed/binary-marker, and extra bindings.

All other accepted behavior remains unchanged: target bytes/SHA-256 and path, predecessor exclusion, package stanzas and priority trees, `FILELIST.TXT`, compatibility `.asc` semantics, deterministic mtimes, final ownership/modes, external SHA-256 tree manifest and sidecar, output-absence preflight, sibling temporary build/publication, root requirement for production, local-only behavior, and absence of package/Slackpkg/network/boot/reboot/persistent-configuration actions.

## Repository-only acceptance

The step-263 harness sources the builder only through `SLACK_UPDATE_LOCAL_SOURCE_V4_BUILDER_LIBRARY_ONLY=1`; production `main` is not entered. It also reconstructs the expected mechanical v4 derivative from the frozen v3-r1 source and requires an exact byte-for-byte match.

Synthetic checksum trees prove:

- valid untagged bindings pass;
- tagged bindings fail;
- a missing binding fails;
- a duplicate binding fails;
- binary-marker/malformed bindings fail;
- an extra binding fails.

These tests exercise checksum-library functions only and do not create `/var/tmp/slack-update-acceptance` output, require root, modify packages, invoke Slackpkg, access the network, or alter boot state.

## Authorization boundary

Step 263 marks the implementation `implementation-reviewed-not-frozen` and opens only repository-side `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-implementation-freeze`.

Production builder execution and the v4 build remain forbidden. Target observation, transport, predecessor staging, Slackpkg refresh/configuration, candidate binding, reference apply, runtime rerun, package mutation, external network, persistent configuration, boot/reboot, evidence cleanup, and Phase 2 remain closed.

`machine_action_required=false`, `controller_action_required=false`, `pause_safe=false`, and `strong_safe_pause=false`.
