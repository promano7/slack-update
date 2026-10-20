# Literal ELF-owner mapping

Run the focused regression from the repository root:

```bash
python3 tests/reference/test-elf-owner-mapping.py
python3 tests/reference/test-elf-owner-collection.py
python3 tests/reference/test-elf-owner-publication.py
python3 tests/reference/test-elf-owner-composition.py
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

Step 493 changes matching/input reading, step 494 adds the collection guard and
step 495 checks the count/publication stages described below. A failed movement
can still leave a changed destination; retained prior count does not describe
that partial destination. Cleanup-command failures remain outside the checked
fault projections. No transaction, rollback or complete I/O-failure coverage
follows. Missing-list early returns,
dangling object links and arbitrary manifest text retain their existing limits.
The Bash input loop still does not distinguish every possible midstream read
failure from EOF. Quiet allocation failures are tested; partial allocation,
concurrent file replacement, cleanup-command failure and whole-host ownership
are not covered by that projection.

## Collection failure guard (step 494)

Check initial owner-list allocation before entering the collection pipeline.
Capture each grep lookup and distinguish its normal no-match status 1 from
other failures. A lookup error, including one following partial output, stops
the pipeline child before that output is parsed. Filter errors also stop that
child; an early failure cannot be hidden by a later successful input record.
The outer pipefail guard checks collection/sorting before any target merge.
It attempts removal of the fresh stage, sets a diagnostic and returns 1 on
failure. The prior ABI queue and counter are preserved in the observed cases.
An ordinary unowned existing object remains a successful no-match case.

The separate collection driver uses real private object/manifest files and
the real parser, normalization and target merge. Supplied grep/filter/sort
callbacks project quiet and partial-output status-43 faults. Normal lookups use
real grep; a real absent private database produces a real grep read/traversal
error. A callback removes the private broken list after the initial predicate,
causing a real input-open error. Quiet initial allocation failure is supplied;
successful allocations, sorting, merge, renames and cleanup use real commands.
The callbacks and named guards are not OS containment or native tool acceptance.

Seven profiles crossed with twelve fault selections and two final-record
termination states give 168 cases. Profiles include two owners, first/last
unowned, all unowned, missing objects, empty input and missing input. Fault
selections include normal, initial allocation, first/last lookup quiet/partial,
sort quiet/partial, filter quiet/partial, missing database and input-open failure.
Selections not reached by a profile are inactive controls, not exercised faults.
The independent oracle checks exact output/status/selected state, ordered lookup/
filter/merge events, sort counts, caller IFS and the private inventory excluding
four explicitly observed instrumentation files. It checks no ELF metadata or
all descriptor/permission/ownership/xattr/concurrency state.

The exact accepted493 source passes 64 cases and rejects 104. All 168 pass on
the corrected source. Six syntax-valid private mutations reject 10/40/30/12/82/82
cases respectively: omitted allocation branch, ignored grep error, rejected
normal no-match, ignored filter error, ignored collection failure and omitted
failed-stage cleanup. Successful private cleanup and a rejected omitted-cleanup
mutation do not establish cleanup when the cleanup command itself fails.

## Count before publication (step 495)

After a successful merge, count the complete `.merged` staging file into a local
value. Count failure, including partial stdout, sets a diagnostic, attempts
removal of the two staging files and returns 1 before publication. Guard the
final move separately, with a publication diagnostic and cleanup attempt on
failure. Assign `TOTAL_EXTRA` only after count and move both succeed. A normal
empty merged queue has count zero and is published successfully.

Count failures preserve the prior queue and public count in the checked cases.
A failed move may already have modified its destination; the partial-move fault
deliberately writes such bytes and verifies failure with the prior public count
retained. No rollback is attempted or certified. Cleanup failures, concurrent
replacement, arbitrary success output from installed tools and filesystem-wide
restoration remain outside the private oracle.

The independent publication driver calls the real collector/parser/merge with
private text objects/manifests and real grep/coreutils/temporary files. Merge,
count and move wrappers supply quiet/partial errors; normal branches call real
commands. A callback deletes the successful merge stage before counting to
produce a real private redirection/open error. The test checks exact output/raw
status/selected state, ordered merge-count-publication events, caller IFS and
the whole private inventory except the explicitly observed event file. It does
not inspect every global, descriptor, permission, ownership, xattr or race.

Six profiles crossed with eight fault selections and two record termination
states give 96 cases: two owners, unowned objects, duplicates, empty ABI with
unowned objects, empty input and missing input; normal, merge quiet/partial,
count quiet/partial, publication quiet/partial and missing-stage faults. Inactive
selections remain controls. The initial 80-case evidence is retained separately;
sixteen empty-ABI cases extended the final matrix without changing the subject.
Final counts refer only to the final 96-case driver.

Exact accepted494 source passes 48 cases and rejects 48; the corrected source
passes all 96. Rejections include the newly required count-before-publication
event order even on otherwise normal rows, not 48 distinct unsafe native faults.
Seven syntax-valid private mutations reject 24/16/12/24/40/48/8 cases: ignored
count failure, ignored publication failure, counting the old queue, assigning
public count on failure, omitted failure cleanup, premature publication and
omitted successful count assignment. Older literal/collection controls retain
their original scopes; this does not rerun or enlarge their native significance.

The apply coordinator and final result mapper retain separate supplied-callback
regressions. Their passes alongside this private mapper test are not an actual
installed workflow composition. No installed package database, native build,
network, service, initrd or GRUB action is performed by this driver. Preparation
UID 0 does not prove actual unprivileged execution or Slackware acceptance.

## Private apply composition (step 496)

The composition driver connects the real apply coordinator, owner mapper,
package parser, normalization, queue merges, SBo builder wrapper and stable
result classification. It uses real private text objects/manifests and normal
coreutils/file effects. Snapshots, package actions, policy preparation/restoration,
module probes and activation flags, synchronization, initial queue construction,
ELF scan/recheck, boot work, summary, clock and selected event sinks are supplied
callbacks. The final `sbopkg` callback only records its private queue vector and
returns the selected status; it performs no build. Named boundary guards are not
an OS sandbox. Source loading bypasses main/configuration/privilege/lock/logging
entry points. UID 0 and private callbacks establish no installed/native acceptance.

The 192 authored cases cross three profiles (owned, unowned, empty scan), eight
fault selections (normal, scan, lookup, sorting, count quiet/partial, publication
quiet/partial), supplied SBo and ELF activation flags, and inert builder statuses
0/43. Inactive selections are controls. Object records are unterminated; the
literal pathname includes brackets and a plus. Independent expected output,
raw status, twelve selected result/state fields, exact error/warning arrays,
selected action/module/builder/summary event order, caller IFS and outer locals,
and the complete private inventory excluding the observed event file are checked.
It does not inspect every global/descriptor/permission/ownership/xattr or race.

On a mapping failure the real coordinator records failed selection, blocks the
inert builder and the real stable classifier reports partial failure (2). The
supplied successful summary leaves raw workflow return 0; that raw return alone
is not success. Current ELF module completion records raw 0 even with failed
state; mapping failure can retain scan status 0 while selection status is 1.
A supplied recheck may clear broken objects even after the inert builder returns
43; real build status still makes the final classification fail. These observed
fields/events are retained, not silently normalized by the oracle. Supplied
activation combinations need not be reachable from installed probe policy.
The computed boot-safe flag follows supplied disabled-boot fields and does not
validate a real boot. No native repair, build, host closure or whole native graph
acceptance follows from this private composition.

Current accepted495 runtime passes all 192 cases without runtime changes. Exact
accepted494 runtime passes 160 and rejects 32. Seven syntax-valid private mutations
reject 84/48/60/30/60/33/97 cases: omitted owner call, ignored owner return, omitted
selection-failure flag, bypassed builder selection gate, omitted selection error,
discarded builder status and discarded partial exit classification. These are
finite discrimination controls, not counts of distinct unsafe installed faults.

The initial test rejected all 192 cases before entering the workflow because its
clock-vector guard joined arguments with the reference IFS. Correcting the guard
to inspect the two arguments separately fixed the driver, not the runtime. A first
repair command used the wrong working directory and repeated the unchanged failed
driver. Both failed outputs, initial driver and explanation remain in preparation
records; later passes erase neither failure. The thirteen selected normal commands
pass separately. The historical sixty-command integration is not rerun here.

The inherited incomplete binary-history record from 492 remains open. Source,
receipt and whole-condition records accompany this delivery with exact archive
identities/hashes; no complete historical archive restoration is claimed.

Prepared496 awaits actual application/test/commit/push/clean source/mode/tree
evidence. Four actual steps (492-495) of the new 8-12-step block are accepted;
496 is not accepted by these prepared documents. The recorded previous repository pause is
491; no new pause is confirmed. Phase1/kernel remain incomplete, A/R/D unselected,
native evidence/live bindings null, host unobserved and global closure false.
All original independent acceptance, migration-if-needed, actual composition,
safe whole review, fresh bounded native grant and own-platform conformance gates
remain in force. No consumed or historical native right is reused or revived.
