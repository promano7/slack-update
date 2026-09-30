# Phase 1 step 273 — local-source-v4 build-launch remediation executor design freeze

## Frozen result

PASS. Consume accepted step 272 (`f5ed5c7`) and require its complete 74-pass
repository acceptance again. Freeze the design as
`executor-design-frozen-not-implemented`; all design fields except this state
remain exactly equal to the accepted review. No production executor is added,
and no live target observation or builder entry is performed.

## Frozen execution contract

The separately named future executor is `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh`.
Its strict three-argument execution interface is
`--execute-authorized-local-source-v4-build-v2 --authorization-boot-id UUID`.
The canonical lowercase UUID is mandatory data, supplied by the future fresh
explicit authorization and compared with the current boot ID. No historical
default, old switch, missing/duplicate/unknown/extra arguments, eval or sourced
authorization input is allowed.

The unchanged regular non-symlink builder must be verified at exact SHA-256
`38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7`.
After every existing preflight guard and a launch-boundary SHA recheck, invoke
exactly once as `bash -- "$builder" --build-local-source-v4`. Preserve argument
boundaries and nonzero exit status; publish success only after exit zero. No
transported executable bit or chmod remediation is required.

## Frozen derivation and acceptance

Use immutable failed-executor SHA-256
`f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985`
as the derivation baseline. Keep every existing verification-function body
byte-identical and preserve all 17 reviewed preflight categories. Allow only the
reviewed executor identity/help/switch/status changes, fresh-boot argument,
Bash command/launch correction, and isolated launch-function/library test seam.

Implementation acceptance must prove the exact allowlisted derivation, unchanged
guard bodies and builder, strict CLI, rejection before surrogate entry, mode-0644
launch and spaced path, exact argument, missing/symlink/changed-input rejection,
and failure-status propagation with no success publication after failure. The
library-only seam must require explicit opt-in and must not automatically enter
main, change production constants for tests or touch host paths. Normal script
execution must run the guarded main.

## Authority and preservation

Open only repository-side implementation and review of the separately named
executor and its synthetic acceptance. `remediation_implementation_authorized`
is restricted to this repository scope; it grants no machine authority and no
permission to change the immutable builder or historical executor.

The controller authorization protocol permits one later attempt, consumed even
on failure, with no automatic/manual retry. No persistent attempt marker or
replay-prevention claim is introduced. Fresh read-only target revalidation and
a new explicit authorization remain required before transport or execution.

Target observation, builder transport/execution/build, package/Slackpkg/network,
configuration/boot/reboot/cleanup, runtime rerun and Phase 2 remain closed.
Accepted v3 and failed-v2 evidence remain immutable. No new live-state claim is
made. `machine_action_required=false`, `controller_action_required=false`,
`pause_safe=false`, `strong_safe_pause=false`.

Next stage: `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-review`.
