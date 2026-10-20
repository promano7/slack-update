# Literal ELF-owner mapping

Run the focused regression from the repository root:

```bash
python3 tests/reference/test-elf-owner-mapping.py
bash tests/reference/test-package-name-parsing.sh
bash tests/reference/test-sbo-target-selection.sh
```

`map_broken_objects_to_sbo_packages` maps an existing broken-object pathname to
package manifests containing that complete literal line. Both the absolute form
and the same path with one initial slash removed are accepted. Fixed-string,
whole-line grep matching treats `.`, `+`, brackets, backslashes and other regular
expression characters as filename data. Explicit `-e` patterns and `--` separate
the patterns from command options and the database argument.

The input reader preserves IFS whitespace and processes a nonempty final record
without a terminating newline. This fixes lost final entries and trailing tabs.
It does not introduce support for newline-containing paths: both broken-object
lists and package manifest records remain line-based. No path canonicalization,
symlink ownership inference or header-versus-file-list parsing is added. Existing
`-e` object presence, recursive database traversal, exact package-build suffix,
sorted target merge and inactive-list behavior remain the surrounding policy.

## Private regression

The standard-library Python driver sources the real Bash reference and calls
the real mapper, package parser, suffix filter, target normalization and merge.
It creates private object text files, package manifests and an existing ABI list.
Real grep/coreutils, redirections, temporary files, rename and deletion operate
only on that authored fixture setup. The objects are not parsed or executed as
ELF files. Named guards prohibit known main/update/network/boot entries; these
guards are not an OS sandbox or independent containment proof.

The 91 independently authored cases comprise:

- Eighteen pathname profiles crossed with two manifest slash forms and two
  final-record termination states: 72 cases, including regex characters, spaces,
  an internal tab, a trailing tab, a leading hyphen and UTF-8 filename bytes.
- Unowned, missing-object and duplicated/blank input records crossed with those
  slash/termination forms: 12 cases.
- Empty-list, missing-list and substring-only controls: three cases.
- A custom build suffix and a symlinked private package database crossed with
  slash/termination forms: four cases.

Each active case has two versions of one real owner, a deceptive SBo manifest,
an ordinary package, a wrong build suffix and an invalid package record. The
expected target union is authored from the fixture design, not from reference
output. Whole-line negative controls include prefix/suffix-only records. The
oracle compares exact stdout/stderr, raw status, selected counts/error/ELF state,
caller IFS, an unrelated scalar and the complete private file/link/directory
inventory. It observes normal temporary-file cleanup through that inventory;
permissions, ownership, xattrs, all globals/descriptors and concurrency remain
outside the oracle.

The exact accepted492 source passes 23 cases and rejects 68. The corrected source
passes all 91. Five syntax-valid private mutations are separately rejected:
omitted fixed-string matching, omitted whole-line matching, omitted slashless
alternative, omitted final unterminated record and omitted IFS preservation.
Their respective rejected case counts are 28, 85, 40, 38 and four. These focused
controls are preparation evidence, not a fresh run of older mutation selections.

## Retained boundaries

Step 493 changes only matching and input reading in this mapper. It does not
repair temporary-allocation, database-read, traversal, sort, publication, count
or cleanup failure propagation. The current mapper can still treat an ignored
collection failure as an empty or partial result; a failed move/count may leave
changed state. No transaction, rollback or general fail-closed collection claim
follows from the successful fixtures here. Missing/unreadable broken-list file
semantics, dangling object links and arbitrary manifest text retain their existing
limits. Later work must distinguish grep's ordinary no-match status from actual
read/traversal errors before claiming collection failure handling.

The apply coordinator and final result mapper retain separate supplied-callback
regressions. Their passes alongside this private mapper test are not an actual
installed workflow composition. No installed package database, native build,
network, service, initrd or GRUB action is performed by this driver. Preparation
UID 0 does not prove actual unprivileged execution or Slackware acceptance.

The inherited incomplete binary-history record from 492 remains open. Source,
receipt and whole-condition records accompany this delivery with exact archive
identities/hashes; no complete historical archive restoration is claimed.

Prepared493 awaits actual application/test/commit/push/clean source/mode/tree
evidence. One actual step (492) of the new 8-12-step block is accepted; 493 is not
accepted by these prepared documents. The recorded previous repository pause is
491; no new pause is confirmed. Phase1/kernel remain incomplete, A/R/D unselected,
native evidence/live bindings null, host unobserved and global closure false.
All original independent acceptance, migration-if-needed, actual composition,
safe whole review, fresh bounded native grant and own-platform conformance gates
remain in force. No consumed or historical native right is reused or revived.
