# Phase 1 Slackware-current boot-selection drift remediation design

Step 142 designs the smallest recovery for the `frozen-boot-selection-mismatch`
accepted by step 141. The authenticated step-140 evidence proves that `/` still
resolves to `/dev/sda2`, the generic-kernel symlink still resolves to kernel
`6.18.45`, and the dedicated GRUB entry remains unchanged, but the running
kernel command line contains
`root=UUID=d1a09d24-cdbf-41cd-8cd6-2faff4d72863` instead of the frozen
`root=/dev/sda2` token.

This is a repository-only design boundary. It does not modify the reference
implementation, configuration template, GRUB configuration, GRUB environment,
packages, repositories, boot files, or either validation machine.

## Designed recovery

The recovery is selection-only. A later separately authorized machine action
may perform one reboot of `vbox-slackcurrent.vbox-slackcurrent.org` and, at the
interactive GRUB menu, manually select exactly:

`Slackware-current slack-update direct generic (no initrd)`

The selected entry must remain the already frozen entry whose single linux
command is:

`linux /boot/vmlinuz-generic root=/dev/sda2 ro`

No persistent boot-selection mutation is part of the design. In particular,
`GRUB_DEFAULT`, `/etc/default/grub`, `/boot/grub/grub.cfg`, the custom
`/etc/grub.d/41_slack-update-direct-generic` script, and GRUB environment state
must not be changed to force the selection. `grub-mkconfig`, `grub-reboot`,
`grub-set-default`, `grub-editenv`, and equivalent persistent or one-shot GRUB
state mutation are outside the designed scope.

The step-140 evidence freezes the pre-recovery boot identities as
`grub.cfg` SHA-256
`f9864ba5d8bbe78689b3b1e3ff337049e48026c1cd3f4289b3d4297af3a40593`
and custom GRUB script SHA-256
`766bc1d8fabee076d521c641e19eeb03353733657031975a87131e72dd31bec1`.
A later authorization must revalidate these identities before permitting the
reboot.

## Post-reboot characterization boundary

Recovery of the boot selection is not itself authorization to execute the
runtime probe. After the manually selected reboot, a separate characterization
must establish all of the following before any replacement rerun can be
considered:

- the FQDN is still `vbox-slackcurrent.vbox-slackcurrent.org`;
- the machine is still booted through UEFI;
- the running kernel is still `6.18.45`;
- `BOOT_IMAGE` is still `/boot/vmlinuz-generic`;
- the live kernel command line carries `root=/dev/sda2`, not the UUID token;
- `/` still resolves to `/dev/sda2`;
- `/boot/vmlinuz-generic` still resolves to `/boot/vmlinuz-6.18.45`;
- the frozen dedicated menuentry still contains exactly one generic `linux`
  command and no `initrd` command;
- the `grub.cfg` and custom GRUB script hashes remain the step-140 values; and
- package, source, template, and boot configuration state remain otherwise
  unchanged.

That characterization must not invoke the remediated runtime probe. A clean
recovery verification may advance only to a fresh Slackware-current rerun
authorization review. The consumed step-139 authorization must never be reused.

## Authorization and publication boundary

Step 142 authorizes no reboot, no machine execution, no runtime rerun, no boot
mutation, no source or template change, no package action, and no Slackware
repository refresh. Slackware 15.0 remains held and unauthorized.

A successful step 142 advances only to a separate repository-only
boot-selection recovery authorization review. Because the designed recovery
uses only the already installed kernel and already frozen GRUB entry and does
not depend on repository metadata, this checkpoint is independent of later
Slackware-current publications and `pause_safe=true`.
