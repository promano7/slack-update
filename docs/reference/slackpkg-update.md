# Slackpkg update and pending configuration regression scope

Run from the repository root:

```sh
python3 tests/reference/test-slackpkg-update.py
```

The driver calls real `update_slackware_system` and
`capture_pending_new_config_files`. Slackpkg is supplied. A guarded find callback
accepts only the original exact `find -H /etc -xdev -type f -name '*.new' -print`
vector, then delegates real find to an owned private tree. The real installed
`/etc` is not enumerated. Sort and wc callbacks trace arguments and normally
execute real coreutils; selected faults return supplied failure after full normal
find/sort output, or fail the count callback without output. No package action,
normal main/apply, policy transaction or network operation runs.

## Cases and observations

There are12 direct capture scenarios and576 update scenarios, each twice with
reset globals:588 scenarios/1176 top-level entries. Update cases cross four true/
false flag pairs, six supplied raw-status triples, six capture profiles, two stale
status seeds and both command-output profiles. Capture profiles include empty
matching sets, three sorted private paths including spaces, irrelevant files and
a `.new` directory, internal file/directory/broken symlinks, a command-line root
symlink, find/sort failure, blank/unset destination, directory/missing-parent
redirection failure and a failed count callback. The count failure and several
filesystem profiles are direct-capture cases only, not integrated update cases.

Expectations compare exact Slackpkg arguments/order, stdout, selected status/
valid/count/error/flag globals, IFS, private list bytes and complete private
inventory. Command stderr must retain invocation order before scan stderr. Real
redirection-error diagnostics are matched as complete repeated records with the
expected reference/destination paths and C-locale reason, allowing Bash line
numbers to vary. Other stderr is exact. Find/sort/count traces are separate files:
the concurrent pipeline stages have no asserted inter-stage trace write order.

The current reference observations include:

- Metadata update always precedes selected install-new and upgrade-all actions.
  Package actions use `-postinst=off`; metadata update does not. Supplied command
  failure does not stop later selected actions or pending-file collection.
- Selected action statuses reset and retain raw command results. Disabled actions
  retain their prior seeded statuses. The update wrapper returns0 even after
  supplied command/capture failure; raw fields remain separate from application
  and stable result mapping.
- Capture clears validity/count/error first. Missing destination and real failed
  redirection stop before enumeration. Enumeration uses real private find/sort,
  C sorting and wc line count; nonmatching files/directories/internal symlinks
  are excluded, while the command-line root alias is followed by `-H`.
- Find/sort fault profiles emit complete normal output then return failure. The
  pipeline is rejected with invalid/count0/error state while retaining those
  already written list bytes. This does not exercise every partial-output,
  interrupted-write, permissions, mount-boundary or concurrent-change behavior.
- The direct count fault prints its supplied diagnostic and no count text. The
  current helper nevertheless sets valid1, stores an empty count, leaves error
  empty and returns0 because it does not check wc status. This exposes a current
  helper limit; no integrated apply/main result or normative acceptance is claimed.

Names containing newlines, actual installed configuration state, file-content
validation, authenticity, filesystem containment and a coherent native snapshot
are outside this check. The relocation is explicit; collected paths refer to the
private tree, not a representation of the user's current `/etc` contents.

## Sensitivity and related checks

Twelve syntax-valid private reference mutations are rejected on one full-matrix
scenario each, two repeated entries: metadata reset/vector, install selection/
postinstall option, upgrade vector, early command-failure continuation, capture
dispatch, validity reset, guarded scan-root binding, pipeline result, line count
and destination initialization. The root mutation is rejected by the known-vector
guard; it does not execute a changed native root. These are focused controls,
not twelve full-matrix reruns. No reference or oracle mutation ships.

Initial normal validation failed because its authored stderr oracle prepended
successive command payloads, reversing their order. Actual command order was
correct. Preserve the initial driver/traceback; append command stderr in invocation
order and scan stderr afterwards. Final full matrix and controls pass after that
oracle correction. No clean-first-attempt normal result is claimed.

Keep [postinstall policy](../../tests/reference/test-slackpkg-postinstall-policy.sh),
[partial policy](partial-update-policy.md), [early apply](apply-early-exits.md),
[secondary apply](apply-secondary-workflow.md), [apply JSON](apply-json-result.md)
and [stable exits](../../tests/reference/test-error-exit-codes.sh) for their
separate boundaries. Raw20 observations do not change native install-new20
empty-AND-no-effect or upgrade20 failure requirements. Guards are not OS containment
or independent observation. No actual host absence/cleanup/native acceptance or
execution authority follows. All original criteria/findings/unselected options,
Phase1/kernel/schema gates and separate specification/migration/composition/
independent-safe-review/fresh-native-grant/platform-conformance gates remain.
