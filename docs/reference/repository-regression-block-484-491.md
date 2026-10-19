# Integrated repository regression block 484-491

This is the integration preparation at step 490, before the proposed closing
step 491. Six actual steps, 484-489, are accepted in the requested 8-12-step block.
The complete supplied 489 return reports HEAD/origin
`e57d454178b78321ca65f9c6b58eb48f34dc25e2`, parent
`fd257e3d30de51d2c9eab91dc03fa1c885d5f15f`, tree
`76284a42ee2fead9530d80cb3e5c427572a66eed`, and canonical report SHA256
`45f9a82094f981d449342199f374a674519b013a5b73087d066c657be9fd95e4`.
Its thirteen ordered outputs, six-path 355-addition/two-deletion scope, required
subject, reported successful push, empty status, matching full local refs and
2,379-file source/Git-mode/tree report agree with the prepared delivery.
Receipts transcribe supplied inline terminal output; they are not original
terminal-file bytes or independent terminal, GitHub or native observation.
Actual user Git objects are not recreated from those reports.

Step 490 changes this new scope document, the testing guide and CHANGELOG only.
Reference implementation, tests, fixtures, requirements, README, existing modes
and the old log tail stay unchanged. Full source and modes, exact predecessor
archive, preimages, receipts and pinned delivery controls remain outside Git in
the delivery. Prepared source and local PASS cannot attest later user actions.

## Bounded changes and retained controls

| Step | Change and current scope | Retained sensitivity evidence |
| --- | --- | --- |
| 484 | [Unresolved display](elf-scan-workflow.md): stop before ELF publication after failed rendering; 33 cases | Old-source rendering failure and selected guard controls |
| 485 | [Cache construction](elf-cache-construction.md): reject failed construction/order pipeline | Original 50-case matrix and pipeline controls |
| 486 | Same cache scope: reject failed publication or count; current matrix 100 cases | Seven syntax-valid source mutations reject |
| 487 | [Cache workflow](elf-cache-workflow.md): 60 cases compose real cache, dependency matcher, scan/recheck and diagnostic helpers | Two old healthy controls pass, four old move/count controls reject; six caller mutations reject |
| 488 | [Runtime logging](runtime-logging.md): 18 real open/descriptor failure cases; correct three comments | All 18 cases pass on old executable statements; six guard mutations reject |
| 489 | [Runtime lifecycle](runtime-lifecycle.md): reset six prior cleanup bindings before fallible setup; 40 real helper-composition cases | Original private deletion counterexample; 29 old-source cases pass and 11 populated early failures reject; six reset omissions reject |

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

All 60 normal commands pass in preparation. The delivery records ordered
command vectors, individual raw stdout/stderr and exit status. Preparation runs as UID 0; it does not establish an actual
unprivileged OS run. Complete actual step 490 must run the same 60 commands on
this prepared tree. Syntax and executable/whitespace checks are separate from
the 60 normal commands. Documentation changes no executable or test bytes.

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
CURRENT490 is active and waits for the actual return.

ELF publication is not atomic: failed copy or move implementations can affect
their destination. A successful clear can precede later staging failure; cache
and staging work may persist. Count failure leaves count zero but can follow
successful cache publication. Individual reader protocols, nonempty predicates,
path trust and unselected failures retain their dedicated limits. Runtime setup,
logging append/rotation, lexical path/version checks and separate GRUB entry
matches retain their own limits. No helper status or printed success replaces
native output/no-effect/boot criteria.

## Conditional closing review

Last confirmed strong STATIC repository pause is 483. Step 490 is integration
preparation, not a new pause. After its complete actual return is accepted,
prepare the final source/docs/navigation review at 491 if the evidence supports
that scope. Eight actual steps 484-491 would meet the requested lower bound.
Keep README concise and detailed history in CHANGELOG/reference documents.

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
