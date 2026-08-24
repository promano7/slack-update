# Phase 1 step 137 — direct-generic initialization remediation implementation

Step 137 consumes the single-use source authorization granted by step 136 and
applies exactly the relocation frozen by step 135.

## Applied source delta

The existing mutable assignment
`GENERIC_KERNEL_LINK=/boot/vmlinuz-generic` is removed from
`classify_direct_generic_boot_layout()` and inserted immediately after the
existing global initialization anchor
`GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot`.

No value is changed and no second assignment is introduced. The classifier
still receives `generic_link` as its fourth argument, the probe still passes
`$GENERIC_KERNEL_LINK` at that call, and no function signature or boot-layout
policy is changed. The configuration template and frozen optional-module
contract remain byte-identical.

## Exact-delta proof

The implementation record binds the resulting source to its post-edit SHA-256.
The validation helper then reconstructs the authorized pre-edit image by
removing the global assignment from immediately after the frozen anchor and
restoring the same assignment at its exact former classifier location. The
reconstructed image must have SHA-256
`c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c`.

This exact reconstruction proves that the relocation is the only source delta
consumed by step 137 rather than merely checking source landmarks.

## Authorization boundary

Step 137 records `authorization_consumed=true` and
`further_source_change_authorized=false`. The step-136 source authorization is
therefore exhausted by this edit and cannot authorize another source mutation.

No Slackware-current rerun is authorized by step 137. Slackware 15.0 remains held. No package, boot, reboot, repository refresh, or machine action is
required. The repository-only checkpoint remains independent of Slackware
publication state and pause-safe.

A successful implementation advances only to the repository-local regression
review for this direct-generic initialization remediation.
