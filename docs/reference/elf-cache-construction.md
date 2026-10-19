# Private static ELF cache construction and publication checks

Step 485 checks the architecture-tagged cache construction pipeline before any
publication. The existing `pipefail` setting makes a nonzero loop or final sort
invalidate that construction. Failure attempts to remove both owned temporary
files and returns 1, without chmod, move or count. The prior destination bytes
survive these selected pre-publication faults; the current cache record count
remains zero. Prior diagnostics and newly produced reader diagnostics remain.

Previously a final sort could emit records and then fail, after which the helper
moved those records into place, counted them and returned success. A quiet failed
sort instead fell through to the distinct no-usable-record diagnostic. The new
branch returns the construction failure directly. A genuinely successful empty
construction still produces the existing no-usable-record diagnostic. Skipped
unresolvable or unreadable library records retain their existing semantics.

Run from the repository root as the ordinary developer, without sudo:

```bash
python3 tests/reference/test-elf-cache-construction.py
python3 tests/reference/test-elf-unresolved-display.py
python3 tests/reference/test-elf-scan-workflow.py
python3 tests/reference/test-elf-metadata.py
bash tests/reference/test-elf-architecture-resolution.sh
python3 tests/reference/test-sbo-workflow.py
python3 tests/reference/test-apply-secondary-workflow.py
python3 tests/reference/test-result-precedence.py
python3 tests/reference/test-apply-json-result.py
python3 tests/reference/test-dry-run-workflow.py
```

## Independently authored matrix and private effects

Step 485's original standard-library Python matrix authored 50 scenarios: valid, duplicate,
mixed-validity, empty and wholly invalid raw records; normal, quiet/late raw
producer failure and quiet/late final-sort failure; and two diagnostic seeds.
Successful controls publish sorted unique five-field records and the exact count.
Failure controls check the prior cache, zero current count, retained diagnostics,
absence of publication/count calls and removal of both construction temporaries.
Raw producer failures are existing guarded-path controls, not new source changes.

Bash, actual private mktemp files, readlink/od/tr path and magic checks, awk,
sort, rm, chmod, mv, wc and redirections run on owned fixtures. Fake ELF prefixes
are not complete native libraries. A Bash function named `/sbin/ldconfig` supplies
bytes/status even for that absolute command spelling; the installed executable is
not called. Identity extraction is supplied, and readelf/ldd/normal updater/boot/
network boundaries are prohibited by named guards. The selected final-sort fault
either drains input quietly or emits the full real sorted result before returning
43. These are supplied failures, not disk/permission/race measurements.

Expected raw status/count, complete stdout/stderr, exact private file bytes and
directory inventory, callback vectors/multiplicity and serial phase relationships
are authored independently of reference execution. Producer/consumer callback
ordering inside a pipeline is deliberately not fixed. Only the two generated
six-character mktemp suffixes are normalized; input templates remain exact.
The fixture snapshot excludes its callback trace, which is checked separately.
It does not measure ownership, permissions, xattrs, descriptors or host state.

## Evidence and remaining limits

At step 485, all 50 scenarios and nine complementary normal suites passed under
UID 0; shell syntax passes. This does not establish an actual unprivileged OS run.
Against exact accepted484 reference bytes, 30 normal/earlier-failure controls pass
and all20 final-sort fault cases reject. In particular, a late failed sort after
usable records reproduces the old raw-success/publication result. Quiet failures
also distinguish cleanup grouping and the misleading no-usable-record fallback.
Five syntax-valid private mutations reject: unchecked construction, zero failure
return, publication after failure and retained raw/staging temporaries separately.
Normal user tests do not rerun those private mutation controls.

The initial test-authoring probe used caller IFS when recording callback vectors
and also normalized literal XXXXXX templates. It failed on a healthy control.
The fixture now sets a local space IFS and excludes those literal templates from
normalization. That harness failure is separate from the later exact old-source
controls; no reference change was made to accommodate its initial faulty trace.
Preparation evidence and this qualification remain outside the normal test run.

Step 485 changed only the construction pipeline guard in the reference. Cleanup
commands can fail; that guard preserves raw failure regardless, but does not prove
global cleanup. Earlier cache/diagnostic setup has real effects. Step 485 left
chmod, move, count and cleanup failure projections outside its patch; step 486
below addresses publication/count status and count retention. Ordinary moves
are not an atomic whole-operation or recovery contract. Reader skip semantics,
path trust, file predicates and caller changes to pipefail retain their limits.
The step484 unresolved-display guard and existing scan/verification protections
remain unchanged. Named guards are not OS containment or independent observation.

Phase1/kernel remain incomplete; all five native families/20 scenarios and
13 findings/16 gaps remain open. A/R/D unselected; original install-new20 empty
AND no-effect and upgrade20 failure criteria remain binding. Native evidence/live
bindings are null; actual host unobserved, global host closure false. Separate
native decision, independent review, conditional migration, actual composition,
independent safe whole review, fresh bounded grant and own-platform conformance
remain due. Schema1/reference-v1/C/Phase2/production remain closed.


## Publication and count failure handling (step 486)

After successful construction, a nonzero move status now attempts to remove the
owned staging temporary and returns 1 before counting. The initialized global
count stays zero. A successful move is followed by a checked local count capture;
only successful capture assigns the public count. A failed count returns 1 and
keeps that count zero, including when the failed command emitted partial stdout.
The helper normalizes these failures to raw 1; the two real scan/verification
callers already test cache refresh as a Boolean and retain their failure paths.
Their result mapping, schema and native criteria are unchanged.

The destination is not rolled back: a failed move can already have altered it,
and a failed count follows an already successful publication. Zero current count
marks the failed refresh; it does not assert an empty or restored cache file.
A failed staging cleanup can leave a temporary file while raw failure remains 1.
There is no retry, whole-operation atomicity, global cleanup or recovery claim.
The existing chmod projection and earlier raw cleanup failures remain separate.

The expanded driver has 100 scenarios. The original50 cases stay unchanged in
scope. Fifty additions cross all five profiles and both prior diagnostic seeds
with quiet/partial/late move failure and quiet/partial-output count failure.
Thirty active cases reach publication/count; twenty empty/invalid controls never
call those operations. Move faults respectively leave the old destination, write
a selected private marker, or perform the complete real move before returning43.
The late count emits42 and returns43. These are supplied faults over private real
file effects, not native disk, permission, race or concurrent-writer measurements.

Exact status/count/output, bytes/directories, callback vectors/multiplicity and
serial publication-before-count relationships are checked. Move failure must
skip counting and attempt staging cleanup; count failure must retain published
bytes and discard partial count stdout. Normal success still assigns the exact
record count. Two generated mktemp suffixes retain the original normalization;
no additional output relaxation or another driver's oracle is imported.

Against exact accepted485 source,70 unaffected cases pass and all30 active new
fault cases reject. The initial quiet move probe reproduces raw success and a
count of the old cache. Seven syntax-valid private mutations reject: unchecked
move, zero move-failure return, counting after failed move, retained failed-move
staging, unchecked count, zero count-failure return and partial-count retention.
All100 normal cases, nine complementary suites and shell syntax pass in preparation
under UID0. No actual unprivileged OS/native run or independent conformance is
claimed. Earlier construction/display guards and native gates above remain intact.
