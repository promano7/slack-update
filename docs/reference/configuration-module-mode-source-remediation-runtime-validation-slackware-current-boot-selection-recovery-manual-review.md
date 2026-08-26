# Slackware-current boot-selection recovery manual review

Phase 1 step 145 authenticates and reviews the completed step-144
selection-only recovery. It is repository-only and performs no machine action.

## Authenticated recovery evidence

The accepted pre-reboot archive is
`slackware-current-configuration-module-mode-source-remediation-runtime-validation-boot-selection-recovery-pre-20260826T153424Z.tar.gz`
with SHA-256
`7779072439d48eaace4b3a5b468647887fe89ca173eb78b1cdb0cb5876d9f60f`.
Its handoff marker has SHA-256
`9d3a00371ef60a1bcd0a399feba31004a98ba807fbd6445de574bd94f9a48cd7`.

The accepted post-reboot archive is
`slackware-current-configuration-module-mode-source-remediation-runtime-validation-boot-selection-recovery-post-20260826T153841Z.tar.gz`
with SHA-256
`0356cb5ac64e8a560b132c61d0c9df3228de1a74af2cd32fef9323850c4b5eb9`.
The post-reboot harness completed with 24 passes, zero failures, and zero skips.

## Recovery result

Before recovery, the running session used
`BOOT_IMAGE=/boot/vmlinuz-generic root=UUID=d1a09d24-cdbf-41cd-8cd6-2faff4d72863 ro`.
After the single authorized manual reboot and interactive selection of
`Slackware-current slack-update direct generic (no initrd)`, the recovered
session uses exactly:

    BOOT_IMAGE=/boot/vmlinuz-generic root=/dev/sda2 ro

The running kernel remains `6.18.45`, `/` remains mounted from `/dev/sda2`, and
`/boot/vmlinuz-generic` still resolves to `/boot/vmlinuz-6.18.45`. The exact
existing GRUB entry remains `linux /boot/vmlinuz-generic root=/dev/sda2 ro`
without an initrd command.

The original `frozen-boot-selection-mismatch` is therefore resolved. The
recovery changed only the selected boot path for this boot; it did not mutate
persistent GRUB configuration.

Package state, Slackpkg metadata, `grub.cfg`, the dedicated GRUB script,
`grubenv`, `/etc/default/grub`, accepted source, and configuration template all
retain their frozen identities. The step-143 recovery authorization was
consumed by the single reboot and is not reusable.

## Runtime-remediation state

The recovery deliberately did not invoke the runtime probe. Consequently, the
step-137 source remediation remains neither exercised nor rejected. A fresh
Slackware-current rerun authorization must be reviewed before the runtime probe
may be attempted again. Neither the consumed step-139 rerun authorization nor
the consumed step-143 recovery authorization may be reused.

Step 145 grants no runtime probe, rerun, reboot, repository refresh, package
mutation, boot mutation, source/template/contract change, or Slackware 15.0
execution. Slackware 15.0 remains held and unauthorized.

The next stage is the repository-only Slackware-current rerun authorization
review. No repository refresh is required, the checkpoint is independent of
later Slackware-current publications, and `pause_safe=true`.
