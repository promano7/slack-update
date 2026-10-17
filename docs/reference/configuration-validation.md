# Supplied configuration validation regression

Run from the repository root with Python 3 and Bash:

```bash
python3 tests/reference/test-configuration-validation.py
```

The 163 scenarios source the current reference, initialize parser state, assign
an authored 34-key baseline and call `validate_configuration`. They include 44
successful states and 119 rejected states. Values are passed as argument data,
not evaluated as shell code. No real configuration file is resolved or parsed.

| Coverage | Expected current behavior |
| --- | --- |
| Required values | Independently reject each of the 29 missing required values |
| Schema | Accept literal version 1; reject unsupported representations |
| Retention | Accept non-negative digit strings, including zero and leading zeros |
| Slackware flags | Accept only lowercase `true` or `false` |
| Five optional module modes | Accept `enabled`, `disabled`, `auto`; reject invalid or empty modes |
| Thirteen configured paths | Require an absolute-path prefix; accept supplied spaces |
| Package lists/tag | Check the current character grammar; preserve supplied list spelling |
| Boot kernel package | Require exactly one package name |
| Cinnamon branch/builder/remote | Exercise current lexical rejection and allowed forms |
| ELF scan paths | Check supplied colon-separated paths and authored resulting array |
| Multiple simultaneous errors | Preserve the first applicable diagnostic |

Each case checks exact status and stderr, stdout framing and preservation of IFS.
Successful cases compare the ELF path array's complete length, values and order.
`apply_configuration` is replaced by an aborting guard, so an accidental call
fails the test. Every Bash subprocess has a ten-second timeout.

Eight private source mutations were rejected with unchanged expectations:
unsupported schema, invalid boolean/mode, relative path, omitted required-value
check, multiple kernel packages, leading builder traversal and wrong ELF delimiter.
The actual validator passed without a reference source fix.

## Limits

These expectations cover current lexical validation of supplied values. They do
not establish path existence, canonical containment, symlink/ownership safety,
resource availability, repository reachability, complete URL validity or safe
execution. The retention check is not a bounded numeric-range test. The ELF cases
do not exhaust every delimiter/empty-field combination. A passing state with an
enabled module does not establish that its commands exist on either platform.
The validator's ELF-array assignment is tested; settings are not applied to the
runtime variables and no update or boot workflow is dispatched.

This test does not call the resolver, text parser, execution-environment initializer
or main. Internal validation status 1 remains distinct from main's stable code 7.
Review future called functions before running the harness against changed code;
function guards are not an OS sandbox. Original native acceptance requirements,
historical policy bindings, operational findings/decisions/grants and phase gates
retain their scope. Phase 1 and the schema/reference release gates remain open.
