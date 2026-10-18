# SBo queue file selection and merge regression scope

Run from the repository root:

```bash
python3 tests/reference/test-sbo-queue-files.py
python3 tests/reference/test-sbo-queue-graph.py
bash tests/reference/test-sbo-dependency-order.sh
bash tests/reference/test-sbo-target-selection.sh
bash tests/reference/test-sbo-options.sh
```

The new standard-library Python driver sources the Bash reference without calling
`main()`. It exercises both queue-directory collectors, sorted target-set merging
and final ordered-queue merging, with their real parser, normalizers and graph
sorter. It uses real private files, directories, symlinks, Bash, AWK, `find`, `sort`,
`mktemp`, `dirname`, `cat`, `mv` and `rm`. Every test workspace and TMPDIR belongs
to the Python harness. Named guards prohibit installed updater/workflow/network
and package-database entries. They are not OS containment.

## Cases and observations

Forty collection entries cover ten directory profiles, both collectors and absent
or preseeded destinations. Profiles include missing and empty optional roots,
shared dependencies, controls/options/CRLF, adjacent duplicates, contradictory
orders, nested queues, ignored extensions, names containing spaces/newlines,
symlinked queue files and a symlinked directory supplied as the root.

The ordered collector rejects a cycle and preserves the old destination; the set
collector accepts the same targets as a sorted set. Real `find` does not follow
symlinked queue files or this command-line root symlink. A symlink root is tested
as a current helper observation, not an installed queue-layout recommendation or
a containment guarantee. NUL enumeration is required for the authored filenames.

Fifty-six merge entries cover nine sorted-set profiles and nineteen final-queue
profiles, each with absent and preseeded destinations. Check sorted unique unions,
preserved core order, sorted extra targets, duplicate removal, inline options,
option-map precedence, unused map entries, identical/conflicting map duplicates,
invalid names/options, comments/controls, blank lines, CRLF and missing sources.
Expected output, raw status and selected error scalars are authored explicitly;
no expected result is recorded from a reference run.

Preserve these current distinctions:

- Sorted-set merging passes source files directly to `cat`. Two unterminated
  records in separate files can join into one target (`z` plus `a\n` gives `za`).
- Final merging silently skips a missing core or option map, but a missing extra
  file fails through the pipeline. This is not a normative acceptance judgment.
- Final merging rejects control/comment records in the core, while the directory
  parser skips them; empty lines in the core are skipped.
- The first duplicate core entry supplies inline options unless a selected map
  overrides them. A later duplicate with invalid options still fails parsing.
- Collection resets its selection diagnostic; merge helpers can retain an older
  selection diagnostic. Option-normalization diagnostics reset only when reached.

The driver compares raw status, complete stdout/stderr, selected diagnostic state,
caller IFS and an unrelated scalar. It snapshots all private file bytes, directory
entries and link targets, excluding the explicitly owned callback counter. Success
may replace only the destination; failure preserves an absent or old destination.
Temporary files must disappear from these selected private workspaces. It does
not measure every shell variable, command vector, permission, ownership or xattr.

## Supplied failures and sensitivity

Fifty entries inject selected temporary-creation, enumeration, normalization,
graph-sort and destination-move failures, each with absent and old destinations.
The graph callback can emit a prefix before failing; it must not replace the
destination. Callback faults have authored diagnostics and do not model actual
permission, disk, race or concurrent filesystem failure. Normal collection uses
the real graph sorter; supplied faults are distinct entries.

Eight syntax-valid private source mutations are rejected:cycle-result preservation,
NUL enumeration, regular-file selection, move status, set uniqueness, final queue
uniqueness, option precedence and pipeline failure propagation. These focused
controls have their own delivery logs; they are not exhaustive mutation coverage
or normal user executions. The related dry-run workflow, apply-secondary workflow
and SBo option JSON drivers retain their separate scopes. Separate passes do not
prove an actual native composition.

No installed package database, synchronization, SBo build, ELF scan, network action
or boot operation runs in the new test. Private cleanup does not demonstrate global
host cleanup or absence of effects. No installed Slackware utility semantics or
own-platform conformance follows. Phase 1/kernel remain incomplete; A/R/D unselected,
schema 1/reference-v1/C/Phase 2/production closed. Native install-new status 20 still
requires empty AND no effect; upgrade status 20 remains failure. Original native,
specification/migration/composition and independent review/grant gates remain.
