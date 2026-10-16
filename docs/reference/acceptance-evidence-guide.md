# Acceptance work and evidence navigation

This guide connects the [current roadmap](../roadmap.md#remaining-phase-1-work)
to existing inventories, scenario labels and evidence records. It changes no
acceptance criteria and grants no execution. The original records and their
complete linked requirements remain authoritative for their scope.

## Read the inventory progression

The [step 175 inventory](phase-1-acceptance-matrix-remainder-inventory.md)
recorded six families/24 scenarios. The later
[execution-control closure review](phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.md)
accepted that four-scenario family in its recorded runtime scope and produced
the [five-family/20-scenario residual inventory](../../tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv).
These are successive inventories, not competing current counts.

The labels below render the residual inventory for reading. They do not mark
scenarios complete, replace detailed contracts or justify repeating closed work.
Repository refresh is conditional on a later selected scenario, not a standing
requirement to refresh metadata before every documentation step.

## Kernel package edge

Original family: `kernel-package-edge`.

- Kernel headers update without a kernel image update.

The historical kernel authorization chains cannot be reused. The unresolved
operational implementation and evidence work below is additional to this
single matrix label.

## Boot safety failures

Original family: `boot-safety-failure-paths`.

- Invalid or stale KERNEL_VERSION in mkinitrd.conf.
- mkinitrd failure leaves GRUB configuration untouched.
- GRUB generation failure leaves the active configuration untouched.
- Invalid staged GRUB syntax leaves the active configuration untouched.
- Concurrent GRUB configuration modification blocks replacement.
- Low free space on /.
- Low free space on /boot.

Use each scenario's fresh boundary and fail-closed boot assertions; listing
failure labels does not provide a test implementation or authorize fault injection.

## SBo and ELF optional runtime

Original family: `sbo-elf-optional-runtime`.

- ABI library update with installed SBo packages.
- SBo package with multiple dependencies.
- SBo build failure in the middle of a queue.
- Removed SBo package no longer present in the repository.
- Broken ELF object owned by an SBo package.
- Broken ELF object not owned by an SBo package.

The inventory requires an optional-module-capable acceptance target and separate
scenario authorization. A mock parser or queue result is not that runtime evidence.

## Cinnamon optional runtime

Original family: `cinnamon-optional-runtime`.

- Cinnamon installed and CSB updated.
- Cinnamon installed with graphical ABI changes.
- Cinnamon not installed.

Installed and absent cases retain their own scope. Configuration/mode validation
does not complete these distinct runtime scenarios.

## Flatpak optional runtime

Original family: `flatpak-optional-runtime`.

- Flatpak system installation only.
- Flatpak user installation only.
- Flatpak not installed.

Keep system and user installation scope explicit under a fresh optional-module
boundary. The inventory itself authorizes no Flatpak action.

## Keep native operational obligations separate

The roadmap's operational backlog has 16 native gaps, 46 qualified proofs,
52 native case templates and 12 independent raw evidence groups. These counts
are not an alternate total for the 20 historical matrix scenarios and must not
be added to or substituted for them.

Read the [native prerequisites](phase-1-operational-native-implementation-prerequisites.md),
[source/gap reconciliation](phase-1-operational-source-native-gap-reconciliation.md),
[whole-entry/two-platform audit](phase-1-operational-joint-whole-entry-two-platform-member-impact-audit-review.md)
and [integrated findings](phase-1-operational-joint-integrated-findings-interaction-disposition-review.md)
for complete criteria and dependencies. Original proof-and-case relations require
both sides; a count or an authored review is not a native result.
The [A/R/D decision reference](phase-1-operational-joint-unselected-a-r-d-decision-brief-review.md)
keeps alternatives unselected and the separate decision/review/grant gates intact.

## Find accepted historical evidence without replaying it

These selected records provide entry points into accepted historical coverage.
They describe their recorded source, scenario, target and time, not a present host.

| Historical coverage | Entry record |
| --- | --- |
| No-change behavior on Slackware 15.0 | [Accepted no-updates record](../../tests/fixtures/reference/acceptance/no-updates/slackware-15.0-accepted.json) |
| No-change behavior on Slackware-current | [Accepted no-updates record](../../tests/fixtures/reference/acceptance/no-updates/slackware-current-accepted.json) |
| Slackware-current rollback return | [Accepted rollback closure](../../tests/fixtures/reference/acceptance/normal-update/slackware-current-rollback-return-verification-closure-20260811-accepted.json) |
| Slackware 15.0 ELILO cleanup | [Accepted scenario closure](../../tests/fixtures/reference/acceptance/kernel-boot/slackware-15.0-elilo-oldkernel-cleanup-scenario-closure-checkpoint-20260817-accepted.json) |
| Configuration/module modes | [Workstream closure and lineage](configuration-module-mode-workstream-closure-checkpoint.md) |
| Execution-control failure scenarios | [Runtime closure and evidence identity](phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.md) |

The [step 175 inventory](phase-1-acceptance-matrix-remainder-inventory.md) also
identifies accepted core coverage excluded from replay. A historical unchecked
roadmap box or an archive's former "Current" heading does not reopen it.

Read each record's actual status, capture basis, source/target binding, criteria,
outcome and limitations. Do not infer acceptance from a filename or replace
missing evidence with a neighboring record. A sanitized JSON record may identify
an original archive; it is not necessarily the archive or complete raw capture.

Mock tests, authored audits, actual native evidence, reported Git receipts and
externally confirmed repository pauses support different claims. A successful
documentation commit proves none of the remaining native obligations. Use the
[reference index](README.md) and [CHANGELOG](../../CHANGELOG.md) for further navigation.
