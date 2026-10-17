# Package snapshot boundary regression

Run from the repository root:

```bash
python3 tests/reference/test-package-snapshot-boundaries.py
python3 tests/reference/test-result-precedence.py
python3 tests/reference/test-apply-json-result.py
python3 tests/reference/test-main-completion.py
bash tests/reference/test-error-exit-codes.sh
```

The standard-library driver sources the reference in private Bash processes.
It checks 61 scenarios and 122 selected entry calls: thirteen direct validators,
36 direct captures and twelve before/after wrapper scenarios, each repeated
with stale state and reseeded destination files. Nested helper/parser calls
are additional to that entry count. Bash and GNU coreutils/findutils are used.

## Validation

The real validator, package parser and C-locale sort check handle missing paths,
a directory, empty content, unsorted/duplicate records, invalid records,
noncanonical archive/path forms, one/three canonical records, a valid last line
without a newline and an invalid tail after a valid record. Exact status,
diagnostic and record count are checked. Failures retain count zero; a preceding
valid record cannot leak a partial count. Validation must preserve private inputs.

One unreadable-snapshot row supplies a false private read predicate. This models
the branch directly and does not establish real permission-denial behavior for
an arbitrary user. Real file predicates handle the other private objects.

## Capture and atomic installation limits

Eighteen capture cases each start with an absent destination and with a previous
snapshot. They cover a regular private database, a command-line compatibility
symlink, ignored internal package-record symlinks, ignored nested records,
missing/non-directory/empty/invalid/duplicate-normalized databases, supplied
read/search denials, each of three temporary-file creation failures, enumeration
failure, sort failure, supplied candidate-validation failure and installation
failure. Distinct archive names that normalize to one record must be rejected.

Ordinary cases use real find, mktemp, sort, uniq, head, rm, mv, the package parser
and validator against owned private objects. Narrow wrappers validate command
arguments, private path roles and C-locale sort selection before delegating.
Temporary random names are represented by their owned listing/normalized/
candidate roles in the trace; their literal names are not authored expectations.
Head's pipeline invocation is checked on a separate trace because its relative
execution order with uniq is not asserted. No concurrent snapshot consistency
or whole-filesystem atomicity guarantee is inferred from these private cases.

Failure callbacks return errors instead of selected command operations. Access
denials supply predicate results; the candidate-validation failure replaces that
validator with a diagnostic callback. Other capture cases retain the real validator.
Exact controlled call order, error, count, destination bytes/existence and absence
of residual temporary files are checked after both calls. Existing destinations
must survive failures unchanged; successful capture installs the authored sorted
canonical three-record snapshot. Failed installation resets the validated count.

Source database inventory, lstat modes, symlink targets and regular-file bytes
must remain unchanged. This excludes destination and declared trace/counter files
from the immutable-input comparison. Internal capture-cleanup rm failures are
outside this test; those cleanups succeed in the modeled failure scenarios.

## Before/after wrappers

Each wrapper crosses initial files absent/present with removal failure, capture
failure and success. The removal command is real unless its return is supplied
as a failure. The capture operation is a callback producing three canonical
records on success. Exact target arguments and pre-capture absence are checked.
Before removes both snapshots; after removes only its final-state destination.

Only the selected wrapper's validity/count/error fields reset. Before's removal
of after-file bytes does not reset the after-wrapper's separate seeded flags.
A removal failure bypasses capture and leaves its shared error/count unchanged;
a capture failure propagates its diagnostic while keeping selected validity/count
zero. Both calls require the exact output state, trace, IFS and private inventory.

## Scope

No installed package database, normal initializer, main, apply/check/planning
workflow, GenInitrd policy, package command, boot operation, network or actual
clock is used. The existing shell snapshot regression keeps its historical scope
and is not rerun by this new driver. Workflow early exits, result projection and
real native acceptance remain separate. Guards restrict known calls and paths
but are not an OS sandbox. Private capture/cleanup assertions establish no global
host absence, independent semantic/native conformance, migration or execution
right. All original criteria, open findings and separate review/grant gates remain.
