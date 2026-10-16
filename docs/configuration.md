# Shell reference configuration

Use [data/config/slack-update.conf](../data/config/slack-update.conf) as the
complete current example. This guide describes its schema version `1`.
That configuration version is separate from the provisional schema-0 JSON and
NDJSON result interfaces described in [reference usage](reference-usage.md).

Configuration selection, source-tree fallback and installation paths are in
[development setup](development-setup.md#configuration-lookup).
`SLACK_UPDATE_CONFIG` selects an alternate absolute file path for tests;
the shell CLI has no `--config` or standalone configuration-validation command.

## File format and validation

The parser reads section headers and `key=value` entries as data. It does not
source the file, expand shell variables or evaluate shell commands. Values are
not shell assignments: avoid shell quoting and use the literal path/value.
Blank lines and full-line comments beginning with `#` or `;` are ignored.
Inline comment suffixes are not stripped from values.

Sections and keys are case-sensitive. Unknown sections/keys, duplicate keys,
keys outside a section, malformed lines, unsupported schema versions and invalid
required values are rejected. Boolean values are exactly `true` or `false`;
module modes are exactly `enabled`, `disabled` or `auto`.

Start from the complete example rather than a fragment containing only a mode.
Disabling a module does not bypass validation of the rest of the configuration.
The original proposed `[module.*]` and `[notifications]` sections in the
[planned C design](design.md#planned-configuration-and-desktop-preferences)
are not current shell sections.

## Supported sections and keys

The table lists all current recognized keys. The checked-in file remains the
source for complete values, including package groups and paths.

| Section | Keys | Purpose |
| --- | --- | --- |
| `[core]` | `schema_version`, `work_dir`, `log_dir`, `lock_file`, `log_retention_days`, `package_database` | Schema and runtime storage/locking/package database |
| `[slackware]` | `install_new`, `upgrade_all` | Enable the two Slackware package phases |
| `[flatpak]` | `mode` | Flatpak activation policy |
| `[sbo]` | `mode`, `sbopkg_config`, `queue_dir_fallback`, `package_tag`, `options_file` | SBo activation, configuration, queues and persistent build options |
| `[elf]` | `mode`, `scan_paths` | ELF diagnostics activation and colon-separated scan paths |
| `[packages]` | `abi`, `cinnamon_abi`, `critical`, `kernel`, `kernel_boot`, `kernel_headers` | Space-separated package-name groups |
| `[boot]` | `mode`, `mkinitrd_config`, `initrd_default_output`, `kernel_package`, `modules_directory`, `grub_directory`, `grub_config` | Boot preparation policy and paths |
| `[cinnamon]` | `mode`, `repository`, `remote`, `branch`, `builder` | Managed CSB checkout and builder selection |

Runtime, database and configured filesystem paths validated as absolute must
begin with `/`. `elf.scan_paths` contains colon-separated absolute paths.
Package groups contain literal package names, not regular expressions or shell
patterns. `boot.kernel_package` names exactly one package. Log retention is a
non-negative integer number of days.

The Cinnamon remote must use explicit HTTPS, its branch has a restricted
character set, and the builder must be a safe relative path. These are input
validation rules, not proof that a selected checkout or builder is trusted or
authorized for execution. Full source/trust requirements remain in the
[reference records](reference/README.md).

## Optional module modes

| Mode | Meaning |
| --- | --- |
| `disabled` | Do not probe or run that optional module |
| `auto` | Use the module when its required tools and applicable local state are detected; unavailable work is skipped |
| `enabled` | Require the module's prerequisites; unavailable requirements are reported as errors |

Flatpak, SBo, ELF, boot and Cinnamon default to `auto`. Configurations that
predate explicit mode keys retain that default when the keys are omitted.
The core Slackware path has no corresponding optional `mode` key.

For example, the following is a FRAGMENT to edit in a complete configuration,
not a standalone file and not a request to run the reference:

```ini
[sbo]
mode=disabled

[flatpak]
mode=auto
```

Activation and applicability are distinct. Available tools do not prove there
is work to do, while an `auto` skip is not successful execution of that module.
For example, Cinnamon auto-detection checks local installation/managed checkout
state and Git; forced enabled mode still requires Git. Boot preparation uses
its supported initrd/GRUB or direct-generic layout checks, not just a mode flag.

## Interpret package and boot policy separately

The broad `kernel` package group can detect kernel-related changes without
requiring boot preparation. In particular, a headers-only change must not be
treated as an installed kernel image transition solely because it is in that
group. The boot requirements and final structured boot result determine reboot
guidance under the stable [exit-code contract](../README.md#exit-codes).

Configuration chooses behavior and paths; it does not complete Phase 1,
establish native compatibility or authorize a system operation. Use the
[roadmap](roadmap.md#current-phase-and-release-gate) and scenario-specific
acceptance material for those boundaries.
