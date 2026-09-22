# Phase 1 execution-control failure-paths runtime-boundary design

Step 180 consumes the accepted step-179 four-scenario contract and freezes the
runtime-boundary design for the **`execution-control-failure-paths`** family.
This remains a repository-only design step. It does not bind a particular VM,
implement the acceptance executor, or authorize runtime execution.

## Bounded runtime design

The future target must be a Slackware-current runtime-validation VM. A later
binding review must record the hostname, FQDN, running kernel, Slackware
version, boot ID, reference-script SHA-256, and effective-configuration
SHA-256 before any execution authorization can be considered.

The planned acceptance executor is
`tests/acceptance/reference/test-execution-control-failure-paths.sh` and its
future explicit acknowledgement is `--execute-runtime-validation`. The target
must already provide Bash, Python 3, SHA-256 tooling, tar, flock, a usable
network namespace through `unshare`, process/signal tooling, `crontab`, and a
running `crond`. A missing capability blocks the chain; step 180 does not
permit installing packages or changing the target to satisfy the design.

The network-failure case will isolate the real reference check inside a
temporary network namespace with no usable external interface, so no host
network configuration is changed and no repository synchronization can
succeed. The simultaneous-execution case will observe a real reference process
holding the execution lock at a safe check path, temporarily hold that process,
and prove that a second real attempt cannot acquire the lock. The signal case
will run separate SIGINT, SIGTERM, and SIGHUP trials before any mutating stage;
the required conventional statuses are 130, 143, and 129. The cron case must
use a real root cron context, preserve any pre-existing root crontab byte for
byte, install only one temporary acceptance entry, observe one bounded run, and
restore the exact original crontab before the scenario can pass.

Pre/post evidence must prove identical package and boot state and clean runtime
control state. Temporary network namespaces, test processes, cron entries, and
execution locks must be gone after the run. Evidence is designed to be retained
under `/var/tmp/slack-update-acceptance/execution-control-failure-paths` and
published as a private archive plus SHA-256 sidecar in `/home/promano`, owned
by `promano:users` with mode `0600`.

## Authorization boundary

Step 180 authorizes only the next target-binding review. It does **not**
authorize implementation of the runtime executor, runtime execution, repository
refresh, successful network access, package mutation, boot mutation, reboot,
source changes on the target, persistent system-configuration changes, or
Phase 2. A later Slackware-current publication does not invalidate this design.

The acceptance matrix remains incomplete; `reference-v1` remains blocked
behind the remaining acceptance work and the C port remains blocked by the
Phase 1 gate.

Frozen helper SHA-256: `abaea6bcb3fa132b1379ac8ca3e7ed3b28e77e21956a95f5cd1f019ac2f1b6f6`.
Frozen policy SHA-256: `63a1605b36cddbc12fb3e0b3b68a349435f2230348bf3be76c71cd04e1c84cf1`.
Frozen record SHA-256: `0d4c3f5015da8f32bdb431d1246b5f670ace8cece2ccfc8331a69f73d87fcab1`.

The next stage is
`phase-1-execution-control-failure-paths-runtime-target-binding-review`.
Step 180 is not the requested end-of-session strong safe pause, so
`pause_safe=false`.
