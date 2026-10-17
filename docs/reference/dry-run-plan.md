# Human dry-run plan regression

Run from the repository root:

```bash
python3 tests/reference/test-dry-run-plan.py
python3 tests/reference/test-dry-run-environment.py
python3 tests/reference/test-dry-run-workflow.py
python3 tests/reference/test-dry-run-json-result.py
bash tests/reference/test-error-exit-codes.sh
```

The independent standard-library driver sources the reference in private Bash
processes and calls the real `print_dry_run_plan`, `print_plan_file` and
`print_sbo_option_records`. It requires Bash and sed in addition to Python.
There are 180 scenarios, repeated for 360 complete render calls.

## Complete output and branch selection

The baseline text fixture is authored expected output; named replacements and
separate expected section fragments describe each supplied scenario. The test
does not generate expectations by capturing reference output, parse the source
to build an oracle or import the shared JSON test support. Whole stdout bytes
are compared, including section order, indentation, blank lines, messages,
planned command arguments, configuration/log paths and the final clock line.

Twelve Slackware rows cross raw status 0, 100 and a failure with the four
install-new/upgrade-all flag pairs. Module profiles cover disabled, required
but unavailable, auto but unavailable, available in auto/enabled modes, and
two deliberately inconsistent supplied states. Those last rows isolate run-flag
and disabled-state precedence without asserting native reachability.

Flatpak, SBo and ELF profiles exercise their four output branches. SBo and ELF
also cross empty, absent and populated private files. Cinnamon crosses each
profile with all four supplied checkout/builder flag pairs. Boot covers skipped
branches and runnable profiles with unknown, mkinitrd-managed and direct-generic
layouts, independently varying initrd and GRUB availability. Direct-generic
output must omit the initrd command even when its supplied capability is true.
Required/auto missing-path messages, deferred kernel validation and temporary
generation/validation/atomic-install descriptions must remain exact.

Thirty-six combined runnable scenarios cross files, check status and Slackware
flags; fifteen mixed-module scenarios rotate five profiles across all modules.
These are rendering projections of authored state. Layout/capability combinations
are not proof that real probes would produce the same reachable combination.

## Real private formatting and state preservation

The real file helpers render private newline-terminated fixtures. Records have
spaces, quotes, backslashes, repeated ABI entries, empty option values and
distinct queue/object contents. They must preserve order and duplicates, print
the expected tab-separated option fields and show `(none)` for absent/empty
inputs. Supplied counts intentionally differ from line counts: the renderer
projects its input fields rather than validating their consistency. Partial
unterminated option records and malformed input validation are outside this test.

A narrow sed wrapper records exact arguments and delegates to the real external
sed command; no result text is substituted. The clock is a fixed-output callback.
Its second return is 19, while its output remains fixed; rendering still returns
0 and preserves the same final text. This checks existing interpolation behavior,
not real clock failures or a new error-handling policy.

Both calls compare the full supplied scalar state and IFS. Exact private file
inventory and bytes must remain unchanged apart from the declared callback trace.
Empty stderr is required. Command-like strings in displayed configuration/log/
queue values must remain literal, with no evaluation or extra private artifacts.
Exact sed call ordering and the final no-argument date invocation are checked.

## Scope

The driver invokes no main, initializer, discovery, repository check, workflow,
package operation, boot preparation, network request, native builder or actual
clock. Known excluded entry points abort, but guards are not OS containment.
Rendering the reference's no-update statement is not evidence about normal
workflow effects. The environment, orchestration, JSON/NDJSON and native tests
retain their separate scopes; these authored output expectations are not an
independent semantic/native oracle. Native criteria, open findings, contract
options, migration and separate review/grant/conformance gates remain unchanged.
