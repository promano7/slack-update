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
- configured boot-sensitive set: `kernel-generic kernel-huge kernel-modules`.

The configured boot-sensitive set is a cross-release policy set rather than a
requirement that every listed package be installed on every target. In current
Slackware-current layouts, a configured name may legitimately be absent. The
probe therefore records each configured boot-sensitive package as `installed`
or `absent`, rejects more than one installed record for any configured name,
and requires at least one configured boot-sensitive package to be installed.
This preserves a fail-closed observation while keeping the configuration valid
for both Slackware 15.0 and Slackware-current.

The probe is bound to `vbox-slackcurrent.vbox-slackcurrent.org`. It records the
target hostname/FQDN, architecture, running kernel, Slackware version, boot ID,
package-database manifest hash, the exact installed `kernel-headers` record,
the per-name boot-sensitive package status and record count, any installed
boot-sensitive package records, and SHA-256 fingerprints of
`/etc/slackpkg/slackpkg.conf` and `/etc/slackpkg/mirrors` when present. It also
verifies availability of the commands required by the step-192 design.

The observation validates the modern pkgtools layout before reading package
state: `/var/log/packages` must be a symbolic link resolving exactly to the
canonical `/var/lib/pkgtools/packages` directory, and that canonical directory
must itself be a real directory rather than a symbolic link. Package records
and the manifest fingerprint are read from the canonical directory.

The observation fails closed unless exactly one `kernel-headers` package
record is present, every configured boot-sensitive name has zero or one package
record, and at least one configured boot-sensitive package is installed. A
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

Frozen probe SHA-256: `bda22255aaa1db2dad4f8a28ed89719ddc89dbb03989fa3facd0a19c6d65ac6f`.  
Frozen helper SHA-256: `15788b1c8f973fc9bdffaa6c582b313632025a1d98f691f3f89211019b8a99a2`.  
Frozen policy SHA-256: `834276083c8e4d50c2c5510e10c21c512bb10ee85a88b70baeebf7a494d5f7a1`.  
Frozen record SHA-256: `6fc9cc61a4ac84eff07f2cf273aabda043f13115b53f35fdfa670c7a64815160`.

The next stage is `phase-1-kernel-package-edge-runtime-target-binding-freeze`.
