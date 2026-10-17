# Configuration text parser regression

Run from the repository root with Python 3 and Bash:

```bash
python3 tests/reference/test-configuration-parser.py
```

The 72 scenarios source the reference and call `initialize_configuration_state`
and `parse_configuration_file` on private files. They cover 51 successful inputs
and 21 rejected inputs. All 34 supported keys have authored key-to-variable
expectations, individually and together. All parser-state variables are seeded
with stale values before initialization; successful cases compare their complete
state and the ordered duplicate-key tracking string.

| Input property | Current parser behavior |
| --- | --- |
| Empty file or comment-only file | Parse successfully with initialized defaults; semantic validation is separate |
| Supported sections and keys | Assign text to the matching parser variable |
| Repeated section with different keys | Accept; duplicate detection remains keyed by section plus key |
| Duplicate key, including an earlier empty value | Reject with the exact path and physical line number |
| Unknown section/key, invalid key or malformed line | Reject with the first applicable diagnostic |
| CRLF, surrounding whitespace, final nonempty EOF row | Preserve the represented value after current trimming |
| Equals signs after the first separator | Preserve them within the value |
| Quotes, inline comment characters, shell substitutions | Preserve literal text without shell expansion or execution |

The test includes whitespace/Unicode paths, backslashes, empty values and three
private marker probes for command substitution, backticks and semicolon text.
Input bytes must remain unchanged. A marker's absence establishes only that
these supplied probes did not execute their marker command; it is not a general
security proof. Private files are removed when the temporary directory closes.
Each Bash subprocess has a ten-second timeout. Arguments are passed as argv,
never inserted as executable shell source.

Eight private source mutations were rejected with unchanged expectations:
EOF row loss, accepted duplicate key, wrong target variable, wrong module default,
missing outer trimming, incorrect line number, accepted unknown key and loss of
text before a later equals sign. The actual parser passed without a source fix.

## Limits

This test checks text parsing and initialized parser state. Some supplied values
are deliberately semantically invalid. It does not call the configuration-file
resolver, `validate_configuration`, `apply_configuration`, the execution-environment
initializer, `main` or update workflows. Parser status 1 is distinct from main's
stable invalid-input code 7. Failed-parse partial state is not specified; only
status, diagnostic, framing and unchanged input bytes are asserted on rejection.
NUL and invalid UTF-8 input handling are outside this coverage.

The original historical configuration policies/fixtures retain their original
checkpoint bindings. These current-source tests do not rewrite those records,
prove native Slackware acceptance, select contract alternatives or discharge
operational findings. Phase 1 and the later schema/reference release gates remain
incomplete; no native execution authority follows from a passing parser check.
