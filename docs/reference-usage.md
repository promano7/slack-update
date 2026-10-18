# Shell reference usage

This guide describes the available reference CLI, not the planned C commands.
Use [development setup](development-setup.md) for a checkout and the
[configuration guide](configuration.md) for current settings. Real Slackware
acceptance uses the scenario-specific [acceptance guide](../tests/acceptance/reference/README.md).

## Select an operation explicitly

The source-tree help command is:

```bash
bash tools/reference/slack-update-reference.sh --help
```

The operation and output combinations below describe the CLI syntax. Actual
runtime execution requires the reviewed target and scope for the intended work.

| Operation arguments | Behavior |
| --- | --- |
| `--check` | Check the Slackware repository without package/boot apply |
| `--check --json` | Check and request one final structured result |
| `--dry-run` | Inspect the environment and produce an execution plan without package/boot apply |
| `--dry-run --events` | Plan and request provisional NDJSON progress |
| `--apply` | Run the existing update workflow and apply configured changes |

Specify at most one of `--check`, `--dry-run` and `--apply`. Repeating an
operation flag is also rejected. `--json` and `--events` are mutually exclusive.
Unexpected positional arguments and unknown options return code `7`.
There is no current `--config` option or `config validate` subcommand.

**No operation flag means apply.** Adding only `--json` or `--events` does not
change that default. Use `--help` for inspection rather than invoking the script
with no arguments. Help is handled after argument parsing, so conflicting or
unknown arguments are still rejected even if `--help` is also present.

## Scope of check, plan and apply

Check invokes the configured mirror ChangeLog probe and `slackpkg check-updates`;
it is not an apply or a complete candidate-bound acceptance preflight.
Raw check status `100` means updates are available; successful check operations
return process code `0` whether updates are reported or not.

Dry-run inspects local state and produces a plan. Its planned apply commands
are descriptions, not commands it has executed. A plan does not reserve a
candidate set or authorize later application after repository changes.

All three runtime operations currently require root after valid configuration
is loaded. They acquire a lock and initialize runtime state and logging. Check
and dry-run can still write local state or logs and perform transport probes.
Avoid inferring absence of effects from their names.

Apply can update packages, run enabled optional components and prepare boot
artifacts. Disabling optional modules does not disable the core Slackware
workflow. A historical apply, recovery or boot grant cannot be reused for a
new run; the linked acceptance records define their own boundaries.

## Read output and results

| Output selection | Standard output | Human-readable progress |
| --- | --- | --- |
| No output flag | Human-readable workflow output | Standard output and normal log |
| `--json` | One final JSON document when execution reaches result emission | Standard error and normal log |
| `--events` | NDJSON progress and completion events during the workflow | Standard error and normal log |

Both structured interfaces use `schema_version: 0` and
`schema_status: "provisional"`. The version 1 result schema remains pending.
Do not parse the proposed schema-1 example in the C design as today's output.

The final JSON reports the operation, success/partial/reboot/boot-safe state,
stable exit code and meaning, timestamps, configuration/log paths, module
results, warnings and errors. Intermediate event exit codes may carry raw
external-command statuses; final normal-operation status uses the stable
[exit-code contract](../README.md#exit-codes).

Startup errors can return before structured output is initialized. For example,
invalid arguments/configuration, missing root privileges or lock failure may
produce no final JSON or completion event. Preserve the process status and
standard error; an empty result is not successful evidence.

## Interpreting current diagnostics

The [regression scopes](testing.md#current-sbo-elf-runtime-and-boot-reader-checks)
now distinguish queue graph/file handling, SBo coordination, static ELF reader
results, scan/recheck state, runtime setup/logging and boot text validation.
A raw helper zero is not proof that a preceding filesystem operation succeeded;
selected failure projections are documented as limitations in those scopes.
Do not treat a printed success label, private regression PASS or plan as native
acceptance, package no-effect evidence or a bootability guarantee.

The [current integrated selection](reference/repository-regression-block-475-483.md)
contains56 named commands. Selected ELF traversal/publication/count, work-file
initialization and diagnostic failures now propagate before success reporting;
see [ELF scanning](reference/elf-scan-workflow.md). Failed copy can still leave
partial destination changes, and remaining display/reader limits retain scope.

Human output passes through the current sed filter before tee, so both console
and log receive filtered text. Supported ANSI sequences and the first carriage
return per line are removed; emoji and unsupported sequences can remain. In
structured modes human progress goes to stderr/log and descriptor 3 preserves
machine-readable stdout. See [runtime/logging](reference/runtime-logging.md).

Generated GRUB path searches can find the kernel and initrd in different entries;
the text check does not establish a bootable paired entry. The synthetic
GenInitrd regression models target ownership and is separate from the real
root-ownership requirement. See [boot artifact validation](reference/boot-artifact-validation.md)
and the original scenario requirements before drawing a native safety conclusion.

## Handle completion correctly

Codes `4` and `5` are successful apply outcomes with reboot guidance. A wrapper
that treats every nonzero status as failure will misclassify them. Apply outcome
precedence remains `3 > 2 > 5 > 4 > 0`; code `3` means unsafe boot preparation.
A kernel headers change alone does not require reboot code `5`.

The registered HUP/INT/TERM handler exits with `128 + signal number` after its
cleanup path. Interrupted runs therefore need not return a code in `0` through
`8` or emit a complete final result. An interruption does not prove that every
effect was undone or authorize an automatic retry.

Reported results must be interpreted with their scenario and evidence. They
do not replace the independent operational requirements or establish the
current state of another run or platform. For those records, use the
[reference index](reference/README.md).
