# Historical SBo package-name emission audit, step556

## Defect and frozen source

`package_names_with_build_suffix_from_stream` emits each selected package name
with `printf` but returns only the last loop iteration's status. A writer failure
can be masked by a later successful emission or a later skipped record. `pipefail`
cannot detect a failure that this producer has already converted into status0.
The shared helper feeds installed-target selection and broken-object owner
mapping; this direct audit does not establish either caller's composed behavior.

The exact historical555 runtime SHA256 is
`52015a485e206993af40a543e0e938052c9e1efa7e5155c475954abf2378c323`.
The driver refuses any different bytes before sourcing or observing the runtime.
Runtime, every existing test/support/fixture and the101-command integration plan
remain byte unchanged in556. The frozen audit must remain excluded from future
current safety integration once the runtime changes.

## Finite observation matrix

Run `python3 tests/reference/test-sbo-package-name-emission-audit.py`.
An optional `--report /absolute/report.json` retains each complete output/status.

| Axis | Values |
| --- | --- |
| Selected failing emission | First, middle, last of three selected names |
| Writer | Normal; quiet status43; full bytes then status43 |
| Following input | None; native package record; malformed record |
| Last input newline | Present; absent |
| Caller context | Direct; shell conditional |

The108 observations check complete stdout, exact supplied stderr event trace,
producer status, all three attempted selected emissions and selected caller
locals/IFS. There are72 activated failures,64 masked failures, eight surfaced
status43 failures and36 normal controls. Quiet failure omits the selected name;
late failure retains its complete bytes. Both must eventually invalidate a
repaired producer regardless of subsequent records. Status43 here is a supplied
writer status, not a stable CLI result code.

The source helper/parser and shell loop execute for real. Writer failures are
supplied by an exact caller/vector-checked shell function. Test controls prohibit
the named installed-reader/owner/workflow/native entry points; no package database
is read. These controls are not OS containment or independent source trust.
This does not cover partial writes, failed reads, real full disks, pipe closure,
all globals/descriptors, concurrency, durability, cleanup, installed tools,
whole JSON/NDJSON schemas, platform conformance or any native recovery guarantee.

## Proposed next step and retained limits

Step557 should retain every selected emission failure until stream completion,
then return nonzero if any failed. Preserve selected records, order, parser/tag
rules, ordinary skips, duplicates and complete processing of later input.
Author a separate current safety driver; do not weaken or rewrite this frozen
historical characterization. Installed selection, owner mapping, ABI/dry-run
composition and end integration remain later work, subject to actual results.

Step556 is pending PC acceptance and creates no new pause. The inherited555
qualified STATIC pause and all provenance/recording/history/native qualifications
remain as imported; this document does not claim their fresh whole review.
