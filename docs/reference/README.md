# Reference documentation

This is a reading guide to the existing reference records, not a replacement
for their complete requirements or evidence. Use the [documentation index](../README.md)
for general guides and the [roadmap](../roadmap.md#current-phase-and-release-gate)
for the current project gate. The entries below are selected starting points,
not an exhaustive inventory or a declaration that a workstream is complete.

## Find the relevant contract or review

| Review question | Starting record |
| --- | --- |
| Which historical acceptance scenarios remain? | [Acceptance-matrix remainder inventory](phase-1-acceptance-matrix-remainder-inventory.md) and the [post-execution-control inventory](../../tests/fixtures/reference/acceptance/phase-1/phase-1-acceptance-matrix-remainder-after-execution-control-closure.tsv) |
| What happened in configuration and module-mode validation? | [Configuration/module-mode closure checkpoint](configuration-module-mode-workstream-closure-checkpoint.md) |
| Where were the execution-control failure scenarios reviewed? | [Execution-control runtime validation and pause review](phase-1-execution-control-failure-paths-runtime-validation-review-and-strong-safe-pause.md) |
| Where are the English-comment remediation records? | [Comment remediation closure review](phase-1-reference-comment-language-remediation-closure-review.md) |
| What native prerequisites remain for the kernel operational work? | [Native implementation prerequisites](phase-1-operational-native-implementation-prerequisites.md) and [source/gap reconciliation](phase-1-operational-source-native-gap-reconciliation.md) |
| What are the unselected contract alternatives and separate decisions? | [A/R/D decision reference](phase-1-operational-joint-unselected-a-r-d-decision-brief-review.md) |
| Where are the integrated manuscript findings and interactions? | [Integrated findings and dispositions](phase-1-operational-joint-integrated-findings-interaction-disposition-review.md) |
| Where are the original member criteria and two-platform impact reviews? | [Whole-entry and two-platform member audit](phase-1-operational-joint-whole-entry-two-platform-member-impact-audit-review.md) |
| What was frozen at the manuscript audit checkpoint? | [Manuscript audit freeze](phase-1-operational-joint-manuscript-audit-freeze-and-safe-pause-review.md) |

Follow each record's source and fixture references for the complete text. In
particular, the prerequisite and audit summaries do not replace original
contracts, exact member criteria or the separate evidence due on each platform.
The decision reference leaves all alternatives unselected; linking it does not
choose a path, approve a migration or grant a native test.

## Locate the supporting files

Paths in the following table are relative to the repository root.

| Location | Contents and scope |
| --- | --- |
| `docs/reference/` | Detailed contracts, designs, audits and evidence reviews |
| `tests/fixtures/reference/` | Mock inputs, expectations, policy data and sanitized acceptance records; interpret each file according to its own record |
| `tests/fixtures/reference/acceptance/` | Recorded scenario evidence and later review inputs, including the Phase 1 inventory |
| `tests/reference/` | Focused regression and checkpoint harnesses; execution requirements differ by harness |
| `tests/acceptance/reference/` | Scripts for real Slackware scenarios and their [acceptance guide](../../tests/acceptance/reference/README.md) |
| `tools/reference/` | Shell reference, review tools and historical operational tools; a file's presence is not permission to execute it |

Mock results, authored paper audits and actual native runs are different evidence
types. Read the record's stated capture basis, target, source, outcome and limits.
An accepted historical run supports its recorded scenario and platform; it does
not establish the current state of a machine or authorize repeating the run.

## Read historical status in context

The [archived README](readme-through-step418.md) retains former "Current" headings,
commands and prepared checkpoints as history. New overview and phase information
is in the current README and roadmap. Detailed older contracts still retain
their original scope; a newer summary does not silently amend them.

A committed prepared freeze cannot attest its own later application, commit,
push or final user return. Keep those distinct from later acceptance and external
pause confirmation. Historical checkpoint harnesses that bind exact README bytes
or whole-repository inventories require their matching complete snapshot; do not
rewrite their baselines to accommodate a later documentation layout.

## Search beyond these starting points

From the repository root, list matching documentation without executing tools:

```bash
rg --files docs/reference | rg 'kernel|configuration|clock|receipt'
```

Use [CHANGELOG](../../CHANGELOG.md) to find the change history, then read the
referenced full record. The [contribution policy](../../CONTRIBUTING.md)
describes applicable checks and documentation placement.
