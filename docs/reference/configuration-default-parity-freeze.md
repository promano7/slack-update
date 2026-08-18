# Phase 1 configuration default parity freeze

Step 119 freezes the effective default surface already observed in steps 117 and
118. It does not add another parser, change the reference implementation, or
alter `data/config/slack-update.conf`.

The frozen contract maps every configuration-template key to exactly one
`CONFIG_*` variable. `CONFIG_FILE` is intentionally excluded because it selects
the configuration source and is not a template key.

## Reviewed surface

The contract contains exactly 34 rows:

- 1 schema-control row;
- 28 existing configuration-surface rows;
- 5 deferred module-mode rows.

All 34 template keys are represented exactly once and every mapped variable is
unique.

## Bootstrap/template overlap

Eight variables currently have a non-empty bootstrap initializer and also have
a template value. The values must remain identical while both representations
exist. Five are the deferred module modes (`auto`). The other three are:

- `CONFIG_SBO_OPTIONS_FILE` = `/etc/slack-update/sbo-options.sqf`;
- `CONFIG_INITRD_KERNEL_PACKAGE` = `kernel-generic`;
- `CONFIG_KERNEL_MODULES_DIRECTORY` = `/lib/modules`.

Step 119 does not remove these overlaps. It freezes them so a later refactor can
prove default-behavior parity before and after any code change.

## Safety boundary

This step is repository-only and read-only with respect to runtime behavior. It
requires no Slackware machine action and does not depend on the current state of
a Slackware package repository. The module `enabled`/`disabled`/`auto` boundary
remains deferred.

System PATH sanitization, GenInitrd safety paths, the canonical generic-kernel
link, and package/boot command identities remain outside user configuration.
