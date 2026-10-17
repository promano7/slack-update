# Dry-run environment regression

Run from the repository root:

```bash
python3 tests/reference/test-dry-run-environment.py
python3 tests/reference/test-dry-run-workflow.py
python3 tests/reference/test-optional-module-probes.py
python3 tests/reference/test-boot-module-policy.py
python3 tests/reference/test-dry-run-json-result.py
```

The independent standard-library driver calls the real
`inspect_dry_run_environment` in private Bash processes. There are 726 scenarios,
each repeated after poisoning all eleven planning fields: 1452 inspection calls.
Expected flags, statuses and traces are authored separately from reference output.

## Discovery and mode gates

Isolated cases cover disabled, enabled and auto modes for each module. Command
discovery is supplied through a callback that accepts only the exact `command -v`
argument form and seven known names. Flatpak and readelf availability are varied
independently; all four sbopkg/sqg pairs and all eight mkinitrd/grub-mkconfig/
grub-script-check triples are exercised. Disabled modules must issue no lookup
or private path query. Enabled and auto modes use the same discovery predicates.

The isolated cases comprise six Flatpak, twelve SBo, six ELF, 192 boot and
24 Cinnamon scenarios. Another 486 cross all 243 five-module mode combinations
with two supplied command profiles and valid private symlinks. Complete ordered
lookup/predicate argument vectors must match on both calls. Each optional
capability flag is independent: absent tools do not suppress configured-path
predicates, and a missing tool cannot borrow another tool's available result.

## Real private path predicates

Eight boot layouts exercise missing paths, regular configuration files, GRUB
directories, wrong file/directory types, valid symlinks, broken symlinks,
configuration-only, directory-only and wrong symlink-target types. The real
Bash file/directory predicates operate on these private objects.

Eight Cinnamon layouts vary the private `.git` marker and builder. They include
a directory marker, a regular marker file, executable and nonexecutable regular
builders, valid/broken symlinks, missing entries and an executable directory.
The present helper recognizes `.git` through `-d` and its builder through `-x`.
Consequently a regular worktree-style marker is false, and an executable builder
directory is true. These are current predicate results; they establish neither
a usable Git checkout nor a valid runnable build program.

Configuration presence means a file predicate here; its contents are not parsed.
Executable bits are explicitly assigned on private fixtures, with no builder
invocation. Paths and the builder name contain spaces. A wrapper records and
restricts path tests while delegating the allowed predicates to Bash's builtin.
It does not substitute their boolean outcomes.

## State, return value and limits

Before both calls all eleven planning fields are set to 987. The exact complete
output vector must reset to the authored 0/1 values. IFS and all five module
modes plus four configured paths/names must remain unchanged. Exact private
fixture inventory, lstat modes, symlink targets and regular-file bytes are
compared before/after; only the declared callback trace may change. Empty stderr
and no unexpected stdout are required.

The helper has no explicit return. Its incidental status is 1 when Cinnamon
inspection is active and the final builder predicate fails, otherwise 0. The
driver records this existing status without treating it as a planning failure
or changing its semantics. The separate workflow regression checks that an
auxiliary inspection return does not replace its planning result.

Command availability is modeled; no installed command, package database,
configuration file, boot path or network service is inspected. No probe dispatcher,
runtime initializer, main, workflow, human plan renderer or native builder runs.
Known excluded entry points abort, but guards are not OS containment. Real
optional activation, boot policy, workflow and JSON drivers retain their own
separate boundaries. These private discovery checks grant no native execution,
contract selection, migration, conformance or whole-host safety/absence verdict.
All original native criteria, findings and separate review/grant gates remain due.
