# Phase 1 kernel-package-edge contract freeze

Step 191 consumes the accepted step-190 `kernel-package-edge` family selection
and freezes the exact runtime-validation contract for the single scenario
**“Kernel headers update without a kernel image update.”**

## Frozen runtime contract

The later acceptance run must use a Slackware-current validation VM and a fresh,
explicitly authorized runtime boundary. Step 191 does not bind the exact VM,
package source, live candidate set, or runtime chain. The transition itself must
be a controlled real-system package-state transition: at least one package from
the configured kernel-header set changes, while **zero** packages from the
configured kernel boot-package set change.

The reference implementation must therefore observe the kernel change
(`KERNEL_TRIGGER=1`) but must not schedule initrd or GRUB work
(`INITRD_UPDATE=0`, `GRUB_UPDATE=0`). The kernel-header external-module warning
must remain observable. Boot preparation may not execute, the running kernel
must remain unchanged, no reboot is required, and pre/post fingerprints of the
relevant boot artifacts must be identical.

The future evidence bundle must bind the target and runtime boundary, record the
configured kernel-header and boot-package sets, preserve pre/post package
snapshots, prove the positive header delta and zero boot-package delta, capture
the kernel/initrd/GRUB decision output and external-module warning, preserve
pre/post boot-artifact fingerprints and running-kernel identity, and record
cleanup plus a coherent final package state.

## Authorization boundary

Step 191 is review-only. Repository refresh remains conditional, but neither a
repository/network refresh nor machine/package/boot/reboot/runtime execution is
authorized here. The exact mechanism used later to obtain the controlled header
transition is deliberately deferred to the runtime-boundary design; no package
source is bound by this contract.

Only the next design stage is authorized. A later Slackware-current publication
does not invalidate the frozen behavioral contract because target, candidate,
and package-source binding have not occurred yet. The acceptance matrix remains
incomplete; `reference-v1` and the C port remain behind their existing gates.

Frozen helper SHA-256: `d47e283f81738763563cdc27f17a2badf7a44cdb8d11240be4d01c4a3dce3896`.  
Frozen policy SHA-256: `95f065e015106467e25f81d1cb9c4199967edd51aee821ed70d3001c301a35fc`.  
Frozen record SHA-256: `ab90fa4f61dd5de7db5fe76cebcd72adfe7d25c95d6925aeb1c67bd09db7f28d`.

The next stage is `phase-1-kernel-package-edge-runtime-boundary-design`.
Step 191 is not the requested end-of-session strong safe pause, so
`pause_safe=false`.
