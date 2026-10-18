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
on exit. This does not establish whole-host cleanup or trap behavior under every
failure. Test setup/redirection faults and concurrent execution are out of scope.

Five syntax-valid private mutations are rejected: removing the private mirror
binding, bypassing preflight, enabling Git terminal prompts, changing the
slackpkg default answer and dispatching apply in check mode. A sixth private
fixture mutation selects HTTPS and is rejected through the supplied wget guard;
no actual request is made. Mutation results are finite controls, not exhaustive
coverage or independent native/semantic acceptance.

Keep the mirror-probe, check-workflow, CLI early-exit and runtime/logging drivers
for their separate authored matrices and callback boundaries. The historical
54-command step 474 selection remains unchanged; this is a later focused repair.
The installed-initrd discrepancy remains open. Phase 1/kernel acceptance remains
incomplete, A/R/D unselected and schema 1/reference-v1/C/Phase 2/production closed.
Native evidence/live bindings remain null; host state is unobserved and global
host closure false. No native execution right or consumed binding is renewed.
