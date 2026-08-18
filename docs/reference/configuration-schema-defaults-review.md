# Phase 1 configuration schema and defaults review

Step 118 records the configuration surface that already exists in the reference
implementation. It does not create a second parser, change runtime behavior, or
promote additional hard-coded safety values into user configuration.

The review is deliberately observational. The helper extracts the first
bootstrap initializer for every `CONFIG_*` variable from the reference script
and separately inventories the real section/key surface in
`data/config/slack-update.conf`.

## Classification

Every observed `CONFIG_*` variable belongs to one of four classes:

- `configuration-source`: `CONFIG_FILE`, which selects/canonicalizes the configuration source and is not itself a template key.
- `schema-control`: the schema-version control itself.
- `deferred-module-mode`: activation modes intentionally reserved for the later
  enabled/disabled/auto module-mode boundary.
- `existing-config-surface`: configuration state already represented by the
  current parser and runtime variables.

The following values remain outside this migration boundary even when they are
hard-coded in the reference implementation: the sanitized system `PATH`,
GenInitrd policy/link locations, the canonical generic-kernel link, and the
identities of `slackpkg`, `mkinitrd`, and `grub-mkconfig`. They require an
independent safety review before they could ever become configurable.

## Default terminology

An empty bootstrap initializer is not automatically an effective user default.
It means only that the variable starts unset before the existing configuration
loader resolves or validates it. Step 118 therefore records bootstrap
initializers and template values separately. Step 119 may freeze effective
parity only after both observed surfaces are reconciled.

## Safety properties

- No runtime source file is modified by the inventory helper.
- The existing configuration template is read only.
- No package manager, boot loader, network client, or privileged command is
  invoked.
- Module activation-mode migration remains deferred.
- Future changes must preserve Slackware 15.0 and Slackware-current support.
