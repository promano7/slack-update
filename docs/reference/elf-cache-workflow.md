# Private ELF cache and coordinator composition

Step 487 adds a source-only regression driver. The reference is byte-identical to
accepted486: this step does not change update behavior, native requirements or
result schemas. The new driver composes the real cache builder, object path/magic
helpers, dependency classifier, architecture-cache matcher, scan, recheck and
diagnostic renderer. It supplies raw cache and header/needed data and selected
command failures on owned private files. No inspected object is executed.

Run the exact focused selection from the repository root, without sudo:

```bash
python3 tests/reference/test-elf-cache-workflow.py
python3 tests/reference/test-elf-cache-construction.py
python3 tests/reference/test-elf-unresolved-display.py
python3 tests/reference/test-elf-scan-workflow.py
python3 tests/reference/test-elf-metadata.py
bash tests/reference/test-elf-architecture-resolution.sh
```

The new standard-library Python driver has60 independently authored scenarios:
scan/recheck entries, healthy/broken/identity-error objects, successful cache or
four selected cache failures, and two prior diagnostic seeds. Every recheck has
a nonempty one-object published input. Empty/missing-list behavior stays in the
separate existing scan driver, not this new composition's coverage.

| Cache selection | Expected coordinator boundary |
| --- | --- |
| Success | Real dependency classification and scan/recheck list processing run |
| Quiet raw-producer failure | Cache refresh fails; diagnostic renderer runs; object traversal/readers do not run |
| Final cache sort emits records then fails | Cache refresh fails before publication; no object processing |
| Quiet cache move failure | Staging cleanup attempted; no cache count or object processing |
| Cache count emits42 then fails | Cache bytes already published; count stays0; no object processing |

Failed cache refresh must produce raw/status1 for the selected coordinator,
preserve the previous broken list and count, and clear rendered diagnostics.
Selected initialization/cache/staging effects are explicitly retained. In the
count-failure case the newly published cache survives; this is not rollback.
The other coordinator status remains its prior authored value. Successful cache
controls observe real compatible-library matching, healthy list clearing, missing
library retention/publication and the separate reader-error behavior below.

## Real and supplied boundaries

Real Bash redirections/pipelines, mktemp, find, readlink, od, tr, awk, sort, rm,
chmod, mv, wc, cp and sed run on private paths. A fake ELF prefix is not a complete
native library or executable. The real architecture matcher reads the cache
produced by the real builder, rather than a separately seeded compatible-cache
oracle. Raw ldconfig bytes and object identity/needed strings are supplied.
The Bash function named `/sbin/ldconfig` intercepts that exact absolute spelling;
the installed executable and readelf/ldd are not called.

Normal main, package, boot and network entries are prohibited by named guards.
These guards are not OS containment. Quiet/late command faults are supplied,
not native disk/permission/race measurements. The new driver does not import
another driver's fixture or expected-result oracle. All expected output, raw
status, four selected state fields, callback vectors/multiplicity and full private
file bytes/directory inventory are independently authored.

Only the two generated six-character mktemp suffixes are normalized; literal
XXXXXX templates and every other callback argument remain exact. The callback
trace is checked separately from the file inventory. Concurrent pipeline callback
order is not fixed; cache-before-object serial relationships are checked.
Snapshots do not measure ownership, permissions, xattrs, descriptors, concurrent
writers or global host state. Python removes its owned temporary root afterwards;
that private cleanup is not whole-host cleanup or an independent observation.

## Evidence and retained behavior

All60 new cases, five complementary ELF suites and shell syntax pass under
preparerUID0. This is not an actual unprivileged OS or native Slackware run.
Against the exact accepted485 reference preimage retained in486, two healthy
controls pass and four move/count failure cases reject across both coordinators.
The old helper can hide a failed move or retain partial count stdout; the new
composition observes that result through real caller paths. Six syntax-valid
private source mutations reject: zero failure status, zero raw return and clearing
the prior published list, independently for scan and recheck cache-failure paths.
Those controls are retained preparation evidence, not normal user mutation runs.

A successful cache plus object identity error retains existing behavior: initial
scan emits diagnostics, omits the object and returns scan0/count0, while recheck
retains the object and returns verification failure. This characterizes current
code; it does not approve that result as native acceptance or amend any original
requirement. Private synthetic states are not proof of installed reachability.
There is no full main/apply/SBo/event/JSON workflow or stable-result mapping here.

The earlier helper-specific drivers retain their own larger metadata, list,
publication, display and command-failure scopes. This selected composition does
not cover every cache fault, empty input, untrusted path, reader protocol, actual
installed tool, atomic snapshot, global cleanup or two-platform conformance.
The historical56-command475-483 run remains unchanged; the new focused selection
is not a claim that a later integrated closing selection has already run.

Phase1/kernel incomplete; five native families/20scenarios,13findings/16gaps remain.
A/R/D unselected; schema1/reference-v1/C/Phase2/production closed. Original
install-new20 empty AND no-effect and upgrade20 failure criteria stay binding.
Native evidence/live bindingsNULL, host unobserved/global closureFALSE. Separate
native decision, independent reviews, conditional migration, actual composition,
independent safe whole review, fresh bounded grant and own-platform conformance
remain due. This private source regression grants no native authority.
