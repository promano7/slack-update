# Phase 1 kernel-package-edge target-artifact staging review

Step 207 consumes the frozen builder implementation from step 206 and reviews the exact boundary for staging the frozen target package on `vbox-slackcurrent`. It performs no machine action and does not yet authorize the stager.

The transport copy is fixed at `/home/promano/Descargas/kernel-headers-6.18.45-x86-1.txz`. It is explicitly **not** an authenticity source: authenticity remains the frozen step-197 package/signature binding, and the transport copy must independently match SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`. The transport file must be a regular non-symlink and is preserved after staging.

The reviewed stager is `tools/reference/phase-1-kernel-package-edge-target-artifact-stage.sh` with SHA-256 `a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb`. Production execution accepts only `--stage-target-artifact`, requires root via sudo, and revalidates the frozen target identity before creating anything: FQDN, running 6.18.45 kernel, x86_64 architecture, Slackware version, boot ID `d767c4ed-b21f-4c6f-9a1e-db7948c285cf`, package-database manifest `726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6`, kernel package records, and `slackpkg` fingerprints.

The final acceptance root must not preexist. Staging is built below a stager-owned temporary sibling and promoted only after the copied artifact verifies. The final staged package is `/var/tmp/slack-update-acceptance/kernel-package-edge/staging-input/kernel-headers-6.18.45-x86-1.txz`, owned `root:root`, mode `0444`, with the frozen SHA-256. Unexpected preexisting acceptance state fails closed and is never overwritten.

The stager performs no network access, repository refresh, package action, `slackpkg` configuration change, builder execution, local-source build, boot action, or reboot. `SLACK_UPDATE_TARGET_ARTIFACT_STAGER_LIBRARY_ONLY=1` exists only for repository harness testing and does not make production paths overridable.

This review does **not** authorize copying or staging the artifact on the VM. The only next stage is `phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-authorization-review`, which may freeze the exact stager and open one bounded machine action if this review is accepted. `pause_safe=false`.
