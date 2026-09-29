# Phase 1 step 260 — empty-pkglist root-cause freeze and local-source-v4 boundary review

## Status

PASS. Step 260 consumes the repository-only continuation opened by step 259, accepts the frozen empty-`pkglist` cause, and defines the exact functional boundary for a new `local-source-v4`. It performs no target observation or mutation and grants no builder implementation or build authority.

## Accepted root cause

The step-259 finding is accepted without modification: the accepted `local-source-v3` writes `CHECKSUMS.md5` in GNU tagged MD5 form. Those package lines end in the digest rather than the package filename, so they fail Slackpkg's terminal package-extension filter before `pkglist.awk` can consume the final field as the package path. With only one package in v3, the resulting transaction-owned `pkglist` contains zero package rows.

The failure class remains `slackpkg-incompatible-tagged-checksums-md5-package-line-format`. Candidate matching remains non-causal, the zero-byte `pkglist` remains exact evidence, and executor-v2 remains forbidden from rerun.

## Local-source-v4 functional boundary

`local-source-v4` must be derived from the accepted v3 behavior and invariants. The functional remediation is intentionally narrow: change the `CHECKSUMS.md5` record representation from GNU tagged output to ordinary GNU untagged `md5sum` output for every checksum-covered regular file.

Required representation:

`<32-hex-md5>  ./relative/path`

For the target package, the path must be the final whitespace-delimited field and the line must end in `kernel-headers-6.18.45-x86-1.txz`, allowing Slackpkg's package-line filter and `pkglist.awk` path extraction to operate normally. GNU tagged records beginning with `MD5 (` are forbidden in v4.

The v4 validator must prove that every eligible generated regular file has exactly the required untagged binding and must reject missing, duplicate, malformed, or tagged bindings.

## Preserved invariants

The target remains `kernel-headers-6.18.45-x86-1.txz` with SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c` at `slackware64/d/kernel-headers-6.18.45-x86-1.txz`. The predecessor `kernel-headers-6.18.44-x86-1.txz` remains absent and the generated source must continue to expose exactly one package archive.

The package location remains `./slackware64/d`; top-level and `slackware64/PACKAGES.TXT` target stanzas remain equivalent; priority-tree package exposure remains unchanged; `FILELIST.TXT` continues to enumerate the generated regular files; generated mtimes remain deterministic.

`CHECKSUMS.md5.asc` must retain the compatibility `PGP` marker required by the installed Slackpkg gate while remaining explicitly non-cryptographic. Package authenticity remains anchored in the frozen target SHA-256 and the external tree-manifest binding, not in the compatibility `.asc` file.

The builder remains local-only, fail-closed, and unable to perform network access, package action, Slackpkg mutation, persistent configuration change, boot action, or reboot. Output paths must be absent before a production build.

## Revision identity

The new revision uses:

- local source root `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4`;
- external manifest `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256`;
- manifest checksum `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v4.tree.sha256.sha256`;
- production switch `--build-local-source-v4`.

The v3-to-v4 builder filename, usage text, output paths, revision labels in generated descriptive metadata, and validation logic needed to enforce the corrected checksum representation are permitted revision-identity changes. They are not authorization to broaden the functional behavior.

## Forbidden scope expansion

The v4 design must not change target package bytes or SHA-256, add the predecessor or any additional package archive, change package selection/location, weaken output-path or tree-safety checks, add external network access, or introduce package/Slackpkg/boot/reboot/persistent-configuration mutation. Accepted v3 artifacts, the accepted v3 builder, and the failed executor-v2 evidence remain immutable historical evidence.

## Continuation prerequisites

Before any v4 build can be authorized, the repository must complete an explicit v4 builder design review, design freeze, implementation review, and implementation freeze. A fresh target revalidation must then prove the target state and absence of all v4 output paths before a single-use build authority is opened. Returned build evidence must be reviewed before runtime work resumes.

Step 260 opens only the repository-side `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-builder-design-review`. It grants no machine or controller action.

## Authority

Target observation, probe transport, v4 builder implementation/build, executor build/transport, predecessor transport/staging, temporary Slackpkg configuration, local-source metadata refresh, repository refresh, candidate binding, reference apply, runtime execution/rerun, package action, Slackpkg mutation, external network, persistent configuration change, boot action, reboot, evidence cleanup, and Phase 2 remain forbidden.

`machine_action_required=false`, `controller_action_required=false`, `pause_safe=false`, and `strong_safe_pause=false` because the repository-only remediation chain remains open.
