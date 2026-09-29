# Phase 1 step 267 — local-source-v4 build-authorization freeze

## Result

`PASS` — the step-266 single-build contract is frozen and **exactly one** `local-source-v4` build attempt is authorized.

## Frozen execution identities

- builder: `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh`
- builder SHA-256: `38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7`
- executor: `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-authorization-freeze-executor.sh`
- executor SHA-256: `f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985`
- authorization boot ID: `d34855ae-e039-4005-a842-1bef51082195`
- authorization use count: `1`

The builder and executor may be copied together to the already-bound Slackware-current VM. Their SHA-256 values must be verified before execution.

## Single authorized machine action

Run the executor once through `sudo` with `--execute-authorized-local-source-v4-build`. The executor must immediately revalidate the exact boot ID, host/kernel/Slackware identity, package-database manifest, installed target records, Slackpkg configuration fingerprints, staged target SHA-256, accepted local-source-v3 tree, preserved failed-v2 evidence, absence of every final v4 output and absence of temporary v4 build roots. It also verifies the exact builder SHA-256 before invoking it.

If any precondition differs, the executor must stop before the builder runs. If the builder succeeds, the expected outputs are the v4 root and its tree-manifest pair. The complete executor output must be returned for step-268 result review.

## Closed actions

This authorization does **not** allow Slackpkg/repository refresh, package mutation, network access, persistent configuration changes, boot mutation, reboot, evidence cleanup, runtime remediation rerun, or Phase 2 work.

There is no authorized second execution. If this single attempt fails for any reason, do not rerun it; return the complete output for review.

`strong_safe_pause=false`. Next stage: `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-result-review-and-strong-safe-pause`.
