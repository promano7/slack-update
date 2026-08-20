# Phase 1 optional-module mode source remediation authorization review

Step 127 performs the separate authorization review for the source remediation
designed and frozen in step 126. The review itself is repository-only and does
not modify the accepted reference implementation.

## Authorized source boundary

A successful review authorizes exactly one future source change in
`tools/reference/slack-update-reference.sh`:

- function: `probe_boot_module()`;
- module/mode: `boot=auto`;
- discrepancy: `boot-auto-partial-path-availability`;
- scope: `boot-auto-partial-applicability-only`;
- edit: remove the historical auto-only branch that turns an incomplete
  preparation capability set into `BOOT_MODULE_STATE=available`,
  `BOOT_MODULE_RUN=1`, and `BOOT_PREPARATION_LAYOUT=partial`.

The authorization is consumable only while the pre-edit source remains at the
accepted SHA-256 from steps 125 and 126. If that source identity changes before
the implementation step, this authorization is invalid and must not be reused.

## Boundaries that remain frozen

The implementation is not authorized to change the configuration template, the
15-row optional-module mode contract, capability detectors, enabled-mode strict
semantics, disabled-mode bypass semantics, or either validated complete boot
preparation layout (`mkinitrd-managed` and `direct-generic-no-initrd`). It may not
introduce a new preparation layout or broaden an existing detector.

The future edit must reuse the existing fail-closed unavailable/non-runnable
fallback for incomplete `boot=auto` layouts.

## Review-only behavior

Step 127 only grants the narrowly scoped source authorization. It does not apply
the source change and therefore records `source_change_applied=false` while
recording `source_change_authorized=true`.

No Slackware machine action or repository refresh is required. Slackware 15.0
and Slackware-current remain mandatory targets. A successful step 127 advances
only to `phase-1-configuration-module-mode-source-remediation-implementation`.
