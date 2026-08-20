# Phase 1 optional-module mode source remediation runtime-validation planning

Step 130 plans target runtime validation for the repository-level remediation
accepted through step 129. It authorizes no machine execution and changes no
runtime source, configuration template, or frozen contract.

## Objective

Repository regression is complete at 15/15 conforming mode-contract rows, but
the remediated `boot=auto` behavior still requires target runtime acceptance on
both mandatory Slackware targets. The runtime plan is deliberately minimal:
two machine executions total, one per target, with characterization and the
non-mutating runtime probe combined in each execution.

No reboot, package operation, boot-file mutation, or Slackware repository
refresh is part of this validation chain.

## Slackware 15.0 target

The established VM `vbox-slack15.vbox-slack15.org` remains the planned
Slackware 15.0 target. Its previously accepted boot profile is UEFI/ELILO with a
generic kernel and initrd.

The future target harness must first characterize the live system and confirm
its identity and boot profile. It must then evaluate the remediated boot-mode
probe without changing the guest. A runtime verdict is acceptable only when
`boot=auto` is runnable because an independently validated supported preparation
path exists. An ELILO installation must not be made runnable merely because
incidental preparation tools happen to be installed.

Characterization failure is a stop condition, not permission to alter the VM
during the acceptance execution.

## Slackware-current target

A new Slackware-current VM is the preferred runtime target. Its hostname is not
frozen in step 130; the exact FQDN will be bound by the later runtime-validation
authorization after the VM exists.

Before that binding, the VM should be prepared with the target profile required
by this project: GRUB with the generic kernel booted directly and no initrd for
that active kernel (`grub-direct-generic-no-initrd`). The future target harness
will combine characterization and runtime probing in one execution. It must
confirm the profile before accepting the expected `boot=auto` result of
`available`, runnable, with `direct-generic-no-initrd` selected.

A VirtualBox snapshot before the VM is formally bound is recommended for easy
repetition, but the snapshot itself is not acceptance evidence.

## Why only two machine executions are planned

Step 128 proved the exact source delta and step 129 retained seven isolated
behavioral regressions, including the complete `mkinitrd-managed` path, the
validated direct-generic path, partial capability rejection, enabled strictness,
and disabled bypass. The target runtime work therefore does not need to create
artificial boot layouts or mutate a machine merely to repeat repository fixture
coverage.

The two target executions instead validate the code against real operating
system state:

1. Slackware 15.0 on the established VM;
2. Slackware-current on the new VM with the required direct-generic profile.

The physical Slackware-current machine is not part of the default plan. It is a
fallback only if a later review demonstrates that a required property cannot be
faithfully validated in the VM or explicitly requires hardware-specific
confirmation.

## Evidence and non-mutation boundary

Each future machine execution must produce one evidence `.tar.gz` and its
`.sha256` sidecar. The test instructions must include commands that copy both
files directly to `/home/promano` with ownership `promano:users`.

The future harnesses must capture enough pre/post state to prove that the
validation itself did not change packages, boot configuration, initrd state, or
the accepted source under test. They must not run `slackpkg update`, install or
upgrade packages, regenerate an initrd or GRUB configuration, or reboot the
machine.

Because no repository refresh is required, the planned runtime validation is
independent of Slackware-current publication timing. A later publication does
not invalidate a completed characterization/probe solely by existing in the
repository.

## Authorization and next stage

Step 130 does not authorize either machine execution. It records
`machine_execution_authorized=false`, preserves the closed source-change
boundary, and remains pause-safe.

A successful step 130 advances only to
`phase-1-configuration-module-mode-source-remediation-runtime-validation-authorization`.
That stage will freeze the actual target harnesses and, for Slackware-current,
bind the exact VM identity before any acceptance command is run.
