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
names. Bash, `find`, `readlink`, `od`, `tr`, `sort`, `cp`, `wc` and `sed` run on owned
private fixtures. Fake ELF-prefix bytes are not complete native executables.

Cache refresh and dependency classification are supplied callbacks. The cache
callback writes one supplied private cache line or reports a selected failure; it does
not call `/sbin/ldconfig`. The classifier returns authored 0/1/2 results, plus an
explicit out-of-contract 23 case to isolate the coordinator's fallback branch.
The added late find/sort failures first emit their real private command output
and then return 43; quiet sort still drains its input. These callbacks do not
establish installed library availability or reachability
of every supplied state. No inspected object is deliberately invoked as a command.

## Independently authored checks

| Boundary | Entries | Covered behavior |
| --- | ---: | --- |
| Initial scan | 82 | Five private layouts across eight normal/fault profiles and two diagnostic seeds, plus two real private missing-root cases |
| Post-build verification | 96 | Twelve input-list profiles, normal/cache/sort/copy outcomes and two diagnostic seeds |
| Diagnostic rendering | 4 | Empty, one-line, multiline and unterminated messages |

Expected stdout/stderr bytes (including the real GNU find missing-root diagnostic
under LC_ALL=C), raw returns, four selected state fields, callback
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
  which have emitted staging data. See the step 477 handling below. A quiet copy
  failure can still preserve the old list while reporting its old count/status 0;
  count failure still uses the zero fallback. Those remaining unchecked status
  projections are limitations, not native success or approved error handling.
- Empty or missing post-build lists return zero early, retaining old diagnostics,
  cache count and still-broken file. Cache failure after a nonempty list preserves
  that list but clears the private still-broken staging file and reports failure.
- Post-build verification retains unresolved, unreadable-existing and dangling
  entries, but drops vanished paths and healthy entries. Status 2 retains an
  object and reports a diagnostic; supplied status 23 is outside the real reader's
  0/1/2 contract and is not treated as a retained inspection error by the wrapper.
- Duplicate results normalize; repeated input errors retain repeated diagnostics.
  A nonempty unterminated final record is ignored by the current `read` loop.
  That deliberately malformed direct list can consequently be cleared as passing;
  the normal scan producer emits terminated records. No input contract is amended.
- A quiet sort failure in verification can produce an empty staging list and a
  passing status. Copy failure on the warning branch still returns failure, but
  can leave the previous input list intact. No atomic transaction or native
  recovery guarantee follows from these selected private observations.

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
post-build verification sort/copy behavior are outside this repair.

The original 60/96/4 matrix is retained in the predecessor delivery. The updated
matrix fails against that exact old implementation on its first quiet-find
control: expected raw/status 1 with preserved state, observed raw/status 0 with
empty published result. The repaired source passes 82 scan, 96 verification and
four diagnostic entries. Scan coverage adds late real-output-then-43 faults for
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
execution. The remaining copy/count/recheck failure projections stay open.

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
