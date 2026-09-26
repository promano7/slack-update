# Phase 1 kernel-package-edge runtime transaction failure characterization freeze and remediation boundary review

Step 219 consumes the accepted step-218-r1 read-only failure characterization and freezes the first runtime attempt as a contained failure with a successful rollback.

The accepted characterization is: `failure_characterization_status=PASS`, cleanup triggered, `kernel-headers-6.18.45-x86-1` restored, frozen package database restored, Slackpkg configuration and state restored, GenInitrd policy restored, `/boot` unchanged, and no published success evidence. The failed Slackpkg refresh returned exit code `0` while exposing `error-downloading-from-local-source`. After cleanup, the restored Slackpkg `pkglist` contains 2032 rows, exactly one of which corresponds to the target package, and the accepted local source lacks `CHECKSUMS.md5.asc`.

These facts supersede the first executor's candidate-binding assumption. A zero Slackpkg refresh exit status alone is not sufficient evidence of a successful local refresh, and the total row count of `/var/lib/slackpkg/pkglist` is not a valid standalone candidate guard when freshness has not first been proved.

## Frozen remediation boundary

The accepted `local-source` v1 tree and the failed runtime evidence root are evidence and must remain byte-preserved. They must not be edited in place, deleted, or reused as proof of a successful rerun.

The next implementation must create a separately named `local-source-v2` generation with deterministic Slackpkg refresh-compatibility metadata. The v2 design must include the metadata required for Slackpkg's local refresh path, including a bounded `CHECKSUMS.md5.asc` compatibility artifact and the required priority-tree metadata. The compatibility `.asc` artifact is not accepted as package-authenticity evidence; package identity remains bound by the frozen package SHA-256 and the new source tree manifest.

A remediated refresh may be accepted only when all of the following hold in the same guarded execution: Slackpkg exits zero, no `error-downloading-from-local-source` signal is present, the Slackpkg work metadata is proven fresh against the v2 source, and the candidate guard observes exactly one target-specific `kernel-headers` row with the frozen predecessor installed and the row bound to the frozen target/source. The old global `pkglist` row-count requirement is retired.

Future executor evidence must use real tab characters for TSV output rather than literal backslash-t sequences. The v2 refresh and candidate-binding remediation must be validated before any new package mutation is authorized.

Step 219 is repository-only. It authorizes no runtime rerun, package action, Slackpkg mutation, repository/network access, boot action, reboot, persistent configuration change, evidence deletion, or Phase 2 action. The next stage is a strong-safe-pause review of this remediation boundary.
