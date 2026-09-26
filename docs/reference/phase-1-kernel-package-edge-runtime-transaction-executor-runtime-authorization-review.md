# Phase 1 kernel-package-edge runtime transaction executor runtime authorization review

Step 217 consumes the exact repository-reviewed step-216 implementation and
opens one single-use runtime authorization for the bounded kernel-header edge
transaction. This review does not rebuild the payload. Only the already frozen
canonical executor and already signed/frozen 6.18.44 predecessor bytes may be
transported to the existing Slackware-current validation VM.

## Exact authorized transport

The only authorized executor is
`tools/reference/phase-1-kernel-package-edge-runtime-transaction-executor.sh`
with SHA-256
`09544b0f1b58a39a988ed705bf4d0d99b0da611bba070972d76828b5c0f93300`.
It may be copied to
`/home/promano/Descargas/phase-1-kernel-package-edge-runtime-transaction-executor.sh`
on `vbox-slackcurrent.vbox-slackcurrent.org` and must be rehashed there before
execution. Rebuilding or substituting another executor is not authorized.

The only authorized predecessor is
`kernel-headers-6.18.44-x86-1.txz`, SHA-256
`3e7ab26d4a5ae1bd4e13f568dc7b8d6705eb670b94fed231ca01fefae2466a9d`.
Its controller source remains the frozen step-196 artifact root at
`/home/promano/slack-update-phase-1-step-196-kernel-package-edge-artifacts`.
Those bytes may be copied to
`/home/promano/Descargas/kernel-headers-6.18.44-x86-1.txz` on the target only
after the controller copy is rehashed. Redownload is not authorized.

## Target and preflight boundary

The single execution remains bound to FQDN
`vbox-slackcurrent.vbox-slackcurrent.org`, running kernel `6.18.45`, and boot ID
`91901677-1dc3-4a39-a4b1-3f87e6875234`. The executor must complete its frozen
preflight before the first package or Slackpkg mutation. Any executor or
predecessor byte drift, FQDN/kernel/boot-ID drift, package-database drift,
Slackpkg-configuration drift, staged-target drift, local-source-tree drift, or
a pre-existing runtime evidence root invalidates this authorization and must
abort before the first mutation.

A later Slackware-current publication by itself does not change the frozen
package bytes or local-source evidence; only observed runtime drift at the
preflight boundary matters.

## Single bounded transaction

After both target transport hashes are verified, the only authorized runtime
invocation is:

```
sudo bash phase-1-kernel-package-edge-runtime-transaction-executor.sh --execute-runtime-validation
```

That single invocation may temporarily stage only
`kernel-headers-6.18.44-x86-1`, temporarily redirect Slackpkg to the preserved
local `file://` source, refresh that local metadata inside the network
namespace, bind the exact one-package 6.18.45 candidate, and execute the frozen
reference `--apply --json`. The candidate binding remains
`same-runtime-transaction-only` and may not survive a pause.

Package mutation is authorized only for the bounded header transition
6.18.45 → 6.18.44 → 6.18.45. External network access, generic repository
refresh, boot mutation, initrd/GRUB action, reboot, and persistent configuration
changes remain unauthorized.

## Restoration and evidence

The final accepted state remains `kernel-headers-6.18.45-x86-1` with the frozen
package-database manifest, unchanged boot ID/running kernel/boot artifacts,
unchanged local source and staged target, restored Slackpkg configuration and
state, restored GenInitrd policy, and no reboot. The 6.18.44 predecessor is not
an acceptable terminal state.

Successful execution must publish
`/home/promano/slack-update-phase-1-kernel-package-edge-runtime-evidence.tar.gz`
and its `.sha256` sidecar. No further machine action is authorized until that
result is reviewed. The next stage is
`phase-1-kernel-package-edge-runtime-transaction-validation-result-review`.
`pause_safe=false`.
