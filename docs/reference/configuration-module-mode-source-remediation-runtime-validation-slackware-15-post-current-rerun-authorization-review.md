# Phase 1 step 149 — Slackware 15.0 post-current-rerun authorization review

Step 149 opens a fresh repository-only authorization boundary for the final
Slackware 15.0 runtime validation after step 148 accepted the remediated source
on Slackware-current. Step 149 performs no machine action.

## Why a fresh harness is required

The historical Slackware 15.0 execution harness frozen by step 132 has SHA-256
`0226e6d48483e0014c699e5affe224bceaa07f8d767673ba30700c7ee21b670c` and
is transitively bound to the pre-remediation source SHA-256
`c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c`.
Step 148 explicitly rejected reuse of that harness after accepting the
remediated source SHA-256
`aeb0ecd032f8988c8e16d1e3a71a8609ea414c39ab69338b96b0ef01b81bbcd7`.

Step 149 therefore freezes a distinct execution harness:
`tests/acceptance/reference/test-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun.sh`,
SHA-256 `346dbb03d30a6ef260d4860a44c160dbbf8e3652887903f1e204d46c1ad14e75`.
The old harness remains present only as an authenticated obsolete identity and
is never treated as an executable authorization source.

## Accepted prerequisite chain

The authorization is bound to the accepted step-148 review policy SHA-256
`de2813f328b1af80531d68a22c049f9c3be58b6a445398c5c3795b49036ead4b`
and review record SHA-256
`9f8c384d4709e8161ac2f6a3e928b7f3e7baea677e7d850c4c061c1aa4d71361`.
That review proves that Slackware-current exercised and accepted the remediated
source, that the runtime validation succeeded, and that Slackware 15.0 was
released only to a fresh authorization review.

The step-132 target-binding policy remains frozen at SHA-256
`97337512e059c26924b19db0f7b4fb61023af8741e331125d9b32e5d99181ec6`
only for the established target identity and ELILO boot contract. Its embedded
pre-remediation source identity is explicitly not reused as a source
authorization.

## Authorized future execution

Exactly one future execution is authorized on
`vbox-slack15.vbox-slack15.org`, kernel `5.15.209`, with the accepted
UEFI/ELILO `generic+initrd` profile. The harness must independently revalidate
the target, the accepted ELILO closure record, source/template identities, and
the step-149 authorization before invoking the runtime probe.

The expected result remains fail-closed for the real ELILO initrd-only
capability set: `boot=auto`, module state `unavailable`, run state `0`, layout
`unknown`, initrd capability `1`, GRUB capability `0`, and direct-generic
capability `0`, with reason `no supported initrd or GRUB preparation path was
detected`.

The execution captures and compares package inventory, Slackpkg metadata, boot
state, source identity, and configuration-template identity before and after
the probe. The authorization is consumed by the execution attempt; a failed
characterization or probe does not authorize a retry.

No repository refresh, package mutation, boot mutation, source/configuration or
contract change, shutdown, or reboot is authorized.

## State after step 149

Step 149 itself requires no machine action and is independent of later
Slackware publications. `pause_safe=true` remains valid until the single-use
execution is actually started.

The next stage is
`phase-1-configuration-module-mode-source-remediation-runtime-validation-slackware-15-post-current-rerun-execution`.
