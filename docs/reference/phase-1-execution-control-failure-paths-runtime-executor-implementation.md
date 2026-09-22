# Phase 1 execution-control failure-paths runtime-executor implementation

Step 185 implements the controller-side builder, the generated standalone runtime
executor, and the repository acceptance harness authorized by step 184. This is
still a controller-repository step; it does not authorize copying the executor
to the runtime VM or executing any runtime scenario.

## Builder and payload

The builder reads only the accepted `tools/reference/slack-update-reference.sh`
and `data/config/slack-update.conf` inputs. It rejects either input unless its
SHA-256 exactly matches the step-182/183 freeze. The generated executor embeds
those exact bytes as base64 payloads and therefore does not require a Git
repository on the target VM.

The executor requires the explicit `--execute-runtime-validation`
acknowledgement. Before any scenario it revalidates the accepted FQDN, kernel,
and boot ID, verifies the embedded source/config identities, and derives a
runtime configuration by changing only `core.work_dir`, `core.log_dir`, and
`core.lock_file` into the root-owned evidence tree.

## Implemented scenarios

The network-failure scenario launches the exact frozen reference `--check` path
inside an ephemeral network namespace and requires a deterministic failure with
no successful external network access. Lock contention uses the real reference
`acquire_instance_lock` path and requires the second attempt to return `6`.
SIGINT, SIGTERM, and SIGHUP are delivered to safe reference drivers using the
real reference traps and require exit codes 130, 143, and 129. The cron scenario
uses the already-running root `crond`, records that no terminal is present, and
restores the prior root crontab exactly.

## State protection and evidence

The executor fingerprints the package database, slackpkg state, running kernel,
`/proc/cmdline`, `/boot`, the root crontab, and the reference lock. Runtime work,
logs, extracted payloads, and temporary cron artifacts are confined to
`/var/tmp/slack-update-acceptance/execution-control-failure-paths`.

Only after all four scenarios, all three signal runs, cleanup, and protected
fingerprint comparisons pass may the executor publish the evidence archive and
SHA-256 file under `/home/promano`. No package action, boot action, reboot,
repository refresh, or persistent target configuration change is authorized by
this implementation step.

## Authorization boundary

Step 185 leaves the builder and generated executor identities deliberately
unfrozen. Step 186 must review the implementation, freeze those identities, and
make a separate runtime-copy/runtime-execution authorization decision. Until
that review passes, the executor must not be copied to or run on the VM.

The next stage is
`phase-1-execution-control-failure-paths-runtime-executor-implementation-review-and-runtime-authorization`.
`pause_safe=false`.
