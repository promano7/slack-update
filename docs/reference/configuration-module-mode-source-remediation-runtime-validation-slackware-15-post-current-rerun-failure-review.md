# Phase 1 Slackware 15.0 post-current-rerun failure review

Step 151 reviews the single Slackware 15.0 execution consumed in step 150 under
the fresh step-149 authorization. The received evidence archive is
`slackware-15-configuration-module-mode-source-remediation-runtime-validation-post-current-rerun-20260827T155021Z.tar.gz`
with SHA-256
`72d62a7b12f95674eefe31fd6b9698519c717d8a0a4d36a90270e62024e5cb78`.
The sidecar received with it is consistent with that archive digest.

The execution completed nineteen assertions, reported two characterization
failures and two skips, consumed the single authorization attempt, and withheld
the runtime probe fail-closed. Therefore the step-149 authorization cannot be
reused and no runtime verdict is accepted from this attempt.

## Preserved target identity

The evidence still proves the stable Slackware 15.0 identity that was actually
frozen by the earlier ELILO closure: FQDN `vbox-slack15.vbox-slack15.org`,
Slackware 15.0, UEFI firmware, running kernel `5.15.209`, the accepted ELILO
kernel command-line identity, and ELILO configuration SHA-256
`94b77b9f70a9d3b22d146c36af0ee6bbf09133d0b1931a2e731e881d3edc37f6`.
That accepted ELILO closure records a stable boot identity but does not freeze
either `/etc/mkinitrd.conf` or `/boot/grub` as target predicates.

## Characterization mismatch

Step 150 added two independent fail-closed predicates before invoking the
runtime probe:

- `/etc/mkinitrd.conf` had to be a regular non-symlink file; the target exposed
  it as absent.
- `/boot/grub` had to be absent; the target exposed it as a directory.

Neither predicate is present in the accepted ELILO scenario-closure record.
Consequently these observations do not, by themselves, prove that the VM boot
state regressed from the accepted closure. In particular, the live boot identity
still points to ELILO and the accepted generic kernel, so the mere existence of
an incidental `/boot/grub` directory is not evidence that GRUB became the active
boot path.

The failure is therefore classified as an
`unfrozen-target-characterization-assumption-mismatch`: the execution harness
was more restrictive than the historical evidence it claimed to characterize.
This review does not classify the result as a source runtime defect because the
accepted source probe was never invoked.

## Non-mutation and authorization state

The evidence proves byte-identical before/after package inventory, Slackpkg
metadata, boot-state capture, accepted source digest, and configuration-template
digest. `system_state_preserved=true`, and no repository refresh, package
mutation, boot mutation, or reboot occurred.

Step 151 grants no source change, configuration change, contract change, harness
change, or machine execution. The consumed step-149 authorization cannot be reused.
A future stage must design a corrected Slackware 15.0 characterization
boundary using predicates that are either directly evidenced or explicitly
re-characterized under a fresh authorization before any new runtime execution is
considered.

The review is repository-only, requires no Slackware repository refresh, is
independent of later Slackware publications, requires no machine action, and
records `pause_safe=true`. Future work requires a fresh boundary.
