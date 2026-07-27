# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project intends to follow [Semantic Versioning](https://semver.org/) once public interfaces begin to stabilize.

## [Unreleased]

### Added

- Added `--json` as an output modifier for check, apply, and dry-run operations. JSON mode reserves standard output for one provisional structured result and routes human-readable progress to standard error and the normal log.
- Added provisional schema version 0 fields for operation status, partial results, reboot and boot safety, timestamps, log path, per-module results, warnings, errors, and the current non-stable process exit code.
- Added `--check` as a non-destructive Slackware repository update check using `slackpkg check-updates`.
- Added `--apply` as an explicit selector for the existing update workflow.
- Added `--dry-run` to inspect the current host state and print the complete apply sequence, conditional triggers, current SBo queues, ABI rebuild candidates, ELF findings, optional-component availability, and boot preparation actions without executing update, synchronization, build, installation, initrd, or bootloader commands.
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
- Relocated the existing shell implementation to `tools/reference/slack-update-reference.sh` without changing its contents.
- Updated the roadmap to reflect the repository work completed in Phase 0.

### Development context

- Current roadmap phase: **Phase 1 — Stabilize and validate the shell reference**.
- Phase 0 is complete, committed as `3064cfa`, tagged as `planning-v1`, and published to GitHub.
- The first seven Phase 1 refactoring and interface tasks are complete: runtime identifiers use `slack-update`, the script is split into named functions, basic argument parsing is available, `--check` is non-destructive, `--apply` explicitly selects the existing update workflow, `--dry-run` prints the complete operation plan without applying changes, and `--json` emits the final provisional structured result.
- The script currently contains 52 named functions.
- Running without an operation still selects apply for backward compatibility with the original reference behavior.
- Dry-run uses `slackpkg check-updates` as its only Slackware command and otherwise performs local state inspection. It does not refresh package metadata, so exact changed package names and package-derived ABI or kernel triggers remain conditional until apply compares its before and after snapshots.
- Dry-run requires root in the current reference implementation because it shares the existing instance lock and system log. Its queue, package-candidate, and ELF scratch files are isolated under a temporary directory and removed at exit.
- Machine-readable progress events, configuration, optional-module activation modes, and stable exit codes have not been implemented yet.
- The next roadmap task is to evaluate and, if practical, add a machine-readable progress/event mode without beginning configuration work.
- `--dry-run` was tested with mocked repository states, current SBo queues, installed SBo packages, optional tools, an unavailable ELF backend, and a failed Slackware probe. Only `slackpkg check-updates` was invoked; mocked mutating commands were not executed.
- `--check`, `--apply`, and `--dry-run` were regression-tested against the previous delivery under deterministic mocked environments. Their human-readable output and command behavior remained unchanged.
- JSON output was parsed successfully for all three operations. A failed check produces valid JSON and a non-zero current exit code; failures detected inside the legacy apply workflow are represented as `success: false` and `partial: true` while stable exit-code propagation remains pending.
- Standard output contains only the JSON document in JSON mode; the banner, progress, summaries, and external command output are routed to standard error and the normal log.
- The reference script has not yet been validated against the Phase 1 acceptance matrix on a real Slackware-current installation.
