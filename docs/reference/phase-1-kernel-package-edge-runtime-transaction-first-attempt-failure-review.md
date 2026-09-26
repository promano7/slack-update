# Phase 1 kernel-package-edge runtime transaction first-attempt failure review

Step 218 records the first authorized runtime transaction attempt as a fail-closed failure before the reference apply was reached.

The observed terminal message was:

`ERROR: refreshed local pkglist contains 2032 package rows instead of exactly one`

The failure occurred after temporary predecessor staging and after the local Slackpkg refresh attempt, so the rollback trap must be verified before any further runtime authorization. This step therefore authorizes only the exact read-only failure-characterization probe with SHA-256 `0f9388cde7fcb178e8f06ff2b200d503c29fb454fa9502091701cc5d2752098d` and acknowledgement `--observe-failure-cleanup`.

The probe verifies that the target `kernel-headers-6.18.45-x86-1`, frozen package database, Slackpkg configuration and state, GenInitrd policy, /boot fingerprint, boot ID, staged target, and local source were restored or remained unchanged. It also requires the failed evidence root to exist, requires successful cleanup evidence, requires success evidence to be absent, records the Slackpkg update exit status, and confirms that the frozen local source does not contain `CHECKSUMS.md5.asc`.

No rerun, package mutation, Slackpkg mutation, network access, boot action, reboot, evidence deletion, or Phase 2 action is authorized by this review. The failed evidence root must be preserved for the next freeze/remediation stage.

## Step 218-r1 probe-format remediation

The first step-218 probe invocation failed before characterization because the step-217 executor wrote `preflight.tsv` with literal `\t` separators inside an unescaped heredoc, while the probe initially accepted only real tab separators. This was a probe/parser mismatch; it did not authorize or perform any additional machine mutation.

The revised read-only probe accepts both the literal `\t` encoding produced by the failed first runtime attempt and real TSV tabs, while preserving every cleanup, package, Slackpkg, GenInitrd, `/boot`, local-source, and no-success-evidence guard. Runtime rerun remains unauthorized.
