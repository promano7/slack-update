# Phase 1 step 138 revision 1 — locale-stable historical regression verification

The initial step-138 regression review preserved the accepted post-remediation
source at SHA-256
`aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7` and
failed only while validating the diagnostic text emitted by the historical
`set -u` fixture.

## Verification defect

The historical fixture correctly executes the exact pre-remediation failure
boundary: `probe_direct_generic_boot_layout()` expands `GENERIC_KERNEL_LINK`
while the variable is unset. The step-138 helper required both the variable
name and the English Bash diagnostic text `unbound variable` in standard error.

That textual requirement was locale-sensitive. The fixture subprocess inherited
the host locale, so Bash could translate the diagnostic while still failing at
the exact reviewed unset variable. The regression therefore rejected a valid
historical failure on non-English hosts.

This is a step-138 verification defect only. It does not change the accepted
step-137 source remediation, configuration template, optional-module contract,
implementation records, or consumed source authorization.

## Revision 1 correction

Revision 1 makes the executable fixtures deterministic by starting both the
remediated and historical fixture subprocesses with `LC_ALL=C` and `LANG=C`.
The historical assertion remains deliberately strict: the subprocess must fail,
standard error must name `GENERIC_KERNEL_LINK`, and the now deterministic Bash
diagnostic must contain `unbound variable`.

The remediated fixture must still pass under `set -u`, preserve
`/boot/vmlinuz-generic` as the fourth classifier argument, and set direct-generic
availability successfully. The original step-138 harness is rerun unchanged
against the corrected helper.

## Authorization and machine boundary

The step-136 source authorization remains consumed and non-reusable. Revision 1
performs no source edit and authorizes no further source change. No
Slackware-current rerun is authorized and Slackware 15.0 remains held.

No repository refresh, package mutation, boot mutation, reboot, or machine action
is required. The repository-only boundary remains independent of Slackware
publication state and pause-safe. A successful revision-1 harness restores the
step-138 regression-review checkpoint and advances only to the separate
Slackware-current rerun authorization review.
