# Phase 1 step 281 — boot-drift revalidation probe design review

## Accepted checkpoint and scope

Consume accepted step 280, user commit prefix `e24690d`, full
`PASS (165 passes, 0 failures)`, successful user commit/push and clean working tree.
The full object ID was not supplied. Its old prepared/pending CHANGELOG wording is
superseded by this acceptance. All consumed historical permissions remain closed.
Current boot ID, target preservation and v4 output absence are not observed here.

This is a repository design review, not a probe implementation or live observation.
The exact proposed byte derivation is represented as six ordered replacements
over the immutable historical probe SHA-256 `3bd3db28f483e9ff842a4f6899ace758acadfc96a92ee2fe55bb5a2fe36577a2`.
In-memory reconstruction and Bash syntax validation review this design; no future
probe is installed or invoked by the step. Its reviewed derivation SHA-256 is
`fe1724a39aeaf4d14165df3d4aaada2ba009f9b01474a50c3083d4775bfe6a2b` and is not an execution authorization.

## Reviewed new probe contract

Future path: `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation-probe.sh`.
Future observation argument: `--observe-v4-preflight-boot-drift-fresh-target-and-output-absence-revalidation`.
Future status field: `v4_preflight_boot_drift_fresh_target_and_output_absence_revalidation_status`.

Retain all nine historical guard function bodies and every readonly constant
exactly. Only help basename, observation switch and status identity change;
the existing canonical UUID guard is moved into an equivalent pure validator;
an explicit sourced-library-only test seam is added. No target constant, path,
fingerprint, target/output guard, success ordering or other publication field is
changed. No executor or builder transport is an observation prerequisite.

The UUID is read from `/proc/sys/kernel/random/boot_id` by the future authorized
probe main and must have canonical lowercase 8-4-4-4-12 hexadecimal form. The CLI
accepts no supplied boot UUID or historical default. A freshly observed value can
equal a historical UUID; permission still comes from the new observation and
authorization. Do not substitute the UUID from an error or compare against history
as a way to accept or reject a fresh binding.

The probe keeps the canonical pkgtools database/compatibility link, current target
identity and package records, Slackpkg configuration/state, staged target, accepted
v3 tree/manifest/sidecar, failed-v2 evidence and empty pkglist, boot/GenInitrd
fingerprints, and all v4 final/temporary output-absence checks. Any drift rejects
before PASS, with no cleanup, constant patching, build or automatic/manual retry.

## Isolated future tests

An explicit `SLACK_UPDATE_V4_BOOT_DRIFT_REVALIDATION_LIBRARY_ONLY=1` requires sourcing and skips main.
Default direct execution still runs main; direct execution in library-only mode
rejects. Future implementation acceptance may call the pure UUID validator and
the exact `regular_sha256` function on temporary synthetic files. It must never
modify frozen production constants, invoke host-bound package/evidence/boot/output
guards, or enter production main/builder. Test valid canonical UUIDs, malformed,
uppercase, missing and extra arguments, and missing/symlink/changed synthetic files.

The design review replays only the proposed pure UUID validator with the exact
historical fail function. Guard preservation and publication order are inspected
from the exact in-memory derivation. This is not a production probe test.

## Publication, authorization and continuation

Only after every guard succeeds may the future probe publish its 41 ordered
real-tab TSV fields. Retain every historical field/value contract except the
renamed status identity and freshly read boot/probe identity. Its self SHA-256
identifies the actual executed file; the frozen builder SHA is repository context,
not proof that a builder was transported or executed. Require complete returned
stdout/stderr and exit status before observation acceptance.

No implementation, transport, probe invocation, build, package/Slackpkg/network,
configuration/boot/reboot/cleanup, runtime rerun or Phase 2 is authorized now.
Only repository design freeze at step 282 is open. Implementation review/freeze
must precede a new explicit step-285 read-only observation authorization. The
unchanged nine-to-twelve-step roadmap grants no machine permission or fixed-date
pause guarantee. Keep the same uninterrupted VM boot from that future observation
through any later authorized build; the immutable executor still checks all guards.

The helper re-requires the full accepted step-280 165-pass suite. Current planning
state: `machine_action_required=false`, `controller_action_required=false`,
`pause_safe=false`, `strong_safe_pause=false`. Step 279 remains the historical
accepted strong-pause checkpoint. Actual result/effect review and revocation are
required before a new strong safe pause.

Next: `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-preflight-boot-drift-revalidation-design-freeze`.
