# Phase 1 step 244 — kernel-package-edge runtime-transaction second failure remediation design freeze

## Status

`PASS` — the accepted step-243 repository-only remediation design is frozen
unchanged. This step performs no machine action and grants no build, package,
Slackpkg, network, boot, reboot, transport, cleanup, or runtime-rerun authority.

## Accepted input

Step 243 reviewed the second remediation after the confirmed runtime failure
mechanism:

- the runtime rollback baseline is restored and remains authoritative;
- `local-source-v2` is preserved as immutable historical evidence;
- the failed `runtime-transaction-remediation` executor generation is preserved
  as immutable historical evidence;
- the observed installed Slackpkg requires a literal `PGP` marker in the
  downloaded `CHECKSUMS.md5.asc`;
- the failed source's compatibility `.asc` did not contain that marker;
- Slackpkg emitted the human-spaced prefix `Error downloading from ` while
  returning status 0; and
- the failed executor searched for a different hyphenated literal and therefore
  did not fail at the correct signal boundary.

## Frozen remediation design

The design is now frozen as follows.

### New local source generation

The next source generation is `local-source-v3`, rooted at:

`/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3`

It MUST be a new generation. `local-source-v2` MUST NOT be modified in place.
The v3 package bytes and priority-tree semantics remain derived from the frozen
v2 contract, and the target package bytes must still equal the accepted staged
target.

The v3 compatibility `CHECKSUMS.md5.asc` MUST contain the literal marker:

`PGP compatibility marker for Slackpkg checkchangelog only.`

That marker exists only to satisfy the observed installed Slackpkg
`checkchangelog` marker gate. The compatibility file MUST state that it makes
no cryptographic authenticity claim, MUST NOT impersonate an upstream
signature, and MUST NOT contain `BEGIN PGP SIGNATURE`. Runtime `CHECKGPG`
remains `off`.

### Future executor generation

A new executor generation is required:

- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-body.sh`
- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor-build.sh`
- `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-v2-executor.sh`

The failed executor generation MUST remain unchanged. The future executor must
bind to `local-source-v3`, and its final exact v3 manifest identity may only be
bound after the v3 build has been accepted.

The future runtime acknowledgement remains reserved as:

`--execute-runtime-remediation-v2-validation`

No runtime execution is authorized by this freeze.

### Refresh success and failure guards

A Slackpkg refresh is successful only when all independent checks pass:

1. the command exit status is zero;
2. captured stdout/stderr does not contain the real human-spaced error prefix
   `Error downloading from `;
3. a fresh transaction-owned `pkglist` exists in the isolated `WORKDIR`; and
4. the target-specific candidate guard succeeds in the same transaction.

The old hyphenated-literal guard is retired. Exit status zero alone is never
sufficient evidence of a successful refresh.

### Retained invariants

The next implementation must retain the already accepted runtime invariants:
transaction-owned `WORKDIR` and `TEMP`, no external network, exact predecessor
and target bytes, header-only staging delta, target-specific same-transaction
candidate binding, real-tab TSV evidence, rollback on every post-mutation
failure, Slackpkg and GenInitrd restoration, unchanged boot artifacts, and no
reboot.

## Authorization boundary

This freeze opens exactly one repository-side next stage:

`phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-failure-remediation-implementation-contract-review`

That next review may define the v3 builder and the future executor-v2 contract.
It does not yet authorize implementing or executing machine-side build/runtime
actions. In particular, local-source-v3 build, executor-v2 runtime transport,
package or Slackpkg mutation, repository refresh, external network, boot,
reboot, evidence cleanup, and Phase 2 remain closed.

`machine_action_required=false`, `controller_action_required=false`, and
`pause_safe=false`.

## Next stage

Review the repository implementation contract for the new local-source-v3
builder and future runtime-transaction-remediation-v2 executor while preserving
all historical evidence and the frozen design above.
