# Phase 1 step 156 — Slackware 15.0 characterization-remediated rerun authorization review

Step 156 creates the fresh machine-execution authorization boundary required by
the accepted step-155 implementation review. It authorizes exactly one execution
of the reviewed successor harness and does not modify that harness.

## Frozen chain

The authorization is bound to the accepted step-155 review policy, record, and
reference document; the step-154 implementation policy; the consumed step-153
repository authorization; the historical step-132 target binding; the accepted
Slackware 15.0 ELILO closure; the consumed step-150 harness identity; the
accepted reference source and configuration template; and the exact successor
harness SHA-256
`6a852531722c3c1b2d5412c1097db569ab355d72983151be64f17ceff8ab48f7`.

The authorized target remains `vbox-slack15.vbox-slack15.org`, Slackware 15.0,
UEFI, running kernel `5.15.209`, with the accepted ELILO generic-kernel boot
identity and accepted `elilo.conf` SHA-256.

## Authorization scope

The authorization is single-use and consumable by one invocation of
`tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh`.
It permits zero reboots and authorizes no Slackware repository refresh, package
mutation, boot mutation, source change, configuration-template change, contract
change, target-binding change, execution-harness change, or retry.

The successor harness must obtain `BOOT_INITRD_AVAILABLE` and
`BOOT_GRUB_AVAILABLE` from the live runtime probe. The historical exact
capability vector is not an acceptance requirement. Runtime acceptance remains
the reviewed semantic `boot=auto` fail-closed behavior for an incomplete
preparation layout.

The consumed step-149 machine authorization remains non-reusable, and the
consumed step-153 repository authorization remains consumed. This step creates a
new authorization rather than reopening either old boundary.

## Pause and next stage

Step 156 itself performs no machine action and is independent of later
Slackware publications. The authorization remains safe to hold without a
repository refresh because the authorized execution is observational and
forbids refresh or mutation.

The next stage is the single authorized Slackware 15.0
characterization-remediated rerun execution. `pause_safe=true`.
