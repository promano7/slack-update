# Private runtime initialization and logging regression

Run `python3 tests/reference/test-runtime-logging.py` after changing runtime path
assignment, temporary-file creation, logging redirection or log rotation. The
driver calls the real `initialize_runtime`, `initialize_dry_run_runtime`,
`configure_logging` and `rotate_logs` functions without calling `main`.
It requires Python 3.9 or newer, Bash, GNU sed, tee and find on Linux.

## Coverage and observations

| Boundary | Entries | Checks |
| --- | ---: | --- |
| Runtime setup | 28 | Full selected bindings, raw return, exact diagnostic, callback order/vectors and private file contents |
| Logging | 28 | Four JSON/events combinations, new/existing log, authored text bytes, missing command discovery and descriptor routing |
| Rotation | 6 | Three retention values, real recursive deletion and supplied quiet find failure |

Setup entries exercise new and existing configured directories. The ordinary
initializer uses the configured work directory; the dry-run initializer uses a
supplied private directory. The state-initializer callback records its position,
can fail with status 43 and otherwise resets only `RUNTIME_TMPDIR`. This is a
wrapper test, not a test of all mutable-state resets in
`initialize_runtime_state`. Seeded bindings make partial initialization visible.
The fixed date callback checks the exact timestamp argument. The generated SBo
path is compared with the independently observed child process PID.

The mkdir wrapper records arguments and uses real private directories except for
its selected failure. The mktemp callback checks the original argument vector,
creates files or a directory owned by the Python test and can fail at each of
the five ordinary temporary-file positions. The dry-run callback requires the
literal `-d /tmp/slack-update-dry-run.XXXXXX` request but maps it to a private
test directory. It does not execute that installed temporary-directory request.
The five temporary failures preserve earlier files, empty the failed assignment
and leave later bindings seeded. No rollback is claimed. The dry-run success
creates exactly the six state files selected by the implementation; other
assigned paths remain uncreated. Existing unrelated private files survive.

Logging uses real sed and tee. A separate control descriptor reports the return
after the process-substitution logger has been waited for. Both stdout and stderr
payloads pass through the logger. Ordinary mode retains the original descriptor
3; either structured flag reserves descriptor 3 for the original stdout and sends
human output to stderr. An existing log is appended to. Missing sed or tee stops
before log creation and redirection, with the exact discovery diagnostic.

Authored byte expectations cover plain text, supported ANSI color sequences,
carriage returns, UTF-8 and an unsupported ANSI sequence. The actual pipeline
filters both the console output and the log. It preserves the emoji and removes
only the first carriage return on each line. These observations disagree with
the nearby source comment about emoji removal and console filtering order; the
regression follows the implementation. The reference script is unchanged.

Rotation uses real find under a private log directory with authored ages safely
away from whole-day boundaries. It removes old matching files recursively,
including a matching empty directory and symlink, while preserving the symlink
target outside that directory. The function has no type restriction. Young and
boundary-age logs and nonmatching files survive. A supplied quiet find status 43
produces raw function status 0 and no removals because of the existing `|| true`.
That unchecked failure projection is an implementation limitation, not approval
of native success or error-handling criteria.

## Deliberate limits

No package manager, network, installed boot operation, actual command discovery
failure, installed mktemp behavior or native runtime grant is established here.
Named guard functions are checks in this harness, not OS containment. The driver
does not claim complete call-graph coverage. Supplied failures are quiet and
bounded; directory/open/redirection failure diagnostics, logger startup errors,
late pipeline failures, concurrent rotation and disk exhaustion remain outside
this matrix. Private temporary cleanup belongs to the Python test and is not
evidence that reference traps remove partial state or that the host is clean.

Keep `test-main-setup-failures.py`, `test-main-completion.py`,
`test-instance-lock.py`, `test-signal-cleanup.sh`, `test-error-exit-codes.sh`,
`test-dry-run-environment.py` and `test-dry-run-workflow.py` for their separate
main dispatch, completion, lock, interruption, exit and dry-run boundaries.

The historical `test-cron-minimal-environment.sh` was attempted while preparing
step 472. Its source/environment checks passed, but its three workflow cases
reached the real mirror preflight before their supplied slackpkg callback and
failed because `/etc/slackpkg/mirrors` was unreadable here. It reported 19 of 79
checks failed. The complete failed attempt and retained private diagnostic are
delivery evidence. It was unchanged and outside the eight passing normal
commands selected for step 472 and the later step 474 selection. Step 475
reproduces that failure and repairs the private mirror fixture; see the
[separate cron scope](cron-minimal-environment.md). That later result does not
change the historical selection or imply native cron acceptance.

Nine syntax-valid private mutations are rejected: ordinary queue path, CSB
binding, dry-run work binding, omitted dry-run cache file, structured-mode
predicate, log append, carriage-return filter, retention age and temporary-file
error text. This finite sensitivity check is not an exhaustive mutation score.
An initial harness attempt read `$!` after a failed logger setup under nounset;
the corrected harness reads it only on success. An initial mutation-runner count
assertion expected two mode predicates rather than one; only that assertion was
corrected. Both failed attempts remain in the delivery. No source failure is
reclassified as a passing normal test.

The scope remains static repository regression. Phase 1 and kernel work remain
incomplete. Native evidence and live bindings are null, actual host state is
unobserved-not-claimed-absent and actual global host closure is false. Existing
native criteria, independent acceptance requirements and authority limits remain.
