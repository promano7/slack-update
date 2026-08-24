# Phase 1 step 138 — direct-generic initialization remediation regression review

Step 138 is a repository-only regression review of the `GENERIC_KERNEL_LINK`
initialization remediation accepted in step 137 and its two verification
revisions. It performs no machine execution and authorizes none.

The accepted post-remediation source is bound to SHA-256
`aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7`.
The review re-runs the corrected step-137 exact-delta proof and requires shell
syntax validation of the accepted reference implementation.

The key executable regression deliberately exercises the original failure
boundary under `set -u`. The current source's exact
`probe_direct_generic_boot_layout()` function is placed in an isolated fixture.
With the accepted global initialization present, the probe must call the
classifier successfully and pass `/boot/vmlinuz-generic` as its fourth
argument. A companion historical fixture removes that initialization and must
fail specifically with `GENERIC_KERNEL_LINK: unbound variable`. This proves
that the regression would detect the step-133 defect rather than merely inspect
for a matching text line.

The configuration template and optional-module contract remain byte-identical.
The step-136 source authorization remains consumed and cannot be reused:
`further_source_change_authorized=false`.

No Slackware-current rerun is authorized by step 138, and Slackware 15.0 remains
held. No `slackpkg update`, package mutation, boot mutation, reboot, or VM action
is required. The boundary is independent of Slackware repository publication
state and remains pause-safe.

The only next stage is a separate repository-only
`slackware-current-rerun-authorization-review`. That review may decide whether
a fresh single-use non-mutating runtime execution can be authorized against the
already bound Slackware-current VM; step 138 itself does not grant it.
