# Reference JSON control-character escaping

## Defect and correction

The step 426 reference escaped quotes, backslashes, backspace, form feed,
newline, carriage return and tab. It emitted the other 26 representable C0
control characters literally. For example, serializing `before`, ESC (U+001B)
and `after` returned status 0 but produced a JSON string rejected by a strict
decoder. A supplied diagnostic containing that character could invalidate a
result or an NDJSON event, even though the serializer itself reported success.

`json_escape` now encodes remaining U+0001 through U+001F characters as
`\u00xx`. Existing short escapes remain unchanged. The additional loop runs
only when a control character remains after the existing substitutions. It
uses Bash builtins and adds no runtime dependency or external command.

The encoded ESC example is `"before\u001bafter"`, with serializer status 0.
Decoding it must reproduce the original supplied string exactly. Backslashes
that spell literal escape-looking text must also round-trip without becoming
control characters. Bash strings cannot carry NUL; this change does not add a
binary-string interface or specify invalid UTF-8 handling.

## Supplied-data regression scenario

Run from the checkout without root:

```bash
bash -n tools/reference/slack-update-reference.sh
python3 tests/reference/test-json-control-escaping.py
bash tests/reference/test-error-exit-codes.sh
```

The new Python test sources the reference in child Bash processes without
calling `main()`. It calls only the selected serializers and event wrappers.
The result case supplies a synthetic successful `check` state and calls
`print_json_result`; it does not run a check workflow. Event timestamps come
from a local stub. File-array inputs live in an automatically removed private
temporary directory. Python's standard JSON decoder supplies the independent
string-decoding expectation; the test never constructs expected strings with
the reference's own escaping code.

| Scenario | Required output and exit status |
| --- | --- |
| Every representable C0 character, alone and combined | Strictly valid JSON, exact decoded value, serializer status 0 |
| Conventional short escapes | Existing `\b`, `\t`, `\n`, `\f`, `\r` bytes retained |
| Text, quotes, backslashes, UTF-8 and DEL | Exact decoded value, serializer status 0 |
| Empty/mixed arrays and supplied line files | Exact order, duplicates, blank lines and final unterminated line retained |
| Synthetic final check result with supplied control text | Valid provisional schema 0 JSON; warning/path text preserved; final result code 0 |
| Two supplied events with control text | Two valid NDJSON records; sequence 1/2, raw action code 42, final code 0 |

The test process returns 0 when all checks pass and 1 for assertion failures.
Local reproduction against the exact step 426 source produced **113 checks,
81 failures** and test exit 1. The patched source produced **113 checks, zero
failures** and test exit 0. The existing exit-code regression produced
**137 checks, zero failures**. The before/after test uses the same expectations;
it does not bless the original invalid output as a compatibility requirement.

## Scope and remaining work

This is a focused Phase 1 shell-reference correction with supplied-data
regression evidence. Schema version remains 0 and provisional. Stable process
codes and intermediate raw event codes retain their existing meanings. The
test does not validate every result field, operation, event transition or
configuration combination; those require their own applicable checks.

No actual Slackware workflow or acceptance scenario ran. This evidence closes
none of the five remaining native acceptance families, 13 operational findings
or native proof/case obligations. Both supported Slackware targets still need
their own applicable acceptance evidence. No A/R/D option, contract amendment,
native grant, schema 1 freeze, `reference-v1`, C or Phase 2 entry is selected.
Historical source bindings remain historical; later native work must bind its
actual reviewed source rather than reuse the step 426 source identity.
