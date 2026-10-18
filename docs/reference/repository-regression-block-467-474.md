# Integrated repository regression block 467-474

This is the prepared closing review for the bounded eight-step repository block.
Complete supplied returns are accepted through repaired473 at
`ffda4571b320877ac85e61144b4ee17784095fcc`, parent
`106c40dbbf40faa0851524e56bccebe849b027ad`, tree
`d03d8e361437de6cb1542a2a7dd16585a1826b53`: eight passing selected commands,
52 synthetic GenInitrd checks, five paths, 475 insertions/one deletion, two new
100644 files, required subject, reported successful push, empty status and full
matching local heads. Source/mode/tree report checksum is
`e1d75f69f3e367107e31021b9cefeb0975b4fdfe22052a9b33ea999f755a36b6`.
This is qualified supplied terminal/local Git evidence, not independent terminal,
GitHub or native observation. The original473 failed attempt remains preserved.

Step474 updates README, roadmap, testing, contribution, development setup, usage
and both documentation indices, plus CHANGELOG and this review, as requested.
The ten-path scope changes no implementation, test, fixture, native criterion or
old executable mode. It adds this one document. README remains an overview;
detailed step history stays in CHANGELOG/reference. The delivery pins the whole
source/mode inventory, preimages and postimages, with a read-only final reporter
outside Git. Prepared474 cannot attest its later commit, push or pause.

## Added scopes and retained sensitivity controls

| Step | Current scoped checks | Focused source controls |
| --- | --- | ---: |
| 467 | [SBo graph](sbo-queue-graph.md): 1737 graph entries, eight records, 41 constraints | 8 |
| 468 | [Queue files](sbo-queue-files.md): 40 collection, 56 merging, 50 supplied-fault entries | 8 |
| 469 | [SBo workflow](sbo-workflow.md): 54 sync, 64 core, 24 ABI, 72 gate, 96 final entries | 9 |
| 470 | [ELF metadata](elf-metadata.md): 96 magic/path, 68 header, 44 dynamic, 189 cache, 560 dependency entries | 10 |
| 471 | [ELF scan/recheck](elf-scan-workflow.md): 60 scan, 96 verify, four diagnostic entries | 9 |
| 472 | [Runtime/logging](runtime-logging.md): 28 setup, 28 logging, six rotation entries | 9 |
| 473 | [Boot artifacts](boot-artifact-validation.md): 20 version, 44 scalar, 12 snapshot, ten output, 34 GRUB entries | 10 |

The ownership-fixture repair separately rejects three guard mutations and has
52 normal post-state checks. Earlier controls retain their own focused-row,
syntax and repetition qualifications. This integrated run does not rerun those
mutations or add heterogeneous entry counts into a native coverage score.
The new drivers have independently authored expected results and do not import
one another's oracle. Supplied callbacks are not installed command conformance.

## Exact integrated selection

The 41-command selection through466 is extended by the seven new drivers and
six complementary shell tests below, for 54 distinct commands. Run from the
repository root as an ordinary developer without sudo. Requirements include
Python 3, Bash, jq, Unix advisory locking/flock, timeout, awk and the ordinary
GNU coreutils/findutils/sed identified by each scope. Delivery helpers require
Python 3.9 or newer. Python tests use the standard library. The JSON tests retain
their existing shared decoder/helper dependencies; that does not make their
supplied outputs a native schema freeze.

```bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1
command -v jq >/dev/null
python3 tests/reference/test-cli-arguments.py
python3 tests/reference/test-cli-early-exits.py
python3 tests/reference/test-configuration-parser.py
python3 tests/reference/test-configuration-resolver.py
python3 tests/reference/test-configuration-validation.py
python3 tests/reference/test-configuration-application.py
python3 tests/reference/test-main-configuration-failures.py
python3 tests/reference/test-main-setup-failures.py
python3 tests/reference/test-main-completion.py
python3 tests/reference/test-result-precedence.py
python3 tests/reference/test-instance-lock.py
python3 tests/reference/test-optional-module-probes.py
python3 tests/reference/test-boot-module-policy.py
python3 tests/reference/test-check-workflow.py
python3 tests/reference/test-json-control-escaping.py
python3 tests/reference/test-check-json-result.py
python3 tests/reference/test-dry-run-json-result.py
python3 tests/reference/test-apply-json-result.py
python3 tests/reference/test-event-ndjson.py
python3 tests/reference/test-sbo-option-json.py
python3 tests/reference/test-dry-run-workflow.py
python3 tests/reference/test-dry-run-environment.py
python3 tests/reference/test-dry-run-plan.py
python3 tests/reference/test-package-snapshot-boundaries.py
python3 tests/reference/test-partial-update-policy.py
python3 tests/reference/test-apply-early-exits.py
python3 tests/reference/test-apply-secondary-workflow.py
bash tests/reference/test-sbo-options.sh
bash tests/reference/test-error-exit-codes.sh
bash tests/reference/test-signal-cleanup.sh
bash tests/reference/test-current-direct-generic-boot-policy.sh
python3 tests/reference/test-boot-preparation-workflow.py
python3 tests/reference/test-package-change-detection.py
python3 tests/reference/test-mirror-probe.py
python3 tests/reference/test-flatpak-update.py
python3 tests/reference/test-cinnamon-rebuild.py
python3 tests/reference/test-slackpkg-update.py
python3 tests/reference/test-human-summary.py
bash tests/reference/test-grub-blocked-after-initrd-failure.sh
bash tests/reference/test-package-name-parsing.sh
bash tests/reference/test-slackpkg-postinstall-policy.sh
python3 tests/reference/test-sbo-queue-graph.py
python3 tests/reference/test-sbo-queue-files.py
python3 tests/reference/test-sbo-workflow.py
python3 tests/reference/test-elf-metadata.py
python3 tests/reference/test-elf-scan-workflow.py
python3 tests/reference/test-runtime-logging.py
python3 tests/reference/test-boot-artifact-validation.py
bash tests/reference/test-sbo-dependency-order.sh
bash tests/reference/test-sbo-target-selection.sh
bash tests/reference/test-sbo-personal-queue-protection.sh
bash tests/reference/test-elf-architecture-resolution.sh
bash tests/reference/test-grub-atomic-replacement.sh
bash tests/reference/test-current-geninitrd-post-state.sh
bash -n tools/reference/slack-update-reference.sh
test -x tools/reference/slack-update-reference.sh
git diff --check
```

All54 normal outputs are retained in the delivery validation record. They run on
the accepted473 implementation/test/fixture bytes; the prepared474 edits only
these ten documentation paths. The final user return must still run all54 on
the prepared tree. Document meaning, changed links/fragments, exact scope and
whitespace are reviewed separately. This is not a blanket all-harness PASS.

Real private operations include files, links, permissions, redirections, AWK and
other coreutils, descriptors/pipelines, advisory locks, signals, inert executable
builders and private GRUB replacement. Supplied boundaries include transports,
package/boot operations, metadata readers, selected discovery and fault results.
Named guards are not an OS sandbox or a complete native call-graph review. No
normal installed package, service, boot generator or native acceptance workflow
is introduced by this selection. Private work/cleanup proves no global absence.

## Known failures, repair and observed limitations

The [testing guide](../testing.md#known-test-failures-and-fixture-repair) records
both excluded failures. Cron's workflow cases hit the real mirrors preflight
before supplied slackpkg and failed19/79 here. Installed-initrd's absent-GRUB
fixture expects auto availability, but the current managed-layout probe requires
both components; it failed1/69. Their original assertions/source remain unchanged
and the expectation/implementation issue remains unresolved. They are excluded
from the passing54, not silently repaired or accepted as native behavior.

Original473 passed its three initial selected tests, then its synthetic GenInitrd
fixture failed for the user and aborted on unset INITRD_OK before staging,
commit, push or final report. It passed here because preparation used UID0.
A supplied target UID1000 reproduced the same failures and exposed the root-owner
guard. An actual unprivileged OS reproduction was unavailable; the user's deleted
temporary-file ownership was not independently observed. Repair models only the
exact target UID query, delegates real mode/path queries, initializes INITRD_OK,
reports positive-validation errors and explicitly checks non-root rejection plus
root restoration. The real reference root-owner guard is unchanged. User accepted
52 repaired checks in the complete actual473 return; original failure/history
and qualified reproduction remain intact. This is synthetic fixture portability,
not native ownership or bootability conformance.

Other observations remain in their full scopes: queue/option precedence and
quiet fault behavior; unchecked scan/find/sort/copy/count projections; early-empty
recheck preservation and ignored unterminated input; partial runtime setup without
rollback; filtered console/log output with retained emoji/unsupported ANSI and
first-CR removal; rotation without a type filter and ignored find failure; lexical
version/path checks; stale direct-call error fields; duplicate same-version kernel
records; output absolute-only checks and GRUB kernel/initrd matches across distinct
menuentries. These are recorded implementation limits, not newly approved native
criteria. Original install-new20 still requires empty output AND no effect;
upgrade20 remains failure. Raw helper zero or a success/reboot/no-modification
message is separate from native result, no-effect, boot safety and final status.

All older failed attempts, mode/extraction/link/inventory observations and unknown
causes remain in immutable history. This block also retains471's SSH disconnect
and successful push-only retry, the recovered exact470 package after absent
scratch state, and local authoring/oracle/packaging failures with their corrections.
New successful runs neither explain unknown causes nor prove end-to-end restoration.
No original native criterion, frozen fixture, contract option or consumed grant is
rewritten by overview updates or the explicitly synthetic ownership repair.

## Conditional STATIC repository pause

The preparation baseline is the confirmed strong STATIC repository pause466.
No new pause is confirmed by this document or local PASS. Complete actual474 must
first include application/scope checks, all54 outputs, exact scoped commit/subject,
reported successful push, clean matching full HEAD/origin and the full pinned
source/Git-mode/tree report. THEN a separate post-return review must read EVERY
WHOLE inherited condition, including every nested original body, and assess all
new in-scope effects, outstanding obligations, cleanup requirements and observation
limits. Summaries, hashes, counts and earlier reviews are not substitutes. Whole
inherited458 and expanded confirmed466 bodies remain unchanged in the delivery.
A same-assistant confirmation is not independent native or semantic acceptance.

The reporter checks all tracked bytes, index blobs, working executable bits and
reconstructed SHA1 Git tree. Its local identity/clean reads do not lock an atomic
filesystem snapshot, query GitHub independently, survey ignored files or observe
host/native state. Private validation commits are explicitly synthetic; no user
Git object is fabricated. Ordinary repository artifacts and test-owned cleanup
are not native cleanup or whole-host safety evidence.

Actual host state remains unobserved-not-claimed-absent, current native evidence
and live bindings null, actual global host closure false. Native dispatch,
service channels, partial operational publication and live/future rights remain
closed. Phase1/kernel are incomplete, A/R/D unselected, findings/gaps unresolved;
schema1/reference-v1/C/Phase2/production remain closed. Original scenario/member
criteria, independent specification and impact review, explicit migration IF
norms change, ACTUAL composition binding, independent safe ACTUAL WHOLE review,
THEN a separate fresh explicit bounded native grant BEFORE effects, and later
own-platform independent conformance remain due in their required order. No
historical source/boot/attempt/run/grant/live binding is reusable or renewed here.

A later Slackware-current refresh cannot invalidate completed STATIC repository
work or revive consumed authority. If the final separate review confirms this
pause, STOP until a NEW bounded request. No native operation is authorized.
