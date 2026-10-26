# Historical SBo target normalization writer audit564

`normalize_sbo_target_names_from_stream` validates nonempty target lines and
writes them to a temporary file, then emits sorted unique lines and returns the
sort status. Its historical `printf` status is unchecked. A failed temporary
write can therefore be hidden by successful sort, including when every write
failed. The557 package-name repair does not change this separate downstream loop.

The frozen driver is
[the target-normalizer audit](../../tests/reference/test-sbo-target-normalization-emission-audit.py).
It binds the exact accepted563 runtime SHA256
`57f814acf7640c8023f209c37c517eefa7c430567ddfd4266602e139070e199c`.
Changed runtime must be refused before any scenario. A PASS only confirms the
historical observations below; it is NOT a safety pass and must never be added
to a current-source safety selection after565 repair.

## Authored matrix and observations

Eight input profiles cross five writers, final-newline presence and direct or
conditional callers:160 cells. Profiles are empty, blank, one valid target,
unsorted duplicates, blank tail, invalid first/middle/last. Expected attempted
names and invalid outcomes are authored separately from the source parser.
Writers are normal, first quiet43, first late127, all quiet1 and all late43.
Quiet returns failure without bytes; late writes all requested bytes then fails.
The selected nonzero codes need not equal the eventual helper status.

| Observation | Cases |
| --- | ---: |
| Activated writer faults |80|
| Activated faults masked by successful sort |48|
| Activated faults with failure through a separate invalid name |32|
| Inactive supplied-fault controls |48|
| Normal writer controls |32|
| All invalid-record cases, overlapping the groups above |60|
| Multiple-fault cases, subset of80 |24|

There are120 failed emissions in the80 activated cases. All160 status/full
stdout/full stderr/ordered callback traces, selected local/IFS preservation and
finite private inventories are checked. For quiet valid cases, the sorted output
is the exact unique remainder; late valid cases can retain complete output yet
return success despite the supplied failure. Invalid names return1 before sort
and emit no target output; earlier writer faults do not gain a distinct status.
No invalid-name result is attributed to a repaired writer gate.

## Real and supplied boundaries

The real sourced normalizer/validator, private input/sentinel/temp files, mktemp,
sort-u and selected rm run. A Bash printf callback supplies only the selected
normalizer writer fault; its exact call vectors/names/attempt order are checked.
Allocation/sort/removal wrappers validate private paths and dispatch real tools.
Input0640/sentinel0600 and absence of leftover allocated temp files are checked;
trace0600 is separately checked and its allocation name is represented once as
`<TEMPORARY>` in report events. Full helper stdout/stderr are not normalized.
The guard list refuses known native/workflow/package/network/boot dispatch paths.
These callbacks, guards, UID, timeout and TemporaryDirectory are not OS containment
or independent source trust. The script sources trusted repository code.

This does not inject real disk exhaustion, partial real writes or failed reads,
allocation/sort/remove/publication/count failures. It does not establish all-fd/
all-global/owner/ACL/xattr/time/descendant cleanup, durability, atomic snapshots,
or arbitrary successful-output trust. It does not exercise installed/queue/merge/
owner/ABI/dry-run/full apply callers, entire stable outputs/JSON/NDJSON or native
Slackware15/current conformance. Each later composition needs separate evidence;
counts must not be added into a native acceptance total.

A source-guard mutation is expected to refuse; a proposed private repair is
expected to make this defective historical oracle refuse after a disclosed
private guard rebinding. Canonical source and frozen expectations stay unchanged.
Proposed565 repair must fail before sorting/publishing an incomplete normalized
set, remove the selected temporary, and preserve ordinary validation/sort semantics.
It grants no rollback/global-cleanup/native authority and is not implemented564.
