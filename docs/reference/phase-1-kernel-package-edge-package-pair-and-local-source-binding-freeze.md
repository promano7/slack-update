# Phase 1 kernel-package-edge package-pair and local-source binding freeze

Step 197 consumes the successful step-196 controller acquisition observation
and freezes the exact bytes that may be used by the remaining
`kernel-package-edge` acceptance chain. This is a repository-only freeze. It
does not copy artifacts to the target, build the local source, mutate packages,
or authorize network access.

## Accepted controller evidence

The accepted acquisition observation reported `PASS` and preserved its complete
evidence root at:

`/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts`

That directory must remain unchanged until the local-source construction chain
has consumed and reverified it. The frozen evidence identities are:

- `binding-evidence.tsv`: SHA-256
  `dd3037a58a3a2455d5c4e960ac027bed3dc644a193c22e9ec806a43d91b2ae63`;
- `acquired-files.sha256`: SHA-256
  `1292ade434fd52b90f4230955610d5a0ca70fb0c586a6a6488ecf912621cf86f`;
- downloaded Slackware `GPG-KEY`: SHA-256
  `82af92f3a9abdae815534912e7c438f1bad50b8516bb8d75fe9e08444f727daf`;
- signing fingerprint
  `EC5649DA401E22ABFA6736EF6A4463C040102233`.

## Frozen package pair

The predecessor is frozen as `kernel-headers-6.18.44-x86-1`:

- package SHA-256:
  `3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d`;
- detached-signature SHA-256:
  `e818c8b1c665aabc8724e8a301de5a711eb949bbf2dfd92dba8ce5ced7bdcf21`;
- signature result: `VALID` for the frozen Slackware signing fingerprint.

The target is frozen as `kernel-headers-6.18.45-x86-1`:

- package SHA-256:
  `c7b56b50f0abdec8f35628d526bb05488c257f667ab9c2be1a7a3e07d97da63c`;
- detached-signature SHA-256:
  `66787e515d7d4420daab5aac412cd8ac5921a1dff037147b8216e1017ac1c801`;
- signature result: `VALID` for the frozen Slackware signing fingerprint.

The accepted step-196 observation also records that it performed no target-VM
network access, no target action, no package action, no boot action, and no
reboot.

## Authorization closure

Step 197 closes the temporary controller acquisition authorization granted by
step 196. No further controller download or generic network access is
inherited. Re-downloading either artifact, signature, or signing key requires a
new explicit authorization boundary.

The target VM remains untouched and offline. Target copy, local-source build,
package mutation, boot mutation, reboot, runtime-executor implementation,
runtime scenario execution, and Phase 2 remain unauthorized.

The next stage is
`phase-1-kernel-package-edge-local-source-construction-review`. That review may
consume only the preserved bytes bound here and must fail closed on any hash or
signature-evidence mismatch.

This step is not yet the requested strong safe pause (`pause_safe=false`),
because the selected family remains inside an active construction chain.

Frozen helper SHA-256: `f9bacedb9c65576a9b7eb32ac53e4465088f5ef8700976ed8a5b6cb31d2f7ebb`.  
Frozen policy SHA-256: `79c0841d604556960fef613b2d0e2c1ed54e2ae32cdac5ddef8b3787363a4d12`.  
Frozen record SHA-256: `abcd032f614dc42e24f820fd8360f864b729897eba964c91d62a1171da0f9449`.
