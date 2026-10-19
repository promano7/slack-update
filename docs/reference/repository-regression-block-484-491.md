# Integrated repository regression block 484-491

This is the prepared final source/docs/navigation review at step 491. Seven
actual steps 484-490 are accepted in the requested 8-12-step block. Final 491
would make eight only after its complete actual return is accepted. Last
confirmed strong STATIC repository pause remains 483; no new pause is confirmed.

Complete uploaded actual 490 reports HEAD/origin
`6843cd38c7cb73d32e4a7100ab12aac62de43431`, parent
`e57d454178b78321ca65f9c6b58eb48f34dc25e2`, tree
`8e9bb3b3251fc20420d6be36a20505b6bc2ecba7`, canonical report SHA256
`a58880c49483cce513e8cda27d1878b2cef5fbd480919b0e728928f16140963f`.
All 60 command vectors and outputs match in order, normalizing only one consistent
generated initrd temporary root. Application/two scope checks, syntax/executable/
whitespace checks, exact three-path 265-addition/four-deletion scope, required
subject, reported push, empty status and full source/Git-mode/tree report agree.
The exact supplied uploaded file is retained with SHA256
`eac637ee66c5b7e949f4cf5c223c8444303a6e57b16ec859e7641aa0697b6177`.
The file is supplied evidence, not independent terminal/GitHub/native capture.
Earlier inline transcriptions keep their original provenance; no actual user Git
objects are fabricated.

Step 491 changes ten existing documentation paths: this review, CHANGELOG,
README's existing selection link, contribution mappings, documentation/reference
indexes, development setup, reference usage, roadmap and testing guidance.
The README remains an overview without new step history. Reference implementation,
tests, fixtures, native requirements, file inventory and existing modes stay
unchanged from accepted 490. Full source, modes, exact predecessor, ten preimages,
receipts and pinned controls are retained outside Git. Prepared source and local
checks cannot attest later user actions.

## Bounded changes and retained controls

| Step | Change and current scope | Retained sensitivity evidence |
| --- | --- | --- |
| 484 | [Unresolved display](elf-scan-workflow.md): stop before ELF publication after failed rendering; 33 cases | Old-source rendering failure and selected guard controls |
| 485 | [Cache construction](elf-cache-construction.md): reject failed construction/order pipeline | Original 50-case matrix and pipeline controls |
| 486 | Same cache scope: reject failed publication or count; current matrix 100 cases | Seven syntax-valid source mutations reject |
| 487 | [Cache workflow](elf-cache-workflow.md): 60 cases compose real cache, dependency matcher, scan/recheck and diagnostic helpers | Two old healthy controls pass, four old move/count controls reject; six caller mutations reject |
| 488 | [Runtime logging](runtime-logging.md): 18 real open/descriptor failure cases; correct three comments | All 18 cases pass on old executable statements; six guard mutations reject |
| 489 | [Runtime lifecycle](runtime-lifecycle.md): reset six prior cleanup bindings before fallible setup; 40 real helper-composition cases | Original private deletion counterexample; 29 old-source cases pass and 11 populated early failures reject; six reset omissions reject |
| 490 | Integrate the historical 56 commands followed by four new drivers | Complete uploaded actual 60-command result, source/modes/tree and scoped docs commit accepted |
| 491 | Final cumulative source/guidance review and current navigation | Prepared documentation-only verification; actual final run and separate post-return whole-body review pending |

The current runtime/logging matrix has 28 setup, 46 logging and six rotation
entries. Existing ELF scan, metadata and all other drivers retain their own
counts, inputs and effect qualifications. The integrated selection does not
rerun historical mutation controls, aggregate heterogeneous entries into native
coverage or borrow an oracle from another driver.

The repaired lifecycle path prevents selected early setup failures from passing
previous bindings to real EXIT cleanup. It can leave older resources untracked;
it neither reclaims them nor proves their absence. Current allocations retain
their existing order. Cleanup, traps, lock and result mappings are unchanged.
Post-exit private lock availability alone cannot distinguish explicit release
from OS descriptor closure. The lifecycle driver also observes callback order,
before-exit fields and the complete private file/directory/link snapshot.

## Exact ordered selection

Keep the original 56 commands from the [475-483 review](repository-regression-block-475-483.md)
in their original order, then append the unresolved-display, cache-construction,
cache-workflow and runtime-lifecycle drivers, in that order. This is 60 distinct
normal commands, selected by name. Historical 54/56-command outcomes and
exclusions retain their original meaning. Do not glob historical or native
acceptance harnesses into this run.

Run from the repository root as an ordinary developer without sudo. Dependencies
include Python 3.9 or newer for delivery helpers, Bash, jq, flock, timeout, awk,
GNU coreutils/findutils/sed and the existing shared JSON decoder/helper support.
Python drivers use the standard library. Before running an unfamiliar entry
point, inspect its selected helpers, supplied command boundaries, fixture paths
and tool requirements; a directory name does not establish containment.

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
bash tests/reference/test-cron-minimal-environment.sh
bash tests/reference/test-initrd-installed-kernel.sh
python3 tests/reference/test-elf-unresolved-display.py
python3 tests/reference/test-elf-cache-construction.py
python3 tests/reference/test-elf-cache-workflow.py
python3 tests/reference/test-runtime-lifecycle.py
bash -n tools/reference/slack-update-reference.sh
test -x tools/reference/slack-update-reference.sh
git diff --check
```

All 60 normal commands pass in the recorded 490 preparation and complete
actual 490 return. Preparation ran as UID 0; it did not establish an actual
unprivileged OS run. The actual result was supplied from the user's Arch checkout,
not a native Slackware acceptance environment. Step 491 reuses that recorded
normal run because implementation, tests, fixtures and modes are unchanged;
it does not claim a second local 60-command execution. Final documentation links,
fragments, byte/mode scope, whitespace and delivery controls are checked separately.
Complete actual 491 must repeat the same 60 commands on the final tree. Syntax
and executable/whitespace checks remain separate from the 60 normal commands.

Real private effects include files/directories/links, redirections, moves,
selected boot-file replacements, descriptors/pipelines, locks, signals, parsing,
coreutils and inert builders. Supplied boundaries include selected metadata,
cache, transport, package, boot and fault results. Callback guards are not an OS
sandbox. Fixture snapshots omit ownership, xattrs, all descriptors and concurrent
host activity. Private cleanup proves neither global cleanup nor host absence.
This selection introduces no normal installed package, service, boot generator
or native acceptance operation.

## Failures, recovery and remaining limits

Step 487 first reported an SSH disconnect during push; the cause is unknown.
Four subsequent Git commands from Downloads failed because it was not a Git
checkout. The reporter had an explicit checkout path and rejected the then
inconsistent HEAD/origin/predecessor state. A later push from the checkout and
complete final report succeeded. Both failures and successful recovery remain;
intermediate remote state was not observed. Delivery Git commands and recovery
tails use `git -C` with the explicit checkout. Recovery never recommits the step.

All older failures, source controls, extraction/mode/link/inventory observations
and unknown packaging causes stay in exact predecessor history. A later PASS
neither erases a failure nor explains its cause. Current finite inventory/CRC/
manifest/mode checks do not prove end-to-end restoration or identify unknown
ambient copy causes. Original pending metadata is retained as historical;
CURRENT491 is active and waits for the final actual return.

The first 491 preparer inventory check rejected one additional 25 MiB temporary
copy, equal to a prefix of an existing fixture. Its bytes and hash are preserved
outside the canonical source, and its cause remains unknown. The original saved
490 archive and canonical file inventory are unchanged. A separate checker input
lookup used a selectively extracted directory without the needed preimages;
reading the exact saved 486 ZIP supplies them. Those initial rejected checks
are retained, not retroactively counted as PASS. Canonical bytes/modes and the
accepted source chain are checked again after those corrections.

ELF publication is not atomic: failed copy or move implementations can affect
their destination. A successful clear can precede later staging failure; cache
and staging work may persist. Count failure leaves count zero but can follow
successful cache publication. Individual reader protocols, nonempty predicates,
path trust and unselected failures retain their dedicated limits. Runtime setup,
logging append/rotation, lexical path/version checks and separate GRUB entry
matches retain their own limits. No helper status or printed success replaces
native output/no-effect/boot criteria.

## Conditional closing review

Complete actual 490 has been accepted. Prepared 491 is the final source/docs/
navigation review for the proposed eight-step block 484-491. It does not confirm
its own execution or pause. Complete final actual 491 remains due, followed by
the separate review below. The original whole conditions and every nested body
must be read again after that final return, even if earlier reviews passed.

Complete actual FINAL return must come FIRST: application/scope checks, selected
normal outputs, exact commit/subject, reported successful push, empty status,
full matching local refs and pinned complete source/Git-mode/tree report. THEN
perform a separate post-return reading/review of EVERY WHOLE inherited condition
and EVERY exact nested original body, plus all new effects, obligations, cleanup
needs and observation limits. Whole originals remain under inherited483 and in
exact nested history. Counts, hashes, summaries and prior reviews are not
substitutes. Reserve context or carry complete verified state into a fresh chat;
do not declare the pause before completing that reading.

The final reporter brackets bounded tracked source/index/mode/tree reads with
Git identity/clean checks. It has no atomic snapshot lock, ignored-file survey,
independent GitHub view or host/native observation. Synthetic controller checks
use private Git history and local refs, not actual user commit objects or pushes.
Same-assistant STATIC review is not independent native or semantic acceptance.

Phase 1 and kernel work remain incomplete. Five families/20 native scenarios,
13 findings and 16 gaps remain unresolved. A/R/D is unselected; four native
repairs inactive; schema1/reference-v1/C/Phase2/production closed. Native evidence
and live bindings remain null, host unobserved-not-claimed-absent, actual global
host closure false. Original install-new20 empty-output AND no-effect criteria,
upgrade20 failure criteria and all older member/audit requirements are unchanged.

Native progress still needs a separate exact decision, independent specification/
impact acceptance, explicit migration IF norms change, ACTUAL composition binding,
independent safe ACTUAL WHOLE containment/source/trust/guard/fresh-original-baseline/
known-recovery/storage/fixed-clock/finite-right/effective-independent-observation
review, THEN a separate FRESH explicit BOUNDED case/platform/run native grant
BEFORE effects, followed by independent own-platform conformance. Old native
rights are closed. No source, boot, attempt, run, grant or live binding reuse,
renewal, retry, refund, replay, rebind, reacquisition, relaunch, replacement or
post-release action follows from this block.

A later Slackware-current refresh cannot invalidate completed STATIC source work
or revive consumed authority. Only after complete final actual acceptance and
the separate whole-body review may a scoped STATIC pause be confirmed. Then STOP
until a new bounded request; no native operation is authorized here.
