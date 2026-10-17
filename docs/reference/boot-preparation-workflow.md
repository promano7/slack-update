# Boot preparation workflow regression scope

Run from the repository root:

```sh
python3 tests/reference/test-boot-preparation-workflow.py
```

The driver sources the unchanged reference and calls the real
`run_boot_preparation_module`. Initrd regeneration, the initrd/GRUB prerequisite,
GRUB configuration work and all four event callbacks are supplied. It does not
call the actual validators, package tools, generator, GRUB transaction, probes,
normal initialization or main. Only orchestration, shell control flow, variable
assignments and callback trace writes are real in this new driver.

## Matrix and observations

The 2,304 scenarios cross three boot modes, two run flags, three supplied module
states, all four required-flag pairs, all four update-flag pairs, all four supplied
initrd/GRUB result pairs and both prerequisite outcomes. Every row runs twice in
the same freshly started Bash process, resetting stale guard and result values
before each call. Operations return 19 then 0; event callbacks return 0 then 19.
Their return codes deliberately disagree with some supplied result globals.
There are 4,608 coordinator entries. These authored combinations include
inconsistent required/update/mode/run/result pairs; they do not prove native
reachability or a policy bypass in an installed system.

The independently authored expectations compare complete ordered callback/event
vectors, exact arguments/messages/raw codes, selected state, preserved request
flags/mode/reason, IFS and outer variables shadowed by the coordinator's two
locals. Exact stdout packets, empty stderr and the private directory inventory
are checked after both entries. Trace paths contain spaces. The driver captures
the coordinator's raw 0/1 return; the containing Bash process ends with status
zero. It does not establish a main/application result or native bootability.

The current coordinator projection includes these distinctions:

- Its three GRUB guard fields are reset before the first event. Initial state
  selection prefers no required work, then disabled mode, then a non-running
  module's supplied state. Later action decisions use the supplied request flags.
- The initrd callback is always called, including unneeded/inapplicable rows.
  Its result global, rather than its raw callback return, controls applicable
  initrd success or failure. The real initrd implementation has its own gating;
  this test substitutes it and does not assert that generators always run.
- GRUB prerequisite checking occurs only for required and selected GRUB work.
  A rejected prerequisite emits a blocked completion without announcing action
  start or calling the supplied GRUB operation; its supplied reason is retained.
- A successful supplied GRUB result preserves a preceding failed initrd state.
  An unsuccessful GRUB result makes the module fail. Inapplicable GRUB reporting
  carries the current boot state, which can already be failed.
- Module completion state determines the final raw coordinator return, despite
  event callback failures. Guard/result globals and action/module raw fields
  are separate observations; a supplied callback's attempt flag is not evidence
  that an installed GRUB command ran.

## Sensitivity and complementary checks

Twelve syntax-valid private reference mutations are rejected by the unchanged
driver on one full-matrix row each, with two entries per row: attempt/block/reason
reset, initrd dispatch and required/result classification, GRUB required gating,
prerequisite polarity, earlier-failure retention, GRUB result classification,
final return and local-state isolation. These are focused checks, not twelve
complete matrix reruns. The shipped reference and oracle are not mutated.

Run the existing
[GRUB-after-initrd check](../../tests/reference/test-grub-blocked-after-initrd-failure.sh)
for its actual guard and private GRUB transaction coverage, the
[boot activation/policy check](../../tests/reference/test-boot-module-policy.py)
for request formation and the
[direct-generic check](../../tests/reference/test-current-direct-generic-boot-policy.sh)
for its private classifier/validator scope. This driver does not replace them.
Use [apply orchestration](apply-secondary-workflow.md),
[result precedence](result-precedence.md), [apply JSON](apply-json-result.md)
and [events](event-ndjson.md) for their separate workflow, mapper, serializer
and event transport boundaries. The new supplied prerequisite does not test
actual managed-initrd/direct-generic/generated-initrd validation.

Known unwanted function/command entries have failure guards. They are not an
operating-system sandbox, whole-host observation or native execution control.
Private files and supplied callbacks do not demonstrate installed-tool behavior,
independent safety, cleanup of an actual machine or native acceptance.
Phase 1/kernel remain incomplete, contract alternatives unselected and all
original criteria/open findings binding. Separate specification/impact review,
explicit migration if norms change, actual composition binding, independent safe
whole review, fresh bounded native authority before effects and later platform
conformance remain due. No historical source/boot/run/grant right is renewed.
