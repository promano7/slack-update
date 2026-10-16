# Supplied-state check result regression

`python3 tests/reference/test-check-json-result.py` validates the current
provisional schema 0 final `check` result. It sources the reference in child
Bash processes and calls `determine_stable_exit_code` and `print_json_result`
with supplied values. It never calls `main`, loads configuration, initializes
runtime, probes a mirror or executes `slackpkg` or a check workflow.

## Cases and expectations

| Supplied state | Raw check status | Final JSON code | Updates available |
| --- | ---: | ---: | --- |
| No updates | 0 | 0 | false |
| Updates available | 100 | 0 | true |
| Check failure | 20, 42 or 255 | 1 | null |
| Missing-command diagnostic | 127 | 1 | null |
| Mirror diagnostic with supplied special characters | 69 | 1 | null |
| Workflow failure flag with raw success | 0 | 1 | false |
| Explicit error with raw success and a successful workflow flag | 0 | 1 | false |
| Raw failure with a successful workflow flag | 42 | 1 | null |

The last three cases test supplied-state precedence; they do not claim that
the actual workflow produces those combinations. Module state reflects the raw
check status, while aggregate success also considers the workflow flag and
diagnostics. Check failures have `partial=false`, `boot_safe=true` and
`reboot="none"` in this result model; these values are not an observation of the
current host's boot safety.

The regression compares all 17 top-level fields and the complete three-field
Slackware module object with independently authored expected values. It checks
exact JSON types, including boolean versus integer and null versus false,
keeps raw status 100 separate from final status 0, preserves supplied diagnostic
and path text, and verifies that seeded stale warnings/errors and apply-like
result flags do not leak into the check result. Timestamps and paths are supplied
strings; no clock or filesystem semantics are inferred from them.

Eight negative controls confirm rejection of wrong scalar types, schema version,
update availability, raw status, duplicate keys, NaN and a second JSON document.
The decoder's duplicate-key/non-JSON-constant checks are tested directly. Python's
standard JSON decoder is independent of the shell serializer. The expected
objects do not call the reference's own mapping helpers.

Expected test output: `Check JSON result tests: 10 scenarios, 8 negative controls,
0 failures`, process status 0. Assertion failures return 1. The child serializer
returns 0 when it successfully emits even a supplied failed-operation result;
that status must not be mistaken for the JSON's final operation code 1.

## Limits

This current-output regression does not freeze schema 1 or prohibit later
explicitly reviewed provisional-format changes. It does not exercise startup,
stdout/stderr routing through `main`, native command semantics, event ordering,
dry-run or apply results, or either platform's acceptance matrix. No behavior
change or native evidence is introduced by adding it. Source executable mode
remains `100755`; the JSON escaping correction is unchanged.
