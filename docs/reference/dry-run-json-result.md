# Supplied-state dry-run JSON regression

Run `python3 tests/reference/test-dry-run-json-result.py` without root. The test
sources the shell reference, supplies result state and private input files,
then calls only `determine_stable_exit_code` and `print_json_result`. It does not
run `--dry-run`, initialize runtime, inspect installed tools, probe repositories,
resolve queues, inspect ELF objects or invoke any planned command.

## Covered supplied states

| Cases | Required serialized result |
| --- | --- |
| Disabled modules; raw check 0 or 100 | Complete six-module object; false/true update availability; final code 0 |
| Both package actions, install-only, upgrade-only, refresh-only | Exact ordered command strings; update remains first |
| Check failure and explicit mirror diagnostic | Raw failure retained; availability null; final code 1; exact diagnostic |
| All optional modules auto/unavailable | Supplied activation/reason fields retained without enabled-module errors |
| All optional modules enabled/unavailable | Five exact errors in Flatpak/SBo/ELF/Cinnamon/Boot order; final code 1 |
| SBo selection error | Raw status and diagnostic retained; selection error contributes to aggregate failure |
| Available modules with supplied records | Capability booleans, queue paths, two build-option records, ordered duplicate targets, ABI/ELF arrays and cache count retained |
| Supplied ELF scan failure with workflow failure flag | Scan status 42 and aggregate code 1; no invented scan diagnostic |
| Zero versus not-run statuses | Integer 0 remains distinct from null for selection/scan |
| Missing supplied record files | Empty arrays; no host-file fallback |

These are 14 supplied-data scenarios, not 14 actual execution observations.
Some combinations intentionally isolate aggregate precedence and are not claims
about reachable workflow state. All 17 top-level fields and every field of the
six module objects are compared with independently authored expected values.
The shared strict decoder/comparator also supports the check-result regression;
both entry points disable bytecode writing before importing it.

The dry-run warning about unresolved exact package changes remains present in
both successful and failed cases. Seeded stale warnings/errors and apply-like
result flags must be replaced. In this model, dry-run failures still report
`partial=false`, `boot_safe=true`, `reboot="none"`; these fields are not a host
boot-safety observation. A successful serializer process returns 0 even when
the JSON's final operation code is 1.

Eight negative controls reject changed boolean/integer/null fields, reversed
command order, lost queue order/duplicates, a missing module field and an omitted
warning. The check-result regression retains its eight decoder/type controls.
Expected new output: `Dry-run JSON result tests: 14 scenarios, 8 negative controls,
0 failures`, test status 0. Assertion failures return 1.

## Limits

Reported literals such as `queue_workspace_isolated=true`,
`executes_inspected_objects=false` and `grub_atomic_replacement=true` are checked
as output fields. This test does not prove the corresponding runtime mechanism,
validate queue semantics or authorize a boot operation. Files contain supplied
records only and live in automatically removed temporary directories.

No reference behavior or executable mode changes. Schema 0 stays provisional;
the current expected field set is not a schema 1 freeze. Native acceptance on
both supported platforms, all operational findings and independent native proof
obligations remain due. For check-specific coverage see
[the check-result regression](check-json-result.md).
