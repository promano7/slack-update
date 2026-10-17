# Package change detector regression scope

Run from the repository root:

```sh
python3 tests/reference/test-package-change-detection.py
```

The driver calls real `detect_abi_changes` or `detect_kernel_changes` together
with the real package-record parser, exact-name snapshot reader, array membership
helper and, for kernel detection, real `apply_boot_module_policy`. Snapshots are
private regular files or explicitly missing paths. No installed package database,
snapshot capture, probe, package command, boot generator or normal main/workflow
is used. No detector/helper/policy operation is supplied as a callback.

## Scenarios and observed results

The 756 ABI scenarios combine 21 authored snapshot/list profiles, three Cinnamon
modes, both module-run flags, two seeded ABI triggers and three seeded Cinnamon
triggers (0/2/3). The 3,456 kernel scenarios combine 18 profiles, three boot modes,
managed/direct-generic layouts, four supplied capability pairs, four seeded
initrd/GRUB request pairs and both seeded kernel triggers. Each scenario enters
its detector twice in a fresh Bash process with reset seed state: 4,212 scenarios
and 8,424 detector entries altogether.

Expected changed-name lists are authored alongside each profile, not derived
from detector output or a Python implementation of the package parser. Full
stdout text and raw detector return, selected globals, complete critical-package
array, all six input arrays, IFS, snapshot bytes and exact private inventory are
checked after the repeated entries. Private paths contain spaces. The parent
parser-name sentinel is checked: parser calls occur in command-substitution
subshells. General loop variables `p`, `BEFORE` and `AFTER` are not asserted to
be isolated; the unchanged reference uses them as global working variables.

The profiles cover installation/removal, version/build/architecture changes,
exact names versus similar prefixes, a literal plus sign, malformed ignored
records, path/archive normalization, missing snapshots, unchanged and changed
unterminated final lines, multiple-record order, duplicate records or configured
names, and empty configured lists. The kernel profile set covers the five
configured groups separately and together. Only ABI profiles include the
build/architecture and final-line cases; this is not every possible cross-product
of package grammar and every detector policy state.

Some profiles deliberately bypass the separate validated-snapshot contract.
The snapshot reader returns an empty comparison string for a missing file,
ignores malformed lines, normalizes accepted path/archive spellings and retains
record order and duplicates. Two equal normalized streams are unchanged;
reordering or duplicating records can count as a change. These are current
helper observations, not permission to accept malformed, missing, unsorted,
duplicate or noncanonical native snapshots. Keep the
[snapshot validation check](../../tests/reference/test-package-snapshot-boundaries.py)
and [package parser check](../../tests/reference/test-package-name-parsing.sh)
for their separate input-contract coverage.

ABI detection clears the prior critical-package array, while existing ABI and
Cinnamon triggers remain unless a matching change assigns them. Only names in
the configured ABI iteration can add critical/Cinnamon triggers; configured
iteration order and duplicates are preserved in the critical result. Cinnamon
selection uses its supplied run flag; authored mode/run combinations need not
be reachable through native probes.

Kernel image/module changes set both raw requests. Headers, firmware and source
changes set the broad kernel trigger without introducing boot requests; existing
requests can still remain. The real policy records required flags before
capability/mode filtering, removes the initrd requirement for direct-generic
layout and preserves required GRUB work when disabled/auto filtering removes
its selected action. Capabilities/layout are supplied values, not live discovery.
No reboot requirement or stable exit is inferred directly from the broad trigger.

## Sensitivity, related checks and limits

Fourteen syntax-valid private source mutations are rejected by unchanged final
driver assertions on one full-matrix row each, with two detector entries per
row. They cover critical reset/append/membership, prior ABI trigger retention,
ABI/kernel trigger assignment, Cinnamon run gating, boot-group classification,
GRUB request formation, policy dispatch, required-before-filter semantics,
direct initrd suppression, exact-name matching and unterminated-line handling.
These are focused rows, not fourteen complete matrix reruns.

The first unterminated-line control unexpectedly passed: an omitted changed tail
and the intended changed tail both triggered detection. Preserve that attempt.
The final driver adds an unchanged unterminated-line profile, and the corrected
control uses that full-matrix row. The shipped reference is unchanged; no earlier
sensitivity failure is hidden or replaced by a clean-first-attempt claim.

Keep [boot policy](boot-module-policy.md), [apply orchestration](apply-secondary-workflow.md),
[result precedence](result-precedence.md), [apply JSON](apply-json-result.md) and
[direct-generic](../../tests/reference/test-current-direct-generic-boot-policy.sh)
checks for their own boundaries. The detector returns are raw helper observations,
not application/main statuses, native acceptance or proof of bootability.

Known unwanted entries and unexpected file predicates have failure guards;
these are not an OS sandbox or independent observation. Private read operations,
real shell helpers and authored snapshots do not establish actual host absence,
cleanup, native consistency, containment or execution rights. Original native
install-new20 empty-AND-no-effect and upgrade20 failure criteria remain binding.
All Phase 1/kernel work, unselected contract options, open findings, independent
specification/impact, possible explicit migration, actual composition binding,
independent safe whole review, fresh bounded native grant before effects and
later platform conformance remain due. No historical binding/right is renewed.
