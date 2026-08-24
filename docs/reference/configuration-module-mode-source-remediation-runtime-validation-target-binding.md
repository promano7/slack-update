# Phase 1 optional-module mode source remediation runtime-validation target binding

Step 132 completes the repository-only target binding required by step 131. It
freezes the real Slackware-current VM identity and the exact execution harnesses
for both mandatory Slackware targets. Step 132 itself performs no machine
execution.

## Bound targets

The established Slackware 15.0 target remains
`vbox-slack15.vbox-slack15.org`. Its accepted boot identity is the existing
UEFI/ELILO generic+initrd state with kernel `5.15.209`, tied to the accepted
scenario-closure record and ELILO configuration already reviewed in the earlier
cleanup chain.

The new Slackware-current target is now bound to
`vbox-slackcurrent.vbox-slackcurrent.org`. Pre-binding characterization proved
that kernel `6.18.45` can boot directly through `/boot/vmlinuz-generic` with
`root=/dev/sda2` and no initrd loaded by the dedicated GRUB entry
`Slackware-current slack-update direct generic (no initrd)`.

The presence of `/boot/initrd-generic.img` as a recovery artifact is not a
profile violation. The accepted reference implementation's direct-generic
classification is intentionally tied to the configured legacy paths
`/etc/mkinitrd.conf` and `/boot/initrd.gz`; both were absent during preparatory
characterization. The target harness independently checks the dedicated active
GRUB entry so the runtime verdict is not based only on those source-level
preconditions.

## Frozen execution harnesses

Exactly two machine-execution harnesses are bound:

- Slackware-current:
  `tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-current.sh`
- Slackware 15.0:
  `tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15.sh`

Their SHA-256 identities are recorded in the target-binding TSV and policy. Each
harness also checks its own frozen digest, the target-binding policy digest, the
accepted remediated source digest, and the frozen configuration-template digest
before accepting a runtime result.

## Runtime expectations

On Slackware-current, characterization must prove the frozen
`grub-direct-generic-no-initrd` profile before `probe_boot_module()` is called.
The accepted result is `boot=auto`, state `available`, runnable, with
`direct-generic-no-initrd` selected and no initrd capability selected by the
configured source path.

On Slackware 15.0, characterization must prove the accepted UEFI/ELILO
`generic+initrd` state and the absence of an active `/boot/grub` preparation
path. The accepted remediated result is fail-closed: `boot=auto` is unavailable,
non-runnable, and remains on the unknown layout because the real ELILO target
exposes only the initrd-side capability recognized by the reference probe. This
is the real-machine confirmation of the partial-path remediation.

## Authorization consumption order

The step-131 scope becomes consumable only after this target-binding stage is
accepted. At step 132 only the Slackware-current execution is immediately
consumable; the single Slackware 15.0 execution remains bound but explicitly
non-consumable until the current evidence review releases it. The total ceiling
remains exactly two executions and zero reboots. The execution order is frozen as:

1. Slackware-current VM;
2. evidence review of that single execution;
3. Slackware 15.0 VM;
4. evidence review of that single execution.

The second machine execution must not be started until the first evidence set
has been reviewed and accepted. This is enforced by the frozen Slackware 15.0
harness: it requires the exact SHA-256 of the future step-134 Slackware-current
review policy and validates that policy's accepted current evidence and explicit
`slackware_15_execution_released=true` gate before probing the machine. The physical Slackware-current host remains
outside the default authorization and stays fallback-only unless a new explicit
review authorizes hardware-specific confirmation. A failed characterization or runtime probe does
not authorize a retry, guest repair, package change, boot change, source change,
repository refresh, or reboot. Any such continuation requires a new explicit
review boundary.

## Non-mutation and evidence boundary

The execution harnesses invoke only the accepted source's configuration loader
and `probe_boot_module()` as library functions. They do not invoke the normal
Slackware update workflow. They capture package, boot, source, and template
state before and after the probe and require byte-equivalent or digest-equivalent
state at completion.

The only permitted writes during a runtime execution are the private evidence
workspace under `/var/tmp/slack-update-acceptance` and the later explicit copy
of the resulting `.tar.gz` and `.sha256` sidecar to `/home/promano`. The copy
instructions preserve ownership as `promano:users`.

No `slackpkg update`, package mutation, `mkinitrd`, GRUB regeneration, ELILO
change, shutdown, or reboot is authorized. The chain remains independent of
Slackware repository publication timing.

## Authorization state after step 132

A successful repository-only step 132 records:

- `target_binding_complete=true`;
- `machine_execution_authorized=true`;
- `authorization_consumable=true`;
- total machine execution limit `2`;
- reboot limit `0`;
- source/configuration/contract changes unauthorized;
- Slackware-current as the first execution target.

Step 132 itself requires no machine action and remains pause-safe. The next
stage is
`phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-current-execution`.
