# Phase 1 step 264 — local-source-v4 builder implementation freeze

## Purpose

Freeze the exact step-263 reviewed `local-source-v4` builder implementation before any target-machine revalidation or production build.

## Accepted inputs

- Step-263 helper SHA-256: `546cc2c6bcb50ea64dfcde09d9facdd997dc6f1c615e04c07d944596d2557445`.
- Step-263 document SHA-256: `df86e5f3e7002dd6fbffd53951d15242c917ad0514c5122e38597b7f7dd9c72b`.
- Step-263 harness SHA-256: `09e8242d0ec4a457cce3df528e73a92419d4c6f663d2127d4ff25521a1cfc5b2`.
- Step-263 policy SHA-256: `2d43ad83fbdd51dfcadcb9dc0b2f61403ab4ab883c18108c02b0e2595efe1dc7`.
- Step-263 record SHA-256: `42289765f73553f2d8ffac31c1d04dbe3208045c5e2e8a3375260b227e0eee28`.
- Immutable v3-r1 builder SHA-256: `80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30`.
- Reviewed v4 builder SHA-256: `38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7`.

## Frozen implementation

`tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-build.sh` is now frozen at SHA-256 `38e83b300807fd23748bd2aa9e0ce86230da7a7270b6f01e9f54671331db80b7` with state `implementation-frozen-not-executed`.

The functional remediation remains limited to `CHECKSUMS.md5` record representation. The writer is ordinary GNU `md5sum -- "$rel"`, so each checksum row has `<32-lowercase-hex-md5><two spaces>./relative/path` and the path is the final field. Tagged `MD5 (...) = digest` records remain forbidden. The exact-binding validator and the complete synthetic gate set from step 263 are frozen as acceptance requirements.

The accepted v3-r1 builder remains immutable historical evidence and must retain SHA-256 `80cc0244df0ed578576d5dd74b962dcf3d279afe5e22c08b8d3e7b65d7e2ba30`.

## Acceptance rerun

The step-264 harness reruns the complete accepted step-263 repository harness and requires `Result: PASS (77 passes, 0 failures)`. It also independently binds the step-263 artifacts, v3 builder, v4 builder, generated step-264 policy/record, documentation, and CHANGELOG entry.

No production `local-source-v4` builder execution is performed by this step.

## Next boundary

Only a fresh read-only target-machine revalidation is opened next. It must revalidate the expected `kernel-headers-6.18.45-x86-1.txz` identity and frozen SHA-256, confirm the predecessor remains absent, and prove the distinct v4 output paths are absent before any build authority can be considered.

That revalidation must not execute the v4 builder, refresh Slackpkg, mutate packages, change persistent configuration, access the network, or perform boot/reboot actions.

Step 264 is not a strong safe pause: `pause_safe=false`, `strong_safe_pause=false`. It requires a bounded read-only machine observation next (`machine_action_required=true`).
