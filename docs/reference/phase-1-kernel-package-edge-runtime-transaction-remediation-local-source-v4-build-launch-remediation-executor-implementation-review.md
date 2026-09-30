# Phase 1 step 274 — local-source-v4 build-launch remediation executor implementation review

## Result

PASS. Consume accepted step 273 (f1d28b9) and its complete 59-pass acceptance.
Add separately named executor phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh at SHA-256 43e07ebfbf2c4ddd263cfbea9214477e620901dbd391aff9ff45c23bd2e8752d.
State: implemented-reviewed-not-frozen-not-production-executed.

The exact ordered derivation is bound in the policy. All nine existing verification
functions and all non-boot readonly constants are unchanged; the immutable builder
and historical executor remain unchanged. No production main, builder or live target
observation is entered during acceptance.

## Implemented contract

Require exactly --execute-authorized-local-source-v4-build-v2 --authorization-boot-id UUID.
The canonical lowercase UUID is mandatory data without a historical default. Reject
old/unknown/missing/duplicate/extra arguments and malformed or executable-looking data
before host checks. All existing preflight checks precede the launch function.

The launch function repeats Bash availability and regular-file/exact-SHA checks, then
invokes bash -- "$builder" --build-local-source-v4 once. No executable bit is required.
It propagates any nonzero builder status before success publication.

SLACK_UPDATE_V4_BUILD_LAUNCH_LIBRARY_ONLY=1 explicitly opts into a sourced test seam
without automatic main entry. Direct execution in library mode is rejected. Normal
execution enters the guarded main. Acceptance calls the actual parser and launch
functions with inert synthetic scripts; frozen constants and host paths are not used
as mutable test inputs.

## Acceptance and continuation

Prove exact allowlisted derivation, unchanged guard functions/constants, strict CLI,
library/default entry behavior, all guards before launch, mode-0644 and spaced-path
launch, one exact argument and unchanged bytes/mode. Reject missing/symlink/changed
scripts and unavailable Bash before surrogate entry. Propagate surrogate exit 37
without success output.

This proves repository implementation and launch mechanics only. Fresh target
revalidation and a new explicit controller single-attempt authorization remain
required. No automatic/manual retry or persistent attempt marker is introduced.
Transport, target observation, production build, package/Slackpkg/network,
configuration/boot/reboot/cleanup, runtime rerun and Phase 2 remain closed.
Accepted v3 and failed-v2 evidence remain immutable.

Next stage: phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-implementation-freeze.
machine_action_required=false, controller_action_required=false,
pause_safe=false, strong_safe_pause=false.
