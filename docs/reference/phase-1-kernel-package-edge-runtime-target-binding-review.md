# Phase 1 kernel-package-edge runtime target-binding review

Step 193 consumes the accepted step-192 runtime-boundary design and opens the
first live-machine gate for the single **kernel-package-edge** scenario. The
gate is deliberately narrow: a standalone probe may observe the designated
Slackware-current validation VM, but no repository refresh, network access,
package mutation, boot mutation, persistent configuration change, or reboot is
authorized.

## Standalone read-only observation

The probe at
`tools/reference/phase-1-kernel-package-edge-runtime-target-binding-probe.sh`
is self-contained and does not require the `slack-update` repository on the
VM. It embeds the controller identities that are relevant to this scenario:

- reference implementation SHA-256
  `1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415`;
- effective configuration SHA-256
  `4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba`;
- configured header set: `kernel-headers`;
- configured boot set: `kernel-generic kernel-huge kernel-modules`.

The probe is bound to `vbox-slackcurrent.vbox-slackcurrent.org`. It records
the target hostname/FQDN, architecture, running kernel, Slackware version, boot
ID, package-database manifest hash, the exact installed `kernel-headers`
record, the three configured boot-package records, and SHA-256 fingerprints of
`/etc/slackpkg/slackpkg.conf` and `/etc/slackpkg/mirrors` when present. It
also verifies availability of the commands required by the step-192 design.

The observation fails closed unless exactly one `kernel-headers` package
record and exactly one record for each configured boot package are present. A
successful output starts with `binding_status<TAB>PASS`. The complete output
must be returned to the controller and is the only live observation accepted by
the next binding-freeze gate.

## What remains deliberately unbound

Step 193 does **not** select or download the official predecessor/target
`kernel-headers` artifacts. It does not construct the immutable local
`slackpkg` source and does not bind a candidate set. Those decisions require
the successful target observation first, so the package pair can be chosen
against the exact installed package state without refreshing the VM.

A later Slackware-current publication does not invalidate this review because
no mirror metadata or live candidate set is consumed. A reboot of the target
**does** invalidate the returned observation because the boot ID is part of the
binding evidence; in that case the probe must be rerun before freezing the
binding.

## Authorization boundary

Step 193 authorizes only the standalone read-only target observation and, after
that observation succeeds, the next target-binding freeze. It does not authorize
package-pair binding, local-source binding, runtime-executor implementation,
runtime execution, repository/network refresh, package action, boot action,
reboot, or Phase 2.

The acceptance matrix remains incomplete. This is an active chain rather than
the requested end-of-session strong safe pause, so `pause_safe=false`.

Frozen probe SHA-256: `f3b6e03f4ac1a89f9a80aef0ed1dbdc16966fae91f06aa57963d92a51eabc465`.  
Frozen helper SHA-256: `968ba7cd830cc2cf4f6242a1b3e2c43a1ec9f624c400a025018d2c19a4dc9d22`.  
Frozen policy SHA-256: `3873f5f84402d4601a2755ca69c9c2f1e697846b70e66555f90fb18159341d30`.  
Frozen record SHA-256: `771401c8d5bfde6c7b14eab7d8ef450b2712f85631f4f5158d6613fb74d68f23`.

The next stage is `phase-1-kernel-package-edge-runtime-target-binding-freeze`.
