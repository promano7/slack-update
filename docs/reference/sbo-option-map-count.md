# SBo option-map count failure

Run from the repository root:

```bash
python3 tests/reference/test-sbo-option-map-count.py
python3 tests/reference/test-sbo-abi-queue-count.py
python3 tests/reference/test-sbo-core-queue-count.py
python3 tests/reference/test-sbo-final-queue-count.py
```

## Failure after option-map publication

`collect_sbo_option_records_from_sources` initializes its count to zero, collects
and normalizes queue/override options, and publishes the selected map. Previously,
a failed final `wc` could replace the count with empty or partial stdout; the
subsequent successful temporary-file cleanup could hide the error with return0.
The real core coordinator and its following ABI gate could then proceed.

Capture the count locally and check status before assigning `SBO_OPTION_RECORD_COUNT`.
On nonzero status, attempt cleanup of the five remaining temporary files, set
`SBO_TARGET_SELECTION_ERROR="cannot count normalized SBo option map"` and return1.
The count keeps its initialized zero, not the caller's previous count. The real
core coordinator propagates failure without counting its queue; its real caller
then blocks the supplied ABI stage. Existing successful behavior is unchanged.

The map has already been published. This change does not restore the previous
destination or undo external replacement/removal. Cleanup failures, other earlier
allocation/read/publication paths, concurrent input changes, special files and
arbitrary successful count output remain outside the demonstrated guarantee.
No atomic input binding, rollback or whole-host cleanup is claimed.

## Private regression and controls

The 168 cases cross four authored profiles (empty, queue options, override, merged
options), seven fault selections, direct collection/real core/real gate invocation,
and existing/absent destination. Real queue-file enumeration, parsing, graph order,
option normalization/override selection, temporary files, sorting, move, cleanup,
redirection and ordinary count run on private files. The collector is renamed only
to record entry/exit and select count faults; its original body remains the real
source. The following ABI callback is supplied and writes a private file on entry.

Count1/43/127 and numeric stdout42 followed by43 are supplied failures. A real
publication wrapper replaces the completed private map with an absent path or a
directory before counting; these produce real Bash redirection/wc errors. Missing
input prevents the count callback. Count errors must block the core-count and ABI
callbacks; normal selections retain their exact ordered vectors. The test checks
raw return, selected counts/error/status fields, exact stdout/C-locale diagnostics,
caller IFS/outer scalars and entire private inventory except events. Normal cleanup
leaves no extra private files in these cases; this does not prove failed cleanup,
historical cleanup, timestamp/owner/mode/ACL/xattr/all-descriptor or host absence.

The separate old-source matrix passes24 normal cases and rejects144 count-failure
cases. First count rejection is retained separately. Six syntax-valid private
variants lose the error, publish failed output as a count, return success, mask
command status, omit failure cleanup or leak a scalar; selected cases reject them.
Eighteen named normal commands pass separately, including the unchanged seventeen
from502. No historical66-suite or historical mutation-matrix rerun claimed.
Named guards are not OS containment; preparer UID0 is not actual unprivileged/native
Slackware conformance. No normal installed package/build/ELF/boot/service workload runs.

## Step503 repair1: Bash diagnostic prefix

The original503 supplied run stopped at its first test, at
`empty/missing/options/absent-destination`. Raw return, stdout and all selected
state bytes matched the expected failure. Bash labeled the real missing-input
diagnostic `sbo-option-count-test: line 110:`; the original oracle allowed only
the reference source path or `environment`. Preserve that failed return. Later
tests, git add/commit/push and final capture did not run; actual503 is not accepted.

Repair1 accepts exactly those three known prefixes for this diagnostic. It still
requires a positive decimal line number, the exact private missing path, exact
C-locale missing-file message, final newline and no extra stderr. Thirteen pure
diagnostic controls accept the three prefixes and reject wrong labels/paths,
zero/negative/nondecimal line numbers, another error, absent newline, additional
diagnostics and prefixed junk. The observed launcher prefix is supplied evidence,
not an independently observed Bash-version explanation or native acceptance.

All168 behavioral cases remain unchanged in scope and pass alongside13 oracle
controls. All18 named normal commands and the six updated-driver source variants
are checked separately. Runtime source remains byte-identical to original503:
SHA256 `07cddef43ab00bd288710894f3a755b330bd424cafd31efca899e0ec25f89262`.
No native/package/option policy or result contract changes. Original prepared
normal records are not relabeled as the repaired result or as a successful user run.

The repair requires the exact original503 applied worktree on accepted502 and an
unchanged base index. It changes only driver/documentation; the full original
unaccepted overlay and mapped members remain historical. Per-file replacements
are not a transaction; retain any partial application failure. This repairs the
same pending503 and counts no additional accepted step. Complete repaired actual
application/tests/commit/push/clean-source return is still due before advancing.

## Actual502 and continuation

Complete supplied actual502 passes all17 vectors/outputs, five-path scope,332-add/
1-delete commit and reported push. HEAD/local origin
`09f2d62ad00f8495634bad08a1e0e2f09030b48b`, parent
`ee050becb186f345e42c8cfd6aa5c9929a6567bb`, tree
`b4912e2e5bb77343adb2a45ed7da1026cbb3018c`, policy SHA256
`cb0faf0a05f0fa649158f64321bb749b9209c2faa667aa69900a645c0ad16d06`
agree with its clean tracked-source/mode report. Supplied inline reconstruction
is not original terminal bytes or independent terminal/GitHub/native capture.

The historical502 runner prints BEGIN/END TESTS501 while running the exact correct
17 commands; preserve that label defect and actual return unchanged. Its member-map
scope text also says original500, although exact filename/hash/2954members bind501.
These are descriptive defects, not replacement evidence for source or commands.
The503 runner and member-map descriptions use their correct step/predecessor;
delivery controls explicitly check both markers and exact18 vectors.

Three actual steps500-502 accepted in bounded500-507, reserves508-511 only if needed.
Candidate503 awaits complete actual application/tests/commit/push/clean refs/source
return. Last confirmed STATIC pause499; no new pause. Final actual acceptance must
precede separate reading of every whole inherited header/condition/exact nested
original plus all new effects/obligations/cleanup/limits before pause assessment.
Counts/hashes/summaries/earlier reviews cannot replace that reading.

Incomplete nested491 binary history, unknown-origin prefixes and all earlier
authoring/runtime/packaging/transport/capture qualifications remain. No unknown
cause or history repair inferred. ELF initial inspection2 omission/raw0, short
circuit, partial publication/count/cleanup/read/input races and whole-state limits
persist. Phase1/kernel incomplete;13 open findings/16 gaps/five families20 native
scenarios/full original criteria remain. A/R/D unselected/proposed repairs inactive;
native evidence/live bindings null; host unobserved/global closure false. Original
separate decision/independent acceptance/migration if needed/ACTUAL composition/
independent safe ACTUAL WHOLE review/fresh bounded native grant/OWN-platform
conformance gates remain; no old/consumed right or live binding renewed.
