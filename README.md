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
the stable exit-code mapping described below is applied consistently.

System configuration path:

```text
/etc/slack-update/slack-update.conf
```

Cron and other unattended launchers are normalized before argument parsing or
configuration loading. The reference replaces the inherited command path with:

```text
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```

It also sets the root identity and home directory, uses `/tmp`, the C locale,
`TERM=dumb`, and `umask 077`; removes inherited desktop-session variables; and
disables Git and SSH credential prompts. The workflow does not read from a
terminal, `slackpkg` is invoked in batch mode, Flatpak uses its non-interactive
mode, and SBo queue processing uses batch arguments.

A conservative root crontab entry performs only the non-destructive check:

```cron
0 3 * * 0 /usr/local/sbin/slack-update --check
```

Automated application remains explicit through `--apply`. Codes `4` and `5`
are successful apply outcomes, so wrappers must use the exit-code contract
below rather than treating every non-zero result as a failure.

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
- [x] Confirm errors produce non-zero exit codes.
- [x] Confirm cron execution works with a minimal environment.

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

Runtime setup now fails closed before the selected operation starts if Slack-Update
cannot record its start time, create its work or log directories, allocate required
temporary files, create the private dry-run workspace, initialize dry-run state, or
open the runtime log. A completion-time capture failure is also included in the final
result instead of being ignored. These failures return stable code `1` before an
operation starts; failures discovered during apply continue to use the documented
partial or boot-unsafe precedence.

The focused exit-code regression suite verifies all stable codes `0` through `8`,
every current error source represented by the final result model, successful
non-zero reboot outcomes, early command-line/configuration/privilege/lock failures,
runtime and logging setup failures, completion-time failure, and consistency between
the process status, final JSON, and final NDJSON event:

```bash
tests/reference/test-error-exit-codes.sh
```

Minimal cron execution is covered with a detached harness that starts under
`env -i`, supplies an unusable inherited `PATH`, connects standard input to
`/dev/null`, and provides no terminal on any standard stream. It verifies the
human-readable, JSON, and NDJSON modes, deterministic environment values,
non-interactive `slackpkg` arguments, persistent logging, and owner-only work,
log, and lock files:

```bash
tests/reference/test-cron-minimal-environment.sh
```

This automated boundary is complete; the equivalent scenario on real
Slackware 15.0 and Slackware-current installations remains part of the
acceptance matrix below.

### Real-system acceptance execution

Real-system scenarios live under `tests/acceptance/reference/`. They execute
actual Slackware tools and must be run only on disposable VM snapshots or
otherwise recoverable test installations.

The first scenario covers a fully updated host with no package changes. It
requires an explicit `--execute-apply` acknowledgement, first proves that
`slackpkg check-updates` reports no updates, and then exercises the real apply
workflow with Flatpak, SBo, ELF, Cinnamon, and boot preparation disabled so the
case remains isolated. Expected structured check and apply outputs are stored
under `tests/fixtures/reference/acceptance/no-updates/`.

Run it separately on each mandatory target:

```bash
sudo bash tests/acceptance/reference/test-no-updates.sh \
    --target slackware-15.0 \
    --execute-apply

sudo bash tests/acceptance/reference/test-no-updates.sh \
    --target slackware-current \
    --execute-apply
```

A passing run must return stable code `0`; report `success=true`,
`partial=false`, `reboot=none`, and `boot_safe=true`; preserve an identical
installed-package database; and leave the observed initrd and GRUB
configuration unchanged. Each run produces a private evidence archive and a
SHA-256 sidecar below `/var/tmp/slack-update-acceptance/no-updates/` by default.
When invoked through `sudo`, both published files are assigned to the invoking
user with mode `0600`; the uncompressed evidence directory remains root-only.
Slackware 15.0 passed on 2026-07-28 with 1,594 unchanged package records and
archive SHA-256
`5a784cd6d830ac271cc3aad02ed89f2e00c2afd63c88f90aabb74b0a81b0b20b`.
Slackware-current passed on the same date with 2,035 unchanged package records
and archive SHA-256
`ba0c1264d57df5acf6bee843391113327736683ede36ec3d708d58ca174a2976`.
Sanitized acceptance records for both mandatory targets are stored alongside the
expected fixtures.
The scenario invokes the reference through `bash`, so extraction tools that lose
Unix executable bits do not prevent the test from running. Package-database
enumeration follows the command-line `/var/log/packages` compatibility symlink
used by modern `pkgtools`, while package-record symlinks inside that directory
remain excluded. See `tests/acceptance/reference/README.md` for the evidence
contract.

The second scenario stages a normal official-package update. It must begin with
a non-destructive preflight that asks `slackpkg` for the actual `install-new` and
`upgrade-all` candidate lists while answering no to installation, then proves
that package and boot state are unchanged:

```bash
sudo bash tests/acceptance/reference/test-normal-update.sh \
    --target slackware-current \
    --preflight
```

Review the resulting candidate files and evidence before using apply mode. A
real apply requires the exact local hostname, and kernel candidates require a
second explicit acknowledgement. Flatpak, SBo, ELF, and Cinnamon remain
disabled for isolation, while boot preparation stays in `auto` mode so kernel
changes must complete initrd and GRUB handling safely. Unattended package
operations disable slackpkg post-install processing with `-postinst=off`, keep
active configuration files, enumerate pending regular `/etc/*.new` files, and
report them for a later administrator-controlled `slackpkg new-config` review.

A Slackware-current preflight captured on 2026-08-03 is diagnostic only and
must not authorize apply. Its raw `slackpkg upgrade-all` log contained 56
package filenames, including `kernel-headers-6.18.41-x86-1.txz`, but the
normalized evidence retained only 55 because the exact Slackware architecture
tag `x86` was not recognized. Together with one `install-new` candidate, the
corrected reconstruction contains 57 packages, two configured kernel
candidates, and SHA-256
`d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1`.
The parser and portable SHA-256 sidecar are fixed, but a fresh preflight is
mandatory because Slackware-current metadata may have changed. The rejected
record is stored at
`tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260803-parser-diagnostic.json`.

The corrected rerun is accepted as non-destructive classification evidence. It
confirmed one `install-new`, 56 upgrades, 57 total candidates, two configured
kernel candidates, no configured critical candidates, and the same candidate
digest. Archive SHA-256
`33a0d6eb20dfc777c4c5f8a0172f8344aab03a20ffd130d0fe95753ffce57cbc`
verified after copying to `/home/promano`. Its sanitized record is
`tests/fixtures/reference/acceptance/normal-update/slackware-current-preflight-20260803-accepted.json`.
Apply remains unauthorized because the set changes the kernel.

Slackware-current kernel candidates now require an additional non-destructive
boot-layout discovery stage:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-boot-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1 \
    --confirm-target-kernel 6.18.41
```

The first run on `pcold-slack` proved the monolithic `kernel-generic` package
model and unchanged package/boot state, but it also exposed a valid boot layout
that the initial preflight did not recognize. The host boots GRUB through
`BOOT_IMAGE=/boot/vmlinuz-generic`; that symlink resolves to the package-owned
`/boot/vmlinuz-6.18.40`, while both `/etc/mkinitrd.conf` and `/boot/initrd.gz`
are intentionally absent. This is a coherent `direct-generic-no-initrd` mode,
not a failure. The rejected diagnostic archive has SHA-256
`8b7d495f8a1466ef308dcb8664e31df756940695b6ed345834fad4ab1f5f3727`.

The corrected stage accepts either a safe `mkinitrd-managed` layout or the
observed direct generic-kernel layout. The real-system rerun on 2026-08-03 passed
all 20 assertions, proved ownership of the running image and module tree,
confirmed `boot/vmlinuz-6.18.41` plus target modules in repository metadata,
validated the actual `BOOT_IMAGE` against the syntax-checked GRUB configuration,
and left package and boot state unchanged. Its archive SHA-256 is
`ed7462e70496cf38a52c211f3d5945438e5f1bad5b8d8eaa7b90079540381967`, and the
sanitized accepted record is
`tests/fixtures/reference/acceptance/kernel-boot/slackware-current-direct-generic-preflight-20260803-accepted.json`.
Discovery deliberately remains `apply_ready=false` and `apply_authorized=false`.

The reference boot module now implements the corresponding direct-update policy.
A validated `direct-generic-no-initrd` host suppresses initrd regeneration only
for that exact layout while retaining mandatory GRUB regeneration. After package
installation and before GRUB generation, the engine requires exactly one
post-update `kernel-generic` record, a package-owned
`/boot/vmlinuz-VERSION` selected by `/boot/vmlinuz-generic`, and the matching
`/lib/modules/VERSION` tree. The temporary GRUB configuration must pass
`grub-script-check` and reference the validated versioned kernel or generic
symlink before atomic replacement. Any missing symlink, module tree, ownership
record, or stale generated entry blocks GRUB and reports `boot_safe=false`.

This policy change is code-only and does not authorize package installation. A
later transaction preflight must inspect the exact downloaded
`kernel-generic-6.18.41-x86_64-1` archive and its install script, revalidate the
candidate digest, and exercise the staged GRUB plan before any accepted fixture
may set `apply_ready=true`.

The step 37 transaction preflight passed on `pcold-slack`. It verified the exact `kernel-generic-6.18.41-x86_64-1.txz` package with SHA-256 `b588e9e74258baaf2d5e05a1731981cb679f5665d50a3a91d9f02219c4a8024a`, 6,588 safe archive members, 5,490 target-module paths, the target versioned kernel, no embedded initrd, and unchanged package plus boot state. The accepted evidence archive has SHA-256 `d4f455dafb6783dc96e8cf45c45d00ef4e54d1e9b5dc2ae8e05b8db166b50888`.

Review of the copied `doinst.sh` showed that the versioned `vmlinuz-generic` transition is followed by a guarded `usr/sbin/geninitrd` invocation. The package script was never executed, but this conditional hook may create a versioned initrd, remove orphaned initrds, invoke custom hooks, and update GRUB according to the installed host policy. Therefore exact-package integrity is accepted while apply remains blocked.

The step 38 host-policy preflight passed on `pcold-slack` with 10 assertions and evidence SHA-256 `3b807d2d00fce2b9986308f5cd252d97b483d4b8f1a397fad7d6f047b20421fd`. It confirmed `AUTOGENERATE_INITRD=true`, effective generator `mkinitrd_command_generator.sh`, automatic GRUB update, and a `direct-to-generated-initrd` transition to `/boot/initrd-6.18.41.img`. It also identified two exact executable pre-install DKMS hooks, so package apply remains blocked.

The step 39 DKMS-hook preflight passed on `pcold-slack` with 10 assertions and evidence SHA-256 `95eec7f57d4ff9d3f254830428d5382a155f890b9e57553b71fbd4f661e30ebf`. DKMS 3.4.1 reported zero status rows; `/var/lib/dkms` and the running `updates/dkms` directory were empty or absent. Manual review confirmed that both exact hooks take their explicit no-registered-module branch and therefore do not invoke `dkms install`. The accepted record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260803-accepted.json`.

Run the step 40 command-output-only GenInitrd preflight on the same machine:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-command-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 d9199fcf6c5cd8c59b87b1bde9a955df2c55d0ac84f6dab37ed8e4c1830dcaf1 \
    --confirm-target-kernel 6.18.41
```

This stage invokes the installed `mkinitrd_command_generator.sh` only for the already installed `6.18.40` kernel and never uses `--run`. It parses exactly one inert `mkinitrd` command, stores the argument vector in private evidence, projects only the kernel and output arguments to `6.18.41` and `/boot/initrd-6.18.41.img`, and never executes either vector. It also revalidates the exact cached kernel archive and proves that package, boot, GenInitrd, and DKMS state stay unchanged. Its result always remains `apply_ready=false` and `apply_authorized=false` pending evidence review and a later post-install simulation design.

Step 41 passed on `pcold-slack` with 11 assertions and evidence SHA-256 `246a54dd81c1db6ce2e7d04cb5d6e4739249e4a2f0483edcb9c7a5f1e0e93ad3`. The accepted record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-grub-ownership-preflight-20260803-accepted.json`. It proved that only a same-directory atomic policy override can prevent package-owned `update-grub`, and that the original policy, package database, and boot state remained unchanged.

Step 42 implements that reviewed boundary in the reference engine without running a VM. For the exact `direct-generic-no-initrd` layout, the engine creates a root-owned same-directory backup, stages a policy whose only active assignment is `AUTO_UPDATE_GRUB=false`, rechecks the source fingerprint, and atomically activates it before package operations. It restores the original policy immediately afterward and again from the exit/signal cleanup path if necessary. Restoration refuses to overwrite concurrent changes, retains the backup on conflict, marks the Slackware operation failed, and reports all states in structured output. Other boot layouts remain no-ops. Step 43 supplies the post-package generated-initrd recognition. Step 44 accepted a fresh 69-candidate set whose target is `6.18.42`, invalidating all candidate-bound `6.18.41` records. The first step 45 restart was diagnostic: package-list metadata contained the exact target trio, but the local file inventory did not yet expose `boot/vmlinuz-6.18.42`. The corrected step 46 rerun passed 20 nested plus 6 outer assertions, accepted `target_image_metadata_state=deferred-to-exact-package-preflight`, preserved package and boot state, and produced accepted outer archive SHA-256 `77618b808093f3e5349f5a6e076a110b56876a7ed08878d89c71a78fc594de51`.

Step 47 accepted the restarted exact-package inspection for `6.18.42`. The real `pcold-slack` run passed 12 assertions, accepted package SHA-256 `e9e7a1c5c71c945ee99595868aa8fee8a644b56601ece0c3e5696d643fe84878`, inventoried 6,588 safe members and 5,490 target-module paths, proved `boot/vmlinuz-6.18.42` plus `/lib/modules/6.18.42`, found no embedded initrd, reviewed but did not execute the conditional `geninitrd` hook, preserved package plus boot state, and produced evidence SHA-256 `44c18026052a7d7b0d5e385258389f8bc73beefe9ac35c2a2777707df17c4f57`.

Step 48 accepted the restarted host-policy inspection for `6.18.42`. The real `pcold-slack` run passed all 10 assertions, confirmed `AUTOGENERATE_INITRD=true`, effective generator `mkinitrd_command_generator.sh`, automatic GRUB update, transition `direct-to-generated-initrd`, expected `/boot/initrd-6.18.42.img`, and the same two reviewed DKMS hooks. Package, boot, and policy state remained unchanged; archive SHA-256 `873c7779dcef6f16d72d809704ca732809e6d5db5b1668f6a4942662b97c54ca` was verified after copying to `/home/promano`. The accepted record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260804-accepted.json`.

Step 49 passed on `pcold-slack` with 10 assertions and evidence SHA-256 `c943b3c25703fc395cfba6708a9c6122b033f82876795053f39a6d8e61ff5074`. DKMS 3.4.1 again reported zero status rows, no `/var/lib/dkms` state, no running `updates/dkms` tree, and no target module tree. The exact `dkms-bcachefs` and `dkms-nvidia` hooks remain explicit no-ops for the reviewed host state. The accepted record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260804-accepted.json`.

Step 50 restarts the command-output-only GenInitrd preflight for `6.18.42`:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-command-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

This stage binds all six accepted records, invokes `mkinitrd_command_generator.sh` only for the installed `6.18.40` kernel without `--run`, parses one inert argument vector, projects only its kernel and output fields to `6.18.42` and `/boot/initrd-6.18.42.img`, and never executes either vector. Package, boot, GenInitrd, and DKMS state must remain unchanged, while `apply_ready=false` and `apply_authorized=false` remain mandatory.

The first real step-50 run passed 10 assertions and failed only the cached-package assertion. The package path existed and the projected 18-module command was safe, but the script compared the file with the stale literal SHA-256 from the earlier `6.18.41` chain. Diagnostic archive SHA-256 `8f3f32b17d735241caf7e22f2aa32b56d2d42590a46bb920979ed51e0ab6c3f6` is not accepted. Step 51 removes all package-digest literals from executable code and loads both filename and SHA-256 from the accepted exact-package record before the corrected rerun.

Step 43 implements post-package recognition without running a VM. When the pre-transaction layout is `direct-generic-no-initrd` and `AUTOGENERATE_INITRD=true`, GRUB regeneration is blocked unless the post-update snapshot contains exactly one safe `kernel-generic` version, `/boot/vmlinuz-generic` selects its package-owned versioned kernel, the matching module tree exists, `/boot/initrd-VERSION.img` is a non-empty root-owned regular file, and `/boot/initrd-generic.img` resolves exactly to it. Legacy `/boot/initrd.gz` and `/etc/mkinitrd.conf` must remain absent. The temporary GRUB configuration must reference both the validated kernel and the versioned or named initrd before atomic replacement. The synthetic fixture records no commands or mutations and does not authorize apply. Final candidate-set revalidation on Slackware-current remains mandatory.

Step 44 adds that final candidate-set revalidation as a dedicated real-system wrapper. It invokes `test-normal-update.sh` only with `--preflight`, embeds the resulting candidate evidence, compares its deterministic digest and exact package list with the accepted chain, and classifies unchanged, changed-kernel, changed-userspace, no-updates, incomplete-kernel, and ambiguous-kernel outcomes. An unchanged kernel set may proceed only to a separate readiness dry-run; any changed target invalidates all target-bound kernel, package, GenInitrd, DKMS, command, and GRUB-ownership evidence. The wrapper never invokes apply, package installation, initrd generation, or GRUB mutation and always reports `apply_ready=false` plus `apply_authorized=false`.

Slackware 15.0 passed the non-kernel branch of this scenario on 2026-08-01.
The reviewed preflight deferred `kernel-generic`, `kernel-huge`, and
`kernel-modules`, then authorized an exact 196-package candidate digest containing
12 `install-new` packages, 184 upgrades, five configured critical packages, and
no boot-kernel candidates. The real apply returned stable code `4`, installed all
12 new packages, changed all 184 upgrade candidates, moved the package database
from 1,554 to 1,566 records, left the observed initrd and GRUB state unchanged,
and reported 45 pending `.new` files through the hardened deferred policy. The
broad `kernel_changes` result was true because `kernel-firmware` and
`kernel-source` changed, while the explicit initrd and GRUB requirements remained
false. Sanitized preflight and apply records are stored under
`tests/fixtures/reference/acceptance/normal-update/`.

The three deferred Slackware 15.0 boot-kernel packages use a separate
non-destructive boot-path preflight before any apply is authorized:

```bash
sudo bash tests/acceptance/reference/test-kernel-boot-preflight.sh \
    --target slackware-15.0
```

This preflight identifies BIOS versus UEFI firmware, classifies probable LILO,
ELILO, or GRUB usage, inventories readable scalar settings from
`/etc/mkinitrd.conf` or records availability of Slackware's official command
generator, records installed and repository kernel package metadata, confirms
that `kernel-generic`, `kernel-huge`, and `kernel-modules` remain blacklisted,
and fingerprints relevant boot artifacts before and after inspection. It does
not modify Slackpkg configuration, packages, initrd images, or boot-loader
files. The current reference implements automatic boot preparation only for
mkinitrd plus GRUB; a LILO, ELILO, ambiguous, or unknown classification remains
blocked until a target-specific safe adapter or an explicit manual acceptance
procedure is designed.

Real Slackware 15.0 evidence collected on 2026-08-01 identified UEFI with ELILO,
confirmed that `/boot/initrd.gz` matches the active EFI copy, and found no
`/etc/mkinitrd.conf`. The initial discovery archive SHA-256 is
`78f4d60738fe08a5ce599458e7da8917402bb029a90b0f9ac449c6129b6746ab`.

A second non-destructive run captured one valid generator command for kernel
`5.15.19`, but also proved that the generic `/boot/vmlinuz` alias points to
`vmlinuz-huge-5.15.19` and does not match the ELILO kernel copy. Its reviewed
archive SHA-256 is
`b3a6d98c6163f66b34dd9e50b74ac6e158530f2e03d142c53b818bb7ac54ffd5`.
This is not evidence of a broken boot entry: ELILO commonly stores a copied
versioned kernel while Slackware's generic `/boot/vmlinuz` alias may target the
huge kernel. The preflight now inventories every top-level `/boot/vmlinuz*`
candidate, collapses aliases resolving to the same file, and requires exactly
one versioned source whose content matches the EFI image and whose filename
identifies the running kernel.

A third non-destructive run accepted the exact source mapping: the EFI kernel
matches `/boot/vmlinuz-generic-5.15.19`, the running kernel is the same release,
the initrd copies match, the generator proposed exactly one command, and all 20
assertions passed. The reviewed archive SHA-256 is
`0eb55c3bda5a4167f4ef9fc19aede6e2029985d5dd325416e78e00ba85d57480`.

Kernel apply remains blocked. The next stage resolves the exact common
repository candidate for `kernel-generic`, `kernel-huge`, and `kernel-modules`,
builds versioned EFI filenames, verifies conservative free space, and writes a
planned ELILO configuration without changing the active system:

```bash
sudo bash tests/acceptance/reference/test-elilo-kernel-transaction-preflight.sh \
    --target slackware-15.0
```

The planned activation boundary is an atomic replacement of `elilo.conf` only
after the new versioned kernel and initrd files have been generated, copied, and
verified. The existing ELILO binary, firmware entry, current kernel, current
initrd, and original configuration remain the rollback path. This preflight does
not authorize the transaction.

The first real transaction-preflight run on 2026-08-01 remained
non-destructive but exposed two compatibility defects in the harness. Slackpkg
retained complete `patches` records for both `5.15.208` and `5.15.209`; the
selector incorrectly required one historical candidate instead of choosing the
newest complete version. Slackware 15.0 `df` also rejects `-P` together with
`--output`. The corrected selector uses version ordering to choose `5.15.209`,
rejects duplicate records, and the free-space probe now uses portable `df -Pk`
output with explicit KiB-to-byte conversion. The diagnostic archive SHA-256 is
`3780c922fffab042ae265b5a54286d7ce22379f4774f174326cec81fed406259`;
packages, blacklist state, initrd, and ELILO files were unchanged. The corrected
real-system rerun then selected `5.15.209-1` from `patches`, produced candidate
digest `10ea616935d628a97ba2bc9cec0d5e57fdebeefe54d2768800ef3a30c3a4c5db`,
passed all 27 assertions, and changed no system state. Its accepted archive
SHA-256 is `d951cd9eb24b54b1b8c20262ac12c59b00a042c7426c883dd4af246076d482bb`.



The reviewed plan now has a separate, deliberately named apply stage:

```bash
sudo bash tests/acceptance/reference/test-elilo-kernel-transaction-apply.sh \
    --target slackware-15.0 \
    --execute-apply \
    --confirm-hostname vbox-slack15.vbox-slack15.org \
    --confirm-candidate-sha256 10ea616935d628a97ba2bc9cec0d5e57fdebeefe54d2768800ef3a30c3a4c5db \
    --confirm-target-kernel 5.15.209
```

This stage follows Slackware's keep-the-working-kernel safety rule: Slackpkg is
used only to download the exact reviewed packages, while `installpkg` installs
`kernel-generic`, `kernel-huge`, and `kernel-modules` alongside version
`5.15.19`. The original blacklist is restored before package installation
continues. The generated mkinitrd command is parsed into an argument vector and
never evaluated as shell text. New kernel and initrd files use versioned names
in both `/boot` and the EFI partition. The final `elilo.conf` explicitly selects
the new `vmlinuz` label as default and retains the current unversioned EFI files
under label `oldkernel`. Activation is a same-directory atomic replacement only
after all new artifacts pass byte-level verification. The EFI loader binary and
firmware boot variables are never changed. Package installation cannot be
rolled back automatically, so this command remains limited to the snapshotted
Slackware 15.0 VM until its evidence and reboot are accepted.

The first real apply attempt on 2026-08-01 stopped before package installation.
Slackpkg returned status `20` because the former single argument
`^kernel-(generic|huge|modules)$` was treated as one unmatched package pattern.
The blacklist was restored byte-for-byte, `installpkg` and `mkinitrd` were not
run, and ELILO remained inactive. The corrected stage calls `slackpkg download`
three times with the exact names `kernel-generic`, `kernel-huge`, and
`kernel-modules`, records each status, and still resolves only the exact approved
`5.15.209-x86_64-1` cache files. The diagnostic archive SHA-256 is
`e3a854a2ed5479e9906ff3dd72592bf39439e55e20d1cc992a42eadf05f14996`.

The corrected real transaction then passed all 31 apply assertions. It kept
`5.15.19` installed, installed `5.15.209`, generated and verified
`initrd-generic-5.15.209.gz`, atomically selected the versioned ELILO files,
and retained label `oldkernel`. The apply archive SHA-256 is
`93c58c1508085f3dffaa182eac52fb49c72e6222d75b49c79af4309713f0ac95`.
The subsequent real reboot ran kernel `5.15.209`; `/proc/cmdline` named the
versioned EFI kernel, and `elilo.conf` still contained the active `vmlinuz`
entry plus the `oldkernel` rollback entry. The ELILO kernel scenario is accepted. Phase 1 step 30 now defines the
retention policy and a non-destructive eligibility preflight. Its corrected
real-system baseline passed all 24 assertions on 2026-08-01, observed a distinct
later boot into `5.15.209`, and preserved package plus boot state; the reviewed
archive SHA-256 is
`5afedf07c964369e19ed7ba28f89f2c92caf50a1f46bba813f5652baedc7c3b4`.
Removal of the previous packages or rollback artifacts remains blocked until a
mature eligibility run is reviewed and a separate cleanup apply stage is
explicitly authorized.

The rollback policy requires both a minimum seven-day interval after the
accepted reboot review and one additional successful boot into `5.15.209`. The
accepted transaction reboot counts as the first of two required successful
boots. Run the new preflight without any cleanup option:

```bash
sudo bash tests/acceptance/reference/test-elilo-oldkernel-retention-preflight.sh \
    --target slackware-15.0
```

The preflight validates the exact active and rollback package records, captures
the current Linux boot ID and boot start time, verifies both ELILO entries and
their `/boot` plus EFI copies, inventories package-log paths shared by the old
and current kernel packages, and proves that package and boot state remain
unchanged. It follows the standard Slackware `/var/log/packages` compatibility
symlink only after resolving it to a readable canonical directory, records both
paths in the evidence, and never follows package-record symlinks inside the
database. Missing state captures fail closed and are never treated as unchanged.
It evaluates eligibility only after the final package and boot captures match
their initial state. It may report `cleanup_eligible=true` only after those
comparisons and both retention gates pass, but always records
`cleanup_authorized=false`. The accepted baseline correctly reported
`cleanup_eligible=false` because only 10,220 of the required 604,800 seconds had
elapsed. The later-boot requirement is already satisfied; the next eligibility
run must occur no earlier than `2026-08-08T19:51:00+02:00`. Evidence sidecars
now contain only the archive basename, so after both files are copied directly
to `/home/promano`, they can be verified there with `sha256sum -c`. The future
cleanup plan must revalidate and retain the exact active package archives,
remove only the three
old package records, reinstall the active package set to repair shared package
paths, verify the active boot chain, atomically remove `oldkernel`, and only then
delete unreferenced rollback files.


### Kernel cleanup plan contract

Phase 1 step 31 defines the cleanup transaction as a plan-only, boot-loader-neutral
contract. It does not change the retained ELILO VM, does not change the GRUB
development VM, and cannot authorize apply. Generate deterministic plans from the
included schema-1 fixtures with:

```bash
tools/reference/kernel-cleanup-plan-reference.sh \
    --input tests/fixtures/reference/kernel-cleanup/slackware-15.0-elilo-dual-kernel-design.json \
    --output /tmp/slack-update-elilo-cleanup-plan.json
```

The common plan requires the running kernel to equal the accepted active kernel,
exactly one active and one rollback package record for each of `kernel-generic`,
`kernel-huge`, and `kernel-modules`, a present module tree for both versions, and
one verified archive for every active package. The package transaction removes
only the exact rollback records and then reinstalls the exact active package set
before any boot-loader rollback reference can disappear. Kernel headers, kernel
source, and firmware packages are preserved.

ELILO and GRUB use different backend actions. ELILO must stage a configuration
without `oldkernel`, validate the versioned active entry, activate the staged file
atomically, and prove that legacy EFI files are no longer referenced before they
can be deleted. GRUB must never be edited manually: `grub-mkconfig` output belongs
in an owner-only same-directory temporary file, `grub-script-check` must accept it,
the regenerated configuration must retain active entries and omit rollback
entries, and replacement must be atomic.

The second Slackware 15.0 VM observed on 2026-08-03 is recorded as a development
baseline. It boots `5.15.209` through GRUB with
`BOOT_IMAGE=/boot/vmlinuz-huge-5.15.209`, has active generic, huge, and modules
records only, retains headers/source/firmware packages, and has no `5.15.19`
rollback records or entries. Its cleanup result is therefore deliberately
`not-applicable`, contains zero actions, and leaves packages plus GRUB unchanged.
The synthetic dual-kernel GRUB fixture exists only to validate backend planning;
it is not real-system acceptance evidence.

Every generated plan contains `apply_permitted=false`,
`cleanup_authorized=false`, and `requires_separate_apply_stage=true`. Mature
retention eligibility removes only the eligibility blocker; it never creates an
authorization.


### Kernel cleanup dry-run contract

Phase 1 step 32 adds a simulation-only executor on top of the step 31 plan. It
has no apply mode and requires the literal `--dry-run` option:

```bash
tools/reference/kernel-cleanup-dry-run-reference.sh \
    --dry-run \
    --plan /tmp/slack-update-elilo-cleanup-plan.json \
    --output /tmp/slack-update-elilo-cleanup-dry-run.json
```

An ineligible plan, including the accepted ELILO baseline before the seven-day
boundary, produces a blocked result with no simulated steps. An eligible plan
still remains blocked until it receives a separate schema-1 authorization bound
to the exact plan SHA-256, target, boot loader, active kernel, and rollback
kernel. That authorization is limited to `scope=dry-run-only`, must contain
`apply_authorized=false`, and cannot authorize a real cleanup.

With a matching synthetic authorization, the executor renders fourteen ordered
steps as data: inventory revalidation, archive verification, private state
capture, exact rollback-package removal, exact active-package reinstallation,
backend staging and atomic activation, active-chain verification, delayed removal
of only unreferenced rollback artifacts, final comparison, and private evidence
publication. ELILO exposes only its legacy EFI `vmlinuz` and `initrd.gz` copies as
future explicit deletion candidates. GRUB exposes no unowned rollback artifacts;
its package-owned old kernel files disappear through the package transaction and
its configuration is regenerated and validated before atomic replacement.

The simulator can inject a failure at any planned action and emits the recovery
sequence that a future apply implementation would need. Failures before package
removal discard only private temporary state; failures after removal require
reinstallation from verified active archives; failures at or after boot-loader
activation additionally require atomic configuration restoration; and failures
after rollback-artifact deletion require restoring those archived files before a
retry. These are plans only: every result records `commands_executed=[]`,
`mutations_performed=[]`, `apply_authorized=false`, and
`real-apply-stage-unavailable`.

The mature ELILO input and authorization policy fixtures are synthetic test data.
They do not replace the scheduled real retention preflight on
`2026-08-08T19:51:00+02:00` and do not authorize execution on either VM.

### Real-system acceptance matrix

- [x] Fully updated system with no available changes.
  - [x] Reproducible scenario, validators, and expected fixtures implemented.
  - [x] Slackware 15.0 evidence accepted on 2026-07-28: check and apply returned stable code `0`, 1,594 package records and observed boot state were unchanged, and the reviewed archive SHA-256 is `5a784cd6d830ac271cc3aad02ed89f2e00c2afd63c88f90aabb74b0a81b0b20b`.
  - [x] Slackware-current evidence accepted on 2026-07-28: check and apply returned stable code `0`, 2,035 package records and observed boot state were unchanged, and the reviewed archive SHA-256 is `ba0c1264d57df5acf6bee843391113327736683ede36ec3d708d58ca174a2976`.
- [ ] Normal Slackware package update.
  - [x] Non-destructive candidate preflight, physical-host safety gates, evidence packaging, and focused automated tests implemented.
  - [x] Slackware-current preflight evidence reviewed.
  - [x] Slackware-current ten-package transaction reviewed and accepted as package/boot evidence.
  - [ ] Revalidate the hardened deferred `.new` policy during the next Slackware-current update.
  - [x] Diagnose and fix the omitted `x86` `kernel-headers` candidate from the 2026-08-03 preflight.
  - [ ] Repeat the corrected Slackware-current preflight before any apply authorization.
  - [x] Slackware 15.0 preflight and real apply evidence accepted.
  - [x] Revalidate the hardened deferred `.new` policy on Slackware 15.0.
  - [x] Exercise the three deferred Slackware 15.0 boot-kernel packages in the dedicated kernel-update scenario.
  - [x] Implement the non-destructive firmware, boot-loader, mkinitrd, kernel-record, blacklist, and boot-artifact preflight.
  - [x] Review real Slackware 15.0 boot-path evidence and select the ELILO branch.
  - [x] Record and review the non-executed mkinitrd command-generator proposal for the running ELILO kernel.
  - [x] Identify and accept the unique versioned `/boot` generic kernel source copied into ELILO.
  - [x] Resolve and review the exact three-package repository candidate and atomic versioned ELILO transaction plan.
  - [x] Execute the gated ELILO transaction, review its evidence, and validate reboot into `5.15.209` with the `oldkernel` fallback retained.
  - [x] Define a seven-day, two-successful-boot retention policy and a non-destructive ELILO oldkernel eligibility preflight.
  - [x] Run and review the retention preflight while cleanup remains unauthorized.
  - [ ] Repeat the retention preflight no earlier than 2026-08-08 19:51 CEST and review mature eligibility evidence.
  - [x] Define and validate the boot-loader-neutral cleanup plan contract without authorizing apply.
  - [x] Implement and validate the simulation-only cleanup executor with plan-bound dry-run authorization and no apply mode.
  - [ ] Implement and explicitly authorize the separate cleanup apply only after mature eligibility evidence is accepted.
- [x] `install-new` introduces new packages.
- [x] Kernel package update.
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
- [x] Validate staged GRUB configuration before replacement.
- [x] Confirm interruption signals release locks and terminate execution.
- [x] Confirm errors produce non-zero exit codes.
- [x] Confirm cron execution works with a minimal environment.
- [ ] Execute and document the Phase 1 acceptance matrix on Slackware 15.0 and Slackware-current.
  - [x] Accept the fully updated no-updates scenario on Slackware 15.0.
  - [x] Accept the fully updated no-updates scenario on Slackware-current.
  - [x] Accept the non-destructive normal-update preflight on Slackware-current.
  - [x] Refresh and reclassify package metadata immediately before normal-update apply authorization.
  - [x] Require separate authorization for kernel and critical normal-update candidates.
  - [x] Require an exact reviewed candidate-set SHA-256 before normal-update apply.
  - [x] Accept the corrected 57-candidate Slackware-current preflight classification.
  - [x] Require a separate matching apply-ready boot-layout record for Slackware-current kernel candidates.
  - [x] Run the first non-destructive Slackware-current kernel boot-layout preflight and reject its initrd-only assumptions.
  - [x] Repeat and accept the corrected direct-generic-aware boot-layout preflight for `6.18.41`.
  - [x] Add reference-engine policy for direct generic kernel transitions without initrd.
  - [x] Add a non-installing exact Slackware-current kernel-package transaction preflight.
  - [x] Run and review the exact Slackware-current kernel package transaction evidence before apply readiness.
  - [x] Detect the package script's conditional `geninitrd` hook and require a host-policy preflight.
  - [x] Run and review the Slackware-current `geninitrd` policy preflight before transaction design.
  - [x] Run and review the discovered Slackware-current DKMS hooks and installed DKMS state.
  - [x] Run and review the command-output-only GenInitrd projection for the target kernel transition.
  - [x] Run and review the GenInitrd versus Slack-Update GRUB-ownership preflight.
  - [x] Implement transactional GenInitrd policy override and guaranteed restoration in the reference engine.
  - [x] Validate the post-package generated-initrd state contract.
  - [x] Run and accept the fresh Slackware-current candidate-chain preflight for the 69-candidate `6.18.42` set.
  - [x] Reject the first `6.18.42` chain restart because target file inventory was required before the exact-package stage.
  - [x] Repeat and accept the corrected target-bound boot restart and exact `kernel-generic-6.18.42` package evidence.
  - [x] Repeat and accept the GenInitrd policy evidence for `6.18.42`.
  - [x] Repeat and accept DKMS, command, and GRUB-ownership evidence for `6.18.42`.
  - [x] Run the final non-installing `6.18.42` readiness preflight; retain it as diagnostic because it exposed the pre-existing versioned initrd.
  - [x] Run the first corrected `geninitrd-managed-versioned-initrd` boot baseline and retain its restricted-IFS metadata failure as diagnostic.
  - [x] Repeat and accept the corrected metadata-safe `geninitrd-managed-versioned-initrd` boot baseline.
  - [x] Repeat and accept the corrected GenInitrd-aware kernel-chain restart.
  - [x] Rebuild and accept the exact package, policy, DKMS, command, and GRUB-ownership evidence for `6.18.42`.
  - [x] Run corrected readiness and retain the safe block caused by the 137-candidate userspace expansion.
  - [x] Classify and accept the 137-candidate userspace-only refresh.
  - [x] Review and accept the exact identities of the 68 added userspace packages for kernel-evidence rebind.
  - [x] Rebind the seven accepted kernel evidence records to the 137-candidate digest.
  - [ ] Inspect the exact 68 added userspace package archives without installation.
  - [ ] Review the captured userspace maintainer scripts and configuration effects.
  - [ ] Repeat transaction readiness against the rebound candidate digest.
  - [ ] Grant a separate explicit apply authorization only after accepted readiness evidence.
  - [x] Review and accept the ten-package Slackware-current transaction as package and boot evidence.
  - [ ] Revalidate the hardened deferred `.new` policy on the next Slackware-current update.
  - [x] Reject the 2026-08-03 Slackware-current diagnostic whose parser omitted the `x86` `kernel-headers` candidate.
  - [x] Repeat the corrected Slackware-current candidate preflight and review the complete 57-package set.
  - [x] Accept the Slackware 15.0 normal-update preflight and 196-package real apply.
  - [x] Revalidate the hardened deferred `.new` policy on Slackware 15.0.
  - [ ] Validate the deferred Slackware 15.0 boot-kernel packages in the dedicated kernel-update scenario.
    - [x] Add a non-destructive boot-path detection and evidence preflight.
    - [ ] Review the real loader and mkinitrd evidence before authorizing package changes.
- [ ] Freeze `reference-v1`.
- [ ] Begin the C architecture only after the reference gate is complete.


### Phase 1 step 52: restarted GenInitrd/GRUB ownership preflight

The corrected step-51 command preflight passed all 11 assertions on `pcold-slack`. It accepted archive SHA-256 `be239e39372ad807be01199051730dbaf2602b962ceebea68b864e5951c78682`, exact cached package SHA-256 `e9e7a1c5c71c945ee99595868aa8fee8a644b56601ece0c3e5696d643fe84878`, and the projected output `/boot/initrd-6.18.42.img`. No generated command, package operation, initrd generation, or GRUB update was executed.

Run the restarted ownership preflight on `pcold-slack`:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-grub-ownership-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

This stage binds all seven accepted records, proves that an environment-only override cannot suppress package-owned `update-grub`, and prepares only an evidence-local copy whose sole active change is `AUTO_UPDATE_GRUB=false`. The real run passed all 11 assertions, preserved all sensitive state, and produced verified archive SHA-256 `f906211517c8887e52b2842ff8756973bf9ef5fa4af378a6c830226befe1d522`. The result remains `apply_ready=false` and `apply_authorized=false`; the accepted record advances to the step-53 readiness review.


### Phase 1 step 53: final Slackware-current kernel transaction readiness preflight

Run this final non-installing review only after all `6.18.42` evidence records are accepted:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-transaction-readiness-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The wrapper binds the accepted normal-update, boot, chain-restart, exact-package, GenInitrd-policy, no-op DKMS, command, and GRUB-ownership records. It also binds the target-specific synthetic post-state contract and the exact reference-engine SHA-256. It then repeats the existing normal-update preflight, requires exact equality with all 69 reviewed candidates, verifies the cached `kernel-generic` package, direct-generic boot layout, active GenInitrd policy, reviewed hooks, zero-row DKMS state, generator and setup scripts, and syntax-valid active GRUB configuration.

A completely clean result may report `apply_ready=true`, but it always reports `apply_authorized=false`, executes no package transaction, and performs no initrd, DKMS, or GRUB mutation. Apply still requires a later explicit authorization and the normal-update apply path must refresh and compare candidates again. Copy the outer archive and portable sidecar directly to `/home/promano` and verify them there.


### Phase 1 step 54: corrected GenInitrd-managed boot baseline

The real step-53 readiness run preserved the system and revalidated all 69 candidates, but blocked readiness because the host already contains `/boot/initrd-generic.img -> initrd-6.18.40.img` and `/boot/initrd-6.18.40.img`. Those files date from 2026-07-28, before the reviewed 2026-08 evidence chain, and the active GRUB configuration was regenerated afterward. The earlier detector looked only for `/boot/initrd.gz`, so the accepted label `direct-generic-no-initrd` is revoked for this host.

Run the corrected boot preflight before rebuilding any target-bound evidence:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-boot-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

A valid result must classify `boot_mode=geninitrd-managed-versioned-initrd`, verify the exact named-link target and versioned initrd, and prove that one GRUB menuentry pairs `/boot/vmlinuz-generic` with `/boot/initrd-generic.img`. The preflight performs no package, initrd, DKMS, or GRUB mutation and must keep `apply_ready=false` and `apply_authorized=false`. Copy its archive and sidecar directly to `/home/promano` and verify them there. All step-46 through step-52 records remain historical until rebuilt from this corrected baseline.


The step-54 repository validation runs all 37 focused suites: 2,412 checks pass with zero failures. The main reference engine remains SHA-256 `0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6`.

### Phase 1 step 55: corrected GenInitrd metadata parser

The first corrected baseline run on `pcold-slack` preserved the live system and identified the correct `geninitrd-managed-versioned-initrd` layout, but one assertion failed with `line 309: [: : integer expected`. The script-wide `IFS` contains only newline and tab, while the safe-file helper attempted to split space-separated `stat` output. Consequently `uid` and `gid` were empty even though `/boot/initrd-6.18.40.img` is a safe root-owned regular file. Diagnostic archive SHA-256 `16ebd14b3dd3447c6663fb25796c603738ce58f99bff56334813f72d5b4fd2bb` is preserved and does not authorize apply.

Repeat the corrected non-destructive baseline:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-boot-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The helper now parses colon-delimited metadata with a local `IFS`, validates all fields before mode arithmetic, and still requires root ownership plus no group/world write bits. A valid result must report `boot-mode=geninitrd-managed-versioned-initrd`, `geninitrd-transition=true`, 20 passes, zero failures, and immutable `apply_ready=false` / `apply_authorized=false`. Copy the archive and sidecar directly to `/home/promano` and verify them there. The corrected real-system rerun is accepted with 20 passes, zero failures, archive SHA-256 `6429fd626973b0c3fc498642e1cd9230bc0eceb0291e232b515fef625467c6ac`, and immutable apply denial. The dependent evidence chain must now be rebuilt from this record.

The step-55 repository validation runs all 37 focused suites: 2,424 checks pass with zero failures. The current-kernel boot harness contributes 94 checks. The main reference engine remains SHA-256 `0dc4a4def9b063b9a598975f46e7458c5771eb8d8603f4fa8bbd9dfc07c4d4c6`.



### Phase 1 step 56: corrected GenInitrd kernel-chain restart

Run the restart wrapper only after accepting the step-55 baseline:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-chain-restart-preflight.sh \
    --target slackware-current
```

The wrapper binds the accepted 69-candidate refresh and normal-update records plus `slackware-current-kernel-boot-preflight-20260805-accepted.json`. It reruns only the non-destructive boot preflight and requires the same `geninitrd-managed-versioned-initrd` classification, `/boot/initrd-6.18.40.img` digest, target-image deferral, unchanged package database, and unchanged boot state. A clean result keeps `apply_ready=false` and `apply_authorized=false` and selects `current-kernel-package-preflight` as the next stage. Copy the final outer archive and portable sidecar directly to `/home/promano` and verify them there.

The step-56 repository validation executes all 37 suites: 2,432 checks pass with zero failures. The chain-restart harness contributes 58 checks.

### Phase 1 step 57: rebuilt exact kernel-package preflight

The corrected step-56 chain restart passed all 20 nested assertions and all 6 wrapper assertions. Its accepted outer archive SHA-256 is `e48c528aafd9daef64edae721ddc96c9b5c52daac1a6f563fe447d1a66e6996e`; the nested boot archive SHA-256 is `286035b2f88b3bd575a6731171180743d80b79f75c2ccbb138df647a6527fcda`.

Run the rebuilt exact-package preflight on `pcold-slack`:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-package-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

Before downloading anything, the preflight binds the corrected step-55 boot record and accepted step-56 restart record, then revalidates the live `vmlinuz-generic`, `initrd-generic.img`, versioned initrd SHA-256, GenInitrd symlink policy, active GRUB digest, and same-menuentry kernel/initrd pairing. It downloads or confirms only `kernel-generic-6.18.42-x86_64-1.txz`, inventories the archive, validates its conditional `geninitrd` hook without execution, and generates a GRUB configuration only inside the evidence directory. Expect 13 passes, zero failures, `apply_ready=false`, and `apply_authorized=false`. Copy the archive and sidecar directly to `/home/promano` with the printed command and verify them there.

The real step-57 run passed all 13 assertions. Its accepted archive SHA-256 is `9f702e85a8ff3eb6155b834ed11cfe494ec60f04082914d80bae2a13d02e016f`; the accepted package record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-package-preflight-20260805-accepted.json`.

### Phase 1 step 58: rebuilt GenInitrd policy preflight

Run only after accepting step 57:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-policy-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The rebuilt policy stage binds the corrected boot, chain-restart, and exact-package records. It revalidates the live `vmlinuz-generic`, `initrd-generic.img`, `/boot/initrd-6.18.40.img`, active GenInitrd scalar policy, and same-menuentry GRUB pairing before parsing the installed scripts. The enabled transaction is modeled as `versioned-to-versioned-initrd`, with expected output `/boot/initrd-6.18.42.img`, named symlink enabled, legacy `initrd.gz` disabled, and automatic GRUB update still active for the later ownership review. It inventories hooks but executes none. Expect 11 passes, zero failures, `apply_ready=false`, and `apply_authorized=false`; copy and verify the evidence directly in `/home/promano`.

The step-58 repository matrix executes all 37 suites: 2,465 checks pass with zero failures. Direct per-suite summation corrects the step-57 total to 2,451; the previously stated 2,395 omitted the valid 56-check direct-generic policy suite. The rebuilt GenInitrd policy harness contributes 61 checks.

The real step-58 run passed all 11 assertions and produced accepted archive SHA-256 `de4ad831efda30eaaa6a0ee8fc099815cf0bdb9882bded361942dc6719a88e80`. Its sanitized record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-policy-preflight-20260805-accepted.json`.

### Phase 1 step 59: rebuilt DKMS-hook preflight

Run only after accepting step 58:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-dkms-hook-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The rebuilt stage binds the accepted normal-update, corrected boot, corrected chain-restart, exact-package, and versioned GenInitrd policy records. Before examining hooks it revalidates the live `vmlinuz-generic`, `initrd-generic.img`, `/boot/initrd-6.18.40.img`, GenInitrd symlink policy, and same-menuentry GRUB pairing. It then verifies the exact `dkms-bcachefs` and `dkms-nvidia` hook hashes, ownership, permissions, syntax, and static command surfaces; runs only `dkms --version` and `dkms status`; and inventories DKMS sources, state, and module trees without following links. No hook, DKMS build/install action, package command, initrd generator, or GRUB command is executed. Expect 11 passes, zero failures, `apply_ready=false`, and `apply_authorized=false`. Copy the evidence archive and portable sidecar directly to `/home/promano` and verify them there.

The real step-59 run passed all 11 assertions and produced accepted archive SHA-256 `780c56432d7d1b1bd4014a56709d6693a7ac1bf1148a072fbf8d1cfceac1cd2f`. Its sanitized record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-dkms-hook-preflight-20260805-accepted.json`.

The step-59 repository matrix executes all 37 suites: 2,473 checks pass with zero failures. The rebuilt DKMS-hook harness contributes 59 checks.

### Phase 1 step 60: rebuilt GenInitrd command preflight

Run only after accepting step 59:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-command-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The rebuilt stage binds the accepted normal-update, corrected boot, chain-restart, exact-package, versioned-policy, and step-59 DKMS records. Before invoking the generator it revalidates the live `vmlinuz-generic`, `initrd-generic.img`, `/boot/initrd-6.18.40.img`, GenInitrd symlink policy, active GRUB digest, and same-menuentry kernel/initrd pairing. It confirms the exact cached target package, runs `mkinitrd_command_generator.sh` only in command-output mode for the installed kernel, parses exactly one inert `mkinitrd` vector, and projects that vector to `6.18.42` with output `/boot/initrd-6.18.42.img`. Neither the current nor projected command is executed. Expect 12 passes, zero failures, `transition=versioned-to-versioned-initrd`, `apply_ready=false`, and `apply_authorized=false`. Copy the archive and sidecar directly to `/home/promano` and verify them there. Do not advance to the GRUB-ownership preflight until this evidence is reviewed and accepted.

The real step-60 run passed all 12 assertions and produced accepted archive SHA-256 `754ebe19080417c9bcd79ba8ca586085c808e24d1d5120286fff19a09c2cf0f0`. The sanitized accepted record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-geninitrd-command-preflight-20260805-accepted.json`. Neither the current nor projected command was executed.

### Phase 1 step 61: rebuilt GenInitrd/GRUB ownership preflight

Run only after accepting step 60:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-grub-ownership-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The rebuilt stage binds all corrected records through the accepted step-60 command evidence. It revalidates the live generic kernel, named initrd, versioned initrd, scalar GenInitrd symlink policy, active GRUB digest, and same-menuentry kernel/initrd pairing before analyzing ownership. It proves that the active `AUTO_UPDATE_GRUB=true` assignment overrides an environment-only value, writes only an evidence-local copy with that single assignment changed to `false`, and emits a non-executing twelve-stage plan with five recovery boundaries in which Slack-Update exclusively owns validated atomic GRUB replacement. Expect 12 passes, zero failures, `transition=versioned-to-versioned-initrd`, `strategy=temporary-atomic-policy-override`, `environment-override-safe=false`, `apply-ready=false`, and `apply-authorized=false`. Copy the archive and sidecar directly to `/home/promano` and verify them there. Do not advance to readiness review until this evidence is accepted.

The first real step-61 run stopped after its first two passes because sensitive-state capture referenced undeclared `GENERATOR_SCRIPT` under `set -u`. The stop occurred before initial state capture, evidence publication, or any package, initrd, GenInitrd, DKMS, or GRUB operation. Step 62 corrects the reference to the declared `GENINITRD_SCRIPT` and adds a nounset execution test for the capture function.

### Phase 1 step 62: corrected GenInitrd/GRUB ownership preflight

Repeat exactly the same non-destructive command:

```bash
sudo bash tests/acceptance/reference/test-current-geninitrd-grub-ownership-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

The corrected real run completed all 12 assertions, preserved the `geninitrd-managed-versioned-initrd` baseline, emitted the evidence-local twelve-stage ownership plan, and produced verified archive SHA-256 `53acb06384b4a8fbea1feceb73e6aa2381c43f5702a41ce990d0f515d04588fe`. The accepted result is `transition=versioned-to-versioned-initrd`, `strategy=temporary-atomic-policy-override`, `apply-ready=false`, and `apply-authorized=false`.

### Phase 1 step 63: rebuilt final transaction readiness preflight

Run only after accepting the corrected step-62 ownership evidence:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-transaction-readiness-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9 \
    --confirm-target-kernel 6.18.42
```

This stage binds the accepted normal-update, boot, chain-restart, exact-package, policy, DKMS, command, and GRUB-ownership records. It also binds the corrected synthetic post-state contract whose pre-transaction mode is `geninitrd-managed-versioned-initrd` and whose target state requires `/boot/initrd-6.18.42.img` plus `initrd-generic.img -> initrd-6.18.42.img`.

The wrapper refreshes Slackpkg metadata through the existing non-installing normal-update preflight and requires the same 69 candidates and candidate-set SHA-256. It then revalidates the exact cached package, the current kernel and initrd hashes, the GenInitrd scalar policy, both reviewed no-op DKMS hooks, empty DKMS state, and the active same-menuentry GRUB kernel/initrd pairing. It executes no package transaction, `mkinitrd`, `geninitrd`, DKMS build, `update-grub`, or `grub-mkconfig` command.

The real step-63 run stopped safely at candidate revalidation: Slackpkg reported 137 candidates with digest `27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926`, while the accepted chain was bound to 69 candidates. The wrapper still verified the nested archive, exact package cache, corrected GenInitrd boot layout, no-op DKMS state, and GRUB ownership boundary, and it preserved all live state. The result was `readiness=blocked`, `apply-ready=false`, and `apply-authorized=false`. Outer archive SHA-256 `1726766092ce5b4b334ba314566ea290d85aa7aa9a563a753cb7262d96a7a69e` and nested archive SHA-256 `cd9ab4ec8c9485e5c196c83d34c0077d0b14651b89afe86a24d7c205a188fbfc` were verified in `/home/promano`.

The step-63 repository inventory contains 37 suites and 2,521 checks with zero failures. The rebuilt readiness harness contributes 64 checks. Static validation covers 56 Bash scripts and 53 JSON files.



### Phase 1 step 64: classify the 137-candidate userspace expansion

The step-63 readiness run is a verified safe stop. Slackpkg still exposes the exact reviewed `kernel-generic`, `kernel-headers`, and `kernel-source` packages for `6.18.42`, but the candidate set expanded from 69 to 137 with 68 additions and no removals. The additions are userspace packages, mostly the Plasma 6.7.4 stack. The previous candidate-bound chain is not directly reusable until that expansion is reviewed and explicitly rebound.

Run only the corrected non-installing refresh wrapper:

```bash
sudo bash tests/acceptance/reference/test-current-candidate-chain-refresh-preflight.sh \
    --target slackware-current
```

The expected classification, while the repository remains unchanged, is `changed-userspace-set` with target `6.18.42`, `kernel_transaction_changed=false`, `strict_candidate_superset=true`, `added_candidate_count=68`, `removed_candidate_count=0`, `next_stage=review-fresh-userspace-candidates`, `apply_ready=false`, and `apply_authorized=false`. The wrapper refreshes metadata only through the existing normal-update preflight, verifies critical-candidate accounting, preserves package and boot state, and publishes one outer archive with a portable sidecar. Copy and verify both files directly in `/home/promano`. Do not run readiness or apply until the fresh userspace evidence is reviewed.

The step-64 repository matrix contains 37 suites and 2,545 checks. The candidate-chain harness contributes 79 checks and the readiness harness contributes 71 checks.

### Phase 1 step 65: userspace candidate review for kernel-evidence rebind

Run only after accepting the step-64 candidate refresh:

```bash
sudo bash tests/acceptance/reference/test-current-userspace-candidate-review-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 \
    --confirm-target-kernel 6.18.42
```

The review binds the accepted 137-candidate refresh and a checked-in exact policy for the 68 additions. It requires a strict superset of the accepted 69-candidate transaction, no removals, no critical candidates, no added `install-new` entries, and the unchanged `kernel-generic`, `kernel-headers`, and `kernel-source` files for `6.18.42`. The added identities must be exactly 61 Plasma 6.7.4 packages, six supporting userspace packages, and `breeze-grub-6.7.4-x86_64-1.txz` as the only boot-adjacent theme package.

This is deliberately not a package-payload or apply-safety review. A clean result may report `kernel_evidence_rebind_ready=true` and route to `current-kernel-evidence-rebind-preflight`, while `package_payloads_inspected=false`, `userspace_apply_review_complete=false`, `apply_ready=false`, and `apply_authorized=false` remain mandatory. The script executes no package transaction, maintainer script, initrd generator, DKMS action, or GRUB update. Copy the final archive and sidecar directly to `/home/promano` and verify them there.

The real step-65 run passed all 11 assertions and the nested six-check normal-update preflight. Outer archive SHA-256 `7d22806577aa4432436d8760e86fdeec5af25a420fe05b28a5150c2c97617037` and nested archive SHA-256 `11812569b828f31874c01e1c7bcacef069c36fe8391c938ae545495d5f9cd1fc` were copied and verified in `/home/promano`. The accepted record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-userspace-candidate-review-20260805-accepted.json`.

The step-65 repository inventory contains 38 suites and 2,591 checks with zero failures. The userspace candidate review harness contributes 46 checks.

### Phase 1 step 66: explicit kernel-evidence rebind to the 137-candidate digest

Run only after accepting the step-65 userspace review:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-evidence-rebind-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 \
    --confirm-target-kernel 6.18.42
```

The rebind stage validates the accepted userspace review, the explicit rebind policy, and the seven accepted kernel evidence records covering boot layout, chain restart, exact package, GenInitrd policy, no-op DKMS hooks, projected command, and GRUB ownership. It refreshes Slackpkg metadata through the existing normal-update preflight and requires the exact 137-candidate list, unchanged `kernel-generic`, `kernel-headers`, and `kernel-source` identities, the exact cached kernel package, the accepted versioned initrd and policy hashes, empty DKMS state, and a valid same-menuentry GRUB kernel/initrd pair.

A clean result records `kernel_evidence_rebound=true` and changes only the candidate binding from `918ded076efb3ff0131b296ceae8854765dd5e92cc433542c498276f9aeba3f9` to `27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926`. It must still report `package_payloads_inspected=false`, `userspace_apply_review_complete=false`, `userspace_payload_review_required=true`, `apply_ready=false`, and `apply_authorized=false`, and route only to `current-userspace-payload-review-preflight`. Copy the final archive and sidecar directly to `/home/promano` and verify them there.

The step-66 repository inventory contains 39 suites and 2,653 checks with zero failures. The kernel evidence rebind harness contributes 62 checks.

The real step-66 run passed all 12 outer assertions plus the nested six-pass normal-update preflight. Outer archive SHA-256 `38a79511d6c17686b3a2b3e8c349c2c199264849ca1fd0222135d0ab1f00b482` and nested archive SHA-256 `24e8e2146029e9f4aadcf189acee5ababec7ecb89395074517363489aa83556e` were copied and verified in `/home/promano`. The accepted record is `tests/fixtures/reference/acceptance/kernel-boot/slackware-current-kernel-evidence-rebind-20260805-accepted.json`.

### Phase 1 step 67: diagnostic userspace payload archive review

The first real payload review used the exact accepted step-66 boundary and correctly remained non-installing, but it stopped after 13 passes and two failures. The exact `breeze-grub-6.7.4-x86_64-1.txz` archive begins with the explicit directory member `boot`, while the reviewed policy incorrectly described the theme as `usr/share/grub/themes/breeze/`. The generic `/boot` prohibition therefore rejected the package before its actual confined theme subtree could be reviewed.

The rejected outer archive SHA-256 is `b61a17d2fb296d8493bab82dfcbb2bdf4bbebcb0b5168f6d61895674c31b45e8`; the nested normal-update archive SHA-256 is `bae2e427e5c789d3f51141cb8281e0493754f1721b6ba0ecff3af52ca219fe0e`. Both were copied and verified in `/home/promano`. The package database, active kernel, initrd, GenInitrd, DKMS, and GRUB state remained unchanged, and no package transaction or maintainer script ran. The diagnostic record is `tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-payload-review-20260805-boot-prefix-diagnostic.json`.

### Phase 1 step 68: corrected exact Breeze GRUB payload boundary

Repeat the same non-installing review only from the unchanged accepted state:

```bash
sudo bash tests/acceptance/reference/test-current-userspace-payload-review-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 \
    --confirm-target-kernel 6.18.42
```

The corrected policy binds the sole boot-adjacent exception to the exact filename `breeze-grub-6.7.4-x86_64-1.txz`, SHA-256 `66209816c42b2363f7a2ca7d1a739dc393c101c752709e7291f1f97b6466008a`, and size `1448432`. Only the explicit ancestor directories `boot`, `boot/grub`, and `boot/grub/themes`, plus the exact `boot/grub/themes/breeze/` root and subtree, are permitted in that archive. Every other `/boot` member, every sibling GRUB theme, every GRUB path in another package, and the stale `usr/share/grub/` layout still fail closed.

The preflight reruns the exact 137-candidate normal-update preflight, resolves all 68 added packages in live Slackpkg metadata, downloads only exact missing archives into the normal Slackpkg cache, and inspects each `.txz` without installing or extracting it into the host. It rejects unsafe or duplicate members, device and FIFO entries, escaping links, setuid/setgid modes, kernel/initrd/pkgtools payloads, and unreviewed GRUB files. Package SHA-256 values, complete member inventories, ELF/config/service counts, and every `install/doinst.sh` are preserved inside the evidence; maintainer scripts receive syntax checks only and are never executed.

The accepted real result reports `package_payloads_inspected=true`, `payload_path_review_complete=true`, and `next_stage=current-userspace-maintainer-script-review-preflight`. It inspected 68 archives and captured 37 syntax-valid but unexecuted scripts while retaining `maintainer_scripts_review_complete=false`, `userspace_apply_review_complete=false`, `apply_ready=false`, and `apply_authorized=false`. Outer evidence SHA-256 `763313828522239da29e3fee5fc2582c14aabb8aa7b5c64fe9e0392ebc2c71ac` and nested evidence SHA-256 `818c40e9cf5e776607d110881d876eaf75937292fc4cfd1814a243b0979ece90` were verified in `/home/promano`.

The step-68 repository inventory contains 40 suites and 2,718 checks with zero failures. The userspace payload review harness contributes 65 checks.

### Phase 1 step 69: accepted maintainer-script review

The real Slackware-current run passed all 15 assertions and statically classified all 37 exact `install/doinst.sh` files without executing them. The accepted boundary contains 1,159 immediately paired remove-plus-symlink replacements, two exact `.new` promotions, five exact cache refreshes, and one package-specific non-persistent `TERM` signal to `kscreenlocker_greet`.

Outer archive SHA-256 `62f87bde4c4b1d49ff6c02476ce4a61af6420fa0798cd13ee9b6f83536762062`, nested payload archive SHA-256 `9bb11f5feec1c4b9be9b38d384717da30c05265b83fa852e5e71bf6d28ea4634`, and nested normal-update archive SHA-256 `98a82f0af75db3019e851ddf8026b5c300839b91abbc19c6db770f359857bcb5` were copied and verified in `/home/promano`. Package, kernel, initrd, GenInitrd, DKMS, and GRUB state remained unchanged. The accepted record is `tests/fixtures/reference/acceptance/normal-update/slackware-current-userspace-maintainer-script-review-20260805-accepted.json`.

### Phase 1 step 70: configuration and service payload review

Run only from the unchanged accepted step-69 state:

```bash
sudo bash tests/acceptance/reference/test-current-userspace-configuration-service-review-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 \
    --confirm-target-kernel 6.18.42
```

The preflight reruns the maintainer-script review without installing packages or executing payload files. Its policy binds the exact 90-path boundary and the SHA-256 plus size of all 19 contributing `.txz` archives: 46 configuration paths containing 21 regular files, and 44 service paths containing 27 regular files.

Configuration classification covers nine XDG autostart desktop entries, three browser native-messaging manifests, two inert shell helpers checked only with `sh -n`, one PAM `.new` file, one XDG menu XML file, one PNG asset, two bounded INI-style files, one OpenSSL `.new` file, and one stunnel sample. Service classification permits only 26 files below `usr/lib/systemd/user/` and one preset below `usr/lib/systemd/user-preset/`. System units, `rc.d` scripts, privileged directives, shell interpreters or control syntax in unit commands, wildcard presets, unknown files, hash drift, package execution, and service control fail closed.

The accepted real result reported 15 passes and zero failures with `configuration_path_count=46`, `configuration_file_count=21`, `service_path_count=44`, `service_file_count=27`, `systemd_user_service_count=26`, `systemd_user_preset_count=1`, `systemd_system_service_count=0`, and `rc_script_count=0`. Outer evidence SHA-256 `b2e6379879297e81bc2da8fa6aa58ccdaf6c904fe3018691ba6d78f463077140` and the nested maintainer, payload, and normal-update SHA-256 values `5aed2e4895cde3611c41d8ba13f83add40c5e3c24db55429cc9a17a07b6b5d2f`, `b0493bec292d964158b7c7c46596ce269db8b05aaf446d47571097609487739f`, and `7290a56c9e45ea27226accfa19b175bfbb414c91bf7f9b7951ed3eb375948a96` were verified in `/home/promano`. The result retains `elf_runtime_review_complete=false`, `userspace_apply_review_complete=false`, `apply_ready=false`, and `apply_authorized=false`.

### Slackware-current ELF runtime review preflight (step 71)

After accepting the step-70 configuration/service evidence, run:

```bash
sudo bash tests/acceptance/reference/test-current-userspace-elf-runtime-review-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 \
    --confirm-target-kernel 6.18.42
```

The wrapper reruns the entire non-installing configuration/service chain and verifies the nested archive. Its policy binds all 68 exact archive SHA-256 values and sizes, the exact 61 packages that contain ELF data, each package-specific ELF count, and the total of 722 objects. Members are streamed one at a time into an owner-only temporary file and inspected with `readelf`; no object is launched and no `ldd`, loader tracing, or package installation is permitted.

Every object must remain `ELF64`, little-endian, and `Advanced Micro Devices X86-64`. Program interpreters are limited to `/lib64/ld-linux-x86-64.so.2`; runtime search paths must resolve beneath `/lib`, `/lib64`, `/usr/lib`, or `/usr/lib64`. The resolver reads `ldconfig -p` without updating it, excludes host libraries owned by packages that the pending transaction will replace, indexes reviewed transaction `SONAME` and shared-object basename providers, and requires every `DT_NEEDED` edge to resolve. `TEXTREL`, executable stacks, writable-executable load segments, slash-containing dependency names, unsafe runtime paths, unresolved dependencies, package drift, payload execution, service control, and boot changes fail closed.

The accepted real run reported 15 passes and zero failures with `elf=722`, `packages=61`, `dynamic=566`, `executable=156`, `needed=14639`, `unresolved=0`, and `unsafe=0`. Outer evidence SHA-256 `b4803f5ef86d5383bc191f7087795b8ecb757bc1aad8bb3a42f4c021c4a1a562` and nested configuration/service SHA-256 `fa6867beb3a59500c5c52d09a9dddcc0ed93662ded96d68d2d69d94f3e345d63` were verified in `/home/promano`. The result retains `userspace_apply_review_complete=false`, `next_stage=current-userspace-apply-review-preflight`, `apply_ready=false`, and `apply_authorized=false`.

The focused step-71 harness contains 56 checks. The complete step-71 inventory contains 43 suites and 2,906 checks with zero failures.

### Slackware-current userspace apply review diagnostic (step 72)

The first real step-72 run preserved the exact 137-package plan and completed the embedded ELF/runtime review successfully, but the outer result was rejected with 13 passes and one failure. The child ELF review reported 722 objects, 14,639 resolved dependency edges, zero unresolved edges, and zero unsafe objects. The separate normal-update preflight and the static application contract also passed.

The sole failure was nested evidence composition. The parent supplied `--output-dir .../nested/elf-review`, then expected `nested/elf-review.tar.gz` and its sidecar to exist beside that directory. The child correctly populated the explicit output directory and separately published its canonical archive under `/var/tmp/slack-update-acceptance/current-userspace-elf-runtime-review-preflight/`; it does not create an adjacent archive for a caller-supplied output directory. Therefore the parent looked for an archive pair that had never been produced.

The rejected outer archive SHA-256 is `bec1280dde4d51aa8db99698cd4d92df2270e1f318774ea215a8e02269249168`. The child-reported canonical ELF archive SHA-256 is `83a6c3eaf5956413eac97eec23439965486e292b709acbf63727416f1f59fabb`, and the nested normal-update archive SHA-256 is `7faaec43c20170508c3d04effeb90e556eeb19b8aec7da5091bc6a3e1742d538`. The outer archive and sidecar were verified in `/home/promano`. Package, kernel, initrd, GenInitrd, DKMS, and GRUB state remained unchanged; the diagnostic does not complete userspace apply review or permit readiness.

### Corrected Slackware-current userspace apply review preflight (step 73)

Repeat the same non-installing command with the corrected repository:

```bash
sudo bash tests/acceptance/reference/test-current-userspace-apply-review-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 \
    --confirm-target-kernel 6.18.42
```

The parent now removes any stale adjacent archive pair, creates a fresh owner-only `nested/elf-review.tar.gz` directly from the exact explicit ELF output directory, writes a portable basename-only SHA-256 sidecar, and verifies the pair before accepting the nested boundary. The archive remains inside the final apply-review evidence and therefore preserves the complete child chain without relying on the child's separately published canonical archive.

All other restrictions are unchanged. The wrapper repeats the complete non-installing ELF/runtime review and a separate normal-update preflight, reconstructs the exact disjoint union of 69 baseline plus 68 reviewed additions, and checks one `install-new`, 136 `upgrade-all`, the three-package `6.18.42` kernel transaction, zero critical candidates, the exact Slackpkg contract, deferred post-install handling, GenInitrd policy restoration, exclusive GRUB ownership, 12 transaction steps, and five recovery boundaries. It does not execute normal-update apply, packages, scripts, initrd generation, DKMS, or GRUB changes.

The corrected real run passed all 15 assertions and accepted the exact transaction. Outer archive SHA-256 `bf627728dcf330b1d22b885466c9f538bc28743ace83af30958ae4555c2a5522`, nested ELF archive SHA-256 `32653f141fb895166c8b422b4e80e0e7dd53c157d809f5085b10388e20706b36`, and nested normal-update archive SHA-256 `5ce4fdc0c4870402890683114b1d2ac30e1a3e3a1a671a7b969a0f022655147b` were verified. The result reported `candidates=137`, `baseline=69`, `additions=68`, `install-new=1`, `upgrade-all=136`, `kernel-transaction=3`, `critical=0`, `userspace-apply-review-complete=true`, `next-stage=current-kernel-transaction-readiness-preflight`, `apply-ready=false`, and `apply-authorized=false`. Package, kernel, initrd, GenInitrd, DKMS, and GRUB state remained unchanged.

The focused step-73 harness contains 76 checks. The complete step-73 inventory contains 44 suites and 2,982 checks with zero failures.

### Rebound Slackware-current kernel transaction readiness preflight (step 74)

Run the final non-installing readiness review only against the accepted 137-candidate digest and target kernel:

```bash
sudo bash tests/acceptance/reference/test-current-kernel-transaction-readiness-preflight.sh \
    --target slackware-current \
    --confirm-candidates-sha256 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 \
    --confirm-target-kernel 6.18.42
```

The rebuilt boundary binds ten accepted records: the original immutable 69-candidate kernel chain, the explicit 137-candidate rebind, and the accepted userspace application review. It then performs a fresh normal-update preflight and requires the exact 137 reviewed candidates, one `install-new`, 136 `upgrade-all`, the unchanged kernel companions, and zero critical candidates. It also verifies exactly 69 cached package archives: all 68 reviewed userspace additions by filename, size, and SHA-256 plus the exact `kernel-generic-6.18.42` archive.

Live readiness checks still require the exact running generic kernel, named and versioned initrd layout, GenInitrd scalar policy, generator and setup hashes, empty DKMS state, active GRUB digest, same-menuentry kernel/initrd pairing, and exclusive Slack-Update GRUB ownership. The wrapper refreshes metadata and probes candidates only; it does not install packages, execute maintainer scripts, generate initrds, build DKMS modules, or change GRUB.

A clean run is expected to report 10 passes, zero failures, `packages=137`, `reviewed-cache=69`, `readiness=apply-ready`, `pause-safe=false`, `apply-ready=true`, `apply-authorized=false`, and `next-stage=normal-update-apply-authorization-review`. **This is not yet a safe pause point.** Slackware-current metadata must be revalidated again at the actual application boundary, so a repository publication after readiness can still invalidate the reviewed transaction. Continue directly to the separate authorization and apply sequence; pause only when a later accepted stage explicitly reports `pause_safe=true`.

The focused step-74 harness contains 92 checks. The complete prepared step-74 inventory contains 44 suites and 3,003 checks with zero failures. Static validation covers 70 shell scripts and 71 JSON files.

### Phase 1 step 74: accepted rebound transaction readiness

The real Slackware-current run passed all 10 assertions and again refreshed package metadata before comparing the exact 137 candidates. It reported running kernel `6.18.40`, target `6.18.42`, 69 reviewed cached package archives, `readiness=apply-ready`, `apply_ready=true`, `pause_safe=false`, and `apply_authorized=false`. No package, initrd, GenInitrd, DKMS, or GRUB action ran.

The verified outer archive SHA-256 is `d49af0c2f95f6ceaaa6f4073a5567b914f53ee9605724f78fea4a30afc463783`; the nested normal-update archive SHA-256 is `be24bafd8d1340ee781a6994835e64298413076e5a1ff9821a8cee3de6a54631`. The outer archive and sidecar were copied and verified directly in `/home/promano`. This boundary is accepted but is not a safe pause, because the package transaction is still pending.

### Phase 1 steps 75-76: corrected explicitly authorized Slackware-current application

This is the first command in the current chain that performs real package changes:

```bash
sudo bash tests/acceptance/reference/test-current-normal-update-authorized-apply.sh \
    --target slackware-current \
    --execute-authorized-apply \
    --confirm-hostname pcold-slack \
    --confirm-hostname-fqdn pcold-slack.pcold-slack.org \
    --confirm-candidates-sha256 27eb06d282b4279f90f422235363c36897ff45f334607c00287384b848a8d926 \
    --confirm-target-kernel 6.18.42 \
    --confirm-readiness-sha256 d49af0c2f95f6ceaaa6f4073a5567b914f53ee9605724f78fea4a30afc463783 \
    --confirm-authorization-sha256 71e24850bd05106eafad2ffcf95d83d8e3a2991e365e696632777c780f14cc1a
```

The rejected step-75 run stopped before package execution because `hostname` returned the FQDN `pcold-slack.pcold-slack.org` while the command confirmed the short name `pcold-slack`; the same comparison was duplicated inside boot-state validation. Archive SHA-256 `909b7866a06c1f5d0cd53193af5b8e9c6f4d6ac4145f12491bc0265c9ca849b2` was verified in `/home/promano`, and package plus boot-sensitive snapshots remained identical. The corrected wrapper validates `hostname -s` and `hostname -f` independently, then validates the accepted readiness record, exact authorization policy and scope, repository script hashes, and complete live 6.18.40 boot baseline. It invokes `test-normal-update.sh --execute-apply` with the verified FQDN. That child refreshes Slackpkg metadata and reconstructs the candidate set again immediately before package installation. Any new, removed, or replaced candidate changes the digest and blocks before the reference apply workflow is called.

The reviewed transaction authorizes kernel packages but does not authorize critical packages. Slackpkg post-install interaction remains disabled and `.new` files remain evidence only. A successful result must use stable exit code 5, report a complete non-partial boot-safe apply, restore `/etc/default/geninitrd` byte-for-byte, install `/boot/vmlinuz-6.18.42`, `/lib/modules/6.18.42`, and `/boot/initrd-6.18.42.img`, retarget the generic kernel and initrd links, atomically replace GRUB with a configuration containing the target kernel/initrd pair, and preserve the 6.18.40 kernel, initrd, and modules as rollback artifacts.

Only that complete state reports `transaction_status=applied-and-boot-prepared`, `apply_authorized=true`, `pause_safe=true`, and `next_stage=current-kernel-post-apply-verification`. Once accepted, later Slackware-current publications no longer invalidate this completed transaction. A changed repository before application or any partial/failed apply retains `pause_safe=false` and routes to candidate refresh or manual recovery rather than claiming a safe pause.

The corrected step-76 harness contains 81 checks. The complete step-76 inventory contains 45 suites and 3,086 checks with zero failures. Static validation covers 72 shell scripts and 74 JSON files.
