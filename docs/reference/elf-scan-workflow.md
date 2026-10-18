# Private ELF scan and post-build verification scope

Run from the repository root:

```bash
python3 tests/reference/test-elf-scan-workflow.py
python3 tests/reference/test-elf-metadata.py
bash tests/reference/test-elf-architecture-resolution.sh
python3 tests/reference/test-sbo-workflow.py
python3 tests/reference/test-apply-secondary-workflow.py
python3 tests/reference/test-result-precedence.py
python3 tests/reference/test-apply-json-result.py
python3 tests/reference/test-dry-run-workflow.py
```

The new standard-library Python driver calls the real scan, post-build verification
and diagnostic renderer. It also uses the real path/magic helpers with private
ELF-prefix files, text, directories, symlinks, dangling targets and space-containing
names. Bash, `find`, `readlink`, `od`, `tr`, `sort`, `cp`, `wc`, `sed` and selected `mv`/`mkdir`/`ln` run on owned
private fixtures. Fake ELF-prefix bytes are not complete native executables.

Cache refresh and dependency classification are supplied callbacks. The cache
callback writes one supplied private cache line or reports a selected failure; it does
not call `/sbin/ldconfig`. The classifier returns authored 0/1/2 results, plus an
explicit out-of-contract 23 case to isolate the coordinator's fallback branch.
The late find/sort failures first emit their real private command output
and then return 43; quiet sort still drains its input. These callbacks do not
establish installed library availability or reachability
of every supplied state. No inspected object is deliberately invoked as a command.

## Independently authored checks

| Boundary | Entries | Covered behavior |
| --- | ---: | --- |
| Initial scan | 102 | Five private layouts across ten normal/fault profiles and two diagnostic seeds, plus two real private missing-root cases |
| Post-build verification | 152 | 144 normal/fault matrix entries plus eight controlled directory/link redirection failures |
| Diagnostic rendering | 4 | Empty, one-line, multiline and unterminated messages |

Expected stdout bytes and controlled stderr (exact GNU find diagnostic under
LC_ALL=C, plus full Bash source/target/directory-error shape with a positive
variable line number), raw returns, four selected state fields, callback
vectors and complete private file/directory/link inventory are authored separately
from reference execution. Check caller IFS and an unrelated scalar too. The real
`find` traversal order is unspecified: compare callback vectors/multiplicity and
cache-first ordering, without imposing directory iteration order. Post-build list
processing has an authored order and checks the complete callback sequence.

All scan paths and callback files belong to the harness. Named guards prohibit
main/updater/network/boot/installed cache/reader entries; they are not OS containment.
The private filesystem snapshot compares bytes, directories and link targets,
not ownership, permissions, xattrs, descriptors or every shell/global state field.
Selected quiet/late command faults are supplied callbacks, not native permission,
disk or concurrency measurements. Two extra cases call real GNU find against a
missing private scan root and preserve its stderr. That is a real private command
failure, not Slackware acceptance or an installed filesystem scan. The quiet
sort fault drains its input before returning 43, avoiding artificial producer
pipe errors.

## Preserve and qualify current behavior

- Initial scanning clears prior diagnostic/new-list files. A cache failure sets
  scan status 1, reports and clears its diagnostics, and preserves the prior
  broken list. Successful supplied cache refresh records its authored count.
- Initial enumeration emits unresolved objects, omits regular non-ELF/dangling
  inputs and reports classifier status 2 without adding that object to the list.
  Final list output is sorted and unique; symlink results use the scanned path.
- Initial `find`/sort failures now set scan status 1 and return 1 before copy/count,
  preserving the published list and its prior count. This includes late failures
  which have emitted staging data. Count is checked on staging before publication;
  a count failure preserves the old list/count. Copy failure sets scan status 1
  and returns 1 without assigning the new count; the destination can still be
  partially altered. See the separate step 477/478 handling below.
- Empty or missing post-build lists return zero early, retaining old diagnostics,
  cache count and still-broken file. Cache failure after a nonempty list preserves
  that list but clears the private still-broken staging file and reports failure.
- Post-build verification retains unresolved, unreadable-existing and dangling
  entries, but drops vanished paths and healthy entries. Status 2 retains an
  object and reports a diagnostic; supplied status 23 is outside the real reader's
  0/1/2 contract and is not treated as a retained inspection error by the wrapper.
- Duplicate results normalize; repeated input errors retain repeated diagnostics.
  A nonempty unterminated final record is now processed by the verification loop,
  so a broken final path is not dropped as passing. The normal scan producer
  continues to emit terminated records; no native input contract is amended.
- Quiet and late sort failures in verification set verification status 1 and
  return 1 before publishing/clearing the prior list. Copy failure on the warning
  branch is reported specifically and returns failure/status 1; partial writes
  remain possible. No atomic transaction or native recovery guarantee follows.

## Initial scan pipeline failure handling

Step 477 changes only `detect_broken_elf_objects` in the reference. It checks the
existing find/classification/sort pipeline with the reference's existing
`pipefail` option. Any failing pipeline stage sets `ELF_SCAN_STATUS=1`, emits
`Cannot enumerate or sort the static ELF scan results`, reports staged reader
diagnostics and returns 1 before publication/counting. It does not change shell
options or a caller that deliberately disables pipefail after sourcing.

The previous `BROKEN` bytes and `BROKEN_COUNT` survive this failure. They describe
the prior result, not a successful current scan. Cache/staging/error files can
still change; cache construction and diagnostic reset occur before enumeration.
Partial staging results are retained privately, not published as a successful
scan. There is no filesystem transaction, rollback, complete cleanup guarantee
or new result-schema field. Copy/count failures after a successful pipeline and
post-build verification sort/copy behavior were outside the step 477 repair;
step 478 below adds explicit failure handling.

The original 60/96/4 matrix is retained in the predecessor delivery. The updated
matrix fails against that exact old implementation on its first quiet-find
control: expected raw/status 1 with preserved state, observed raw/status 0 with
empty published result. The step 477 source passed 82 scan, 96 verification and
four diagnostic entries; the current expanded counts are in the table above. Scan coverage adds late real-output-then-43 faults for
find and sort, plus an actually absent private scan root. Each failure checks
exact status/diagnostic, unchanged publication/count, no copy/count callbacks
and the complete expected private inventory. Successful empty scans still
publish an empty list normally. No inspected ELF-prefix object is executed.

Six syntax-valid private controls reject: restored unchecked pipeline, zero
scan status, zero raw return, disabled pipefail, publication on failure and
omitted failure diagnostic. The seven complementary metadata/architecture/SBo/
apply/result/JSON/dry-run suites retain their separate callback scopes; they do
not constitute native end-to-end composition. Existing callers already gate
ownership mapping on scan success and record scan failure; those call sites
are unchanged. Source fixes do not amend native criteria or authorize native
execution. Its then-remaining copy/count/recheck failures are addressed below.

## List publication and verification failure handling

Step 478 changes only the initial scan and post-build verification functions.
The initial scan counts the complete staging file before copying it. Nonzero
count status, including failure after partial stdout, sets scan status 1 and
returns 1 before copy; no zero fallback is used. Publication status is checked,
and the new global count is assigned only after copy succeeds. A quiet copy
failure or a supplied partial-write failure produces raw/status 1 rather than a
successful count/summary. The old count is retained as a prior value, not a valid
current result after failure.

Verification now checks its read/classification/sort pipeline under the existing
pipefail option. Quiet and late sort failures produce raw/status 1, report
reader diagnostics and preserve the original list bytes before any copy/clear.
The loop also processes a nonempty last record without a newline. An unresolved
final path is retained normally. Publishing a nonempty unresolved result checks
copy status and reports a specific warning on failure; verification remains
failed whether unresolved objects persist or their publication fails.

Copying is still ordinary `cp`, not an atomic transaction. The partial-copy
callback writes a selected private marker before returning 43; tests explicitly
retain that destination alteration while requiring raw/status failure and no
success summary. There is no rollback claim. Count callbacks can emit `42` and
then fail; those bytes are not accepted as a successful count. The actual GNU
commands, redirections and private files retain their documented real effects.
These supplied faults are not native disk/permission/race measurements.

Five focused controls against accepted477 demonstrate the old quiet-copy,
count, quiet-sort, late-sort and unterminated-record failures. The current driver
passes 102 scan, 144 verification and four diagnostic entries. Six syntax-valid
mutations reject: zero-count fallback, copy-failure success return, count status
zero, old unchecked verification, dropped final record and verification copy
status zero. Seven related normal suites keep their separate supplied boundaries.
The step 477 pipeline guard and both earlier fixture repairs remain intact.

At step 478, resolved-list clearing was still the unchecked redirection after
the success message, with no explicit verification-status assignment on error.
That path was outside its patch; step 479 below handles the final clear.
Staging/diagnostic reset errors, reader classification and diagnostic-rendering
faults retain their separate scopes.
No metadata/cache/native contract, result schema or execution authority changes.

## Resolved-list clearing

Step 479 checks the final `: > "$BROKEN"` before announcing successful
verification. A failed redirection sets `ELF_VERIFICATION_STATUS=1`, reports
`Cannot clear the resolved ELF object list` and returns 1. The success message
is emitted only after clearing succeeds. This changes only the final tail of
verification; all other reference bytes and the step 477/478 protections remain.

Eight added cases cross healthy/vanished-object input, two blocking path shapes
and empty/preseeded diagnostics. After the real private sort has drained its
input and produced an empty verification list, the selected callback moves the
original input to private `saved-broken` and replaces the publication path with
a private directory or a symlink to another private directory. The guard checks
exact owned paths and the empty staging result before these operations. The
subsequent real Bash write redirection fails with `Is a directory`, including
when the preparer is root. This does not rely on chmod unreadability modeling.
It does not constitute a concurrent writer or filesystem containment test.

Each added case checks raw/status 1, the warning, absence of the success message,
the full expected private directory/link/file inventory, saved input bytes,
callback order and the Bash source/target/error text with only its numeric line
number variable. The original normal success controls still require an empty
published list and exactly one success message. No sudo, chown or installed
package/boot/cache operation is introduced; all moved/replaced paths are owned
fixtures and are removed by the Python test's private cleanup.

Four old-source controls reproduce the misleading success message/status 0 with
raw failure on accepted478. Four syntax-valid source mutations reject: restored
old clear tail, status zero, return zero and premature success output. Current
coverage is102scan/152verify/4diagnostic entries plus seven complementary normal
suites with their existing separate boundaries. These controls do not establish
native permission/race/disk behavior or an unprivileged OS run by this preparer.
No global cleanup or independent native conformance follows. Reset/render faults
and other original limitations remain outside this narrow final-clear repair.

These tests characterize present coordinator behavior. They are not acceptance
criteria approving the unchecked failure cases. Real cache construction, installed
inspection, native composition, result mapping and conformance remain separate
review boundaries. Broader claims require their own evidence and requirements.

The original step 471 nine syntax-valid private source controls rejected:scan diagnostic reset, cache-fail
status, reader-error classification, copy source, empty-list early return, dangling
retention, uninspectable retention, unterminated-record behavior and diagnostic
clear. They are focused sensitivity checks, not exhaustive mutation coverage or
normal user runs. The first authoring run rejected a callback guard that omitted
the reference's `cp --` argument. Correct the guard and authored vector;retain the
failure and leave reference code unchanged. Those historical final matrices and controls passed; they are not a fresh
mutation claim for step 477.

The architecture-resolution regression requires `jq` and has its own supplied
metadata/cache scope. No installed cache/binary or normal updater/boot action is
introduced by this new driver. Private artifacts and cleanup are real work products
and do not demonstrate global host absence or cleanup. Phase 1/kernel remain
incomplete; A/R/D unselected, schema 1/reference-v1/C/Phase 2/production closed.
Install-new20 empty AND no-effect, upgrade20 failure, original specification/
migration/composition/independent whole-review/fresh native grant/platform
conformance gates all remain unchanged.
