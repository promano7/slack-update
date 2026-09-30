# Phase 1 step 272 — local-source-v4 build-launch remediation executor design review

## Reviewed result

PASS. Consume accepted step 271 (`cd73456`) and its 53-pass repository acceptance.
The new executor is designed, not implemented. No production builder entry,
transport or target observation occurs.

## Executor identity and fresh binding

Reserve `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor.sh` and the strict future argument sequence
`--execute-authorized-local-source-v4-build-v2 --authorization-boot-id UUID`.
Require exactly three arguments, a canonical lowercase UUID, and no old switch,
default boot ID, duplicate/unknown/missing/extra argument or executable argument
evaluation. The UUID is data and must equal the current boot ID before launch.

This permits implementation/freeze before fresh target revalidation: the later
explicit authorization supplies the observed boot ID without rewriting the
frozen executor. The historical step-267 boot ID is never a fallback. Other
target/package/configuration identities remain at the existing frozen baseline;
drift blocks execution and requires review rather than silent rebinding.

## Bounded derivation and preflight

Derive separately from immutable failed executor SHA-256
`f91ee0a2ff9f9410c968d5ce9c78080bb7e8de6ff4307e734ea71cb121ce6985`.
Allow only identity/help/switch/status changes, mandatory fresh boot input,
Bash availability and launch changes, and a launch-function/library-only test
seam. Keep existing verification function bodies byte-identical. Do not modify
the historical executor or builder.

Before launch require: root and required commands; regular non-symlink builder
at exact frozen SHA-256; canonical package database/compatibility symlink and
acceptance root; current authorized boot ID; FQDN, architecture, running kernel
and Slackware release; package-database manifest and installed header/generic
records with huge/modules absent; Slackpkg configuration/mirrors hashes;
staged-target SHA-256; accepted v3 tree/sidecar; preserved failed-v2 evidence and
boot/Slackpkg/GenInitrd fingerprints; absence of every final v4 output and
temporary build root. No guard may be weakened.

## Launch, result and single attempt

After all preflight guards, use exactly one
`bash -- "$builder" --build-local-source-v4` invocation. Recheck the builder
regular-file/SHA binding in the launch function. No executable bit or chmod is
required. Preserve paths containing spaces, the one exact builder argument,
and any nonzero builder exit status. Publish success only after exit zero.

The explicit authorization and controller procedure permit one attempt even on
failure, with no automatic or manual retry. This design does not add a persistent
attempt marker or claim replay prevention through a reusable command. A later
failure must be returned for review without rerunning anything.

## Implementation acceptance plan

Require an exact allowlisted derivation, byte-identical existing guard functions,
and the unchanged frozen builder. Test the strict CLI and rejection before
surrogate entry; use a synthetic inert script to test mode 0644, spaced paths,
missing/symlink/changed scripts, exact arguments, failure-status propagation and
absence of success after failure. The explicit library-only seam must not enter
production main, alter frozen production constants, or touch host paths during
synthetic acceptance. Normal script execution must enter the guarded main.

## Authority

Only design freeze is opened: `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build-launch-remediation-executor-design-freeze`.
Implementation, target observation, transport/build, package/Slackpkg/network,
configuration/boot/reboot/cleanup, runtime rerun and Phase 2 remain closed.
Accepted v3 and failed-v2 evidence remain immutable. No new live-state claim is
made. `machine_action_required=false`, `controller_action_required=false`,
`pause_safe=false`, `strong_safe_pause=false`.
