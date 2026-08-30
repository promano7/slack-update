# Phase 1 step 153 — Slackware 15.0 characterization remediation authorization review

Step 153 reviews and grants the narrow repository edit authorization designed in
step 152. This is an authorization-review boundary only: it does not implement
or execute a successor runtime harness and performs no machine action.

## Authorized repository change

The authorization is consumable only while the exact step-152 design, policy,
and reference document remain byte-identical at their reviewed SHA-256 values.
It authorizes creation of exactly one new successor harness:

`tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh`

The consumed step-150 harness must remain immutable. No edit to any other
execution harness is authorized. The accepted reference source, configuration
template, optional-module contract, historical step-132 target binding, and
accepted ELILO closure also remain immutable.

## Required successor semantics

The successor harness must implement the two-layer boundary frozen by step 152.
Before invoking the accepted runtime probe, it may gate only on the accepted
Slackware 15.0 ELILO core identity: FQDN, Slackware release, UEFI presence,
running kernel `5.15.209`, accepted ELILO `BOOT_IMAGE` suffix, and accepted
`elilo.conf` SHA-256.

`/etc/mkinitrd.conf` presence and `/boot/grub` directory state must not be pre-probe identity requirements. Both states must still be recorded in evidence.
The live runtime probe must determine `BOOT_INITRD_AVAILABLE` and
`BOOT_GRUB_AVAILABLE`; the historical step-132 exact capability vector must not
be used as a fresh target-identity predicate.

The successor acceptance verdict is semantic. With `boot=auto` on the frozen
ELILO identity, the incomplete preparation layout must fail closed as
`BOOT_MODULE_STATE=unavailable`, `BOOT_MODULE_RUN=0`,
`BOOT_PREPARATION_LAYOUT=unknown`, `BOOT_DIRECT_GENERIC_AVAILABLE=0`, and reason
`no supported initrd or GRUB preparation path was detected`.

The successor must retain before/after non-mutation evidence for package,
Slackpkg, boot, accepted source, and configuration-template state. Any frozen
core-identity mismatch must withhold runtime probing.

## Authorization consumption and execution hold

This authorization is single-use for the step-154 repository implementation.
A successful implementation must record the authorization as consumed. It does not authorize execution of the resulting harness on Slackware 15.0.

The step-149 machine authorization remains consumed and cannot be reused. Step
153 grants no rerun, reboot, package mutation, boot mutation, repository refresh,
source edit, template edit, contract edit, or target-binding edit.

A successful step 153 advances only to the repository-local characterization
remediation implementation. Machine execution still requires a later fresh
boundary after the implemented successor harness has passed repository review.
The checkpoint is independent of Slackware publication state and records
`pause_safe=true`.
