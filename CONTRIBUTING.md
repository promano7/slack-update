# Contributing to Slack-Update

Thank you for your interest in Slack-Update. The project is currently preserving and validating its shell reference implementation before any C port begins.

## Development phase gate

The [development roadmap](docs/roadmap.md) defines the phase gates. Detailed
reference contracts remain authoritative for their own scope; historical
README archives and per-step summaries do not supersede them.

- Do not add C implementation code until the Phase 1 reference acceptance gate is complete.
- Keep the reference script under `tools/reference/slack-update-reference.sh` as the executable specification.
- During Phase 0, changes to the reference script are not allowed.
- During Phase 1, behavioral changes must be covered by an acceptance scenario, expected output, and expected exit code.
- Do not mix work from later roadmap phases into an earlier phase.

## Documentation policy

- `README.md` contains the project introduction, one concise current status,
  installation/development entry points, basic usage and links.
- `CHANGELOG.md` records changes by step or version. Put per-step test results,
  commit/acceptance history and delivery notes there when they are useful.
- `docs/roadmap.md` holds the development plan and phase completion gates.
- `docs/reference/` holds detailed audits, contracts and evidence reviews.
  Keep historical records explicitly historical and retain their original scope.
- Change the README only when information useful for understanding or using
  the project changes. A new step, test run, commit, push or audit checkpoint
  alone is not a reason to edit it.
- Update the existing current-status summary when it changes; do not prepend
  another "Current" section. Link to detailed records instead of duplicating them.
- Label planned interfaces and components as planned. Describe installation
  and usage that the repository actually supports.
- Documentation moves do not amend contracts, reopen consumed authorizations,
  establish native conformance or complete an implementation phase.
- Historical checkpoint harnesses that bind exact README bytes or whole-repository
  inventories require their matching historical source snapshot. Do not weaken
  frozen baselines or rewrite old fixtures to make them pass on a later checkout.

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

## Choosing verification scope

The [testing guide](docs/testing.md) distinguishes documentation checks,
focused regressions, historical checkpoint snapshots and real acceptance.
For delivery archive validation changes, run
`python3 tests/reference/test-delivery-zip.py` and validate the exact final archive
with `tools/reference/verify-delivery-zip.py`. Explicitly select embedded ZIPs
when their validity is claimed. See the
[delivery integrity scope](docs/reference/delivery-archive-integrity.md).

The mappings below still govern reference-script changes; frozen historical
baselines retain their original scope. The prepared
[524-531 integrated review](docs/reference/repository-regression-block-524-531.md)
selects86 current commands FRESH, zero normal-result reuse: exact ordered82 from
[516-523](docs/reference/repository-regression-block-516-523.md), then cleanup
binding/lifecycle/admission/apply drivers in introduction order. Seven actual
steps524-530 are accepted; final531 actual acceptance and separate whole inherited-
condition/new-effect review remain due. README is updated in this final preparation;
only later complete actual acceptance/review can confirm a new scoped STATIC pause.
Last qualified outer pause523 remains historical. No native authority or phase gate.

The [preintegration review](docs/reference/repository-regression-block-524-530-preintegration.md)
retains the original legacy personal-queue fixture failure and its114-check repair
through verified real cleanup between independent scenarios. Preserve earlier
assertions and unresolved state; do not clear metadata to bypass admission.
For cleanup/admission changes run the four named current regressions and the
personal-queue test when fixture isolation changes. The
[testing guide](docs/testing.md#current-bounded-block-and-integrated-selection)
records current commands/dependencies/private-supplied limits and installed-initrd
negative-output normalization. No historical snapshot/native matrix is implied.
Workspace count/listing/parent helper and apply checks below retain their exact
scopes. Unsafe source-bound512/516/519/524/527 audits must not run on repaired current
source; original observations remain history, not current safety passes.

The [500-507 selection](docs/reference/repository-regression-block-500-507.md),
[492-499 selection](docs/reference/repository-regression-block-492-499.md),
[484-491 selection](docs/reference/repository-regression-block-484-491.md),
[475-483 selection](docs/reference/repository-regression-block-475-483.md) and earlier
reviews retain their historical scopes, failures and corrections. Incomplete491
binary history and unknown extra provenance remain OPEN. An archive checksum or
correct current inventory does not close those questions.

A new pause needs complete FINAL actual acceptance FIRST, THEN a separate reading
of EVERY WHOLE inherited header/condition/EVERY exact nested original and ALL new
effects/obligations/cleanup/limits, with stored-original comparison. Counts, hashes,
summaries, indices and prior reviews cannot replace it. Static repository work
neither changes native criteria nor opens consumed authority or a new native run.

## Reference-script changes

For ELF path-emission status, run `python3 tests/reference/test-elf-emission-status.py`
and `python3 tests/reference/test-elf-emission-apply.py`; see the
[direct36/apply48 scope](docs/reference/elf-emission-status.md). Retain failures
across every iteration without stopping input early or publishing/counting a
failed scan. Historical532/536 audits and scopes stay unchanged and must refuse
repaired source before fixtures; exclude them from normal integration.

For real initial ELF scan through apply/owner/builder/stable mapping, run
`python3 tests/reference/test-elf-initial-inspection-apply.py`; see the
[96-case composition scope](docs/reference/elf-initial-inspection-apply.md).
Preserve failed-scan owner/builder gates, raw0/stable2 distinction, prior-list
meaning and exact shared owner-scaffold hash. Installed leaves remain supplied.

For initial ELF diagnostic/staging composition, run
`python3 tests/reference/test-elf-initial-inspection-diagnostics.py`; see the
[72-case scope](docs/reference/elf-initial-inspection-diagnostics.md). Preserve
failed metadata/last-emission status through reporting and prior publication/count.
These cases leave earlier producer-write masking/resolver skipping separate.

Before submitting a change to the reference script:

For initial ELF metadata-error handling, also run
`python3 tests/reference/test-elf-initial-inspection-errors.py`; see its
[96-case scope](docs/reference/elf-initial-inspection-errors.md). Preserve prior
published list/count on classifier2 and producer subshell failure status. Keep
the historical532 audit unchanged: it must refuse repaired source and is excluded
from current normal checks. Scan/cache-workflow/cache-lookup initial-error
expectations change in533; preserve their first failures and all remaining cases/
assertions. Private checks do not change native criteria.

1. Run `bash -n tools/reference/slack-update-reference.sh`.
   Run `python3 tests/reference/test-runtime-lifecycle.py` when real state initialization, early cleanup bindings, setup/EXIT composition or private lock lifecycle changes. Its [lifecycle scope](docs/reference/runtime-lifecycle.md) distinguishes supplied failures, real cleanup and preserved prior resources; keep main, logging, signal and lock tests for their separate boundaries.

   Run `python3 tests/reference/test-elf-unresolved-display.py` when unresolved-list rendering and its publication guard change; see the [display scope](docs/reference/elf-scan-workflow.md#unresolved-list-display-failure-before-publication).

   Run `python3 tests/reference/test-elf-cache-construction.py` for cache construction/order/publication/count changes, and `python3 tests/reference/test-elf-cache-workflow.py` for their propagation through real dependency/scan/recheck/report helpers. The [construction](docs/reference/elf-cache-construction.md) and [workflow](docs/reference/elf-cache-workflow.md) scopes retain supplied metadata/faults, partial publication and cleanup limits. These checks do not replace metadata, architecture, main result or native acceptance scopes.

   Run `python3 tests/reference/test-boot-artifact-validation.py` when version/scalar readers, installed-kernel selection, initrd-output precedence or generated GRUB validation changes. It uses private files, real parser/awk/chmod and a supplied GRUB checker; see [the boot artifact scope](docs/reference/boot-artifact-validation.md). Preserve the distinction between text matching, actual artifact binding and native boot acceptance; keep coordinator and transaction regressions for their separate boundaries.

   Run `python3 tests/reference/test-runtime-logging.py` when runtime path/temporary-file setup, log descriptor routing, text filtering or retention changes. It uses private files, real sed/tee/find and supplied state/date/mktemp callbacks; see [the runtime/logging scope](docs/reference/runtime-logging.md). Keep main setup/completion and trap/lock regressions for their separate boundaries; the separate cron regression now uses private local mirror fixtures and the real preflight, as described in [its scope](docs/reference/cron-minimal-environment.md).

   Run `python3 tests/reference/test-elf-scan-workflow.py` when ELF traversal, error rendering, broken-list replacement or post-build recheck coordination changes. It uses real private files/coreutils/path helpers with supplied cache/dependency callbacks, quiet/partial-output failures and a real private missing-root find failure; see [the ELF scan workflow scope](docs/reference/elf-scan-workflow.md). Initial traversal/order/count failures must return failure before publication, and publication errors must be reported. Step 478 also checks verification ordering/copy failures and nonempty unterminated records. Step 479 checks final resolved-list clearing before announcing success. Step 480 requires failed diagnostic/result initialization to stop before cache refresh, while preserving empty/missing verification-list early returns. Step 481 requires failed diagnostic rendering/clearing to return failure before publication; rendering failure must preserve diagnostic bytes. Partial copy effects, unresolved-list display and individual reader errors retain their documented limits; cache construction, metadata parsing, final result mapping and native acceptance retain separate scopes.

   Run `python3 tests/reference/test-elf-metadata.py` when static magic/path resolution, readelf text parsing, architecture cache matching or missing-dependency classification changes. It uses private files, real parsers/coreutils and supplied readelf output; see [the ELF metadata scope](docs/reference/elf-metadata.md). Run the architecture-resolution regression with its jq requirement; cache production, scanning/recheck, workflow and native acceptance retain separate scopes.

   Run `python3 tests/reference/test-sbo-workflow.py` when SBo refresh/generation sequencing, core/ABI coordination, generation-ready gating, final submission or post-build recheck propagation changes. It calls real coordinators with supplied commands/collectors and private lists; see [the SBo workflow scope](docs/reference/sbo-workflow.md). Keep real queue-file/configuration, ELF, final result mapping and native acceptance boundaries separate.

   For SBo count/removal changes, also select `test-sbo-final-queue-count.py`,
   `test-sbo-core-queue-count.py`, `test-sbo-abi-queue-count.py`,
   `test-sbo-option-map-count.py` and `test-sbo-queue-reset.py` through `python3`
   under `tests/reference/`. Their [final](docs/reference/sbo-final-queue-count.md),
   [core](docs/reference/sbo-core-queue-count.md), [ABI](docs/reference/sbo-abi-queue-count.md),
   [option-map](docs/reference/sbo-option-map-count.md) and
   [removal](docs/reference/sbo-queue-reset.md) scopes distinguish preserved counters,
   published files, partial effects and blocked callbacks. Run
   `python3 tests/reference/test-sbo-count-apply-composition.py` for their selected
   propagation through real private apply/result mapping; the
   [500-507 integration](docs/reference/repository-regression-block-500-507.md)
   describes192 cases and supplied boundaries. No rollback/global-cleanup/native
   guarantee follows; retain original diagnostic failures and oracle corrections.

   For private workspace count failures, run
   `python3 tests/reference/test-sbo-workspace-count.py` and
   `python3 tests/reference/test-sbo-workspace-apply-composition.py`; their
   [helper](docs/reference/sbo-workspace-count.md) and
   [apply scope](docs/reference/sbo-workspace-apply-composition.md) retain76/136 cases.
   For failed final-listing removal, run
   `python3 tests/reference/test-sbo-workspace-listing-removal.py` and
   `python3 tests/reference/test-sbo-workspace-listing-apply-composition.py`; see the
   [54-case helper](docs/reference/sbo-workspace-listing-removal.md) and
   [84-case apply scope](docs/reference/sbo-workspace-listing-apply-composition.md).
   For destination-parent assignment/status changes, run
   `python3 tests/reference/test-sbo-workspace-parent-assignment.py` and
   `python3 tests/reference/test-sbo-workspace-parent-apply-composition.py`; see the
   [104-case helper](docs/reference/sbo-workspace-parent-assignment.md) and
   [176-case apply scope](docs/reference/sbo-workspace-parent-apply-composition.md).
   Select companion workflow/result checks for the affected callers. Preserve
   earlier-copy counters, raw/stable/readiness distinctions and selected retained
   resources; these are not rollback, universal-cleanup or native guarantees.

   Run `python3 tests/reference/test-sbo-queue-files.py` when queue directory enumeration, candidate installation, target-set merging, core/extras ordering or option-map precedence changes. It checks real private files/coreutils and supplied selected faults; see [the queue file scope](docs/reference/sbo-queue-files.md). Run the graph, dependency-order, target-selection and option regressions alongside it; installed database and builder workflows remain separate boundaries.

   Run `python3 tests/reference/test-sbo-queue-graph.py` with the existing SBo dependency-order, target-selection and option checks when queue constraints, edge deduplication, deterministic ordering, cycle handling or parser-to-graph propagation changes. It compares real Bash/AWK helpers with an independently authored model and private graph bytes; see [the graph regression scope](docs/reference/sbo-queue-graph.md). Keep directory collectors, build submission and native acceptance separate.

   Run `python3 tests/reference/test-mirror-probe.py` when mirrors-file selection/counting, ChangeLog target construction, local readability, remote probe arguments or real mirror-to-check-helper propagation changes. It uses private files and supplied discovery/transport/package callbacks; see [the mirror probe scope](docs/reference/mirror-probe.md). Keep native source trust, repository validity and network acceptance separate.

   Run `python3 tests/reference/test-check-workflow.py` when check command outcomes, mirror-error fallback, event ordering or workflow status propagation changes. Mirror/command/event/summary callbacks are supplied; see [the check workflow scope](docs/reference/check-workflow.md). Keep JSON and main-completion checks for their separate output boundaries.
   Run `python3 tests/reference/test-human-summary.py` when apply/check human summary text, display branches, list formatting, module labels or footer behavior changes. It calls real renderers with authored state, private lists and a supplied clock; see [the human summary scope](docs/reference/human-summary.md). Keep mapper/JSON/workflow and native acceptance boundaries separate.

   Run `python3 tests/reference/test-dry-run-workflow.py` when dry-run inspection sequencing, queue failure cleanup, warning propagation or planning return precedence changes. It calls the real orchestrator with supplied inspections and private files; see [the dry-run workflow scope](docs/reference/dry-run-workflow.md). Keep plan-rendering, JSON and native acceptance claims separate.

   Run `python3 tests/reference/test-dry-run-environment.py` when planning availability flags, disabled-mode discovery gates or private boot/Cinnamon path predicates change. It models command discovery and uses real private file predicates; see [the environment inspection scope](docs/reference/dry-run-environment.md). Presence/executable predicates do not establish usable native configuration or builders.

   Run `python3 tests/reference/test-dry-run-plan.py` when human planning messages, command descriptions, list/option formatting or module rendering precedence changes. It calls the real renderers with supplied state, private files, real sed and a fixed clock callback; see [the human plan scope](docs/reference/dry-run-plan.md). Review its authored text fixture alongside message changes; rendered commands do not establish native execution or configuration validity.

   Run `python3 tests/reference/test-package-change-detection.py` when ABI/kernel snapshot comparison, critical/Cinnamon trigger selection, kernel package-group requests or detector-to-boot-policy propagation changes. It uses real helpers/policy and private snapshots; see [the change detector scope](docs/reference/package-change-detection.md). Keep snapshot validation, native package state and stable-result checks separate.

   Run `python3 tests/reference/test-package-snapshot-boundaries.py` when snapshot validation, temporary capture stages, destination preservation or before/after wrapper resets change. It uses owned private databases/files, real coreutils/findutils and selected failure callbacks; see [the snapshot boundary scope](docs/reference/package-snapshot-boundaries.md). Keep workflow, installed-database and native consistency claims separate.

   Run `python3 tests/reference/test-partial-update-policy.py` when raw action-result classification or secondary-module blocking assignments change. It calls the real in-memory helpers with supplied state; see [the partial-update helper scope](docs/reference/partial-update-policy.md). Keep workflow sequencing, current shell projections and original native code-20 criteria separate.

   Run `python3 tests/reference/test-slackpkg-update.py` when package-action sequencing, postinstall arguments, raw status assignment or pending .new list collection changes. It supplies slackpkg and guarded root relocation, uses real private find/sort/wc and selected faults; see [the Slackpkg wrapper scope](docs/reference/slackpkg-update.md). Keep native /etc state, package effects and application-result acceptance separate.

   Run `python3 tests/reference/test-apply-early-exits.py` when baseline/ownership gates, package-result precedence, restoration/final-snapshot ordering or partial-update dispatch blocking changes. It calls the real apply prefix and classifier/blocker with supplied operations; see [the early-exit scope](docs/reference/apply-early-exits.md). Positive controls stop at a private continuation checkpoint before secondary dispatch.

   Run `python3 tests/reference/test-cinnamon-rebuild.py` when Cinnamon trigger gating, Git refresh/clone sequencing, private builder execution, subshell cwd isolation, result assignments or output routing changes. It supplies Git and selected cd failure, and executes inert private builders; see [the Cinnamon wrapper scope](docs/reference/cinnamon-rebuild.md). Keep native checkout trust, activation and build acceptance separate.

   Run `python3 tests/reference/test-flatpak-update.py` when the Flatpak command wrapper, discovery redirection, argument vector, stored raw status or consecutive-call behavior changes. It supplies discovery/command callbacks; see [the Flatpak wrapper scope](docs/reference/flatpak-update.md). Keep activation, apply orchestration, result mapping and native acceptance separate.

   Run `python3 tests/reference/test-apply-secondary-workflow.py` when optional apply sequencing, synchronization/selection/ELF blocking, queue cleanup, module state/raw-code reporting or normal workflow completion changes. It uses supplied operations and private files; see [the secondary-workflow scope](docs/reference/apply-secondary-workflow.md). Keep raw workflow returns distinct from main/application exit codes and native conformance.
   Run `python3 tests/reference/test-boot-preparation-workflow.py` when boot coordinator state precedence, initrd/GRUB callback ordering, prerequisite short-circuiting or action/module event payloads change. It calls the real coordinator with supplied operations and event callbacks; see [the boot workflow scope](docs/reference/boot-preparation-workflow.md). Keep the existing GRUB-after-initrd regression for its separate real guard/transaction coverage and result/serializer checks for their own boundaries.
   Run `python3 tests/reference/test-boot-module-policy.py` when boot activation, partial-path rejection, command/path requirement precedence or initrd/GRUB request gating changes. It uses private paths and supplied discovery/direct-probe callbacks; see [the boot policy scope](docs/reference/boot-module-policy.md). Keep the standalone direct-generic regression for its real private classifier/validator scope.
   Run `python3 tests/reference/test-optional-module-probes.py` when Flatpak/SBo/ELF/Cinnamon activation, dependency reason priority, probe-state reset or Cinnamon detection precedence changes. Availability/package predicates are modeled and checkout state is private; see [the optional-probe scope](docs/reference/optional-module-probes.md). Boot probing and the five-module dispatcher are outside this check.
   Run `python3 tests/reference/test-instance-lock.py` when lock acquisition/release, ownership flags, descriptor lifetime or lock-error handling changes. It uses real Linux advisory locks on private files with two explicitly modeled error cases; see [the instance-lock scope](docs/reference/instance-lock.md). Keep the signal-cleanup regression for actual interruption/trap coverage.
   Run `python3 tests/reference/test-result-precedence.py` when result-state calculation, stable-code priority, combined diagnostics or message-state reset changes. It calls the real mapper/helpers with authored state and private ELF-result files; see [the combined result scope](docs/reference/result-precedence.md). Keep stable-exit and JSON/event tests for their additional implementation/output coverage.
   Run `python3 tests/reference/test-main-completion.py` when main workflow dispatch, completion-time handling, mapper/result propagation or final-output selection/descriptor closure changes. It uses supplied setup/workflow/result callbacks and a fixed clock; see [the main completion scope](docs/reference/main-completion.md). Run the existing stable-exit and serializer tests for their actual implementations.
   Run `python3 tests/reference/test-main-setup-failures.py` when main privilege/lock short-circuiting, initializer selection, trap-installation ordering or logging-failure handling changes. It calls real main/parser with setup callbacks and stops before workflow dispatch; see [the main setup scope](docs/reference/main-setup-failures.md). Keep the stable-exit regression for real helper/result coverage.
   Run `python3 tests/reference/test-main-configuration-failures.py` when main configuration-failure status/routing, loader stage sequencing or its short-circuit changes. It uses the real private-file loader with environment/application/privilege callbacks and later effects prohibited; see [the main configuration scope](docs/reference/main-configuration-failures.md).
   Run `python3 tests/reference/test-configuration-application.py` when configuration-to-runtime scalar assignments, package-list splitting, reapplication or IFS preservation changes. It calls only the in-memory assignment function with supplied state; see [the configuration application scope](docs/reference/configuration-application.md).
   Run `python3 tests/reference/test-configuration-validation.py` when required configuration values, booleans, module modes, lexical path/package/remote/builder checks, ELF path splitting or validation diagnostics change. It validates authored state without applying settings; see [the configuration validation scope](docs/reference/configuration-validation.md).
   Run `python3 tests/reference/test-configuration-resolver.py` when configuration-file precedence, explicit-path rejection, source fallback or resolver diagnostics change. It uses exact relocated source, private files and modeled installed-file/readability predicates; see [the resolver scope](docs/reference/configuration-resolver.md).
   Run `python3 tests/reference/test-configuration-parser.py` when configuration grammar, key assignment, parser defaults or duplicate/unknown-key diagnostics change. It parses private files without resolving system configuration, validating values, applying settings or calling `main`; see [the configuration parser scope](docs/reference/configuration-parser.md).
   Run `python3 tests/reference/test-cli-arguments.py` when argument parsing, operation selection, output-mode exclusion or parser-state reset changes; see [the CLI parser regression scope](docs/reference/cli-arguments.md). This sources the reference and calls only `parse_arguments`, without dispatching `main` or any workflow. Run `python3 tests/reference/test-cli-early-exits.py` when help handling, argument rejection, early-exit routing or the boundary before configuration changes. It calls `main` with environment initialization replaced and later boundaries prohibited; see [the early-exit scope](docs/reference/cli-arguments.md#main-early-exit-regression).
2. Run `tests/reference/test-package-name-parsing.sh` when package records, package ownership, or SBo detection are affected.
3. Run `tests/reference/test-package-snapshots.sh` when package snapshot capture, validation, or comparison is affected.
4. Run `tests/reference/test-partial-slackware-update.sh` when Slackware failure handling or secondary-module sequencing is affected.
5. Run `tests/reference/test-sbo-target-selection.sh` when SBo queue parsing, target discovery, ABI rebuild candidates, broken-object ownership, or deterministic target-set merging is affected.
   For literal broken-object ownership and input-record reading, also run
   `python3 tests/reference/test-elf-owner-mapping.py`; see the
   [private manifest scope and failure limits](docs/reference/elf-owner-mapping.md).
   For owner-list allocation, lookup/filter/ordering failures and the pre-merge
   gate, also run `python3 tests/reference/test-elf-owner-collection.py`.
   For merged-list counting, publication and public-count assignment, also run
   `python3 tests/reference/test-elf-owner-publication.py`.
   For owner failure propagation through the real apply coordinator, builder
   wrapper and stable classifier, run `python3 tests/reference/test-elf-owner-composition.py`;
   read its supplied-operation and raw-status limits in the owner mapping scope.
6. Run `tests/reference/test-sbo-dependency-order.sh` when generated queue constraints, dependency ordering, final ordered merging, or SBo queue submission is affected.
7. Run `tests/reference/test-sbo-options.sh` when queue build options, persistent overrides, option conflict handling, or final option-preserving submission is affected.
8. Run `tests/reference/test-sbo-personal-queue-protection.sh` when sbopkg system/local queue-directory resolution, private `sqg` configuration wrappers, queue workspaces, symlink handling, invocation isolation, or cleanup is affected.
9. Run `tests/reference/test-elf-static-inspection.sh` when ELF candidate filtering, `readelf` parsing, loader-cache handling, broken-object verification, or the non-execution boundary is affected.
10. Run `tests/reference/test-elf-architecture-resolution.sh` when ELF identity extraction, cache record structure, class/data/machine compatibility, multilib behavior, or architecture-aware verification is affected.
11. Run `tests/reference/test-initrd-installed-kernel.sh` when `mkinitrd.conf` parsing, installed kernel resolution, module-tree validation, initrd output selection, or boot safety reporting is affected. Step 476 aligns its stale initrd-only auto expectation with the accepted steps 122/128/129 contract. Its 90 checks preserve incomplete-path rejection, complete managed capability discovery and later unsafe-scalar rejection; the reference is unchanged. The original 1/69 failure remains historical evidence. See [the fixture alignment](docs/reference/boot-artifact-validation.md#installed-kernel-fixture-alignment) and [known limits](docs/testing.md#known-test-failures-and-fixture-repair).
12. Run `tests/reference/test-grub-blocked-after-initrd-failure.sh` when initrd-to-GRUB sequencing, boot action events, GRUB command guards, blocked boot reporting, or boot safety result diagnostics are affected.
13. Run `tests/reference/test-grub-atomic-replacement.sh` when staged GRUB generation, syntax validation, active-file fingerprinting, temporary-file cleanup, permission preservation, or atomic replacement is affected.
14. Run `tests/reference/test-signal-cleanup.sh` when signal traps, instance locking, runtime cleanup, GRUB temporary cleanup, SBo workspace cleanup, or interruption statuses are affected.
15. Run `tests/reference/test-error-exit-codes.sh` when stable result mapping, early failure handling, runtime setup, logging setup, JSON/NDJSON completion output, or process exit behavior is affected.
   Also run `python3 tests/reference/test-json-control-escaping.py` when shared JSON string escaping, string arrays, final result string fields, or NDJSON event string fields are affected. It uses supplied data and Python's standard JSON decoder without running `main()` or a system workflow; see [the regression scope](docs/reference/json-control-escaping.md).
   Run `python3 tests/reference/test-check-json-result.py` when final check-result fields, JSON types, check status mapping or diagnostic precedence are affected; see [the supplied-state cases and limits](docs/reference/check-json-result.md).
   Run `python3 tests/reference/test-dry-run-json-result.py` when dry-run result fields, planned command serialization, module diagnostics or nested arrays/statuses are affected; see [the supplied-data regression scope](docs/reference/dry-run-json-result.md). Run all five consumers when `json_result_test_support.py` changes: check, dry-run, apply, event NDJSON and SBo option JSON. See [the current test dependencies and limits](docs/testing.md#current-json-and-ndjson-checks).
   Run `python3 tests/reference/test-apply-json-result.py` when final apply result fields, boot/module reporting or supplied-state precedence are affected; see [the supplied apply-result scope](docs/reference/apply-json-result.md). Include this test when changing shared JSON-result support.
   Run `python3 tests/reference/test-event-ndjson.py` when event fields, wrappers, sequence state, descriptor routing or final event diagnostics/codes are affected; see [the supplied-event scope](docs/reference/event-ndjson.md). Include it when changing shared JSON-result support.
   Run `python3 tests/reference/test-sbo-option-json.py` when SBo option JSON projection or its dry-run/apply supplied-case helpers change; see [EOF behavior and focused regressions](docs/reference/sbo-option-json.md). Preserve upstream option validation and package-submission boundaries.
16. Run `tests/reference/test-cron-minimal-environment.sh` when command-path normalization, root environment defaults, non-interactive behavior, detached output, prompt suppression, runtime permissions, or cron compatibility is affected. Its current 153 checks use the real mirror reader/local preflight with private files, supplied privilege/slackpkg callbacks and real runtime/logging/locking. The original 19/79 failure remains historical evidence; see [cron scope](docs/reference/cron-minimal-environment.md) and [known limits](docs/testing.md#known-test-failures-and-fixture-repair). Step482 waits for the exact private logger after closing its pipe writers; do not inspect progress files solely on main-child exit. Preserve the original main status and the failed integration/serial observations.
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
27. Run `tests/reference/test-current-kernel-boot-preflight-harness.sh` when Slackware-current monolithic kernel layout, repository kernel transition, target file-inventory deferral, module or kernel-image ownership, direct-generic, GenInitrd-versioned, versus mkinitrd-managed classification, `BOOT_IMAGE` validation, GRUB discovery, apply-readiness gating, or current-kernel evidence publication is affected.
28. Run `tests/reference/test-current-direct-generic-boot-policy.sh` when direct generic boot detection, exact `BOOT_IMAGE` parsing, active kernel ownership, no-initrd policy selection, post-update generic-kernel validation, generated GRUB target validation, or boot-safety result mapping is affected.
29. Run `tests/reference/test-current-kernel-package-preflight-harness.sh` when accepted candidate/boot/restart binding, exact Slackpkg kernel downloads, cache resolution, package-archive path safety, target image or module inventory, non-executed `doinst.sh` policy, GRUB evidence generation, portable sidecars, or transaction apply denial is affected.
30. Run `tests/reference/test-current-geninitrd-policy-preflight-harness.sh` when installed GenInitrd script recognition, non-evaluating policy parsing, generator selection, automatic GRUB behavior, custom hook inventory, or policy evidence publication is affected.
31. Run `tests/reference/test-current-geninitrd-dkms-hook-preflight-harness.sh` when reviewed hook identity, hook metadata or syntax, static command-surface capture, read-only DKMS status, DKMS source/module inventory, or immutable apply denial is affected.
32. Run `tests/reference/test-current-geninitrd-command-preflight-harness.sh` when accepted chain linkage, live versioned-initrd validation, command-generator identity, command-output-only invocation, inert argument parsing, target-kernel projection, cached-package binding, or no-execution guarantees are affected.
33. Run `tests/reference/test-current-geninitrd-grub-ownership-preflight-harness.sh` when accepted chain linkage, GenInitrd policy precedence, automatic GRUB suppression, evidence-local policy staging, transaction ordering, recovery boundaries, or exclusive Slack-Update GRUB ownership are affected.
34. Run `tests/reference/test-current-kernel-transaction-readiness-preflight-harness.sh` when final candidate refresh, accepted evidence linkage, exact package-cache identity, live transaction state, post-state contract binding, positive readiness, or separate authorization denial are affected.
34. Run `tests/reference/test-geninitrd-grub-ownership-engine.sh` when same-directory policy staging, atomic activation or restoration, cleanup recovery, concurrent-change handling, backup retention, apply workflow ordering, or ownership-state reporting is affected.
35. Run `tests/reference/test-current-geninitrd-post-state.sh` when generated-initrd expectation, post-update kernel ownership, versioned initrd validation, named initrd links, legacy-initrd exclusion, or kernel-plus-initrd GRUB validation is affected. This synthetic fixture models only its exact target UID query and tests non-root rejection; real reference ownership enforcement remains unchanged. See [the repair scope](docs/reference/boot-artifact-validation.md#repair-1-synthetic-geninitrd-ownership-fixture).
36. Run `tests/reference/test-current-candidate-chain-refresh-preflight-harness.sh` when fresh Slackware-current metadata refresh, embedded preflight composition, candidate-set hashing, exact kernel-transaction comparison, userspace-only expansion classification, critical-candidate validation, stale-chain classification, or no-apply evidence publication is affected.
37. Run `tests/reference/test-current-kernel-chain-restart-preflight-harness.sh` when accepted refresh/normal-update/boot binding, corrected GenInitrd-versioned boot composition, nested target-image metadata or initrd digest, diagnostic restart evidence, nested archive verification, or restarted-chain no-apply boundaries are affected.
38. Run `tests/reference/test-current-userspace-candidate-review-preflight-harness.sh` when exact userspace-expansion identity, category boundaries, kernel-evidence rebind eligibility, nested preflight composition, or no-apply review constraints are affected.
39. Run `tests/reference/test-current-kernel-evidence-rebind-preflight-harness.sh` when accepted userspace review linkage, candidate-binding-only maps, live kernel/GenInitrd/DKMS/GRUB revalidation, or rebound no-apply boundaries are affected.
40. Run `tests/reference/test-current-userspace-payload-review-preflight-harness.sh` when exact archive downloads, package-cache resolution, archive path or link safety, GRUB-theme confinement, maintainer-script capture, or payload-review boundaries are affected.
41. Run `tests/reference/test-current-userspace-maintainer-script-review-preflight-harness.sh` when exact `doinst.sh` identities, static command classification, remove/symlink pairing, `.new` promotion, cache refreshes, process-signal confinement, or non-execution boundaries are affected.
42. Run `tests/reference/test-current-userspace-configuration-service-review-preflight-harness.sh` when exact configuration/service path manifests, contributing package hashes, static file classification, XDG or native-messaging validation, PAM/XML/shell-helper checking, systemd user-unit scope, preset handling, or non-execution boundaries are affected.
43. Run `tests/reference/test-current-userspace-elf-runtime-review-preflight-harness.sh` when exact package or per-package ELF bindings, static `readelf` parsing, loader-cache shadowing, transaction provider indexing, runtime path restrictions, hardening checks, dependency resolution, or ELF non-execution boundaries are affected.
44. Run `tests/reference/test-current-userspace-apply-review-preflight-harness.sh` when baseline/addition union binding, exact action classification, nested ELF output archiving, portable sidecar verification, stale-evidence replacement, reference-engine package commands, deferred post-install handling, GenInitrd policy restoration, GRUB ownership, failure blocking, or userspace application non-execution boundaries are affected.
45. Run `tests/reference/test-current-rollback-reconstruction-inventory-harness.sh` when optional rollback classification, empty-directory handling, exact local package inspection, module-manifest comparison, space estimation, or inventory non-mutation boundaries are affected.
46. Run `tests/reference/test-current-rollback-source-and-plan-preflight-harness.sh` when failed-preflight evidence binding, depmod metadata-placeholder classification, signed historical source acquisition, isolated GPG keyring handling, primary/subkey binding, archive safety, prerequisite-skip semantics, kernel/module manifesting, reconstruction space budgeting, placeholder backup, zero-to-two reviewed early-microcode images, initrd source-order preservation, GRUB projection, or apply-denial boundaries are affected.
47. Run `tests/reference/test-current-rollback-reconstruction-authorized-apply-review-harness.sh` when accepted step-87 binding, explicit authorization scope, retained-source revalidation, nested fresh-preflight composition, semantic action-plan auditing, before/after state comparison, authorization-record generation, or apply-execution denial is affected.
48. Confirm that destructive commands are not exercised outside an isolated or explicitly recoverable Slackware test system.
49. Record the relevant acceptance scenario.
50. Preserve deterministic output and exit-code behavior.
51. Exercise `enabled`, `disabled`, and `auto` when changing optional-module behavior.
52. Ensure every new or modified comment is written in English.


Optional rollback reconstruction authorization must remain distinct from execution. The authorization review must bind an accepted source-and-plan archive, exact retained source hashes, exact review code, and an explicit confirmation scope; rerun the non-mutating source-and-plan preflight into nested evidence; audit the payload, initrd vector, microcode order, GRUB fragment, ordered actions, backup limits, and recovery constraints; and prove package plus rollback-sensitive state remain unchanged. It may emit `apply_authorized=true` only with `apply_executed=false` and only for the canonical apply contract fixed by SHA-256. It must not refresh repositories, install or register the historical package, execute package scripts, run `depmod` or `mkinitrd`, modify GRUB or generic links, change `grubenv`, or reboot.

Never run the apply workflow on a production machine merely to validate a contribution.


## Historical native workflow instructions

The dated step-specific instructions below retain their original requirements
and evidence bindings. Their imperative wording is historical context, not a
current grant to repeat a run. Follow the [current phase gate](docs/roadmap.md#current-phase-and-release-gate)
and the separate source/target/review/authorization gates before any native work.

## Current Slackware-current boot-baseline preflight

The step-53 diagnostic revoked the previous direct-no-initrd classification. Run only the corrected non-destructive boot preflight:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-boot-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The step-55 rerun is accepted with archive SHA-256 `6429fd626973b0c3fc498642e1cd9230bc0eceb0291e232b515fef625467c6ac`. Do not run normal-update apply or reuse the dependent step-46 through step-52 records. Rebuild the chain with `test-current-kernel-chain-restart-preflight.sh`, copy the final outer archive and sidecar directly to `/home/promano`, verify the sidecar there, and include both files with the review.

## Pull requests

A pull request should include:

- the roadmap item addressed;
- the reason for the change;
- the validation performed;
- any remaining risks or follow-up work.

Keep unrelated changes in separate pull requests and commits.

### Rebuilt Slackware-current exact-package evidence (step 57)

After accepting the corrected step-56 GenInitrd-aware chain restart, run only:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-package-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The preflight must fail before package download if the accepted boot or chain records drift, or if the live generic kernel, named initrd, versioned initrd, GenInitrd policy, or active GRUB pairing differs from the accepted baseline. It may download and inspect the exact `.txz`, but must not execute `doinst.sh`, install packages, run `geninitrd` or `mkinitrd`, or replace GRUB state. Copy the generated `.tar.gz` and `.sha256` directly to `/home/promano` with `promano:users` ownership and verify the portable sidecar there. Do not advance to the policy preflight until the evidence is reviewed and recorded as accepted.

### Rebuilt Slackware-current GenInitrd policy evidence (step 58)

After accepting step 57, run only `test-current-geninitrd-policy-preflight.sh` with the accepted candidate digest and target. The stage must bind the corrected boot, chain-restart, and exact-package records, revalidate the live named and versioned initrd plus GRUB pairing, parse `/etc/default/geninitrd` without sourcing it, and classify the target as `versioned-to-versioned-initrd`. A disabled or skipped generator must expose a stale-initrd transition and fail the real acceptance path. No GenInitrd hook, generator, package tool, `mkinitrd`, `geninitrd`, `update-grub`, or `grub-mkconfig` command may be executed. Publish and verify the archive and sidecar directly in `/home/promano`; do not advance to DKMS review until this evidence is accepted.

### Rebuilt Slackware-current DKMS-hook evidence (step 59)

After accepting step 58, run only:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-dkms-hook-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The stage must bind the corrected boot, chain-restart, exact-package, and versioned-policy records and reject the historical direct-no-initrd chain. It must revalidate the live named and versioned initrd plus GRUB pairing before inspecting the two reviewed hooks. Hook bodies may be copied into private evidence and parsed statically, but must never be executed. Only read-only `dkms --version` and `dkms status` calls are permitted; `dkms build`, `install`, `autoinstall`, `remove`, package tools, initrd generation, and GRUB mutation remain forbidden. Copy the archive and sidecar directly to `/home/promano` with `promano:users` ownership and verify the sidecar there. Do not advance to the GenInitrd command preflight until this evidence is reviewed and accepted.

### Rebuilt Slackware-current GenInitrd command evidence (step 60)

After accepting step 59, run only:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-command-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The stage must bind all corrected records through the accepted DKMS boundary and fail closed if the live named initrd, versioned initrd, GenInitrd symlink policy, package cache, or active GRUB pairing differs from the accepted chain. The generator may run only in command-output mode for the installed kernel and must not use `--run`; the emitted text must contain exactly one safe inert `mkinitrd` vector. The projected vector may change only the reviewed kernel and versioned output target. Never use `eval`, `bash -c`, or execute either vector. Copy and verify the evidence directly in `/home/promano`; do not advance to GRUB-ownership review until the record is accepted.

### Rebuilt Slackware-current GenInitrd/GRUB ownership evidence (step 61)

After accepting step 60, run only:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-grub-ownership-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The stage must bind every corrected record through the accepted command boundary and fail closed if the live named initrd, versioned initrd, GenInitrd symlink policy, or active GRUB pairing differs from the accepted chain. It may create only an evidence-local policy copy with the single reviewed `AUTO_UPDATE_GRUB=false` change and an evidence-local transaction plan. It must not install or replace that policy, execute package tools, run `mkinitrd` or `geninitrd`, invoke `update-grub` or `grub-mkconfig`, or mutate any boot artifact.

The first real step-61 run stopped before initial state capture because `capture_sensitive_state()` referenced undeclared `GENERATOR_SCRIPT` under nounset. Step 62 corrects this to `GENINITRD_SCRIPT`; contributors must retain the harness test that executes sensitive-state capture in a subshell under `set -u` and verifies both declared script paths. The corrected real run is accepted with archive SHA-256 `53acb06384b4a8fbea1feceb73e6aa2381c43f5702a41ce990d0f515d04588fe`.

### Rebuilt Slackware-current transaction readiness evidence (step 63)

The readiness stage must bind the eight corrected accepted records and the corrected versioned-to-versioned post-state contract before examining the live host. It must refresh candidates only through `test-normal-update.sh --preflight`, verify the nested archive inside its own evidence, and reject any candidate, package, boot, initrd, policy, hook, DKMS, or GRUB drift. The revoked `direct-generic-no-initrd` baseline must never be accepted by this stage.

The live-state check must verify the exact current kernel hash, `initrd-generic.img` target, current versioned-initrd size and SHA-256, absence of target kernel/modules/initrd before apply, scalar GenInitrd policy, exact script and hook hashes, empty DKMS state, exact cached package, active GRUB digest, syntax, and same-menuentry pairing. It may set `apply_ready=true` only when every check passes, but it must always retain `apply_authorized=false` and all execution flags as false. Positive readiness only advances to a separately reviewed apply-authorization boundary. Evidence and sidecars must be copied directly to `/home/promano` with `promano:users` ownership and verified there.



### Candidate drift after a reviewed kernel chain

A changed aggregate candidate digest is not sufficient to declare a changed kernel target. Compare the exact `kernel-generic`, `kernel-headers`, and `kernel-source` filenames from the accepted and fresh sets. When those files are identical but userspace candidates are added, removed, or replaced, classify the refresh as `changed-userspace-set`, keep the old candidate-bound chain directly non-reusable, and require an explicit userspace review before any rebind. Configured critical candidates must be represented by a sorted unique file that is a subset of the exact candidate set; any critical entry requires manual review. Blocked readiness must route back to candidate-chain refresh, never to apply authorization.

### Slackware-current userspace candidate-expansion review

After a candidate refresh classifies an exact same-kernel strict superset as `changed-userspace-set`, run the dedicated identity review before reusing any kernel evidence:

```bash
sudo bash tests/acceptance/reference/test-current-userspace-candidate-review-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 \
    --confirm-target-kernel 6.18.42
```

The reviewed policy must enumerate every added package exactly once, preserve the exact prior kernel transaction, keep all additions in `upgrade-all`, and contain no configured critical candidate. The review scope is limited to candidate identity for kernel-evidence rebind; it must never claim payload inspection, apply readiness, or apply authorization. Copy the resulting `.tar.gz` and `.sha256` directly to `/home/promano`, set ownership to `promano:users`, and verify the sidecar there before proceeding.

### Explicit kernel-evidence rebind after an accepted userspace expansion

After accepting the userspace identity review, use `test-current-kernel-evidence-rebind-preflight.sh` to create a new candidate binding. The rebind must validate the accepted review archive and nested archive, every accepted kernel evidence archive, the exact source and destination candidate digests, and a checked-in policy that permits only the binding change. It must rerun the normal-update preflight, require the exact fresh candidate list, and revalidate the cached target package plus the live kernel, versioned initrd, GenInitrd policy, DKMS no-op state, and same-menuentry GRUB pair.

The original evidence records remain immutable and continue to contain the source candidate digest. The rebind output is a separate map that records both digests and all accepted archive hashes. It must retain `package_payloads_inspected=false`, `userspace_apply_review_complete=false`, `userspace_payload_review_required=true`, `apply_ready=false`, and `apply_authorized=false`, and may route only to a separate userspace payload review. Copy and verify the final evidence directly in `/home/promano` before continuing.

### Userspace package-payload archive review

After the explicit rebind is accepted, use `test-current-userspace-payload-review-preflight.sh` to inspect the exact added package archives. The preflight must rerun normal-update only in `--preflight` mode, require the exact rebound candidate digest, resolve one live Slackpkg record per reviewed filename, and download only exact missing package stems. Package downloads are cache population only; no package-manager install, upgrade, or removal operation is permitted.

Every `.txz` must be inspected without extraction into the host. Reject absolute or traversing paths, duplicate members, devices, FIFOs, unsupported member types, escaping links, setuid/setgid modes, kernel/module/initrd/pkgtools payloads, and GRUB content outside the explicitly reviewed Breeze theme prefix. A boot-adjacent exception must bind the exact package filename, archive SHA-256, and byte size. For the reviewed Slackware `breeze-grub` archive, only the ancestor directories required to reach `boot/grub/themes/breeze/` and that exact theme subtree are allowed; every other `/boot` or GRUB member remains forbidden. Never broaden the exception to a package-name pattern, a sibling theme, or a generic `/boot/grub` prefix.

Record each archive SHA-256 and complete inventory. Copy `install/doinst.sh` files only into the evidence directory, validate syntax without execution, and preserve a separate maintainer-script review boundary. A payload-path pass must still retain `maintainer_scripts_review_complete=false`, `userspace_apply_review_complete=false`, `apply_ready=false`, and `apply_authorized=false`. Copy the resulting archive and sidecar directly to `/home/promano`, set `promano:users` ownership, and verify the sidecar before continuing.

### Userspace maintainer-script static review

After an accepted payload-path review, run `test-current-userspace-maintainer-script-review-preflight.sh`. The wrapper must repeat the non-installing payload review, bind all captured `install/doinst.sh` files to exact package names, SHA-256 values, line counts, and per-script action counts, and classify every non-comment command without executing any script.

Relative `rm -rf` commands are permitted only as an immediately paired precursor to a `ln -sf` operation with the same package-relative directory and destination. Both the write path and relative link target must remain within the package root; absolute link targets require an exact policy entry. Configuration promotion and cache regeneration commands require exact package/path or package/command pairs. Process control is forbidden except for the reviewed `kscreenlocker` command `killall -TERM kscreenlocker_greet 1>/dev/null 2>/dev/null`, bound to the exact package and script hash. Never generalize this exception to another signal, process name, package, command form, or script identity.

A clean static review may set `maintainer_scripts_review_complete=true` and route only to `current-userspace-configuration-service-review-preflight`. It must retain `userspace_apply_review_complete=false`, `apply_ready=false`, `apply_authorized=false`, and every execution flag as false. Copy and verify the outer evidence archive and sidecar directly in `/home/promano` before continuing.
### Userspace configuration and service payload review

After accepting the maintainer-script evidence, run `test-current-userspace-configuration-service-review-preflight.sh`. The wrapper must repeat the full non-installing maintainer review, verify its nested archive and exact prior counts, and bind every reviewed path to package name, member path, type, mode, size, and the exact SHA-256 plus size of the contributing package archive.

Read regular members directly from the cached `.txz` files into the owner-only evidence tree. Never extract them into live system paths or execute them. Configuration files require complete type-specific classification and static format checks. Shell helpers may receive `sh -n` syntax checks only. Service payloads must remain confined to systemd user-unit and user-preset directories; system units, `rc.d` scripts, privileged directives, shell execution, unsafe presets, unknown content, package operations, service control, and boot actions fail closed.

A clean review may set `configuration_service_review_complete=true` and route only to `current-userspace-elf-runtime-review-preflight`. It must retain `elf_runtime_review_complete=false`, `userspace_apply_review_complete=false`, `apply_ready=false`, `apply_authorized=false`, and all package, payload, service-control, and boot execution flags as false. Copy and verify the evidence archive and sidecar directly in `/home/promano` before continuing.
### Userspace ELF runtime review

After accepting the configuration/service evidence, run `test-current-userspace-elf-runtime-review-preflight.sh`. The wrapper must repeat the full non-installing review chain, verify its nested archive, and bind all package identities and per-package ELF counts before inspecting any object. Stream one object at a time into an owner-only temporary file, pass its path to `readelf` only after `--`, and remove the temporary file before evidence publication. Never execute a payload object or use `ldd`, `sotruss`, `strace`, or another loader-tracing mechanism.

Require the exact reviewed ELF class, byte order, and machine. Constrain interpreters and runtime search paths to reviewed system roots. Reject slash-containing `DT_NEEDED` values, text relocations, executable stacks, writable-executable load segments, and unresolved dependencies. Treat host loader-cache paths owned by pending replacement packages as unavailable unless the reviewed transaction supplies the required library. Transaction providers may resolve dependencies only when their installation directory is a default loader directory or an explicitly safe resolved runtime directory.

A clean review may set `elf_runtime_review_complete=true` and route only to `current-userspace-apply-review-preflight`. It must retain `userspace_apply_review_complete=false`, `apply_ready=false`, `apply_authorized=false`, and all package, payload, dynamic-loader tracing, service-control, and boot execution flags as false. Copy and verify the evidence archive and sidecar directly in `/home/promano` before continuing.

### Userspace application review

After accepting the ELF/runtime evidence, run `test-current-userspace-apply-review-preflight.sh`. The wrapper must rerun the complete non-installing ELF review and a separate normal-update preflight, verify both nested archives, and reconstruct the exact candidate transaction from the accepted baseline and reviewed additions. Any missing, added, duplicated, reclassified, critical, or kernel-transaction package must fail closed.

Bind the exact reference-engine SHA-256 and require noninteractive metadata refresh, `-postinst=off` install-new and upgrade-all actions, deferred `.new` handling, the temporary atomic GenInitrd GRUB-suppression override, mandatory restoration, secondary-module blocking after partial Slackware failure, temporary GRUB generation plus validation, and the reviewed transaction and recovery counts. Review these commands statically only; never call normal-update apply or execute package, maintainer, initrd, DKMS, service, or GRUB actions from this boundary.

A clean review may set `userspace_apply_review_complete=true` and route only to `current-kernel-transaction-readiness-preflight`. It must retain `apply_ready=false`, `apply_authorized=false`, and every execution flag as false. Copy and verify the outer evidence archive and sidecar directly in `/home/promano` before continuing.

### Rebound kernel transaction readiness review

After the accepted userspace application review, rerun `test-current-kernel-transaction-readiness-preflight.sh` against the rebound 137-candidate digest. The readiness wrapper must bind both the immutable source kernel evidence and the explicit rebind, require the accepted userspace apply-review archive, recompute the exact 69-plus-68 candidate union, and verify all package-policy manifests before it reads live state.

Require exactly one regular, nonsymlink cached archive for each of the 68 reviewed userspace packages and for the exact target `kernel-generic` package. Verify names, byte sizes, and SHA-256 values. Revalidate the exact running kernel, versioned GenInitrd layout, policy scalars, hooks, generator, setup script, active GRUB digest and pairing, and empty DKMS state. Any stale record, package duplicate, symlink, changed candidate, or live-state drift must fail closed.

A clean readiness result may set `apply_ready=true` and route only to `normal-update-apply-authorization-review`, but it must retain `apply_authorized=false` and record `pause_safe=false` while apply-time candidate revalidation and the real package transaction are pending. Never describe this boundary as a safe pause on Slackware-current. Continue to the explicit authorization and application chain, and declare a pause safe only after a later accepted boundary explicitly records `pause_safe=true`.

### Explicit Slackware-current authorized apply

After accepting the rebound readiness evidence, use `test-current-normal-update-authorized-apply.sh` as the only application entry point for this reviewed transaction. Require the exact short hostname, exact FQDN, 137-candidate digest, target kernel, readiness archive digest, and authorization-scope digest. Validate host identity separately from boot state, and pass the verified FQDN to the nested normal-update acceptance workflow. The authorization scope and policy must bind the exact reference engine, normal-update acceptance script, and authorized-apply wrapper hashes; any code change requires a new explicit authorization digest.

The wrapper must validate the accepted 6.18.40 live baseline before starting. The real acceptance boundary must initialize every mutable live boot-probe input, including `BOOT_CMDLINE_FILE=/proc/cmdline`, `GENERIC_KERNEL_LINK=/boot/vmlinuz-generic`, and `RUNNING_KERNEL` from `uname -r`, before invoking the accepted engine with `set -u`. Its child normal-update acceptance workflow must refresh metadata and compare the complete candidate digest again before calling the reference apply engine. Do not add `--allow-critical-update`; this reviewed transaction contains zero critical candidates. Any candidate drift must block before package mutation. An early engine failure with identical before/after package snapshots must be recorded as `failed-before-package-transaction`; do not parse empty child JSON or run inapplicable target-artifact assertions. Package drift after a failed apply is a partial transaction requiring manual recovery.

A successful authorized apply must prove package database change, stable exit code 5, deferred Slackpkg post-install processing, complete non-partial boot-safe JSON, restored GenInitrd policy, successful versioned initrd generation, validated atomic GRUB replacement, installed 6.18.42 kernel/modules, and retained 6.18.40 rollback artifacts. Set `pause_safe=true` only after all these checks pass. If packages changed but the final boundary is incomplete, retain `pause_safe=false` and route to manual recovery review. Copy the outer archive and sidecar directly to `/home/promano`, set ownership to `promano:users`, and verify the sidecar there.

### Post-package safe-pause recovery boundary

When a reviewed Slackware-current transaction completes package installation but the enclosing boot workflow exits nonzero, classify the result from evidence rather than from the outer status alone. If both Slackpkg package phases succeeded and the installed package snapshot changed to the exact reviewed post-state, preserve that transaction as completed. Do not rerun candidate review or reinstall the same packages merely because later boot orchestration failed.

A non-mutating recovery verification may declare `pause_safe=true` only when it binds the exact failed-apply archive, exact installed package database snapshot, exact target package records, exact target kernel/initrd/module identities, exact generic symlink targets, restored GenInitrd controls, and a syntax-valid unchanged GRUB configuration that already pairs those generic links in one menuentry. The verifier must capture before/after package and boot-sensitive state and prove both are unchanged. It must not refresh repositories, install packages, run package scripts, generate initrds, or alter GRUB.

Missing rollback artifacts must never be described as preserved. Record separately whether the old kernel image, old initrd, and old module tree exist. A safe pause after the installed target boot pair is verified does not itself authorize reboot; keep `reboot_authorized=false` until a dedicated reboot review is accepted.

The accepted Slackware-current safe-pause record is `tests/fixtures/reference/acceptance/normal-update/slackware-current-post-package-boot-recovery-20260805-accepted.json`, with archive SHA-256 `b2e3ee1d4bcdc243afbde0160d7d7f50e985e365f9580551fea6def4d6ae1f96`. Once this exact boundary is accepted, later repository publications are a new update cycle and must not invalidate or restart the completed transaction. The next contribution must focus only on a dedicated reboot review bound to the installed 6.18.42 pair; it must not refresh metadata, reinstall packages, or claim that the degraded 6.18.40 disk rollback exists.

### Optional rollback reconstruction apply boundary

Changes to `test-current-rollback-reconstruction-authorized-apply.sh` require a new code-bound confirmation scope and must preserve the separation between the historical source package and the installed package database. Do not introduce Slackpkg metadata refresh, package-manager installation, generic-link changes, GRUB default changes, or reboot commands.

The executor must remain transactional. Before mutation, rerun the accepted authorization review and capture package plus sensitive state. Stage and verify the complete payload before installing it. Keep owner-only backups of the module placeholder, active GRUB configuration, and any existing `/boot/initrd-tree`. Validate the temporary GRUB configuration before same-directory atomic replacement. Every failure path after mutation begins must attempt restoration and must set `pause_safe=true` only after byte-equivalent baseline verification.

Acceptance changes must extend the focused harness with both commit and rollback cases. At minimum cover depmod failure, mkinitrd failure after partial output creation, GRUB generation or semantic-validation failure, source drift before mutation, authorization rejection before mutation, generic-link preservation, package-database immutability, and initrd-tree restoration.

### Optional rollback boot authorization boundary

Changes to `test-current-rollback-boot-authorization-review.sh` must remain non-mutating. Bind the accepted step-89 reconstruction, exact package database snapshot, active 6.18.42 boot pair, versioned 6.18.40 kernel/initrd/module tree, explicit rollback fragment, active GRUB semantics, and grubenv state before issuing authorization. Reject duplicate or ambiguous rollback entries, a pending `next_entry`, a saved rollback selection, package drift, generic-link drift, or any boot artifact mismatch.

This boundary may authorize only a manual selection of the exact reviewed rollback entry. It must never call Slackpkg, regenerate GRUB, edit grubenv, change the configured default, reboot, power off, or execute the boot itself. Before/after package and sensitive snapshots must be byte-identical. A successful result routes only to `current-rollback-boot-test-manual-reboot`.



### Optional rollback boot verification and return boundary

Changes to `test-current-rollback-boot-verification-and-return-review.sh` must remain non-mutating and must bind the accepted step-90 authorization archive. Require the running kernel and kernel osrelease to match the rollback version, retain the exact package database, kernel/initrd/module identities, validate module `vermagic`, preserve the active generic links and first/default GRUB entry, and reject a pending `next_entry`, saved rollback selection, conflicting `BOOT_IMAGE`, root UUID drift, package drift, or boot-artifact drift.

A successful review may authorize only a normal manual reboot using the unchanged configured default. It must not call Slackpkg, regenerate GRUB, set or unset grubenv variables, change packages, reboot, shut down, or power off. Before/after package and sensitive snapshots must be byte-identical. The next stage is the final post-return verification on 6.18.42.

For Phase 1 step 92, preserve the accepted step-91 return-review archive boundary `c4a8e207ad3af7ef118c2371f3cec0694c1e5fca50599d4b5a2e89daa2b77d7f` and run only the non-mutating `test-current-rollback-return-verification-closure.sh`. The closure must prove the host returned through `/boot/vmlinuz-generic` to 6.18.42 while retaining the tested 6.18.40 rollback, and must not refresh Slackware-current metadata, mutate packages, modify GRUB/grubenv, or reboot. The reviewed closure scope is `083e44cb173729870b9f825da8363b4576ea501767c126a5384f4438863de8de`. A clean result closes the optional Slackware-current rollback boot demonstration and routes project work back to the pending Slackware 15.0 ELILO preflight repeat.



25. Run `tests/reference/test-elilo-oldkernel-cleanup-source-and-plan-preflight-harness.sh` whenever the mature ELILO retention acceptance record, authenticated Slackpkg checksum handling, local active-kernel archive resolution, package-archive structural inspection, real-system cleanup inventory generation, fourteen-step dry-run integration, or cleanup-readiness gating changes. Real cleanup must remain unauthorized in this boundary.
26. Run `tests/reference/test-elilo-oldkernel-cleanup-authorization-review-harness.sh` whenever the accepted step-93 source-and-plan record, exact cached archive identities, canonical fourteen-action cleanup contract, live ELILO/package revalidation, or cleanup-authorization boundary changes. This review must keep real apply unexecuted and must not run package mutation, ELILO mutation, repository refresh, rollback deletion, or reboot commands.
27. Run `tests/reference/test-elilo-oldkernel-cleanup-authorized-apply-harness.sh` whenever the accepted step-94 authorization record, exact cached active package identities, transactional ELILO cleanup executor, private recovery snapshot, package rollback recovery, active ELILO activation, authorized rollback-file deletion, post-apply safety gate, or recovery-retention boundary changes. Any destructive acceptance run must be performed only on a recoverable VM or equivalent disposable test environment; `pause_safe=true` requires either a coherent commit or proven exact recovery.
28. Run `tests/reference/test-elilo-oldkernel-cleanup-authorized-apply-recovery-review-harness.sh` whenever recovered step-95 evidence, retained recovery-archive verification, exact pre-apply package/boot/module manifest comparison, depmod-generated-index classification, or revised-cleanup retry gating changes. This boundary must remain non-mutating and keep cleanup/apply authorization false.
29. Run `tests/reference/test-elilo-oldkernel-cleanup-authorized-apply-revision-1-harness.sh` whenever the accepted step-97 revision record, production revision-1 policy, revision-evidence binding, or destructive retry scope changes. The production boundary must bind both the original step-94 authorization and the accepted step-97 revision before the revised executor can mutate the host.

## Generated module indexes

When validating a reinstalled Slackware kernel module tree, do not treat generated depmod indexes as immutable package payload. Any exception must be an explicit closed path set, while `.ko*` objects and all non-generated files remain byte-identical and depmod is validated read-only.


### ELILO cleanup retry diagnostics

A recovered ELILO cleanup failure is not permission to retry the destructive transaction. When an aggregated final-state assertion fails, add or run a non-mutating diagnostic that records each unresolved predicate before revising or reauthorizing the executor. Preserve the retained private recovery archive until a later successful reboot-verification boundary explicitly permits cleanup.

- ELILO oldkernel cleanup retries must remain denied after step 99 until the final-predicate instrumentation review has classified rollback package-unowned module survivors or explicitly routed to runtime instrumentation.


### ELILO cleanup rollback-module survivor review (step 101)

Step 100 confirmed that the failed final rollback-module predicate is caused by exactly three package-unowned VirtualBox Guest Additions objects under the 5.15.19 rollback tree: `vboxguest.ko`, `vboxsf.ko`, and `vboxvideo.ko`. Step 101 is a non-mutating review only. It revalidates the recovered boundary, scans every installed package `FILE LIST:` to prove that none owns those rollback paths, validates rollback `modinfo` identity/vermagic, and requires matching 5.15.209 active counterparts. It fingerprints the exact three rollback objects and their active counterparts into an evidence-local survivor-removal contract. Recursive removal of `/lib/modules/5.15.19`, removal of active counterparts, and any third cleanup attempt remain unauthorized until a separate review accepts that exact scope. A clean step-101 result remains `pause_safe=true`.


### ELILO rollback survivor deletion authorization

Any cleanup revision that handles package-unowned rollback modules must separate discovery, deletion authorization, and destructive execution. Authorization must be path- and SHA-256-bound, must preserve active-kernel counterparts, must forbid recursive rollback-tree removal, and must not imply authorization for the cleanup transaction itself.

### ELILO survivor-integrated cleanup executor revision

Any revision that consumes the step-102 survivor deletion authorization must keep discovery, deletion authorization, executor revision review, third-attempt authorization, and destructive execution as separate boundaries. The revised executor may unlink only the three authorized rollback paths and must verify each rollback SHA-256 plus its 5.15.209 active counterpart immediately before unlink. Recursive removal of `/lib/modules/5.15.19` is forbidden as a cleanup action.

The unlink stage must occur after exact rollback package removal, active-package reinstallation, and active-package verification, but before ELILO mutation and final-state verification. The pre-mutation full rollback-module recovery snapshot must continue to cover all three survivor paths. A prepared revision must remain impossible to execute until a separate accepted third-attempt authorization record is present and bound by the production policy.

30. Run `tests/reference/test-elilo-oldkernel-cleanup-rollback-module-survivor-authorized-apply-revision-review-harness.sh` whenever the accepted step-102 survivor authorization, exact-unlink integration contract, prepared apply policy, or third-attempt fail-closed gate changes. Also rerun `tests/reference/test-elilo-oldkernel-cleanup-authorized-apply-harness.sh` whenever unlink ordering, survivor fingerprints, active-counterpart preservation, or recovery of the three survivor objects changes.

31. Third-attempt authorization must remain separate from destructive execution. `tests/acceptance/reference/test-elilo-oldkernel-cleanup-third-attempt-authorization-review.sh` may authorize only the exact step-103 survivor-integrated revision after revalidating the recovered live boundary, exact survivor fingerprints, and exact cached active archives. Its authorization artifact may set `third_attempt_authorized=true` and `apply_authorized=true`, but the prepared executor policy must remain `execution_authorized=false` until a later accepted-evidence boundary explicitly enables execution. Run `tests/reference/test-elilo-oldkernel-cleanup-third-attempt-authorization-review-harness.sh` whenever this separation, authorization contract, cached-archive gate, or confirmation scope changes.


For static ELF cache lookup status changes, run
`python3 tests/reference/test-elf-cache-lookup.py` with metadata, architecture and
scan workflow regressions. Read the [lookup scope](docs/reference/elf-cache-lookup.md)
for absent-versus-error statuses, supplied operations and existing scan limits.
