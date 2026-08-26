# Phase 1 step 141 revision 1 — manual-review document assertion fix

The initial step-141 overlay completed the substantive Slackware-current rerun
manual review successfully. Its harness reported 59 passes and one failure. The
only failing assertion attempted to prove that the authenticated step-140 rerun
never entered the runtime probe and therefore did not exercise or reject the
step-135 through step-138 source remediation.

## Verification defect

The step-141 manual-review document already states the required conclusion. Its
Markdown source wraps the phrase `runtime probe was never invoked` across a
physical newline: `runtime probe` ends one line and `was never invoked` begins
the next. The harness used line-oriented `grep -F`, so the semantic statement
was present while the literal single-line search failed.

The 59 passing checks already authenticated step-140 evidence SHA-256
`def71e947186de4e3df4f4af4cddc55f0b41397076e17fbc1b97f13129e58eb8`,
classified the failure as `frozen-boot-selection-mismatch`, confirmed that the
runtime probe was not entered, preserved system state, and kept the source
remediation unexercised.

## Revision 1 correction

Revision 1 changes only the step-141 verification harness. It normalizes
Markdown whitespace before checking the complete statements `runtime probe was
never invoked` and `neither exercised nor rejected`. The step-141 manual-review
document, helper, TSV record, policy, authenticated evidence binding, source,
configuration template, step-132 target binding, step-139 authorization, and
step-140 rerun harness remain unchanged.

This correction mirrors the whitespace-normalized document verification already
used after the earlier line-wrapping assertion defect in step 137 revision 2.

## Authorization and continuation boundary

The single step-139 rerun attempt remains consumed and must not be reused.
Revision 1 authorizes no source change, no machine execution, no replacement
Slackware-current rerun, no Slackware 15.0 execution, no boot mutation, no
reboot, no package action, and no Slackware repository refresh.

The manual-review checkpoint remains `pause_safe=true` and independent of later
Slackware-current publications. A successful revision-1 harness restores the
intended step-141 repository-only checkpoint and leaves the next stage unchanged:
`phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-boot-selection-drift-remediation-design`.
