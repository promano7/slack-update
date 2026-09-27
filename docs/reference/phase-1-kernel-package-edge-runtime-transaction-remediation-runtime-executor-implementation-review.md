# Phase 1 step 237 kernel-package-edge runtime-transaction remediation runtime executor implementation review

Step 237 consumes the accepted step-236 repository-only executor remediation design and reviews a new executor generation. The historical failed executor generation remains unchanged evidence and is not edited in place.

## Reviewed implementation

The remediated implementation consists of:

- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh` with SHA-256 `ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b`;
- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh` with SHA-256 `a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379`;
- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh` with SHA-256 `9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c`;
- `tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-executor.sh` with SHA-256 `9fac7f4ad77454bcec6ec9f3cb4df09cb69be54dbdc6c38652d0c7b7d23f7652`.

The repository acceptance result is `PASS (118 passes, 0 failures)`. The builder reproduces the canonical executor byte-for-byte and the canonical executor embeds the exact frozen reference script and effective configuration.

The historical failed body, builder, and executor remain frozen respectively at `47fc2b067ac361562fc2921bf6df5b66bc4054456cea88297b9a53fb96514581`, `348301a0d421d0e0a12ee48a33b843a1b0a7b7434ea02399964d63e716a57eea`, and `09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300`.

## Slackpkg isolation and refresh remediation

The new executor uses the accepted `local-source-v2` only. It derives a temporary Slackpkg configuration that points `WORKDIR` to the transaction-owned `runtime-transaction-remediation/slackpkg-workdir`, points `TEMP` to the transaction-owned cache, and uses `CHECKGPG=off` only for the already accepted local compatibility role of `CHECKSUMS.md5.asc`.

The transaction workdir must start empty and its `pkglist` must be absent before refresh. The local-source-v2 tree, sidecar, exact manifest coverage, priority-tree metadata, compatibility `.asc`, and target bytes are revalidated immediately before the refresh. The refresh runs under a disabled network namespace and is accepted only when its exit status is zero, its captured output contains no `error-downloading-from-local-source`, and a fresh regular `pkglist` appears in the transaction workdir. `/var/lib/slackpkg/pkglist` is not used as refresh evidence or candidate-binding input.

## Target-specific candidate binding

The historical global `pkglist` row-count guard remains retired. The remediated parser reads Slackpkg `pkglist` rows using an explicit space field separator and validates the target fields independently: priority tree `slackware64`, package `kernel-headers`, version `6.18.45`, architecture `x86`, build `1`, fullname `kernel-headers-6.18.45-x86-1`, location `./slackware64/d`, and extension `txz`.

Auxiliary `pkglist` rows are not themselves candidates. A non-target row is classified as an unexpected candidate only when its package path resolves to a real regular non-symlink package file inside the frozen local-source-v2 tree. This preserves the step-234 rule that auxiliary metadata rows are not a failure while still failing closed on any unexpected package bytes exposed by the source.

The accepted candidate set is therefore exactly one frozen target candidate, zero unexpected `kernel-headers` candidates, zero install-new candidates, zero non-header upgrade candidates, and zero configured boot-package upgrade candidates. The binding remains valid only in the same runtime transaction and is consumed without a pause by the reference apply or rollback path.

The repository acceptance harness includes synthetic candidate-binding coverage. It proves that an auxiliary `pkglist` row without backing v2 package bytes does not invalidate the target binding and that an unexpected source-backed package is rejected.

## Evidence and preservation remediation

The new executor uses real tab characters through `record_kv` for preflight, refresh, candidate-binding, and result TSV evidence. The historical failed evidence root and local-source v1 are required before execution and are rechecked at the final invariant gate. The old failed success archive remains absent.

The existing transaction semantics remain unchanged: stage only the frozen 6.18.44 header predecessor, require a header-only package delta and unchanged boot state, execute the frozen reference apply without external network interfaces, restore Slackpkg configuration/state and GenInitrd policy, restore the accepted 6.18.45 header baseline on rollback, forbid reboot and boot mutation, and publish success evidence only after all final invariants pass.

## Authorization boundary

Step 237 is repository-only. It does not authorize building a transport artifact for the VM, transporting or executing the canonical executor, transporting or staging the predecessor package, modifying Slackpkg, refreshing metadata on the VM, binding a live candidate set, running the reference apply, performing package actions, accessing external networks, changing boot state, rebooting, deleting evidence, or starting Phase 2.

The only next action opened by this step is repository-side freeze of the reviewed implementation. The next stage is `phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-implementation-freeze`. The remediation family remains active with `machine_action_required=false`, `controller_action_required=false`, `pause_safe=false`, and `strong_safe_pause=false`.

Frozen helper SHA-256: `4e11c6176988331cc9e2a21e4297857b3345573bc24f3b60a4db642996b65883`.
Frozen policy SHA-256: `75b19adf4c35d1a3f12106388e10e1d5a36b4809a66c8a11c72d90784b878162`.
Frozen record SHA-256: `2f08b3896171cd4a8da74fe910cf4bd0c4b74b690cbdba388a08376f09d05ea8`.
