# Phase 1 kernel-package-edge package-pair and local-source binding review

Step 196 consumes the accepted step-195 package-pair/local-source design and
freezes the **controller acquisition review gate** for the single documented
`kernel-package-edge` scenario. It does not yet bind package bytes or authorize
any action on the Slackware-current target VM.

## Reviewed package pair and archive origins

The logical pair remains:

- predecessor: `kernel-headers-6.18.44-x86-1`;
- target: `kernel-headers-6.18.45-x86-1`.

The cumulative Slackware64-current archive exposes the predecessor package and
signature with timestamp `2026-08-10 03:40` and the target package and signature
with timestamp `2026-08-20 05:19`, consecutively in the retained package
history. Step 196 freezes these exact HTTPS origins:

- `https://slackware.uk/cumulative/slackware64-current/slackware64/d/kernel-headers-6.18.44-x86-1.txz`;
- `https://slackware.uk/cumulative/slackware64-current/slackware64/d/kernel-headers-6.18.44-x86-1.txz.asc`;
- `https://slackware.uk/cumulative/slackware64-current/slackware64/d/kernel-headers-6.18.45-x86-1.txz`;
- `https://slackware.uk/cumulative/slackware64-current/slackware64/d/kernel-headers-6.18.45-x86-1.txz.asc`.

The cumulative site is an archive transport, not the trust anchor. Authenticity
is established independently through the Slackware Linux Project signing key.

## Slackware signing-key identity

The acquisition probe obtains `GPG-KEY` from the Slackware mirror service at:

`https://mirrors.slackware.com/slackware/slackware-current/GPG-KEY`

and fails closed unless the primary key identity is exactly:

- fingerprint: `EC5649DA401E22ABFA6736EF6A4463C040102233`;
- long key ID: `6A4463C040102233`;
- UID: `Slackware Linux Project <security@slackware.com>`.

Both detached signatures must produce a GnuPG `VALIDSIG` status for that exact
primary fingerprint. Automatic key retrieval is disabled. A merely successful
HTTPS download or matching filename is not sufficient evidence.

## Controller-only acquisition probe

The frozen probe is:

`tools/reference/phase-1-kernel-package-edge-controller-artifact-acquisition-probe.sh`

The probe must run **without root privileges** on the controller and requires a
new, caller-selected output directory. It downloads only the five frozen URLs:
the project key, two package artifacts, and their two detached signatures. It
performs no repository refresh and no target-VM access.

On success it preserves the acquired files plus:

- `binding-evidence.tsv` with package/signature SHA-256 values and signature
  validation results;
- `acquired-files.sha256` covering the key, both packages, both signatures, and
  the binding-evidence record;
- GnuPG inspection and detached-signature status logs.

The next gate must consume the complete probe output and freeze the exact
package SHA-256 values, signature SHA-256 values, downloaded key-file SHA-256,
binding-evidence SHA-256, and acquired-files manifest SHA-256. Until that
freeze succeeds, package bytes remain unbound.

## Authorization boundary

Step 196 authorizes **only** the exact unprivileged controller acquisition
probe and HTTPS network access to its frozen URLs. It does not authorize generic
controller network work, target-VM network access, target artifact copy,
package staging or mutation, local-source construction, runtime-executor
implementation, boot mutation, reboot, runtime scenario execution, or Phase 2.

The target VM remains untouched and offline for this step. No target machine
action is required. Preserve the probe output directory unchanged for the next
gate.

After a successful acquisition observation, the only next stage is
`phase-1-kernel-package-edge-package-pair-and-local-source-binding-freeze`.
This step is not a strong safe pause (`pause_safe=false`).

Frozen helper SHA-256: `512c2bb9146a740ba05a2b839b406550d3d0f11e9e9e59ed53c8486c62f38301`.  
Frozen controller acquisition probe SHA-256: `943af8b0995368b34c3fc79efaac09cbbdebebc1ea5929a4c566ccfd2ef1e586`.  
Frozen policy SHA-256: `ba6fe4afb14cc5c7793c2ac610660706648eb2bbf5a8b95ea31199efe18cb03b`.  
Frozen record SHA-256: `27c86a17e6f98984cb2101749d3fba21b14be697dca7382f9016ef90ef83df2a`.
