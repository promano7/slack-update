# Human result summaries

Run `python3 tests/reference/test-human-summary.py` for changes to
`print_summary` or `print_check_summary` in the
[reference implementation](../../tools/reference/slack-update-reference.sh).
The independent Python driver invokes the real renderers with authored state
and compares complete stdout bytes against separately authored expected text.
It also checks empty stderr, raw return, selected input globals/array/IFS,
ordered date/wc/sed traces and unchanged private file contents/link targets.
Each scenario resets its inputs and runs twice in one Bash process.

## Selected cases

There are 388 apply scenarios and 16 check scenarios: 808 renderer entries.
The apply groups are 80 snapshot/pending/blocked combinations, 240 ABI/Cinnamon/
boot combinations, 60 queue/ELF/critical-package combinations, and eight
blocked/clock/module-label combinations. These groups overlap intentionally;
they are not the full Cartesian product of all input fields.

- All before/after snapshot-valid combinations, empty/nonempty snapshot errors,
  valid/invalid pending lists, positive/zero supplied pending counts, spaces,
  backslashes, a blank record and a final record without newline.
- Blocked early return, unblocked details and both module label profiles.
  Blocked output omits ABI, Cinnamon, kernel, queues and ELF sections.
- ABI values 0/1/7; Cinnamon 0/1/2/3/7; absent/noncanonical kernel triggers,
  initrd skipped/success/failed/validation-error, direct generic validation
  success/error/quiet failure, other layout, GRUB skipped/blocked/success/failure/
  transaction error, and simultaneous initrd failure/GRUB blocking.
- Conflicting supplied GRUB flags establish display precedence: mode skip before
  blocked before successful status. These states need not be workflow-reachable.
- Ordered critical-package arrays including spaces/duplicates, personal queues,
  validated/unvalidated generated queue paths and optional-field unset defaults.
- Real empty, newline-terminated, unterminated and private-symlink ELF lists.
  Real wc/sed and file-size predicates operate only on private fixtures.
- Check statuses 0/100/1/20/42/127/255/-1 and clock returns 0/41; fixed date text
  comes from a supplied callback. Raw renderer return remains zero, including
  an error check status or a failing clock callback that prints its fixed value.

## Current observations and limits

Pending counts and all workflow/module/boot states are supplied, not recomputed.
Snapshot validity, queue readiness and successful boot labels do not prove real
snapshots, generated queues, boot artifacts or native effects. The check text
claiming no modifications is a supplied-state rendering observation, not a
measurement of real package/component effects. Date text is not native time.
Input-state checks intentionally exclude the renderer loop temporaries `pkg`
and `pending_config`, which are not local to the current shell functions.

The renderer currently prints the kernel reboot recommendation whenever its
kernel trigger equals one, including skipped or failed boot preparation. The
test preserves that current text; it does not approve rebooting or amend the
separate [boot policy](boot-module-policy.md). An unterminated ELF
record is displayed even though wc counts zero newlines; sed leaves that final
record unterminated and the following echo supplies its newline. A supplied
pending count can likewise differ from actual list records. Human summaries
are not final result mapping or acceptance criteria.

The source is loaded without invoking main. Guards reject package/network/boot
commands, setup/workflows, discovery and JSON/event entry points. No installed
package enumeration, real updater, builder, network request or boot command runs.
Fixtures, their symlink targets and trace writes are private test work products;
they do not establish host absence, OS containment or native cleanup. Missing/
unreadable lists, arbitrary text injection, every tool failure, locale variants,
concurrent changes and all combinations are outside this matrix. This is an
independently authored output oracle, not independent platform conformance.

Keep [dry-run planning](dry-run-plan.md), [check workflow](check-workflow.md),
[main completion](main-completion.md), [result precedence](result-precedence.md),
[apply JSON](apply-json-result.md), [check JSON](check-json-result.md),
[events](event-ndjson.md) and stable-exit tests for their separate boundaries.
Native install-new code 20 still needs empty AND no-effect; upgrade code 20 is
failure. No static test changes those obligations, selects an alternative,
reopens schema1/reference-v1/C/Phase2/production, or grants native execution.
