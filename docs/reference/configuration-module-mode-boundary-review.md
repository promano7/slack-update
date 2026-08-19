# Phase 1 optional-module mode boundary review

Step 121 opens the fresh Phase 1 configuration boundary required by the accepted
step-120 compatibility checkpoint. It does not extend the closed step-117–120
review lineage as an authorization chain; it uses step 120 only as the immutable
starting checkpoint for a new review.

## Purpose

The optional-module activation modes already exist in the shell reference. This
step does not introduce or change them. It inventories and names their existing
contract before any later refactor, migration, or runtime change is considered.

The reviewed mode values are:

- `enabled` — requirements are probed strictly; when the module is applicable it
  is attempted, and missing mandatory requirements are an error.
- `disabled` — the module is intentionally bypassed; its requirements are not a
  reason to fail the operation and the module must not run.
- `auto` — availability and applicability are detected; the module runs only
  when the existing conditions are satisfied, while absent or irrelevant
  optional software remains non-fatal.

The shipped/default value remains `auto` for all five reviewed optional modules.

## Reviewed module surface

| Module | Runtime configuration variable | Configuration key | Default |
|---|---|---|---|
| Flatpak | `CONFIG_FLATPAK_MODE` | `flatpak.mode` | `auto` |
| SBo | `CONFIG_SBO_MODE` | `sbo.mode` | `auto` |
| ELF | `CONFIG_ELF_MODE` | `elf.mode` | `auto` |
| Boot | `CONFIG_BOOT_MODE` | `boot.mode` | `auto` |
| Cinnamon | `CONFIG_CINNAMON_MODE` | `cinnamon.mode` | `auto` |

Boot mode keeps its existing safety specialization: `auto` may select only a
validated supported preparation path, `disabled` suppresses boot preparation,
and `enabled` retains strict missing-requirement failure behavior. This step does
not authorize any change to boot safety validation.

## Boundary guarantees

Step 121 is repository-local and observational:

- the reference implementation must remain at the exact source SHA-256 accepted
  by step 120;
- the shipped configuration template must remain byte-identical to step 120;
- the frozen step-119 parity contract must still classify exactly five module
  mode rows with `auto` bootstrap and template values;
- no package repository refresh, network access, package operation, boot
  operation, module mutation, reboot, or other machine action is required;
- Slackware 15.0 and Slackware-current remain mandatory targets;
- no runtime behavior or mode semantics are changed or newly authorized.

A successful review advances only to
`phase-1-configuration-module-mode-contract-freeze`, where the observed behavior
can be frozen into an explicit compatibility contract before any implementation
change is considered.
