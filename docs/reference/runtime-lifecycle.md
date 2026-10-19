# Private runtime initialization and EXIT cleanup composition

Step489 clears six cleanup-managed bindings at the start of
`initialize_runtime_state`: QUEUE_FINAL,BROKEN_NEW,STILL_BROKEN,BROKEN_ERRORS,
ELF_LIBRARY_CACHE,RUNTIME_TMPDIR. The reset precedes the first checked clock call
and all subsequent setup operations. Later successful allocations assign fresh
paths in the existing order. No cleanup, trap, lock, result or native contract
implementation is changed by this patch.

Previously an early failure could leave inherited/previous values in those
variables. The already installed EXIT trap then removed the referenced old files
or directory. A private probe reproduces start-time failure deleting all five
seeded files and the seeded directory. The fix prevents those prior bindings from
being presented as current cleanup targets. It does not reclaim old resources,
prove their absence or make repeated initialization a supported recovery process.

Run the exact focused selection without sudo:

```bash
python3 tests/reference/test-runtime-lifecycle.py
python3 tests/reference/test-runtime-logging.py
python3 tests/reference/test-main-setup-failures.py
python3 tests/reference/test-main-completion.py
python3 tests/reference/test-instance-lock.py
bash tests/reference/test-signal-cleanup.sh
bash tests/reference/test-error-exit-codes.sh
python3 tests/reference/test-apply-json-result.py
python3 tests/reference/test-sbo-option-json.py
python3 tests/reference/test-event-ndjson.py
python3 tests/reference/test-dry-run-json-result.py
python3 tests/reference/test-dry-run-environment.py
bash tests/reference/test-cron-minimal-environment.sh
```

## Independently authored40-scenario lifecycle matrix

The new standard-library driver composes REAL state initialization, ordinary/dry
runtime initialization, lock acquisition, trap installation, EXIT cleanup and
lock release in a fresh child Bash process. No main or update workflow is called.

Eighteen ordinary cases cross empty/populated prior bindings with success,
start-time failure, mkdir failure, runtime-time failure and each of five temporary
allocation failures. Twenty-two dry cases add each of the six real initialization
redirection failures instead of the ordinary later allocations. Every case keeps
separate protected prior files and a protected prior directory with known bytes.

Date results/failures, selected mkdir failure and temporary allocation mapping
are supplied callbacks. The allocator creates real private empty files/directories
and can fail before an allocation; the literal dry `/tmp/...XXXXXX` request is
mapped into the owned fixture. It does not run the installed mktemp command.
For dry file failures, the allocator creates a directory at the selected file
path; the real Bash redirection fails even under preparerUID0. Real mkdir, rm,
flock, EXIT traps and descriptor9 operate only on owned private fixtures.

The driver independently authors expected raw exit, six pre-exit bindings,
lock-held field, exact stderr, full callback order/vectors and post-exit private
files/directories/link snapshot. Directory-redirection diagnostics match full
source/target/error text and the explicit application warning; only a positive
source-line number varies. Old protected bytes must survive, new ordinary
allocated files must be removed and a fresh dry workspace must be removed,
including after partial initialization. Lock acquisition/release calls are traced;
a separate real flock probe confirms that exact private lock is available after
process exit. That latter observation alone cannot distinguish cleanup release
from the operating system closing descriptors on exit.

No inspected package/cache/boot/network operation runs. Named guards reject those
entries, but are not OS containment. Snapshots do not measure ownership,
permissions,xattrs,every descriptor,concurrent writers or global host state.
Python later removes its entire fixture tree; that is not evidence of global
reference cleanup. Supplied failures are not native clock/disk/permission cases.

## Evidence and deliberate limits

Exact accepted488 source passes29 cases and rejects11 populated early-failure
cases. The initial direct private start-time probe and full old-source state/file
counterexamples remain retained. Six syntax-valid private source controls each
omit one of the early resets and reject on the same seeded start-time failure.
All40 cases, twelve complementary suites and syntax pass under preparerUID0.
This is not an actual unprivileged OS/native Slackware run or independent conformance.
Normal user commands do not rerun the private mutation controls.

The existing runtime/logging setup driver supplies its own state callback and
therefore retains its separately authored seeded-wrapper expectations. The new
composition uses the real state reset and closes that specific coverage gap;
its oracle is not imported from the old driver. Other new reset effects on JSON,
main and cron retain their separate tests and scopes.

Only these six bindings are added to the existing initialization reset. The final
legacy RUNTIME_TMPDIR clear remains, preserving ordinary successful flow. This
is not a general ownership schema, environment sanitization, rollback, once-only
right or global cleanup proof. Clearing previous pointers can leave earlier
resources untracked; callers still need separately reviewed lifecycle/ownership.
Mutable ordinary bindings and the selected failures are assumed. Readonly/imported
shell state errors, arbitrary path substitution, cleanup-command failure,
concurrent mutation, production logger drain and native graph containment remain
outside the new matrix. No old native criterion or consumed authority is amended.

Phase1/kernel incomplete;five native families20scenarios,13findings/16gaps remain.
A/R/D unselected;schema1/reference-v1/C/Phase2/production closed. Native evidence/
live bindingsNULL, actual host unobserved/global closureFALSE. Original install-new20
empty AND no-effect and upgrade20 failure criteria remain binding. Separate native
decision, independent reviews, conditional migration, ACTUAL composition, safe
independent whole review, fresh bounded grant and own-platform conformance remain.
