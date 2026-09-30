# Phase 1 step 278 — local-source-v4 launch-remediation build-authorization freeze

## Frozen result and identities

PASS. Consume accepted step 277 (`d19a209`), requiring its complete
112-pass repository acceptance again. Freeze the reviewed contract and grant
exactly one local-source-v4 build attempt through the immutable new executor.
The repository helper itself performs no live observation or production action.

- Executor: `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh`
- Executor SHA-256: `43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d`
- Builder: `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh`
- Builder SHA-256: `38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7`
- Fresh authorization boot ID: `79a19518-0d0a-4c57-ac1f-679a39edefbd`
- Attempt limit: `1`, including an invocation rejected by preflight.

The complete 41-field step-276 observation remains frozen at normalized SHA-256
2f049ae8ef6f8780a453f86a536f0585ebc8a3fc1955f367202a11da130a2fef.
Its display-transcription provenance and repository-only builder-SHA context
remain unchanged. Probe authority is already consumed; no probe rerun is granted.
The new build authority is distinct from that consumed observation authority and
from the historical step-267 build authority. Historical records remain immutable.

## Controller procedure

Apply the overlay, pass repository acceptance, commit step 278 and require a clean
repository tree before transport. Copy only the two exact artifacts together to
`vbox-slackcurrent.vbox-slackcurrent.org`; confirm both are regular non-symlink
files and verify both SHA-256 values before invoking the executor once through
`sudo bash --`. Supply exactly these arguments:

```text
--execute-authorized-local-source-v4-build-v2 --authorization-boot-id 79a19518-0d0a-4c57-ac1f-679a39edefbd
```

The executor must repeat every frozen preflight/output-absence guard immediately
before its single verified `bash -- "$builder" --build-local-source-v4` launch.
Require the same boot ID, host/architecture/running-kernel/Slackware identity,
canonical package database and compatibility symlink, complete package manifest,
installed header/generic records, no huge/modules records, unchanged Slackpkg
configuration/state, staged target SHA-256, accepted v3 tree/sidecar, preserved
failed-v2 evidence, boot/GenInitrd fingerprints, and absence of all v4 final and
temporary outputs. Require exact regular-file builder SHA at preflight and launch.
Any drift stops before launch; never replace the boot argument to bypass it.

Transport does not require an executable bit. Manual chmod remediation, manual
builder launch, the old executor, consumed authorizations, automatic/manual
retries, and manual evidence/output cleanup remain forbidden. A transport or
SHA-verification failure stops the procedure for repository review. Executor
invocation consumes the one-attempt authority even on preflight rejection,
builder failure, or interruption. No persistent marker is added; the accepted
controller protocol enforces single use. Preserve complete stdout/stderr and the
exit status for review. Do not infer remaining authority from absence of a PASS.

## Permitted effects and closed actions

Limit production writes to the v4 root, its tree-manifest pair, and existing
builder-owned `.local-source-v4.build.*` construction/cleanup. Preserve the
unchanged builder's source finalization and temporary cleanup contract; this
allows no manual chmod or broad cleanup remediation.

No package action, Slackpkg/repository refresh or configuration/state mutation,
network access, persistent configuration change, boot action, reboot, evidence
cleanup, target observation, runtime executor rerun, or Phase 2 is authorized.
Accepted v3, failed-v2 evidence, the failed step-267 executor and historical
builder/executor identities remain unchanged.

## Result review and strong safe pause

On success, return complete output and exit status for
`phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-result-review-and-strong-safe-pause`.
On any failure or interruption, stop and return complete available output for
`phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-build-failure-result-review`; do not retry.
Both result routes must review the actual boundary and revoke remaining build
and transport authority before declaring a strong safe pause. Success is not
preclaimed. A later runtime continuation requires fresh target revalidation and
new explicit authorization; the old live-state binding cannot authorize it.

`machine_action_required=true`, `controller_action_required=true`,
`pause_safe=false`, `strong_safe_pause=false` while the one attempt/result review
is pending.
