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

The standard-library Python driver calls the real scan, post-build verification
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
| Initial scan | 133 | Original 118 entries plus 15 diagnostic outcome checks across normal/cache/pipeline stages |
| Post-build verification | 199 | Original 184 entries plus 15 diagnostic outcome checks across normal/cache/pipeline stages |
| Diagnostic rendering | 20 | Four original layouts plus 16 quiet/late render or clear-obstruction checks |

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

- Initial scanning checks diagnostic/new-list initialization before cache refresh.
  Failure returns raw/status 1 without a cache, traversal, count or copy callback.
  Prior publication/count and cache state survive; a successful diagnostic clear
  can precede a staging-clear failure. A cache failure sets
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
count, quiet-sort, late-sort and unterminated-record failures. The step 478 driver
passed 102 scan, 144 verification and four diagnostic entries. Six syntax-valid
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
old clear tail, status zero, return zero and premature success output. At step 479,
coverage was102scan/152verify/4diagnostic entries plus seven complementary normal
suites with their existing separate boundaries. These controls do not establish
native permission/race/disk behavior or an unprivileged OS run by this preparer.
No global cleanup or independent native conformance follows. Reset/render faults
and other original limitations remain outside this narrow final-clear repair.

## Work-file initialization failures

Step 480 checks the two initialization redirections in each of the initial scan
and nonempty-list verification paths. Diagnostic initialization is attempted
first; results initialization is attempted only if it succeeds. Failure sets
the corresponding scan/verification status to 1, emits `Cannot initialize the
static ELF scan files` or `Cannot initialize the static ELF verification files`
and returns 1 before cache refresh, readers, traversal, sorting or publication.
The original empty/missing verification-list early return remains before these
operations and still leaves its old diagnostics/cache/staging state untouched.

The prior published list, count and cache bytes/count are preserved on these
failures. This is not a transaction: if diagnostics initialize successfully but
the results path fails, the old diagnostic bytes have already been cleared.
An initialization redirection can have ordinary filesystem effects even when a
later operation fails. No atomic rollback, global cleanup, path-trust or native
permission guarantee is introduced. Diagnostic rendering, later reader failures
and partial publication retain their separate limits.

Forty-eight added entries use real private directories or links to private
directories in place of the diagnostic or result file before entry. Sixteen scan
cases cross healthy/broken inputs, four obstructions and two diagnostic seeds.
Thirty-two verification cases add the same 16 active checks plus 16 empty/missing
list early-return controls. The real Bash redirection error is checked against
its full source/target/directory-error shape with a variable positive source-line
number. Full output, raw/status, unchanged publication/cache state, complete
private inventory and absence of callbacks are independently authored.
Results-path failures explicitly require that diagnostics were already cleared;
diagnostic-path failures require untouched result staging. The fixture does not
rely on chmod behavior for root and does not run an unprivileged subprocess.

Eight controls against accepted479 reproduce the old continued execution and
misleading success. Six syntax-valid source mutations reject unchecked resets,
zero status and zero raw returns separately for scan and verification. The
step 480 driver passed118scan/184verify/4diagnostic entries; seven complementary
normal suites pass with their existing independent scopes. Every reference byte
outside the two initialization blocks remains unchanged, including477-479 guards.
No installed cache, package, boot or inspected-object execution is added.

## Diagnostic rendering and clearing failures

Step 481 checks diagnostic rendering before clearing its input. A nonzero `sed`
status returns 1 with `Cannot render the static ELF inspection diagnostics` and
does not attempt the clear. This includes failure after the command has already
emitted all its selected private output. Successful rendering then checks its
clear redirection; failure returns 1 with `Cannot clear the static ELF inspection
diagnostics`. Empty diagnostic input remains a successful no-op. No state field
is assigned by the renderer itself.

The ordinary post-pipeline scan and verification paths now check the helper's
return, set their relevant status 1 and return 1 before publication/counting or
resolved-list clearing. Already-failed cache/pipeline branches still return 1;
they also use the guarded helper and retain its warning and diagnostic effects.
There is no second rendering attempt or automatic retry. Previous published
list/count survive this failure, but preceding cache/staging work remains real.
Diagnostic clearing is not an atomic transaction and no rollback is claimed.

Forty-six added entries use the existing guarded private cache/classifier plus
a selected `sed` callback. Fifteen per workflow cross normal/cache-failure/
late-pipeline-failure stages with success, quiet renderer failure, full real
rendering followed by failure, and two diagnostic-clear obstructions. Sixteen
direct-helper entries cross empty/one-line/multiline/unterminated input and the
four failure selections; empty input invokes no renderer and succeeds.
The two clear callbacks first run real private `sed`, save its original input
and then substitute a directory or a link to a private directory. The subsequent
real Bash clear fails even under preparer UID0. This is controlled private path
mutation, not an unprivileged execution, concurrent writer or OS containment test.

Expected stdout, raw returns, four state fields, callback order/arguments and
complete private inventory are authored separately. Quiet/late rendering failure
must retain exact diagnostic bytes; a clear obstruction retains saved input and
its private directory/link effects. Bash stderr matches its full source/target/
directory-error shape with a variable positive line number. Positive workflow
controls retain normal scan publication and unresolved verification behavior.

Twelve controls against accepted480 expose old lost diagnostics, missing clear
warnings or continued publication. Eight syntax-valid source mutations reject:
old helper, zero render/clear returns, erasure on failed render, unchecked scan/
verification helper returns and zero scan/verification status assignments.
The driver passes133scan/199verify/20diagnostic entries, plus seven complementary
normal suites with their existing separate boundaries. Reference changes are
limited to this helper and two ordinary post-pipeline call guards. The original
477-480 protections remain intact. No native acceptance or result schema changes.

Later unresolved-list display, individual reader failures, cache construction
and ordinary partial-copy effects retain their separate scopes. A helper's
nonempty-file predicate is not a complete filesystem-readability or descriptor
error protocol. These tests do not prove race resistance, global cleanup,
installed-state consistency or two-platform native composition/conformance.

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
