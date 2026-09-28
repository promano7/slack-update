# Phase 1 step 254 — runtime executor-v2 implementation review

## Status

PASS. Step 254 implements and reviews the repository-only executor v2 defined by the frozen step-246 contract and bound by step 253 to the accepted `local-source-v3` identity. No target-machine action is performed or authorized by this step.

## Accepted implementation

The reviewed implementation consists of:

- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh`, SHA-256 `c5e8bce4802ecefdc72d975c269ece98fb3d7364c856665e64254b7fc9097a68`;
- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh`, SHA-256 `43c858e351d32c4ed2c28c687ccc9a06a1fc78f77032eaf20fb3d40a3ff197da`;
- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh`, SHA-256 `deb2d96c1590c176ae93f75cbf66161fe5a26f00401d9179f1082e3a1399f07d`;
- repository acceptance harness `tests/acceptance/reference/test-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh`, SHA-256 `86fcfd31ebe023d6fdfe3ec0c0c6bebaac3a17fd47202de43ffa3afe89854eef`, result `PASS (94 passes, 0 failures)`.

The builder reproduces the canonical executor byte-for-byte from the frozen reference script, configuration and reviewed body. The executor remains bound to fresh boot ID `047e744d-d2ea-4d9a-8746-7734b58db3b2`, staged target SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`, and accepted `local-source-v3` manifest SHA-256 `8a19d7f1c8b5b6f57ce92d9bd0b3c84523878b48bd2a82a4231c8cecd66aed8b`.

## Refresh and candidate contract

The v2 refresh path captures Slackpkg stdout and stderr and requires exit status zero, but exit zero is explicitly insufficient. Any occurrence of the exact human-spaced prefix `Error downloading from ` fails closed. The earlier synthetic hyphenated literal remains forbidden.

The transaction-owned Slackpkg `WORKDIR` must start without `pkglist`; a fresh regular `pkglist` must exist after that same refresh. Candidate binding then runs in the same runtime transaction and requires exactly one target-specific source-backed candidate while rejecting unexpected install-new, non-header and configured boot-package candidates.

The accepted `local-source-v3` tree is revalidated immediately before use, including exact manifest identity and coverage, immutable ownership/modes, target bytes, priority-tree metadata, the exact `PGP compatibility marker for Slackpkg checkchangelog only.` marker and absence of an OpenPGP signature block.

## Preservation and rollback

The failed remediation executor generation remains immutable at its accepted hashes. Historical `local-source-v2` remains preserved and verified at manifest SHA-256 `e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945`, including its historical no-`PGP` state. Failed remediation evidence remains preserved, including the human-spaced Slackpkg failure, while its absent `pkglist` and absent success result remain required.

The v2 executor uses a new evidence root `/var/tmp/slack-update-acceptance/kernel-package-edge/runtime-transaction-remediation-v2` and a distinct publication path `/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-v2-evidence.tar.gz`; it therefore cannot overwrite the failed remediation evidence or its historical publication path.

Post-mutation failures remain rollback-protected. Slackpkg configuration/state and GenInitrd policy must be restored, boot artifacts must remain unchanged, the target header must return to the frozen target, external network remains forbidden and no reboot is performed.

## Authorization boundary

Step 254 authorizes only the repository-side implementation freeze review that follows. It does not authorize executor transport, candidate binding on the target, runtime execution, package/Slackpkg mutation, repository refresh, external network, boot/reboot, evidence cleanup, persistent configuration changes, or Phase 2.

## Next stage

The next stage is `phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-v2-implementation-freeze`. `machine_action_required=false`, `controller_action_required=false`, and `pause_safe=false`.
