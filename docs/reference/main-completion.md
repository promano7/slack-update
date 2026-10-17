# Main dispatch and completion regression

Run from the repository root:

```bash
python3 tests/reference/test-main-completion.py
```

This independent Python 3 standard-library driver invokes Bash with the real
reference `main` and argument parser. All setup, workflow and final-result
implementations are replaced by authored callbacks. It complements the
[setup failure test](main-setup-failures.md),
[stable-exit regression](../../tests/reference/test-error-exit-codes.sh) and
[JSON/NDJSON serializer checks](../testing.md#current-json-and-ndjson-checks).

## Matrix and assertions

The 576 scenarios cross four operation spellings (omitted means apply, explicit
check, dry-run, apply), three output modes, three raw workflow statuses (0, 1,
23), two supplied clock statuses (0, 41), four supplied mapped statuses (0, 2,
5, 8) and two inherited descriptor-3 states (open to a private file or closed).

- Main selects exactly one matching workflow after setup and operation-start.
  Dry-run selects its own initializer; the other operations select the normal one.
- Workflow status reaches the mapper unchanged when the clock succeeds. Clock
  failure replaces it with general failure 1 and produces the exact diagnostic.
  The date callback checks the argument vector and supplies a fixed timestamp.
- Main replaces deliberately stale completion/status state. The mapper receives
  the completed timestamp, or an empty value when the clock callback fails.
- The mapper callback supplies a status independently of the workflow result.
  Main passes that mapped value to the summary and selected final-output callback,
  then returns it. All cases assert the complete ordered trace and output bytes.
- Human mode invokes no machine-result callback and preserves the inherited
  descriptor-3 state. Structured modes close descriptor 3 after final output.
  The old inherited file stays empty; the modeled reserved channel receives
  exactly the selected callback marker and no human progress text.

The raw statuses 23 and 41 exercise forwarding and failure replacement; they are
not new stable exit codes. Supplied mapped statuses test propagation, not the
semantic mapping of a native workload. For example, a callback may deliberately
return mapped 0 despite a supplied workflow failure. That is test data, not an
approved status policy. Existing stable-exit tests retain mapping responsibility.

## Scope and replaced effects

The driver replaces environment normalization, configuration loading, privilege,
locking, traps, runtime state/files, rotation, logging and banner rendering.
Workflow bodies, event wrappers, the clock, stable mapper, summary, JSON emitter
and final-events emitter are callbacks. No actual update, package, boot, lock,
trap, cleanup or configuration operation is performed by these callbacks.

The logging callback models structured-output routing by reserving a private
file on descriptor 3 and moving stdout to stderr. It does not invoke the real
logging function, tee/sed processes or production log paths. The marker output
is not JSON/NDJSON and does not test schemas, serializers or final-event contents.
The test covers main's JSON redirection and structured descriptor closing, not
the real logger's descriptor reservation or process-substitution behavior.

Exact traces and selected forbidden functions detect changed reviewed boundaries;
they are not OS containment against arbitrary new code. Review new calls before
running this driver on changed reference source. Python and Bash use private
temporary artifacts, without a native Slackware update workflow.

This is repository regression coverage, not native acceptance, independent
semantic approval, a schema freeze or Phase 1 completion. Original obligations,
findings, option decisions and separate platform/run execution gates remain.
