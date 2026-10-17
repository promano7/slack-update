# Apply early-exit and partial-update sequencing regression

Run from the repository root:

```bash
python3 tests/reference/test-apply-early-exits.py
python3 tests/reference/test-partial-update-policy.py
python3 tests/reference/test-apply-json-result.py
python3 tests/reference/test-main-completion.py
bash tests/reference/test-error-exit-codes.sh
```

The independent standard-library driver calls the real `run_apply_workflow`
prefix, real action-failure classifier and real secondary-module assignment
helper. Snapshot, boot probe, ownership-policy preparation/restoration, package
operation, events and summary are callbacks. The first optional-module probe
is a controlled checkpoint that exits its private Bash process with code 86.
No secondary operation is allowed beyond that checkpoint in this driver.

There are 870 scenarios and 1740 workflow entries. Six scenarios supply initial
snapshot or ownership-preparation returns 1, 23 and 255. The other 864 cross
216 package-result triples with restoration success/failure and final-snapshot
success/failure. Each raw package component is -1, 0, 20, 21, 42 or 255.

## Early gates and ordering

An invalid initial snapshot must emit its exact failure action/module events,
print the authored diagnostic and summary, then return 1 before boot probing,
policy preparation, package operations, restoration or final capture. An
ownership-preparation failure must stop before package operations while retaining
the already supplied initial-snapshot result. Supplied nonstandard failure returns
are normalized to the workflow's existing return 1.

After package callbacks, restoration must precede the final snapshot. Both are
attempted after failed package results. Restoration failure changes the effective
module/action result to failure 1. Final-snapshot failure then returns 1 before
the shared secondary-block assignment point; the initial block flag is preserved
in that earlier-return branch. A successful final snapshot retains its supplied
count even after package or restoration failure.

The complete ordered callback/event argument vectors are checked, including
identifiers, messages, states, record counts and raw event codes. Event success
does not imply a callback's real operation succeeded on a native target.

## Classification, block assignments and positive checkpoint

The authored priority table selects the first failed update/install-new/upgrade-all
raw result for the package event. Restoration failure can replace that effective
code with 1, while the three stored raw package results remain unchanged.
With a valid final snapshot, a positive effective error must run the real blocker:
all five states/reasons/run flags, shared flag/reason and preserved modes are
asserted. No optional activation or secondary command may follow.

Of the 870 cases, 852 return early and eighteen reach the controlled continuation
checkpoint. The latter prove prefix admission to that call only. Their process
exit 86 is a deliberate test marker, not a successful complete apply result or
an application exit code. Secondary orchestration and final completion require
their own separate coverage.

## Repetition, state and actual limits

Each case runs in two private Bash processes with freshly seeded state. The
first gives event, boot-probe, package-function and summary callbacks return 0;
the second gives them 19. Those auxiliary returns must not replace the tested
prefix decision, which uses its designated state fields and explicit gates.
Snapshot/preparation/restoration returns retain their independently supplied
values. Exact stdout, stderr, selected global-state packets, IFS and private
trace inventory are checked. On normal early return, outer variables named
action_exit and slackware_state must remain untouched by local workflow state.

No normal initializer, main, installed snapshot/database, GenInitrd file, package
command, native boot action, discovery, network, clock or filesystem utility runs.
The private driver writes only its callback trace. Some supplied module-mode/
state pairs isolate ordering and do not assert native reachability. Event and
summary invocation does not prove serialization, transport or real rendering.
Known-call guards are not OS containment; review new calls before changed source.

Current shell code-20 projection changes no original native requirement:
install-new 20 needs empty AND no-effect; upgrade 20 remains failure. No option,
migration, actual native composition, independent whole-run safety review,
fresh bounded native grant or own-platform conformance is accepted by this test.
Historical criteria, findings and unknown global host state remain unchanged.
