# Core SBo queue count failure

Run from the repository root:

```bash
python3 tests/reference/test-sbo-core-queue-count.py
python3 tests/reference/test-sbo-final-queue-count.py
python3 tests/reference/test-sbo-workflow.py
python3 tests/reference/test-sbo-queue-files.py
```

## Count failure and the next stage

`build_sbo_core_queue` removes the previous private queue files, collects the
ordered targets, and collects build options before counting the core queue.
Previously, a failed count could overwrite `TOTAL_CORE` with empty or partial
stdout, print a success-looking count and return 0. The real
`build_sbo_target_queues_after_synchronization` gate could then run ABI selection.

Capture the count locally and check command status before publishing `TOTAL_CORE`.
A nonzero status now sets `SBO_TARGET_SELECTION_ERROR="cannot count the core SBo queue"`,
prints the error and returns 1. It preserves the previous `TOTAL_CORE`; that old
value does not describe the newly collected queue. The existing caller's `&&`
then blocks the following ABI-target stage. This helper does not set build status
or the caller's target-selection status; those remain separate responsibilities.
Successful count behavior and all earlier resolve/collection failures are unchanged.

Removal/collection already happened. There is no rollback of those files or
of the option count. No atomic input binding, race/permission/special-file proof,
arbitrary successful-output validation, or universal failure-handling guarantee
follows. Unchecked removal and option-map count failure projections remain for
later bounded review. This step does not change the initial ELF scan's
inspection-error omission/raw-0 policy or post-build verification policy.

## Private regression scope

The 240 authored cases cross three core/option payloads (empty, one, ordered
multiple), ten fault selections, direct helper versus real gate invocation,
configured versus supplied-resolved queue directory, and two previous core totals.
The real core coordinator and gate run. The target and option collectors supply
authored bytes/statuses; directory resolution and the subsequent ABI stage are
also supplied. The ABI callback records entry and writes a private target file;
its absence after a core count error is checked, not assumed from output alone.
These are not native collector/ABI/build compositions.

Real Bash redirections, private removal/files/directories and ordinary `wc` run.
Count failures 1/43/127 and numeric partial stdout `42` followed by 43 are supplied.
A real missing-file redirection fails before the count callback; a real directory
input fails in `wc`. Earlier resolve/target/options failures and inactive fault
selections retain their separate scopes. The test checks exact stdout, raw return,
selected status/counter fields, error, ordered vectors, caller IFS/outer scalars,
queue-source fallback and the entire private inventory except its event file.
It does not survey every global, descriptor, ownership, ACL, xattr or whole host.
Diagnostics are checked in the C locale under the documented GNU-tool projection.

The old source's separate matrix passes 96 normal/earlier-failure controls and
rejects 144 count-failure cases. Preserve the first observed rejection separately.
Six syntax-valid private source variants are rejected: lost error, overwritten
old total, successful raw failure return, masked count status, lost caller `&&`
and a leaked count variable. A normal source run and fifteen complementary named
commands retain their own recorded output; the complementary selection includes
the unchanged 288-case step500 driver. No historical 66-suite or historical mutation
matrix rerun is claimed. Named guards are not OS containment. Preparer UID 0
does not establish actual unprivileged or native Slackware acceptance. No normal
installed package, SBo builder, ELF object execution, boot or service workload runs.

## Acceptance and continuation

Complete supplied actual500 passes all fifteen commands, the five-path scope,
338-add/2-delete commit and reported push. HEAD/local origin is
`e719255a5ddc7596f53192a0a7fe37cc185c51f6`, parent
`11139b0f59e1151721396c4a7a32748482d0783e`, tree
`a04a51a2bd17dc78dd3e37e6cb69579266418328`, policy SHA256
`f6d8d7388ded24d7ec6002d0d69b8ed78195eee65e2953a4c65a0ae5f462073f`.
The supplied clean source/mode report agrees. Retained inline transcription and
reconstructed report are not original terminal bytes or independent capture.

One actual step500 accepted in bounded500-507, reserve508-511 only if required.
Candidate501 awaits complete actual application/tests/commit/push/clean refs/
source-mode-tree return. Last confirmed STATIC pause499; no new pause. Final
actual acceptance must precede separate reading of every whole inherited header,
condition and exact nested original body, plus all new effects/obligations/cleanup/
limits before any new pause assessment. Counts/hashes/summaries do not replace it.

Incomplete saved nested491 binary history, unknown-origin scratch prefixes,
packaging rejections and every earlier failure/repair/transport/capture qualification
remain open and unchanged. Partial publication/count/cleanup/read/input races and
whole-state limits persist. Phase1/kernel incomplete; 13 open findings/16 gaps/
five families20 native scenarios/full original criteria persist; A/R/D unselected,
proposed repairs inactive, native evidence/live bindings null, host unobserved,
global closure false. Separate option decision, independent specification/impact
acceptance, migration if norms change, ACTUAL composition binding, independent
safe ACTUAL WHOLE review, fresh bounded native grant and OWN-platform conformance
remain due. This step grants no native authority or old/consumed binding reuse.
