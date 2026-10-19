# Testing and verification scope

Choose checks for the change being made and for the source tree they describe.
The mappings in [CONTRIBUTING](../CONTRIBUTING.md#reference-script-changes)
remain the detailed guide for reference-script changes. This document explains
how current regression checks, historical checkpoint harnesses and real
Slackware acceptance differ; it does not authorize a system run.

## Select the applicable checks

| Change or review | Verification scope |
| --- | --- |
| Documentation only | Review meaning and status, check changed links/fragments and whitespace, and confirm the intended file scope |
| Reference behavior | Run the focused regression checks for the affected behavior and review their fixture/environment requirements |
| Frozen historical checkpoint | Use that checkpoint's matching complete repository tree, fixtures and harness |
| Real Slackware acceptance | Use the separately reviewed scenario, target and execution scope from the acceptance workflow |

A directory name or `harness` suffix does not prove that a script is safe to
run anywhere. Read the entry point, selected functions, fixture paths, command
substitutions and required tools before executing an unfamiliar check.

For a shell-source change, the existing syntax check is:

```bash
bash -n tools/reference/slack-update-reference.sh
```

For a documentation change, inspect both unstaged and staged whitespace:

```bash
git diff --check
git diff --cached --check
```

Also inspect new files: an unstaged `git diff` does not list untracked content.
After adding the intended paths, `git diff --cached --stat` shows the complete
staged scope. Link checks must resolve paths from the containing document and
verify fragments, not just search for a filename somewhere in the repository.

Documentation checks do not need a new permanent fixture set or a native test
run merely because another numbered step has been delivered.

## Current regression checks

Select tests using the existing contribution mappings. For example,
[package-name parsing](../tests/reference/test-package-name-parsing.sh) sources
the reference without invoking `main()` and exercises the parser with fixtures.
Other harnesses have different dependencies, mock boundaries and outputs.
Do not infer that every script under `tests/reference/` has the same behavior.

Mock or supplied-data checks can validate the behavior they exercise. They do
not prove installed command semantics, native containment or complete acceptance
on Slackware 15.0 and Slackware-current. Record the actual check and its scope;
a PASS count alone does not identify what was demonstrated.

## Current CLI and configuration checks

Run these seven independent Python 3 checks from the repository root. Each invokes
Bash and uses only the Python standard library; the resolver also uses `dirname`
and `pwd` in private directories, and the help renderer invokes `cat`.
They have no shared Python test-support module or cross-test fixture imports.

| Test under `tests/reference/` | Actual exercised boundary |
| --- | --- |
| [test-cli-arguments.py](../tests/reference/test-cli-arguments.py) | Parser state/status/diagnostics only; no main or workflow |
| [test-cli-early-exits.py](../tests/reference/test-cli-early-exits.py) | Real main/parser/help; environment mocked and later boundaries prohibited |
| [test-configuration-parser.py](../tests/reference/test-configuration-parser.py) | Initialized parser state and private-file text parsing; no value validation/application |
| [test-configuration-resolver.py](../tests/reference/test-configuration-resolver.py) | Exact source relocated to private files; installed presence/readability modeled |
| [test-configuration-validation.py](../tests/reference/test-configuration-validation.py) | Authored supplied values and lexical validation; no file lookup or application |
| [test-configuration-application.py](../tests/reference/test-configuration-application.py) | In-memory scalar/array assignments; no apply workflow |
| [test-main-configuration-failures.py](../tests/reference/test-main-configuration-failures.py) | Real private-file loader/main; environment/application/privilege callbacks replaced, later effects prohibited |

Run the parser, early-exit and main-configuration checks when argument parsing
changes. Run the resolver plus main-configuration checks for resolver changes;
the latter covers explicit private paths, not installed-file precedence. Parser
state initialization or text grammar changes need the configuration-parser check
and the main loader check. Validation changes need the validation and main loader
checks. Assignment changes need the application check; changes to loader stage
ordering also need the main loader check. Help rendering needs the early-exit
check. Run all seven for a combined entry/configuration change or integrated review.
Environment normalization has its existing cron regression; its recorded
workflow failure is described under [known limits](#known-test-failures-and-fixture-repair).
The two main harnesses replace normalization and do not test its real behavior.

The main loader test includes valid-input controls which stop deliberately at a
modeled privilege callback with code 8. That is not a native privilege failure.
Its application callback checks loader sequencing, not real runtime assignments;
the assignment test covers those separately. Code 7 is the stable main rejection
status, while parser/resolver/validator internals use status 1. Early help writes
usage to stdout; invalid arguments write diagnostic plus usage to stderr. A
configuration-loading error writes its diagnostic without usage or structured
output, including with `--json` or `--events`.

All files/channels created by these checks are private test artifacts. Config
resolver unreadability is modeled, not a native permissions test; explicit symlink
and `..` acceptance describes current resolution without a containment guarantee.
Supplied parser/assignment values can deliberately bypass semantic validation.
Lexical checks do not prove path existence, canonical containment, URL validity,
resource availability or runtime safety. The guards are not an OS sandbox; review
newly introduced calls before extending a harness to changed reference code.

These are current repository regressions, not native Slackware acceptance or an
operational protocol implementation. They establish no whole-host absence of
effects, independent semantic acceptance, schema 1 freeze, contract-option choice
or native execution right. Original scenario/member criteria, unresolved findings
and separate review/grant/conformance gates remain binding.

## Current setup, completion and module checks

The seven independent Python drivers below use the standard library and Bash.
Select them for the affected boundary, alongside the earlier CLI/configuration
and JSON checks. Their expected results are authored separately from reference
output; none imports the shared JSON test support.

| Test under `tests/reference/` | Exercised boundary and material limit |
| --- | --- |
| [test-main-setup-failures.py](../tests/reference/test-main-setup-failures.py) | Real main/parser setup sequencing with supplied privilege, lock, trap, runtime and logging callbacks; positive controls stop at the banner |
| [test-main-completion.py](../tests/reference/test-main-completion.py) | Real main/parser dispatch and completion; setup, workflows, clock, mapper and output are callbacks; checks descriptor 3 routing/closure |
| [test-result-precedence.py](../tests/reference/test-result-precedence.py) | Real result mapper/message/preparation/status helpers with authored state and private ELF-result files; no workflows |
| [test-instance-lock.py](../tests/reference/test-instance-lock.py) | Real flock/descriptor lifecycle in owned private child sessions, independently observed with Python fcntl; selected command errors are modeled |
| [test-optional-module-probes.py](../tests/reference/test-optional-module-probes.py) | Real Flatpak/SBo/ELF/Cinnamon probes and selected Cinnamon detection; supplied discovery/package predicates and private checkout directory |
| [test-boot-module-policy.py](../tests/reference/test-boot-module-policy.py) | Real boot activation and request policy with supplied discovery/direct-probe results and private file/directory/symlink predicates |
| [test-check-workflow.py](../tests/reference/test-check-workflow.py) | Real check workflow/helper with supplied mirror, command, event and summary callbacks; selected supplied inconsistent pairs isolate result fields |

For detailed scenarios and exclusions, read the linked tests and the respective
[setup](reference/main-setup-failures.md),
[completion](reference/main-completion.md),
[result](reference/result-precedence.md),
[lock](reference/instance-lock.md),
[optional-probe](reference/optional-module-probes.md),
[boot](reference/boot-module-policy.md) and
[check workflow](reference/check-workflow.md) scope documents.

The lock test additionally requires Unix advisory locking, Python fcntl and
flock. Its finite handshakes and owned private process-group cleanup do not
prove installed application containment. The existing
[signal-cleanup regression](../tests/reference/test-signal-cleanup.sh) uses real
signals, timeout, locks and cleanup on private child-process fixtures; it checks
no normal package or boot workflow. These real private OS operations must not
be described as wholly mocked, or expand earlier historical mock-only claims.

For boot classification changes, also run the existing
[direct-generic regression](../tests/reference/test-current-direct-generic-boot-policy.sh).
It exercises real private classifiers/files and a stub GRUB validator. Its two
old available/partial expectations after failed validation were corrected in
step 448 against the already accepted steps 122/128/129 fail-closed contract.
The current 59 checks include unavailable/non-runnable and reason assertions.
This repaired current test does not rewrite frozen native criteria or evidence.

The CLI/configuration, setup/completion/module and JSON/NDJSON groups, plus
SBo options, stable exit codes, signal cleanup and direct-generic, comprise the
24-command baseline. The seven dry-run/package/apply checks below extend it to
31 through step458. The 459-466 review added seven drivers and three shell tests,
forming the earlier 41-command selection. The historical467-474 review added seven
new drivers and six complementary shell checks, for54 named commands. The current
475-483 selection appends the two repaired cron/initrd tests, for56. Select exact files; do not glob historical
harnesses. The earlier64 private source mutations from443-449 retain their original
scope; an integrated normal run is neither a fresh mutation run nor acceptance.

Callbacks and prohibited-entry guards are not an OS sandbox. Supplied flags,
status pairs and policy combinations need not be reachable native states. No
normal installed Slackware package/module/boot workflow or network request is
introduced by this block. No native bootability, whole-host absence of effects,
global cleanup or compatibility/conformance verdict follows from these tests.

## Current dry-run, package and apply checks

The seven additional Python drivers use the standard library and Bash. Run them
from the repository root, together with the preceding baseline for an integrated
review. Each expected result is authored independently of reference execution;
none imports another test's oracle.

| Test under `tests/reference/` | Exercised boundary and material limit |
| --- | --- |
| [test-dry-run-workflow.py](../tests/reference/test-dry-run-workflow.py) | Real dry-run orchestration with supplied operation/event/summary callbacks; no package or boot action |
| [test-dry-run-environment.py](../tests/reference/test-dry-run-environment.py) | Real dry-run environment inspection with supplied discovery/probes and private queue files |
| [test-dry-run-plan.py](../tests/reference/test-dry-run-plan.py) | Real human plan renderer, authored complete text fixture and supplied state/queue/option data |
| [test-package-snapshot-boundaries.py](../tests/reference/test-package-snapshot-boundaries.py) | Real package snapshot wrapper/parser/validator with a private package database, real find/coreutils and selected supplied command faults |
| [test-partial-update-policy.py](../tests/reference/test-partial-update-policy.py) | Real in-memory raw-action classifier and secondary-blocking assignments; no workflow |
| [test-apply-early-exits.py](../tests/reference/test-apply-early-exits.py) | Real apply prefix/classifier/blocker with supplied operations; positive controls stop at a deliberate private checkpoint before secondary dispatch |
| [test-apply-secondary-workflow.py](../tests/reference/test-apply-secondary-workflow.py) | Complete real apply orchestration with supplied operations/events/summary and seeded private files; no normal main or installed tool actions |

Read each linked test and its corresponding scope document:
[dry-run orchestration](reference/dry-run-workflow.md),
[environment](reference/dry-run-environment.md),
[plan rendering](reference/dry-run-plan.md),
[snapshot boundaries](reference/package-snapshot-boundaries.md),
[partial-update policy](reference/partial-update-policy.md),
[early apply exits](reference/apply-early-exits.md) and
[secondary apply](reference/apply-secondary-workflow.md).

The package snapshot driver uses real private files and commands; it does not
inspect the installed package database. The environment and plan checks use
private files and supplied module states. File predicates, coreutils, redirection
and callback-written queue content are real where each scope says so. This block
must not be described as wholly mocked or as native tool acceptance.

For a shared workflow/result change, run the relevant workflow and JSON/result
checks together; rendering and supplied event callbacks cover different boundaries
from JSON serialization and NDJSON transport. Apply-prefix controls use process
marker 86 at their positive continuation checkpoint. Complete secondary controls
instead reach summary, whose supplied return becomes the normal-end raw workflow
return. Neither marker nor raw workflow return establishes a main/application
exit, native success or execution authority. Authored inconsistent flags and raw
statuses need not be reachable installed states.

Current reference synchronization failures can retain a failed SBo state even
when later selection/build actions complete; queue/ELF failure can block later
processing. Event state and raw code are separately observed fields. Preserve
these regression expectations without adopting them as original native semantics:
install-new20 still requires empty output AND no effect; upgrade-all20 remains a
failure. A normative change requires its own independent specification/impact,
explicit migration if needed, actual-composition review and later native gates.

The seven drivers retain 80 rejected private source mutations from steps451-457.
Their records include focused versus full-matrix scopes, the supplementary
secondary-workflow row and the initial nondistinguishing priority-row correction.
An integrated normal run does not rerun these controls or erase earlier failed
attempts. Guards prohibit known unwanted calls; they are not OS containment or
independent observation of an actual native graph.

## Current boot, detector, wrapper and human-summary checks

The 459-466 block added seven independent Python drivers. They use the
standard library and Bash with the real/private/supplied boundaries documented
below; none imports another test's oracle. Read the dedicated scope for selected
faults, authored inconsistent states and exclusions before extending a test.

| Test under `tests/reference/` | Exercised boundary and material limit |
| --- | --- |
| [test-boot-preparation-workflow.py](../tests/reference/test-boot-preparation-workflow.py) | Real coordinator and state/event ordering; prerequisite, initrd/GRUB operations and events supplied |
| [test-package-change-detection.py](../tests/reference/test-package-change-detection.py) | Real ABI/kernel detectors, parser/snapshot helpers and boot policy; private snapshots and supplied capabilities |
| [test-mirror-probe.py](../tests/reference/test-mirror-probe.py) | Real resolver/probe/check helpers; private files/readability, two modeled denials and supplied discovery/transport/package callbacks |
| [test-flatpak-update.py](../tests/reference/test-flatpak-update.py) | Real wrapper with supplied discovery/command and carried status sequences; no installed Flatpak |
| [test-cinnamon-rebuild.py](../tests/reference/test-cinnamon-rebuild.py) | Real wrapper, private executable/link predicates, subshell/cd and inert builders; supplied Git and selected cd rejection |
| [test-slackpkg-update.py](../tests/reference/test-slackpkg-update.py) | Real wrapper/capture, private find/sort/wc and files; supplied Slackpkg, exact guarded /etc-to-private root relocation and selected faults |
| [test-human-summary.py](../tests/reference/test-human-summary.py) | Real apply/check renderers with independently authored complete output/state, supplied clock and private lists/wc/sed |

Their scopes are [boot workflow](reference/boot-preparation-workflow.md),
[detectors](reference/package-change-detection.md), [mirror](reference/mirror-probe.md),
[Flatpak](reference/flatpak-update.md), [Cinnamon](reference/cinnamon-rebuild.md),
[Slackpkg](reference/slackpkg-update.md) and [human summaries](reference/human-summary.md).
The88 private source controls retain their focused-row/repetition scopes and
original failures/corrections; they are not repeated by normal integrated testing.
Real inert builders and private coreutils/file/lock/signal operations are not
wholly mocked and do not establish native acceptance or OS containment.

The earlier 41-command review selected the 31-command baseline, these seven
drivers and three existing shell tests:

| Complementary test | Additional real/supplied scope |
| --- | --- |
| [test-grub-blocked-after-initrd-failure.sh](../tests/reference/test-grub-blocked-after-initrd-failure.sh) | Real prerequisite/GRUB transaction in private paths with supplied generator/validator, selected coordinator and JSON/result checks; requires jq |
| [test-package-name-parsing.sh](../tests/reference/test-package-name-parsing.sh) | Real parser/exact-name/suffix helpers, authored records and private package files; no installed database enumeration |
| [test-slackpkg-postinstall-policy.sh](../tests/reference/test-slackpkg-postinstall-policy.sh) | Real wrapper/collection and JSON/message helpers with supplied Slackpkg/find, private lists and real sort/wc |

The [block review](reference/repository-regression-block-459-466.md) records the
selected order, source binding, current behavioral limits and retained failures.
These suites do not execute a normal installed package update or native boot
workflow. They require Python3/Bash and ordinary Unix tools; individual scopes
add flock/fcntl, timeout, jq and private inert executables. Guarded entry points
are not an operating-system sandbox. Complete source/test/fixture bytes must
match the delivery to interpret a reported result.

Do not infer native success or a stable main result from a raw helper zero or a
human success label. The existing summary recommends reboot on a broad kernel
trigger even after skipped/failed preparation; this test records that text and
does not endorse rebooting. Slackpkg direct count failure can leave valid1 with
an empty count; Cinnamon clone-failure wording differs from preseeded-builder
continuation. Read the respective scopes; passing regressions do not resolve
those limits or amend original native install-new20/upgrade20 criteria.

## Current SBo, ELF, runtime and boot reader checks

The current [475-483 integrated review](reference/repository-regression-block-475-483.md)
keeps the earlier54-command order and appends the repaired cron and installed-initrd
fixtures. Its exact56-command order is the reproducible selection;
there is no glob over historical or native acceptance scripts. Each Python
matrix uses its own authored oracle and the standard library, Bash and the
private/supplied boundaries in its scope.

| Test under `tests/reference/` | Exercised boundary and material limit |
| --- | --- |
| [test-sbo-queue-graph.py](../tests/reference/test-sbo-queue-graph.py) | Real Bash/AWK graph and ordering; authored independent graph model, private inputs |
| [test-sbo-queue-files.py](../tests/reference/test-sbo-queue-files.py) | Real directory collection/merging and selected supplied file-operation faults |
| [test-sbo-workflow.py](../tests/reference/test-sbo-workflow.py) | Real synchronization/core/ABI/final coordinators; command/collector callbacks supplied |
| [test-elf-metadata.py](../tests/reference/test-elf-metadata.py) | Real private magic/path/AWK/cache matching; readelf bytes/status supplied |
| [test-elf-scan-workflow.py](../tests/reference/test-elf-scan-workflow.py) | Real private traversal/recheck/list handling; initial traversal/order failure propagation and a real private missing-root find error; cache/dependency readers supplied |
| [test-runtime-logging.py](../tests/reference/test-runtime-logging.py) | Real private mkdir/files, sed/tee descriptor routing and find rotation; state/date/mktemp/fault callbacks supplied |
| [test-boot-artifact-validation.py](../tests/reference/test-boot-artifact-validation.py) | Real token/scalar/package/output/GRUB text helpers, private awk/chmod and supplied GRUB checker |

The six extra shell tests cover SBo dependency order, target selection and
personal queue protection, ELF architecture resolution, private GRUB replacement
and synthetic generated-initrd post state. The linked block review gives exact
filenames and the dedicated scope links. Normal passes do not rerun the retained
private mutation controls or establish a native composition.

The selected suite runs as an ordinary developer without sudo. Requirements
include Python 3, Bash, jq, Unix advisory locking/flock, timeout and the ordinary
GNU coreutils/findutils/sed/awk used by the scopes. Delivery helpers require
Python 3.9 or newer. Real private files, links, permissions, inert builders,
locks, signals and child descriptors are effects; callback guards are not OS
containment or global host absence. This is not two-platform native conformance.

Step 477 checks initial ELF traversal/order failures before list publication; see
[the scan scope](reference/elf-scan-workflow.md#initial-scan-pipeline-failure-handling).
Step 478 additionally checks count/copy statuses and post-build sort/copy
failures, and processes nonempty unterminated verification records. Copying can
still alter a destination partially. Step 479 checks resolved-list clearing
before success/status reporting. Step 480 checks diagnostic/staging initialization
failures before cache refresh; empty/missing verification lists still return early.
Step 481 checks diagnostic rendering/clearing and propagates its failure before
publication. Remaining limitations include unresolved-list display and rotation projections,
partial runtime setup without rollback, stale direct-call error fields, lexical
rather than semantic path/version filtering and GRUB path matches across distinct
menuentries. The exact conditions remain in the scope documents. Recording a
behavior does not approve it as native success or weaken original requirements.

## Step 484 focused addition

Run `python3 tests/reference/test-elf-unresolved-display.py` for 33 private
unresolved-list display scenarios. The [ELF scope](reference/elf-scan-workflow.md#unresolved-list-display-failure-before-publication)
gives the exact nine-command focused selection, supplied faults and real private
effects. A failed display now stops publication while retaining failure status
and the previous list. Cache/staging/diagnostic effects can already have occurred.

The 56-command 475-483 selection above remains its historical integrated baseline;
this addition does not retroactively change that selection or confirm a new pause.
Prepared 484 awaits the complete user application/test/commit/push/source report.
The new bounded block aims for 8-12 actual steps, subject to findings and a later
integrated review; no native acceptance criterion or gate changes.

## Step 485 focused addition

Run `python3 tests/reference/test-elf-cache-construction.py` for 50 private cache
construction scenarios. The [cache scope](reference/elf-cache-construction.md)
gives the ten-command focused selection, raw/identity/selected-sort callbacks,
real private commands and remaining publication/count/cleanup limits. Failed
construction returns before publication; prior cache bytes survive the selected
faults while the current record count stays zero. Diagnostic effects remain.

Complete supplied484 is accepted at `5bb6aba72ad5881389363099f240f8ffeb9cd940`.
Prepared485 awaits its own full return. The historical56-command selection remains
unchanged; neither focused addition confirms the new block's closing pause.

## Step 486 focused extension

The current `test-elf-cache-construction.py` matrix has100 scenarios: the original
50 construction cases plus50 publication/count cases and inactive controls.
The [publication/count scope](reference/elf-cache-construction.md#publication-and-count-failure-handling-step-486)
records exact failure effects and the unchanged ten-command focused selection.
Failed moves return before count; failed counts keep the current count zero.
Destination bytes may already have changed and are not rolled back.

Complete supplied485 is accepted at `e5398e6f0cad21c7ce82d883701ba2812a690d50`.
Prepared486 awaits its full return. Two actual steps (484-485) are complete in the
new block; the last confirmed strong STATIC repository pause remains483.

## Step 487 real ELF helper composition

Run `python3 tests/reference/test-elf-cache-workflow.py` for60 private scenarios
that compose the real cache builder, dependency/cache matching, scan, recheck and
diagnostic renderer. The [composition scope](reference/elf-cache-workflow.md)
gives the exact six-command ELF selection, supplied metadata/fault boundaries,
retained reader-error behavior and publication/count effects. Reference code is
byte-identical to accepted486; no native criterion or schema changes.

Complete supplied486 is accepted at `1b85fde4fa707d67a625922d3c6ddbcbba09b382`.
Prepared487 awaits its own complete return. Three actual steps484-486 are complete;
last confirmed strong STATIC pause483. This focused run is not closing integration.

## Known test failures and fixture repair

| Test or attempt | Recorded result and current treatment |
| --- | --- |
| `test-cron-minimal-environment.sh` | Historical 19/79 failure reproduced in step 475. The current fixture uses private local mirrors with the real reader/preflight: 153 checks cover three successful modes and 12 preflight rejections. This repairs the fixture dependency; it does not establish native cron compatibility. See [cron scope](reference/cron-minimal-environment.md). |
| `test-initrd-installed-kernel.sh` | Historical 1/69 failure reproduced in step 476. Its initrd-only auto expectation predated the accepted partial-path removal. The repaired 90 checks require inactive partial layout and preserve complete managed discovery plus later unsafe-scalar rejection. Reference and native criteria unchanged; see [fixture alignment](reference/boot-artifact-validation.md#installed-kernel-fixture-alignment). |
| Original step473 generated-initrd test | Passed in the preparer's UID0 environment, failed for the user's pending checkout and aborted on unset INITRD_OK. Exact target UID1000 callback reproduced the failure; no actual user temp ownership or unprivileged OS run was independently observed. |
| Repaired `test-current-geninitrd-post-state.sh` | User-reported 52 checks pass at accepted473: only the exact synthetic target UID query is supplied, with real modes/paths/links and explicit non-root rejection/root restoration. Reference root-ownership guard unchanged. See [repair details](reference/boot-artifact-validation.md#repair-1-synthetic-geninitrd-ownership-fixture). |

The original interrupted473 attempt, local root-only baseline, callback
reproduction, repair and complete later user return all remain in delivery
history. The later success qualifies that synthetic fixture; it does not erase
the failure, certify a real root-owned initrd or explain older unknown anomalies.
The original cron failure remains retained alongside its step 475 fixture repair.
The installed-initrd failure likewise remains recorded alongside its step 476
contract-aligned fixture correction. Both later focused regressions are runnable;
neither is retrospectively added to the historical step 474 selection of 54
commands. Other recorded failure projections and native acceptance remain open.

## Cron logger completion qualification

The initial planned step482 integration ran56 commands:55 passed, but cron missed
one events diagnostic and failed1/153. A serial repeat failed a different events
diagnostic1/153. Step482 changes only the fixture to capture the exact logger PID,
close its pipe writers and wait before inspecting files, retaining main's status.
All153 assertions remain unchanged. Three old and three repaired FIFO-barrier
probes distinguish main exit from complete logging; source runtime is unchanged.
The wrong-heredoc authoring probe and correction remain qualified separately.
See [the completion scope](reference/cron-minimal-environment.md#logger-completion-before-assertions).

That focused repair moved closing integration to483, nine steps within the
requested8-12. It did not claim a56-command passing integrated run or new pause;
the current integrated review above records the later selection separately.
The historical54-command474 selection remains unchanged. Final actual return must
still precede the separate every-whole inherited/nested-body review.

## Conditional repository pause after step483

The preparation baseline is the confirmed STATIC repository pause474. The bounded
block is475-483; prepared483 does not attest its later application or pause.
Confirmation needs all56 exact outputs, scoped commit/subject, reported successful
push, clean matching full HEAD/origin and the complete source/Git-mode/tree report.
THEN a separate post-return review must read EVERY WHOLE inherited condition,
including every nested original body, and assess all new effects, obligations,
cleanup needs and observation limits. Counts, hashes, summaries and prior review
are not substitutes. Whole inherited bodies remain unchanged in the delivery.

The read-only reporter observes tracked source, index blobs, working executable
bits and a reconstructed Git tree. It brackets local clean/identity reads but
has no atomic filesystem snapshot, independent GitHub view, ignored-file survey
or host/native observation. Synthetic validation commits are not user history.
Same-assistant confirmation is not independent native or semantic acceptance.

Actual host state remains unobserved-not-claimed-absent; native evidence/live
bindings are null and actual global host closure false. Native dispatch, service
channels, partial publication and live/future rights remain closed. Original
Phase1/kernel criteria, findings, unselected A/R/D, specification/impact review,
conditional migration, ACTUAL composition, independent safe ACTUAL WHOLE review,
fresh explicit bounded native grant and own-platform conformance remain due.
No source/run/grant binding or consumed authority is renewed by this block.

A later Slackware-current refresh cannot invalidate completed STATIC repository
work. After actual final confirmation, STOP until a NEW bounded request. This
repository pause does not complete Phase1/kernel, freeze schema1/reference-v1,
open C/Phase2/production or authorize a native operation.

## Current JSON and NDJSON checks

Run these checks with Python 3 from the repository root. All six invoke Bash; the two existing shell regressions below also use standard
command-line tools such as `mktemp`, `sed` and `grep`.
Each Python test prints its own scenario or check count and fails on a mismatch.

| Test under `tests/reference/` | Supplied-data coverage |
| --- | --- |
| [test-json-control-escaping.py](../tests/reference/test-json-control-escaping.py) | Shared escaping of all C0 characters Bash can represent; Bash strings cannot contain NUL |
| [test-check-json-result.py](../tests/reference/test-check-json-result.py) | Complete current check-result fields, types, statuses and diagnostic precedence |
| [test-dry-run-json-result.py](../tests/reference/test-dry-run-json-result.py) | Complete current dry-run result, planned commands and module arrays/statuses |
| [test-apply-json-result.py](../tests/reference/test-apply-json-result.py) | Complete current apply result using authored supplied state and fixed-date initialization |
| [test-event-ndjson.py](../tests/reference/test-event-ndjson.py) | Complete supplied event records, sequence state, wrappers and descriptor routing |
| [test-sbo-option-json.py](../tests/reference/test-sbo-option-json.py) | Supplied option-file rows, including final EOF rows, and whole dry-run/apply projections |

The check, dry-run, apply, event and option tests share the strict decoder and
type-aware comparator in `json_result_test_support.py`. Run all five when that
support changes. The option test imports authored scenario helpers from the
dry-run and apply tests; run it when either helper changes. The escaping test
has its own driver. A change to shared shell escaping can affect all six.

For SBo option handling, also run
[`bash tests/reference/test-sbo-options.sh`](../tests/reference/test-sbo-options.sh).
For shared result/status behavior, also run
[`bash tests/reference/test-error-exit-codes.sh`](../tests/reference/test-error-exit-codes.sh).
The SBo harness calls the queue builder with a stubbed `sbopkg`; the exit-code
harness calls `main` with replaced configuration, root, locking, runtime,
workflow and output boundaries. They use private fixture files; some existing
checks read the actual clock. Review each harness before expanding its scope.

These JSON/NDJSON checks exercise selected functions with supplied data, not a
normal update workflow. Apply-result projection uses `initialize_runtime_state`
with a fixed date, not the file-creating `initialize_runtime`. Expected objects
are authored test data; negative controls reject deliberate output mutations.
The EOF regression does not establish ordinary update data loss: the current
normalized-map producer already emits newline-terminated rows.

These tests cover provisional schema 0. They do not freeze schema 1, establish
native reachability or prove clock, custody, once-only, absence-of-effects or
host-safety properties. The shell reference's raw-20 reporting is not acceptance
of the distinct original native requirements: install-new 20 requires empty
output AND no effect; upgrade-all 20 is a failure. Original native obligations,
findings, decisions and separate execution grants remain unchanged.

## Historical checkpoint harnesses

Some checkpoint tests bind exact README bytes, fixture hashes, permitted
prefixes and the complete repository inventory. For example, the
[manuscript audit freeze harness](../tests/reference/test-phase-1-operational-joint-manuscript-audit-freeze-and-safe-pause-review-harness.sh)
checks its original supplied inputs, source roots and exact path set.
Later documentation additions can therefore violate its historical inventory
contract even when the frozen implementation and evidence are unchanged.

Before interpreting a failure, identify the checkpoint and read its policy,
baseline and actual failing assertion. Do not dismiss an arbitrary regression
as historical: only a demonstrated snapshot mismatch supports that conclusion.

To reproduce an applicable repository-only historical check, obtain its verified
complete commit/tree. A detached worktree keeps the current checkout separate:

```bash
git worktree add --detach ../slack-update-checkpoint CHECKPOINT_COMMIT
```

Replace `CHECKPOINT_COMMIT` with the verified commit for the record being
reproduced. This command prepares a source tree; it does not select or run a
test. A reported short commit prefix must resolve to the correct local commit
and matching source binding. If the matching tree is unavailable, record the
check as not reproduced rather than inventing a result.

Do not copy the archived README over the current one to force a pass: its links
were rebased, and one file cannot recreate a complete historical inventory.
Do not weaken frozen baselines or rewrite old acceptance records for a later
checkout. An intentional new behavior or contract change needs its own scoped
review and evidence; historical records retain their original claims.

## Real acceptance and reporting

Scripts in the [real acceptance guide](../tests/acceptance/reference/README.md)
exercise actual Slackware installations. Apply scenarios require a disposable
snapshot or equivalently recoverable environment and the appropriate reviewed
execution scope. Even a preflight may refresh metadata or produce local state.
Keep each platform's evidence and source/run bindings separate.

Historical authorization is not a standing right to repeat a native run.
Preparing a worktree, passing mocks, committing documentation or reaching a
repository pause does not grant that right. Read the
[acceptance/evidence guide](reference/acceptance-evidence-guide.md) for the
original scenario labels and the different claims supported by each record.

When reporting verification, name the check, source/checkpoint, outcome and
material limits. Distinguish local checks from a user's reported commit/push,
actual native evidence and final repository pause confirmation. Early failures,
missing dependencies or absent matching snapshots must remain visible.
