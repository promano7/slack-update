# Slackware-current boot-selection recovery execution boundary

Phase 1 step 144 consumes only the single-use recovery authorization granted by
step 143. It does not reopen the source remediation and does not authorize a
replacement runtime-validation rerun.

## Frozen target

- FQDN: `vbox-slackcurrent.vbox-slackcurrent.org`.
- Kernel: `6.18.45`.
- Boot image: `/boot/vmlinuz-generic`.
- Versioned generic target: `/boot/vmlinuz-6.18.45`.
- Mounted root: `/dev/sda2`.
- Required recovered live root token: `/dev/sda2`.
- GRUB menuentry: `Slackware-current slack-update direct generic (no initrd)`.
- Linux command: `linux /boot/vmlinuz-generic root=/dev/sda2 ro`.
- Frozen `grub.cfg` SHA-256: `f9864ba5d8bbe78689b3b1e3ff337049e48026c1cd3f4289b3d4297af3a40593`.
- Frozen custom GRUB script SHA-256: `766bc1d8fabee076d521c641e19eeb03353733657031975a87131e72dd31bec1`.

## Execution shape

The machine harness has two explicit stages.

The **pre-reboot** stage revalidates the step-143 authorization, the step-144
execution policy, FQDN, UEFI, kernel, mounted root, generic-kernel target,
dedicated menuentry, and both frozen GRUB hashes. It also fingerprints the
package database, Slackpkg metadata, `grubenv`, `/etc/default/grub`, accepted
source, and configuration template. A failure stops before reboot. A clean run
creates only private acceptance evidence and a handoff marker below `/var/tmp`.
The machine harness never executes the reboot itself.

After that gate has been separately reviewed, exactly one manual reboot may use:

    sudo /sbin/reboot

At GRUB, the only authorized interactive selection is:

    Slackware-current slack-update direct generic (no initrd)

No persistent/default boot selection may be changed.

The **post-reboot** stage requires the exact pre-reboot marker SHA-256, an
explicit operator confirmation that exactly one authorized reboot occurred, and
an explicit confirmation of the selected menuentry. Once it proves a new boot
occurred after the pre-reboot gate, the step-143 authorization is marked
consumed and cannot authorize another reboot. The stage then requires
`BOOT_IMAGE=/boot/vmlinuz-generic`, live `root=/dev/sda2`, mounted
`/dev/sda2`, kernel `6.18.45`, the frozen generic target, the exact no-initrd
menuentry, unchanged GRUB hashes, and preservation of all pre-reboot state
fingerprints.

The runtime probe remains unauthorized throughout step 144. Repository refresh,
package mutation, source/template/contract mutation, GRUB mutation, a replacement
Slackware-current rerun, and Slackware 15.0 execution are all forbidden.
Slackware 15.0 remains unauthorized.

## Pause semantics

The repository checkpoint is safe before the pre-reboot stage because it has no
Slackware repository-state dependency. Once the pre-reboot handoff is armed, do
not pause the recovery sequence: complete the one authorized reboot and the
post-reboot characterization. A successful post-reboot result advances only to
manual evidence review, where pause safety is decided from the authenticated
result.

Execution policy SHA-256: `4d056fcf9287ffbbdf83ec8b9fc5bb709b781989f59a719639aab77f58c93e6f`.
Machine harness SHA-256: `300335ef07df2f091e9b0d8f849f8c65fcece5a134880301d684c36bb10bf12f`.
