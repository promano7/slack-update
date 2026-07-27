# Slack-Update

A modular and configurable update manager for Slackware, written in C.

Slack-Update is intended to provide a desktop-oriented update experience similar in spirit to Arch Update, while respecting Slackware's tools, conventions, and non-systemd environment. It will support command-line use, a system tray application, desktop notifications, optional update modules, structured results, and safe privileged operations.

> [!IMPORTANT]
> The project is currently in the planning and reference-implementation stage. The existing shell script is the executable specification for the future C implementation. C development must not begin until the script has passed the acceptance tests defined in this roadmap.

## Project status

- [x] Project name selected: **Slack-Update**
- [x] Implementation language selected: **C**
- [x] Core concept defined: Slackware update manager with CLI, tray icon, and notifications
- [x] Modular and configurable design established
- [x] Reference shell script created
- [ ] Reference shell script validated on a real Slackware-current installation
- [x] Public GitHub repository created: `slack-update`
- [ ] Build system selected
- [x] License selected: **GNU GPL v3 or later (`GPL-3.0-or-later`)**
- [ ] First C milestone started

## Goals

- Provide a reliable and understandable update workflow for Slackware.
- Support Slackware-current first, without preventing later support for stable releases.
- Keep system updates independent from optional components such as SBo, Cinnamon, and Flatpak.
- Allow every optional module to be enabled, disabled, or automatically detected.
- Provide both graphical and command-line frontends over the same core logic.
- Run the tray application as an unprivileged user.
- Request elevated privileges only for operations that require them.
- Produce human-readable logs and machine-readable results.
- Detect partial updates, broken ELF dependencies, boot preparation failures, and reboot requirements.
- Avoid systemd-only assumptions.
- Make update behavior testable without modifying the host system.

## Non-goals for the first release

- [ ] Implement a replacement for `slackpkg`, `sbopkg`, Flatpak, or bootloader tools.
- [ ] Provide transactional package management that Slackware itself does not provide.
- [ ] Load third-party binary plugins through a public runtime ABI.
- [ ] Support every Slackware-compatible package manager in version 1.0.
- [ ] Perform unattended package installation by default.
- [ ] Require a graphical environment for CLI or headless use.

The first release will use an internal module interface. A stable external plugin ABI may be designed later, after the internal API has proved reliable.

## Design principles

1. **Fail safely**
   A failed Slackware update, initrd generation, or bootloader update must prevent unsafe follow-up actions.

2. **Detect before acting**
   Every module follows a common lifecycle: probe, check, plan, apply, verify, and report.

3. **Optional means optional**
   Missing Cinnamon, Flatpak, SBo, GRUB, or any other optional component must not be treated as a global application failure.

4. **No hidden root session**
   The tray process must never run permanently as root.

5. **One source of truth**
   The CLI, tray application, and privileged helper must use the same core data model and status definitions.

6. **Deterministic operation**
   Package selection, queue generation, dependency ordering, and result reporting must not depend on filesystem enumeration order or ambiguous text parsing.

7. **No systemd dependency**
   Scheduling, startup, logging, and privilege handling must remain compatible with standard Slackware installations.

8. **Observable execution**
   Every phase must expose progress, warnings, errors, logs, and a final structured result.

## Planned components

| Component | Purpose | Privileges |
|---|---|---|
| `libslackupdate` | Core state model, configuration, modules, planning, command execution, and reporting | Unprivileged by default |
| `slack-update` | Command-line frontend | Unprivileged for checks; elevation for changes |
| `slack-update-helper` | Short-lived privileged executor for approved operations | Root only while needed |
| `slack-update-tray` | System tray icon, status, actions, and desktop notifications | Unprivileged |
| Reference shell script | Executable specification and regression oracle during the port | Root for apply operations |

## High-level architecture

```text
+----------------------+       +----------------------+
| slack-update-tray    |       | slack-update CLI     |
| notifications        |       | interactive/headless |
+----------+-----------+       +----------+-----------+
           |                              |
           +--------------+---------------+
                          |
                +---------v----------+
                | libslackupdate      |
                | configuration       |
                | module registry     |
                | planner             |
                | result model        |
                +---------+----------+
                          |
              unprivileged checks and planning
                          |
                +---------v----------+
                | privilege boundary |
                +---------+----------+
                          |
                +---------v----------+
                | privileged helper  |
                | validated actions  |
                | command execution  |
                +---------+----------+
                          |
       +------------------+-----------------------------+
       |                  |              |              |
   slackpkg           sbopkg/sqg     mkinitrd and    optional
                                      bootloader      modules
```

The preferred desktop integration is D-Bus plus PolicyKit where available. A root CLI mode must remain available for installations without a graphical authorization agent.

## Module lifecycle

Every update module should implement the same conceptual lifecycle:

1. `probe` — determine whether the module is available and applicable.
2. `check` — inspect repositories and local state without applying changes.
3. `plan` — return the exact actions, dependencies, risks, and required privileges.
4. `apply` — perform the approved changes.
5. `verify` — confirm that the expected final state was reached.
6. `report` — return structured status, counts, warnings, errors, and reboot requirements.

Planned module states:

- `disabled`
- `unavailable`
- `idle`
- `checking`
- `update-available`
- `planned`
- `running`
- `success`
- `warning`
- `failed`
- `skipped`
- `reboot-required`

## Planned modules

### Slackware module

The Slackware module is the only core update module enabled by default.

- Run `slackpkg update`.
- Detect and optionally apply `install-new`.
- Detect and optionally apply `upgrade-all`.
- Stop secondary modules after a partial Slackware update.
- Snapshot the package database before and after changes.
- Determine exact package names that changed.
- Detect critical library and kernel changes.
- Expose update counts and package lists to the frontends.

### SBo module

Optional module for systems using `sbopkg` and `sqg`.

- Auto-detect `sbopkg`, `sqg`, and their configuration.
- Synchronize the configured SBo repository.
- Detect potential updates for installed SBo packages.
- Rebuild installed SBo packages after configured ABI changes.
- Map broken ELF objects to owning SBo packages.
- Generate one deterministic dependency-ordered queue.
- Preserve per-package build options.
- Stop on the first build failure by default.
- Verify repaired binaries after rebuilding.

### ELF dependency module

Optional diagnostic module, enabled automatically when the required tools are available.

- Inspect ELF objects statically without executing them.
- Prefer `lddtree` when available.
- Provide a `readelf`-based fallback.
- Resolve `RPATH`, `RUNPATH`, `$ORIGIN`, architecture, and loader cache entries.
- Avoid duplicate scans of the same real file.
- Record the unresolved library for every affected object.
- Map affected files to installed package manifests.

### Boot module

Optional module activated by relevant kernel changes.

- Detect the installed kernel and package changes.
- Validate `/etc/mkinitrd.conf` before running `mkinitrd`.
- Verify that the configured kernel has installed modules.
- Generate and validate the initrd.
- Refuse bootloader changes when initrd preparation fails.
- Stage and validate bootloader configuration before replacing it.
- Preserve a backup of the previous configuration.
- Report a clear **do not reboot** condition after critical failures.

Planned bootloader adapters:

- [ ] GRUB
- [ ] ELILO
- [ ] LILO
- [ ] Extensible bootloader adapter interface

GRUB will be the first implemented adapter because it is already covered by the reference script.

### Cinnamon module

Optional module for users who install Cinnamon through CinnamonSlackBuilds.

- Default mode: `auto`.
- Remain disabled when Cinnamon or its configured build repository is absent.
- Synchronize the configured CSB repository.
- Detect repository changes independently of Slackware ABI changes.
- Trigger a rebuild after relevant graphical ABI changes.
- Run the configured Cinnamon build command.
- Report the exact reason for a rebuild.

### Flatpak module

Optional module for systems that use Flatpak.

- Default mode: `auto`.
- Update system Flatpaks independently from user Flatpaks.
- Discover eligible local users safely.
- Allow an explicit user allowlist or denylist.
- Report failures per installation and per user.
- Do nothing when Flatpak is not installed or the module is disabled.

### Notification module

Desktop-only module.

- Notify when updates are available.
- Notify when an update completes.
- Notify when an update fails.
- Notify when a reboot is recommended or required.
- Avoid repeated notifications for the same update set.
- Support configurable urgency and notification categories.
- Never display privileged command output without sanitization.

### Scheduler module

Optional scheduling support without requiring systemd.

- Periodic checks from the tray process.
- Optional cron integration for headless systems.
- Configurable interval and quiet hours.
- Network availability checks before repository access.
- Single-instance locking shared with manual executions.
- No automatic application of updates unless explicitly enabled.

## Configuration model

Modules will support three activation modes:

- `enabled` — always attempt to use the module and report missing requirements as an error.
- `disabled` — never probe or run the module.
- `auto` — use the module only when its requirements and relevant local installation are detected.

Proposed system configuration path:

```text
/etc/slack-update/slack-update.conf
```

Proposed per-user desktop preferences path:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/slack-update/preferences.conf
```

Example configuration:

```ini
[core]
check_interval_minutes=60
automatic_checks=true
automatic_apply=false
log_retention_days=30
minimum_free_mib=4096

[module.slackware]
mode=enabled
install_new=true
upgrade_all=true

[module.sbo]
mode=auto
rebuild_on_abi_change=true
stop_on_failure=true
options_file=/etc/slack-update/sbo-options.sqf

[module.elf]
mode=auto
scan_after_system_update=true

[module.boot]
mode=auto
bootloader=auto
update_initrd=true

[module.cinnamon]
mode=auto
repository=/var/lib/slack-update/csb
branch=master

[module.flatpak]
mode=auto
update_system=true
update_users=true

[notifications]
enabled=true
notify_available=true
notify_completed=true
notify_failed=true
notify_reboot=true
```

Configuration requirements:

- [ ] Reject unknown critical values with a useful error.
- [ ] Preserve backward compatibility through a configuration schema version.
- [ ] Distinguish system policy from per-user presentation preferences.
- [ ] Never allow user-controlled configuration to inject shell syntax.
- [ ] Provide `slack-update config validate`.
- [ ] Provide `slack-update config dump-effective`.

## Result and event model

Every execution must produce a stable structured result in addition to human-readable output.

Proposed top-level result fields:

```json
{
  "schema_version": 1,
  "operation": "apply",
  "success": true,
  "partial": false,
  "reboot": "recommended",
  "boot_safe": true,
  "started_at": "2026-01-01T10:00:00Z",
  "finished_at": "2026-01-01T10:15:00Z",
  "modules": {},
  "warnings": [],
  "errors": []
}
```

Progress should be exposed as events so that the CLI and tray application can display the same execution:

- operation started;
- module started;
- module progress changed;
- action started;
- log message emitted;
- warning emitted;
- error emitted;
- reboot state changed;
- module completed;
- operation completed.

## Exit codes

The exact values must be finalized before the CLI is considered stable.

| Code | Meaning |
|---:|---|
| `0` | Operation completed successfully; no reboot required |
| `1` | General failure |
| `2` | Partial update or verification failure |
| `3` | Critical boot preparation failure; do not reboot |
| `4` | Success; reboot recommended |
| `5` | Success; reboot required |
| `6` | Another instance is already running |
| `7` | Invalid configuration or command-line arguments |
| `8` | Required privilege was denied or unavailable |

- [ ] Confirm exit-code semantics.
- [ ] Ensure shell reference and C implementation return equivalent results.
- [ ] Document which codes are stable API before version 1.0.

## Proposed repository layout

```text
slack-update/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── CONTRIBUTING.md
├── meson.build or CMakeLists.txt
├── include/
│   └── slack-update/
├── src/
│   ├── core/
│   ├── config/
│   ├── execution/
│   ├── modules/
│   │   ├── slackware/
│   │   ├── sbo/
│   │   ├── elf/
│   │   ├── boot/
│   │   ├── cinnamon/
│   │   ├── flatpak/
│   │   ├── notifications/
│   │   └── scheduler/
│   ├── cli/
│   ├── helper/
│   └── tray/
├── data/
│   ├── config/
│   ├── icons/
│   ├── desktop/
│   ├── dbus/
│   ├── polkit/
│   └── translations/
├── docs/
│   ├── architecture.md
│   ├── configuration.md
│   ├── module-api.md
│   ├── security.md
│   └── testing.md
├── tests/
│   ├── unit/
│   ├── integration/
│   ├── fixtures/
│   ├── mocks/
│   └── system/
├── tools/
│   └── reference/
│       └── slack-update-reference.sh
└── packaging/
    └── slackware/
        ├── slack-update.SlackBuild
        ├── slack-desc
        └── doinst.sh
```

The final layout may change during the architecture prototype, but separation between core, modules, frontends, helper, tests, and packaging must be preserved.

# Development roadmap

## Phase 0 — Create the repository and preserve the reference implementation

**Goal:** establish a clean project history before writing C code.

- [x] Create the public GitHub repository `slack-update`.
- [x] Add this `README.md`.
- [x] Add the corrected shell script under `tools/reference/slack-update-reference.sh`.
- [x] Preserve the current reference script byte-for-byte while relocating it; no earlier historical copy was available.
- [x] Add a `.gitignore` suitable for C build outputs and editor files.
- [x] Choose a license: GNU GPL v3 or later (`GPL-3.0-or-later`).
- [x] Add `CONTRIBUTING.md` with the English commit-message policy.
- [x] Add `CHANGELOG.md` using a consistent release format.
- [x] Tag the initial planning state as `planning-v1` when the repository structure is complete.

**Completion gate:** the public repository contains documentation and the untouched reference script, but no premature C implementation.

## Phase 1 — Stabilize and validate the shell reference

**Goal:** make the script a trustworthy executable specification.

### Refactoring and interfaces

- [x] Rename paths and identifiers from `sbo-auto` to `slack-update` where appropriate.
- [x] Split the script into clearly named functions.
- [x] Add command-line argument parsing.
- [x] Add `--check` for non-destructive update detection.
- [ ] Add `--apply` for approved changes.
- [ ] Add `--dry-run` that produces a complete plan without modifying the system.
- [ ] Add `--json` for structured final output.
- [ ] Add a machine-readable progress/event mode if practical.
- [ ] Move hard-coded behavior into a configuration file.
- [ ] Add `enabled`, `disabled`, and `auto` modes for optional modules.
- [ ] Add stable exit codes.
- [ ] Ensure every comment added to the script is written in English.

### Safety validation

- [ ] Validate exact Slackware package-name parsing.
- [ ] Validate package snapshots before and after updates.
- [ ] Confirm that secondary modules stop after partial Slackware updates.
- [ ] Confirm deterministic SBo target selection.
- [ ] Confirm dependency order is preserved in generated SBo queues.
- [ ] Confirm custom SBo options are preserved.
- [ ] Confirm no personal queue is overwritten.
- [ ] Confirm ELF analysis never executes inspected binaries.
- [ ] Confirm architecture-specific library resolution.
- [ ] Confirm initrd validation uses the installed kernel.
- [ ] Confirm GRUB is not updated after an initrd failure.
- [ ] Confirm staged GRUB configuration is validated before replacement.
- [ ] Confirm interruption signals release locks and terminate execution.
- [ ] Confirm errors produce non-zero exit codes.
- [ ] Confirm cron execution works with a minimal environment.

### Real-system acceptance matrix

- [ ] Fully updated system with no available changes.
- [ ] Normal Slackware package update.
- [ ] `install-new` introduces new packages.
- [ ] Kernel package update.
- [ ] Kernel headers update without a kernel image update.
- [ ] Invalid or stale `KERNEL_VERSION` in `mkinitrd.conf`.
- [ ] `mkinitrd` failure.
- [ ] GRUB generation failure.
- [ ] Low free space on `/`.
- [ ] Low free space on `/boot`.
- [ ] ABI library update with installed SBo packages.
- [ ] SBo package with multiple dependencies.
- [ ] SBo build failure in the middle of a queue.
- [ ] Removed SBo package no longer present in the repository.
- [ ] Broken ELF object owned by an SBo package.
- [ ] Broken ELF object not owned by an SBo package.
- [ ] Cinnamon installed and CSB updated.
- [ ] Cinnamon installed with graphical ABI changes.
- [ ] Cinnamon not installed.
- [ ] Flatpak system installation only.
- [ ] Flatpak user installation only.
- [ ] Flatpak not installed.
- [ ] Network failure before repository synchronization.
- [ ] Simultaneous execution attempt.
- [ ] `SIGINT`, `SIGTERM`, and `SIGHUP` during safe test operations.
- [ ] Execution from cron with no interactive terminal.

### Reference freeze

- [ ] Record expected output and exit code for every acceptance scenario.
- [ ] Store sanitized fixtures and logs under `tests/fixtures/reference/`.
- [ ] Define the version 1 JSON result schema.
- [ ] Mark the script behavior as `reference-v1`.
- [ ] Do not start the C port until all blocking tests pass.

**Completion gate:** the shell reference behaves deterministically, passes the acceptance matrix, and has documented structured outputs.

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

## Security requirements

- [ ] The tray application never runs as root.
- [ ] The helper exposes only predefined operations.
- [ ] External commands are executed without a shell unless strictly necessary.
- [ ] Paths crossing the privilege boundary are canonicalized and validated.
- [ ] Temporary files use safe creation APIs and restrictive permissions.
- [ ] Symlink attacks are considered for every privileged file operation.
- [ ] Configuration writable by normal users cannot alter privileged command paths.
- [ ] Repository URLs and executable paths have explicit trust rules.
- [ ] Logs do not expose secrets or sensitive environment data.
- [ ] Update locks cover CLI, tray, cron, and helper operations.
- [ ] Boot files are validated before activation.
- [ ] The UI clearly distinguishes warnings from unsafe-to-reboot failures.

## Coding standards

- Use English for source-code identifiers, comments, commit messages, documentation, and developer-facing logs.
- Keep user-facing strings translatable.
- Prefer explicit ownership and cleanup rules.
- Avoid global mutable state where practical.
- Keep modules independent from graphical code.
- Do not parse command output when a stable file or API is available.
- Treat external command output as untrusted input.
- Compile with strict warnings.
- Add tests with every bug fix.
- Keep commits focused and buildable whenever practical.

## Commit policy

All commit messages will be written in English. During implementation, every delivered file change should be accompanied by a proposed commit message.

Recommended format:

```text
<type>(<scope>): <imperative summary>
```

Suggested types:

- `build` — build-system or dependency changes;
- `docs` — documentation only;
- `feat` — new functionality;
- `fix` — bug fix;
- `refactor` — internal restructuring without behavior change;
- `test` — tests and fixtures;
- `chore` — maintenance work;
- `ci` — continuous-integration changes;
- `security` — security hardening.

Examples:

```text
docs: add initial project roadmap
build: add the initial Meson project skeleton
feat(core): add the module lifecycle interface
feat(slackware): detect changed package records
fix(sbo): preserve dependency order in generated queues
test(boot): cover invalid mkinitrd kernel versions
security(helper): reject unapproved executable paths
```

Commit rules:

- [ ] Use the imperative mood.
- [ ] Keep the subject concise.
- [ ] Do not end the subject with a period.
- [ ] Use a scope when it improves clarity.
- [ ] Explain why in the body when the change is not obvious.
- [ ] Mention incompatible configuration or output changes explicitly.
- [ ] Keep unrelated changes in separate commits.

## License

Slack-Update is licensed under the GNU General Public License, version 3 or any later version (`GPL-3.0-or-later`). See `LICENSE` for the complete license text.

## Versioning

The project should use semantic versioning after public interfaces begin to stabilize.

- `0.x.y` — architecture and feature development; interfaces may change.
- `1.0.0` — first stable CLI, configuration schema, helper protocol, and documented module behavior.
- Patch releases must not make incompatible changes to stable machine-readable interfaces.

Planned compatibility surfaces:

- [ ] Configuration schema.
- [ ] CLI commands and options.
- [ ] Exit codes.
- [ ] JSON result schema.
- [ ] D-Bus/helper protocol.
- [ ] Module identifiers.
- [ ] External plugin ABI, only if introduced later.

## Definition of version 1.0

Slack-Update 1.0 will be ready when:

- [ ] Slackware updates can be checked and applied safely from the CLI.
- [ ] Optional SBo, Cinnamon, Flatpak, ELF, and boot modules can be independently configured.
- [ ] Missing optional software does not cause unrelated failures.
- [ ] The tray application reports available updates and operation progress.
- [ ] Desktop notifications work without running the tray as root.
- [ ] Privileged operations use a constrained helper or documented root CLI mode.
- [ ] Results are available in stable human-readable and JSON formats.
- [ ] Partial updates and boot failures are clearly identified.
- [ ] The complete reference acceptance matrix passes.
- [ ] Automated unit and integration tests pass with GCC and Clang.
- [ ] A Slackware package and SlackBuild are available.
- [ ] Installation, configuration, recovery, and security behavior are documented.

## Immediate next steps

- [x] Commit the completed Phase 0 repository structure.
- [x] Tag the initial planning state as `planning-v1` after the Phase 0 commit.
- [x] Rename `sbo-auto` paths and identifiers to `slack-update` where appropriate, without changing behavior.
- [x] Modularize the reference script into clearly named functions without changing behavior.
- [x] Add basic command-line argument parsing without implementing later operation modes.
- [x] Implement `--check` as a non-destructive Slackware repository update check.
- [ ] Implement `--apply`, `--dry-run`, and `--json` in the script.
- [ ] Execute and document the Phase 1 acceptance matrix.
- [ ] Freeze `reference-v1`.
- [ ] Begin the C architecture only after the reference gate is complete.
