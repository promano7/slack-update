# Dry-run workflow regression

Run from the repository root:

```bash
python3 tests/reference/test-dry-run-workflow.py
python3 tests/reference/test-dry-run-json-result.py
python3 tests/reference/test-check-workflow.py
python3 tests/reference/test-main-completion.py
bash tests/reference/test-error-exit-codes.sh
```

The standard-library Python driver sources the reference in private Bash
processes and calls the real `run_dry_run_workflow`. It crosses five supplied
check return/raw-code pairs, five SBo inspection outcomes, five ELF inspection
outcomes and an empty or nonempty option-record path: 250 scenarios. Each runs
twice, for 500 workflow calls, reseeding stale state and five private files.

## Ordered calls and result precedence

The check pairs are 0/0, 0/100, 1/69, 23/42 and 255/127. Its raw code and reason
are supplied by a callback. Check event state follows the function return,
while the raw event status follows `CHECK_STATUS`. With no later inspection
failure the workflow preserves the check return, including 23 and 255. An
SBo or ELF inspection failure replaces it with 1. ELF findings alone produce
a warning event without replacing the check result.

Every scenario checks exact ordered callback argument vectors: Slackware
probe, environment inspection, optional probing and activation output, SBo
inspection, ELF inspection and plan rendering, with their start/completion
events. A failed check does not bypass later planning. A failed queue callback
must bypass candidate collection. A failed SBo inspection does not bypass ELF
inspection or rendering. Inapplicable modules skip their inspection callbacks.

The second call gives every event, environment-inspection, optional-probe,
activation-output and plan callback return 19. Those returns do not replace
the current workflow result or prevent its subsequent calls. This isolates
existing orchestration behavior; it does not endorse every authored failure
combination as reachable or prescribe new error-handling semantics.

## Private files and selected state

The SBo rows are disabled, unavailable, successful, queue failure and candidate
failure. Before a runnable queue inspection, selection status must reset to 0.
Failures set it to 1 and clear core queues, optional option records, ABI
candidates and their selected counts. Inapplicable SBo clears these plus extra
queues and the broken-SBo count, and assigns the supplied fallback directory.
Its selection status remains the seeded value; this test does not claim a
reset in that branch. Successful callbacks supply authored counts and bytes.

The ELF rows are disabled, unavailable, clean, broken and scan failure. The
workflow clears the private broken-object file and count when inapplicable.
For runnable rows the callback supplies files and counts, including deliberately
independent counts and bytes; scan internals and count/file consistency are
outside this test. A later supplied ELF inspection can populate extra queues
after SBo was skipped or failed. Exact final private file bytes and selected
counts must reflect that order.

Both calls are checked through output packets before reseeding. Final file
bytes, exact private directory inventory, empty stderr, selected state and IFS
are also asserted. The unused seeded option file must remain unchanged when
the configured option-record path is empty. Paths include spaces.

## Scope

Only orchestration and its private redirections are real here. Check, tools,
environment/module probes, queue/candidate/ELF inspections, event emitters and
the human plan renderer are callbacks. No main, normal initializer, package
database, mirror, network request, installed tool, native boot action or clock
is invoked by this driver. Real helper, renderer, JSON/NDJSON and main tests
retain their separate scopes; event invocation does not prove serialization
or transport. Supplied flags/statuses/counts do not establish native reachability.

Known excluded entry points abort, but these guards are not an OS sandbox.
Review new source calls before testing changed code. This repository regression
does not accept native conformance, contract options, migration or operational
execution rights. Original native criteria, findings, unknown host state and
separate composition/review/grant/conformance obligations remain unchanged.
