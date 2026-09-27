# Phase 1 step 249 — local-source-v3 builder output remediation freeze and build authorization review

## Status

PASS. The accepted step-248 repository review is consumed, the corrected `local-source-v3` builder r1 is frozen at SHA-256 `80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30`, and exactly one bounded v3 build authorization is opened.

## Consumed prebuild observation

The step-247 observation remains the sole machine-state basis for this build. It reported `prebuild_v3_revalidation_status=PASS` on boot ID `fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9`, with package database manifest `726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6`, staged target SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`, preserved local-source-v2 manifest SHA-256 `e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945`, restored runtime baseline, preserved failed-remediation evidence, and absence of all v3 final and temporary outputs.

That observation is already consumed. No second probe invocation is authorized.

## Corrected builder freeze

The historical builder `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh` remains preserved at SHA-256 `56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582` and execution count zero.

The corrected builder `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh` is frozen at SHA-256 `80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30`. Repository review proved that its only byte-level semantic changes relative to the historical builder are the evidence-label substitutions `local_source_v2_build_status` → `local_source_v3_build_status` and `local_source_v2_root` → `local_source_v3_root`; synthetic renders remain manifest-identical.

## Single-use build authorization

Exactly one copy/transport of the corrected builder r1 is authorized, followed by exactly one root execution with `--build-local-source-v3`. The copied builder SHA-256 must be verified before execution.

The authorization is bound to boot ID `fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9`. Immediately before execution, the final paths `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3`, `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256`, and `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256.sha256`, plus all `.local-source-v3.build.*` temporary roots, must still be absent. The builder independently verifies the staged target SHA-256 before publication.

The authorization is consumed when the builder starts, even if it exits non-zero. A second execution is forbidden. On failure or partial output, preserve state and stop; do not retry, delete, repair, or rerun without a later explicit authorization.

A successful run must report `local_source_v3_build_status=PASS`, the exact `local_source_v3_root`, target identity, compatibility-marker presence, and the generated external tree-manifest SHA-256. Return the complete output for step 250 review.

## Closed boundaries

This step does not authorize package or Slackpkg mutation, repository refresh, external network, boot changes, reboot, evidence cleanup, runtime-executor-v2 implementation/transport, runtime rerun, or Phase 2. The future executor v2 remains `reviewed-frozen-not-implemented` until the exact accepted v3 manifest identity exists.

## Next gate

After one successful builder execution, the only next gate is `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-result-review-and-strong-safe-pause`.

`pause_safe=false` because one explicitly authorized machine action remains outstanding.
