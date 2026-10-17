# Check workflow regression

Run from the repository root:

```bash
python3 tests/reference/test-check-workflow.py
python3 tests/reference/test-check-json-result.py
python3 tests/reference/test-main-completion.py
bash tests/reference/test-error-exit-codes.sh
```

The Python standard-library driver sources the reference in private Bash
processes and calls the real `run_check_workflow`. Twelve scenarios also call
its real `check_slackware_updates`; twenty supply that helper's result to
isolate orchestration. There are 32 scenarios and 64 workflow calls.

## Check command outcomes

The twelve integrated scenarios model command discovery, mirror probing and
slackpkg execution. They cover a missing command; mirror rejection with an
explicit, empty or unset diagnostic; successful raw codes 0 and 100; and raw
codes 1, 2, 20, 42, 127 and 255 that the check helper treats as failures.

The assertions distinguish function return from raw status: missing command
sets 127, mirror failure sets 69, and command outcomes preserve their raw code.
Failures return 1; both successful codes return 0. Diagnostic state is poisoned
before each call and must reset, including successful runs after stale errors.
An empty or unset mirror diagnostic must select the authored fallback message.

Exact callback traces require command lookup before mirror probing and mirror
success before slackpkg. Missing commands and rejected mirrors must bypass
later callbacks. The slackpkg callback accepts only the exact three arguments
`-batch=on -default_answer=n check-updates`. Human output and diagnostic text
are checked against authored expectations, not captured reference output.

## Orchestration and independent result fields

Twenty supplied-helper scenarios cross function returns 0, 1, 23 and 255 with
raw statuses 0, 100, 42, 69 and 127. These deliberately include inconsistent
pairs; they isolate which field drives each decision and do not assert that
every pair is reachable through the real helper.

Every scenario requires module-started, action-started, the check operation,
action-completed, module-completed and summary in that exact order. Complete
argument vectors are checked, including messages, module/action identifiers,
event state and raw code. Event success/failure follows the helper return;
event raw status follows `CHECK_STATUS`. The workflow returns the helper result
after the summary, including a supplied nonstandard failure return.

Each scenario runs twice. The first uses successful event/summary callbacks;
the second supplies event return 17 and summary return 19. Those callback
returns must not replace the check result. Selected state is poisoned before
both calls; IFS, stderr, exact output and the private trace inventory are checked.

## Scope

Mirror lookup and command execution are callbacks. No mirrors file, network,
installed command, package database, clock, runtime initializer or native
Slackware workflow is inspected or executed. Event emitters and summary are
callbacks too: this test verifies their invocation, not real serialization,
summary rendering or transport. Existing JSON and main-completion regressions
retain their separate supplied-state and callback boundaries.

The guards abort known excluded entry points but are not operating-system
containment. Review new calls before testing changed source. The private driver
uses no shared Python test support and makes no native conformance, authorization,
no-effects or global host safety claim. Raw 20 here follows the check helper's
existing contract; it does not alter original native install-new/upgrade rules.
Original findings, decisions, criteria, schema and phase boundaries are unchanged.
