# Phase 1 execution-control failure-paths contract freeze

Step 179 consumes the accepted step-178 family selection and freezes the exact
runtime-validation contract for **`execution-control-failure-paths`**. The
family remains four acceptance scenarios: network failure before repository
synchronization, simultaneous execution, SIGINT/SIGTERM/SIGHUP during safe test
operations, and execution from cron without an interactive terminal.

## Frozen safety contract

All four scenarios must run inside one later, explicitly authorized bounded
runtime chain on a Slackware-current validation VM. The exact target machine is
not bound by this step. No live package candidate set is bound and no successful
repository synchronization is required. The contract is deliberately
independent of the current contents of Slackware-current mirrors.

The network scenario must fail before any successful repository synchronization
and may not persistently modify host network configuration. The simultaneous
execution scenario must hold one process at a safe non-mutating point and prove
that a second attempt cannot proceed concurrently. The signal scenario requires
separate SIGINT, SIGTERM, and SIGHUP runs at a safe non-mutating operation. The
cron scenario must use a real noninteractive cron context rather than merely
redirecting a terminal session.

Every scenario must finish with clean control state and no package or boot
mutation. Temporary fault-injection, lock, signal-test, or cron artifacts must
be removed. Evidence must bind the future target and runtime boundary, record
one result per scenario plus one result per signal, preserve pre/post control
state, prove no package or boot mutation, and record cleanup.

## Authorization boundary

Step 179 is review-only. It authorizes only the design of the next runtime
boundary. It does **not** authorize a repository refresh, network access,
machine execution, package action, boot action, reboot, source change, Phase 2,
or persistent system-configuration change. A later Slackware-current
publication does not invalidate this frozen contract.

The acceptance matrix remains incomplete; `reference-v1` remains blocked
behind the remaining acceptance work, and the C port remains blocked by the
Phase 1 gate.

Frozen helper SHA-256: `1da5e60a3c7f015c3817e51baf5d7c0598408df274cca49fdcfaee10256f81d1`.
Frozen policy SHA-256: `5ea897b193250dd99d9f7ac988cdd2fc95f1bc48df41c8d6189b6a689e1c1dd9`.
Frozen record SHA-256: `7a6ed7b1342f8d741debdc40de7d39bf1063fb84cb0e57e6f60f8e42db9f4bd6`.

The next stage is
`phase-1-execution-control-failure-paths-runtime-boundary-design`.
Step 179 is not the requested end-of-session strong safe pause, so
`pause_safe=false`.
