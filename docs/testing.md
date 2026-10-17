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

## Current CLI and configuration checks

Run these seven independent Python 3 checks from the repository root. Each invokes
Bash and uses only the Python standard library; the resolver also uses `dirname`
and `pwd` in private directories, and the help renderer invokes `cat`.
They have no shared Python test-support module or cross-test fixture imports.

| Test under `tests/reference/` | Actual exercised boundary |
| --- | --- |
| [test-cli-arguments.py](../tests/reference/test-cli-arguments.py) | Parser state/status/diagnostics only; no main or workflow |
| [test-cli-early-exits.py](../tests/reference/test-cli-early-exits.py) | Real main/parser/help; environment mocked and later boundaries prohibited |
| [test-configuration-parser.py](../tests/reference/test-configuration-parser.py) | Initialized parser state and private-file text parsing; no value validation/application |
| [test-configuration-resolver.py](../tests/reference/test-configuration-resolver.py) | Exact source relocated to private files; installed presence/readability modeled |
| [test-configuration-validation.py](../tests/reference/test-configuration-validation.py) | Authored supplied values and lexical validation; no file lookup or application |
| [test-configuration-application.py](../tests/reference/test-configuration-application.py) | In-memory scalar/array assignments; no apply workflow |
| [test-main-configuration-failures.py](../tests/reference/test-main-configuration-failures.py) | Real private-file loader/main; environment/application/privilege callbacks replaced, later effects prohibited |

Run the parser, early-exit and main-configuration checks when argument parsing
changes. Run the resolver plus main-configuration checks for resolver changes;
the latter covers explicit private paths, not installed-file precedence. Parser
state initialization or text grammar changes need the configuration-parser check
and the main loader check. Validation changes need the validation and main loader
checks. Assignment changes need the application check; changes to loader stage
ordering also need the main loader check. Help rendering needs the early-exit
check. Run all seven for a combined entry/configuration change or integrated review.
Environment normalization itself has its existing cron-environment regression;
the two new main harnesses replace that function and do not test its real behavior.

The main loader test includes valid-input controls which stop deliberately at a
modeled privilege callback with code 8. That is not a native privilege failure.
Its application callback checks loader sequencing, not real runtime assignments;
the assignment test covers those separately. Code 7 is the stable main rejection
status, while parser/resolver/validator internals use status 1. Early help writes
usage to stdout; invalid arguments write diagnostic plus usage to stderr. A
configuration-loading error writes its diagnostic without usage or structured
output, including with `--json` or `--events`.

All files/channels created by these checks are private test artifacts. Config
resolver unreadability is modeled, not a native permissions test; explicit symlink
and `..` acceptance describes current resolution without a containment guarantee.
Supplied parser/assignment values can deliberately bypass semantic validation.
Lexical checks do not prove path existence, canonical containment, URL validity,
resource availability or runtime safety. The guards are not an OS sandbox; review
newly introduced calls before extending a harness to changed reference code.

These are current repository regressions, not native Slackware acceptance or an
operational protocol implementation. They establish no whole-host absence of
effects, independent semantic acceptance, schema 1 freeze, contract-option choice
or native execution right. Original scenario/member criteria, unresolved findings
and separate review/grant/conformance gates remain binding.

## Current JSON and NDJSON checks

Run these checks with Python 3 from the repository root. All six invoke Bash; the two existing shell regressions below also use standard
command-line tools such as `mktemp`, `sed` and `grep`.
Each Python test prints its own scenario or check count and fails on a mismatch.

| Test under `tests/reference/` | Supplied-data coverage |
| --- | --- |
| [test-json-control-escaping.py](../tests/reference/test-json-control-escaping.py) | Shared escaping of all C0 characters Bash can represent; Bash strings cannot contain NUL |
| [test-check-json-result.py](../tests/reference/test-check-json-result.py) | Complete current check-result fields, types, statuses and diagnostic precedence |
| [test-dry-run-json-result.py](../tests/reference/test-dry-run-json-result.py) | Complete current dry-run result, planned commands and module arrays/statuses |
| [test-apply-json-result.py](../tests/reference/test-apply-json-result.py) | Complete current apply result using authored supplied state and fixed-date initialization |
| [test-event-ndjson.py](../tests/reference/test-event-ndjson.py) | Complete supplied event records, sequence state, wrappers and descriptor routing |
| [test-sbo-option-json.py](../tests/reference/test-sbo-option-json.py) | Supplied option-file rows, including final EOF rows, and whole dry-run/apply projections |

The check, dry-run, apply, event and option tests share the strict decoder and
type-aware comparator in `json_result_test_support.py`. Run all five when that
support changes. The option test imports authored scenario helpers from the
dry-run and apply tests; run it when either helper changes. The escaping test
has its own driver. A change to shared shell escaping can affect all six.

For SBo option handling, also run
[`bash tests/reference/test-sbo-options.sh`](../tests/reference/test-sbo-options.sh).
For shared result/status behavior, also run
[`bash tests/reference/test-error-exit-codes.sh`](../tests/reference/test-error-exit-codes.sh).
The SBo harness calls the queue builder with a stubbed `sbopkg`; the exit-code
harness calls `main` with replaced configuration, root, locking, runtime,
workflow and output boundaries. They use private fixture files; some existing
checks read the actual clock. Review each harness before expanding its scope.

These JSON/NDJSON checks exercise selected functions with supplied data, not a
normal update workflow. Apply-result projection uses `initialize_runtime_state`
with a fixed date, not the file-creating `initialize_runtime`. Expected objects
are authored test data; negative controls reject deliberate output mutations.
The EOF regression does not establish ordinary update data loss: the current
normalized-map producer already emits newline-terminated rows.

These tests cover provisional schema 0. They do not freeze schema 1, establish
native reachability or prove clock, custody, once-only, absence-of-effects or
host-safety properties. The shell reference's raw-20 reporting is not acceptance
of the distinct original native requirements: install-new 20 requires empty
output AND no effect; upgrade-all 20 is a failure. Original native obligations,
findings, decisions and separate execution grants remain unchanged.

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
