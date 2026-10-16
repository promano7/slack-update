# SBo option JSON projection and end-of-file handling

`json_sbo_option_records_from_file` previously processed a row only when Bash
`read` found a newline. A supplied file containing `alpha`, a tab and `MODE=yes`
without a final newline produced `[]` with serializer status 0. The last row of
a longer file was likewise omitted, including in final dry-run/apply JSON.

The loop now also processes a nonempty target read at EOF, matching the existing
string-array reader's unterminated-line behavior. The one-row example must emit
`[{"target":"alpha","options":"MODE=yes"}]`, serializer status 0. Newline-terminated
maps, blank/empty/missing inputs, field names and result schema remain unchanged.

The current normalized-map producer writes every row with `printf ...\n`.
This is a defensive serialization fix for supplied/externally changed files,
not evidence that the ordinary producer lost rows during an actual update.
Option parsing, validation, merging, ordering and package submission are unchanged.
The JSON helper is a projection, not an additional option-grammar validator.

## Regression and expectations

Run without root:

```bash
bash -n tools/reference/slack-update-reference.sh
python3 tests/reference/test-sbo-option-json.py
python3 tests/reference/test-dry-run-json-result.py
python3 tests/reference/test-apply-json-result.py
bash tests/reference/test-sbo-options.sh
bash tests/reference/test-error-exit-codes.sh
```

The new test has 12 file-array cases plus two complete supplied-result cases.
It covers missing/empty/blank files, LF/EOF, multiple rows, surrounding blank
lines and quoted/backslash/UTF-8 text. Whole dry-run/apply expectations reuse the
independently authored case data from their existing Python tests, with only the
supplied option file's final newline removed. Eight negative controls reject
lost/reordered/extra rows, altered values/types and missing/extra object fields.
These supplied strings are projection inputs, not a declaration that any such
text bypasses upstream grammar validation. No option or command is evaluated.

Before correction, the same test and expected values reported 14 scenarios,
eight negative controls, eight failures and test status 1. After correction,
expected output is `SBo option JSON tests: 14 scenarios, 8 negative controls,
0 failures`, test status 0. Serializer status and assertion-test status are
separate; the original silently truncated serializer itself returned 0.

Local focused regressions also passed: dry-run 14/8 and apply 24/8 scenarios/
controls, 57 existing SBo option checks and 137 existing exit-code checks.
The new Python tests call supplied-data result helpers; apply uses the state-only
initializer with a fixed date stub. The existing SBo harness DOES call its queue
builder with `sbopkg` replaced by a function and private files. The exit-code
harness DOES invoke `main` with configuration/root/locking/runtime/workflow/output
functions replaced by test implementations. Some existing checks read the real
clock. These are scoped mocks, not a normal Slackware update or native evidence.

## Scope

The shared decoder and prior test bodies are unchanged. Imported bytecode is
disabled; supplied files are automatically removed. Stable process codes and
provisional schema 0 are retained. Native SBo/ELF acceptance on both platforms,
original operational raw-20 rules, all findings and phase gates remain due.
No package installation, boot operation, contract amendment or new authority is
introduced by this correction. Later native review must bind the changed source.
