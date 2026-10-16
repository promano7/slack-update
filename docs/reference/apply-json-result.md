# Supplied-state apply JSON regression

Run `python3 tests/reference/test-apply-json-result.py` without root. It validates
the complete provisional schema 0 object using an independently authored
[baseline fixture](../../tests/fixtures/reference/apply-json-supplied-baseline.json)
and explicit case expectations. Expected values are not captured from the subject.

## Execution boundary

The child Bash process sources declarations, runs `initialize_runtime_state`
with its only external command (`date`) replaced by a fixed-output local
function, assigns supplied state, calculates the result and serializes it.
The initializer assigns variables; it is distinct from `initialize_runtime`,
which creates runtime files and is never called. Neither `main`, configuration
loading, locking nor an apply/check/dry-run workflow is entered.

Result helpers inspect only supplied private broken-object/pending-file/option
files. These temporary directories are removed by Python. Boot paths in the
fixture are strings, not files to inspect or modify. Assignment names are fixed
test inputs checked against an identifier pattern; values use `shlex.quote`.
No supplied command string is evaluated. Imported test bytecode is disabled.

## Cases and expected results

| Supplied case group | Required output |
| --- | --- |
| Success; headers-only kernel indicator | Final code 0; broad kernel indicator alone does not request reboot |
| Critical userspace package | Successful code 4 with recommendation and critical package list |
| Successful required boot preparation | Successful code 5; integer-zero validation statuses retained |
| Workflow failure plus successful required boot preparation | Code 2 takes precedence over 5; partial result retains required reboot field |
| Initrd failure/blocked GRUB; GRUB failure | Code 3, unsafe reboot state and exact failure diagnostics |
| Invalid before/after/both snapshots | Code 2; before-error diagnostic precedence; dependent boot reporting blocked |
| Failed package action and skipped later actions | Raw failure retained; negative statuses become null |
| Reference no-match status reporting | Raw 20 retained for both package actions, current reference aggregate code 0 |
| Flatpak, SBo and ELF failures | Corresponding module state/status/diagnostic; aggregate code 2 |
| Four Cinnamon trigger values | Not-required/incomplete/success/failed states, with appropriate supplied aggregate result |
| Pending configuration files; enumeration warning | Exact list/count/warning text, without inventing a package failure |
| SBo supplied records and counts | Typed workspace counters and ordered option objects retained |
| Direct-generic and GenInitrd supplied metadata | Paths, counts, flags and nullable/zero statuses retained |

There are 24 supplied-state scenarios, each comparing all 17 root fields and
the complete six-module object. They do not assert native reachability of every
combination. Eight negative controls reject wrong types/codes, changed validity
or non-execution fields, and a missing boot field. Expected output is
`Apply JSON result tests: 24 scenarios, 8 negative controls, 0 failures`, test
status 0. Assertion failures return 1; a serialized failed-operation code is
separate from the successful child serializer process status.

The raw-20 case records the existing **shell reference** predicate, already
covered by its exit-code regression. It does not replace the distinct original
operational/native contracts: native install20 still needs empty AND no-effect
evidence, and native upgrade20 is failure. Those full original criteria remain
binding and unproved here; current-reference serialization is not their acceptance.

## Limits

This test does not reproduce real package operations, pending-file enumeration,
queue construction, ELF inspection, Policy restoration, boot validation or
containment. Reported `boot_safe`, isolation, non-execution and atomic replacement
fields are supplied-result outputs, not observations or proofs of those mechanisms.
Fixed test timestamps supply no native-clock evidence. The fixture and cases do
not freeze schema 1, close a native scenario, amend a contract or open another
development phase. The reference source bytes and executable mode are unchanged.
