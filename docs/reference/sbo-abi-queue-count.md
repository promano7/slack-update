# ABI SBo target queue count failure

Run from the repository root:

```bash
python3 tests/reference/test-sbo-abi-queue-count.py
python3 tests/reference/test-sbo-core-queue-count.py
python3 tests/reference/test-sbo-final-queue-count.py
python3 tests/reference/test-sbo-workflow.py
```

## Count after selection

With `ABI_TRIGGER=1`, `add_abi_rebuild_targets` collects installed SBo targets
before counting the resulting extra queue. Previously, a failed `wc` could erase
`TOTAL_EXTRA` or replace it with partial stdout, print a success-looking count
and return 0 through `build_sbo_target_queues_after_synchronization`.

Capture the count in a local variable and check its status before updating
`TOTAL_EXTRA`. A nonzero count status now sets
`SBO_TARGET_SELECTION_ERROR="cannot count the ABI SBo target queue"`, prints the
error and returns 1. The prior total remains unchanged and is not a count of the
newly selected targets. The real caller propagates this failure. Build status,
caller target-selection status and successful-count policy remain unchanged.

The target queue has already been collected/published. No rollback, atomic
opened-file binding, race/special-file guarantee or validation of arbitrary
successful count output is claimed. Earlier collector errors remain failures.
For other trigger values, the existing `touch` branch is unchanged. Its failure
handling and timestamp semantics are not repaired or fully characterized here.
Core/options removal/count and whole-workflow cleanup limits remain as documented.

## Private regression and discrimination

The 288 cases cross three authored package inventories, eight fault selections,
trigger values 0/1/2, direct helper versus real caller gate, and two previous totals.
The real installed-target collector, package parser/build-tag filter, normalization,
private temporary files, `find`, sort, move, cleanup and count run. Native-tag
decoys are ignored; duplicate versions collapse and hyphenated names survive in
the exact expected sorted target bytes. The database consists of private text
manifests. No installed package database is read or modified.

Count statuses 1/43/127 and numeric stdout `42` followed by status43 are supplied.
Real missing input fails before entering the count callback; real directory input
fails in `wc`. The missing/directory projections replace the completed private
queue after collection. An earlier supplied collector error and trigger0/2 cases
are controls with inactive count faults. The real caller uses a supplied successful
core stage; no whole core/ABI/build workflow conformance is inferred.

Assert raw return, selected totals/status/error fields, exact stdout/diagnostics,
ordered collector/enumeration/count/touch vectors, caller IFS/outer scalars and
the complete private inventory except events. Timestamps, owner/mode/ACL/xattr,
all globals/descriptors and whole host are not surveyed. C-locale GNU diagnostic
projections are not assertions about all tool versions. Named guards are not OS
containment. Main/environment/configuration/logging, normal installed update/build/
boot/service actions and native acceptance do not run. UID0 preparation is not
actual unprivileged or native Slackware conformance.

The separate old-source matrix passes216 normal/inactive/earlier-failure controls
and rejects72 count-failure cases. Preserve the first count rejection separately.
Six syntax-valid private variants lose the error, overwrite the previous total,
return success on count failure, mask count status, mask the caller failure or
leak the local scalar; selected cases reject them. Before runtime modification,
the first authored oracle used an actual newline instead of literal backslash-n
for the expected `find -printf` argument. Its failure/initial driver and the
test-only correction remain distinct from the old-source count defect. Do not
attribute the oracle rejection to runtime or substitute it for the corrected matrix.

Seventeen normal commands pass separately, including this driver and the unchanged
sixteen-command501 selection. Retain individual scopes; no heterogeneous native
count, historical66-suite or historical mutation-matrix rerun is claimed.

## Acceptance and continuation

Complete supplied actual501 passes all16 commands, five-path scope,351-add/1-delete
commit and reported push. HEAD/local origin
`ee050becb186f345e42c8cfd6aa5c9929a6567bb`, parent
`e719255a5ddc7596f53192a0a7fe37cc185c51f6`, tree
`19d444c109ff0372b9d52ae0285b5effb1a4601d`, policy SHA256
`0d19dcdb00e1fd7f6dacbc8ccb4b92c18750638162544b3989b8f57fab56d198`
agree with its clean tracked source/mode report. Inline supplied transcription and
reconstructed report are not original terminal bytes or independent capture.

Two actual steps500-501 accepted in bounded500-507; reserves508-511 only if needed.
Candidate502 awaits complete actual application/tests/commit/push/clean refs/source
return. Last confirmed STATIC pause499; no new pause. At final block close accept
the complete final actual return first, then separately read every whole inherited
condition/header/exact nested original and all new effects/obligations/cleanup/
limits before pause assessment. Counts/hashes/summaries do not replace that reading.

Preserve incomplete nested491 binary history, unknown-origin prefix observations,
all packaging/authoring failures and earlier qualifications. No unknown cause or
binary repair is inferred. ELF initial inspection2 omission/raw0, short circuit,
partial publication/count/cleanup/input races and whole-state limits persist.
Phase1/kernel incomplete;13 open findings/16 gaps/five families20 native scenarios/
original criteria remain. A/R/D unselected/proposed repairs inactive; native
evidence/live bindings null; host unobserved/global closure false. Original separate
option decision, independent specification/impact acceptance, migration if norms
change, ACTUAL composition, independent safe ACTUAL WHOLE review, fresh bounded
native grant and OWN-platform conformance remain due. No native authority or
historical/consumed live binding is reused, revived or renewed by this step.
