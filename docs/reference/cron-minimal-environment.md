# Detached minimal-environment regression and mirror-fixture repair

Run `bash tests/reference/test-cron-minimal-environment.sh` from the repository
root when execution-environment normalization, detached output, prompt suppression
or runtime permissions change. It requires Linux, Bash, GNU coreutils, grep,
sed and flock. It does not require root, installed slackpkg or network access.
The reference executable bit must be preserved for its direct `--help` control.

## Reproduced failure and correction

Step 472 recorded 19 failures out of 79 checks. Step 475 reproduces the same
result on the exact accepted step 474 source, with the full failure output
retained in the delivery. The three check-mode workflows consulted the installed
`/etc/slackpkg/mirrors` before reaching the supplied slackpkg callback. The
unreadable installed path prevented the expected successful workflow.

The correction changes the test fixture only. After sourcing the unchanged
reference, its child harness sets `SLACKPKG_MIRRORS_FILE` to its private case
file. The real `resolve_active_slackpkg_mirror`,
`probe_slackpkg_mirror_changelog`, `check_slackware_updates` and complete check
workflow remain in use. Successful mirrors use an absolute private directory or
`file://` URL with a private ChangeLog. No transport-success callback bypasses
the preflight. The original 79 assertions remain in place.

## Current checks

The current result is 153 assertions, including the original source-order,
empty/hostile environment and direct-help controls, plus these 15 workflows:

| Mirror fixture | Output modes | Expected result |
| --- | --- | --- |
| Private absolute directory | Human and events | Process 0; supplied slackpkg status 100; updates available |
| Private file URL | JSON | Process 0; supplied slackpkg status 100; updates available |
| Missing mirrors file | Human, JSON and events | Process 1; mirror status 69; no slackpkg invocation |
| Comments without an active mirror | Human, JSON and events | Process 1; mirror status 69; no slackpkg invocation |
| Multiple active mirrors | Human, JSON and events | Process 1; mirror status 69; no slackpkg invocation |
| Local mirror without a ChangeLog | Human, JSON and events | Process 1; mirror status 69; no slackpkg invocation |

Each workflow starts under `env -i` with an unusable PATH, hostile selected
variables, detached descriptors and a finite timeout. The real main function
normalizes its environment, loads a private configuration, acquires a private
lock and creates runtime/log files. The privilege callback supplies success; it
does not grant privilege. The slackpkg callback accepts only the exact three
arguments `-batch=on -default_answer=n check-updates` and records its inherited
environment and descriptor types. It never invokes the installed command.

Positive cases retain the owner-only directory, lock and log mode assertions
and structured-output routing controls. All 12 negative cases assert the real
preflight diagnostic, stable failure, no slackpkg invocation and no prohibited
call marker. JSON cases also assert failed result, mirror code 69 and stable
code 1; event cases assert completion and stable code 1. These substring checks
complement the separate JSON/NDJSON parsing suites; they do not validate every
serialized field or full document grammar.

The harness records and rejects selected wget, curl, apply/dry-run entry points
and unexpected slackpkg vectors. These guards are finite sensitivity controls,
not an OS sandbox or a complete effect monitor. No installed mirror is needed
by the current check workflows. The normal test does not execute network tools
or ordinary package/boot/module operations. Real private locking, coreutils,
logging, process substitution and cleanup still occur. Runtime temporary files
use the real reference mktemp calls under `/tmp`; the test case root is removed
on exit after the selected logger has completed. This does not establish whole-host cleanup or trap behavior under every
failure. Arbitrary setup/redirection faults and native concurrent execution remain outside
this fixture; the selected completion barrier below is independently controlled.

Five syntax-valid private mutations are rejected: removing the private mirror
binding, bypassing preflight, enabling Git terminal prompts, changing the
slackpkg default answer and dispatching apply in check mode. A sixth private
fixture mutation selects HTTPS and is rejected through the supplied wget guard;
no actual request is made. Mutation results are finite controls, not exhaustive
coverage or independent native/semantic acceptance.

## Logger completion before assertions

The first planned closing integration in step482 ran56 named commands:55 passed,
but cron missed the missing-file/events diagnostic and failed1/153. A serial
repeat missed the no-active/events diagnostic and also failed1/153. These are
retained new outcomes, separate from the original installed-mirror19/79 failure.
The focused user153PASS at475 remains valid for its reported run; it did not
establish producer/consumer completion under every scheduling order.

The main child can return while its process-substitution logger still reads and
forwards progress. The old fixture immediately inspected regular output files,
so main's status did not mean those files were complete. Step482 repairs only
the fixture: copy the exact sourced `configure_logging` definition under a private
name with Bash builtins, delegate its unchanged body and retain its logger PID
immediately after success. After main returns, save its status, close both pipe
writers and wait for that exact child. Return the original main status after a
successful drain. A failed wait returns fixture-only97 and cannot count as an
expected main0/1 result. The production reference and cleanup path are unchanged.

Six controlled private probes hold the actual logger behind an owned FIFO before
real tee forwards bytes. All three old human/JSON/event children exit with the
expected mirror-failure1 while that logger remains held. All three repaired
children remain waiting until release, then return1 with the complete diagnostic.
The controller observes main-finished and logger-entered markers, releases its
exact FIFO and captures both pipes through EOF with finite deadlines. Prohibited
call/slackpkg markers remain absent. This is a controlled private completion
experiment, not native timing, permission, global process cleanup or conformance.
An early probe authoring attempt selected the unrelated environment heredoc; it
failed before logging. The corrected probe selects the exact cron heredoc; its
failed output and correction qualification remain in the delivery.

All153 assertions remain unchanged and pass after repair, including three main
success statuses0 and12 real mirror-preflight failures1. A further normal run
under the selected companion checks also passes. Six companion drivers retain
their own scopes: mirror probe, check workflow, CLI early exits, runtime/logging,
check JSON and event NDJSON. No arbitrary sleep, logger retry or production drain
guarantee is introduced. Existing phase/native gates remain closed.

The closing integration moves to483, making nine steps in the requested8-12-step
block. No56-command integrated PASS or new pause follows from the initial failed
attempt or this focused repair. Actual482 is still required, followed by the
closing integration and its complete actual return; only then can the separate
whole inherited-condition review confirm a scoped repository pause.

Keep the mirror-probe, check-workflow, CLI early-exit and runtime/logging drivers
for their separate authored matrices and callback boundaries. The historical
54-command step 474 selection remains unchanged; this is a later focused repair.
The installed-initrd fixture was aligned in476 with the accepted incomplete-path
contract; its original failure and native criteria remain preserved. Phase 1/kernel acceptance remains
incomplete, A/R/D unselected and schema 1/reference-v1/C/Phase 2/production closed.
Native evidence/live bindings remain null; host state is unobserved and global
host closure false. No native execution right or consumed binding is renewed.
