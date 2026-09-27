# Phase 1 step 228 — local-source-v2 prebuild fresh target revalidation review

## Status

**PASS — one exact read-only prebuild target observation is authorized.**

Step 227 froze the local-source-v2 builder at SHA-256 `8e2803813e9004130b26b402346cf81061377efe78974e902c65f7807d841b2d` but deliberately did not
transport or execute it. Step 228 therefore does not build anything. It authorizes only the exact
standalone probe at SHA-256 `207ce41439c6ce2fe0f98a40266528bed4178073d5bab781d19b6d938bc64984` to be copied to `vbox-slackcurrent`, verified byte-for-byte,
and run once through `sudo` with `--observe-prebuild-fresh-target-revalidation`.

## What the observation must prove

The probe revalidates the restored Slackware-current target baseline immediately before any future
builder use: hostname/architecture/kernel, package database manifest, installed kernel package
records, Slackpkg configuration, preserved local-source v1, staged 6.18.45 target, failed-run evidence,
and the accepted `/boot`, Slackpkg-state and geninitrd-policy fingerprints.

It additionally proves that the final `local-source-v2` tree, its manifest/sidecar, and every
`.local-source-v2.build.*` temporary tree are absent. This makes the later builder run fail-closed
against a pre-existing or partially published v2 result.

The previously frozen boot ID is historical context only and is intentionally not embedded in the
probe. A successful observation must return the current non-empty boot ID; step 229 will decide
whether to freeze that returned observation and issue a single-use builder authorization.

## Explicitly still unauthorized

The probe does not transport or execute the builder. `local-source-v2` construction, Slackpkg or
repository refresh, candidate binding, package mutation, network access, boot changes, reboot,
evidence cleanup and Phase 2 all remain unauthorized. The only machine action in this step is the
read-only observation itself.

## Next gate

After a successful returned observation, the next repository review is
`phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v2-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review`.
That review must consume the returned evidence before it may authorize the exact frozen builder.
