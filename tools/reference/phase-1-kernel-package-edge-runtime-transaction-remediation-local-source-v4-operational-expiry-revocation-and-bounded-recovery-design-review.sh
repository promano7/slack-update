#!/bin/bash
set -euo pipefail
export LC_ALL=C
script_dir=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd -P)
if [[ $# -eq 1 && $1 == --help ]]; then
    printf 'Usage: %s --output-dir DIR\nRepository-only expiry revocation and bounded recovery design review; no runtime authority.\n' "${0##*/}"
    exit 0
fi
[[ $# -eq 2 && $1 == --output-dir && -n $2 ]] || { printf 'ERROR: expected --output-dir DIR\n' >&2; exit 2; }
python3 - "$repo_root" "$2" <<'PYREVIEW'
import ast
import hashlib
import json
import subprocess
import sys
import tempfile
from pathlib import Path

BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-expiry-revocation-and-bounded-recovery-design-review'
PRIOR = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-stage7-owned-binding-effect-design-review'
FIXTURE = 'tests/fixtures/reference/acceptance/phase-1'
OWN_HASHES = {'docs/reference/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-expiry-revocation-and-bounded-recovery-design-review.md': '5dd691f00f5bb72cb74661c9fbb2bf1d17149920e5eb8bafa6612259bfd22cca', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-expiry-revocation-and-bounded-recovery-design-review-policy.json': 'fa45d77bcb3066e669fc2eddeb1299f84b19fca3f07cefa5c6b53cfe281fcb87', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-expiry-revocation-and-bounded-recovery-design-review-design.json': '40a574a020fcd8a5a6e79d0faebea6e00e62283751a94bcd877a9b47182d8b98', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-expiry-revocation-and-bounded-recovery-design-review-checkpoint-confirmation.json': 'c6695bf11db39cb76af4e14ff4aff40882ca33c8671bd0e4be02cb1da7dfd5ab', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-expiry-revocation-and-bounded-recovery-design-review-step322-user-acceptance.json': '20000855e063b17e3eee1c74d5e8dcd72117ad03e25ee07f6d3d2b30f5fe6085', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-expiry-revocation-and-bounded-recovery-design-review-revocation-scope-matrix.tsv': '5ae7b80aace04b5e226a8b5d9759e5ffb29c6bfe988d556b88937df7d086ab04', 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-expiry-revocation-and-bounded-recovery-design-review-bounded-recovery-action-matrix.tsv': '8f51262146086a8f1ca41531f51cc1bc27b908a736b7932df3f4bc2590c64bd7'}
CHANGELOG_PREFIX = '## Phase 1 step323 — expiry revocation and bounded same-attempt recovery design review — 2026-10-04\n\n- Confirmed322 dfee48f prefix: complete ordered456 PASS identical to prepared suite, first push success, clean tree and matching HEAD/origin. Full ID unknown. Preserve original40900-byte receipt and external confirmation without rewriting prepared322 flags.318 remains last confirmed strong pause.\n- Preserve1485 accepted files except additive CHANGELOG prefix; nine new artifacts. Rerun exact456 predecessor acceptance, keeping2251/843/547/717 and full historical coverage. Bind exact320 admission,321 offline handoff and322 owned stage7 successor designs without changing frozen history or running v2.\n- Select immutable authenticated issuer split forward/recovery scopes with independent finite deadlines, durable action budget and external live revocation fence for the same original consumed-active attempt. Forward failure/completion/expiry/revocation irreversibly stops forward effects. Forward-only expiry/revocation allows only explicitly retained bounded recovery while its own rights remain valid; no blanket exemption, new grant, renewal, retry or per-nested-call unused grant.\n- Offline receipt/lease alone cannot prove no revocation. Require actual external trusted gate and time/boot mapping serialized through effects without adding worker service RPC/broker FD or rewriting321 bootstrap. Actual clock/deadlines/budget/enforcer/transport null; successor integration remains blocked for324/325 and independent15.0/current proof. Unknown fence/time/revocation/boot/identity stops effects and keeps pending obligations.\n- Started helper/package/config effects remain obligations. Recovery requires bounded owned-child quiescence, traps/continuous guard/canonical owner/all writers/exact original backups/original baseline approved deltas. Durable budget spent before each action; unknown action outcome never replayed. Restore only safe same identity, verify original invariants and complete target evidence before release; keep original failure status separate. Publication rights independent, captured closed data only through last receipt.\n- Private finite typed rights/clock/revocation/budget/phase models only; no real issuer, clock, deadline, fence, grant, child, backup, restore or target action. Six proofs plus seven capabilities and ten cross obligations required-not-proven; actual host/live slots null/unobserved. No new machine/controller cleanup from repository stage.\n-323 apply/tests/exact commit/user push/return pending, no strong pause.324 guarded original baseline/deltas follows full323 return;325 graph/fence integration,326 model/conformanceplan,327 closure,328 conditional repository design freeze/pause. Production/Phase2 closed and Phase1/kernel incomplete; optional329–330 ungranted.\n\n'
BASELINE_JSON_SHA256 = '65e0936fc1f132b6c9cc64d0b0c782f0cbd9d112c7ef3db4aa6c0fa81041069c'
CONFIRMATION_SHA256 = 'c6695bf11db39cb76af4e14ff4aff40882ca33c8671bd0e4be02cb1da7dfd5ab'
RECEIPT_SHA256 = '6205d4ac335f54aa9b28913fa00e2c90bd4432aa2b9d16321c48a565c5cdefc5'
TABLE_HASHES = ['5ae7b80aace04b5e226a8b5d9759e5ffb29c6bfe988d556b88937df7d086ab04', '8f51262146086a8f1ca41531f51cc1bc27b908a736b7932df3f4bc2590c64bd7']

REQUIREMENTS_BASE = 'phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-requirements-freeze-and-strong-safe-pause'
DESIGN_SPEC = {'schema': 1, 'step': 323, 'scope': 'expiry-revocation-and-bounded-same-attempt-recovery-design-only', 'design_version': 'split-rights-external-fence-v1-review-not-operational-freeze', 'review_status': 'PASS-policy-contract-only-actual-enforcement-and-conformance-blocked', 'selected_policy': 'immutable-issuer-split-forward-and-recovery-rights-same-consumed-attempt-with-external-live-fence', 'previous_design_bindings': {'320': {'path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-and-durable-consumption-design-review-design.json', 'sha256': '206070db792430966f1b1654d29d7fecabaf43288f1d208b1332d5a40432726f'}, '321': {'path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-admission-handoff-and-namespace-fd-design-review-design.json', 'sha256': 'c814396b3d002f3398b1d024ab30d9b74dfa6d84aee0c87df93215f571bd1540'}, '322': {'path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-stage7-owned-binding-effect-design-review-design.json', 'sha256': 'ff7428e2039927559130a6b0f58611a669f30215221aaf3887e3fa360438a494'}}, 'forward_contract': {'owner': 'original-consumed-active-attempt-no-new-or-unused-grant-per-nested-call', 'validity': 'independent-authenticated-scope-trusted-time-and-continuously-enforced-live-fence-before-and-through-every-permitted-effect', 'termination': 'expiry-forward-revocation-or-any-failure-latches-forward-stop-irreversibly; no-new-effect-dispatch-or-revival', 'in_flight': 'started-effects-and-children-remain-obligations; inability-to-prove-stop-at-safe-effect-boundary-keeps-unknown-pending', 'terminal': 'normal-forward-completion-also-closes-forward-before-restoration-evidence-and-target-control-release'}, 'recovery_contract': {'owner': 'narrow-retained-rights-of-same-original-consumed-attempt-not-another-grant-or-invocation', 'validity': 'explicit-authenticated-issuer-original-recovery-scope-with-own-finite-deadline-budget-and-live-recovery-fence', 'expiry_relation': 'forward-expiry-or-forward-only-revocation-does-not-itself-revoke-explicitly-retained-recovery; never-blanket-expiry-exemption', 'revocation': 'recovery/all-revocation-unknown-scope-clock-discontinuity-boot-or-identity-drift-block-recovery-writes-and-preserve-obligations', 'whitelist': ['bounded-owned-child-control-and-drain', 'exact-original-backup-restoration', 'verify-original-invariants', 'capture-owned-target-evidence', 'verified-target-control-release'], 'preconditions': 'traps-guards-owned-canonical-paths-all-writers-excluded-exact-backups-same-safe-identity-original-baseline-and-approved-deltas', 'boundedness': 'finite-issuer-bound-deadline-and-durable-action-budget; spend-before-action; no-renewal-refill-retry-after-unknown-or-new-grant', 'idempotence': 'known-already-restored-state-may-return-reviewed-no-op-with-fresh-verification; never-repeat-unknown-package-or-file-action', 'order': 'stop-forward-then-known-child-quiescence-then-safe-restore-verify-target-evidence-before-release', 'status': 'keep-original-forward-failure-status-separate-from-recovery-and-publication-status; restoration-cannot-turn-failure-into-success'}, 'clock_contract': {'actual_clock': None, 'actual_forward_deadline': None, 'actual_recovery_deadline': None, 'actual_recovery_budget': None, 'rule': 'issuer-authenticated-finite-bounds-and-independent-trusted-time-mapping-with-same-boot; no-wallclock-rollback-suspend-epoch-restart-or-unknown-as-valid', 'fixture': 'integer-ticks-forward100-recovery140-budget5-only-synthetic-no-real-seconds-or-host-observation'}, 'fence_contract': {'actual_enforcer': None, 'actual_transport': None, 'rule': 'trusted-external-controller-enforces-original-policy-and-absorbing-revocation-at-every-effect-boundary; worker-and-contained-commands-have-no-service-or-broker-capability', 'compatibility': '321-offline-bootstrap-schema-and-FD-closure-unchanged; no-added-worker-RPC-or-inherited-control-channel; future-successor-fence-policy-and-transport-integration-explicitly-required324/325', 'uncertainty': 'gate-outcome-loss-or-stale-or-unavailable-status-stops-effects; consumed-grant-launch-slot-and-recovery-budget-never-reopen', 'scope': 'live-check-is-original-attempt-validity-not-new-grant-per-action; no-claim-of-instant-revocation-from-offline-receipt-or-finite-lease-alone'}, 'closure_contract': {'machine': 'only-known-original-restoration-and-known-owned-child-quiescence-with-complete-target-evidence-under-guard-can-close-scoped-target-obligations', 'controller': 'unknown-durable-claim-launch-binding-budget-child-or-evidence-state-remains-pending-no-auto-delete-release-or-closed-rights-claim', 'publication': 'after-target-closure-use-captured-closed-data-under-independent-publication-controls-through-last-receipt; no-target-refresh-write-or-renewal'}, 'prerequisite_gates': ['same_consumed_active_attempt', 'authenticated_original_scope', 'issuer_split_policy_authenticated', 'trusted_clock_and_boot_mapping', 'external_nonreusable_fence_proven', 'traps_and_continuous_guard', 'owned_paths_and_all_writers_proven', 'fresh_original_baseline_and_approved_deltas', 'exact_verified_original_backups', 'reviewed_same_identity', 'contained_children_and_helpers'], 'model_actions': ['forward', 'fail-forward', 'finish-forward', 'drain', 'restore-original', 'verify-original', 'capture-evidence', 'release-control', 'publication', 'retry', 'rebind', 'lose-action-outcome'], 'model_revocation_scopes': ['none', 'forward', 'recovery', 'all', 'unknown'], 'requirements': {'original_attempt_only': True, 'split_scope_explicit_not_blanket_exemption': True, 'finite_trusted_deadlines': True, 'external_live_fence_no_worker_capability': True, 'revocation_absorbing': True, 'unknown_stops_effects': True, 'failure_latch_survives_recovery': True, 'ordinary_failure_allows_only_safe_bounded_recovery': True, 'no_wrong_boot_or_identity_restore': True, 'no_new_invocation_renewal_retry_or_rebind': True, 'durable_budget_before_action': True, 'no_ack_loss_action_replay': True, 'owned_children_quiescent_before_restore': True, 'exact_original_baseline_and_backups': True, 'earlier_package_config_effects_preserved': True, 'complete_target_evidence_before_release': True, 'separate_publication_controls': True, 'frozen_history_unchanged': True}, 'proof_state': {'selected_split_policy': True, 'actual_issuer_policy_issued': False, 'actual_clock_or_deadlines_bound': False, 'actual_external_fence_proven': False, 'actual_revocation_enforced': False, 'actual_recovery_authorized': False, 'actual_recovery_budget_durable': False, 'actual_children_drained': False, 'actual_original_restoration_verified': False, 'actual_host_obligations_closed': False, 'actual_live_bindings': None, 'actual_host_obligations_observed': None, 'actual_host_obligations_claimed_absent': False, 'actual_grant_consumed': False, 'historical_v2_sourced_or_run': False, 'operational_implementation_complete': False, 'operational_conformance': False, 'operational_readiness': False}, 'future_proof_obligations': [{'id': 'issuer-split-scope-and-clock', 'evidence': 'Authenticated original immutable forward/recovery policy, exact finite scopes/deadlines/budget and trusted time/boot/suspend/rollback/clock-discontinuity semantics on both platforms; no local clock or receipt self-authority.', 'status': 'required-not-proven'}, {'id': 'external-live-revocation-fence', 'evidence': 'Actual external trusted authority gate serializes revocation, expiry, action dispatch and effect boundaries; no stale snapshot, lease-only proof, per-call grant, service RPC/FD capability in worker children or authority after uncertain gate outcome.', 'status': 'required-not-proven'}, {'id': 'inflight-effect-and-child-drain', 'evidence': 'Actual bounded control rights, child inventory/stop/drain/quiescence and original status retention; expiry/revocation cannot erase started package/config effects or justify release on unknown child status.', 'status': 'required-not-proven'}, {'id': 'same-attempt-bounded-safe-restoration', 'evidence': 'Actual signed retained same-attempt recovery rights, independent recovery validity/revocation, exact backups/original baseline, guards/canonical whitelist/approved deltas and no wrong-boot restore, retry, renewal or target substitution.', 'status': 'required-not-proven'}, {'id': 'durable-recovery-budget-and-idempotence', 'evidence': 'Actual durable once-only action budget/terminal latch across crashes, bounded idempotent restoration and explicit no-op versus new write proof; unknown acknowledgement never repeats a potentially applied action.', 'status': 'required-not-proven'}, {'id': 'closure-evidence-and-separate-publication', 'evidence': 'Actual verified restoration plus known child quiescence/target evidence under guard before release; preserve unknown obligations/artifacts, captured-data-only publication under separate reviewed rights through last receipt.', 'status': 'required-not-proven'}], 'seven_requirements_bindings': [{'capability': 'real-reference-integration-and-selector-equivalence', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-policy.json', 'policy_sha256': '9fcb69804f2d3abff675044f477b903416314bb7a195a938e45b1ee1f1260fa1', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-reference-integration-and-selector-requirements-review-review.json', 'review_sha256': '69d846f1a5473cc8e2859ee7f3a242047c32d49e364601f9429054a742cdabf8', 'step': 310}, {'capability': 'namespace-command-transport-and-no-fallback', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-namespace-transport-and-no-fallback-requirements-review-policy.json', 'policy_sha256': '3f321ef0ca8317cb6261d707dc158ae306ef92435430e824d77e42b9e066b8a8', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-namespace-transport-and-no-fallback-requirements-review-review.json', 'review_sha256': 'ed2b6651ab1f54eaea7cd33c765f9d677a0cb257d47840237babd966281b9af9', 'step': 311}, {'capability': 'absolute-backend-path-and-SHA', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-absolute-backend-identity-requirements-review-policy.json', 'policy_sha256': '8e64828bd8abfb55f36e326177c8ddb24bb0e81a3f20bf592b949f9e1a0fc80a', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-absolute-backend-identity-requirements-review-review.json', 'review_sha256': 'b23906d94ad0111daf310cf563ad056020ec4066e14b341bec7bf6e0ae28dd26', 'step': 312}, {'capability': 'reviewed-platform-writer-serialization', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-platform-writer-serialization-requirements-review-policy.json', 'policy_sha256': '4f387f3b9fb6c90f8b018b45fa0e3529786c5908d6a3027a2113a7a9f25d47e8', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-platform-writer-serialization-requirements-review-review.json', 'review_sha256': 'ba896b35f91d1adc6692a6813652752b158eb258af3267c85e80ec024fe856f4', 'step': 313}, {'capability': 'fresh-single-use-grant-source-target-predecessor-and-boot', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-fresh-single-use-grant-requirements-review-policy.json', 'policy_sha256': '3e9bdf7b20fef359781964c489aeee00749fc9039b8397c72eeb2c95c8e9a64f', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-fresh-single-use-grant-requirements-review-review.json', 'review_sha256': '73c7905dede694806bf8062ff0063775f8f927e7dada91a0bf339e87061affb6', 'step': 314}, {'capability': 'real-source-and-archive-revalidation', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-real-source-and-archive-revalidation-requirements-review-policy.json', 'policy_sha256': 'b8fbffd1dff20736ad71850677aa613aa557c792b42c8616f9d8fe3073c0efe2', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-real-source-and-archive-revalidation-requirements-review-review.json', 'review_sha256': '36a7f9559aaa87550ed7f4b2544960df4ec71775cb3444fd6070279e4613f5f0', 'step': 315}, {'capability': 'operational-owner-and-publication-path-bindings', 'operational_conformance': False, 'policy_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-owner-and-publication-path-requirements-review-policy.json', 'policy_sha256': 'b816d61589c59fefa1c35df234269c05f1698eddab6c615a99ae030356729377', 'requirements_status': 'reviewed-not-operationally-complete', 'review_path': 'tests/fixtures/reference/acceptance/phase-1/phase-1-kernel-package-edge-runtime-transaction-remediation-local-source-v4-operational-owner-and-publication-path-requirements-review-review.json', 'review_sha256': '30c9472c9b68fd6073783c678600c9c5f41730a43a6525b132c2a0d725213ecf', 'step': 316}], 'preserved_cross_obligations': [{'id': 'claim-traps-containment', 'negative_case': 'promote-review-or-private-fixture-to-resolved-claim-traps-containment', 'required_evidence': 'No local ledger before traps; no unreviewed admission socket/service inherited by isolated backend; no protocol chosen', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'guarded-baseline', 'negative_case': 'promote-review-or-private-fixture-to-resolved-guarded-baseline', 'required_evidence': 'Keep frozen stages unchanged; interstage integration and real baseline proof still required', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'binding-effect-classification', 'negative_case': 'promote-review-or-private-fixture-to-resolved-binding-effect-classification', 'required_evidence': 'Explicit owned binding effect classification and traps/guard/grant integration review before operational freeze; do not rewrite frozen bytes', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'whole-effect-graph', 'negative_case': 'promote-review-or-private-fixture-to-resolved-whole-effect-graph', 'required_evidence': 'Persistent forward failure latch and complete actual helpers/selectors/namespace FD/identity/writer graph; no fallback', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'retained-bytes-and-writers', 'negative_case': 'promote-review-or-private-fixture-to-resolved-retained-bytes-and-writers', 'required_evidence': 'Actual ancestry aliases and content/dependency writer exclusion continuously through checked-byte consumption; no self-rehash/rebind', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'same-attempt-phase-deltas', 'negative_case': 'promote-review-or-private-fixture-to-resolved-same-attempt-phase-deltas', 'required_evidence': 'Never demand unused grant per nested call or rebind baseline to foreign drift; independently verified archive roles and same-boot scope', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'pkglist-selector-status', 'negative_case': 'promote-review-or-private-fixture-to-resolved-pkglist-selector-status', 'required_evidence': 'SHA bound once; zero install-new one upgrade required; raw helper0/20 differs from frozen emulator and real mandatory upgrade20 fails', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'target-publication-controls', 'negative_case': 'promote-review-or-private-fixture-to-resolved-target-publication-controls', 'required_evidence': 'Drain children verify restore close target evidence then release; captured closed data only; separate publication controls through receipt/handoff', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'last-receipt-durability', 'negative_case': 'promote-review-or-private-fixture-to-resolved-last-receipt-durability', 'required_evidence': 'Actual supported no-replace file/meta/directory/storage semantics and trusted origin; no pair atomicity self-containing receipt or SHA authority', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}, {'id': 'failure-recovery-rights', 'negative_case': 'promote-review-or-private-fixture-to-resolved-failure-recovery-rights', 'required_evidence': 'No blanket exemption renewal replay retry or wrong-boot restore; preserve unknown/pending obligations and backups for separately authorized recovery', 'scope': 'future-operational-conformance-not-executed', 'status': 'required-not-proven'}], 'remaining_operational_blockers': ['314-durable-claim-traps-gap-retained', 'admission-service-no-broker-FD-isolation-integration-unresolved', 'stage7-readonly-versus-owned-binding-effect-classification-unresolved', 'all-seven-capabilities-still-require-operational-implementation-and-conformance', 'actual-recovery-expiry-revocation-policy-unselected', 'actual-current-machine-and-controller-obligations-unobserved'], 'remaining_design_reviews': [324, 325, 326, 327, 328], 'compatibility_scope': ['Slackware-15.0', 'Slackware-current'], 'private_model_scope': 'finite-typed-in-memory-rights-clock-revocation-budget-and-phase-model-not-real-service-time-durable-actions-or-restoration', 'unresolved_design_edges': ['324-continuous-guard-and-original-phase-baseline', '325-external-fence-policy-transport-and-whole-effect-graph', 'actual-issuer-clock-fence-budget-child-backup-restore-evidence-and-publication-proofs-unimplemented']}
SUFFIXES = ['-policy.json', '-design.json', '-checkpoint-confirmation.json', '-step322-user-acceptance.json', '-revocation-scope-matrix.tsv', '-bounded-recovery-action-matrix.tsv']

PRIOR_DESIGN_SHA256 = 'ff7428e2039927559130a6b0f58611a669f30215221aaf3887e3fa360438a494'
GATE_KEYS = ['same_consumed_active_attempt', 'authenticated_original_scope', 'issuer_split_policy_authenticated', 'trusted_clock_and_boot_mapping', 'external_nonreusable_fence_proven', 'traps_and_continuous_guard', 'owned_paths_and_all_writers_proven', 'fresh_original_baseline_and_approved_deltas', 'exact_verified_original_backups', 'reviewed_same_identity', 'contained_children_and_helpers']


MODEL_ACTIONS = ['forward', 'fail-forward', 'finish-forward', 'drain', 'restore-original', 'verify-original', 'capture-evidence', 'release-control', 'publication', 'retry', 'rebind', 'lose-action-outcome']
REVOCATIONS = ['none', 'forward', 'recovery', 'all', 'unknown']
RECOVERY_ACTIONS = ['drain', 'restore-original', 'verify-original', 'capture-evidence', 'release-control']

def exact(actual, expected, label):
    if json.dumps(actual, sort_keys=True, default=lambda b: ["bytes", b.hex()]) != json.dumps(expected, sort_keys=True, default=lambda b: ["bytes", b.hex()]):
        raise ValueError(label)

def sha(content):
    return hashlib.sha256(content).hexdigest()

def safe_relative(rel):
    if type(rel) is not str or not rel or '\\' in rel or rel.startswith('/') or any(x in ('', '.', '..') for x in rel.split('/')):
        raise ValueError('unsafe relative path')
    return Path(rel)

def safe_file(root, rel):
    p = root / safe_relative(rel)
    if not p.is_file() or p.is_symlink() or p.absolute() != p.resolve() or not p.resolve().is_relative_to(root.resolve()):
        raise ValueError('unsafe file ' + rel)
    return p.read_bytes()

def validate_confirmation(c,receipt):
    exact(sha((json.dumps(c,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode()),CONFIRMATION_SHA256,'external322 confirmation')
    exact(sorted(receipt),['encoding','original_display_sha256','original_display_size_bytes','text'],'receipt fields');exact(receipt['encoding'],'utf8-json-text','receipt encoding')
    raw=receipt['text'].encode();exact(sha(raw),RECEIPT_SHA256,'original322 digest');exact(len(raw),40900,'original322 length')
    exact(receipt['original_display_sha256'],RECEIPT_SHA256,'receipt digest metadata');exact(receipt['original_display_size_bytes'],40900,'receipt size metadata')
    lines=receipt['text'].splitlines();exact(sum(x.startswith('PASS: ') for x in lines),456,'complete456 return');exact(lines.count('Result: PASS (456 passes, 0 failures)'),1,'full456 summary')
    log='dfee48f (HEAD -> main, origin/main, origin/HEAD) Phase 1 step 322: classify successor stage 7 binding as an owned file effect'
    exact(lines.count(log),2,'matching322 HEAD origin')
    if '[main dfee48f]' not in receipt['text'] or 'dd37e79..dfee48f  main -> main' not in receipt['text']:raise ValueError('missing322 commit/push')
    return True

def verify_history(root, policy):
    binding = policy['baseline_sha256_bindings']
    serialized = (json.dumps(binding, ensure_ascii=False, sort_keys=True, indent=2)+'\n').encode()
    exact(sha(serialized),BASELINE_JSON_SHA256,'exact accepted1485 manifest')
    exact(len(binding),1485,'accepted1485 file count')
    history = {}
    for rel,digest in binding.items():
        content = safe_file(root,rel)
        if rel == 'CHANGELOG.md':
            prefix = CHANGELOG_PREFIX.encode()
            exact(len(content),policy['accepted_changelog_size_bytes']+len(prefix),'additive CHANGELOG length')
            exact(content[:len(prefix)],prefix,'new CHANGELOG prefix')
            content = content[len(prefix):]
        exact(sha(content),digest,'accepted artifact drift '+rel)
        history[rel] = content
    return history

def validate_design(design,prior,frozen,history):
    exact(design,DESIGN_SPEC,'exact split-rights recovery policy')
    exact(sha((json.dumps(prior,ensure_ascii=False,sort_keys=True,indent=2)+'\n').encode()),PRIOR_DESIGN_SHA256,'exact322 owned stage7 contract')
    for step,binding in design['previous_design_bindings'].items():exact(sha(history[binding['path']]),binding['sha256'],'exact prior design '+step)
    exact(design['seven_requirements_bindings'],frozen['seven_review_bindings'],'seven frozen requirements')
    exact(design['preserved_cross_obligations'],frozen['proof_obligations'],'ten frozen cross obligations')
    return True

def validate_tables(roadmap, obligations):
    exact(sha(roadmap),TABLE_HASHES[0],'exact typed roadmap')
    exact(sha(obligations),TABLE_HASHES[1],'exact obligation coverage table')
    return True

def canonical(value):
    return json.dumps(value,sort_keys=True,separators=(',',':'),ensure_ascii=True).encode('ascii')

def unique_pairs(pairs):
    result={}
    for key,value in pairs:
        if key in result:raise ValueError('duplicate JSON field')
        result[key]=value
    return result


def simulate_private_rights(value):
    exact(sorted(value),['conditions','events','origin','phase','recovery_budget','scope'],'rights model fields')
    exact(value['origin'],'synthetic-private-fixture','rights origin');exact(value['scope'],'split-rights-policy-only','rights scope')
    exact(sorted(value['conditions']),sorted(GATE_KEYS),'rights conditions')
    if any(type(x) is not bool for x in value['conditions'].values()):raise ValueError('typed rights prerequisite')
    if type(value['recovery_budget']) is not int or not 0<=value['recovery_budget']<=8:raise ValueError('finite synthetic budget')
    if type(value['phase']) is not str or value['phase'] not in ['baseline','predecessor','target','unknown']:raise ValueError('typed phase')
    if type(value['events']) is not list or len(value['events'])>24:raise ValueError('bounded rights schedule')
    gates=all(value['conditions'].values());phase=value['phase'];budget=value['recovery_budget'];forward_closed=not gates;recovery_closed=not gates
    drained=False;verified=False;evidence=False;released=False;uncertain=phase=='unknown';last=-1;forward_count=0;restore_writes=0;denied=0;status=None;trace=[]
    for event in value['events']:
        exact(sorted(event),['action','identity_safe','revocation','tick'],'event fields')
        action=event['action'];tick=event['tick'];revocation=event['revocation']
        if type(action) is not str or action not in MODEL_ACTIONS or type(tick) is not int or tick<0 or type(event['identity_safe']) is not bool or type(revocation) is not str or revocation not in REVOCATIONS:raise ValueError('typed rights event')
        if tick<last or not event['identity_safe'] or revocation=='unknown':
            forward_closed=True;recovery_closed=True;uncertain=True
            if status is None:status='authority-or-identity-unknown'
        last=tick
        if revocation in ['forward','all'] or tick>=100:forward_closed=True
        if revocation in ['recovery','all'] or tick>=140:recovery_closed=True
        allowed=False;write=False
        if action=='lose-action-outcome':
            forward_closed=True;recovery_closed=True;uncertain=True;allowed=True
            if status is None:status='recovery-outcome-unknown'
        elif action=='fail-forward':
            forward_closed=True
            if status is None:status='original-forward-failure'
            allowed=True
        elif action=='finish-forward':
            forward_closed=True
            if status is None:status='forward-complete'
            allowed=True
        elif action=='forward':
            allowed=not forward_closed and not released and forward_count==0 and phase in ['baseline','predecessor']
            if allowed:forward_count+=1;phase='target';write=True
        elif action in RECOVERY_ACTIONS:
            safe=forward_closed and not recovery_closed and not released and budget>0 and not uncertain
            allowed=safe and (action=='drain' or action=='restore-original' and drained or action=='verify-original' and drained and phase=='baseline' or action=='capture-evidence' and drained and verified or action=='release-control' and drained and verified and evidence)
            if allowed:
                budget-=1
                if action=='drain':drained=True
                elif action=='restore-original':
                    write=phase!='baseline';restore_writes+=int(write);phase='baseline';verified=False;evidence=False
                elif action=='verify-original':verified=True
                elif action=='capture-evidence':evidence=True
                elif action=='release-control':released=True
        if not allowed:
            denied+=1;forward_closed=True
            if status is None:status='original-forward-denial'
        trace.append(dict(action=action,tick=tick,allowed=allowed,modeled_write=write,forward_closed=forward_closed,recovery_closed=recovery_closed,budget_remaining=budget,phase=phase,drained=drained,verified=verified,evidence=evidence,released=released,original_status=status))
    closed=drained and verified and evidence and phase=='baseline' and not uncertain
    return dict(trace=trace,model_original_status=status,model_forward_effects=forward_count,model_restore_writes=restore_writes,
        model_scoped_target_obligations_closed=closed,model_machine_obligations_pending=not closed,model_controller_obligations_pending=not released or uncertain,
        model_phase_unknown=uncertain,model_denials=denied,model_recovery_budget_remaining=None if uncertain else budget,
        actual_dispatch_authorized=False,actual_recovery_authorized=False,actual_grant_consumed=False,actual_clock_or_fence_proven=False,
        actual_restoration_proven=False,actual_host_obligations_closed=False,actual_operational_conformance=False,actual_strong_safe_pause_confirmed=False,
        renewal_authorized=False,retry_authorized=False,publication_authorized=False)






def run_historical(history):
    with tempfile.TemporaryDirectory(prefix='step323-exact322-') as directory:
        snapshot = Path(directory)/'slack-update'
        for rel,content in history.items():
            p = snapshot/safe_relative(rel); p.parent.mkdir(parents=True,exist_ok=True); p.write_bytes(content)
        result = subprocess.run(['bash',str(snapshot/'tests/reference'/('test-'+PRIOR+'-harness.sh'))],capture_output=True)
        lines = result.stdout.decode().splitlines()
        if result.returncode or lines.count('Result: PASS (456 passes, 0 failures)')!=1 or sum(x.startswith('PASS: ') for x in lines)!=456:
            sys.stderr.buffer.write(result.stdout+result.stderr)
            raise ValueError('full exact456 predecessor acceptance failed')
        return result.stdout

def main(root,out):
    if not root.is_dir() or root.absolute()!=root.resolve():raise ValueError('unsafe repository root')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'changed323 input '+rel)
    fixture=root/FIXTURE;load=lambda suffix:json.loads((fixture/(BASE+suffix)).read_bytes())
    policy,design=load('-policy.json'),load('-design.json');history=verify_history(root,policy)
    frozen=json.loads(history[FIXTURE+'/'+REQUIREMENTS_BASE+'-freeze.json']);prior=json.loads(history[FIXTURE+'/'+PRIOR+'-design.json'])
    validate_design(design,prior,frozen,history);validate_confirmation(load('-checkpoint-confirmation.json'),load('-step322-user-acceptance.json'))
    validate_tables(*[(fixture/(BASE+s)).read_bytes() for s in ['-revocation-scope-matrix.tsv','-bounded-recovery-action-matrix.tsv']])
    payloads={BASE+s:(fixture/(BASE+s)).read_bytes() for s in SUFFIXES};log_name=BASE+'-predecessor-test.log'
    if not out.is_dir() or out.absolute()!=out.resolve():raise ValueError('output must exist without symlink ancestors')
    if any((out/name).exists() or (out/name).is_symlink() for name in list(payloads)+[log_name]):raise ValueError('occupied output; no overwrite')
    payloads[log_name]=run_historical(history);exact(verify_history(root,policy),history,'history changed during validation')
    for rel,digest in OWN_HASHES.items():exact(sha(safe_file(root,rel)),digest,'323 input changed during validation')
    created=[]
    try:
        for name,content in payloads.items():
            with (out/name).open('xb') as stream:created.append(out/name);stream.write(content)
    except BaseException:
        for p in reversed(created):p.unlink()
        raise
    print('exact_step322_acceptance\tPASS (456 passes, 0 failures)')
    print('step323_split_rights_design_review_status\tPASS');print('actual_forward_or_recovery_authorized\tno')
    print('actual_clock_fence_budget_or_restoration_proven\tno');print('operational_readiness\tno')
    print('strong_safe_pause\tno');print('last_confirmed_strong_safe_pause_step\t318');print('next_stage_authorized\tno')

if __name__ == '__main__':
    try: main(Path(sys.argv[1]).absolute(),Path(sys.argv[2]).absolute())
    except (ValueError,OSError,KeyError,TypeError) as exc:
        print('ERROR: '+str(exc),file=sys.stderr);sys.exit(1)
PYREVIEW
