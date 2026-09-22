# Phase 1 execution-control failure-paths runtime-executor implementation design

Step 183 freezes the implementation design for the bounded runtime executor that
will validate the four accepted execution-control failure paths. This step is
repository-only and does not authorize implementation or machine execution.

## Accepted target binding

The design consumes the step-182 binding for
`vbox-slackcurrent.vbox-slackcurrent.org`, kernel `6.18.45`, boot ID
`cb85100b-9993-4876-ab32-b2457ed0ac6d`, reference-script SHA-256
`086b28b42be3135ebf47a28c1fcd2e5652f8fdd261e696ad48e612a241edf4ea`, and
effective-config SHA-256
`4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba`.
The future executor must stop before any scenario if FQDN, kernel, boot ID, or
embedded source/config identity no longer matches this binding.

## Standalone payload

The implementation will create a single self-contained shell payload for the
runtime VM. The target will not require a Git repository. A controller-side
builder will embed the exact frozen reference script and effective configuration
into the payload and record their identities. The payload must require the
explicit `--execute-runtime-validation` acknowledgement before runtime work.

The embedded configuration may be derived only by redirecting
`core.work_dir`, `core.log_dir`, and `core.lock_file` into the root-owned
acceptance evidence tree. Every other configuration value must remain identical
to the frozen controller configuration, and the derived configuration SHA-256
must be recorded in evidence.

## Safe reference driver

For lock, signal, and cron validation, the executor will source the exact frozen
reference script with its normal main guard inactive and invoke only the real
runtime setup, configuration, privilege, locking, and trap functions. An
executor-owned FIFO will hold the driver after the real reference lock is
acquired. No package or boot workflow may run in these control tests.

The network-failure scenario is the only scenario that launches the complete
reference `--check` path. It runs inside an ephemeral network namespace with no
usable external network and must fail before any successful repository
synchronization.

## Scenario observations

The simultaneous-execution scenario must observe the second real lock attempt
return stable exit code `6`. Signal runs must separately observe SIGINT `130`,
SIGTERM `143`, and SIGHUP `129`, with the lock clean after every run. The cron
scenario must use the already-running real `crond`, execute without a terminal,
and restore the previous root crontab exactly after one bounded run. Its maximum
wait is 90 seconds.

## State and cleanup gates

Before and after runtime validation, the executor must fingerprint package
database contents, running kernel, `/proc/cmdline`, boot artifacts and symlink
targets, control-lock state, runtime work/log state, and root-crontab state.
Packages, boot artifacts, repository state, reboot state, and persistent system
configuration must remain unchanged.

The evidence archive may be published only after cleanup proves that no test
process remains, the reference lock is released, the temporary network
namespace and cron entry are gone, the previous root crontab is restored, and
runtime files are contained under the evidence root.

## Authorization boundary

Step 183 authorizes only the next repository review of executor implementation.
It does not authorize implementation itself and does not authorize any runtime
scenario. A later Slackware-current publication alone does not invalidate this
design, but drift from the frozen runtime binding does.

The next stage is
`phase-1-execution-control-failure-paths-runtime-executor-implementation-authorization-review`.
`pause_safe=false`.
