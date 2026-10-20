# ELF cache lookup status

Run the focused regression and complementary metadata/architecture tests from the
repository root:

```bash
python3 tests/reference/test-elf-cache-lookup.py
python3 tests/reference/test-elf-metadata.py
bash tests/reference/test-elf-architecture-resolution.sh
python3 tests/reference/test-elf-scan-workflow.py
```

## Completed search versus lookup failure

`static_elf_cache_has_compatible_library` returns 0 for a matching soname/class/
data/machine record, 1 for a completed search without one, and 2 when the awk
lookup fails, does not produce its expected result marker, or its cache operand
is a directory after the lookup. Its existing early
return 1 for an incomplete query identity remains unchanged; no cache lookup is
attempted in that case. These are opaque identity fields, not an architecture
validity certification. Existing record matching and cache format remain intact.

Repair1 additionally rejects a directory operand after the awk call. GNU awk can
skip a directory with a warning, return0 and emit the normal absent marker; the
original497 therefore misclassified this case. A nonzero-status check alone was
insufficient. The explicit directory check also retains command-event behavior
across awk implementations. This is a finite path-type observation after the
search, not an atomic opened-file binding or a guarantee against concurrent
replacement, symlink races or every special-file behavior.

Capture the successful awk search result separately from its execution status.
Any nonzero awk status, including partial success-looking stdout, becomes 2.
Consume no result marker from a failed invocation. Successful unexpected/empty
output also becomes 2. The search reads the cache through completion rather than
exiting on the first match. This does not validate every cache row or certify all
possible installed-tool output and I/O behaviors.

`static_elf_object_has_missing_dependency` retains its existing status contract:
0 means a missing compatible dependency was found, 1 means the inspected needed
set was satisfied (including no dependencies), and 2 means inspection failed.
Only lookup status 1 is evidence of a missing dependency. Lookup failure becomes
inspection status 2 instead of being treated as a normal absence. Processing
still stops on the first missing dependency or error; it is not an exhaustive
health audit of later needed entries. A dependency-free object performs no lookup,
so an unavailable cache can remain unobserved on that path.

## Existing scan and verification policy

The real initial scan currently logs a generic `readelf could not inspect`
diagnostic and omits an object whose inspection returns 2. It can then publish
an empty broken-object list and return 0. This step preserves that policy; a
successful scan return alone does not establish that every object was inspected.
The generic diagnostic does not distinguish readelf from a cache lookup problem.
An awk diagnostic can additionally appear on stderr. No complete failure-blocking
scan or SBo blocking guarantee follows from this change.

The real post-build verification instead retains an existing object when its
inspection returns 2, reports it as still unresolved and returns failure. It
clears the list only when all selected entries pass its existing policy. Normal
absence still marks an object broken in both paths. These behaviors are exercised
with real helpers and private files, not installed ELF objects or native repairs.

## Private regression and controls

The repaired 592 authored scenarios comprise:

- 432 direct lookups: nine cache profiles, six query identities and eight command
  fault selections. Profiles cover matching, wrong class/data/machine, soname
  prefix, empty, duplicate, real missing file and real directory. Two identities
  are incomplete and preserve the existing early-return behavior.
- 64 object inspections: four cache profiles, four needed sets and four command
  selections, using the real metadata parsers and lookup/object helpers.
- 48 initial scans and 48 reverifications: four cache profiles, three needed sets
  and four command selections, connecting the real path/magic/metadata/lookup/
  scan or verification helpers.

Normal awk, sort, find, readlink, od, tr, sed, counts, copies and redirections run
on private authored files. `readelf` supplies header/dynamic-section bytes; cache
refresh supplies successful status and a record count without calling ldconfig.
Quiet statuses 1/2/127, partial stdout with status43 and empty/unexpected stdout
with status0 are supplied command projections. The additional directory-skip
selection prints a warning and the absent marker with status0 only when its
private cache path is a directory; otherwise it executes real awk. These94
additional selections make the omitted-directory guard detectable locally even
when the installed awk normally returns an error for directories. Inactive selections, including
no-needed and incomplete-identity cases, are controls rather than exercised faults.
Text fixture objects have ELF magic but are not parsed by an installed readelf or
executed. Named guards are not OS containment. Main/configuration/privilege/lock/
logging/native package/build/boot workflows do not run. Preparation UID0 does not
prove actual unprivileged or Slackware acceptance.

The oracle independently authors expected raw output/status, selected scan/
verification/count fields, ordered lookup/readelf/refresh events, caller IFS,
an unrelated outer scalar and complete private inventory excluding the observed
event file. Native awk error wording varies: missing-file diagnostics must name
the private path; directory diagnostics must identify awk and the directory error
category. Exact vendor wording is outside that check. It does not inspect every
global, descriptor, permission, owner, xattr, race or whole host.

## Original failure and repair evidence

Original497 passed498 locally under the preparer's mawk, but the user's original
execution passed487/rejected11. GNU awk warned that a directory was skipped,
returned0 and the helper produced absence1. Object inspection therefore produced
missing0 instead of inspection2; scan/verification projections also differed.
The original block stopped at the first test before git add/commit/push/capture.
No actual497 return or commit was accepted. All eleven supplied projections are
retained with explicit inline-transcription provenance.

The user tested the repair only in private copies: original498 passed, and all
fourteen complementary commands passed with runtime SHA256
`cf26b233556522176875427fcfad9bd4eba72b94ddc2d81bfda9e69994ef1f95`.
Those commands checked that repository source bytes stayed unchanged. This is
supplied terminal evidence, not independent capture, installed/native acceptance
or an actual repair/commit in the user's checkout. The current source has the
same runtime hash; the driver now has592 cases, including94 additional selections.
Do not relabel the prior498 result as592. Current controls and outputs accompany
repair1; historical original497 controls remain bound to their original subjects.

A separate earlier authoring failure must also remain distinct: the preparer's
initial diagnostic oracle required a directory path that mawk omitted, producing
487pass/11fail before that oracle was corrected. The historical baseline244/254
and corrected-driver baseline248/250 are retained only with those original scopes.
That test-only issue did not explain or excuse the later user's real GNU awk
runtime defect. Neither failed result is erased by a later pass.

Fifteen selected normal commands ran separately during repair preparation and
actual497; the later [66-command actual498 integration](repository-regression-block-492-499.md)
also passed. Neither result accepts a whole native workflow composition.
Existing owner collection/publication cleanup, partial-move, concurrency and
whole-state limits remain. No complete archive repair is claimed for the inherited
incomplete nested491 delivery. Full source, receipts and exact inherited condition
bodies accompany the prepared delivery.

Complete actual497 repair1 and actual498 integration are accepted as supplied
evidence. Seven actual steps492-498 are accepted; final prepared499 still needs
its actual return and separate whole-condition review. Previous recorded
repository pause491; no new pause is confirmed here. Phase1/kernel remain incomplete,
A/R/D unselected, native evidence/live bindings null, host unobserved and global
closure false. Original independent acceptance/migration-if-needed/actual
composition/safe whole review/fresh bounded native grant/own-platform conformance
gates remain; no historical or consumed right or binding is reused or revived.
