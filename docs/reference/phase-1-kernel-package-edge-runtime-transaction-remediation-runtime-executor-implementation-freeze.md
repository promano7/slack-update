# Phase 1 step 238 kernel-package-edge runtime-transaction remediation runtime executor implementation freeze

Step 238 consumes the accepted step-237 repository-only implementation review and freezes the exact remediated executor generation. It re-runs the repository acceptance harness and rebuilds the canonical executor before freezing it, so runtime authorization review cannot rely on annotated hashes alone.

## Frozen implementation

The frozen implementation consists of:

- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-body.sh` with SHA-256 `ec25c18a03cb5bf267b755a2d9fb62f67f90e97f476bf9ffee6145414563ef3b`;
- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor-build.sh` with SHA-256 `a86ece6f7e7bb44fe928d9f24e8a9eb055202e71a44ccf7c3e42c4e610b8a379`;
- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh` with SHA-256 `9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c`;
- `tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-executor.sh` with SHA-256 `9fac7f4ad77454bcec6ec9f3cb4df09cb69be54dbdc6c38652d0c7b7d23f7652`.

The freeze rebuilds the executor from the frozen reference/config/body inputs and requires byte-for-byte equality with the canonical executor. It also reruns repository acceptance and requires `PASS (118 passes, 0 failures)`.

The historical failed body, builder, and executor remain immutable evidence at their previously frozen hashes. No historical runtime payload is rewritten or reclassified.

## Frozen remediation semantics

The target-specific, source-backed candidate guard remains frozen. The global `pkglist` row-count guard remains retired. A fresh transaction-owned Slackpkg `WORKDIR` remains mandatory, `error-downloading-from-local-source` remains a hard refresh failure, auxiliary metadata rows without backing source bytes remain non-candidates, and the exact target remains `kernel-headers-6.18.45-x86-1`.

Candidate binding remains valid only inside the same runtime transaction. Evidence remains real-tab TSV. The accepted local-source-v2 identity and fresh runtime identity from the preceding remediation chain are not reinterpreted by this freeze.

## Authorization boundary

Step 238 is repository-only. It does not authorize rebuilding for transport, copying the executor or predecessor to the VM, predecessor staging, temporary Slackpkg mutation, local metadata refresh, live candidate binding, reference apply, package action, external network access, boot action, reboot, evidence cleanup, or Phase 2.

The only next action opened by this step is the repository-only runtime authorization review for the exact frozen implementation. The next stage is `phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-review`. The remediation family remains active with `machine_action_required=false`, `controller_action_required=false`, `pause_safe=false`, and `strong_safe_pause=false`.

Frozen helper SHA-256: `d24b7d2b62a39878935bdc5a1983a368351937e63aa93ae79b8520039480a0a4`.
Frozen policy SHA-256: `8648917cc2ed5188a73d3d2f53d799d11680da224cf98135a28262b7def23e9d`.
Frozen record SHA-256: `e3194088051d95db4df7a6f806a0003db814086a4f66c835ea4fcc7bfe09c902`.
