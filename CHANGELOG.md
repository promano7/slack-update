# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project intends to follow [Semantic Versioning](https://semver.org/) once public interfaces begin to stabilize.

## [Unreleased]

### Added

- Added `--check` as a non-destructive Slackware repository check using `slackpkg check-updates`; it reports whether repository updates are available without invoking package installation or optional-component update actions.
- Added a C-oriented `.gitignore` covering prospective Meson and CMake build output, compiler artifacts, test output, and common editor files.
- Added `CONTRIBUTING.md` with the English-language policy, phase-gate rules, reference-script validation requirements, and commit-message convention.
- Added the GNU General Public License version 3, with the project designated as `GPL-3.0-or-later` in the README.
- Added this changelog using the Keep a Changelog structure.

### Changed

- Renamed the reference script installation target, lock file, work directory, log directory, and runtime identity from `sbo-auto` to `slack-update`, without changing the update workflow.
- Split the linear reference workflow into 24 clearly named functions, including the `main()` coordinator, while preserving command order and observable behavior.
- Added two command-line interface functions for `-h` and `--help`, explicit rejection of unknown options and unexpected positional arguments.
- Added explicit workflow dispatch between the legacy no-argument apply path and `--check`; the script now contains 30 named functions.
- Relocated the existing shell implementation to `tools/reference/slack-update-reference.sh` without changing its contents.
- Updated the roadmap to reflect the repository work completed in Phase 0.

### Development context

- Current roadmap phase: **Phase 1 — Stabilize and validate the shell reference**.
- Phase 0 is complete, committed as `3064cfa`, tagged as `planning-v1`, and published to GitHub.
- The first four Phase 1 refactoring and interface tasks are complete: runtime identifiers use `slack-update`, the script is function-based, basic command-line parsing is available, and `--check` performs a non-destructive Slackware repository check.
- `--apply`, `--dry-run`, JSON output, configuration model, optional-module check behavior, and stable exit-code work have not been implemented yet.
- The no-argument invocation still runs the legacy apply workflow to preserve reference behavior until the dedicated `--apply` roadmap step.
- `--check` currently requires root because the reference script still uses the shared system lock, work directory, and log directory; privilege separation is not part of this step.
- The next development task is to implement `--apply` as the explicit approved-change operation without adding dry-run or JSON behavior.
- The function-only refactor was checked with `bash -n`, a non-root invocation comparison, and two mocked root execution scenarios; output and exit behavior matched the previous script.
- The argument parser was checked with help, unknown-option, positional-argument, and `--` cases. Help and parse errors occur before privilege checks, and a mocked no-argument execution remained byte-for-byte identical to the previous version.
- The `--check` path was validated with mocked `slackpkg` results for no updates (`0`), updates available (`100`), and command failure; destructive and optional-component commands were not invoked.
- The reference script has not yet been validated against the Phase 1 acceptance matrix on a real Slackware-current installation.
