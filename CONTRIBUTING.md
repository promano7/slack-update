# Contributing to Slack-Update

Thank you for your interest in Slack-Update. The project is currently preserving and validating its shell reference implementation before any C port begins.

## Development phase gate

The roadmap in `README.md` is authoritative.

- Do not add C implementation code until the Phase 1 reference acceptance gate is complete.
- Keep the reference script under `tools/reference/slack-update-reference.sh` as the executable specification.
- During Phase 0, changes to the reference script are not allowed.
- During Phase 1, behavioral changes must be covered by an acceptance scenario, expected output, and expected exit code.
- Do not mix work from later roadmap phases into an earlier phase.

## Compatibility policy

Slackware 15.0 and Slackware-current are both mandatory targets. Changes to the
reference implementation, future C code, packaging, or documentation must not
assume that behavior observed only on one target is valid on the other. Record
target-specific requirements and provide detection or a safe fallback where the
two systems differ.

Slackware-current kernel package scripts may invoke `geninitrd` conditionally. Acceptance work must first bind the exact accepted candidate, boot-layout, restarted-chain, and downloaded-package records, then inspect the installed `/etc/default/geninitrd`, setup script, generator, custom hooks, cleanup settings, and automatic GRUB behavior without sourcing or executing them. A recognized versioned kernel symlink transition alone is not sufficient to authorize apply. Executable GenInitrd hooks must be hash-bound to reviewed evidence, copied without execution, statically inspected, and correlated with read-only DKMS state before any apply-ready transaction can be designed. When a fresh Slackware-current candidate set changes the target kernel, the DKMS review must be repeated against the newly accepted candidate, boot, chain-restart, exact-package, and GenInitrd-policy records; a previously accepted no-op result is historical only. A command generator must be invoked without `--run`, its output parsed as an argument vector without evaluation, and any target-kernel projection must remain explicitly non-executable until a later isolated post-install simulation is accepted. After a Slackware-current kernel target changes, this command preflight must bind the fresh normal-update, boot-layout, chain-restart, exact-package, GenInitrd-policy, and no-op DKMS records; historical target records are not reusable. The cached package filename and digest must be loaded from the accepted exact-package record; version-specific package hashes must not be used as operational cache expectations in executable preflights. Harnesses may reference fixture values only to prove that the preflight loads that single source of truth. When Slack-Update temporarily owns GRUB regeneration, the active GenInitrd policy must be replaced and restored atomically from the same directory, byte-bound to the reviewed original and override, covered by signal cleanup, and forbidden from overwriting concurrent external changes. A restoration failure is a package-transaction failure and must retain recovery material. A generated-initrd transition must then validate the exact post-update kernel record, package-owned kernel and modules, safe versioned initrd, named initrd link, and matching kernel-plus-initrd GRUB entries before atomic replacement; partial transitions fail closed.

## Language policy

Use English for:

- source-code identifiers;
- source-code comments;
- commit messages;
- documentation;
- developer-facing logs.

Keep user-facing strings suitable for later translation.

## Stable exit-code policy

Process exit codes `0` through `8` are a stable compatibility surface. Changes must
preserve their documented meanings and precedence. Codes `4` and `5` are successful
results with reboot guidance and must not be collapsed into a generic failure.
Intermediate event exit codes may represent raw external-command statuses, but the
final process status and final operation event must use the stable Slack-Update codes.
Any incompatible change requires explicit roadmap discussion and documentation before
implementation.

Acceptance validators must distinguish the broad `kernel_changes` package-group
indicator from explicit boot preparation. Updates to `kernel-firmware`,
`kernel-source`, or kernel headers may set `kernel_changes=true` without requiring
initrd or bootloader work. Stable code `5` is required only when the structured
boot result sets `initrd_required=true` or `grub_required=true`; critical
userspace packages without boot preparation use stable code `4`.

## Commit messages

Use the following format when a scope improves clarity:

```text
<type>(<scope>): <imperative summary>
```

Common types are `build`, `docs`, `feat`, `fix`, `refactor`, `test`, `chore`, `ci`, and `security`.

Examples:

```text
docs: complete the initial repository structure
refactor(reference): split the update workflow into functions
test(reference): add the no-updates acceptance fixture
```

Commit subjects must:

- use the imperative mood;
- remain concise;
- not end with a period;
- describe one focused change.

Use the commit body to explain non-obvious decisions, compatibility changes, or safety implications.

## Reference-script changes

Before submitting a change to the reference script:

1. Run `bash -n tools/reference/slack-update-reference.sh`.
2. Run `tests/reference/test-package-name-parsing.sh` when package records, package ownership, or SBo detection are affected.
3. Run `tests/reference/test-package-snapshots.sh` when package snapshot capture, validation, or comparison is affected.
4. Run `tests/reference/test-partial-slackware-update.sh` when Slackware failure handling or secondary-module sequencing is affected.
5. Run `tests/reference/test-sbo-target-selection.sh` when SBo queue parsing, target discovery, ABI rebuild candidates, broken-object ownership, or deterministic target-set merging is affected.
6. Run `tests/reference/test-sbo-dependency-order.sh` when generated queue constraints, dependency ordering, final ordered merging, or SBo queue submission is affected.
7. Run `tests/reference/test-sbo-options.sh` when queue build options, persistent overrides, option conflict handling, or final option-preserving submission is affected.
8. Run `tests/reference/test-sbo-personal-queue-protection.sh` when sbopkg system/local queue-directory resolution, private `sqg` configuration wrappers, queue workspaces, symlink handling, invocation isolation, or cleanup is affected.
9. Run `tests/reference/test-elf-static-inspection.sh` when ELF candidate filtering, `readelf` parsing, loader-cache handling, broken-object verification, or the non-execution boundary is affected.
10. Run `tests/reference/test-elf-architecture-resolution.sh` when ELF identity extraction, cache record structure, class/data/machine compatibility, multilib behavior, or architecture-aware verification is affected.
11. Run `tests/reference/test-initrd-installed-kernel.sh` when `mkinitrd.conf` parsing, installed kernel resolution, module-tree validation, initrd output selection, or boot safety reporting is affected.
12. Run `tests/reference/test-grub-blocked-after-initrd-failure.sh` when initrd-to-GRUB sequencing, boot action events, GRUB command guards, blocked boot reporting, or boot safety result diagnostics are affected.
13. Run `tests/reference/test-grub-atomic-replacement.sh` when staged GRUB generation, syntax validation, active-file fingerprinting, temporary-file cleanup, permission preservation, or atomic replacement is affected.
14. Run `tests/reference/test-signal-cleanup.sh` when signal traps, instance locking, runtime cleanup, GRUB temporary cleanup, SBo workspace cleanup, or interruption statuses are affected.
15. Run `tests/reference/test-error-exit-codes.sh` when stable result mapping, early failure handling, runtime setup, logging setup, JSON/NDJSON completion output, or process exit behavior is affected.
16. Run `tests/reference/test-cron-minimal-environment.sh` when command-path normalization, root environment defaults, non-interactive behavior, detached output, prompt suppression, runtime permissions, or cron compatibility is affected.
17. Run `tests/reference/test-no-updates-acceptance-harness.sh` when the no-updates real-system scenario, its expected fixtures, failure diagnostics, evidence ownership, archive publication, or JSON contract is affected.
18. Run `tests/reference/test-normal-update-acceptance-harness.sh` when normal-update candidate detection, Slackware architecture tags, package classification, physical-host safety gates, portable SHA-256 sidecars, apply validation, or evidence publication is affected.
19. Run `tests/reference/test-slackpkg-postinstall-policy.sh` when slackpkg post-install arguments, deferred `.new` handling, pending-file enumeration, human warnings, or structured-result metadata is affected.
20. Run `tests/reference/test-kernel-boot-preflight-harness.sh` when firmware detection, boot-loader classification, mkinitrd evidence, kernel metadata, blacklist verification, boot-artifact capture, or kernel-preflight publication is affected.
21. Run `tests/reference/test-elilo-generator-preflight-harness.sh` when ELILO directive parsing, versioned kernel-source mapping, EFI-copy validation, generator probing, non-execution guards, or ELILO evidence publication is affected.
22. Run `tests/reference/test-elilo-kernel-transaction-preflight-harness.sh` when Slackpkg kernel-candidate resolution, version comparison, versioned EFI naming, planned ELILO rewriting, free-space guards, transaction boundaries, or transaction-preflight evidence publication is affected.
23. Run `tests/reference/test-elilo-kernel-transaction-apply-harness.sh` when exact per-package Slackpkg download statuses, cached-package resolution, blacklist restoration, old/new kernel coexistence, generated mkinitrd parsing, versioned EFI staging, ELILO fallback entries, atomic activation, rollback cleanup, or apply evidence publication is affected.
24. Run `tests/reference/test-elilo-oldkernel-retention-preflight-harness.sh` when retention timing, later-boot evidence, package-database compatibility symlinks, active/rollback package records, state-capture comparison, ELILO two-entry validation, shared package-path inventory, cleanup planning, portable evidence sidecars, destination verification, or no-cleanup source guards are affected.
25. Run `tests/reference/test-kernel-cleanup-plan.sh` when cleanup inventory schema, exact active/rollback package sets, active archive coverage, module-tree requirements, boot-transaction metadata, ELILO oldkernel-removal planning, GRUB regeneration planning, no-op single-kernel handling, or cleanup authorization boundaries are affected.
26. Run `tests/reference/test-kernel-cleanup-dry-run.sh` when mandatory dry-run gating, plan identity, simulation-only authorization, proposed command vectors, failure injection, recovery planning, backend transaction rendering, or no-mutation guarantees are affected.
27. Run `tests/reference/test-current-kernel-boot-preflight-harness.sh` when Slackware-current monolithic kernel layout, repository kernel transition, target file-inventory deferral, module or kernel-image ownership, direct-generic versus mkinitrd-managed classification, `BOOT_IMAGE` validation, GRUB discovery, apply-readiness gating, or current-kernel evidence publication is affected.
28. Run `tests/reference/test-current-direct-generic-boot-policy.sh` when direct generic boot detection, exact `BOOT_IMAGE` parsing, active kernel ownership, no-initrd policy selection, post-update generic-kernel validation, generated GRUB target validation, or boot-safety result mapping is affected.
29. Run `tests/reference/test-current-kernel-package-preflight-harness.sh` when accepted candidate/boot/restart binding, exact Slackpkg kernel downloads, cache resolution, package-archive path safety, target image or module inventory, non-executed `doinst.sh` policy, GRUB evidence generation, portable sidecars, or transaction apply denial is affected.
30. Run `tests/reference/test-current-geninitrd-policy-preflight-harness.sh` when installed GenInitrd script recognition, non-evaluating policy parsing, generator selection, automatic GRUB behavior, custom hook inventory, or policy evidence publication is affected.
31. Run `tests/reference/test-current-geninitrd-dkms-hook-preflight-harness.sh` when reviewed hook identity, hook metadata or syntax, static command-surface capture, read-only DKMS status, DKMS source/module inventory, or immutable apply denial is affected.
32. Run `tests/reference/test-current-geninitrd-command-preflight-harness.sh` when command-generator identity, command-output-only invocation, inert argument parsing, target-kernel projection, cached-package binding, or no-execution guarantees are affected.
33. Run `tests/reference/test-current-geninitrd-grub-ownership-preflight-harness.sh` when accepted chain linkage, GenInitrd policy precedence, automatic GRUB suppression, evidence-local policy staging, transaction ordering, recovery boundaries, or exclusive Slack-Update GRUB ownership are affected.
34. Run `tests/reference/test-geninitrd-grub-ownership-engine.sh` when same-directory policy staging, atomic activation or restoration, cleanup recovery, concurrent-change handling, backup retention, apply workflow ordering, or ownership-state reporting is affected.
35. Run `tests/reference/test-current-geninitrd-post-state.sh` when generated-initrd expectation, post-update kernel ownership, versioned initrd validation, named initrd links, legacy-initrd exclusion, or kernel-plus-initrd GRUB validation is affected.
36. Run `tests/reference/test-current-candidate-chain-refresh-preflight-harness.sh` when fresh Slackware-current metadata refresh, embedded preflight composition, candidate-set hashing, target-kernel companion validation, stale-chain classification, or no-apply evidence publication is affected.
37. Run `tests/reference/test-current-kernel-chain-restart-preflight-harness.sh` when accepted refresh binding, target-specific boot-preflight composition, nested target-image metadata state, diagnostic restart evidence, nested archive verification, or restarted-chain no-apply boundaries are affected.
38. Confirm that destructive commands are not exercised outside an isolated or explicitly recoverable Slackware test system.
39. Record the relevant acceptance scenario.
40. Preserve deterministic output and exit-code behavior.
41. Exercise `enabled`, `disabled`, and `auto` when changing optional-module behavior.
42. Ensure every new or modified comment is written in English.

Never run the apply workflow on a production machine merely to validate a contribution.


## Current Slackware-current ownership preflight

After accepting the corrected `6.18.42` GenInitrd command evidence, run only the non-destructive ownership preflight:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-grub-ownership-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

Do not run normal-update apply. Copy the printed evidence archive and sidecar directly to `/home/promano`, verify the sidecar there, and include both files with the review.

## Pull requests

A pull request should include:

- the roadmap item addressed;
- the reason for the change;
- the validation performed;
- any remaining risks or follow-up work.

Keep unrelated changes in separate pull requests and commits.
