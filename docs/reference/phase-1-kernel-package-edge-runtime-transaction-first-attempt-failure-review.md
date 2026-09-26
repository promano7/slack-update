# Phase 1 kernel-package-edge runtime transaction first-attempt failure review

Step 218 records the first authorized runtime transaction attempt as a fail-closed failure before the reference apply was reached.

The observed terminal message was:

`ERROR: refreshed local pkglist contains 2032 package rows instead of exactly one`

The failure occurred after temporary predecessor staging and after the local Slackpkg refresh attempt, so the rollback trap must be verified before any further runtime authorization. This step therefore authorizes only the exact read-only failure-characterization probe with SHA-256 `a5ec4bb7ecffa052edd540729c8f1cf44e0c68e4e0283d196ae4ad71a6898ae1` and acknowledgement `--observe-failure-cleanup`.

The probe verifies that the target `kernel-headers-6.18.45-x86-1`, frozen package database, Slackpkg configuration and state, GenInitrd policy, /boot fingerprint, boot ID, staged target, and local source were restored or remained unchanged. It also requires the failed evidence root to exist, requires successful cleanup evidence, requires success evidence to be absent, records the Slackpkg update exit status, and confirms that the frozen local source does not contain `CHECKSUMS.md5.asc`.

No rerun, package mutation, Slackpkg mutation, network access, boot action, reboot, evidence deletion, or Phase 2 action is authorized by this review. The failed evidence root must be preserved for the next freeze/remediation stage.
