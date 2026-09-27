# Phase 1 step 247 — local-source-v3 prebuild fresh target revalidation review

## Status

PASS. The frozen step-246 implementation contract is accepted unchanged and one exact read-only target observation is authorized before any local-source-v3 builder transport or execution.

## Read-only observation boundary

The only machine-side action opened by this step is one root execution of `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-review-probe.sh` at SHA-256 `7872bbcad0c21515273451a919deaeba9e1a84d8ad79a03160bbc1f822827949` with acknowledgement `--observe-prebuild-v3-fresh-target-revalidation`.

The probe is standalone and read-only. It does not depend on a preserved executor copy in `~/Descargas`; it reads only canonical target state and preserved evidence under `/var/tmp`. It must observe a fresh boot ID rather than reuse any previous runtime binding.

## Required baseline proof

The observation must revalidate the restored `vbox-slackcurrent` baseline: running kernel `6.18.45`, installed `kernel-headers-6.18.45-x86-1` and `kernel-generic-6.18.45-x86_64-1`, package-database manifest SHA-256 `726a67acda9e270555a0a8d9f80e78a8f66400d843a947480c0d7d8ad4a7a1b6`, accepted Slackpkg configuration fingerprints, and staged target SHA-256 `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`.

The accepted `local-source-v2` tree must verify against manifest SHA-256 `e775e47078c266f6f0219aa5899c430293d6181433e53deec02e30fb127ca945`, including its external sidecar. Its historical compatibility `.asc` must still lack a `PGP` marker; v2 is immutable failure evidence and is not repaired in place.

The failed remediation evidence root must remain present with no `result.tsv` and no published success archive. The captured Slackpkg update must still record exit status `0`, the human-spaced `Error downloading from ` signal must remain preserved, the failed transaction-owned `pkglist` must remain absent, and current `/boot`, Slackpkg state, and GenInitrd policy must match the failed remediation preflight fingerprints.

## local-source-v3 absence requirement

Before any future build authorization, all final v3 outputs must be absent:

- `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3`
- `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256`
- `/var/tmp/slack-update-acceptance/kernel-package-edge/local-source-v3.tree.sha256.sha256`

No `.local-source-v3.build.*` sibling temporary root may exist either.

The frozen builder remains `tools/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-build.sh` at SHA-256 `56cf6248b90d8120f8a949a7a0ceeeec544bb95b18f40e49344ad06fc7d5c582`. The probe neither transports nor executes it. The future runtime-transaction-remediation-v2 executor remains reviewed and frozen but not implemented.

## Closed boundaries

This step does not authorize builder transport/execution, local-source-v3 construction, package or Slackpkg mutation, repository refresh, network access, executor-v2 implementation or transport, runtime rerun, boot mutation, reboot, evidence cleanup, or Phase 2.

## Next gate

Return the complete output from the one read-only probe. A successful observation may then be consumed only by `phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v3-prebuild-fresh-target-revalidation-freeze-and-build-authorization-review`.

`pause_safe=false` because a read-only machine observation remains outstanding.
