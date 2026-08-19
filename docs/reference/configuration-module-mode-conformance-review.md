# Phase 1 optional-module mode conformance review

Step 123 compares the unchanged reference implementation with the complete
15-row optional-module mode contract frozen in step 122. The review is
observational: it records what the accepted source already does and does not
authorize a source, template, or contract modification.

## Result expected from the accepted source

Fourteen module/mode rows conform to the frozen contract. One row requires
classification before the project can decide whether the contract or the
implementation should change:

- module: `boot`
- mode: `auto`
- discrepancy: `boot-auto-partial-path-availability`
- frozen contract: only a validated supported preparation path may be selected
- observed source: when exactly one boot preparation capability is available,
  the probe may mark the module `available`, set `BOOT_MODULE_RUN=1`, and label
  the layout `partial`

The source later gates individual initrd and GRUB actions by their detected
availability. Step 123 does not decide whether that historical partial-path
behavior is the compatibility surface that should be preserved or whether the
stricter step-122 contract should govern a future implementation change. That
is the purpose of the next classification stage.

## Other rows

The other fourteen rows retain the frozen behavior: disabled modules bypass
activation work, enabled modules surface missing mandatory requirements as
errors, and auto remains non-fatal when optional requirements are unavailable.
Cinnamon's enabled module remains rebuild-trigger gated; enabling the module
does not by itself create an ABI rebuild trigger.

## Safety boundary

This review is repository-only. It keeps the exact step-122 source and template
hashes, performs no package or network operation, changes no boot state, and
requires no action on Slackware 15.0 or Slackware-current.

A successful step 123 advances only to
`phase-1-configuration-module-mode-conformance-discrepancy-classification`.
