# Phase 1 step 239 kernel-package-edge runtime-transaction remediation runtime authorization review

Step 239 consumes the accepted step-238 implementation freeze and reviews the exact contract for one future bounded runtime remediation transaction. This step is repository-only. It deliberately separates authorization design from authorization consumption: no executor or predecessor transport, staging, Slackpkg mutation, candidate binding, package action, or runtime execution is authorized yet.

## Exact future payload and transport contract

The only executor eligible for the later single-use authorization is `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh`, SHA-256 `9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c`. Its future target path is `/home/promano/Descargas/phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh`. Rebuilding before transport is not part of the reviewed runtime contract; the frozen bytes must be rehashed on the target before execution.

The only predecessor eligible for staging is `kernel-headers-6.18.44-x86-1.txz`, SHA-256 `3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d`, from the preserved controller source `/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts/kernel-headers-6.18.44-x86-1.txz`. Redownload remains forbidden. A future transport, if needed, must preserve these exact bytes and the target copy must be rehashed before execution.

## Fresh-state and fail-closed boundary

The future authorization remains bound to `vbox-slackcurrent.vbox-slackcurrent.org`, running kernel `6.18.45`, boot ID `fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9`, package-database manifest `726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6`, the frozen Slackpkg configuration fingerprints, staged target SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`, and local-source-v2 manifest SHA-256 `e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945`.

The executor must revalidate these conditions before its first mutation. Local-source-v2 must also pass sidecar verification, exact manifest coverage, priority-tree structure, bounded compatibility-asc semantics, ownership/mode checks, and target-byte verification. The historical failed evidence root must remain present while the new remediation evidence root and published remediation archive/checksum must be absent before runtime start.

Any drift in executor or predecessor bytes, host/kernel/boot identity, package database, Slackpkg fingerprints, staged target, local-source-v2, historical failed evidence, or absence of the new remediation evidence destinations invalidates the future authorization and routes back to fresh revalidation before mutation.

## Bounded future transaction

If the next step freezes the reviewed contract as a single-use authorization, the exact command will be:

`sudo bash phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh --execute-runtime-remediation-validation`

The authority will be consumed when runtime execution starts. Candidate binding remains `same-runtime-transaction-only`. The only bounded package transition is `kernel-headers` 6.18.45 to 6.18.44 and back to 6.18.45. Transaction-owned Slackpkg state, local file-source metadata refresh, target-specific source-backed candidate binding, and frozen reference apply may occur only inside that future authorized transaction. External network access, boot action, reboot, and persistent configuration changes remain forbidden.

The required terminal state restores `kernel-headers-6.18.45-x86-1`, the accepted package-database manifest, Slackpkg state/configuration, GenInitrd policy, boot artifacts, running kernel and boot ID. Publication of the remediation evidence archive and checksum is mandatory for result review, and no further machine action may follow until that result is reviewed.

## Current authorization boundary

Step 239 itself grants no machine authority. Executor transport, predecessor transport or staging, runtime execution, package action, Slackpkg mutation, metadata refresh, live candidate binding, reference apply, evidence cleanup, network access, boot/reboot action, and Phase 2 all remain closed. The only next action opened is repository-side `phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-executor-runtime-authorization-freeze`.

Frozen helper SHA-256: `c40913a7b59accd6a76ccb5435e4d12a85c828cc9bbbbcc991bf2949a8a8755c`.
Frozen policy SHA-256: `9bf93ea719de95e8413b36913bd347744cbcb0cd2431182e55ce87b3d9a338df`.
Frozen record SHA-256: `8884fdd1d74f7bbe7b358e4630a60090bad3b417d9c45802ee1acbe1abad9cd8`.
