# Private boot activation and policy regression

Run from the repository root:

```bash
python3 tests/reference/test-boot-module-policy.py
bash tests/reference/test-current-direct-generic-boot-policy.sh
```

The independent Python 3 standard-library driver calls the real
`probe_boot_module` and `apply_boot_module_policy` in Bash. Command availability
and the direct-generic probe result are supplied callbacks. Configuration-file
and GRUB-directory predicates inspect private fixtures only. No boot tool runs.

## Existing accepted contract and repaired standalone test

The [frozen mode contract](configuration-module-mode-contract-freeze.md) requires
validated supported boot preparation in auto mode. The
[step-128 implementation](configuration-module-mode-source-remediation-implementation.md)
removed partial-path activation; the
[step-129 regression](configuration-module-mode-source-remediation-regression-review.md)
explicitly requires incomplete paths to remain unavailable and non-runnable.

The standalone direct-generic regression still expected `available`/`partial`
after its private GRUB validator failed. Running that unchanged test produced
56 checks and exactly two failures. Those expectations described the removed
pre-remediation branch and contradicted the accepted requirements above.

The current regression now asserts unavailable/non-runnable/unknown layout,
the auto rejection reason, and the retained syntax-validation reason. It passes
59 checks. Reference source, frozen contracts, configuration template and native
acceptance fixtures are unchanged. Historical test outputs remain historical;
this update aligns a current standalone test with the accepted source contract.

## New probe matrix

The 117 probe scenarios cross three activation modes, thirteen authored
capability/path rows and three supplied direct-probe outcomes (success, rejection
with reason, rejection without reason). Rows cover no capabilities, initrd only,
GRUB only, both complete, missing validator, and file/directory/symlink/broken-link
variants for configuration and GRUB paths.

Each call checks eight selected fields: module state/run/reason, initrd/GRUB/
direct availability, preparation layout and direct reason. Fields are poisoned
before both calls. Exact query traces verify disabled bypass, command/path
short-circuiting, managed-layout precedence and conditional direct probing.
Internal status and IFS are checked independently of reported availability.

Complete managed/direct layouts activate; partial paths remain unavailable.
Enabled reports specific missing requirements or a supplied direct reason; auto
uses its fail-closed module reason while retaining the direct diagnostic field.
These are supplied-result assertions, not actual direct-layout validation.

## In-memory request policy

The 144 policy scenarios cross three modes, three layouts, four capability pairs
and four requested initrd/GRUB pairs. An authored truth table supplies expected
required and execution flags. Disabled suppresses execution while preserving
applicable requirements; enabled retains requests; auto gates requests by
availability. Direct-generic suppresses initrd requirement/execution and retains
the separate GRUB rules. Zero requests clear deliberately stale requirements.

All 261 scenarios run twice: 522 selected-entry calls. Policy cases do no command
or path queries. The probe checks regular private configuration/target bytes and
private target-directory presence after each case. Trace writes and all fixtures
are temporary. No shared Python support or captured subject-output oracle is used.

## Scope

Command discovery is modeled; mkinitrd, GRUB generation/validation and real direct
classification abort if entered. The latter is a supplied callback in this new
test. The existing direct-generic regression separately calls real classifiers
against its own private files and a stub validator. Neither is a native update,
boot transaction or observation of an installed/running Slackware system.

The new policy matrix contains supplied combinations not established as reachable
native states. It verifies current flags, not bootability, path containment,
permission safety, execution authorization or native absence of effects. Guards
are not OS containment; review added calls before testing changed reference code.
No original criteria, findings, options, schema or phase/native gates are changed.
