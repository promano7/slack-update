# Secondary apply workflow regression scope

Run from the repository root:

```sh
python3 tests/reference/test-apply-secondary-workflow.py
```

The driver calls the real `run_apply_workflow` through its normal end with a
successful supplied Slackware prefix and the real action classifier. All
snapshots, policy/package operations, probes, optional operations, event emitters,
boot preparation and summary are supplied callbacks. It does not invoke normal
initialization/main, installed package tools, native discovery or boot work.
Early failures and partial-update blocking remain covered separately by
[test-apply-early-exits.py](../../tests/reference/test-apply-early-exits.py) and
[the helper policy scope](partial-update-policy.md).

## Matrix and observations

The 472 distinct scenarios combine all sixteen four-module run-flag patterns
with disabled/unavailable/blocked supplied states; SBo enabled/disabled and ELF
enabled/disabled combinations with nine synchronization/selection/build profiles,
five scan/map/content profiles and present/empty option-record paths; and five
Flatpak raw statuses with seven Cinnamon trigger values and both option paths.
Overlapping rows are deduplicated. The deliberately authored states are not a
claim that native probes can reach every combination or accept unknown values.

Each row runs twice in freshly seeded Bash processes: auxiliary callbacks return
0 or 19, boot returns 0 or 255, and summary returns 0 or 19 respectively. Snapshot,
policy, queue-builder and ELF gate callbacks have their own designated returns.
There are 944 complete workflow entries. The shell caller catches the raw
workflow return; the Bash process itself completes with status zero. Summary's
return becomes the normal-end raw workflow return, including 19. This does not
assert an application/main exit code or successful native apply.

Authored expectations check the entire ordered callback/event vector, exact
arguments/messages/raw codes, selected global values, preserved module modes and
run flags, IFS, and all six outer variables shadowed by workflow locals. They
also require exact stdout packets, empty stderr, exact private inventory and the
bytes of core/extra/options/broken files after every entry. Private directory and
trace paths contain spaces; option-path absence leaves its seeded file alone.

The test observes the current reference projection in particular:

- Flatpak uses its status global, while trigger callbacks run ABI before kernel.
- SBo synchronization prefers positive sbopkg status over positive sqg status.
  Synchronization failure still reaches selection and, if selection/ELF succeed,
  queue processing. A successful build does not erase the failed SBo state;
  its final action raw code can nevertheless be zero.
- Failed selection clears core/extra and configured option records plus counts.
  Disabled SBo chooses the fallback directory and clears the same fields.
- ELF mapping is skipped after scan failure. Either failure marks selection
  failed and blocks enabled SBo processing. Successful mapping can populate the
  extra queue after prior clearing; disabled ELF clears the broken-object file.
- ELF completion keeps raw zero even after its failed action. A disabled SBo
  completion can retain raw one from an ELF failure while its action reports zero.
  These distinct event fields are preserved without interpreting native meaning.
- Cinnamon triggers 0/2/1-or-3 map to skipped/success/failed; other authored
  values leave the initial skipped state. Boot callback failure is ignored before
  summary. Optional/trigger/event auxiliary returns do not replace status globals.

## Sensitivity and boundaries

Twelve syntax-valid private reference mutations are rejected using focused
unchanged-driver assertions: Flatpak classification, trigger order, synchronization
priority, selection reset, core/options clearing, ELF short-circuit and blocking,
failed-state retention, Cinnamon trigger 3, ignored boot return and summary return.
Eleven focused rows are in the full matrix; the mapping-failure mutation also
uses an empty broken-object file as a supplementary focused row. These are not
twelve full-matrix reruns. No mutation changes the shipped reference or oracle.

Only the workflow, classifier, shell control flow, private redirections and
private-file size predicate are real. Supplied operations write seeded files and
counts; their side effects are not evidence about actual tools, queues, event
serialization/transport or safety. Function guards fail known unintended entry
points and commands; they are not operating-system containment or independent
native observation. Test guards do not enforce a native execution right.

Reference code-20 matching remains separate from original native obligations:
install-new20 requires empty AND no-effect; upgrade20 remains failure. All
unselected options, open findings and separate specification/impact, possible
explicit migration, actual composition, independent safe whole review, fresh
bounded case/platform/run grant before effects and later conformance remain due.
No runtime grant, actual host absence, Phase 1/kernel completion or production
readiness follows from this regression.
