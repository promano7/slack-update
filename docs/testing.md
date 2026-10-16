# Testing and verification scope

Choose checks for the change being made and for the source tree they describe.
The mappings in [CONTRIBUTING](../CONTRIBUTING.md#reference-script-changes)
remain the detailed guide for reference-script changes. This document explains
how current regression checks, historical checkpoint harnesses and real
Slackware acceptance differ; it does not authorize a system run.

## Select the applicable checks

| Change or review | Verification scope |
| --- | --- |
| Documentation only | Review meaning and status, check changed links/fragments and whitespace, and confirm the intended file scope |
| Reference behavior | Run the focused regression checks for the affected behavior and review their fixture/environment requirements |
| Frozen historical checkpoint | Use that checkpoint's matching complete repository tree, fixtures and harness |
| Real Slackware acceptance | Use the separately reviewed scenario, target and execution scope from the acceptance workflow |

A directory name or `harness` suffix does not prove that a script is safe to
run anywhere. Read the entry point, selected functions, fixture paths, command
substitutions and required tools before executing an unfamiliar check.

For a shell-source change, the existing syntax check is:

```bash
bash -n tools/reference/slack-update-reference.sh
```

For a documentation change, inspect both unstaged and staged whitespace:

```bash
git diff --check
git diff --cached --check
```

Also inspect new files: an unstaged `git diff` does not list untracked content.
After adding the intended paths, `git diff --cached --stat` shows the complete
staged scope. Link checks must resolve paths from the containing document and
verify fragments, not just search for a filename somewhere in the repository.

Documentation checks do not need a new permanent fixture set or a native test
run merely because another numbered step has been delivered.

## Current regression checks

Select tests using the existing contribution mappings. For example,
[package-name parsing](../tests/reference/test-package-name-parsing.sh) sources
the reference without invoking `main()` and exercises the parser with fixtures.
Other harnesses have different dependencies, mock boundaries and outputs.
Do not infer that every script under `tests/reference/` has the same behavior.

Mock or supplied-data checks can validate the behavior they exercise. They do
not prove installed command semantics, native containment or complete acceptance
on Slackware 15.0 and Slackware-current. Record the actual check and its scope;
a PASS count alone does not identify what was demonstrated.

## Historical checkpoint harnesses

Some checkpoint tests bind exact README bytes, fixture hashes, permitted
prefixes and the complete repository inventory. For example, the
[manuscript audit freeze harness](../tests/reference/test-phase-1-operational-joint-manuscript-audit-freeze-and-safe-pause-review-harness.sh)
checks its original supplied inputs, source roots and exact path set.
Later documentation additions can therefore violate its historical inventory
contract even when the frozen implementation and evidence are unchanged.

Before interpreting a failure, identify the checkpoint and read its policy,
baseline and actual failing assertion. Do not dismiss an arbitrary regression
as historical: only a demonstrated snapshot mismatch supports that conclusion.

To reproduce an applicable repository-only historical check, obtain its verified
complete commit/tree. A detached worktree keeps the current checkout separate:

```bash
git worktree add --detach ../slack-update-checkpoint CHECKPOINT_COMMIT
```

Replace `CHECKPOINT_COMMIT` with the verified commit for the record being
reproduced. This command prepares a source tree; it does not select or run a
test. A reported short commit prefix must resolve to the correct local commit
and matching source binding. If the matching tree is unavailable, record the
check as not reproduced rather than inventing a result.

Do not copy the archived README over the current one to force a pass: its links
were rebased, and one file cannot recreate a complete historical inventory.
Do not weaken frozen baselines or rewrite old acceptance records for a later
checkout. An intentional new behavior or contract change needs its own scoped
review and evidence; historical records retain their original claims.

## Real acceptance and reporting

Scripts in the [real acceptance guide](../tests/acceptance/reference/README.md)
exercise actual Slackware installations. Apply scenarios require a disposable
snapshot or equivalently recoverable environment and the appropriate reviewed
execution scope. Even a preflight may refresh metadata or produce local state.
Keep each platform's evidence and source/run bindings separate.

Historical authorization is not a standing right to repeat a native run.
Preparing a worktree, passing mocks, committing documentation or reaching a
repository pause does not grant that right. Read the
[acceptance/evidence guide](reference/acceptance-evidence-guide.md) for the
original scenario labels and the different claims supported by each record.

When reporting verification, name the check, source/checkpoint, outcome and
material limits. Distinguish local checks from a user's reported commit/push,
actual native evidence and final repository pause confirmation. Early failures,
missing dependencies or absent matching snapshots must remain visible.
