# Partial-update policy helper regression

Run from the repository root:

```bash
python3 tests/reference/test-partial-update-policy.py
python3 tests/reference/test-result-precedence.py
python3 tests/reference/test-apply-json-result.py
python3 tests/reference/test-main-completion.py
bash tests/reference/test-error-exit-codes.sh
```

The independent standard-library driver sources the reference in private Bash
processes and calls two real in-memory helpers: `slackpkg_apply_action_failed`
and `block_secondary_modules_after_partial_slackware_update`. There are 1044
scenarios and 2088 selected entry calls: 801 classifier cases and 243 blocker
cases, each called twice without reseeding between its calls.

## Current classifier projection

For each of update, install-new and upgrade-all, the test supplies every raw
integer code from 0 through 255 plus -1. Twelve rows supply four unknown action
strings with -1, 0 and 20. Eighteen more supply literal noncanonical numeric
strings: `00`, `020`, `-01`, `+0`, leading-space zero and trailing-space zero.
Expected returns are authored data, with no source parsing or output capture.

The function's return convention is inverted relative to an operation result:
0 means the helper classifies the supplied action as failed; 1 means it does
not. Current exact matching treats update 0, install-new 0/20 and upgrade-all
0/20 as nonfailure. The -1 suffix matches even unknown actions. Other unknown
actions and noncanonical zero strings use the failure branch. These observations
describe this shell-reference helper, not an argument validator or native meaning
for arbitrary raw input. No shell command is run with the supplied action/code.

All selected surrounding state must remain unchanged, including raw action
codes, module configuration/activation fields, capability flags, snapshot fields,
queue/scan status, outer variables named action/status and IFS. The second call
must return the same answer without accumulating side effects.

## Secondary-module state blocking

All 243 combinations of disabled, enabled and auto modes across five modules
are supplied with varied activation states, reasons and run flags. The helper
must assign the exact shared blocking flag/reason and all five blocked states,
matching reasons and zero run flags, regardless of the configured modes.

Configured modes, availability/capability flags, raw package results, snapshot
counts/validity, queue/scan results and unrelated selected variables must survive.
The immediate second call is not reseeded: it checks idempotency of the complete
assignment result. Exact stdout state packets, empty stderr and an empty private
working directory are required. The selected helpers perform no file operations.

Calling this assignment helper does not prove that a workflow establishes the
partial-update condition first, invokes the helper at the right point or skips
every secondary action. That sequencing remains a separate workflow boundary.
The existing shell partial-update regression retains its original scope and is
not invoked by this driver. JSON projection is covered separately.

## Native and execution boundaries

Neither helper issues main, runtime initialization, events, summaries, a workflow,
package command, discovery, filesystem utility, network request, clock or boot
operation here. Known excluded entry points abort, but guards are not OS
containment and supplied state is not a native reachability claim.

Observing the reference's treatment of code 20 changes no original native
criterion: install-new 20 still requires empty AND no-effect, and upgrade 20
remains failure under the preserved native contract. Original findings, options,
semantic/migration decisions, actual composition, independent safe whole-run
review, separate fresh bounded native grant and own-platform conformance remain
due. These private state tests establish no native right, compatibility or
whole-host absence/cleanup/safety verdict.
