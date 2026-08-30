# Phase 1 Slackware 15.0 characterization remediation implementation

Step 154 consumes the narrow repository authorization granted by step 153 and
creates the separately named successor execution harness required by step 152.
The consumed step-150 execution harness is not modified.

## Applied harness delta

The new successor harness is:

`tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-characterization-remediated-rerun.sh`

Its pre-probe target characterization is limited to the accepted ELILO core
identity: FQDN, Slackware 15.0 release, UEFI, running kernel `5.15.209`, the
accepted ELILO `BOOT_IMAGE` suffix, and the accepted `elilo.conf` SHA-256.

The step-150 assumptions about `/etc/mkinitrd.conf` presence and `/boot/grub`
absence are no longer identity gates. Both states remain captured before and
after execution as runtime evidence.

After the core identity gate succeeds, the accepted source is loaded and
`probe_boot_module()` supplies live `BOOT_INITRD_AVAILABLE` and
`BOOT_GRUB_AVAILABLE` values. Those capability bits are written to evidence but
are not compared with the historical step-132 exact vector.

The runtime verdict instead checks the semantic remediation property: with
`boot=auto`, an incomplete preparation layout must be `unavailable`,
non-runnable, `unknown`, direct-generic capability `0`, and report
`no supported initrd or GRUB preparation path was detected`.

## Execution hold

Step 154 deliberately does **not** create the future machine-execution
authorization policy. The successor harness refuses execution unless the future
policy file exists and its SHA-256 is supplied explicitly on the command line.
Therefore creating the harness does not create a consumable machine boundary.

The step-149 machine authorization remains consumed and non-reusable. Step 153
is consumed only as the single-use repository authorization for creating this
new harness.

## Preserved boundaries

The implementation changes no reference source, configuration template,
optional-module contract, historical target binding, accepted ELILO closure,
package state, boot state, or Slackware repository metadata. It performs no
machine action and no reboot.

The implementation also preserves pre/post evidence comparison for package
inventory, Slackpkg metadata, boot state, source identity, and configuration
identity when a later separately authorized execution eventually occurs.

A successful step 154 advances only to a repository-only implementation review.
Machine execution and a Slackware 15.0 rerun remain unauthorized, future work
requires a fresh boundary, and this checkpoint is publication-state independent
with `pause_safe=true`.
