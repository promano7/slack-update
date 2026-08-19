# Phase 1 optional-module mode remediation decision freeze

Step 125 freezes the remediation decision for the single optional-module mode
conformance gap classified in step 124. This is a repository-only decision
boundary. It does not edit the reference implementation, configuration template,
or frozen 15-row module-mode contract.

## Frozen decision

The accepted discrepancy remains `boot-auto-partial-path-availability`, scoped to
`boot=auto` in the `boot-preparation` safety domain. The frozen resolution is
`preserve-contract-tighten-source`.

The frozen contract is therefore preserved. A future source remediation is
required and must be limited to the `boot-auto-partial-applicability-only` scope.
Its target behavior is that `boot=auto` is not considered runnable unless a
validated supported preparation path exists.

This freeze does not authorize the implementation edit. The next stage designs
the smallest source remediation and its repository-only regression boundary
before any source modification can be authorized.

## Safety boundary

Step 125 changes no runtime behavior and does not modify the configuration
template. It authorizes neither a source change nor a contract change. It does
not depend on Slackware repository state and requires no machine action.
Slackware 15.0 and Slackware-current remain mandatory targets.

A successful step 125 remains pause-safe and advances only to
`phase-1-configuration-module-mode-source-remediation-design`.
