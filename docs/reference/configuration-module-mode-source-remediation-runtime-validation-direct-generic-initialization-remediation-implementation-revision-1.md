# Phase 1 step 137 revision 1 — implementation verification fix

The initial step-137 overlay successfully consumed the step-136 source
authorization and produced post-edit reference source SHA-256
`aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7`.
The post-edit source shape and the implementation records were accepted before
the validation helper aborted.

## Verification defect

The exact-delta reconstruction helper used the line
`BOOT_DIRECT_GENERIC_BOOT_IMAGE=` as a reconstruction landmark and required the
line to occur exactly once in the entire source file. That assumption was too
broad: the line occurs legitimately both inside
`classify_direct_generic_boot_layout()` and in the general runtime-state
initialization block.

The failure therefore belonged to the step-137 verification code, not to the
authorized source relocation.

## Revision 1 correction

Revision 1 does not edit `tools/reference/slack-update-reference.sh`, does not
reconsume the exhausted step-136 authorization, and does not rewrite the
implementation TSV or policy.

The reconstruction now scopes the landmark to the exact body of
`classify_direct_generic_boot_layout()`. It removes the relocated global
`GENERIC_KERNEL_LINK=/boot/vmlinuz-generic` assignment, identifies exactly one
classifier-local `BOOT_DIRECT_GENERIC_BOOT_IMAGE=` state line, restores the
assignment immediately after that classifier-local line, and requires the
reconstructed image to match the authorized pre-edit SHA-256
`c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c`.

This preserves the original exact-delta proof while removing the invalid global
uniqueness assumption.

## Authorization and machine boundary

The step-136 source authorization remains consumed exactly once by the already
applied source relocation. No further source change is authorized. No
Slackware-current rerun is authorized by this revision and Slackware 15.0
remains held. No package, boot, reboot, repository refresh, or machine action is
required.

A successful revision-1 harness re-establishes the repository-only step-137
implementation checkpoint and advances to the planned repository-local
regression review.
