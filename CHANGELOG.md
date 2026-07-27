# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project intends to follow [Semantic Versioning](https://semver.org/) once public interfaces begin to stabilize.

## [Unreleased]

### Added

- Added `--check` as a non-destructive Slackware repository update check using `slackpkg check-updates`.
- Added `--apply` as an explicit selector for the existing update workflow.
- Added a C-oriented `.gitignore` covering prospective Meson and CMake build output, compiler artifacts, test output, and common editor files.
- Added `CONTRIBUTING.md` with the English-language policy, phase-gate rules, reference-script validation requirements, and commit-message convention.
- Added the GNU General Public License version 3, with the project designated as `GPL-3.0-or-later` in the README.
- Added this changelog using the Keep a Changelog structure.

### Changed

- Renamed the reference script installation target, lock file, work directory, log directory, and runtime identity from `sbo-auto` to `slack-update`, without changing the update workflow.
- Split the linear reference workflow into 24 clearly named functions, including the `main()` coordinator, while preserving command order and observable behavior.
- Added two command-line interface functions for `-h` and `--help`, explicit rejection of unknown options and unexpected positional arguments, and no operational mode changes; the script then contained 26 named functions.
- Added mutually exclusive operation parsing for `--check` and `--apply`; running without an operation remains a compatibility alias for apply.
- Relocated the existing shell implementation to `tools/reference/slack-update-reference.sh` without changing its contents.
- Updated the roadmap to reflect the repository work completed in Phase 0.

### Development context

- Current roadmap phase: **Phase 1 — Stabilize and validate the shell reference**.
- Phase 0 is complete, committed as `3064cfa`, tagged as `planning-v1`, and published to GitHub.
- The first five Phase 1 refactoring and interface tasks are complete: runtime identifiers use `slack-update`, the script is split into named functions, basic argument parsing is available, `--check` is non-destructive, and `--apply` explicitly selects the existing update workflow.
- The script currently contains 30 named functions.
- Running without an operation still selects apply for backward compatibility with the original reference behavior.
- `--dry-run`, JSON output, machine-readable progress, configuration, optional-module activation modes, and stable exit codes have not been implemented yet.
- The next development task is to implement `--dry-run` as a complete non-modifying plan, without adding JSON output or later configuration behavior.
- `--check` was tested with mocked `slackpkg` exit codes `0`, `100`, and a generic failure; only `slackpkg check-updates` was invoked.
- `--apply` was tested against the no-argument compatibility path under a mocked root environment; output, command sequence, and exit status were identical. Conflicting operation selectors are rejected before privilege checks.
- The reference script has not yet been validated against the Phase 1 acceptance matrix on a real Slackware-current installation.
