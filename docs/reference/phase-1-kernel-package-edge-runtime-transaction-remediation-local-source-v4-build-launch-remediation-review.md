# Phase 1 step 270 — local-source-v4 build-launch remediation review

## Result and evidence boundary

PASS: repository-only review of the launch remediation selected at accepted step 269
(commit `b039f08`). The production builder is neither entered nor changed. No live
target observation or new machine-state claim is made by this review.

The frozen failure occurred before builder entry: direct execution rejected a
transported regular script at mode `0644`. Its verified content is independent of
the executable bit. The failed step-267 executor and its consumed authorization
remain immutable history and must not be reused.

## Reviewed future correction

Use a separately named future executor. After verifying that the builder is a
regular non-symlink file at exact SHA-256
`38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7`, and that `bash` is available,
invoke it as `bash -- "$builder" --build-local-source-v4`. Preserve argument
boundaries for paths containing spaces. No executable-bit requirement or `chmod`
remediation is needed. Propagate the builder's nonzero exit status and do not
publish success after failure.

Retain all target, package-database, Slackpkg, staged-target, v3-tree, failed-v2
evidence, final-output-absence and temporary-root-absence guards. A fresh read-only
target revalidation must precede a new explicit single-attempt authorization.
The historical boot ID is not current authority. Stop before launch on any drift;
the attempt is consumed even if it fails, with no automatic or manual retry.

## Repository acceptance

The harness binds the seven accepted checkpoint/builder/executor files by SHA-256.
It demonstrates the permission failure using an inert synthetic script at mode
`0644`, then verifies the reviewed Bash invocation with a path containing spaces.
It rejects missing, symlinked and changed surrogate scripts before entry, and
checks argument preservation and propagation of a failing surrogate's exit code.
This demonstrates the launch mechanism only; it is not a v4 build or target test.

## Closed actions and continuation

No remediation implementation, transport, target probe, production build, package
or Slackpkg action, network access, boot/reboot action, persistent configuration
change, evidence cleanup, runtime rerun or Phase 2 is authorized. The accepted v3
and failed-v2 evidence must remain unchanged.

Next stage: `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-freeze`.
Only repository review/freeze is open. `machine_action_required=false`,
`controller_action_required=false`, `pause_safe=false`, `strong_safe_pause=false`
while this repository workstream is reopened. The planned later pause requires
closing the newly authorized attempt and reviewing its success or failure.
