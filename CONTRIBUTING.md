# Contributing to Slack-Update

Thank you for your interest in Slack-Update. The project is currently preserving and validating its shell reference implementation before any C port begins.

## Development phase gate

The roadmap in `README.md` is authoritative.

- Do not add C implementation code until the Phase 1 reference acceptance gate is complete.
- Keep the reference script under `tools/reference/slack-update-reference.sh` as the executable specification.
- During Phase 0, changes to the reference script are not allowed.
- During Phase 1, behavioral changes must be covered by an acceptance scenario, expected output, and expected exit code.
- Do not mix work from later roadmap phases into an earlier phase.

## Compatibility policy

Slackware 15.0 and Slackware-current are both mandatory targets. Changes to the
reference implementation, future C code, packaging, or documentation must not
assume that behavior observed only on one target is valid on the other. Record
target-specific requirements and provide detection or a safe fallback where the
two systems differ.

## Language policy

Use English for:

- source-code identifiers;
- source-code comments;
- commit messages;
- documentation;
- developer-facing logs.

Keep user-facing strings suitable for later translation.

## Stable exit-code policy

Process exit codes `0` through `8` are a stable compatibility surface. Changes must
preserve their documented meanings and precedence. Codes `4` and `5` are successful
results with reboot guidance and must not be collapsed into a generic failure.
Intermediate event exit codes may represent raw external-command statuses, but the
final process status and final operation event must use the stable Slack-Update codes.
Any incompatible change requires explicit roadmap discussion and documentation before
implementation.

## Commit messages

Use the following format when a scope improves clarity:

```text
<type>(<scope>): <imperative summary>
```

Common types are `build`, `docs`, `feat`, `fix`, `refactor`, `test`, `chore`, `ci`, and `security`.

Examples:

```text
docs: complete the initial repository structure
refactor(reference): split the update workflow into functions
test(reference): add the no-updates acceptance fixture
```

Commit subjects must:

- use the imperative mood;
- remain concise;
- not end with a period;
- describe one focused change.

Use the commit body to explain non-obvious decisions, compatibility changes, or safety implications.

## Reference-script changes

Before submitting a change to the reference script:

1. Run `bash -n tools/reference/slack-update-reference.sh`.
2. Run `tests/reference/test-package-name-parsing.sh` when package records, package ownership, or SBo detection are affected.
3. Run `tests/reference/test-package-snapshots.sh` when package snapshot capture, validation, or comparison is affected.
4. Run `tests/reference/test-partial-slackware-update.sh` when Slackware failure handling or secondary-module sequencing is affected.
5. Run `tests/reference/test-sbo-target-selection.sh` when SBo queue parsing, target discovery, ABI rebuild candidates, broken-object ownership, or deterministic target-set merging is affected.
6. Run `tests/reference/test-sbo-dependency-order.sh` when generated queue constraints, dependency ordering, final ordered merging, or SBo queue submission is affected.
7. Run `tests/reference/test-sbo-options.sh` when queue build options, persistent overrides, option conflict handling, or final option-preserving submission is affected.
8. Run `tests/reference/test-sbo-personal-queue-protection.sh` when sbopkg system/local queue-directory resolution, private `sqg` configuration wrappers, queue workspaces, symlink handling, invocation isolation, or cleanup is affected.
9. Run `tests/reference/test-elf-static-inspection.sh` when ELF candidate filtering, `readelf` parsing, loader-cache handling, broken-object verification, or the non-execution boundary is affected.
10. Run `tests/reference/test-elf-architecture-resolution.sh` when ELF identity extraction, cache record structure, class/data/machine compatibility, multilib behavior, or architecture-aware verification is affected.
11. Run `tests/reference/test-initrd-installed-kernel.sh` when `mkinitrd.conf` parsing, installed kernel resolution, module-tree validation, initrd output selection, or boot safety reporting is affected.
12. Confirm that destructive commands are not exercised outside an isolated Slackware test system.
13. Record the relevant acceptance scenario.
14. Preserve deterministic output and exit-code behavior.
15. Exercise `enabled`, `disabled`, and `auto` when changing optional-module behavior.
16. Ensure every new or modified comment is written in English.

Never run the apply workflow on a production machine merely to validate a contribution.

## Pull requests

A pull request should include:

- the roadmap item addressed;
- the reason for the change;
- the validation performed;
- any remaining risks or follow-up work.

Keep unrelated changes in separate pull requests and commits.
