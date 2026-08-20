# Phase 1 optional-module mode source remediation design

Step 126 designs the smallest source remediation for the frozen
`boot-auto-partial-path-availability` implementation-conformance gap. This is a
repository-only design boundary. It does not modify the reference implementation,
the configuration template, or the frozen 15-row module-mode contract.

## Designed source delta

The remediation is confined to `probe_boot_module()` and only to the `boot=auto`
partial-applicability branch. The current source already recognizes two complete,
validated preparation layouts: `mkinitrd-managed` and
`direct-generic-no-initrd`. Those paths remain unchanged and continue to make the
boot module available and runnable in auto mode.

The future implementation edit removes the auto-only branch that treats the
presence of only one preparation capability as sufficient to set
`BOOT_MODULE_STATE=available`, `BOOT_MODULE_RUN=1`, and
`BOOT_PREPARATION_LAYOUT=partial`. After that branch is removed, the existing
fail-closed fallback handles incomplete layouts as unavailable and non-runnable.

No capability detector is broadened or weakened. The design reuses the existing
fail-closed fallback instead of adding a third preparation layout or a new policy
exception.

## Frozen regression boundary

A later implementation must demonstrate all of the following before it can be
accepted:

- `boot=auto` + complete `mkinitrd-managed` layout remains available/runnable;
- `boot=auto` + validated `direct-generic-no-initrd` remains available/runnable;
- `boot=auto` + initrd-only partial capability becomes unavailable/non-runnable;
- `boot=auto` + GRUB-only capability without a validated direct-generic layout
  becomes unavailable/non-runnable;
- `boot=auto` + no preparation capability remains unavailable/non-runnable;
- `boot=enabled` keeps its existing strict failure semantics for incomplete
  preparation layouts;
- `boot=disabled` remains disabled/non-runnable regardless of detected layout;
- the configuration template and frozen 15-row contract remain byte-identical.

## Authorization boundary

Step 126 does not authorize the source edit. The accepted source must remain at
its step-125 SHA-256 throughout this design review, including the historical
partial branch that the later implementation will remove.

No Slackware machine action or repository refresh is required. Slackware 15.0 and
Slackware-current remain mandatory targets. A successful step 126 advances only
to `phase-1-configuration-module-mode-source-remediation-authorization-review`.
