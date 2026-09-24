# Phase 1 kernel-package-edge runtime target-binding freeze

Step 194 freezes the successful corrected standalone observation accepted by
step 193-r2 as the exact pre-staging runtime target for the
`kernel-package-edge` family. This step is repository-only and performs no
machine action.

## Frozen target identity

The accepted target is `vbox-slackcurrent.vbox-slackcurrent.org`, architecture
`x86_64`, running kernel `6.18.45`, Slackware release string `Slackware 15.0+`,
and boot ID `5e79b100-55a8-415d-a6ea-1cb8c568c2eb`.

The controller reference implementation SHA-256 is
`1014658196f384b29756827b9074fb0393aeaaf82dad857ff4da91762d9ca415` and
the effective configuration SHA-256 is
`4845e2c5038fe8896409f90b6287de33a011a76874229cb76479aa6cd4253bba`.
The accepted corrected standalone probe SHA-256 is
`bda22255aaa1db2dad4f8a28ed89719ddc89dbb03989fa3facd0a19c6d65ac6f`.

## Frozen package state

The pkgtools compatibility path `/var/log/packages` resolved exactly to the
canonical `/var/lib/pkgtools/packages` directory. The canonical package-database
manifest SHA-256 is
`3aeaf9f193f5bc5c92f10ee3c5063be0b17a0e3001eccbc57bc4037c4343e910`.

Exactly one configured header record was observed:
`kernel-headers-6.18.45-x86-1`.

The configured boot-sensitive set remains `kernel-generic kernel-huge
kernel-modules`. Its observed state is unambiguous: `kernel-generic` is installed
as `kernel-generic-6.18.45-x86_64-1`, while `kernel-huge` and `kernel-modules`
are absent. This cross-release policy distinction remains intentional.

The observed `/etc/slackpkg/slackpkg.conf` SHA-256 is
`f1584eec58ed92c30d4514977ef7bb0a334fb9c54f2f5f47059fbefc877fe7a4`
and the observed `/etc/slackpkg/mirrors` SHA-256 is
`71f0e8113d5cd8b7a84b92153ce7767ee4d708e8b26b225dc4aaafe15deebf12`.
The accepted observation performed no repository refresh, network access,
package action, boot action, persistent configuration change, or reboot.

## Binding validity

Before any package staging, later gates must observe the same FQDN, boot ID,
running kernel, architecture, controller reference/configuration identities,
pkgtools layout, package-database manifest, exact header record, and
boot-sensitive package observations. Before local-source binding, the same
`slackpkg.conf` and `mirrors` fingerprints are also required.

A target reboot, running-kernel change, package-database drift before staging,
slackpkg configuration drift before source binding, or controller
reference/configuration change invalidates this binding and returns the chain to
target-binding review before a package mutation may occur. A later
Slackware-current publication by itself does not invalidate the binding because
no network metadata or live candidate set has been bound.

## Authorization boundary

Step 194 authorizes only the next repository stage: design of the exact
predecessor/target package pair and immutable local source binding. It does not
authorize package-pair binding, local-source binding, runtime executor
implementation, runtime scenario execution, repository/network refresh, package
or boot actions, reboot, or Phase 2.

The next stage is
`phase-1-kernel-package-edge-package-pair-and-local-source-binding-design`.
`pause_safe=false`.
