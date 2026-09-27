# Phase 1 step 248 — local-source-v3 prebuild revalidation freeze and builder output-contract remediation review

## Status

PASS. The successful step-247 read-only observation is consumed and frozen, but no build authority is opened because repository review found an evidence-label defect in the previously frozen, never-executed v3 builder.

## Frozen step-247 observation

The accepted observation reported `prebuild_v3_revalidation_status=PASS` on boot ID `fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9`. It revalidated the restored package database manifest `726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6`, staged target SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`, preserved local-source-v2 tree-manifest SHA-256 `e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945`, restored Slackpkg/GenInitrd/boot fingerprints, failed remediation evidence, and continued absence of all local-source-v3 final and temporary outputs.

The observation is consumed by this step. It does not authorize another probe invocation.

## Builder output-contract defect

Repository review found that the frozen builder `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh` at SHA-256 `56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582` constructs the v3 tree correctly but ends by reporting two stale v2 evidence keys:

- `local_source_v2_build_status`
- `local_source_v2_root`

That builder has never been executed on the target and remains preserved unchanged as historical reviewed input.

A separate corrected builder is reviewed at `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build-r1.sh`, SHA-256 `80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30`. Its bytes differ from the original builder only by the two evidence-label substitutions:

- `local_source_v2_build_status` → `local_source_v3_build_status`
- `local_source_v2_root` → `local_source_v3_root`

The render, validation, publication, ownership, permissions, target SHA-256, `PGP` compatibility marker, manifest generation, and no-network/no-package/no-boot semantics are unchanged. Repository tests re-render the same synthetic input through both implementations and require identical tree manifests.

## Closed boundaries

This step authorizes only repository-side freeze/build-authorization review of the corrected builder. It does not authorize builder transport, builder execution, local-source-v3 construction, package or Slackpkg mutation, repository refresh, external network, boot action, reboot, executor-v2 implementation/transport, runtime rerun, evidence cleanup, or Phase 2.

## Next gate

The only next gate is `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-builder-output-remediation-freeze-and-build-authorization-review`.

`pause_safe=false`; no machine action is currently authorized or required.
