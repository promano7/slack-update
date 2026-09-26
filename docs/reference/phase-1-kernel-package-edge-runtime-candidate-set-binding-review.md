# Phase 1 step 214 kernel-package-edge runtime candidate-set binding review

Step 214 consumes the corrected step-213-r1 fresh runtime identity and resolves
when a truthful runtime candidate set can be bound for the single
**kernel-package-edge** scenario. This is a repository-only review. It does not
stage the predecessor, change Slackpkg configuration, refresh metadata, bind a
live candidate set, execute the reference apply, or mutate the VM.

## Why the candidate set cannot be frozen yet

The accepted pre-staging target already has `kernel-headers-6.18.45-x86-1`
installed, while the preserved immutable local source exposes exactly
`kernel-headers-6.18.45-x86-1.txz`. Before predecessor staging, the truthful
upgrade candidate count is therefore zero. A repository-side claim that one
upgrade is already available would be false and is forbidden.

The predecessor remains `kernel-headers-6.18.44-x86-1`. Only after that exact
package has been staged on the still-bound VM can the local source legitimately
produce one upgrade back to the target. The live candidate set must therefore
be observed after predecessor staging and before the reference apply.

## Candidate binding contract

The later runtime transaction must bind exactly one upgrade candidate:

- package: `kernel-headers`;
- installed predecessor: `kernel-headers-6.18.44-x86-1`;
- candidate target: `kernel-headers-6.18.45-x86-1`;
- `install-new` candidates: zero;
- non-header upgrade candidates: zero;
- configured boot-package upgrade candidates: zero.

The candidate source remains
`file:///var/tmp/slack-update-acceptance/kernel-package-edge/local-source` and
its accepted external tree-manifest SHA-256 remains
`0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e`.
Runtime network access is forbidden.

A candidate binding is valid only inside the same controlled runtime
transaction that stages the predecessor and consumes the candidate set. It may
not be treated as a durable pre-staging binding, carried across a pause, or
reused after any package-state, boot-ID, local-source, or Slackpkg-configuration
change.

## Required runtime ordering

The later executor design must preserve this fail-closed sequence:

1. revalidate the frozen step-213-r1 runtime identity;
2. verify the preserved local-source tree and frozen predecessor bytes;
3. stage only the 6.18.44 `kernel-headers` predecessor;
4. prove the package delta is header-only and boot artifacts are unchanged;
5. activate temporary local-only Slackpkg configuration;
6. refresh metadata from the immutable `file://` source only;
7. bind the exact candidate set described above;
8. immediately consume that binding with the reference apply or rollback;
9. restore Slackpkg configuration byte for byte;
10. finish only with the target 6.18.45 header state and unchanged boot state.

Leaving the predecessor installed is not an acceptable successful terminal
state. Any failure after predecessor staging must restore the bound target
header package before the transaction returns.

## Authorization boundary

Step 214 authorizes only repository-side design review of the future atomic
runtime transaction executor. It does **not** authorize predecessor transport or
staging, temporary Slackpkg configuration, local metadata refresh, live
candidate binding, `slack-update-reference.sh --apply`, package action, network
access, boot action, reboot, or Phase 2.

The next stage is
`phase-1-kernel-package-edge-runtime-transaction-executor-design-review`.
Step 214 is not a safe-pause checkpoint because the family is still active, so
`pause_safe=false`.

Frozen helper SHA-256: `6bbc9e32e52163025a8947e0a8cb172c8a710ab91dc8420c9a940b9186a325e2`.  
Frozen policy SHA-256: `c5fcead64abd1c2d4136c754da6bcca56e2ec5ed16ba1e7193d55c8dceff21aa`.  
Frozen record SHA-256: `fd76bd3d83f50e71210bc7b38f2604eb119432ec716af64f0b8608c440228007`.
