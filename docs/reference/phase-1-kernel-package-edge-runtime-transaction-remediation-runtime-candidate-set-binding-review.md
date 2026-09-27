# Phase 1 step 234 kernel-package-edge runtime-transaction remediation runtime candidate-set binding review

Step 234 consumes the accepted step-233-r1 fresh runtime identity as repository-only input and reviews the remediated candidate-set binding contract for the future atomic runtime transaction. No live candidate set is created by this step, and no machine authority is inherited from the step-232 observation.

## Why the live candidate still cannot be frozen

The accepted target state already has `kernel-headers-6.18.45-x86-1` installed. The accepted `local-source-v2` exposes the same 6.18.45 target package, so the truthful upgrade-candidate count before predecessor staging is zero. The future candidate becomes meaningful only after the exact `kernel-headers-6.18.44-x86-1` predecessor has been staged inside the same bounded transaction.

A durable pre-staging candidate binding remains forbidden. The candidate must be observed, validated, and consumed without a pause inside the transaction that staged the predecessor.

## Remediated refresh boundary

The only candidate source is `file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v2`, bound to external tree-manifest SHA-256 `e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945` and target SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`.

The later transaction must create a new empty transaction-owned Slackpkg workdir. Its `pkglist` must be absent before refresh and created inside that workdir by the guarded local refresh. The existing `/var/lib/slackpkg/pkglist` may not be reused as proof that the new refresh succeeded.

Refresh acceptance requires all of the following in the same transaction:

- verify the accepted v2 tree, external manifest sidecar, exact manifest coverage, priority-tree contract, and target bytes immediately before refresh;
- use the local `file://` source only, with external network access forbidden;
- use bounded temporary Slackpkg configuration with `CHECKGPG=off` only for the accepted compatibility role of `CHECKSUMS.md5.asc`;
- require refresh exit status zero;
- reject captured refresh output containing `error-downloading-from-local-source`;
- require a newly created transaction-workdir `pkglist`;
- use target-specific candidate validation rather than the retired global `pkglist` row-count guard.

Auxiliary metadata rows are therefore not themselves a failure. What matters is that the target-specific guard proves exactly one candidate for `kernel-headers-6.18.45-x86-1` from `./slackware64/d` while 6.18.44 is installed.

## Candidate binding contract

The future live binding must prove exactly:

- installed predecessor: `kernel-headers-6.18.44-x86-1`;
- upgrade target: `kernel-headers-6.18.45-x86-1`;
- matching target candidate rows: one;
- `install-new` candidates: zero;
- non-header upgrade candidates: zero;
- configured boot-package upgrade candidates: zero;
- evidence encoding: real-tab TSV.

The binding must trace the selected target back to the frozen target SHA-256 and v2 tree manifest. It is invalidated by any boot-ID, package-state, Slackpkg-configuration, v2-source, transaction-workdir, or refresh-execution change. Reusing a binding across a pause or a second refresh is forbidden.

## Required future transaction order

The future remediated executor must revalidate the accepted identity and v2 source, verify the frozen predecessor bytes, stage only the 6.18.44 header, prove the package delta is header-only with unchanged boot state, create the fresh Slackpkg workdir, activate local-only temporary configuration, verify v2 immediately before refresh, perform the guarded local refresh, bind the exact target-specific candidate set, and immediately consume it with the reference apply or rollback. Final success still requires restoration to the accepted 6.18.45 header state plus the existing package, Slackpkg, boot, source, and evidence invariants.

## Authorization boundary

Step 234 authorizes only repository-side freeze of this candidate-binding contract. It does not authorize target observation, predecessor staging, Slackpkg mutation, metadata refresh, live candidate binding, executor remediation, executor transport, runtime rerun, package action, network access, boot action, reboot, evidence cleanup, persistent configuration change, or Phase 2.

The next stage is `phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-candidate-set-binding-freeze`. The remediation family remains active, with `machine_action_required=false`, `controller_action_required=false`, `pause_safe=false`, and `strong_safe_pause=false`.

Frozen helper SHA-256: `00f6eb580fdde4777d22fe89807057bc81d64b7ce0ee369a0dd2ac7c0abb17b3`.
Frozen policy SHA-256: `2cf0b22bfc87cf302354074dfa011a89092a4ed71aeb34d82b09f93df0011521`.
Frozen record SHA-256: `a936f539f0b219f2b5e26937ec0ec72380b90ff72ba5babdd23867239e9d29bc`.
