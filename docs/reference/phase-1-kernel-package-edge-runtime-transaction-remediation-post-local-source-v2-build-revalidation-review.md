# Phase 1 step 232 kernel-package-edge runtime-transaction remediation post-local-source-v2-build revalidation review

Step 232 consumes the accepted step-231 repository-only resume boundary and opens exactly one bounded read-only observation of the Slackware-current validation VM. No pre-pause or prebuild target identity is reused as machine authority.

## Fresh target observation

The standalone probe records a fresh boot ID while requiring the live target to remain compatible with the accepted restored baseline: FQDN `vbox-slackcurrent.vbox-slackcurrent.org`, architecture `x86_64`, running kernel `6.18.45`, Slackware release `Slackware 15.0+`, package-database manifest `726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6`, installed `kernel-headers-6.18.45-x86-1` and `kernel-generic-6.18.45-x86_64-1`, no `kernel-huge` or `kernel-modules`, and the accepted Slackpkg configuration fingerprints. The fresh boot ID may equal the previously observed boot ID; freshness means that it is observed again under this authorization rather than inherited.

## Accepted v2 source verification

The staged target must still hash to `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`. The accepted `local-source-v2` root must still be bound to tree-manifest SHA-256 `e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945`; the external sidecar must verify and every regular file in the tree must match the frozen manifest.

The probe additionally requires that the manifest covers exactly the accepted regular-file set, the frozen directory set, no symlinks or unsupported filesystem objects, root ownership and read-only modes, exactly one package archive, absence of the 6.18.44 predecessor archive, the five priority-tree `PACKAGES.TXT` contract, complete `FILELIST.TXT`, the expected MD5 compatibility bindings, and the bounded `CHECKSUMS.md5.asc` role without a PGP-signature claim. No builder-owned temporary v2 root may remain.

## Historical evidence preservation

`local-source` v1 remains immutable historical evidence and must still verify against manifest SHA-256 `0a47285c0503565263e64369e2a3816e8fdfd34e18a0f5e25eb53ee378082e4e`, with `CHECKSUMS.md5.asc` still absent. The historical failed runtime evidence root must remain present, its accepted `/boot`, Slackpkg-state, and GenInitrd fingerprints must still match, `result.tsv` must remain absent, and no success archive/checksum may have appeared.

## Standalone probe and authorization

The only target program authorized by this step is `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-review-probe.sh`. It is self-contained and does not require the Git repository on the VM. The exact probe copy may be transported to the target and executed once through `sudo` with `--observe-post-v2-build-revalidation`.

The probe performs reads, hashes, and comparisons only. It performs no Slackpkg refresh, package mutation, candidate binding, repository/network access, runtime-executor remediation, runtime rerun, boot action, reboot, evidence cleanup, or persistent configuration change. Any drift fails closed and must be reviewed before the runtime chain advances.

A successful returned observation authorizes only repository-side `phase-1-kernel-package-edge-runtime-transaction-remediation-post-local-source-v2-build-revalidation-freeze`. It does not itself bind a candidate set or authorize executor remediation. `machine_action_required=true`, `controller_action_required=true`, and `pause_safe=false`.
