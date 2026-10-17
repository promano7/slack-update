# Combined result precedence regression

Run from the repository root:

```bash
python3 tests/reference/test-result-precedence.py
```

This independent Python 3 standard-library driver calls the real
`determine_stable_exit_code`, message preparation, enabled-module diagnostics,
result-state calculation and package-action status predicate. Its authored
baseline does not invoke a runtime initializer or clock. It complements the
[stable-exit regression](../../tests/reference/test-error-exit-codes.sh) and
[supplied apply JSON cases](apply-json-result.md); it does not use their helpers.

## Authored matrix

There are 492 scenarios and 984 mapper calls. The apply matrix crosses eight
boot states, ten nonboot fault/warning states, presence/absence of critical
packages and three supplied workflow statuses (0, 1, 23): 480 scenarios.
Six check and six dry-run cases exercise their separate result scopes.

| Supplied group | Independent expected behavior |
| --- | --- |
| No boot work | Clean result 0, or successful 4 when critical packages are supplied |
| Successful initrd, GRUB or both | Successful 5, taking precedence over a recommendation |
| Failed initrd, GRUB, both or blocked GRUB | Unsafe 3, taking precedence over ordinary failures and reboot notices |
| Ordinary failure plus successful boot work | Partial 2, retaining the required reboot field |
| Ordinary failure with no boot work | Partial 2, retaining any critical-package recommendation field |
| Package/snapshot/module/SBo/ELF faults | Exact ordered authored errors; nonboot failure cannot hide an unsafe boot result |
| Pending-file count or enumeration problem | Warning only; does not create a partial result by itself |
| Empty versus populated private ELF file | A supplied enabled scan reports an error only for the populated file |
| Check and dry-run | 0 or 1, no partial/reboot state; check ignores supplied apply-only failures |

An explicit table provides the complete expected code, success, partial,
boot-safe and reboot fields. Diagnostic fragments and their concatenation order
are authored separately from the subject: enabled modules, selected snapshot,
package actions, Flatpak, SBo/Cinnamon, boot, then ELF. Both invalid snapshots
produce only the before-snapshot error. Pending-file warnings precede the
critical-package warning. Explicit check errors suppress the default raw-status
diagnostic; dry-run always retains its unresolved-package warning.

Each scenario runs the real mapper twice, poisoning scalar results and adding
stale error/warning entries before each call. Exact NUL-delimited records verify
fresh fields, array lengths/order, function status 0 and unchanged IFS. NUL is
only a record delimiter; no NUL-containing Bash string is supplied. A successful
helper return is separate from the mapped failed-operation code in its variables.

The ten nonboot rows are clean; all three package actions failing; both snapshots
invalid; all five enabled modules unavailable; SBo synchronization/selection/build
and Cinnamon failing; an empty ELF result; a populated ELF result; invalid pending
enumeration; two pending files; and a combined fault row. Combined rows include
Flatpak status and the preceding module/snapshot/package/SBo/ELF failures together.

## Scope and limits

All inputs are authored variables/arrays and one private empty or populated
broken-object file. Python quotes fixed-name shell assignments and verifies
unchanged file bytes after both calls. Actual result helpers inspect that private
file using their `-s` predicate; no snapshot, package database, config, boot path
or pending-file list is opened. No shared serializer or JSON decoder is involved.

Main, workflow, runtime, configuration, locking, clock and serializer functions
abort if entered. The driver neither calls them nor initializes real runtime
state. These selected guards are not OS containment for arbitrary new source;
review added calls and effects before running it against changed reference code.

The matrix deliberately includes combinations not established as reachable
native states, such as unavailable-module metadata beside supplied successful
boot flags. Its `boot_safe` values are computed outputs, not observations of a
bootable host. Raw workflow 23 is supplied failure data, not a new stable code.
No package operation or actual module/boot validation is executed.

These expectations preserve current reference behavior. They do not accept native
raw-20 semantics, amend original install-new/upgrade-all criteria, freeze schema 1,
select an option or complete Phase 1. Native obligations, findings and separate
semantic/migration/platform/run execution gates remain unchanged.
