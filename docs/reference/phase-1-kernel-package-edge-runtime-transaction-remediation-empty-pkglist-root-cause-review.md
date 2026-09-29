# Phase 1 step 259 — empty-pkglist root-cause review

## Status

PASS. Step 259 consumes only the repository-review continuation opened by the step-258 strong safe pause. It performs no target observation or mutation and freezes the exact cause of the zero-byte transaction-owned Slackpkg `pkglist`.

## Frozen root cause

The accepted `local-source-v3` builder writes `CHECKSUMS.md5` with GNU `md5sum --tag`. For the only package in the source, that produces a line shaped as:

`MD5 (./slackware64/d/kernel-headers-6.18.45-x86-1.txz) = <32-hex-digest>`

The accepted v3 builder also validates this tagged representation, so the format was internally consistent and passed the repository/local-source validation that preceded executor-v2.

Slackpkg package-list generation, however, uses `CHECKSUMS.md5` as the package-row source and selects package checksum lines by a terminal Slackware package extension (`.tgz`, `.tbz`, `.tlz`, or `.txz`) before passing the path to `pkglist.awk`. The Slackpkg parser treats the final whitespace-delimited field as the package path.

A GNU tagged checksum line ends in the digest rather than the package path. Therefore the v3 target checksum line does not match Slackpkg's terminal package-extension filter and never reaches `pkglist.awk`. Since local-source-v3 contains exactly one package, the generated package list has exactly zero package rows.

This predicts the observed executor-v2 evidence exactly: a newly created regular `pkglist` of zero bytes with SHA-256 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`, followed by the fail-closed candidate-binding error `ERROR: fresh pkglist exposes 0 exact target candidates instead of one`.

The failure is therefore frozen as `slackpkg-incompatible-tagged-checksums-md5-package-line-format`. Candidate row matching is not causal because no row existed to match. `FILELIST.TXT` and `PACKAGES.TXT` are not the package-row source at this Slackpkg formatting stage.

## Reproduction

The step-259 helper performs a repository-only synthetic reproduction. The same target path written with `md5sum --tag` does not pass the Slackpkg package-line filter and does not expose the package path as its final field. The same path written with normal untagged GNU `md5sum` output does both:

`<32-hex-digest>  ./slackware64/d/kernel-headers-6.18.45-x86-1.txz`

This establishes the required checksum-format correction without touching the VM or the preserved failed runtime evidence.

## Remediation boundary

The accepted `local-source-v3`, its external manifest, the v3 builder bytes and the failed executor-v2 evidence remain immutable historical evidence. They must not be edited in place, and executor-v2 must not be rerun.

Remediation must use a new `local-source-v4` revision. Its `CHECKSUMS.md5` package entries must use the ordinary untagged GNU `md5sum` representation so the package path is the final field and the line ends in `.txz`. Package authenticity remains anchored in the frozen package SHA-256 and the external source-tree manifest. The compatibility `.asc` artifact remains explicitly non-cryptographic.

No v4 builder implementation or build is authorized by this step. The next repository-only stage must freeze the root-cause finding and define the exact local-source-v4 remediation boundary before any implementation or target action.

## Authority

All machine/runtime authority remains closed. Target observation, probe transport, local-source construction, executor build/transport, predecessor transport/staging, temporary Slackpkg mutation, metadata refresh, candidate binding, reference apply, package action, external network, boot action, reboot, evidence cleanup and Phase 2 remain forbidden.

`machine_action_required=false` and `controller_action_required=false`. Step 259 itself is not a strong safe pause because it opens the next repository-only review stage. The next stage is `phase-1-kernel-package-edge-runtime-transaction-remediation-empty-pkglist-root-cause-freeze-and-local-source-v4-boundary-review`.
