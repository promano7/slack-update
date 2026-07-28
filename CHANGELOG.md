# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project intends to follow [Semantic Versioning](https://semver.org/) once public interfaces begin to stabilize.

## [Unreleased]

### Added

- Added `tests/reference/test-sbo-target-selection.sh` with focused coverage for active queue records, build-option syntax, recursive references, deselected records, unsafe names, C-locale normalization, filesystem-order independence, exact installed SBo detection, broken-object ownership, atomic failure behavior, and final target submission.
- Added reusable SBo target-selection helpers for queue records, installed SBo packages, and deterministic target-set merging.
- Added `tests/reference/test-partial-slackware-update.sh` with focused coverage for failures in `slackpkg update`, `install-new`, and `upgrade-all`, post-failure snapshot capture, blocked module state, event suppression, provisional JSON reporting, and the successful continuation path.
- Added validated package snapshot capture with canonical normalization, deterministic ordering, duplicate rejection, record counts, and atomic replacement.
- Added `tests/reference/test-package-snapshots.sh` with focused coverage for valid, empty, missing, malformed, unsorted, duplicate, and non-canonical snapshots, plus apply-workflow guards.
- Added a reusable Slackware package-record parser that extracts name, version, architecture, and build from the rightmost fields used by `pkgtools`.
- Added `tests/reference/test-package-name-parsing.sh` and representative Slackware 15.0, Slackware-current, patched-package, multi-hyphen, plus-sign, and SBo fixture records.
- Added stable process exit codes `0` through `8`, including dedicated statuses for partial updates, unsafe boot preparation, successful reboot guidance, concurrent execution, invalid input, and unavailable privilege.
- Added stable exit-code descriptions to human-readable summaries and final JSON results.
- Added `enabled`, `disabled`, and `auto` activation modes for the optional Flatpak, SBo, ELF, Cinnamon, and boot modules.
- Added explicit requirement and applicability probes for every optional module, with activation state and reason reporting in human-readable, JSON, and event output.
- Added schema-1 compatibility defaults so configurations created before module modes were introduced continue to load with omitted modes interpreted as `auto`.
- Added `data/config/slack-update.conf` as the schema-versioned system configuration for the shell reference.
- Added a strict, non-evaluating INI-style parser that rejects unknown sections and keys, duplicates, missing values, invalid booleans, unsafe paths and tokens, and unsupported schema versions.
- Added Slackware 15.0 and Slackware-current as explicit, mandatory compatibility targets in the roadmap and contribution policy.
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

- SBo target selection now ignores comments, recursive queue references, and deselected records, extracts package names independently from build options, rejects unsafe names, and produces a C-locale sorted unique target set independent of queue-file enumeration order.
- ABI rebuild candidates, broken-object SBo owners, and the final submitted target set now share the same canonical selection and merge rules.
- Invalid SBo target selection now fails the SBo module, is exposed in provisional JSON, and blocks queue submission to `sbopkg`.
- Apply now stops after the validated post-update snapshot when any Slackware package operation fails, preventing Flatpak, package-change analysis, SBo, ELF, Cinnamon, initrd, and GRUB work from running against a partial Slackware state.
- Partial Slackware updates now mark every secondary module as `blocked`, include a stable blocking reason in summaries and provisional JSON, and emit no secondary-module start events.
- Package snapshots now fail closed when the package database cannot be enumerated or validated instead of silently creating incomplete state with `|| true`.
- Apply now stops before invoking `slackpkg` when the baseline snapshot is invalid and stops snapshot-dependent follow-up work when the post-update snapshot is invalid.
- Apply summaries and provisional JSON results now report snapshot validity, package counts, and validation errors for the before and after states.
- Replaced prefix-based package snapshot matching with literal parsed package-name comparison, preventing collisions such as `openssl` versus `openssl-solibs`.
- Replaced `rev | cut` SBo-name extraction and arbitrary tag filtering with parsed build-suffix checks for dry-run candidates, ABI rebuild targets, and broken-object ownership.
- Cinnamon package detection now compares the parsed package name exactly instead of relying on a filename glob.
- The reference script can now be sourced by regression tests without invoking `main()`; direct execution remains unchanged.
- Final JSON results now set `exit_code_stable` to `true`, include `exit_code_meaning`, and preserve `success=true` for successful reboot-recommended (`4`) and reboot-required (`5`) outcomes.
- The final `operation_completed` NDJSON event now carries the stable process exit code; intermediate action events continue to expose raw external-command statuses.
- Invalid arguments and configuration now return `7`, missing privilege returns `8`, and a concurrent instance returns `6` before workflow execution begins.
- Apply-result precedence is now unsafe boot (`3`), partial or verification failure (`2`), reboot required (`5`), reboot recommended (`4`), then success without reboot (`0`).
- Kernel headers changes alone no longer produce a reboot-required result; code `5` is tied to kernel image or module changes that schedule boot preparation.
- Optional modules now execute only when permitted by their configured activation mode.
- `enabled` reports missing module requirements as errors, `disabled` bypasses probing and execution, and `auto` treats unavailable or irrelevant optional software as non-fatal.
- Cinnamon graphical ABI triggers are ignored when the Cinnamon module is disabled or not applicable.
- Boot auto mode independently selects validated initrd and GRUB preparation paths after kernel changes; disabled mode suppresses both actions, while enabled mode retains strict failure reporting.
- Provisional JSON results now include each optional module's configured mode, activation state, reason, and operation-specific final state.
- Moved runtime paths, log retention, package groups, SBo and boot paths, Cinnamon repository settings, ELF scan roots, and the Slackware `install-new` and `upgrade-all` decisions out of the script and into the configuration file.
- Kept executable command names and argument structures fixed in the reference script so configuration values cannot introduce arbitrary shell execution.
- Added the effective configuration path to human-readable summaries and provisional final JSON results.
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
- The first fifteen Phase 1 refactoring, interface, parsing, and safety tasks are complete: runtime identifiers use `slack-update`, the script is split into named functions, argument parsing is available, `--check`, `--apply`, and `--dry-run` are implemented, `--json` emits a final structured result, `--events` streams machine-readable progress, operational settings are loaded from a validated configuration file, optional modules implement `enabled`, `disabled`, and `auto`, and process exit codes `0` through `8` are stable.
- The script currently contains 103 named functions.
- Running without an operation still selects apply for backward compatibility with the original reference behavior.
- `--json` and `--events` both retain provisional schema version `0`; their complete schemas are not stable APIs yet. The final process exit code is stable: `--json` marks it with `exit_code_stable=true`, and the final `operation_completed` event uses the same code. Intermediate event exit codes remain raw external-command statuses.
- Machine-readable modes reserve standard output. Human-readable progress and external-command output are written to standard error and the normal log.
- `--json` and `--events` are mutually exclusive. The current event types are `operation_started`, `module_started`, `action_started`, `action_completed`, `module_completed`, `warning`, `error`, and `operation_completed`.
- Dry-run uses `slackpkg check-updates` as its only Slackware command and otherwise performs local state inspection. It does not refresh package metadata, so exact changed package names and package-derived ABI or kernel triggers remain conditional until apply compares its before and after snapshots.
- Dry-run requires root in the current reference implementation because it shares the existing instance lock and system log. Its queue, package-candidate, and ELF scratch files are isolated under a temporary directory and removed at exit.
- Configuration schema version `1` is implemented for the shell reference. Optional-module activation modes and stable process exit codes are implemented.
- The system configuration path is `/etc/slack-update/slack-update.conf`; the source-tree fallback is `data/config/slack-update.conf`, and `SLACK_UPDATE_CONFIG` may select an absolute test fixture.
- Exact Slackware package-name parsing is validated with 71 focused checks.
- Package snapshots before and after updates are validated with 33 focused checks. Partial Slackware update handling is validated with 66 focused checks across each `slackpkg` operation, blocked module states, event suppression, provisional JSON, and the successful continuation path. Deterministic SBo target selection is validated with 47 focused checks. The next development task is to preserve dependency order in generated SBo queues without combining custom-option or personal-queue preservation work into the same step.
- Package-name parsing tests cover path and archive normalization, right-to-left field extraction, malformed records, literal snapshot matching, prefix collisions, plus signs, multi-hyphen names, patched builds, and exact `_SBo` build suffixes.
- Package snapshot tests cover canonical normalization, deterministic C-locale ordering, duplicate rejection, atomic replacement, missing and empty package databases, malformed and non-canonical records, stale snapshot removal, record counts, and workflow guards before and after Slackware operations.
- Partial-update tests confirm that a non-zero status from `update`, `install-new`, or `upgrade-all` still permits final snapshot capture but blocks every secondary module, suppresses their start events, reports `blocked` states in provisional JSON, and leaves the successful path unchanged.
- SBo target-selection tests cover queue options, comments, recursive references, deselected entries, unsafe names, duplicate removal, C-locale ordering, directory-layout independence, exact `_SBo` ownership, installed-package deduplication, deterministic union, and the final `sbopkg -b -B` submission file.
- Stable exit-code tests cover all values `0` through `8`, successful non-zero reboot outcomes, check failure, partial update failure, failed initrd preparation, invalid input, invalid configuration, privilege denial, lock contention, kernel headers without reboot, final JSON metadata, and the final NDJSON event.
- Module-mode tests cover all modules disabled, all requirements available in auto mode, invalid mode values, enabled modules with missing requirements, non-fatal auto unavailability, kernel changes with boot auto and boot enabled, and schema-1 configurations without explicit mode keys.
- Disabled modules were verified not to invoke Flatpak, SBo, ELF, Cinnamon, initrd, or GRUB commands in the deterministic mock environment.
- JSON results were parsed for apply and dry-run activation scenarios. NDJSON events were parsed, checked for contiguous sequence numbers and required first/final event types, and verified to expose disabled module states.
- Syntax validation passed with `bash -n`; the executable mode remains `0755`, no C source files were added, and no trailing whitespace was detected. ShellCheck was not installed in the validation environment.
- The reference script has not yet been validated against the Phase 1 acceptance matrix on real Slackware 15.0 or Slackware-current installations.
