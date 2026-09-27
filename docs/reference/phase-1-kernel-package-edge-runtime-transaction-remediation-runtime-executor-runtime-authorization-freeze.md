# Phase 1 step 240 kernel-package-edge runtime-transaction remediation runtime authorization freeze

Step 240 consumes the accepted step-239 repository-only authorization review and freezes exactly one bounded runtime-remediation authority. This is the first step in the current remediation chain that authorizes controller and machine action.

## Single-use authority

The authority permits transport of exactly two frozen artifacts to `vbox-slackcurrent.vbox-slackcurrent.org`: the remediated executor SHA-256 `9647531df1ff4183a9fc0ea60db3b5d6f01179ef0a5971148e47f8223f645c4c` and the preserved predecessor `kernel-headers-6.18.44-x86-1.txz` SHA-256 `3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d`. Both controller and target copies must be verified before runtime start. Rebuilding the executor or redownloading the predecessor is not authorized.

The exact runtime command is:

```bash
sudo bash phase-1-kernel-package-edge-runtime-transaction-remediation-executor.sh \
  --execute-runtime-remediation-validation
```

The authority is consumed when that executor starts. A second execution is forbidden even if the first attempt exits during preflight. Any preflight failure returns the family to fresh runtime revalidation review before any new authority can be considered.

## Bounded mutation and preflight

Before its first mutation the frozen executor must revalidate the exact host, running kernel `6.18.45`, boot ID `fc6032e0-cfe2-4b5a-b4d8-2f60308cbcd9`, package database manifest, Slackpkg fingerprints, staged target, complete `local-source-v2` identity and structure, preserved failed evidence, and absence of the new remediation evidence outputs.

Only the bounded `kernel-headers 6.18.45 -> 6.18.44 -> 6.18.45` transaction, isolated local-source metadata refresh, same-transaction candidate binding, frozen reference apply, rollback/restoration, and remediation evidence publication are authorized. External network access, boot changes, reboot, evidence cleanup, persistent configuration change, a second run, and Phase 2 remain forbidden.

## Result boundary

After the single runtime start there is no pause-safe machine boundary until the executor exits and its evidence is reviewed. A successful run must emit `runtime_remediation_validation_status` as `PASS` and publish `/home/promano/slack-update-phase-1-kernel-package-edge-runtime-remediation-evidence.tar.gz` plus its `.sha256` sidecar. No further machine action is authorized before the result review.

The next stage is `phase-1-kernel-package-edge-runtime-transaction-remediation-runtime-result-review`.
