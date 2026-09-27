# Phase 1 step 222 kernel-package-edge runtime transaction remediation fresh target revalidation review

Step 222 consumes the accepted step-221 repository-only resume-planning boundary and opens exactly one bounded read-only observation of the Slackware-current validation VM. This is the first machine gate after the step-220 strong safe pause. No earlier runtime, target, or candidate authorization is revived.

## Historical baseline only

The accepted post-build target identity from step 213, the step-217 final-state contract, and the step-219 contained-failure characterization are used only as historical evidence for the state that must still be observed. The old boot ID is intentionally not embedded in the new probe and is not reusable as a binding.

A successful observation must report a fresh boot ID while confirming the expected target identity: `vbox-slackcurrent.vbox-slackcurrent.org`, architecture `x86_64`, running kernel `6.18.45`, Slackware release `Slackware 15.0+`, package database manifest `726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6`, `kernel-headers-6.18.45-x86-1`, `kernel-generic-6.18.45-x86_64-1`, and absence of `kernel-huge` and `kernel-modules`.

The accepted Slackpkg configuration fingerprints remain `f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4` for `slackpkg.conf` and `71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12` for `mirrors`.

## Preserved failure and local-source evidence

The observation also verifies that the staged 6.18.45 target still hashes to `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c` and that `local-source` v1 still verifies against tree-manifest SHA-256 `0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e`. The v1 tree must still lack `CHECKSUMS.md5.asc`; it is historical evidence and must not be remediated in place.

The failed runtime evidence root must remain present. The probe reuses the accepted failed-run preflight fingerprints only to prove that `/boot`, the restored Slackpkg state, and the GenInitrd policy still match the contained-failure baseline. It also requires the failed run to remain without `result.tsv` and without a published success archive or checksum.

## Standalone read-only probe

The only authorized target probe is `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-review-probe.sh`. It is standalone and does not require the Git repository on the VM. The exact probe bytes must be copied to the target, verified by SHA-256, and invoked once with `--observe-fresh-target-revalidation` through `sudo`.

The probe performs reads and hashing only. It performs no Slackpkg refresh, network access, package mutation, repository mutation, boot action, reboot, persistent configuration change, evidence cleanup, `local-source-v2` creation, or runtime rerun. Any drift fails closed and must be reviewed before remediation design proceeds.

## Authorization boundary

Step 222 authorizes only transport of the exact probe and one read-only observation. After a successful returned observation, only the repository-side fresh-target revalidation freeze is authorized. `local-source-v2` design and build remain closed, as do all package, Slackpkg, runtime, network, boot, reboot, evidence-cleanup, and Phase 2 actions.

`machine_action_required=true` and `controller_action_required=true`. The chain remains active, so `pause_safe=false`. The next stage is `phase-1-kernel-package-edge-runtime-transaction-remediation-fresh-target-revalidation-freeze`.
