# Phase 1 step 245: kernel-package-edge runtime-transaction second remediation implementation-contract review

Step 245 consumes the frozen step-244 second-remediation design and reviews a
concrete repository implementation for the new `local-source-v3` builder. It
also freezes the exact contract that the future runtime executor v2 must obey,
but deliberately does **not** implement that executor yet because its source
must be bound to the exact accepted v3 tree-manifest identity after the v3
build.

## Reviewed local-source-v3 builder

The reviewed builder is `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh` at SHA-256
`56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582`. Its production acknowledgement is
`--build-local-source-v3`; repository tests may source pure functions only
through `SLACK_UPDATE_LOCAL_SOURCE_V3_BUILDER_LIBRARY_ONLY=1`.

The builder consumes only the frozen staged
`kernel-headers-6.18.45-x86-1.txz` at SHA-256
`c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`.
It publishes a new, previously absent
`/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3` plus its
external v3 tree manifest and manifest sidecar. It does not mutate
`local-source-v2`, the failed executor generation, or prior runtime evidence.

The package layout remains the frozen five-tree Slackpkg priority layout:
`patches`, `slackware64`, `extra`, `pasture`, and `testing`. Exactly one package
archive is exposed, at `slackware64/d/kernel-headers-6.18.45-x86-1.txz`; the
6.18.44 predecessor remains absent.

The v3 `CHECKSUMS.md5.asc` is intentionally a compatibility artifact, not a
signature. It must contain the exact line:

`PGP compatibility marker for Slackpkg checkchangelog only.`

It must also state that no cryptographic authenticity claim is made and it
must never contain `BEGIN PGP SIGNATURE`. Package authenticity continues to be
bound by the frozen target SHA-256 and the external v3 SHA-256 tree manifest.
Generated mtimes are normalized to epoch zero and publication remains
fail-closed through a builder-owned temporary sibling followed by validated
publication into absent final paths.

## Future executor-v2 contract

The future executor generation is reserved at:

- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh`
- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh`
- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh`

Those files are **not implemented by step 245**. Their implementation must
wait until the v3 build result has been accepted, because the executor must
bind the exact accepted v3 manifest SHA-256 rather than a predicted identity.
The runtime acknowledgement will be
`--execute-runtime-remediation-v2-validation`.

The future refresh logic must satisfy all independent guards: Slackpkg exit
status zero; captured stdout/stderr containing no literal human-spaced
`Error downloading from ` prefix; a fresh regular transaction-owned `pkglist`
in the isolated `WORKDIR`; and the already accepted target-specific candidate
guard in the same transaction. The old hyphenated-literal error guard is
forbidden.

All established invariants remain unchanged: transaction-owned `WORKDIR` and
`TEMP`, no external network, exact predecessor and target bytes, header-only
staging, rollback after any post-mutation failure, restored Slackpkg and
GenInitrd state, unchanged boot artifacts, real-tab TSV evidence, and no
reboot.

## Repository-only verification

The step-245 harness exercises the v3 builder through its library seam using a
synthetic kernel-headers package. It proves deterministic rendering, exact
five-tree layout, a single target archive, predecessor absence, complete
FILELIST and checksum metadata, the exact PGP compatibility marker, absence of
an OpenPGP signature block, deterministic external tree manifests, and
fail-closed rejection of pre-existing v3 output paths.

No production v3 build, target observation, package action, Slackpkg mutation,
network access, boot action, reboot, runtime executor transport, or runtime
rerun is authorized or performed here.

## Authorization boundary

The only opened next stage is repository-side implementation-contract freeze:
`phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-freeze`. Builder execution and every machine-side action remain closed.

`machine_action_required=false`, `controller_action_required=false`, and
`pause_safe=false`.
