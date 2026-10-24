# Step 524: private SBo workspace cleanup binding audit

This is a source-bound defect characterization, not a safety regression or native
acceptance. The runtime remains exact step 523, SHA256
`524f6910daab586bc4fed4682e31f365a3e988a11c254add904f0ce4a31f56ae`.
The driver refuses other runtime bytes, including any later repaired source.

Run explicitly from the repository:

```sh
python3 tests/reference/audit-sbo-workspace-cleanup-binding.py
```

The real `remove_owned_sbo_queue_workspace` function is sourced without main.
Six independent temporary fixtures each call it twice. Actual private directories,
files and a symlink are created. Shell functions constrain and record every
`readlink` and `rm` call; selected status43/readlink-output faults are supplied.
Normal canonicalization and removal use actual coreutils. No installed update,
package, boot, repository synchronization or native scenario is selected.

| Case | First status | Second status | Binding after first | Resource |
| --- | ---: | ---: | --- | --- |
| Empty owned path | 0 | 0 | Path empty, prior canonical retained | Retained |
| Normal owned directory | 0 | 0 | Both empty | Removed |
| Failed readlink | 1 | 1 | Both retained | Retained |
| Failed rm | 1 | 1 | Both retained | Retained |
| Supplied canonical mismatch | 1 | 0 | Both empty | Retained |
| Actual symlink at owned path | 1 | 0 | Both empty | Retained |

The last two rows reproduce the known loss of cleanup bookkeeping. Refusing
removal on mismatch/symlink protects the current target; clearing both fields
then prevents the next call from observing that unresolved path. A zero second
status is an empty-binding fast return, not successful resource disposal.
The symlink target sentinel is checked unchanged; regular queue bytes, symlink
identity, exact ordered call records and both complete binding states are checked.
The absent-path row intentionally retains a stale canonical field.

A later repair must keep refusal of unsafe removal and determine how unresolved
binding information survives. This audit does not authorize deleting a changed
path, rebinding it, retrying a native grant or treating retained metadata as fresh
ownership authority. Cleanup callers, stable results and whole-run compositions
still need separate review and tests. The driver is not added to the normal82
selection: a repaired source must reject this historical audit rather than pass it.

TemporaryDirectory disposal belongs to fixture teardown, not production cleanup
or evidence of whole-host absence. PATH/environment/coreutils/UID0 execution and
shell call guards are not OS containment. No native ownership, ACL/xattr, race,
atomic snapshot, independent review, provenance closure or Slackware conformance
is established. Existing unknown extras, incomplete491 binary history, 13 audit
findings, 16 native gaps and all original native criteria remain unresolved.

The new user request bounds work to524-531 with reserve532-535 only if needed.
Proposed sequence: characterization; cleanup-binding repair; caller composition;
cleanup status review; resulting focused work; integration; documentation; final
actual acceptance and separate whole inherited-condition/new-effect review.
This sequence is a plan and can change with evidence. No later step is performed
or accepted here. The root README is due at the end of the block. No new strong
pause, Phase1 completion, native authority or independent acceptance is claimed.
