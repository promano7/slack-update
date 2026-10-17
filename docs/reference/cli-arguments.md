# Command-line argument parser regression scope

Run from the repository root, using Python 3 and Bash:

```bash
python3 tests/reference/test-cli-arguments.py
```

The check sources the current shell reference, then calls `parse_arguments`.
It never calls `main`, loads configuration, initializes the root environment,
acquires a lock or dispatches a workflow. Subprocesses have a ten-second timeout.
No command-line arguments from the cases are evaluated as shell code.

## Covered behavior

The 138 scenarios check complete successful parser state, exact parser status,
stdout framing and stderr diagnostics. One scenario contains seven consecutive
calls in one Bash process, including recovery after an invalid option. Every
standalone case starts with deliberately stale globals to detect missing reset.

| Input | Current parser behavior |
| --- | --- |
| No operation, including output-only options | Select legacy `apply`; tests do not execute it |
| One of `--check`, `--apply`, `--dry-run` | Select that explicit operation |
| A second operation, including a duplicate | Reject with parser status 1 |
| Both `--json` and `--events`, in either order | Reject with parser status 1 |
| Repeated `--json`, repeated `--events` | Accept the selected format |
| `-h` or `--help` | Set the help flag and continue validating all arguments |
| Final `--` | Accept the end marker |
| Any argument after `--`, including another option | Reject as an unexpected argument |
| Unknown options or positional arguments | Reject with the first applicable diagnostic |

All permutations of an operation, an output format and either help spelling
are included. Rejections cover case-sensitive options, assignment-style options,
empty strings, whitespace, Unicode, embedded newline and error precedence.
Unsuccessful parser globals are not promised as an interface; the next call
must reset them. The success cases compare every parser global.

## Limits

These expectations describe current argument parsing without changing it.
`main` maps a parser failure to stable code 7; this test checks the parser's
internal status 1 and does not exercise that mapping. It also does not test
help rendering, early exits, descriptor routing, configuration precedence,
privileges, locking or operation execution. Those need their own checks.
Help combined with invalid arguments is currently rejected; help does not
short-circuit validation. Output-only flags still select the legacy apply
operation, so running the real reference with them can modify a system.

Eight private source mutations were rejected during test validation: wrong
legacy default, stale output state, missing operation/format exclusion, early
help return, ignored arguments after `--`, success on unknown options and
repeated-event flag toggling. The expectations were unchanged. This experiment
checks the regression test's sensitivity, not native Slackware conformance.

The version 1 result schema and reference freeze remain pending. Original
native acceptance requirements, open operational findings and independent
review/execution gates retain their scope. No native grant follows from this
parser check or a repository commit.
