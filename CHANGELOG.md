# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project intends to follow [Semantic Versioning](https://semver.org/) once public interfaces begin to stabilize.

## [Unreleased]

### Added

- Added a C-oriented `.gitignore` covering prospective Meson and CMake build output, compiler artifacts, test output, and common editor files.
- Added `CONTRIBUTING.md` with the English-language policy, phase-gate rules, reference-script validation requirements, and commit-message convention.
- Added the GNU General Public License version 3, with the project designated as `GPL-3.0-or-later` in the README.
- Added this changelog using the Keep a Changelog structure.

### Changed

- Relocated the existing shell implementation to `tools/reference/slack-update-reference.sh` without changing its contents.
- Updated the roadmap to reflect the repository work completed in Phase 0.

### Development context

- Current roadmap phase: **Phase 0 — Create the repository and preserve the reference implementation**.
- Phase 0 file preparation is complete; the remaining manual gate is to commit this state and create the `planning-v1` tag.
- No Phase 1 behavior has been implemented.
- The next development task after the planning tag is the first Phase 1 refactor: rename `sbo-auto` paths and identifiers to `slack-update` where appropriate, without changing validated behavior.
- The reference script has not yet been validated against the Phase 1 acceptance matrix on a real Slackware-current installation.
