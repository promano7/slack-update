# Phase 1 kernel-package-edge target-artifact staging authorization review

Step 208 consumes the accepted step-207 staging review and grants one narrow machine-action authority: place the already authenticated target package bytes at the fixed VM transport path and execute the exact reviewed stager once. The stager remains byte-identical at SHA-256 `a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb`.

## Authorized bytes and transport

The only package authorized for this action is `kernel-headers-6.18.45-x86-1.txz`, frozen at SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`. The preserved controller evidence source is:

`/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts/kernel-headers-6.18.45-x86-1.txz`

That evidence root must remain unchanged. A byte-for-byte transport copy may be created and transferred to the VM only as `/home/promano/Descargas/kernel-headers-6.18.45-x86-1.txz`. The transport copy is not trusted by location; the stager validates its regular-file type, non-symlink status, filename, and frozen SHA-256 before any destination mutation.

## Single staging execution

After the reviewed stager itself is copied to the VM and verified as `a57303868eff7ee5ad8bb597d0dff52dec74887732fe590c40bae0edeb7d05eb`, the only authorized privileged execution is:

`sudo bash phase-1-kernel-package-edge-target-artifact-stage.sh --stage-target-artifact`

Before mutation, the stager revalidates the frozen step-202 runtime identity, kernel/package records, package-database manifest, and `slackpkg` fingerprints. It also requires the final acceptance root to be absent. It stages through a private temporary root, validates the copied artifact, promotes atomically, and leaves the staged artifact `root:root` mode `0444`. The transport copy is preserved.

This authority is effectively single-use: successful staging creates the acceptance root, so a repeat execution fails the preflight. Any runtime, transport, or stager-byte drift also invalidates the action and requires review rather than adaptation.

## Still forbidden

Builder execution and local-source construction remain forbidden. No repository refresh, package action, `slackpkg` configuration change, boot action, reboot, network acquisition, runtime scenario execution, or Phase 2 action is authorized.

The returned stager output must be reviewed before any further machine action. The only next stage is `phase-1-kernel-package-edge-local-source-construction-target-artifact-staging-result-review`. `pause_safe=false` because the construction chain is still active.
