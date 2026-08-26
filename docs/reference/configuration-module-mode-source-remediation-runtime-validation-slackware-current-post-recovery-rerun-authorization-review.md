# Phase 1 step 146 — Slackware-current post-recovery rerun authorization review

Step 146 grants a fresh, single-use authorization for one non-mutating
Slackware-current runtime-validation rerun after the accepted step-145
boot-selection recovery review. Step 146 itself is repository-only and performs
no machine action.

## Accepted recovery boundary

The authorization is bound to the exact step-145 manual-review policy SHA-256
`f0976658c0c1a9ffbdb21bc3ec7a6f9157204f7642469488f515d136ff983e90`
and record SHA-256
`4dd611a3fdb2f35724ba5ad4da3305d6ac8c26889baa346ee838d51662bb1bc3`.
That review established that the frozen boot-selection mismatch is resolved,
the recovered live `root=` token is `/dev/sda2`, the mounted root remains
`/dev/sda2`, kernel `6.18.45` and `/boot/vmlinuz-generic` are preserved, and the
runtime probe has not yet been invoked after recovery.

The old step-139 rerun authorization and the step-143 reboot authorization are
both consumed and explicitly non-reusable. Step 146 creates a distinct
authorization identity: `runtime-slackware-current-post-recovery-rerun`.

## Fresh execution boundary

Exactly one future execution is authorized on
`vbox-slackcurrent.vbox-slackcurrent.org`. It must run the frozen harness
`tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun.sh`.
The harness is bound to the accepted remediated source SHA-256
`aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7`,
the unchanged configuration template SHA-256
`4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba`,
the step-145 review, and the preserved step-132 target binding.

Before invoking the runtime probe, the harness must independently prove:

- Slackware-current on the exact bound VM;
- UEFI firmware and running kernel `6.18.45`;
- `BOOT_IMAGE=/boot/vmlinuz-generic`;
- exactly one live root token, `root=/dev/sda2`;
- mounted root `/dev/sda2`;
- `/boot/vmlinuz-generic` resolving to the running kernel;
- no `/etc/mkinitrd.conf` and no `/boot/initrd.gz`;
- a syntactically valid GRUB configuration;
- the dedicated direct-generic entry with one generic `linux` command and no
  `initrd` command.

Any characterization mismatch is a hard stop and withholds the runtime probe.
If characterization passes, the harness invokes only configuration loading and
`probe_boot_module` from the accepted source. The expected verdict is
`boot=auto`, `available`, runnable, and
`direct-generic-no-initrd`, with GRUB and the direct-generic path available and
no initrd available.

The execution permits only evidence-workspace mutation under
`/var/tmp/slack-update-acceptance`. It forbids repository refresh, package
mutation, boot mutation, source or configuration changes, and reboot. Package,
Slackpkg metadata, boot state, source, and template snapshots are compared
before and after the probe.

Slackware 15.0 remains held and unauthorized until the post-recovery rerun
evidence is reviewed.

## Safe-pause boundary

`pause_safe=true`. Step 146 is independent of later Slackware-current
publications because neither repository refresh nor package mutation is
required or authorized. If the VM changes while paused, the execution harness
fails closed before the probe.

The only next stage is
`phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-post-recovery-rerun-execution`.
No older authorization may be used for that execution.
