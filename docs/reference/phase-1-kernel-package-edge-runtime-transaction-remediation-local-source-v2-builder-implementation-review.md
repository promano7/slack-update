# Phase 1 step 226: kernel-package-edge runtime-transaction remediation local-source-v2 builder implementation review

Step 226 implements the repository-side `local-source-v2` builder against the exact design frozen at step 225. The implementation is reviewed without executing its production path and without inheriting any target-machine authority from the historical frozen runtime identity.

## Reviewed builder implementation

The reviewed builder is `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-build.sh` at SHA-256 `8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d`. Production execution requires the explicit `--build-local-source-v2` acknowledgement and root privileges. The repository harness uses only `SLACK_UPDATE_LOCAL_SOURCE_V2_BUILDER_LIBRARY_ONLY=1` to source and exercise pure builder functions; this seam does not make production paths overridable.

The implementation consumes only the frozen staged `kernel-headers-6.18.45-x86-1.txz` at SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`. It publishes only `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2` and its v2 external manifest files, leaving `local-source-v1`, the failed-runtime evidence, and the staged target untouched.

The builder creates the target package at `slackware64/d/kernel-headers-6.18.45-x86-1.txz`, top-level deterministic metadata, and `PACKAGES.TXT` for `patches`, `slackware64`, `extra`, `pasture`, and `testing`. Only the top-level and `slackware64` indexes contain the single frozen target stanza. The other priority indexes contain no package stanza. `CHECKSUMS.md5.asc` is generated as an explicit compatibility artifact with no cryptographic-authenticity claim.

`FILELIST.TXT` enumerates the complete generated regular-file tree. `CHECKSUMS.md5` binds every generated regular file except itself and the compatibility `.asc`; package authenticity remains anchored in the frozen target SHA-256 and the external v2 SHA-256 tree manifest. Generated mtimes are normalized to epoch zero. Final publication remains fail-closed: v2 final paths must not pre-exist, construction occurs in a builder-owned temporary sibling, validation precedes publication, and the final tree is root-owned and read-only.

## Repository-only verification

The step-226 harness builds a synthetic `kernel-headers` package and exercises the builder functions without invoking production `main`. It verifies exact target SHA guards, symlink rejection, deterministic v2 rendering, the five priority indexes, one and only one package archive, predecessor absence, complete `FILELIST.TXT`, bounded compatibility `.asc`, deterministic MD5 metadata, external SHA-256 manifest verification, and rejection of pre-existing final output paths.

No Slackpkg command, package mutation, network client, boot action, reboot, or target-machine execution is authorized or performed by this review.

## Authorization boundary

This step authorizes only the repository-side implementation freeze next. Builder execution, target observation, construction of `local-source-v2`, Slackpkg refresh, candidate binding, executor remediation/rerun, package/network/boot action, reboot, evidence cleanup, and Phase 2 remain closed. Before any later builder execution, the target identity must be freshly revalidated and explicit runtime authorization must be issued.

Next stage: `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-builder-implementation-freeze`. The remediation chain remains active, so `pause_safe=false`.
