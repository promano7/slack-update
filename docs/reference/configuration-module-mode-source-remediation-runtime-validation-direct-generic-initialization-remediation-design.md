# Phase 1 direct-generic initialization remediation design

Step 135 designs the smallest source remediation for the runtime-initialization
failure accepted by step 134. The consumed Slackware-current execution reached
the real direct-generic boot capability probe and aborted under `set -u` because
`probe_direct_generic_boot_layout()` expanded `GENERIC_KERNEL_LINK` before the
accepted source had assigned that variable.

This is a repository-only design boundary. It does not modify the accepted
reference implementation, the configuration template, the frozen optional-module
contract, package state, boot state, or either validation machine.

## Designed source delta

The existing assignment is:

`GENERIC_KERNEL_LINK=/boot/vmlinuz-generic`

Step 135 freezes a relocation-only remediation. A later separately authorized
implementation may move that exact assignment out of
`classify_direct_generic_boot_layout()` and place it immediately after the
existing top-level anchor:

`GENINITRD_VERSIONED_INITRD_DIRECTORY=/boot`

The assignment must remain mutable, must keep the exact `/boot/vmlinuz-generic`
value, and must occur exactly once. The implementation must not add `readonly`,
change either function signature, remove the classifier's `generic_link`
argument, or alter any direct-generic classification rule. The purpose is only
to guarantee initialization before the first wrapper expansion.

Relocating the assignment also removes the classifier's incidental global-state
side effect while retaining its explicit `generic_link` input. Isolated classifier
fixtures therefore remain able to supply private paths without weakening the
real wrapper's fixed generic-kernel path.

## Regression boundary

A later implementation review must prove that:

- the assignment exists exactly once and before both direct-generic functions;
- `classify_direct_generic_boot_layout()` no longer assigns the global variable;
- `probe_direct_generic_boot_layout()` can expand `GENERIC_KERNEL_LINK` under
  `set -u` before entering the classifier;
- the classifier still receives and uses its explicit `generic_link` argument;
- `mkinitrd-managed` behavior is unchanged;
- validated `direct-generic-no-initrd` behavior is unchanged;
- the previously remediated `boot=auto` partial-capability path remains
  fail-closed and non-runnable;
- enabled and disabled module-mode semantics remain unchanged;
- the configuration template and frozen 15-row module-mode contract remain
  byte-identical.

## Authorization and machine boundary

Step 135 does **not** authorize the source relocation. The accepted source must
remain at SHA-256
`c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c`
throughout this design review.

The consumed step-132 Slackware-current authorization remains non-reusable.
Slackware 15.0 remains held and unreleased. No machine execution, reboot,
package or boot mutation, Slackware repository refresh, configuration-template
change, or contract change is authorized.

A successful step 135 advances only to a separate repository-only source
remediation authorization review. This checkpoint remains independent of
Slackware repository publication state and is safe to pause.
