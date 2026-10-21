# Final SBo queue count failure

Run from the repository root:

```bash
python3 tests/reference/test-sbo-final-queue-count.py
python3 tests/reference/test-sbo-workflow.py
python3 tests/reference/test-sbo-queue-files.py
python3 tests/reference/test-elf-owner-composition.py
```

## Count before builder dispatch

`build_and_apply_sbo_queue` first merges its final dependency-ordered queue.
Previously, an unsuccessful `wc -l` could overwrite `TOTAL` and `TOTAL_EN_COLA`
with empty or partial stdout. An empty value produced an integer diagnostic
and the empty-queue message; a positive partial value could dispatch `sbopkg`
despite the failed count. Neither path necessarily marked the build failed.

The helper now captures the count in a local variable and checks its command
status before publishing either counter. A nonzero count status, including a
failed input redirection or partial numeric stdout, sets `SBO_BUILD_STATUS=1`
and `SBO_TARGET_SELECTION_ERROR="cannot count the final dependency-ordered SBo queue"`,
returns 1, and invokes neither the builder nor post-build ELF verification.
`TOTAL` and `TOTAL_EN_COLA` retain their previous values on this path. Those
values are previous state, not a count of the newly merged queue. The failed
count output is not used as a successful result.

The queue merge has already happened. This change does not roll it back or
restore a final file subsequently removed/replaced by another actor. Per-file
publication, concurrent path replacement, partial merge/move/cleanup effects,
ownership and whole-host state remain outside this guarantee. No atomic file
binding, validation of arbitrary successful count output, or exhaustive I/O
failure handling is claimed. Existing successful count/empty-queue, builder
status and supplied post-build verification policies are unchanged.

## Private regression scope

The 288 cases cross three independently authored queues (empty, one target,
ordered duplicate/extra targets), eight fault selections, two broken-list
states, three inert builder statuses (0/7/20), and configured/unset option records.
Options and final order are checked as exact bytes. The real final-queue merge,
parsers, option normalization, private temporary files, redirections and ordinary
coreutils run. No inspected object is executed. `sbopkg` is an inert callback;
post-build verification is supplied and returns 19 without native work. The
test asserts raw return/status fields, both totals, selected unrelated fields,
caller IFS/outer scalars, exact stdout, expected diagnostics, ordered command
vectors and the complete private file/directory inventory except its event log.

Supplied `wc` failures return 1/43/127 or print `42` then return 43. Successful
counting uses installed `wc` on the private queue. A real missing-input redirection
fails before the count callback is entered; a real directory input reaches `wc`
and fails while reading. A supplied merge failure is an earlier inactive-count
control. Builder/recheck selections are inactive when the count fails or the
queue is empty, and do not count as exercised native failures. Diagnostics are
checked in the C locale; they are not an assertion about every platform's wording.
Named guards are not OS containment. Main, root-environment setup, configuration,
logging, installed package/build/boot workflows and native acceptance do not run.
Preparer UID 0 does not establish actual unprivileged or Slackware conformance.

Preparation preserves the first baseline rejection and a separate complete
baseline matrix: 72 inactive/normal cases pass, 216 count-failure cases reject
the old source. These are driver projections, not native acceptance counts.
Six syntax-valid private source variants test lost build/error status, changed
old totals, a successful raw failure return, masked command status and a leaked
caller variable. Their selected rejections and hashes are retained separately.
The normal selection also includes fourteen complementary commands; their
individual outputs retain each driver's existing real/supplied scope. The
historical 66-command integration and historical mutation matrices are not
claimed rerun by this focused step.

## Continuation and acceptance limits

The complete supplied actual499 return and later separate review confirmed
STATIC repository pause499 at HEAD/local origin
`11139b0f59e1151721396c4a7a32748482d0783e`, tree
`a7090a69611709cb1ca95760c2ea64e86b86298a`. Its prepared source documentation
retains its historical pending wording; the external confirmation is distinct.
The new user request opens bounded repository block500-507, with reserves
508-511 only if needed for the requested 8-12 steps. Prepared500 is the first
candidate and awaits the complete actual application/tests/commit/push/clean
refs/source-mode-tree return. No new pause is confirmed here.

Plan subsequent work from observed failures and acceptance returns: selected
SBo queue construction/count and private failure propagation, then integration
and closing source/guidance review. Reserve steps are not automatic work. Final
actual acceptance must precede separate reading of every whole inherited
condition/header and every exact nested original body, together with every new
effect, obligation, cleanup and observation limit, before a scoped pause can be
assessed. Counts, hashes, summaries and earlier reviews do not replace it.

Keep the incomplete saved nested491 binary archive and unknown-origin scratch
prefix observations open with their exact historical evidence; this step repairs
neither history nor unknown causes. GNU awk original497 failure, its distinct
diagnostic-oracle failure, repair, transport/capture failures and all older
qualifications remain. ELF initial-scan inspection-error omission/raw 0, first
missing/error short circuit, partial publication/cleanup and input races remain.
All original native member criteria, five acceptance families/20 scenarios,
13 open findings and 16 gaps persist. Phase1/kernel incomplete; A/R/D unselected;
native evidence/live bindings null; host unobserved, global closure false.
Separate option decision, independent specification/impact acceptance, explicit
migration if norms change, ACTUAL composition binding, independent safe ACTUAL
WHOLE review, fresh bounded native grant and own-platform conformance remain due.
This repository work grants no native authority or historical binding reuse.
