# Phase 1 Slackware-current boot-selection recovery authorization review

Step 143 reviews the accepted step-142 selection-only recovery design and grants
one fresh, consumable authorization for the later recovery sequence on
`vbox-slackcurrent.vbox-slackcurrent.org`. Step 143 itself is repository-only
and performs no machine action.

The authorization exists only to recover the exact frozen boot selection that
step 140 failed to reproduce. The authenticated failure remains classified as
`frozen-boot-selection-mismatch`; the source remediation was never exercised
and is neither accepted nor rejected by that failed execution.

## Authorized recovery sequence

A later execution may perform exactly one recovery sequence and at most one
reboot. At the interactive GRUB menu, the operator must manually select exactly:

`Slackware-current slack-update direct generic (no initrd)`

The selected entry remains the already frozen entry whose linux command is:

`linux /boot/vmlinuz-generic root=/dev/sda2 ro`

Interactive selection of this already existing entry is the only boot-selection
action authorized. It is not authorization to mutate boot configuration.
Changes to `/boot/grub/grub.cfg`, `/etc/default/grub`,
`/etc/grub.d/41_slack-update-direct-generic`, GRUB environment state, or any
persistent/default boot selection remain forbidden. `grub-mkconfig`,
`grub-reboot`, `grub-set-default`, `grub-editenv`, and equivalent mutation are
outside the authorization.

Before the reboot, a separately delivered execution boundary must revalidate
the FQDN, UEFI state, kernel `6.18.45`, `/boot/vmlinuz-generic` target,
`/dev/sda2` mounted root, the exact dedicated menuentry, and the frozen GRUB
hashes. Any mismatch must stop before reboot.

## Post-reboot boundary

After the manual selection and reboot, characterization must establish that the
live kernel command line now contains `root=/dev/sda2`, `/` still resolves to
`/dev/sda2`, `BOOT_IMAGE` remains `/boot/vmlinuz-generic`, kernel `6.18.45` is
running, the generic-kernel symlink and dedicated no-initrd entry remain frozen,
and the GRUB hashes are unchanged.

The runtime remediation probe is explicitly forbidden during this recovery
sequence. A successful characterization may advance only to a fresh rerun
authorization review. The consumed step-139 authorization remains non-reusable,
and no replacement Slackware-current rerun is authorized by step 143.
Slackware 15.0 remains held and unauthorized.

## Safe-pause boundary

Step 143 authorizes no repository refresh, package mutation, source/template or
contract change, persistent boot mutation, runtime probe, or Slackware 15.0
execution. Step 143 itself requires no machine action. The future recovery uses
only the already installed kernel and already frozen GRUB entry, so this
checkpoint does not depend on Slackware-current repository publication state
and `pause_safe=true`.

The only next stage is
`phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-recovery-execution`.
