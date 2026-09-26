# Phase 1 step 212 kernel-package-edge post-local-source-build revalidation review

Step 212 consumes the accepted step-211 fresh planning boundary and opens one narrow machine gate: a standalone, read-only revalidation of the Slackware-current target plus the preserved staged target and local-source tree. No package mutation, repository refresh, network access, boot action, reboot, builder rerun, or runtime scenario execution is authorized.

## Fresh target observation

The historical step-202 binding remains expired. The probe records a fresh boot ID but does not require it to differ from the earlier boot ID. It requires the live target to remain compatible with the accepted post-build baseline: FQDN `vbox-slackcurrent.vbox-slackcurrent.org`, `x86_64`, running kernel `6.18.45`, Slackware `15.0+`, package-database manifest `726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6`, exactly `kernel-headers-6.18.45-x86-1` and `kernel-generic-6.18.45-x86_64-1`, no `kernel-huge` or `kernel-modules`, and the accepted Slackpkg configuration fingerprints.

## Preserved artifact and local-source verification

The probe also verifies the staged target at `/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz` against SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`, owner `root:root`, and mode `0444`.

The completed local source at `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source` must still verify against external manifest `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source.tree.sha256`, whose frozen SHA-256 is `0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e`. The sidecar manifest checksum must verify, all source directories/files must retain the builder's read-only `root:root` modes, the source must expose exactly one `.txz` candidate, and the 6.18.44 predecessor must remain absent from that source.

## Standalone probe and authorization

The exact probe is `tools/reference/phase-1-kernel-package-edge-post-local-source-build-revalidation-probe.sh`, SHA-256 `44a68d5e63b873c5df836cccb4ffa525852e45a15fda0b332a7ee6ef56899383`. It is self-contained and does not require the repository on the VM. It may be transported as a script copy and executed only as:

`sudo bash phase-1-kernel-package-edge-post-local-source-build-revalidation-probe.sh --observe-post-build-revalidation`

A successful result begins with `revalidation_status<TAB>PASS`. The complete output must be returned for step 213. Success does not bind a runtime candidate set and does not authorize predecessor staging or any package operation. Any drift fails closed.

Step 212 therefore requires a machine/controller action and is not a safe-pause checkpoint. Its only continuation is `phase-1-kernel-package-edge-post-local-source-build-revalidation-freeze`.
