# Phase 1 optional-module mode conformance discrepancy classification

Step 124 classifies the single discrepancy recorded by step 123. It is a
repository-only decision record and does not change the reference implementation,
the configuration template, or the frozen 15-row module-mode contract.

## Classified discrepancy

- ID: `boot-auto-partial-path-availability`
- Module: `boot`
- Mode: `auto`
- Classification: `implementation-conformance-gap`
- Safety domain: `boot-preparation`
- Resolution direction: `preserve-contract-tighten-source`

The frozen contract requires `boot=auto` to activate only when a validated
supported preparation path exists. The accepted source additionally recognizes a
`partial` layout when exactly one preparation capability is available and marks
the boot module available and runnable before later per-action gating.

This discrepancy is classified against the implementation rather than the
contract because boot preparation is safety-sensitive and the stricter frozen
contract preserves an atomic, validated applicability boundary. Relaxing that
contract merely to encode the historical partial branch would expand the accepted
boot surface without a demonstrated safety requirement.

## What this step does not authorize

Step 124 recommends preserving the frozen contract and tightening the source, but
it does not yet authorize a source change. It also does not authorize a contract
or configuration-template change. The remediation decision is frozen separately
in the next stage before any implementation edit is allowed.

No Slackware machine action or repository refresh is required. Slackware 15.0 and
Slackware-current remain mandatory targets.

A successful step 124 advances only to
`phase-1-configuration-module-mode-remediation-decision-freeze`.
