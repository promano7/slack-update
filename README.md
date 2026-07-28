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
- [ ] Reference shell script validated on real Slackware 15.0 and Slackware-current installations
- [x] Public GitHub repository created: `slack-update`
- [ ] Build system selected
- [x] License selected: **GNU GPL v3 or later (`GPL-3.0-or-later`)**
- [x] Supported Slackware targets defined: **Slackware 15.0 and Slackware-current**
- [ ] First C milestone started

## Goals

- Provide a reliable and understandable update workflow for Slackware.
- Support Slackware 15.0 and Slackware-current as first-class release targets.
- Keep system updates independent from optional components such as SBo, Cinnamon, and Flatpak.
- Allow every optional module to be enabled, disabled, or automatically detected.
- Provide both graphical and command-line frontends over the same core logic.
- Run the tray application as an unprivileged user.
- Request elevated privileges only for operations that require them.
- Produce human-readable logs and machine-readable results.
- Detect partial updates, broken ELF dependencies, boot preparation failures, and reboot requirements.
- Avoid systemd-only assumptions.
- Make update behavior testable without modifying the host system.

## Supported Slackware targets

Slack-Update must support both:

- **Slackware 15.0**, the supported stable-release baseline;
- **Slackware-current**, the rolling development branch.

Compatibility with both targets is a release requirement, not a best-effort goal.
Reference acceptance tests, the future C implementation, packaging, and installation
documentation must cover both systems. A feature that is only available on one target
must be detected explicitly and must not silently break the other target.

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

The shell reference now reads its operational settings from:

```text
/etc/slack-update/slack-update.conf
```

The repository provides the installable default at
`data/config/slack-update.conf`. When the reference script is run directly from
the source tree and the system file is absent, it uses that repository copy. The
`SLACK_UPDATE_CONFIG` environment variable may select an absolute alternative
path for isolated tests; it is not yet a stable command-line interface.

The current reference configuration uses schema version `1` and externalizes:

- work, log, lock, package-database, SBo, persistent SBo-option, ELF-scan, boot, and Cinnamon paths;
- log retention;
- Slackware `install-new` and `upgrade-all` decisions;
- ABI, Cinnamon ABI, critical, and kernel package groups;
- the trusted Cinnamon repository, branch, and relative builder path;
- activation modes for Flatpak, SBo, ELF diagnostics, Cinnamon, and boot preparation.

The parser treats the file strictly as data and never sources it as shell code.
Unknown sections, unknown keys, duplicates, missing required values, unsupported
schema versions, unsafe values, invalid booleans, and invalid paths are rejected.
Executable command names and argument structures remain fixed in the script so a
configuration value cannot inject an arbitrary shell command.

The shell reference now implements three activation modes for the optional
Flatpak, SBo, ELF, Cinnamon, and boot modules:

- `enabled` — require the module and report missing requirements as an error.
- `disabled` — do not probe or run the module.
- `auto` — run the module only when its requirements and an applicable local installation are detected.

All optional modules default to `auto`. Configuration files created before the
mode keys were added remain valid under schema version `1`; an omitted mode is
interpreted as `auto`.

The current probes are intentionally explicit:

- Flatpak requires the `flatpak` executable.
- SBo requires both `sbopkg` and `sqg`.
- ELF diagnostics require `readelf` and `/sbin/ldconfig`.
- Cinnamon auto-detection accepts the Cinnamon executable, an installed
  `cinnamon` package record, or an existing managed CSB checkout, and also
  requires Git.
- Boot auto-detection enables each supported path independently: a validated
  `mkinitrd.conf` for initrd preparation, with the configured kernel validated
  against the post-update installed package and modules tree, and an installed
  GRUB directory plus both `grub-mkconfig` and `grub-script-check` for staged
  GRUB generation and validation.

An unavailable module in `auto` mode is skipped without becoming a global
failure. An unavailable module in `enabled` mode is reported as an error in
human-readable output, provisional JSON, and final NDJSON events. Stable process
exit-code mapping remains the next roadmap task.

System configuration path:

```text
/etc/slack-update/slack-update.conf
```

Proposed per-user desktop preferences path:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/slack-update/preferences.conf
```

Proposed final configuration shape:

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

- [x] Reject unknown sections, keys, duplicate keys, and invalid critical values with a useful error in the shell reference.
- [ ] Preserve backward compatibility through a configuration schema version.
  The current schema-1 parser preserves compatibility with configurations that
  predate module-mode keys by defaulting omitted modes to `auto`.
- [ ] Distinguish system policy from per-user presentation preferences.
- [x] Parse the shell-reference configuration as data without evaluating shell syntax.
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

The current shell reference exposes two provisional machine-readable interfaces:

- `--json` writes one final JSON result document to standard output.
- `--events` streams newline-delimited JSON (NDJSON) progress events to standard output.
- Human-readable progress is redirected to standard error and the normal log in either mode.
- `--json` and `--events` are mutually exclusive because each reserves standard output.
- Both interfaces currently use schema version `0` with status `provisional`; they are not stable APIs yet.

The provisional event records contain a sequence number, UTC timestamp, operation,
event type, module, action, state, message, and optional exit code. The shell
reference currently emits operation, module, action, warning, error, and completion
events; finer-grained progress percentages and log-message events remain part of
the future core model.

## Exit codes

Exit codes `0` through `8` are a stable process-level contract for the shell
reference and the future C implementation.

| Code | Meaning |
|---:|---|
| `0` | Operation completed successfully; no reboot required |
| `1` | General failure before a complete apply result exists, including failed check or dry-run operations |
| `2` | Apply completed only partially, or post-update verification failed |
| `3` | Critical boot preparation failed; the system must not be rebooted |
| `4` | Operation completed successfully; reboot recommended |
| `5` | Operation completed successfully; reboot required |
| `6` | Another Slack-Update instance is already running |
| `7` | Invalid configuration or command-line arguments |
| `8` | Required privilege was denied or unavailable |

Codes `4` and `5` are successful outcomes despite being non-zero. Update callers,
cron jobs, frontends, and tests must handle them explicitly rather than treating every
non-zero value as failure.

When several apply outcomes are present, the reference uses this precedence:

```text
3 (unsafe boot) > 2 (partial or verification failure) >
5 (reboot required) > 4 (reboot recommended) > 0 (success)
```

Codes `6`, `7`, and `8` are returned before the selected operation starts. A
successful `--check` returns `0` whether or not `slackpkg check-updates` reports
available repository changes. A kernel headers change alone does not produce code `5`.

The final `exit_code` field emitted by `--json` and the `exit_code` of the final
`operation_completed` event emitted by `--events` use this stable contract. Exit
codes attached to intermediate action events remain the raw status of the external
command represented by that event.

- [x] Confirm exit-code semantics.
- [ ] Ensure shell reference and C implementation return equivalent results.
- [x] Document which codes are stable API before version 1.0.

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
│   │   └── slack-update.conf
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
- [x] Add `--apply` for approved changes.
- [x] Add `--dry-run` that produces a complete plan without modifying the system.
- [x] Add `--json` for structured final output.
- [x] Add a machine-readable progress/event mode if practical.
- [x] Move hard-coded behavior into a configuration file.
- [x] Add `enabled`, `disabled`, and `auto` modes for optional modules.
- [x] Add stable exit codes.
- [ ] Ensure every comment added to the script is written in English.

### Safety validation

- [x] Validate exact Slackware package-name parsing.
- [x] Validate package snapshots before and after updates.
- [x] Confirm that secondary modules stop after partial Slackware updates.
- [x] Confirm deterministic SBo target selection.
- [x] Confirm dependency order is preserved in generated SBo queues.
- [x] Confirm custom SBo options are preserved.
- [x] Confirm no personal queue is overwritten.
- [x] Confirm ELF analysis never executes inspected binaries.
- [x] Confirm architecture-specific library resolution.
- [x] Confirm initrd validation uses the installed kernel.
- [x] Confirm GRUB is not updated after an initrd failure.
- [x] Confirm staged GRUB configuration is validated before replacement.
- [x] Confirm interruption signals release locks and terminate execution.
- [ ] Confirm errors produce non-zero exit codes.
- [ ] Confirm cron execution works with a minimal environment.

Slackware package records are parsed from the rightmost three hyphen-separated
fields, matching the `name-version-architecture-build` convention used by
Slackware `pkgtools`. Directory prefixes and the supported package archive
extensions (`.tgz`, `.tbz`, `.tlz`, and `.txz`) are removed before parsing.
Package comparisons are literal: similarly prefixed names such as `openssl` and
`openssl-solibs` remain distinct, and SBo ownership is determined from the build
field suffix rather than an arbitrary substring match.

The parser regression test covers representative Slackware 15.0,
Slackware-current, patched-package, multi-hyphen, plus-sign, and `_SBo` records:

```bash
tests/reference/test-package-name-parsing.sh
```

Package snapshots are generated from the configured `pkgtools` package database,
normalized to canonical records, sorted with the C locale, checked for duplicates,
and installed atomically only after complete validation. Empty, missing, unreadable,
malformed, unsorted, duplicate, or non-canonical snapshots are rejected. Apply stops
before package operations when the baseline snapshot is invalid and stops all work
that depends on package-state comparison when the final snapshot is invalid.

The focused snapshot regression test is:

```bash
tests/reference/test-package-snapshots.sh
```

A non-zero result from any Slackware package operation (`update`, `install-new`,
or `upgrade-all`) is treated as a partial Slackware update. The post-update
snapshot is still captured for diagnosis, but Flatpak, package-change analysis,
SBo, ELF, Cinnamon, initrd, and GRUB work is blocked. Provisional JSON reports
those modules as `blocked`, and no secondary-module start events are emitted.

The focused partial-update regression test is:

```bash
tests/reference/test-partial-slackware-update.sh
```

SBo target selection is now a separate deterministic stage. Active package
records are extracted from queue files independently of filesystem enumeration
order, comments, recursive queue references, deselected records, and build
options. Installed ABI rebuild candidates and broken-object package owners use
the exact configured SBo build suffix. Every selected target is validated, and
independent target sets are deduplicated and sorted with the C locale.

Generated queue order is preserved separately. Active records in each `.sqf`
file become dependency constraints, shared dependencies are deduplicated, and a
deterministic topological order combines all generated queues. C-locale ordering
is used only to break ties between independent packages. Cyclic, contradictory,
or unsafe constraints fail atomically and prevent submission to `sbopkg`. The
final queue retains this dependency-ordered core and appends unique ABI and
broken-ELF rebuild targets deterministically.

Per-package build options are preserved independently from dependency ordering.
Options already present in generated queues are collected, normalized, and
checked for conflicts. The optional persistent file configured by
`sbo.options_file` overlays those generated values, so custom choices survive
subsequent `sqg -a` regeneration. Its default path is:

```text
/etc/slack-update/sbo-options.sqf
```

The persistent file uses normal queue records such as:

```text
OpenCASCADE | FFMPEG=yes FREEIMAGE=yes TBB=yes
ffmpeg | CHROMAPRINT=yes CODECS=all
package | CFLAGS="-O2 -fPIC" TESTS=no
```

Blank lines and comments are accepted. Every active record must contain one or
more safe `NAME=value` assignments. Identical options repeated by generated
queues are deduplicated, conflicting generated values fail closed, and duplicate
records in the persistent override file are rejected. The persistent file is
optional; if it does not exist, options found in current generated queues are
used. Options are applied to both dependency-ordered targets and later ABI or
broken-ELF rebuild targets without selecting additional packages. Invalid option
data preserves the previous output atomically and prevents `sbopkg` from running.

Personal SBo queues are now treated as read-only source state. During apply, the
effective sbopkg `QUEUEDIR` is resolved from the supported system and local
configuration forms, separately from a private per-run workspace under
Slack-Update's work directory. Regular `.sqf` files are copied byte-for-byte into
that workspace as owner-only regular files, preserving nested paths. Queue
symlinks and unrelated files are not followed or copied.

`slack-update` invokes `sqg -a` through owner-only system and local configuration
wrappers stored inside the disposable workspace. The wrappers load the original
sbopkg system and local configuration, then reassert the private `QUEUEDIR` after
each layer. This prevents either configuration file from redirecting generation
back to personal state after environment variables have been set. Every
subsequent dependency, target, and build-option stage reads from the private
copy. The configured personal directory is never passed to the generator and
remains unchanged even when generation fails partway through. A
workspace-preparation, wrapper-generation, or non-zero `sqg` result blocks target
construction and final `sbopkg -B` submission, so the workflow cannot fall back
to personal state or consume a partially generated queue tree.

Workspace validation rejects relative paths, a workspace equal to or canonically
inside the personal queue tree, symlinked personal queue roots, and pre-existing
workspace paths. A missing personal queue directory produces an empty private
workspace. Apply JSON reports both path roles, copied regular-file and ignored
symlink counts, the explicit isolation state, and whether private generation
completed successfully. Cleanup removes a workspace only when Slack-Update
recorded ownership at creation and its canonical identity is unchanged;
pre-existing paths and replacement symlinks are never followed or deleted.

The focused SBo regression tests are:

```bash
tests/reference/test-sbo-target-selection.sh
tests/reference/test-sbo-dependency-order.sh
tests/reference/test-sbo-options.sh
tests/reference/test-sbo-personal-queue-protection.sh
```

ELF inspection now uses one static path for both initial detection and
post-rebuild verification. Candidate paths are resolved without following
non-regular targets, filtered by the ELF magic bytes, and read with `readelf -d`.
The loader cache is obtained once from `/sbin/ldconfig -p`. Every cached
library path is resolved and inspected with `readelf -h`, then normalized as an
exact record containing soname, ELF class, data encoding, machine, and canonical
path. A `DT_NEEDED` entry is considered available only when both its soname and
the inspected object's class, data encoding, and machine match a cached record.
This prevents an ELF32, x86-64, AArch64, or opposite-endian library from hiding
a broken dependency for an incompatible object. Inspected objects and cached
libraries are never invoked as commands, and dynamic-loader trace execution is
not used. If an object cannot be re-inspected after a rebuild, it remains in the
broken-object set rather than being reported as repaired.

Provisional JSON reports the inspection method, explicitly records
`executes_inspected_objects=false` and `architecture_specific_resolution=true`,
lists the exact identity fields, reports the normalized cache-record count, and
includes static scan and post-build verification statuses.

The focused regression tests are:

```bash
tests/reference/test-elf-static-inspection.sh
tests/reference/test-elf-architecture-resolution.sh
```

The static-inspection test uses guarded executable fixtures that create a marker
if run, while the architecture-resolution test mixes ELF32 x86, ELF64 x86-64,
AArch64, and opposite-endian cache records sharing the same soname. Together
they cover the initial scan, symlinked objects, exact identity matching, parser
and cache failures, and post-rebuild verification while proving that inspected
objects are never executed.

Initrd validation now derives its target from the exact `kernel-generic` record
in the validated post-update package snapshot. It does not use `uname -r`,
because the running kernel may legitimately remain older until reboot. The
configured `KERNEL_VERSION` must match the installed package version exactly,
and the corresponding configured modules root must contain a
`<modules_directory>/<version>` directory before `mkinitrd -F` is allowed to
run. Missing, unsafe, duplicate, stale, or ambiguous data fails closed.

Schema-1 configuration accepts these optional keys, with backward-compatible
defaults when older files omit them:

```ini
[boot]
kernel_package=kernel-generic
modules_directory=/lib/modules
```

`OUTPUT_IMAGE` is the preferred generated-image path from `mkinitrd.conf`; the
legacy `OUTPUT` assignment remains supported, followed by
`boot.initrd_default_output` as the fallback. Provisional JSON reports the
configured and installed versions, the package source, modules path, output
path, validation status, and diagnostic. The focused regression test is:

```bash
tests/reference/test-initrd-installed-kernel.sh
```

GRUB generation now has an explicit initrd prerequisite whenever both actions
were scheduled by the same kernel update. A failed initrd validation, a non-zero
`mkinitrd`, a missing or empty generated image, or required initrd preparation
that is unavailable in auto mode prevents the GRUB action from starting. The
coordinator emits `grub_state=blocked` without an `action_started` event, and
`update_grub_configuration` repeats the guard immediately before the
`grub-mkconfig` command as a defensive boundary. GRUB-only work remains valid
when no initrd action was required.

Provisional JSON reports `grub_command_attempted`,
`grub_blocked_by_initrd`, and a stable `grub_block_reason`, allowing consumers
to distinguish an intentionally suppressed command from a real
`grub-mkconfig` failure. The focused regression test is:

```bash
tests/reference/test-grub-blocked-after-initrd-failure.sh
```

GRUB configuration replacement is now transactional. `grub-mkconfig` writes to
an owner-only, unpredictable temporary file created beside the configured
`grub.cfg`, ensuring that the final rename remains on the same filesystem. The
active configuration path is never passed to the generator. The temporary file
must be a readable, non-empty regular file and must pass `grub-script-check`
before installation is considered.

Slack-Update fingerprints the active configuration before generation and checks
it again immediately before replacement. A concurrent modification, active
symlink, configuration outside the configured GRUB directory, generation
failure, validation failure, permission failure, or final rename failure leaves
the active file untouched. When validation succeeds, existing ownership and
permissions are preserved and `mv -T` performs the final atomic replacement. If no active file
existed, the new configuration is installed with mode `0600`.

Provisional JSON reports the active and temporary paths, generation, validation,
and installation exit codes, the validator name, replacement-attempt state, and
whether the active configuration was replaced. Dry-run describes the same
staged generation, validation, and atomic installation sequence. The focused
regression test is:

```bash
tests/reference/test-grub-atomic-replacement.sh
```

Interruption handling is installed immediately after the process acquires the
single-instance lock, before runtime directories or temporary files are
created. Dedicated `SIGHUP`, `SIGINT`, and `SIGTERM` handlers disable all runtime
traps, run the same ownership-aware cleanup used for normal exit, explicitly
unlock and close the lock descriptor, and terminate without returning to the
interrupted workflow. The conventional shell statuses are `129`, `130`, and
`143` respectively; they identify interrupted runs and remain outside the
stable `0` through `8` completed-run result contract.

The focused regression test launches real subprocesses, observes their active
`flock`, delivers each signal, and verifies the terminating status, lock
availability, temporary-file removal, GRUB transaction cleanup, private SBo
workspace cleanup, unrelated-file preservation, and absence of post-signal
execution. It also covers interruption immediately after lock acquisition,
before runtime state exists:

```bash
tests/reference/test-signal-cleanup.sh
```

### Real-system acceptance matrix

- [ ] Fully updated system with no available changes.
- [ ] Normal Slackware package update.
- [ ] `install-new` introduces new packages.
- [ ] Kernel package update.
- [ ] Kernel headers update without a kernel image update.
- [ ] Invalid or stale `KERNEL_VERSION` in `mkinitrd.conf`.
- [ ] `mkinitrd` failure leaves GRUB configuration untouched.
- [ ] GRUB generation failure leaves the active configuration untouched.
- [ ] Invalid staged GRUB syntax leaves the active configuration untouched.
- [ ] Concurrent GRUB configuration modification blocks replacement.
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

- [ ] Slackware 15.0 and Slackware-current are both covered by the applicable acceptance matrix.
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
- [x] Implement `--check` for non-destructive Slackware repository update detection.
- [x] Implement `--apply` as an explicit selector for the existing update workflow.
- [x] Implement `--dry-run` as a complete non-modifying plan.
- [x] Implement `--json` for structured final output.
- [x] Implement provisional NDJSON progress events through `--events`.
- [x] Move hard-coded reference behavior into a validated configuration file.
- [x] Add `enabled`, `disabled`, and `auto` modes for optional modules.
- [x] Add stable exit codes.
- [x] Validate exact Slackware package-name parsing.
- [x] Validate package snapshots before and after updates.
- [x] Confirm that secondary modules stop after partial Slackware updates.
- [x] Confirm deterministic SBo target selection.
- [x] Preserve dependency order in generated SBo queues.
- [x] Preserve custom SBo build options.
- [x] Protect personal SBo queues from `sqg` overwrites.
- [x] Confirm ELF analysis never executes inspected binaries.
- [x] Confirm architecture-specific library resolution.
- [x] Confirm initrd validation uses the installed kernel.
- [x] Confirm GRUB is not updated after an initrd failure.
- [ ] Validate staged GRUB configuration before replacement.
- [ ] Execute and document the Phase 1 acceptance matrix on Slackware 15.0 and Slackware-current.
- [ ] Freeze `reference-v1`.
- [ ] Begin the C architecture only after the reference gate is complete.
