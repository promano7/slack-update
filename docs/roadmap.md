# Development roadmap

This document holds the project roadmap previously embedded in the README.
The README gives a short project overview; [CHANGELOG.md](../CHANGELOG.md)
records changes, and [reference documentation](reference/README.md)
preserves historical checkpoint and design material. Moving documentation does
not amend the original contracts or mark an acceptance scenario complete.

## Current phase and release gate

**Phase 1 is incomplete.** `reference-v1`, the version 1 result schema, C
development, Phase 2 and production remain blocked. Both Slackware 15.0 and
Slackware-current are mandatory targets.

Accepted historical coverage includes core updates, `install-new`, kernel
updates, no-change behavior, the Slackware-current rollback demonstration,
Slackware 15.0 ELILO cleanup, configuration/module modes, English-comment
remediation and the four execution-control failure scenarios in their recorded
scope. Detailed evidence remains in the existing reference records; historical
acceptance does not describe the present state of a machine.

### Repository verification and next decisions

Last confirmed qualified outer STATIC pause531 follows accepted86 integration;
its external closure is in the supplied continuation. Seven actual532-538 steps
accepted, latest `6100e602c3c0a9c8fa30c0aef961e85bf4a96694`. Prepared539 is the
eighth/final step: root README update and91 fresh commands on CURRENT source.
Complete actual539 acceptance and separate post-actual whole-condition review
remain due; no new pause. See the
[prepared final review](reference/repository-regression-block-532-539.md).

Current initial scan rejects classifier2 and any selected path-emission failure
before counting/publishing, preserving prior list/count while processing all input.
Final91 is ordered86 from531 plus metadata96/diagnostic72/apply96/emission-direct36/
emission-apply48. All commands run FRESH in preparation and on PC, zero result reuse.
Historical532/536 audits remain frozen and excluded, with earlier source-bound
512/516/519/524/527 audits. Native criteria and all code/tests remain exact538.

Resolver/unknown-status skipping, output trust, partial publication/cleanup,
canonical-string/inode/input races, external durability, setup resets, suppressed
cleanup/enclosing-parent removal and prior-sync43 build policy limits remain.
Raw apply0 is not stable success. Preserve all original failures/unknown extras/
incomplete491 binary/failed unread retrieval/UNKNOWN origin/no-repair qualifications.
Current equality proves no historical/global absence or native authorization.

Final complete actual acceptance FIRST, THEN separately READ WHOLE inherited header/
EVERY WHOLE condition/EVERY exact nested original/ALL new effects/obligations/
cleanup/failures/limits with original comparisons; no count/hash/summary substitutes.
All original native criteria/independent decisions/reviews/ACTUAL binding/safe
ACTUAL WHOLE review/fresh bounded authority BEFORE effects/OWN-platform gates due
in order. A/R/D unselected/native repairs inactive. Same-assistant STATIC work
satisfies none and renews no consumed rights. Host unobserved/evidence-live bindings
null/global closurefalse. Later-current refresh cannot invalidate completed scoped
531 STATIC pause or revive consumed source/boot/run/grant/right/binding authority.

### Remaining Phase 1 work

| Acceptance family | Remaining scenarios |
| --- | ---: |
| [Kernel headers update without a kernel image update](reference/acceptance-evidence-guide.md#kernel-package-edge) | 1 |
| [Boot safety failures](reference/acceptance-evidence-guide.md#boot-safety-failures) | 7 |
| [SBo and ELF optional runtime](reference/acceptance-evidence-guide.md#sbo-and-elf-optional-runtime) | 6 |
| [Cinnamon optional runtime](reference/acceptance-evidence-guide.md#cinnamon-optional-runtime) | 3 |
| [Flatpak optional runtime](reference/acceptance-evidence-guide.md#flatpak-optional-runtime) | 3 |

The complete rows and their original criteria remain in the
[post-execution-control inventory](../tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv).
The [evidence guide](reference/acceptance-evidence-guide.md) connects these
labels to their original rows and accepted historical evidence.
The [step 175 inventory](reference/phase-1-acceptance-matrix-remainder-inventory.md)
explains historical accepted coverage. These five families/20 scenarios are
separate from the operational work's 46 qualified proofs, 52 native case
templates and 12 independent raw evidence groups; none has been discharged by
the manuscript audits. Counts are navigation aids, not replacement criteria.

For the kernel operational work, read the
[native prerequisites](reference/phase-1-operational-native-implementation-prerequisites.md),
[source/gap reconciliation](reference/phase-1-operational-source-native-gap-reconciliation.md),
[integrated audit](reference/phase-1-operational-joint-integrated-findings-interaction-disposition-review.md)
and [A/R/D decision reference](reference/phase-1-operational-joint-unselected-a-r-d-decision-brief-review.md).
All 16 native gaps and 13 audit findings remain unresolved. Original norms
remain binding, all alternatives are unselected, and proposed repairs are inactive.

Later native progress requires the separate decision, independent specification
and impact review, conditional migration approval, actual composition binding,
safe actual review, fresh bounded test authority and own-platform conformance
described in the decision reference. Repository continuation is not one of those
approvals. Actual host state remains unobserved; old boot/source/run identities
and consumed authority cannot be reused.

Before Phase 1 can close, complete the remaining applicable acceptance work,
record expected outputs and exit codes, retain sanitized fixtures/evidence,
define and accept the version 1 JSON result schema, and freeze `reference-v1`.
The full original checklists and detailed contracts are preserved in the
[historical roadmap](reference/readme-through-step418.md#development-roadmap).

## Later phases

The [planned C application design](design.md) describes the components, modules,
privilege boundary and proposed interfaces for these future phases.

The following existing Phase 2–15 plan is retained from the previous README.
It describes future work and opens no implementation phase. Its requirements
remain subject to the Phase 1 completion gate above.

## Phase 2 — Define the C architecture and build skeleton

**Goal:** create a warning-clean, testable project skeleton without update logic.

- [ ] Select the build system.
  - [ ] Evaluate Meson.
  - [ ] Evaluate CMake if required by portability or contributor needs.
- [ ] Select the minimum C standard, preferably C11 or newer.
- [ ] Define supported Slackware versions for the first release.
- [ ] Define the minimum supported compiler versions.
- [ ] Create all top-level source directories.
- [ ] Create a core library target.
- [ ] Create empty CLI, helper, and tray targets.
- [ ] Enable strict compiler warnings.
- [ ] Treat project warnings as errors in CI.
- [ ] Add debug and release build profiles.
- [ ] Add AddressSanitizer and UndefinedBehaviorSanitizer development profiles.
- [ ] Add formatting rules.
- [ ] Add static-analysis targets.
- [ ] Add a minimal unit-test framework.
- [ ] Add GitHub Actions for build and unit tests.
- [ ] Confirm the build does not require systemd development files.

**Completion gate:** all targets build and tests run, but no privileged or package-management action exists yet.

## Phase 3 — Implement the core data model

**Goal:** represent modules, operations, plans, events, and results independently of any frontend.

- [ ] Define immutable module identifiers.
- [ ] Define module availability and activation states.
- [ ] Define operation types: check, plan, apply, verify.
- [ ] Define action types and required privilege levels.
- [ ] Define warning and error structures.
- [ ] Define reboot states: none, recommended, required, unsafe.
- [ ] Define operation and module result structures.
- [ ] Define progress events.
- [ ] Define cancellation semantics.
- [ ] Define timestamps and duration reporting.
- [ ] Define ownership and cleanup rules for every allocated structure.
- [ ] Add unit tests for every state transition.
- [ ] Add JSON serialization for results.
- [ ] Add JSON or line-oriented serialization for progress events.
- [ ] Version the machine-readable schema.

**Completion gate:** synthetic modules can run through the full lifecycle and produce validated structured results.

## Phase 4 — Implement configuration

**Goal:** load, validate, merge, and expose safe system and user configuration.

- [ ] Implement the system configuration parser.
- [ ] Implement per-user presentation preferences.
- [ ] Define precedence: defaults, system configuration, approved CLI overrides.
- [ ] Implement `enabled`, `disabled`, and `auto` module modes.
- [ ] Validate paths, integers, booleans, enums, and lists.
- [ ] Reject unsafe command injection and shell fragments.
- [ ] Provide configuration defaults in a documented sample file.
- [ ] Implement configuration schema versioning.
- [ ] Implement effective-configuration output.
- [ ] Add unit tests for valid, invalid, incomplete, and legacy configurations.

**Completion gate:** configuration behavior is deterministic and no module reads arbitrary global variables directly.

## Phase 5 — Implement the command-execution layer

**Goal:** execute external Slackware tools safely and make them fully testable.

- [ ] Execute programs without invoking a shell by default.
- [ ] Pass arguments as explicit arrays.
- [ ] Control environment variables explicitly.
- [ ] Capture stdout and stderr separately.
- [ ] Stream progress without losing the final output.
- [ ] Record exit status and terminating signal.
- [ ] Support timeouts where safe.
- [ ] Support cancellation and child-process cleanup.
- [ ] Redact secrets and unsafe environment data from logs.
- [ ] Implement a fake command runner for tests.
- [ ] Implement fixture-based command outputs.
- [ ] Add tests for large output, invalid UTF-8, signals, and failed process startup.

**Completion gate:** modules can be tested without calling real package-management commands.

## Phase 6 — Port the Slackware core module

**Goal:** reproduce the validated Slackware behavior from the reference script.

- [ ] Detect the Slackware package database path.
- [ ] Parse Slackware package filenames exactly.
- [ ] Capture sorted package snapshots.
- [ ] Calculate exact changed package names.
- [ ] Implement `slackpkg update` checking and application.
- [ ] Implement configurable `install-new` behavior.
- [ ] Implement configurable `upgrade-all` behavior.
- [ ] Detect partial updates.
- [ ] Stop dependent modules after unsafe partial updates.
- [ ] Detect critical library updates.
- [ ] Detect kernel-related package changes.
- [ ] Produce the same results as `reference-v1` fixtures.
- [ ] Add integration tests with mocked package databases and command output.

**Completion gate:** the C Slackware module matches the reference script for every applicable fixture.

## Phase 7 — Port boot preparation

**Goal:** safely prepare boot files after kernel updates.

- [ ] Create a generic boot module.
- [ ] Create the GRUB adapter.
- [ ] Parse and validate `mkinitrd.conf` safely.
- [ ] Detect the installed generic kernel version.
- [ ] Validate `/lib/modules/<version>`.
- [ ] Generate the initrd.
- [ ] Verify the output image exists and is non-empty.
- [ ] Generate GRUB configuration to a temporary path.
- [ ] Validate the generated menu entries.
- [ ] Back up the current GRUB configuration.
- [ ] Replace the configuration atomically where possible.
- [ ] Mark the system unsafe to reboot after critical failure.
- [ ] Add mocked and VM-based tests.
- [ ] Design, but do not necessarily implement, ELILO and LILO adapters.

**Completion gate:** kernel update scenarios match the reference behavior and cannot silently leave an unsafe reboot recommendation.

## Phase 8 — Port SBo and ELF diagnostics

**Goal:** safely update and rebuild third-party SlackBuilds.

### SBo

- [ ] Parse the effective `sbopkg` configuration.
- [ ] Synchronize only the configured repository.
- [ ] Detect updates for installed SBo packages.
- [ ] Enumerate installed SBo packages after ABI triggers.
- [ ] Validate target existence in the active repository.
- [ ] Generate a single dependency-ordered queue through `sqg`.
- [ ] Apply per-package options without losing queue semantics.
- [ ] Install rebuilt packages, not merely compile them.
- [ ] Stop on failure according to configuration.
- [ ] Preserve complete build logs.

### ELF diagnostics

- [ ] Implement ELF class detection.
- [ ] Implement loader-cache parsing.
- [ ] Implement `RPATH`, `RUNPATH`, `$ORIGIN`, `$LIB`, and `$PLATFORM` handling.
- [ ] Resolve dependencies recursively without executing target files.
- [ ] Use `lddtree` as an optional optimized backend.
- [ ] Map affected paths to Slackware package manifests.
- [ ] Trigger relevant SBo rebuild targets.
- [ ] Verify affected binaries after the rebuild.

**Completion gate:** dependency ordering, SBo options, failure handling, and ELF verification match the reference fixtures.

## Phase 9 — Port optional desktop and ecosystem modules

**Goal:** add independent modules without coupling them to the Slackware core.

### Cinnamon

- [ ] Detect whether Cinnamon management is applicable.
- [ ] Synchronize CSB only when enabled or auto-detected.
- [ ] Detect CSB repository changes.
- [ ] Detect configured graphical ABI triggers.
- [ ] Rebuild Cinnamon with complete progress and logs.
- [ ] Verify success and report the trigger reason.

### Flatpak

- [ ] Detect Flatpak availability.
- [ ] Update the system installation when configured.
- [ ] Discover eligible user installations.
- [ ] Respect user allowlists and denylists.
- [ ] Execute user updates under the correct account and environment.
- [ ] Report results per installation.

**Completion gate:** disabling or omitting either module has no effect on unrelated update operations.

## Phase 10 — Implement the CLI

**Goal:** provide a complete interface before building the tray frontend.

Planned commands:

```text
slack-update check
slack-update plan
slack-update apply
slack-update status
slack-update modules
slack-update config validate
slack-update config dump-effective
slack-update logs
```

Planned global options:

```text
--json
--no-color
--dry-run
--module <id>
--disable-module <id>
--config <path>
--verbose
--quiet
```

Tasks:

- [ ] Implement command parsing.
- [ ] Implement human-readable summaries.
- [ ] Implement stable JSON output.
- [ ] Implement progress display for interactive terminals.
- [ ] Disable ANSI output for non-interactive use.
- [ ] Map final results to stable exit codes.
- [ ] Add shell-completion generation if practical.
- [ ] Add manual pages.
- [ ] Test operation over SSH and from cron.

**Completion gate:** Slack-Update is fully usable without a graphical desktop.

## Phase 11 — Implement privilege separation

**Goal:** ensure frontends never need to run permanently as root.

- [ ] Enumerate every action that requires root.
- [ ] Define a strict privileged-action protocol.
- [ ] Validate every request again inside the helper.
- [ ] Reject arbitrary executable paths and arbitrary shell commands.
- [ ] Implement a short-lived privileged helper.
- [ ] Evaluate PolicyKit authorization.
- [ ] Provide a root CLI fallback for systems without a graphical authorization agent.
- [ ] Define D-Bus interfaces if D-Bus is selected.
- [ ] Add sender identity and authorization checks.
- [ ] Prevent concurrent privileged operations.
- [ ] Sanitize environment variables.
- [ ] Audit file ownership, permissions, temporary files, and symlink handling.
- [ ] Document the threat model.
- [ ] Add security-focused tests.

**Completion gate:** the tray application can request approved operations without running as root and without exposing arbitrary command execution.

## Phase 12 — Implement tray icon and notifications

**Goal:** provide the desktop experience that motivates the project.

- [ ] Evaluate StatusNotifierItem/AppIndicator compatibility on Slackware desktops.
- [ ] Select a tray implementation compatible with Cinnamon.
- [ ] Keep tray dependencies outside the core and CLI targets.
- [ ] Add icons for idle, checking, updates available, running, warning, failed, and reboot required.
- [ ] Add tooltip summaries.
- [ ] Add a context menu.
- [ ] Add actions for check, view updates, apply, open logs, preferences, and quit.
- [ ] Display per-module status and progress.
- [ ] Integrate desktop notifications.
- [ ] Suppress duplicate notifications for the same result.
- [ ] Add XDG autostart support.
- [ ] Support desktops without a tray through notifications and CLI only.
- [ ] Ensure the tray remains responsive while updates run.
- [ ] Handle helper cancellation and disconnection safely.

**Completion gate:** the user can check, inspect, start, follow, and review updates from the desktop without launching the tray as root.

## Phase 13 — Testing and quality assurance

**Goal:** make regressions visible before they reach a real Slackware installation.

### Unit tests

- [ ] Package-name and version parsing.
- [ ] Package snapshot comparison.
- [ ] Module state transitions.
- [ ] Configuration parsing and precedence.
- [ ] SBo output parsing.
- [ ] Queue option handling.
- [ ] ELF path expansion and dependency resolution.
- [ ] Reboot and boot-safety decisions.
- [ ] JSON serialization and schema validation.
- [ ] Exit-code mapping.

### Integration tests

- [ ] Mock command runner scenarios.
- [ ] Fake Slackware package database.
- [ ] Fake SBo repository and queues.
- [ ] Fake `/boot` tree and `mkinitrd.conf`.
- [ ] Simulated partial update.
- [ ] Simulated process interruption.
- [ ] Simulated low disk space.
- [ ] Simulated privilege denial.
- [ ] Simulated network failure.

### Real-system tests

- [ ] Slackware 15.0 virtual machine snapshots.
- [ ] Slackware-current virtual machine snapshots.
- [ ] Clean installation.
- [ ] Installation with SBo.
- [ ] Installation with Cinnamon.
- [ ] Installation with Flatpak.
- [ ] Headless installation.
- [ ] GRUB installation.
- [ ] Future ELILO/LILO test systems.

### Code quality

- [ ] GCC warning-clean build.
- [ ] Clang warning-clean build.
- [ ] AddressSanitizer pass.
- [ ] UndefinedBehaviorSanitizer pass.
- [ ] Static-analysis pass.
- [ ] Memory-leak checks.
- [ ] Failure-path coverage.
- [ ] Fuzz configuration and structured-input parsers where practical.

**Completion gate:** release builds pass automated tests and the applicable VM acceptance matrix.

## Phase 14 — Packaging and installation

**Goal:** distribute Slack-Update in a way familiar to Slackware users.

- [ ] Create a SlackBuild.
- [ ] Define runtime and optional dependencies.
- [ ] Install binaries under the correct prefixes.
- [ ] Install default configuration under `/etc/slack-update/`.
- [ ] Preserve modified configuration during upgrades.
- [ ] Install icons and desktop files.
- [ ] Install D-Bus and PolicyKit files only when used.
- [ ] Install manual pages and documentation.
- [ ] Add an uninstall manifest or package-owned file list.
- [ ] Test installation, upgrade, reinstall, and removal.
- [ ] Document manual build and package build procedures.
- [ ] Evaluate submission to SlackBuilds.org after the first stable release.

**Completion gate:** Slack-Update can be installed, upgraded, and removed using a normal Slackware package.

## Phase 15 — Documentation, localization, and release

**Goal:** prepare the project for public use and contributions.

- [ ] Complete installation documentation.
- [ ] Complete configuration reference.
- [ ] Document every module and activation mode.
- [ ] Document privilege and security behavior.
- [ ] Document JSON output and exit codes.
- [ ] Document troubleshooting and recovery procedures.
- [ ] Add screenshots after the tray interface stabilizes.
- [ ] Mark all user-facing strings for translation.
- [ ] Provide English user-facing strings.
- [ ] Provide Spanish translation.
- [ ] Add contribution and coding guidelines.
- [ ] Add issue and pull-request templates.
- [ ] Publish a release candidate.
- [ ] Run the complete acceptance matrix.
- [ ] Publish version `1.0.0`.
