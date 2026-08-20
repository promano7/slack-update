# Phase 1 optional-module mode source remediation runtime-validation authorization

Step 131 reviews and authorizes the narrow runtime-validation scope planned in
step 130. It does not execute either Slackware target and does not yet make a
machine authorization consumable.

## Authorization decision

The two-execution runtime-validation scope is approved. After target binding is
complete, the accepted validation may contain exactly one non-mutating execution
on Slackware 15.0 and exactly one non-mutating execution on Slackware-current.
No reboot is authorized.

The authorization remains held because the new Slackware-current VM does not
yet have a frozen FQDN. Therefore step 131 records
`runtime_validation_scope_authorized=true` while preserving
`machine_execution_authorized=false` and `authorization_consumable=false`.
This prevents either target execution from starting before both target
identities and the execution harnesses are frozen together.

## Slackware 15.0 authorization envelope

The existing VM remains bound to `vbox-slack15.vbox-slack15.org` with the
accepted `elilo-generic-with-initrd` profile. Its scope is approved, but its
single execution is intentionally held until the common target-binding freeze
is complete.

The future execution must characterize the live boot state before accepting a
runtime verdict. `boot=auto` may be runnable only when the program's selected
preparation path is independently supported by the actual target state.
Incidental tools must not turn an unsupported ELILO layout into a runnable boot
module.

## Slackware-current authorization envelope

The new VM remains the preferred Slackware-current target. Its required profile
is `grub-direct-generic-no-initrd`, but its exact hostname is deliberately not
invented in step 131. The VM must exist before that FQDN is frozen.

The current scope is approved, but execution remains blocked until a later
repository-only target-binding stage records the exact VM FQDN and binds the
actual execution harnesses. That binding stage must not itself run the target
validation.

Once bound, the single current execution must combine characterization and the
runtime probe. A profile mismatch is a stop condition; it is not permission to
change GRUB, create an initrd, install packages, or otherwise reshape the guest
during acceptance.

## Mutation and repository boundary

The authorized protocol permits observation only. It forbids package changes,
boot changes, source changes, configuration-template changes, repository
refresh, and reboot. In particular, `slackpkg update`, package installation or
upgrade, `mkinitrd`, GRUB regeneration, ELILO changes, and shutdown/reboot are
outside the authorization.

The accepted source under test remains bound to SHA-256
`c5fcf486469e7ca6cbbc894a21899ae9330cbe5ecc6247372728b9ee8caff86c`.
The runtime chain has no dependency on Slackware repository publication timing.

## Evidence boundary

Each eventual target execution must produce one evidence `.tar.gz` and one
`.sha256` sidecar. Instructions must copy both directly to `/home/promano` and
leave them owned by `promano:users`. Those files must be preserved until their
corresponding acceptance review is complete.

## Physical Slackware-current fallback

The physical Slackware-current host remains outside the default authorization.
It receives zero executions. Reintroducing it requires a new explicit review
showing that a required property cannot be validated faithfully in the VM or
that hardware-specific confirmation is necessary.

## Next stage and safe pause

Step 131 itself requires no machine action and remains pause-safe. It advances
only to
`phase-1-configuration-module-mode-source-remediation-runtime-validation-target-binding`.

That stage is intentionally blocked on the new Slackware-current VM existing so
its real FQDN can be frozen. Until that binding is complete, no runtime machine
execution is authorized.
