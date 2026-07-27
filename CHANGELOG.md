# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project intends to follow [Semantic Versioning](https://semver.org/) once public interfaces begin to stabilize.

## [Unreleased]

### Added

- Added `--check` as a non-destructive Slackware repository update check using `slackpkg check-updates`.
- Added `--apply` as an explicit selector for the existing update workflow.
- Added `--dry-run` to inspect the current host state and print the complete apply sequence, conditional triggers, current SBo queues, ABI rebuild candidates, ELF findings, optional-component availability, and boot preparation actions without executing update, synchronization, build, installation, initrd, or bootloader commands.
- Added `--json` for one provisional structured result document on standard output.
- Added `--events` for provisional newline-delimited JSON progress events covering operation, module, action, warning, error, and completion states.
- Added a C-oriented `.gitignore` covering prospective Meson and CMake build output, compiler artifacts, test output, and common editor files.
- Added `CONTRIBUTING.md` with the English-language policy, phase-gate rules, reference-script validation requirements, and commit-message convention.
- Added the GNU General Public License version 3, with the project designated as `GPL-3.0-or-later` in the README.
- Added this changelog using the Keep a Changelog structure.

### Changed

- Renamed the reference script installation target, lock file, work directory, log directory, and runtime identity from `sbo-auto` to `slack-update`, without changing the update workflow.
- Split the linear reference workflow into 24 clearly named functions, including the `main()` coordinator, while preserving command order and observable behavior.
- Added two command-line interface functions for `-h` and `--help`, explicit rejection of unknown options and unexpected positional arguments, and no operational mode changes; the script then contained 26 named functions.
- Added mutually exclusive operation parsing for `--check`, `--apply`, and `--dry-run`; running without an operation remains a compatibility alias for apply.
- Added an isolated temporary workspace for dry-run queue and ELF inspection data so planning does not overwrite the persistent reference state under `/var/lib/slack-update`; normal locking and logging remain enabled.
- Reserved standard output for machine-readable data when either `--json` or `--events` is selected, while human-readable progress continues through standard error and the normal log.
- Made `--json` and `--events` mutually exclusive so each output stream remains unambiguous and directly parseable.
- Instrumented the existing check, dry-run, and apply coordinators with provisional operation, module, and action events without changing their human-readable execution order.
- Relocated the existing shell implementation to `tools/reference/slack-update-reference.sh` without changing its contents.
- Updated the roadmap to reflect the repository work completed in Phase 0.

### Development context

- Current roadmap phase: **Phase 1 — Stabilize and validate the shell reference**.
- Phase 0 is complete, committed as `3064cfa`, tagged as `planning-v1`, and published to GitHub.
- The first eight Phase 1 refactoring and interface tasks are complete: runtime identifiers use `slack-update`, the script is split into named functions, argument parsing is available, `--check`, `--apply`, and `--dry-run` are implemented, `--json` emits a final structured result, and `--events` streams machine-readable progress.
- The script currently contains 59 named functions.
- Running without an operation still selects apply for backward compatibility with the original reference behavior.
- `--json` and `--events` both use provisional schema version `0`; neither is a stable API yet. `--json` emits one document, while `--events` emits one JSON object per line with sequence, UTC timestamp, operation, event type, module, action, state, message, and optional exit code.
- Machine-readable modes reserve standard output. Human-readable progress and external-command output are written to standard error and the normal log.
- `--json` and `--events` are mutually exclusive. The current event types are `operation_started`, `module_started`, `action_started`, `action_completed`, `module_completed`, `warning`, `error`, and `operation_completed`.
- Dry-run uses `slackpkg check-updates` as its only Slackware command and otherwise performs local state inspection. It does not refresh package metadata, so exact changed package names and package-derived ABI or kernel triggers remain conditional until apply compares its before and after snapshots.
- Dry-run requires root in the current reference implementation because it shares the existing instance lock and system log. Its queue, package-candidate, and ELF scratch files are isolated under a temporary directory and removed at exit.
- Configuration, optional-module activation modes, and stable exit codes have not been implemented yet.
- The next development task is to move hard-coded reference behavior into a configuration file without implementing later optional-module activation modes in the same step.
- Human-readable `--check`, `--dry-run`, `--apply`, and no-argument execution were regression-tested against the previous delivery under a deterministic mocked environment; output and command order remained unchanged.
- JSON output was revalidated for all three operations. NDJSON events were parsed for all operations, checked for contiguous sequence numbers and required first/final event types, and tested with a failed Slackware check. The `--json`/`--events` conflict is rejected before runtime setup.
- The reference script has not yet been validated against the Phase 1 acceptance matrix on a real Slackware-current installation.
