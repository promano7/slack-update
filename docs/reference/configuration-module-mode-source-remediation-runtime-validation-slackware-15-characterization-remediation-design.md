# Phase 1 Slackware 15.0 characterization remediation design

Step 152 designs the smallest correction for the
`unfrozen-target-characterization-assumption-mismatch` accepted by step 151.
The consumed step-150 execution proved that the accepted Slackware 15.0 ELILO
core identity was still intact, but its execution harness added two pre-probe
requirements that were not frozen by the accepted historical ELILO closure:
`/etc/mkinitrd.conf` had to exist as a regular file and `/boot/grub` had to be
absent.

This is a repository-only design boundary. It changes no execution harness,
reference source, configuration template, target-binding record, package state,
boot state, repository metadata, or validation machine.

## Two-layer characterization boundary

A future successor execution harness must separate **target identity** from
**runtime capability observations**.

The pre-probe target-identity gate remains fail-closed and may use only the
accepted ELILO core identity already evidenced by the historical closure and the
accepted step-151 review:

- FQDN `vbox-slack15.vbox-slack15.org`;
- Slackware version `Slackware 15.0`;
- UEFI presence;
- running kernel `5.15.209`;
- the accepted ELILO `BOOT_IMAGE` suffix
  `\EFI\Slackware\vmlinuz-generic-5.15.209`; and
- active ELILO configuration SHA-256
  `94b77b9f70a9d3b22d146c36af0ee6bbf09133d0b1931a2e731e881d3edc37f6`.

If any of those frozen identity predicates fails, the runtime probe must remain
withheld.

By contrast, `/etc/mkinitrd.conf` presence and `/boot/grub` directory state are
runtime capability inputs. Their step-150 observations (`absent` and
`directory`, respectively) must remain captured as evidence, but they must not
be used as historical-identity prerequisites for entering the probe.

## Future runtime acceptance semantics

A later separately authorized successor harness may invoke the accepted source's
`probe_boot_module()` only after the frozen ELILO identity gate succeeds. The
probe's `BOOT_INITRD_AVAILABLE` and `BOOT_GRUB_AVAILABLE` values must be recorded
as observations of the live machine rather than forced to the historical
step-132 vector.

The semantic runtime expectation remains the remediation property being tested,
not a predeclared filesystem shape: with `boot=auto` on this accepted ELILO
identity, an incomplete preparation layout must fail closed with module state
`unavailable`, run flag `0`, preparation layout `unknown`, direct-generic
capability `0`, and reason
`no supported initrd or GRUB preparation path was detected`.

The successor harness must therefore not require the exact historical
`BOOT_INITRD_AVAILABLE=1` / `BOOT_GRUB_AVAILABLE=0` pair before or after the
probe. Either capability bit is evidence whose live value is determined by the
accepted source. What must remain invariant is that the observed capability set
does not become an accepted complete preparation layout on the frozen ELILO
boot identity.

## Historical artifacts remain immutable

Step 152 does not rewrite the step-132 target-binding policy. That document is a
historical record of the earlier characterization and remains frozen at SHA-256
`97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6`.
Likewise, the consumed step-150 harness remains immutable at SHA-256
`346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75`.
A later implementation, if separately authorized, must create a successor
boundary rather than silently changing the evidence identity of the consumed
execution.

The step-149 single-use authorization remains consumed and cannot be reused.

## Non-mutation and authorization boundary

Step 152 authorizes no harness implementation and no machine execution. It also
authorizes no source, configuration-template, optional-module contract,
target-binding, package, boot, or Slackware repository mutation and no reboot.
The accepted source remains
`aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7`
and the configuration template remains
`4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba`.

A successful step 152 advances only to a separate repository-only
characterization-remediation authorization review. The checkpoint is independent
of later Slackware publications, requires no machine action, and records
`pause_safe=true`.
