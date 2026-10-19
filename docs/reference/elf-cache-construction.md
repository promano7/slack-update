# Private static ELF cache construction checks

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

The standard-library Python driver authors 50 scenarios: valid, duplicate,
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

All 50 scenarios and nine complementary normal suites pass in preparation under
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

Only the construction pipeline guard changes in the reference. Cleanup commands
can fail; this guard preserves raw failure regardless, but does not prove global
cleanup. Earlier cache/diagnostic setup has real effects. Later chmod, move,
count and cleanup failure projections remain outside this patch; ordinary moves
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
