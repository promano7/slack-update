# Cinnamon rebuild wrapper regression scope

Run from the repository root:

```sh
python3 tests/reference/test-cinnamon-rebuild.py
```

The driver calls real `rebuild_cinnamon`. Git is a supplied callback; it neither
contacts a remote nor mutates a checkout. Private checkout directories, file and
executable predicates, builder files/symlinks, a subshell and execution of an inert
private Bash builder are real. The builder only writes trace/output and exits with
a supplied status. This is not a real Cinnamon build or a wholly mocked test.

## Matrix and observations

The 288 active cases cross three private `.git` kinds (directory/file/missing),
four supplied fetch/reset/clone profiles, six builder kinds, two builder statuses
and two output profiles. Another144 cases cross initial triggers0/2/3/9 with the
three repository kinds, six builder kinds and both output profiles. Four additional
cases supply a failed `cd` for an otherwise executable builder. There are436
scenarios and872 wrapper entries. Each scenario calls twice without resetting
state: a first active call changes its trigger to2/3, and the second call skips.
Inactive initial triggers skip both calls. No retry or second build is inferred.

The builder kinds are executable, nonexecutable, missing, private executable
symlink, broken symlink and a nested executable. Checkout and builder names contain
spaces. All checkout directories and builder fixtures are preseeded by Python;
Git callbacks do not create clone contents. Successful clone status is supplied,
not evidence that an empty destination was cloned or a remote checkout is valid.

Authored expectations assert complete ordered predicate/Git/cd/builder traces,
exact Git vectors, stdout/stderr routing, raw wrapper returns, selected module/
trigger/OK/RET fields, branch/remote/builder values, parent cwd/IFS and unchanged
private bytes/modes/link targets/inventory. The actual private builder records its
cwd and argument count. The `cd` callback normally delegates to real builtin cd;
only the four rejection cases supply failure. Parent cwd must remain unchanged.

Current reference distinctions include:

- Only trigger1 enters. A directory at `.git` selects fetch/reset; file/missing
  selects clone. This is the current directory predicate, not a full Git-worktree
  discovery contract or native source-trust decision.
- Fetch failure skips reset; either refresh failure warns and continues with the
  private builder. Exact reset target remains `origin/BRANCH`. Fetch/reset callback
  stderr merges into stdout; clone stderr remains a separate channel.
- Clone failure prints the existing message that Cinnamon will not be rebuilt,
  yet the executable predicate and any preseeded executable builder still run.
  The test retains that observable control-flow/message mismatch; it does not
  endorse the wording, change a native contract or prove actual clone behavior.
- Active work resets OK to0. Executed builder success sets OK1/trigger2; builder
  or supplied cd failure sets trigger3. Missing/nonexecutable/broken builders set
  trigger3 without changing the old RET value. Inactive calls preserve old state.
- All selected raw wrapper returns are0. Global RET retains an executed builder
  or subshell status; module/main/application results are separate boundaries.

## Sensitivity and related checks

Twelve syntax-valid private source mutations are rejected using unchanged-driver
assertions on one full-matrix scenario each, two consecutive calls: trigger gate,
repository branch, fetch short-circuit, clone-failure continuation, OK reset,
subshell isolation, builder quoting, builder-result classification, failure trigger,
Git stderr routing, raw wrapper return and reset target. These are focused controls,
not twelve full-matrix reruns. No reference or oracle mutation ships.

Keep [optional probes](optional-module-probes.md),
[secondary apply](apply-secondary-workflow.md), [result precedence](result-precedence.md),
[apply JSON](apply-json-result.md) and
[stable exit codes](../../tests/reference/test-error-exit-codes.sh) for their
separate activation/workflow/result/serialization scopes. This driver supplies one
auto/running module profile; it does not test all activation modes or native builds.

Known-entry/path guards are not OS containment or independent observation. Real
private executable files, subprocesses and symlinks are not native Cinnamon
acceptance, whole-host absence or actual cleanup proof. Original native criteria,
open findings and unselected options remain binding. Phase1/kernel are incomplete;
schema1/reference-v1/C/Phase2/production remain closed. Separate specification/
impact, explicit migration if norms change, actual composition, independent safe
whole review, fresh bounded native grant before effects and later own-platform
conformance remain due. No historical binding or execution right is renewed.
