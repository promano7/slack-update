# Phase 1 step 235 kernel-package-edge runtime-transaction remediation runtime candidate-set binding freeze

Step 235 consumes the accepted step-234 repository-only candidate-set binding review and freezes that contract without changing its semantics. No live candidate set is created, and no machine authority is inherited from the earlier target observation.

## Frozen candidate-binding contract

The truthful pre-staging upgrade-candidate count remains zero because `kernel-headers-6.18.45-x86-1` is already installed. The future binding exists only after the exact `kernel-headers-6.18.44-x86-1` predecessor has been staged inside the same bounded runtime transaction.

The only candidate source remains `file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2`, bound to v2 tree-manifest SHA-256 `e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945` and target SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`.

The future transaction must use a new empty transaction-owned Slackpkg workdir. Its `pkglist` must be absent before the guarded local refresh and created by that refresh. The pre-existing `/var/lib/slackpkg/pkglist` cannot prove freshness. Refresh acceptance requires exit status zero and captured output without `error-downloading-from-local-source`.

The global `pkglist` row-count guard is permanently retired for this scenario. Candidate acceptance is target-specific and must prove exactly one `kernel-headers-6.18.45-x86-1` row from `./slackware64/d`, zero `install-new` candidates, zero non-header upgrade candidates, and zero configured boot-package upgrade candidates. The binding must trace to the frozen target bytes and v2 manifest, use real-tab TSV evidence, and be consumed without pause in the same transaction.

Any relevant boot-ID, package-state, Slackpkg-configuration, v2-source, workdir, or refresh-execution change invalidates the binding and requires a fresh fail-closed observation inside a newly authorized transaction.

## Executor remediation design boundary

The candidate-binding contract is now frozen input for the remediated executor design. The design must preserve the accepted transaction order: revalidate frozen inputs, verify predecessor bytes, stage only the 6.18.44 header, prove a header-only delta and unchanged boot state, create the fresh Slackpkg workdir, activate bounded local-only configuration, reverify v2 immediately before refresh, perform the guarded local refresh, bind the exact target candidate, consume it immediately with the frozen reference apply or rollback, restore Slackpkg and the 6.18.45 header baseline, and publish success only after final invariants pass.

The next design review may change executor logic only where required to conform to this frozen remediation contract. It may not weaken the original rollback, boot-state, package-state, source-integrity, evidence-preservation, or no-external-network invariants.

## Authorization boundary

Step 235 authorizes only repository-side runtime-executor remediation design review. It does not authorize target observation, predecessor transport or staging, Slackpkg mutation, metadata refresh, live candidate binding, executor implementation or transport, runtime rerun, package action, network access, boot action, reboot, evidence cleanup, persistent configuration change, or Phase 2.

Next stage: `phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-design-review`. The remediation family remains active with `machine_action_required=false`, `controller_action_required=false`, `pause_safe=false`, and `strong_safe_pause=false`.

Frozen helper SHA-256: `0ea822e030dbf22304f4564f9e075fc0e1d3da38f2b9b0621b986ac5f3783cf8`.
Frozen policy SHA-256: `73244a59e776a9a9ab41802d1995211a1e3ba2505cb36bf950f09ba7084f6878`.
Frozen record SHA-256: `0496250d4f680485559b043278725c5437f6fe830d2692640feeb479b4b8f389`.
